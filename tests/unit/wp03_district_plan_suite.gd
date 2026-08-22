@tool
extends McpTestSuite

const CARD_CATALOGUE: DistrictCardCatalogue = preload(
	"res://data/cards/milestone_5_district_card_catalogue.tres"
)
const ROUTE_DEFINITION: PatrolRouteDefinition = preload(
	"res://data/routes/downtown_loop_route.tres"
)
const ALL_CARD_IDS: Array[StringName] = [
	&"arcade",
	&"convenience_store",
	&"gang_hideout",
	&"subway_entrance",
]
const PRODUCTION_CARD_IDS: Array[StringName] = [
	&"arcade",
	&"convenience_store",
	&"subway_entrance",
]


func suite_name() -> String:
	return "wp03_district_plan"


func test_focused_offer_is_cards_stream_only_and_seed_locked() -> void:
	var first: Dictionary = _new_fixture(30301, ALL_CARD_IDS)
	var second: Dictionary = _new_fixture(30301, ALL_CARD_IDS)
	var perturbed: Dictionary = _new_fixture(30301, ALL_CARD_IDS, 19)
	var first_cards: CardSystem = first.cards as CardSystem
	var second_cards: CardSystem = second.cards as CardSystem
	var perturbed_cards: CardSystem = perturbed.cards as CardSystem

	assert_eq(first_cards.get_snapshot().get("offer_count"), 0, "offer: INTRO performs no hidden draw")
	assert_eq(
		(first.streams as RunRandomStreams).get_draw_count(RunRandomStreams.STREAM_CARDS),
		0,
		"offer: cards stream begins untouched"
	)
	assert_true(first_cards.begin_focused_district_plan(_plan_snapshot(1, 1, 4), true), "offer: first PLAN opens")
	assert_true(second_cards.begin_focused_district_plan(_plan_snapshot(1, 1, 4), true), "offer: repeat PLAN opens")
	assert_true(perturbed_cards.begin_focused_district_plan(_plan_snapshot(1, 1, 4), true), "offer: cosmetic-perturbed PLAN opens")
	var offer_ids: Array[StringName] = _snapshot_ids(first_cards.get_snapshot(), "offer_ids")
	print("WP03_LOCKED_SEED_30301_OFFER=" + JSON.stringify(offer_ids))
	assert_eq(offer_ids.size(), 2, "offer: focused choice is exactly two cards")
	assert_eq(offer_ids, _snapshot_ids(second_cards.get_snapshot(), "offer_ids"), "offer: same seed repeats exact vector")
	assert_eq(offer_ids, _snapshot_ids(perturbed_cards.get_snapshot(), "offer_ids"), "offer: cosmetic draws cannot perturb cards")
	assert_eq(offer_ids, [&"gang_hideout", &"subway_entrance"], "offer: seed 30301 vector is locked (%s)" % [offer_ids])
	assert_eq((first.streams as RunRandomStreams).get_draw_count(RunRandomStreams.STREAM_CARDS), 2, "offer: exactly two cards draws")
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		if stream_name == RunRandomStreams.STREAM_CARDS:
			continue
		assert_eq(
			(first.streams as RunRandomStreams).get_draw_count(stream_name),
			0,
			"offer: %s remains untouched" % stream_name
		)
	assert_eq((first.streams as RunRandomStreams).get_random_schema_version(), 1, "offer: random schema remains version 1")


