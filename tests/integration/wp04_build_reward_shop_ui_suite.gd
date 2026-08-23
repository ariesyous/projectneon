@tool
extends McpTestSuite

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const JAX: ActorDefinition = preload("res://data/crew/jax.tres")
const ZOEY: ActorDefinition = preload("res://data/crew/zoey.tres")
const REX: ActorDefinition = preload("res://data/crew/rex.tres")
const JAX_ATTACK: AttackDefinition = preload("res://data/attacks/jax_basic_punch.tres")
const ZOEY_ATTACK: AttackDefinition = preload("res://data/attacks/zoey_rapid_strike.tres")
const REX_ATTACK: AttackDefinition = preload("res://data/attacks/rex_heavy_hook.tres")


class RewardCapture:
	extends RefCounted

	var count: int = 0
	var encounter_id: int = -1
	var choice_token: int = -1
	var choice_index: int = -1
	var destination: StringName = &""

	func on_acquisition(
		new_encounter_id: int,
		new_choice_token: int,
		new_choice_index: int,
		new_destination: StringName,
		_equipment_slot: int,
		_backpack_slot: int,
		_replace_confirmed: bool,
		_expected_revision: int
	) -> void:
		count += 1
		encounter_id = new_encounter_id
		choice_token = new_choice_token
		choice_index = new_choice_index
		destination = new_destination


class DeclineCapture:
	extends RefCounted

	var count: int = 0
	var encounter_id: int = -1
	var choice_token: int = -1

	func on_decline(new_encounter_id: int, new_choice_token: int) -> void:
		count += 1
		encounter_id = new_encounter_id
		choice_token = new_choice_token


class ShopCapture:
	extends RefCounted

	var purchase_count: int = 0
	var leave_count: int = 0
	var visit_revision: int = -1
	var source_id: StringName = &""

	func on_purchase(new_visit_revision: int, new_source_id: StringName) -> void:
		purchase_count += 1
		visit_revision = new_visit_revision
		source_id = new_source_id

	func on_leave() -> void:
		leave_count += 1


func suite_name() -> String:
	return "wp04_build_reward_shop_ui"


func test_reward_review_is_one_layer_with_exact_token_destination_build_and_payout() -> void:
	var system: SynergySystem = _new_system()
	assert_true(system.equip_by_id(&"spiked_bat", 0), "reward review: starter")
	assert_true(system.equip_by_id(&"steel_toe_boots", 1), "reward review: active synergy")
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	var choice: EquipmentDefinition = system.get_catalogue_item(&"voltaic_blade")
	var previews: Array[Dictionary] = [_choice_previews(system, choice, JAX, JAX_ATTACK)]
	hud.present_equipment_reward(
		401,
		[choice],
		previews,
		77,
		{
			"display_name": "Neon Stash",
			"awarded_coins": 33,
			"awarded_scrap": 3,
		}
	)
	assert_false(hud.equipment_reward_panel.has_node("StatComparison"), "reward review: owner single layer preserved")
	assert_contains(hud.reward_choice_details_01.text, choice.role_label, "reward review: icon card has category")
	assert_contains(hud.reward_choice_details_01.text, "PROMISE: EVERY HIT", "reward review: short promise")
	assert_false(hud.reward_target_01.visible, "reward review: destination waits for selection")
	hud.reward_choice_01.pressed.emit()
	hud.reward_target_01.pressed.emit()
	assert_contains(hud.reward_choice_details_01.text, "PRIMARY HIT", "reward review: exact crew value")
	assert_contains(hud.reward_choice_details_01.text, "NOW:", "reward review: synergy edge")
	assert_contains(hud.reward_choice_details_01.text, "NEXT:", "reward review: next-fight expression")
	assert_contains(hud.reward_confirmation_label.text, "ACTIVE 1", "reward review: exact destination")
	assert_contains(hud.reward_confirmation_label.text, "SPiked Bat".to_upper(), "reward review: outgoing item named")
	assert_contains(hud.reward_confirmation_label.text, "AFTER ACTIVE", "reward review: post-confirm active state")
	assert_contains(hud.reward_confirmation_label.text, "BACKPACK", "reward review: post-confirm backpack state")
	assert_contains(hud.reward_confirmation_label.text, "+33 COINS", "reward review: paired coins exact")
	assert_contains(hud.reward_confirmation_label.text, "+3 SCRAP", "reward review: paired Scrap exact")
	var capture: RewardCapture = RewardCapture.new()
	hud.equipment_acquisition_requested.connect(capture.on_acquisition)
	hud.reward_confirm_button.pressed.emit()
	hud.reward_confirm_button.pressed.emit()
	assert_eq(capture.count, 1, "reward review: Confirm forwards once")
	assert_eq(capture.encounter_id, 401, "reward review: encounter context exact")
	assert_eq(capture.choice_token, 77, "reward review: monotonic token exact")
	assert_eq(capture.choice_index, 0, "reward review: stable choice exact")
	assert_eq(capture.destination, SynergySystem.AREA_EQUIPPED, "reward review: active destination exact")


