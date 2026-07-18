class_name CombatLabController
extends Node

## Milestone 1-only authored demo orchestration. It maintains a fixed five-
## enemy laboratory load without encounter scheduling, run progression, or RNG.

signal lab_status_changed(
	elapsed_seconds: float,
	active_enemies: int,
	total_spawned: int,
	total_defeated: int,
	round_number: int
)
signal coin_cluster_presented(cluster: CoinCluster)

const TARGET_ENEMY_COUNT: int = 5
const ENEMY_RESPAWN_DELAY: float = 0.75
const CREW_RESET_DELAY: float = 1.5
const STATUS_REFRESH_INTERVAL: float = 0.20

@export var jax_scene: PackedScene
@export var street_punk_scene: PackedScene
@export var coin_cluster_scene: PackedScene

var _combat_director: CombatDirector
var _reward_director: RewardDirector
var _crew_container: Node2D
var _enemy_container: Node2D
var _loot_container: Node2D
var _left_spawn: Marker2D
var _right_spawn: Marker2D

var _started: bool = false
var _enemy_lane_sequence: Array[int] = [1, 0, 2, 0, 2, 1]
var _elapsed_seconds: float = 0.0
var _status_refresh_remaining: float = 0.0
var _pending_enemy_spawns: Array[float] = []
var _next_enemy_sequence_index: int = 0
var _next_cluster_id: int = 1
var _total_spawned: int = 0
var _total_defeated: int = 0
var _round_number: int = 1
var _reset_remaining: float = -1.0


func configure(
	combat_director: CombatDirector,
	reward_director: RewardDirector,
	crew_container: Node2D,
	enemy_container: Node2D,
	loot_container: Node2D,
	left_spawn: Marker2D,
	right_spawn: Marker2D
) -> void:
	_combat_director = combat_director
	_reward_director = reward_director
	_crew_container = crew_container
	_enemy_container = enemy_container
	_loot_container = loot_container
	_left_spawn = left_spawn
	_right_spawn = right_spawn
	if not _combat_director.actor_died.is_connected(_on_actor_died):
		_combat_director.actor_died.connect(_on_actor_died)
	if not _combat_director.actor_incapacitated.is_connected(_on_actor_incapacitated):
		_combat_director.actor_incapacitated.connect(_on_actor_incapacitated)


func start_lab() -> bool:
	if _started or not _has_required_dependencies():
		return false
	_started = true
	_elapsed_seconds = 0.0
	_status_refresh_remaining = 0.0
	_pending_enemy_spawns.clear()
	_reset_remaining = -1.0
	_spawn_jax()
	for _index: int in range(TARGET_ENEMY_COUNT):
		_spawn_street_punk()
	_emit_status()
	return true


func stop_lab() -> void:
	_started = false
	_pending_enemy_spawns.clear()
	_reset_remaining = -1.0
	if _combat_director != null:
		_combat_director.clear_all(true)


func step_lab(delta: float) -> void:
	if not _started or delta <= 0.0:
		return
	_elapsed_seconds += delta
	_status_refresh_remaining -= delta

	if _reset_remaining >= 0.0:
		_reset_remaining -= delta
		if _reset_remaining <= 0.0:
			_restart_round()
		if _status_refresh_remaining <= 0.0:
			_emit_status()
		return

	for index: int in range(_pending_enemy_spawns.size() - 1, -1, -1):
		_pending_enemy_spawns[index] -= delta
		if _pending_enemy_spawns[index] <= 0.0:
			_pending_enemy_spawns.remove_at(index)
			if _combat_director.get_live_count(ActorController.Team.ENEMY) < TARGET_ENEMY_COUNT:
				_spawn_street_punk()

	if _status_refresh_remaining <= 0.0:
		_emit_status()


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func get_total_spawned() -> int:
	return _total_spawned


func get_total_defeated() -> int:
	return _total_defeated


func get_round_number() -> int:
	return _round_number


func get_debug_snapshot() -> Dictionary:
	return {
		"elapsed_seconds": _elapsed_seconds,
		"active_enemies": (
			_combat_director.get_live_count(ActorController.Team.ENEMY)
			if _combat_director != null
			else 0
		),
		"pending_spawns": _pending_enemy_spawns.size(),
		"total_spawned": _total_spawned,
		"total_defeated": _total_defeated,
		"round_number": _round_number,
		"reset_pending": _reset_remaining >= 0.0,
	}


