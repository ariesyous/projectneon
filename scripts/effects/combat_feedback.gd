class_name CombatFeedback
extends Node2D

## Replaceable Milestone 1 combat presentation. This node receives resolved
## events, owns no combat or reward state, and never uses gameplay randomness.

const HIT_SPARK_SCENE: PackedScene = preload("res://scenes/effects/hit_spark.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/effects/damage_number.tscn")

const MAX_LIVE_TRANSIENTS: int = 48
const AUDIO_MIX_RATE: int = 22050

const LIGHT_HIT_COLOR: Color = Color(1.0, 0.88, 0.30, 1.0)
const HEAVY_HIT_COLOR: Color = Color(1.0, 0.30, 0.68, 1.0)
const DEATH_COLOR: Color = Color(1.0, 0.24, 0.62, 1.0)
const SPAWN_COLOR: Color = Color(0.22, 0.90, 1.0, 1.0)
const WATER_COLOR: Color = Color(0.20, 0.84, 1.0, 1.0)
const WATER_CORE_COLOR: Color = Color(0.82, 1.0, 1.0, 1.0)
const CORE_COLOR: Color = Color(1.0, 1.0, 0.86, 1.0)

@onready var hit_audio: AudioStreamPlayer = $HitAudio
@onready var death_audio: AudioStreamPlayer = $DeathAudio
@onready var coin_audio: AudioStreamPlayer = $CoinAudio
@onready var streak_audio: AudioStreamPlayer = $StreakAudio
@onready var hydrant_activation_audio: AudioStreamPlayer = $HydrantActivationAudio
@onready var hydrant_impact_audio: AudioStreamPlayer = $HydrantImpactAudio
@onready var hydrant_rejection_audio: AudioStreamPlayer = $HydrantRejectionAudio
@onready var audio_unlock_audio: AudioStreamPlayer = $AudioUnlockAudio

var _damage_numbers_enabled: bool = true

var _light_hit_stream: AudioStreamWAV
var _heavy_hit_stream: AudioStreamWAV
var _death_stream: AudioStreamWAV
var _manual_coin_stream: AudioStreamWAV
var _auto_coin_stream: AudioStreamWAV
var _streak_stream: AudioStreamWAV
var _hydrant_activation_stream: AudioStreamWAV
var _hydrant_impact_stream: AudioStreamWAV
var _hydrant_rejection_stream: AudioStreamWAV
var _audio_unlock_stream: AudioStreamWAV
var _live_transients: Array[CanvasItem] = []
var _audio_primed: bool = false


func _ready() -> void:
	_build_reusable_audio()
	_register_web_audio_samples()


## Spawns one spark and one damage number, and plays exactly one hit sound.
func show_hit(world_position: Vector2, damage: float, heavy: bool = false) -> void:
	_spawn_spark(
		world_position,
		HEAVY_HIT_COLOR if heavy else LIGHT_HIT_COLOR,
		CORE_COLOR,
		14.0 if heavy else 10.0,
		0.19 if heavy else 0.14,
		heavy
	)
	if _damage_numbers_enabled:
		_spawn_damage_number(world_position, damage, heavy)
	play_hit(heavy)


## Spawns the death burst and plays exactly one death sound.
func show_death(world_position: Vector2) -> void:
	_spawn_spark(world_position, DEATH_COLOR, CORE_COLOR, 20.0, 0.32, true)
	play_death()


func show_spawn(world_position: Vector2) -> void:
	_spawn_spark(world_position, SPAWN_COLOR, Color(0.78, 0.98, 1.0, 1.0), 13.0, 0.24, false)


## Presents one authoritative Hydrant hit. Gameplay owns the damage and target;
## this method only visualizes the already-resolved result.
func show_hydrant_impact(
	world_position: Vector2,
	damage: float,
	impact_duration: float = 0.28
) -> void:
	_spawn_spark(
		world_position,
		WATER_COLOR,
		WATER_CORE_COLOR,
		18.0,
		maxf(impact_duration, 0.01),
		true
	)
	if _damage_numbers_enabled:
		_spawn_damage_number(world_position, damage, true)
	if not is_node_ready():
		return
	hydrant_impact_audio.stream = _hydrant_impact_stream
	hydrant_impact_audio.pitch_scale = 1.0
	hydrant_impact_audio.play()


func set_damage_numbers_enabled(is_enabled: bool) -> void:
	_damage_numbers_enabled = is_enabled


func are_damage_numbers_enabled() -> bool:
	return _damage_numbers_enabled


func play_hit(heavy: bool = false) -> void:
	if not is_node_ready():
		return
	hit_audio.stream = _heavy_hit_stream if heavy else _light_hit_stream
	hit_audio.pitch_scale = 1.0
	hit_audio.play()


func play_death() -> void:
	if not is_node_ready():
		return
	death_audio.stream = _death_stream
	death_audio.pitch_scale = 1.0
	death_audio.play()


func play_hydrant_activation() -> void:
	if not is_node_ready():
		return
	hydrant_activation_audio.stream = _hydrant_activation_stream
	hydrant_activation_audio.pitch_scale = 1.0
	hydrant_activation_audio.play()


func play_hydrant_rejection() -> void:
	if not is_node_ready():
		return
	hydrant_rejection_audio.stream = _hydrant_rejection_stream
	hydrant_rejection_audio.pitch_scale = 1.0
	hydrant_rejection_audio.play()


## Called from the first Web user gesture. Registration happens in _ready so
## this path only starts one short confirmation sample and never resets combat.
func prime_audio() -> void:
	if not is_node_ready() or _audio_primed:
		return
	_audio_primed = true
	audio_unlock_audio.stream = _audio_unlock_stream
	audio_unlock_audio.pitch_scale = 1.0
	audio_unlock_audio.play()


