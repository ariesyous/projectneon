@tool
extends McpTestSuite

const HEAT_TUNING: HeatDefinition = preload("res://data/run/milestone_3_heat.tres")
const COOLING_TUNING: RunCoolingDefinition = preload(
	"res://data/run/milestone_3_cooling.tres"
)
const ROUTE_TUNING: PatrolRouteDefinition = preload(
	"res://data/routes/downtown_loop_route.tres"
)
const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const STREET_REWARD: StandardRewardDefinition = preload(
	"res://data/rewards/street_cache.tres"
)
const NEON_REWARD: StandardRewardDefinition = preload(
	"res://data/rewards/neon_stash.tres"
)


class ShopReentrancyCapture:
	extends RefCounted

	var cooling: RunCoolingController
	var visit_revision: int = -1
	var source_id: StringName = &""
	var attempted: bool = false
	var nested_result: Dictionary = {}

	func on_coins_changed(_total: int) -> void:
		if attempted:
			return
		attempted = true
		nested_result = cooling.request_shop_cooling_result(visit_revision, source_id)


func suite_name() -> String:
	return "wp04_reward_shop_authority"


func test_standard_reward_latches_heat_multiplier_for_coins_only() -> void:
	var streams: RunRandomStreams = _new_streams(40401)
	var rewards: RewardDirector = _new_rewards(streams)
	rewards.standard_rewards = [NEON_REWARD]
	var selected: StandardRewardDefinition = rewards.prepare_standard_reward(
		41,
		1,
		[NEON_REWARD.id],
		HEAT_TUNING.reward_multiplier_for_tier(1)
	)
	assert_eq(selected, NEON_REWARD, "reward: selected definition is unchanged")
	var preview: Dictionary = rewards.get_pending_standard_reward_preview(41)
	assert_eq(preview.get("base_coins"), 30, "reward: raw authored coins are visible")
	_assert_near(float(preview.get("reward_multiplier")), 1.05, "reward: Heat multiplier is latched")
	assert_eq(preview.get("awarded_coins"), 32, "reward: positive .5 rounds half-up")
	assert_eq(preview.get("awarded_scrap"), 3, "reward: Scrap is never multiplied")
	preview["awarded_coins"] = 999
	assert_eq(
		rewards.get_pending_standard_reward_preview(41).get("awarded_coins"),
		32,
		"reward: callers cannot mutate the pending authority snapshot"
	)
	assert_true(rewards.apply_standard_reward(41), "reward: first application succeeds")
	assert_eq(rewards.get_coin_total(), 32, "reward: scaled coins apply exactly")
	assert_eq(rewards.get_scrap_total(), 3, "reward: raw Scrap applies exactly")
	var result: Dictionary = rewards.get_applied_standard_reward_result(41)
	assert_eq(result.get("coins_before"), 0, "reward result: exact starting coins")
	assert_eq(result.get("coins_after"), 32, "reward result: exact ending coins")
	assert_eq(result.get("scrap_before"), 0, "reward result: exact starting Scrap")
	assert_eq(result.get("scrap_after"), 3, "reward result: exact ending Scrap")
	assert_false(rewards.apply_standard_reward(41), "reward: replay rejects")
	assert_eq(rewards.get_coin_total(), 32, "reward: replay cannot duplicate coins")
	assert_eq(
		streams.get_draw_count(RunRandomStreams.STREAM_REWARDS),
		1,
		"reward: selection consumes one rewards draw"
	)
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		if stream_name == RunRandomStreams.STREAM_REWARDS:
			continue
		assert_eq(streams.get_draw_count(stream_name), 0, "reward: %s remains isolated" % stream_name)


