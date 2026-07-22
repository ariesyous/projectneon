@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EPSILON: float = 0.0001
const LIFECYCLE: RunLifecycleDefinition = preload(
	"res://data/run/milestone_6_run_lifecycle.tres"
)
const COMBO_TUNING: ComboTuningDefinition = preload(
	"res://data/combat/milestone_6_combo.tres"
)
const CADENCE_TUNING: RunCadenceDefinition = preload(
	"res://data/run/milestone_6_cadence.tres"
)


class RunSignalCapture extends RefCounted:
	var completions: Array[int] = []
	var boss_intro_durations: Array[float] = []
	var victory_durations: Array[float] = []
	var victory_completion_count: int = 0

	func on_run_completed(result: int) -> void:
		completions.append(result)

	func on_boss_intro_started(duration_seconds: float) -> void:
		boss_intro_durations.append(duration_seconds)

	func on_victory_started(duration_seconds: float) -> void:
		victory_durations.append(duration_seconds)

	func on_victory_completed() -> void:
		victory_completion_count += 1


class ComboSignalCapture extends RefCounted:
	var milestones: Array[int] = []
	var expired_values: Array[int] = []

	func on_milestone(milestone: int) -> void:
		milestones.append(milestone)

	func on_expired(expired_combo: int) -> void:
		expired_values.append(expired_combo)


func suite_name() -> String:
	return "milestone_6_runtime_systems"


func test_authored_lifecycle_combo_and_cadence_resources() -> void:
	_expect_equal(LIFECYCLE.id, &"milestone_6_run_lifecycle", "lifecycle: stable id")
	_expect_approx(LIFECYCLE.intro_duration_seconds, 1.25, "lifecycle: intro duration")
	_expect_approx(LIFECYCLE.extraction_duration_seconds, 1.0, "lifecycle: extraction duration")
	_expect_approx(LIFECYCLE.boss_intro_duration_seconds, 2.5, "lifecycle: boss intro duration")
	_expect_approx(
		LIFECYCLE.victory_presentation_duration_seconds,
		2.0,
		"lifecycle: victory presentation duration"
	)
	_expect_equal(LIFECYCLE.validation_errors(), PackedStringArray(), "lifecycle: resource validates")
	_expect_equal(COMBO_TUNING.id, &"milestone_6_combo", "combo: stable id")
	_expect_approx(COMBO_TUNING.expiry_seconds, 2.5, "combo: exact eligible-time expiry")
	_expect_equal(
		COMBO_TUNING.presentation_milestones,
		PackedInt32Array([10, 20, 30, 50]),
		"combo: authored presentation milestones"
	)
	_expect_equal(COMBO_TUNING.validation_errors(), PackedStringArray(), "combo: resource validates")
	_expect_equal(CADENCE_TUNING.id, &"milestone_6_cadence", "cadence: stable id")
	_expect_approx(CADENCE_TUNING.ambient_minimum_seconds, 10.0, "cadence: ambient minimum")
	_expect_approx(CADENCE_TUNING.ambient_maximum_seconds, 20.0, "cadence: ambient maximum")
	_expect_approx(CADENCE_TUNING.strategic_minimum_seconds, 30.0, "cadence: strategic minimum")
	_expect_approx(CADENCE_TUNING.strategic_maximum_seconds, 60.0, "cadence: strategic maximum")
	_expect_approx(CADENCE_TUNING.major_minimum_seconds, 120.0, "cadence: major minimum")
	_expect_approx(CADENCE_TUNING.major_maximum_seconds, 180.0, "cadence: major maximum")
	_expect_equal(CADENCE_TUNING.validation_errors(), PackedStringArray(), "cadence: resource validates")


func test_null_lifecycle_preserves_manual_boss_intro_and_immediate_victory() -> void:
	var director: RunDirector = _new_run_director(null)
	var capture: RunSignalCapture = RunSignalCapture.new()
	director.run_completed.connect(capture.on_run_completed)
	director.start_run(6001, true)
	director.complete_intro()
	director.add_night_pressure(50.0)
	_expect_true(director.notify_safe_transition_boundary(), "fallback: boss intro begins")
	_expect_equal(director.current_state, RunDirector.RunState.BOSS_INTRO, "fallback: intro is manual")
	director.step_run(100.0)
	_expect_equal(
		director.current_state,
		RunDirector.RunState.BOSS_INTRO,
		"fallback: elapsed time cannot steal the accepted manual completion contract"
	)
	_expect_true(director.complete_boss_intro(), "fallback: explicit completion remains usable")
	_expect_true(director.notify_boss_defeated(), "fallback: boss defeat accepted")
	_expect_equal(
		capture.completions,
		[RunDirector.RunResult.VICTORY],
		"fallback: victory completion remains immediate"
	)
	director.step_run(100.0)
	_expect_equal(capture.completions.size(), 1, "fallback: completion emits exactly once")


