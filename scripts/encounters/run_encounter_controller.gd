class_name RunEncounterController
extends Node

const ActorSceneCatalogueType = preload("res://scripts/actors/actor_scene_catalogue.gd")
const EncounterSpawnEntryType = preload("res://data/encounters/encounter_spawn_entry.gd")

## Owns Milestone 3 encounter actor spawning, pending-spawn accounting,
## exactly-once completion publication, scaled actor configuration, and clean
## run reset. RunDirector remains the lifecycle/escalation authority.

signal encounter_started(
	encounter_instance_id: int,
	definition: EncounterDefinition,
	spawn_budget: int
)
signal encounter_completed(encounter_instance_id: int, definition: EncounterDefinition)
signal crew_defeated()
signal boss_encounter_started(
	encounter_instance_id: int,
	definition: EncounterDefinition,
	boss: ActorController
)
signal boss_defeated(boss: ActorController)
signal boss_summons_spawned(boss: ActorController, summons: Array[ActorController])
signal elite_defeated(elite: ActorController)
signal enemy_spawned(actor: ActorController, actor_id: StringName)
signal permanent_crew_spawned(actor: ActorController, actor_id: StringName)
signal status_changed(snapshot: Dictionary)
signal coin_cluster_presented(cluster: CoinCluster)

const DEFAULT_COIN_EXCLUSION_ORIGIN: Vector2 = Vector2(410.0, 239.0)
const DEFAULT_COIN_EXCLUSION_RADIUS: float = 76.0
const COIN_PRESENTATION_OFFSET: Vector2 = Vector2(44.0, -8.0)
const DEFAULT_ACTOR_CATALOGUE: ActorSceneCatalogueType = preload(
	"res://data/actors/milestone_6_actor_catalogue.tres"
)

@export var jax_scene: PackedScene
@export var street_punk_scene: PackedScene
@export var coin_cluster_scene: PackedScene
@export var actor_catalogue: ActorSceneCatalogueType = DEFAULT_ACTOR_CATALOGUE
@export var starting_crew_ids: Array[StringName] = [&"jax"]

var _run_director: RunDirector
var _combat_director: CombatDirector
var _reward_director: RewardDirector
var _crew_container: Node2D
var _enemy_container: Node2D
var _loot_container: Node2D
var _left_spawn: Marker2D
var _right_spawn: Marker2D
var _combat_space: CombatSpaceDefinition
var _random_streams: RunRandomStreams

var _active_definition: EncounterDefinition
var _active_encounter_instance_id: int = -1
var _remaining_to_spawn: int = 0
var _pending_enemy_ids: Array[StringName] = []
var _spawn_delay_remaining: float = 0.0
var _spawn_budget: int = 0
var _completion_published: bool = false
var _next_cluster_id: int = 1
var _total_enemies_spawned: int = 0
var _total_enemies_defeated: int = 0
var _total_elites_defeated: int = 0
var _boss_defeated_published: bool = false
var _permanent_crew_instance_ids: Dictionary[int, bool] = {}
var _spawn_counts_by_id: Dictionary[StringName, int] = {}
var _last_spawn_plan: Array[StringName] = []
var _coin_exclusion_origin: Vector2 = DEFAULT_COIN_EXCLUSION_ORIGIN
var _coin_exclusion_radius: float = DEFAULT_COIN_EXCLUSION_RADIUS


func _process(delta: float) -> void:
	step_spawn_pacing(delta)


func configure(
	run_director: RunDirector,
	combat_director: CombatDirector,
	reward_director: RewardDirector,
	crew_container: Node2D,
	enemy_container: Node2D,
	loot_container: Node2D,
	left_spawn: Marker2D,
	right_spawn: Marker2D
) -> void:
	_run_director = run_director
	_combat_director = combat_director
	_reward_director = reward_director
	_crew_container = crew_container
	_enemy_container = enemy_container
	_loot_container = loot_container
	_left_spawn = left_spawn
	_right_spawn = right_spawn
	_combat_space = _combat_director.get_combat_space() if _combat_director != null else null
	_random_streams = _run_director.get_random_streams() if _run_director != null else null
	if _combat_director != null:
		if not _combat_director.actor_died.is_connected(_on_actor_died):
			_combat_director.actor_died.connect(_on_actor_died)
		if not _combat_director.actor_incapacitated.is_connected(_on_actor_incapacitated):
			_combat_director.actor_incapacitated.connect(_on_actor_incapacitated)
		if not _combat_director.boss_summon_requested.is_connected(
			_on_boss_summon_requested
		):
			_combat_director.boss_summon_requested.connect(_on_boss_summon_requested)


