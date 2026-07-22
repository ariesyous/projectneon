class_name RunContentAccessSnapshot
extends RefCounted

## Immutable-by-convention profile/content selection captured before the run's
## first deterministic draw. Replaying the same seed reuses this snapshot.

var selected_crew_id: StringName = &"jax"
var allowed_equipment_ids: Array[StringName] = []
var allowed_card_ids: Array[StringName] = []
var profile_save_version: int = 1
var development_catalogue_access: bool = false


static func create(
	crew_id: StringName,
	equipment_ids: Array[StringName],
	card_ids: Array[StringName],
	save_version: int,
	development_access: bool
) -> RunContentAccessSnapshot:
	var result: RunContentAccessSnapshot = RunContentAccessSnapshot.new()
	result.selected_crew_id = crew_id if crew_id != &"" else &"jax"
	result.allowed_equipment_ids = _stable_unique_ids(equipment_ids)
	result.allowed_card_ids = _stable_unique_ids(card_ids)
	result.profile_save_version = maxi(save_version, 0)
	result.development_catalogue_access = development_access
	return result


func duplicate_snapshot() -> RunContentAccessSnapshot:
	return create(
		selected_crew_id,
		allowed_equipment_ids,
		allowed_card_ids,
		profile_save_version,
		development_catalogue_access
	)


func signature() -> String:
	return "profile:%d|crew:%s|equipment:%s|cards:%s|dev:%s" % [
		profile_save_version,
		String(selected_crew_id),
		_join_ids(allowed_equipment_ids),
		_join_ids(allowed_card_ids),
		"1" if development_catalogue_access else "0",
	]


func to_dictionary() -> Dictionary:
	return {
		"selected_crew_id": selected_crew_id,
		"allowed_equipment_ids": allowed_equipment_ids.duplicate(),
		"allowed_card_ids": allowed_card_ids.duplicate(),
		"profile_save_version": profile_save_version,
		"development_catalogue_access": development_catalogue_access,
		"signature": signature(),
	}


static func _stable_unique_ids(values: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: StringName in values:
		if value != &"" and not result.has(value):
			result.append(value)
	result.sort_custom(_string_name_before)
	return result


static func _join_ids(values: Array[StringName]) -> String:
	var text_values: PackedStringArray = PackedStringArray()
	for value: StringName in values:
		text_values.append(String(value))
	return ",".join(text_values)


static func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
