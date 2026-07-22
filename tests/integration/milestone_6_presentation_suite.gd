@tool
extends McpTestSuite

const DESIGN_SIZE: Vector2i = Vector2i(1280, 720)
const MINIMUM_FONT_SIZE: int = 16
const CARD_CATALOGUE: DistrictCardCatalogue = preload(
	"res://data/cards/milestone_5_district_card_catalogue.tres"
)


class IntentCapture:
	extends RefCounted

	var crew_id: StringName = &""
	var settings: Dictionary = {}
	var backup_count: int = 0

	func on_start(selected_crew_id: StringName) -> void:
		crew_id = selected_crew_id

	func on_settings(new_settings: Dictionary) -> void:
		settings = new_settings.duplicate(true)

	func on_backup() -> void:
		backup_count += 1


func suite_name() -> String:
	return "milestone_6_presentation"


func test_overlay_crew_selection_rejects_locked_and_forwards_unlocked_intent() -> void:
	var overlay: VerticalSliceOverlay = _new_overlay()
	var capture: IntentCapture = IntentCapture.new()
	overlay.start_run_requested.connect(capture.on_start)
	overlay.show_main_menu([
		_crew_entry(&"jax", "Jax", "Brawler", true),
		_crew_entry(&"zoey", "Zoey", "Tech Fighter", false),
		_crew_entry(&"rex", "Rex", "Bruiser", true),
	], "TEST PROFILE")
	_expect_equal(overlay.get_selected_crew_id(), &"jax", "crew: first unlocked stable ID selected")
	_expect_true(overlay.zoey_button.disabled, "crew: locked Zoey is textually and mechanically disabled")
	overlay.zoey_button.pressed.emit()
	_expect_equal(overlay.get_selected_crew_id(), &"jax", "crew: locked request cannot replace selection")
	overlay.rex_button.pressed.emit()
	_expect_equal(overlay.get_selected_crew_id(), &"rex", "crew: unlocked Rex becomes selected")
	overlay.start_button.pressed.emit()
	_expect_equal(capture.crew_id, &"rex", "crew: exact selected stable ID forwarded once")
	_expect_contains(overlay.crew_details.text, "NO PERMANENT STAT", "crew: profile gives no permanent stat bonus")


func test_settings_controls_clamp_present_and_forward_every_required_option() -> void:
	var overlay: VerticalSliceOverlay = _new_overlay()
	var capture: IntentCapture = IntentCapture.new()
	overlay.settings_apply_requested.connect(capture.on_settings)
	overlay.present_settings({
		"master_volume": 2.0,
		"music_volume": -1.0,
		"sound_effects_volume": 0.65,
		"fullscreen": true,
		"screen_shake_intensity": 0.35,
		"damage_numbers_enabled": false,
		"hit_flash_reduction": 0.75,
		"pause_on_focus_loss": false,
	})
	_expect_equal(float(overlay.master_slider.value), 1.0, "settings: master clamps")
	_expect_equal(float(overlay.music_slider.value), 0.0, "settings: music clamps")
	_expect_equal(float(overlay.sfx_slider.value), 0.65, "settings: SFX presents")
	_expect_equal(overlay.display_mode.selected, 1, "settings: fullscreen presents")
	_expect_equal(float(overlay.shake_slider.value), 0.35, "settings: shake presents")
	_expect_false(overlay.damage_numbers_toggle.button_pressed, "settings: damage-number toggle presents")
	_expect_equal(float(overlay.hit_flash_slider.value), 0.75, "settings: hit-flash reduction presents")
	_expect_false(overlay.focus_pause_toggle.button_pressed, "settings: focus-pause presents")
	overlay.settings_apply_button.pressed.emit()
	for required_key: String in [
		"master_volume", "music_volume", "sound_effects_volume", "fullscreen",
		"screen_shake_intensity", "damage_numbers_enabled", "hit_flash_reduction",
		"pause_on_focus_loss",
	]:
		_expect_true(capture.settings.has(required_key), "settings: forwards %s" % required_key)
	_expect_contains(overlay.settings_status.text, "SAVING", "settings: UI waits for authority acknowledgement")
	overlay.present_settings_status("SETTINGS SAVED - GAMEPLAY AUTHORITY UNCHANGED")
	_expect_contains(overlay.settings_status.text, "SAVED", "settings: authority can publish success")


