@tool
extends McpTestSuite

const CARD_CATALOGUE: DistrictCardCatalogue = preload(
	"res://data/cards/milestone_5_district_card_catalogue.tres"
)
const ROUTE_DEFINITION: PatrolRouteDefinition = preload(
	"res://data/routes/downtown_loop_route.tres"
)
const REQUIRED_CARD_IDS: Array[StringName] = [
	&"arcade",
	&"convenience_store",
	&"gang_hideout",
	&"subway_entrance",
]
const NON_CARD_STREAMS: Array[StringName] = [
	RunRandomStreams.STREAM_ENCOUNTERS,
	RunRandomStreams.STREAM_SPAWNS,
	RunRandomStreams.STREAM_REWARDS,
	RunRandomStreams.STREAM_EQUIPMENT,
	RunRandomStreams.STREAM_ENEMY_VARIANTS,
	RunRandomStreams.STREAM_COSMETIC,
]


func suite_name() -> String:
	return "milestone_5_card_system"


func test_catalogue_has_exactly_four_unique_stable_sorted_cards() -> void:
	_expect_equal(CARD_CATALOGUE.validation_errors().size(), 0, "catalogue: strict validation passes")
	_expect_equal(CARD_CATALOGUE.cards.size(), 4, "catalogue: exactly four authored cards")
	_expect_equal(CARD_CATALOGUE.get_sorted_ids(), REQUIRED_CARD_IDS, "catalogue: stable ID order")
	var seen_ids: Dictionary[StringName, bool] = {}
	var seen_effect_ids: Dictionary[StringName, bool] = {}
	var seen_icons: Dictionary[String, bool] = {}
	for card: DistrictCardDefinition in CARD_CATALOGUE.get_sorted_cards():
		_expect_true(_is_lower_snake_case(card.id), "catalogue: stable lowercase ID %s" % card.id)
		_expect_false(seen_ids.has(card.id), "catalogue: card ID %s is unique" % card.id)
		seen_ids[card.id] = true
		_expect_equal(CARD_CATALOGUE.get_by_id(card.id), card, "catalogue: lookup returns %s" % card.id)
		_expect_true(card.effect_definition != null, "catalogue: %s has typed effect" % card.id)
		if card.effect_definition != null:
			_expect_false(
				seen_effect_ids.has(card.effect_definition.id),
				"catalogue: effect ID %s is unique" % card.effect_definition.id
			)
			seen_effect_ids[card.effect_definition.id] = true
		var icon_path: String = card.icon.resource_path if card.icon != null else ""
		_expect_false(icon_path.is_empty(), "catalogue: %s icon has stable path" % card.id)
		_expect_false(seen_icons.has(icon_path), "catalogue: %s icon is distinct" % card.id)
		seen_icons[icon_path] = true
	_expect_equal(seen_ids.size(), 4, "catalogue: four unique card IDs observed")
	_expect_equal(seen_effect_ids.size(), 4, "catalogue: four unique effect IDs observed")
	_expect_equal(seen_icons.size(), 4, "catalogue: four distinct icons observed")


func test_required_card_fields_and_effect_payloads_are_exact() -> void:
	for card: DistrictCardDefinition in CARD_CATALOGUE.get_sorted_cards():
		_expect_equal(card.validation_errors().size(), 0, "%s: definition validates" % card.id)
		_expect_false(card.display_name.strip_edges().is_empty(), "%s: display name" % card.id)
		_expect_false(card.description.strip_edges().is_empty(), "%s: description" % card.id)
		_expect_true(card.icon != null, "%s: icon" % card.id)
		_expect_equal(card.cost, 0, "%s: zero authored cost" % card.id)
		_expect_equal(card.cost_label(), "FREE", "%s: player-facing FREE label" % card.id)
		_expect_equal(card.heat_delta, _expected_heat(card.id), "%s: exact Heat delta" % card.id)
		_expect_equal(card.valid_node_types.size(), 1, "%s: one target node type" % card.id)
		_expect_equal(
			card.valid_node_types[0],
			_expected_node_type(card.id),
			"%s: exact target node type" % card.id
		)
		_expect_equal(card.sorted_tags(), _expected_tags(card.id), "%s: exact tags" % card.id)
		_expect_false(
			card.progression_implications.strip_edges().is_empty(),
			"%s: progression implications" % card.id
		)
		var effect: CardEffectDefinition = card.effect_definition
		_expect_true(effect != null, "%s: typed effect exists" % card.id)
		if effect == null:
			continue
		_expect_equal(effect.validation_errors().size(), 0, "%s: effect validates" % card.id)
		_expect_equal(effect.id, _expected_effect_id(card.id), "%s: stable effect ID" % card.id)
		_expect_equal(effect.kind, _expected_effect_kind(card.id), "%s: effect kind" % card.id)
		_expect_false(effect.summary.strip_edges().is_empty(), "%s: effect summary" % card.id)
		_expect_false(effect.allows_card_reward, "%s: no recursive card reward" % card.id)

	var arcade: CardEffectDefinition = CARD_CATALOGUE.get_by_id(&"arcade").effect_definition
	_expect_equal(arcade.encounter_id, &"", "Arcade: baseline encounter selection")
	_expect_equal(arcade.reward_quality_tier_steps, 1, "Arcade: exactly one authored reward tier")
	_expect_equal(arcade.maximum_purchases, 0, "Arcade: no shop purchase")

	var store: CardEffectDefinition = CARD_CATALOGUE.get_by_id(&"convenience_store").effect_definition
	_expect_equal(store.maximum_purchases, 1, "Store: exactly one purchase")
	_expect_true(store.uses_existing_shop_stock, "Store: existing finite stock")
	_expect_false(store.guarantees_equipment_choice, "Store: no equipment guarantee")

	var hideout: CardEffectDefinition = CARD_CATALOGUE.get_by_id(&"gang_hideout").effect_definition
	_expect_equal(hideout.encounter_id, &"viper_signal", "Hideout: existing elite placeholder")
	_expect_true(hideout.guarantees_equipment_choice, "Hideout: guaranteed equipment")
	_expect_equal(hideout.reward_quality_tier_steps, 0, "Hideout: no standard quality mutation")

	var subway: CardEffectDefinition = CARD_CATALOGUE.get_by_id(&"subway_entrance").effect_definition
	_expect_true(subway.reroutes_next_segment, "Subway: reroutes next segment")
	_expect_equal(subway.baseline_standard_encounters_to_skip, 1, "Subway: exact one baseline skip")
	_expect_false(subway.consumes_subway_charge, "Subway: consumes no intervention charge")


