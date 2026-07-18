@tool
class_name PatrolRouteDefinition
extends Resource

## Fixed authored route used by Milestone 3. Node arrays are parallel and are
## read in stable index order; later district-card mutation remains deferred.

@export var id: StringName = &"downtown_loop_route"
@export_range(0.1, 60.0, 0.1) var travel_seconds_per_segment: float = 4.0
@export var node_ids: Array[StringName] = [
	&"arcade_corner",
	&"convenience_store",
	&"alley_crossing",
	&"subway_entrance",
	&"gang_block",
]
@export var node_types: Array[StringName] = [
	&"encounter",
	&"shop",
	&"encounter",
	&"travel",
	&"encounter",
]


func node_count() -> int:
	return mini(node_ids.size(), node_types.size())


func node_id(index: int) -> StringName:
	if node_count() <= 0:
		return &"missing_route_node"
	return node_ids[wrapi(index, 0, node_count())]


func node_type(index: int) -> StringName:
	if node_count() <= 0:
		return &"travel"
	return node_types[wrapi(index, 0, node_count())]
