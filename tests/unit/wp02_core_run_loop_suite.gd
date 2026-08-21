@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const LOOP: DistrictLoopDefinition = preload("res://data/run/wp02_district_loop.tres")
const ROUTE: PatrolRouteDefinition = preload("res://data/routes/downtown_loop_route.tres")
const STANDARD_ENCOUNTER: EncounterDefinition = preload(
	"res://data/encounters/alley_scuffle.tres"
)
const UNLOCK_POLICY: UnlockPolicyDefinition = preload(
	"res://data/persistence/milestone_6_unlock_policy.tres"
)


func suite_name() -> String:
	return "wp02_core_run_loop"


func test_approved_definition_and_pure_three_by_three_transition_vector_are_locked() -> void:
	assert_eq(LOOP.validation_errors().size(), 0, "definition: exact WP02 tuning validates")
	assert_eq(LOOP.lap_count, 3, "definition: exactly three laps")
	assert_eq(LOOP.blocks_per_lap, 3, "definition: exactly three blocks per lap")
	assert_eq(LOOP.pressure_gain_multipliers, PackedFloat32Array([1.0, 1.15, 1.3]), "definition: pressure escalation vector")
	assert_eq(LOOP.reward_quality_tier_bonuses, PackedInt32Array([0, 1, 2]), "definition: reward escalation vector")
	assert_eq(ROUTE.travel_seconds_per_segment, 21.0, "definition: represented approach supports the 8-12 minute boss-run target")

	var lifecycle: DistrictRunLifecycle = DistrictRunLifecycle.new(LOOP)
	assert_true(lifecycle.start_run(), "vector: SELECT CREW enters INTRO")
	assert_eq(lifecycle.phase_name(), "INTRO", "vector: intro is explicit")
	assert_true(lifecycle.complete_intro(), "vector: intro enters first plan")
	assert_eq(lifecycle.phase_name(), "PLAN", "vector: PLAN is explicit")
	assert_eq(lifecycle.get_snapshot().get("block_id"), &"district_lap_01::block_01", "vector: first stable block ID")

	_resolve_lifecycle_fight(lifecycle, 1, 1)
	_resolve_lifecycle_fight(lifecycle, 1, 2)
	_resolve_lifecycle_fight(lifecycle, 1, 3)
	var first_decision: Dictionary = lifecycle.get_snapshot()
	assert_eq(first_decision.get("phase_name"), "LAP DECISION", "vector: lap one reaches decision")
	assert_eq(first_decision.get("decision_token"), 1, "vector: first decision token is stable")
	var first_preview: Dictionary = first_decision.get("push_preview", {})
	assert_eq(first_preview.get("lap_id"), &"district_lap_02", "vector: Push previews lap two")
	assert_eq(first_preview.get("modifier_id"), &"rising_pressure", "vector: lap two modifier is exact")
	assert_eq(first_preview.get("reward_quality_tier_bonus"), 1, "vector: lap two reward tier is exact")
	assert_false(bool(first_preview.get("final_lap_commitment", true)), "vector: first Push is not boss commitment")

	var before_stale: Dictionary = lifecycle.get_snapshot()
	assert_false(bool(lifecycle.accept_lap_decision(99, DistrictRunLifecycle.DECISION_PUSH).get("accepted", false)), "vector: stale token rejects")
	assert_eq(lifecycle.get_snapshot(), before_stale, "vector: stale decision is immutable")
	assert_true(bool(lifecycle.accept_lap_decision(1, DistrictRunLifecycle.DECISION_PUSH).get("accepted", false)), "vector: first Push accepted once")
	assert_eq(lifecycle.get_snapshot().get("lap_id"), &"district_lap_02", "vector: Push enters lap two")
	assert_false(bool(lifecycle.accept_lap_decision(1, DistrictRunLifecycle.DECISION_PUSH).get("accepted", false)), "vector: replayed first token rejects")

	_resolve_lifecycle_shop(lifecycle, 2, 1)
	_resolve_lifecycle_fight(lifecycle, 2, 2)
	_resolve_lifecycle_fight(lifecycle, 2, 3)
	var second_decision: Dictionary = lifecycle.get_snapshot()
	assert_eq(second_decision.get("decision_token"), 2, "vector: second decision token is stable")
	var second_preview: Dictionary = second_decision.get("push_preview", {})
	assert_eq(second_preview.get("lap_id"), &"district_lap_03", "vector: second Push previews lap three")
	assert_eq(second_preview.get("modifier_id"), &"boss_commitment", "vector: final modifier is exact")
	assert_eq(second_preview.get("reward_quality_tier_bonus"), 2, "vector: final reward tier is exact")
	assert_true(bool(second_preview.get("final_lap_commitment", false)), "vector: second Push names boss commitment")
	assert_eq(second_preview.get("next_decision_after_blocks"), 0, "vector: final lap has no routine extraction")
	assert_true(bool(lifecycle.accept_lap_decision(2, DistrictRunLifecycle.DECISION_PUSH).get("accepted", false)), "vector: boss commitment accepted")
	assert_true(lifecycle.boss_committed, "vector: boss commitment latches")

	_resolve_lifecycle_fight(lifecycle, 3, 1)
	_resolve_lifecycle_fight(lifecycle, 3, 2)
	_resolve_lifecycle_fight(lifecycle, 3, 3)
	assert_eq(lifecycle.phase_name(), "BOSS", "vector: block nine leads directly to boss")
	assert_eq(lifecycle.completed_laps, 3, "vector: all three laps complete")
	assert_eq(lifecycle.completed_blocks, 9, "vector: exactly nine blocks complete")
	assert_eq(lifecycle.get_accepted_decisions().size(), 2, "vector: only two lap decisions exist")


