extends SceneTree

## WP06 visual audit fixture. It composes the current production scene, uses
## existing presentation/authority APIs, and writes representative before/final
## captures without changing gameplay content or random-stream semantics.

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const ALLEY: EncounterDefinition = preload("res://data/encounters/alley_scuffle.tres")
const ARCADE: EncounterDefinition = preload("res://data/encounters/arcade_ambush.tres")
const VIPER_SIGNAL: EncounterDefinition = preload("res://data/encounters/viper_signal.tres")
const STREET_PUNK: PackedScene = preload("res://scenes/actors/street_punk.tscn")
const BAT_THUG: PackedScene = preload("res://scenes/actors/bat_thug.tscn")
const BOTTLE_THROWER: PackedScene = preload("res://scenes/actors/bottle_thrower.tscn")
const VIPER_ENFORCER: PackedScene = preload("res://scenes/actors/viper_enforcer.tscn")
const THE_VIPER: PackedScene = preload("res://scenes/actors/the_viper.tscn")
const ENFORCER_CHARGE: AttackDefinition = preload(
	"res://data/attacks/viper_enforcer_charge.tres"
)
const VIPER_AREA: AttackDefinition = preload("res://data/attacks/viper_area_warning.tres")
const BEFORE_OUTPUT_DIRECTORY: String = "res://docs/screenshots/wp06/phase_a/before"
const FINAL_OUTPUT_DIRECTORY: String = "res://docs/screenshots/wp06/final"
const PROFILE_PATH: String = "user://wp06_phase_a_visual_audit/profile.json"

var _service: ProfileSaveService
var _app: NeonAppState
var _final_capture: bool = false
var _output_directory: String = BEFORE_OUTPUT_DIRECTORY


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_final_capture = OS.get_cmdline_user_args().has("--final") or \
		OS.get_environment("WP06_FINAL_CAPTURE") == "1"
	_output_directory = FINAL_OUTPUT_DIRECTORY if _final_capture else BEFORE_OUTPUT_DIRECTORY
	_remove_profile_siblings()
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_output_directory)
	)
	if directory_error != OK:
		_fail("capture directory: %s" % error_string(directory_error))
		return

	var plan_game: GameRun = await _new_started_game(&"jax", false)
	if plan_game == null or await _capture("before_plan.png") != OK:
		_fail("PLAN capture")
		return
	await _free_game(plan_game)

	var ordinary_game: GameRun = await _new_started_encounter(ALLEY, &"jax", &"wp06_before_alley")
	if ordinary_game == null:
		return
	var ordinary_crew: ActorController = _selected_crew(ordinary_game)
	_spawn_enemy(ordinary_game, STREET_PUNK, Vector2(338.0, 194.0), ordinary_crew)
	_spawn_enemy(ordinary_game, BAT_THUG, Vector2(386.0, 226.0), ordinary_crew)
	_spawn_enemy(ordinary_game, BOTTLE_THROWER, Vector2(438.0, 258.0), ordinary_crew)
	ordinary_game._refresh_combat_presentation()
	if await _capture("before_ordinary_combat.png") != OK:
		_fail("ordinary combat capture")
		return
	await _free_game(ordinary_game)

	var focus_game: GameRun = await _new_started_encounter(ARCADE, &"zoey", &"wp06_before_arcade")
	if focus_game == null:
		return
	var focus_crew: ActorController = _selected_crew(focus_game)
	var bottle: ActorController = _spawn_enemy(
		focus_game,
		BOTTLE_THROWER,
		Vector2(370.0, 226.0),
		focus_crew
	)
	_spawn_enemy(focus_game, STREET_PUNK, Vector2(412.0, 194.0), focus_crew)
	_spawn_enemy(focus_game, BAT_THUG, Vector2(426.0, 258.0), focus_crew)
	if bottle != null:
		bottle._start_planned_attack(bottle.attack_definition)
		focus_game.focus_controller.step_eligible_time(0.001)
	focus_game._refresh_combat_presentation()
	if await _capture("before_power_box_focus.png") != OK:
		_fail("Power Box/Focus capture")
		return
	await _free_game(focus_game)

	var elite_game: GameRun = await _new_started_encounter(
		VIPER_SIGNAL,
		&"rex",
		&"wp06_before_elite"
	)
	if elite_game == null:
		return
	var elite_crew: ActorController = _selected_crew(elite_game)
	var enforcer: ActorController = _spawn_enemy(
		elite_game,
		VIPER_ENFORCER,
		Vector2(370.0, 226.0),
		elite_crew
	)
	_spawn_enemy(elite_game, BAT_THUG, Vector2(416.0, 194.0), elite_crew)
	_spawn_enemy(elite_game, BOTTLE_THROWER, Vector2(432.0, 258.0), elite_crew)
	if enforcer != null:
		enforcer._start_planned_attack(ENFORCER_CHARGE)
		elite_game.focus_controller.step_eligible_time(0.001)
	elite_game._refresh_combat_presentation()
	if await _capture("before_elite_pressure.png") != OK:
		_fail("elite capture")
		return
	await _free_game(elite_game)

	var boss_game: GameRun = await _new_started_encounter(
		VIPER_SIGNAL,
		&"rex",
		&"wp06_before_boss"
	)
	if boss_game == null:
		return
	var boss_crew: ActorController = _selected_crew(boss_game)
	var boss: ActorController = _spawn_enemy(
		boss_game,
		THE_VIPER,
		Vector2(370.0, 226.0),
		boss_crew
	)
	_spawn_enemy(boss_game, STREET_PUNK, Vector2(424.0, 194.0), boss_crew)
	_spawn_enemy(boss_game, BAT_THUG, Vector2(432.0, 258.0), boss_crew)
	if boss != null:
		boss._start_planned_attack(VIPER_AREA)
		boss_game.focus_controller.step_eligible_time(0.001)
		boss_game._refresh_combat_presentation()
		boss_game.set_process(false)
		boss_game.game_hud.clear_build_callout()
		boss_game.vertical_slice_overlay.present_boss(
			"The Viper",
			boss.health_component.current_health,
			boss.health_component.maximum_health,
			"Phase 1",
			"VENOM AREA  /  1.1s"
		)
		boss_game.game_hud.phase_banner.present(
			"BOSS",
			"LAP 3/3  /  BLOCK 3/3  /  BOSS COMMITMENT",
			"DEFEAT THE VIPER",
			"THREAT",
			"BOSS ACTIVE",
			true,
			boss_game.game_hud.ICON_PHASE_FIGHT
		)
	if await _capture("before_boss.png") != OK:
		_fail("boss capture")
		return
	await _free_game(boss_game)

	print("WP06_FINAL_MATRIX=PASS captures=5 authority_changes=0" if _final_capture else \
		"WP06_PHASE_A_BASELINE=PASS captures=5 authority_changes=0")
	_cleanup_services()
	_remove_profile_siblings()
	quit(0)


