@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)


class InventoryIntentCapture:
	extends RefCounted

	var swap_count: int = 0
	var move_count: int = 0
	var discard_count: int = 0
	var equipment_slot: int = -1
	var backpack_slot: int = -1
	var replace_confirmed: bool = false
	var revision: int = -1

	func on_swap(active_slot: int, stored_slot: int, expected_revision: int) -> void:
		swap_count += 1
		equipment_slot = active_slot
		backpack_slot = stored_slot
		revision = expected_revision

	func on_move(
		active_slot: int,
		stored_slot: int,
		confirmed: bool,
		expected_revision: int
	) -> void:
		move_count += 1
		equipment_slot = active_slot
		backpack_slot = stored_slot
		replace_confirmed = confirmed
		revision = expected_revision

	func on_discard(
		_area: StringName,
		_slot: int,
		_equipment_id: StringName,
		_expected_revision: int
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
		_encounter_instance_id: int,
		_choice_token: int,
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


func suite_name() -> String:
	return "milestone_4_2_inventory_drag"


func test_one_backpack_uses_unambiguous_three_slot_language() -> void:
	var system: SynergySystem = _new_system()
	var hud: GameHUD = _new_hud_for_management(system)
	_expect_contains(hud.backpack_title_label.text, "BACKPACK", "terminology: one backpack")
	_expect_contains(hud.backpack_title_label.text, "0/3 STORED", "terminology: exact storage count")
	_expect_contains(hud.backpack_title_label.text, "INACTIVE", "terminology: stored state")
	var backpack_buttons: Array[EquipmentDragSlot] = [
		hud.backpack_inventory_01,
		hud.backpack_inventory_02,
		hud.backpack_inventory_03,
	]
	for slot_index: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
		var button: EquipmentDragSlot = backpack_buttons[slot_index]
		_expect_contains(button.text, "SLOT %d" % (slot_index + 1), "terminology: storage cell is a slot")
		_expect_false(button.text.contains("PACK %d" % (slot_index + 1)), "terminology: no fake pack number")
	var help_text: String = str((hud.get_node("Root/HelpPanel/InterventionHelp") as Label).text)
	_expect_contains(help_text, "3 EQUIPPED + 3 STORED", "terminology: six-position ownership is explicit")
	var auto_help_text: String = str((hud.get_node("Root/HelpPanel/AutoHelp") as Label).text)
	_expect_contains(auto_help_text, "CLICKS ONLY INSPECT", "terminology: clicks and drags are distinct")
	var scene_source: String = FileAccess.get_file_as_string("res://scenes/ui/game_hud.tscn")
	for forbidden: String in ["PACK 1", "PACK 2", "PACK 3", "STORE PACK"]:
		_expect_false(scene_source.contains(forbidden), "terminology: scene excludes '%s'" % forbidden)


func test_longest_dynamic_inventory_copy_fits_authored_controls() -> void:
	var full_system: SynergySystem = _new_full_system()
	var full_hud: GameHUD = _new_hud_for_management(full_system)
	var choices: Array[EquipmentDefinition] = [
		full_system.get_catalogue_item(&"magnetic_flail")
	]
	full_hud.present_equipment_reward(423, choices, _previews_for(full_system, choices))
	var active_targets: Array[EquipmentDragSlot] = [
		full_hud.reward_target_01,
		full_hud.reward_target_02,
		full_hud.reward_target_03,
	]
	var backpack_targets: Array[EquipmentDragSlot] = [
		full_hud.reward_store_01,
		full_hud.reward_store_02,
		full_hud.reward_store_03,
	]
	for slot_index: int in range(SynergySystem.SLOT_COUNT):
		_expect_control_copy_fits(
			active_targets[slot_index],
			"dynamic fit: active reward target %d" % (slot_index + 1)
		)
		_expect_control_copy_fits(
			backpack_targets[slot_index],
			"dynamic fit: backpack reward target %d" % (slot_index + 1)
		)
	full_hud.dismiss_equipment_reward()
	full_hud.equipped_inventory_03.pressed.emit()
	_expect_control_copy_fits(full_hud.inventory_action_prompt, "dynamic fit: item selected")
	for button: Button in [
		full_hud.inventory_action_01,
		full_hud.inventory_action_02,
		full_hud.inventory_action_03,
	]:
		_expect_control_copy_fits(button, "dynamic fit: backpack action target")
	full_hud.backpack_inventory_01.pressed.emit()
	_expect_control_copy_fits(full_hud.inventory_action_prompt, "dynamic fit: occupied swap")
	full_hud.inventory_cancel_button.pressed.emit()
	full_hud.backpack_inventory_01.pressed.emit()
	for button: Button in [
		full_hud.inventory_action_01,
		full_hud.inventory_action_02,
		full_hud.inventory_action_03,
	]:
		_expect_control_copy_fits(button, "dynamic fit: active action target")
	full_hud.inventory_cancel_button.pressed.emit()
	full_hud.equipped_inventory_03.pressed.emit()
	full_hud.inventory_discard_button.pressed.emit()
	_expect_control_copy_fits(full_hud.inventory_action_prompt, "dynamic fit: named discard")
	var drag_payload: EquipmentDragPayload = (
		full_hud.equipped_inventory_03.get_configured_drag_payload()
	)
	full_hud._on_equipment_drag_started(drag_payload)
	_expect_control_copy_fits(full_hud.inventory_action_prompt, "dynamic fit: drag guidance")

	var empty_backpack_system: SynergySystem = _new_system()
	_expect_true(
		empty_backpack_system.equip_by_id(&"reinforced_jacket", 0),
		"dynamic fit: active setup"
	)
	var empty_backpack_hud: GameHUD = _new_hud_for_management(empty_backpack_system)
	empty_backpack_hud.backpack_inventory_03._drop_data(
		Vector2.ZERO,
		empty_backpack_hud.equipped_inventory_01.get_configured_drag_payload()
	)
	_expect_control_copy_fits(
		empty_backpack_hud.inventory_action_prompt,
		"dynamic fit: store in empty backpack"
	)

	var empty_active_system: SynergySystem = _new_system()
	_expect_true(
		empty_active_system.store(
			empty_active_system.get_catalogue_item(&"reinforced_jacket"),
			2
		),
		"dynamic fit: backpack setup"
	)
	var empty_active_hud: GameHUD = _new_hud_for_management(empty_active_system)
	empty_active_hud.equipped_inventory_03._drop_data(
		Vector2.ZERO,
		empty_active_hud.backpack_inventory_03.get_configured_drag_payload()
	)
	_expect_control_copy_fits(
		empty_active_hud.inventory_action_prompt,
		"dynamic fit: equip into empty active slot"
	)


func test_pointer_threshold_fallback_starts_native_drag_without_mutation() -> void:
	var system: SynergySystem = _new_system()
	var hud: GameHUD = _new_hud_for_management(system)
	var choices: Array[EquipmentDefinition] = [
		system.get_catalogue_item(&"magnetic_flail")
	]
	hud.present_equipment_reward(424, choices, _previews_for(system, choices))
	var source: EquipmentDragSlot = hud.reward_choice_01
	var payload: EquipmentDragPayload = source.get_configured_drag_payload()
	var drag_starts: Array[EquipmentDragPayload] = []
	source.equipment_drag_started.connect(
		func(started_payload: EquipmentDragPayload) -> void:
			drag_starts.append(started_payload)
	)
	var revision: int = system.get_inventory_revision()
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(100.0, 100.0)
	source._gui_input(down)
	var near_motion: InputEventMouseMotion = InputEventMouseMotion.new()
	near_motion.position = Vector2(104.0, 100.0)
	near_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	source._gui_input(near_motion)
	_expect_equal(
		source.get_viewport().gui_get_drag_data(),
		null,
		"pointer fallback: sub-threshold motion remains an ordinary click candidate"
	)
	var drag_motion: InputEventMouseMotion = InputEventMouseMotion.new()
	drag_motion.position = Vector2(116.0, 100.0)
	drag_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	source._gui_input(drag_motion)
	_expect_equal(
		source.get_viewport().gui_get_drag_data(),
		payload,
		"pointer fallback: threshold begins the native viewport drag"
	)
	_expect_true(hud.reward_target_01.visible, "pointer fallback: drag reveals active targets")
	_expect_true(hud.reward_store_01.visible, "pointer fallback: drag reveals backpack targets")
	_expect_equal(drag_starts.size(), 1, "pointer fallback: drag start emits exactly once")
	source._gui_input(drag_motion)
	_expect_equal(drag_starts.size(), 1, "pointer fallback: later motion does not emit twice")
	_expect_equal(
		system.get_inventory_revision(),
		revision,
		"pointer fallback: beginning a drag never mutates inventory"
	)
	_expect_equal(
		hud.get_selected_reward_choice(),
		-1,
		"pointer fallback: drag start does not apply click selection"
	)
	_expect_contains(
		hud.reward_instruction_label.text,
		"DRAGGING MAGNETIC FLAIL",
		"pointer fallback: drag guidance is visible"
	)


func test_touch_threshold_preserves_first_pointer_and_starts_native_drag() -> void:
	var system: SynergySystem = _new_system()
	var hud: GameHUD = _new_hud_for_management(system)
	var choices: Array[EquipmentDefinition] = [
		system.get_catalogue_item(&"voltaic_blade")
	]
	hud.present_equipment_reward(425, choices, _previews_for(system, choices))
	var source: EquipmentDragSlot = hud.reward_choice_01
	var payload: EquipmentDragPayload = source.get_configured_drag_payload()
	var drag_starts: Array[EquipmentDragPayload] = []
	source.equipment_drag_started.connect(
		func(started_payload: EquipmentDragPayload) -> void:
			drag_starts.append(started_payload)
	)
	var revision: int = system.get_inventory_revision()
	var first_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	first_touch.index = 3
	first_touch.pressed = true
	first_touch.position = Vector2(80.0, 80.0)
	source._gui_input(first_touch)
	var second_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	second_touch.index = 4
	second_touch.pressed = true
	second_touch.position = Vector2(90.0, 90.0)
	source._gui_input(second_touch)
	var wrong_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	wrong_drag.index = 4
	wrong_drag.position = Vector2(120.0, 90.0)
	source._gui_input(wrong_drag)
	_expect_equal(
		source.get_viewport().gui_get_drag_data(),
		null,
		"touch fallback: second pointer cannot steal the armed drag"
	)
	var first_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	first_drag.index = 3
	first_drag.position = Vector2(100.0, 80.0)
	source._gui_input(first_drag)
	_expect_equal(
		source.get_viewport().gui_get_drag_data(),
		payload,
		"touch fallback: first pointer starts the native viewport drag"
	)
	_expect_equal(drag_starts.size(), 1, "touch fallback: drag start emits exactly once")
	_expect_equal(
		system.get_inventory_revision(),
		revision,
		"touch fallback: beginning a drag never mutates inventory"
	)
	_expect_equal(
		hud.get_selected_reward_choice(),
		-1,
		"touch fallback: drag start does not apply click selection"
	)


func test_inventory_drag_payload_and_cross_area_targets_are_typed_and_complete() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "payload: active setup")
	var hud: GameHUD = _new_hud_for_management(system)
	var source: EquipmentDragSlot = hud.equipped_inventory_01
	var payload: EquipmentDragPayload = source.get_configured_drag_payload()
	_expect_true(source.is_drag_source_enabled(), "payload: eligible item is draggable")
	_expect_true(payload != null and payload.is_valid(), "payload: typed payload is valid")
	_expect_equal(payload.equipment_id, &"spiked_bat", "payload: stable ID")
	_expect_equal(payload.source_area, SynergySystem.AREA_EQUIPPED, "payload: source area")
	_expect_equal(payload.source_slot, 0, "payload: source position")
	_expect_equal(payload.inventory_revision, system.get_inventory_revision(), "payload: captured revision")
	_expect_true(hud.backpack_inventory_03.accepts_drag_payload(payload), "payload: third backpack slot accepts")
	_expect_false(hud.equipped_inventory_02.accepts_drag_payload(payload), "payload: same-area target rejects")
	_expect_false(hud.reward_target_01.accepts_drag_payload(payload), "payload: reward target rejects inventory kind")
	_expect_false(hud.backpack_inventory_03.disabled, "payload: empty third destination remains pointer-reachable")


