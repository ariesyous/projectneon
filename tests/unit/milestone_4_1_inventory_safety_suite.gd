@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const STREET_REWARD: StandardRewardDefinition = preload(
	"res://data/rewards/street_cache.tres"
)
const SORTED_EQUIPMENT_IDS: Array[StringName] = [
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


class RewardResolutionReentrancyCapture:
	extends RefCounted

	var rewards: RewardDirector
	var encounter_id: int = -1
	var build_change_count: int = 0
	var reentrant_decline_result: bool = true
	var choice_applied_count: int = 0
	var choice_resolved_count: int = 0
	var declined_count: int = 0
	var standard_applied_count: int = 0
	var resolved_equipment_id: StringName = &""

	func on_build_changed(_snapshot: Dictionary) -> void:
		build_change_count += 1
		reentrant_decline_result = rewards.decline_equipment_reward(encounter_id)

	func on_choice_applied(
		_signal_encounter_id: int,
		_choice_index: int,
		_equipment: EquipmentDefinition,
		_slot_index: int
	) -> void:
		choice_applied_count += 1

	func on_choice_resolved(
		_signal_encounter_id: int,
		_choice_index: int,
		equipment: EquipmentDefinition,
		_destination: StringName,
		_equipment_slot: int,
		_backpack_slot: int
	) -> void:
		choice_resolved_count += 1
		resolved_equipment_id = equipment.id

	func on_reward_declined(_signal_encounter_id: int) -> void:
		declined_count += 1

	func on_standard_applied(
		_signal_encounter_id: int,
		_reward: StandardRewardDefinition,
		_total_coins: int,
		_total_scrap: int
	) -> void:
		standard_applied_count += 1


func suite_name() -> String:
	return "milestone_4_1_inventory_safety"


func test_backpack_has_exactly_three_ordered_slots_and_finite_capacity() -> void:
	var system: SynergySystem = _new_system()
	var snapshot: Dictionary = system.get_snapshot()
	_expect_equal(
		int(snapshot.get("backpack_slot_count", -1)),
		SynergySystem.BACKPACK_SLOT_COUNT,
		"backpack: snapshot publishes the authority constant"
	)
	_expect_equal(SynergySystem.BACKPACK_SLOT_COUNT, 3, "backpack: exactly three slots")
	_expect_equal(snapshot.get("backpack_slots", []).size(), 3, "backpack: three ordered entries")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 2), "backpack: store slot three")
	_expect_true(system.store(system.get_catalogue_item(&"spiked_bat"), 0), "backpack: store slot one")
	_expect_true(system.store(system.get_catalogue_item(&"steel_toe_boots"), 1), "backpack: store slot two")
	_expect_equal(system.get_backpack_item(0).id, &"spiked_bat", "backpack: slot one is stable")
	_expect_equal(system.get_backpack_item(1).id, &"steel_toe_boots", "backpack: slot two is stable")
	_expect_equal(system.get_backpack_item(2).id, &"hacker_deck", "backpack: slot three is stable")
	_expect_equal(system.first_empty_backpack_slot(), -1, "backpack: full capacity is explicit")
	_expect_false(
		system.store(system.get_catalogue_item(&"chain_sneakers")),
		"backpack: a fourth item cannot silently replace storage"
	)


func test_duplicate_ownership_is_rejected_across_active_and_backpack_slots() -> void:
	var system: SynergySystem = _new_system()
	var bat: EquipmentDefinition = system.get_catalogue_item(&"spiked_bat")
	var deck: EquipmentDefinition = system.get_catalogue_item(&"hacker_deck")
	_expect_true(system.equip(bat, 0), "duplicate: initial active item")
	_expect_false(system.store(bat, 0), "duplicate: active item cannot also enter backpack")
	_expect_true(system.store(deck, 1), "duplicate: initial stored item")
	_expect_false(system.equip(deck, 2), "duplicate: stored item cannot also become active")
	_expect_true(system.owns_equipment(&"spiked_bat"), "duplicate: active ownership is visible")
	_expect_true(system.owns_equipment(&"hacker_deck"), "duplicate: stored ownership is visible")


