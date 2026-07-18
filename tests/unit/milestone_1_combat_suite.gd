@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EPSILON: float = 0.00001

var _combat_space: CombatSpaceDefinition = CombatSpaceDefinition.new()


class HealthSignalCapture:
	extends RefCounted

	var health_events: Array[Vector2i] = []
	var depleted_count: int = 0

	func on_health_changed(current_health: int, maximum_health: int) -> void:
		health_events.append(Vector2i(current_health, maximum_health))

	func on_depleted() -> void:
		depleted_count += 1


class AttackSignalCapture:
	extends RefCounted

	var phase_edges: Array[Vector2i] = []
	var active_count: int = 0
	var finished_count: int = 0

	func on_phase_changed(previous_phase: int, new_phase: int) -> void:
		phase_edges.append(Vector2i(previous_phase, new_phase))

	func on_active_started() -> void:
		active_count += 1

	func on_attack_finished() -> void:
		finished_count += 1


func suite_name() -> String:
	return "milestone_1_combat"


func test_damage_is_non_negative_and_uses_deterministic_half_up_rounding() -> void:
	_expect_equal(
		DamageCalculator.calculate_damage(-20, 1.0, 1.0, 1.0),
		0,
		"damage: negative base clamps to zero"
	)
	_expect_equal(
		DamageCalculator.calculate_damage(20, -1.0, 1.0, 1.0),
		0,
		"damage: negative attacker multiplier clamps to zero"
	)
	_expect_equal(
		DamageCalculator.calculate_damage(20, 1.0, -2.0, 1.0),
		0,
		"damage: negative ability multiplier clamps to zero"
	)
	_expect_equal(
		DamageCalculator.calculate_damage(20, 1.0, 1.0, -0.5),
		0,
		"damage: negative taken multiplier clamps to zero"
	)
	_expect_equal(
		DamageCalculator.calculate_damage(3, 0.5, 1.0, 1.0),
		2,
		"damage: exact 1.5 rounds half up"
	)
	_expect_equal(
		DamageCalculator.calculate_damage(10, 0.149, 1.0, 1.0),
		1,
		"damage: 1.49 rounds down"
	)
	_expect_equal(
		DamageCalculator.calculate_damage(10, 0.151, 1.0, 1.0),
		2,
		"damage: 1.51 rounds up"
	)
	_expect_equal(
		DamageCalculator.calculate_damage(16, 1.25, 0.5, 1.2),
		12,
		"damage: authored multiplier order has an exact deterministic result"
	)


func test_health_clamps_overkill_and_emits_depletion_once() -> void:
	var health: HealthComponent = track(HealthComponent.new()) as HealthComponent
	var capture: HealthSignalCapture = HealthSignalCapture.new()
	health.health_changed.connect(capture.on_health_changed)
	health.depleted.connect(capture.on_depleted)

	health.initialize(10)
	_expect_equal(health.maximum_health, 10, "health: authored maximum is retained")
	_expect_equal(health.current_health, 10, "health: initialization fills health")
	_expect_equal(health.apply_damage(-5), 0, "health: negative damage is rejected")
	_expect_equal(health.apply_damage(4), 4, "health: ordinary damage reports applied amount")
	_expect_equal(health.current_health, 6, "health: ordinary damage changes current health")
	_expect_equal(health.apply_damage(100), 6, "health: overkill reports only remaining health")
	_expect_equal(health.current_health, 0, "health: overkill clamps at zero")
	_expect_equal(capture.depleted_count, 1, "health: depletion emits exactly once")
	_expect_equal(health.apply_damage(1), 0, "health: damage after death is a no-op")
	_expect_equal(capture.depleted_count, 1, "health: repeated damage cannot re-emit death")
	_expect_equal(health.heal(5), 0, "health: depleted actors cannot be revived implicitly")
	_expect_equal(capture.health_events, [Vector2i(10, 10), Vector2i(6, 10), Vector2i(0, 10)], "health: only authoritative changes emit")