func configure_coin_interaction_exclusion(world_origin: Vector2, exclusion_radius: float) -> void:
	_coin_exclusion_origin = world_origin
	_coin_exclusion_radius = maxf(exclusion_radius, 0.0)


func start_run() -> bool:
	if not _has_dependencies():
		return false
	reset_for_run()
	if not _spawn_starting_crew():
		return false
	_emit_status()
	return true


func configure_starting_crew(requested_ids: Array[StringName]) -> bool:
	if requested_ids.is_empty() or requested_ids.size() > 3:
		return false
	var stable_unique_ids: Array[StringName] = []
	for actor_id: StringName in requested_ids:
		if actor_id == &"" or stable_unique_ids.has(actor_id) or _resolve_actor_scene(actor_id) == null:
			return false
		stable_unique_ids.append(actor_id)
	starting_crew_ids = stable_unique_ids
	return true


func reset_for_run() -> void:
	_active_definition = null
	_active_encounter_instance_id = -1
	_remaining_to_spawn = 0
	_pending_enemy_ids.clear()
	_spawn_delay_remaining = 0.0
	_spawn_budget = 0
	_completion_published = false
	_next_cluster_id = 1
	_total_enemies_spawned = 0
	_total_enemies_defeated = 0
	_total_elites_defeated = 0
	_boss_defeated_published = false
	_permanent_crew_instance_ids.clear()
	_spawn_counts_by_id.clear()
	_last_spawn_plan.clear()
	if _combat_director != null:
		_combat_director.clear_all(false)
	_clear_container(_crew_container)
	_clear_container(_enemy_container)
	_clear_container(_loot_container)


func start_encounter(encounter_instance_id: int, definition: EncounterDefinition) -> bool:
	if (
		definition == null
		or encounter_instance_id < 0
		or _active_definition != null
		or _run_director == null
		or _combat_director == null
		or definition.boss
		or definition.completion_condition != &"all_required_defeated"
	):
		return false
	_active_definition = definition
	_active_encounter_instance_id = encounter_instance_id
	_spawn_budget = _run_director.calculate_spawn_budget(definition)
	_pending_enemy_ids = _build_spawn_plan(definition, _spawn_budget)
	if _pending_enemy_ids.is_empty():
		_active_definition = null
		_active_encounter_instance_id = -1
		return false
	_last_spawn_plan = _pending_enemy_ids.duplicate()
	_remaining_to_spawn = _pending_enemy_ids.size()
	_completion_published = false
	_boss_defeated_published = false
	_spawn_delay_remaining = maxf(definition.initial_spawn_delay_seconds, 0.0)
	if not _uses_authored_spawn_pacing():
		_fill_spawn_slots()
	elif _spawn_delay_remaining <= 0.0 and _spawn_one_paced_enemy():
		if _remaining_to_spawn > 0:
			_spawn_delay_remaining = maxf(definition.spawn_interval_seconds, 0.0)
	encounter_started.emit(encounter_instance_id, definition, _spawn_budget)
	_emit_status()
	return true


