@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const ARCADE: EncounterDefinition = preload("res://data/encounters/arcade_ambush.tres")


func suite_name() -> String:
	return "playability_repairs"


func test_short_profile_preserves_route_encounter_content_and_legacy_resources() -> void:
	var game: GameRun = _new_game()
	var historical_route: PatrolRouteDefinition = load("res://data/routes/downtown_loop_route.tres") as PatrolRouteDefinition
	var short_route: PatrolRouteDefinition = game.patrol_controller.route_definition
	assert_eq(short_route.travel_seconds_per_segment, 4.0, "configured approach uses four seconds")
	assert_eq(historical_route.travel_seconds_per_segment, 21.0, "historical route fixture remains unchanged")
	assert_eq(short_route.id, historical_route.id, "same stable route identity")
	assert_eq(short_route.node_ids, historical_route.node_ids, "same authored route nodes")
	assert_eq(short_route.node_types, historical_route.node_types, "same route node types")
	for definition: EncounterDefinition in game.run_flow_controller.encounter_candidates:
		var historical: EncounterDefinition = load("res://data/encounters/%s.tres" % definition.id) as EncounterDefinition
		assert_eq(_encounter_content(definition), _encounter_content(historical), "only scheduling changes for %s" % definition.id)
		assert_eq(definition.initial_spawn_delay_seconds, 1.0, "configured entry is one second")
		assert_eq(definition.spawn_interval_seconds, 4.0, "configured reinforcements are four seconds apart")
		assert_eq(historical.initial_spawn_delay_seconds, 3.0, "historical entry fixture remains unchanged")
		assert_eq(historical.spawn_interval_seconds, 12.0, "historical spawn fixture remains unchanged")
	assert_eq(game.cadence_tracker.definition.id, &"short_run_cadence", "configured telemetry uses current bands")


func test_short_approach_and_spawns_use_real_authorities_and_preserve_pause() -> void:
	var game: GameRun = _new_game()
	game._on_start_run_requested(&"jax")
	# Isolate scheduling from offer selection; the card authority still stages,
	# confirms, and dispatches the one accessible fixture card normally.
	game.card_system.configure_run_access([&"arcade"])
	var seeded_run: int = game.run_flow_controller.start_initial_run(6062026, true)
	assert_eq(seeded_run, 6062026, "fixture starts its supplied seed")
	game.run_director.complete_intro()
	var cards: Dictionary = game.card_system.get_snapshot()
	var staged: Dictionary = game.run_flow_controller.stage_focused_district_plan_choice(&"arcade", int(cards.offer_revision), int(cards.context_lifecycle_revision), StringName(cards.lap_id), StringName(cards.block_id))
	assert_true(bool(staged.get("accepted", false)), "offered combat selection stages: offer=%s seed=%d result=%s" % [str(cards.get("offer_ids", [])), game.run_director.run_seed, str(staged)])
	assert_true(bool(game.run_flow_controller.confirm_focused_district_plan_choice(int(staged.confirmation_token)).accepted), "fight confirms through the real token")
	game.patrol_controller.step_patrol(3.0)
	assert_eq(game.run_director.current_state, RunDirector.RunState.PATROLLING, "approach has not ended early")
	game.run_director.toggle_pause()
	game.patrol_controller.step_patrol(30.0)
	game.run_director.toggle_pause()
	game.patrol_controller.step_patrol(1.0)
	assert_eq(game.run_director.current_state, RunDirector.RunState.ENCOUNTER_ACTIVE, "four active approach seconds begin the chosen fight")
	assert_eq(game.combat_director.get_live_count(ActorController.Team.ENEMY), 0, "entry warning precedes spawning")
	game.encounter_controller.step_spawn_pacing(0.5)
	assert_eq(game.combat_director.get_live_count(ActorController.Team.ENEMY), 0, "half a second does not skip the warning")
	game.encounter_controller.step_spawn_pacing(0.5)
	assert_eq(game.combat_director.get_live_count(ActorController.Team.ENEMY), 1, "first enemy arrives at one second")
	game.run_director.toggle_pause()
	game.encounter_controller.step_spawn_pacing(30.0)
	assert_eq(game.combat_director.get_live_count(ActorController.Team.ENEMY), 1, "pause never accelerates the queue")
	game.run_director.toggle_pause()
	game.encounter_controller.step_spawn_pacing(3.5)
	assert_eq(game.combat_director.get_live_count(ActorController.Team.ENEMY), 1, "second enemy respects the full interval")
	game.encounter_controller.step_spawn_pacing(0.5)
	assert_eq(game.combat_director.get_live_count(ActorController.Team.ENEMY), 2, "second enemy arrives after four active seconds")


