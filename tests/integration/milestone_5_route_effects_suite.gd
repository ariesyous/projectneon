@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const CARD_CATALOGUE: DistrictCardCatalogue = preload(
	"res://data/cards/milestone_5_district_card_catalogue.tres"
)
const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const ALLEY_SCUFFLE: EncounterDefinition = preload("res://data/encounters/alley_scuffle.tres")
const ARCADE_AMBUSH: EncounterDefinition = preload("res://data/encounters/arcade_ambush.tres")
const VIPER_SIGNAL: EncounterDefinition = preload("res://data/encounters/viper_signal.tres")
const STREET_CACHE: StandardRewardDefinition = preload("res://data/rewards/street_cache.tres")
const NEON_STASH: StandardRewardDefinition = preload("res://data/rewards/neon_stash.tres")
const VIPER_CACHE: StandardRewardDefinition = preload("res://data/rewards/viper_cache.tres")
const ROUTE_STEP_SECONDS: float = 5.0


class TestEncounterController:
	extends RunEncounterController

	var active_definition: EncounterDefinition
	var active_instance_id: int = -1
	var started_count: int = 0
	var last_started_definition: EncounterDefinition

	func start_run() -> bool:
		reset_for_run()
		return true

	func reset_for_run() -> void:
		active_definition = null
		active_instance_id = -1
		started_count = 0
		last_started_definition = null

	func start_encounter(encounter_instance_id: int, definition: EncounterDefinition) -> bool:
		if definition == null or encounter_instance_id < 0 or active_definition != null:
			return false
		active_definition = definition
		active_instance_id = encounter_instance_id
		last_started_definition = definition
		started_count += 1
		encounter_started.emit(encounter_instance_id, definition, 0)
		status_changed.emit(get_snapshot())
		return true

	func complete_active() -> bool:
		if active_definition == null:
			return false
		var completed_definition: EncounterDefinition = active_definition
		var completed_id: int = active_instance_id
		active_definition = null
		active_instance_id = -1
		encounter_completed.emit(completed_id, completed_definition)
		status_changed.emit(get_snapshot())
		return true

	func has_active_encounter() -> bool:
		return active_definition != null

	func get_active_encounter_instance_id() -> int:
		return active_instance_id

	func get_active_definition() -> EncounterDefinition:
		return active_definition

	func get_total_enemies_spawned() -> int:
		return 0

	func get_total_enemies_defeated() -> int:
		return 0

	func get_snapshot() -> Dictionary:
		return {
			"active_encounter_instance_id": active_instance_id,
			"active_encounter_id": (
				active_definition.id if active_definition != null else &"none"
			),
			"active_encounter_name": (
				active_definition.display_name if active_definition != null else "Patrolling"
			),
			"spawn_budget": 0,
			"remaining_to_spawn": 0,
			"active_enemies": 0,
			"total_enemies_spawned": 0,
			"total_enemies_defeated": 0,
		}


class FlowFixture:
	extends RefCounted

	var run: RunDirector
	var patrol: PatrolController
	var encounter: TestEncounterController
	var rewards: RewardDirector
	var cooling: RunCoolingController
	var combat: CombatDirector
	var hydrant: FireHydrantController
	var synergies: SynergySystem
	var cards: CardSystem
	var flow: RunFlowController


class CardIntentCapture:
	extends RefCounted

	var open_count: int = 0
	var stage_count: int = 0
	var cancel_count: int = 0
	var card_id: StringName = &""
	var slot_id: StringName = &""

	func on_open() -> void:
		open_count += 1

	func on_stage(
		new_card_id: StringName,
		new_slot_id: StringName,
		_hand_revision: int,
		_route_revision: int
	) -> void:
		stage_count += 1
		card_id = new_card_id
		slot_id = new_slot_id

	func on_cancel(_confirmation_token: int) -> void:
		cancel_count += 1


func suite_name() -> String:
	return "milestone_5_route_effects"


func test_five_stable_slots_and_revisioned_placement_are_exactly_once() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"gang_hideout", &"subway_entrance"])
	var slots: Array[RouteSlotSnapshot] = fixture.patrol.get_future_route_slots()
	_expect_equal(slots.size(), 5, "slots: exactly five future occurrences")
	var expected_types: Array[StringName] = [&"encounter", &"shop", &"encounter", &"travel", &"encounter"]
	for index: int in range(slots.size()):
		_expect_equal(slots[index].occurrence_index, index, "slots: monotonic occurrence %d" % index)
		_expect_equal(
			slots[index].slot_id,
			StringName("downtown_loop_route::route_slot::%d" % index),
			"slots: stable slot id %d" % index
		)
		_expect_equal(slots[index].node_type, expected_types[index], "slots: authored node type %d" % index)
	var target: RouteSlotSnapshot = slots[2]
	_expect_true(fixture.flow.begin_card_planning(), "placement: safe planning opens")
	var staged: Dictionary = fixture.flow.stage_card_placement(
		&"gang_hideout", target.slot_id, fixture.cards.get_hand_revision(), fixture.patrol.get_route_revision()
	)
	_expect_true(bool(staged.get("accepted", false)), "placement: valid encounter slot stages")
	var heat_before: int = fixture.run.heat
	var confirmed: Dictionary = fixture.flow.confirm_card_placement(int(staged.get("confirmation_token", -1)))
	_expect_true(bool(confirmed.get("accepted", false)), "placement: first confirmation applies")
	_expect_equal(fixture.run.heat, heat_before + 20, "placement: Heat delta applies once")
	_expect_false(
		bool(fixture.flow.confirm_card_placement(int(staged.get("confirmation_token", -1))).get("accepted", false)),
		"placement: repeated confirmation is rejected"
	)
	_expect_equal(fixture.run.heat, heat_before + 20, "placement: repeated confirmation adds no Heat")
	_expect_equal(fixture.cards.get_discard_pile().size(), 1, "placement: played card enters discard once")
	_expect_equal(fixture.cards.get_snapshot().get("pending_route_effects", []).size(), 1, "placement: pending card effect snapshotted")
	_expect_equal(fixture.patrol.get_snapshot().get("pending_route_modifications", []).size(), 1, "placement: pending route modification snapshotted")

	var authoritative_before: Dictionary = _authoritative_card_fingerprint(fixture)
	var occupied: Dictionary = fixture.flow.stage_card_placement(
		&"subway_entrance", target.slot_id, fixture.cards.get_hand_revision(), fixture.patrol.get_route_revision()
	)
	_expect_equal(occupied.get("reason"), &"occupied", "placement: one card per slot")
	var wrong_type: Dictionary = fixture.flow.stage_card_placement(
		&"subway_entrance", slots[3].slot_id, fixture.cards.get_hand_revision(), fixture.patrol.get_route_revision()
	)
	_expect_equal(wrong_type.get("reason"), &"wrong_node_type", "placement: wrong node rejected")
	var stale: Dictionary = fixture.flow.stage_card_placement(
		&"subway_entrance", slots[4].slot_id, fixture.cards.get_hand_revision(), fixture.patrol.get_route_revision() - 1
	)
	_expect_equal(stale.get("reason"), &"stale_route_revision", "placement: stale revision rejected")
	_expect_equal(fixture.flow.reject_outside_card_drop(&"subway_entrance").get("reason"), &"outside", "placement: outside drop rejected")
	_expect_equal(_authoritative_card_fingerprint(fixture), authoritative_before, "placement: all rejected attempts are non-mutating")
	_expect_true(fixture.flow.end_card_planning(), "placement: planning closes")


