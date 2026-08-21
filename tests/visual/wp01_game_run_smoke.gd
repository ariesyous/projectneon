extends SceneTree

## Launches the configured GameRun composition, exercises the changed live
## presentation paths through their existing typed controls, captures one
## representative runtime frame, and exits without completing/persisting a run.

const GAME_RUN_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const SCREENSHOT_PATH: String = "res://docs/screenshots/wp01/wp01_game_run_patrol_1280x720.png"


func _init() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var game_run: GameRun = GAME_RUN_SCENE.instantiate() as GameRun
	root.add_child(game_run)
	for _frame: int in range(4):
		await process_frame
	if not game_run.vertical_slice_overlay.is_main_menu_visible():
		_fail("configured /GameRun did not open its main menu")
		return
	if game_run.vertical_slice_overlay.start_button.disabled:
		_fail("configured /GameRun did not select an accessible starting crew")
		return
	game_run.vertical_slice_overlay.start_button.pressed.emit()
	for _frame: int in range(3):
		await process_frame
	if not game_run.game_hud.visible:
		_fail("starting /GameRun did not reveal GameHUD")
		return
	game_run.run_director.step_run(2.0)
	for _frame: int in range(4):
		await process_frame
	if game_run.run_director.current_state != RunDirector.RunState.PATROLLING:
		_fail("/GameRun did not reach safe patrol after the authored intro")
		return
	if game_run.game_hud.help_panel.visible:
		game_run.game_hud.help_button.pressed.emit()
	game_run.game_hud.build_title_button.pressed.emit()
	if not game_run.game_hud.build_details_panel.visible:
		_fail("build progressive-disclosure shell did not open")
		return
	game_run.game_hud.build_details_close.pressed.emit()
	game_run.game_hud.district_card_open_button.pressed.emit()
	var planning_opened: bool = game_run.game_hud.is_district_card_panel_visible()
	if planning_opened:
		game_run.game_hud.district_card_close_button.pressed.emit()
	game_run.game_hud.backup_button.pressed.emit()
	game_run.game_hud.hydrant_button.pressed.emit()
	game_run.call("_toggle_pause_from_input")
	for _frame: int in range(2):
		await process_frame
	if not game_run.vertical_slice_overlay.is_pause_visible():
		_fail("pause shell did not open through GameRun")
		return
	game_run.vertical_slice_overlay.pause_settings_button.pressed.emit()
	if not game_run.vertical_slice_overlay.is_settings_visible():
		_fail("settings shell did not open from pause")
		return
	game_run.vertical_slice_overlay.settings_back_button.pressed.emit()
	game_run.vertical_slice_overlay.resume_button.pressed.emit()
	game_run.game_hud.apply_safe_area(Rect2i(32, 24, 1216, 672), Vector2i(1280, 720))
	for _frame: int in range(3):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("configured /GameRun viewport capture was empty")
		return
	var save_error: Error = image.save_png(ProjectSettings.globalize_path(SCREENSHOT_PATH))
	if save_error != OK:
		_fail("configured /GameRun screenshot failed: %s" % error_string(save_error))
		return
	print(
		"WP01_GAME_RUN_SMOKE=PASS state=%s planning=%s build=pass pause/settings=pass "
		% [RunDirector.state_name(game_run.run_director.current_state), planning_opened]
		+ "invalid intervention feedback=pass safe-area=pass"
	)
	game_run.free()
	for _frame: int in range(3):
		await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("WP01_GAME_RUN_SMOKE=FAIL %s" % message)
	quit(1)