func test_backpack_items_do_not_contribute_tags_modifiers_effects_or_synergies() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "inactive storage: one active bridge")
	_expect_true(system.store(system.get_catalogue_item(&"voltaic_blade"), 0), "inactive storage: stored Bleed bridge")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 1), "inactive storage: stored Tech item")
	_expect_equal(system.get_tag_count(&"BLEED"), 1, "inactive storage: stored Bleed tag excluded")
	_expect_equal(system.get_tag_count(&"TECH"), 0, "inactive storage: stored Tech tag excluded")
	_expect_false(system.is_synergy_active(&"bleed_2"), "inactive storage: stored item cannot activate synergy")
	_expect_approx(
		system.get_percent_modifier(&"damage_against_shocked"),
		0.0,
		"inactive storage: stored modifier excluded"
	)
	_expect_approx(
		system.get_percent_modifier(&"intervention_cooldown"),
		0.0,
		"inactive storage: second stored modifier excluded"
	)
	_expect_equal(system.get_triggered_effects().size(), 1, "inactive storage: only active Bat effect aggregates")


func test_atomic_acquire_to_occupied_active_moves_outgoing_item_to_backpack() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 1), "atomic acquire: occupied active setup")
	var revision: int = system.get_inventory_revision()
	var flail: EquipmentDefinition = system.get_catalogue_item(&"magnetic_flail")
	_expect_true(
		system.acquire_equipped(flail, 1, -1, false, revision),
		"atomic acquire: confirmed revision applies one transaction"
	)
	_expect_equal(system.get_inventory_revision(), revision + 1, "atomic acquire: revision increments once")
	_expect_equal(system.get_equipped_item(1), flail, "atomic acquire: incoming item is active")
	_expect_equal(system.get_backpack_item(0).id, &"spiked_bat", "atomic acquire: outgoing item is stored")
	_expect_true(system.owns_equipment(&"spiked_bat"), "atomic acquire: outgoing item remains owned")


func test_full_six_position_inventory_rejects_every_unconfirmed_eviction() -> void:
	var system: SynergySystem = _new_full_system()
	var before_ids: Array[StringName] = _inventory_ids(system)
	var revision: int = system.get_inventory_revision()
	var flail: EquipmentDefinition = system.get_catalogue_item(&"magnetic_flail")
	_expect_false(
		system.acquire_equipped(flail, 0, 1, false, revision),
		"full inventory: occupied active plus occupied backpack needs confirmation"
	)
	_expect_false(
		system.store(flail, 2, false, revision),
		"full inventory: direct storage replacement needs confirmation"
	)
	_expect_equal(_inventory_ids(system), before_ids, "full inventory: rejected actions are non-mutating")
	_expect_equal(system.get_inventory_revision(), revision, "full inventory: rejected actions do not revise state")


func test_explicit_confirmation_replaces_the_exact_named_backpack_position() -> void:
	var system: SynergySystem = _new_full_system()
	var revision: int = system.get_inventory_revision()
	var flail: EquipmentDefinition = system.get_catalogue_item(&"magnetic_flail")
	_expect_true(
		system.acquire_equipped(flail, 1, 2, true, revision),
		"confirmed eviction: exact active and backpack destinations apply"
	)
	_expect_equal(system.get_equipped_item(1), flail, "confirmed eviction: incoming item uses chosen active slot")
	_expect_equal(system.get_backpack_item(2).id, &"hacker_deck", "confirmed eviction: outgoing active uses chosen pack slot")
	_expect_equal(system.get_backpack_item(0).id, &"steel_toe_boots", "confirmed eviction: other pack slot zero unchanged")
	_expect_equal(system.get_backpack_item(1).id, &"serrated_wraps", "confirmed eviction: other pack slot one unchanged")
	_expect_false(system.owns_equipment(&"shock_gloves"), "confirmed eviction: only the named stored item is left behind")


func test_swap_preserves_both_items_and_recalculates_the_active_build() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "swap: active setup")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 2), "swap: stored setup")
	var revision: int = system.get_inventory_revision()
	_expect_true(system.swap_equipped_with_backpack(0, 2, revision), "swap: atomic exchange")
	_expect_equal(system.get_equipped_item(0).id, &"hacker_deck", "swap: stored item becomes active")
	_expect_equal(system.get_backpack_item(2).id, &"spiked_bat", "swap: active item remains stored")
	_expect_equal(system.get_tag_count(&"TECH"), 1, "swap: new active tags apply immediately")
	_expect_equal(system.get_tag_count(&"BLEED"), 0, "swap: stored tags stop applying immediately")


func test_move_to_backpack_requires_confirmation_for_an_occupied_destination() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 1), "move: active setup")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 0), "move: occupied destination setup")
	var revision: int = system.get_inventory_revision()
	_expect_false(
		system.move_equipped_to_backpack(1, 0, false, revision),
		"move: no unconfirmed storage replacement"
	)
	_expect_equal(system.get_equipped_item(1).id, &"spiked_bat", "move: rejected item remains active")
	_expect_true(
		system.move_equipped_to_backpack(1, 0, true, revision),
		"move: explicit exact destination confirmation applies"
	)
	_expect_equal(system.get_equipped_item(1), null, "move: active position is cleared")
	_expect_equal(system.get_backpack_item(0).id, &"spiked_bat", "move: selected item is stored")
	_expect_false(system.owns_equipment(&"hacker_deck"), "move: named replaced item is left behind")