func test_lap_deck_is_one_copy_without_replacement_and_archives_a_clear_trail() -> void:
	var fixture: Dictionary = _new_fixture(30302, PRODUCTION_CARD_IDS)
	var cards: CardSystem = fixture.cards as CardSystem
	var selected_ids: Array[StringName] = []
	var first_offer: Array[StringName] = []
	for block_index: int in range(1, 4):
		var lifecycle_revision: int = 10 + block_index
		assert_true(
			cards.begin_focused_district_plan(
				_plan_snapshot(1, block_index, lifecycle_revision),
				true
			),
			"lap deck: block %d PLAN opens" % block_index
		)
		var before: Array[StringName] = _snapshot_ids(cards.get_snapshot(), "offer_ids")
		if block_index == 1:
			first_offer = before.duplicate()
		assert_eq(before.size(), 2 if block_index < 3 else 1, "lap deck: offer shrinks only after finite deck exhausts")
		var selected_id: StringName = before[0]
		var unselected_id: StringName = before[1] if before.size() > 1 else &""
		var record: CardPlacementRecord = _select(cards, selected_id, 1, block_index, lifecycle_revision)
		assert_true(record != null, "lap deck: block %d selection confirms" % block_index)
		selected_ids.append(selected_id)
		var after: Array[StringName] = _snapshot_ids(cards.get_snapshot(), "offer_ids")
		if unselected_id != &"":
			assert_true(after.has(unselected_id), "lap deck: unselected choice remains available")
		assert_true(cards.end_planning(), "lap deck: confirmed PLAN closes")
		var occurrence_id: StringName = StringName("wp03_occurrence_%02d" % block_index)
		var resolved: CardResolutionRecord = cards.resolve_focused_district_plan_block(
			block_index,
			occurrence_id,
			block_index,
			StringName("route_node_%02d" % block_index),
			&"travel",
			_block_snapshot(1, block_index, lifecycle_revision + 1, occurrence_id)
		)
		assert_true(resolved != null, "lap deck: selected consequence resolves exactly once")
		assert_eq(
			cards.resolve_focused_district_plan_block(
				block_index,
				occurrence_id,
				block_index,
				&"duplicate",
				&"travel",
				_block_snapshot(1, block_index, lifecycle_revision + 1, occurrence_id)
			),
			null,
			"lap deck: resolution replay rejects"
		)
		assert_true(cards.complete_focused_district_plan_block(1, block_index), "lap deck: block completes")

	assert_eq(selected_ids.size(), PRODUCTION_CARD_IDS.size(), "lap deck: three selections recorded")
	for required_id: StringName in PRODUCTION_CARD_IDS:
		assert_eq(selected_ids.count(required_id), 1, "lap deck: %s consumed exactly once" % required_id)
	assert_eq((fixture.streams as RunRandomStreams).get_draw_count(RunRandomStreams.STREAM_CARDS), 3, "lap deck: no replacement or hidden fourth draw")
	assert_true(cards.begin_focused_district_plan(_plan_snapshot(2, 1, 30), true), "lap deck: next lap rebuilds")
	var next_snapshot: Dictionary = cards.get_snapshot()
	assert_eq(next_snapshot.get("lap_selected_count"), 0, "lap deck: next lap selection pile starts clean")
	assert_eq(next_snapshot.get("offer_count"), 2, "lap deck: next lap refills two-card offer")
	assert_eq(next_snapshot.get("lap_deck_remaining"), 1, "lap deck: one accessible card remains behind offer")
	var archived: Array = next_snapshot.get("archived_lap_history", []) as Array
	assert_eq(archived.size(), 1, "history: previous lap archived once")
	if not archived.is_empty():
		assert_eq((archived[0] as Dictionary).get("lap_id"), &"district_lap_01", "history: stable lap ID retained")
		assert_eq(((archived[0] as Dictionary).get("history", []) as Array).size(), 3, "history: three resolved block consequences retained")
	assert_eq(first_offer.size(), 2, "lap deck: original offer evidence retained in test")


