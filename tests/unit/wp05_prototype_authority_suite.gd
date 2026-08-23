@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const CATALOGUE: WP05PrototypeCatalogue = preload(
	"res://data/interventions/prototypes/wp05_prototype_catalogue.tres"
)
const JAX_SCENE: PackedScene = preload("res://scenes/actors/jax.tscn")
const ZOEY_SCENE: PackedScene = preload("res://scenes/actors/zoey.tscn")
const STREET_SCENE: PackedScene = preload("res://scenes/actors/street_punk.tscn")
const BAT_SCENE: PackedScene = preload("res://scenes/actors/bat_thug.tscn")
const BOTTLE_SCENE: PackedScene = preload("res://scenes/actors/bottle_thrower.tscn")
const ENFORCER_SCENE: PackedScene = preload("res://scenes/actors/viper_enforcer.tscn")
const VIPER_SCENE: PackedScene = preload("res://scenes/actors/the_viper.tscn")
const HYDRANT_TUNING: FireHydrantTuning = preload(
	"res://data/interventions/milestone_2_fire_hydrant_tuning.tres"
)


class BackupHarness extends RefCounted:
	var host: Node
	var fail_spawn: bool = false
	var fail_registration: bool = false
	var removed_count: int = 0

	func spawn_ally(_token: int, ally_index: int) -> Node2D:
		if fail_spawn and ally_index == 1:
			return null
		var ally: Node2D = Node2D.new()
		ally.name = "WP05Backup%d" % ally_index
		return ally

	func register_ally(ally: Node2D) -> bool:
		if fail_registration:
			return false
		host.add_child(ally)
		return true

	func remove_ally(ally: Node2D, _reason: StringName) -> void:
		removed_count += 1
		if ally != null and is_instance_valid(ally) and not ally.is_queued_for_deletion():
			ally.queue_free()


func suite_name() -> String:
	return "wp05_prototype_authority"


func test_prototype_catalogue_is_bounded_typed_and_development_only() -> void:
	assert_true(CATALOGUE != null, "catalogue: prototype resource loads")
	assert_eq(CATALOGUE.validation_errors(), PackedStringArray(), "catalogue: every definition validates")
	assert_eq(
		CATALOGUE.get_stable_action_ids(),
		[&"wp05_proto_focus_priority", &"wp05_proto_hanging_sign", &"wp05_proto_power_box", &"wp05_proto_rally_reposition"],
		"catalogue: exactly four bounded candidate definitions"
	)
	assert_eq(
		CATALOGUE.get_stable_scenario_ids(),
		[
			&"wp05_proto_scenario_boss_defense",
			&"wp05_proto_scenario_early_control",
			&"wp05_proto_scenario_elite_interrupt",
			&"wp05_proto_scenario_middle_ranged",
		],
		"catalogue: exact early/middle/elite/boss matrix"
	)
	var actor_ids: Dictionary[StringName, bool] = {}
	for scenario: WP05PrototypeScenarioDefinition in CATALOGUE.scenario_definitions:
		for actor_id: StringName in scenario.expected_enemy_ids:
			actor_ids[actor_id] = true
	var stable_actor_ids: Array[StringName] = []
	for actor_id: StringName in actor_ids:
		stable_actor_ids.append(actor_id)
	stable_actor_ids.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	assert_eq(
		stable_actor_ids,
		[&"bat_thug", &"bottle_thrower", &"street_punk", &"the_viper", &"viper_enforcer"],
		"catalogue: matrix combines only the existing five enemy roles"
	)
	for action: WP05PrototypeActionDefinition in CATALOGUE.action_definitions:
		assert_true(action.id.begins_with("wp05_proto_"), "catalogue: prototype prefix prevents release identity confusion")
		assert_false(action.strong_case.is_empty(), "catalogue: strong case documented")
		assert_false(action.weak_case.is_empty(), "catalogue: weak case documented")
		assert_false(action.invalid_case.is_empty(), "catalogue: invalid case documented")
		assert_false(action.hold_case.is_empty(), "catalogue: hold case documented")
		assert_false(action.counter_case.is_empty(), "catalogue: counter case documented")