func test_strict_resource_validation_rejects_every_required_bad_field() -> void:
	var source: DistrictCardDefinition = CARD_CATALOGUE.get_by_id(&"arcade")
	var invalid_id: DistrictCardDefinition = _clone_card(source)
	invalid_id.id = &"Arcade Bad"
	_expect_true(_has_error(invalid_id.validation_errors(), "lowercase snake_case"), "validation: stable ID")

	var missing_icon: DistrictCardDefinition = _clone_card(source)
	missing_icon.icon = null
	_expect_true(_has_error(missing_icon.validation_errors(), "has no icon"), "validation: icon required")

	var paid: DistrictCardDefinition = _clone_card(source)
	paid.cost = 1
	_expect_true(_has_error(paid.validation_errors(), "must be FREE"), "validation: M5 cost is zero")

	var no_heat: DistrictCardDefinition = _clone_card(source)
	no_heat.heat_delta = 0
	_expect_true(_has_error(no_heat.validation_errors(), "no authored Heat"), "validation: Heat required")

	var bad_node: DistrictCardDefinition = _clone_card(source)
	bad_node.valid_node_types = [&"shop"]
	_expect_true(_has_error(bad_node.validation_errors(), "invalid node type"), "validation: node type")

	var bad_tags: DistrictCardDefinition = _clone_card(source)
	bad_tags.tags = [&"fight"]
	_expect_true(_has_error(bad_tags.validation_errors(), "invalid tag"), "validation: stable tag")

	var recursive: DistrictCardDefinition = _clone_card(source)
	recursive.effect_definition.allows_card_reward = true
	_expect_true(_has_error(recursive.validation_errors(), "recursively"), "validation: recursion forbidden")

	var wrong_arcade_tier: DistrictCardDefinition = _clone_card(source)
	wrong_arcade_tier.effect_definition.reward_quality_tier_steps = 0
	_expect_true(
		_has_error(wrong_arcade_tier.validation_errors(), "exactly one authored reward tier"),
		"validation: Arcade exact tier step"
	)

	var wrong_catalogue: DistrictCardCatalogue = DistrictCardCatalogue.new()
	for card: DistrictCardDefinition in CARD_CATALOGUE.get_sorted_cards():
		wrong_catalogue.cards.append(_clone_card(card))
	wrong_catalogue.cards[0].heat_delta = 9
	_expect_true(
		_has_error(wrong_catalogue.validation_errors(), "Heat delta must be 10"),
		"validation: catalogue enforces exact authored Heat"
	)


func test_opening_draw_is_two_cards_from_one_copy_deck_with_capacity_three() -> void:
	var fixture: Dictionary = _new_fixture(5101)
	var cards: CardSystem = fixture["cards"] as CardSystem
	var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
	var snapshot: Dictionary = cards.get_snapshot()
	_expect_equal(CardSystem.OPENING_DRAW_COUNT, 2, "opening: authored draw count")
	_expect_equal(CardSystem.HAND_CAPACITY, 3, "opening: authored hand capacity")
	_expect_equal(snapshot["hand_count"], 2, "opening: two cards in hand")
	_expect_equal(snapshot["draw_count"], 2, "opening: two cards remain in draw pile")
	_expect_equal(snapshot["discard_count"], 0, "opening: discard starts empty")
	_expect_equal(snapshot["hand_revision"], 1, "opening: clean hand revision")
	_expect_true(bool(snapshot["no_reshuffle"]), "opening: no reshuffle contract exposed")
	_expect_false(bool(snapshot["reward_hand_full"]), "opening: hand has one free slot")
	var all_ids: Array[StringName] = _card_ids(cards.get_hand())
	all_ids.append_array(_card_ids(cards.get_draw_pile()))
	_expect_equal(all_ids.size(), 4, "opening: four total cards remain owned")
	for required_id: StringName in REQUIRED_CARD_IDS:
		_expect_equal(all_ids.count(required_id), 1, "opening: exactly one copy of %s" % required_id)
	_expect_equal(streams.get_draw_count(RunRandomStreams.STREAM_CARDS), 2, "opening: exactly two card draws")
	for stream_name: StringName in NON_CARD_STREAMS:
		_expect_equal(streams.get_draw_count(stream_name), 0, "opening: does not draw %s" % stream_name)


