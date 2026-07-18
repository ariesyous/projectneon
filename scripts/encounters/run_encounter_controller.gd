class_name RunEncounterController
extends Node

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
signal status_changed(snapshot: Dictionary)
signal coin_cluster_presented(cluster: CoinCluster)

const DEFAULT_COIN_EXCLUSION_ORIGIN: Vector2 = Vector2(410.0, 239.0)
const DEFAULT_COIN_EXCLUSION_RADIUS: float = 76.0
const COIN_PRESENTATION_OFFSET: Vector2 = Vector2(44.0, -8.0)

@export var jax_scene: PackedScene
@export var street_punk_scene: PackedScene
@export var coin_cluster_scene: PackedScene

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
var _spawn_budget: int = 0
var _completion_published: bool = false
var _next_cluster_id: int = 1
var _total_enemies_spawned: int = 0
var _total_enemies_defeated: int = 0
var _coin_exclusion_origin: Vector2 = DEFAULT_COIN_EXCLUSION_ORIGIN
var _coin_exclusion_radius: float = DEFAULT_COIN_EXCLUSION_RADIUS


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


func configure_coin_interaction_exclusion(world_origin: Vector2, exclusion_radius: float) -> void:
	_coin_exclusion_origin = world_origin
	_coin_exclusion_radius = maxf(exclusion_radius, 0.0)


func start_run() -> bool:
	if not _has_dependencies():
		return false
	reset_for_run()
	_spawn_jax()
	_emit_status()
	return true


func reset_for_run() -> void:
	_active_definition = null
	_active_encounter_instance_id = -1
	_remaining_to_spawn = 0
	_spawn_budget = 0
	_completion_published = false
	_next_cluster_id = 1
	_total_enemies_spawned = 0
	_total_enemies_defeated = 0
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
		or not definition.allowed_enemy_ids.has(&"street_punk")
		or definition.completion_condition != &"all_required_defeated"
	):
		return false
	_active_definition = definition
	_active_encounter_instance_id = encounter_instance_id
	_spawn_budget = _run_director.calculate_spawn_budget(definition)
	_remaining_to_spawn = _spawn_budget
	_completion_published = false
	_fill_spawn_slots()
	encounter_started.emit(encounter_instance_id, definition, _spawn_budget)
	_emit_status()
	return true


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


func get_snapshot() -> Dictionary:
	return {
		"active_encounter_instance_id": _active_encounter_instance_id,
		"active_encounter_id": _active_definition.id if _active_definition != null else &"none",
		"active_encounter_name": _active_definition.display_name if _active_definition != null else "Patrolling",
		"spawn_budget": _spawn_budget,
		"remaining_to_spawn": _remaining_to_spawn,
		"active_enemies": (
			_combat_director.get_live_count(ActorController.Team.ENEMY)
			if _combat_director != null
			else 0
		),
		"total_enemies_spawned": _total_enemies_spawned,
		"total_enemies_defeated": _total_enemies_defeated,
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
		and jax_scene != null
		and street_punk_scene != null
		and coin_cluster_scene != null
	)


func _spawn_jax() -> ActorController:
	var actor: ActorController = jax_scene.instantiate() as ActorController
	if actor == null:
		return null
	actor.name = "Jax"
	actor.initial_lane = 1
	actor.configure_combat_space(_combat_space)
	actor.position = _combat_space.clamp_actor_position(
		Vector2(_left_spawn.position.x + 48.0, _combat_space.lane_y(1))
	)
	_crew_container.add_child(actor)
	_combat_director.register_actor(actor)
	return actor


func _spawn_street_punk() -> ActorController:
	var actor: ActorController = street_punk_scene.instantiate() as ActorController
	if actor == null:
		return null
	var spawn_position_ids: Array[StringName] = (
		_active_definition.spawn_position_ids
		if _active_definition != null and not _active_definition.spawn_position_ids.is_empty()
		else [&"lane_0", &"lane_1", &"lane_2"]
	)
	var lane_id: StringName = _random_streams.choose_stable_id(
		RunRandomStreams.STREAM_SPAWNS,
		spawn_position_ids
	)
	var lane: int = clampi(int(String(lane_id).trim_prefix("lane_")), 0, 2)
	_total_enemies_spawned += 1
	actor.name = "StreetPunk%03d" % _total_enemies_spawned
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
	_combat_director.register_actor(actor)
	return actor


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
		if _spawn_street_punk() == null:
			break
		_remaining_to_spawn -= 1
		active_enemies += 1
		spawn_capacity -= 1


func _on_actor_died(actor: ActorController) -> void:
	if actor == null or actor.team != ActorController.Team.ENEMY or _active_definition == null:
		return
	_total_enemies_defeated += 1
	_spawn_coin_cluster_for(actor)
	_fill_spawn_slots()
	_check_completion()
	_emit_status()


func _on_actor_incapacitated(actor: ActorController) -> void:
	if actor == null or actor.team != ActorController.Team.CREW:
		return
	crew_defeated.emit()


func _check_completion() -> void:
	if (
		_active_definition == null
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
