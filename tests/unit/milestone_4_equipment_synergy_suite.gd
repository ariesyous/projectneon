@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const REQUIRED_IDS: Array[StringName] = [
	&"chain_sneakers",
	&"hacker_deck",
	&"magnetic_flail",
	&"reinforced_jacket",
	&"serrated_wraps",
	&"shock_gloves",
	&"spiked_bat",
	&"steel_toe_boots",
	&"voltaic_blade",
]
const PRIMARY_TAGS: Array[StringName] = [&"BLEED", &"KNOCKBACK", &"TECH"]


class SignalCapture:
	extends RefCounted

	var activated: Array[StringName] = []
	var deactivated: Array[StringName] = []
	var build_change_count: int = 0
	var equipment_change_count: int = 0

	func on_activated(synergy: SynergyDefinition) -> void:
		activated.append(synergy.id)

	func on_deactivated(synergy: SynergyDefinition) -> void:
		deactivated.append(synergy.id)

	func on_build_changed(_snapshot: Dictionary) -> void:
		build_change_count += 1

	func on_equipment_changed(
		_slot_index: int,
		_previous: EquipmentDefinition,
		_current: EquipmentDefinition
	) -> void:
		equipment_change_count += 1


func suite_name() -> String:
	return "milestone_4_equipment_synergy"


func test_exactly_nine_required_equipment_definitions_have_unique_stable_ids() -> void:
	_expect_equal(EQUIPMENT_CATALOGUE.items.size(), 9, "catalogue: exactly nine milestone-four items")
	var ids: Array[StringName] = []
	var unique: Dictionary[StringName, bool] = {}
	for item: EquipmentDefinition in EQUIPMENT_CATALOGUE.items:
		ids.append(item.id)
		unique[item.id] = true
	ids.sort_custom(_string_name_before)
	_expect_equal(ids, REQUIRED_IDS, "catalogue: exact required stable ids")
	_expect_equal(unique.size(), 9, "catalogue: all ids unique")


func test_equipment_status_and_synergy_resources_validate_completely() -> void:
	_expect_equal(EQUIPMENT_CATALOGUE.validation_errors(), PackedStringArray(), "validation: equipment")
	_expect_equal(SYNERGY_CATALOGUE.validation_errors(), PackedStringArray(), "validation: synergies")
	var bleed: StatusEffectDefinition = load("res://data/equipment/bleed_status.tres")
	var shock: StatusEffectDefinition = load("res://data/equipment/shock_status.tres")
	_expect_equal(bleed.validation_errors(), PackedStringArray(), "validation: Bleed status")
	_expect_equal(shock.validation_errors(), PackedStringArray(), "validation: Shock status")
	for item: EquipmentDefinition in EQUIPMENT_CATALOGUE.items:
		_expect_true(not item.tags.is_empty(), "validation: %s has tags" % item.id)
		_expect_true(
			not item.modifiers.is_empty() or not item.triggered_effects.is_empty(),
			"validation: %s has typed functional data" % item.id
		)


