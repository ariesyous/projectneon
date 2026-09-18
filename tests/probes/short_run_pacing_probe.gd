extends SceneTree

## Current composed-run timing probe. Advances production authorities at 60 Hz,
## resolves mandatory PLAN with revisioned intents, and bounds both eligible
## time and total steps so a modal regression cannot hang the runner.
## --compare uses unchanged historical Resources for a same-policy baseline.
## --build equips offered gear into empty active slots and uses valid actions.
## --seed=<integer> selects a seed; --extract=<1|2> covers lap extraction.

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const LEGACY_ROUTE: PatrolRouteDefinition = preload("res://data/routes/downtown_loop_route.tres")
const LEGACY_ENCOUNTERS: Array[EncounterDefinition] = [
	preload("res://data/encounters/alley_scuffle.tres"),
	preload("res://data/encounters/arcade_ambush.tres"),
	preload("res://data/encounters/viper_signal.tres"),
]
const DT: float = 1.0 / 60.0
const MAX_STEPS: int = 60 * 1200
const OUTPUT_DIRECTORY: String = "res://build/short_run_pacing"

var _seed_value: int = 6062026
var _use_build: bool = false
var _extract_lap: int = 0
var _results: Array[Dictionary] = []
var _failed: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	_use_build = arguments.has("--build")
	for argument: String in arguments:
		if argument.begins_with("--seed="):
			_seed_value = argument.trim_prefix("--seed=").to_int()
		if argument.begins_with("--extract="):
			_extract_lap = argument.trim_prefix("--extract=").to_int()
	var profiles: Array[bool] = [false]
	if arguments.has("--compare"):
		profiles = [true, false]
	for legacy: bool in profiles:
		for full_access: bool in [false, true]:
			for crew_id: StringName in [&"jax", &"zoey", &"rex"]:
				await _run_case(legacy, full_access, crew_id)
	var path: String = "%s/%s_%d_extract_%d%s.json" % [
		OUTPUT_DIRECTORY, "build" if _use_build else "hold", _seed_value,
		_extract_lap, "_comparison" if arguments.has("--compare") else "",
	]
	var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if output == null:
		push_error("Could not write pacing evidence: %s" % path)
		_failed = true
	else:
		output.store_string(JSON.stringify(_results, "\t"))
		output.close()
	print("SHORT_RUN_PROBE=%s rows=%d path=%s" % ["FAIL" if _failed else "PASS", _results.size(), path])
	for frame: int in range(10):
		await process_frame
	quit(1 if _failed else 0)


func _run_case(legacy: bool, full_access: bool, crew_id: StringName) -> void:
	var profile_path: String = "%s/profile_%d_%d.json" % [OUTPUT_DIRECTORY, Time.get_ticks_usec(), _results.size()]
	var service: ProfileSaveService = ProfileSaveService.new(profile_path)
	var app: NeonAppState = NeonAppState.new()
	app.initialize(service, full_access)
	app.profile.settings.pause_on_focus_loss = false
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(viewport)
	var game: GameRun = GAME_SCENE.instantiate() as GameRun
	game.app_state_override = app
	viewport.add_child(game)
	if legacy:
		game.patrol_controller.route_definition = LEGACY_ROUTE
		game.run_flow_controller.encounter_candidates = LEGACY_ENCOUNTERS.duplicate()
	game._on_start_run_requested(crew_id)
	game.run_flow_controller.start_initial_run(_seed_value, true)
	game.run_director.complete_intro()
	# Full HUD refresh is a presentation observer, not simulation. The configured
	# graphical smoke covers it; omit its per-frame work in this bounded matrix.
	game.run_flow_controller.flow_status_changed.disconnect(game._on_flow_status_changed)
	var steps: int = 0
	var previous_state: int = -1
	var fight_start: float = -1.0
	var boss_start: float = -1.0
	var fights: Array[float] = []
	var lap_decisions: Array[float] = []
	var choices: Array[StringName] = []
	var first_lap_seconds: float = -1.0
	var first_lap_empty: float = 0.0
	var empty_seconds: float = 0.0
	var travel_seconds: float = 0.0
	var active_empty_gap: float = 0.0
	var longest_empty_gap: float = 0.0
	var failed_intent: bool = false
	while game.run_director.current_state != RunDirector.RunState.RUN_SUMMARY and steps < MAX_STEPS:
		var state: int = game.run_director.current_state
		var elapsed: float = game.run_director.run_elapsed_seconds
		if state != previous_state:
			if state == RunDirector.RunState.ENCOUNTER_ACTIVE:
				fight_start = elapsed
			if state == RunDirector.RunState.REWARD_SELECTION and fight_start >= 0.0:
				fights.append(snappedf(elapsed - fight_start, 0.001))
				fight_start = -1.0
			if state == RunDirector.RunState.BOSS_ACTIVE:
				boss_start = elapsed
			if state == RunDirector.RunState.EXTRACTION_AVAILABLE:
				lap_decisions.append(snappedf(elapsed, 0.001))
				if first_lap_seconds < 0.0:
					first_lap_seconds = elapsed
					first_lap_empty = empty_seconds
			previous_state = state
		if state == RunDirector.RunState.PAUSED:
			var selected: StringName = _choose_plan(game)
			if selected == &"":
				failed_intent = true
				break
			choices.append(selected)
		elif state == RunDirector.RunState.REWARD_SELECTION:
			if not _resolve_reward(game):
				failed_intent = true
				break
		elif state == RunDirector.RunState.SHOP:
			if not game.run_flow_controller.leave_shop():
				failed_intent = true
				break
		elif state == RunDirector.RunState.EXTRACTION_AVAILABLE:
			var token: int = game.run_director.get_district_decision_token()
			var completed_laps: int = int(game.run_director.get_district_loop_snapshot().completed_laps)
			var accepted: bool = (
				game.run_flow_controller.confirm_extraction(token)
				if _extract_lap == completed_laps
				else game.run_flow_controller.decline_extraction(token)
			)
			if not accepted:
				failed_intent = true
				break
		state = game.run_director.current_state
		var active: bool = RunDirector.is_eligible_active_state(state)
		var empty: bool = game.combat_director.get_live_count(ActorController.Team.ENEMY) == 0
		if active and empty:
			empty_seconds += DT
			active_empty_gap += DT
			longest_empty_gap = maxf(longest_empty_gap, active_empty_gap)
		elif active:
			active_empty_gap = 0.0
		if state == RunDirector.RunState.PATROLLING:
			travel_seconds += DT
		if _use_build:
			_use_available_actions(game)
		_step(game)
		steps += 1
		if steps % 240 == 0:
			await process_frame
	var completed: bool = game.run_director.current_state == RunDirector.RunState.RUN_SUMMARY
	_failed = _failed or failed_intent or not completed
	var result: Dictionary = {
		"pacing": "historical" if legacy else "short",
		"access": "full" if full_access else "fresh", "crew": crew_id,
		"seed": _seed_value, "policy": "build_and_actions" if _use_build else "starter_hold",
		"extract_lap": _extract_lap, "completed": completed, "failed_intent": failed_intent,
		"outcome": RunDirector.result_name(game.run_director.get_result()),
		"duration": snappedf(game.run_director.run_elapsed_seconds, 0.001),
		"first_lap": snappedf(first_lap_seconds, 0.001),
		"first_lap_no_enemy": snappedf(first_lap_empty, 0.001),
		"boss_start": snappedf(boss_start, 0.001), "lap_decisions": lap_decisions,
		"fight_durations": fights, "cards": choices,
		"travel": snappedf(travel_seconds, 0.001),
		"no_enemy_seconds": snappedf(empty_seconds, 0.001),
		"longest_no_enemy_gap": snappedf(longest_empty_gap, 0.001),
		"district": game.run_director.get_district_loop_snapshot(),
		"cadence": game.cadence_tracker.get_snapshot(),
	}
	_results.append(result)
	var compact: Dictionary = result.duplicate()
	compact.erase("cadence")
	compact.erase("district")
	print("SHORT_RUN_CASE=" + JSON.stringify(compact))
	viewport.free()
	app.free()
	service.free()
	for suffix: String in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(profile_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path + suffix))
	await process_frame