func test_run_director_tokens_precedence_summary_and_restart_are_authoritative() -> void:
	var director: RunDirector = _new_wp02_director()
	director.start_run(2202, true)
	director.complete_intro()
	var initial_draws: Dictionary = director.get_random_streams().get_debug_snapshot().get("draw_counts", {}).duplicate(true)
	director.add_night_pressure(100.0)
	assert_true(director.is_boss_threshold_latched(), "precedence: pressure threshold remains recorded")
	assert_false(director.is_boss_queued(), "precedence: pressure cannot bypass explicit laps")
	assert_false(director.notify_safe_transition_boundary(), "precedence: ordinary route boundary cannot start boss")

	for block_index: int in range(1, 4):
		_resolve_director_fight(director, 1, block_index)
	assert_eq(director.current_state, RunDirector.RunState.EXTRACTION_AVAILABLE, "authority: lap one opens decision")
	var first_token: int = director.get_district_decision_token()
	var first_snapshot: Dictionary = director.get_snapshot().duplicate(true)
	assert_false(director.decline_extraction(first_token + 1), "authority: stale Push token rejects")
	assert_eq(director.get_snapshot(), first_snapshot, "authority: stale Push mutates nothing")
	var heat_before_push: int = director.heat
	assert_true(director.decline_extraction(first_token), "authority: exact Push token accepted")
	assert_eq(director.heat, heat_before_push + LOOP.push_heat_delta, "authority: Push Heat applies once")
	assert_false(director.decline_extraction(first_token), "authority: replayed Push token rejects")
	assert_eq(director.heat, heat_before_push + LOOP.push_heat_delta, "authority: replayed Push adds no Heat")
	assert_eq(director.get_reward_quality_tier(), 1, "authority: lap two reward tier bonus applies")

	for block_index: int in range(1, 4):
		_resolve_director_fight(director, 2, block_index)
	var second_token: int = director.get_district_decision_token()
	assert_true(director.decline_extraction(second_token), "authority: final-lap commitment accepted")
	assert_true(bool(director.get_district_loop_snapshot().get("boss_committed", false)), "authority: commitment visible in snapshot")
	assert_eq(director.get_reward_quality_tier(), 2, "authority: final lap reward tier bonus applies")

	for block_index: int in range(1, 4):
		_resolve_director_fight(director, 3, block_index)
	assert_eq(director.current_state, RunDirector.RunState.BOSS_INTRO, "authority: block nine starts boss at safe boundary")
	assert_true(director.was_boss_started(), "authority: boss start latches once")
	assert_true(director.complete_boss_intro(), "authority: boss intro completes")
	assert_true(director.notify_boss_defeated(), "authority: boss defeat enters victory")
	var summary: RunSummaryRecord = director.finalize_summary(9, 90, 0, 0, 9)
	assert_eq(summary.laps_completed, 3, "summary: three completed laps")
	assert_eq(summary.blocks_completed, 9, "summary: nine completed blocks")
	assert_true(summary.boss_committed, "summary: boss commitment frozen")
	assert_eq(summary.lap_decisions.size(), 2, "summary: exact accepted decision trail")
	assert_eq(summary.final_lap_id, &"district_lap_03", "summary: stable final lap ID")
	assert_eq(director.get_random_streams().get_debug_snapshot().get("draw_counts", {}), initial_draws, "isolation: lifecycle consumes no random stream")

	assert_eq(director.restart_same_seed(), 2202, "restart: same seed retained")
	var reset_loop: Dictionary = director.get_district_loop_snapshot()
	assert_eq(reset_loop.get("phase_name"), "INTRO", "restart: lifecycle returns to intro")
	assert_eq(reset_loop.get("completed_blocks"), 0, "restart: blocks clear")
	assert_eq(reset_loop.get("decision_token"), -1, "restart: decision token clears")
	assert_eq(reset_loop.get("accepted_decisions", []).size(), 0, "restart: decision trail clears")


