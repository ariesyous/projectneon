class_name ActorController
extends Node2D

## Generic definition-backed automatic combat actor. The scene composes state,
## health, attack timing, logical hitbox, and replaceable presentation nodes.

signal state_changed(actor: ActorController, previous_state: int, new_state: int)
signal target_changed(actor: ActorController, target: ActorController)
signal health_changed(actor: ActorController, current_health: int, maximum_health: int)
signal died(actor: ActorController)
signal incapacitated(actor: ActorController)
signal enrage_changed(actor: ActorController, enraged: bool)
signal status_changed(
	actor: ActorController,
	status_id: StringName,
	stacks: int,
	remaining_seconds: float
)

enum Team {
	CREW,
	ENEMY,
}

const DEFAULT_COMBAT_SPACE: CombatSpaceDefinition = preload(
	"res://data/combat/downtown_loop_combat_space.tres"
)
const POSITION_ARRIVAL_TOLERANCE: float = 2.0

@export var actor_definition: ActorDefinition
@export var attack_definition: AttackDefinition
@export var special_attack_definitions: Array[AttackDefinition] = []
@export var team: int = Team.ENEMY
@export_range(0, 2, 1) var initial_lane: int = 1

@onready var state_machine: ActorStateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var status_controller: StatusController = get_node_or_null("StatusController") as StatusController
@onready var attack_controller: AttackController = $AttackController
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var actor_visual: ActorVisual = $ActorVisual

var combat_coordinator: Node = null
var combat_space: CombatSpaceDefinition = DEFAULT_COMBAT_SPACE
var current_target: ActorController = null
var registration_order: int = -1
var lane_index: int = 1
var facing_direction: float = 1.0
var _attack_cooldown_remaining: float = 0.0
var _active_attack_definition: AttackDefinition = null
var _planned_attack_definition: AttackDefinition = null
var _special_cooldown_by_id: Dictionary[StringName, float] = {}
var _used_one_shot_attack_ids: Dictionary[StringName, bool] = {}
var _special_cycle_index: int = 0
var _basic_attacks_since_special: int = 0
var _knockback_remaining: float = 0.0
var _knockback_velocity_x: float = 0.0
var _knockback_initial_force: float = 0.0
var _knockback_source_id: StringName = &"knockback"
var _knockback_source_actor: ActorController = null
var _environmental_collision_emitted: bool = false
var _stun_remaining: float = 0.0
var _control_lockout_remaining: float = 0.0
var _cleanup_remaining: float = 0.0
var _runtime_initialized: bool = false
var _runtime_health_multiplier: float = 1.0
var _runtime_damage_multiplier: float = 1.0
var _build_flat_modifiers: Dictionary[StringName, float] = {}
var _build_percent_modifiers: Dictionary[StringName, float] = {}
var _enraged: bool = false


func _ready() -> void:
	_ensure_status_controller()
	state_machine.state_changed.connect(_on_state_machine_changed)
	health_component.health_changed.connect(_on_health_component_changed)
	health_component.depleted.connect(_on_health_depleted)
	attack_controller.phase_changed.connect(_on_attack_phase_changed)
	attack_controller.active_started.connect(_on_attack_active_started)
	attack_controller.attack_finished.connect(_on_attack_finished)
	attack_hitbox.monitorable = false
	attack_hitbox.monitoring = false
	lane_index = clampi(initial_lane, 0, 2)
	global_position.y = combat_space.lane_y(lane_index)
	global_position = combat_space.clamp_actor_position(global_position)
	_refresh_lane_depth()
	initialize_runtime()
	set_process(false)
	if combat_coordinator != null:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func initialize_runtime() -> void:
	if _runtime_initialized:
		return
	if actor_definition == null:
		push_error("ActorController '%s' requires an ActorDefinition." % name)
		return
	if attack_definition == null:
		push_error("ActorController '%s' requires an AttackDefinition." % name)
		return
	_ensure_status_controller()
	_runtime_initialized = true
	_special_cooldown_by_id.clear()
	_used_one_shot_attack_ids.clear()
	_special_cycle_index = 0
	_basic_attacks_since_special = 0
	_enraged = false
	for special_attack: AttackDefinition in special_attack_definitions:
		if special_attack != null and special_attack.id != &"":
			_special_cooldown_by_id[special_attack.id] = 0.0
	var scaled_maximum_health: int = maxi(
		int(floor(float(actor_definition.maximum_health) * _runtime_health_multiplier + 0.5)),
		1
	)
	health_component.initialize(scaled_maximum_health)
	actor_visual.set_health(health_component.current_health, health_component.maximum_health)
	actor_visual.set_state(state_machine.current_state)
	actor_visual.set_facing(facing_direction)


