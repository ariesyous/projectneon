extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const STANDARD_ENCOUNTER: EncounterDefinition = preload(
	"res://data/encounters/alley_scuffle.tres"
)
const OUTPUT_DIRECTORY: String = "res://docs/screenshots/wp04"
const PROFILE_PATH: String = "user://wp04_runtime_smoke/profile.json"

const REWARD_CAPTURE: String = OUTPUT_DIRECTORY + "/wp04_reward_consequence_1280x720.png"
const FULL_CAPTURE: String = OUTPUT_DIRECTORY + "/wp04_full_inventory_1280x720.png"
const SHOP_CAPTURE: String = OUTPUT_DIRECTORY + "/wp04_shop_consequence_1280x720.png"
const PROC_CAPTURE: String = OUTPUT_DIRECTORY + "/wp04_build_proc_feedback_1280x720.png"

var _service: ProfileSaveService
var _app: NeonAppState


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_profile_siblings()
	var error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	if error != OK:
		_fail("capture directory: %s" % error_string(error))
		return

	var reward_game: GameRun = await _new_started_game(&"jax")
	if reward_game == null:
		return
	if not await _open_reward(reward_game, 9401, &"wp04_reward_capture"):
		return
	var reward_token: int = reward_game.reward_director.get_pending_equipment_choice_token(9401)
	if reward_token < 1 or not reward_game.game_hud.is_equipment_reward_visible():
		_fail("configured reward did not expose a revisioned gear choice")
		return
	reward_game.game_hud.reward_choice_01.pressed.emit()
	reward_game.game_hud.reward_target_02.pressed.emit()
	if not reward_game.game_hud.reward_choice_details_01.text.contains("NEXT:"):
		_fail("reward review did not show next-fight consequence")
		return
	if not reward_game.game_hud.reward_confirmation_label.text.contains("REWARD:"):
		_fail("reward review did not show paired payout")
		return
	if await _capture(REWARD_CAPTURE) != OK:
		_fail("reward capture")
		return
	var heat_before_replay: int = reward_game.run_director.heat
	if reward_game.run_flow_controller.claim_equipment_reward_to_inventory(
		0, SynergySystem.AREA_EQUIPPED, 1, -1, false,
		reward_game.synergy_system.get_inventory_revision(), 9401, reward_token + 1
	):
		_fail("stale equipment token was accepted")
		return
	if reward_game.run_director.heat != heat_before_replay:
		_fail("stale equipment token changed run state")
		return
	await _free_game(reward_game)

	var full_game: GameRun = await _new_started_game(&"jax")
	if full_game == null:
		return
	for item_id: StringName in [&"steel_toe_boots", &"chain_sneakers"]:
		if not full_game.synergy_system.equip_by_id(item_id):
			_fail("full inventory active setup %s" % item_id)
			return
	for item_id: StringName in [&"reinforced_jacket", &"serrated_wraps", &"shock_gloves"]:
		if not full_game.synergy_system.store(
			full_game.synergy_system.get_catalogue_item(item_id), -1, false,
			full_game.synergy_system.get_inventory_revision()
		):
			_fail("full inventory backpack setup %s" % item_id)
			return
	if not await _open_reward(full_game, 9402, &"wp04_full_capture"):
		return
	full_game.game_hud.reward_choice_01.pressed.emit()
	full_game.game_hud.reward_target_01.pressed.emit()
	full_game.game_hud.reward_pack_target_02.pressed.emit()
	if not full_game.game_hud.reward_confirmation_label.text.contains("DISCARD"):
		_fail("full inventory review did not name leave-behind")
		return
	if not full_game.game_hud.reward_keep_current_button.visible:
		_fail("full inventory removed Skip Gear")
		return
	if await _capture(FULL_CAPTURE) != OK:
		_fail("full inventory capture")
		return
	await _free_game(full_game)

	var shop_game: GameRun = await _new_started_game(&"jax")
	if shop_game == null:
		return
	shop_game.reward_director.grant_coins(120)
	shop_game.run_director.apply_heat_delta(80)
	if not await _open_shop(shop_game, &"wp04_shop_capture"):
		return
	var shop_before: Dictionary = shop_game.cooling_controller.get_snapshot()
	var visit_revision: int = int(shop_before.get("shop_visit_revision", -1))
	shop_game.game_hud.shop_cooling_choice.pressed.emit()
	var shop_result: Dictionary = shop_game.cooling_controller.get_last_shop_purchase_result()
	if not bool(shop_result.get("accepted", false)):
		_fail("configured shop purchase rejected")
		return
	if int(shop_result.get("coins_after", -1)) != 60 or int(shop_result.get("heat_after", -1)) != 62:
		_fail("configured shop result was not exact")
		return
	if await _capture(SHOP_CAPTURE) != OK:
		_fail("shop capture")
		return
	var immutable: Dictionary = shop_game.cooling_controller.request_shop_cooling_result(
		visit_revision + 100,
		&"convenience_store"
	)
	if immutable.get("reason") != &"stale_visit":
		_fail("stale shop visit was not rejected")
		return
	shop_game.game_hud.shop_leave_choice.pressed.emit()
	if shop_game.run_director.current_state == RunDirector.RunState.SHOP:
		_fail("shop exit did not leave")
		return
	await _free_game(shop_game)

	var proc_game: GameRun = await _new_started_game(&"zoey")
	if proc_game == null:
		return
	if not proc_game.synergy_system.equip_by_id(&"hacker_deck"):
		_fail("proc build Hacker Deck")
		return
	if not proc_game.synergy_system.equip_by_id(&"magnetic_flail"):
		_fail("proc build Magnetic Flail")
		return
	if not _begin_direct_planned_encounter(proc_game, &"wp04_proc_capture"):
		return
	while proc_game.tutorial_controller.dismiss_current():
		pass
	proc_game.game_hud.action_toast.hide()
	proc_game._on_equipment_status_applied(
		null,
		&"shock",
		1,
		6.0,
		&"shock_gloves_shock"
	)
	if not proc_game.game_hud.build_callout.visible:
		_fail("combat proc acknowledgement hidden")
		return
	if not proc_game.game_hud.build_callout.get_detail().contains("ENV DMG +25%"):
		_fail("combat proc acknowledgement lacked exact consequence")
		return
	if await _capture(PROC_CAPTURE) != OK:
		_fail("proc capture")
		return
	proc_game.vertical_slice_overlay.return_to_main_menu_requested.emit()
	if proc_game.run_director.current_state != RunDirector.RunState.INITIALIZING:
		_fail("menu cleanup did not reset configured run")
		return
	if proc_game.game_hud.build_callout.visible:
		_fail("menu cleanup left build callout")
		return
	await _free_game(proc_game)

	print(
		"WP04_GAME_RUN_SMOKE=PASS reward/token=pass full/skip=pass "
		+ "shop/purchase/stale/exit=pass proc/cleanup=pass captures=4"
	)
	_cleanup_services()
	_remove_profile_siblings()
	quit(0)


