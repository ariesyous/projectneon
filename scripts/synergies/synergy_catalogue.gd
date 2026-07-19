@tool
class_name SynergyCatalogue
extends Resource

@export var synergies: Array[SynergyDefinition] = []


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var seen_ids: Dictionary[StringName, bool] = {}
	for synergy: SynergyDefinition in synergies:
		if synergy == null:
			errors.append("synergy catalogue contains a null definition")
			continue
		if seen_ids.has(synergy.id):
			errors.append("synergy catalogue repeats id '%s'" % synergy.id)
		seen_ids[synergy.id] = true
		errors.append_array(synergy.validation_errors())
	return errors


func get_sorted_synergies() -> Array[SynergyDefinition]:
	var result: Array[SynergyDefinition] = []
	for synergy: SynergyDefinition in synergies:
		if synergy != null:
			result.append(synergy)
	result.sort_custom(_synergy_before)
	return result


func _synergy_before(left: SynergyDefinition, right: SynergyDefinition) -> bool:
	if left.required_tag == right.required_tag:
		if left.threshold == right.threshold:
			return String(left.id) < String(right.id)
		return left.threshold < right.threshold
	return String(left.required_tag) < String(right.required_tag)
