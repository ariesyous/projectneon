@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const CARD_CATALOGUE: DistrictCardCatalogue = preload(
	"res://data/cards/milestone_5_district_card_catalogue.tres"
)
const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const MINIMUM_FONT_SIZE: int = 16
const HAND_REVISION: int = 11
const ROUTE_REVISION: int = 7


class PlacementIntentCapture:
	extends RefCounted

	var open_count: int = 0
	var close_count: int = 0
	var stage_count: int = 0
	var confirm_count: int = 0
	var cancel_count: int = 0
	var card_id: StringName = &""
	var slot_id: StringName = &""
	var hand_revision: int = -1
	var route_revision: int = -1
	var confirmation_token: int = -1
	var cancelled_token: int = -1

	func on_open() -> void:
		open_count += 1

	func on_close() -> void:
		close_count += 1

	func on_stage(
		new_card_id: StringName,
		new_slot_id: StringName,
		new_hand_revision: int,
		new_route_revision: int
	) -> void:
		stage_count += 1
		card_id = new_card_id
		slot_id = new_slot_id
		hand_revision = new_hand_revision
		route_revision = new_route_revision

	func on_confirm(token: int) -> void:
		confirm_count += 1
		confirmation_token = token

	func on_cancel(token: int) -> void:
		cancel_count += 1
		cancelled_token = token


class RewardIntentCapture:
	extends RefCounted

	var acquisition_count: int = 0
	var skip_count: int = 0
	var encounter_id: int = -1
	var choice_token: int = -1
	var choice_index: int = -1
	var hand_revision: int = -1

	func on_acquisition(
		new_encounter_id: int,
		new_choice_token: int,
		new_choice_index: int,
		new_hand_revision: int
	) -> void:
		acquisition_count += 1
		encounter_id = new_encounter_id
		choice_token = new_choice_token
		choice_index = new_choice_index
		hand_revision = new_hand_revision

	func on_skip(new_encounter_id: int, new_choice_token: int) -> void:
		skip_count += 1
		encounter_id = new_encounter_id
		choice_token = new_choice_token


func suite_name() -> String:
	return "milestone_5_card_ui"


func test_native_card_layout_is_contained_and_uses_readable_typography() -> void:
	_expect_equal(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		1280,
		"layout: native viewport width"
	)
	_expect_equal(
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)),
		720,
		"layout: native viewport height"
	)
	var hud: GameHUD = _new_hud()
	_open_planning(hud)
	_expect_true(hud.district_card_panel.visible, "layout: planning modal is visible")
	_expect_equal(
		hud.district_card_panel.get_index(),
		hud.district_card_panel.get_parent().get_child_count() - 1,
		"layout: modal is topmost for pointer input"
	)
	var compact_bounds: Rect2 = (hud.district_card_compact_panel.get_parent() as Control).get_global_rect()
	_expect_rect_inside(
		hud.district_card_compact_panel.get_global_rect(),
		compact_bounds,
		"layout: compact card status stays inside run-actions panel"
	)
	_expect_rect_inside(
		hud.district_card_panel.get_global_rect(),
		Rect2(Vector2.ZERO, DESIGN_SIZE),
		"layout: modal stays inside the native viewport"
	)
	var containment_failures: Array[String] = _collect_descendant_containment_failures(
		hud.district_card_panel
	)
	_expect_true(
		containment_failures.is_empty(),
		"layout: every modal control stays inside its border:\n%s"
		% "\n".join(containment_failures)
	)
	var font_audit: Dictionary = _audit_card_fonts(hud)
	_expect_true(int(font_audit.get("checked", 0)) >= 20, "layout: broad card typography audit")
	var font_failures: Array[String] = []
	font_failures.assign(font_audit.get("failures", []))
	_expect_true(
		font_failures.is_empty(),
		"layout: card UI uses at least 16px text:\n%s" % "\n".join(font_failures)
	)
	_expect_contains(hud.district_card_compact_summary.text, "H3/3", "layout: hand count")
	_expect_contains(hud.district_card_compact_summary.text, "D1", "layout: draw count")
	_expect_contains(hud.district_card_compact_summary.text, "X0", "layout: discard count")
	_expect_contains(hud.district_card_counts.text, "HAND 3/3", "layout: expanded hand count")
	_expect_contains(hud.district_card_counts.text, "DRAW 1", "layout: expanded draw count")
	_expect_contains(hud.district_card_counts.text, "DISC 0", "layout: expanded discard count")


