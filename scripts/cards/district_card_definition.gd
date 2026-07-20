@tool
class_name DistrictCardDefinition
extends Resource

## Stable authored District Card content. CardSystem owns every collection and
## transaction; this Resource contains presentation and typed effect data only.

const NODE_TYPE_TRAVEL: StringName = &"travel"
const NODE_TYPE_ENCOUNTER: StringName = &"encounter"
const VALID_BASELINE_NODE_TYPES: Array[StringName] = [
	NODE_TYPE_TRAVEL,
	NODE_TYPE_ENCOUNTER,
]
const FREE_COST_LABEL: String = "FREE"

@export var id: StringName
@export var display_name: String = "District Card"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_range(0, 999, 1) var cost: int = 0
@export_range(-100, 100, 1) var heat_delta: int = 0
@export var valid_node_types: Array[StringName] = []
@export var tags: Array[StringName] = []
@export_multiline var progression_implications: String = ""
@export var effect_definition: CardEffectDefinition


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not _is_valid_stable_id(id):
		errors.append("district-card id '%s' must be lowercase snake_case" % id)
	if display_name.strip_edges().is_empty():
		errors.append("district card '%s' has no display name" % id)
	if description.strip_edges().is_empty():
		errors.append("district card '%s' has no description" % id)
	if icon == null:
		errors.append("district card '%s' has no icon" % id)
	if cost != 0:
		errors.append("district card '%s' must be FREE during Milestone 5" % id)
	if heat_delta == 0:
		errors.append("district card '%s' has no authored Heat change" % id)
	if progression_implications.strip_edges().is_empty():
		errors.append("district card '%s' has no progression implication text" % id)
	_validate_node_types(errors)
	_validate_tags(errors)
	if effect_definition == null:
		errors.append("district card '%s' has no effect definition" % id)
	else:
		errors.append_array(effect_definition.validation_errors())
	return errors


func cost_label() -> String:
	if cost == 0:
		return FREE_COST_LABEL
	return str(cost)


func supports_node_type(node_type: StringName) -> bool:
	return node_type in valid_node_types


func sorted_tags() -> Array[StringName]:
	var result: Array[StringName] = tags.duplicate()
	result.sort_custom(_string_name_before)
	return result


func _validate_node_types(errors: PackedStringArray) -> void:
	if valid_node_types.is_empty():
		errors.append("district card '%s' has no valid node types" % id)
		return
	var seen_node_types: Dictionary[StringName, bool] = {}
	for node_type: StringName in valid_node_types:
		if node_type not in VALID_BASELINE_NODE_TYPES:
			errors.append("district card '%s' has invalid node type '%s'" % [id, node_type])
		elif seen_node_types.has(node_type):
			errors.append("district card '%s' repeats node type '%s'" % [id, node_type])
		seen_node_types[node_type] = true


func _validate_tags(errors: PackedStringArray) -> void:
	if tags.is_empty():
		errors.append("district card '%s' has no tags" % id)
		return
	var seen_tags: Dictionary[StringName, bool] = {}
	for tag: StringName in tags:
		if not _is_valid_tag(tag):
			errors.append("district card '%s' has invalid tag '%s'" % [id, tag])
		elif seen_tags.has(tag):
			errors.append("district card '%s' repeats tag '%s'" % [id, tag])
		seen_tags[tag] = true


func _is_valid_stable_id(value: StringName) -> bool:
	var text: String = String(value)
	if text.is_empty() or text.begins_with("_") or text.ends_with("_") or text.contains("__"):
		return false
	for index: int in range(text.length()):
		var code: int = text.unicode_at(index)
		var is_lowercase_letter: bool = code >= 97 and code <= 122
		var is_digit: bool = code >= 48 and code <= 57
		if not is_lowercase_letter and not is_digit and code != 95:
			return false
	return true


func _is_valid_tag(value: StringName) -> bool:
	var text: String = String(value)
	if text.is_empty() or text.begins_with("_") or text.ends_with("_") or text.contains("__"):
		return false
	for index: int in range(text.length()):
		var code: int = text.unicode_at(index)
		var is_uppercase_letter: bool = code >= 65 and code <= 90
		var is_digit: bool = code >= 48 and code <= 57
		if not is_uppercase_letter and not is_digit and code != 95:
			return false
	return true


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
