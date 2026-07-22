@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const SETTINGS_DEFAULTS: GameSettingsData = preload(
	"res://data/persistence/milestone_6_settings_defaults.tres"
)
const UNLOCK_POLICY: UnlockPolicyDefinition = preload(
	"res://data/persistence/milestone_6_unlock_policy.tres"
)

var _test_paths: Array[String] = []
var _path_nonce: int = 0
var _bus_state: Dictionary[StringName, Dictionary] = {}


func suite_name() -> String:
	return "milestone_6_persistence_settings"


func setup() -> void:
	_test_paths.clear()
	_capture_bus_state(AudioBusContract.BUS_MASTER)
	_capture_bus_state(AudioBusContract.BUS_MUSIC)
	_capture_bus_state(AudioBusContract.BUS_SOUND_EFFECTS)


func teardown() -> void:
	for path: String in _test_paths:
		_remove_path(path)
		_remove_path(path + ".tmp")
		_remove_path(path + ".bak")
	_restore_bus_state()


func test_production_defaults_and_development_access_are_exact() -> void:
	var profile: PersistentProfileData = PersistentProfileData.create_default()
	_expect_equal(profile.save_version, 1, "defaults: version one")
	_expect_equal(
		profile.unlocked_crew_ids,
		[&"jax"],
		"defaults: only Jax is production-unlocked"
	)
	_expect_equal(
		profile.unlocked_equipment_ids,
		PersistentProfileData.PRODUCTION_DEFAULT_EQUIPMENT_IDS,
		"defaults: exactly eight existing gear entries"
	)
	_expect_false(
		PersistentProfileData.EQUIPMENT_HACKER_DECK in profile.unlocked_equipment_ids,
		"defaults: Hacker Deck is the one gated existing gear item"
	)
	_expect_equal(
		profile.unlocked_card_ids,
		PersistentProfileData.PRODUCTION_DEFAULT_CARD_IDS,
		"defaults: exactly three existing cards"
	)
	_expect_false(
		PersistentProfileData.CARD_GANG_HIDEOUT in profile.unlocked_card_ids,
		"defaults: Gang Hideout is the one gated existing card"
	)
	_expect_equal(
		profile.get_accessible_crew_ids(true),
		PersistentProfileData.ALL_CREW_IDS,
		"development: all three crew available"
	)
	_expect_equal(
		profile.get_accessible_equipment_ids(true),
		PersistentProfileData.ALL_EQUIPMENT_IDS,
		"development: all nine required gear entries available"
	)
	_expect_equal(
		profile.get_accessible_card_ids(true),
		PersistentProfileData.ALL_CARD_IDS,
		"development: all four required cards available"
	)
	_expect_equal(UNLOCK_POLICY.validation_errors().size(), 0, "defaults: exact unlock policy validates")
	_expect_equal(UNLOCK_POLICY.rules.size(), 4, "defaults: only four authored unlock rules")
	var serialized: Dictionary = profile.to_dictionary()
	_expect_equal(serialized.size(), 6, "defaults: minimal six-field profile root")
	_expect_false(serialized.has("stat_bonuses"), "defaults: no permanent statistical bonuses")
	_expect_false(serialized.has("active_run"), "defaults: no mid-run save state")
	_expect_equal(SETTINGS_DEFAULTS.to_dictionary(), profile.settings.to_dictionary(), "defaults: versioned settings resource")


func test_missing_optional_fields_receive_safe_defaults_and_values_are_sanitized() -> void:
	var path: String = _new_test_path("missing_fields")
	_write_text(
		path,
		JSON.stringify({
			"save_version": 1,
			"unlocked_crew_ids": ["zoey", "unknown", "zoey"],
			"settings": {
				"master_volume": 7.0,
				"music_volume": "loud",
				"damage_numbers_enabled": false,
				"hit_flash_reduction": -3.0,
			},
		})
	)
	var service: ProfileSaveService = track(ProfileSaveService.new(path)) as ProfileSaveService
	var profile: PersistentProfileData = service.load_profile()
	_expect_equal(service.last_load_status, ProfileSaveService.LOAD_STATUS_LOADED, "missing: valid v1 loaded")
	_expect_equal(profile.unlocked_crew_ids, [&"jax", &"zoey"], "missing: required Jax plus valid Zoey")
	_expect_equal(
		profile.unlocked_equipment_ids,
		PersistentProfileData.PRODUCTION_DEFAULT_EQUIPMENT_IDS,
		"missing: equipment defaults"
	)
	_expect_equal(profile.unlocked_card_ids, PersistentProfileData.PRODUCTION_DEFAULT_CARD_IDS, "missing: card defaults")
	_expect_equal(profile.lifetime_statistics.completed_runs, 0, "missing: lifetime defaults")
	_expect_equal(profile.settings.master_volume, 1.0, "missing: numeric setting clamps high")
	_expect_equal(profile.settings.music_volume, GameSettingsData.DEFAULT_MUSIC_VOLUME, "missing: wrong type defaults")
	_expect_false(profile.settings.damage_numbers_enabled, "missing: valid optional bool retained")
	_expect_equal(profile.settings.hit_flash_reduction, 0.0, "missing: numeric setting clamps low")
	_expect_equal(
		profile.settings.pause_on_focus_loss,
		GameSettingsData.DEFAULT_PAUSE_ON_FOCUS_LOSS,
		"missing: absent focus setting defaults"
	)


