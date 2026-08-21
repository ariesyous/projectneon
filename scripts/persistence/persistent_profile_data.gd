@tool
class_name PersistentProfileData
extends Resource

## Version-one profile facts remain byte-compatible with Milestone 6. WP02
## changes crew access policy without rewriting historical Zoey/Rex facts.

const SAVE_VERSION: int = 1

const CREW_JAX: StringName = &"jax"
const CREW_ZOEY: StringName = &"zoey"
const CREW_REX: StringName = &"rex"
const EQUIPMENT_HACKER_DECK: StringName = &"hacker_deck"
const CARD_GANG_HIDEOUT: StringName = &"gang_hideout"

const ALL_CREW_IDS: Array[StringName] = [&"jax", &"rex", &"zoey"]
const ALL_EQUIPMENT_IDS: Array[StringName] = [
	&"chain_sneakers",
	&"hacker_deck",
	&"magnetic_flail",
	&"reinforced_jacket",
	&"serrated_wraps",
	&"shock_gloves",
	&"spiked_bat",
	&"steel_toe_boots",
	&"voltaic_blade",
]
const ALL_CARD_IDS: Array[StringName] = [
	&"arcade",
	&"convenience_store",
	&"gang_hideout",
	&"subway_entrance",
]
const PRODUCTION_DEFAULT_CREW_IDS: Array[StringName] = [&"jax"]
const PRODUCTION_ACCESS_CREW_IDS: Array[StringName] = ALL_CREW_IDS
const PRODUCTION_DEFAULT_EQUIPMENT_IDS: Array[StringName] = [
	&"chain_sneakers",
	&"magnetic_flail",
	&"reinforced_jacket",
	&"serrated_wraps",
	&"shock_gloves",
	&"spiked_bat",
	&"steel_toe_boots",
	&"voltaic_blade",
]
const PRODUCTION_DEFAULT_CARD_IDS: Array[StringName] = [
	&"arcade",
	&"convenience_store",
	&"subway_entrance",
]

@export var save_version: int = SAVE_VERSION
@export var unlocked_crew_ids: Array[StringName] = PRODUCTION_DEFAULT_CREW_IDS.duplicate()
@export var unlocked_equipment_ids: Array[StringName] = (
	PRODUCTION_DEFAULT_EQUIPMENT_IDS.duplicate()
)
@export var unlocked_card_ids: Array[StringName] = PRODUCTION_DEFAULT_CARD_IDS.duplicate()
@export var lifetime_statistics: LifetimeStatisticsData = LifetimeStatisticsData.new()
@export var settings: GameSettingsData = GameSettingsData.create_default()


static func create_default() -> PersistentProfileData:
	return PersistentProfileData.new()


static func from_dictionary(raw_value: Variant) -> PersistentProfileData:
	var result: PersistentProfileData = create_default()
	if not raw_value is Dictionary:
		return result
	var values: Dictionary = raw_value as Dictionary
	result.save_version = SAVE_VERSION
	result.unlocked_crew_ids = _read_ids(
		values,
		"unlocked_crew_ids",
		ALL_CREW_IDS,
		PRODUCTION_DEFAULT_CREW_IDS
	)
	result.unlocked_equipment_ids = _read_ids(
		values,
		"unlocked_equipment_ids",
		ALL_EQUIPMENT_IDS,
		PRODUCTION_DEFAULT_EQUIPMENT_IDS
	)
	result.unlocked_card_ids = _read_ids(
		values,
		"unlocked_card_ids",
		ALL_CARD_IDS,
		PRODUCTION_DEFAULT_CARD_IDS
	)
	result.lifetime_statistics = LifetimeStatisticsData.from_dictionary(
		values.get("lifetime_statistics", {})
	)
	result.settings = GameSettingsData.from_dictionary(values.get("settings", {}))
	return result


func duplicate_profile() -> PersistentProfileData:
	return PersistentProfileData.from_dictionary(to_dictionary())


