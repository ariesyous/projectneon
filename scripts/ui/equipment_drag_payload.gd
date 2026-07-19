@tool
class_name EquipmentDragPayload
extends RefCounted

## Typed, presentation-only description of one equipment drag. Gameplay
## authorities never receive this object; GameHUD validates it and forwards the
## existing revisioned typed intent only after the player confirms.

enum Origin {
	INVENTORY,
	REWARD,
}

var origin: Origin = Origin.INVENTORY
var source_area: StringName = &""
var source_slot: int = -1
var choice_index: int = -1
var equipment_id: StringName = &""
var display_name: String = ""
var inventory_revision: int = -1
var encounter_id: int = -1
var icon: Texture2D


func _init(
	new_origin: Origin = Origin.INVENTORY,
	new_source_area: StringName = &"",
	new_source_slot: int = -1,
	new_choice_index: int = -1,
	new_equipment_id: StringName = &"",
	new_display_name: String = "",
	new_inventory_revision: int = -1,
	new_encounter_id: int = -1,
	new_icon: Texture2D = null
) -> void:
	origin = new_origin
	source_area = new_source_area
	source_slot = new_source_slot
	choice_index = new_choice_index
	equipment_id = new_equipment_id
	display_name = new_display_name
	inventory_revision = new_inventory_revision
	encounter_id = new_encounter_id
	icon = new_icon


func is_valid() -> bool:
	if equipment_id == &"" or display_name.strip_edges().is_empty():
		return false
	if origin == Origin.INVENTORY:
		return source_area != &"" and source_slot >= 0 and inventory_revision >= 0
	if origin == Origin.REWARD:
		return choice_index >= 0 and encounter_id >= 0 and inventory_revision >= 0
	return false
