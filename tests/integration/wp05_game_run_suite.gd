@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const ALLEY: EncounterDefinition = preload("res://data/encounters/alley_scuffle.tres")
const ARCADE: EncounterDefinition = preload("res://data/encounters/arcade_ambush.tres")
const BOTTLE: PackedScene = preload("res://scenes/actors/bottle_thrower.tscn")


class GameFixture extends RefCounted:
	var viewport: SubViewport
	var game: GameRun
	var app: NeonAppState
	var service: ProfileSaveService
	var profile_path: String = ""


var _test_paths: Array[String] = []
var _path_nonce: int = 0


func suite_name() -> String:
	return "wp05_game_run"


func setup() -> void:
	_test_paths.clear()


func teardown() -> void:
	for path: String in _test_paths:
		_remove_path(path)
		_remove_path(path + ".tmp")
		_remove_path(path + ".bak")


func test_configured_scene_exposes_only_three_production_combat_roles() -> void:
	var fixture: GameFixture = _new_game()
	assert_true(fixture.game.environment_controller != null, "composition: Environment authority exists")
	assert_true(fixture.game.focus_controller != null, "composition: Focus authority exists")
	assert_true(fixture.game.call_backup_controller != null, "composition: Backup authority exists")
	assert_true(fixture.game.power_box != null, "composition: Power Box world surface exists")
	assert_true(fixture.game.fire_hydrant != null, "composition: Hydrant world surface remains")
	assert_true(fixture.game.get_node_or_null("WP05PrototypeRuntime") == null, "composition: no prototype runtime is created")
	assert_true(fixture.game.game_hud.get_node_or_null("Root/WP05RallyPrototype") == null, "composition: no Rally control exists")
	assert_eq(fixture.game.environment_controller.get_current_action_id(), &"", "composition: menu has no combat Environment context")
	assert_false(fixture.game.game_hud.interventions_panel.is_visible_in_tree(), "composition: Environment hides outside combat")
	assert_false(fixture.game.game_hud.focus_placeholder_button.is_visible_in_tree(), "composition: Focus hides outside combat")
	assert_false(fixture.game.game_hud.backup_button.is_visible_in_tree(), "composition: Backup hides outside combat")


func test_encounter_context_swaps_one_world_object_and_pause_preserves_it() -> void:
	var hydrant_fixture: GameFixture = _new_started_encounter(ALLEY, &"wp05_hydrant_context")
	assert_eq(hydrant_fixture.game.environment_controller.get_current_action_id(), EnvironmentController.ACTION_HYDRANT, "context: alley selects Hydrant")
	assert_true(hydrant_fixture.game.fire_hydrant.visible, "context: Hydrant world object is visible")
	assert_false(hydrant_fixture.game.power_box.visible, "context: Power Box world object is hidden")
	assert_contains(hydrant_fixture.game.game_hud.hydrant_button.text, "HYDRANT", "context: existing slot names Hydrant")

	var power_fixture: GameFixture = _new_started_encounter(ARCADE, &"wp05_power_context")
	assert_eq(power_fixture.game.environment_controller.get_current_action_id(), EnvironmentController.ACTION_POWER_BOX, "context: arcade selects Power Box")
	assert_false(power_fixture.game.fire_hydrant.visible, "context: Hydrant hides when replaced")
	assert_true(power_fixture.game.power_box.visible, "context: Power Box becomes the one street object")
	assert_contains(power_fixture.game.game_hud.hydrant_button.text, "BREAKER", "context: existing slot changes verb")
	var revision_before_pause: int = power_fixture.game.environment_controller.get_context_revision()
	assert_true(power_fixture.game.run_director.toggle_pause(), "context: combat pauses")
	assert_eq(power_fixture.game.environment_controller.get_current_action_id(), EnvironmentController.ACTION_POWER_BOX, "context: pause retains encounter object identity")
	assert_false(power_fixture.game.environment_controller.combat_available, "context: pause rejects activation")
	assert_true(power_fixture.game.run_director.toggle_pause(), "context: combat resumes")
	assert_eq(power_fixture.game.environment_controller.get_current_action_id(), EnvironmentController.ACTION_POWER_BOX, "context: resume restores same object")
	assert_true(power_fixture.game.environment_controller.combat_available, "context: combat availability returns")
	assert_true(power_fixture.game.environment_controller.get_context_revision() > revision_before_pause, "context: pause/resume invalidates old caller context")