func test_all_four_cards_show_free_heat_effect_tags_art_and_progression() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	_open_planning(hud)
	var expected_copy: Dictionary = {
		&"arcade": ["+10 HEAT", "ADD FIGHT", "FIGHT", "REWARD"],
		&"convenience_store": ["-10 HEAT", "ADD SHOP", "RECOVERY", "SHOP"],
		&"gang_hideout": ["+20 HEAT", "ADD SCALED ELITE", "ELITE", "EQUIPMENT"],
		&"subway_entrance": ["-15 HEAT", "REROUTE", "REROUTE", "SKIP"],
	}
	for card_id: StringName in DistrictCardCatalogue.REQUIRED_CARD_IDS:
		var card: DistrictCardDefinition = CARD_CATALOGUE.get_by_id(card_id)
		hud.present_district_cards(_cards_snapshot([card]), _patrol_snapshot())
		var details: String = hud.district_card_choice_details_01.text
		_expect_contains(details, card.display_name.to_upper(), "details: %s name" % card_id)
		_expect_contains(details, "FREE", "details: %s free cost" % card_id)
		for expected: String in expected_copy[card_id]:
			_expect_contains(details, expected, "details: %s copy '%s'" % [card_id, expected])
		_expect_contains(details, "IMPLICATION:", "details: %s progression heading" % card_id)
		_expect_equal(
			hud.district_card_choice_icon_01.texture,
			card.icon,
			"details: %s placeholder art" % card_id
		)
		_expect_contains(
			hud.district_card_choice_01.tooltip_text,
			card.effect_definition.summary,
			"details: %s full typed effect" % card_id
		)
		_expect_contains(
			hud.district_card_choice_01.tooltip_text,
			card.progression_implications,
			"details: %s full progression implication" % card_id
		)
		_expect_control_copy_fits(
			hud.district_card_choice_details_01,
			"details: %s card copy fits" % card_id
		)


func test_five_stable_slots_explain_valid_wrong_occupied_current_and_expired() -> void:
	var slots: Array[Dictionary] = [
		_route_slot(1, &"travel", &"valid"),
		_route_slot(2, &"encounter", &"valid"),
		_route_slot(3, &"travel", &"occupied", &"convenience_store"),
		_route_slot(4, &"travel", &"current"),
		_route_slot(5, &"travel", &"expired"),
	]
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")], slots)
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	hud.district_card_choice_01.pressed.emit()
	var buttons: Array[DistrictCardDragSlot] = _route_buttons(hud)
	var expected_labels: Array[String] = ["VALID", "WRONG TYPE", "OCCUPIED", "CURRENT", "EXPIRED"]
	var expected_feedback: Array[String] = [
		"VALID",
		"WRONG NODE TYPE",
		"OCCUPIED",
		"CURRENT",
		"EXPIRED",
	]
	for slot_index: int in range(buttons.size()):
		_expect_equal(
			buttons[slot_index].get_target_slot_id(),
			StringName(slots[slot_index].get("slot_id", &"")),
			"slots: stable target identity %d" % slot_index
		)
		_expect_contains(
			buttons[slot_index].text,
			expected_labels[slot_index],
			"slots: textual status %d" % slot_index
		)
		_expect_contains(buttons[slot_index].text, "OCC %d" % (slot_index + 1), "slots: position")
		_expect_contains(buttons[slot_index].text, "NODE", "slots: baseline node position/type")
	for invalid_index: int in [1, 2, 3, 4]:
		buttons[invalid_index].pressed.emit()
		_expect_contains(
			hud.district_card_feedback.text,
			expected_feedback[invalid_index],
			"slots: immediate rejection feedback %d" % invalid_index
		)
	_expect_equal(capture.stage_count, 0, "slots: invalid statuses emit no placement intent")
	buttons[0].pressed.emit()
	_expect_equal(capture.stage_count, 1, "slots: valid click stages one intent")


func test_pending_and_resolved_card_changes_update_minimap_and_route_preview() -> void:
	var cards: Dictionary = _cards_snapshot(_opening_hand())
	cards["pending_route_effects"] = [
		{
			"card_id": &"arcade",
			"card_name": "Arcade",
			"slot_id": &"downtown_loop::route_slot::3",
			"occurrence_index": 3,
		}
	]
	cards["resolved_route_effects"] = [
		{
			"card_id": &"subway_entrance",
			"card_name": "Subway Entrance",
			"slot_id": &"downtown_loop::route_slot::1",
			"occurrence_index": 1,
		}
	]
	var hud: GameHUD = _new_hud_from_snapshots(cards, _patrol_snapshot())
	_open_planning(hud)
	for journey_label: String in ["HIDEOUT", "PATROL", "FIGHT", "GEAR", "EXIT/BOSS"]:
		_expect_contains(hud.route_label.text, journey_label, "preview: preserved journey %s" % journey_label)
	_expect_contains(hud.route_label.text, "CARDS P:ARCA@4", "preview: minimap pending marker")
	_expect_contains(hud.route_label.text, "R:SUBW@2", "preview: minimap resolved marker")
	_expect_contains(hud.district_card_route_preview.text, "PENDING ARCADE@O4", "preview: pending route detail")
	_expect_contains(
		hud.district_card_route_preview.text,
		"RESOLVED SUBWAY ENTRANCE@O2",
		"preview: resolved route detail"
	)