func test_contextual_environment_replaces_one_slot_and_rejects_stale_or_invalid_requests() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_middle_ranged", &"jax", []), "environment: middle scenario begins")
	var snapshot: Dictionary = runtime.get_snapshot().environment
	assert_eq(snapshot.action_id, &"wp05_proto_power_box", "environment: one contextual action replaces Hydrant")
	assert_eq(snapshot.target_count, 0, "environment: no target starts invalid")
	var invalid: Dictionary = runtime.request_current_environment()
	assert_false(invalid.accepted, "environment: no-target request rejects")
	assert_eq(invalid.reason, WP05PrototypeRuntime.REASON_NO_TARGET, "environment: exact no-target reason")
	assert_eq(runtime.get_snapshot().environment.cooldown_remaining, 0.0, "environment: invalid request spends no cooldown")

	var enemy: ActorController = _spawn_actor(harness.host, BOTTLE_SCENE, Vector2(430.0, 226.0))
	assert_true(harness.director.register_actor(enemy), "environment: target registers")
	runtime.step_eligible_time(0.01)
	var current: Dictionary = runtime.get_snapshot().environment
	assert_true(current.can_activate, "environment: context becomes valid with one in-range target")
	var stale: Dictionary = runtime.request_environment(
		current.action_id,
		int(current.revision) - 1,
		int(current.request_token)
	)
	assert_false(stale.accepted, "environment: stale revision rejects")
	assert_eq(stale.reason, WP05PrototypeRuntime.REASON_STALE, "environment: stale reason")
	assert_eq(runtime.get_snapshot().environment.cooldown_remaining, 0.0, "environment: stale request spends nothing")


func test_power_box_interrupts_a_readable_threat_and_shared_cooldown_prevents_spam() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	var crew: ActorController = _spawn_actor(harness.host, JAX_SCENE, Vector2(300.0, 226.0))
	var enemy: ActorController = _spawn_actor(harness.host, ENFORCER_SCENE, Vector2(430.0, 226.0))
	assert_true(harness.director.register_actor(crew), "power box: crew registers")
	assert_true(harness.director.register_actor(enemy), "power box: elite registers")
	assert_true(enemy.assign_target(crew), "power box: elite target assigns")
	var charge: AttackDefinition = _attack_by_id(enemy, &"viper_enforcer_charge")
	assert_true(charge != null, "power box: authored charge exists")
	enemy._start_planned_attack(charge)
	assert_eq(enemy.state_machine.current_state, ActorStateMachine.State.ATTACK_WINDUP, "power box: charge enters readable windup")
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_elite_interrupt", &"jax", []), "power box: elite scenario begins")
	var before_health: int = enemy.health_component.current_health
	var request: Dictionary = runtime.request_current_environment()
	assert_true(request.accepted, "power box: valid breaker request accepts")
	assert_eq(request.result.interrupted_count, 1, "power box: charge is interrupted")
	assert_eq(enemy.state_machine.current_state, ActorStateMachine.State.STUNNED, "power box: elite enters resisted stun")
	assert_true(enemy.has_status(&"shock"), "power box: existing Shock status marks the target")
	assert_eq(before_health - enemy.health_component.current_health, 4, "power box: exact low damage preserves control role")
	assert_eq(runtime.get_snapshot().environment.cooldown_remaining, 12.0, "power box: exact shared Environment cooldown")
	var replay: Dictionary = runtime.request_environment(
		request.action_id,
		int(runtime.get_snapshot().environment.revision) - 1,
		int(runtime.get_snapshot().environment.request_token) - 1
	)
	assert_false(replay.accepted, "power box: consumed transaction cannot repeat")
	assert_true(replay.reason in [WP05PrototypeRuntime.REASON_REPLAYED, WP05PrototypeRuntime.REASON_STALE], "power box: replay is explicitly rejected")


func test_hanging_sign_is_one_charge_high_burst_and_exposes_dominance_risk() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	var boss: ActorController = _spawn_actor(harness.host, VIPER_SCENE, Vector2(420.0, 226.0))
	assert_true(harness.director.register_actor(boss), "sign: boss registers")
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_boss_defense", &"rex", []), "sign: boss scenario begins")
	var before_health: int = boss.health_component.current_health
	var result: Dictionary = runtime.request_current_environment()
	assert_true(result.accepted, "sign: one valid drop accepts")
	assert_eq(before_health - boss.health_component.current_health, 65, "sign: exact high burst lands")
	assert_eq(runtime.get_snapshot().environment.charges_remaining, 0, "sign: single charge is spent")
	assert_eq(runtime.get_snapshot().environment.validity_reason, WP05PrototypeRuntime.REASON_EXHAUSTED, "sign: slot names exhaustion")
	var second: Dictionary = runtime.request_current_environment()
	assert_false(second.accepted, "sign: second drop rejects")
	assert_eq(second.reason, WP05PrototypeRuntime.REASON_EXHAUSTED, "sign: exact exhaustion reason")