func test_valid_placement_moves_once_to_discard_and_resolves_once_at_future_node() -> void:
	var fixture: Dictionary = _new_fixture(5102)
	var cards: CardSystem = fixture["cards"] as CardSystem
	var patrol: PatrolController = fixture["patrol"] as PatrolController
	var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
	_expect_true(cards.begin_planning(true), "placement: planning opens")
	var card: DistrictCardDefinition = cards.get_hand()[0]
	var slot: RouteSlotSnapshot = _find_slot_for_card(patrol, card, true)
	_expect_true(slot != null, "placement: matching future slot exists")
	if slot == null:
		return
	var stream_before: Dictionary[StringName, Dictionary] = streams.capture_states()
	var staged: Dictionary = cards.stage_placement(
		card.id,
		slot.slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision()
	)
	_expect_true(bool(staged["accepted"]), "placement: valid stage accepted")
	_expect_equal(staged["reason"], &"ok", "placement: valid reason")
	var token: int = int(staged["confirmation_token"])
	_expect_true(token > 0, "placement: positive confirmation token")
	var record: CardPlacementRecord = cards.confirm_staged_placement(token)
	_expect_true(record != null, "placement: confirmation succeeds")
	if record == null:
		return
	_expect_equal(record.card.id, card.id, "placement: exact card recorded")
	_expect_equal(record.slot_id, slot.slot_id, "placement: exact stable slot recorded")
	_expect_equal(cards.get_hand().size(), 1, "placement: hand loses one card")
	_expect_equal(cards.get_discard_pile().size(), 1, "placement: discard gains one card")
	_expect_equal(cards.get_discard_pile()[0].id, card.id, "placement: exact card discarded")
	_expect_equal(cards.get_snapshot()["pending_route_effects"].size(), 1, "placement: one pending effect")
	_expect_equal(patrol.get_snapshot()["pending_route_modifications"].size(), 1, "placement: route owns one modification")
	_expect_equal(patrol.get_route_slot_status(slot.slot_id), PatrolController.SLOT_STATUS_OCCUPIED, "placement: slot occupied")
	_expect_equal(cards.confirm_staged_placement(token), null, "placement: duplicate confirmation rejected")
	_expect_equal(cards.get_discard_pile().size(), 1, "placement: duplicate cannot discard twice")
	_expect_equal(streams.capture_states(), stream_before, "placement: no random stream changes")
	_expect_equal(cards.resolve_current_route_effect(), null, "resolution: cannot resolve before target")
	_advance_patrol_to_occurrence(patrol, record.occurrence_index)
	var resolved: CardResolutionRecord = cards.resolve_current_route_effect()
	_expect_true(resolved != null, "resolution: resolves when exact future node is reached")
	if resolved != null:
		_expect_equal(resolved.placement_token, token, "resolution: exact token")
		_expect_equal(resolved.card.id, card.id, "resolution: exact card")
		_expect_equal(resolved.slot_id, slot.slot_id, "resolution: exact slot")
	_expect_equal(cards.resolve_current_route_effect(), null, "resolution: duplicate resolution rejected")
	_expect_equal(cards.get_snapshot()["pending_route_effects"].size(), 0, "resolution: pending effect cleared")
	_expect_equal(cards.get_snapshot()["resolved_route_effects"].size(), 1, "resolution: one history record")
	_expect_equal(patrol.get_snapshot()["pending_route_modifications"].size(), 0, "resolution: route pending cleared")
	_expect_equal(patrol.get_snapshot()["resolved_route_modifications"].size(), 1, "resolution: route history records once")
	_expect_equal(cards.get_discard_pile().size(), 1, "resolution: discard remains exactly once")


func test_wrong_invalid_and_outside_equivalent_drops_are_fully_atomic() -> void:
	var fixture: Dictionary = _new_fixture(5103)
	var cards: CardSystem = fixture["cards"] as CardSystem
	var patrol: PatrolController = fixture["patrol"] as PatrolController
	var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
	_expect_true(cards.begin_planning(false), "atomic drop: planning opens")
	var card: DistrictCardDefinition = cards.get_hand()[0]
	var wrong_slot: RouteSlotSnapshot = _find_slot_for_card(patrol, card, false)
	_expect_true(wrong_slot != null, "atomic drop: wrong-type slot exists")
	if wrong_slot != null:
		_assert_stage_rejection_atomic(
			cards,
			patrol,
			streams,
			card.id,
			wrong_slot.slot_id,
			cards.get_hand_revision(),
			patrol.get_route_revision(),
			&"wrong_node_type",
			"wrong node"
		)
	_assert_stage_rejection_atomic(
		cards,
		patrol,
		streams,
		&"missing_card",
		patrol.get_future_route_slots()[0].slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision(),
		&"card_not_in_hand",
		"invalid card"
	)
	_assert_stage_rejection_atomic(
		cards,
		patrol,
		streams,
		card.id,
		&"not_a_route_slot",
		cards.get_hand_revision(),
		patrol.get_route_revision(),
		PatrolController.SLOT_STATUS_INVALID,
		"invalid slot"
	)
	var before_outside: Dictionary = _capture_authority(cards, patrol, streams)
	var outside: Dictionary = cards.stage_placement(
		card.id,
		&"",
		cards.get_hand_revision(),
		patrol.get_route_revision()
	)
	_expect_false(bool(outside["accepted"]), "outside: empty destination rejected")
	_expect_equal(outside["reason"], PatrolController.SLOT_STATUS_INVALID, "outside: invalid reason")
	_expect_equal(_capture_authority(cards, patrol, streams), before_outside, "outside: all authority unchanged")

	# Compare the next valid token with an untouched twin. This covers the token
	# authority that is intentionally not exposed in CardSystem snapshots.
	var twin: Dictionary = _new_fixture(5103)
	var twin_cards: CardSystem = twin["cards"] as CardSystem
	var twin_patrol: PatrolController = twin["patrol"] as PatrolController
	twin_cards.begin_planning(false)
	var valid_slot: RouteSlotSnapshot = _find_slot_for_card(patrol, card, true)
	var twin_card: DistrictCardDefinition = twin_cards.get_hand_card_by_id(card.id)
	var twin_slot: RouteSlotSnapshot = _find_slot_for_card(twin_patrol, twin_card, true)
	var staged_after_outside: Dictionary = cards.stage_placement(
		card.id,
		valid_slot.slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision()
	)
	var staged_without_outside: Dictionary = twin_cards.stage_placement(
		twin_card.id,
		twin_slot.slot_id,
		twin_cards.get_hand_revision(),
		twin_patrol.get_route_revision()
	)
	_expect_equal(
		staged_after_outside["confirmation_token"],
		staged_without_outside["confirmation_token"],
		"outside: rejection consumes no confirmation token"
	)