func test_current_past_expired_invalid_and_wrong_type_slots_reject_without_mutation() -> void:
	var fixture: FlowFixture = _new_fixture(5102)
	var first_slot: RouteSlotSnapshot = fixture.patrol.get_future_route_slots()[0]
	_expect_equal(
		fixture.patrol.apply_future_route_modification(
			first_slot.slot_id, &"orphan", &"orphan_effect", 700, [&"encounter"], fixture.patrol.get_route_revision()
		),
		&"ok",
		"slot states: orphan setup accepted by route authority"
	)
	_advance_to_occurrence(fixture, 3)
	_expect_equal(fixture.patrol.get_current_occurrence_index(), 3, "slot states: reached travel occurrence")
	var route_history: Array = fixture.patrol.get_snapshot().get("route_slot_history", [])
	var history_status_by_occurrence: Dictionary[int, StringName] = {}
	for history_entry: Variant in route_history:
		if history_entry is Dictionary:
			history_status_by_occurrence[int(history_entry.get("occurrence_index", -1))] = (
				StringName(history_entry.get("status", &"invalid"))
			)
	_expect_equal(route_history.size(), 4, "slot states: current and available closed history are exposed")
	_expect_equal(history_status_by_occurrence.get(3), &"current", "slot states: live history names current identity")
	_expect_equal(history_status_by_occurrence.get(0), &"expired", "slot states: live history retains expired identity")
	_expect_true(fixture.flow.begin_card_planning(), "slot states: planning opens at safe travel")
	var hud: GameHUD = _new_hud(fixture)
	hud.district_card_open_button.pressed.emit()
	_expect_contains(hud.district_card_route_preview.text, "CURRENT OCC 4", "slot states: live panel labels current slot")
	_expect_contains(hud.district_card_route_preview.text, "EXPIRED OCC 1", "slot states: live panel labels expired slot")
	var card: DistrictCardDefinition = fixture.cards.get_hand()[0]
	var revision: int = fixture.patrol.get_route_revision()
	var hand_revision: int = fixture.cards.get_hand_revision()
	var fingerprint: Dictionary = _authoritative_card_fingerprint(fixture)
	_expect_equal(
		fixture.flow.stage_card_placement(card.id, &"downtown_loop_route::route_slot::3", hand_revision, revision).get("reason"),
		&"current",
		"slot states: current occurrence rejected"
	)
	_expect_equal(
		fixture.flow.stage_card_placement(card.id, &"downtown_loop_route::route_slot::1", hand_revision, revision).get("reason"),
		&"past",
		"slot states: past occurrence rejected"
	)
	_expect_equal(
		fixture.flow.stage_card_placement(card.id, first_slot.slot_id, hand_revision, revision).get("reason"),
		&"expired",
		"slot states: expired occurrence rejected"
	)
	_expect_equal(
		fixture.flow.stage_card_placement(card.id, &"downtown_loop_route::route_slot::99", hand_revision, revision).get("reason"),
		&"invalid",
		"slot states: out-of-window identity rejected"
	)
	var opposite: RouteSlotSnapshot = _first_slot_with_other_type(fixture, card)
	_expect_true(opposite != null, "slot states: opposite-type future slot exists")
	if opposite != null:
		_expect_equal(
			fixture.flow.stage_card_placement(card.id, opposite.slot_id, hand_revision, revision).get("reason"),
			&"wrong_node_type",
			"slot states: valid future identity still enforces card node type"
		)
	_expect_equal(_authoritative_card_fingerprint(fixture), fingerprint, "slot states: every rejection preserves authority")
	fixture.flow.end_card_planning()


func test_safe_planning_pause_freezes_time_and_pressure_and_space_cannot_release_it() -> void:
	var fixture: FlowFixture = _new_fixture(5103)
	var elapsed_before: float = fixture.run.run_elapsed_seconds
	var pressure_before: float = fixture.run.night_pressure
	_expect_true(fixture.flow.begin_card_planning(), "planning: safe travel opens")
	_expect_equal(fixture.run.current_state, RunDirector.RunState.PAUSED, "planning: travel is paused")
	_expect_true(fixture.run.is_card_planning_pause_active(), "planning: pause provenance is card-owned")
	fixture.run.step_run(30.0)
	_expect_approx(fixture.run.run_elapsed_seconds, elapsed_before, "planning: eligible time frozen")
	_expect_approx(fixture.run.night_pressure, pressure_before, "planning: Night Pressure frozen")
	_expect_false(fixture.run.toggle_pause(), "planning: Space-equivalent toggle cannot steal pause")
	_expect_equal(fixture.run.current_state, RunDirector.RunState.PAUSED, "planning: state remains paused")
	_expect_true(fixture.flow.end_card_planning(), "planning: explicit close resumes")
	_expect_equal(fixture.run.current_state, RunDirector.RunState.PATROLLING, "planning: returns to patrol")
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.run.current_state, RunDirector.RunState.ENCOUNTER_ACTIVE, "planning: baseline combat started")
	_expect_false(fixture.flow.begin_card_planning(), "planning: active combat rejects planning")