func test_focus_uses_one_press_context_targeting_without_direct_attack_control() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	var crew: ActorController = _spawn_actor(harness.host, ZOEY_SCENE, Vector2(300.0, 226.0))
	var ordinary: ActorController = _spawn_actor(harness.host, STREET_SCENE, Vector2(320.0, 226.0))
	var thrower: ActorController = _spawn_actor(harness.host, BOTTLE_SCENE, Vector2(360.0, 226.0))
	assert_true(harness.director.register_actor(crew), "focus: crew registers")
	assert_true(harness.director.register_actor(ordinary), "focus: ordinary enemy registers")
	assert_true(harness.director.register_actor(thrower), "focus: thrower registers")
	assert_true(crew.assign_target(ordinary), "focus: crew begins on ordinary target")
	assert_true(thrower.assign_target(crew), "focus: thrower target assigns")
	thrower._start_planned_attack(thrower.attack_definition)
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_middle_ranged", &"zoey", []), "focus: ranged scenario begins")
	var snapshot: Dictionary = runtime.get_snapshot().focus
	assert_eq(snapshot.target_id, &"bottle_thrower", "focus: authority names current threat")
	assert_eq(snapshot.attack_id, &"bottle_throw", "focus: authority names intent")
	assert_true(snapshot.window_seconds >= 0.35, "focus: readable decision window remains")
	var accepted: Dictionary = runtime.request_current_focus()
	assert_true(accepted.accepted, "focus: one contextual press accepts")
	assert_eq(crew.current_target, thrower, "focus: available automatic crew retargets")
	assert_eq(accepted.result.retargeted_count, 1, "focus: retarget result is explicit")
	assert_eq(runtime.get_snapshot().focus.cooldown_remaining, 10.0, "focus: exact provisional cooldown")
	assert_true(thrower.attack_controller.is_attacking(), "focus: priority does not directly cancel the enemy attack")


func test_focus_invalid_window_target_death_expiry_and_replay_are_lossless() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	var crew: ActorController = _spawn_actor(harness.host, JAX_SCENE, Vector2(300.0, 226.0))
	var thrower: ActorController = _spawn_actor(harness.host, BOTTLE_SCENE, Vector2(360.0, 226.0))
	assert_true(harness.director.register_actor(crew), "focus lifecycle: crew registers")
	assert_true(harness.director.register_actor(thrower), "focus lifecycle: target registers")
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_middle_ranged", &"jax", []), "focus lifecycle: scenario begins")
	var invalid: Dictionary = runtime.request_current_focus()
	assert_false(invalid.accepted, "focus lifecycle: no-windup request rejects")
	assert_eq(invalid.reason, WP05PrototypeRuntime.REASON_NO_TARGET, "focus lifecycle: no-target reason")
	assert_eq(runtime.get_snapshot().focus.cooldown_remaining, 0.0, "focus lifecycle: invalid request spends no cooldown")
	assert_true(thrower.assign_target(crew), "focus lifecycle: enemy target assigns")
	thrower._start_planned_attack(thrower.attack_definition)
	runtime.step_eligible_time(0.01)
	var accepted_snapshot: Dictionary = runtime.get_snapshot().focus
	var accepted: Dictionary = runtime.request_current_focus()
	assert_true(accepted.accepted, "focus lifecycle: valid focus accepts")
	var replay: Dictionary = runtime.request_focus(
		int(accepted_snapshot.target_instance_id),
		StringName(accepted_snapshot.attack_id),
		int(accepted_snapshot.revision),
		int(accepted_snapshot.request_token)
	)
	assert_false(replay.accepted, "focus lifecycle: exact token replay rejects")
	assert_eq(replay.reason, WP05PrototypeRuntime.REASON_REPLAYED, "focus lifecycle: replay reason")
	thrower.receive_damage(9999)
	runtime.step_eligible_time(0.1)
	assert_eq(runtime.get_snapshot().focus.active_target_instance_id, -1, "focus lifecycle: target death clears priority")
	runtime.step_eligible_time(9.9)
	assert_eq(runtime.get_snapshot().focus.cooldown_remaining, 0.0, "focus lifecycle: eligible time completes cooldown")