func _new_started_game(crew_id: StringName) -> GameRun:
	_cleanup_services()
	_service = ProfileSaveService.new()
	_service.configure_profile_path(PROFILE_PATH)
	_app = NeonAppState.new()
	_app.initialize(_service, true)
	var game: GameRun = GAME_SCENE.instantiate() as GameRun
	game.app_state_override = _app
	root.add_child(game)
	for _frame: int in range(4):
		await process_frame
	match crew_id:
		&"zoey":
			game.vertical_slice_overlay.zoey_button.pressed.emit()
		&"rex":
			game.vertical_slice_overlay.rex_button.pressed.emit()
		_:
			game.vertical_slice_overlay.jax_button.pressed.emit()
	game.vertical_slice_overlay.start_button.pressed.emit()
	if not game.run_director.complete_intro():
		_fail("intro/PLAN for %s" % crew_id)
		return null
	game.patrol_controller.set_process(false)
	return game


func _open_reward(game: GameRun, encounter_id: int, occurrence_id: StringName) -> bool:
	if not _begin_direct_planned_encounter(game, occurrence_id):
		return false
	game.run_flow_controller._on_encounter_completed(encounter_id, STANDARD_ENCOUNTER)
	if game.run_director.current_state != RunDirector.RunState.REWARD_SELECTION:
		_fail("direct encounter did not enter reward")
		return false
	if game.reward_director.get_pending_equipment_choices(encounter_id).is_empty():
		_fail("direct encounter did not prepare equipment")
		return false
	for _frame: int in range(3):
		await process_frame
	return true