func test_unsafe_progression_transition_clears_planning_and_rejects_stale_confirmation() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"subway_entrance"])
	var threshold: float = fixture.run.escalation_definition.extraction_pressure_thresholds[0]
	fixture.run.add_night_pressure(threshold + 0.1)
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(
		fixture.run.current_state,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
		"planning transition: extraction offer reached"
	)
	_expect_true(fixture.flow.begin_card_planning(), "planning transition: safe extraction planning opens")
	var card: DistrictCardDefinition = fixture.cards.get_hand_card_by_id(&"subway_entrance")
	var slot: RouteSlotSnapshot = _first_compatible_slot(fixture, card)
	var staged: Dictionary = fixture.flow.stage_card_placement(
		card.id,
		slot.slot_id,
		fixture.cards.get_hand_revision(),
		fixture.patrol.get_route_revision()
	)
	var confirmation_token: int = int(staged.get("confirmation_token", -1))
	_expect_true(bool(staged.get("accepted", false)), "planning transition: placement staged")
	_expect_true(confirmation_token >= 0, "planning transition: staged token captured")
	var before_transition: Dictionary = _authoritative_card_fingerprint(fixture)
	_expect_true(fixture.flow.confirm_extraction(), "planning transition: extraction can advance lifecycle")
	_expect_equal(
		fixture.run.current_state,
		RunDirector.RunState.EXTRACTING,
		"planning transition: extraction state entered"
	)
	_expect_false(fixture.cards.is_planning_active(), "planning transition: planning latch cleared")
	_expect_equal(
		fixture.cards.get_snapshot().get("staged_confirmation_token"),
		-1,
		"planning transition: staged token cleared"
	)
	var stale_result: Dictionary = fixture.flow.confirm_card_placement(confirmation_token)
	_expect_false(bool(stale_result.get("accepted", false)), "planning transition: stale confirmation rejected")
	_expect_equal(
		stale_result.get("reason"),
		&"planning_state_invalid",
		"planning transition: authoritative state guard reports invalid planning state"
	)
	_expect_equal(
		_authoritative_card_fingerprint(fixture),
		before_transition,
		"planning transition: stale confirmation changes no card, route, Heat, reward, or stream authority"
	)


func test_card_draws_are_reproducible_isolated_stably_ordered_and_vary_by_seed() -> void:
	var baseline: Dictionary = _card_sequence(5104, false)
	var repeated: Dictionary = _card_sequence(5104, false)
	var noisy: Dictionary = _card_sequence(5104, true)
	_expect_equal(baseline.get("sequence"), repeated.get("sequence"), "cards stream: same seed reproduces opening and reward order")
	_expect_equal(baseline.get("sequence"), noisy.get("sequence"), "cards stream: other-stream activity is isolated")
	_expect_equal(baseline.get("cards_draws"), 4, "cards stream: two opening plus two reward-choice draws")
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		if stream_name == RunRandomStreams.STREAM_CARDS:
			continue
		_expect_equal(
			int((baseline.get("draw_counts", {}) as Dictionary).get(stream_name, 0)),
			0,
			"cards stream: clean card selection consumes no %s draws" % stream_name
		)
	var candidate_order: Array = baseline.get("candidate_order", [])
	var sorted_order: Array = candidate_order.duplicate()
	sorted_order.sort_custom(func(left: Variant, right: Variant) -> bool:
		return String(left).naturalnocasecmp_to(String(right)) < 0
	)
	_expect_equal(candidate_order, sorted_order, "cards stream: remaining candidates sorted by stable ID")
	var sequences: Dictionary[String, bool] = {}
	for seed: int in range(1, 33):
		sequences[JSON.stringify(_card_sequence(seed, false).get("sequence", []))] = true
	_expect_true(sequences.size() >= 8, "cards stream: seeds 1-32 produce at least eight documented permutations")


func test_card_acquisition_is_exactly_once_full_hand_can_keep_and_no_reshuffle_occurs() -> void:
	var fixture: FlowFixture = _new_fixture(5105)
	var opening_hand: Array[StringName] = _card_ids(fixture.cards.get_hand())
	var choices: Array[DistrictCardDefinition] = fixture.rewards.prepare_card_choices(71)
	_expect_equal(choices.size(), 2, "acquisition: finite remainder offers both cards")
	var token: int = fixture.rewards.get_pending_card_choice_token()
	var revision: int = fixture.rewards.get_card_hand_revision()
	var acquired: DistrictCardDefinition = fixture.rewards.acquire_card_choice(71, token, 0, revision)
	_expect_true(acquired != null, "acquisition: selected card added")
	_expect_equal(fixture.cards.get_hand().size(), 3, "acquisition: hand reaches capacity three")
	_expect_equal(fixture.cards.get_draw_pile().size(), 1, "acquisition: only selected card leaves draw pile")
	_expect_equal(fixture.rewards.acquire_card_choice(71, token, 0, revision), null, "acquisition: repeated token rejected")
	var full_choices: Array[DistrictCardDefinition] = fixture.rewards.prepare_card_choices(72)
	_expect_equal(full_choices.size(), 1, "acquisition: remaining valid card may still be reviewed")
	var full_token: int = fixture.rewards.get_pending_card_choice_token()
	_expect_equal(
		fixture.rewards.acquire_card_choice(72, full_token, 0, fixture.cards.get_hand_revision()),
		null,
		"acquisition: full hand cannot be overfilled"
	)
	_expect_true(fixture.rewards.skip_card_choice(72, full_token), "acquisition: Skip / Keep Hand resolves")
	_expect_false(fixture.rewards.skip_card_choice(72, full_token), "acquisition: skip token is exactly once")
	_expect_equal(fixture.cards.get_hand().size(), 3, "acquisition: Keep Hand preserves all three")
	_expect_equal(fixture.cards.get_draw_pile().size(), 1, "acquisition: skipped card remains finite draw candidate")
	_expect_true(bool(fixture.cards.get_snapshot().get("no_reshuffle", false)), "acquisition: M5 no-reshuffle contract exposed")
	_expect_true(opening_hand != _card_ids(fixture.cards.get_hand()), "acquisition: hand changed only through one acquisition")


