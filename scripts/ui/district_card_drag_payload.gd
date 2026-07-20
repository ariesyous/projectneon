@tool
class_name DistrictCardDragPayload
extends RefCounted

## Typed, presentation-only description of one district-card drag. The HUD
## uses the captured revisions to stage intent; CardSystem and PatrolController
## remain the only authorities that may accept or mutate it.

enum Origin {
	HAND,
	REWARD,
}

var origin: Origin = Origin.HAND
var source_index: int = -1
var card_id: StringName = &""
var display_name: String = ""
var hand_revision: int = -1
var route_revision: int = -1
var encounter_id: int = -1
var choice_token: int = -1
var heat_delta: int = 0
var effect_summary: String = ""
var icon: Texture2D


func _init(
	new_origin: Origin = Origin.HAND,
	new_source_index: int = -1,
	new_card_id: StringName = &"",
	new_display_name: String = "",
	new_hand_revision: int = -1,
	new_route_revision: int = -1,
	new_encounter_id: int = -1,
	new_choice_token: int = -1,
	new_heat_delta: int = 0,
	new_effect_summary: String = "",
	new_icon: Texture2D = null
) -> void:
	origin = new_origin
	source_index = new_source_index
	card_id = new_card_id
	display_name = new_display_name
	hand_revision = new_hand_revision
	route_revision = new_route_revision
	encounter_id = new_encounter_id
	choice_token = new_choice_token
	heat_delta = new_heat_delta
	effect_summary = new_effect_summary
	icon = new_icon


func is_valid() -> bool:
	if (
		card_id == &""
		or display_name.strip_edges().is_empty()
		or source_index < 0
		or hand_revision < 0
	):
		return false
	if origin == Origin.HAND:
		return route_revision >= 0
	if origin == Origin.REWARD:
		return encounter_id >= 0 and choice_token >= 0
	return false
