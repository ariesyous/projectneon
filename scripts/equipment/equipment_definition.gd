@tool
class_name EquipmentDefinition
extends Resource

## Stable catalogue entry for one generic equipment slot.

@export var id: StringName
@export var display_name: String = "Equipment"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var tags: Array[StringName] = []
@export var modifiers: Array[EquipmentModifierDefinition] = []
@export var triggered_effects: Array[TriggeredEffectDefinition] = []
@export var major_effects: PackedStringArray = PackedStringArray()


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("equipment id is empty")
	if display_name.strip_edges().is_empty():
		errors.append("equipment '%s' has no display name" % id)
	if tags.is_empty():
		errors.append("equipment '%s' has no tags" % id)
	if modifiers.is_empty() and triggered_effects.is_empty():
		errors.append("equipment '%s' has no functional effect" % id)
	if major_effects.is_empty():
		errors.append("equipment '%s' has no player-facing major effects" % id)

	var seen_tags: Dictionary[StringName, bool] = {}
	for tag: StringName in tags:
		if tag == &"":
			errors.append("equipment '%s' contains an empty tag" % id)
		elif seen_tags.has(tag):
			errors.append("equipment '%s' repeats tag '%s'" % [id, tag])
		seen_tags[tag] = true

	var seen_component_ids: Dictionary[StringName, bool] = {}
	for modifier: EquipmentModifierDefinition in modifiers:
		if modifier == null:
			errors.append("equipment '%s' contains a null modifier" % id)
			continue
		if seen_component_ids.has(modifier.id):
			errors.append("equipment '%s' repeats component id '%s'" % [id, modifier.id])
		seen_component_ids[modifier.id] = true
		errors.append_array(modifier.validation_errors())
	for effect: TriggeredEffectDefinition in triggered_effects:
		if effect == null:
			errors.append("equipment '%s' contains a null triggered effect" % id)
			continue
		if seen_component_ids.has(effect.id):
			errors.append("equipment '%s' repeats component id '%s'" % [id, effect.id])
		seen_component_ids[effect.id] = true
		errors.append_array(effect.validation_errors())
	return errors


func sorted_tags() -> Array[StringName]:
	var result: Array[StringName] = tags.duplicate()
	result.sort_custom(_string_name_before)
	return result


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
