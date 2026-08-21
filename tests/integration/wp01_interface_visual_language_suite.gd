@tool
extends McpTestSuite

const DESIGN_SIZE: Vector2i = Vector2i(1280, 720)
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/vertical_slice_overlay.tscn")
const GALLERY_SCENE: PackedScene = preload("res://scenes/ui/wp01_state_gallery.tscn")


class IntentCapture:
	extends RefCounted

	var primary_count: int = 0
	var cooling_count: int = 0
	var extraction_count: int = 0
	var backup_count: int = 0

	func on_primary() -> void:
		primary_count += 1

	func on_cooling() -> void:
		cooling_count += 1

	func on_extraction() -> void:
		extraction_count += 1

	func on_backup() -> void:
		backup_count += 1


func suite_name() -> String:
	return "wp01_interface_visual_language"


func test_tokens_define_complete_accessible_visual_language() -> void:
	assert_eq(NeonUiTokens.FONT_CAPTION, 16, "tokens: caption remains readable")
	assert_eq(NeonUiTokens.FONT_BODY, 18, "tokens: body hierarchy")
	assert_eq(NeonUiTokens.FONT_HEADING, 26, "tokens: heading hierarchy")
	assert_eq(NeonUiTokens.SPACE_1, 4, "tokens: base spacing")
	assert_eq(NeonUiTokens.SPACE_6, 32, "tokens: largest spacing")
	assert_eq(NeonUiTokens.TOUCH_TARGET_MINIMUM, 48.0, "tokens: touch minimum")
	assert_gt(NeonUiTokens.MOTION_STANDARD, 0.0, "tokens: animation duration is explicit")
	var theme: Theme = NeonUiTokens.create_theme()
	assert_true(theme.has_stylebox(&"focus", &"Button"), "tokens: visible keyboard focus style")
	assert_true(theme.has_stylebox(&"disabled", &"Button"), "tokens: explicit disabled style")
	for variation: StringName in [
		&"SurfacePanel", &"DecisionPanel", &"ChoiceCardSelected",
		&"InterventionReady", &"InterventionCooling", &"InterventionUnavailable",
	]:
		assert_true(theme.get_type_variation_base(variation) != &"", "tokens: variation %s exists" % variation)


func test_reusable_components_encode_non_colour_state_and_tooltips() -> void:
	var viewport: SubViewport = _new_viewport()
	var choice: NeonChoiceCard = NeonChoiceCard.new()
	choice.text = "QUIET STREETS"
	choice.tooltip_text = "Exact consequence preview"
	viewport.add_child(choice)
	choice.set_visual_state(NeonChoiceCard.VisualState.SELECTED, "SELECTED")
	assert_true(choice.button_pressed, "choice: selected state has pressed shape")
	assert_eq(choice.theme_type_variation, &"ChoiceCardSelected", "choice: selected token")
	assert_contains(choice.tooltip_text, "SELECTED", "choice: selected cue is textual")
	var intervention: NeonInterventionButton = NeonInterventionButton.new()
	viewport.add_child(intervention)
	intervention.present("2", "BACKUP", "COOLDOWN 8s", NeonInterventionButton.VisualState.COOLING)
	assert_contains(intervention.text, "COOLDOWN", "intervention: cooldown is textual")
	assert_eq(intervention.theme_type_variation, &"InterventionCooling", "intervention: cooldown token")
	var comparison: NeonStatComparison = NeonStatComparison.new()
	viewport.add_child(comparison)
	comparison.present("HEAT PREVIEW", "58", "43", "NIGHT PRESSURE UNCHANGED", true)
	assert_contains(comparison.get_comparison_text(), "58", "comparison: before value")
	assert_contains(comparison.get_comparison_text(), "43", "comparison: after value")


func test_icon_family_is_replaceable_and_complete() -> void:
	for icon_path: String in [
		"res://assets/ui/icons/wp01/health.svg",
		"res://assets/ui/icons/wp01/heat.svg",
		"res://assets/ui/icons/wp01/pressure.svg",
		"res://assets/ui/icons/wp01/coins.svg",
		"res://assets/ui/icons/wp01/environment.svg",
		"res://assets/ui/icons/wp01/focus.svg",
		"res://assets/ui/icons/wp01/backup.svg",
		"res://assets/ui/icons/wp01/phase_plan.svg",
		"res://assets/ui/icons/wp01/phase_fight.svg",
		"res://assets/ui/icons/wp01/phase_reward.svg",
		"res://assets/ui/icons/wp01/phase_shop.svg",
		"res://assets/ui/icons/wp01/phase_extract.svg",
		"res://assets/ui/icons/wp01/phase_result.svg",
		"res://assets/ui/icons/wp01/knockback.svg",
		"res://assets/ui/icons/wp01/bleed.svg",
		"res://assets/ui/icons/wp01/tech.svg",
	]:
		assert_true(ResourceLoader.exists(icon_path, "Texture2D"), "icons: loadable %s" % icon_path)


