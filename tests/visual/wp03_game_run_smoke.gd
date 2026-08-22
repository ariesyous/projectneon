extends SceneTree

## Configured /GameRun WP03 smoke. Uses a disposable production-profile path,
## real native Button signals, the live cards stream, and the authoritative
## Patrol/RunFlow boundary. It never touches the player's production profile.

const GAME_RUN_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const OUTPUT_DIRECTORY: String = "res://docs/screenshots/wp03"
const PLAN_CAPTURE_PATH: String = (
	"res://docs/screenshots/wp03/wp03_game_run_plan_prediction_1280x720.png"
)
const HISTORY_CAPTURE_PATH: String = (
	"res://docs/screenshots/wp03/wp03_game_run_recognized_history_1280x720.png"
)
const INSUFFICIENT_CAPTURE_PATH: String = (
	"res://docs/screenshots/wp03/wp03_game_run_insufficient_choice_1280x720.png"
)
const PROFILE_PATH: String = "user://wp03_runtime_smoke/profile.json"

var _service: ProfileSaveService


func _init() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_remove_profile_siblings()
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	if directory_error != OK:
		_fail("capture directory failed: %s" % error_string(directory_error))
		return
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
	game.vertical_slice_overlay.jax_button.pressed.emit()
	game.vertical_slice_overlay.start_button.pressed.emit()
	if not game.run_director.complete_intro():
		_fail("intro did not reach focused PLAN")
		return
	game.patrol_controller.set_process(false)
	if game.run_director.current_state != RunDirector.RunState.PAUSED:
		_fail("focused PLAN did not own its safe-boundary pause")
		return
	if not game.run_director.is_card_planning_pause_active():
		_fail("PLAN pause ownership was not authoritative")
		return
	if game.run_director.toggle_pause():
		_fail("ordinary pause input released mandatory PLAN")
		return
	var before: Dictionary = game.card_system.get_snapshot()
	var offer: Array = before.get("offer", []) as Array
	if offer.size() != 2:
		_fail("focused PLAN did not expose exactly two choices")
		return
	if bool(before.get("legacy_route_planner_enabled", true)):
		_fail("release snapshot exposed the legacy future-slot planner")
		return
	if game.game_hud.district_card_close_button.visible:
		_fail("mandatory PLAN exposed a close path")
		return
	if game.game_hud.district_route_slot_01.visible or game.game_hud.district_route_slot_05.visible:
		_fail("release PLAN exposed future-slot clutter")
		return
	var chosen: DistrictCardDefinition = offer[0] as DistrictCardDefinition
	if chosen == null:
		_fail("first offered card was not authored data")
		return
	game.game_hud.district_card_choice_01.pressed.emit()
	if not game.game_hud.district_card_feedback.text.contains(
		CardSystem.focused_block_type(chosen)
	):
		_fail("selected card did not predict its exact block type")
		return
	if not game.game_hud.district_card_feedback.text.contains(
		"HEAT %s" % _signed(chosen.heat_delta)
	):
		_fail("selected card did not predict its exact Heat")
		return
	while game.tutorial_controller.dismiss_current():
		pass
	if game.game_hud.help_panel.visible:
		game.game_hud.help_button.pressed.emit()
	if await _capture_root(PLAN_CAPTURE_PATH) != OK:
		_fail("prediction capture failed")
		return

	game.run_director.apply_heat_delta(30)
	var heat_before: int = game.run_director.heat
	game.game_hud.district_card_confirm_button.pressed.emit()
	if game.run_director.current_state != RunDirector.RunState.PATROLLING:
		_fail("confirmation did not release patrol")
		return
	if game.run_director.heat != heat_before + chosen.heat_delta:
		_fail("chosen Heat did not apply exactly once")
		return
	var accepted: Dictionary = game.card_system.get_snapshot()
	var pending: Dictionary = accepted.get("selected_next_block", {}) as Dictionary
	if pending.get("card_id") != chosen.id:
		_fail("stable card ID was not bound to the next block")
		return
	if pending.get("block_id") != &"district_lap_01::block_01":
		_fail("stable first block ID was not bound")
		return
	var selection_token: int = int(pending.get("selection_token", -1))
	var replay_heat: int = game.run_director.heat
	if bool(
		game.run_flow_controller.confirm_focused_district_plan_choice(
			selection_token
		).get("accepted", false)
	):
		_fail("selection-token replay was accepted")
		return
	if game.run_director.heat != replay_heat:
		_fail("selection-token replay changed Heat")
		return

	game.patrol_controller.step_patrol(100.0)
	var occurred: Dictionary = game.card_system.get_snapshot()
	var history: Array = occurred.get("current_lap_history", []) as Array
	if history.size() != 1 or not bool((history[0] as Dictionary).get("resolved", false)):
		_fail("chosen consequence did not enter resolved history")
		return
	if (history[0] as Dictionary).get("card_id") != chosen.id:
		_fail("resolved history did not repeat the chosen stable ID")
		return
	var recognition_copy: String = " ".join([
		game.game_hud.hydrant_feedback_label.text,
		game.game_hud.district_card_compact_summary.text,
		game.game_hud.district_card_route_preview.text,
	])
	if not recognition_copy.contains(chosen.display_name.to_upper()):
		_fail("visible consequence did not repeat the chosen location name")
		return
	if not _complete_current_block(game):
		return
	if game.run_director.current_state != RunDirector.RunState.PAUSED:
		_fail("completed block did not open the next focused PLAN")
		return
	var next: Dictionary = game.card_system.get_snapshot()
	if int(next.get("block_index", -1)) != 2 or int(next.get("offer_count", 0)) < 1:
		_fail("next block did not retain/refill the finite lap offer")
		return
	if (next.get("current_lap_history", []) as Array).size() != 1:
		_fail("resolved trail was not retained beside the next choice")
		return
	while game.tutorial_controller.dismiss_current():
		pass
	if await _capture_root(HISTORY_CAPTURE_PATH) != OK:
		_fail("recognized-history capture failed")
		return

	# A production lap with three accessible cards naturally reaches one
	# remaining choice on block three. Exercise that non-deadlocking state instead
	# of manufacturing a presentation-only fixture.
	var second_offer: Array = next.get("offer", []) as Array
	var second_choice: DistrictCardDefinition = second_offer[0] as DistrictCardDefinition
	if second_choice == null:
		_fail("second block did not retain an authored choice")
		return
	game.game_hud.district_card_choice_01.pressed.emit()
	game.game_hud.district_card_confirm_button.pressed.emit()
	game.patrol_controller.step_patrol(100.0)
	if game.run_director.current_state != RunDirector.RunState.PAUSED:
		if not _complete_current_block(game):
			return
	if game.run_director.current_state != RunDirector.RunState.PAUSED:
		_fail("second consequence did not reach the third focused PLAN")
		return
	var final_offer: Dictionary = game.card_system.get_snapshot()
	if int(final_offer.get("block_index", -1)) != 3:
		_fail("insufficient-choice evidence was not block three")
		return
	if int(final_offer.get("offer_count", -1)) != 1:
		_fail("finite lap deck did not expose exactly one remaining choice")
		return
	if game.game_hud.district_card_choice_02.visible or game.game_hud.district_card_choice_03.visible:
		_fail("insufficient-choice state exposed empty card controls")
		return
	if game.game_hud.district_card_close_button.visible:
		_fail("insufficient-choice state exposed a deadlocking decline path")
		return
	if await _capture_root(INSUFFICIENT_CAPTURE_PATH) != OK:
		_fail("insufficient-choice capture failed")
		return

	game.vertical_slice_overlay.return_to_main_menu_requested.emit()
	if game.run_director.current_state != RunDirector.RunState.INITIALIZING:
		_fail("return to menu did not clear run authority")
		return
	var cleared: Dictionary = game.card_system.get_snapshot()
	if not (cleared.get("current_lap_history", []) as Array).is_empty():
		_fail("return to menu left card history")
		return
	if not game.card_system.get_hand().is_empty():
		_fail("return to menu left a hidden offer")
		return
	print(
		"WP03_GAME_RUN_SMOKE=PASS offer=2 predict=pass confirm/heat=pass "
		+ "resolved/recognized=pass next-plan=pass insufficient=1 replay/cleanup=pass card=%s"
		% chosen.id
	)
	game.free()
	app.free()
	_service.free()
	for _frame: int in range(3):
		await process_frame
	_remove_profile_siblings()
	quit(0)