func test_extract_path_and_profile_migration_preserve_legacy_facts() -> void:
	var director: RunDirector = _new_wp02_director()
	director.start_run(2203, true)
	director.complete_intro()
	for block_index: int in range(1, 4):
		_resolve_director_fight(director, 1, block_index)
	var extract_token: int = director.get_district_decision_token()
	assert_true(director.confirm_extraction(extract_token), "extract: exact token accepted")
	assert_false(director.confirm_extraction(extract_token), "extract: replay rejected")
	director.step_run(director.get_extraction_duration_seconds() + 0.01)
	var summary: RunSummaryRecord = director.finalize_summary(3, 30, 0, 0, 3)
	assert_eq(summary.result_label, "EXTRACTED", "extract: result is exact")
	assert_eq(summary.laps_completed, 1, "extract: one lap secured")
	assert_eq(summary.blocks_completed, 3, "extract: three blocks secured")
	assert_false(summary.boss_committed, "extract: no boss commitment")
	assert_eq(summary.lap_decisions[0].get("decision"), &"extract", "extract: decision trail records Extract")

	var fresh: PersistentProfileData = PersistentProfileData.create_default()
	assert_eq(fresh.unlocked_crew_ids, [&"jax"], "migration: fresh v1 fact ledger stays compatible")
	assert_eq(fresh.get_accessible_crew_ids(false), PersistentProfileData.ALL_CREW_IDS, "migration: all crew available in production")
	var legacy: PersistentProfileData = PersistentProfileData.from_dictionary({
		"save_version": 1,
		"unlocked_crew_ids": ["jax", "zoey"],
	})
	assert_eq(legacy.unlocked_crew_ids, [&"jax", &"zoey"], "migration: historical Zoey fact retained")
	assert_eq(legacy.get_accessible_crew_ids(false), PersistentProfileData.ALL_CREW_IDS, "migration: missing Rex fact does not gate Rex")
	var serialized: Dictionary = legacy.to_dictionary()
	assert_eq(serialized.get("unlocked_crew_ids"), ["jax", "zoey"], "migration: load/serialize does not invent Rex fact")
	assert_eq(UNLOCK_POLICY.apply_completed_run(legacy, &"defeated", 0), [], "migration: completed run no longer grants Zoey")
	assert_eq(UNLOCK_POLICY.apply_completed_run(legacy, &"victory", 0), [], "migration: victory no longer grants Rex")
	assert_eq(UNLOCK_POLICY.apply_completed_run(legacy, &"defeated", 1), [&"hacker_deck"], "migration: Hacker Deck breadth rule remains")
	assert_eq(UNLOCK_POLICY.apply_completed_run(legacy, &"extracted", 0), [&"gang_hideout"], "migration: Gang Hideout breadth rule remains")
	assert_false(&"rex" in legacy.unlocked_crew_ids, "migration: retired rule does not invent Rex fact")