func test_combat_hud_is_minimal_phase_led_and_keeps_current_authority_paths() -> void:
	var hud: GameHUD = _new_hud()
	hud.help_button.pressed.emit()
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.ENCOUNTER_ACTIVE))
	assert_eq(hud.phase_banner.get_phase_text(), "FIGHT", "combat: phase is first-order")
	assert_contains(hud.phase_banner.get_next_event_text(), "ENEMY ARRIVAL", "combat: next event named")
	assert_false(hud.minimap_panel.visible, "combat: legacy route wall is progressively disclosed")
	assert_false(hud.primary_action_button.visible, "combat: automatic-status action is removed from action strip")
	assert_true(hud.backup_button.visible, "combat: Backup remains present")
	assert_true(hud.focus_placeholder_button.visible, "combat: Focus vocabulary has compatible shell")
	assert_true(hud.focus_placeholder_button.disabled, "combat: absent Focus authority is visibly disabled")
	assert_false(hud.subway_reroute_button.visible, "combat: strategic travel action is not combat clutter")
	assert_true(hud.hydrant_button is NeonInterventionButton, "combat: Environment uses shared intervention component")
	assert_true(hud.backup_button is NeonInterventionButton, "combat: Backup uses shared intervention component")
	assert_true(hud.has_node("Root/CardsPanel/BackupButton"), "combat: legacy node path remains present")


func test_shop_and_extract_shells_forward_existing_typed_intents_only() -> void:
	var hud: GameHUD = _new_hud()
	var capture: IntentCapture = IntentCapture.new()
	hud.primary_action_requested.connect(capture.on_primary)
	hud.shop_cooling_requested.connect(capture.on_cooling)
	hud.extraction_requested.connect(capture.on_extraction)
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.SHOP))
	assert_true(hud.shop_decision_panel.visible, "shop: focused shell visible")
	assert_contains(hud.shop_cooling_choice.text, "HEAT 58 -> 43", "shop: exact Heat preview")
	assert_contains(hud.shop_comparison.get_comparison_text(), "HEAT 58", "shop: stat comparison before")
	hud.shop_cooling_choice.pressed.emit()
	hud.shop_leave_choice.pressed.emit()
	assert_eq(capture.cooling_count, 1, "shop: purchase forwards one existing intent")
	assert_eq(capture.primary_count, 1, "shop: leave forwards one existing intent")
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.EXTRACTION_AVAILABLE))
	assert_true(hud.extraction_panel.visible, "extract: focused shell visible")
	assert_contains(hud.extraction_button.text, "SECURE CURRENT RESULT", "extract: secure consequence")
	assert_contains(hud.extraction_continue_button.text, "NIGHT PRESSURE CONTINUES", "push: irreversible consequence")
	hud.extraction_button.pressed.emit()
	hud.extraction_continue_button.pressed.emit()
	assert_eq(capture.extraction_count, 1, "extract: forwards one existing extraction intent")
	assert_eq(capture.primary_count, 2, "push: forwards one existing continuation intent")


func test_safe_area_keeps_edge_critical_controls_inside_supported_bounds() -> void:
	var hud: GameHUD = _new_hud()
	var safe_area: Rect2i = Rect2i(32, 24, 1216, 672)
	hud.apply_safe_area(safe_area, DESIGN_SIZE)
	var safe_bounds: Rect2 = Rect2(safe_area)
	for control: Control in [
		hud.phase_banner,
		hud.resources_panel,
		hud.crew_panel,
		hud.build_panel,
		hud.cards_panel,
		hud.interventions_panel,
		hud.help_button,
		hud.fullscreen_button,
	]:
		assert_true(safe_bounds.encloses(control.get_global_rect()), "safe area: contains %s" % control.name)


func test_overlay_pause_settings_summary_have_focus_and_progressive_hierarchy() -> void:
	var overlay: VerticalSliceOverlay = _new_overlay()
	overlay.show_pause({})
	assert_true(overlay.resume_button.has_focus(), "pause: primary action receives keyboard focus")
	overlay.pause_settings_button.pressed.emit()
	assert_true(overlay.master_slider.has_focus(), "settings: first control receives keyboard focus")
	assert_true(overlay.master_slider.custom_minimum_size.y >= NeonUiTokens.TOUCH_TARGET_MINIMUM, "settings: touch target")
	var summary: RunSummaryRecord = RunSummaryRecord.new()
	summary.result_label = "Victory"
	summary.duration_seconds = 582.0
	summary.equipment_build = "SPiked Bat / Reinforced Jacket / Shock Gloves"
	summary.active_synergies = "KNOCKBACK 2 / TECH 2"
	summary.highest_combo = 30
	summary.elites_defeated = 1
	summary.coins_collected = 286
	overlay.present_run_summary(summary)
	assert_contains(overlay.summary_highlight.text, "BUILD EXPRESSION", "summary: build expression before detail wall")
	assert_contains(overlay.summary_highlight.text, "HIGHLIGHT", "summary: decisive highlight")
	assert_true(overlay.replay_button.has_focus(), "summary: replay receives keyboard focus")