func configure_combat_space(definition: CombatSpaceDefinition) -> void:
	combat_space = definition if definition != null else DEFAULT_COMBAT_SPACE
	lane_index = clampi(lane_index, 0, maxi(combat_space.lane_count() - 1, 0))
	global_position = combat_space.clamp_actor_position(global_position)
	if not is_node_ready():
		return
	_refresh_lane_from_position()


func configure_runtime_scaling(health_multiplier: float, damage_multiplier: float) -> void:
	if _runtime_initialized:
		return
	_runtime_health_multiplier = maxf(health_multiplier, 0.0)
	_runtime_damage_multiplier = maxf(damage_multiplier, 0.0)


func get_runtime_damage_multiplier() -> float:
	var enrage_multiplier: float = (
		actor_definition.enrage_damage_multiplier
		if _enraged and actor_definition != null
		else 1.0
	)
	return _runtime_damage_multiplier * enrage_multiplier


func apply_build_modifiers(
	flat_modifiers: Dictionary[StringName, float],
	percent_modifiers: Dictionary[StringName, float]
) -> void:
	_build_flat_modifiers.clear()
	_build_percent_modifiers.clear()
	if team == Team.CREW:
		for stat_id: StringName in flat_modifiers:
			_build_flat_modifiers[stat_id] = flat_modifiers[stat_id]
		for stat_id: StringName in percent_modifiers:
			_build_percent_modifiers[stat_id] = percent_modifiers[stat_id]
	if _runtime_initialized:
		var base_maximum: float = (
			float(actor_definition.maximum_health)
			* _runtime_health_multiplier
			* maxf(0.05, 1.0 + get_build_percent_modifier(&"maximum_health"))
		)
		health_component.set_maximum_health(maxi(int(floor(base_maximum + 0.5)), 1))


func get_build_flat_modifier(stat_id: StringName) -> float:
	return _build_flat_modifiers.get(stat_id, 0.0)


func get_build_percent_modifier(stat_id: StringName) -> float:
	return _build_percent_modifiers.get(stat_id, 0.0)


func get_movement_speed() -> float:
	return actor_definition.movement_speed * maxf(
		0.05,
		1.0 + get_build_percent_modifier(&"movement_speed")
	)


func get_attack_speed_multiplier() -> float:
	var enrage_multiplier: float = (
		actor_definition.enrage_attack_speed_multiplier
		if _enraged and actor_definition != null
		else 1.0
	)
	return maxf(
		0.05,
		(1.0 + get_build_percent_modifier(&"attack_speed")) * enrage_multiplier
	)


func get_intervention_cooldown_multiplier() -> float:
	return (
		actor_definition.intervention_cooldown_multiplier
		if actor_definition != null
		else 1.0
	)


func get_combat_role() -> int:
	return (
		actor_definition.combat_role
		if actor_definition != null
		else ActorDefinition.CombatRole.BASIC_ENEMY
	)


func is_permanent_crew() -> bool:
	return actor_definition != null and actor_definition.is_permanent_crew()


func is_elite() -> bool:
	return actor_definition != null and actor_definition.is_elite()


func is_boss() -> bool:
	return actor_definition != null and actor_definition.is_boss()


func is_enraged() -> bool:
	return _enraged


func get_control_lockout_remaining() -> float:
	return _control_lockout_remaining


func get_combat_space() -> CombatSpaceDefinition:
	return combat_space


func bind_combat(coordinator: Node) -> void:
	combat_coordinator = coordinator
	if is_node_ready() and can_act():
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func unbind_combat() -> void:
	clear_target()
	combat_coordinator = null
	if is_node_ready() and can_act():
		state_machine.transition_to(ActorStateMachine.State.IDLE)