func test_authored_required_tuning_values_are_locked() -> void:
	var system: SynergySystem = _new_system()
	_expect_approx(_modifier_amount(system, &"spiked_bat", &"heavy_hit_damage"), 0.25, "tuning: bat heavy")
	_expect_approx(_modifier_amount(system, &"spiked_bat", &"knockback_distance"), 0.15, "tuning: bat knockback")
	_expect_equal(_effect(system, &"spiked_bat", &"bleed").chance_basis_points, 2500, "tuning: bat Bleed")
	_expect_approx(_modifier_amount(system, &"shock_gloves", &"attack_speed"), 0.08, "tuning: gloves speed")
	_expect_equal(_effect(system, &"shock_gloves", &"shock").chance_basis_points, 2500, "tuning: gloves Shock")
	_expect_approx(_modifier_amount(system, &"reinforced_jacket", &"maximum_health"), 0.20, "tuning: jacket health")
	_expect_approx(_modifier_amount(system, &"reinforced_jacket", &"knockback_received"), -0.20, "tuning: jacket resistance")
	_expect_approx(_modifier_amount(system, &"hacker_deck", &"intervention_cooldown"), -0.10, "tuning: deck cooldown")
	_expect_approx(_modifier_amount(system, &"hacker_deck", &"shock_duration"), 1.5, "tuning: deck Shock")
	_expect_approx(_modifier_amount(system, &"steel_toe_boots", &"movement_speed"), 0.10, "tuning: boots movement")
	_expect_approx(_modifier_amount(system, &"steel_toe_boots", &"environmental_collision_damage"), 0.15, "tuning: boots collision")
	_expect_approx(_modifier_amount(system, &"serrated_wraps", &"bleed_maximum_stacks"), 1.0, "tuning: wraps stacks")
	_expect_approx(_modifier_amount(system, &"serrated_wraps", &"damage_against_bleeding"), 0.15, "tuning: wraps damage")
	_expect_equal(_effect(system, &"serrated_wraps", &"bleed").chance_basis_points, 3500, "tuning: wraps Bleed")
	_expect_approx(_modifier_amount(system, &"magnetic_flail", &"environmental_knockback"), 0.20, "tuning: flail interaction")
	_expect_equal(_effect(system, &"voltaic_blade", &"bleed").chance_basis_points, 10000, "tuning: blade Bleed")
	_expect_approx(_modifier_amount(system, &"voltaic_blade", &"damage_against_shocked"), 0.20, "tuning: blade Shock")
	_expect_approx(_modifier_amount(system, &"chain_sneakers", &"movement_speed"), 0.06, "tuning: sneakers movement")
	_expect_approx(_modifier_amount(system, &"chain_sneakers", &"attack_speed"), 0.06, "tuning: sneakers attack")
	_expect_approx(_modifier_amount(system, &"chain_sneakers", &"knockback_distance"), 0.10, "tuning: sneakers knockback")


func test_three_generic_slots_equip_replace_and_remove() -> void:
	var system: SynergySystem = _new_system()
	_expect_equal(system.get_snapshot().get("slot_count"), 3, "slots: exactly three")
	_expect_equal(system.first_empty_slot(), 0, "slots: first empty starts at zero")
	_expect_true(system.equip_by_id(&"spiked_bat"), "slots: acquisition fills first empty")
	_expect_equal(system.get_equipped_item(0).id, &"spiked_bat", "slots: bat in slot zero")
	_expect_false(system.equip_by_id(&"hacker_deck", 0), "slots: low-level equip cannot evict")
	_expect_true(
		system.acquire_equipped(
			system.get_catalogue_item(&"hacker_deck"),
			0,
			0,
			false,
			system.get_inventory_revision()
		),
		"slots: explicit safe replacement succeeds"
	)
	_expect_equal(system.get_equipped_item(0).id, &"hacker_deck", "slots: replacement stored")
	_expect_equal(system.get_backpack_item(0).id, &"spiked_bat", "slots: outgoing item is preserved")
	_expect_true(system.remove(0), "slots: removal succeeds")
	_expect_equal(system.get_equipped_item(0), null, "slots: removal clears")
	_expect_false(system.remove(0), "slots: repeated removal rejected")


func test_duplicate_invalid_and_full_without_target_are_rejected() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "rejection: first equip")
	_expect_false(system.equip_by_id(&"spiked_bat", 1), "rejection: duplicate stable id")
	var invalid: EquipmentDefinition = EquipmentDefinition.new()
	invalid.id = &"spiked_bat"
	invalid.display_name = "Forgery"
	_expect_false(system.equip(invalid, 1), "rejection: non-catalogue resource")
	_expect_false(system.equip_by_id(&"missing", 1), "rejection: unknown id")
	_expect_true(system.equip_by_id(&"hacker_deck", 1), "rejection: slot one")
	_expect_true(system.equip_by_id(&"reinforced_jacket", 2), "rejection: slot two")
	_expect_false(system.equip_by_id(&"steel_toe_boots"), "rejection: full loadout needs replacement target")


