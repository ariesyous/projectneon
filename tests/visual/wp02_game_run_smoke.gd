extends SceneTree

## Configured /GameRun smoke for every WP02 lifecycle branch. Uses an injected
## disposable profile path and never touches the player's production profile.

const GAME_RUN_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const STANDARD_ENCOUNTER: EncounterDefinition = preload(
	"res://data/encounters/alley_scuffle.tres"
)
const SCREENSHOT_PATH: String = (
	"res://docs/screenshots/wp02/wp02_game_run_final_commitment_1280x720.png"
)
const PROFILE_PATH: String = "user://wp02_runtime_smoke/profile.json"

var _service: ProfileSaveService


func _init() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_remove_profile_siblings()
	_service = ProfileSaveService.new(PROFILE_PATH)
	var app: NeonAppState = NeonAppState.new()
	app.initialize(_service, false)
	var game: GameRun = GAME_RUN_SCENE.instantiate() as GameRun
	game.app_state_override = app
	root.add_child(game)
	for _frame: int in range(4):
		await process_frame
	if not game.vertical_slice_overlay.is_main_menu_visible():
		_fail("main menu did not open")
		return
	if game.vertical_slice_overlay.zoey_button.disabled or game.vertical_slice_overlay.rex_button.disabled:
		_fail("fresh production menu did not expose all crew")
		return
	game.vertical_slice_overlay.jax_button.pressed.emit()
	game.vertical_slice_overlay.zoey_button.pressed.emit()
	game.vertical_slice_overlay.rex_button.pressed.emit()
	game.vertical_slice_overlay.start_button.pressed.emit()
	game.run_director.complete_intro()
	game.patrol_controller.set_process(false)
	if str(game.run_director.get_district_loop_snapshot().get("phase_name", "")) != "PLAN":
		_fail("intro did not enter authoritative PLAN")
		return
	if game.game_hud.help_panel.visible:
		game.game_hud.help_button.pressed.emit()
	game.game_hud.district_card_open_button.pressed.emit()
	if game.game_hud.is_district_card_panel_visible():
		game.game_hud.district_card_close_button.pressed.emit()
	game.call("_toggle_pause_from_input")
	if not game.vertical_slice_overlay.is_pause_visible():
		_fail("pause did not open from PLAN")
		return
	game.vertical_slice_overlay.pause_settings_button.pressed.emit()
	game.vertical_slice_overlay.settings_back_button.pressed.emit()
	game.vertical_slice_overlay.resume_button.pressed.emit()

	# Shop is one authored block outcome and must be unmistakable before close.
	if not game.run_director.open_shop():
		_fail("direct authored shop block did not open")
		return
	if not game.game_hud.shop_decision_panel.visible:
		_fail("configured shop did not own attention")
		return
	game.game_hud.shop_leave_choice.pressed.emit()
	if not _resolve_fight_blocks(game, 2):
		return
	if game.run_director.current_state != RunDirector.RunState.EXTRACTION_AVAILABLE:
		_fail("lap one did not reach LAP DECISION")
		return
	var first_token: int = game.run_director.get_district_decision_token()
	game.game_hud.extraction_continue_button.pressed.emit()
	if game.run_director.current_state != RunDirector.RunState.PATROLLING:
		_fail("lap-one Push did not enter lap two PLAN")
		return
	if game.run_flow_controller.decline_extraction(first_token):
		_fail("replayed lap-one Push token was accepted")
		return

	if not _resolve_fight_blocks(game, 3):
		return
	if game.run_director.current_state != RunDirector.RunState.EXTRACTION_AVAILABLE:
		_fail("lap two did not reach final commitment")
		return
	if not game.game_hud.extraction_continue_button.text.contains("COMMIT TO FINAL LAP + BOSS"):
		_fail("final-lap boss consequence was not visible")
		return
	while game.tutorial_controller.dismiss_current():
		pass
	game.game_hud.apply_safe_area(Rect2i(32, 24, 1216, 672), Vector2i(1280, 720))
	for _frame: int in range(3):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("configured final-commitment capture was empty")
		return
	var capture_error: Error = image.save_png(ProjectSettings.globalize_path(SCREENSHOT_PATH))
	if capture_error != OK:
		_fail("configured capture failed: %s" % error_string(capture_error))
		return
	var second_token: int = game.run_director.get_district_decision_token()
	game.game_hud.extraction_continue_button.pressed.emit()
	if not bool(game.run_director.get_district_loop_snapshot().get("boss_committed", false)):
		_fail("second Push did not latch boss commitment")
		return
	if game.run_flow_controller.decline_extraction(second_token):
		_fail("replayed final commitment token was accepted")
		return

	if not _resolve_fight_blocks(game, 3):
		return
	if game.run_director.current_state != RunDirector.RunState.BOSS_INTRO:
		_fail("block nine did not enter boss intro")
		return
	game.run_director.complete_boss_intro()
	if game.run_director.current_state != RunDirector.RunState.BOSS_ACTIVE:
		_fail("boss intro did not enter BOSS")
		return
	if not game.run_director.notify_all_crew_incapacitated():
		_fail("boss-path defeat did not resolve")
		return
	if game.run_director.get_last_summary() == null:
		_fail("boss-path result did not publish summary")
		return
	game.vertical_slice_overlay.return_to_main_menu_requested.emit()

	# Separate extraction branch proves the exact decision token and cleanup.
	game.vertical_slice_overlay.jax_button.pressed.emit()
	game.vertical_slice_overlay.start_button.pressed.emit()
	game.run_director.complete_intro()
	game.patrol_controller.set_process(false)
	if not _resolve_fight_blocks(game, 3):
		return
	game.game_hud.extraction_button.pressed.emit()
	if game.run_director.current_state != RunDirector.RunState.EXTRACTING:
		_fail("Extract button did not enter EXTRACTION")
		return
	game.run_director.step_run(game.run_director.get_extraction_duration_seconds() + 0.01)
	var extracted: RunSummaryRecord = game.run_director.get_last_summary()
	if extracted == null or extracted.result_label != "EXTRACTED":
		_fail("extraction did not publish RESULT")
		return
	if extracted.laps_completed != 1 or extracted.blocks_completed != 3:
		_fail("extraction summary lost lap/block outcome")
		return
	game.vertical_slice_overlay.return_to_main_menu_requested.emit()
	if game.run_director.current_state != RunDirector.RunState.INITIALIZING:
		_fail("return to menu did not clear run authority")
		return
	print(
		"WP02_GAME_RUN_SMOKE=PASS crew=3 plan/pause/shop=pass "
		+ "lap1_push=pass final_commit=pass boss/result=pass extraction=pass cleanup=pass"
	)
	game.free()
	app.free()
	_service.free()
	for _frame: int in range(3):
		await process_frame
	_remove_profile_siblings()
	quit(0)