func test_future_route_effect_waits_for_exact_occurrence_and_resolves_once() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"subway_entrance"])
	var target: RouteSlotSnapshot = _slot_at_occurrence(fixture, 2)
	var placed: Dictionary = _place_card(fixture, &"subway_entrance", target)
	_expect_true(bool(placed.get("accepted", false)), "timing: Subway placed on occurrence two")
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.patrol.get_current_occurrence_index(), 0, "timing: first occurrence reached")
	_expect_equal(fixture.cards.get_snapshot().get("resolved_route_effects", []).size(), 0, "timing: future effect not early")
	_settle_current_route_state(fixture)
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.run.current_state, RunDirector.RunState.SHOP, "timing: intervening shop remains baseline")
	_expect_equal(fixture.cards.get_snapshot().get("pending_route_effects", []).size(), 1, "timing: effect remains pending")
	fixture.flow.leave_shop()
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.patrol.get_current_occurrence_index(), 2, "timing: target occurrence reached")
	_expect_equal(fixture.cards.get_snapshot().get("pending_route_effects", []).size(), 0, "timing: pending effect consumed")
	_expect_equal(fixture.cards.get_snapshot().get("resolved_route_effects", []).size(), 1, "timing: resolved card snapshot retained")
	_expect_equal(fixture.patrol.get_snapshot().get("resolved_route_modifications", []).size(), 1, "timing: resolved route snapshot retained")
	_expect_equal(fixture.cards.resolve_current_route_effect(), null, "timing: repeated resolution is a no-op")


func test_arcade_creates_standard_only_fight_advances_authored_reward_tier_and_never_recurses() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"arcade"])
	var placed: Dictionary = _place_card(fixture, &"arcade", _slot_at_occurrence(fixture, 3))
	_expect_true(bool(placed.get("accepted", false)), "Arcade: placement accepted")
	_advance_to_occurrence(fixture, 3)
	var definition: EncounterDefinition = fixture.encounter.get_active_definition()
	_expect_true(definition != null, "Arcade: resulting fight starts")
	if definition == null:
		return
	_expect_false(definition.elite_eligible, "Arcade: selection is standard-only")
	_expect_false(definition.boss, "Arcade: selection is not a boss")
	_expect_true(definition.id in [&"alley_scuffle", &"arcade_ambush"], "Arcade: selected from baseline standard infrastructure")
	_expect_equal(fixture.rewards.get_advanced_authored_quality_tier(0), 1, "Arcade: authored tier 0 advances to 1")
	_expect_equal(fixture.rewards.get_advanced_authored_quality_tier(1), 3, "Arcade: authored tier 1 advances to 3")
	_expect_equal(fixture.rewards.get_advanced_authored_quality_tier(3), 3, "Arcade: highest authored tier clamps")
	var encounter_id: int = fixture.encounter.get_active_encounter_instance_id()
	var cards_draw_before: int = fixture.run.get_random_streams().get_draw_count(RunRandomStreams.STREAM_CARDS)
	_expect_true(fixture.encounter.complete_active(), "Arcade: encounter completion published")
	var reward: StandardRewardDefinition = fixture.rewards.get_pending_standard_reward(encounter_id)
	_expect_true(reward != null, "Arcade: resulting standard reward prepared")
	if reward != null:
		_expect_equal(reward.quality_tier, 1, "Arcade: live result advances one eligible tier")
	_expect_true(fixture.flow.decline_equipment_reward(), "Arcade: paired reward resolves")
	_expect_false(bool(fixture.flow.get_snapshot().get("card_reward_phase_active", false)), "Arcade: no recursive card reward")
	_expect_equal(fixture.run.get_random_streams().get_draw_count(RunRandomStreams.STREAM_CARDS), cards_draw_before, "Arcade: recursion consumes no card draw")


func test_convenience_store_allows_one_purchase_from_unchanged_finite_stock() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"convenience_store"])
	fixture.run.apply_heat_delta(30)
	var pressure_before_placement: float = fixture.run.night_pressure
	var placed: Dictionary = _place_card(fixture, &"convenience_store", _slot_at_occurrence(fixture, 3))
	_expect_true(bool(placed.get("accepted", false)), "Store: placement accepted")
	_expect_equal(fixture.run.heat, 20, "Store: -10 Heat applies at placement")
	_expect_approx(fixture.run.night_pressure, pressure_before_placement, "Store: placement never lowers pressure")
	_advance_to_occurrence(fixture, 3)
	_expect_equal(fixture.run.current_state, RunDirector.RunState.SHOP, "Store: future node opens shop")
	_expect_equal(fixture.cooling.get_shop_visit_source_id(), &"convenience_store", "Store: visit source is explicit")
	_expect_equal(fixture.cooling.get_shop_purchases_remaining(), 2, "Store: global stock was not replenished")
	_expect_equal(fixture.cooling.get_shop_visit_purchases_remaining(), 1, "Store: visit limit is one")
	fixture.rewards.grant_coins(100)
	var pressure_before_purchase: float = fixture.run.night_pressure
	_expect_true(fixture.flow.request_shop_cooling(), "Store: first purchase succeeds")
	_expect_equal(fixture.cooling.get_shop_purchases_remaining(), 1, "Store: one existing global stock consumed")
	_expect_equal(fixture.cooling.get_shop_visit_purchases_remaining(), 0, "Store: visit allowance exhausted")
	_expect_false(fixture.flow.request_shop_cooling(), "Store: second purchase rejected")
	_expect_equal(fixture.cooling.get_shop_purchases_remaining(), 1, "Store: rejection consumes no stock")
	_expect_approx(fixture.run.night_pressure, pressure_before_purchase, "Store: cooling never lowers pressure")
	_expect_true(fixture.flow.leave_shop(), "Store: visit closes")
	_expect_false(fixture.cooling.is_shop_visit_active(), "Store: no stale visit remains")


func test_gang_hideout_uses_viper_signal_elite_guarantees_equipment_and_never_recurses() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"gang_hideout"])
	var placed: Dictionary = _place_card(fixture, &"gang_hideout", _slot_at_occurrence(fixture, 0))
	_expect_true(bool(placed.get("accepted", false)), "Hideout: placement accepted")
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.encounter.get_active_definition(), VIPER_SIGNAL, "Hideout: exact viper_signal encounter starts")
	_expect_true(VIPER_SIGNAL.elite_eligible, "Hideout: encounter remains elite-eligible")
	_expect_equal(
		VIPER_SIGNAL.allowed_enemy_ids,
		[&"viper_enforcer", &"street_punk", &"bat_thug", &"bottle_thrower"],
		"Hideout: Milestone 6 replaces the accepted placeholder with the authorized Enforcer roster"
	)
	_expect_true(fixture.run.calculate_spawn_budget(VIPER_SIGNAL) > 0, "Hideout: existing scaled budget applies")
	var encounter_id: int = fixture.encounter.get_active_encounter_instance_id()
	var cards_draw_before: int = fixture.run.get_random_streams().get_draw_count(RunRandomStreams.STREAM_CARDS)
	_expect_true(fixture.encounter.complete_active(), "Hideout: elite completion published")
	_expect_true(not fixture.rewards.get_pending_equipment_choices(encounter_id).is_empty(), "Hideout: equipment choice guaranteed")
	_expect_true(fixture.flow.decline_equipment_reward(), "Hideout: equipment reward can be safely declined")
	_expect_false(bool(fixture.flow.get_snapshot().get("card_reward_phase_active", false)), "Hideout: elite does not recursively offer cards")
	_expect_equal(fixture.run.get_random_streams().get_draw_count(RunRandomStreams.STREAM_CARDS), cards_draw_before, "Hideout: no recursive cards-stream draw")


