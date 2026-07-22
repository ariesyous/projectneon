@tool
class_name AudioCueCatalogue
extends Resource

const DISTRICT_MUSIC_ID: StringName = &"music_district_loop"
const BOSS_MUSIC_ID: StringName = &"music_boss_layer"
const REQUIRED_CUE_IDS: Array[StringName] = [
	&"music_boss_layer",
	&"music_district_loop",
	&"sfx_boss_introduction",
	&"sfx_card_placement",
	&"sfx_coin_auto_collect",
	&"sfx_coin_manual_collect",
	&"sfx_coin_streak_increase",
	&"sfx_defeat",
	&"sfx_environment_collision",
	&"sfx_extraction_available",
	&"sfx_heat_tier_increase",
	&"sfx_heavy_hit",
	&"sfx_intervention_activation",
	&"sfx_knockback",
	&"sfx_light_hit",
	&"sfx_night_pressure_warning",
	&"sfx_ui_confirm",
	&"sfx_ui_hover",
	&"sfx_victory",
]

@export var cues: Array[AudioCueDefinition] = []


func get_by_id(cue_id: StringName) -> AudioCueDefinition:
	for cue: AudioCueDefinition in cues:
		if cue != null and cue.id == cue_id:
			return cue
	return null


func get_sorted_cues() -> Array[AudioCueDefinition]:
	var result: Array[AudioCueDefinition] = []
	for cue: AudioCueDefinition in cues:
		if cue != null:
			result.append(cue)
	result.sort_custom(_cue_before)
	return result


func get_sorted_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for cue: AudioCueDefinition in get_sorted_cues():
		result.append(cue.id)
	return result


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if cues.size() != REQUIRED_CUE_IDS.size():
		errors.append(
			"audio catalogue must contain exactly %d cues, found %d"
			% [REQUIRED_CUE_IDS.size(), cues.size()]
		)
	var seen: Dictionary[StringName, bool] = {}
	for cue: AudioCueDefinition in cues:
		if cue == null:
			errors.append("audio catalogue contains a null cue")
			continue
		errors.append_array(cue.validation_errors())
		if cue.id in seen:
			errors.append("audio catalogue repeats cue '%s'" % cue.id)
		seen[cue.id] = true
		if cue.id not in REQUIRED_CUE_IDS:
			errors.append("audio catalogue contains unexpected cue '%s'" % cue.id)
	for required_id: StringName in REQUIRED_CUE_IDS:
		if not seen.has(required_id):
			errors.append("audio catalogue is missing cue '%s'" % required_id)
	var district: AudioCueDefinition = get_by_id(DISTRICT_MUSIC_ID)
	var boss: AudioCueDefinition = get_by_id(BOSS_MUSIC_ID)
	if district == null or not district.loop or district.bus != AudioBusContract.BUS_MUSIC:
		errors.append("district music must be a looping Music cue")
	if boss == null or not boss.loop or boss.bus != AudioBusContract.BUS_MUSIC:
		errors.append("boss variation must be a looping Music cue")
	return errors


static func _cue_before(left: AudioCueDefinition, right: AudioCueDefinition) -> bool:
	return String(left.id) < String(right.id)