func test_actor_state_machine_exposes_all_required_states_and_terminal_rules() -> void:
	var state_machine: ActorStateMachine = track(ActorStateMachine.new()) as ActorStateMachine
	var required_names: Array[String] = [
		"IDLE",
		"PATROLLING",
		"ACQUIRING_TARGET",
		"APPROACHING_TARGET",
		"ATTACK_WINDUP",
		"ATTACK_ACTIVE",
		"ATTACK_RECOVERY",
		"STUNNED",
		"KNOCKED_BACK",
		"INCAPACITATED",
		"DEAD",
	]
	for state: int in range(required_names.size()):
		_expect_equal(
			ActorStateMachine.state_name(state),
			required_names[state],
			"state machine: required state %d has a stable debug name" % state
		)

	_expect_equal(state_machine.current_state, ActorStateMachine.State.IDLE, "state machine: starts idle")
	_expect_true(
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET),
		"state machine: ordinary transition succeeds"
	)
	state_machine.advance_time(0.25)
	_expect_true(state_machine.state_elapsed > 0.24, "state machine: elapsed time advances")
	_expect_true(
		state_machine.transition_to(ActorStateMachine.State.ATTACK_WINDUP),
		"state machine: attack windup transition succeeds"
	)
	_expect_approx(state_machine.state_elapsed, 0.0, "state machine: transition resets elapsed time")
	_expect_false(
		state_machine.transition_to(ActorStateMachine.State.ATTACK_WINDUP),
		"state machine: duplicate transition is rejected"
	)
	_expect_true(
		state_machine.transition_to(ActorStateMachine.State.INCAPACITATED),
		"state machine: incapacitation is reachable"
	)
	_expect_true(state_machine.is_terminal(), "state machine: incapacitated is terminal")
	_expect_false(
		state_machine.transition_to(ActorStateMachine.State.IDLE),
		"state machine: incapacitated cannot resume ordinary action"
	)
	_expect_true(
		state_machine.transition_to(ActorStateMachine.State.DEAD),
		"state machine: incapacitated may transition to dead"
	)
	_expect_false(
		state_machine.transition_to(ActorStateMachine.State.IDLE),
		"state machine: dead is immutable"
	)


func test_attack_timing_respects_just_before_exact_and_after_phase_edges() -> void:
	var definition: AttackDefinition = _timing_definition()
	var controller: AttackController = track(AttackController.new()) as AttackController
	var capture: AttackSignalCapture = _capture_attack_signals(controller)

	_expect_true(controller.start_attack(definition), "attack timing: attack starts")
	_expect_equal(controller.current_phase, AttackController.Phase.WINDUP, "attack timing: starts in windup")
	_expect_false(controller.is_hitbox_active(), "attack timing: windup hitbox is inactive")
	controller.step(0.199)
	_expect_equal(controller.current_phase, AttackController.Phase.WINDUP, "attack timing: just before windup edge stays windup")
	controller.step(controller.phase_remaining)
	_expect_equal(controller.current_phase, AttackController.Phase.ACTIVE, "attack timing: exact windup edge enters active")
	_expect_true(controller.is_hitbox_active(), "attack timing: active phase enables logical hitbox")
	_expect_equal(capture.active_count, 1, "attack timing: active edge emits once")
	controller.step(0.079)
	_expect_equal(controller.current_phase, AttackController.Phase.ACTIVE, "attack timing: just before active edge stays active")
	controller.step(controller.phase_remaining)
	_expect_equal(controller.current_phase, AttackController.Phase.RECOVERY, "attack timing: exact active edge enters recovery")
	_expect_false(controller.is_hitbox_active(), "attack timing: recovery hitbox is inactive")
	controller.step(0.339)
	_expect_equal(controller.current_phase, AttackController.Phase.RECOVERY, "attack timing: just before recovery edge stays recovery")
	controller.step(controller.phase_remaining + 0.001)
	_expect_equal(controller.current_phase, AttackController.Phase.IDLE, "attack timing: step past recovery edge returns idle")
	_expect_equal(capture.active_count, 1, "attack timing: completed attack has one active edge")
	_expect_equal(capture.finished_count, 1, "attack timing: completed attack emits one finish")
	_expect_equal(controller.active_edge_count, 1, "attack timing: controller records one active edge")


func test_attack_large_delta_consumes_all_phases_without_duplicate_active_edge() -> void:
	var definition: AttackDefinition = _timing_definition()
	var controller: AttackController = track(AttackController.new()) as AttackController
	var capture: AttackSignalCapture = _capture_attack_signals(controller)

	_expect_true(controller.start_attack(definition), "large delta: attack starts")
	_expect_false(controller.start_attack(definition), "large delta: overlapping attack is rejected")
	controller.step(10.0)
	_expect_equal(controller.current_phase, AttackController.Phase.IDLE, "large delta: timeline completes")
	_expect_equal(capture.active_count, 1, "large delta: active signal cannot duplicate")
	_expect_equal(capture.finished_count, 1, "large delta: finish signal cannot duplicate")
	_expect_equal(controller.active_edge_count, 1, "large delta: one authoritative active edge")
	controller.step(10.0)
	_expect_equal(capture.active_count, 1, "large delta: idle stepping is a no-op")
	_expect_equal(capture.finished_count, 1, "large delta: idle stepping cannot re-finish")