func test_subway_skips_exact_target_without_charge_pressure_or_progression_mutation() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"subway_entrance"])
	fixture.run.apply_heat_delta(30)
	fixture.run.add_night_pressure(10.0)
	var pressure_before: float = fixture.run.night_pressure
	var charges_before: int = fixture.cooling.get_subway_charges()
	var placed: Dictionary = _place_card(fixture, &"subway_entrance", _slot_at_occurrence(fixture, 0))
	_expect_true(bool(placed.get("accepted", false)), "Subway card: placement accepted")
	_expect_equal(fixture.run.heat, 15, "Subway card: -15 Heat applies once")
	_expect_approx(fixture.run.night_pressure, pressure_before, "Subway card: placement does not lower pressure")
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.patrol.get_current_occurrence_index(), 0, "Subway card: exact targeted occurrence reached")
	_expect_equal(fixture.encounter.started_count, 0, "Subway card: targeted standard encounter skipped")
	_expect_equal(fixture.run.current_state, RunDirector.RunState.PATROLLING, "Subway card: reroute returns to travel")
	_expect_equal(fixture.cooling.get_subway_charges(), charges_before, "Subway card: intervention charge untouched")
	_expect_approx(fixture.run.night_pressure, pressure_before, "Subway card: resolution does not lower pressure")
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.run.current_state, RunDirector.RunState.SHOP, "Subway card: following shop is not skipped")
	fixture.flow.leave_shop()
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.run.current_state, RunDirector.RunState.ENCOUNTER_ACTIVE, "Subway card: next standard encounter still occurs")
	_expect_equal(fixture.encounter.started_count, 1, "Subway card: exactly one encounter was skipped")


func test_extraction_defers_exact_current_effect_and_boss_precedence_cannot_be_bypassed() -> void:
	var extraction: FlowFixture = _new_fixture_with_opening([&"subway_entrance"])
	extraction.run.apply_heat_delta(30)
	_place_card(extraction, &"subway_entrance", _slot_at_occurrence(extraction, 0))
	var threshold: float = extraction.run.escalation_definition.extraction_pressure_thresholds[0]
	extraction.run.add_night_pressure(threshold + 0.1)
	var pressure_before: float = extraction.run.night_pressure
	extraction.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(extraction.run.current_state, RunDirector.RunState.EXTRACTION_AVAILABLE, "progression: extraction has boundary precedence")
	_expect_equal(extraction.flow.get_snapshot().get("deferred_route_occurrence_id"), extraction.patrol.get_current_occurrence_id(), "progression: exact current occurrence is deferred")
	_expect_equal(extraction.cards.get_snapshot().get("pending_route_effects", []).size(), 1, "progression: card remains pending during extraction offer")
	_expect_true(extraction.flow.decline_extraction(), "progression: extraction decline resumes deferred node")
	_expect_equal(extraction.patrol.get_current_occurrence_index(), 0, "progression: resume does not advance past target")
	_expect_equal(extraction.cards.get_snapshot().get("resolved_route_effects", []).size(), 1, "progression: deferred effect resolves once")
	_expect_equal(extraction.encounter.started_count, 0, "progression: deferred Subway still skips its exact encounter")
	_expect_approx(extraction.run.night_pressure, pressure_before, "progression: card and decline never lower pressure")
	_expect_true(extraction.run.is_extraction_threshold_spent(0), "progression: extraction threshold remains spent")

	var boss: FlowFixture = _new_fixture_with_opening([&"subway_entrance"])
	_place_card(boss, &"subway_entrance", _slot_at_occurrence(boss, 0))
	boss.run.add_night_pressure(boss.run.escalation_definition.boss_pressure_threshold + 0.1)
	_expect_true(boss.run.is_boss_queued(), "progression: boss queued before route boundary")
	var boss_pressure: float = boss.run.night_pressure
	boss.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(boss.run.current_state, RunDirector.RunState.BOSS_INTRO, "progression: boss outranks pending card effect")
	_expect_true(boss.run.was_boss_started(), "progression: boss start latch preserved")
	_expect_equal(boss.cards.get_snapshot().get("pending_route_effects", []).size(), 1, "progression: queued boss does not clear card state")
	_expect_equal(boss.cards.get_snapshot().get("resolved_route_effects", []).size(), 0, "progression: card cannot bypass boss")
	_expect_false(boss.flow.confirm_extraction(), "progression: card cannot reopen extraction over boss")
	_expect_approx(boss.run.night_pressure, boss_pressure, "progression: boss pressure never reduced")


func test_supplemental_card_reward_is_baseline_only_and_consumes_only_cards_stream() -> void:
	var fixture: FlowFixture = _new_fixture(5111)
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	_expect_equal(fixture.run.current_state, RunDirector.RunState.ENCOUNTER_ACTIVE, "supplemental: baseline encounter starts")
	var encounter_id: int = fixture.encounter.get_active_encounter_instance_id()
	_expect_true(fixture.encounter.complete_active(), "supplemental: baseline completion published")
	var before: Dictionary = fixture.run.get_random_streams().get_debug_snapshot().get("draw_counts", {})
	_expect_true(fixture.flow.decline_equipment_reward(), "supplemental: core reward resolves first")
	_expect_true(bool(fixture.flow.get_snapshot().get("card_reward_phase_active", false)), "supplemental: baseline non-elite offers cards")
	_expect_equal(fixture.rewards.get_pending_card_encounter_id(), encounter_id, "supplemental: offer token bound to baseline encounter")
	_expect_true(fixture.rewards.get_pending_card_choices().size() <= 3, "supplemental: at most three finite choices")
	var after: Dictionary = fixture.run.get_random_streams().get_debug_snapshot().get("draw_counts", {})
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		var delta: int = int(after.get(stream_name, 0)) - int(before.get(stream_name, 0))
		_expect_equal(
			delta,
			fixture.rewards.get_pending_card_choices().size() if stream_name == RunRandomStreams.STREAM_CARDS else 0,
			"supplemental: preparation draw ownership for %s" % stream_name
		)
	_expect_true(
		fixture.flow.skip_card_reward(encounter_id, fixture.rewards.get_pending_card_choice_token()),
		"supplemental: Skip / Keep Hand completes reward flow"
	)
	_expect_equal(fixture.run.current_state, RunDirector.RunState.PATROLLING, "supplemental: patrol resumes")