func step_simulation(delta: float) -> void:
	if not _runtime_initialized or delta <= 0.0 or state_machine.is_terminal():
		return
	if status_controller != null:
		status_controller.step(delta)
	if state_machine.is_terminal():
		return
	state_machine.advance_time(delta)
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	_control_lockout_remaining = maxf(_control_lockout_remaining - delta, 0.0)
	for special_id: StringName in _special_cooldown_by_id.keys():
		_special_cooldown_by_id[special_id] = maxf(
			_special_cooldown_by_id.get(special_id, 0.0) - delta,
			0.0
		)

	if _knockback_remaining > 0.0:
		_step_knockback(delta)
		return
	if _stun_remaining > 0.0:
		_step_stun(delta)
		return

	if current_target != null and not _coordinator_target_is_valid(current_target):
		_cancel_active_attack()
		clear_target()

	if attack_controller.is_attacking():
		attack_controller.step(delta)
		return

	if current_target == null:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)
		_acquire_target()
		if current_target == null:
			return

	var planned_attack: AttackDefinition = _get_planned_attack_definition()
	if planned_attack == null:
		return
	if not _approach_for_attack(planned_attack, delta):
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
		return
	if _attack_cooldown_remaining <= 0.0:
		_start_planned_attack(planned_attack)
	else:
		state_machine.transition_to(ActorStateMachine.State.IDLE)


func _get_planned_attack_definition() -> AttackDefinition:
	if _planned_attack_definition != null:
		return _planned_attack_definition
	if _basic_attacks_since_special > 0:
		var specials: Array[AttackDefinition] = _get_stable_special_attacks()
		for offset: int in range(specials.size()):
			var candidate_index: int = (special_cycle_index() + offset) % specials.size()
			var candidate: AttackDefinition = specials[candidate_index]
			if not _is_special_attack_available(candidate):
				continue
			_special_cycle_index = candidate_index
			_planned_attack_definition = candidate
			return candidate
	_planned_attack_definition = attack_definition
	return _planned_attack_definition


func special_cycle_index() -> int:
	var specials: Array[AttackDefinition] = _get_stable_special_attacks()
	return 0 if specials.is_empty() else posmod(_special_cycle_index, specials.size())


func _get_stable_special_attacks() -> Array[AttackDefinition]:
	var result: Array[AttackDefinition] = []
	var seen: Dictionary[StringName, bool] = {}
	for candidate: AttackDefinition in special_attack_definitions:
		if candidate == null or candidate.id == &"" or seen.has(candidate.id):
			continue
		seen[candidate.id] = true
		result.append(candidate)
	result.sort_custom(_attack_id_before)
	return result


func _is_special_attack_available(candidate: AttackDefinition) -> bool:
	if candidate == null:
		return false
	if _special_cooldown_by_id.get(candidate.id, 0.0) > 0.0:
		return false
	return not candidate.one_shot or not _used_one_shot_attack_ids.has(candidate.id)


func _approach_for_attack(planned_attack: AttackDefinition, delta: float) -> bool:
	if current_target == null or planned_attack == null:
		return false
	face_toward(current_target.global_position.x)
	if planned_attack.delivery_kind == AttackDefinition.DeliveryKind.MELEE:
		return _approach_reserved_melee_position(planned_attack, delta)
	_release_attack_position()
	if planned_attack.delivery_kind == AttackDefinition.DeliveryKind.SUMMON:
		return true

	var distance: float = global_position.distance_to(current_target.global_position)
	var minimum_range: float = maxf(
		planned_attack.minimum_range,
		actor_definition.preferred_minimum_range if actor_definition != null else 0.0
	)
	var maximum_range: float = planned_attack.attack_range
	if actor_definition != null and actor_definition.preferred_maximum_range > 0.0:
		maximum_range = minf(maximum_range, actor_definition.preferred_maximum_range)
	if distance < minimum_range:
		var retreat_direction: float = -1.0 if current_target.global_position.x > global_position.x else 1.0
		var previous_position: Vector2 = global_position
		global_position = combat_space.clamp_actor_position(
			global_position + Vector2(retreat_direction * get_movement_speed() * delta, 0.0)
		)
		_refresh_lane_from_position()
		return global_position.is_equal_approx(previous_position)
	if distance > maximum_range:
		global_position = combat_space.clamp_actor_position(
			global_position.move_toward(current_target.global_position, get_movement_speed() * delta)
		)
		_refresh_lane_from_position()
		return false
	return true


