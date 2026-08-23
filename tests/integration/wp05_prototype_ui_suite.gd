@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

## Post-selection compatibility coverage for the Part A presentation boundary.
## Prototype Resources remain reproducible evidence, while configured GameHUD
## exposes only the approved Environment / Focus / Backup vocabulary.

const DESIGN_SIZE: Vector2i = Vector2i(1280, 720)
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const POWER_ICON: Texture2D = preload("res://assets/icons/interventions/power_box.svg")


class IntentCapture extends RefCounted:
	var environment: Dictionary = {}
	var focus: Dictionary = {}
	var backup: Dictionary = {}

	func on_environment(action_id: StringName, revision: int, token: int) -> void:
		environment = {"action_id": action_id, "revision": revision, "token": token}

	func on_focus(target_id: int, attack_id: StringName, revision: int, token: int) -> void:
		focus = {"target_id": target_id, "attack_id": attack_id, "revision": revision, "token": token}

	func on_backup(revision: int, token: int) -> void:
		backup = {"revision": revision, "token": token}


func suite_name() -> String:
	return "wp05_prototype_ui"


func test_owner_selection_replaces_part_a_controls_with_three_production_roles() -> void:
	var hud: GameHUD = _new_hud()
	hud.present_flow_snapshot(_combat_flow_snapshot())
	assert_contains(hud.hydrant_button.text, "BREAKER", "production UI: context verb occupies Environment slot")
	assert_eq(hud.hydrant_button.icon, POWER_ICON, "production UI: Power Box uses production icon")
	assert_contains(hud.hydrant_button.text, "2 TARGETS", "production UI: Environment target count is textual")
	assert_contains(hud.focus_placeholder_button.text, "THROWER", "production UI: Focus names the target")
	assert_contains(hud.focus_placeholder_button.text, "THROW", "production UI: Focus names enemy intent")
	assert_contains(hud.backup_button.text, "3", "production UI: Backup is the third combat role")
	assert_false(hud.subway_reroute_button.visible, "production UI: strategic Subway is outside combat")
	assert_eq(hud.cards_panel.size.x, 560.0, "production UI: Focus/Backup strip keeps bounded width")
	assert_true(hud.get_node_or_null("Root/WP05RallyPrototype") == null, "production UI: Rally control is removed")
	assert_false(_hud_source().contains("wp05_proto_"), "production UI: no prototype identity remains in GameHUD")
	assert_false(_hud_source().contains("HANGING_SIGN"), "production UI: Hanging Sign is absent from release HUD")
	assert_false(_hud_source().contains("4 DEV"), "production UI: fourth development control is absent")


func test_mouse_touch_keyboard_button_path_forwards_exact_production_context() -> void:
	var hud: GameHUD = _new_hud()
	var capture: IntentCapture = IntentCapture.new()
	hud.environment_activation_requested.connect(capture.on_environment)
	hud.focus_activation_requested.connect(capture.on_focus)
	hud.backup_activation_context_requested.connect(capture.on_backup)
	hud.present_flow_snapshot(_combat_flow_snapshot())
	hud.hydrant_button.pressed.emit()
	hud.focus_placeholder_button.pressed.emit()
	hud.backup_button.pressed.emit()
	assert_eq(capture.environment, {"action_id": &"power_box", "revision": 11, "token": 101}, "production UI: Environment exact context forwarded")
	assert_eq(capture.focus, {"target_id": 7001, "attack_id": &"bottle_throw", "revision": 12, "token": 102}, "production UI: Focus exact target context forwarded")
	assert_eq(capture.backup, {"revision": 13, "token": 103}, "production UI: Backup exact request gate forwarded")
	assert_eq(hud._environment_snapshot.context_revision, 11, "production UI: Environment press is intent-only")
	assert_eq(hud._focus_snapshot.context_revision, 12, "production UI: Focus press is intent-only")
	assert_eq(hud._backup_snapshot.request_context_revision, 13, "production UI: Backup press is intent-only")


