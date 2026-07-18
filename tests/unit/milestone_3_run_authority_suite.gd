@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EPSILON: float = 0.0001
const HEAT_TUNING: HeatDefinition = preload("res://data/run/milestone_3_heat.tres")
const ESCALATION_TUNING: RunEscalationDefinition = preload(
	"res://data/run/milestone_3_escalation.tres"
)
const COOLING_TUNING: RunCoolingDefinition = preload("res://data/run/milestone_3_cooling.tres")
const RANDOM_SCHEMA: RunRandomSchemaDefinition = preload(
	"res://data/run/milestone_3_random_schema.tres"
)
const ROUTE_TUNING: PatrolRouteDefinition = preload("res://data/routes/downtown_loop_route.tres")
const ALLEY_ENCOUNTER: EncounterDefinition = preload("res://data/encounters/alley_scuffle.tres")
const ARCADE_ENCOUNTER: EncounterDefinition = preload("res://data/encounters/arcade_ambush.tres")
const VIPER_ENCOUNTER: EncounterDefinition = preload("res://data/encounters/viper_signal.tres")
const STREET_REWARD: StandardRewardDefinition = preload("res://data/rewards/street_cache.tres")
const NEON_REWARD: StandardRewardDefinition = preload("res://data/rewards/neon_stash.tres")
const VIPER_REWARD: StandardRewardDefinition = preload("res://data/rewards/viper_cache.tres")
const JAX_DEFINITION: ActorDefinition = preload("res://data/crew/jax.tres")
const STREET_PUNK_DEFINITION: ActorDefinition = preload("res://data/enemies/street_punk.tres")
const JAX_ATTACK: AttackDefinition = preload("res://data/attacks/jax_basic_punch.tres")
const STREET_PUNK_ATTACK: AttackDefinition = preload(
	"res://data/attacks/street_punk_basic_punch.tres"
)


func suite_name() -> String:
	return "milestone_3_run_authority"


func test_authored_milestone_3_tuning_and_content_contract() -> void:
	_expect_equal(HEAT_TUNING.tier_lower_bounds, PackedInt32Array([0, 20, 40, 60, 80, 100]), "heat: exact tier bounds")
	_expect_equal(HEAT_TUNING.spawn_budget_additions, PackedInt32Array([0, 1, 2, 3, 4, 5]), "heat: authored budget additions")
	_expect_equal(HEAT_TUNING.reward_quality_tiers, PackedInt32Array([0, 0, 1, 2, 3, 4]), "heat: authored reward quality")
	_expect_equal(HEAT_TUNING.elite_available_from_tier, 3, "heat: elite availability begins at tier 3")
	_expect_approx(ESCALATION_TUNING.passive_pressure_per_second, 0.25, "pressure: passive rate")
	_expect_approx(ESCALATION_TUNING.pressure_per_standard_encounter, 6.0, "pressure: standard completion")
	_expect_approx(ESCALATION_TUNING.pressure_per_elite_encounter, 10.0, "pressure: elite completion")
	_expect_equal(ESCALATION_TUNING.extraction_pressure_thresholds, PackedFloat32Array([18.0, 36.0]), "pressure: extraction thresholds")
	_expect_approx(ESCALATION_TUNING.boss_pressure_threshold, 50.0, "pressure: boss threshold")
	_expect_equal(ESCALATION_TUNING.global_enemy_concurrency_limit, 30, "pressure: global concurrency cap")
	_expect_equal(COOLING_TUNING.initial_subway_reroute_charges, 2, "cooling: initial subway charges")
	_expect_equal(COOLING_TUNING.subway_reroute_acquisition_cap, 2, "cooling: subway acquisition cap")
	_expect_equal(COOLING_TUNING.subway_heat_reduction, 15, "cooling: subway reduction")
	_expect_equal(COOLING_TUNING.shop_cooling_purchase_limit, 2, "cooling: finite shop stock")
	_expect_equal(COOLING_TUNING.shop_cooling_coin_cost, 60, "cooling: meaningful shop cost")
	_expect_equal(COOLING_TUNING.shop_heat_reduction, 18, "cooling: shop reduction")
	_expect_equal(ROUTE_TUNING.node_count(), 5, "route: five stable authored nodes")
	_expect_equal(ROUTE_TUNING.node_id(0), &"arcade_corner", "route: first node")
	_expect_equal(ROUTE_TUNING.node_type(1), &"shop", "route: shop node")
	_expect_true(ALLEY_ENCOUNTER.allowed_enemy_ids.has(&"street_punk"), "encounter: allowed enemy table")
	_expect_equal(ALLEY_ENCOUNTER.completion_condition, &"all_required_defeated", "encounter: completion condition")
	_expect_equal(ARCADE_ENCOUNTER.reward_table_ids, [&"street_cache", &"neon_stash"], "encounter: deterministic reward table")
	_expect_true(VIPER_ENCOUNTER.elite_eligible, "encounter: elite eligibility flag")
	_expect_false(VIPER_ENCOUNTER.boss, "encounter: Milestone 3 candidate is not boss content")
	_expect_equal(RANDOM_SCHEMA.random_schema_version, 1, "randomness: schema version")
	_expect_equal(RANDOM_SCHEMA.derivation_algorithm_id, &"fnv1a32_utf8_v1", "randomness: algorithm id")