func start_boss_encounter(
	encounter_instance_id: int,
	definition: EncounterDefinition
) -> bool:
	if (
		definition == null
		or encounter_instance_id < 0
		or not definition.boss
		or definition.completion_condition != &"boss_defeated"
		or _active_definition != null
		or _combat_director == null
	):
		return false
	_active_definition = definition
	_active_encounter_instance_id = encounter_instance_id
	_spawn_budget = maxi(definition.base_spawn_budget, 1)
	_pending_enemy_ids = _build_spawn_plan(definition, _spawn_budget)
	if _pending_enemy_ids.size() != 1:
		_active_definition = null
		_active_encounter_instance_id = -1
		return false
	_last_spawn_plan = _pending_enemy_ids.duplicate()
	_remaining_to_spawn = 1
	_spawn_delay_remaining = 0.0
	_completion_published = false
	_boss_defeated_published = false
	var boss: ActorController = _spawn_next_pending_enemy()
	if boss == null or not boss.is_boss():
		_active_definition = null
		_active_encounter_instance_id = -1
		return false
	boss_encounter_started.emit(encounter_instance_id, definition, boss)
	_emit_status()
	return true


func step_spawn_pacing(delta: float) -> void:
	if (
		delta <= 0.0
		or not _uses_authored_spawn_pacing()
		or _active_definition == null
		or _active_definition.boss
		or _remaining_to_spawn <= 0
		or _run_director == null
		or _run_director.current_state != RunDirector.RunState.ENCOUNTER_ACTIVE
	):
		return
	var remaining_delta: float = maxf(delta, 0.0)
	while remaining_delta > 0.0 and _remaining_to_spawn > 0:
		if _spawn_delay_remaining > remaining_delta:
			_spawn_delay_remaining -= remaining_delta
			return
		remaining_delta -= _spawn_delay_remaining
		_spawn_delay_remaining = 0.0
		if not _spawn_one_paced_enemy():
			# A full authored concurrency cap is not an error. Keep the elapsed
			# delay at zero and retry as soon as a stable slot becomes available.
			return
		if _remaining_to_spawn <= 0:
			return
		_spawn_delay_remaining = maxf(_active_definition.spawn_interval_seconds, 0.0)
		if _spawn_delay_remaining <= 0.0:
			_fill_spawn_slots()
			return


func has_active_encounter() -> bool:
	return _active_definition != null and not _completion_published


func get_active_encounter_instance_id() -> int:
	return _active_encounter_instance_id


func get_active_definition() -> EncounterDefinition:
	return _active_definition


func get_total_enemies_spawned() -> int:
	return _total_enemies_spawned


func get_total_enemies_defeated() -> int:
	return _total_enemies_defeated


func get_total_elites_defeated() -> int:
	return _total_elites_defeated


func get_last_spawn_plan() -> Array[StringName]:
	return _last_spawn_plan.duplicate()


func get_permanent_crew() -> Array[ActorController]:
	var result: Array[ActorController] = []
	if _combat_director == null:
		return result
	for actor: ActorController in _combat_director.get_live_actors(ActorController.Team.CREW):
		if actor.is_permanent_crew():
			result.append(actor)
	result.sort_custom(_actor_registration_before)
	return result


func get_snapshot() -> Dictionary:
	return {
		"active_encounter_instance_id": _active_encounter_instance_id,
		"active_encounter_id": _active_definition.id if _active_definition != null else &"none",
		"active_encounter_name": _active_definition.display_name if _active_definition != null else "Patrolling",
		"spawn_budget": _spawn_budget,
		"remaining_to_spawn": _remaining_to_spawn,
		"spawn_delay_remaining": _spawn_delay_remaining,
		"initial_spawn_delay_seconds": (
			_active_definition.initial_spawn_delay_seconds
			if _active_definition != null
			else 0.0
		),
		"spawn_interval_seconds": (
			_active_definition.spawn_interval_seconds
			if _active_definition != null
			else 0.0
		),
		"pending_enemy_ids": _pending_enemy_ids.duplicate(),
		"active_enemies": (
			_combat_director.get_live_count(ActorController.Team.ENEMY)
			if _combat_director != null
			else 0
		),
		"total_enemies_spawned": _total_enemies_spawned,
		"total_enemies_defeated": _total_enemies_defeated,
		"total_elites_defeated": _total_elites_defeated,
		"boss_active": _active_definition != null and _active_definition.boss,
		"boss_defeated": _boss_defeated_published,
		"permanent_crew_count": _permanent_crew_instance_ids.size(),
	}