func test_combat_locks_drag_but_preserves_click_inspection() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "combat lock: active setup")
	var hud: GameHUD = _new_hud_for_management(system)
	hud.build_details_panel.visible = true
	hud.present_flow_snapshot({"run": {"state": RunDirector.RunState.ENCOUNTER_ACTIVE}})
	_expect_false(hud.equipped_inventory_01.is_drag_source_enabled(), "combat lock: drag source disabled")
	_expect_false(hud.backpack_inventory_03.is_drop_target_enabled(), "combat lock: drop target disabled")
	var revision: int = system.get_inventory_revision()
	hud.equipped_inventory_01.pressed.emit()
	_expect_equal(system.get_inventory_revision(), revision, "combat lock: click remains non-mutating")
	_expect_contains(hud.equipment_details_label.text, "SPIKED BAT", "combat lock: click still inspects")
	_expect_contains(hud.inventory_action_prompt.text, "INSPECTION ONLY", "combat lock: phase is explained")


func test_active_drag_to_empty_backpack_slot_three_stages_one_safe_move() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "empty drop: active setup")
	var hud: GameHUD = _new_hud_for_management(system)
	var capture: InventoryIntentCapture = _capture_inventory(hud)
	var payload: EquipmentDragPayload = hud.equipped_inventory_01.get_configured_drag_payload()
	hud.backpack_inventory_03._drop_data(Vector2.ZERO, payload)
	_expect_equal(hud.get_pending_inventory_action(), &"move_to_backpack", "empty drop: safe move staged")
	_expect_equal(hud.get_pending_inventory_target(), 2, "empty drop: third slot staged")
	_expect_equal(capture.move_count, 0, "empty drop: no authority intent before Confirm")
	_expect_contains(hud.inventory_action_prompt.text, "NO ITEM WILL BE LOST", "empty drop: lossless consequence")
	hud.inventory_confirm_button.pressed.emit()
	hud.inventory_confirm_button.pressed.emit()
	_expect_equal(capture.move_count, 1, "empty drop: repeated Confirm forwards once")
	_expect_equal(capture.swap_count, 0, "empty drop: does not swap")
	_expect_equal(capture.discard_count, 0, "empty drop: never discards")
	_expect_equal(capture.equipment_slot, 0, "empty drop: exact active source")
	_expect_equal(capture.backpack_slot, 2, "empty drop: exact third destination")
	_expect_false(capture.replace_confirmed, "empty drop: no replacement flag")


