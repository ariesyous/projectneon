extends SceneTree

## Accelerated wall-clock probe of the ordinary composed GameRun. Every
## gameplay update uses a fixed 1/60-second delta; no Heat, Night Pressure,
## damage, actor-health, route, or random-stream accelerator is used. Modal
## choices are resolved through the same typed flow intents as the HUD.
## This is technical evidence only, never human/qualitative validation.

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const FIXED_DELTA_SECONDS: float = 1.0 / 60.0
const MAX_ELIGIBLE_SECONDS: float = 720.0
const FIXED_SEED: int = 6062026
const PROFILE_PATH: String = "user://wp02_long_form_probe_profile.json"


func _init() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	_remove_probe_profile()
	var service: ProfileSaveService = ProfileSaveService.new()
	service.configure_profile_path(PROFILE_PATH)
	var app: NeonAppState = NeonAppState.new()
	app.initialize(service, true)
	var viewport: SubViewport = SubViewport.new()
	viewport.name = "WP02LongFormProbe"
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(viewport)
	var game: GameRun = GAME_SCENE.instantiate() as GameRun
	game.app_state_override = app
	viewport.add_child(game)

	# Use the production menu/access path, then replace the generated seed with
	# a fixed authoritative restart before any simulated frame advances.
	game.vertical_slice_overlay.rex_button.pressed.emit()
	game.vertical_slice_overlay.start_button.pressed.emit()
	game.run_flow_controller.start_initial_run(FIXED_SEED, true)

	var last_state: int = -1
	var simulated_steps: int = 0
	var modal_resolution_failures: int = 0
	while (
		game.run_director.current_state != RunDirector.RunState.RUN_SUMMARY
		and game.run_director.run_elapsed_seconds < MAX_ELIGIBLE_SECONDS
	):
		var current_state: int = game.run_director.current_state
		if current_state != last_state:
			print(
				"WP02_LONG_FORM_STATE=%s@%.3f"
				% [RunDirector.state_name(current_state), game.run_director.run_elapsed_seconds]
			)
			last_state = current_state
		if not _resolve_non_active_state(game):
			modal_resolution_failures += 1
			if modal_resolution_failures > 1:
				break
		else:
			modal_resolution_failures = 0
		_step_composed_run(game, FIXED_DELTA_SECONDS)
		simulated_steps += 1
		if simulated_steps % 60 == 0:
			await process_frame

	var cadence: Dictionary = game.cadence_tracker.get_snapshot()
	var result_snapshot: Dictionary = game.run_director.get_snapshot()
	print(
		"WP02_LONG_FORM_RESULT=%s elapsed=%.3f seed=%d steps=%d state=%s"
		% [
			RunDirector.result_name(game.run_director.get_result()),
			game.run_director.run_elapsed_seconds,
			game.run_director.run_seed,
			simulated_steps,
			RunDirector.state_name(game.run_director.current_state),
		]
	)
	var category_snapshots: Dictionary = cadence.get("categories", {})
	for category: StringName in [
		RunCadenceTracker.CATEGORY_AMBIENT,
		RunCadenceTracker.CATEGORY_STRATEGIC,
		RunCadenceTracker.CATEGORY_MAJOR,
	]:
		var category_snapshot: Dictionary = category_snapshots.get(category, {})
		print(
			"WP02_LONG_FORM_CADENCE_%s=count:%d average:%.3f violations:%d last_gap:%.3f"
			% [
				String(category).to_upper(),
				int(category_snapshot.get("count", 0)),
				float(category_snapshot.get("average_gap", 0.0)),
				int(category_snapshot.get("violation_count", 0)),
				float(category_snapshot.get("last_gap", 0.0)),
			]
		)
	print(
		"WP02_LONG_FORM_COIN_PRESENTATIONS=%d"
		% int(cadence.get("coin_cluster_presentations", 0))
	)
	print("WP02_LONG_FORM_CADENCE=" + JSON.stringify(cadence))
	print("WP02_LONG_FORM_RUN=" + JSON.stringify(result_snapshot))
	var major_snapshot: Dictionary = category_snapshots.get(
		RunCadenceTracker.CATEGORY_MAJOR,
		{}
	)
	var major_events: Array = major_snapshot.get("events", []) as Array
	var district_snapshot: Dictionary = result_snapshot.get("district_loop", {})
	var boss_run_within_target: bool = (
		game.run_director.run_elapsed_seconds >= 8.0 * 60.0
		and game.run_director.run_elapsed_seconds <= 12.0 * 60.0
	)
	var lap_decisions_within_target: bool = (
		major_events.size() >= 2
		and StringName((major_events[0] as Dictionary).get("validation", &""))
			== RunCadenceTracker.VALIDATION_WITHIN_TARGET
		and StringName((major_events[1] as Dictionary).get("validation", &""))
			== RunCadenceTracker.VALIDATION_WITHIN_TARGET
	)
	var lifecycle_complete: bool = (
		int(district_snapshot.get("completed_laps", 0)) == 3
		and int(district_snapshot.get("completed_blocks", 0)) == 9
		and bool(district_snapshot.get("boss_committed", false))
		and (district_snapshot.get("accepted_decisions", []) as Array).size() == 2
		and game.run_director.was_boss_started()
		and game.run_director.current_state == RunDirector.RunState.RUN_SUMMARY
	)
	var gate_passed: bool = (
		modal_resolution_failures == 0
		and boss_run_within_target
		and lap_decisions_within_target
		and lifecycle_complete
	)
	print(
		"WP02_LONG_FORM_GATE=%s boss_result=%.3f lap_one=%.3f lap_two_gap=%.3f"
		% [
			"PASS" if gate_passed else "FAIL",
			game.run_director.run_elapsed_seconds,
			float((major_events[0] as Dictionary).get("gap_seconds", 0.0)) if major_events.size() >= 1 else -1.0,
			float((major_events[1] as Dictionary).get("gap_seconds", 0.0)) if major_events.size() >= 2 else -1.0,
		]
	)
	if not gate_passed:
		push_error(
			"WP02 long-form target failed: boss=%s laps=%s lifecycle=%s modal_failures=%d"
			% [
				boss_run_within_target,
				lap_decisions_within_target,
				lifecycle_complete,
				modal_resolution_failures,
			]
		)

	viewport.free()
	app.free()
	service.free()
	_remove_probe_profile()
	for _frame: int in range(10):
		await process_frame
	quit(0 if gate_passed else 1)