func calculate_coin_presentation_position(defeat_position: Vector2) -> Vector2:
	if _combat_space == null:
		return defeat_position
	var outward_direction: float = -1.0 if defeat_position.x < 320.0 else 1.0
	var candidate: Vector2 = _combat_space.clamp_actor_position(
		defeat_position + Vector2(COIN_PRESENTATION_OFFSET.x * outward_direction, COIN_PRESENTATION_OFFSET.y)
	)
	if candidate.distance_to(_coin_exclusion_origin) < _coin_exclusion_radius:
		candidate = _combat_space.clamp_actor_position(
			defeat_position + Vector2(-COIN_PRESENTATION_OFFSET.x, COIN_PRESENTATION_OFFSET.y)
		)
	return candidate


func _has_dependencies() -> bool:
	return (
		_run_director != null
		and _combat_director != null
		and _reward_director != null
		and _crew_container != null
		and _enemy_container != null
		and _loot_container != null
		and _left_spawn != null
		and _right_spawn != null
		and _combat_space != null
		and _random_streams != null
		and (
			(actor_catalogue != null and actor_catalogue.is_valid())
			or (jax_scene != null and street_punk_scene != null)
		)
		and coin_cluster_scene != null
	)


func _spawn_jax() -> ActorController:
	return _spawn_permanent_crew(&"jax", 1, 0)


func _spawn_street_punk() -> ActorController:
	return _spawn_enemy_by_id(&"street_punk")


func _spawn_starting_crew() -> bool:
	if starting_crew_ids.is_empty() or starting_crew_ids.size() > 3:
		return false
	for index: int in range(starting_crew_ids.size()):
		var lane: int = [1, 0, 2][index]
		if _spawn_permanent_crew(starting_crew_ids[index], lane, index) == null:
			return false
	return true


func _spawn_permanent_crew(
	actor_id: StringName,
	lane: int,
	formation_index: int
) -> ActorController:
	var scene: PackedScene = _resolve_actor_scene(actor_id)
	if scene == null:
		return null
	var actor: ActorController = scene.instantiate() as ActorController
	if actor == null or actor.actor_definition == null or not actor.actor_definition.is_permanent_crew():
		if actor != null:
			actor.free()
		return null
	actor.name = actor.actor_definition.display_name.replace(" ", "")
	actor.team = ActorController.Team.CREW
	actor.initial_lane = clampi(lane, 0, 2)
	actor.configure_combat_space(_combat_space)
	actor.position = _combat_space.clamp_actor_position(Vector2(
		_left_spawn.position.x + 48.0 + float(formation_index) * 18.0,
		_combat_space.lane_y(actor.initial_lane)
	))
	_crew_container.add_child(actor)
	if not _combat_director.register_actor(actor):
		actor.queue_free()
		return null
	_permanent_crew_instance_ids[actor.get_instance_id()] = true
	permanent_crew_spawned.emit(actor, actor_id)
	return actor


func spawn_temporary_ally(
	actor_id: StringName = &"backup_runner",
	lane: int = 1,
	world_position: Vector2 = Vector2.INF
) -> ActorController:
	var scene: PackedScene = _resolve_actor_scene(actor_id)
	if scene == null or _crew_container == null or _combat_director == null:
		return null
	var actor: ActorController = scene.instantiate() as ActorController
	if actor == null or actor.actor_definition == null or not actor.actor_definition.is_temporary_ally():
		if actor != null:
			actor.free()
		return null
	actor.team = ActorController.Team.CREW
	actor.initial_lane = clampi(lane, 0, 2)
	actor.configure_combat_space(_combat_space)
	actor.position = _combat_space.clamp_actor_position(
		world_position
		if world_position != Vector2.INF
		else Vector2(_left_spawn.position.x + 62.0, _combat_space.lane_y(actor.initial_lane))
	)
	_crew_container.add_child(actor)
	if not _combat_director.register_actor(actor):
		actor.queue_free()
		return null
	return actor