func test_revision_context_and_replay_rejections_are_atomic() -> void:
	var fixture: Dictionary = _new_fixture(30303, ALL_CARD_IDS)
	var cards: CardSystem = fixture.cards as CardSystem
	var streams: RunRandomStreams = fixture.streams as RunRandomStreams
	var plan: Dictionary = _plan_snapshot(1, 1, 7)
	assert_true(cards.begin_focused_district_plan(plan, true), "atomic: PLAN opens")
	var snapshot: Dictionary = cards.get_snapshot()
	var card_id: StringName = _snapshot_ids(snapshot, "offer_ids")[0]
	var clean_cards: Dictionary = _focused_authority(cards)
	var clean_streams: Dictionary[StringName, Dictionary] = streams.capture_states()
	var rejection_vectors: Array[Dictionary] = [
		{"offer": int(snapshot.offer_revision) - 1, "life": 7, "lap": &"district_lap_01", "block": &"district_lap_01::block_01", "reason": &"stale_offer_revision"},
		{"offer": int(snapshot.offer_revision), "life": 6, "lap": &"district_lap_01", "block": &"district_lap_01::block_01", "reason": &"stale_lifecycle_revision"},
		{"offer": int(snapshot.offer_revision), "life": 7, "lap": &"district_lap_02", "block": &"district_lap_01::block_01", "reason": &"wrong_lap"},
		{"offer": int(snapshot.offer_revision), "life": 7, "lap": &"district_lap_01", "block": &"district_lap_01::block_02", "reason": &"wrong_block"},
		{"offer": int(snapshot.offer_revision), "life": 7, "lap": &"district_lap_01", "block": &"district_lap_01::block_01", "card": &"missing", "reason": &"card_not_offered"},
	]
	for vector: Dictionary in rejection_vectors:
		var result: Dictionary = cards.stage_focused_district_plan_choice(
			StringName(vector.get("card", card_id)),
			int(vector.offer),
			int(vector.life),
			StringName(vector.lap),
			StringName(vector.block)
		)
		assert_false(bool(result.accepted), "atomic: %s rejects" % vector.reason)
		assert_eq(result.reason, vector.reason, "atomic: exact rejection reason")
		assert_eq(_focused_authority(cards), clean_cards, "atomic: rejected stage changes no card authority")
		assert_eq(streams.capture_states(), clean_streams, "atomic: rejected stage changes no stream")

	var staged: Dictionary = cards.stage_focused_district_plan_choice(
		card_id,
		int(snapshot.offer_revision),
		7,
		&"district_lap_01",
		&"district_lap_01::block_01"
	)
	assert_true(bool(staged.accepted), "atomic: exact context stages")
	var before_race: Dictionary = _focused_authority(cards)
	var raced: Dictionary = plan.duplicate(true)
	raced.lifecycle_revision = 8
	assert_eq(cards.confirm_focused_district_plan_choice(int(staged.confirmation_token), raced), null, "atomic: transition race rejects")
	var after_race: Dictionary = _focused_authority(cards)
	assert_eq(after_race.offer_ids, before_race.offer_ids, "atomic: race preserves offer")
	assert_eq(after_race.history, before_race.history, "atomic: race preserves history")
	assert_eq(after_race.selected, before_race.selected, "atomic: race preserves selected block")
	assert_eq(streams.capture_states(), clean_streams, "atomic: race changes no stream")

	var restaged: Dictionary = cards.stage_focused_district_plan_choice(
		card_id,
		int(snapshot.offer_revision),
		7,
		&"district_lap_01",
		&"district_lap_01::block_01"
	)
	var confirmed: CardPlacementRecord = cards.confirm_focused_district_plan_choice(int(restaged.confirmation_token), plan)
	assert_true(confirmed != null, "atomic: valid confirmation succeeds")
	var accepted_authority: Dictionary = _focused_authority(cards)
	var accepted_streams: Dictionary[StringName, Dictionary] = streams.capture_states()
	assert_eq(cards.confirm_focused_district_plan_choice(int(restaged.confirmation_token), plan), null, "atomic: confirmation replay rejects")
	assert_eq(_focused_authority(cards), accepted_authority, "atomic: replay changes no authority")
	assert_eq(streams.capture_states(), accepted_streams, "atomic: replay changes no stream")