func test_stale_inventory_revisions_reject_mutations_without_side_effects() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "revision: active setup")
	var stale_revision: int = system.get_inventory_revision()
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 0), "revision: intervening mutation")
	var current_ids: Array[StringName] = _inventory_ids(system)
	_expect_false(
		system.acquire_equipped(
			system.get_catalogue_item(&"magnetic_flail"),
			1,
			-1,
			false,
			stale_revision
		),
		"revision: stale reward confirmation rejected"
	)
	_expect_false(
		system.swap_equipped_with_backpack(0, 0, stale_revision),
		"revision: stale management confirmation rejected"
	)
	_expect_equal(_inventory_ids(system), current_ids, "revision: stale requests are non-mutating")


func test_named_confirmed_discard_rejects_wrong_identity_and_clears_exact_item() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "discard: active setup")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 2), "discard: backpack setup")
	var revision: int = system.get_inventory_revision()
	_expect_false(
		system.discard_confirmed(SynergySystem.AREA_BACKPACK, 2, &"shock_gloves", revision),
		"discard: wrong stable id is rejected"
	)
	_expect_false(
		system.discard_confirmed(SynergySystem.AREA_BACKPACK, 2, &"hacker_deck", revision - 1),
		"discard: stale confirmation is rejected"
	)
	_expect_true(
		system.discard_confirmed(SynergySystem.AREA_BACKPACK, 2, &"hacker_deck", revision),
		"discard: exact name and revision apply"
	)
	_expect_equal(system.get_backpack_item(2), null, "discard: exact backpack slot clears")
	_expect_equal(system.get_equipped_item(0).id, &"spiked_bat", "discard: unrelated active item remains")
	var active_revision: int = system.get_inventory_revision()
	_expect_true(
		system.discard_confirmed(SynergySystem.AREA_EQUIPPED, 0, &"spiked_bat", active_revision),
		"discard: exact active item can be deliberately removed"
	)
	_expect_equal(system.get_equipped_item(0), null, "discard: named active slot clears")


func test_reset_clears_active_backpack_synergy_modifiers_and_owned_state() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "reset: active Bat")
	_expect_true(system.equip_by_id(&"steel_toe_boots", 1), "reset: active Boots")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 0), "reset: stored Deck")
	_expect_true(system.is_synergy_active(&"knockback_2"), "reset: active synergy precondition")
	var previous_revision: int = system.get_inventory_revision()
	system.reset_for_run()
	_expect_equal(system.get_equipped_items().size(), 0, "reset: no active items")
	_expect_equal(system.get_backpack_items().size(), 0, "reset: no stored items")
	_expect_equal(system.get_owned_items_stable().size(), 0, "reset: no stale ownership")
	_expect_equal(system.get_active_synergies().size(), 0, "reset: no stale synergies")
	_expect_equal(system.get_tag_counts().size(), 0, "reset: no stale tags")
	_expect_equal(system.get_flat_modifiers().size(), 0, "reset: no stale flat modifiers")
	_expect_equal(system.get_percent_modifiers().size(), 0, "reset: no stale percent modifiers")
	_expect_equal(system.get_inventory_revision(), previous_revision + 1, "reset: old confirmations become stale")


func test_reward_candidates_exclude_every_owned_active_and_backpack_item() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "candidate filter: active ownership")
	_expect_true(system.store(system.get_catalogue_item(&"hacker_deck"), 0), "candidate filter: backpack ownership")
	var rewards: RewardDirector = _new_rewards(system, _new_streams(4510))
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(10)
	var choice_ids: Array[StringName] = _choice_ids(choices)
	_expect_false(choice_ids.has(&"spiked_bat"), "candidate filter: active item excluded")
	_expect_false(choice_ids.has(&"hacker_deck"), "candidate filter: stored item excluded")
	var expected_order: Array[StringName] = SORTED_EQUIPMENT_IDS.duplicate()
	expected_order.erase(&"spiked_bat")
	expected_order.erase(&"hacker_deck")
	_expect_equal(
		rewards.get_last_equipment_candidate_order(),
		expected_order,
		"candidate filter: remaining candidates retain stable ID order"
	)


