extends SceneTree

const FIXED_STEP: float = 1.0 / 60.0
const PROBE_SECONDS: float = 6.0
const LATE_BACKUP_AT: float = 5.8
const HYDRANT_ORIGIN: Vector2 = Vector2(410.0, 239.0)
const POWER_BOX_ORIGIN: Vector2 = Vector2(370.0, 226.0)
const HYDRANT_TUNING: FireHydrantTuning = preload(
	"res://data/interventions/milestone_2_fire_hydrant_tuning.tres"
)
const POWER_BOX: PowerBoxDefinition = preload("res://data/interventions/wp05_power_box.tres")
const FOCUS: FocusDefinition = preload("res://data/interventions/wp05_focus.tres")
const CREW_SCENES: Dictionary[StringName, PackedScene] = {
	&"jax": preload("res://scenes/actors/jax.tscn"),
	&"zoey": preload("res://scenes/actors/zoey.tscn"),
	&"rex": preload("res://scenes/actors/rex.tscn"),
}
const ENEMY_SCENES: Dictionary[StringName, PackedScene] = {
	&"street_punk": preload("res://scenes/actors/street_punk.tscn"),
	&"bat_thug": preload("res://scenes/actors/bat_thug.tscn"),
	&"bottle_thrower": preload("res://scenes/actors/bottle_thrower.tscn"),
	&"viper_enforcer": preload("res://scenes/actors/viper_enforcer.tscn"),
	&"the_viper": preload("res://scenes/actors/the_viper.tscn"),
}
const BACKUP_SCENE: PackedScene = preload("res://scenes/actors/backup_runner.tscn")
const SCENARIOS: Dictionary[StringName, Dictionary] = {
	&"early_control": {
		"environment": &"fire_hydrant",
		"enemies": [&"bat_thug", &"street_punk", &"street_punk"],
	},
	&"middle_ranged": {
		"environment": &"power_box",
		"enemies": [&"bottle_thrower", &"bottle_thrower", &"street_punk"],
	},
	&"elite_interrupt": {
		"environment": &"power_box",
		"enemies": [&"viper_enforcer", &"bottle_thrower", &"bat_thug"],
	},
	&"boss_defense": {
		"environment": &"power_box",
		"enemies": [&"the_viper"],
	},
}
const POLICIES: Array[StringName] = [
	&"hold",
	&"environment",
	&"focus",
	&"backup",
	&"late_backup",
]
const CREW_BUILD_IDS: Dictionary[StringName, Array] = {
	&"jax": [&"spiked_bat", &"steel_toe_boots", &"chain_sneakers"],
	&"zoey": [&"shock_gloves", &"hacker_deck", &"magnetic_flail"],
	&"rex": [&"reinforced_jacket", &"serrated_wraps", &"voltaic_blade"],
}


class BackupFactory extends RefCounted:
	var host: Node2D
	var director: CombatDirector
	var next_x: float = 280.0

	func create(_token: int, ally_index: int) -> Node2D:
		var ally: ActorController = BACKUP_SCENE.instantiate() as ActorController
		ally.global_position = Vector2(next_x + float(ally_index) * 18.0, 226.0)
		return ally

	func register(ally_node: Node2D) -> bool:
		var ally: ActorController = ally_node as ActorController
		if ally == null:
			return false
		host.add_child(ally)
		ally.set_process(false)
		ally.set_physics_process(false)
		return director.register_actor(ally)

	func remove(ally_node: Node2D, _reason: StringName) -> void:
		var ally: ActorController = ally_node as ActorController
		if ally != null and is_instance_valid(ally):
			director.unregister_actor(ally)
			ally.queue_free()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var matrix: Array[Dictionary] = []
	for scenario_id: StringName in _stable_scenario_ids():
		for crew_id: StringName in [&"jax", &"zoey", &"rex"]:
			for policy: StringName in POLICIES:
				matrix.append(await _run_variant(scenario_id, crew_id, policy, 0))
	var repeat_a: Dictionary = await _run_variant(&"elite_interrupt", &"zoey", &"focus", 0)
	var repeat_b: Dictionary = await _run_variant(&"elite_interrupt", &"zoey", &"focus", 0)
	var cosmetic: Dictionary = await _run_variant(&"elite_interrupt", &"zoey", &"focus", 50)
	var repeatable: bool = _gameplay_projection(repeat_a) == _gameplay_projection(repeat_b)
	var cosmetic_isolated: bool = _gameplay_projection(repeat_a) == _gameplay_projection(cosmetic)
	var compact: Array[Dictionary] = _compact_matrix(matrix)
	var dominance: Dictionary = _dominance_summary(matrix)
	var coverage: Dictionary = _coverage_summary(matrix)
	print("WP05_PRODUCTION_COMPACT=" + JSON.stringify(compact))
	print("WP05_PRODUCTION_DOMINANCE=" + JSON.stringify(dominance))
	print("WP05_PRODUCTION_COVERAGE=" + JSON.stringify(coverage))
	print("WP05_PRODUCTION_REPEATABLE=%s" % repeatable)
	print("WP05_PRODUCTION_COSMETIC_ISOLATED=%s" % cosmetic_isolated)
	print("WP05_PRODUCTION_MATRIX_SUMMARY=%d rows, %d crews, %d contexts, %d policies" % [
		matrix.size(), 3, SCENARIOS.size(), POLICIES.size(),
	])
	var passed: bool = (
		repeatable
		and cosmetic_isolated
		and matrix.size() == 60
		and int(coverage.get("environment_accepted", 0)) > 0
		and int(coverage.get("focus_accepted", 0)) > 0
		and int(coverage.get("backup_accepted", 0)) == 12
		and int(coverage.get("late_backup_accepted", 0)) == 12
	)
	quit(0 if passed else 1)