func test_restart_clears_route_card_modal_tokens_and_restores_cards_stream_state() -> void:
	var fixture: FlowFixture = _new_fixture_with_opening([&"subway_entrance"])
	var opening_ids: Array[StringName] = _card_ids(fixture.cards.get_hand())
	_place_card(fixture, &"subway_entrance", _slot_at_occurrence(fixture, 2))
	fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
	fixture.encounter.complete_active()
	fixture.flow.decline_equipment_reward()
	_expect_equal(fixture.cards.get_discard_pile().size(), 1, "restart: precondition discard populated")
	_expect_equal(fixture.cards.get_snapshot().get("pending_route_effects", []).size(), 1, "restart: precondition route effect pending")
	_expect_true(bool(fixture.flow.get_snapshot().get("card_reward_phase_active", false)), "restart: precondition card modal active")
	var old_route_revision: int = fixture.patrol.get_route_revision()
	fixture.flow.restart_same_seed()
	_expect_equal(fixture.run.current_state, RunDirector.RunState.INTRO, "restart: lifecycle returns to intro")
	_expect_equal(_card_ids(fixture.cards.get_hand()), opening_ids, "restart: same seed restores deterministic opening")
	_expect_equal(fixture.cards.get_discard_pile().size(), 0, "restart: discard cleared")
	_expect_equal(fixture.cards.get_snapshot().get("pending_route_effects", []).size(), 0, "restart: pending effects cleared")
	_expect_equal(fixture.cards.get_snapshot().get("resolved_route_effects", []).size(), 0, "restart: resolved history cleared")
	_expect_equal(fixture.cards.get_snapshot().get("staged_confirmation_token"), -1, "restart: staged confirmation cleared")
	_expect_equal(fixture.cards.get_pending_reward_choice_token(), -1, "restart: reward token cleared")
	_expect_false(fixture.cards.is_planning_active(), "restart: planning modal closed")
	_expect_false(bool(fixture.flow.get_snapshot().get("card_reward_phase_active", false)), "restart: flow modal state cleared")
	_expect_equal(fixture.flow.get_snapshot().get("deferred_route_occurrence_id"), &"", "restart: deferred route entry cleared")
	_expect_equal(fixture.patrol.get_snapshot().get("pending_route_modifications", []).size(), 0, "restart: route modifications cleared")
	_expect_true(fixture.patrol.get_route_revision() > old_route_revision, "restart: old route revisions invalidated")
	_expect_equal(fixture.cooling.get_shop_purchases_remaining(), 2, "restart: finite cooling stock reset normally")
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		_expect_equal(
			fixture.run.get_random_streams().get_draw_count(stream_name),
			2 if stream_name == RunRandomStreams.STREAM_CARDS else 0,
			"restart: deterministic stream reset for %s" % stream_name
		)
	fixture.run.complete_intro()
	fixture.flow.begin_card_planning()
	var card: DistrictCardDefinition = fixture.cards.get_hand()[0]
	var slot: RouteSlotSnapshot = _first_compatible_slot(fixture, card)
	var restaged: Dictionary = fixture.flow.stage_card_placement(
		card.id, slot.slot_id, fixture.cards.get_hand_revision(), fixture.patrol.get_route_revision()
	)
	_expect_equal(restaged.get("confirmation_token"), 1, "restart: confirmation token sequence restarts cleanly")
	fixture.flow.cancel_card_placement(1)
	fixture.flow.end_card_planning()