func test_long_names_remain_bounded_in_compact_hud() -> void:
	var hud: GameHUD = _new_hud()
	hud.present_crew_status(
		"ALEXANDRIA MAXIMILIAN NIGHTSHADE",
		399.0,
		520.0,
		&"ATTACK_RECOVERY",
		"VIPER ENFORCER WITH AN EXTREMELY LONG TARGET LABEL"
	)
	hud.present_build_snapshot({
		"inventory_revision": 9,
		"slots": [
			{"id": &"one", "display_name": "Electromagnetic Reinforced Impact Distributor"},
			{"id": &"two", "display_name": "Extraordinarily Serrated Technical Wraps"},
			{"id": &"three", "display_name": "Metropolitan Shockwave Amplification Gloves"},
		],
		"backpack_slots": [{}, {}, {}],
		"active_synergies": [],
		"synergy_progress": [],
	})
	assert_true((hud.get_node("Root/CrewPanel/CrewName") as Label).clip_text, "long copy: crew name clips inside its field")
	for slot: LinkButton in [hud.build_slot_01, hud.build_slot_02, hud.build_slot_03]:
		assert_eq(slot.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS, "long copy: build slot uses ellipsis")
		assert_true(hud.build_panel.get_global_rect().encloses(slot.get_global_rect()), "long copy: slot contained")


func test_representative_state_matrix_is_native_contained_and_nonmodal_gameplay_is_clear() -> void:
	var gallery: Wp01StateGallery = _new_gallery()
	for state_name: String in [
		"combat", "plan", "reward", "shop", "extract", "pause", "settings", "summary",
	]:
		gallery.present_state(state_name)
		assert_eq(gallery.representative_state, state_name, "matrix: selected %s" % state_name)
		for child: Node in gallery.get_children():
			if not child is Control or not (child as Control).visible:
				continue
			assert_true(
				Rect2(Vector2.ZERO, Vector2(DESIGN_SIZE)).encloses((child as Control).get_global_rect()),
				"matrix: %s contains %s" % [state_name, child.name]
			)
	gallery.present_state("combat")
	assert_true(gallery.has_node("CrewMarker"), "combat matrix: fight relationship visible")
	assert_true(gallery.has_node("ActionStrip"), "combat matrix: intervention strip visible")


func test_hud_presentation_does_not_consume_gameplay_random_streams() -> void:
	var streams: RunRandomStreams = RunRandomStreams.new()
	track(streams)
	streams.reset_for_seed(82941)
	var before: Dictionary = streams.get_debug_snapshot()
	var hud: GameHUD = _new_hud()
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.PATROLLING))
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.ENCOUNTER_ACTIVE))
	hud.present_backup_state({
		"active_allies": 0,
		"charges_remaining": 2,
		"cooldown_remaining": 0.0,
		"can_activate": true,
		"validity_text": "READY",
	})
	assert_eq(streams.get_debug_snapshot(), before, "presentation: no deterministic stream draw or mutation")


func _new_viewport() -> SubViewport:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = DESIGN_SIZE
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(viewport)
	return viewport


func _new_hud() -> GameHUD:
	var viewport: SubViewport = _new_viewport()
	var hud: GameHUD = HUD_SCENE.instantiate() as GameHUD
	viewport.add_child(hud)
	return hud


func _new_overlay() -> VerticalSliceOverlay:
	var viewport: SubViewport = _new_viewport()
	var overlay: VerticalSliceOverlay = OVERLAY_SCENE.instantiate() as VerticalSliceOverlay
	viewport.add_child(overlay)
	return overlay


func _new_gallery() -> Wp01StateGallery:
	var viewport: SubViewport = _new_viewport()
	var gallery: Wp01StateGallery = GALLERY_SCENE.instantiate() as Wp01StateGallery
	viewport.add_child(gallery)
	return gallery


func _flow_snapshot(state: int) -> Dictionary:
	return {
		"run": {
			"state": state,
			"run_elapsed_seconds": 145.0,
			"heat": 58,
			"heat_tier": 2,
			"night_pressure": 31.5,
			"boss_threshold": 50.0,
			"next_major_threshold": 36.0,
			"reward_multiplier": 1.35,
			"boss_intro_remaining": 2.0,
		},
		"patrol": {
			"route_index": 3,
			"route_progress": 0.62,
			"route_node_type": &"encounter",
			"route_revision": 4,
			"loop_count": 1,
		},
		"encounter": {
			"active_encounter_name": "Viper Enforcer",
			"remaining_to_spawn": 2,
			"spawn_delay_remaining": 2.4,
		},
		"cooling": {
			"subway_charges": 2,
			"subway_heat_reduction": 15,
			"shop_purchases_remaining": 1,
			"shop_coin_cost": 60,
			"shop_heat_reduction": 15,
		},
		"rewards": {
			"coin_total": 126,
			"scrap_total": 8,
			"streak_count": 3,
		},
	}