func test_modifier_and_tag_aggregation_are_stable_across_slot_order() -> void:
	var left: SynergySystem = _new_system()
	var right: SynergySystem = _new_system()
	_expect_true(left.equip_by_id(&"spiked_bat", 0), "aggregation: left bat")
	_expect_true(left.equip_by_id(&"steel_toe_boots", 1), "aggregation: left boots")
	_expect_true(left.equip_by_id(&"hacker_deck", 2), "aggregation: left deck")
	_expect_true(right.equip_by_id(&"hacker_deck", 0), "aggregation: right deck")
	_expect_true(right.equip_by_id(&"spiked_bat", 1), "aggregation: right bat")
	_expect_true(right.equip_by_id(&"steel_toe_boots", 2), "aggregation: right boots")
	_expect_equal(left.get_tag_counts(), right.get_tag_counts(), "aggregation: tags stable")
	_expect_equal(left.get_flat_modifiers(), right.get_flat_modifiers(), "aggregation: flat stable")
	_expect_equal(left.get_percent_modifiers(), right.get_percent_modifiers(), "aggregation: percent stable")
	_expect_approx(left.get_percent_modifier(&"knockback_distance"), 0.35, "aggregation: item + synergy knockback")
	_expect_approx(left.get_percent_modifier(&"environmental_collision_damage"), 0.40, "aggregation: item + synergy collision")


func test_every_equipment_change_recalculates_immediately() -> void:
	var system: SynergySystem = _new_system()
	var capture: SignalCapture = SignalCapture.new()
	system.build_changed.connect(capture.on_build_changed)
	system.equipment_changed.connect(capture.on_equipment_changed)
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "immediate: equip")
	_expect_equal(system.get_tag_count(&"BLEED"), 1, "immediate: tag visible synchronously")
	_expect_true(system.equip_by_id(&"voltaic_blade", 1), "immediate: second equip")
	_expect_true(system.is_synergy_active(&"bleed_2"), "immediate: activation visible synchronously")
	_expect_true(system.remove(1), "immediate: remove")
	_expect_false(system.is_synergy_active(&"bleed_2"), "immediate: deactivation visible synchronously")
	_expect_equal(capture.build_change_count, 3, "immediate: exactly one build event per change")
	_expect_equal(capture.equipment_change_count, 3, "immediate: exactly one equipment event per change")


func test_knockback_2_activation_and_exact_effects() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"chain_sneakers", 1)
	_expect_true(system.is_synergy_active(&"knockback_2"), "knockback: threshold activates")
	_expect_approx(system.get_percent_modifier(&"knockback_distance"), 0.45, "knockback: bat + sneakers +20% synergy")
	_expect_approx(system.get_percent_modifier(&"environmental_collision_damage"), 0.25, "knockback: exact +25% synergy collision")


func test_bleed_2_activation_and_exact_effects() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"serrated_wraps", 1)
	_expect_true(system.is_synergy_active(&"bleed_2"), "bleed: threshold activates")
	_expect_approx(system.get_flat_modifier(&"bleed_maximum_stacks"), 3.0, "bleed: wraps + two synergy stacks")
	_expect_approx(system.get_percent_modifier(&"damage_against_bleeding"), 0.35, "bleed: wraps + crew synergy damage")


func test_tech_2_activation_and_exact_effects() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"shock_gloves", 0)
	system.equip_by_id(&"hacker_deck", 1)
	_expect_true(system.is_synergy_active(&"tech_2"), "tech: threshold activates")
	_expect_approx(system.get_percent_modifier(&"intervention_cooldown"), -0.25, "tech: deck -10% plus synergy -15%")
	_expect_approx(system.get_flat_modifier(&"shock_duration"), 3.0, "tech: deck + synergy Shock duration")


