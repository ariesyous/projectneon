@tool
class_name GameSettingsData
extends Resource

## Version-1 presentation and accessibility settings. Values are normalized so
## callers can safely apply profiles written by older or hand-edited builds.

const DEFAULT_MASTER_VOLUME: float = 0.8
const DEFAULT_MUSIC_VOLUME: float = 0.65
const DEFAULT_SOUND_EFFECTS_VOLUME: float = 0.8
const DEFAULT_FULLSCREEN: bool = false
const DEFAULT_SCREEN_SHAKE_INTENSITY: float = 0.75
const DEFAULT_DAMAGE_NUMBERS_ENABLED: bool = true
const DEFAULT_HIT_FLASH_REDUCTION: float = 0.0
const DEFAULT_PAUSE_ON_FOCUS_LOSS: bool = true

@export_range(0.0, 1.0, 0.01) var master_volume: float = DEFAULT_MASTER_VOLUME
@export_range(0.0, 1.0, 0.01) var music_volume: float = DEFAULT_MUSIC_VOLUME
@export_range(0.0, 1.0, 0.01) var sound_effects_volume: float = (
	DEFAULT_SOUND_EFFECTS_VOLUME
)
@export var fullscreen: bool = DEFAULT_FULLSCREEN
@export_range(0.0, 1.0, 0.01) var screen_shake_intensity: float = (
	DEFAULT_SCREEN_SHAKE_INTENSITY
)
@export var damage_numbers_enabled: bool = DEFAULT_DAMAGE_NUMBERS_ENABLED
@export_range(0.0, 1.0, 0.01) var hit_flash_reduction: float = (
	DEFAULT_HIT_FLASH_REDUCTION
)
@export var pause_on_focus_loss: bool = DEFAULT_PAUSE_ON_FOCUS_LOSS


static func create_default() -> GameSettingsData:
	return GameSettingsData.new()


static func from_dictionary(raw_value: Variant) -> GameSettingsData:
	var result: GameSettingsData = create_default()
	if not raw_value is Dictionary:
		return result
	var values: Dictionary = raw_value as Dictionary
	result.master_volume = _read_unit_float(
		values,
		"master_volume",
		DEFAULT_MASTER_VOLUME
	)
	result.music_volume = _read_unit_float(values, "music_volume", DEFAULT_MUSIC_VOLUME)
	result.sound_effects_volume = _read_unit_float(
		values,
		"sound_effects_volume",
		DEFAULT_SOUND_EFFECTS_VOLUME
	)
	result.fullscreen = _read_bool(values, "fullscreen", DEFAULT_FULLSCREEN)
	result.screen_shake_intensity = _read_unit_float(
		values,
		"screen_shake_intensity",
		DEFAULT_SCREEN_SHAKE_INTENSITY
	)
	result.damage_numbers_enabled = _read_bool(
		values,
		"damage_numbers_enabled",
		DEFAULT_DAMAGE_NUMBERS_ENABLED
	)
	result.hit_flash_reduction = _read_unit_float(
		values,
		"hit_flash_reduction",
		DEFAULT_HIT_FLASH_REDUCTION
	)
	result.pause_on_focus_loss = _read_bool(
		values,
		"pause_on_focus_loss",
		DEFAULT_PAUSE_ON_FOCUS_LOSS
	)
	return result


func sanitized_copy() -> GameSettingsData:
	return GameSettingsData.from_dictionary(to_dictionary())


func sanitize() -> void:
	master_volume = clampf(master_volume, 0.0, 1.0)
	music_volume = clampf(music_volume, 0.0, 1.0)
	sound_effects_volume = clampf(sound_effects_volume, 0.0, 1.0)
	screen_shake_intensity = clampf(screen_shake_intensity, 0.0, 1.0)
	hit_flash_reduction = clampf(hit_flash_reduction, 0.0, 1.0)


func to_dictionary() -> Dictionary:
	sanitize()
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sound_effects_volume": sound_effects_volume,
		"fullscreen": fullscreen,
		"screen_shake_intensity": screen_shake_intensity,
		"damage_numbers_enabled": damage_numbers_enabled,
		"hit_flash_reduction": hit_flash_reduction,
		"pause_on_focus_loss": pause_on_focus_loss,
	}


static func _read_unit_float(values: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = values.get(key, fallback)
	if value is float or value is int:
		return clampf(float(value), 0.0, 1.0)
	return fallback


static func _read_bool(values: Dictionary, key: String, fallback: bool) -> bool:
	var value: Variant = values.get(key, fallback)
	return bool(value) if value is bool else fallback