func _approach_reserved_melee_position(
	planned_attack: AttackDefinition,
	delta: float
) -> bool:
	if not _has_attack_position() and not _reserve_attack_position_for(planned_attack.attack_range):
		return false
	var destination: Vector2 = _get_attack_position()
	if destination == Vector2.INF:
		_release_attack_position()
		return false
	if global_position.distance_to(destination) > POSITION_ARRIVAL_TOLERANCE:
		global_position = global_position.move_toward(destination, get_movement_speed() * delta)
		global_position = combat_space.clamp_actor_position(global_position)
		_refresh_lane_from_position()
		return false
	global_position = combat_space.clamp_actor_position(destination)
	_refresh_lane_from_position()
	return global_position.distance_to(current_target.global_position) <= planned_attack.attack_range


func _start_planned_attack(planned_attack: AttackDefinition) -> void:
	_active_attack_definition = planned_attack
	if planned_attack.telegraph_seconds > 0.0:
		_notify_attack_telegraph(planned_attack)
	if not attack_controller.start_attack(planned_attack):
		_active_attack_definition = null
		return
	if planned_attack == attack_definition:
		_basic_attacks_since_special += 1
	else:
		_basic_attacks_since_special = 0
		_special_cooldown_by_id[planned_attack.id] = maxf(
			planned_attack.special_cooldown_seconds,
			0.0
		)
		if planned_attack.one_shot:
			_used_one_shot_attack_ids[planned_attack.id] = true
		var specials: Array[AttackDefinition] = _get_stable_special_attacks()
		if not specials.is_empty():
			_special_cycle_index = (_special_cycle_index + 1) % specials.size()


func _notify_attack_telegraph(planned_attack: AttackDefinition) -> void:
	if combat_coordinator == null or not combat_coordinator.has_method("notify_attack_telegraph"):
		return
	combat_coordinator.call("notify_attack_telegraph", self, planned_attack)


func _cancel_active_attack() -> void:
	attack_controller.cancel()
	_active_attack_definition = null
	_planned_attack_definition = null


func _attack_id_before(left: AttackDefinition, right: AttackDefinition) -> bool:
	return String(left.id) < String(right.id)


func assign_target(target: ActorController) -> bool:
	if target == current_target:
		return target != null
	if target != null and not _coordinator_target_is_valid(target):
		return false
	_release_attack_position()
	_planned_attack_definition = null
	current_target = target
	actor_visual.set_has_target(current_target != null)
	if current_target != null:
		face_toward(current_target.global_position.x)
		target_changed.emit(self, current_target)
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
	else:
		target_changed.emit(self, null)
		if can_act():
			state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)
	return true


func invalidate_target(invalid_actor: ActorController) -> void:
	if current_target == invalid_actor:
		_cancel_active_attack()
		clear_target()


func clear_target() -> void:
	_release_attack_position()
	_planned_attack_definition = null
	if current_target == null:
		return
	current_target = null
	actor_visual.set_has_target(false)
	target_changed.emit(self, null)


func receive_damage(amount: int) -> int:
	if not can_be_targeted():
		return 0
	var applied_damage: int = health_component.apply_damage(maxi(amount, 0))
	if applied_damage > 0:
		actor_visual.play_hit_flash()
	return applied_damage


func set_hit_flash_reduction(reduction: float) -> void:
	if actor_visual != null:
		actor_visual.set_hit_flash_reduction(reduction)


func apply_status(
	status_id: StringName,
	stacks: int,
	duration_seconds: float,
	maximum_stacks_override: int = -1
) -> bool:
	if not can_be_targeted():
		return false
	_ensure_status_controller()
	return status_controller.apply_status(
		status_id,
		stacks,
		duration_seconds,
		maximum_stacks_override
	)


func has_status(status_id: StringName) -> bool:
	return status_controller != null and status_controller.has_status(status_id)


func get_status_stacks(status_id: StringName) -> int:
	return status_controller.get_stacks(status_id) if status_controller != null else 0


func is_knocked_back() -> bool:
	return _knockback_remaining > 0.0