func test_restart_and_menu_cleanup_clear_every_focused_ledger() -> void:
	var fixture: Dictionary = _new_fixture(30304, ALL_CARD_IDS)
	var cards: CardSystem = fixture.cards as CardSystem
	var streams: RunRandomStreams = fixture.streams as RunRandomStreams
	var plan: Dictionary = _plan_snapshot(1, 1, 3)
	assert_true(cards.begin_focused_district_plan(plan, true), "cleanup: initial PLAN opens")
	var first_offer: Array[StringName] = _snapshot_ids(cards.get_snapshot(), "offer_ids")
	var record: CardPlacementRecord = _select(cards, first_offer[0], 1, 1, 3)
	assert_true(record != null, "cleanup: selection exists before restart")
	assert_true(cards.end_planning(), "cleanup: planning closes")

	streams.reset_for_seed(30304)
	assert_true(cards.reset_for_run(), "restart: focused authority resets")
	var reset_snapshot: Dictionary = cards.get_snapshot()
	assert_eq(reset_snapshot.get("offer_count"), 0, "restart: no stale offer before PLAN")
	assert_eq(reset_snapshot.get("offer_revision"), 0, "restart: revision resets")
	assert_eq(reset_snapshot.get("staged_confirmation_token"), -1, "restart: staged token clears")
	assert_true((reset_snapshot.get("selected_next_block", {}) as Dictionary).is_empty(), "restart: selected block clears")
	assert_true((reset_snapshot.get("active_block", {}) as Dictionary).is_empty(), "restart: active consequence clears")
	assert_true((reset_snapshot.get("current_lap_history", []) as Array).is_empty(), "restart: lap history clears")
	assert_true((reset_snapshot.get("archived_lap_history", []) as Array).is_empty(), "restart: archive clears")
	assert_true(cards.begin_focused_district_plan(plan, true), "restart: same PLAN opens again")
	assert_eq(_snapshot_ids(cards.get_snapshot(), "offer_ids"), first_offer, "restart: same seed reproduces exact offer")
	var fresh_stage: Dictionary = cards.stage_focused_district_plan_choice(
		first_offer[0],
		int(cards.get_snapshot().offer_revision),
		3,
		&"district_lap_01",
		&"district_lap_01::block_01"
	)
	assert_eq(fresh_stage.get("confirmation_token"), 1, "restart: token ledger restarts at one")

	cards.clear_for_main_menu()
	var cleared: Dictionary = cards.get_snapshot()
	assert_eq(cleared.get("offer_count"), 0, "menu: offer clears")
	assert_eq(cleared.get("lap_index"), -1, "menu: lap context clears")
	assert_eq(cleared.get("block_id"), &"", "menu: block context clears")
	assert_false(bool(cleared.get("planning_active", true)), "menu: planning latch clears")
	assert_true((cleared.get("current_lap_history", []) as Array).is_empty(), "menu: current history clears")
	assert_true((cleared.get("archived_lap_history", []) as Array).is_empty(), "menu: archived history clears")


func test_authored_cards_map_to_predictable_next_block_language() -> void:
	var expected: Dictionary[StringName, Dictionary] = {
		&"arcade": {"kind": &"fight", "type": "FIGHT + REWARD", "heat": 10, "special": "standard fight"},
		&"convenience_store": {"kind": &"shop", "type": "SHOP + RECOVERY", "heat": -10, "special": "one purchase"},
		&"gang_hideout": {"kind": &"elite", "type": "ELITE + GEAR", "heat": 20, "special": "gear choice"},
		&"subway_entrance": {"kind": &"utility", "type": "TRANSIT + COOLING", "heat": -15, "special": "replaces one baseline fight"},
	}
	for card_id: StringName in ALL_CARD_IDS:
		var card: DistrictCardDefinition = CARD_CATALOGUE.get_by_id(card_id)
		var contract: Dictionary = expected[card_id]
		assert_eq(CardSystem.focused_block_kind(card), contract.kind, "%s: exact authority kind" % card_id)
		assert_eq(CardSystem.focused_block_type(card), contract.type, "%s: exact visible block type" % card_id)
		assert_eq(card.heat_delta, contract.heat, "%s: exact Heat delta" % card_id)
		assert_contains(CardSystem.focused_special_rule(card).to_lower(), String(contract.special), "%s: named special consequence" % card_id)
		assert_false(card.progression_implications.strip_edges().is_empty(), "%s: payoff/risk copy exists" % card_id)


