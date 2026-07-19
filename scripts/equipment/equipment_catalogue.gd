@tool
class_name EquipmentCatalogue
extends Resource

@export var items: Array[EquipmentDefinition] = []


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var seen_ids: Dictionary[StringName, bool] = {}
	for item: EquipmentDefinition in items:
		if item == null:
			errors.append("equipment catalogue contains a null item")
			continue
		if seen_ids.has(item.id):
			errors.append("equipment catalogue repeats id '%s'" % item.id)
		seen_ids[item.id] = true
		errors.append_array(item.validation_errors())
	return errors


func get_by_id(equipment_id: StringName) -> EquipmentDefinition:
	for item: EquipmentDefinition in items:
		if item != null and item.id == equipment_id:
			return item
	return null


func get_sorted_items() -> Array[EquipmentDefinition]:
	var result: Array[EquipmentDefinition] = []
	for item: EquipmentDefinition in items:
		if item != null:
			result.append(item)
	result.sort_custom(_equipment_before)
	return result


func _equipment_before(left: EquipmentDefinition, right: EquipmentDefinition) -> bool:
	return String(left.id) < String(right.id)