func apply_knockback(
	direction_x: float,
	force: float,
	duration: float,
	source_id: StringName = &"knockback",
	source_actor: ActorController = null
) -> void:
	if not can_act() or force <= 0.0 or duration <= 0.0:
		return
	if actor_definition != null and force <= actor_definition.light_stagger_armour:
		return
	var resistance: float = clampf(actor_definition.knockback_resistance, 0.0, 1.0)
	var received_multiplier: float = maxf(
		0.0,
		1.0 + get_build_percent_modifier(&"knockback_received")
	)
	_knockback_velocity_x = (
		(-1.0 if direction_x < 0.0 else 1.0)
		* force
		* (1.0 - resistance)
		* received_multiplier
	)
	_knockback_remaining = duration
	_knockback_initial_force = force
	_knockback_source_id = source_id
	_knockback_source_actor = source_actor
	_environmental_collision_emitted = false
	_cancel_active_attack()
	_release_attack_position()
	state_machine.transition_to(ActorStateMachine.State.KNOCKED_BACK)


func apply_stun(duration: float) -> void:
	request_stun(duration)


func request_stun(duration: float) -> bool:
	if not can_act() or duration <= 0.0:
		return false
	if _control_lockout_remaining > 0.0:
		return false
	var resistance: float = (
		clampf(actor_definition.stagger_resistance, 0.0, 1.0)
		if actor_definition != null
		else 0.0
	)
	var maximum_duration: float = (
		maxf(actor_definition.maximum_stun_duration, 0.0)
		if actor_definition != null
		else duration
	)
	var applied_duration: float = minf(duration * (1.0 - resistance), maximum_duration)
	if applied_duration <= 0.0:
		return false
	_stun_remaining = maxf(_stun_remaining, applied_duration)
	_control_lockout_remaining = (
		maxf(actor_definition.control_lockout_seconds, 0.0)
		if actor_definition != null
		else 0.0
	)
	_cancel_active_attack()
	_release_attack_position()
	state_machine.transition_to(ActorStateMachine.State.STUNNED)
	return true


func can_act() -> bool:
	return (
		_runtime_initialized
		and not health_component.is_depleted()
		and not state_machine.is_terminal()
	)


func can_be_targeted() -> bool:
	return can_act() and not is_queued_for_deletion()


func is_target_in_attack_range(
	target: ActorController,
	definition: AttackDefinition = null
) -> bool:
	var resolved_definition: AttackDefinition = definition if definition != null else attack_definition
	if target == null or not is_instance_valid(target) or resolved_definition == null:
		return false
	return global_position.distance_to(target.global_position) <= resolved_definition.attack_range


func is_hitbox_active() -> bool:
	return (
		state_machine.current_state == ActorStateMachine.State.ATTACK_ACTIVE
		and attack_controller.is_hitbox_active()
		and attack_hitbox.monitoring
	)


func set_targeted_indicator(is_targeted: bool) -> void:
	actor_visual.set_targeted(is_targeted)


func face_toward(world_x: float) -> void:
	if is_equal_approx(world_x, global_position.x):
		return
	facing_direction = -1.0 if world_x < global_position.x else 1.0
	actor_visual.set_facing(facing_direction)
	attack_hitbox.position.x = 18.0 * facing_direction


func definition_id() -> StringName:
	return actor_definition.id if actor_definition != null else &"missing"


func authored_coin_value() -> int:
	if actor_definition == null or not actor_definition.grants_coin_reward:
		return 0
	return maxi(actor_definition.authored_coin_value, 0)


func grants_coin_reward() -> bool:
	return actor_definition != null and actor_definition.grants_coin_reward


func get_state_name() -> String:
	return ActorStateMachine.state_name(state_machine.current_state)