func test_current_and_past_slot_rejections_are_fully_atomic() -> void:
	var fixture: Dictionary = _new_fixture(5104)
	var cards: CardSystem = fixture["cards"] as CardSystem
	var patrol: PatrolController = fixture["patrol"] as PatrolController
	var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
	patrol.set_simulation_enabled(true)
	patrol.step_patrol(ROUTE_DEFINITION.travel_seconds_per_segment)
	_expect_equal(patrol.get_current_occurrence_index(), 0, "current/past: first occurrence reached")
	_expect_true(cards.begin_planning(false), "current/past: planning opens")
	var card: DistrictCardDefinition = cards.get_hand()[0]
	var first_slot_id: StringName = _slot_id(0)
	_assert_stage_rejection_atomic(
		cards,
		patrol,
		streams,
		card.id,
		first_slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision(),
		PatrolController.SLOT_STATUS_CURRENT,
		"current slot"
	)
	_expect_true(patrol.continue_from_current_node(), "current/past: leave first occurrence")
	patrol.step_patrol(ROUTE_DEFINITION.travel_seconds_per_segment)
	_expect_equal(patrol.get_current_occurrence_index(), 1, "current/past: second occurrence reached")
	_assert_stage_rejection_atomic(
		cards,
		patrol,
		streams,
		card.id,
		first_slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision(),
		PatrolController.SLOT_STATUS_PAST,
		"past slot"
	)


func test_stale_and_occupied_slot_rejections_are_fully_atomic() -> void:
	var fixture: Dictionary = _new_fixture(5105)
	var cards: CardSystem = fixture["cards"] as CardSystem
	var patrol: PatrolController = fixture["patrol"] as PatrolController
	var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
	cards.begin_planning(false)
	var card: DistrictCardDefinition = cards.get_hand()[0]
	var slot: RouteSlotSnapshot = _find_slot_for_card(patrol, card, true)
	_assert_stage_rejection_atomic(
		cards,
		patrol,
		streams,
		card.id,
		slot.slot_id,
		cards.get_hand_revision() - 1,
		patrol.get_route_revision(),
		&"stale_hand_revision",
		"stale hand"
	)
	_assert_stage_rejection_atomic(
		cards,
		patrol,
		streams,
		card.id,
		slot.slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision() - 1,
		&"stale_route_revision",
		"stale route"
	)
	var staged: Dictionary = cards.stage_placement(
		card.id,
		slot.slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision()
	)
	var record: CardPlacementRecord = cards.confirm_staged_placement(
		int(staged["confirmation_token"])
	)
	_expect_true(record != null, "occupied: first card claims slot")
	var remaining_card: DistrictCardDefinition = cards.get_hand()[0]
	_assert_stage_rejection_atomic(
		cards,
		patrol,
		streams,
		remaining_card.id,
		slot.slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision(),
		PatrolController.SLOT_STATUS_OCCUPIED,
		"occupied slot"
	)
	_expect_equal(cards.get_discard_pile().size(), 1, "occupied: no stacking or second discard")
	_expect_equal(patrol.get_snapshot()["pending_route_modifications"].size(), 1, "occupied: one card per slot")