func to_dictionary() -> Dictionary:
	_sanitize_unlocks()
	if lifetime_statistics == null:
		lifetime_statistics = LifetimeStatisticsData.new()
	if settings == null:
		settings = GameSettingsData.create_default()
	return {
		"save_version": SAVE_VERSION,
		"unlocked_crew_ids": _ids_to_strings(unlocked_crew_ids),
		"unlocked_equipment_ids": _ids_to_strings(unlocked_equipment_ids),
		"unlocked_card_ids": _ids_to_strings(unlocked_card_ids),
		"lifetime_statistics": lifetime_statistics.to_dictionary(),
		"settings": settings.to_dictionary(),
	}


func unlock_content(content_kind: StringName, content_id: StringName) -> bool:
	var destination: Array[StringName]
	var permitted: Array[StringName]
	match content_kind:
		&"crew":
			destination = unlocked_crew_ids
			permitted = ALL_CREW_IDS
		&"equipment":
			destination = unlocked_equipment_ids
			permitted = ALL_EQUIPMENT_IDS
		&"card":
			destination = unlocked_card_ids
			permitted = ALL_CARD_IDS
		_:
			return false
	if content_id not in permitted or content_id in destination:
		return false
	destination.append(content_id)
	destination.sort_custom(_string_name_before)
	return true


func get_accessible_crew_ids(development_full_access: bool) -> Array[StringName]:
	# All three core play styles are available on first launch. Keep the stored
	# unlock array as a historical v1 ledger so merely loading an old profile
	# never invents or rewrites Zoey/Rex facts.
	return _copy_ids(ALL_CREW_IDS if development_full_access else PRODUCTION_ACCESS_CREW_IDS)


func get_accessible_equipment_ids(development_full_access: bool) -> Array[StringName]:
	return _copy_ids(ALL_EQUIPMENT_IDS if development_full_access else unlocked_equipment_ids)


func get_accessible_card_ids(development_full_access: bool) -> Array[StringName]:
	return _copy_ids(ALL_CARD_IDS if development_full_access else unlocked_card_ids)


func _sanitize_unlocks() -> void:
	unlocked_crew_ids = _sanitize_ids(
		unlocked_crew_ids,
		ALL_CREW_IDS,
		PRODUCTION_DEFAULT_CREW_IDS
	)
	unlocked_equipment_ids = _sanitize_ids(
		unlocked_equipment_ids,
		ALL_EQUIPMENT_IDS,
		PRODUCTION_DEFAULT_EQUIPMENT_IDS
	)
	unlocked_card_ids = _sanitize_ids(
		unlocked_card_ids,
		ALL_CARD_IDS,
		PRODUCTION_DEFAULT_CARD_IDS
	)


static func _read_ids(
	values: Dictionary,
	key: String,
	permitted: Array[StringName],
	fallback: Array[StringName]
) -> Array[StringName]:
	var raw_ids: Variant = values.get(key, null)
	if not raw_ids is Array:
		return _copy_ids(fallback)
	var parsed: Array[StringName] = []
	for raw_id: Variant in raw_ids as Array:
		if raw_id is String or raw_id is StringName:
			parsed.append(StringName(String(raw_id)))
	return _sanitize_ids(parsed, permitted, fallback)


static func _sanitize_ids(
	values: Array[StringName],
	permitted: Array[StringName],
	required_defaults: Array[StringName]
) -> Array[StringName]:
	var result: Array[StringName] = []
	for required_id: StringName in required_defaults:
		if required_id in permitted and required_id not in result:
			result.append(required_id)
	for content_id: StringName in values:
		if content_id in permitted and content_id not in result:
			result.append(content_id)
	result.sort_custom(_string_name_before)
	return result


static func _copy_ids(values: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = values.duplicate()
	result.sort_custom(_string_name_before)
	return result


static func _ids_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for content_id: StringName in values:
		result.append(String(content_id))
	return result


static func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
