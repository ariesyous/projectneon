@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const AUDIO_CATALOGUE: AudioCueCatalogue = preload(
	"res://data/audio/milestone_6_audio_catalogue.tres"
)
const TUTORIAL_CATALOGUE: TutorialPromptCatalogue = preload(
	"res://data/tutorials/milestone_6_tutorial_catalogue.tres"
)
const AUDIO_SCENE: PackedScene = preload(
	"res://scenes/audio/audio_presentation_controller.tscn"
)


func suite_name() -> String:
	return "milestone_6_audio_tutorial"


func test_audio_catalogue_covers_every_required_category_with_stable_buses() -> void:
	_expect_equal(AUDIO_CATALOGUE.validation_errors().size(), 0, "audio: strict catalogue validation")
	_expect_equal(AUDIO_CATALOGUE.cues.size(), 19, "audio: two music cues plus seventeen SFX cues")
	_expect_equal(AUDIO_CATALOGUE.get_sorted_ids(), AudioCueCatalogue.REQUIRED_CUE_IDS, "audio: exact stable IDs")
	var music_count: int = 0
	var sound_effect_count: int = 0
	for cue: AudioCueDefinition in AUDIO_CATALOGUE.get_sorted_cues():
		_expect_equal(cue.validation_errors().size(), 0, "%s: authored cue validates" % cue.id)
		if cue.bus == AudioBusContract.BUS_MUSIC:
			music_count += 1
			_expect_true(cue.loop, "%s: music loops" % cue.id)
		else:
			sound_effect_count += 1
			_expect_equal(cue.bus, AudioBusContract.BUS_SOUND_EFFECTS, "%s: SFX bus" % cue.id)
			_expect_false(cue.loop, "%s: one-shot SFX" % cue.id)
	_expect_equal(music_count, 2, "audio: district and boss music only")
	_expect_equal(sound_effect_count, 17, "audio: every required sound-effect category")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_light_hit") != null, "audio: light hit")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_heavy_hit") != null, "audio: heavy hit")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_environment_collision") != null, "audio: environment")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_coin_auto_collect") != null, "audio: coin auto")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_coin_manual_collect") != null, "audio: coin manual")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_night_pressure_warning") != null, "audio: pressure warning")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_ui_hover") != null, "audio: UI hover")
	_expect_true(AUDIO_CATALOGUE.get_by_id(&"sfx_ui_confirm") != null, "audio: UI confirm")


func test_generated_audio_is_fixed_reproducible_and_music_loops() -> void:
	var light_definition: AudioCueDefinition = AUDIO_CATALOGUE.get_by_id(&"sfx_light_hit")
	var light_a: AudioStreamWAV = GeneratedAudioStreamFactory.build_stream(light_definition)
	var light_b: AudioStreamWAV = GeneratedAudioStreamFactory.build_stream(light_definition)
	_expect_true(light_a != null and light_b != null, "synthesis: light streams created")
	_expect_equal(light_a.mix_rate, GeneratedAudioStreamFactory.SAMPLE_RATE, "synthesis: fixed sample rate")
	_expect_equal(light_a.data, light_b.data, "synthesis: same authored cue is byte-identical")
	_expect_true(light_a.data.size() > 0, "synthesis: PCM data is nonempty")
	_expect_equal(light_a.loop_mode, AudioStreamWAV.LOOP_DISABLED, "synthesis: SFX does not loop")
	var district: AudioStreamWAV = GeneratedAudioStreamFactory.build_stream(
		AUDIO_CATALOGUE.get_by_id(AudioCueCatalogue.DISTRICT_MUSIC_ID)
	)
	var boss: AudioStreamWAV = GeneratedAudioStreamFactory.build_stream(
		AUDIO_CATALOGUE.get_by_id(AudioCueCatalogue.BOSS_MUSIC_ID)
	)
	_expect_equal(district.loop_mode, AudioStreamWAV.LOOP_FORWARD, "music: district track loops")
	_expect_equal(boss.loop_mode, AudioStreamWAV.LOOP_FORWARD, "music: boss layer loops")
	_expect_equal(district.loop_begin, 0, "music: district loop begins at sample zero")
	_expect_equal(district.loop_end * 2, district.data.size(), "music: district loop spans full PCM")
	_expect_true(district.data != boss.data, "music: boss variation is audibly distinct data")
	var source: String = FileAccess.get_file_as_string(
		"res://scripts/audio/generated_audio_stream_factory.gd"
	)
	for forbidden: String in ["randi()", "randf()", "randomize()", ".shuffle()", ".pick_random()"]:
		_expect_false(source.contains(forbidden), "synthesis: no gameplay randomness token %s" % forbidden)