func test_confirmed_equip_reward_and_standard_reward_latch_exactly_once() -> void:
	var system: SynergySystem = _new_system()
	var rewards: RewardDirector = _new_rewards_with_standard(system, _new_streams(4511))
	var encounter_id: int = 11
	_expect_equal(_prepare_paired_reward(rewards, encounter_id), STREET_REWARD, "reward equip: paired reward prepared")
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(encounter_id)
	var revision: int = system.get_inventory_revision()
	_expect_true(
		rewards.apply_equipment_choice_to_inventory(
			encounter_id,
			0,
			SynergySystem.AREA_EQUIPPED,
			0,
			-1,
			false,
			revision
		),
		"reward equip: confirmed acquisition applies"
	)
	_expect_false(
		rewards.apply_equipment_choice_to_inventory(
			encounter_id,
			0,
			SynergySystem.AREA_EQUIPPED,
			0,
			-1,
			false,
			revision
		),
		"reward equip: repeated confirmation is rejected"
	)
	_expect_equal(system.get_equipped_item(0), choices[0], "reward equip: chosen item appears once")
	_expect_paired_reward_once(rewards, "reward equip")


func test_pending_equipment_choice_blocks_direct_standard_reward_claim() -> void:
	var system: SynergySystem = _new_system()
	var rewards: RewardDirector = _new_rewards_with_standard(system, _new_streams(4514))
	var encounter_id: int = 14
	_expect_equal(
		_prepare_paired_reward(rewards, encounter_id),
		STREET_REWARD,
		"reward guard: paired reward prepared"
	)
	_expect_false(
		rewards.prepare_equipment_choices(encounter_id).is_empty(),
		"reward guard: equipment decision is pending"
	)
	_expect_false(
		rewards.apply_standard_reward(encounter_id),
		"reward guard: ordinary claim cannot orphan equipment modal"
	)
	_expect_equal(rewards.get_coin_total(), 0, "reward guard: coins remain unchanged")
	_expect_equal(
		rewards.get_pending_equipment_choices(encounter_id).size(),
		3,
		"reward guard: equipment choices remain pending"
	)
	_expect_true(
		rewards.decline_equipment_reward(encounter_id),
		"reward guard: explicit keep-current path resolves both rewards"
	)
	_expect_paired_reward_once(rewards, "reward guard")


func test_equipment_resolution_rejects_reentrant_decline_and_finishes_once() -> void:
	var system: SynergySystem = _new_system()
	var rewards: RewardDirector = _new_rewards_with_standard(system, _new_streams(4515))
	var encounter_id: int = 15
	_expect_equal(
		_prepare_paired_reward(rewards, encounter_id),
		STREET_REWARD,
		"reward reentrancy: paired reward prepared"
	)
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(encounter_id)
	_expect_false(choices.is_empty(), "reward reentrancy: equipment choice prepared")

	var capture: RewardResolutionReentrancyCapture = RewardResolutionReentrancyCapture.new()
	capture.rewards = rewards
	capture.encounter_id = encounter_id
	system.build_changed.connect(capture.on_build_changed)
	rewards.equipment_choice_applied.connect(capture.on_choice_applied)
	rewards.equipment_choice_resolved.connect(capture.on_choice_resolved)
	rewards.equipment_reward_declined.connect(capture.on_reward_declined)
	rewards.standard_reward_applied.connect(capture.on_standard_applied)

	_expect_true(
		rewards.apply_equipment_choice_to_inventory(
			encounter_id,
			0,
			SynergySystem.AREA_EQUIPPED,
			0,
			-1,
			false,
			system.get_inventory_revision()
		),
		"reward reentrancy: chosen equipment resolves"
	)
	_expect_equal(capture.build_change_count, 1, "reward reentrancy: one mutation callback")
	_expect_false(
		capture.reentrant_decline_result,
		"reward reentrancy: decline is rejected while the choice is resolving"
	)
	_expect_equal(capture.choice_applied_count, 1, "reward reentrancy: legacy choice signal once")
	_expect_equal(capture.choice_resolved_count, 1, "reward reentrancy: chosen resolution signal once")
	_expect_equal(capture.declined_count, 0, "reward reentrancy: decline signal never emits")
	_expect_equal(capture.standard_applied_count, 1, "reward reentrancy: paired reward signal once")
	_expect_equal(
		capture.resolved_equipment_id,
		choices[0].id,
		"reward reentrancy: emitted resolution names the chosen equipment"
	)
	_expect_equal(
		rewards.get_pending_equipment_choices(encounter_id).size(),
		0,
		"reward reentrancy: pending choice state clears"
	)
	_expect_paired_reward_once(rewards, "reward reentrancy")