func test_heat_clamping_and_every_exact_tier_boundary() -> void:
	var cases: Array[Dictionary] = [
		{"heat": -100, "clamped": 0, "tier": 0},
		{"heat": 0, "clamped": 0, "tier": 0},
		{"heat": 19, "clamped": 19, "tier": 0},
		{"heat": 20, "clamped": 20, "tier": 1},
		{"heat": 39, "clamped": 39, "tier": 1},
		{"heat": 40, "clamped": 40, "tier": 2},
		{"heat": 59, "clamped": 59, "tier": 2},
		{"heat": 60, "clamped": 60, "tier": 3},
		{"heat": 79, "clamped": 79, "tier": 3},
		{"heat": 80, "clamped": 80, "tier": 4},
		{"heat": 99, "clamped": 99, "tier": 4},
		{"heat": 100, "clamped": 100, "tier": 5},
		{"heat": 999, "clamped": 100, "tier": 5},
	]
	for record: Dictionary in cases:
		var requested: int = int(record.heat)
		_expect_equal(HEAT_TUNING.clamp_heat(requested), int(record.clamped), "heat: clamp %d" % requested)
		_expect_equal(HEAT_TUNING.tier_for_heat(requested), int(record.tier), "heat: tier %d" % requested)


func test_heat_changes_immediate_effects_without_night_pressure_mutation() -> void:
	var director: RunDirector = _new_run_director()
	director.start_run(301, true)
	director.complete_intro()
	director.add_night_pressure(12.0)
	var fixed_pressure: float = director.night_pressure
	var tier_cases: Array[Dictionary] = [
		{"heat": 0, "quality": 0, "elite": false, "budget": 3, "reward": 1.0},
		{"heat": 20, "quality": 0, "elite": false, "budget": 4, "reward": 1.05},
		{"heat": 40, "quality": 1, "elite": false, "budget": 5, "reward": 1.10},
		{"heat": 60, "quality": 2, "elite": true, "budget": 6, "reward": 1.20},
		{"heat": 80, "quality": 3, "elite": true, "budget": 7, "reward": 1.35},
		{"heat": 100, "quality": 4, "elite": true, "budget": 8, "reward": 1.50},
	]
	var previous_damage: float = 0.0
	for record: Dictionary in tier_cases:
		director.apply_heat_delta(int(record.heat) - director.heat)
		_expect_approx(director.night_pressure, fixed_pressure, "heat: pressure stays separate at %d" % int(record.heat))
		_expect_equal(director.get_reward_quality_tier(), int(record.quality), "heat: quality at %d" % int(record.heat))
		_expect_equal(director.is_elite_available(), bool(record.elite), "heat: elite availability at %d" % int(record.heat))
		_expect_equal(director.calculate_spawn_budget(ALLEY_ENCOUNTER), int(record.budget), "heat: spawn budget at %d" % int(record.heat))
		_expect_approx(director.get_reward_multiplier(), float(record.reward), "heat: reward multiplier at %d" % int(record.heat))
		var damage: float = director.get_enemy_damage_multiplier()
		_expect_true(damage >= previous_damage, "heat: immediate damage never falls between tiers")
		previous_damage = damage
	_expect_false(director.is_boss_threshold_latched(), "heat: Heat 100 does not latch boss")


func test_night_pressure_advances_only_during_eligible_active_time() -> void:
	var director: RunDirector = _new_run_director()
	director.start_run(302, true)
	director.step_run(100.0)
	_expect_equal(director.current_state, RunDirector.RunState.PATROLLING, "time: intro completes")
	_expect_approx(director.run_elapsed_seconds, 0.0, "time: non-interactive intro excluded")
	_expect_approx(director.night_pressure, 0.0, "time: intro adds no pressure")
	director.step_run(4.0)
	_expect_approx(director.run_elapsed_seconds, 4.0, "time: patrol is eligible")
	_expect_approx(director.night_pressure, 1.0, "time: patrol pressure")
	_expect_true(director.toggle_pause(), "time: pause enters")
	director.step_run(40.0)
	_expect_approx(director.run_elapsed_seconds, 4.0, "time: pause excluded")
	_expect_approx(director.night_pressure, 1.0, "time: pause pressure excluded")
	_expect_true(director.toggle_pause(), "time: pause resumes")
	_expect_true(director.open_shop(), "time: shop opens")
	director.step_run(40.0)
	_expect_approx(director.night_pressure, 1.0, "time: modal shop excluded")
	_expect_true(director.leave_shop(), "time: shop closes")
	_expect_true(director.begin_encounter(ALLEY_ENCOUNTER), "time: encounter begins")
	director.step_run(4.0)
	_expect_approx(director.run_elapsed_seconds, 8.0, "time: encounter is eligible")
	_expect_approx(director.night_pressure, 2.0, "time: encounter pressure")
	_expect_true(director.notify_encounter_completed(1, ALLEY_ENCOUNTER), "time: encounter completes")
	var reward_pressure: float = director.night_pressure
	director.step_run(40.0)
	_expect_approx(director.run_elapsed_seconds, 8.0, "time: modal reward excluded")
	_expect_approx(director.night_pressure, reward_pressure, "time: reward pressure excluded")


