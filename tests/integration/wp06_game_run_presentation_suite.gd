@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const ALLEY: EncounterDefinition = preload("res://data/encounters/alley_scuffle.tres")
const ARCADE: EncounterDefinition = preload("res://data/encounters/arcade_ambush.tres")
const VIPER_SIGNAL: EncounterDefinition = preload("res://data/encounters/viper_signal.tres")
const BOTTLE: PackedScene = preload("res://scenes/actors/bottle_thrower.tscn")
const STREET_PUNK: PackedScene = preload("res://scenes/actors/street_punk.tscn")


class GameFixture extends RefCounted:
	var viewport: SubViewport
	var game: GameRun
	var app: NeonAppState
	var service: ProfileSaveService
	var profile_path: String = ""


var _test_paths: Array[String] = []
var _path_nonce: int = 0


func suite_name() -> String:
	return "wp06_game_run_presentation"


func setup() -> void:
	_test_paths.clear()


func teardown() -> void:
	for path: String in _test_paths:
		_remove_path(path)
		_remove_path(path + ".tmp")
		_remove_path(path + ".bak")


func test_configured_game_composes_authored_world_and_phase_presenter_without_debug_leak() -> void:
	var fixture: GameFixture = _new_game()
	assert_true(fixture.game.phase_transition_presenter != null, "composition: phase transition presenter exists")
	assert_true(fixture.game.downtown_loop.backdrop != null, "composition: authored backdrop exists")
	assert_false(fixture.game.downtown_loop.lane_markers.visible, "composition: lanes hidden by default")
	assert_false(fixture.game.downtown_loop.route_markers.visible, "composition: route debug hidden by default")
	assert_false(fixture.game.get_node("DowntownLoop/LaneMarkers/BackLaneLabel").is_visible_in_tree(), "composition: no release lane label")
	assert_false(fixture.game.get_node("DowntownLoop/RouteNodes/RouteLabel").is_visible_in_tree(), "composition: no release route placeholder")
	assert_eq(fixture.game.downtown_loop.get_world_presentation_snapshot().profile_id, &"alley", "composition: menu starts in authored neutral block")


func test_existing_encounter_context_drives_stage_profile_and_distinct_environment_object() -> void:
	var alley: GameFixture = _new_started_encounter(ALLEY, &"jax", &"wp06_alley")
	assert_eq(alley.game.downtown_loop.get_world_presentation_snapshot().profile_id, &"alley", "context: Alley profile follows existing encounter")
	assert_true(alley.game.fire_hydrant.visible, "context: Alley retains Hydrant")
	assert_false(alley.game.power_box.visible, "context: Alley hides Power Box")
	assert_false(alley.game.fire_hydrant._state_label.visible, "context: inactive Hydrant has no unexplained world label")

	var arcade: GameFixture = _new_started_encounter(ARCADE, &"zoey", &"wp06_arcade")
	assert_eq(arcade.game.downtown_loop.get_world_presentation_snapshot().profile_id, &"arcade", "context: Arcade profile follows existing encounter")
	assert_false(arcade.game.fire_hydrant.visible, "context: Arcade replaces Hydrant")
	assert_true(arcade.game.power_box.visible, "context: Arcade integrates Power Box")
	assert_false(arcade.game.power_box._state_label.visible, "context: Power Box label stays quiet without a live tell")

	var viper: GameFixture = _new_started_encounter(VIPER_SIGNAL, &"rex", &"wp06_viper")
	assert_eq(viper.game.downtown_loop.get_world_presentation_snapshot().profile_id, &"viper", "context: existing elite encounter selects lockdown frontage")
	assert_eq(viper.game.run_director.get_random_schema_version(), 1, "context: random schema unchanged")


func test_projectile_intent_focus_and_power_box_keep_three_distinct_shape_contracts() -> void:
	var fixture: GameFixture = _new_started_encounter(ARCADE, &"zoey", &"wp06_shapes")
	var enemy: ActorController = _spawn_bottle_threat(fixture.game)
	fixture.game.focus_controller.step_eligible_time(0.001)
	var telegraph: CombatTelegraph = _first_telegraph(fixture.game)
	assert_true(telegraph != null, "shapes: live intent creates world telegraph")
	assert_eq(telegraph.get_presentation_snapshot().kind, CombatTelegraph.TelegraphKind.PROJECTILE, "shapes: Bottle uses projectile relationship")
	assert_eq(telegraph.get_presentation_snapshot().intent_label, "BOTTLE THROW", "shapes: named text remains")
	assert_eq(enemy.actor_visual.get_presentation_snapshot().focus_shape, &"corner_brackets", "shapes: Focus uses brackets")
	assert_eq(enemy.actor_visual.get_presentation_snapshot().target_shape, &"diamond", "shapes: target uses diamond")
	assert_true(fixture.game.power_box.is_preview_visible() == false, "shapes: Environment footprint is contextual")
	fixture.game.power_box.set_external_preview_visible(true)
	assert_true(fixture.game.power_box.is_preview_visible(), "shapes: Power Box octagonal footprint can be inspected")