func test_complete_summary_boss_telegraph_tutorial_and_combo_use_textual_cues() -> void:
	var overlay: VerticalSliceOverlay = _new_overlay()
	var summary: RunSummaryRecord = RunSummaryRecord.new()
	summary.result_label = "VICTORY"
	summary.duration_seconds = 601.0
	summary.run_seed = 6606
	summary.random_schema_version = 1
	summary.maximum_heat = 88
	summary.final_night_pressure = 54.5
	summary.enemies_defeated = 27
	summary.elites_defeated = 2
	summary.boss_result = "DEFEATED"
	summary.coins_collected = 820
	summary.manual_clusters_collected = 7
	summary.maximum_manual_streak = 4
	summary.scrap_secured = 9
	summary.highest_combo = 18
	summary.equipment_build = "SHOCK GLOVES / HACKER DECK / VOLTAIC BLADE"
	summary.active_synergies = "TECH 2"
	overlay.present_run_summary(summary)
	var summary_text: String = "%s\n%s\n%s" % [
		overlay.summary_title.text,
		overlay.summary_left.text,
		overlay.summary_right.text,
	]
	for required_text: String in [
		"VICTORY", "10:01", "6606", "MAX HEAT", "NIGHT PRESSURE", "ENEMIES",
		"ELITES", "BOSS RESULT", "COINS", "MANUAL CLUSTERS", "MAX STREAK",
		"SCRAP", "HIGHEST COMBO", "EQUIPMENT BUILD", "ACTIVE SYNERGIES",
	]:
		_expect_contains(summary_text, required_text, "summary: %s" % required_text)
	_expect_true(overlay.replay_button.visible, "summary: replay same seed")
	_expect_true(overlay.restart_button.visible, "summary: restart run")
	_expect_true(overlay.summary_main_menu_button.visible, "summary: return main menu")

	overlay.summary_panel.visible = false
	overlay.present_boss("The Viper", 720, 1800, "Enraged", "AREA ATTACK • MOVE OUT")
	_expect_true(overlay.boss_panel.visible, "boss: dedicated health panel")
	_expect_equal(int(overlay.boss_health.value), 720, "boss: exact current health")
	_expect_contains(overlay.boss_title.text, "ENRAGED", "boss: phase has text cue")
	_expect_contains(overlay.boss_status.text, "AREA ATTACK", "boss: telegraph has text cue")
	overlay.present_tutorial(&"intervention_backup", "PRESS 2 • CALL TWO ALLIES FOR 12 SECONDS")
	_expect_true(overlay.tutorial_panel.visible, "tutorial: contextual strip visible")
	_expect_contains(overlay.tutorial_label.text, "PRESS 2", "tutorial: input is explained")
	overlay.present_combo(6, 13)
	_expect_contains(overlay.combo_label.text, "COMBO 6", "combo: current count textual")
	_expect_contains(overlay.combo_label.text, "BEST 13", "combo: highest count textual")


func test_overlay_and_extended_hud_are_native_contained_and_readable() -> void:
	var overlay: VerticalSliceOverlay = _new_overlay()
	var font_failures: Array[String] = []
	_collect_font_failures(overlay.get_node("Root"), font_failures)
	_expect_true(font_failures.is_empty(), "layout: overlay typography >= 16px\n%s" % "\n".join(font_failures))
	for panel_path: String in [
		"Root/MainMenu/MenuPanel",
		"Root/PauseMenu/PausePanel",
		"Root/SettingsPanel/Panel",
		"Root/SummaryPanel/Panel",
		"Root/BossPanel",
		"Root/TutorialPanel",
		"Root/ComboPanel",
	]:
		var panel: Control = overlay.get_node(panel_path) as Control
		var failures: Array[String] = []
		_collect_direct_containment_failures(panel, failures)
		_expect_true(failures.is_empty(), "layout: %s children contained\n%s" % [panel_path, "\n".join(failures)])

	var hud: GameHUD = _new_hud()
	var backup: Button = hud.get_node("Root/CardsPanel/BackupButton") as Button
	var subway: Button = hud.get_node("Root/CardsPanel/Card02") as Button
	var hydrant: Button = hud.get_node("Root/InterventionsPanel/HydrantButton") as Button
	_expect_true(backup.icon != null, "interventions: Backup has replaceable icon")
	_expect_true(subway.icon != null, "interventions: Subway has replaceable icon")
	_expect_true(hydrant.icon != null, "interventions: Hydrant has replaceable icon")
	_expect_contains(backup.tooltip_text, "12", "interventions: Backup tooltip explains duration")
	_expect_contains(subway.tooltip_text, "Night Pressure", "interventions: Subway tooltip explains irreversible pressure")
	var capture: IntentCapture = IntentCapture.new()
	hud.backup_activation_requested.connect(capture.on_backup)
	backup.pressed.emit()
	_expect_equal(capture.backup_count, 1, "interventions: Backup forwards exactly one typed intent")
	hud.present_backup_state({
		"active_allies": 0,
		"charges_remaining": 1,
		"cooldown_remaining": 0.0,
		"can_activate": false,
		"validity_text": "NO ACTIVE ENEMY",
	})
	_expect_contains(backup.text, "NO ACTIVE ENEMY", "interventions: invalidity does not depend on colour")


