@tool
class_name AudioCueDefinition
extends Resource

enum Waveform {
	SINE,
	TRIANGLE,
	SQUARE,
}

@export var id: StringName = &""
@export var bus: StringName = AudioBusContract.BUS_SOUND_EFFECTS
@export var waveform: Waveform = Waveform.SINE
@export_range(30.0, 4000.0, 1.0) var base_frequency_hz: float = 440.0
@export var note_pattern_hz: PackedFloat32Array = PackedFloat32Array()
@export_range(0.02, 2.0, 0.01) var note_seconds: float = 0.16
@export_range(0.02, 16.0, 0.01) var duration_seconds: float = 0.2
@export_range(0.0, 1.0, 0.01) var gain: float = 0.35
@export_range(0.0, 4.0, 0.01) var secondary_frequency_ratio: float = 0.0
@export_range(0.0, 0.2, 0.001) var attack_seconds: float = 0.005
@export_range(0.0, 0.5, 0.001) var release_seconds: float = 0.04
@export var loop: bool = false


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not _is_lower_snake_case(id):
		errors.append("audio cue id must be lowercase snake_case")
	if bus not in [AudioBusContract.BUS_MUSIC, AudioBusContract.BUS_SOUND_EFFECTS]:
		errors.append("audio cue '%s' uses unsupported bus '%s'" % [id, bus])
	if base_frequency_hz <= 0.0:
		errors.append("audio cue '%s' needs a positive base frequency" % id)
	if duration_seconds <= 0.0:
		errors.append("audio cue '%s' needs a positive duration" % id)
	if gain <= 0.0 or gain > 1.0:
		errors.append("audio cue '%s' gain must be within (0, 1]" % id)
	if loop and bus != AudioBusContract.BUS_MUSIC:
		errors.append("only Music cues may loop")
	return errors


func frequency_at(time_seconds: float) -> float:
	if note_pattern_hz.is_empty():
		return base_frequency_hz
	var safe_note_seconds: float = maxf(note_seconds, 0.001)
	var note_index: int = int(floor(time_seconds / safe_note_seconds)) % note_pattern_hz.size()
	return maxf(note_pattern_hz[note_index], 1.0)


static func _is_lower_snake_case(value: StringName) -> bool:
	var text: String = String(value)
	return (
		not text.is_empty()
		and text == text.to_lower()
		and text == text.to_snake_case()
		and not text.begins_with("_")
		and not text.ends_with("_")
	)