func test_typed_native_drag_payload_and_revisioned_target_stage_only() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	var source: DistrictCardDragSlot = hud.district_card_choice_01
	var payload: DistrictCardDragPayload = source.get_configured_drag_payload()
	_expect_true(source.is_drag_source_enabled(), "drag: hand card is a native source")
	_expect_true(payload != null and payload.is_valid(), "drag: typed payload is valid")
	_expect_equal(payload.origin, DistrictCardDragPayload.Origin.HAND, "drag: hand origin")
	_expect_equal(payload.card_id, &"arcade", "drag: stable card ID")
	_expect_equal(payload.hand_revision, HAND_REVISION, "drag: hand revision captured")
	_expect_equal(payload.route_revision, ROUTE_REVISION, "drag: route revision captured")
	_expect_equal(payload.icon, CARD_CATALOGUE.get_by_id(&"arcade").icon, "drag: art travels in preview")
	var buttons: Array[DistrictCardDragSlot] = _route_buttons(hud)
	hud._on_district_card_drag_started(payload)
	_expect_true(buttons[0].accepts_drag_payload(payload), "drag: matching travel slot accepts")
	_expect_false(buttons[1].accepts_drag_payload(payload), "drag: encounter slot rejects Arcade")
	buttons[0]._drop_data(Vector2.ZERO, payload)
	_expect_equal(capture.stage_count, 1, "drag: valid drop stages exactly once")
	_expect_equal(capture.card_id, &"arcade", "drag: exact card forwarded")
	_expect_equal(capture.slot_id, &"downtown_loop::route_slot::1", "drag: exact slot forwarded")
	_expect_equal(capture.hand_revision, HAND_REVISION, "drag: exact hand revision forwarded")
	_expect_equal(capture.route_revision, ROUTE_REVISION, "drag: exact route revision forwarded")
	_expect_equal(capture.confirm_count, 0, "drag: drop never confirms or mutates")
	_expect_true(hud.district_card_confirm_button.disabled, "drag: authority token required before Confirm")


func test_mouse_threshold_starts_native_drag_at_eight_pixels_without_staging() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	var source: DistrictCardDragSlot = hud.district_card_choice_01
	var payload: DistrictCardDragPayload = source.get_configured_drag_payload()
	var drag_starts: Array[DistrictCardDragPayload] = []
	source.district_card_drag_started.connect(
		func(started_payload: DistrictCardDragPayload) -> void:
			drag_starts.append(started_payload)
	)
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(80.0, 80.0)
	source._gui_input(down)
	var near_motion: InputEventMouseMotion = InputEventMouseMotion.new()
	near_motion.position = Vector2(87.0, 80.0)
	near_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	source._gui_input(near_motion)
	_expect_equal(source.get_viewport().gui_get_drag_data(), null, "mouse: seven pixels remains click")
	var threshold_motion: InputEventMouseMotion = InputEventMouseMotion.new()
	threshold_motion.position = Vector2(88.0, 80.0)
	threshold_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	source._gui_input(threshold_motion)
	_expect_equal(source.get_viewport().gui_get_drag_data(), payload, "mouse: eight pixels starts native drag")
	_expect_equal(drag_starts.size(), 1, "mouse: drag begins exactly once")
	source._gui_input(threshold_motion)
	_expect_equal(drag_starts.size(), 1, "mouse: later motion does not restart drag")
	_expect_equal(capture.stage_count, 0, "mouse: beginning drag emits no placement")
	source.get_viewport().gui_cancel_drag()