func test_encounter_completion_pressure_is_exactly_once_under_retries() -> void:
	var director: RunDirector = _new_active_run(303)
	_expect_true(director.begin_encounter(ALLEY_ENCOUNTER), "completion: encounter begins")
	_expect_true(director.notify_encounter_completed(77, ALLEY_ENCOUNTER), "completion: first notification accepted")
	_expect_equal(director.encounters_completed, 1, "completion: count once")
	_expect_approx(director.night_pressure, 6.0, "completion: standard gain once")
	_expect_false(director.notify_encounter_completed(77, ALLEY_ENCOUNTER), "completion: immediate duplicate rejected")
	_expect_true(director.complete_reward_selection(), "completion: reward closes")
	_expect_true(director.begin_encounter(ALLEY_ENCOUNTER), "completion: later encounter begins")
	_expect_false(director.notify_encounter_completed(77, ALLEY_ENCOUNTER), "completion: retried old id rejected")
	_expect_equal(director.encounters_completed, 1, "completion: retry cannot increment count")
	_expect_approx(director.night_pressure, 6.0, "completion: retry cannot add pressure")
	_expect_true(director.notify_encounter_completed(78, VIPER_ENCOUNTER), "completion: new elite-eligible encounter accepted")
	_expect_equal(director.encounters_completed, 2, "completion: new id increments")
	_expect_approx(director.night_pressure, 16.0, "completion: elite authored gain")


func test_data_driven_scaling_rounding_and_concurrency_caps() -> void:
	var director: RunDirector = _new_active_run(304)
	director.add_night_pressure(20.0)
	director.apply_heat_delta(60)
	_expect_approx(director.get_enemy_health_multiplier(), 1.20, "scaling: health multiplier")
	_expect_approx(director.get_enemy_damage_multiplier(), 1.10 * 1.15, "scaling: pressure and Heat damage")
	_expect_equal(director.calculate_spawn_budget(ALLEY_ENCOUNTER), 7, "scaling: pressure rounds before Heat addition")
	var rounding: RunEscalationDefinition = RunEscalationDefinition.new()
	rounding.spawn_budget_multiplier_per_pressure = 0.125
	_expect_equal(rounding.scaled_spawn_budget(4, 1.0), 5, "rounding: exact .5 rounds up")
	_expect_equal(rounding.scaled_spawn_budget(4, 1.0, 1), 6, "rounding: Heat addition after scaling")
	_expect_equal(director.calculate_encounter_concurrency(ALLEY_ENCOUNTER, 20, 0), 3, "caps: encounter cap")
	_expect_equal(director.calculate_encounter_concurrency(ALLEY_ENCOUNTER, 20, 2), 1, "caps: active encounter enemies consume slots")
	_expect_equal(director.calculate_encounter_concurrency(ALLEY_ENCOUNTER, 20, 30), 0, "caps: global cap")
	var tiny_cap: RunEscalationDefinition = ESCALATION_TUNING.duplicate(true) as RunEscalationDefinition
	tiny_cap.global_enemy_concurrency_limit = 2
	director.escalation_definition = tiny_cap
	_expect_equal(director.calculate_spawn_budget(VIPER_ENCOUNTER), 2, "caps: spawn budget respects global cap")


func test_enemy_actor_receives_scaled_health_and_damage_configuration() -> void:
	var actor: ActorController = _new_actor(false, 400.0, 1, false)
	actor.configure_runtime_scaling(1.25, 1.40)
	actor.initialize_runtime()
	var expected_health: int = int(floor(float(STREET_PUNK_DEFINITION.maximum_health) * 1.25 + 0.5))
	_expect_equal(actor.health_component.maximum_health, expected_health, "actor scaling: deterministic health round-half-up")
	_expect_equal(actor.health_component.current_health, expected_health, "actor scaling: starts at scaled maximum")
	_expect_approx(actor.get_runtime_damage_multiplier(), 1.40, "actor scaling: runtime damage multiplier")


