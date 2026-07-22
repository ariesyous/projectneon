@tool
class_name GeneratedAudioStreamFactory
extends RefCounted

## Fixed mathematical synthesis for replaceable prototype audio. It performs no
## random draws and cannot affect gameplay stream state or outcomes.

const SAMPLE_RATE: int = 22050
const MAX_PCM_VALUE: float = 32767.0


static func build_stream(definition: AudioCueDefinition) -> AudioStreamWAV:
	if definition == null:
		return null
	var sample_count: int = maxi(int(round(definition.duration_seconds * SAMPLE_RATE)), 1)
	var pcm_data: PackedByteArray = PackedByteArray()
	pcm_data.resize(sample_count * 2)
	for sample_index: int in range(sample_count):
		var time_seconds: float = float(sample_index) / float(SAMPLE_RATE)
		var frequency_hz: float = definition.frequency_at(time_seconds)
		var phase: float = TAU * frequency_hz * time_seconds
		var sample: float = _wave_value(definition.waveform, phase)
		if definition.secondary_frequency_ratio > 0.0:
			var secondary_phase: float = phase * definition.secondary_frequency_ratio
			sample = sample * 0.72 + _wave_value(definition.waveform, secondary_phase) * 0.28
		var envelope: float = _envelope(definition, time_seconds)
		var signed_sample: int = int(
			round(clampf(sample * definition.gain * envelope, -1.0, 1.0) * MAX_PCM_VALUE)
		)
		pcm_data.encode_s16(sample_index * 2, signed_sample)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm_data
	if definition.loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream


static func _wave_value(waveform: AudioCueDefinition.Waveform, phase: float) -> float:
	match waveform:
		AudioCueDefinition.Waveform.SINE:
			return sin(phase)
		AudioCueDefinition.Waveform.TRIANGLE:
			return (2.0 / PI) * asin(sin(phase))
		AudioCueDefinition.Waveform.SQUARE:
			return 1.0 if sin(phase) >= 0.0 else -1.0
	return 0.0


static func _envelope(definition: AudioCueDefinition, time_seconds: float) -> float:
	if definition.loop:
		return 1.0
	var attack: float = 1.0
	if definition.attack_seconds > 0.0:
		attack = clampf(time_seconds / definition.attack_seconds, 0.0, 1.0)
	var release: float = 1.0
	if definition.release_seconds > 0.0:
		var remaining: float = definition.duration_seconds - time_seconds
		release = clampf(remaining / definition.release_seconds, 0.0, 1.0)
	return minf(attack, release)
