@tool
class_name AudioPresentationController
extends Node

signal cue_played(cue_id: StringName)
signal music_mode_changed(boss_active: bool)

const DEFAULT_CATALOGUE: AudioCueCatalogue = preload(
	"res://data/audio/milestone_6_audio_catalogue.tres"
)

@export var catalogue: AudioCueCatalogue = DEFAULT_CATALOGUE
@export_range(1, 16, 1) var sound_effect_voice_count: int = 8

var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _sound_effect_players: Array[AudioStreamPlayer] = []
var _district_player: AudioStreamPlayer = null
var _boss_player: AudioStreamPlayer = null
var _next_voice_index: int = 0
var _boss_active: bool = false
var _initialized: bool = false


func _ready() -> void:
	initialize_audio()
	start_district_music()


func _exit_tree() -> void:
	# Explicitly release generated streams before a scene/test tree is torn
	# down. This keeps the audio server from retaining prototype WAV playback
	# objects past their owning run.
	_release_audio_resources()


func _notification(what: int) -> void:
	# Off-tree test/tool instances never receive _exit_tree(), but Godot still
	# sends PREDELETE before freeing them. Use the same idempotent cleanup path
	# so generated streams do not survive their controller in either lifecycle.
	if what == NOTIFICATION_PREDELETE:
		_release_audio_resources()


func _release_audio_resources() -> void:
	stop_all_audio()
	if _district_player != null and is_instance_valid(_district_player):
		_district_player.stream = null
	if _boss_player != null and is_instance_valid(_boss_player):
		_boss_player.stream = null
	for player: AudioStreamPlayer in _sound_effect_players:
		if player != null and is_instance_valid(player):
			player.stream = null
	_streams.clear()
	_initialized = false


func initialize_audio() -> bool:
	if _initialized:
		return true
	if catalogue == null or not catalogue.validation_errors().is_empty():
		return false
	AudioBusContract.ensure_required_buses()
	for cue: AudioCueDefinition in catalogue.get_sorted_cues():
		_streams[cue.id] = GeneratedAudioStreamFactory.build_stream(cue)
	_create_players()
	_initialized = true
	return true


func start_district_music() -> bool:
	if not initialize_audio():
		return false
	_district_player.stream = _streams.get(AudioCueCatalogue.DISTRICT_MUSIC_ID)
	if is_inside_tree() and _has_audio_output() and not _district_player.playing:
		_district_player.play()
	return true


func set_boss_music_active(active: bool) -> void:
	if not initialize_audio() or _boss_active == active:
		return
	_boss_active = active
	if active:
		_boss_player.stream = _streams.get(AudioCueCatalogue.BOSS_MUSIC_ID)
		if is_inside_tree() and _has_audio_output():
			_boss_player.play()
	else:
		_boss_player.stop()
	music_mode_changed.emit(_boss_active)


func play_cue(cue_id: StringName) -> bool:
	if not initialize_audio():
		return false
	var definition: AudioCueDefinition = catalogue.get_by_id(cue_id)
	if definition == null or definition.bus != AudioBusContract.BUS_SOUND_EFFECTS:
		return false
	var player: AudioStreamPlayer = _sound_effect_players[_next_voice_index]
	_next_voice_index = (_next_voice_index + 1) % _sound_effect_players.size()
	player.stream = _streams[cue_id]
	if is_inside_tree() and _has_audio_output():
		player.play()
	cue_played.emit(cue_id)
	return true


func stop_all_audio() -> void:
	if _district_player != null and is_instance_valid(_district_player):
		_district_player.stop()
	if _boss_player != null and is_instance_valid(_boss_player):
		_boss_player.stop()
	for player: AudioStreamPlayer in _sound_effect_players:
		if player != null and is_instance_valid(player):
			player.stop()
	_boss_active = false


func get_generated_stream(cue_id: StringName) -> AudioStreamWAV:
	if not initialize_audio():
		return null
	return _streams.get(cue_id)


func is_boss_music_active() -> bool:
	return _boss_active


func _has_audio_output() -> bool:
	# A headless process has no listener or user-facing audio device. Avoid
	# creating playback objects there while retaining the same generated streams,
	# cue signals, bus configuration, and deterministic presentation state for
	# automated/runtime verification.
	return DisplayServer.get_name().to_lower() != "headless"


func _create_players() -> void:
	_district_player = AudioStreamPlayer.new()
	_district_player.name = "DistrictMusic"
	_district_player.bus = AudioBusContract.BUS_MUSIC
	add_child(_district_player)
	_boss_player = AudioStreamPlayer.new()
	_boss_player.name = "BossMusicLayer"
	_boss_player.bus = AudioBusContract.BUS_MUSIC
	add_child(_boss_player)
	for voice_index: int in range(sound_effect_voice_count):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SoundEffectVoice%d" % (voice_index + 1)
		player.bus = AudioBusContract.BUS_SOUND_EFFECTS
		add_child(player)
		_sound_effect_players.append(player)
