@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const MINIMUM_BODY_FONT_SIZE: int = 16


class InventoryIntentCapture:
	extends RefCounted

	var swap_count: int = 0
	var move_count: int = 0
	var discard_count: int = 0

	func on_swap(_active_slot: int, _backpack_slot: int, _revision: int) -> void:
		swap_count += 1

	func on_move(
		_active_slot: int,
		_backpack_slot: int,
		_confirmed: bool,
		_revision: int
	) -> void:
		move_count += 1

	func on_discard(
		_area: StringName,
		_slot: int,
		_equipment_id: StringName,
		_revision: int
	) -> void:
		discard_count += 1


class AcquisitionIntentCapture:
	extends RefCounted

	var count: int = 0
	var choice_index: int = -1
	var destination: StringName = &""
	var equipment_slot: int = -1
	var backpack_slot: int = -1
	var replace_confirmed: bool = false
	var revision: int = -1

	func on_acquisition(
		new_choice_index: int,
		new_destination: StringName,
		new_equipment_slot: int,
		new_backpack_slot: int,
		new_replace_confirmed: bool,
		new_revision: int
	) -> void:
		count += 1
		choice_index = new_choice_index
		destination = new_destination
		equipment_slot = new_equipment_slot
		backpack_slot = new_backpack_slot
		replace_confirmed = new_replace_confirmed
		revision = new_revision


class DeclineIntentCapture:
	extends RefCounted

	var count: int = 0

	func on_decline() -> void:
		count += 1


func suite_name() -> String:
	return "milestone_4_1_inventory_ui"


func test_equipped_slot_click_only_inspects_and_emits_no_mutation_intent() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "safe inspect: active item setup")
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	var capture: InventoryIntentCapture = InventoryIntentCapture.new()
	hud.inventory_swap_requested.connect(capture.on_swap)
	hud.inventory_move_requested.connect(capture.on_move)
	hud.inventory_discard_requested.connect(capture.on_discard)
	var revision: int = system.get_inventory_revision()
	hud.build_slot_01.pressed.emit()
	_expect_equal(
		hud.build_details_panel.get_index(),
		hud.build_details_panel.get_parent().get_child_count() - 1,
		"safe inspect: management modal is topmost for pointer input"
	)
	_expect_equal(capture.swap_count, 0, "safe inspect: no swap intent")
	_expect_equal(capture.move_count, 0, "safe inspect: no move intent")
	_expect_equal(capture.discard_count, 0, "safe inspect: no discard intent")
	_expect_equal(system.get_inventory_revision(), revision, "safe inspect: authority remains unchanged")
	_expect_equal(system.get_equipped_item(0).id, &"spiked_bat", "safe inspect: item remains equipped")
	_expect_true(hud.build_details_panel.visible, "safe inspect: details open")
	_expect_contains(hud.equipment_details_label.text, "SPIKED BAT", "safe inspect: selected item is named")
	_expect_contains(
		hud.equipment_details_label.text,
		"POWERING CURRENT BUILD",
		"safe inspect: UI confirms the selected item remains active"
	)


func test_full_loadout_has_no_preselected_active_replacement() -> void:
	var system: SynergySystem = _new_full_system()
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	var choices: Array[EquipmentDefinition] = [system.get_catalogue_item(&"magnetic_flail")]
	hud.present_equipment_reward(41, choices, _previews_for(system, choices))
	_expect_equal(hud.get_selected_reward_slot(), -1, "full loadout: modal opens without replacement target")
	_expect_equal(hud.get_selected_reward_choice(), -1, "full loadout: modal opens without item selection")
	hud.reward_choice_01.pressed.emit()
	_expect_equal(hud.get_selected_reward_choice(), 0, "full loadout: ordinary click selects only the item")
	_expect_equal(hud.get_selected_reward_slot(), -1, "full loadout: item selection does not pick oldest active slot")
	_expect_true(hud.reward_confirm_button.disabled, "full loadout: confirmation unavailable without destination")