func test_milestone_6_lifecycle_automates_boss_intro_and_delays_victory_completion() -> void:
	var director: RunDirector = _new_run_director(LIFECYCLE)
	var capture: RunSignalCapture = RunSignalCapture.new()
	director.run_completed.connect(capture.on_run_completed)
	director.boss_intro_timing_started.connect(capture.on_boss_intro_started)
	director.victory_presentation_started.connect(capture.on_victory_started)
	director.victory_presentation_completed.connect(capture.on_victory_completed)
	director.start_run(6002, true)
	director.step_run(1.24)
	_expect_equal(director.current_state, RunDirector.RunState.INTRO, "timing: intro remains before edge")
	director.step_run(0.02)
	_expect_equal(director.current_state, RunDirector.RunState.PATROLLING, "timing: intro completes automatically")
	director.add_night_pressure(50.0)
	_expect_true(director.notify_safe_transition_boundary(), "timing: boss intro begins at safe boundary")
	_expect_equal(capture.boss_intro_durations, [2.5], "timing: authored boss intro announced")
	director.step_run(2.49)
	_expect_equal(director.current_state, RunDirector.RunState.BOSS_INTRO, "timing: boss intro remains before edge")
	director.step_run(0.02)
	_expect_equal(director.current_state, RunDirector.RunState.BOSS_ACTIVE, "timing: boss activates automatically")
	_expect_true(director.notify_boss_defeated(), "timing: boss defeat enters victory")
	_expect_equal(director.current_state, RunDirector.RunState.VICTORY, "timing: victory presentation state")
	_expect_equal(capture.victory_durations, [2.0], "timing: authored victory duration announced")
	_expect_equal(capture.completions.size(), 0, "timing: outcome waits for presentation")
	director.step_run(1.99)
	_expect_equal(capture.completions.size(), 0, "timing: completion remains pending before edge")
	director.step_run(0.02)
	_expect_equal(
		capture.completions,
		[RunDirector.RunResult.VICTORY],
		"timing: victory completes after authored delay"
	)
	_expect_equal(capture.victory_completion_count, 1, "timing: presentation completes once")
	director.step_run(20.0)
	_expect_equal(capture.completions.size(), 1, "timing: delayed completion cannot duplicate")


func test_summary_extension_preserves_old_positional_api_and_adds_m6_fields() -> void:
	var director: RunDirector = _new_run_director(null)
	director.start_run(6003, true)
	director.complete_intro()
	director.add_night_pressure(50.0)
	director.notify_safe_transition_boundary()
	director.complete_boss_intro()
	director.notify_boss_defeated()
	var summary: RunSummaryRecord = director.finalize_summary(
		24,
		250,
		6,
		5,
		32,
		"JAX / FLAIL / BOOTS / JACKET",
		"KNOCKBACK 2",
		3,
		41
	)
	_expect_true(summary != null, "summary: direct finalization remains available")
	_expect_equal(summary.elites_defeated, 3, "summary: elite count appended")
	_expect_equal(summary.highest_combo, 41, "summary: highest combo appended")
	_expect_equal(summary.boss_result, "DEFEATED", "summary: textual boss result derived")
	_expect_equal(summary.to_dictionary().get("boss_result"), "DEFEATED", "summary: dictionary includes boss text")
	_expect_equal(summary.equipment_build, "JAX / FLAIL / BOOTS / JACKET", "summary: old equipment position preserved")
	_expect_equal(summary.active_synergies, "KNOCKBACK 2", "summary: old synergy position preserved")

	var defeat: RunDirector = _new_run_director(null)
	defeat.start_run(6004, true)
	defeat.complete_intro()
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &"summary_probe"
	_expect_true(defeat.begin_encounter(encounter), "summary: defeat probe encounter starts")
	_expect_true(defeat.notify_all_crew_incapacitated(), "summary: defeat accepted")
	var old_api_summary: RunSummaryRecord = defeat.finalize_summary(1, 2, 3, 4, 5)
	_expect_equal(old_api_summary.elites_defeated, 0, "summary: appended elite default preserves old calls")
	_expect_equal(old_api_summary.highest_combo, 0, "summary: appended combo default preserves old calls")
	_expect_equal(old_api_summary.boss_result, "NOT REACHED", "summary: pre-boss defeat is explicit")