func test_full_inventory_names_exact_leave_behind_and_skip_keeps_context() -> void:
	var system: SynergySystem = _new_system()
	for item_id: StringName in [
		&"spiked_bat", &"steel_toe_boots", &"hacker_deck",
	]:
		assert_true(system.equip_by_id(item_id), "full inventory: equip %s" % item_id)
	for item_id: StringName in [
		&"shock_gloves", &"reinforced_jacket", &"chain_sneakers",
	]:
		assert_true(
			system.store(
				system.get_catalogue_item(item_id),
				-1,
				false,
				system.get_inventory_revision()
			),
			"full inventory: store %s" % item_id
		)
	var hud: GameHUD = _new_hud()
	hud.present_build_snapshot(system.get_snapshot())
	var choice: EquipmentDefinition = system.get_catalogue_item(&"voltaic_blade")
	hud.present_equipment_reward(
		402,
		[choice],
		[_choice_previews(system, choice, JAX, JAX_ATTACK)],
		78,
		{"display_name": "Viper Cache", "awarded_coins": 61, "awarded_scrap": 5}
	)
	assert_contains(hud.reward_confirmation_label.text, "INVENTORY FULL", "full inventory: visible before selection")
	hud.reward_choice_01.pressed.emit()
	hud.reward_target_01.pressed.emit()
	assert_true(hud.reward_pack_target_01.visible, "full inventory: explicit stored targets")
	hud.reward_pack_target_02.pressed.emit()
	assert_contains(hud.reward_confirmation_label.text, "DISCARD REINFORCED JACKET", "full inventory: exact leave-behind")
	assert_contains(hud.reward_confirmation_label.text, "+61 COINS", "full inventory: coin payout exact")
	assert_contains(hud.reward_confirmation_label.text, "+5 SCRAP", "full inventory: Scrap payout exact")
	var decline: DeclineCapture = DeclineCapture.new()
	hud.equipment_reward_decline_requested.connect(decline.on_decline)
	hud.reward_cancel_button.pressed.emit()
	hud.reward_keep_current_button.pressed.emit()
	assert_eq(decline.count, 1, "full inventory: Skip forwards once")
	assert_eq(decline.encounter_id, 402, "full inventory: Skip encounter exact")
	assert_eq(decline.choice_token, 78, "full inventory: Skip token exact")