func get_snapshot() -> Dictionary:
	return {
		"instance_id": get_instance_id(),
		"registration_order": registration_order,
		"definition_id": definition_id(),
		"display_name": actor_definition.display_name if actor_definition != null else String(name),
		"combat_role": get_combat_role(),
		"team": team,
		"state": state_machine.current_state,
		"state_name": get_state_name(),
		"current_health": health_component.current_health,
		"maximum_health": health_component.maximum_health,
		"runtime_health_multiplier": _runtime_health_multiplier,
		"runtime_damage_multiplier": _runtime_damage_multiplier,
		"build_flat_modifiers": _build_flat_modifiers.duplicate(),
		"build_percent_modifiers": _build_percent_modifiers.duplicate(),
		"statuses": status_controller.get_snapshot() if status_controller != null else [],
		"lane": lane_index,
		"target_instance_id": current_target.get_instance_id() if current_target != null else -1,
		"position": global_position,
		"hitbox_active": is_hitbox_active(),
		"active_attack_id": (
			_active_attack_definition.id if _active_attack_definition != null else &""
		),
		"enraged": _enraged,
		"control_lockout_remaining": _control_lockout_remaining,
	}


static func lane_y(requested_lane: int) -> float:
	# Compatibility seam for callers that do not yet hold the run-scoped
	# director. Runtime actors use their configured CombatSpaceDefinition.
	return DEFAULT_COMBAT_SPACE.lane_y(requested_lane)


func _acquire_target() -> void:
	if combat_coordinator == null or not combat_coordinator.has_method("acquire_target"):
		return
	var candidate: Variant = combat_coordinator.call("acquire_target", self)
	if candidate is ActorController:
		assign_target(candidate as ActorController)


func _coordinator_target_is_valid(target: ActorController) -> bool:
	if combat_coordinator == null or not combat_coordinator.has_method("is_valid_target"):
		return false
	return bool(combat_coordinator.call("is_valid_target", self, target))


func _reserve_attack_position() -> bool:
	return _reserve_attack_position_for(
		attack_definition.attack_range if attack_definition != null else 0.0
	)


func _reserve_attack_position_for(maximum_distance: float) -> bool:
	if combat_coordinator == null or not combat_coordinator.has_method("reserve_attack_position"):
		return false
	if combat_coordinator.has_method("reserve_attack_position_with_range"):
		return bool(combat_coordinator.call(
			"reserve_attack_position_with_range",
			self,
			current_target,
			maximum_distance
		))
	return bool(combat_coordinator.call("reserve_attack_position", self, current_target))


func _has_attack_position() -> bool:
	if combat_coordinator == null or not combat_coordinator.has_method("has_attack_position"):
		return false
	return bool(combat_coordinator.call("has_attack_position", self, current_target))


func _get_attack_position() -> Vector2:
	if combat_coordinator == null or not combat_coordinator.has_method("get_attack_position"):
		return Vector2.INF
	var result: Variant = combat_coordinator.call("get_attack_position", self)
	return result as Vector2 if result is Vector2 else Vector2.INF


func _release_attack_position() -> void:
	if combat_coordinator != null and combat_coordinator.has_method("release_attack_position"):
		combat_coordinator.call("release_attack_position", self)


func _step_knockback(delta: float) -> void:
	var applied_time: float = minf(delta, _knockback_remaining)
	var requested_position: Vector2 = (
		global_position + Vector2(_knockback_velocity_x * applied_time, 0.0)
	)
	var clamped_position: Vector2 = combat_space.clamp_actor_position(requested_position)
	var hit_horizontal_boundary: bool = not is_equal_approx(
		requested_position.x,
		clamped_position.x
	)
	global_position = clamped_position
	if hit_horizontal_boundary and not _environmental_collision_emitted:
		_environmental_collision_emitted = true
		_request_environmental_collision()
	_knockback_remaining = maxf(_knockback_remaining - delta, 0.0)
	_knockback_velocity_x = move_toward(_knockback_velocity_x, 0.0, 500.0 * delta)
	if _knockback_remaining <= 0.0:
		_knockback_source_actor = null
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)


func _request_environmental_collision() -> void:
	if combat_coordinator == null or not combat_coordinator.has_method(
		"request_environmental_collision"
	):
		return
	combat_coordinator.call(
		"request_environmental_collision",
		_knockback_source_id,
		_knockback_source_actor,
		self,
		global_position,
		_knockback_initial_force
	)


func _step_stun(delta: float) -> void:
	_stun_remaining = maxf(_stun_remaining - delta, 0.0)
	if _stun_remaining <= 0.0:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func _refresh_lane_from_position() -> void:
	lane_index = combat_space.nearest_lane_index(global_position.y)
	_refresh_lane_depth()


func _refresh_lane_depth() -> void:
	z_index = int(combat_space.lane_y(lane_index))