func test_card_rewards_are_finite_exactly_once_and_keep_full_hand() -> void:
	var fixture: Dictionary = _new_fixture(5106)
	var cards: CardSystem = fixture["cards"] as CardSystem
	var patrol: PatrolController = fixture["patrol"] as PatrolController
	var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
	var expected_candidates: Array[StringName] = _card_ids(cards.get_draw_pile())
	expected_candidates.sort_custom(_string_name_before)
	var choices: Array[DistrictCardDefinition] = cards.prepare_reward_choices(601)
	_expect_true(choices.size() > 0 and choices.size() <= CardSystem.REWARD_CHOICE_COUNT, "reward: up to three choices")
	_expect_equal(choices.size(), 2, "reward: only two cards remain after opening")
	_expect_equal(cards.get_last_reward_candidate_order(), expected_candidates, "reward: stable candidate order")
	_expect_equal(streams.get_draw_count(RunRandomStreams.STREAM_CARDS), 4, "reward: only two additional card draws")
	var token: int = cards.get_pending_reward_choice_token()
	var revision: int = cards.get_hand_revision()
	var selected: DistrictCardDefinition = cards.acquire_reward_choice(601, token, 0, revision)
	_expect_true(selected != null, "reward: first acquisition succeeds")
	_expect_equal(cards.get_hand().size(), CardSystem.HAND_CAPACITY, "reward: hand reaches cap three")
	_expect_equal(cards.get_draw_pile().size(), 1, "reward: selected card removed exactly once")
	var after_acquire: Dictionary = _capture_authority(cards, patrol, streams)
	_expect_equal(cards.acquire_reward_choice(601, token, 0, revision), null, "reward: duplicate acquisition rejected")
	_expect_equal(_capture_authority(cards, patrol, streams), after_acquire, "reward: duplicate acquisition is atomic")

	var full_choices: Array[DistrictCardDefinition] = cards.prepare_reward_choices(602)
	_expect_equal(full_choices.size(), 1, "reward: final remaining card offered")
	var full_token: int = cards.get_pending_reward_choice_token()
	var full_revision: int = cards.get_hand_revision()
	var before_full_apply: Dictionary = _capture_authority(cards, patrol, streams)
	_expect_equal(
		cards.acquire_reward_choice(602, full_token, 0, full_revision),
		null,
		"reward: full hand cannot acquire"
	)
	_expect_equal(_capture_authority(cards, patrol, streams), before_full_apply, "reward: full-hand rejection atomic")
	var kept_hand_ids: Array[StringName] = _card_ids(cards.get_hand())
	var kept_draw_ids: Array[StringName] = _card_ids(cards.get_draw_pile())
	var stream_before_skip: Dictionary[StringName, Dictionary] = streams.capture_states()
	_expect_true(cards.skip_reward_choice(602, full_token), "reward: Keep Hand skip succeeds")
	_expect_false(cards.skip_reward_choice(602, full_token), "reward: skip resolves exactly once")
	_expect_equal(_card_ids(cards.get_hand()), kept_hand_ids, "reward: skip keeps hand")
	_expect_equal(_card_ids(cards.get_draw_pile()), kept_draw_ids, "reward: skip keeps finite draw pile")
	_expect_equal(streams.capture_states(), stream_before_skip, "reward: skip consumes no random draw")

	_expect_true(cards.begin_planning(false), "reward: planning opens after modal closes")
	var placed: CardPlacementRecord = _place_first_available(cards, patrol)
	_expect_true(placed != null, "reward: playing a card frees one hand slot")
	_expect_true(cards.end_planning(), "reward: planning closes before reward source")
	var final_choices: Array[DistrictCardDefinition] = cards.prepare_reward_choices(603)
	_expect_equal(final_choices.size(), 1, "reward: skipped card remains the only candidate")
	var final_card: DistrictCardDefinition = cards.acquire_reward_choice(
		603,
		cards.get_pending_reward_choice_token(),
		0,
		cards.get_hand_revision()
	)
	_expect_true(final_card != null, "reward: remaining card acquired once capacity exists")
	_expect_equal(cards.get_draw_pile().size(), 0, "reward: finite draw pile exhausted")
	_expect_equal(cards.get_hand().size(), CardSystem.HAND_CAPACITY, "reward: hand returns to cap")
	_expect_true(cards.begin_planning(false), "reward: planning reopens for second play")
	_expect_true(_place_first_available(cards, patrol) != null, "reward: second play creates discard state")
	_expect_true(cards.end_planning(), "reward: second planning session closes")
	var draws_before_empty: Dictionary[StringName, Dictionary] = streams.capture_states()
	_expect_equal(cards.prepare_reward_choices(604).size(), 0, "reward: empty draw pile offers nothing")
	_expect_true(cards.get_discard_pile().size() >= 2, "reward: discard is non-empty")
	_expect_equal(streams.capture_states(), draws_before_empty, "reward: discard is never reshuffled or drawn")


func test_same_seed_reproduces_opening_and_reward_choices() -> void:
	var left: Dictionary = _new_fixture(5107)
	var right: Dictionary = _new_fixture(5107)
	var left_cards: CardSystem = left["cards"] as CardSystem
	var right_cards: CardSystem = right["cards"] as CardSystem
	var left_streams: RunRandomStreams = left["streams"] as RunRandomStreams
	var right_streams: RunRandomStreams = right["streams"] as RunRandomStreams
	_expect_equal(_card_ids(left_cards.get_hand()), _card_ids(right_cards.get_hand()), "same seed: opening order")
	var left_choices: Array[DistrictCardDefinition] = left_cards.prepare_reward_choices(701)
	var right_choices: Array[DistrictCardDefinition] = right_cards.prepare_reward_choices(701)
	_expect_equal(_card_ids(left_choices), _card_ids(right_choices), "same seed: reward choice order")
	_expect_equal(
		left_cards.get_last_reward_candidate_order(),
		right_cards.get_last_reward_candidate_order(),
		"same seed: stable candidate order"
	)
	_expect_equal(left_streams.capture_states(), right_streams.capture_states(), "same seed: every stream state")