func test_standard_reward_default_multiplier_remains_one_and_negative_is_safe() -> void:
	var rewards: RewardDirector = _new_rewards(_new_streams(40402))
	rewards.standard_rewards = [STREET_REWARD]
	assert_eq(
		rewards.prepare_standard_reward(42, 0, [STREET_REWARD.id]),
		STREET_REWARD,
		"compatibility: legacy three-argument preparation remains valid"
	)
	_assert_near(
		float(rewards.get_pending_standard_reward_preview(42).get("reward_multiplier")),
		1.0,
		"compatibility: omitted multiplier defaults to one"
	)
	assert_true(rewards.apply_standard_reward(42), "compatibility: default reward applies")
	assert_eq(rewards.get_coin_total(), 20, "compatibility: default coins remain authored")
	rewards.reset_for_run()
	assert_eq(
		rewards.prepare_standard_reward(43, 0, [STREET_REWARD.id], -2.0),
		STREET_REWARD,
		"reward: negative multiplier cannot invalidate deterministic selection"
	)
	assert_eq(
		rewards.get_pending_standard_reward_preview(43).get("awarded_coins"),
		0,
		"reward: negative multiplier clamps to a non-negative award"
	)
	assert_true(rewards.apply_standard_reward(43), "reward: zero-coin result still resolves")
	assert_eq(rewards.get_coin_total(), 0, "reward: clamped award cannot remove coins")
	assert_eq(rewards.get_scrap_total(), 2, "reward: Scrap remains raw at zero coin multiplier")


func test_equipment_choice_tokens_are_monotonic_and_context_bound() -> void:
	var streams: RunRandomStreams = _new_streams(40403)
	var system: SynergySystem = _new_synergy_system()
	var rewards: RewardDirector = _new_rewards(streams, system)
	assert_false(rewards.prepare_equipment_choices(51).is_empty(), "equipment: first choice opens")
	var first_token: int = rewards.get_pending_equipment_choice_token(51)
	assert_true(first_token > 0, "equipment: first choice has a positive token")
	assert_false(
		rewards.decline_equipment_reward(51, 50, first_token),
		"equipment: wrong expected encounter rejects"
	)
	assert_false(
		rewards.decline_equipment_reward(51, 51, first_token + 1),
		"equipment: stale expected token rejects"
	)
	assert_eq(rewards.get_pending_equipment_choice_token(51), first_token, "equipment: rejection preserves token")
	assert_true(
		rewards.decline_equipment_reward(51, 51, first_token),
		"equipment: exact encounter and token decline safely"
	)

	rewards.reset_for_run()
	assert_false(rewards.prepare_equipment_choices(52).is_empty(), "equipment: next run choice opens")
	var second_token: int = rewards.get_pending_equipment_choice_token(52)
	assert_true(second_token > first_token, "equipment: token ledger never resets between runs")
	var revision: int = system.get_inventory_revision()
	assert_false(
		rewards.apply_equipment_choice_to_inventory(
			52,
			0,
			SynergySystem.AREA_EQUIPPED,
			0,
			-1,
			false,
			revision,
			52,
			first_token
		),
		"equipment: prior-run token cannot mutate inventory"
	)
	assert_eq(system.get_equipped_items().size(), 0, "equipment: stale token leaves build unchanged")
	assert_true(
		rewards.apply_equipment_choice_to_inventory(
			52,
			0,
			SynergySystem.AREA_EQUIPPED,
			0,
			-1,
			false,
			revision,
			52,
			second_token
		),
		"equipment: exact context applies once"
	)
	assert_eq(system.get_equipped_items().size(), 1, "equipment: exact context mutates one slot")
	assert_eq(
		rewards.get_debug_snapshot().get("next_equipment_choice_token"),
		second_token + 1,
		"equipment: debug state exposes monotonic ledger"
	)