func test_enemy_intent_world_marker_and_pointer_touch_environment_paths_are_live() -> void:
	for use_touch: bool in [false, true]:
		var fixture: GameFixture = _new_started_encounter(
			ARCADE,
			StringName("wp05_pointer_touch_%s" % ("touch" if use_touch else "mouse"))
		)
		var enemy: ActorController = _spawn_bottle_threat(fixture.game)
		fixture.game.focus_controller.step_eligible_time(0.001)
		var focus_snapshot: Dictionary = fixture.game.focus_controller.get_snapshot()
		assert_eq(focus_snapshot.target_id, &"bottle_thrower", "intent: Bottle target is authoritative")
		assert_eq(focus_snapshot.intent_label, "BOTTLE THROW", "intent: named throw is authoritative")
		assert_true(float(focus_snapshot.window_seconds) >= 0.35, "intent: readable countdown remains")
		assert_contains(fixture.game.game_hud.focus_placeholder_button.text, "THROWER", "intent: HUD names target")
		assert_contains(fixture.game.game_hud.focus_placeholder_button.text, "THROW", "intent: HUD names attack")
		assert_eq(_count_telegraphs(fixture.game), 1, "intent: one world shape/label marker appears")
		var telegraph: CombatTelegraph = _first_telegraph(fixture.game)
		assert_contains((telegraph.get_child(0) as Label).text, "BOTTLE THROW", "intent: world marker carries same label")
		var health_before: int = enemy.health_component.current_health
		if use_touch:
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.pressed = true
			touch.position = enemy.global_position
			fixture.game.power_box._input_event(fixture.viewport, touch, 0)
		else:
			var mouse: InputEventMouseButton = InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = true
			mouse.position = enemy.global_position
			fixture.game.power_box._input_event(fixture.viewport, mouse, 0)
		assert_eq(health_before - enemy.health_component.current_health, 4, "input parity: pointer/touch reaches same Power Box authority")
		assert_eq(fixture.game.environment_controller.get_shared_cooldown_remaining(), 12.0, "input parity: one exact cooldown commits")


func test_number_keys_map_to_environment_focus_backup_and_four_is_inert() -> void:
	var fixture: GameFixture = _new_started_encounter(ARCADE, &"wp05_number_keys")
	var enemy: ActorController = _spawn_bottle_threat(fixture.game)
	fixture.game.focus_controller.step_eligible_time(0.001)
	var subway_before: int = fixture.game.cooling_controller.get_subway_charges()
	_press_key(fixture.game, KEY_2)
	assert_eq(fixture.game.focus_controller.get_snapshot().active_target_instance_id, enemy.get_instance_id(), "keys: 2 activates Focus")
	_press_key(fixture.game, KEY_1)
	assert_eq(fixture.game.environment_controller.get_shared_cooldown_remaining(), 12.0, "keys: 1 activates context Environment")
	_press_key(fixture.game, KEY_3)
	assert_eq(fixture.game.call_backup_controller.get_active_allies().size(), 2, "keys: 3 activates finite Backup")
	assert_eq(fixture.game.call_backup_controller.get_charges_remaining(), 1, "keys: Backup spends one of two run charges")
	assert_eq(fixture.game.cooling_controller.get_subway_charges(), subway_before, "keys: combat key 3 never spends strategic Subway")
	var environment_after: Dictionary = fixture.game.environment_controller.get_snapshot()
	var focus_after: Dictionary = fixture.game.focus_controller.get_snapshot()
	var backup_after: Dictionary = fixture.game.call_backup_controller.get_snapshot()
	_press_key(fixture.game, KEY_4)
	assert_eq(fixture.game.environment_controller.get_snapshot(), environment_after, "keys: removed fourth role cannot mutate Environment")
	assert_eq(fixture.game.focus_controller.get_snapshot(), focus_after, "keys: removed fourth role cannot mutate Focus")
	assert_eq(fixture.game.call_backup_controller.get_snapshot(), backup_after, "keys: removed fourth role cannot mutate Backup")
	assert_contains(fixture.game.game_hud.backup_button.text, "3", "keys: HUD reinforces Backup key")


