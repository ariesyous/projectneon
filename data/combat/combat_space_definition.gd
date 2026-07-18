@tool
class_name CombatSpaceDefinition
extends Resource

## Authored actor-origin bounds and lane centres for one combat space. Runtime
## movement, spawning, reservations, and knockback all share this contract.

@export var actor_origin_bounds: Rect2 = Rect2(164.0, 194.0, 292.0, 64.0)
@export var lane_y_positions: PackedFloat32Array = PackedFloat32Array([
	194.0,
	226.0,
	258.0,
])


func minimum_x() -> float:
	return minf(actor_origin_bounds.position.x, actor_origin_bounds.end.x)


func maximum_x() -> float:
	return maxf(actor_origin_bounds.position.x, actor_origin_bounds.end.x)


func minimum_y() -> float:
	return minf(actor_origin_bounds.position.y, actor_origin_bounds.end.y)


func maximum_y() -> float:
	return maxf(actor_origin_bounds.position.y, actor_origin_bounds.end.y)


func clamp_actor_position(world_position: Vector2) -> Vector2:
	return Vector2(
		clampf(world_position.x, minimum_x(), maximum_x()),
		clampf(world_position.y, minimum_y(), maximum_y())
	)


func contains_actor_position(world_position: Vector2) -> bool:
	return (
		world_position.x >= minimum_x()
		and world_position.x <= maximum_x()
		and world_position.y >= minimum_y()
		and world_position.y <= maximum_y()
	)


func lane_count() -> int:
	return lane_y_positions.size()


func lane_y(requested_lane: int) -> float:
	if lane_y_positions.is_empty():
		return clampf(actor_origin_bounds.get_center().y, minimum_y(), maximum_y())
	return lane_y_positions[clampi(requested_lane, 0, lane_y_positions.size() - 1)]


func nearest_lane_index(world_y: float) -> int:
	if lane_y_positions.is_empty():
		return 0
	var nearest_lane: int = 0
	var nearest_distance: float = absf(world_y - lane_y_positions[0])
	for candidate_lane: int in range(1, lane_y_positions.size()):
		var candidate_distance: float = absf(world_y - lane_y_positions[candidate_lane])
		if candidate_distance < nearest_distance:
			nearest_lane = candidate_lane
			nearest_distance = candidate_distance
	return nearest_lane