func _on_attack_phase_changed(_previous_phase: int, new_phase: int) -> void:
	match new_phase:
		AttackController.Phase.WINDUP:
			state_machine.transition_to(ActorStateMachine.State.ATTACK_WINDUP)
		AttackController.Phase.ACTIVE:
			state_machine.transition_to(ActorStateMachine.State.ATTACK_ACTIVE)
		AttackController.Phase.RECOVERY:
			state_machine.transition_to(ActorStateMachine.State.ATTACK_RECOVERY)
		AttackController.Phase.IDLE:
			_set_hitbox_active(false)


func _on_attack_active_started() -> void:
	if combat_coordinator == null or not combat_coordinator.has_method("request_attack_hit"):
		return
	var resolved_attack: AttackDefinition = (
		_active_attack_definition
		if _active_attack_definition != null
		else attack_definition
	)
	combat_coordinator.call("request_attack_hit", self, current_target, resolved_attack)


func _on_attack_finished() -> void:
	var resolved_attack: AttackDefinition = (
		_active_attack_definition
		if _active_attack_definition != null
		else attack_definition
	)
	_attack_cooldown_remaining = (
		resolved_attack.cooldown_time / get_attack_speed_multiplier()
		if resolved_attack != null
		else 0.0
	)
	_active_attack_definition = null
	_planned_attack_definition = null
	if current_target != null:
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
	else:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func _on_state_machine_changed(previous_state: int, new_state: int) -> void:
	_set_hitbox_active(new_state == ActorStateMachine.State.ATTACK_ACTIVE)
	actor_visual.set_state(new_state)
	state_changed.emit(self, previous_state, new_state)


func _set_hitbox_active(is_active: bool) -> void:
	attack_hitbox.monitoring = is_active


func _on_health_component_changed(current_health: int, maximum_health: int) -> void:
	actor_visual.set_health(current_health, maximum_health)
	_evaluate_enrage(current_health, maximum_health)
	health_changed.emit(self, current_health, maximum_health)


func _evaluate_enrage(current_health: int, maximum_health: int) -> void:
	if (
		_enraged
		or actor_definition == null
		or not actor_definition.is_boss()
		or actor_definition.enrage_health_ratio <= 0.0
		or current_health <= 0
	):
		return
	var health_ratio: float = float(current_health) / float(maxi(maximum_health, 1))
	if health_ratio > actor_definition.enrage_health_ratio:
		return
	_enraged = true
	enrage_changed.emit(self, true)
	if combat_coordinator != null and combat_coordinator.has_method("notify_boss_enraged"):
		combat_coordinator.call("notify_boss_enraged", self)


func _on_health_depleted() -> void:
	if status_controller != null:
		status_controller.clear_all()
	_cancel_active_attack()
	clear_target()
	if team == Team.CREW:
		state_machine.transition_to(ActorStateMachine.State.INCAPACITATED)
		incapacitated.emit(self)
	else:
		state_machine.transition_to(ActorStateMachine.State.DEAD)
		_cleanup_remaining = actor_definition.cleanup_delay
		set_process(true)
		died.emit(self)


func _on_status_changed(
	status_id: StringName,
	stacks: int,
	remaining_seconds: float
) -> void:
	actor_visual.set_statuses(
		status_controller.get_stacks(&"bleed"),
		status_controller.has_status(&"shock")
	)
	status_changed.emit(self, status_id, stacks, remaining_seconds)


func _on_status_damage_requested(amount: int, _status_id: StringName) -> void:
	receive_damage(amount)


func _ensure_status_controller() -> void:
	if status_controller == null:
		status_controller = StatusController.new()
		status_controller.name = "StatusController"
		add_child(status_controller)
	if not status_controller.status_changed.is_connected(_on_status_changed):
		status_controller.status_changed.connect(_on_status_changed)
	if not status_controller.status_damage_requested.is_connected(
		_on_status_damage_requested
	):
		status_controller.status_damage_requested.connect(_on_status_damage_requested)


func _process(delta: float) -> void:
	if state_machine.current_state != ActorStateMachine.State.DEAD:
		return
	_cleanup_remaining -= maxf(delta, 0.0)
	if _cleanup_remaining <= 0.0:
		queue_free()