func test_touch_threshold_preserves_first_pointer_and_starts_native_drag() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	var source: DistrictCardDragSlot = hud.district_card_choice_01
	var payload: DistrictCardDragPayload = source.get_configured_drag_payload()
	var drag_starts: Array[DistrictCardDragPayload] = []
	source.district_card_drag_started.connect(
		func(started_payload: DistrictCardDragPayload) -> void:
			drag_starts.append(started_payload)
	)
	var first_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	first_touch.index = 3
	first_touch.pressed = true
	first_touch.position = Vector2(60.0, 60.0)
	source._gui_input(first_touch)
	var second_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	second_touch.index = 4
	second_touch.pressed = true
	second_touch.position = Vector2(70.0, 70.0)
	source._gui_input(second_touch)
	var wrong_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	wrong_drag.index = 4
	wrong_drag.position = Vector2(90.0, 70.0)
	source._gui_input(wrong_drag)
	_expect_equal(source.get_viewport().gui_get_drag_data(), null, "touch: second pointer cannot steal drag")
	var near_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	near_drag.index = 3
	near_drag.position = Vector2(67.0, 60.0)
	source._gui_input(near_drag)
	_expect_equal(source.get_viewport().gui_get_drag_data(), null, "touch: seven pixels remains a tap")
	var first_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	first_drag.index = 3
	first_drag.position = Vector2(68.0, 60.0)
	source._gui_input(first_drag)
	_expect_equal(source.get_viewport().gui_get_drag_data(), payload, "touch: eight pixels starts native drag")
	_expect_equal(drag_starts.size(), 1, "touch: drag begins exactly once")
	_expect_equal(capture.stage_count, 0, "touch: beginning drag emits no placement")
	source.get_viewport().gui_cancel_drag()


func test_successful_stage_result_focuses_confirm_and_keeps_confirmation_separate() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	hud.district_card_choice_01.pressed.emit()
	hud.district_route_slot_01.pressed.emit()
	_expect_equal(capture.stage_count, 1, "stage focus: placement intent is staged once")
	_expect_equal(capture.confirm_count, 0, "stage focus: staging does not confirm")
	hud.present_district_card_placement_result({
		"accepted": true,
		"completed": false,
		"reason": &"ok",
		"confirmation_token": 93,
	})
	_expect_true(hud.district_card_panel.visible, "stage focus: modal remains open for review")
	_expect_false(hud.district_card_confirm_button.disabled, "stage focus: Confirm is enabled")
	_expect_true(
		hud.district_card_confirm_button.has_focus(),
		"stage focus: accepted stage moves keyboard focus to Confirm"
	)
	_expect_equal(capture.confirm_count, 0, "stage focus: presenting token still does not confirm")
	hud.district_card_confirm_button.pressed.emit()
	_expect_equal(capture.confirm_count, 1, "stage focus: deliberate Confirm forwards once")
	_expect_equal(capture.confirmation_token, 93, "stage focus: exact token is forwarded")
	hud.district_card_confirm_button.pressed.emit()
	_expect_equal(capture.confirm_count, 1, "stage focus: repeated Confirm remains exactly once")


func test_click_and_keyboard_focus_fallback_forward_confirm_and_cancel_tokens_once() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	hud.district_card_open_button.pressed.emit()
	_expect_equal(capture.open_count, 1, "fallback: click opens planning once")
	_expect_true(hud.district_card_choice_01.has_focus(), "fallback: first card receives keyboard focus")
	hud.district_card_choice_01.pressed.emit()
	_expect_equal(hud.get_selected_district_card_id(), &"arcade", "fallback: click selects exact card")
	_expect_true(hud.district_route_slot_01.has_focus(), "fallback: first valid slot receives keyboard focus")
	_expect_true(
		hud.district_route_slot_01.focus_mode != Control.FOCUS_NONE,
		"fallback: route button remains keyboard reachable"
	)
	hud.district_route_slot_01.pressed.emit()
	_expect_equal(capture.stage_count, 1, "fallback: click stages once")
	hud.present_district_card_placement_result({
		"accepted": true,
		"reason": &"ok",
		"confirmation_token": 91,
	})
	_expect_false(hud.district_card_confirm_button.disabled, "fallback: accepted token enables Confirm")
	hud.district_card_confirm_button.grab_focus()
	_expect_true(hud.district_card_confirm_button.has_focus(), "fallback: Confirm is keyboard focusable")
	hud.district_card_confirm_button.pressed.emit()
	hud.district_card_confirm_button.pressed.emit()
	_expect_equal(capture.confirm_count, 1, "fallback: repeated Confirm forwards once")
	_expect_equal(capture.confirmation_token, 91, "fallback: exact confirmation token")
	hud.present_district_card_placement_result({"accepted": true, "completed": true, "reason": &"ok"})
	hud.district_card_choice_01.pressed.emit()
	hud.district_route_slot_01.pressed.emit()
	_expect_equal(capture.stage_count, 2, "fallback: second placement can stage after completion")
	hud.present_district_card_placement_result({
		"accepted": true,
		"reason": &"ok",
		"confirmation_token": 92,
	})
	hud.district_card_cancel_button.pressed.emit()
	_expect_equal(capture.cancel_count, 1, "fallback: Cancel forwards once")
	_expect_equal(capture.cancelled_token, 92, "fallback: exact cancellation token")
	_expect_equal(hud.get_selected_district_route_slot_id(), &"", "fallback: cancel clears route selection")
	hud.district_card_close_button.pressed.emit()
	_expect_equal(capture.close_count, 1, "fallback: close intent forwards once")


