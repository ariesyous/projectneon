extends SceneTree

## Exercises the focused production choice through Godot's real GUI event
## routing. Suite tests already verify the shared revisioned intent; this smoke
## proves keyboard and touch both reach that same native Button path.

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const CARD_CATALOGUE: DistrictCardCatalogue = preload(
	"res://data/cards/milestone_5_district_card_catalogue.tres"
)

var _requests: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var keyboard_hud: GameHUD = await _new_presented_hud()
	keyboard_hud.district_card_choice_01.grab_focus()
	await process_frame
	_send_accept(true)
	_send_accept(false)
	await process_frame
	var keyboard_selected: bool = (
		"PREDICTION" in keyboard_hud.district_card_feedback.text
		and not keyboard_hud.district_card_confirm_button.disabled
	)
	keyboard_hud.district_card_confirm_button.grab_focus()
	await process_frame
	_send_accept(true)
	_send_accept(false)
	await process_frame
	var keyboard_confirmed: bool = (
		_requests.size() == 1
		and StringName(_requests[0].get("card_id", &"")) == &"arcade"
	)
	keyboard_hud.queue_free()
	await process_frame

	_requests.clear()
	var touch_hud: GameHUD = await _new_presented_hud()
	_send_touch(touch_hud.district_card_choice_02, 7)
	await process_frame
	var touch_selected: bool = (
		"PREDICTION" in touch_hud.district_card_feedback.text
		and "TRANSIT + COOLING" in touch_hud.district_card_feedback.text
		and not touch_hud.district_card_confirm_button.disabled
	)
	_send_touch(touch_hud.district_card_confirm_button, 8)
	await process_frame
	var touch_confirmed: bool = (
		_requests.size() == 1
		and StringName(_requests[0].get("card_id", &"")) == &"subway_entrance"
	)

	var passed: bool = (
		keyboard_selected
		and keyboard_confirmed
		and touch_selected
		and touch_confirmed
	)
	print(
		"WP03_INPUT_PARITY_SMOKE=%s keyboard_select=%s keyboard_confirm=%s touch_select=%s touch_confirm=%s"
		% [
			"PASS" if passed else "FAIL",
			keyboard_selected,
			keyboard_confirmed,
			touch_selected,
			touch_confirmed,
		]
	)
	touch_hud.queue_free()
	await process_frame
	quit(0 if passed else 1)


func _new_presented_hud() -> GameHUD:
	var hud: GameHUD = HUD_SCENE.instantiate() as GameHUD
	root.add_child(hud)
	hud.district_plan_choice_requested.connect(_capture_request)
	hud.present_district_cards(_card_snapshot(), {})
	for _frame: int in range(3):
		await process_frame
	return hud


func _send_accept(pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_accept"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _send_touch(control: Control, touch_index: int) -> void:
	var position: Vector2 = control.get_global_rect().get_center()
	var pressed: InputEventScreenTouch = InputEventScreenTouch.new()
	pressed.index = touch_index
	pressed.position = position
	pressed.pressed = true
	Input.parse_input_event(pressed)
	var released: InputEventScreenTouch = InputEventScreenTouch.new()
	released.index = touch_index
	released.position = position
	released.pressed = false
	Input.parse_input_event(released)


func _capture_request(
	card_id: StringName,
	offer_revision: int,
	lifecycle_revision: int,
	lap_id: StringName,
	block_id: StringName
) -> void:
	_requests.append({
		"card_id": card_id,
		"offer_revision": offer_revision,
		"lifecycle_revision": lifecycle_revision,
		"lap_id": lap_id,
		"block_id": block_id,
	})


func _card_snapshot() -> Dictionary:
	var offer: Array[DistrictCardDefinition] = [
		CARD_CATALOGUE.get_by_id(&"arcade"),
		CARD_CATALOGUE.get_by_id(&"subway_entrance"),
	]
	return {
		"district_plan_enabled": true,
		"legacy_route_planner_enabled": false,
		"supplemental_card_rewards_enabled": false,
		"planning_active": true,
		"planning_owns_pause": true,
		"offer": offer,
		"offer_ids": [&"arcade", &"subway_entrance"],
		"offer_count": 2,
		"offer_capacity": 2,
		"offer_revision": 9,
		"lap_deck_remaining": 1,
		"lap_selected_count": 0,
		"lap_index": 1,
		"lap_id": &"district_lap_01",
		"block_index": 1,
		"block_id": &"district_lap_01::block_01",
		"context_lifecycle_revision": 14,
		"selected_next_block": {},
		"active_block": {},
		"current_lap_history": [],
		"archived_lap_history": [],
		"staged_confirmation_token": -1,
		"staged_card_id": &"",
		"staged_slot_id": &"",
	}