func test_injected_path_round_trip_uses_atomic_replacement_without_real_profile() -> void:
	var path: String = _new_test_path("round_trip")
	_expect_true(path != ProfileSaveService.DEFAULT_PROFILE_PATH, "round trip: injected path is not real profile")
	var service: ProfileSaveService = track(ProfileSaveService.new(path)) as ProfileSaveService
	var profile: PersistentProfileData = service.load_profile()
	_expect_equal(service.last_load_status, ProfileSaveService.LOAD_STATUS_MISSING_DEFAULTS, "round trip: missing starts defaults")
	profile.unlock_content(&"crew", &"zoey")
	profile.settings.master_volume = 0.31
	profile.settings.fullscreen = true
	profile.lifetime_statistics.record_completed_run(&"defeated", 2)
	_expect_true(service.save_profile(profile), "round trip: first save succeeds")
	_expect_true(FileAccess.file_exists(path), "round trip: exact injected file exists")
	_expect_false(FileAccess.file_exists(path + ".tmp"), "round trip: no temporary file remains")
	_expect_false(FileAccess.file_exists(path + ".bak"), "round trip: no backup file remains")
	profile.settings.master_volume = 0.47
	_expect_true(service.save_profile(profile), "round trip: atomic overwrite succeeds")
	var reloader: ProfileSaveService = track(ProfileSaveService.new(path)) as ProfileSaveService
	var loaded: PersistentProfileData = reloader.load_profile()
	_expect_equal(reloader.last_load_status, ProfileSaveService.LOAD_STATUS_LOADED, "round trip: saved v1 loads")
	_expect_true(&"zoey" in loaded.unlocked_crew_ids, "round trip: unlock retained")
	_expect_equal(loaded.settings.master_volume, 0.47, "round trip: replacement value retained")
	_expect_true(loaded.settings.fullscreen, "round trip: display setting retained")
	_expect_equal(loaded.lifetime_statistics.completed_runs, 1, "round trip: lifetime run retained")
	_expect_equal(loaded.lifetime_statistics.elites_defeated, 2, "round trip: lifetime elites retained")


func test_malformed_and_wrong_root_saves_recover_in_memory_without_overwrite() -> void:
	var malformed_path: String = _new_test_path("malformed")
	var malformed_text: String = "{ not valid json"
	_write_text(malformed_path, malformed_text)
	var malformed_service: ProfileSaveService = track(
		ProfileSaveService.new(malformed_path)
	) as ProfileSaveService
	var malformed_profile: PersistentProfileData = malformed_service.load_profile()
	_expect_equal(
		malformed_service.last_load_status,
		ProfileSaveService.LOAD_STATUS_CORRUPT_DEFAULTS,
		"corrupt: malformed JSON safely recovers"
	)
	_expect_equal(malformed_profile.unlocked_crew_ids, [&"jax"], "corrupt: safe production defaults")
	_expect_equal(FileAccess.get_file_as_string(malformed_path), malformed_text, "corrupt: source preserved")

	var wrong_root_path: String = _new_test_path("wrong_root")
	var wrong_root_text: String = JSON.stringify([1, 2, 3])
	_write_text(wrong_root_path, wrong_root_text)
	var wrong_root_service: ProfileSaveService = track(
		ProfileSaveService.new(wrong_root_path)
	) as ProfileSaveService
	wrong_root_service.load_profile()
	_expect_equal(
		wrong_root_service.last_load_status,
		ProfileSaveService.LOAD_STATUS_CORRUPT_DEFAULTS,
		"corrupt: wrong JSON root safely recovers"
	)
	_expect_equal(FileAccess.get_file_as_string(wrong_root_path), wrong_root_text, "corrupt: wrong root preserved")
	_expect_false(wrong_root_service.is_read_only, "corrupt: defaults can be explicitly saved later")