func test_shop_preview_and_result_are_exact_and_context_rejections_are_atomic() -> void:
	var fixture: Dictionary = _new_shop_fixture(40404, 80, 180, &"convenience_store", 1)
	var run: RunDirector = fixture.run as RunDirector
	var rewards: RewardDirector = fixture.rewards as RewardDirector
	var cooling: RunCoolingController = fixture.cooling as RunCoolingController
	var revision: int = cooling.get_shop_visit_revision()
	var pressure_before: float = run.night_pressure
	var preview: Dictionary = cooling.get_shop_purchase_preview(revision, &"convenience_store")
	assert_true(bool(preview.get("valid")), "shop preview: exact visit context is valid")
	assert_true(bool(preview.get("can_purchase")), "shop preview: UI-facing purchase flag is exact")
	assert_eq(preview.get("coins_before"), 180, "shop preview: coins before")
	assert_eq(preview.get("coins_after"), 120, "shop preview: coins after")
	assert_eq(preview.get("heat_before"), 80, "shop preview: Heat before")
	assert_eq(preview.get("heat_after"), 62, "shop preview: Heat after")
	assert_eq(preview.get("heat_tier_before"), 4, "shop preview: Heat tier before")
	assert_eq(preview.get("heat_tier_after"), 3, "shop preview: Heat tier after")
	assert_eq(preview.get("reward_quality_tier_before"), 3, "shop preview: reward quality before")
	assert_eq(preview.get("reward_quality_tier_after"), 2, "shop preview: reward quality after")
	assert_eq(preview.get("reward_quality_before"), 3, "shop preview: focused UI quality before")
	assert_eq(preview.get("reward_quality_after"), 2, "shop preview: focused UI quality after")
	_assert_near(float(preview.get("reward_multiplier_before")), 1.35, "shop preview: multiplier before")
	_assert_near(float(preview.get("reward_multiplier_after")), 1.20, "shop preview: multiplier after")
	assert_eq(preview.get("global_stock_before"), 2, "shop preview: global stock before")
	assert_eq(preview.get("global_stock_after"), 1, "shop preview: global stock after")
	assert_eq(preview.get("visit_stock_before"), 1, "shop preview: visit stock before")
	assert_eq(preview.get("visit_stock_after"), 0, "shop preview: visit stock after")
	_assert_near(float(preview.get("night_pressure_after")), pressure_before, "shop preview: Pressure unchanged")
	assert_eq(rewards.get_coin_total(), 180, "shop preview: no coin mutation")
	assert_eq(run.heat, 80, "shop preview: no Heat mutation")

	var authority_before: Dictionary = _shop_economy_state(run, rewards, cooling)
	var malformed: Dictionary = cooling.request_shop_cooling_result(revision, &"")
	assert_eq(malformed.get("reason"), &"malformed_context", "shop: partial context rejects")
	assert_eq(_shop_economy_state(run, rewards, cooling), authority_before, "shop: malformed rejection is atomic")
	var stale: Dictionary = cooling.request_shop_cooling_result(revision + 100, &"convenience_store")
	assert_eq(stale.get("reason"), &"stale_visit", "shop: stale revision rejects")
	assert_eq(_shop_economy_state(run, rewards, cooling), authority_before, "shop: stale rejection is atomic")
	var wrong: Dictionary = cooling.request_shop_cooling_result(revision, &"baseline_shop")
	assert_eq(wrong.get("reason"), &"wrong_source", "shop: wrong source rejects")
	assert_eq(_shop_economy_state(run, rewards, cooling), authority_before, "shop: wrong-source rejection is atomic")

	var result: Dictionary = cooling.request_shop_cooling_result(revision, &"convenience_store")
	assert_true(bool(result.get("accepted")), "shop: exact context purchases")
	assert_eq(result.get("resulting_visit_revision"), revision, "shop result: visit revision retained")
	assert_eq(result.get("coins_after"), 120, "shop result: exact coins after")
	assert_eq(result.get("heat_after"), 62, "shop result: exact Heat after")
	assert_eq(result.get("global_stock_after"), 1, "shop result: exact global stock after")
	assert_eq(result.get("visit_stock_after"), 0, "shop result: exact visit stock after")
	_assert_near(float(result.get("night_pressure_after")), pressure_before, "shop result: Pressure unchanged")
	assert_eq(cooling.get_snapshot().get("shop_visit_revision"), revision, "shop snapshot: revision exposed")
	assert_eq(
		(cooling.get_snapshot().get("last_shop_purchase_result", {}) as Dictionary).get("reason"),
		&"ok",
		"shop snapshot: exact accepted result retained"
	)


