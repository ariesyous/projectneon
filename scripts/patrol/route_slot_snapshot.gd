class_name RouteSlotSnapshot
extends RefCounted

## Immutable-style view of one fixed future route occurrence. PatrolController
## creates fresh snapshots so presentation never receives route authority.

var slot_id: StringName = &""
var occurrence_index: int = -1
var occurrence_id: StringName = &""
var route_index: int = -1
var loop_count: int = 0
var node_id: StringName = &""
var node_type: StringName = &""
var route_revision: int = 0
var status: StringName = &"invalid"
var occupied_card_id: StringName = &""
var occupied_effect_id: StringName = &""
var placement_token: int = -1


func _init(
	new_slot_id: StringName = &"",
	new_occurrence_index: int = -1,
	new_occurrence_id: StringName = &"",
	new_route_index: int = -1,
	new_loop_count: int = 0,
	new_node_id: StringName = &"",
	new_node_type: StringName = &"",
	new_route_revision: int = 0,
	new_status: StringName = &"invalid"
) -> void:
	slot_id = new_slot_id
	occurrence_index = new_occurrence_index
	occurrence_id = new_occurrence_id
	route_index = new_route_index
	loop_count = new_loop_count
	node_id = new_node_id
	node_type = new_node_type
	route_revision = new_route_revision
	status = new_status


func duplicate_snapshot() -> RouteSlotSnapshot:
	var result: RouteSlotSnapshot = RouteSlotSnapshot.new(
		slot_id,
		occurrence_index,
		occurrence_id,
		route_index,
		loop_count,
		node_id,
		node_type,
		route_revision,
		status
	)
	result.occupied_card_id = occupied_card_id
	result.occupied_effect_id = occupied_effect_id
	result.placement_token = placement_token
	return result


func to_dictionary() -> Dictionary:
	return {
		"slot_id": slot_id,
		"occurrence_index": occurrence_index,
		"occurrence_id": occurrence_id,
		"route_index": route_index,
		"loop_count": loop_count,
		"node_id": node_id,
		"node_type": node_type,
		"route_revision": route_revision,
		"status": status,
		"occupied_card_id": occupied_card_id,
		"occupied_effect_id": occupied_effect_id,
		"placement_token": placement_token,
	}