func test_intervention_action_copy_is_ascii_and_pixel_fits_every_dynamic_state() -> void:
	var hud: GameHUD = _new_hud()
	var backup: Button = hud.backup_button
	var subway: Button = hud.subway_reroute_button
	var hydrant: Button = hud.hydrant_button
	var hydrant_title: Label = hud.get_node("Root/InterventionsPanel/Title") as Label
	var backup_states: Array[Dictionary] = [
		{
			"active_ally_count": 2,
			"active_duration_remaining": 12.0,
			"charges_remaining": 1,
			"cooldown_remaining": 30.0,
			"can_activate": false,
			"validity_reason": &"already_active",
		},
		{
			"active_ally_count": 0,
			"charges_remaining": 1,
			"cooldown_remaining": 30.0,
			"can_activate": false,
			"validity_reason": &"cooldown",
		},
		{
			"active_ally_count": 0,
			"charges_remaining": 2,
			"cooldown_remaining": 0.0,
			"can_activate": true,
			"validity_reason": &"ok",
		},
		{
			"active_ally_count": 0,
			"charges_remaining": 0,
			"cooldown_remaining": 0.0,
			"can_activate": false,
			"validity_reason": &"no_charges",
		},
	]
	for state: Dictionary in backup_states:
		hud.present_backup_state(state)
		_expect_ascii(backup.text, "copy: Backup action is Web-safe ASCII")
		_expect_control_copy_fits(backup, "copy: Backup dynamic action fits")
	hud.present_flow_snapshot({
		"run": {"state": RunDirector.RunState.PATROLLING},
		"cooling": {"subway_charges": 2, "subway_heat_reduction": 15},
		"rewards": {},
	})
	for control: Control in [subway, hydrant, hydrant_title]:
		_expect_ascii(str(control.get("text")), "copy: intervention label is Web-safe ASCII")
		_expect_control_copy_fits(control, "copy: intervention label fits")


func test_overlay_and_hud_remain_contained_at_1080p_and_1440p() -> void:
	for viewport_size: Vector2i in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		var overlay: VerticalSliceOverlay = _new_overlay_at(viewport_size)
		var overlay_root: Control = overlay.get_node("Root") as Control
		_expect_equal(
			Vector2i(overlay_root.size),
			viewport_size,
			"resolution: overlay root fills %s" % viewport_size
		)
		for panel_path: String in [
			"Root/MainMenu/MenuPanel",
			"Root/PauseMenu/PausePanel",
			"Root/SettingsPanel/Panel",
			"Root/SummaryPanel/Panel",
		]:
			var panel: Control = overlay.get_node(panel_path) as Control
			_expect_true(
				Rect2(Vector2.ZERO, overlay_root.size).encloses(Rect2(panel.global_position, panel.size)),
				"resolution: %s contained at %s" % [panel_path, viewport_size]
			)
		var hud: GameHUD = _new_hud_at(viewport_size)
		var hud_root: Control = hud.get_node("Root") as Control
		_expect_equal(Vector2i(hud_root.size), DESIGN_SIZE, "resolution: HUD preserves 1280x720 design canvas")
		_expect_true(
			Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(Rect2(hud_root.position, hud_root.size)),
			"resolution: HUD design canvas is contained at %s" % viewport_size
		)