func _encounter_content(definition: EncounterDefinition) -> Dictionary:
	var signature: Dictionary = {}
	for property: StringName in [
		&"id", &"display_name", &"minimum_heat_tier", &"minimum_night_pressure",
		&"base_spawn_budget", &"maximum_concurrent_enemies", &"allowed_enemy_ids",
		&"spawn_position_ids", &"reward_table_ids", &"completion_condition",
		&"heat_gain_on_completion", &"elite_eligible", &"boss", &"environment_action_id",
	]:
		signature[property] = definition.get(property)
	var entries: Array[Dictionary] = []
	for entry: EncounterSpawnEntry in definition.spawn_entries:
		entries.append({"id": entry.actor_id, "minimum": entry.minimum_count, "maximum": entry.maximum_count, "cost": entry.budget_cost})
	signature["spawn_entries"] = entries
	return signature


func test_final_projectile_and_coins_resolve_before_reward_and_next_plan() -> void:
	var game: GameRun = _new_bottle_encounter()
	var enemy: ActorController = _windup(game)
	enemy.attack_controller.step(0.96)
	assert_eq(game.combat_director.get_live_projectile_count(), 1, "fixture: authored attack launches a bottle")
	var projectile: Node2D = game.combat_director.get_child(game.combat_director.get_child_count() - 1) as Node2D
	var before_coins: int = game.reward_director.get_coin_total()
	var base_coins: int = enemy.authored_coin_value()
	enemy.receive_damage(99999)
	assert_eq(game.run_director.current_state, RunDirector.RunState.REWARD_SELECTION, "real final kill opens reward")
	assert_eq(game.combat_director.get_live_projectile_count(), 0, "final kill removes the orphaned projectile synchronously")
	assert_false(projectile.visible, "queued projectile cannot leave a rendered remnant")
	assert_eq(game.reward_director.get_active_cluster_count(), 0, "reward boundary settles the final coin countdown")
	assert_eq(game.reward_director.get_coin_total(), before_coins + base_coins, "settlement grants full base value")
	assert_eq(game.reward_director.settle_pending_coin_clusters_as_base(), 0, "settlement cannot credit twice")
	_decline_reward(game)
	assert_true(game.run_director.is_card_planning_pause_active(), "reward goes straight to real next PLAN")
	for frame: int in range(300):
		game.combat_director.step_simulation(1.0 / 60.0)
	assert_eq(game.combat_director.get_live_projectile_count(), 0, "no frozen projectile survives five paused seconds")


func test_killed_windup_cannot_freeze_a_warning_in_next_plan() -> void:
	var game: GameRun = _new_bottle_encounter()
	var enemy: ActorController = _windup(game)
	assert_eq(_visible_warnings(game), 1, "fixture: live windup has one warning")
	enemy.receive_damage(99999)
	assert_eq(_visible_warnings(game), 0, "cancelled threat disappears before reward")
	_decline_reward(game)
	assert_true(game.run_director.is_card_planning_pause_active(), "real PLAN owns the pause")
	assert_eq(_visible_warnings(game), 0, "PLAN cannot suspend a dead threat")


func test_live_warning_and_projectile_survive_ordinary_combat_pause() -> void:
	var game: GameRun = _new_bottle_encounter()
	var enemy: ActorController = _windup(game)
	var warning: CombatTelegraph = _first_warning(game)
	var before: float = warning.get_remaining_seconds()
	assert_true(game.run_director.toggle_pause(), "ordinary combat pause accepted")
	warning._process(5.0)
	assert_eq(warning.get_remaining_seconds(), before, "live windup does not expire while paused")
	assert_true(warning.visible, "live threat remains available on resume")
	assert_true(game.run_director.toggle_pause(), "ordinary pause resumes")
	enemy.attack_controller.step(0.96)
	assert_eq(_visible_warnings(game), 0, "warning retires when its attack becomes active")
	assert_eq(game.combat_director.get_live_projectile_count(), 1, "live projectile starts normally")
	var projectiles: Array[Dictionary] = game.combat_director.get_projectile_snapshot()
	game.run_director.toggle_pause()
	game.combat_director.step_simulation(5.0)
	assert_eq(game.combat_director.get_projectile_snapshot(), projectiles, "ordinary pause preserves live projectile state")
	game.run_director.toggle_pause()
	game.combat_director.step_simulation(0.1)
	assert_ne(game.combat_director.get_projectile_snapshot(), projectiles, "projectile advances after resume")


