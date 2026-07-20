class_name RouteModificationRecord
extends RefCounted

## Typed runtime record for one card-owned route modification. Callers receive
## copies so PatrolController remains the only mutation authority.

const STATE_PENDING: StringName = &"pending"
const STATE_RESOLVED: StringName = &"resolved"
const STATE_EXPIRED: StringName = &"expired"

var slot_id: StringName = &""
var occurrence_index: int = -1
var occurrence_id: StringName = &""
var route_index: int = -1
var loop_count: int = 0
var node_id: StringName = &""
var node_type: StringName = &""
var card_id: StringName = &""
var effect_id: StringName = &""
var placement_token: int = -1
var applied_route_revision: int = 0
var resolved_route_revision: int = -1
var state: StringName = STATE_PENDING


func duplicate_record() -> RouteModificationRecord:
	var result: RouteModificationRecord = RouteModificationRecord.new()
	result.slot_id = slot_id
	result.occurrence_index = occurrence_index
	result.occurrence_id = occurrence_id
	result.route_index = route_index
	result.loop_count = loop_count
	result.node_id = node_id
	result.node_type = node_type
	result.card_id = card_id
	result.effect_id = effect_id
	result.placement_token = placement_token
	result.applied_route_revision = applied_route_revision
	result.resolved_route_revision = resolved_route_revision
	result.state = state
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
		"card_id": card_id,
		"effect_id": effect_id,
		"placement_token": placement_token,
		"applied_route_revision": applied_route_revision,
		"resolved_route_revision": resolved_route_revision,
		"state": state,
	}