func test_long_summary_wraps_without_clipping() -> void:
	var overlay: VerticalSliceOverlay = _new_overlay()
	var summary: RunSummaryRecord = RunSummaryRecord.new()
	summary.result_label = "VICTORY"
	summary.equipment_build = (
		"SLOT 1 MAGNETIC FLAIL / SLOT 2 REINFORCED JACKET / SLOT 3 VOLTAIC BLADE"
	)
	summary.active_synergies = "KNOCKBACK 2 / BLEED 2 / TECH 2"
	overlay.present_run_summary(summary)
	_expect_true(overlay.summary_right.autowrap_mode != TextServer.AUTOWRAP_OFF, "summary: wrapping enabled")
	_expect_false(overlay.summary_right.clip_text, "summary: glyph clipping disabled")
	var line_count: int = overlay.summary_right.get_line_count()
	var summary_font: Font = overlay.summary_right.get_theme_font("font")
	var summary_font_size: int = overlay.summary_right.get_theme_font_size("font_size")
	var required_height: float = (
		summary_font.get_height(summary_font_size) * float(line_count)
		+ float(maxi(line_count - 1, 0))
		* float(overlay.summary_right.get_theme_constant("line_spacing"))
	)
	_expect_true(
		line_count > 0 and required_height <= overlay.summary_right.size.y,
		"summary: every wrapped line pixel-fits (required %.1f, available %.1f)" % [
			required_height,
			overlay.summary_right.size.y,
		]
	)


func test_screen_shake_setting_is_presentation_only_deterministic_and_resettable() -> void:
	var root: Node2D = track(Node2D.new()) as Node2D
	var camera: Camera2D = Camera2D.new()
	camera.name = "Camera2D"
	root.add_child(camera)
	var shake: ScreenShakeController = ScreenShakeController.new()
	shake.camera_path = NodePath("../Camera2D")
	root.add_child(shake)
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		scene_tree.root.add_child(root)
	shake.set_intensity(0.5)
	_expect_true(shake.request_heavy_hit(), "shake: accepted at nonzero setting")
	shake.step_presentation(0.017)
	var first_offset: Vector2 = camera.offset
	_expect_true(first_offset != Vector2.ZERO, "shake: moves only camera presentation")
	shake.reset_presentation()
	_expect_equal(camera.offset, Vector2.ZERO, "shake: reset restores authored camera offset")
	shake.request_heavy_hit()
	shake.step_presentation(0.017)
	_expect_equal(camera.offset, first_offset, "shake: repeated input sequence is deterministic")
	shake.reset_presentation()
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams._ready()
	streams.reset_for_seed(6611)
	var random_before: Dictionary = streams.get_debug_snapshot()
	shake.request_environmental_hit()
	shake.step_presentation(0.031)
	_expect_equal(streams.get_debug_snapshot(), random_before, "shake: consumes no gameplay random stream")
	shake.reset_presentation()
	shake.set_intensity(0.0)
	_expect_false(shake.request_boss_hit(), "shake: zero setting suppresses impulse")
	_expect_equal(camera.offset, Vector2.ZERO, "shake: disabled remains stable")


func test_profile_access_filters_latch_without_changing_catalogue_or_random_schema() -> void:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams._ready()
	streams.reset_for_seed(6610)
	var patrol: PatrolController = track(PatrolController.new()) as PatrolController
	patrol._ready()
	var cards: CardSystem = track(CardSystem.new()) as CardSystem
	cards.catalogue = CARD_CATALOGUE
	cards.configure(streams, patrol)
	cards.configure_run_access([&"arcade", &"convenience_store", &"subway_entrance"])
	_expect_true(cards.reset_for_run(), "access: filtered three-card deck initializes")
	_expect_equal(cards.get_active_access_ids(), [&"arcade", &"convenience_store", &"subway_entrance"], "access: sorted card IDs latch")
	_expect_equal(cards.get_hand().size(), 2, "access: opening hand contract retained")
	_expect_equal(cards.get_draw_pile().size(), 1, "access: one gated-run card remains")
	_expect_equal(CARD_CATALOGUE.cards.size(), 4, "access: canonical four-card catalogue unchanged")
	_expect_equal(streams.get_random_schema_version(), 1, "access: random schema unchanged")