func test_different_seeds_vary_over_documented_one_through_sixty_four_sample() -> void:
	var opening_signatures: Dictionary[String, bool] = {}
	var full_draw_signatures: Dictionary[String, bool] = {}
	for seed: int in range(1, 65):
		var fixture: Dictionary = _new_fixture(seed)
		var cards: CardSystem = fixture["cards"] as CardSystem
		var opening_signature: String = _card_signature(cards.get_hand())
		var choices: Array[DistrictCardDefinition] = cards.prepare_reward_choices(8000 + seed)
		var reward_signature: String = _card_signature(choices)
		opening_signatures[opening_signature] = true
		full_draw_signatures["%s|%s" % [opening_signature, reward_signature]] = true
	_expect_true(
		opening_signatures.size() >= 8,
		"variation seeds 1..64: at least 8 of 12 possible ordered opening hands (got %d)"
		% opening_signatures.size()
	)
	_expect_true(
		full_draw_signatures.size() >= 16,
		"variation seeds 1..64: at least 16 of 24 possible full finite-deck orders (got %d)"
		% full_draw_signatures.size()
	)


func test_cards_stream_is_isolated_from_cosmetic_and_every_gameplay_stream() -> void:
	var control: Dictionary = _new_fixture(5108)
	var control_cards: CardSystem = control["cards"] as CardSystem
	var control_streams: RunRandomStreams = control["streams"] as RunRandomStreams
	var control_opening: Array[StringName] = _card_ids(control_cards.get_hand())
	var control_choices: Array[StringName] = _card_ids(control_cards.prepare_reward_choices(801))
	var control_card_draws: int = control_streams.get_draw_count(RunRandomStreams.STREAM_CARDS)
	for stream_name: StringName in NON_CARD_STREAMS:
		_expect_equal(control_streams.get_draw_count(stream_name), 0, "isolation: cards do not draw %s" % stream_name)

	for perturbed_stream: StringName in NON_CARD_STREAMS:
		var fixture: Dictionary = _new_fixture(5108, perturbed_stream, 11)
		var cards: CardSystem = fixture["cards"] as CardSystem
		var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
		for _draw_index: int in range(13):
			streams.draw_index(perturbed_stream, 97)
		_expect_equal(_card_ids(cards.get_hand()), control_opening, "isolation: %s leaves opening" % perturbed_stream)
		_expect_equal(
			_card_ids(cards.prepare_reward_choices(801)),
			control_choices,
			"isolation: %s leaves reward choices" % perturbed_stream
		)
		_expect_equal(
			streams.get_draw_count(RunRandomStreams.STREAM_CARDS),
			control_card_draws,
			"isolation: %s leaves cards draw count" % perturbed_stream
		)
		_expect_equal(streams.get_draw_count(perturbed_stream), 24, "isolation: perturbation was consumed")


func test_clean_same_seed_restart_clears_all_card_and_route_state() -> void:
	var fixture: Dictionary = _new_fixture(5109)
	var cards: CardSystem = fixture["cards"] as CardSystem
	var patrol: PatrolController = fixture["patrol"] as PatrolController
	var streams: RunRandomStreams = fixture["streams"] as RunRandomStreams
	var original_opening: Array[StringName] = _card_ids(cards.get_hand())
	_expect_true(cards.prepare_reward_choices(901).size() > 0, "restart setup: pending reward modal")
	streams.reset_for_seed(5109)
	patrol.reset_patrol()
	_expect_true(cards.reset_for_run(), "restart setup: first reset clears reward modal")
	_expect_equal(cards.get_pending_reward_encounter_id(), -1, "restart setup: reward encounter cleared")
	_expect_equal(cards.get_pending_reward_choice_token(), -1, "restart setup: reward token cleared")

	_expect_true(cards.begin_planning(true), "restart setup: planning opens")
	_expect_true(_place_first_available(cards, patrol) != null, "restart setup: pending route effect")
	var staged_card: DistrictCardDefinition = cards.get_hand()[0]
	var staged_slot: RouteSlotSnapshot = _find_slot_for_card(patrol, staged_card, true)
	var staged: Dictionary = cards.stage_placement(
		staged_card.id,
		staged_slot.slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision()
	)
	_expect_true(bool(staged["accepted"]), "restart setup: staged confirmation")
	_expect_true(cards.get_discard_pile().size() > 0, "restart setup: discard populated")
	_expect_true(cards.get_snapshot()["pending_route_effects"].size() > 0, "restart setup: card effect pending")
	_expect_true(patrol.get_snapshot()["pending_route_modifications"].size() > 0, "restart setup: route mutation pending")

	streams.reset_for_seed(5109)
	patrol.reset_patrol()
	_expect_true(cards.reset_for_run(), "restart: CardSystem resets from same seed")
	var card_snapshot: Dictionary = cards.get_snapshot()
	var patrol_snapshot: Dictionary = patrol.get_snapshot()
	_expect_equal(_card_ids(cards.get_hand()), original_opening, "restart: deterministic opening restored")
	_expect_equal(card_snapshot["hand_count"], 2, "restart: two-card hand")
	_expect_equal(card_snapshot["draw_count"], 2, "restart: two-card draw pile")
	_expect_equal(card_snapshot["discard_count"], 0, "restart: discard cleared")
	_expect_equal(card_snapshot["pending_route_effects"].size(), 0, "restart: pending card effects cleared")
	_expect_equal(card_snapshot["resolved_route_effects"].size(), 0, "restart: resolved history cleared")
	_expect_equal(card_snapshot["pending_reward_encounter_id"], -1, "restart: reward modal cleared")
	_expect_equal(card_snapshot["pending_reward_choice_token"], -1, "restart: reward token cleared")
	_expect_equal(card_snapshot["staged_confirmation_token"], -1, "restart: confirmation cleared")
	_expect_false(bool(card_snapshot["planning_active"]), "restart: planning state cleared")
	_expect_equal(patrol_snapshot["route_index"], -1, "restart: route returns before first occurrence")
	_expect_equal(patrol_snapshot["current_occurrence_index"], -1, "restart: occurrence identity clears")
	_expect_equal(patrol_snapshot["pending_route_modifications"].size(), 0, "restart: route modifications clear")
	_expect_equal(patrol_snapshot["resolved_route_modifications"].size(), 0, "restart: route history clears")
	_expect_equal(streams.get_draw_count(RunRandomStreams.STREAM_CARDS), 2, "restart: cards stream restarts at opening")
	for stream_name: StringName in NON_CARD_STREAMS:
		_expect_equal(streams.get_draw_count(stream_name), 0, "restart: %s stream remains clean" % stream_name)

	cards.begin_planning(false)
	var fresh_card: DistrictCardDefinition = cards.get_hand()[0]
	var fresh_slot: RouteSlotSnapshot = _find_slot_for_card(patrol, fresh_card, true)
	var fresh_stage: Dictionary = cards.stage_placement(
		fresh_card.id,
		fresh_slot.slot_id,
		cards.get_hand_revision(),
		patrol.get_route_revision()
	)
	_expect_equal(fresh_stage["confirmation_token"], 1, "restart: confirmation token restarts cleanly")