func _run_variant(
	scenario_id: StringName,
	crew_id: StringName,
	policy: StringName,
	cosmetic_draws: int
) -> Dictionary:
	var scenario: Dictionary = SCENARIOS.get(scenario_id, {})
	var host: Node2D = Node2D.new()
	host.name = "WP05Matrix_%s_%s_%s" % [scenario_id, crew_id, policy]
	host.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(host)
	var streams: RunRandomStreams = RunRandomStreams.new()
	host.add_child(streams)
	streams.reset_for_seed(505000 + _stable_scenario_ids().find(scenario_id) * 100 + [&"jax", &"zoey", &"rex"].find(crew_id))
	for _draw: int in range(cosmetic_draws):
		streams.draw_index(RunRandomStreams.STREAM_COSMETIC, 1000)
	var build: SynergySystem = SynergySystem.new()
	host.add_child(build)
	for equipment_id: StringName in _build_ids_for(crew_id):
		if not build.equip_by_id(equipment_id):
			return await _failed_row(host, scenario_id, crew_id, policy, "build_failed")
	var director: CombatDirector = CombatDirector.new()
	host.add_child(director)
	director.set_process(false)
	director.set_physics_process(false)
	director.configure_build_system(build, streams)
	director.set_simulation_enabled(true)
	var hydrant: FireHydrantController = FireHydrantController.new()
	hydrant.tuning = HYDRANT_TUNING
	host.add_child(hydrant)
	hydrant.set_process(false)
	hydrant.configure(director, HYDRANT_ORIGIN)
	hydrant.set_simulation_enabled(true)
	var environment: EnvironmentController = EnvironmentController.new()
	environment.power_box_definition = POWER_BOX
	host.add_child(environment)
	environment.set_process(false)
	environment.configure(director, hydrant, HYDRANT_ORIGIN, POWER_BOX_ORIGIN)
	environment.set_simulation_enabled(true)
	environment.set_combat_available(true)
	environment.set_context_action(StringName(scenario.get("environment", &"")))
	var focus: FocusController = FocusController.new()
	focus.definition = FOCUS
	host.add_child(focus)
	focus.set_process(false)
	focus.configure(director)
	focus.set_simulation_enabled(true)
	focus.set_combat_available(true)
	var backup: CallBackupController = CallBackupController.new()
	host.add_child(backup)
	backup.set_process(false)
	var backup_factory: BackupFactory = BackupFactory.new()
	backup_factory.host = host
	backup_factory.director = director
	backup.configure(
		Callable(backup_factory, "create"),
		Callable(backup_factory, "register"),
		Callable(backup_factory, "remove")
	)
	backup.set_simulation_enabled(true)
	backup.set_combat_available(true)
	var crew: ActorController = CREW_SCENES[crew_id].instantiate() as ActorController
	host.add_child(crew)
	crew.set_process(false)
	crew.set_physics_process(false)
	crew.global_position = Vector2(290.0, 226.0)
	director.register_actor(crew)
	var enemies: Array[ActorController] = []
	var enemy_ids: Array = scenario.get("enemies", []) as Array
	for index: int in range(enemy_ids.size()):
		var enemy_id: StringName = StringName(enemy_ids[index])
		var enemy: ActorController = ENEMY_SCENES[enemy_id].instantiate() as ActorController
		host.add_child(enemy)
		enemy.set_process(false)
		enemy.set_physics_process(false)
		enemy.global_position = _enemy_position(scenario_id, index)
		director.register_actor(enemy)
		enemies.append(enemy)
	var cooldown_multiplier: float = maxf(
		crew.get_intervention_cooldown_multiplier()
		* (1.0 + build.get_percent_modifier(&"intervention_cooldown")),
		0.05
	)
	environment.set_cooldown_multiplier(cooldown_multiplier)
	focus.set_cooldown_multiplier(cooldown_multiplier)
	backup.set_cooldown_multiplier(cooldown_multiplier)
	var action_attempted: bool = false
	var action_accepted: bool = false
	var action_reason: StringName = &"held"
	var elapsed: float = 0.0
	var frames: int = ceili(PROBE_SECONDS / FIXED_STEP)
	for _frame: int in range(frames):
		director.step_simulation(FIXED_STEP)
		hydrant.step_cooldown(FIXED_STEP)
		environment.step_eligible_time(FIXED_STEP)
		focus.step_eligible_time(FIXED_STEP)
		backup.step_eligible_time(FIXED_STEP)
		elapsed += FIXED_STEP
		if not action_attempted:
			var attempt: Dictionary = _try_policy(policy, elapsed, environment, focus, backup)
			if not attempt.is_empty():
				action_attempted = true
				action_accepted = bool(attempt.get("accepted", false))
				action_reason = StringName(attempt.get("reason", &"rejected"))
	var enemy_health: int = 0
	var enemy_maximum: int = 0
	var enemies_defeated: int = 0
	for enemy: ActorController in enemies:
		enemy_health += maxi(enemy.health_component.current_health, 0)
		enemy_maximum += enemy.health_component.maximum_health
		if enemy.health_component.is_depleted():
			enemies_defeated += 1
	var draw_snapshot: Dictionary = streams.get_debug_snapshot().get("draw_counts", {})
	var gameplay_draws: Dictionary = {}
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		if stream_name != RunRandomStreams.STREAM_COSMETIC:
			gameplay_draws[stream_name] = int(draw_snapshot.get(stream_name, 0))
	var row: Dictionary = {
		"scenario_id": scenario_id,
		"context_id": scenario.get("environment", &""),
		"crew_id": crew_id,
		"build_ids": _build_ids_for(crew_id),
		"policy": policy,
		"action_attempted": action_attempted,
		"action_accepted": action_accepted,
		"action_reason": action_reason,
		"crew_health": maxi(crew.health_component.current_health, 0),
		"crew_maximum": crew.health_component.maximum_health,
		"enemy_health": enemy_health,
		"enemy_maximum": enemy_maximum,
		"enemies_defeated": enemies_defeated,
		"backup_charges": backup.get_charges_remaining(),
		"backup_expression": 12.0 - backup.get_active_duration_remaining() if action_accepted and policy in [&"backup", &"late_backup"] else 0.0,
		"gameplay_draws": gameplay_draws,
		"cosmetic_draws": cosmetic_draws,
	}
	backup.cleanup_for_terminal_state()
	environment.cleanup_for_terminal_state()
	focus.cleanup_for_terminal_state()
	director.clear_all(false)
	host.free()
	await process_frame
	return row


