@tool
class_name AudioPresentationController
extends Node

signal cue_played(cue_id: StringName)
signal music_mode_changed(boss_active: bool)
signal phase_mix_changed(phase_id: StringName, district_db: float, boss_db: float)

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
var _presentation_phase: StringName = &"menu"


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
	_apply_phase_mix()
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
	_apply_phase_mix()
	music_mode_changed.emit(_boss_active)


func set_presentation_phase(phase_id: StringName) -> void:
	if _presentation_phase == phase_id:
		return
	_presentation_phase = phase_id
	if initialize_audio():
		_apply_phase_mix()


func get_mix_snapshot() -> Dictionary:
	return {
		"phase_id": _presentation_phase,
		"boss_active": _boss_active,
		"district_volume_db": _district_player.volume_db if _district_player != null else 0.0,
		"boss_volume_db": _boss_player.volume_db if _boss_player != null else 0.0,
		"semantic_cue_ids_unchanged": true,
	}


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
	_apply_phase_mix()


func _apply_phase_mix() -> void:
	if _district_player == null or _boss_player == null:
		return
	var district_db: float = 0.0
	var boss_db: float = 0.0
	match _presentation_phase:
		&"menu":
			district_db = -5.0
			boss_db = -80.0
		&"intro", &"plan", &"district_plan":
			district_db = -3.0
			boss_db = -80.0
		&"reward", &"shop", &"decision":
			district_db = -6.0
			boss_db = -80.0
		&"extract", &"result", &"victory", &"defeat":
			district_db = -8.0
			boss_db = -80.0
		&"boss_intro", &"boss":
			district_db = -7.0
			boss_db = 0.0
		_:
			district_db = 0.0
			boss_db = -80.0
	if not _boss_active:
		boss_db = -80.0
	_district_player.volume_db = district_db
	_boss_player.volume_db = boss_db
	phase_mix_changed.emit(_presentation_phase, district_db, boss_db)