func remove_temporary_ally(actor: ActorController) -> bool:
	if (
		actor == null
		or actor.actor_definition == null
		or not actor.actor_definition.is_temporary_ally()
	):
		return false
	var removed: bool = _combat_director.unregister_actor(actor, true)
	if removed and is_instance_valid(actor):
		actor.queue_free()
	return removed


func _spawn_enemy_by_id(actor_id: StringName, forced_lane: int = -1) -> ActorController:
	var scene: PackedScene = _resolve_actor_scene(actor_id)
	if scene == null:
		return null
	var actor: ActorController = scene.instantiate() as ActorController
	if actor == null or actor.actor_definition == null:
		if actor != null:
			actor.free()
		return null
	if actor.actor_definition.combat_role not in [
		ActorDefinition.CombatRole.BASIC_ENEMY,
		ActorDefinition.CombatRole.ELITE,
		ActorDefinition.CombatRole.BOSS,
	]:
		actor.free()
		return null
	var spawn_position_ids: Array[StringName] = (
		_active_definition.spawn_position_ids
		if _active_definition != null and not _active_definition.spawn_position_ids.is_empty()
		else [&"lane_0", &"lane_1", &"lane_2"]
	)
	var lane: int = forced_lane
	if lane < 0:
		var lane_id: StringName = (
			spawn_position_ids[0]
			if spawn_position_ids.size() == 1
			else _random_streams.choose_stable_id(
				RunRandomStreams.STREAM_SPAWNS,
				spawn_position_ids
			)
		)
		lane = clampi(int(String(lane_id).trim_prefix("lane_")), 0, 2)
	_total_enemies_spawned += 1
	actor.name = "%s%03d" % [String(actor_id).to_pascal_case().replace("_", ""), _total_enemies_spawned]
	actor.team = ActorController.Team.ENEMY
	actor.initial_lane = lane
	actor.configure_combat_space(_combat_space)
	actor.configure_runtime_scaling(
		_run_director.get_enemy_health_multiplier(),
		_run_director.get_enemy_damage_multiplier()
	)
	var column_offset: float = float(_total_enemies_spawned % 2) * 24.0
	actor.position = _combat_space.clamp_actor_position(
		Vector2(_right_spawn.position.x - column_offset, _combat_space.lane_y(lane))
	)
	_enemy_container.add_child(actor)
	if not _combat_director.register_actor(actor):
		actor.queue_free()
		return null
	_spawn_counts_by_id[actor_id] = _spawn_counts_by_id.get(actor_id, 0) + 1
	enemy_spawned.emit(actor, actor_id)
	return actor


func _spawn_next_pending_enemy() -> ActorController:
	if _pending_enemy_ids.is_empty():
		_remaining_to_spawn = 0
		return null
	var actor_id: StringName = _pending_enemy_ids.pop_front()
	_remaining_to_spawn = _pending_enemy_ids.size()
	return _spawn_enemy_by_id(actor_id)