func _new_overlay() -> VerticalSliceOverlay:
	return _new_overlay_at(DESIGN_SIZE)


func _new_overlay_at(viewport_size: Vector2i) -> VerticalSliceOverlay:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = viewport_size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var scene: PackedScene = load("res://scenes/ui/vertical_slice_overlay.tscn") as PackedScene
	var overlay: VerticalSliceOverlay = scene.instantiate() as VerticalSliceOverlay
	viewport.add_child(overlay)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(viewport)
	return overlay


func _new_hud() -> GameHUD:
	return _new_hud_at(DESIGN_SIZE)


func _new_hud_at(viewport_size: Vector2i) -> GameHUD:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = viewport_size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var scene: PackedScene = load("res://scenes/ui/game_hud.tscn") as PackedScene
	var hud: GameHUD = scene.instantiate() as GameHUD
	viewport.add_child(hud)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(viewport)
	return hud


func _crew_entry(
	id: StringName,
	display_name: String,
	archetype: String,
	unlocked: bool
) -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"archetype": archetype,
		"unlocked": unlocked,
		"summary": "DISTINCT AUTHORED COMBAT PROFILE",
		"trait_text": "NO PERMANENT STAT BONUS",
		"unlock_hint": "LOCKED • COMPLETE THE AUTHORED RUN CONDITION",
	}


func _collect_font_failures(node: Node, failures: Array[String]) -> void:
	if node is Label or node is Button or node is OptionButton or node is CheckButton:
		var control: Control = node as Control
		var size: int = control.get_theme_font_size("font_size")
		if size < MINIMUM_FONT_SIZE:
			failures.append("%s = %d" % [String(control.get_path()), size])
	for child: Node in node.get_children():
		_collect_font_failures(child, failures)


func _collect_direct_containment_failures(panel: Control, failures: Array[String]) -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO, panel.size)
	for child: Node in panel.get_children():
		if not child is Control:
			continue
		var control: Control = child as Control
		if not control.visible:
			continue
		var child_rect: Rect2 = Rect2(control.position, control.size)
		if not bounds.encloses(child_rect):
			failures.append("%s outside %s" % [String(control.get_path()), str(bounds)])


func _expect_ascii(text: String, context: String) -> void:
	var ascii_only: bool = true
	for codepoint: int in text.to_utf32_buffer():
		if codepoint > 127:
			ascii_only = false
			break
	_expect_true(ascii_only, "%s (%s)" % [context, text.replace("\n", " / ")])


func _expect_control_copy_fits(control: Control, context: String) -> void:
	var text_value: String = str(control.get("text"))
	var font: Font = control.get_theme_font("font")
	var font_size: int = control.get_theme_font_size("font_size")
	var maximum_line_width: float = 0.0
	var lines: PackedStringArray = text_value.split("\n")
	for line: String in lines:
		maximum_line_width = maxf(
			maximum_line_width,
			font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		)
	var icon_width: float = 0.0
	if control is Button:
		var button: Button = control as Button
		if button.icon != null:
			icon_width = float(button.icon.get_width())
			var authored_max_width: Variant = button.get("icon_max_width")
			if authored_max_width != null and int(authored_max_width) > 0:
				icon_width = minf(icon_width, float(authored_max_width))
			else:
				icon_width = minf(icon_width, 32.0)
			icon_width += float(button.get_theme_constant("h_separation"))
	var required_height: float = font.get_height(font_size) * float(lines.size())
	var available_width: float = control.size.x - 16.0 - icon_width
	_expect_true(
		maximum_line_width <= available_width and required_height <= control.size.y,
		"%s (required %.1fx%.1f, available %.1fx%.1f, text: %s)" % [
			context,
			maximum_line_width,
			required_height,
			available_width,
			control.size.y,
			text_value.replace("\n", " / "),
		]
	)


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)


func _expect_contains(actual: String, expected_fragment: String, context: String) -> void:
	assert_true(expected_fragment in actual, "%s (expected '%s' in '%s')" % [context, expected_fragment, actual])