func _open_shop(game: GameRun, occurrence_id: StringName) -> bool:
	if _confirm_current_plan(game) == null:
		_fail("shop plan confirmation")
		return false
	if not game.run_director.begin_district_block(occurrence_id, &"shop"):
		_fail("shop block begin")
		return false
	if not _resolve_direct_block(game, occurrence_id, &"shop"):
		_fail("shop block resolve")
		return false
	game.run_director.apply_heat_delta(80 - game.run_director.heat)
	if not bool(game.run_flow_controller.call("_open_shop_visit", &"convenience_store", 1)):
		_fail("shop visit open")
		return false
	for _frame: int in range(3):
		await process_frame
	return true


func _begin_direct_planned_encounter(game: GameRun, occurrence_id: StringName) -> bool:
	if _confirm_current_plan(game) == null:
		_fail("encounter plan confirmation")
		return false
	if not game.run_director.begin_district_block(occurrence_id, &"encounter"):
		_fail("encounter block begin")
		return false
	if not _resolve_direct_block(game, occurrence_id, &"encounter"):
		_fail("encounter block resolve")
		return false
	if not game.run_director.begin_encounter(STANDARD_ENCOUNTER):
		_fail("encounter begin")
		return false
	return true


func _confirm_current_plan(game: GameRun) -> DistrictCardDefinition:
	var snapshot: Dictionary = game.card_system.get_snapshot()
	var offer: Array = snapshot.get("offer", []) as Array
	if offer.is_empty():
		return null
	var card: DistrictCardDefinition = offer[0] as DistrictCardDefinition
	var staged: Dictionary = game.run_flow_controller.stage_focused_district_plan_choice(
		card.id,
		int(snapshot.get("offer_revision", -1)),
		int(snapshot.get("context_lifecycle_revision", -1)),
		StringName(snapshot.get("lap_id", &"")),
		StringName(snapshot.get("block_id", &""))
	)
	if not bool(staged.get("accepted", false)):
		return null
	var confirmed: Dictionary = game.run_flow_controller.confirm_focused_district_plan_choice(
		int(staged.get("confirmation_token", -1))
	)
	return card if bool(confirmed.get("accepted", false)) else null


func _resolve_direct_block(
	game: GameRun,
	occurrence_id: StringName,
	node_type: StringName
) -> bool:
	var loop: Dictionary = game.run_director.get_district_loop_snapshot()
	return game.card_system.resolve_focused_district_plan_block(
		int(loop.get("block_index", 1)),
		occurrence_id,
		int(loop.get("block_index", 1)),
		occurrence_id,
		node_type,
		loop
	) != null


func _capture(path: String) -> Error:
	for _frame: int in range(4):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return ERR_CANT_CREATE
	return image.save_png(ProjectSettings.globalize_path(path))


func _free_game(game: GameRun) -> void:
	if game != null and is_instance_valid(game):
		game.free()
	_cleanup_services()
	for _frame: int in range(2):
		await process_frame


func _cleanup_services() -> void:
	if _app != null and is_instance_valid(_app):
		_app.free()
	if _service != null and is_instance_valid(_service):
		_service.free()
	_app = null
	_service = null


func _remove_profile_siblings() -> void:
	for path: String in [PROFILE_PATH, PROFILE_PATH + ".tmp", PROFILE_PATH + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> void:
	push_error("WP04_GAME_RUN_SMOKE=FAIL %s" % message)
	_cleanup_services()
	_remove_profile_siblings()
	quit(1)