func _resolve_non_active_state(game: GameRun) -> bool:
	match game.run_director.current_state:
		RunDirector.RunState.REWARD_SELECTION:
			return _resolve_reward(game)
		RunDirector.RunState.SHOP:
			return game.run_flow_controller.leave_shop()
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			return game.run_flow_controller.decline_extraction(
				game.run_director.get_district_decision_token()
			)
	return true


func _resolve_reward(game: GameRun) -> bool:
	var flow_snapshot: Dictionary = game.run_flow_controller.get_snapshot()
	var encounter_id: int = int(flow_snapshot.get("pending_reward_encounter_id", -1))
	if encounter_id < 0:
		return false
	if bool(flow_snapshot.get("card_reward_phase_active", false)):
		var card_snapshot: Dictionary = game.reward_director.get_card_debug_snapshot()
		return game.run_flow_controller.skip_card_reward(
			encounter_id,
			int(card_snapshot.get("pending_choice_token", -1))
		)
	if not game.reward_director.get_pending_equipment_choices(encounter_id).is_empty():
		return game.run_flow_controller.decline_equipment_reward()
	return game.run_flow_controller.claim_standard_reward()


func _step_composed_run(game: GameRun, delta: float) -> void:
	game.run_director.step_run(delta)
	game.patrol_controller.step_patrol(delta)
	game.encounter_controller.step_spawn_pacing(delta)
	game.combat_director.step_simulation(delta)
	game.reward_director._process(delta)
	game.fire_hydrant_controller.step_cooldown(delta)
	game._process(delta)


func _remove_probe_profile() -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var path: String = PROFILE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