func test_terminal_restart_and_menu_cleanup_clear_all_three_roles_and_world_cues() -> void:
	var fixture: GameFixture = _new_started_encounter(ARCADE, &"wp05_cleanup")
	var enemy: ActorController = _spawn_bottle_threat(fixture.game)
	fixture.game.focus_controller.step_eligible_time(0.001)
	_press_key(fixture.game, KEY_2)
	_press_key(fixture.game, KEY_3)
	assert_eq(fixture.game.focus_controller.get_snapshot().active_target_instance_id, enemy.get_instance_id(), "cleanup: Focus begins active")
	assert_eq(fixture.game.call_backup_controller.get_active_allies().size(), 2, "cleanup: Backup begins active")
	assert_true(fixture.game.run_director.notify_all_crew_incapacitated(), "cleanup: terminal defeat accepts")
	assert_eq(fixture.game.environment_controller.get_current_action_id(), &"", "cleanup: terminal clears Environment context")
	assert_eq(fixture.game.focus_controller.get_snapshot().active_target_instance_id, -1, "cleanup: terminal clears Focus target")
	assert_eq(fixture.game.call_backup_controller.get_active_allies().size(), 0, "cleanup: terminal removes Backup allies")
	assert_false(fixture.game.environment_controller.simulation_enabled, "cleanup: terminal disables Environment")
	assert_false(fixture.game.focus_controller.simulation_enabled, "cleanup: terminal disables Focus")
	assert_eq(_count_telegraphs(fixture.game), 0, "cleanup: terminal clears intent world cues")
	fixture.game.vertical_slice_overlay.restart_same_seed_requested.emit()
	assert_eq(fixture.game.environment_controller.get_shared_cooldown_remaining(), 0.0, "cleanup: restart clears Environment cooldown")
	assert_eq(fixture.game.focus_controller.get_snapshot().cooldown_remaining, 0.0, "cleanup: restart clears Focus cooldown")
	assert_eq(fixture.game.call_backup_controller.get_charges_remaining(), 2, "cleanup: restart restores two Backup charges")
	fixture.game.vertical_slice_overlay.return_to_main_menu_requested.emit()
	assert_eq(fixture.game.run_director.current_state, RunDirector.RunState.INITIALIZING, "cleanup: menu returns to initial state")
	assert_eq(fixture.game.environment_controller.get_current_action_id(), &"", "cleanup: menu has no Environment context")
	assert_eq(fixture.game.focus_controller.get_snapshot().active_target_instance_id, -1, "cleanup: menu has no Focus target")
	assert_eq(fixture.game.call_backup_controller.get_active_allies().size(), 0, "cleanup: menu has no Backup actors")


func _new_started_encounter(definition: EncounterDefinition, occurrence_id: StringName) -> GameFixture:
	var fixture: GameFixture = _new_game()
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	assert_true(fixture.game.run_director.complete_intro(), "fixture: intro reaches plan")
	assert_true(_confirm_current_district_plan(fixture.game), "fixture: focused District Plan confirms")
	assert_true(fixture.game.run_director.begin_district_block(occurrence_id, &"encounter"), "fixture: district block begins")
	assert_true(_resolve_direct_focused_block(fixture.game, occurrence_id, &"encounter"), "fixture: plan resolves for occurrence")
	assert_true(bool(fixture.game.run_flow_controller.call(
		"_start_encounter",
		definition,
		RunFlowController.ENCOUNTER_SOURCE_BASELINE,
		true,
		0
	)), "fixture: RunFlow starts configured encounter")
	return fixture


func _new_game() -> GameFixture:
	_path_nonce += 1
	var fixture: GameFixture = GameFixture.new()
	fixture.profile_path = "user://wp05_game_run_%d_%d.json" % [Time.get_ticks_usec(), _path_nonce]
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


func _spawn_bottle_threat(game: GameRun) -> ActorController:
	var enemy: ActorController = BOTTLE.instantiate() as ActorController
	game.get_node("DowntownLoop/EnemyContainer").add_child(enemy)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.global_position = Vector2(370.0, 226.0)
	assert_true(game.combat_director.register_actor(enemy), "fixture: Bottle registers")
	var crew: Array[ActorController] = game.encounter_controller.get_permanent_crew()
	assert_eq(crew.size(), 1, "fixture: one permanent crew exists")
	assert_true(enemy.assign_target(crew[0]), "fixture: Bottle targets crew")
	enemy._start_planned_attack(enemy.attack_definition)
	return enemy


func _confirm_current_district_plan(game: GameRun) -> bool:
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


func _resolve_direct_focused_block(
	game: GameRun,
	occurrence_id: StringName,
	baseline_node_type: StringName
) -> bool:
	var loop: Dictionary = game.run_director.get_district_loop_snapshot()
	return game.card_system.resolve_focused_district_plan_block(
		int(loop.get("block_index", 1)),
		occurrence_id,
		int(loop.get("block_index", 1)),
		occurrence_id,
		baseline_node_type,
		loop
	) != null


func _press_key(game: GameRun, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	game._input(event)


func _count_telegraphs(game: GameRun) -> int:
	var count: int = 0
	for child: Node in game.get_node("DowntownLoop/EffectsContainer").get_children():
		if child is CombatTelegraph:
			count += 1
	return count


func _first_telegraph(game: GameRun) -> CombatTelegraph:
	for child: Node in game.get_node("DowntownLoop/EffectsContainer").get_children():
		if child is CombatTelegraph:
			return child as CombatTelegraph
	return null


func _remove_path(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