func _build_spawn_plan(
	definition: EncounterDefinition,
	budget: int
) -> Array[StringName]:
	var result: Array[StringName] = []
	var safe_budget: int = maxi(budget, 0)
	if definition == null or safe_budget <= 0:
		return result
	var entries: Array[EncounterSpawnEntryType] = _get_stable_spawn_entries(definition)
	if entries.is_empty():
		var allowed_ids: Array[StringName] = _get_valid_stable_actor_ids(
			definition.allowed_enemy_ids
		)
		if allowed_ids.is_empty():
			return result
		for _spawn_index: int in range(safe_budget):
			result.append(
				allowed_ids[0]
				if allowed_ids.size() == 1
				else _random_streams.choose_stable_id(
					RunRandomStreams.STREAM_ENEMY_VARIANTS,
					allowed_ids
				)
			)
		return result

	var remaining_budget: int = safe_budget
	var counts_by_id: Dictionary[StringName, int] = {}
	var entry_by_id: Dictionary[StringName, EncounterSpawnEntryType] = {}
	for entry: EncounterSpawnEntryType in entries:
		entry_by_id[entry.actor_id] = entry
		counts_by_id[entry.actor_id] = 0
		for _minimum_index: int in range(entry.minimum_count):
			if entry.budget_cost > remaining_budget:
				return []
			result.append(entry.actor_id)
			counts_by_id[entry.actor_id] = counts_by_id.get(entry.actor_id, 0) + 1
			remaining_budget -= entry.budget_cost

	while remaining_budget > 0:
		var eligible_ids: Array[StringName] = []
		for entry: EncounterSpawnEntryType in entries:
			if (
				entry.budget_cost <= remaining_budget
				and counts_by_id.get(entry.actor_id, 0) < entry.maximum_count
			):
				eligible_ids.append(entry.actor_id)
		if eligible_ids.is_empty():
			break
		var selected_id: StringName = (
			eligible_ids[0]
			if eligible_ids.size() == 1
			else _random_streams.choose_stable_id(
				RunRandomStreams.STREAM_ENEMY_VARIANTS,
				eligible_ids
			)
		)
		var selected_entry: EncounterSpawnEntryType = entry_by_id.get(selected_id)
		if selected_entry == null:
			break
		result.append(selected_id)
		counts_by_id[selected_id] = counts_by_id.get(selected_id, 0) + 1
		remaining_budget -= selected_entry.budget_cost
	return result


func _get_stable_spawn_entries(
	definition: EncounterDefinition
) -> Array[EncounterSpawnEntryType]:
	var result: Array[EncounterSpawnEntryType] = []
	var seen: Dictionary[StringName, bool] = {}
	for entry: EncounterSpawnEntryType in definition.spawn_entries:
		if (
			entry == null
			or not entry.is_valid()
			or seen.has(entry.actor_id)
			or _resolve_actor_scene(entry.actor_id) == null
		):
			continue
		seen[entry.actor_id] = true
		result.append(entry)
	result.sort_custom(_spawn_entry_before)
	return result