func test_active_drag_to_occupied_backpack_stages_lossless_swap_not_replacement() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "occupied drop: active setup")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 2), "occupied drop: stored setup")
	var hud: GameHUD = _new_hud_for_management(system)
	var capture: InventoryIntentCapture = _capture_inventory(hud)
	var payload: EquipmentDragPayload = hud.equipped_inventory_01.get_configured_drag_payload()
	hud.backpack_inventory_03._drop_data(Vector2.ZERO, payload)
	_expect_equal(hud.get_pending_inventory_action(), &"swap", "occupied drop: atomic swap staged")
	_expect_contains(hud.inventory_action_prompt.text, "KEEP BOTH", "occupied drop: lossless copy")
	hud.inventory_confirm_button.pressed.emit()
	_expect_equal(capture.swap_count, 1, "occupied drop: one swap intent")
	_expect_equal(capture.move_count, 0, "occupied drop: destructive move path unused")
	_expect_equal(capture.discard_count, 0, "occupied drop: discard path unused")
	_expect_equal(capture.equipment_slot, 0, "occupied drop: active index")
	_expect_equal(capture.backpack_slot, 2, "occupied drop: backpack index")


func test_backpack_drag_to_occupied_active_stages_lossless_swap() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "equip drop: active setup")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 2), "equip drop: stored setup")
	var hud: GameHUD = _new_hud_for_management(system)
	var capture: InventoryIntentCapture = _capture_inventory(hud)
	var payload: EquipmentDragPayload = hud.backpack_inventory_03.get_configured_drag_payload()
	hud.equipped_inventory_01._drop_data(Vector2.ZERO, payload)
	_expect_equal(hud.get_pending_inventory_action(), &"swap", "equip drop: swap staged")
	_expect_contains(hud.inventory_action_prompt.text, "SPIKED BAT", "equip drop: outgoing item named")
	hud.inventory_confirm_button.pressed.emit()
	_expect_equal(capture.swap_count, 1, "equip drop: one swap intent")
	_expect_equal(capture.equipment_slot, 0, "equip drop: exact active target")
	_expect_equal(capture.backpack_slot, 2, "equip drop: exact backpack source")
	_expect_equal(capture.discard_count, 0, "equip drop: no discard intent")