func test_full_loadout_requires_choice_destination_named_eviction_and_confirm() -> void:
	var system: SynergySystem = _new_full_system()
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	var choices: Array[EquipmentDefinition] = [system.get_catalogue_item(&"magnetic_flail")]
	hud.present_equipment_reward(42, choices, _previews_for(system, choices))
	_expect_equal(
		hud.equipment_reward_panel.get_index(),
		hud.equipment_reward_panel.get_parent().get_child_count() - 1,
		"two stage: reward modal is topmost for pointer input"
	)
	var capture: AcquisitionIntentCapture = AcquisitionIntentCapture.new()
	hud.equipment_acquisition_requested.connect(capture.on_acquisition)
	hud.reward_choice_01.pressed.emit()
	_expect_equal(capture.count, 0, "two stage: selecting item emits no acquisition")
	hud.reward_target_01.pressed.emit()
	_expect_equal(capture.count, 0, "two stage: selecting active destination emits no acquisition")
	_expect_true(hud.reward_pack_target_label.visible, "two stage: full backpack requests exact leave-behind")
	_expect_true(hud.reward_confirm_button.disabled, "two stage: confirmation waits for exact stored item")
	hud.reward_pack_target_02.pressed.emit()
	_expect_false(hud.reward_confirm_button.disabled, "two stage: complete consequence choice enables confirmation")
	_expect_contains(hud.reward_confirmation_label.text, "SPIKED BAT", "two stage: outgoing active item is named")
	_expect_contains(hud.reward_confirmation_label.text, "SERRATED WRAPS", "two stage: leave-behind item is named")
	_expect_equal(capture.count, 0, "two stage: review still does not mutate")
	hud.reward_confirm_button.pressed.emit()
	hud.reward_confirm_button.pressed.emit()
	_expect_equal(capture.count, 1, "two stage: repeated confirm forwards exactly one intent")
	_expect_equal(capture.choice_index, 0, "two stage: chosen item index")
	_expect_equal(capture.destination, SynergySystem.AREA_EQUIPPED, "two stage: active destination")
	_expect_equal(capture.equipment_slot, 0, "two stage: exact active slot")
	_expect_equal(capture.backpack_slot, 1, "two stage: exact backpack slot")
	_expect_true(capture.replace_confirmed, "two stage: named eviction is explicit")
	_expect_equal(capture.revision, system.get_inventory_revision(), "two stage: current revision travels with intent")


func test_clear_selection_and_keep_current_are_safe_exactly_once_paths() -> void:
	var system: SynergySystem = _new_system()
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	var choices: Array[EquipmentDefinition] = [system.get_catalogue_item(&"voltaic_blade")]
	hud.present_equipment_reward(43, choices, _previews_for(system, choices))
	var acquisition: AcquisitionIntentCapture = AcquisitionIntentCapture.new()
	var decline: DeclineIntentCapture = DeclineIntentCapture.new()
	hud.equipment_acquisition_requested.connect(acquisition.on_acquisition)
	hud.equipment_reward_decline_requested.connect(decline.on_decline)
	hud.reward_choice_01.pressed.emit()
	hud.reward_store_01.pressed.emit()
	_expect_false(hud.reward_cancel_button.disabled, "safe alternatives: clear selection becomes available")
	hud.reward_cancel_button.pressed.emit()
	_expect_equal(hud.get_selected_reward_choice(), -1, "safe alternatives: clear returns to no item selection")
	_expect_equal(hud.get_selected_reward_slot(), -1, "safe alternatives: clear removes destination")
	_expect_equal(acquisition.count, 0, "safe alternatives: clear emits no acquisition")
	hud.reward_choice_01.pressed.emit()
	hud.reward_keep_current_button.pressed.emit()
	hud.reward_keep_current_button.pressed.emit()
	_expect_equal(decline.count, 1, "safe alternatives: keep-current forwards once")
	_expect_equal(acquisition.count, 0, "safe alternatives: keep-current never applies equipment")


func test_choice_overview_and_exact_destination_preview_are_visible() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "visible preview: active Bat setup")
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	var choices: Array[EquipmentDefinition] = [system.get_catalogue_item(&"voltaic_blade")]
	hud.present_equipment_reward(44, choices, _previews_for(system, choices))
	_expect_contains(
		hud.reward_choice_details_01.text,
		"CAN ACTIVATE: BLEED 2",
		"visible preview: overview shows possible immediate activation"
	)
	_expect_contains(
		hud.reward_choice_details_01.text,
		"CAN OPEN: TECH 1/2",
		"visible preview: overview shows alternative path progress"
	)
	hud.reward_choice_01.pressed.emit()
	hud.reward_target_02.pressed.emit()
	_expect_contains(
		hud.reward_choice_details_01.text,
		"NOW: +BLEED 2",
		"visible preview: exact active destination shows activation"
	)
	_expect_contains(
		hud.reward_choice_details_01.text,
		"OTHER PATH: TECH 1/2",
		"visible preview: exact destination retains alternative progress"
	)
	hud.reward_store_01.pressed.emit()
	_expect_contains(
		hud.reward_choice_details_01.text,
		"STORE: INACTIVE UNTIL EQUIPPED",
		"visible preview: stored destination is explicitly inactive"
	)