func test_complete_run_state_transition_graph_branches() -> void:
	var ordinary: RunDirector = _new_run_director()
	_expect_equal(ordinary.start_run(401, true), 401, "graph: supplied seed begins run")
	_expect_equal(ordinary.current_state, RunDirector.RunState.INTRO, "graph: initializing to intro")
	_expect_true(ordinary.complete_intro(), "graph: intro to patrol")
	_expect_true(ordinary.begin_encounter(ALLEY_ENCOUNTER), "graph: patrol to encounter")
	_expect_true(ordinary.notify_encounter_completed(1, ALLEY_ENCOUNTER), "graph: encounter to reward")
	_expect_true(ordinary.complete_reward_selection(), "graph: reward to patrol")
	_expect_true(ordinary.open_shop(), "graph: patrol to shop")
	_expect_true(ordinary.leave_shop(), "graph: shop to patrol")
	_expect_true(ordinary.toggle_pause(), "graph: patrol to paused")
	_expect_true(ordinary.toggle_pause(), "graph: paused to patrol")

	var extraction: RunDirector = _new_active_run(402)
	extraction.add_night_pressure(18.0)
	_expect_true(extraction.notify_safe_transition_boundary(), "graph: patrol to extraction window")
	_expect_true(extraction.confirm_extraction(), "graph: extraction confirmation")
	_expect_equal(extraction.current_state, RunDirector.RunState.EXTRACTING, "graph: extraction animation state")
	_expect_equal(extraction.get_result(), RunDirector.RunResult.NONE, "graph: result waits for extraction sequence")
	extraction.step_run(RunDirector.EXTRACTION_DURATION_SECONDS)
	_expect_equal(extraction.get_result(), RunDirector.RunResult.EXTRACTED, "graph: extraction completes")
	var extraction_summary: RunSummaryRecord = extraction.finalize_summary(3, 20, 1, 2, 2)
	_expect_equal(extraction.current_state, RunDirector.RunState.RUN_SUMMARY, "graph: extraction to summary")
	_expect_equal(extraction_summary.result_label, "EXTRACTED", "graph: extracted summary result")

	var defeat: RunDirector = _new_active_run(403)
	_expect_true(defeat.begin_encounter(ALLEY_ENCOUNTER), "graph: defeat encounter begins")
	_expect_true(defeat.notify_all_crew_incapacitated(), "graph: encounter to defeat")
	_expect_equal(defeat.get_result(), RunDirector.RunResult.DEFEATED, "graph: defeat result")
	_expect_equal(defeat.finalize_summary(0, 0, 0, 0, 0).result_label, "DEFEATED", "graph: defeat summary")

	var victory: RunDirector = _new_active_run(404)
	victory.add_night_pressure(50.0)
	_expect_true(victory.notify_safe_transition_boundary(), "graph: safe boundary begins boss intro")
	_expect_true(victory.complete_boss_intro(), "graph: boss intro to active")
	_expect_true(victory.notify_boss_defeated(), "graph: boss active to victory")
	var victory_summary: RunSummaryRecord = victory.finalize_summary(12, 100, 4, 4, 10)
	_expect_equal(victory.current_state, RunDirector.RunState.RUN_SUMMARY, "graph: victory to summary")
	_expect_true(victory_summary.boss_defeated, "graph: summary records boss defeat")


func test_invalid_duplicate_and_out_of_range_transitions_are_rejected() -> void:
	var director: RunDirector = _new_run_director()
	director.start_run(405, true)
	_expect_false(director.request_transition(RunDirector.RunState.INTRO), "transition: duplicate intro rejected")
	_expect_false(director.open_shop(), "transition: intro cannot open shop")
	_expect_false(director.request_transition(999), "transition: unknown state rejected")
	_expect_true(director.complete_intro(), "transition: valid intro completion")
	_expect_false(director.request_transition(RunDirector.RunState.RUN_SUMMARY), "transition: patrol cannot jump to summary")
	_expect_false(director.begin_encounter(null), "transition: null encounter rejected")
	_expect_true(director.open_shop(), "transition: valid shop opens")
	_expect_false(director.open_shop(), "transition: duplicate shop rejected")
	_expect_false(director.notify_all_crew_incapacitated(), "transition: shop cannot produce combat defeat")


func test_extraction_thresholds_latch_and_spent_windows_do_not_reopen() -> void:
	var director: RunDirector = _new_active_run(406)
	director.add_night_pressure(18.0)
	_expect_true(director.is_extraction_threshold_latched(0), "extraction: first threshold latches")
	_expect_equal(director.get_pending_extraction_count(), 1, "extraction: window queues")
	_expect_true(director.notify_safe_transition_boundary(), "extraction: safe boundary opens window")
	_expect_true(director.decline_extraction(), "extraction: decline spends window")
	_expect_true(director.is_extraction_threshold_spent(0), "extraction: first window remains spent")
	var pressure_after_decline: float = director.night_pressure
	director.apply_heat_delta(-100)
	_expect_approx(director.night_pressure, pressure_after_decline, "extraction: cooling cannot lower pressure")
	_expect_true(director.is_extraction_threshold_latched(0), "extraction: cooling cannot unlatch")
	_expect_true(director.is_extraction_threshold_spent(0), "extraction: cooling cannot reopen spent window")
	_expect_false(director.notify_safe_transition_boundary(), "extraction: no duplicate first window")
	director.add_night_pressure(18.0)
	_expect_true(director.is_extraction_threshold_latched(1), "extraction: second threshold latches")
	_expect_true(director.notify_safe_transition_boundary(), "extraction: later threshold opens next window")