func test_inventory_preview_names_synergy_value_and_post_transaction_state() -> void:
	var system: SynergySystem = _new_system()
	assert_true(system.equip_by_id(&"spiked_bat", 0), "inventory preview: bat")
	assert_true(system.equip_by_id(&"steel_toe_boots", 1), "inventory preview: boots")
	assert_true(
		system.store(
			system.get_catalogue_item(&"voltaic_blade"),
			0,
			false,
			system.get_inventory_revision()
		),
		"inventory preview: blade stored"
	)
	var preview: Dictionary = system.preview_inventory_transaction(
		&"swap",
		SynergySystem.AREA_BACKPACK,
		0,
		1,
		&"voltaic_blade",
		system.get_inventory_revision()
	)
	preview = BuildConsequenceEvaluator.enrich_preview(preview, JAX, JAX_ATTACK, 8.0, 30.0)
	assert_true(bool(preview.get("valid", false)), "inventory preview: authority accepts exact snapshot")
	assert_true(preview.get("deactivations", []).has(&"knockback_2"), "inventory preview: lost synergy exact")
	assert_true(preview.get("immediate_activations", []).has(&"bleed_2"), "inventory preview: activated synergy exact")
	assert_false((preview.get("exact_changes", []) as Array).is_empty(), "inventory preview: exact value changes")
	var hud: GameHUD = _new_hud()
	hud.present_inventory_transaction_preview(preview)
	assert_eq(
		(hud._pending_inventory_preview as Dictionary).get("inventory_revision"),
		system.get_inventory_revision(),
		"inventory preview: HUD only stores authority snapshot"
	)


func test_shop_preview_exposes_affordability_visit_stock_tradeoff_purchase_and_exit() -> void:
	var hud: GameHUD = _new_hud()
	var capture: ShopCapture = ShopCapture.new()
	hud.shop_cooling_requested.connect(capture.on_purchase)
	hud.primary_action_requested.connect(capture.on_leave)
	var preview: Dictionary = _shop_preview(9, &"convenience_store", 80, 20, 80, 62, 4, 3, 2, 1, 1, 0, &"ok")
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.SHOP, preview))
	assert_true(hud.shop_decision_panel.visible, "shop: focused decision visible")
	assert_contains(hud.shop_cooling_choice.text, "80 -> 20", "shop: exact coins")
	assert_contains(hud.shop_cooling_choice.text, "HEAT 80 -> 62", "shop: exact Heat")
	assert_contains(hud.shop_cooling_choice.text, "TIER 4 -> 3", "shop: next-fight tier")
	assert_contains(hud.shop_cooling_choice.text, "VISIT 1 -> 0", "shop: visit stock")
	assert_contains(hud.shop_comparison.get_expression_text(), "COIN x1.35 -> x1.20", "shop: reward tradeoff")
	assert_contains(hud.shop_leave_choice.text, "BUY NOTHING", "shop: decline outcome")
	hud.shop_cooling_choice.pressed.emit()
	hud.shop_leave_choice.pressed.emit()
	assert_eq(capture.purchase_count, 1, "shop: purchase intent once")
	assert_eq(capture.visit_revision, 9, "shop: exact revision forwarded")
	assert_eq(capture.source_id, &"convenience_store", "shop: exact source forwarded")
	assert_eq(capture.leave_count, 1, "shop: exit intent once")
	var purchase_result: Dictionary = preview.duplicate(true)
	purchase_result["accepted"] = true
	hud.present_shop_purchase_result(purchase_result)
	assert_contains(hud.shop_cooling_choice.text, "PURCHASE COMPLETE", "shop: purchase acknowledged")
	assert_contains(
		(hud.shop_decision_panel.get_node("Instruction") as Label).text,
		"Purchase applied exactly",
		"shop: completed purchase cannot regress to no-purchase copy"
	)

	var insufficient: Dictionary = _shop_preview(10, &"convenience_store", 45, 45, 60, 60, 3, 3, 2, 2, 1, 1, &"insufficient_coins")
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.SHOP, insufficient))
	assert_true(hud.shop_cooling_choice.disabled, "shop: unaffordable disabled")
	assert_contains(hud.shop_cooling_choice.tooltip_text, "NEED 15 MORE COINS", "shop: affordability is textual")
	var used: Dictionary = _shop_preview(10, &"convenience_store", 120, 120, 60, 60, 3, 3, 1, 1, 0, 0, &"visit_limit_reached")
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.SHOP, used))
	assert_contains(hud.shop_cooling_choice.tooltip_text, "PURCHASE USED", "shop: visit limit explicit")
	var sold: Dictionary = _shop_preview(10, &"convenience_store", 120, 120, 60, 60, 3, 3, 0, 0, 0, 0, &"sold_out")
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.SHOP, sold))
	assert_contains(hud.shop_cooling_choice.tooltip_text, "SOLD OUT", "shop: global stock explicit")