func test_reward_drag_to_active_stages_preview_and_applies_only_after_confirm() -> void:
	var system: SynergySystem = _new_system()
	var hud: GameHUD = _new_hud_for_management(system)
	var item: EquipmentDefinition = system.get_catalogue_item(&"voltaic_blade")
	var choices: Array[EquipmentDefinition] = [item]
	hud.present_equipment_reward(420, choices, _previews_for(system, choices))
	var capture: AcquisitionIntentCapture = AcquisitionIntentCapture.new()
	hud.equipment_acquisition_requested.connect(capture.on_acquisition)
	_expect_false(hud.reward_target_03.disabled, "reward drag: destination reachable before click selection")
	var payload: EquipmentDragPayload = hud.reward_choice_01.get_configured_drag_payload()
	hud.reward_target_03._drop_data(Vector2.ZERO, payload)
	_expect_equal(hud.get_selected_reward_choice(), 0, "reward drag: choice staged")
	_expect_equal(hud.get_selected_reward_destination(), SynergySystem.AREA_EQUIPPED, "reward drag: active destination")
	_expect_equal(hud.get_selected_reward_slot(), 2, "reward drag: third active slot")
	_expect_equal(capture.count, 0, "reward drag: drop does not mutate")
	_expect_contains(hud.reward_instruction_label.text, "REVIEW THE RESULT", "reward drag: staged state is explicit")
	hud.reward_confirm_button.pressed.emit()
	hud.reward_confirm_button.pressed.emit()
	_expect_equal(capture.count, 1, "reward drag: Confirm forwards exactly once")
	_expect_equal(capture.equipment_slot, 2, "reward drag: exact active slot forwarded")
	_expect_equal(capture.backpack_slot, -1, "reward drag: no storage displacement")