func test_card_ui_supports_button_pointer_touch_invalid_drop_and_right_click_cancel() -> void:
	var fixture: FlowFixture = _new_fixture(5113)
	var hud: GameHUD = _new_hud(fixture)
	var capture: CardIntentCapture = CardIntentCapture.new()
	hud.district_card_planning_open_requested.connect(capture.on_open)
	hud.district_card_placement_staged.connect(capture.on_stage)
	hud.district_card_placement_cancel_requested.connect(capture.on_cancel)
	hud.district_card_open_button.pressed.emit()
	_expect_equal(capture.open_count, 1, "UI fallback: button opens planning for click, tap, or keyboard activation")
	_expect_true(hud.district_card_choice_01.focus_mode != Control.FOCUS_NONE, "UI fallback: card is keyboard-focusable")
	hud.district_card_choice_01.pressed.emit()
	var source: DistrictCardDragSlot = hud.district_card_choice_01
	var payload: DistrictCardDragPayload = source.get_configured_drag_payload()
	_expect_true(payload != null and payload.is_valid(), "UI drag: typed hand payload configured")
	var valid_target: DistrictCardDragSlot = _first_valid_hud_target(hud)
	var invalid_target: DistrictCardDragSlot = _first_invalid_hud_target(hud)
	_expect_true(valid_target != null and valid_target.accepts_drag_payload(payload), "UI drag: valid route target highlighted and accepts")
	_expect_true(invalid_target != null and not invalid_target.accepts_drag_payload(payload), "UI drag: invalid route target remains distinguishable")
	if valid_target != null:
		valid_target.pressed.emit()
	_expect_equal(capture.stage_count, 1, "UI fallback: focused button path forwards one revisioned placement")

	var pointer_fixture: FlowFixture = _new_fixture(5114)
	var pointer_hud: GameHUD = _new_hud(pointer_fixture)
	pointer_hud.district_card_open_button.pressed.emit()
	var pointer_source: DistrictCardDragSlot = pointer_hud.district_card_choice_01
	var pointer_payload: DistrictCardDragPayload = pointer_source.get_configured_drag_payload()
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(50.0, 50.0)
	pointer_source._gui_input(down)
	var near_motion: InputEventMouseMotion = InputEventMouseMotion.new()
	near_motion.position = Vector2(54.0, 50.0)
	near_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	pointer_source._gui_input(near_motion)
	_expect_equal(pointer_source.get_viewport().gui_get_drag_data(), null, "UI drag: sub-threshold mouse remains click candidate")
	var far_motion: InputEventMouseMotion = InputEventMouseMotion.new()
	far_motion.position = Vector2(66.0, 50.0)
	far_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	pointer_source._gui_input(far_motion)
	_expect_equal(pointer_source.get_viewport().gui_get_drag_data(), pointer_payload, "UI drag: 8px fallback enters native/Web-safe drag")
	var right_click: InputEventMouseButton = InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	pointer_hud._input(right_click)
	_expect_equal(pointer_source.get_viewport().gui_get_drag_data(), null, "UI drag: right click cancels active drag")

	var touch_fixture: FlowFixture = _new_fixture(5115)
	var touch_hud: GameHUD = _new_hud(touch_fixture)
	touch_hud.district_card_open_button.pressed.emit()
	var touch_source: DistrictCardDragSlot = touch_hud.district_card_choice_01
	var touch_payload: DistrictCardDragPayload = touch_source.get_configured_drag_payload()
	var first_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	first_touch.index = 3
	first_touch.pressed = true
	first_touch.position = Vector2(40.0, 40.0)
	touch_source._gui_input(first_touch)
	var second_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	second_touch.index = 4
	second_touch.pressed = true
	second_touch.position = Vector2(45.0, 45.0)
	touch_source._gui_input(second_touch)
	var wrong_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	wrong_drag.index = 4
	wrong_drag.position = Vector2(70.0, 45.0)
	touch_source._gui_input(wrong_drag)
	_expect_equal(touch_source.get_viewport().gui_get_drag_data(), null, "UI drag: second touch cannot steal first pointer")
	var first_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	first_drag.index = 3
	first_drag.position = Vector2(60.0, 40.0)
	touch_source._gui_input(first_drag)
	_expect_equal(touch_source.get_viewport().gui_get_drag_data(), touch_payload, "UI drag: first touch starts native drag")
	touch_source.get_viewport().gui_cancel_drag()
	var stage_before: int = capture.stage_count
	hud._on_district_card_drag_ended(payload, false)
	_expect_equal(capture.stage_count, stage_before, "UI drag: outside drop emits no placement intent")
	_expect_contains(hud.district_card_feedback.text, "RETURNED TO HAND", "UI drag: outside drop gives immediate return feedback")


func _new_fixture(seed: int) -> FlowFixture:
	var fixture: FlowFixture = FlowFixture.new()
	fixture.run = track(RunDirector.new()) as RunDirector
	fixture.run._ready()
	fixture.patrol = track(PatrolController.new()) as PatrolController
	fixture.patrol._ready()
	fixture.encounter = track(TestEncounterController.new()) as TestEncounterController
	fixture.rewards = track(RewardDirector.new()) as RewardDirector
	fixture.rewards._ready()
	fixture.rewards.standard_rewards = [STREET_CACHE, NEON_STASH, VIPER_CACHE]
	fixture.cooling = track(RunCoolingController.new()) as RunCoolingController
	fixture.cooling._ready()
	fixture.combat = track(CombatDirector.new()) as CombatDirector
	fixture.combat._ready()
	fixture.combat.set_physics_process(false)
	fixture.hydrant = track(FireHydrantController.new()) as FireHydrantController
	fixture.hydrant._ready()
	fixture.synergies = track(SynergySystem.new()) as SynergySystem
	fixture.synergies.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	fixture.combat.configure_build_system(fixture.synergies, fixture.run.get_random_streams())
	fixture.cards = track(CardSystem.new()) as CardSystem
	fixture.cards.catalogue = CARD_CATALOGUE
	fixture.flow = track(RunFlowController.new()) as RunFlowController
	fixture.flow.encounter_candidates = [ALLEY_SCUFFLE, ARCADE_AMBUSH, VIPER_SIGNAL]
	fixture.cooling.configure(fixture.run, fixture.rewards, fixture.patrol)
	fixture.hydrant.configure(fixture.combat, Vector2.ZERO)
	fixture.flow.configure(
		fixture.run,
		fixture.patrol,
		fixture.encounter,
		fixture.rewards,
		fixture.cooling,
		fixture.combat,
		fixture.hydrant,
		fixture.synergies,
		fixture.cards
	)
	fixture.flow.start_initial_run(seed, true)
	fixture.run.complete_intro()
	return fixture


func _new_fixture_with_opening(required_ids: Array[StringName]) -> FlowFixture:
	return _new_fixture(_seed_with_opening(required_ids))


func _seed_with_opening(required_ids: Array[StringName]) -> int:
	for seed: int in range(1, 2049):
		var opening: Array[StringName] = _opening_ids_for_seed(seed)
		var matches: bool = true
		for required_id: StringName in required_ids:
			if not opening.has(required_id):
				matches = false
				break
		if matches:
			return seed
	return 1


func _opening_ids_for_seed(seed: int) -> Array[StringName]:
	var streams: RunRandomStreams = RunRandomStreams.new()
	streams.reset_for_seed(seed)
	var remaining: Array[StringName] = [&"arcade", &"convenience_store", &"gang_hideout", &"subway_entrance"]
	var result: Array[StringName] = []
	for _draw_index: int in range(2):
		var selected: StringName = streams.choose_stable_id(RunRandomStreams.STREAM_CARDS, remaining)
		result.append(selected)
		remaining.erase(selected)
	streams.free()
	return result


func _card_sequence(seed: int, draw_other_streams: bool) -> Dictionary:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams.reset_for_seed(seed)
	if draw_other_streams:
		for stream_name: StringName in streams.get_declared_stream_names():
			if stream_name == RunRandomStreams.STREAM_CARDS:
				continue
			for _draw_index: int in range(17):
				streams.draw_index(stream_name, 97)
	var patrol: PatrolController = track(PatrolController.new()) as PatrolController
	patrol.start_patrol()
	var cards: CardSystem = track(CardSystem.new()) as CardSystem
	cards.catalogue = CARD_CATALOGUE
	cards.configure(streams, patrol)
	cards.reset_for_run()
	var sequence: Array[StringName] = _card_ids(cards.get_hand())
	var reward_choices: Array[DistrictCardDefinition] = cards.prepare_reward_choices(91)
	sequence.append_array(_card_ids(reward_choices))
	return {
		"sequence": sequence,
		"candidate_order": cards.get_last_reward_candidate_order(),
		"cards_draws": streams.get_draw_count(RunRandomStreams.STREAM_CARDS),
		"draw_counts": streams.get_debug_snapshot().get("draw_counts", {}),
	}