func _new_fixture(
	seed: int,
	perturbed_stream: StringName = &"",
	perturbation_draws: int = 0
) -> Dictionary:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams._ready()
	streams.reset_for_seed(seed)
	if perturbed_stream != &"":
		for _draw_index: int in range(maxi(perturbation_draws, 0)):
			streams.draw_index(perturbed_stream, 97)
	var patrol: PatrolController = track(PatrolController.new()) as PatrolController
	patrol.route_definition = ROUTE_DEFINITION
	patrol._ready()
	patrol.set_process(false)
	patrol.start_patrol()
	var cards: CardSystem = track(CardSystem.new()) as CardSystem
	cards.catalogue = CARD_CATALOGUE
	cards.configure(streams, patrol)
	cards.reset_for_run()
	return {
		"streams": streams,
		"patrol": patrol,
		"cards": cards,
	}


func _capture_authority(
	cards: CardSystem,
	patrol: PatrolController,
	streams: RunRandomStreams
) -> Dictionary:
	return {
		"cards": _card_authority_snapshot(cards),
		"patrol": patrol.get_snapshot(),
		"streams": streams.capture_states(),
	}


func _card_authority_snapshot(cards: CardSystem) -> Dictionary:
	var snapshot: Dictionary = cards.get_snapshot()
	var pending_choice_ids: Array[StringName] = []
	for choice: DistrictCardDefinition in cards.get_pending_reward_choices():
		if choice != null:
			pending_choice_ids.append(choice.id)
	return {
		"hand_ids": snapshot["hand_ids"],
		"draw_ids": snapshot["draw_ids"],
		"discard_ids": snapshot["discard_ids"],
		"hand_count": snapshot["hand_count"],
		"hand_capacity": snapshot["hand_capacity"],
		"draw_count": snapshot["draw_count"],
		"discard_count": snapshot["discard_count"],
		"hand_revision": snapshot["hand_revision"],
		"planning_active": snapshot["planning_active"],
		"planning_owns_pause": snapshot["planning_owns_pause"],
		"staged_confirmation_token": snapshot["staged_confirmation_token"],
		"staged_card_id": snapshot["staged_card_id"],
		"staged_slot_id": snapshot["staged_slot_id"],
		"pending_route_effects": snapshot["pending_route_effects"],
		"resolved_route_effects": snapshot["resolved_route_effects"],
		"pending_reward_encounter_id": snapshot["pending_reward_encounter_id"],
		"pending_reward_choice_token": snapshot["pending_reward_choice_token"],
		"pending_reward_choice_ids": pending_choice_ids,
		"reward_hand_full": snapshot["reward_hand_full"],
		"no_reshuffle": snapshot["no_reshuffle"],
		"last_reward_candidate_order": cards.get_last_reward_candidate_order(),
	}


func _assert_stage_rejection_atomic(
	cards: CardSystem,
	patrol: PatrolController,
	streams: RunRandomStreams,
	card_id: StringName,
	slot_id: StringName,
	hand_revision: int,
	route_revision: int,
	expected_reason: StringName,
	context: String
) -> void:
	var before: Dictionary = _capture_authority(cards, patrol, streams)
	var result: Dictionary = cards.stage_placement(
		card_id,
		slot_id,
		hand_revision,
		route_revision
	)
	_expect_false(bool(result["accepted"]), "%s: rejected" % context)
	_expect_equal(result["reason"], expected_reason, "%s: exact reason" % context)
	_expect_equal(_capture_authority(cards, patrol, streams), before, "%s: full authority unchanged" % context)


func _find_slot_for_card(
	patrol: PatrolController,
	card: DistrictCardDefinition,
	should_match: bool
) -> RouteSlotSnapshot:
	if card == null:
		return null
	for slot: RouteSlotSnapshot in patrol.get_future_route_slots():
		if slot.status != PatrolController.SLOT_STATUS_VALID:
			continue
		var matches: bool = card.supports_node_type(slot.node_type)
		if matches == should_match:
			return slot
	return null


