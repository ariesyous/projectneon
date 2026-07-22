@tool
class_name AudioBusContract
extends RefCounted

## Stable presentation bus ownership. Runtime creation keeps the foundation
## self-contained until project.godot selects a versioned bus-layout resource.

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SOUND_EFFECTS: StringName = &"SFX"
const SILENT_DB: float = -80.0


static func ensure_required_buses() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SOUND_EFFECTS)


static func apply_volume_settings(settings: GameSettingsData) -> void:
	ensure_required_buses()
	var safe_settings: GameSettingsData = (
		settings.sanitized_copy() if settings != null else GameSettingsData.create_default()
	)
	_set_bus_linear_volume(BUS_MASTER, safe_settings.master_volume)
	_set_bus_linear_volume(BUS_MUSIC, safe_settings.music_volume)
	_set_bus_linear_volume(BUS_SOUND_EFFECTS, safe_settings.sound_effects_volume)


static func get_linear_volume(bus_name: StringName) -> float:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)


static func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, BUS_MASTER)


static func _set_bus_linear_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var safe_volume: float = clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, safe_volume <= 0.0)
	AudioServer.set_bus_volume_db(
		bus_index,
		SILENT_DB if safe_volume <= 0.0 else linear_to_db(safe_volume)
	)