func test_rally_repositions_at_an_area_warning_but_costs_attack_uptime() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	var crew: ActorController = _spawn_actor(harness.host, JAX_SCENE, Vector2(400.0, 226.0))
	var boss: ActorController = _spawn_actor(harness.host, VIPER_SCENE, Vector2(420.0, 226.0))
	assert_true(harness.director.register_actor(crew), "rally: crew registers")
	assert_true(harness.director.register_actor(boss), "rally: boss registers")
	assert_true(crew.assign_target(boss), "rally: crew begins attacking")
	assert_true(boss.assign_target(crew), "rally: boss target assigns")
	var area: AttackDefinition = _attack_by_id(boss, &"viper_area_warning")
	boss._start_planned_attack(area)
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_boss_defense", &"jax", []), "rally: boss scenario begins")
	var start_position: Vector2 = crew.global_position
	var request_snapshot: Dictionary = runtime.get_snapshot().rally
	var accepted: Dictionary = runtime.request_current_rally()
	assert_true(accepted.accepted, "rally: area-warning response accepts")
	var replay: Dictionary = runtime.request_rally(
		int(request_snapshot.target_instance_id),
		StringName(request_snapshot.attack_id),
		int(request_snapshot.revision),
		int(request_snapshot.request_token)
	)
	assert_false(replay.accepted, "rally: exact token replay rejects")
	assert_eq(replay.reason, WP05PrototypeRuntime.REASON_REPLAYED, "rally: replay reason")
	runtime.step_eligible_time(1.1)
	assert_true(crew.global_position.x < start_position.x - 100.0, "rally: crew retreats materially")
	assert_eq(crew.current_target, null, "rally: attack target is sacrificed during retreat")
	assert_eq(runtime.get_snapshot().rally.cooldown_remaining, 16.9, "rally: long cooldown advances only by eligible time")
	assert_true(runtime.get_telemetry_snapshot().results.has(&"completed"), "rally: displacement result is recorded")


func test_backup_gate_preserves_finite_authority_and_rejects_replay() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_elite_interrupt", &"rex", []), "backup: elite scenario begins")
	harness.backup.set_simulation_enabled(true)
	harness.backup.set_combat_available(true)
	runtime.set_simulation_enabled(true)
	runtime.set_combat_available(true)
	var snapshot: Dictionary = runtime.get_snapshot().backup
	assert_true(snapshot.can_activate, "backup: finite authority is ready")
	var accepted: Dictionary = runtime.request_current_backup()
	assert_true(accepted.accepted, "backup: gated request accepts")
	assert_eq(accepted.result.active_ally_count, 2, "backup: existing authority creates exactly two allies")
	assert_eq(accepted.result.charges_remaining, 1, "backup: exactly one finite charge spent")
	var replay: Dictionary = runtime.request_backup(int(snapshot.revision), int(snapshot.request_token))
	assert_false(replay.accepted, "backup: exact request token cannot replay")
	assert_eq(replay.reason, WP05PrototypeRuntime.REASON_REPLAYED, "backup: replay reason is explicit")
	assert_eq(harness.backup.get_charges_remaining(), 1, "backup: replay spends nothing")


func test_backup_late_use_has_negligible_expression_and_makes_holding_better() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_early_control", &"jax", []), "backup hold: scenario begins")
	harness.backup.set_simulation_enabled(true)
	harness.backup.set_combat_available(true)
	runtime.set_simulation_enabled(true)
	runtime.set_combat_available(true)
	var accepted: Dictionary = runtime.request_current_backup()
	assert_true(accepted.accepted, "backup hold: late request can still accept")
	harness.backup.step_eligible_time(0.1)
	var expressed_seconds: float = 12.0 - harness.backup.get_active_duration_remaining()
	assert_true(expressed_seconds <= 0.1001, "backup hold: terminal after 0.1s yields negligible ally expression")
	harness.backup.cleanup_for_terminal_state()
	assert_eq(harness.backup.get_charges_remaining(), 1, "backup hold: terminal cleanup does not refund the finite charge")
	assert_eq(harness.backup.get_active_allies().size(), 0, "backup hold: terminal removes both allies")
	assert_true(harness.backup.get_cooldown_remaining() > 29.8, "backup hold: almost the full cooldown remains")