func test_authority_ending_planning_dismisses_modal_without_echoing_close_intent() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var flow: RunFlowController = track(RunFlowController.new()) as RunFlowController
	flow.card_planning_changed.connect(hud.present_district_card_planning_state)
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	_expect_true(hud.district_card_panel.visible, "authority close: planning modal starts visible")
	flow.card_planning_changed.emit(true)
	_expect_true(hud.district_card_panel.visible, "authority close: active planning remains visible")
	flow.card_planning_changed.emit(false)
	_expect_false(hud.district_card_panel.visible, "authority close: inactive planning dismisses modal")
	_expect_equal(
		hud.get_district_card_panel_mode(),
		GameHUD.DistrictCardPanelMode.CLOSED,
		"authority close: presentation mode returns to closed"
	)
	_expect_equal(capture.close_count, 0, "authority close: presentation emits no player close intent")


func test_invalid_and_outside_drop_return_card_without_any_mutation_request() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	var source: DistrictCardDragSlot = hud.district_card_choice_01
	var payload: DistrictCardDragPayload = source.get_configured_drag_payload()
	hud._on_district_card_drag_started(payload)
	_expect_false(hud.district_route_slot_02.accepts_drag_payload(payload), "invalid drop: wrong node rejects")
	hud.district_route_slot_02._drop_data(Vector2.ZERO, payload)
	_expect_equal(capture.stage_count, 0, "invalid drop: rejected target emits nothing")
	hud._on_district_card_drag_ended(payload, false)
	_expect_contains(hud.district_card_feedback.text, "CARD RETURNED TO HAND", "outside drop: immediate return")
	_expect_contains(hud.district_card_feedback.text, "NOTHING CHANGED", "outside drop: no mutation explained")
	_expect_equal(hud.get_selected_district_card_id(), &"arcade", "outside drop: card remains selected in hand")
	_expect_equal(hud.get_selected_district_route_slot_id(), &"", "outside drop: no slot remains staged")
	_expect_equal(capture.confirm_count, 0, "outside drop: no confirmation intent")
	_expect_equal(capture.cancel_count, 0, "outside drop: no authority token was cancelled")
	_expect_true(hud.district_card_choice_01.visible, "outside drop: source remains visually in hand")
	_expect_equal(hud.district_card_choice_icon_01.texture, payload.icon, "outside drop: card art returns")