func test_activation_and_deactivation_signals_emit_once_without_duplicates() -> void:
	var system: SynergySystem = _new_system()
	var capture: SignalCapture = SignalCapture.new()
	system.synergy_activated.connect(capture.on_activated)
	system.synergy_deactivated.connect(capture.on_deactivated)
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"steel_toe_boots", 1)
	_expect_equal(capture.activated, [&"knockback_2"], "signals: one activation")
	system.equip_by_id(&"hacker_deck", 2)
	_expect_equal(capture.activated.size(), 1, "signals: unrelated change emits no duplicate")
	system.remove(1)
	_expect_equal(capture.deactivated, [&"knockback_2"], "signals: one deactivation")
	system.remove(0)
	_expect_equal(capture.deactivated.size(), 1, "signals: inactive threshold emits no duplicate")


func test_replacing_an_item_deactivates_an_invalidated_synergy() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"steel_toe_boots", 1)
	system.equip_by_id(&"reinforced_jacket", 2)
	_expect_true(system.is_synergy_active(&"knockback_2"), "replacement: starts active")
	_expect_true(
		system.acquire_equipped(
			system.get_catalogue_item(&"voltaic_blade"),
			0,
			0,
			false,
			system.get_inventory_revision()
		),
		"replacement: explicit transaction replaces bridge"
	)
	_expect_false(system.is_synergy_active(&"knockback_2"), "replacement: threshold invalidated")
	_expect_equal(system.get_backpack_item(0).id, &"spiked_bat", "replacement: bridge remains owned")


func test_future_non_two_thresholds_are_evaluated_from_data() -> void:
	var threshold_one: SynergyDefinition = _custom_synergy(&"tech_1_test", 1)
	var threshold_four: SynergyDefinition = _custom_synergy(&"tech_4_test", 4)
	var custom_catalogue: SynergyCatalogue = SynergyCatalogue.new()
	var definitions: Array[SynergyDefinition] = [threshold_four, threshold_one]
	custom_catalogue.synergies = definitions
	var system: SynergySystem = track(SynergySystem.new()) as SynergySystem
	system.configure(EQUIPMENT_CATALOGUE, custom_catalogue)
	system.equip_by_id(&"shock_gloves", 0)
	_expect_true(system.is_synergy_active(&"tech_1_test"), "future: threshold one activates")
	_expect_false(system.is_synergy_active(&"tech_4_test"), "future: threshold four remains progress")
	var progress: Array[Dictionary] = system.get_synergy_progress()
	_expect_equal(progress[1].get("threshold"), 4, "future: threshold four retained from data")


func test_each_primary_synergy_has_at_least_three_two_item_combinations() -> void:
	for tag: StringName in PRIMARY_TAGS:
		var tagged_count: int = 0
		for item: EquipmentDefinition in EQUIPMENT_CATALOGUE.items:
			if item.tags.has(tag):
				tagged_count += 1
		var combination_count: int = tagged_count * (tagged_count - 1) / 2
		_expect_true(combination_count >= 3, "combinations: %s has at least three pairs" % tag)


func test_cross_primary_bridges_and_named_build_path_contract() -> void:
	var bridge_ids: Array[StringName] = []
	for item: EquipmentDefinition in EQUIPMENT_CATALOGUE.items:
		var primary_count: int = 0
		for tag: StringName in PRIMARY_TAGS:
			if item.tags.has(tag):
				primary_count += 1
		if primary_count >= 2:
			bridge_ids.append(item.id)
	_expect_true(bridge_ids.size() >= 2, "bridges: at least two cross-primary items")
	_expect_true(bridge_ids.has(&"spiked_bat"), "bridges: Spiked Bat")
	_expect_true(bridge_ids.has(&"magnetic_flail"), "bridges: Magnetic Flail")
	_expect_true(bridge_ids.has(&"voltaic_blade"), "bridges: Voltaic Blade")