func test_pause_terminal_restart_and_random_stream_isolation_are_explicit() -> void:
	var harness: Dictionary = _new_harness()
	var runtime: WP05PrototypeRuntime = harness.runtime
	var enemy: ActorController = _spawn_actor(harness.host, STREET_SCENE, Vector2(410.0, 226.0))
	assert_true(harness.director.register_actor(enemy), "boundaries: environment target registers")
	assert_true(runtime.begin_scenario(&"wp05_proto_scenario_early_control", &"jax", []), "boundaries: scenario begins")
	var accepted: Dictionary = runtime.request_current_environment()
	assert_true(accepted.accepted, "boundaries: Hydrant adapter accepts")
	var cooldown: float = float(runtime.get_snapshot().environment.cooldown_remaining)
	runtime.set_simulation_enabled(false)
	runtime.step_eligible_time(4.0)
	assert_eq(runtime.get_snapshot().environment.cooldown_remaining, cooldown, "boundaries: pause freezes prototype cooldown")
	runtime.cleanup_for_terminal_state()
	assert_false(runtime.get_snapshot().simulation_enabled, "boundaries: terminal disables simulation")
	assert_eq(runtime.get_snapshot().focus.active_target_instance_id, -1, "boundaries: terminal clears Focus")
	runtime.reset_for_run()
	assert_false(runtime.get_snapshot().enabled, "boundaries: restart removes scenario context")
	var source: String = FileAccess.get_file_as_string("res://scripts/interventions/wp05_prototype_runtime.gd")
	for forbidden: String in ["randi(", "randf(", "randomize(", ".shuffle(", ".pick_random("]:
		assert_false(source.contains(forbidden), "boundaries: prototype runtime has no unseeded gameplay RNG %s" % forbidden)
	var telemetry: Dictionary = runtime.get_telemetry_snapshot()
	assert_true(bool(telemetry.development_only), "boundaries: telemetry labels itself development-only")
	assert_false(bool(telemetry.authoritative), "boundaries: telemetry labels itself non-authoritative")


func _new_harness() -> Dictionary:
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	assert_true(scene_tree != null, "harness: SceneTree exists")
	var host: Node2D = track(Node2D.new()) as Node2D
	host.name = "WP05PrototypeHarness"
	host.process_mode = Node.PROCESS_MODE_DISABLED
	scene_tree.root.add_child(host)

	var director: CombatDirector = CombatDirector.new()
	host.add_child(director)
	director.set_physics_process(false)
	director.set_simulation_enabled(false)
	var hydrant: FireHydrantController = FireHydrantController.new()
	hydrant.tuning = HYDRANT_TUNING
	host.add_child(hydrant)
	hydrant.set_process(false)
	hydrant.configure(director, Vector2(410.0, 239.0))
	var backup: CallBackupController = CallBackupController.new()
	host.add_child(backup)
	backup.set_process(false)
	var backup_harness: BackupHarness = BackupHarness.new()
	backup_harness.host = host
	backup.configure(
		Callable(backup_harness, "spawn_ally"),
		Callable(backup_harness, "register_ally"),
		Callable(backup_harness, "remove_ally")
	)
	var encounters: RunEncounterController = RunEncounterController.new()
	host.add_child(encounters)
	encounters.set_process(false)
	encounters._combat_director = director
	var runtime: WP05PrototypeRuntime = WP05PrototypeRuntime.new()
	host.add_child(runtime)
	assert_true(runtime.configure(director, hydrant, backup, encounters), "harness: runtime configures")
	return {
		"host": host,
		"director": director,
		"hydrant": hydrant,
		"backup": backup,
		"backup_harness": backup_harness,
		"encounters": encounters,
		"runtime": runtime,
	}


func _spawn_actor(host: Node, scene: PackedScene, world_position: Vector2) -> ActorController:
	var actor: ActorController = scene.instantiate() as ActorController
	assert_true(actor != null, "actor: scene instantiates")
	host.add_child(actor)
	actor.set_process(false)
	actor.set_physics_process(false)
	actor.global_position = actor.get_combat_space().clamp_actor_position(world_position)
	return actor


func _attack_by_id(actor: ActorController, attack_id: StringName) -> AttackDefinition:
	if actor.attack_definition != null and actor.attack_definition.id == attack_id:
		return actor.attack_definition
	for attack: AttackDefinition in actor.special_attack_definitions:
		if attack != null and attack.id == attack_id:
			return attack
	return null