func test_boss_threshold_latches_queues_and_has_same_update_precedence() -> void:
	var director: RunDirector = _new_active_run(407)
	_expect_true(director.begin_encounter(ALLEY_ENCOUNTER), "boss: unsafe encounter begins")
	director.add_night_pressure(50.0)
	_expect_true(director.is_boss_threshold_latched(), "boss: threshold latches")
	_expect_true(director.is_boss_queued(), "boss: unsafe crossing queues boss")
	_expect_true(director.is_extraction_threshold_latched(0), "boss: same update latches extraction 0")
	_expect_true(director.is_extraction_threshold_latched(1), "boss: same update latches extraction 1")
	_expect_true(director.is_extraction_threshold_spent(0), "boss: precedence spends extraction 0")
	_expect_true(director.is_extraction_threshold_spent(1), "boss: precedence spends extraction 1")
	_expect_equal(director.get_pending_extraction_count(), 0, "boss: precedence clears extraction queue")
	_expect_true(director.notify_encounter_completed(1, ALLEY_ENCOUNTER), "boss: current encounter closes safely")
	_expect_true(director.complete_reward_selection(), "boss: next boundary begins boss")
	_expect_equal(director.current_state, RunDirector.RunState.BOSS_INTRO, "boss: queued transition is safe")
	_expect_true(director.was_boss_started(), "boss: trigger recorded")
	_expect_false(director.is_boss_queued(), "boss: queue consumed exactly once")
	director.apply_heat_delta(-100)
	_expect_true(director.is_boss_threshold_latched(), "boss: cooling cannot clear latch")
	_expect_equal(director.current_state, RunDirector.RunState.BOSS_INTRO, "boss: cooling cannot reverse transition")


func test_confirmed_extraction_is_not_preempted_by_later_boss_crossing() -> void:
	var director: RunDirector = _new_active_run(408)
	director.add_night_pressure(18.0)
	director.notify_safe_transition_boundary()
	_expect_true(director.confirm_extraction(), "precedence: extraction confirmed first")
	director.add_night_pressure(32.0)
	_expect_true(director.is_boss_threshold_latched(), "precedence: later boss threshold still records")
	_expect_false(director.is_boss_queued(), "precedence: confirmed extraction prevents boss queue")
	_expect_equal(director.current_state, RunDirector.RunState.EXTRACTING, "precedence: extraction remains authoritative")
	director.step_run(RunDirector.EXTRACTION_DURATION_SECONDS)
	_expect_equal(director.get_result(), RunDirector.RunResult.EXTRACTED, "precedence: extraction result completes")


func test_patrol_progression_and_reroute_use_stable_authored_order() -> void:
	var patrol: PatrolController = _new_patrol_controller()
	patrol.start_patrol()
	patrol.set_simulation_enabled(true)
	patrol.step_patrol(3.9)
	_expect_equal(patrol.route_index, -1, "route: segment remains in travel")
	patrol.step_patrol(0.11)
	_expect_equal(patrol.route_index, 0, "route: first node entered")
	_expect_equal(patrol.get_route_node_id(), &"arcade_corner", "route: first stable id")
	_expect_true(patrol.continue_from_current_node(), "route: first node resolves")
	patrol.step_patrol(4.0)
	_expect_equal(patrol.route_index, 1, "route: second node entered")
	_expect_equal(patrol.get_route_node_type(), &"shop", "route: second node type")
	_expect_true(patrol.continue_from_current_node(), "route: shop resolves")
	_expect_true(patrol.request_reroute(), "route: finite intervention ends travel")
	_expect_equal(patrol.route_index, 2, "route: reroute advances exactly one node")


func test_finite_subway_reroutes_reject_zero_without_mutating_pressure() -> void:
	var director: RunDirector = _new_active_run(409)
	var patrol: PatrolController = _new_patrol_controller()
	patrol.start_patrol()
	patrol.set_simulation_enabled(true)
	var rewards: RewardDirector = _new_reward_director(director.get_random_streams())
	var cooling: RunCoolingController = _new_cooling_controller(director, rewards, patrol)
	director.apply_heat_delta(80)
	director.add_night_pressure(10.0)
	var pressure_before: float = director.night_pressure
	_expect_true(cooling.request_subway_reroute(), "subway: first charge accepted")
	_expect_equal(cooling.get_subway_charges(), 1, "subway: one charge remains")
	_expect_equal(director.heat, 65, "subway: first Heat reduction")
	_expect_approx(director.night_pressure, pressure_before, "subway: pressure unchanged")
	_expect_true(patrol.continue_from_current_node(), "subway: resolve reached route node")
	_expect_true(cooling.request_subway_reroute(), "subway: second charge accepted")
	_expect_equal(cooling.get_subway_charges(), 0, "subway: charges exhausted")
	_expect_equal(director.heat, 50, "subway: second Heat reduction")
	var route_after_two: int = patrol.route_index
	_expect_false(cooling.request_subway_reroute(), "subway: zero-charge request rejected")
	_expect_equal(patrol.route_index, route_after_two, "subway: rejection leaves route unchanged")
	_expect_equal(director.heat, 50, "subway: rejection leaves Heat unchanged")
	_expect_approx(director.night_pressure, pressure_before, "subway: rejection leaves pressure unchanged")
	director.step_run(20.0)
	_expect_equal(cooling.get_subway_charges(), 0, "subway: elapsed time never regenerates charges")