func test_shop_reentrancy_is_guarded_and_visit_revision_never_resets() -> void:
	var fixture: Dictionary = _new_shop_fixture(40405, 80, 180, &"baseline_shop", -1)
	var run: RunDirector = fixture.run as RunDirector
	var rewards: RewardDirector = fixture.rewards as RewardDirector
	var cooling: RunCoolingController = fixture.cooling as RunCoolingController
	var first_revision: int = cooling.get_shop_visit_revision()
	var capture: ShopReentrancyCapture = ShopReentrancyCapture.new()
	capture.cooling = cooling
	capture.visit_revision = first_revision
	capture.source_id = &"baseline_shop"
	rewards.coins_changed.connect(capture.on_coins_changed)
	assert_true(
		cooling.request_shop_cooling(first_revision, &"baseline_shop"),
		"shop reentrancy: outer purchase succeeds"
	)
	assert_true(capture.attempted, "shop reentrancy: synchronous nested request attempted")
	assert_eq(capture.nested_result.get("reason"), &"reentrant_request", "shop reentrancy: nested request rejects")
	assert_eq(rewards.get_coin_total(), 120, "shop reentrancy: coins charged once")
	assert_eq(run.heat, 62, "shop reentrancy: Heat reduced once")
	assert_eq(cooling.get_shop_purchases_remaining(), 1, "shop reentrancy: stock consumed once")
	assert_true(cooling.end_shop_visit(), "shop revision: first visit ends")
	assert_true(cooling.begin_shop_visit(&"baseline_shop", -1), "shop revision: second visit opens")
	var second_revision: int = cooling.get_shop_visit_revision()
	assert_true(second_revision > first_revision, "shop revision: later visit advances")
	cooling.reset_for_run()
	assert_true(cooling.begin_shop_visit(&"baseline_shop", -1), "shop revision: post-reset visit opens")
	assert_true(
		cooling.get_shop_visit_revision() > second_revision,
		"shop revision: reset cannot revive an old visit token"
	)


func _new_streams(seed: int) -> RunRandomStreams:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams._ready()
	streams.reset_for_seed(seed)
	return streams


func _new_rewards(
	streams: RunRandomStreams,
	system: SynergySystem = null
) -> RewardDirector:
	var rewards: RewardDirector = track(RewardDirector.new()) as RewardDirector
	rewards._ready()
	rewards.set_process(false)
	rewards.configure_random_streams(streams)
	if system != null:
		rewards.configure_equipment(system)
	rewards.reset_for_run()
	return rewards


func _new_synergy_system() -> SynergySystem:
	var system: SynergySystem = track(SynergySystem.new()) as SynergySystem
	system.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	return system


func _new_run(seed: int) -> RunDirector:
	var run: RunDirector = track(RunDirector.new()) as RunDirector
	var streams: RunRandomStreams = RunRandomStreams.new()
	streams.name = "RunRandomStreams"
	run.add_child(streams)
	run._ready()
	run.set_process(false)
	run.start_run(seed, true)
	run.complete_intro()
	return run


func _new_patrol() -> PatrolController:
	var patrol: PatrolController = track(PatrolController.new()) as PatrolController
	patrol.route_definition = ROUTE_TUNING
	patrol._ready()
	patrol.set_process(false)
	return patrol


func _new_shop_fixture(
	seed: int,
	heat: int,
	coins: int,
	source_id: StringName,
	visit_limit: int
) -> Dictionary:
	var run: RunDirector = _new_run(seed)
	var rewards: RewardDirector = _new_rewards(run.get_random_streams())
	var cooling: RunCoolingController = track(RunCoolingController.new()) as RunCoolingController
	cooling.tuning = COOLING_TUNING
	cooling._ready()
	cooling.configure(run, rewards, _new_patrol())
	rewards.grant_coins(coins)
	run.apply_heat_delta(heat)
	assert_true(run.open_shop(), "fixture: shop state opens")
	assert_true(cooling.begin_shop_visit(source_id, visit_limit), "fixture: revisioned visit opens")
	return {"run": run, "rewards": rewards, "cooling": cooling}


func _shop_economy_state(
	run: RunDirector,
	rewards: RewardDirector,
	cooling: RunCoolingController
) -> Dictionary:
	return {
		"coins": rewards.get_coin_total(),
		"heat": run.heat,
		"pressure": run.night_pressure,
		"global_stock": cooling.get_shop_purchases_remaining(),
		"visit_stock": cooling.get_shop_visit_purchases_remaining(),
		"visit_revision": cooling.get_shop_visit_revision(),
		"source_id": cooling.get_shop_visit_source_id(),
	}


func _assert_near(actual: float, expected: float, message: String) -> void:
	assert_true(absf(actual - expected) <= 0.0001, "%s (actual=%f expected=%f)" % [message, actual, expected])