func test_phase_changes_clear_pending_inventory_actions_and_terminal_panels() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "phase safety: active Bat setup")
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	hud.present_flow_snapshot({"run": {"state": RunDirector.RunState.PATROLLING}})
	hud.build_slot_01.pressed.emit()
	hud.inventory_discard_button.pressed.emit()
	_expect_false(hud.inventory_confirm_button.disabled, "phase safety: discard can be reviewed")
	hud.present_flow_snapshot({"run": {"state": RunDirector.RunState.ENCOUNTER_ACTIVE}})
	_expect_true(hud.inventory_confirm_button.disabled, "phase safety: combat clears pending action")
	_expect_contains(
		hud.equipment_details_label.text,
		"SELECT AN ITEM TO INSPECT",
		"phase safety: stale selection is cleared"
	)
	hud.build_details_panel.visible = true
	hud.present_flow_snapshot({"run": {"state": RunDirector.RunState.RUN_SUMMARY}})
	_expect_false(hud.build_details_panel.visible, "phase safety: terminal summary stays unobscured")


func test_native_1280_layout_camera_and_pixel_filter_contract() -> void:
	_expect_equal(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		1280,
		"resolution: native viewport width"
	)
	_expect_equal(
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)),
		720,
		"resolution: native viewport height"
	)
	_expect_equal(
		str(ProjectSettings.get_setting("display/window/stretch/mode", "")),
		"viewport",
		"resolution: deterministic viewport stretch"
	)
	_expect_equal(
		str(ProjectSettings.get_setting("display/window/stretch/aspect", "")),
		"keep",
		"resolution: preserve 16:9"
	)
	_expect_equal(
		str(ProjectSettings.get_setting("display/window/stretch/scale_mode", "")),
		"integer",
		"resolution: integer scale mode"
	)
	_expect_equal(
		int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)),
		0,
		"resolution: nearest canvas texture filtering"
	)
	var game_scene: PackedScene = load("res://scenes/game/game_run.tscn") as PackedScene
	var game_run: Node = track(game_scene.instantiate()) as Node
	var camera: Camera2D = game_run.get_node("Camera2D") as Camera2D
	_expect_equal(camera.position, Vector2(320.0, 180.0), "resolution: world remains centered on 640 by 360 coordinates")
	_expect_equal(camera.zoom, Vector2(2.0, 2.0), "resolution: camera preserves established world framing")


func test_hud_minimum_font_panel_containment_and_journey_orientation() -> void:
	var hud: GameHUD = _new_hud()
	var root: Control = hud.get_node("Root") as Control
	var font_audit: Dictionary = _audit_minimum_fonts()
	var checked_fonts: int = int(font_audit.get("checked", 0))
	_expect_true(checked_fonts >= 40, "layout: broad text/control sample is covered")
	var font_failures: Array[String] = []
	font_failures.assign(font_audit.get("failures", []))
	_expect_true(
		font_failures.is_empty(),
		"layout: every text control uses at least %dpx authored type:\n%s"
		% [MINIMUM_BODY_FONT_SIZE, "\n".join(font_failures)]
	)
	var containment_failures: Array[String] = _collect_containment_failures(root)
	_expect_true(
		containment_failures.is_empty(),
		"layout: every root control and panel child stays within its border:\n%s"
		% "\n".join(containment_failures)
	)
	var journey_text: String = "%s\n%s" % [
		hud.route_label.text,
		str((hud.get_node("Root/HelpPanel/AutoHelp") as Label).text),
	]
	for required_text: String in ["HIDEOUT", "PATROL", "FIGHT", "GEAR", "EXIT/BOSS"]:
		_expect_contains(journey_text, required_text, "journey: %s is visible" % required_text)
	_expect_contains(journey_text, "CLICKS ONLY INSPECT", "journey: safe inventory orientation is visible")


func test_equipment_icons_and_synergy_badges_are_present_square_and_legible_size() -> void:
	for catalogue_item: EquipmentDefinition in EQUIPMENT_CATALOGUE.items:
		var item: EquipmentDefinition = ResourceLoader.load(
			"res://data/equipment/%s.tres" % catalogue_item.id,
			"EquipmentDefinition",
			ResourceLoader.CACHE_MODE_REPLACE
		) as EquipmentDefinition
		_expect_true(item != null, "icons: %s resource reloads" % catalogue_item.id)
		if item == null:
			continue
		_expect_true(item.icon != null, "icons: %s has a visual" % item.id)
		if item.icon == null:
			continue
		var icon_size: Vector2 = item.icon.get_size()
		_expect_equal(icon_size.x, icon_size.y, "icons: %s is square" % item.id)
		_expect_true(icon_size.x >= 64.0, "icons: %s has enough source resolution" % item.id)
	for catalogue_synergy: SynergyDefinition in SYNERGY_CATALOGUE.synergies:
		var synergy: SynergyDefinition = ResourceLoader.load(
			"res://data/synergies/%s.tres" % catalogue_synergy.id,
			"SynergyDefinition",
			ResourceLoader.CACHE_MODE_REPLACE
		) as SynergyDefinition
		_expect_true(synergy != null, "badges: %s resource reloads" % catalogue_synergy.id)
		if synergy == null:
			continue
		_expect_true(synergy.badge != null, "badges: %s has a visual" % synergy.id)
		if synergy.badge == null:
			continue
		var badge_size: Vector2 = synergy.badge.get_size()
		_expect_equal(badge_size.x, badge_size.y, "badges: %s is square" % synergy.id)
		_expect_true(badge_size.x >= 64.0, "badges: %s has enough source resolution" % synergy.id)