func test_future_version_is_read_only_and_reset_touches_only_configured_path() -> void:
	var path: String = _new_test_path("future")
	var sentinel_path: String = _new_test_path("sentinel")
	var future_text: String = JSON.stringify({
		"save_version": 99,
		"unlocked_crew_ids": ["jax", "rex"],
		"future_payload": {"must_survive": true},
	})
	_write_text(path, future_text)
	_write_text(sentinel_path, "keep me")
	var service: ProfileSaveService = track(ProfileSaveService.new(path)) as ProfileSaveService
	var loaded: PersistentProfileData = service.load_profile()
	_expect_equal(
		service.last_load_status,
		ProfileSaveService.LOAD_STATUS_FUTURE_READ_ONLY,
		"future: explicit future status"
	)
	_expect_true(service.is_read_only, "future: service locks writes")
	_expect_true(&"rex" in loaded.unlocked_crew_ids, "future: known safe fields are readable")
	loaded.settings.master_volume = 0.1
	_expect_false(service.save_profile(loaded), "future: ordinary save rejected")
	_expect_equal(FileAccess.get_file_as_string(path), future_text, "future: unknown payload remains byte-identical")
	var reset: PersistentProfileData = service.reset_profile()
	_expect_false(service.is_read_only, "reset: explicit development reset clears read-only mode")
	_expect_equal(reset.unlocked_crew_ids, [&"jax"], "reset: production defaults restored")
	_expect_true(FileAccess.file_exists(path), "reset: defaults persisted at exact configured path")
	_expect_equal(FileAccess.get_file_as_string(sentinel_path), "keep me", "reset: sibling sentinel untouched")
	_expect_false(FileAccess.file_exists(path + ".tmp"), "reset: no temporary sibling remains")
	_expect_false(FileAccess.file_exists(path + ".bak"), "reset: no backup sibling remains")


func test_authored_unlocks_and_lifetime_counters_apply_once_without_stat_bonuses() -> void:
	var path: String = _new_test_path("unlocks")
	var service: ProfileSaveService = track(ProfileSaveService.new(path)) as ProfileSaveService
	var app_state: NeonAppState = track(NeonAppState.new()) as NeonAppState
	app_state.initialize(service, false)
	_expect_equal(app_state.get_accessible_crew_ids(), [&"jax"], "unlocks: production crew filter")
	_expect_equal(app_state.record_completed_run(&"defeated", 0), [&"zoey"], "unlocks: first completion grants Zoey")
	_expect_equal(app_state.record_completed_run(&"defeated", 1), [&"hacker_deck"], "unlocks: first elite grants existing gear")
	_expect_equal(app_state.record_completed_run(&"extracted", 0), [&"gang_hideout"], "unlocks: first extraction grants existing card")
	_expect_equal(app_state.record_completed_run(&"victory", 0), [&"rex"], "unlocks: first victory grants Rex")
	_expect_equal(app_state.record_completed_run(&"victory", 3), [], "unlocks: all grants are idempotent")
	_expect_equal(app_state.profile.unlocked_crew_ids.count(&"zoey"), 1, "unlocks: Zoey appears once")
	_expect_equal(app_state.profile.unlocked_crew_ids.count(&"rex"), 1, "unlocks: Rex appears once")
	_expect_equal(app_state.profile.unlocked_equipment_ids.count(&"hacker_deck"), 1, "unlocks: Hacker Deck appears once")
	_expect_equal(app_state.profile.unlocked_card_ids.count(&"gang_hideout"), 1, "unlocks: Gang Hideout appears once")
	_expect_equal(app_state.profile.lifetime_statistics.completed_runs, 5, "lifetime: every completed run counted")
	_expect_equal(app_state.profile.lifetime_statistics.victories, 2, "lifetime: victories counted")
	_expect_equal(app_state.profile.lifetime_statistics.extractions, 1, "lifetime: extraction counted")
	_expect_equal(app_state.profile.lifetime_statistics.defeats, 2, "lifetime: defeats counted")
	_expect_equal(app_state.profile.lifetime_statistics.elites_defeated, 4, "lifetime: elites accumulated")
	var before_invalid: Dictionary = app_state.profile.to_dictionary()
	_expect_equal(app_state.record_completed_run(&"unknown", 99), [], "lifetime: invalid outcome rejected")
	_expect_equal(app_state.profile.to_dictionary(), before_invalid, "lifetime: invalid outcome immutable")

	var dev_path: String = _new_test_path("development_access")
	var dev_service: ProfileSaveService = track(ProfileSaveService.new(dev_path)) as ProfileSaveService
	var dev_state: NeonAppState = track(NeonAppState.new()) as NeonAppState
	dev_state.initialize(dev_service, true)
	_expect_equal(dev_state.get_accessible_crew_ids().size(), 3, "development: complete crew catalogue")
	_expect_equal(dev_state.get_accessible_equipment_ids().size(), 9, "development: complete gear catalogue")
	_expect_equal(dev_state.get_accessible_card_ids().size(), 4, "development: complete card catalogue")
	_expect_equal(dev_state.profile.unlocked_crew_ids, [&"jax"], "development: bypass does not mutate save")