func test_audio_controller_exposes_district_boss_transition_and_all_one_shots() -> void:
	var controller: AudioPresentationController = track(
		AudioPresentationController.new()
	) as AudioPresentationController
	_expect_true(controller.initialize_audio(), "controller: catalogue initializes")
	_expect_equal(controller.get_child_count(), 10, "controller: district, boss, and eight SFX voices")
	_expect_true(controller.start_district_music(), "controller: district track configured")
	var played_ids: Array[StringName] = []
	controller.cue_played.connect(func(cue_id: StringName) -> void: played_ids.append(cue_id))
	for cue: AudioCueDefinition in AUDIO_CATALOGUE.get_sorted_cues():
		if cue.bus == AudioBusContract.BUS_SOUND_EFFECTS:
			_expect_true(controller.play_cue(cue.id), "controller: plays %s" % cue.id)
	_expect_equal(played_ids.size(), 17, "controller: every required SFX intent forwarded")
	_expect_false(controller.play_cue(AudioCueCatalogue.DISTRICT_MUSIC_ID), "controller: music rejected as one-shot")
	_expect_false(controller.play_cue(&"unknown"), "controller: unknown cue rejected")
	var boss_modes: Array[bool] = []
	controller.music_mode_changed.connect(func(active: bool) -> void: boss_modes.append(active))
	controller.set_boss_music_active(true)
	controller.set_boss_music_active(true)
	_expect_true(controller.is_boss_music_active(), "controller: boss layer active")
	controller.set_boss_music_active(false)
	_expect_false(controller.is_boss_music_active(), "controller: district-only mode restored")
	_expect_equal(boss_modes, [true, false], "controller: music transition emits once per change")
	_expect_true(
		controller.get_generated_stream(AudioCueCatalogue.BOSS_MUSIC_ID) != null,
		"controller: generated boss layer available"
	)


func test_versioned_audio_scene_instantiates_with_typed_catalogue() -> void:
	var instance: Node = track(AUDIO_SCENE.instantiate()) as Node
	_expect_true(instance is AudioPresentationController, "scene: typed presentation controller root")
	var controller: AudioPresentationController = instance as AudioPresentationController
	_expect_equal(controller.catalogue, AUDIO_CATALOGUE, "scene: versioned catalogue assigned")
	_expect_true(controller.initialize_audio(), "scene: controller initializes off-tree")


func test_tutorial_catalogue_has_complete_written_contextual_prompts() -> void:
	_expect_equal(TUTORIAL_CATALOGUE.validation_errors().size(), 0, "tutorial: strict catalogue validation")
	_expect_equal(TUTORIAL_CATALOGUE.prompts.size(), 7, "tutorial: seven bounded contextual prompts")
	var ids: Array[StringName] = []
	for prompt: TutorialPromptDefinition in TUTORIAL_CATALOGUE.get_sorted_prompts():
		ids.append(prompt.id)
		_expect_equal(prompt.validation_errors().size(), 0, "%s: authored prompt validates" % prompt.id)
		_expect_true(prompt.heading == prompt.heading.to_upper(), "%s: readable labelled heading" % prompt.id)
		_expect_true(prompt.body.length() >= 35, "%s: sufficient written instruction" % prompt.id)
	_expect_equal(ids, TutorialPromptCatalogue.REQUIRED_PROMPT_IDS, "tutorial: exact stable prompt IDs")
	var coin: TutorialPromptDefinition = TUTORIAL_CATALOGUE.get_by_id(&"tutorial_coin_cluster")
	_expect_true("full base value" in coin.body.to_lower(), "tutorial: ignoring coins preserves full base reward")
	var cards: TutorialPromptDefinition = TUTORIAL_CATALOGUE.get_by_id(&"tutorial_district_cards")
	_expect_true("night pressure never cools" in cards.body.to_lower(), "tutorial: Heat/Pressure distinction written")
	var interventions: TutorialPromptDefinition = TUTORIAL_CATALOGUE.get_by_id(&"tutorial_interventions")
	_expect_true("spend nothing" in interventions.body.to_lower(), "tutorial: rejection immutability written")
	var controls: TutorialPromptDefinition = TUTORIAL_CATALOGUE.get_by_id(&"tutorial_run_controls")
	_expect_true("help button" in controls.body.to_lower(), "tutorial: names the labelled Help surface")
	_expect_false("f1 opens help" in controls.body.to_lower(), "tutorial: never mislabels development F1")
	var equipment: TutorialPromptDefinition = TUTORIAL_CATALOGUE.get_by_id(&"tutorial_equipment")
	_expect_equal(equipment.trigger_id, &"equipment_choice_available", "tutorial: equipment context has exact trigger")