func _place_card(
	fixture: FlowFixture,
	card_id: StringName,
	slot: RouteSlotSnapshot
) -> Dictionary:
	if slot == null or not fixture.flow.begin_card_planning():
		return {"accepted": false, "reason": &"setup_failed"}
	var staged: Dictionary = fixture.flow.stage_card_placement(
		card_id,
		slot.slot_id,
		fixture.cards.get_hand_revision(),
		fixture.patrol.get_route_revision()
	)
	var result: Dictionary = staged
	if bool(staged.get("accepted", false)):
		result = fixture.flow.confirm_card_placement(int(staged.get("confirmation_token", -1)))
	fixture.flow.end_card_planning()
	return result


func _advance_to_occurrence(fixture: FlowFixture, occurrence_index: int) -> void:
	var guard: int = 0
	while fixture.patrol.get_current_occurrence_index() < occurrence_index and guard < 24:
		guard += 1
		_settle_current_route_state(fixture)
		if fixture.run.current_state != RunDirector.RunState.PATROLLING:
			return
		fixture.patrol.step_patrol(ROUTE_STEP_SECONDS)
		if fixture.patrol.get_current_occurrence_index() < occurrence_index:
			_settle_current_route_state(fixture)


func _settle_current_route_state(fixture: FlowFixture) -> void:
	if fixture.run.current_state == RunDirector.RunState.ENCOUNTER_ACTIVE:
		fixture.encounter.complete_active()
	if fixture.run.current_state == RunDirector.RunState.REWARD_SELECTION:
		var encounter_id: int = int(fixture.flow.get_snapshot().get("pending_reward_encounter_id", -1))
		if fixture.rewards.get_pending_equipment_choices(encounter_id).is_empty():
			fixture.flow.claim_standard_reward()
		else:
			fixture.flow.decline_equipment_reward()
		if bool(fixture.flow.get_snapshot().get("card_reward_phase_active", false)):
			fixture.flow.skip_card_reward(
				encounter_id,
				fixture.rewards.get_pending_card_choice_token()
			)
	if fixture.run.current_state == RunDirector.RunState.SHOP:
		fixture.flow.leave_shop()
	elif fixture.run.current_state == RunDirector.RunState.EXTRACTION_AVAILABLE:
		fixture.flow.decline_extraction()


func _slot_at_occurrence(fixture: FlowFixture, occurrence_index: int) -> RouteSlotSnapshot:
	for slot: RouteSlotSnapshot in fixture.patrol.get_future_route_slots():
		if slot.occurrence_index == occurrence_index:
			return slot
	return null


func _first_compatible_slot(
	fixture: FlowFixture,
	card: DistrictCardDefinition
) -> RouteSlotSnapshot:
	for slot: RouteSlotSnapshot in fixture.patrol.get_future_route_slots():
		if card != null and card.valid_node_types.has(slot.node_type):
			return slot
	return null


func _first_slot_with_other_type(
	fixture: FlowFixture,
	card: DistrictCardDefinition
) -> RouteSlotSnapshot:
	for slot: RouteSlotSnapshot in fixture.patrol.get_future_route_slots():
		if card != null and not card.valid_node_types.has(slot.node_type):
			return slot
	return null


func _authoritative_card_fingerprint(fixture: FlowFixture) -> Dictionary:
	return {
		"heat": fixture.run.heat,
		"pressure": fixture.run.night_pressure,
		"hand": _card_ids(fixture.cards.get_hand()),
		"draw": _card_ids(fixture.cards.get_draw_pile()),
		"discard": _card_ids(fixture.cards.get_discard_pile()),
		"hand_revision": fixture.cards.get_hand_revision(),
		"route_revision": fixture.patrol.get_route_revision(),
		"pending_cards": fixture.cards.get_snapshot().get("pending_route_effects", []).duplicate(true),
		"pending_route": fixture.patrol.get_snapshot().get("pending_route_modifications", []).duplicate(true),
		"stream_draws": fixture.run.get_random_streams().get_debug_snapshot().get("draw_counts", {}).duplicate(true),
		"coins": fixture.rewards.get_coin_total(),
		"scrap": fixture.rewards.get_scrap_total(),
	}


func _card_ids(cards: Array[DistrictCardDefinition]) -> Array[StringName]:
	var result: Array[StringName] = []
	for card: DistrictCardDefinition in cards:
		if card != null:
			result.append(card.id)
	return result


func _new_hud(fixture: FlowFixture) -> GameHUD:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var packed: PackedScene = ResourceLoader.load(
		"res://scenes/ui/game_hud.tscn",
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE
	) as PackedScene
	var hud: GameHUD = packed.instantiate() as GameHUD
	viewport.add_child(hud)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(viewport)
	hud.present_flow_snapshot(fixture.flow.get_snapshot())
	hud.present_district_cards(fixture.cards.get_snapshot(), fixture.patrol.get_snapshot())
	return hud


func _first_valid_hud_target(hud: GameHUD) -> DistrictCardDragSlot:
	var targets: Array[DistrictCardDragSlot] = [
		hud.district_route_slot_01,
		hud.district_route_slot_02,
		hud.district_route_slot_03,
		hud.district_route_slot_04,
		hud.district_route_slot_05,
	]
	for target: DistrictCardDragSlot in targets:
		if target.is_valid_drop_target():
			return target
	return null


func _first_invalid_hud_target(hud: GameHUD) -> DistrictCardDragSlot:
	var targets: Array[DistrictCardDragSlot] = [
		hud.district_route_slot_01,
		hud.district_route_slot_02,
		hud.district_route_slot_03,
		hud.district_route_slot_04,
		hud.district_route_slot_05,
	]
	for target: DistrictCardDragSlot in targets:
		if target.is_drop_target_enabled() and not target.is_valid_drop_target():
			return target
	return null


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(absf(actual - expected) <= 0.001, "%s (expected %.3f, got %.3f)" % [context, expected, actual])


func _expect_contains(actual: String, expected: String, context: String) -> void:
	assert_contains(actual, expected, context)
