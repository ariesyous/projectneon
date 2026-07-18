class_name PatrolController
extends Node

## Owns fixed-route travel, stable route indexing, and the immediate travel
## skip used by Subway Reroute. Run state and Heat remain external authorities.

signal route_node_entered(route_index: int, node_id: StringName, node_type: StringName)
signal route_progress_changed(route_index: int, progress: float, loop_count: int)
signal reroute_resolved(previous_index: int, new_index: int)

const RESPONSIBILITY: String = "Coordinate crew patrol along the district route."
const DEFAULT_ROUTE: PatrolRouteDefinition = preload(
	"res://data/routes/downtown_loop_route.tres"
)

@export var route_definition: PatrolRouteDefinition = DEFAULT_ROUTE

var simulation_enabled: bool = false
var route_index: int = -1
var loop_count: int = 0
var _travel_remaining: float = 0.0
var _awaiting_node_resolution: bool = false


func _ready() -> void:
	if route_definition == null:
		route_definition = DEFAULT_ROUTE


func _process(delta: float) -> void:
	step_patrol(delta)


func start_patrol() -> void:
	route_index = -1
	loop_count = 0
	_awaiting_node_resolution = false
	_begin_segment()


func reset_patrol() -> void:
	simulation_enabled = false
	route_index = -1
	loop_count = 0
	_travel_remaining = 0.0
	_awaiting_node_resolution = false


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled


func step_patrol(delta: float) -> void:
	if not simulation_enabled or _awaiting_node_resolution or delta <= 0.0:
		return
	_travel_remaining = maxf(_travel_remaining - delta, 0.0)
	var segment_duration: float = maxf(route_definition.travel_seconds_per_segment, 0.001)
	var progress: float = clampf(1.0 - _travel_remaining / segment_duration, 0.0, 1.0)
	route_progress_changed.emit(route_index, progress, loop_count)
	if _travel_remaining <= 0.0:
		_enter_next_node()


func continue_from_current_node() -> bool:
	if not _awaiting_node_resolution:
		return false
	_awaiting_node_resolution = false
	_begin_segment()
	return true


func can_reroute() -> bool:
	return simulation_enabled and not _awaiting_node_resolution and route_definition.node_count() > 0


func request_reroute() -> bool:
	if not can_reroute():
		return false
	var previous_index: int = route_index
	_travel_remaining = 0.0
	_enter_next_node()
	reroute_resolved.emit(previous_index, route_index)
	return true


func get_route_node_id() -> StringName:
	return route_definition.node_id(route_index) if route_index >= 0 else &"departing_hideout"


func get_route_node_type() -> StringName:
	return route_definition.node_type(route_index) if route_index >= 0 else &"travel"


func get_route_progress() -> float:
	if _awaiting_node_resolution:
		return 1.0
	var duration: float = maxf(route_definition.travel_seconds_per_segment, 0.001)
	return clampf(1.0 - _travel_remaining / duration, 0.0, 1.0)


func get_snapshot() -> Dictionary:
	return {
		"route_id": route_definition.id,
		"route_index": route_index,
		"route_node_id": get_route_node_id(),
		"route_node_type": get_route_node_type(),
		"route_progress": get_route_progress(),
		"loop_count": loop_count,
		"awaiting_node_resolution": _awaiting_node_resolution,
		"simulation_enabled": simulation_enabled,
	}


func _begin_segment() -> void:
	_travel_remaining = maxf(route_definition.travel_seconds_per_segment, 0.001)
	route_progress_changed.emit(route_index, 0.0, loop_count)


func _enter_next_node() -> void:
	var count: int = route_definition.node_count()
	if count <= 0:
		return
	var next_index: int = route_index + 1
	if next_index >= count:
		next_index = 0
		loop_count += 1
	route_index = next_index
	_awaiting_node_resolution = true
	route_progress_changed.emit(route_index, 1.0, loop_count)
	route_node_entered.emit(
		route_index,
		route_definition.node_id(route_index),
		route_definition.node_type(route_index)
	)