func _resolve_fight_blocks(game: GameRun, count: int) -> bool:
	for _index: int in range(count):
		var loop: Dictionary = game.run_director.get_district_loop_snapshot()
		var lap_index: int = int(loop.get("lap_index", 1))
		var block_index: int = int(loop.get("block_index", 1))
		var occurrence_id: StringName = StringName(
			"wp02_smoke::lap_%d::block_%d" % [lap_index, block_index]
		)
		if not game.run_director.begin_district_block(occurrence_id, &"encounter"):
			_fail("could not begin %s" % occurrence_id)
			return false
		if not game.run_director.begin_encounter(STANDARD_ENCOUNTER):
			_fail("could not enter fight for %s" % occurrence_id)
			return false
		var encounter_id: int = lap_index * 100 + block_index
		if not game.run_director.notify_encounter_completed(encounter_id, STANDARD_ENCOUNTER):
			_fail("could not complete fight for %s" % occurrence_id)
			return false
		if not game.run_director.complete_reward_selection():
			_fail("could not complete reward for %s" % occurrence_id)
			return false
	return true


func _remove_profile_siblings() -> void:
	for path: String in [PROFILE_PATH, PROFILE_PATH + ".tmp", PROFILE_PATH + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> void:
	push_error("WP02_GAME_RUN_SMOKE=FAIL %s" % message)
	_remove_profile_siblings()
	quit(1)