func test_finite_shop_cooling_has_cost_stock_and_cannot_clear_progression() -> void:
	var director: RunDirector = _new_active_run(410)
	var patrol: PatrolController = _new_patrol_controller()
	var rewards: RewardDirector = _new_reward_director(director.get_random_streams())
	var cooling: RunCoolingController = _new_cooling_controller(director, rewards, patrol)
	rewards.grant_coins(180)
	director.apply_heat_delta(100)
	director.add_night_pressure(50.0)
	_expect_true(director.is_boss_queued(), "shop: boss queued before cooling")
	_expect_true(director.open_shop(), "shop: modal shop opens before safe boss boundary")
	var fixed_pressure: float = director.night_pressure
	_expect_true(cooling.request_shop_cooling(), "shop: first purchase")
	_expect_true(cooling.request_shop_cooling(), "shop: second purchase")
	_expect_equal(cooling.get_shop_purchases_remaining(), 0, "shop: finite stock exhausted")
	_expect_equal(rewards.get_coin_total(), 60, "shop: two meaningful costs paid")
	_expect_equal(director.heat, 64, "shop: authored reductions applied")
	_expect_approx(director.night_pressure, fixed_pressure, "shop: pressure never decreases")
	_expect_true(director.is_boss_queued(), "shop: cooling cannot clear queued boss")
	_expect_true(director.is_extraction_threshold_spent(0), "shop: cooling cannot reopen first window")
	_expect_false(cooling.request_shop_cooling(), "shop: sold-out purchase rejected")
	_expect_equal(rewards.get_coin_total(), 60, "shop: rejection charges no coins")
	_expect_equal(director.heat, 64, "shop: rejection grants no cooling")


func test_standard_rewards_use_encounter_tables_and_apply_exactly_once() -> void:
	var director: RunDirector = _new_active_run(411)
	var rewards: RewardDirector = _new_reward_director(director.get_random_streams())
	rewards.standard_rewards = [VIPER_REWARD, STREET_REWARD, NEON_REWARD]
	var selected: StandardRewardDefinition = rewards.prepare_standard_reward(
		1,
		1,
		ARCADE_ENCOUNTER.reward_table_ids
	)
	_expect_equal(selected.id, &"neon_stash", "reward: highest eligible authored table entry")
	_expect_true(rewards.apply_standard_reward(1), "reward: first application succeeds")
	_expect_equal(rewards.get_coin_total(), 30, "reward: coins credited")
	_expect_equal(rewards.get_scrap_total(), 3, "reward: Scrap credited")
	_expect_false(rewards.apply_standard_reward(1), "reward: duplicate application rejected")
	_expect_equal(rewards.get_coin_total(), 30, "reward: duplicate cannot credit coins")
	_expect_equal(rewards.get_scrap_total(), 3, "reward: duplicate cannot credit Scrap")
	_expect_equal(rewards.prepare_standard_reward(2, 0, VIPER_ENCOUNTER.reward_table_ids), null, "reward: Heat quality filters table deterministically")


func test_run_summaries_report_extraction_defeat_and_boss_results() -> void:
	var extraction: RunDirector = _new_active_run(412)
	extraction.step_run(8.0)
	extraction.apply_heat_delta(60)
	extraction.add_night_pressure(16.0)
	extraction.notify_safe_transition_boundary()
	extraction.confirm_extraction()
	extraction.step_run(RunDirector.EXTRACTION_DURATION_SECONDS)
	var extracted: RunSummaryRecord = extraction.finalize_summary(9, 80, 3, 4, 7)
	_expect_equal(extracted.result, RunDirector.RunResult.EXTRACTED, "summary: extraction result")
	_expect_equal(extracted.run_seed, 412, "summary: authoritative seed")
	_expect_equal(extracted.random_schema_version, 1, "summary: schema version")
	_expect_equal(extracted.maximum_heat, 60, "summary: maximum Heat")
	_expect_equal(extracted.enemies_defeated, 9, "summary: enemy count")
	_expect_equal(extracted.manual_clusters_collected, 3, "summary: manual clusters")
	_expect_equal(extracted.maximum_manual_streak, 4, "summary: best streak")
	_expect_false(extracted.boss_defeated, "summary: extraction did not defeat boss")

	var defeated_director: RunDirector = _new_active_run(413)
	defeated_director.begin_encounter(ALLEY_ENCOUNTER)
	defeated_director.notify_all_crew_incapacitated()
	var defeated: RunSummaryRecord = defeated_director.finalize_summary(1, 10, 0, 0, 0)
	_expect_equal(defeated.result_label, "DEFEATED", "summary: defeat label")

	var victory_director: RunDirector = _new_active_run(414)
	victory_director.add_night_pressure(50.0)
	victory_director.notify_safe_transition_boundary()
	victory_director.complete_boss_intro()
	victory_director.notify_boss_defeated()
	var victory: RunSummaryRecord = victory_director.finalize_summary(20, 200, 5, 4, 20)
	_expect_equal(victory.result_label, "VICTORY", "summary: victory label")
	_expect_true(victory.boss_triggered, "summary: boss trigger recorded")
	_expect_true(victory.boss_defeated, "summary: boss defeat recorded")
	_expect_equal(victory.equipment_build, "NOT AVAILABLE IN MILESTONE 3", "summary: later equipment honestly deferred")
	_expect_equal(victory.active_synergies, "NOT AVAILABLE IN MILESTONE 3", "summary: later synergies honestly deferred")