func test_immediate_activation_and_alternative_path_previews_are_accurate() -> void:
	var system: SynergySystem = _new_system()
	var bat_preview: Dictionary = system.preview_equipment(system.get_catalogue_item(&"spiked_bat"), 0)
	_expect_equal(bat_preview.get("immediate_activations"), [], "preview: first bridge activates nothing")
	_expect_equal(_preview_path_tags(bat_preview), [&"BLEED", &"KNOCKBACK"], "preview: bat opens two paths")
	system.equip_by_id(&"spiked_bat", 0)
	var flail_preview: Dictionary = system.preview_equipment(system.get_catalogue_item(&"magnetic_flail"), 1)
	_expect_true(flail_preview.get("immediate_activations", []).has(&"knockback_2"), "preview: flail completes Knockback")
	_expect_true(_preview_path_tags(flail_preview).has(&"TECH"), "preview: flail also opens Tech")
	var blade_preview: Dictionary = system.preview_equipment(system.get_catalogue_item(&"voltaic_blade"), 1)
	_expect_true(blade_preview.get("immediate_activations", []).has(&"bleed_2"), "preview: blade completes Bleed")
	_expect_true(_preview_path_tags(blade_preview).has(&"TECH"), "preview: blade also opens Tech")


func test_full_slot_replacement_preview_reports_loss_gain_and_replaced_item() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"steel_toe_boots", 1)
	system.equip_by_id(&"hacker_deck", 2)
	var preview: Dictionary = system.preview_equipment(
		system.get_catalogue_item(&"voltaic_blade"),
		0
	)
	_expect_true(bool(preview.get("valid", false)), "full preview: valid targeted replacement")
	_expect_equal(preview.get("replaces_id"), &"spiked_bat", "full preview: named consequence")
	_expect_true(preview.get("deactivations", []).has(&"knockback_2"), "full preview: Knockback loss")
	_expect_true(preview.get("immediate_activations", []).has(&"tech_2"), "full preview: Tech gain")
	var untargeted: Dictionary = system.preview_equipment(system.get_catalogue_item(&"voltaic_blade"))
	_expect_true(bool(untargeted.get("requires_replacement", false)), "full preview: target required")
	_expect_equal(untargeted.get("replacement_previews", []).size(), 3, "full preview: all three consequences")


func _new_system() -> SynergySystem:
	var system: SynergySystem = track(SynergySystem.new()) as SynergySystem
	system.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	return system


func _modifier_amount(system: SynergySystem, item_id: StringName, stat_id: StringName) -> float:
	var item: EquipmentDefinition = system.get_catalogue_item(item_id)
	for modifier: EquipmentModifierDefinition in item.modifiers:
		if modifier.stat_id == stat_id:
			return modifier.amount
	return NAN


func _effect(
	system: SynergySystem,
	item_id: StringName,
	status_id: StringName
) -> TriggeredEffectDefinition:
	for effect: TriggeredEffectDefinition in system.get_catalogue_item(item_id).triggered_effects:
		if effect.status_id == status_id:
			return effect
	return null


func _custom_synergy(synergy_id: StringName, threshold: int) -> SynergyDefinition:
	var modifier: EquipmentModifierDefinition = EquipmentModifierDefinition.new()
	modifier.id = StringName("%s_modifier" % synergy_id)
	modifier.stat_id = &"test_stat"
	modifier.operation = EquipmentModifierDefinition.Operation.FLAT
	modifier.amount = 1.0
	var synergy: SynergyDefinition = SynergyDefinition.new()
	synergy.id = synergy_id
	synergy.display_name = String(synergy_id)
	synergy.role_label = "TEST ROLE"
	synergy.combat_promise = "Test combat promise."
	synergy.required_tag = &"TECH"
	synergy.threshold = threshold
	var modifiers: Array[EquipmentModifierDefinition] = [modifier]
	synergy.modifiers = modifiers
	synergy.major_effects = PackedStringArray(["Test effect"])
	return synergy


func _preview_path_tags(preview: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in preview.get("alternative_progress", []):
		var entry: Dictionary = value as Dictionary
		result.append(StringName(entry.get("tag", &"")))
	result.sort_custom(_string_name_before)
	return result


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(
		absf(actual - expected) <= 0.0001,
		"%s (expected %.4f, got %.4f)" % [context, expected, actual]
	)


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