func test_settings_apply_required_buses_and_forward_focus_pause_intent_only() -> void:
	var settings: GameSettingsData = GameSettingsData.create_default()
	settings.master_volume = 0.25
	settings.music_volume = 0.5
	settings.sound_effects_volume = 0.75
	settings.screen_shake_intensity = 2.0
	settings.hit_flash_reduction = -1.0
	settings.damage_numbers_enabled = false
	settings.pause_on_focus_loss = true
	var controller: ApplicationSettingsController = track(
		ApplicationSettingsController.new()
	) as ApplicationSettingsController
	var focus_intents: Array[bool] = []
	controller.focus_pause_intent_requested.connect(
		func(should_pause: bool) -> void: focus_intents.append(should_pause)
	)
	controller.apply_settings(settings)
	_expect_true(AudioServer.get_bus_index(&"Master") >= 0, "settings: Master bus exists")
	_expect_true(AudioServer.get_bus_index(&"Music") >= 0, "settings: Music bus exists")
	_expect_true(AudioServer.get_bus_index(&"SFX") >= 0, "settings: SFX bus exists")
	_expect_true(absf(AudioBusContract.get_linear_volume(&"Master") - 0.25) < 0.001, "settings: master volume")
	_expect_true(absf(AudioBusContract.get_linear_volume(&"Music") - 0.5) < 0.001, "settings: music volume")
	_expect_true(absf(AudioBusContract.get_linear_volume(&"SFX") - 0.75) < 0.001, "settings: SFX volume")
	_expect_equal(controller.current_settings.screen_shake_intensity, 1.0, "settings: shake clamps")
	_expect_equal(controller.current_settings.hit_flash_reduction, 0.0, "settings: hit reduction clamps")
	_expect_false(controller.current_settings.damage_numbers_enabled, "settings: damage-number toggle retained")
	controller.handle_focus_changed(false)
	controller.handle_focus_changed(false)
	controller.handle_focus_changed(true)
	controller.handle_focus_changed(true)
	_expect_equal(focus_intents, [true, false], "settings: one typed pause and release intent per focus cycle")
	_expect_false(controller.is_focus_pause_intent_active(), "settings: focus intent clears")
	_expect_true(
		not FileAccess.get_file_as_string(
			"res://scripts/app/application_settings_controller.gd"
		).contains("get_tree().paused"),
		"settings: presentation component never owns gameplay pause"
	)


func _new_test_path(label: String) -> String:
	_path_nonce += 1
	var path: String = (
		"user://neon_loop_m6_tests/%s_%d_%d.json"
		% [label, Time.get_ticks_usec(), _path_nonce]
	)
	_test_paths.append(path)
	return path


func _write_text(path: String, source_text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(source_text)
	file.close()


func _remove_path(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _capture_bus_state(bus_name: StringName) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	_bus_state[bus_name] = {
		"volume_db": AudioServer.get_bus_volume_db(index),
		"muted": AudioServer.is_bus_mute(index),
	}


func _restore_bus_state() -> void:
	for bus_name: StringName in _bus_state:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index < 0:
			continue
		var state: Dictionary = _bus_state[bus_name]
		AudioServer.set_bus_volume_db(index, float(state["volume_db"]))
		AudioServer.set_bus_mute(index, bool(state["muted"]))
	_bus_state.clear()


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)
