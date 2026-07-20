@tool
class_name CardResolutionRecord
extends RefCounted

## Typed handoff from CardSystem to RunFlowController. CardSystem latches the
## matching placement as resolved before publishing this value, so callbacks
## cannot resolve the same future effect twice.

var placement_token: int = -1
var card: DistrictCardDefinition
var effect: CardEffectDefinition
var slot_id: StringName = &""
var occurrence_index: int = -1
var route_index: int = -1
var loop_count: int = -1
var node_id: StringName = &""
var baseline_node_type: StringName = &""


func to_dictionary() -> Dictionary:
	return {
		"placement_token": placement_token,
		"card_id": card.id if card != null else &"",
		"card_name": card.display_name if card != null else "",
		"effect_id": effect.id if effect != null else &"",
		"effect_kind": int(effect.kind) if effect != null else -1,
		"slot_id": slot_id,
		"occurrence_index": occurrence_index,
		"route_index": route_index,
		"loop_count": loop_count,
		"node_id": node_id,
		"baseline_node_type": baseline_node_type,
	}