func test_interrupted_warning_retires_without_ending_the_encounter() -> void:
	var game: GameRun = _new_bottle_encounter()
	var enemy: ActorController = _windup(game)
	enemy.apply_stun(1.0)
	assert_eq(game.run_director.current_state, RunDirector.RunState.ENCOUNTER_ACTIVE, "interruption keeps fight active")
	assert_eq(_visible_warnings(game), 0, "interrupted attack no longer advertises danger")


func test_plan_confirm_and_clear_labels_fit_the_actual_button_content_area() -> void:
	var game: GameRun = _new_game()
	game.vertical_slice_overlay.start_button.pressed.emit()
	game.run_director.complete_intro()
	for button: Button in [game.game_hud.district_card_confirm_button, game.game_hud.district_card_cancel_button]:
		var style: StyleBox = button.get_theme_stylebox(&"normal")
		var width: float = button.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
		var text_width: float = button.get_theme_font(&"font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size(&"font_size")).x
		assert_true(text_width <= width, "%s must fit without clipping" % button.text)


func _new_game() -> GameRun:
	var app: NeonAppState = track(NeonAppState.new()) as NeonAppState
	var service: ProfileSaveService = track(ProfileSaveService.new("user://playability_fixture_%d.json" % Time.get_ticks_usec())) as ProfileSaveService
	app.initialize(service, true)
	app.profile.settings.pause_on_focus_loss = false
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var game: GameRun = GAME_SCENE.instantiate() as GameRun
	game.app_state_override = app
	viewport.add_child(game)
	(Engine.get_main_loop() as SceneTree).root.add_child(viewport)
	return game


func _new_bottle_encounter() -> GameRun:
	var game: GameRun = _new_game()
	game.vertical_slice_overlay.start_button.pressed.emit()
	game.run_director.complete_intro()
	var cards: Dictionary = game.card_system.get_snapshot()
	var card: DistrictCardDefinition = cards.offer[0] as DistrictCardDefinition
	var staged: Dictionary = game.run_flow_controller.stage_focused_district_plan_choice(card.id, int(cards.offer_revision), int(cards.context_lifecycle_revision), StringName(cards.lap_id), StringName(cards.block_id))
	assert_true(bool(game.run_flow_controller.confirm_focused_district_plan_choice(int(staged.confirmation_token)).accepted), "fixture: real plan confirms")
	var occurrence: StringName = &"repair_final_enemy"
	game.run_director.begin_district_block(occurrence, &"encounter")
	game.card_system.resolve_focused_district_plan_block(1, occurrence, 1, occurrence, &"encounter", game.run_director.get_district_loop_snapshot())
	var encounter: EncounterDefinition = ARCADE.duplicate(true) as EncounterDefinition
	var spawn: EncounterSpawnEntry = EncounterSpawnEntry.new()
	spawn.actor_id = &"bottle_thrower"
	spawn.minimum_count = 1
	spawn.maximum_count = 1
	spawn.budget_cost = 1
	encounter.base_spawn_budget = 1
	encounter.spawn_entries = [spawn]
	encounter.allowed_enemy_ids = [&"bottle_thrower"]
	encounter.initial_spawn_delay_seconds = 0.0
	encounter.spawn_interval_seconds = 0.0
	assert_true(game.run_flow_controller._start_encounter(encounter, RunFlowController.ENCOUNTER_SOURCE_BASELINE, true, 0), "fixture: one final enemy encounter begins")
	return game


func _windup(game: GameRun) -> ActorController:
	var enemy: ActorController = game.combat_director.get_live_actors(ActorController.Team.ENEMY)[0]
	var crew: ActorController = game.get_selected_crew_actor()
	enemy.global_position = Vector2(430.0, 226.0)
	crew.global_position = Vector2(280.0, 226.0)
	enemy.assign_target(crew)
	enemy._start_planned_attack(enemy.attack_definition)
	return enemy


func _decline_reward(game: GameRun) -> void:
	var encounter_id: int = int(game.run_flow_controller.get_snapshot().pending_reward_encounter_id)
	assert_true(game.run_flow_controller.decline_equipment_reward(encounter_id, game.reward_director.get_pending_equipment_choice_token(encounter_id)), "fixture: reward decline uses its exact token")


func _visible_warnings(game: GameRun) -> int:
	var count: int = 0
	for child: Node in game.get_node("DowntownLoop/EffectsContainer").get_children():
		if child is CombatTelegraph and (child as CombatTelegraph).visible and not child.is_queued_for_deletion():
			count += 1
	return count


func _first_warning(game: GameRun) -> CombatTelegraph:
	for child: Node in game.get_node("DowntownLoop/EffectsContainer").get_children():
		if child is CombatTelegraph and not child.is_queued_for_deletion():
			return child as CombatTelegraph
	return null
