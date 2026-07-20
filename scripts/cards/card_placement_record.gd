@tool
class_name CardPlacementRecord
extends RefCounted

## Immutable-by-convention authority record for one confirmed card placement.
## The card leaves the hand when this record is created; its future effect is
## still pending until the matching route occurrence is reached.

var placement_token: int = -1
var card: DistrictCardDefinition
var slot_id: StringName = &""
var occurrence_index: int = -1
var route_index: int = -1
var loop_count: int = -1
var node_id: StringName = &""
var node_type: StringName = &""
var hand_revision: int = -1
var route_revision: int = -1
var resolved: bool = false


func to_dictionary() -> Dictionary:
	return {
		"placement_token": placement_token,
		"card_id": card.id if card != null else &"",
		"card_name": card.display_name if card != null else "",
		"effect_id": (
			card.effect_definition.id
			if card != null and card.effect_definition != null
			else &""
		),
		"slot_id": slot_id,
		"occurrence_index": occurrence_index,
		"route_index": route_index,
		"loop_count": loop_count,
		"node_id": node_id,
		"node_type": node_type,
		"hand_revision": hand_revision,
		"route_revision": route_revision,
		"resolved": resolved,
	}