func _choose_plan(game: GameRun) -> StringName:
	if not game.run_director.is_card_planning_pause_active():
		return &""
	var snapshot: Dictionary = game.card_system.get_snapshot()
	for preferred: StringName in [&"arcade", &"gang_hideout", &"convenience_store", &"subway_entrance"]:
		for card: DistrictCardDefinition in snapshot.get("offer", []):
			if card.id != preferred:
				continue
			var staged: Dictionary = game.run_flow_controller.stage_focused_district_plan_choice(
				card.id, int(snapshot.offer_revision), int(snapshot.context_lifecycle_revision),
				StringName(snapshot.lap_id), StringName(snapshot.block_id)
			)
			if not bool(staged.get("accepted", false)):
				return &""
			if bool(game.run_flow_controller.confirm_focused_district_plan_choice(int(staged.confirmation_token)).get("accepted", false)):
				return card.id
	return &""


func _resolve_reward(game: GameRun) -> bool:
	var encounter_id: int = int(game.run_flow_controller.get_snapshot().pending_reward_encounter_id)
	var token: int = game.reward_director.get_pending_equipment_choice_token(encounter_id)
	if game.reward_director.get_pending_equipment_choices(encounter_id).is_empty():
		return game.run_flow_controller.claim_standard_reward()
	if _use_build:
		for slot: int in range(3):
			if game.synergy_system.get_equipped_item(slot) == null:
				return game.run_flow_controller.claim_equipment_reward_to_inventory(
					0, SynergySystem.AREA_EQUIPPED, slot, -1, false,
					game.synergy_system.get_inventory_revision(), encounter_id, token
				)
	return game.run_flow_controller.decline_equipment_reward(encounter_id, token)


func _use_available_actions(game: GameRun) -> void:
	if game.environment_controller.get_validity_reason() == &"ok":
		game._request_environment_activation()
	if game.focus_controller.can_activate():
		game._request_focus_activation()
	if game.call_backup_controller.get_validity_reason() != &"ok":
		return
	var encounter: EncounterDefinition = game.encounter_controller.get_active_definition()
	if encounter != null and (encounter.boss or (encounter.elite_eligible and game.combat_director.get_live_count(ActorController.Team.ENEMY) >= 2)):
		game._request_backup_activation()


func _step(game: GameRun) -> void:
	game.run_director.step_run(DT)
	game.patrol_controller.step_patrol(DT)
	game.encounter_controller.step_spawn_pacing(DT)
	game.combat_director.step_simulation(DT)
	game.reward_director._process(DT)
	game.fire_hydrant_controller.step_cooldown(DT)
	game.environment_controller.step_eligible_time(DT)
	game.focus_controller.step_eligible_time(DT)
	game._process(DT)
	for actor: Node in game.get_node("DowntownLoop/EnemyContainer").get_children():
		if actor is ActorController and not actor.is_queued_for_deletion():
			(actor as ActorController)._process(DT)
