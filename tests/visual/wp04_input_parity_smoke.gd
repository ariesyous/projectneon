extends SceneTree

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const JAX: ActorDefinition = preload("res://data/crew/jax.tres")
const JAX_ATTACK: AttackDefinition = preload("res://data/attacks/jax_basic_punch.tres")

var _reward_requests: Array[Dictionary] = []
var _shop_requests: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var keyboard: GameHUD = await _reward_hud()
	keyboard.reward_choice_01.grab_focus()
	await process_frame
	var keyboard_focus: bool = keyboard.reward_choice_01.has_focus()
	_send_accept()
	var keyboard_selected: int = keyboard.get_selected_reward_choice()
	keyboard.reward_target_01.grab_focus()
	await process_frame
	_send_accept()
	var keyboard_destination: StringName = keyboard.get_selected_reward_destination()
	var keyboard_confirm_disabled: bool = keyboard.reward_confirm_button.disabled
	keyboard.reward_confirm_button.grab_focus()
	await process_frame
	_send_accept()
	await process_frame
	var keyboard_ok: bool = _reward_request_matches(0, SynergySystem.AREA_EQUIPPED)
	print("WP04_KEYBOARD_TRACE focus=%s visible=%s disabled=%s selected=%d destination=%s confirm_disabled=%s requests=%d" % [
		keyboard_focus,
		keyboard.reward_choice_01.visible,
		keyboard.reward_choice_01.disabled,
		keyboard_selected,
		keyboard_destination,
		keyboard_confirm_disabled,
		_reward_requests.size(),
	])
	keyboard.queue_free()
	await process_frame

	_reward_requests.clear()
	var touch: GameHUD = await _reward_hud()
	_send_touch(touch.reward_choice_01, 4)
	await process_frame
	_send_touch(touch.reward_store_03, 5)
	await process_frame
	_send_touch(touch.reward_confirm_button, 6)
	await process_frame
	var touch_ok: bool = _reward_request_matches(0, SynergySystem.AREA_BACKPACK)
	touch.queue_free()
	await process_frame

	_reward_requests.clear()
	var mouse: GameHUD = await _reward_hud()
	_send_mouse(mouse.reward_choice_01)
	await process_frame
	_send_mouse(mouse.reward_target_02)
	await process_frame
	_send_mouse(mouse.reward_confirm_button)
	await process_frame
	var mouse_ok: bool = _reward_request_matches(0, SynergySystem.AREA_EQUIPPED)
	mouse.queue_free()
	await process_frame

	var shop: GameHUD = HUD_SCENE.instantiate() as GameHUD
	root.add_child(shop)
	shop.shop_cooling_requested.connect(_capture_shop)
	shop.present_flow_snapshot(_shop_flow_snapshot())
	await process_frame
	_send_touch(shop.shop_cooling_choice, 7)
	await process_frame
	var shop_ok: bool = (
		_shop_requests.size() == 1
		and int(_shop_requests[0].get("revision", -1)) == 23
		and StringName(_shop_requests[0].get("source", &"")) == &"convenience_store"
	)

	var passed: bool = keyboard_ok and touch_ok and mouse_ok and shop_ok
	print("WP04_INPUT_PARITY_SMOKE=%s keyboard=%s touch=%s mouse=%s shop=%s" % [
		"PASS" if passed else "FAIL",
		keyboard_ok,
		touch_ok,
		mouse_ok,
		shop_ok,
	])
	shop.queue_free()
	await process_frame
	quit(0 if passed else 1)