func test_build_callout_is_icon_labelled_rate_limited_and_clears_outside_combat() -> void:
	var hud: GameHUD = _new_hud()
	var icon: Texture2D = EQUIPMENT_CATALOGUE.get_sorted_items()[0].icon
	assert_true(hud.present_build_callout(icon, "Serrated Wraps", "Bleed +1", &"bleed", 1000), "callout: first proc shown")
	assert_true(hud.build_callout.visible, "callout: visible")
	assert_eq(hud.build_callout.get_heading(), "SERRATED WRAPS", "callout: source label")
	assert_false(hud.present_build_callout(icon, "Serrated Wraps", "Bleed +1", &"bleed", 1200), "callout: duplicate rate-limited")
	assert_contains(hud.build_callout.get_detail(), "x2", "callout: duplicate is aggregated")
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.REWARD_SELECTION, {}))
	assert_false(hud.build_callout.visible, "callout: non-combat cleanup")


func test_three_disjoint_builds_each_lead_one_behavior_axis_without_universal_core() -> void:
	var jax: SynergySystem = _build([&"spiked_bat", &"steel_toe_boots", &"chain_sneakers"])
	var zoey: SynergySystem = _build([&"shock_gloves", &"hacker_deck", &"magnetic_flail"])
	var rex: SynergySystem = _build([&"reinforced_jacket", &"serrated_wraps", &"voltaic_blade"])
	assert_true(jax.is_synergy_active(&"knockback_2"), "matrix: Jax control build")
	assert_true(zoey.is_synergy_active(&"tech_2"), "matrix: Zoey intervention build")
	assert_true(rex.is_synergy_active(&"bleed_2"), "matrix: Rex survival Bleed build")
	_assert_near(jax.get_percent_modifier(&"knockback_distance"), 0.45, "matrix: Jax leads attack knockback")
	_assert_near(
		ZOEY.intervention_cooldown_multiplier * (1.0 + zoey.get_percent_modifier(&"intervention_cooldown")),
		0.6375,
		"matrix: Zoey leads intervention cadence"
	)
	assert_eq(
		int(round(float(REX.maximum_health) * (1.0 + rex.get_percent_modifier(&"maximum_health")))),
		864,
		"matrix: Rex leads survival"
	)
	_assert_near(rex.get_percent_modifier(&"damage_against_bleeding"), 0.35, "matrix: Rex status payoff")
	var all_ids: Dictionary[StringName, bool] = {}
	for system: SynergySystem in [jax, zoey, rex]:
		for item: EquipmentDefinition in system.get_equipped_items():
			assert_false(all_ids.has(item.id), "matrix: no universal shared core item %s" % item.id)
			all_ids[item.id] = true
	assert_eq(all_ids.size(), 9, "matrix: all nine authored items have one distinct role")