func test_confirmed_store_reward_and_standard_reward_latch_exactly_once() -> void:
	var system: SynergySystem = _new_system()
	var rewards: RewardDirector = _new_rewards_with_standard(system, _new_streams(4512))
	var encounter_id: int = 12
	_expect_equal(_prepare_paired_reward(rewards, encounter_id), STREET_REWARD, "reward store: paired reward prepared")
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(encounter_id)
	var revision: int = system.get_inventory_revision()
	_expect_true(
		rewards.apply_equipment_choice_to_inventory(
			encounter_id,
			0,
			SynergySystem.AREA_BACKPACK,
			-1,
			1,
			false,
			revision
		),
		"reward store: confirmed acquisition applies"
	)
	_expect_false(
		rewards.apply_equipment_choice_to_inventory(
			encounter_id,
			0,
			SynergySystem.AREA_BACKPACK,
			-1,
			1,
			false,
			revision
		),
		"reward store: repeated confirmation is rejected"
	)
	_expect_equal(system.get_backpack_item(1), choices[0], "reward store: chosen item appears once")
	_expect_equal(system.get_equipped_items().size(), 0, "reward store: active build remains unchanged")
	_expect_paired_reward_once(rewards, "reward store")


func test_decline_reward_keeps_inventory_and_latches_standard_reward_exactly_once() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"spiked_bat", 0), "reward decline: existing build setup")
	var rewards: RewardDirector = _new_rewards_with_standard(system, _new_streams(4513))
	var encounter_id: int = 13
	_expect_equal(_prepare_paired_reward(rewards, encounter_id), STREET_REWARD, "reward decline: paired reward prepared")
	_expect_false(rewards.prepare_equipment_choices(encounter_id).is_empty(), "reward decline: equipment prepared")
	var before_ids: Array[StringName] = _inventory_ids(system)
	_expect_true(rewards.decline_equipment_reward(encounter_id), "reward decline: first intent resolves")
	_expect_false(rewards.decline_equipment_reward(encounter_id), "reward decline: repeated intent rejected")
	_expect_equal(_inventory_ids(system), before_ids, "reward decline: current build and backpack unchanged")
	_expect_equal(rewards.get_pending_equipment_choices(encounter_id).size(), 0, "reward decline: modal authority clears")
	_expect_paired_reward_once(rewards, "reward decline")


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


func _new_streams(seed: int) -> RunRandomStreams:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams.reset_for_seed(seed)
	return streams


func _new_rewards(system: SynergySystem, streams: RunRandomStreams) -> RewardDirector:
	var rewards: RewardDirector = track(RewardDirector.new()) as RewardDirector
	rewards.configure_random_streams(streams)
	rewards.configure_equipment(system)
	return rewards


func _new_rewards_with_standard(
	system: SynergySystem,
	streams: RunRandomStreams
) -> RewardDirector:
	var rewards: RewardDirector = _new_rewards(system, streams)
	var definitions: Array[StandardRewardDefinition] = [STREET_REWARD]
	rewards.standard_rewards = definitions
	return rewards


func _prepare_paired_reward(
	rewards: RewardDirector,
	encounter_id: int
) -> StandardRewardDefinition:
	var allowed_ids: Array[StringName] = [STREET_REWARD.id]
	return rewards.prepare_standard_reward(encounter_id, 0, allowed_ids)


func _expect_paired_reward_once(rewards: RewardDirector, context: String) -> void:
	_expect_equal(rewards.get_coin_total(), STREET_REWARD.coins, "%s: paired coins once" % context)
	_expect_equal(rewards.get_scrap_total(), STREET_REWARD.scrap, "%s: paired scrap once" % context)
	_expect_equal(
		int(rewards.get_debug_snapshot().get("equipment_rewards_applied", -1)),
		1,
		"%s: one equipment resolution latch" % context
	)


func _choice_ids(choices: Array[EquipmentDefinition]) -> Array[StringName]:
	var result: Array[StringName] = []
	for item: EquipmentDefinition in choices:
		result.append(item.id)
	return result


func _inventory_ids(system: SynergySystem) -> Array[StringName]:
	var result: Array[StringName] = []
	for slot_index: int in range(SynergySystem.SLOT_COUNT):
		var active: EquipmentDefinition = system.get_equipped_item(slot_index)
		result.append(active.id if active != null else &"")
	for slot_index: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
		var stored: EquipmentDefinition = system.get_backpack_item(slot_index)
		result.append(stored.id if stored != null else &"")
	return result


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(
		absf(actual - expected) <= 0.0001,
		"%s (expected %.4f, got %.4f)" % [context, expected, actual]
	)