func _reward_hud() -> GameHUD:
	var system: SynergySystem = SynergySystem.new()
	system.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	system.equip_by_id(&"spiked_bat", 0)
	var item: EquipmentDefinition = system.get_catalogue_item(&"voltaic_blade")
	var by_slot: Array[Dictionary] = []
	var matrix: Array = []
	var stored: Array[Dictionary] = []
	for slot: int in range(SynergySystem.SLOT_COUNT):
		by_slot.append(BuildConsequenceEvaluator.enrich_preview(
			system.preview_equipment(item, slot), JAX, JAX_ATTACK, 8.0, 30.0
		))
		var by_backpack: Array[Dictionary] = []
		for backpack_slot: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
			by_backpack.append(BuildConsequenceEvaluator.enrich_preview(
				system.preview_equipment(item, slot, backpack_slot), JAX, JAX_ATTACK, 8.0, 30.0
			))
		matrix.append(by_backpack)
	for backpack_slot: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
		stored.append(BuildConsequenceEvaluator.enrich_preview(
			system.preview_stored_equipment(item, backpack_slot), JAX, JAX_ATTACK, 8.0, 30.0
		))
	var hud: GameHUD = HUD_SCENE.instantiate() as GameHUD
	root.add_child(hud)
	hud.equipment_acquisition_requested.connect(_capture_reward)
	hud.present_build_snapshot(system.get_snapshot())
	hud.present_equipment_reward(
		900,
		[item],
		[{"by_slot": by_slot, "by_slot_and_backpack": matrix, "by_backpack_slot": stored}],
		91,
		{"display_name": "Street Cache", "awarded_coins": 20, "awarded_scrap": 2}
	)
	for _frame: int in range(3):
		await process_frame
	system.free()
	return hud


func _capture_reward(
	encounter_id: int,
	choice_token: int,
	choice_index: int,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int,
	_replace_confirmed: bool,
	_revision: int
) -> void:
	_reward_requests.append({
		"encounter": encounter_id,
		"token": choice_token,
		"choice": choice_index,
		"destination": destination,
		"equipment_slot": equipment_slot,
		"backpack_slot": backpack_slot,
	})


func _capture_shop(revision: int, source: StringName) -> void:
	_shop_requests.append({"revision": revision, "source": source})


func _reward_request_matches(choice: int, destination: StringName) -> bool:
	return (
		_reward_requests.size() == 1
		and int(_reward_requests[0].get("encounter", -1)) == 900
		and int(_reward_requests[0].get("token", -1)) == 91
		and int(_reward_requests[0].get("choice", -1)) == choice
		and StringName(_reward_requests[0].get("destination", &"")) == destination
	)


func _send_accept() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	press.strength = 1.0
	root.push_input(press)
	var release: InputEventAction = InputEventAction.new()
	release.action = &"ui_accept"
	release.pressed = false
	root.push_input(release)


func _send_touch(control: Control, index: int) -> void:
	var position: Vector2 = control.get_global_rect().get_center()
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.index = index
	press.position = position
	press.pressed = true
	Input.parse_input_event(press)
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.index = index
	release.position = position
	release.pressed = false
	Input.parse_input_event(release)


func _send_mouse(control: Control) -> void:
	var position: Vector2 = control.get_global_rect().get_center()
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = position
	press.global_position = position
	press.pressed = true
	Input.parse_input_event(press)
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = position
	release.global_position = position
	release.pressed = false
	Input.parse_input_event(release)


func _shop_flow_snapshot() -> Dictionary:
	var preview: Dictionary = {
		"can_purchase": true,
		"reason": &"ok",
		"visit_revision": 23,
		"source_id": &"convenience_store",
		"coins_before": 120,
		"coins_after": 60,
		"heat_before": 80,
		"heat_after": 62,
		"heat_tier_before": 4,
		"heat_tier_after": 3,
		"reward_quality_before": 3,
		"reward_quality_after": 2,
		"reward_multiplier_before": 1.35,
		"reward_multiplier_after": 1.20,
		"global_stock_before": 2,
		"global_stock_after": 1,
		"visit_stock_before": 1,
		"visit_stock_after": 0,
		"night_pressure": 20.0,
	}
	return {
		"run": {"state": RunDirector.RunState.SHOP, "heat": 80, "heat_tier": 4, "night_pressure": 20.0, "boss_threshold": 50.0, "district_loop": {}},
		"patrol": {}, "encounter": {}, "cards": {},
		"rewards": {"coin_total": 120, "scrap_total": 0, "streak_count": 0},
		"cooling": {
			"subway_charges": 2, "subway_heat_reduction": 15,
			"shop_coin_cost": 60, "shop_heat_reduction": 18,
			"shop_purchases_remaining": 2,
			"shop_visit_active": true,
			"shop_visit_source_id": &"convenience_store",
			"shop_visit_purchases_remaining": 1,
			"shop_visit_revision": 23,
			"shop_purchase_preview": preview,
		},
	}