func test_invalid_transition_and_planning_pause_vectors_are_non_mutating() -> void:
	var director: RunDirector = _new_wp02_director()
	director.start_run(2204, true)
	var intro_loop: Dictionary = director.get_district_loop_snapshot().duplicate(true)
	assert_false(director.begin_encounter(STANDARD_ENCOUNTER), "invalid: intro cannot begin fight")
	assert_false(director.open_shop(), "invalid: intro cannot open shop")
	assert_eq(director.get_district_loop_snapshot(), intro_loop, "invalid: rejected intro intents preserve lifecycle")
	director.complete_intro()
	director.step_run(4.0)
	var elapsed_before_pause: float = director.run_elapsed_seconds
	var pressure_before_pause: float = director.night_pressure
	assert_true(director.begin_card_planning_pause(), "pause: PLAN can enter card-owned pause")
	var paused_loop: Dictionary = director.get_district_loop_snapshot().duplicate(true)
	director.step_run(90.0)
	assert_eq(director.run_elapsed_seconds, elapsed_before_pause, "pause: eligible time frozen")
	assert_eq(director.night_pressure, pressure_before_pause, "pause: Night Pressure frozen")
	assert_eq(director.get_district_loop_snapshot(), paused_loop, "pause: lifecycle identity frozen")
	assert_false(director.toggle_pause(), "pause: ordinary toggle cannot steal planning pause")
	assert_true(director.end_card_planning_pause(), "pause: explicit planning close resumes PLAN")
	assert_eq(director.get_district_loop_snapshot().get("phase_name"), "PLAN", "pause: authoritative PLAN resumes")


func _resolve_lifecycle_fight(
	lifecycle: DistrictRunLifecycle,
	lap_value: int,
	block_value: int
) -> void:
	assert_true(lifecycle.begin_block(StringName("occurrence_%02d_%02d" % [lap_value, block_value]), &"encounter"), "vector: block begins")
	assert_true(lifecycle.enter_fight(), "vector: block enters fight")
	assert_true(lifecycle.enter_reward(), "vector: fight enters reward")
	assert_true(lifecycle.complete_block() >= 0, "vector: reward completes block")


func _resolve_lifecycle_shop(
	lifecycle: DistrictRunLifecycle,
	lap_value: int,
	block_value: int
) -> void:
	assert_true(lifecycle.begin_block(StringName("occurrence_%02d_%02d" % [lap_value, block_value]), &"shop"), "vector: shop block begins")
	assert_true(lifecycle.enter_shop(), "vector: block enters shop")
	assert_true(lifecycle.complete_block() >= 0, "vector: shop completes block")


func _resolve_director_fight(director: RunDirector, lap_value: int, block_value: int) -> void:
	var occurrence_id: StringName = StringName("route::lap_%02d::block_%02d" % [lap_value, block_value])
	assert_true(director.begin_district_block(occurrence_id, &"encounter"), "director: stable block begins")
	assert_true(director.begin_encounter(STANDARD_ENCOUNTER), "director: fight begins")
	var encounter_id: int = (lap_value - 1) * 3 + block_value
	assert_true(director.notify_encounter_completed(encounter_id, STANDARD_ENCOUNTER), "director: fight completes once")
	assert_true(director.complete_reward_selection(), "director: reward completes block")


func _new_wp02_director() -> RunDirector:
	var director: RunDirector = track(RunDirector.new()) as RunDirector
	director.district_loop_definition = LOOP
	var streams: RunRandomStreams = RunRandomStreams.new()
	streams.name = "RunRandomStreams"
	director.add_child(streams)
	director._ready()
	director.set_process(false)
	return director