func test_accessibility_reductions_apply_without_removing_shape_text_or_audio_categories() -> void:
	var fixture: GameFixture = _new_started_encounter(ALLEY, &"jax", &"wp06_accessibility")
	var settings: GameSettingsData = GameSettingsData.create_default()
	settings.screen_shake_intensity = 0.0
	settings.damage_numbers_enabled = false
	settings.hit_flash_reduction = 1.0
	settings.master_volume = 0.0
	fixture.game._apply_settings(settings)
	assert_eq(fixture.game.screen_shake_controller.get_intensity(), 0.0, "accessibility: shake disabled")
	assert_false(fixture.game.combat_feedback.are_damage_numbers_enabled(), "accessibility: numbers disabled")
	var crew: ActorController = fixture.game.get_selected_crew_actor()
	assert_true(crew != null, "accessibility: selected crew remains")
	assert_eq(crew.actor_visual.get_presentation_snapshot().hit_flash_reduction, 1.0, "accessibility: flash fully reduced")
	crew.actor_visual.set_statuses(2, true)
	assert_eq(crew.actor_visual.get_presentation_snapshot().bleed_shape, &"droplet", "accessibility: Bleed remains shape-coded")
	assert_eq(crew.actor_visual.get_presentation_snapshot().shock_shape, &"bolt", "accessibility: Shock remains shape-coded")
	fixture.game.phase_transition_presenter.present_state(RunDirector.RunState.ENCOUNTER_ACTIVE, {"lap_index": 1, "block_index": 1}, false)
	assert_false(str(fixture.game.phase_transition_presenter.get_snapshot().heading).is_empty(), "accessibility: phase transition retains text")
	assert_eq(AudioBusContract.get_linear_volume(AudioBusContract.BUS_MASTER), 0.0, "accessibility: audio category mute applied")
	fixture.game._apply_settings(GameSettingsData.create_default())


func test_presentation_activity_mutates_no_heat_pressure_tokens_or_stream_state() -> void:
	var fixture: GameFixture = _new_started_encounter(ALLEY, &"jax", &"wp06_isolation")
	var before: Dictionary = _authority_projection(fixture.game)
	for lap: int in range(1, 4):
		fixture.game.downtown_loop.present_world_snapshot({
			"run": {
				"state": RunDirector.RunState.ENCOUNTER_ACTIVE,
				"state_name": "ENCOUNTER_ACTIVE",
				"district_loop": {"lap_index": lap, "block_index": 2},
			},
			"encounter": {"active_encounter_id": &"alley_scuffle", "boss_active": false},
			"cards": {},
			"environment": {"action_id": &"fire_hydrant"},
		})
		fixture.game.phase_transition_presenter.present_state(RunDirector.RunState.ENCOUNTER_ACTIVE, {"lap_index": lap, "block_index": 2}, false)
		fixture.game.combat_feedback.show_hit(Vector2(320.0, 226.0), 10.0, lap > 1, &"heavy" if lap > 1 else &"light")
	assert_eq(_authority_projection(fixture.game), before, "isolation: world/effect/transition activity leaves full authority unchanged")


func test_peak_density_presentation_remains_bounded_and_cleanup_is_exact() -> void:
	var fixture: GameFixture = _new_started_encounter(ALLEY, &"rex", &"wp06_peak")
	var crew: ActorController = fixture.game.get_selected_crew_actor()
	for index: int in range(30):
		var enemy: ActorController = STREET_PUNK.instantiate() as ActorController
		fixture.game.get_node("DowntownLoop/EnemyContainer").add_child(enemy)
		enemy.set_process(false)
		enemy.set_physics_process(false)
		enemy.global_position = Vector2(170.0 + float(index % 10) * 29.0, [194.0, 226.0, 258.0][index % 3])
		assert_true(fixture.game.combat_director.register_actor(enemy), "peak: enemy %d registers" % index)
		if crew != null:
			enemy.assign_target(crew)
	for hit_index: int in range(72):
		fixture.game.combat_feedback.show_hit(Vector2(180.0 + float(hit_index % 20) * 13.0, 210.0), 8.0, hit_index % 4 == 0)
	assert_eq(fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY), 30, "peak: supported ordinary density represented")
	assert_true(fixture.game.combat_feedback.get_live_transient_count() <= 48, "peak: feedback remains capped")
	fixture.game._clear_combat_telegraphs()
	fixture.game.phase_transition_presenter.clear()
	fixture.game.combat_director.clear_all()
	assert_eq(fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY), 0, "cleanup: peak actors clear")
	assert_eq(_count_telegraphs(fixture.game), 0, "cleanup: telegraphs clear")
	assert_false(fixture.game.phase_transition_presenter.is_transition_active(), "cleanup: transition clears")