func test_reward_drag_to_backpack_slot_three_uses_all_three_storage_destinations() -> void:
	var system: SynergySystem = _new_system()
	var hud: GameHUD = _new_hud_for_management(system)
	var choices: Array[EquipmentDefinition] = [system.get_catalogue_item(&"magnetic_flail")]
	hud.present_equipment_reward(421, choices, _previews_for(system, choices))
	var capture: AcquisitionIntentCapture = AcquisitionIntentCapture.new()
	hud.equipment_acquisition_requested.connect(capture.on_acquisition)
	hud.reward_choice_01.pressed.emit()
	hud.reward_store_03.pressed.emit()
	_expect_equal(hud.get_selected_reward_backpack_slot(), 2, "reward store: click fallback reaches third slot")
	hud.reward_cancel_button.pressed.emit()
	var payload: EquipmentDragPayload = hud.reward_choice_01.get_configured_drag_payload()
	hud.reward_store_03._drop_data(Vector2.ZERO, payload)
	_expect_equal(hud.get_selected_reward_destination(), SynergySystem.AREA_BACKPACK, "reward store: backpack destination")
	_expect_equal(hud.get_selected_reward_backpack_slot(), 2, "reward store: third slot staged")
	_expect_contains(hud.reward_confirmation_label.text, "BACKPACK SLOT 3", "reward store: third slot named")
	hud.reward_confirm_button.pressed.emit()
	_expect_equal(capture.count, 1, "reward store: one intent")
	_expect_equal(capture.destination, SynergySystem.AREA_BACKPACK, "reward store: destination forwarded")
	_expect_equal(capture.backpack_slot, 2, "reward store: third slot forwarded")
	_expect_false(capture.replace_confirmed, "reward store: empty slot is non-destructive")