func _try_policy(
	policy: StringName,
	elapsed: float,
	environment: EnvironmentController,
	focus: FocusController,
	backup: CallBackupController
) -> Dictionary:
	match policy:
		&"environment":
			if environment.can_activate():
				var snapshot: Dictionary = environment.get_snapshot()
				return environment.request_activation(snapshot.action_id, snapshot.context_revision, snapshot.request_token)
		&"focus":
			if focus.can_activate():
				var snapshot: Dictionary = focus.get_snapshot()
				return focus.request_activation(snapshot.target_instance_id, snapshot.attack_id, snapshot.context_revision, snapshot.request_token)
		&"backup":
			if backup.can_activate():
				var snapshot: Dictionary = backup.get_snapshot()
				return {
					"accepted": backup.request_activation(snapshot.request_context_revision, snapshot.request_token),
					"reason": &"ok",
				}
		&"late_backup":
			if elapsed >= LATE_BACKUP_AT and backup.can_activate():
				var snapshot: Dictionary = backup.get_snapshot()
				return {
					"accepted": backup.request_activation(snapshot.request_context_revision, snapshot.request_token),
					"reason": &"ok",
				}
	return {}


func _enemy_position(scenario_id: StringName, index: int) -> Vector2:
	if scenario_id == &"early_control":
		return Vector2(382.0 + float(index) * 26.0, 226.0)
	if scenario_id in [&"middle_ranged", &"elite_interrupt"]:
		return Vector2(350.0 + float(index) * 34.0, 226.0)
	return Vector2(390.0, 226.0)