func _new_started_encounter(
	definition: EncounterDefinition,
	crew_id: StringName,
	occurrence_id: StringName
) -> GameFixture:
	var fixture: GameFixture = _new_game()
	match crew_id:
		&"zoey":
			fixture.game.vertical_slice_overlay.zoey_button.pressed.emit()
		&"rex":
			fixture.game.vertical_slice_overlay.rex_button.pressed.emit()
		_:
			fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	assert_true(fixture.game.run_director.complete_intro(), "fixture: intro reaches PLAN")
	assert_true(_confirm_current_plan(fixture.game), "fixture: focused plan confirms")
	assert_true(fixture.game.run_director.begin_district_block(occurrence_id, &"encounter"), "fixture: block begins")
	assert_true(_resolve_direct_block(fixture.game, occurrence_id, &"encounter"), "fixture: plan resolves")
	assert_true(bool(fixture.game.run_flow_controller.call(
		"_start_encounter",
		definition,
		RunFlowController.ENCOUNTER_SOURCE_BASELINE,
		true,
		0
	)), "fixture: encounter starts")
	while fixture.game.tutorial_controller.dismiss_current():
		pass
	fixture.game.game_hud.action_toast.hide()
	return fixture


func _new_game() -> GameFixture:
	_path_nonce += 1
	var fixture: GameFixture = GameFixture.new()
	fixture.profile_path = "user://wp06_game_run_%d_%d.json" % [Time.get_ticks_usec(), _path_nonce]
	_test_paths.append(fixture.profile_path)
	fixture.service = track(ProfileSaveService.new()) as ProfileSaveService
	fixture.service.configure_profile_path(fixture.profile_path)
	fixture.app = track(NeonAppState.new()) as NeonAppState
	fixture.app.initialize(fixture.service, true)
	fixture.viewport = track(SubViewport.new()) as SubViewport
	fixture.viewport.size = Vector2i(1280, 720)
	fixture.viewport.disable_3d = true
	fixture.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	fixture.game = GAME_SCENE.instantiate() as GameRun
	fixture.game.app_state_override = fixture.app
	fixture.viewport.add_child(fixture.game)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(fixture.viewport)
	return fixture


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


func _resolve_direct_block(game: GameRun, occurrence_id: StringName, node_type: StringName) -> bool:
	var loop: Dictionary = game.run_director.get_district_loop_snapshot()
	return game.card_system.resolve_focused_district_plan_block(
		int(loop.get("block_index", 1)),
		occurrence_id,
		int(loop.get("block_index", 1)),
		occurrence_id,
		node_type,
		loop
	) != null


func _spawn_bottle_threat(game: GameRun) -> ActorController:
	var enemy: ActorController = BOTTLE.instantiate() as ActorController
	game.get_node("DowntownLoop/EnemyContainer").add_child(enemy)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.global_position = Vector2(370.0, 226.0)
	assert_true(game.combat_director.register_actor(enemy), "fixture: Bottle registers")
	var crew: ActorController = game.get_selected_crew_actor()
	assert_true(crew != null and enemy.assign_target(crew), "fixture: Bottle targets crew")
	enemy._start_planned_attack(enemy.attack_definition)
	return enemy


func _first_telegraph(game: GameRun) -> CombatTelegraph:
	for child: Node in game.get_node("DowntownLoop/EffectsContainer").get_children():
		if child is CombatTelegraph:
			return child as CombatTelegraph
	return null


func _count_telegraphs(game: GameRun) -> int:
	var count: int = 0
	for child: Node in game.get_node("DowntownLoop/EffectsContainer").get_children():
		if child is CombatTelegraph:
			count += 1
	return count


func _authority_projection(game: GameRun) -> Dictionary:
	return {
		"state": game.run_director.current_state,
		"heat": game.run_director.heat,
		"pressure": game.run_director.night_pressure,
		"district": game.run_director.get_district_loop_snapshot(),
		"cards": game.card_system.get_snapshot(),
		"inventory_revision": game.synergy_system.get_inventory_revision(),
		"streams": game.run_director.get_random_streams().capture_states(),
		"schema": game.run_director.get_random_schema_version(),
	}


func _remove_path(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