func _get_valid_stable_actor_ids(source_ids: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for actor_id: StringName in source_ids:
		if actor_id == &"" or result.has(actor_id) or _resolve_actor_scene(actor_id) == null:
			continue
		result.append(actor_id)
	result.sort_custom(_string_name_before)
	return result


func _resolve_actor_scene(actor_id: StringName) -> PackedScene:
	if actor_catalogue != null:
		var catalogued_scene: PackedScene = actor_catalogue.get_scene(actor_id)
		if catalogued_scene != null:
			return catalogued_scene
	if actor_id == &"jax":
		return jax_scene
	if actor_id == &"street_punk":
		return street_punk_scene
	return null


func _fill_spawn_slots() -> void:
	if _active_definition == null or _remaining_to_spawn <= 0:
		_check_completion()
		return
	var active_enemies: int = _combat_director.get_live_count(ActorController.Team.ENEMY)
	var spawn_capacity: int = _run_director.calculate_encounter_concurrency(
		_active_definition,
		_remaining_to_spawn,
		active_enemies
	)
	while spawn_capacity > 0 and _remaining_to_spawn > 0:
		if _spawn_next_pending_enemy() == null:
			break
		active_enemies += 1
		spawn_capacity -= 1


func _spawn_one_paced_enemy() -> bool:
	if _active_definition == null or _remaining_to_spawn <= 0:
		return false
	var active_enemies: int = _combat_director.get_live_count(ActorController.Team.ENEMY)
	var spawn_capacity: int = _run_director.calculate_encounter_concurrency(
		_active_definition,
		_remaining_to_spawn,
		active_enemies
	)
	if spawn_capacity <= 0:
		return false
	return _spawn_next_pending_enemy() != null


func _uses_authored_spawn_pacing() -> bool:
	return (
		_active_definition != null
		and (
			_active_definition.initial_spawn_delay_seconds > 0.0
			or _active_definition.spawn_interval_seconds > 0.0
		)
	)


func _on_actor_died(actor: ActorController) -> void:
	if actor == null or actor.team != ActorController.Team.ENEMY or _active_definition == null:
		return
	_total_enemies_defeated += 1
	if actor.is_elite():
		_total_elites_defeated += 1
		elite_defeated.emit(actor)
	_spawn_coin_cluster_for(actor)
	if actor.is_boss():
		if not _boss_defeated_published:
			_boss_defeated_published = true
			_completion_published = true
			_active_definition = null
			_active_encounter_instance_id = -1
			_pending_enemy_ids.clear()
			_remaining_to_spawn = 0
			_spawn_delay_remaining = 0.0
			boss_defeated.emit(actor)
		_emit_status()
		return
	if not _uses_authored_spawn_pacing():
		_fill_spawn_slots()
	_check_completion()
	_emit_status()


func _on_actor_incapacitated(actor: ActorController) -> void:
	if (
		actor == null
		or actor.team != ActorController.Team.CREW
		or not actor.is_permanent_crew()
		or not _permanent_crew_instance_ids.has(actor.get_instance_id())
	):
		return
	for snapshot: Dictionary in _combat_director.get_actor_snapshots():
		if int(snapshot.get("combat_role", -1)) != ActorDefinition.CombatRole.PERMANENT_CREW:
			continue
		var state: int = int(snapshot.get("state", ActorStateMachine.State.DEAD))
		if state not in [ActorStateMachine.State.INCAPACITATED, ActorStateMachine.State.DEAD]:
			return
	crew_defeated.emit()


func _on_boss_summon_requested(
	boss: ActorController,
	actor_ids: Array[StringName]
) -> void:
	if (
		boss == null
		or not boss.is_boss()
		or _active_definition == null
		or not _active_definition.boss
		or _boss_defeated_published
	):
		return
	var stable_ids: Array[StringName] = _get_valid_stable_actor_ids(actor_ids)
	var summons: Array[ActorController] = []
	for actor_id: StringName in stable_ids:
		var summoned: ActorController = _spawn_enemy_by_id(actor_id)
		if summoned == null or summoned.is_elite() or summoned.is_boss():
			if summoned != null:
				_combat_director.unregister_actor(summoned, true)
				summoned.queue_free()
			continue
		summons.append(summoned)
	if not summons.is_empty():
		boss_summons_spawned.emit(boss, summons)


func _check_completion() -> void:
	if (
		_active_definition == null
		or _active_definition.boss
		or _completion_published
		or _remaining_to_spawn > 0
		or _combat_director.get_live_count(ActorController.Team.ENEMY) > 0
	):
		return
	_completion_published = true
	var completed_id: int = _active_encounter_instance_id
	var completed_definition: EncounterDefinition = _active_definition
	_active_definition = null
	_active_encounter_instance_id = -1
	encounter_completed.emit(completed_id, completed_definition)


func _spawn_coin_cluster_for(actor: ActorController) -> void:
	if not actor.grants_coin_reward() or actor.authored_coin_value() <= 0:
		return
	var cluster_id: int = _next_cluster_id
	_next_cluster_id += 1
	if not _reward_director.register_coin_cluster(cluster_id, actor.authored_coin_value()):
		return
	var cluster: CoinCluster = coin_cluster_scene.instantiate() as CoinCluster
	if cluster == null:
		return
	cluster.position = _loot_container.to_local(calculate_coin_presentation_position(actor.global_position))
	_loot_container.add_child(cluster)
	cluster.bind(
		cluster_id,
		actor.authored_coin_value(),
		_reward_director.get_cluster_expires_at_msec(cluster_id),
		_reward_director
	)
	coin_cluster_presented.emit(cluster)


func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child: Node in container.get_children():
		if is_instance_valid(child):
			child.free()


func _emit_status() -> void:
	status_changed.emit(get_snapshot())


func _spawn_entry_before(left: EncounterSpawnEntryType, right: EncounterSpawnEntryType) -> bool:
	return String(left.actor_id) < String(right.actor_id)


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


func _actor_registration_before(left: ActorController, right: ActorController) -> bool:
	return left.registration_order < right.registration_order