func _build_ids_for(crew_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in CREW_BUILD_IDS.get(crew_id, []):
		result.append(StringName(value))
	return result


func _stable_scenario_ids() -> Array[StringName]:
	return [&"early_control", &"middle_ranged", &"elite_interrupt", &"boss_defense"]


func _gameplay_projection(row: Dictionary) -> Dictionary:
	return {
		"scenario_id": row.get("scenario_id"),
		"crew_id": row.get("crew_id"),
		"policy": row.get("policy"),
		"action_attempted": row.get("action_attempted"),
		"action_accepted": row.get("action_accepted"),
		"action_reason": row.get("action_reason"),
		"crew_health": row.get("crew_health"),
		"crew_maximum": row.get("crew_maximum"),
		"enemy_health": row.get("enemy_health"),
		"enemy_maximum": row.get("enemy_maximum"),
		"enemies_defeated": row.get("enemies_defeated"),
		"backup_charges": row.get("backup_charges"),
		"backup_expression": row.get("backup_expression"),
		"gameplay_draws": row.get("gameplay_draws"),
	}


func _compact_matrix(matrix: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for scenario_id: StringName in _stable_scenario_ids():
		for crew_id: StringName in [&"jax", &"zoey", &"rex"]:
			var compact: Dictionary = {"scenario_id": scenario_id, "crew_id": crew_id}
			for policy: StringName in POLICIES:
				var row: Dictionary = _find_row(matrix, scenario_id, crew_id, policy)
				compact[policy] = {
					"accepted": bool(row.get("action_accepted", false)),
					"crew_health": int(row.get("crew_health", 0)),
					"enemy_health": int(row.get("enemy_health", 0)),
					"enemies_defeated": int(row.get("enemies_defeated", 0)),
					"backup_expression": float(row.get("backup_expression", 0.0)),
				}
			result.append(compact)
	return result


func _dominance_summary(matrix: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for policy: StringName in [&"environment", &"focus", &"backup", &"late_backup"]:
		var counts: Dictionary = {"accepted": 0, "unavailable": 0, "better_or_equal": 0, "tradeoff": 0, "worse_or_equal": 0, "same": 0}
		for scenario_id: StringName in _stable_scenario_ids():
			for crew_id: StringName in [&"jax", &"zoey", &"rex"]:
				var hold: Dictionary = _find_row(matrix, scenario_id, crew_id, &"hold")
				var action: Dictionary = _find_row(matrix, scenario_id, crew_id, policy)
				if not bool(action.get("action_accepted", false)):
					counts.unavailable += 1
					continue
				counts.accepted += 1
				var survival: int = int(action.get("crew_health", 0)) - int(hold.get("crew_health", 0))
				var pressure: int = int(hold.get("enemy_health", 0)) - int(action.get("enemy_health", 0))
				if survival == 0 and pressure == 0:
					counts.same += 1
				elif survival >= 0 and pressure >= 0:
					counts.better_or_equal += 1
				elif survival <= 0 and pressure <= 0:
					counts.worse_or_equal += 1
				else:
					counts.tradeoff += 1
		result[policy] = counts
	return result


func _coverage_summary(matrix: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {
		"environment_accepted": 0,
		"focus_accepted": 0,
		"backup_accepted": 0,
		"late_backup_accepted": 0,
	}
	for row: Dictionary in matrix:
		var policy: StringName = StringName(row.get("policy", &""))
		if bool(row.get("action_accepted", false)) and result.has(String(policy) + "_accepted"):
			result[String(policy) + "_accepted"] += 1
	return result


func _find_row(matrix: Array[Dictionary], scenario_id: StringName, crew_id: StringName, policy: StringName) -> Dictionary:
	for row: Dictionary in matrix:
		if row.get("scenario_id") == scenario_id and row.get("crew_id") == crew_id and row.get("policy") == policy:
			return row
	return {}


func _failed_row(host: Node, scenario_id: StringName, crew_id: StringName, policy: StringName, reason: String) -> Dictionary:
	host.free()
	await process_frame
	return {"scenario_id": scenario_id, "crew_id": crew_id, "policy": policy, "error": reason}