func _complete_current_block(game: GameRun) -> bool:
	match game.run_director.current_state:
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			var encounter_id: int = game.encounter_controller.get_active_encounter_instance_id()
			var definition: EncounterDefinition = game.encounter_controller.get_active_definition()
			game.run_flow_controller._on_encounter_completed(encounter_id, definition)
			if game.run_director.current_state != RunDirector.RunState.REWARD_SELECTION:
				_fail("resolved fight did not enter reward")
				return false
			if game.reward_director.get_pending_equipment_choices(encounter_id).is_empty():
				if not game.run_flow_controller.claim_standard_reward():
					_fail("standard reward did not complete chosen fight")
					return false
			elif not game.run_flow_controller.decline_equipment_reward():
				_fail("equipment decline did not complete chosen fight")
				return false
		RunDirector.RunState.SHOP:
			if not game.run_flow_controller.leave_shop():
				_fail("leaving chosen shop did not complete block")
				return false
		RunDirector.RunState.PAUSED:
			# Transit utility completes synchronously and opens the next PLAN.
			pass
		_:
			_fail("chosen effect entered unexpected state %d" % game.run_director.current_state)
			return false
	return true


func _capture_root(resource_path: String) -> Error:
	for _frame: int in range(3):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return ERR_CANT_CREATE
	return image.save_png(ProjectSettings.globalize_path(resource_path))


func _signed(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)


func _remove_profile_siblings() -> void:
	for path: String in [PROFILE_PATH, PROFILE_PATH + ".tmp", PROFILE_PATH + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> void:
	push_error("WP03_GAME_RUN_SMOKE=FAIL %s" % message)
	_remove_profile_siblings()
	quit(1)