func _place_first_available(
	cards: CardSystem,
	patrol: PatrolController
) -> CardPlacementRecord:
	for card: DistrictCardDefinition in cards.get_hand():
		var slot: RouteSlotSnapshot = _find_slot_for_card(patrol, card, true)
		if slot == null:
			continue
		var staged: Dictionary = cards.stage_placement(
			card.id,
			slot.slot_id,
			cards.get_hand_revision(),
			patrol.get_route_revision()
		)
		if bool(staged.get("accepted", false)):
			return cards.confirm_staged_placement(int(staged["confirmation_token"]))
	return null


func _advance_patrol_to_occurrence(patrol: PatrolController, occurrence_index: int) -> void:
	patrol.set_simulation_enabled(true)
	while patrol.get_current_occurrence_index() < occurrence_index:
		if patrol.get_current_occurrence_index() >= 0:
			patrol.continue_from_current_node()
		patrol.step_patrol(ROUTE_DEFINITION.travel_seconds_per_segment)


func _clone_card(source: DistrictCardDefinition) -> DistrictCardDefinition:
	var result: DistrictCardDefinition = DistrictCardDefinition.new()
	result.id = source.id
	result.display_name = source.display_name
	result.description = source.description
	result.icon = source.icon
	result.cost = source.cost
	result.heat_delta = source.heat_delta
	result.valid_node_types = source.valid_node_types.duplicate()
	result.tags = source.tags.duplicate()
	result.progression_implications = source.progression_implications
	result.effect_definition = _clone_effect(source.effect_definition)
	return result


func _clone_effect(source: CardEffectDefinition) -> CardEffectDefinition:
	var result: CardEffectDefinition = CardEffectDefinition.new()
	result.id = source.id
	result.summary = source.summary
	result.kind = source.kind
	result.encounter_id = source.encounter_id
	result.reward_quality_tier_steps = source.reward_quality_tier_steps
	result.maximum_purchases = source.maximum_purchases
	result.uses_existing_shop_stock = source.uses_existing_shop_stock
	result.guarantees_equipment_choice = source.guarantees_equipment_choice
	result.reroutes_next_segment = source.reroutes_next_segment
	result.baseline_standard_encounters_to_skip = source.baseline_standard_encounters_to_skip
	result.consumes_subway_charge = source.consumes_subway_charge
	result.allows_card_reward = source.allows_card_reward
	return result


func _card_ids(cards: Array[DistrictCardDefinition]) -> Array[StringName]:
	var result: Array[StringName] = []
	for card: DistrictCardDefinition in cards:
		if card != null:
			result.append(card.id)
	return result


func _card_signature(cards: Array[DistrictCardDefinition]) -> String:
	var ids: PackedStringArray = PackedStringArray()
	for card: DistrictCardDefinition in cards:
		if card != null:
			ids.append(String(card.id))
	return ",".join(ids)


func _slot_id(occurrence_index: int) -> StringName:
	return StringName("%s::route_slot::%d" % [ROUTE_DEFINITION.id, occurrence_index])


func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for message: String in errors:
		if fragment in message:
			return true
	return false


func _is_lower_snake_case(value: StringName) -> bool:
	var text: String = String(value)
	return (
		not text.is_empty()
		and text == text.to_lower()
		and text == text.to_snake_case()
		and not text.begins_with("_")
		and not text.ends_with("_")
	)


func _expected_heat(card_id: StringName) -> int:
	match card_id:
		&"arcade":
			return 10
		&"convenience_store":
			return -10
		&"gang_hideout":
			return 20
		&"subway_entrance":
			return -15
	return 0


func _expected_node_type(card_id: StringName) -> StringName:
	return (
		DistrictCardDefinition.NODE_TYPE_TRAVEL
		if card_id == &"arcade" or card_id == &"convenience_store"
		else DistrictCardDefinition.NODE_TYPE_ENCOUNTER
	)


func _expected_tags(card_id: StringName) -> Array[StringName]:
	match card_id:
		&"arcade":
			return [&"FIGHT", &"REWARD"]
		&"convenience_store":
			return [&"RECOVERY", &"SHOP"]
		&"gang_hideout":
			return [&"ELITE", &"EQUIPMENT"]
		&"subway_entrance":
			return [&"REROUTE", &"SKIP"]
	var empty_result: Array[StringName] = []
	return empty_result


func _expected_effect_id(card_id: StringName) -> StringName:
	match card_id:
		&"arcade":
			return &"arcade_standard_encounter_reward_boost"
		&"convenience_store":
			return &"convenience_store_existing_stock_purchase"
		&"gang_hideout":
			return &"gang_hideout_viper_signal_elite"
		&"subway_entrance":
			return &"subway_entrance_reroute_skip"
	return &""


func _expected_effect_kind(card_id: StringName) -> int:
	match card_id:
		&"arcade":
			return CardEffectDefinition.EffectKind.ADD_STANDARD_ENCOUNTER
		&"convenience_store":
			return CardEffectDefinition.EffectKind.OPEN_ONE_PURCHASE_SHOP
		&"gang_hideout":
			return CardEffectDefinition.EffectKind.ADD_ELITE_ENCOUNTER
		&"subway_entrance":
			return CardEffectDefinition.EffectKind.REROUTE_SKIP_STANDARD
	return -1


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)