func test_right_click_cancels_native_drag_and_returns_to_hand() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	var source: DistrictCardDragSlot = hud.district_card_choice_01
	var payload: DistrictCardDragPayload = source.get_configured_drag_payload()
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(40.0, 40.0)
	source._gui_input(down)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = Vector2(52.0, 40.0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	source._gui_input(motion)
	_expect_equal(source.get_viewport().gui_get_drag_data(), payload, "right-click: native drag is active")
	var cancel: InputEventMouseButton = InputEventMouseButton.new()
	cancel.button_index = MOUSE_BUTTON_RIGHT
	cancel.pressed = true
	hud._input(cancel)
	_expect_equal(source.get_viewport().gui_get_drag_data(), null, "right-click: viewport drag is cancelled")
	_expect_equal(capture.stage_count, 0, "right-click: cancellation stages nothing")
	_expect_contains(hud.district_card_feedback.text, "DRAG CANCELLED", "right-click: immediate feedback")
	_expect_contains(hud.district_card_feedback.text, "CARD RETURNED TO HAND", "right-click: visual return")


func test_rejected_stage_clears_token_and_preserves_card_selection() -> void:
	var hud: GameHUD = _new_hud([CARD_CATALOGUE.get_by_id(&"arcade")])
	var capture: PlacementIntentCapture = _capture_placement(hud)
	_open_planning(hud)
	hud.district_card_choice_01.pressed.emit()
	hud.district_route_slot_01.pressed.emit()
	_expect_equal(capture.stage_count, 1, "rejection: stage request emitted once")
	hud.present_district_card_placement_result({
		"accepted": false,
		"reason": &"stale_route_revision",
		"confirmation_token": -1,
	})
	_expect_true(hud.district_card_confirm_button.disabled, "rejection: Confirm remains disabled")
	_expect_equal(hud.get_selected_district_card_id(), &"arcade", "rejection: card remains in hand")
	_expect_equal(hud.get_selected_district_route_slot_id(), &"", "rejection: stale slot is cleared")
	_expect_contains(hud.district_card_feedback.text, "CARD RETURNED", "rejection: return is explicit")
	_expect_contains(hud.district_card_feedback.text, "STALE ROUTE REVISION", "rejection: reason is explicit")
	_expect_equal(capture.confirm_count, 0, "rejection: no confirmation emitted")


func test_full_hand_keep_hand_reward_and_equipment_modal_are_mutually_exclusive() -> void:
	var hand: Array[DistrictCardDefinition] = _opening_hand()
	var cards: Dictionary = _cards_snapshot(hand)
	cards["reward_hand_full"] = true
	var hud: GameHUD = _new_hud_from_snapshots(cards, _patrol_snapshot())
	hud.present_flow_snapshot({
		"run": {"state": RunDirector.RunState.REWARD_SELECTION},
		"patrol": _patrol_snapshot(),
	})
	hud.present_district_cards(cards, _patrol_snapshot())
	var reward_capture: RewardIntentCapture = RewardIntentCapture.new()
	hud.district_card_reward_acquisition_requested.connect(reward_capture.on_acquisition)
	hud.district_card_reward_skip_requested.connect(reward_capture.on_skip)
	var reward_choices: Array[DistrictCardDefinition] = [
		CARD_CATALOGUE.get_by_id(&"subway_entrance")
	]
	hud.present_district_card_reward(71, 505, reward_choices, HAND_REVISION, true)
	_expect_true(hud.district_card_panel.visible, "full hand: card reward modal opens")
	_expect_false(hud.equipment_reward_panel.visible, "full hand: equipment modal is not behind card modal")
	_expect_true(hud.district_card_skip_button.visible, "full hand: Skip / Keep Hand is visible")
	_expect_contains(hud.district_card_skip_button.text, "KEEP HAND", "full hand: safe path is named")
	_expect_contains(hud.district_card_feedback.text, "HAND FULL", "full hand: capacity is explained")
	hud.district_card_choice_01.pressed.emit()
	_expect_true(hud.district_card_confirm_button.disabled, "full hand: acquisition cannot bypass capacity")
	hud.district_card_skip_button.pressed.emit()
	hud.district_card_skip_button.pressed.emit()
	_expect_equal(reward_capture.skip_count, 1, "full hand: repeated Skip forwards once")
	_expect_equal(reward_capture.encounter_id, 71, "full hand: exact encounter token owner")
	_expect_equal(reward_capture.choice_token, 505, "full hand: exact choice token")
	_expect_equal(reward_capture.acquisition_count, 0, "full hand: Keep Hand acquires nothing")
	hud.present_district_card_acquisition_result(true)
	hud.present_equipment_reward(72, [], [])
	_expect_true(hud.equipment_reward_panel.visible, "modal: equipment reward can open next")
	_expect_false(hud.district_card_panel.visible, "modal: opening equipment closes cards")
	hud.present_district_card_reward(73, 506, reward_choices, HAND_REVISION, true)
	_expect_true(hud.district_card_panel.visible, "modal: card reward can open after equipment")
	_expect_false(hud.equipment_reward_panel.visible, "modal: opening cards closes equipment")


func test_web_safe_structure_keeps_native_mouse_touch_keyboard_paths() -> void:
	var drag_source: String = FileAccess.get_file_as_string(
		"res://scripts/ui/district_card_drag_slot.gd"
	)
	var hud_source: String = FileAccess.get_file_as_string("res://scripts/ui/game_hud.gd")
	var scene_source: String = FileAccess.get_file_as_string("res://scenes/ui/game_hud.tscn")
	for required: String in [
		"_get_drag_data",
		"_can_drop_data",
		"_drop_data",
		"force_drag",
		"InputEventMouseButton",
		"InputEventScreenTouch",
		"InputEventScreenDrag",
		"POINTER_DRAG_THRESHOLD: float = 8.0",
	]:
		_expect_contains(drag_source, required, "web structure: %s" % required)
	_expect_contains(hud_source, "gui_cancel_drag", "web structure: right-click uses Viewport cancellation")
	_expect_contains(hud_source, "grab_focus", "web structure: keyboard focus fallback remains")
	_expect_false(drag_source.contains("OS.has_feature"), "web structure: no platform-specific drag fork")
	_expect_false(drag_source.contains("DisplayServer"), "web structure: no desktop-only input authority")
	for preserved_node: String in ["Card01", "Card02", "Card03", "DistrictCardPanel"]:
		_expect_contains(scene_source, "name=\"%s\"" % preserved_node, "web structure: node %s" % preserved_node)
	var hud: GameHUD = _new_hud()
	_open_planning(hud)
	var actionable_controls: Array[Button] = [
		hud.district_card_open_button,
		hud.district_card_choice_01,
		hud.district_route_slot_01,
		hud.district_card_confirm_button,
		hud.district_card_cancel_button,
	]
	for button: Button in actionable_controls:
		_expect_true(button.focus_mode != Control.FOCUS_NONE, "web structure: keyboard-reachable %s" % button.name)
		_expect_true(_is_ascii(button.text), "web structure: ASCII action copy %s" % button.name)
	hud.present_district_card_reward(
		99,
		600,
		[CARD_CATALOGUE.get_by_id(&"subway_entrance")],
		HAND_REVISION,
		true
	)
	_expect_true(hud.district_card_skip_button.visible, "web structure: reward alternative is visible")
	_expect_true(
		hud.district_card_skip_button.focus_mode != Control.FOCUS_NONE,
		"web structure: reward alternative is keyboard reachable"
	)
	_expect_true(
		_is_ascii(hud.district_card_skip_button.text),
		"web structure: visible reward action uses ASCII copy"
	)


func _new_hud(
	hand: Array[DistrictCardDefinition] = [],
	slots: Array[Dictionary] = []
) -> GameHUD:
	var effective_hand: Array[DistrictCardDefinition] = hand
	if effective_hand.is_empty():
		effective_hand = _opening_hand()
	var effective_slots: Array[Dictionary] = slots
	if effective_slots.is_empty():
		effective_slots = _default_route_slots()
	return _new_hud_from_snapshots(
		_cards_snapshot(effective_hand),
		_patrol_snapshot(effective_slots)
	)


func _new_hud_from_snapshots(cards: Dictionary, patrol: Dictionary) -> GameHUD:
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
	hud.present_flow_snapshot({
		"run": {"state": RunDirector.RunState.PATROLLING},
		"patrol": patrol,
	})
	hud.present_district_cards(cards, patrol)
	hud._set_help_expanded(false)
	return hud


func _open_planning(hud: GameHUD) -> void:
	if not hud.district_card_panel.visible:
		hud.district_card_open_button.pressed.emit()


func _opening_hand() -> Array[DistrictCardDefinition]:
	return [
		CARD_CATALOGUE.get_by_id(&"arcade"),
		CARD_CATALOGUE.get_by_id(&"convenience_store"),
		CARD_CATALOGUE.get_by_id(&"gang_hideout"),
	]


func _cards_snapshot(hand: Array[DistrictCardDefinition]) -> Dictionary:
	var hand_ids: Array[StringName] = []
	for card: DistrictCardDefinition in hand:
		hand_ids.append(card.id)
	return {
		"hand": hand.duplicate(),
		"hand_ids": hand_ids,
		"draw_ids": [&"subway_entrance"],
		"discard_ids": [],
		"hand_count": hand.size(),
		"hand_capacity": 3,
		"draw_count": 1,
		"discard_count": 0,
		"hand_revision": HAND_REVISION,
		"planning_active": false,
		"planning_owns_pause": false,
		"staged_confirmation_token": -1,
		"staged_card_id": &"",
		"staged_slot_id": &"",
		"pending_route_effects": [],
		"resolved_route_effects": [],
		"pending_reward_encounter_id": -1,
		"pending_reward_choice_token": -1,
		"pending_reward_choices": [],
		"reward_hand_full": hand.size() >= 3,
		"no_reshuffle": true,
	}


func _patrol_snapshot(slots: Array[Dictionary] = []) -> Dictionary:
	var effective_slots: Array[Dictionary] = slots
	if effective_slots.is_empty():
		effective_slots = _default_route_slots()
	return {
		"route_id": &"downtown_loop",
		"route_index": 0,
		"route_node_id": &"hideout_exit",
		"route_node_type": &"travel",
		"route_progress": 0.25,
		"loop_count": 0,
		"route_revision": ROUTE_REVISION,
		"current_occurrence_index": 0,
		"current_occurrence_id": &"downtown_loop::occurrence::0",
		"future_route_slots": effective_slots.duplicate(true),
		"pending_route_modifications": [],
		"resolved_route_modifications": [],
		"current_route_modification": {},
	}


func _default_route_slots() -> Array[Dictionary]:
	return [
		_route_slot(1, &"travel", &"valid"),
		_route_slot(2, &"encounter", &"valid"),
		_route_slot(3, &"travel", &"valid"),
		_route_slot(4, &"encounter", &"valid"),
		_route_slot(5, &"travel", &"valid"),
	]


func _route_slot(
	occurrence_index: int,
	node_type: StringName,
	status: StringName,
	occupied_card_id: StringName = &""
) -> Dictionary:
	return {
		"slot_id": StringName("downtown_loop::route_slot::%d" % occurrence_index),
		"occurrence_index": occurrence_index - 1,
		"occurrence_id": StringName("downtown_loop::occurrence::%d" % occurrence_index),
		"route_index": occurrence_index - 1,
		"loop_count": 0,
		"node_id": StringName("node_%d" % occurrence_index),
		"node_type": node_type,
		"route_revision": ROUTE_REVISION,
		"status": status,
		"occupied_card_id": occupied_card_id,
		"occupied_effect_id": &"occupied_effect" if occupied_card_id != &"" else &"",
		"placement_token": 44 if occupied_card_id != &"" else -1,
	}


func _route_buttons(hud: GameHUD) -> Array[DistrictCardDragSlot]:
	return [
		hud.district_route_slot_01,
		hud.district_route_slot_02,
		hud.district_route_slot_03,
		hud.district_route_slot_04,
		hud.district_route_slot_05,
	]


func _capture_placement(hud: GameHUD) -> PlacementIntentCapture:
	var capture: PlacementIntentCapture = PlacementIntentCapture.new()
	hud.district_card_planning_open_requested.connect(capture.on_open)
	hud.district_card_planning_close_requested.connect(capture.on_close)
	hud.district_card_placement_staged.connect(capture.on_stage)
	hud.district_card_placement_confirm_requested.connect(capture.on_confirm)
	hud.district_card_placement_cancel_requested.connect(capture.on_cancel)
	return capture


func _audit_card_fonts(hud: GameHUD) -> Dictionary:
	var failures: Array[String] = []
	var checked: int = 0
	var pending: Array[Node] = [hud.district_card_compact_panel, hud.district_card_panel]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child: Node in node.get_children():
			pending.append(child)
		var control: Control = node as Control
		if control == null or not (control is Label or control is BaseButton):
			continue
		checked += 1
		var font_size: int = control.get_theme_font_size("font_size")
		if font_size < MINIMUM_FONT_SIZE:
			failures.append("%s uses %dpx" % [control.get_path(), font_size])
	return {"checked": checked, "failures": failures}


func _collect_descendant_containment_failures(panel: Panel) -> Array[String]:
	var failures: Array[String] = []
	var bounds: Rect2 = panel.get_global_rect()
	var pending: Array[Node] = []
	pending.assign(panel.get_children())
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child: Node in node.get_children():
			pending.append(child)
		var control: Control = node as Control
		if control == null:
			continue
		var rect: Rect2 = control.get_global_rect()
		if not _rect_is_inside(rect, bounds):
			failures.append("%s outside %s: %s" % [control.get_path(), bounds, rect])
	return failures


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
	var required_height: float = font.get_height(font_size) * float(lines.size())
	_expect_true(
		maximum_line_width <= control.size.x and required_height <= control.size.y,
		"%s (required %.1fx%.1f, available %.1fx%.1f)" % [
			context,
			maximum_line_width,
			required_height,
			control.size.x,
			control.size.y,
		]
	)


func _expect_rect_inside(rect: Rect2, bounds: Rect2, context: String) -> void:
	_expect_true(_rect_is_inside(rect, bounds), "%s (bounds %s, got %s)" % [context, bounds, rect])


func _rect_is_inside(rect: Rect2, bounds: Rect2) -> bool:
	return (
		rect.position.x >= bounds.position.x - 0.01
		and rect.position.y >= bounds.position.y - 0.01
		and rect.end.x <= bounds.end.x + 0.01
		and rect.end.y <= bounds.end.y + 0.01
	)


func _is_ascii(value: String) -> bool:
	for index: int in range(value.length()):
		if value.unicode_at(index) > 127:
			return false
	return true


func _expect_contains(actual: String, expected: String, context: String) -> void:
	assert_contains(actual, expected, context)


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])
