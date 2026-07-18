@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const JAX_DEFINITION: ActorDefinition = preload("res://data/crew/jax.tres")
const STREET_PUNK_DEFINITION: ActorDefinition = preload("res://data/enemies/street_punk.tres")
const JAX_ATTACK: AttackDefinition = preload("res://data/attacks/jax_basic_punch.tres")
const STREET_PUNK_ATTACK: AttackDefinition = preload("res://data/attacks/street_punk_basic_punch.tres")


func suite_name() -> String:
	return "milestone_1_combat_director"


func test_target_validity_dead_invalidation_and_reacquisition() -> void:
	var director: CombatDirector = _new_director()
	var jax: ActorController = _new_actor(true, 200.0, 1)
	var near_enemy: ActorController = _new_actor(false, 260.0, 1)
	var far_enemy: ActorController = _new_actor(false, 420.0, 2)
	var other_crew: ActorController = _new_actor(true, 230.0, 0)
	director.register_actor(jax)
	director.register_actor(far_enemy)
	director.register_actor(near_enemy)
	director.register_actor(other_crew)

	jax.step_simulation(0.01)
	_expect_equal(
		jax.current_target,
		near_enemy,
		"targeting: nearest valid enemy wins independent of registration order"
	)
	_expect_false(director.is_valid_target(jax, jax), "targeting: actor cannot target itself")
	_expect_false(
		director.is_valid_target(jax, other_crew),
		"targeting: same-team actors are invalid"
	)

	near_enemy.state_machine.force_initial_state(ActorStateMachine.State.DEAD)
	_expect_false(
		director.is_valid_target(jax, near_enemy),
		"targeting: dead enemy is invalid synchronously"
	)
	director.unregister_actor(near_enemy, false)
	_expect_equal(jax.current_target, null, "targeting: dead enemy cannot remain selected")
	_expect_equal(
		director.get_reservation_snapshot().size(),
		0,
		"targeting: dead target releases reservations"
	)

	jax.step_simulation(0.01)
	_expect_equal(jax.current_target, far_enemy, "targeting: next step reacquires remaining enemy")
	_expect_true(director.is_valid_target(jax, far_enemy), "targeting: replacement target is valid")


func test_knockback_interrupts_attack_moves_and_releases_position() -> void:
	var director: CombatDirector = _new_director()
	var jax: ActorController = _new_actor(true, 220.0, 1)
	var enemy: ActorController = _new_actor(false, 260.0, 1)
	director.register_actor(jax)
	director.register_actor(enemy)
	jax.assign_target(enemy)
	_expect_true(director.reserve_attack_position(jax, enemy), "knockback: position is reserved")
	jax.attack_controller.start_attack(jax.attack_definition)
	jax.state_machine.transition_to(ActorStateMachine.State.ATTACK_WINDUP)
	var starting_x: float = jax.global_position.x

	jax.apply_knockback(1.0, 120.0, 0.10)
	_expect_equal(
		jax.state_machine.current_state,
		ActorStateMachine.State.KNOCKED_BACK,
		"knockback: state interrupts windup"
	)
	_expect_false(jax.attack_controller.is_attacking(), "knockback: attack timeline is cancelled")
	_expect_false(director.has_attack_position(jax), "knockback: reservation is released")
	jax.step_simulation(0.05)
	_expect_true(jax.global_position.x > starting_x, "knockback: actor moves visibly")
	jax.step_simulation(0.05)
	_expect_equal(
		jax.state_machine.current_state,
		ActorStateMachine.State.APPROACHING_TARGET,
		"knockback: actor returns to ordinary combat state"
	)


func test_repeated_registration_cleanup_has_no_stale_target_or_reservation() -> void:
	var director: CombatDirector = _new_director()
	var jax: ActorController = _new_actor(true, 220.0, 1)
	director.register_actor(jax)
	for cycle: int in range(20):
		var enemy: ActorController = _new_actor(false, 260.0, cycle % 3)
		_expect_true(director.register_actor(enemy), "cleanup: cycle %d registers" % cycle)
		_expect_true(jax.assign_target(enemy), "cleanup: cycle %d assigns target" % cycle)
		_expect_true(
			director.reserve_attack_position(jax, enemy),
			"cleanup: cycle %d reserves position" % cycle
		)
		enemy.state_machine.force_initial_state(ActorStateMachine.State.DEAD)
		_expect_false(
			director.is_valid_target(jax, enemy),
			"cleanup: cycle %d marks dead target invalid" % cycle
		)
		_expect_true(director.unregister_actor(enemy, false), "cleanup: cycle %d unregisters" % cycle)
		_expect_equal(director.get_registered_count(), 1, "cleanup: cycle %d retains only Jax" % cycle)
		_expect_equal(jax.current_target, null, "cleanup: cycle %d clears stale target" % cycle)
		_expect_equal(
			director.get_reservation_snapshot().size(),
			0,
			"cleanup: cycle %d clears stale reservation" % cycle
		)
	_expect_equal(
		director.get_live_counts(),
		{"crew": 1, "enemies": 0, "registered": 1},
		"cleanup: repeated lifecycle leaves only Jax"
	)


func _new_director() -> CombatDirector:
	var director: CombatDirector = track(CombatDirector.new()) as CombatDirector
	director._ready()
	director.set_physics_process(false)
	return director


func _new_actor(is_crew: bool, world_x: float, lane: int) -> ActorController:
	var actor: ActorController = track(ActorController.new()) as ActorController
	actor.actor_definition = JAX_DEFINITION if is_crew else STREET_PUNK_DEFINITION
	actor.attack_definition = JAX_ATTACK if is_crew else STREET_PUNK_ATTACK
	actor.team = ActorController.Team.CREW if is_crew else ActorController.Team.ENEMY
	actor.initial_lane = lane
	actor.lane_index = lane
	actor.position = Vector2(world_x, ActorController.lane_y(lane))
	actor.state_machine = ActorStateMachine.new()
	actor.health_component = HealthComponent.new()
	actor.attack_controller = AttackController.new()
	actor.attack_hitbox = Area2D.new()
	actor.actor_visual = ActorVisual.new()
	actor.add_child(actor.state_machine)
	actor.add_child(actor.health_component)
	actor.add_child(actor.attack_controller)
	actor.add_child(actor.attack_hitbox)
	actor.add_child(actor.actor_visual)
	actor.initialize_runtime()
	return actor


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)