func test_tutorial_controller_is_once_per_run_queued_stable_and_nonmodal() -> void:
	var controller: TutorialPromptController = track(
		TutorialPromptController.new()
	) as TutorialPromptController
	var presented: Array[StringName] = []
	var dismissed: Array[StringName] = []
	controller.prompt_presented.connect(
		func(prompt: TutorialPromptDefinition) -> void: presented.append(prompt.id)
	)
	controller.prompt_dismissed.connect(
		func(prompt_id: StringName) -> void: dismissed.append(prompt_id)
	)
	controller.begin_run(42)
	_expect_true(controller.request_trigger(&"run_started"), "tutorial: first context accepted")
	_expect_equal(controller.get_active_prompt().id, &"tutorial_run_controls", "tutorial: run prompt active")
	_expect_true(controller.request_trigger(&"coin_cluster_available"), "tutorial: later context queued")
	_expect_equal(controller.get_queued_ids(), [&"tutorial_coin_cluster"], "tutorial: stable queue")
	_expect_false(controller.request_trigger(&"coin_cluster_available"), "tutorial: duplicate queued context rejected")
	_expect_true(controller.dismiss_current(), "tutorial: active prompt dismisses")
	_expect_equal(controller.get_active_prompt().id, &"tutorial_coin_cluster", "tutorial: queued context follows")
	_expect_true(controller.dismiss_current(), "tutorial: second prompt dismisses")
	_expect_equal(controller.get_active_prompt(), null, "tutorial: no modal remains")
	_expect_false(controller.request_trigger(&"run_started"), "tutorial: already-shown context rejected")
	_expect_equal(controller.get_shown_ids(), [&"tutorial_coin_cluster", &"tutorial_run_controls"], "tutorial: stable once-per-run ledger")
	var before_unknown: Dictionary = {
		"shown": controller.get_shown_ids(),
		"queued": controller.get_queued_ids(),
		"active": controller.get_active_prompt(),
	}
	_expect_false(controller.request_trigger(&"unknown"), "tutorial: unknown context rejected")
	_expect_equal(
		{
			"shown": controller.get_shown_ids(),
			"queued": controller.get_queued_ids(),
			"active": controller.get_active_prompt(),
		},
		before_unknown,
		"tutorial: invalid request is immutable"
	)
	_expect_equal(presented, [&"tutorial_run_controls", &"tutorial_coin_cluster"], "tutorial: typed presentation order")
	_expect_equal(dismissed, [&"tutorial_run_controls", &"tutorial_coin_cluster"], "tutorial: typed dismissal order")
	controller.begin_run(43)
	_expect_equal(controller.get_shown_ids(), [], "tutorial: new run clears shown ledger")
	_expect_true(controller.request_trigger(&"run_started"), "tutorial: prompt can appear in next run")
	_expect_equal(controller.get_run_serial(), 43, "tutorial: current run serial exposed")
	var source: String = FileAccess.get_file_as_string(
		"res://scripts/tutorial/tutorial_prompt_controller.gd"
	)
	_expect_false(source.contains("get_tree().paused"), "tutorial: controller never pauses gameplay")
	_expect_false(source.contains("set_deferred(\"paused\""), "tutorial: no deferred pause mutation")


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)