func _choice_previews(
	system: SynergySystem,
	item: EquipmentDefinition,
	crew: ActorDefinition,
	attack: AttackDefinition
) -> Dictionary:
	var by_slot: Array[Dictionary] = []
	var matrix: Array = []
	for slot: int in range(SynergySystem.SLOT_COUNT):
		by_slot.append(BuildConsequenceEvaluator.enrich_preview(
			system.preview_equipment(item, slot), crew, attack, 8.0, 30.0
		))
		var by_backpack: Array[Dictionary] = []
		for backpack_slot: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
			by_backpack.append(BuildConsequenceEvaluator.enrich_preview(
				system.preview_equipment(item, slot, backpack_slot), crew, attack, 8.0, 30.0
			))
		matrix.append(by_backpack)
	var stored: Array[Dictionary] = []
	for backpack_slot: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
		stored.append(BuildConsequenceEvaluator.enrich_preview(
			system.preview_stored_equipment(item, backpack_slot), crew, attack, 8.0, 30.0
		))
	return {"by_slot": by_slot, "by_slot_and_backpack": matrix, "by_backpack_slot": stored}


func _shop_preview(
	revision: int,
	source: StringName,
	coins_before: int,
	coins_after: int,
	heat_before: int,
	heat_after: int,
	tier_before: int,
	tier_after: int,
	stock_before: int,
	stock_after: int,
	visit_before: int,
	visit_after: int,
	reason: StringName
) -> Dictionary:
	return {
		"can_purchase": reason == &"ok",
		"reason": reason,
		"visit_revision": revision,
		"source_id": source,
		"coins_before": coins_before,
		"coins_after": coins_after,
		"heat_before": heat_before,
		"heat_after": heat_after,
		"heat_tier_before": tier_before,
		"heat_tier_after": tier_after,
		"reward_quality_before": 3 if tier_before >= 4 else 2,
		"reward_quality_after": 2,
		"reward_multiplier_before": 1.35 if tier_before >= 4 else 1.20,
		"reward_multiplier_after": 1.20,
		"global_stock_before": stock_before,
		"global_stock_after": stock_after,
		"visit_stock_before": visit_before,
		"visit_stock_after": visit_after,
		"night_pressure": 23.5,
	}


func _flow_snapshot(state: int, shop_preview: Dictionary) -> Dictionary:
	return {
		"run": {
			"state": state,
			"state_name": RunDirector.state_name(state),
			"heat": int(shop_preview.get("heat_before", 20)),
			"heat_tier": int(shop_preview.get("heat_tier_before", 1)),
			"night_pressure": 23.5,
			"boss_threshold": 50.0,
			"run_elapsed_seconds": 120.0,
			"district_loop": {},
		},
		"patrol": {},
		"encounter": {},
		"rewards": {
			"coin_total": int(shop_preview.get("coins_before", 0)),
			"scrap_total": 0,
			"streak_count": 0,
		},
		"cooling": {
			"subway_charges": 2,
			"subway_heat_reduction": 15,
			"shop_coin_cost": 60,
			"shop_heat_reduction": 18,
			"shop_purchases_remaining": int(shop_preview.get("global_stock_before", 2)),
			"shop_visit_active": state == RunDirector.RunState.SHOP,
			"shop_visit_source_id": shop_preview.get("source_id", &"convenience_store"),
			"shop_visit_purchases_remaining": int(shop_preview.get("visit_stock_before", 1)),
			"shop_visit_revision": int(shop_preview.get("visit_revision", 9)),
			"shop_purchase_preview": shop_preview,
		},
		"cards": {},
	}


func _build(ids: Array[StringName]) -> SynergySystem:
	var system: SynergySystem = _new_system()
	for item_id: StringName in ids:
		assert_true(system.equip_by_id(item_id), "matrix: equip %s" % item_id)
	return system


func _new_system() -> SynergySystem:
	var system: SynergySystem = track(SynergySystem.new()) as SynergySystem
	system.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	return system


func _new_hud() -> GameHUD:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = Vector2i(1280, 720)
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var hud: GameHUD = track(HUD_SCENE.instantiate()) as GameHUD
	viewport.add_child(hud)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(viewport)
	return hud


func _assert_near(actual: float, expected: float, message: String) -> void:
	assert_true(
		absf(actual - expected) <= 0.0001,
		"%s (actual=%.4f expected=%.4f)" % [message, actual, expected]
	)