func _process(delta: float) -> void:
	step_lab(delta)


func _has_required_dependencies() -> bool:
	return (
		_combat_director != null
		and _reward_director != null
		and _crew_container != null
		and _enemy_container != null
		and _loot_container != null
		and _left_spawn != null
		and _right_spawn != null
		and jax_scene != null
		and street_punk_scene != null
		and coin_cluster_scene != null
	)


func _spawn_jax() -> ActorController:
	var actor: ActorController = jax_scene.instantiate() as ActorController
	if actor == null:
		push_error("Combat Lab could not instantiate Jax.")
		return null
	actor.name = "Jax"
	actor.initial_lane = 1
	actor.position = Vector2(_left_spawn.position.x + 48.0, ActorController.lane_y(1))
	_crew_container.add_child(actor)
	_combat_director.register_actor(actor)
	return actor


func _spawn_street_punk() -> ActorController:
	var actor: ActorController = street_punk_scene.instantiate() as ActorController
	if actor == null:
		push_error("Combat Lab could not instantiate Street Punk.")
		return null
	var sequence_index: int = _next_enemy_sequence_index
	var lane: int = _enemy_lane_sequence[sequence_index % _enemy_lane_sequence.size()]
	_next_enemy_sequence_index += 1
	_total_spawned += 1
	actor.name = "StreetPunk%03d" % _total_spawned
	actor.initial_lane = lane
	var column_offset: float = float(sequence_index % 2) * 24.0
	actor.position = Vector2(
		_right_spawn.position.x - column_offset,
		ActorController.lane_y(lane)
	)
	_enemy_container.add_child(actor)
	_combat_director.register_actor(actor)
	return actor


func _on_actor_died(actor: ActorController) -> void:
	if not _started or actor == null or actor.team != ActorController.Team.ENEMY:
		return
	_total_defeated += 1
	_spawn_coin_cluster_for(actor)
	_pending_enemy_spawns.append(ENEMY_RESPAWN_DELAY)
	_emit_status()


func _on_actor_incapacitated(actor: ActorController) -> void:
	if not _started or actor == null or actor.team != ActorController.Team.CREW:
		return
	_pending_enemy_spawns.clear()
	_reset_remaining = CREW_RESET_DELAY
	_emit_status()


func _spawn_coin_cluster_for(actor: ActorController) -> void:
	if not actor.grants_coin_reward():
		return
	var base_value: int = actor.authored_coin_value()
	if base_value <= 0:
		return
	var cluster_id: int = _next_cluster_id
	_next_cluster_id += 1
	if not _reward_director.register_coin_cluster(cluster_id, base_value):
		return
	var cluster: CoinCluster = coin_cluster_scene.instantiate() as CoinCluster
	if cluster == null:
		push_error("Combat Lab could not instantiate a coin cluster.")
		return
	# Present the generous click target just outside the melee silhouette so the
	# 2.5-second choice never masks Jax or the current target.
	var outward_direction: float = -1.0 if actor.global_position.x < 320.0 else 1.0
	var world_position: Vector2 = actor.global_position + Vector2(44.0 * outward_direction, -8.0)
	world_position.x = clampf(world_position.x, 158.0, 482.0)
	world_position.y = clampf(world_position.y, 190.0, 262.0)
	cluster.position = _loot_container.to_local(world_position)
	_loot_container.add_child(cluster)
	cluster.bind(
		cluster_id,
		base_value,
		_reward_director.get_cluster_expires_at_msec(cluster_id),
		_reward_director
	)
	coin_cluster_presented.emit(cluster)


func _restart_round() -> void:
	_combat_director.clear_all(true)
	_pending_enemy_spawns.clear()
	_reset_remaining = -1.0
	_round_number += 1
	_spawn_jax()
	for _index: int in range(TARGET_ENEMY_COUNT):
		_spawn_street_punk()
	_emit_status()


func _emit_status() -> void:
	_status_refresh_remaining = STATUS_REFRESH_INTERVAL
	lab_status_changed.emit(
		_elapsed_seconds,
		_combat_director.get_live_count(ActorController.Team.ENEMY) if _combat_director != null else 0,
		_total_spawned,
		_total_defeated,
		_round_number
	)