## Manual and automatic collections use distinct fixed tones. A second fixed
## streak voice is layered only after the first successful manual collection.
func play_coin(manual: bool, streak_count: int) -> void:
	if not is_node_ready():
		return
	coin_audio.stream = _manual_coin_stream if manual else _auto_coin_stream
	coin_audio.pitch_scale = 1.0
	coin_audio.play()

	if manual and streak_count > 1:
		streak_audio.stream = _streak_stream
		streak_audio.pitch_scale = minf(1.35, 1.0 + float(streak_count - 2) * 0.055)
		streak_audio.play()


func _spawn_spark(
	world_position: Vector2,
	primary_color: Color,
	secondary_color: Color,
	radius: float,
	lifetime: float,
	heavy: bool
) -> void:
	var spark: CombatHitSpark = HIT_SPARK_SCENE.instantiate() as CombatHitSpark
	spark.configure(primary_color, secondary_color, radius, lifetime, heavy)
	spark.position = to_local(world_position)
	_register_transient(spark)
	add_child(spark)


func _spawn_damage_number(world_position: Vector2, damage: float, heavy: bool) -> void:
	var number: CombatDamageNumber = DAMAGE_NUMBER_SCENE.instantiate() as CombatDamageNumber
	number.configure(damage, heavy)
	number.position = to_local(world_position) + Vector2(-28.0, -46.0)
	_register_transient(number)
	add_child(number)


func _register_transient(transient: CanvasItem) -> void:
	_prune_expired_transients()
	while _live_transients.size() >= MAX_LIVE_TRANSIENTS:
		var oldest: CanvasItem = _live_transients.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	_live_transients.append(transient)


func _prune_expired_transients() -> void:
	for index: int in range(_live_transients.size() - 1, -1, -1):
		if not is_instance_valid(_live_transients[index]):
			_live_transients.remove_at(index)


func _build_reusable_audio() -> void:
	_light_hit_stream = _build_tone(210.0, 92.0, 0.075, 0.40, 0.34)
	_heavy_hit_stream = _build_tone(145.0, 48.0, 0.125, 0.54, 0.48)
	_death_stream = _build_tone(250.0, 46.0, 0.28, 0.45, 0.28)
	_manual_coin_stream = _build_tone(720.0, 1220.0, 0.13, 0.32, 0.16)
	_auto_coin_stream = _build_tone(520.0, 660.0, 0.11, 0.22, 0.10)
	_streak_stream = _build_tone(980.0, 1480.0, 0.10, 0.24, 0.12)
	_hydrant_activation_stream = _build_tone(170.0, 760.0, 0.22, 0.42, 0.44)
	_hydrant_impact_stream = _build_tone(118.0, 42.0, 0.16, 0.48, 0.52)
	_hydrant_rejection_stream = _build_tone(190.0, 142.0, 0.075, 0.24, 0.18)
	_audio_unlock_stream = _build_tone(620.0, 1040.0, 0.085, 0.18, 0.10)


## Web Sample playback can otherwise register a stream on its first audible
## use. Register every tiny deterministic PCM stream during scene startup so a
## combat hit or Hydrant activation does not absorb that one-time cost.
func _register_web_audio_samples() -> void:
	if not OS.has_feature("web"):
		return
	var players: Array[AudioStreamPlayer] = [
		hit_audio,
		death_audio,
		coin_audio,
		streak_audio,
		hydrant_activation_audio,
		hydrant_impact_audio,
		hydrant_rejection_audio,
		audio_unlock_audio,
	]
	for player: AudioStreamPlayer in players:
		player.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE

	var streams: Array[AudioStream] = [
		_light_hit_stream,
		_heavy_hit_stream,
		_death_stream,
		_manual_coin_stream,
		_auto_coin_stream,
		_streak_stream,
		_hydrant_activation_stream,
		_hydrant_impact_stream,
		_hydrant_rejection_stream,
		_audio_unlock_stream,
	]
	for stream: AudioStream in streams:
		AudioServer.register_stream_as_sample(stream)


## Builds deterministic, reusable mono PCM. The harmonic is fixed and contains
## no random/noise draw, so presentation cannot perturb future gameplay streams.
func _build_tone(
	start_frequency: float,
	end_frequency: float,
	duration: float,
	volume: float,
	harmonic_mix: float
) -> AudioStreamWAV:
	var frame_count: int = maxi(2, int(round(duration * float(AUDIO_MIX_RATE))))
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(frame_count * 2)

	for frame: int in range(frame_count):
		var progress: float = float(frame) / float(frame_count - 1)
		var time_seconds: float = float(frame) / float(AUDIO_MIX_RATE)
		var frequency: float = lerpf(start_frequency, end_frequency, progress)
		var attack: float = minf(1.0, progress * 28.0)
		var release: float = (1.0 - progress) * (1.0 - progress)
		var envelope: float = attack * release
		var fundamental: float = sin(TAU * frequency * time_seconds)
		var harmonic: float = sin(TAU * frequency * 2.0 * time_seconds)
		var sample_float: float = (fundamental + harmonic * harmonic_mix) * envelope * volume
		var sample: int = clampi(int(round(sample_float * 32767.0)), -32768, 32767)
		pcm[frame * 2] = sample & 0xff
		pcm[frame * 2 + 1] = (sample >> 8) & 0xff

	var wave: AudioStreamWAV = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = AUDIO_MIX_RATE
	wave.stereo = false
	wave.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wave.data = pcm
	return wave