func _new_started_game(crew_id: StringName, confirm_plan: bool = true) -> GameRun:
	_cleanup_services()
	_service = ProfileSaveService.new()
	_service.configure_profile_path(PROFILE_PATH)
	_app = NeonAppState.new()
	_app.initialize(_service, true)
	var game: GameRun = GAME_SCENE.instantiate() as GameRun
	game.app_state_override = _app
	root.add_child(game)
	var capture_settings: GameSettingsData = GameSettingsData.create_default()
	capture_settings.pause_on_focus_loss = false
	game._apply_settings(capture_settings)
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
	if confirm_plan and not _confirm_current_plan(game):
		_fail("plan confirmation for %s" % crew_id)
		return null
	return game


func _new_started_encounter(
	definition: EncounterDefinition,
	crew_id: StringName,
	occurrence_id: StringName
) -> GameRun:
	var game: GameRun = await _new_started_game(crew_id, true)
	if game == null:
		return null
	if not game.run_director.begin_district_block(occurrence_id, &"encounter"):
		_fail("block begin: %s" % occurrence_id)
		return null
	if not _resolve_direct_block(game, occurrence_id, &"encounter"):
		_fail("block resolve: %s" % occurrence_id)
		return null
	if not bool(game.run_flow_controller.call(
		"_start_encounter",
		definition,
		RunFlowController.ENCOUNTER_SOURCE_BASELINE,
		true,
		0
	)):
		_fail("encounter start: %s" % definition.id)
		return null
	while game.tutorial_controller.dismiss_current():
		pass
	game.game_hud.action_toast.hide()
	return game


func _confirm_current_plan(game: GameRun) -> bool:
	var snapshot: Dictionary = game.card_system.get_snapshot()
	var offer: Array = snapshot.get("offer", []) as Array
	if offer.is_empty():
		return false
	var card: DistrictCardDefinition = offer[0] as DistrictCardDefinition
	if card == null:
		return false
	var staged: Dictionary = game.run_flow_controller.stage_focused_district_plan_choice(
		card.id,
		int(snapshot.get("offer_revision", -1)),
		int(snapshot.get("context_lifecycle_revision", -1)),
		StringName(snapshot.get("lap_id", &"")),
		StringName(snapshot.get("block_id", &""))
	)
	if not bool(staged.get("accepted", false)):
		return false
	return bool(game.run_flow_controller.confirm_focused_district_plan_choice(
		int(staged.get("confirmation_token", -1))
	).get("accepted", false))


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


func _selected_crew(game: GameRun) -> ActorController:
	var crew: Array[ActorController] = game.encounter_controller.get_permanent_crew()
	return crew[0] if crew.size() == 1 else null


func _spawn_enemy(
	game: GameRun,
	scene: PackedScene,
	world_position: Vector2,
	target: ActorController
) -> ActorController:
	var enemy: ActorController = scene.instantiate() as ActorController
	if enemy == null:
		return null
	game.get_node("DowntownLoop/EnemyContainer").add_child(enemy)
	enemy.global_position = world_position
	if not game.combat_director.register_actor(enemy):
		enemy.queue_free()
		return null
	if target != null:
		enemy.assign_target(target)
	return enemy


func _capture(file_name: String) -> Error:
	for _frame: int in range(4):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return ERR_CANT_CREATE
	var resolved_name: String = file_name.replace("before_", "final_") if _final_capture else file_name
	return image.save_png(ProjectSettings.globalize_path(
		"%s/%s" % [_output_directory, resolved_name]
	))


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
	push_error("WP06_PHASE_A_BASELINE=FAIL %s" % message)
	_cleanup_services()
	_remove_profile_siblings()
	quit(1)