func test_attack_cancel_is_an_immediate_inactive_seam() -> void:
	var definition: AttackDefinition = _timing_definition()
	var controller: AttackController = track(AttackController.new()) as AttackController
	var capture: AttackSignalCapture = _capture_attack_signals(controller)

	controller.start_attack(definition)
	controller.step(definition.windup_time)
	_expect_true(controller.is_hitbox_active(), "cancel: attack reached active")
	controller.cancel()
	_expect_equal(controller.current_phase, AttackController.Phase.IDLE, "cancel: returns idle immediately")
	_expect_false(controller.is_hitbox_active(), "cancel: hitbox is inactive immediately")
	_expect_equal(capture.active_count, 1, "cancel: already-crossed active edge remains singular")
	_expect_equal(capture.finished_count, 0, "cancel: interruption is not a normal finish")
	controller.cancel()
	_expect_equal(capture.finished_count, 0, "cancel: repeated cancel is a no-op")


func test_three_lane_mapping_is_clamped_and_evenly_spaced() -> void:
	_expect_approx(_combat_space.lane_y(-99), _combat_space.lane_y(0), "lanes: low index clamps to back")
	_expect_approx(_combat_space.lane_y(0), _combat_space.lane_y(0), "lanes: back lane is authored")
	_expect_approx(_combat_space.lane_y(1), _combat_space.lane_y(1), "lanes: middle lane is authored")
	_expect_approx(_combat_space.lane_y(2), _combat_space.lane_y(2), "lanes: front lane is authored")
	_expect_approx(_combat_space.lane_y(99), _combat_space.lane_y(2), "lanes: high index clamps to front")
	_expect_approx(
		_combat_space.lane_y(1) - _combat_space.lane_y(0),
		32.0,
		"lanes: back-to-middle spacing is stable"
	)
	_expect_approx(
		_combat_space.lane_y(2) - _combat_space.lane_y(1),
		32.0,
		"lanes: middle-to-front spacing is stable"
	)


func test_six_attack_positions_are_unique_span_three_lanes_and_release_for_reuse() -> void:
	var registry: AttackPositionRegistry = track(AttackPositionRegistry.new()) as AttackPositionRegistry
	registry.configure(_combat_space)
	var target: ActorController = track(ActorController.new()) as ActorController
	target.global_position = Vector2(320.0, _combat_space.lane_y(1))
	target.lane_index = 1
	var attackers: Array[ActorController] = []
	var positions: Array[Vector2] = []
	for index: int in range(7):
		var attacker: ActorController = track(ActorController.new()) as ActorController
		attacker.global_position = Vector2(260.0 + float(index), _combat_space.lane_y(1))
		attackers.append(attacker)

	for index: int in range(6):
		_expect_true(
			registry.reserve(attackers[index], target, 52.0),
			"reservations: slot %d can be reserved" % index
		)
		var position: Vector2 = registry.get_world_position(attackers[index])
		_expect_false(positions.has(position), "reservations: slot %d has a unique world position" % index)
		positions.append(position)
	_expect_false(registry.reserve(attackers[6], target, 52.0), "reservations: seventh attacker is rejected")
	_expect_equal(registry.get_snapshot().size(), 6, "reservations: exactly six slots exist")

	var observed_lane_y: Array[float] = []
	for position: Vector2 in positions:
		if not observed_lane_y.has(position.y):
			observed_lane_y.append(position.y)
	observed_lane_y.sort()
	_expect_equal(
		observed_lane_y,
		[_combat_space.lane_y(0), _combat_space.lane_y(1), _combat_space.lane_y(2)],
		"reservations: a middle-lane target exposes positions across all authored lanes"
	)

	var released_position: Vector2 = registry.get_world_position(attackers[2])
	registry.release_attacker(attackers[2])
	_expect_false(registry.has_reservation(attackers[2]), "reservations: released attacker loses its slot")
	_expect_true(registry.reserve(attackers[6], target, 52.0), "reservations: released capacity is reusable")
	_expect_equal(
		registry.get_world_position(attackers[6]),
		released_position,
		"reservations: deterministic nearest free slot is reused"
	)
	registry.release_target(target)
	_expect_equal(registry.get_snapshot().size(), 0, "reservations: releasing target clears every attacker")


func _timing_definition() -> AttackDefinition:
	var definition: AttackDefinition = AttackDefinition.new()
	definition.windup_time = 0.2
	definition.active_time = 0.08
	definition.recovery_time = 0.34
	definition.cooldown_time = 0.22
	return definition


func _capture_attack_signals(controller: AttackController) -> AttackSignalCapture:
	var capture: AttackSignalCapture = AttackSignalCapture.new()
	controller.phase_changed.connect(capture.on_phase_changed)
	controller.active_started.connect(capture.on_active_started)
	controller.attack_finished.connect(capture.on_attack_finished)
	return capture


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(absf(actual - expected) <= EPSILON, "%s (expected %.6f, got %.6f)" % [context, expected, actual])