func test_clean_same_seed_restart_clears_authoritative_and_ledger_state() -> void:
	var director: RunDirector = _new_active_run(415)
	var streams: RunRandomStreams = director.get_random_streams()
	var first_sequence: Array[int] = []
	for index: int in range(8):
		first_sequence.append(streams.draw_index(RunRandomStreams.STREAM_ENCOUNTERS, 17))
	director.step_run(12.0)
	director.apply_heat_delta(90)
	director.add_night_pressure(50.0)
	var rewards: RewardDirector = _new_reward_director(streams)
	rewards.standard_rewards = [STREET_REWARD]
	rewards.grant_coins(100)
	rewards.grant_scrap(9)
	rewards.register_coin_cluster(1, 10)

	var combat: CombatDirector = _new_combat_director()
	var jax: ActorController = _new_actor(true, 220.0, 1)
	var enemy: ActorController = _new_actor(false, 360.0, 1)
	combat.register_actor(jax)
	combat.register_actor(enemy)
	jax.assign_target(enemy)
	combat.reserve_attack_position(jax, enemy)
	combat.clear_all(true)
	rewards.reset_for_run()
	_expect_equal(director.restart_same_seed(), 415, "restart: same seed retained")
	_expect_equal(director.current_state, RunDirector.RunState.INTRO, "restart: lifecycle returns to intro")
	_expect_approx(director.run_elapsed_seconds, 0.0, "restart: timer cleared")
	_expect_equal(director.heat, 0, "restart: Heat cleared")
	_expect_approx(director.night_pressure, 0.0, "restart: Night Pressure cleared")
	_expect_false(director.is_boss_threshold_latched(), "restart: boss latch cleared")
	_expect_false(director.is_boss_queued(), "restart: boss queue cleared")
	_expect_equal(director.get_pending_extraction_count(), 0, "restart: extraction queue cleared")
	_expect_equal(director.encounters_completed, 0, "restart: encounter completions cleared")
	_expect_equal(rewards.get_coin_total(), 0, "restart: coin ledger cleared")
	_expect_equal(rewards.get_scrap_total(), 0, "restart: Scrap ledger cleared")
	_expect_equal(rewards.get_active_cluster_count(), 0, "restart: pending rewards cleared")
	_expect_equal(combat.get_registered_count(), 0, "restart: actors cleared")
	_expect_equal(combat.get_reservation_snapshot().size(), 0, "restart: reservations cleared")
	var replay_sequence: Array[int] = []
	for index: int in range(8):
		replay_sequence.append(streams.draw_index(RunRandomStreams.STREAM_ENCOUNTERS, 17))
	_expect_equal(replay_sequence, first_sequence, "restart: random stream state resets reproducibly")