func test_part_a_runtime_stays_isolated_after_release_seams_are_removed() -> void:
	var game_source: String = FileAccess.get_file_as_string("res://scripts/run/game_run.gd")
	assert_false(game_source.contains("enable_wp05_prototype_mode"), "isolation: release composition has no prototype enable seam")
	assert_false(game_source.contains("prototype_visual_freeze"), "isolation: release composition has no visual freeze seam")
	assert_false(game_source.contains("request_rally"), "isolation: release composition has no Rally request path")
	var catalogue: WP05PrototypeCatalogue = load(
		"res://data/interventions/prototypes/wp05_prototype_catalogue.tres"
	) as WP05PrototypeCatalogue
	assert_true(catalogue != null, "isolation: Part A evidence catalogue remains loadable")
	assert_eq(catalogue.validation_errors(), PackedStringArray(), "isolation: Part A evidence still validates")
	for action_id: StringName in catalogue.get_stable_action_ids():
		assert_true(action_id.begins_with("wp05_proto_"), "isolation: evidence identity cannot masquerade as release content")
	var hud: GameHUD = _new_hud()
	hud.present_flow_snapshot(_travel_flow_snapshot())
	assert_false(hud.backup_button.visible, "isolation: combat Backup hides during travel")
	assert_false(hud.focus_placeholder_button.visible, "isolation: combat Focus hides during travel")
	assert_false(hud.interventions_panel.visible, "isolation: combat Environment hides during travel")
	assert_true(hud.subway_reroute_button.visible, "isolation: Subway remains strategic travel vocabulary")


func _new_hud() -> GameHUD:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = DESIGN_SIZE
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(viewport)
	var hud: GameHUD = HUD_SCENE.instantiate() as GameHUD
	viewport.add_child(hud)
	return hud


func _hud_source() -> String:
	return FileAccess.get_file_as_string("res://scripts/ui/game_hud.gd")


func _combat_flow_snapshot() -> Dictionary:
	return {
		"run": {
			"state": RunDirector.RunState.ENCOUNTER_ACTIVE,
			"run_elapsed_seconds": 150.0,
			"heat": 45,
			"heat_tier": 2,
			"night_pressure": 24.0,
			"boss_threshold": 50.0,
			"next_major_threshold": 36.0,
			"reward_multiplier": 1.1,
		},
		"patrol": {"route_index": 2, "route_progress": 0.5, "route_node_type": &"encounter"},
		"encounter": {"active_encounter_name": "Ranged Pressure", "remaining_to_spawn": 0},
		"cooling": {"subway_charges": 2, "subway_heat_reduction": 15},
		"rewards": {"coin_total": 120, "scrap_total": 4, "streak_count": 0},
		"environment": {
			"action_id": &"power_box",
			"display_name": "Power Box",
			"verb": "BREAKER",
			"icon": POWER_ICON,
			"description": "Interrupt and Shock enemies in the marked area.",
			"context_revision": 11,
			"request_token": 101,
			"validity_reason": &"ok",
			"can_activate": true,
			"target_count": 2,
			"cooldown_remaining": 0.0,
			"cooldown_duration": 12.0,
		},
		"focus": {
			"context_revision": 12,
			"request_token": 102,
			"validity_reason": &"ok",
			"can_activate": true,
			"cooldown_remaining": 0.0,
			"active_remaining": 0.0,
			"target_instance_id": 7001,
			"target_name": "Bottle Thrower",
			"attack_id": &"bottle_throw",
			"attack_name": "Readable Bottle Throw",
			"intent_label": "BOTTLE THROW",
			"window_seconds": 0.52,
		},
		"backup": {
			"request_context_revision": 13,
			"request_token": 103,
			"can_activate": true,
			"validity_reason": &"ok",
			"charges_remaining": 2,
			"active_ally_count": 0,
			"cooldown_remaining": 0.0,
		},
	}


func _travel_flow_snapshot() -> Dictionary:
	var snapshot: Dictionary = _combat_flow_snapshot()
	snapshot.run.state = RunDirector.RunState.PATROLLING
	snapshot.environment = {}
	snapshot.focus = {}
	snapshot.backup = {}
	return snapshot