func _new_fixture(
	seed: int,
	allowed_ids: Array[StringName],
	cosmetic_perturbation: int = 0
) -> Dictionary:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams._ready()
	streams.reset_for_seed(seed)
	for _draw_index: int in range(cosmetic_perturbation):
		streams.draw_index(RunRandomStreams.STREAM_COSMETIC, 97)
	var patrol: PatrolController = track(PatrolController.new()) as PatrolController
	patrol.route_definition = ROUTE_DEFINITION
	patrol._ready()
	patrol.set_process(false)
	patrol.start_patrol()
	var cards: CardSystem = track(CardSystem.new()) as CardSystem
	cards.catalogue = CARD_CATALOGUE
	cards.configure(streams, patrol)
	cards.configure_run_access(allowed_ids)
	cards.configure_focused_district_plan(true)
	assert_true(cards.reset_for_run(), "fixture: focused cards initialize")
	return {"streams": streams, "patrol": patrol, "cards": cards}


func _plan_snapshot(lap_index: int, block_index: int, revision: int) -> Dictionary:
	return {
		"phase_name": "PLAN",
		"lap_index": lap_index,
		"lap_id": StringName("district_lap_%02d" % lap_index),
		"block_index": block_index,
		"block_id": StringName("district_lap_%02d::block_%02d" % [lap_index, block_index]),
		"lifecycle_revision": revision,
	}


func _block_snapshot(
	lap_index: int,
	block_index: int,
	revision: int,
	occurrence_id: StringName
) -> Dictionary:
	var result: Dictionary = _plan_snapshot(lap_index, block_index, revision)
	result.phase_name = "BLOCK"
	result.current_route_occurrence_id = occurrence_id
	return result


func _select(
	cards: CardSystem,
	card_id: StringName,
	lap_index: int,
	block_index: int,
	lifecycle_revision: int
) -> CardPlacementRecord:
	var snapshot: Dictionary = cards.get_snapshot()
	var staged: Dictionary = cards.stage_focused_district_plan_choice(
		card_id,
		int(snapshot.get("offer_revision", -1)),
		lifecycle_revision,
		StringName("district_lap_%02d" % lap_index),
		StringName("district_lap_%02d::block_%02d" % [lap_index, block_index])
	)
	if not bool(staged.get("accepted", false)):
		return null
	return cards.confirm_focused_district_plan_choice(
		int(staged.get("confirmation_token", -1)),
		_plan_snapshot(lap_index, block_index, lifecycle_revision)
	)


func _snapshot_ids(snapshot: Dictionary, key: String) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in snapshot.get(key, []):
		result.append(StringName(value))
	return result


func _focused_authority(cards: CardSystem) -> Dictionary:
	var snapshot: Dictionary = cards.get_snapshot()
	return {
		"offer_ids": _snapshot_ids(snapshot, "offer_ids"),
		"deck_ids": _snapshot_ids(snapshot, "lap_deck_ids"),
		"selected_ids": _snapshot_ids(snapshot, "lap_selected_ids"),
		"offer_revision": int(snapshot.get("offer_revision", -1)),
		"history": snapshot.get("current_lap_history", []),
		"selected": snapshot.get("selected_next_block", {}),
		"active": snapshot.get("active_block", {}),
	}