func test_encounter_composition_reset_synchronously_removes_stale_run_nodes() -> void:
	var director: RunDirector = _new_active_run(416)
	var combat: CombatDirector = _new_combat_director()
	var rewards: RewardDirector = _new_reward_director(director.get_random_streams())
	var owner: Node2D = track(Node2D.new()) as Node2D
	var crew: Node2D = Node2D.new()
	var enemies: Node2D = Node2D.new()
	var loot: Node2D = Node2D.new()
	var left_spawn: Marker2D = Marker2D.new()
	var right_spawn: Marker2D = Marker2D.new()
	left_spawn.position = Vector2(164.0, 226.0)
	right_spawn.position = Vector2(456.0, 226.0)
	owner.add_child(crew)
	owner.add_child(enemies)
	owner.add_child(loot)
	owner.add_child(left_spawn)
	owner.add_child(right_spawn)
	var encounters: RunEncounterController = track(RunEncounterController.new()) as RunEncounterController
	encounters.configure(
		director,
		combat,
		rewards,
		crew,
		enemies,
		loot,
		left_spawn,
		right_spawn
	)
	var jax: ActorController = _new_actor(true, 220.0, 1)
	jax.name = "Jax"
	crew.add_child(jax)
	combat.register_actor(jax)
	for enemy_index: int in range(3):
		var enemy: ActorController = _new_actor(false, 360.0 + float(enemy_index), enemy_index)
		enemy.name = "StreetPunk%03d" % (enemy_index + 1)
		enemies.add_child(enemy)
		combat.register_actor(enemy)
	var loot_marker: Node2D = Node2D.new()
	loot_marker.name = "PendingLoot"
	loot.add_child(loot_marker)
	jax.assign_target(enemies.get_child(0) as ActorController)
	combat.reserve_attack_position(jax, enemies.get_child(0) as ActorController)
	_expect_equal(crew.get_child_count(), 1, "composition reset: one crew actor before reset")
	_expect_equal(enemies.get_child_count(), 3, "composition reset: three enemies before reset")
	_expect_equal(combat.get_registered_count(), 4, "composition reset: four actors registered")
	_expect_equal(combat.get_reservation_snapshot().size(), 1, "composition reset: stale reservation candidate exists")
	encounters.reset_for_run()
	_expect_equal(crew.get_child_count(), 0, "composition reset: crew container clears immediately")
	_expect_equal(enemies.get_child_count(), 0, "composition reset: enemy container clears immediately")
	_expect_equal(loot.get_child_count(), 0, "composition reset: loot container clears immediately")
	_expect_equal(combat.get_registered_count(), 0, "composition reset: registrations clear immediately")
	_expect_equal(combat.get_reservation_snapshot().size(), 0, "composition reset: reservations clear immediately")
	var fresh_jax: Node2D = Node2D.new()
	fresh_jax.name = "Jax"
	crew.add_child(fresh_jax)
	_expect_equal(crew.get_child_count(), 1, "composition reset: exactly one fresh crew actor")
	_expect_equal(crew.get_child(0).name, &"Jax", "composition reset: no duplicate-name fallback")


func _new_run_director() -> RunDirector:
	var director: RunDirector = track(RunDirector.new()) as RunDirector
	var streams: RunRandomStreams = RunRandomStreams.new()
	streams.name = "RunRandomStreams"
	director.add_child(streams)
	director._ready()
	director.set_process(false)
	return director


func _new_active_run(seed: int) -> RunDirector:
	var director: RunDirector = _new_run_director()
	director.start_run(seed, true)
	director.complete_intro()
	return director


func _new_reward_director(streams: RunRandomStreams) -> RewardDirector:
	var rewards: RewardDirector = track(RewardDirector.new()) as RewardDirector
	rewards._ready()
	rewards.set_process(false)
	rewards.configure_random_streams(streams)
	rewards.reset_for_run()
	return rewards


func _new_patrol_controller() -> PatrolController:
	var patrol: PatrolController = track(PatrolController.new()) as PatrolController
	patrol.route_definition = ROUTE_TUNING
	patrol._ready()
	patrol.set_process(false)
	return patrol


func _new_cooling_controller(
	director: RunDirector,
	rewards: RewardDirector,
	patrol: PatrolController
) -> RunCoolingController:
	var cooling: RunCoolingController = track(RunCoolingController.new()) as RunCoolingController
	cooling.tuning = COOLING_TUNING
	cooling._ready()
	cooling.configure(director, rewards, patrol)
	return cooling


func _new_combat_director() -> CombatDirector:
	var combat: CombatDirector = track(CombatDirector.new()) as CombatDirector
	combat.combat_space = CombatSpaceDefinition.new()
	combat._ready()
	combat.set_physics_process(false)
	return combat


func _new_actor(
	is_crew: bool,
	world_x: float,
	lane: int,
	initialize: bool = true
) -> ActorController:
	var actor: ActorController = track(ActorController.new()) as ActorController
	actor.actor_definition = JAX_DEFINITION if is_crew else STREET_PUNK_DEFINITION
	actor.attack_definition = JAX_ATTACK if is_crew else STREET_PUNK_ATTACK
	actor.team = ActorController.Team.CREW if is_crew else ActorController.Team.ENEMY
	actor.initial_lane = lane
	actor.lane_index = lane
	actor.configure_combat_space(CombatSpaceDefinition.new())
	actor.position = Vector2(world_x, actor.get_combat_space().lane_y(lane))
	actor.state_machine = ActorStateMachine.new()
	actor.health_component = HealthComponent.new()
	actor.attack_controller = AttackController.new()
	actor.attack_hitbox = Area2D.new()
	actor.actor_visual = ActorVisual.new()
	actor.add_child(actor.state_machine)
	actor.add_child(actor.health_component)
	actor.add_child(actor.attack_controller)
	actor.add_child(actor.attack_hitbox)
	actor.add_child(actor.actor_visual)
	if initialize:
		actor.initialize_runtime()
	return actor


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(
		absf(actual - expected) <= EPSILON,
		"%s (expected %.6f, got %.6f)" % [context, expected, actual]
	)