func test_combo_is_shared_environmentally_continued_and_uses_only_eligible_time() -> void:
	var tracker: ComboTracker = track(ComboTracker.new()) as ComboTracker
	tracker.tuning = COMBO_TUNING
	tracker._ready()
	var capture: ComboSignalCapture = ComboSignalCapture.new()
	tracker.presentation_milestone_reached.connect(capture.on_milestone)
	tracker.combo_expired.connect(capture.on_expired)
	for hit_index: int in range(9):
		_expect_true(tracker.record_crew_hit(), "combo: crew hit %d accepted" % hit_index)
	_expect_true(tracker.record_environmental_hit(), "combo: environmental hit continues shared combo")
	_expect_equal(tracker.get_current_combo(), 10, "combo: one shared counter")
	_expect_equal(tracker.get_highest_combo(), 10, "combo: highest tracks shared counter")
	_expect_equal(capture.milestones, [10], "combo: presentation milestone is data driven")
	var before_invalid: Dictionary = tracker.get_snapshot()
	_expect_false(tracker.record_successful_hit(&"enemy"), "combo: non-crew source rejected")
	_expect_equal(tracker.get_snapshot(), before_invalid, "combo: rejected source is immutable")
	_expect_false(tracker.step_eligible_time(2.49), "combo: active before exact expiry")
	_expect_equal(tracker.get_current_combo(), 10, "combo: remains before expiry")
	_expect_true(tracker.record_environmental_hit(), "combo: continuation resets eligible timer")
	_expect_false(tracker.step_eligible_time(2.49), "combo: reset timer remains active")
	_expect_true(tracker.step_eligible_time(0.02), "combo: expires after 2.5 eligible seconds")
	_expect_equal(tracker.get_current_combo(), 0, "combo: expiry clears current value")
	_expect_equal(tracker.get_highest_combo(), 11, "combo: expiry retains run high")
	_expect_equal(capture.expired_values, [11], "combo: expiry publishes the ended value")
	tracker.reset_for_run()
	_expect_equal(tracker.get_highest_combo(), 0, "combo: restart clears run high")
	_expect_equal(tracker.get_snapshot().get("presentation_only"), true, "combo: explicitly presentation only")


func test_cadence_records_authoritative_gaps_without_promoting_coins() -> void:
	var tracker: RunCadenceTracker = track(RunCadenceTracker.new()) as RunCadenceTracker
	tracker.definition = CADENCE_TUNING
	tracker._ready()
	_expect_true(tracker.record_ambient_opportunity(&"hydrant_ready", 10.0), "cadence: ambient edge accepted")
	_expect_true(tracker.record_coin_cluster_presented(7, 20.0), "cadence: coin presentation is ambient")
	_expect_true(tracker.record_strategic_opportunity(&"equipment_choice", 30.0), "cadence: strategic edge accepted")
	_expect_true(tracker.record_major_opportunity(&"extraction_offer", 120.0), "cadence: major edge accepted")
	_expect_equal(tracker.get_event_count(RunCadenceTracker.CATEGORY_AMBIENT), 2, "cadence: ambient count")
	_expect_equal(tracker.get_event_count(RunCadenceTracker.CATEGORY_STRATEGIC), 1, "cadence: strategic count excludes coin")
	_expect_equal(tracker.get_event_count(RunCadenceTracker.CATEGORY_MAJOR), 1, "cadence: major count")
	_expect_approx(tracker.get_last_gap(RunCadenceTracker.CATEGORY_AMBIENT), 10.0, "cadence: ambient gap")
	_expect_equal(
		tracker.get_gap_validation(RunCadenceTracker.CATEGORY_STRATEGIC, 29.0),
		RunCadenceTracker.VALIDATION_TOO_SOON,
		"cadence: too-soon measurement"
	)
	_expect_equal(
		tracker.get_gap_validation(RunCadenceTracker.CATEGORY_MAJOR, 181.0),
		RunCadenceTracker.VALIDATION_TOO_LATE,
		"cadence: too-late measurement"
	)
	var before_rejections: Dictionary = tracker.get_snapshot()
	_expect_false(
		tracker.record_strategic_opportunity(&"coin_click", 130.0),
		"cadence: coins cannot be relabelled strategic"
	)
	_expect_equal(tracker.get_snapshot(), before_rejections, "cadence: coin rejection is immutable")
	_expect_false(
		tracker.record_ambient_opportunity(&"stale_probe", 119.0),
		"cadence: stale authoritative timestamp rejected"
	)
	_expect_equal(tracker.get_snapshot(), before_rejections, "cadence: stale rejection is immutable")
	_expect_equal(before_rejections.get("coin_cluster_presentations"), 1, "cadence: coin presentation separately counted")
	_expect_equal(before_rejections.get("coin_collections_count_as_strategic"), false, "cadence: explicit coin contract")
	tracker.reset_for_run()
	_expect_equal(tracker.get_event_count(RunCadenceTracker.CATEGORY_AMBIENT), 0, "cadence: restart clears history")


func _new_run_director(lifecycle: RunLifecycleDefinition) -> RunDirector:
	var director: RunDirector = track(RunDirector.new()) as RunDirector
	director.lifecycle_definition = lifecycle
	var streams: RunRandomStreams = RunRandomStreams.new()
	streams.name = "RunRandomStreams"
	director.add_child(streams)
	director._ready()
	director.set_process(false)
	return director


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