func test_full_inventory_drag_requires_named_slot_three_discard_or_skip() -> void:
	var system: SynergySystem = _new_full_system()
	var hud: GameHUD = _new_hud_for_management(system)
	var choices: Array[EquipmentDefinition] = [system.get_catalogue_item(&"magnetic_flail")]
	hud.present_equipment_reward(422, choices, _previews_for(system, choices))
	_expect_contains(hud.reward_confirmation_label.text, "INVENTORY FULL", "full drag: capacity explained")
	_expect_contains(hud.reward_confirmation_label.text, "SKIP GEAR", "full drag: safe skip is prominent")
	_expect_contains(hud.reward_keep_current_button.text, "KEEP RUN REWARD", "full drag: ordinary reward is preserved")
	var capture: AcquisitionIntentCapture = AcquisitionIntentCapture.new()
	hud.equipment_acquisition_requested.connect(capture.on_acquisition)
	var payload: EquipmentDragPayload = hud.reward_choice_01.get_configured_drag_payload()
	hud.reward_target_01._drop_data(Vector2.ZERO, payload)
	_expect_true(hud.reward_pack_target_label.visible, "full drag: exact stored consequence requested")
	_expect_true(hud.reward_confirm_button.disabled, "full drag: cannot confirm before leave-behind")
	hud.reward_pack_target_03.pressed.emit()
	_expect_false(hud.reward_confirm_button.disabled, "full drag: third leave-behind completes review")
	_expect_contains(hud.reward_confirmation_label.text, "SHOCK GLOVES", "full drag: exact third stored item named")
	hud.reward_confirm_button.pressed.emit()
	_expect_equal(capture.count, 1, "full drag: one acquisition intent")
	_expect_equal(capture.backpack_slot, 2, "full drag: third stored position forwarded")
	_expect_true(capture.replace_confirmed, "full drag: named destructive consequence explicit")


func test_stale_and_same_area_drops_emit_no_inventory_mutation_intent() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "invalid drop: active setup")
	var hud: GameHUD = _new_hud_for_management(system)
	var capture: InventoryIntentCapture = _capture_inventory(hud)
	var stale_payload: EquipmentDragPayload = hud.equipped_inventory_01.get_configured_drag_payload()
	_expect_false(hud.equipped_inventory_02.accepts_drag_payload(stale_payload), "invalid drop: same area rejected")
	hud.equipped_inventory_02._drop_data(Vector2.ZERO, stale_payload)
	_expect_equal(capture.swap_count + capture.move_count + capture.discard_count, 0, "invalid drop: same-area emits nothing")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 0), "invalid drop: authority revision changes")
	hud.present_build_snapshot(system.get_snapshot())
	hud.backpack_inventory_02._drop_data(Vector2.ZERO, stale_payload)
	_expect_equal(capture.swap_count + capture.move_count + capture.discard_count, 0, "invalid drop: stale emits nothing")
	_expect_contains(
		hud.inventory_action_prompt.text,
		"STALE DROP REJECTED",
		"invalid drop: stale feedback (actual: %s)" % hud.inventory_action_prompt.text
	)


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


func _new_hud_for_management(system: SynergySystem) -> GameHUD:
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
	hud.present_flow_snapshot({"run": {"state": RunDirector.RunState.PATROLLING}})
	hud.present_build_snapshot(system.get_snapshot())
	return hud


func _capture_inventory(hud: GameHUD) -> InventoryIntentCapture:
	var capture: InventoryIntentCapture = InventoryIntentCapture.new()
	hud.inventory_swap_requested.connect(capture.on_swap)
	hud.inventory_move_requested.connect(capture.on_move)
	hud.inventory_discard_requested.connect(capture.on_discard)
	return capture


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


func _expect_contains(actual: String, expected: String, context: String) -> void:
	assert_contains(actual, expected, context)


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])


func _expect_control_copy_fits(control: Control, context: String) -> void:
	var text_value: String = str(control.get("text"))
	var font: Font = control.get_theme_font("font")
	var font_size: int = control.get_theme_font_size("font_size")
	var maximum_line_width: float = 0.0
	var lines: PackedStringArray = text_value.split("\n")
	for line: String in lines:
		maximum_line_width = maxf(
			maximum_line_width,
			font.get_string_size(
				line,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				font_size
			).x
		)
	var required_height: float = font.get_height(font_size) * float(lines.size())
	var available_width: float = control.size.x - 16.0
	_expect_true(
		maximum_line_width <= available_width and required_height <= control.size.y,
		(
			"%s (required %.1fx%.1f, available %.1fx%.1f, text: %s)"
			% [
				context,
				maximum_line_width,
				required_height,
				available_width,
				control.size.y,
				text_value.replace("\n", " / "),
			]
		)
	)