func _new_system() -> SynergySystem:
	var system: SynergySystem = track(SynergySystem.new()) as SynergySystem
	system.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	return system


func _new_full_system() -> SynergySystem:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"hacker_deck", 1)
	system.equip_by_id(&"reinforced_jacket", 2)
	system.store(system.get_catalogue_item(&"steel_toe_boots"), 0)
	system.store(system.get_catalogue_item(&"serrated_wraps"), 1)
	system.store(system.get_catalogue_item(&"shock_gloves"), 2)
	return system


func _new_hud() -> GameHUD:
	var test_viewport: SubViewport = track(SubViewport.new()) as SubViewport
	test_viewport.size = Vector2i(int(DESIGN_SIZE.x), int(DESIGN_SIZE.y))
	test_viewport.disable_3d = true
	test_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	test_viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var hud_scene: PackedScene = ResourceLoader.load(
		"res://scenes/ui/game_hud.tscn",
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE
	) as PackedScene
	var hud: GameHUD = hud_scene.instantiate() as GameHUD
	test_viewport.add_child(hud)
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree != null:
		scene_tree.root.add_child(test_viewport)
	return hud


func _previews_for(
	system: SynergySystem,
	choices: Array[EquipmentDefinition]
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: EquipmentDefinition in choices:
		var by_slot: Array[Dictionary] = []
		for slot_index: int in range(SynergySystem.SLOT_COUNT):
			by_slot.append(system.preview_equipment(item, slot_index))
		result.append({"by_slot": by_slot})
	return result


func _audit_minimum_fonts() -> Dictionary:
	var scene_source: String = FileAccess.get_file_as_string("res://scenes/ui/game_hud.tscn")
	var pattern: RegEx = RegEx.new()
	var compile_error: Error = pattern.compile(
		"theme_override_font_sizes/font_size = ([0-9]+)"
	)
	var failures: Array[String] = []
	if compile_error != OK:
		return {"checked": 0, "failures": ["font audit regular expression failed"]}
	var matches: Array[RegExMatch] = pattern.search_all(scene_source)
	for match_result: RegExMatch in matches:
		var authored_font_size: int = int(match_result.get_string(1))
		if authored_font_size < MINIMUM_BODY_FONT_SIZE:
			failures.append(
				"scene font override uses %dpx" % authored_font_size
			)
	return {"checked": matches.size(), "failures": failures}


func _collect_containment_failures(root: Control) -> Array[String]:
	var failures: Array[String] = []
	for child: Node in root.get_children():
		var control: Control = child as Control
		if control == null:
			continue
		_append_rect_failure(
			failures,
			control,
			Rect2(Vector2.ZERO, DESIGN_SIZE),
			"root child"
		)
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child: Node in node.get_children():
			pending.append(child)
		var panel: Panel = node as Panel
		if panel == null:
			continue
		var bounds: Rect2 = Rect2(Vector2.ZERO, panel.size)
		for child: Node in panel.get_children():
			var control: Control = child as Control
			if control != null:
				_append_rect_failure(
					failures,
					control,
					bounds,
					"%s child" % panel.get_path()
				)
	return failures


func _append_rect_failure(
	failures: Array[String],
	control: Control,
	bounds: Rect2,
	context: String
) -> void:
	var rect: Rect2 = Rect2(control.position, control.size)
	var inside: bool = (
		rect.position.x >= bounds.position.x - 0.01
		and rect.position.y >= bounds.position.y - 0.01
		and rect.end.x <= bounds.end.x + 0.01
		and rect.end.y <= bounds.end.y + 0.01
	)
	if not inside:
		failures.append(
			"%s: %s within %s, got %s" % [context, control.get_path(), bounds, rect]
		)


func _expect_contains(actual: String, expected: String, context: String) -> void:
	assert_contains(actual, expected, context)


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])
