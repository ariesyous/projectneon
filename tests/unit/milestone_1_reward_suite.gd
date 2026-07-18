@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const DEFAULT_AUTO_COLLECT_MSEC: int = 2500
const DEFAULT_STREAK_WINDOW_MSEC: int = 3000

class RewardSignalCapture:
	extends RefCounted

	var resolution_events: Array[Dictionary] = []
	var coin_totals: Array[int] = []
	var streak_events: Array[Dictionary] = []

	func on_cluster_resolved(
		cluster_id: int,
		manual: bool,
		base_value: int,
		bonus_value: int,
		resulting_streak: int
	) -> void:
		resolution_events.append({
			"cluster_id": cluster_id,
			"manual": manual,
			"base_value": base_value,
			"bonus_value": bonus_value,
			"resulting_streak": resulting_streak,
		})

	func on_coins_changed(total_coins: int) -> void:
		coin_totals.append(total_coins)

	func on_streak_changed(streak_count: int, expires_at_msec: int) -> void:
		streak_events.append({
			"streak_count": streak_count,
			"expires_at_msec": expires_at_msec,
		})


class ReentrantResolutionCapture:
	extends RefCounted

	var director: RewardDirector
	var callback_count: int = 0
	var reentrant_request_succeeded: bool = true

	func on_cluster_resolved(
		cluster_id: int,
		_manual: bool,
		_base_value: int,
		_bonus_value: int,
		_resulting_streak: int
	) -> void:
		callback_count += 1
		reentrant_request_succeeded = director.request_manual_collection(cluster_id)


func suite_name() -> String:
	return "milestone_1_rewards"


func test_manual_collection_awards_positive_capped_bonus() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	_expect_true(director.register_coin_cluster(1, 40), "manual: registration succeeds")
	_expect_true(director.request_manual_collection(1, 100), "manual: collection succeeds")
	_expect_equal(director.get_coin_total(), 41, "manual: 40 base plus floor(2.5%) is awarded")
	_expect_equal(director.get_active_streak_count(), 1, "manual: first successful click starts streak")
	_expect_equal(director.get_active_cluster_count(), 0, "manual: resolved record is removed")
	_expect_equal(capture.resolution_events.size(), 1, "manual: resolution emits once")
	_expect_equal(capture.resolution_events[0]["bonus_value"], 1, "manual: signal reports bonus")
	_expect_equal(capture.coin_totals, [41], "manual: coin total update is authoritative")
	_expect_equal(capture.streak_events.size(), 1, "manual: streak update emits once")


func test_auto_collection_awards_complete_base_only() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	_expect_true(director.register_coin_cluster(2, 40), "auto: registration succeeds")
	director.process_until(DEFAULT_AUTO_COLLECT_MSEC - 1)
	_expect_equal(director.get_coin_total(), 0, "auto: no early award")
	_expect_equal(director.get_active_cluster_count(), 1, "auto: cluster remains before deadline")
	director.process_until(DEFAULT_AUTO_COLLECT_MSEC)
	_expect_equal(director.get_coin_total(), 40, "auto: full base value is awarded")
	_expect_equal(director.get_active_streak_count(), 0, "auto: streak does not start")
	_expect_equal(capture.resolution_events.size(), 1, "auto: resolution emits once")
	_expect_false(capture.resolution_events[0]["manual"], "auto: signal identifies timeout")
	_expect_equal(capture.resolution_events[0]["bonus_value"], 0, "auto: no manual bonus")
	_expect_equal(capture.streak_events.size(), 0, "auto: no streak update")


func test_click_first_before_timeout() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(3, 40)
	_expect_true(director.request_manual_collection(3, 2499), "click-first: click succeeds")
	director.process_until(2500)
	_expect_equal(director.get_coin_total(), 41, "click-first: timeout cannot duplicate award")
	_expect_equal(capture.resolution_events.size(), 1, "click-first: signal emits once")


func test_timeout_first_before_late_click() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(4, 40)
	director.process_until(2500)
	_expect_false(director.request_manual_collection(4, 2501), "timeout-first: late click fails")
	_expect_equal(director.get_coin_total(), 40, "timeout-first: base is not duplicated")
	_expect_equal(capture.resolution_events.size(), 1, "timeout-first: signal emits once")


func test_click_first_at_same_tick() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(5, 40)
	_expect_true(director.request_manual_collection(5, 2500), "same-tick click-first: click wins")
	director.process_until(2500)
	_expect_equal(director.get_coin_total(), 41, "same-tick click-first: one manual award")
	_expect_true(capture.resolution_events[0]["manual"], "same-tick click-first: manual result")
	_expect_equal(capture.resolution_events.size(), 1, "same-tick click-first: one signal")


func test_timeout_first_at_same_tick() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(6, 40)
	director.process_until(2500)
	_expect_false(director.request_manual_collection(6, 2500), "same-tick timeout-first: click loses")
	_expect_equal(director.get_coin_total(), 40, "same-tick timeout-first: one auto award")
	_expect_false(capture.resolution_events[0]["manual"], "same-tick timeout-first: auto result")
	_expect_equal(capture.resolution_events.size(), 1, "same-tick timeout-first: one signal")


func test_repeated_and_late_input_are_no_ops() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(7, 40)
	_expect_true(director.request_manual_collection(7, 200), "repeat: first click succeeds")
	_expect_false(director.request_manual_collection(7, 200), "repeat: same-tick repeat fails")
	_expect_false(director.request_manual_collection(7, 201), "repeat: later repeat fails")
	director.process_until(5000)
	_expect_false(director.request_manual_collection(7, 5000), "repeat: late click fails")
	_expect_equal(director.get_coin_total(), 41, "repeat: total remains at one award")
	_expect_equal(capture.resolution_events.size(), 1, "repeat: one resolution signal")


func test_exact_streak_boundary_advances() -> void:
	var director: RewardDirector = _new_director(10000)
	director.register_coin_cluster(8, 40, 0)
	director.request_manual_collection(8, 0)
	director.register_coin_cluster(9, 40, 100)
	_expect_true(director.request_manual_collection(9, 3000), "boundary: click exactly at 3s succeeds")
	_expect_equal(director.get_active_streak_count(), 2, "boundary: exact window advances streak")
	_expect_equal(director.get_coin_total(), 83, "boundary: second click receives 5% floor bonus")


func test_expired_streak_resets_before_manual_collection() -> void:
	var director: RewardDirector = _new_director(10000)
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(10, 40, 0)
	director.request_manual_collection(10, 0)
	director.register_coin_cluster(11, 40, 100)
	director.process_until(3001)
	_expect_equal(director.get_active_streak_count(), 0, "expiry: streak clears after exact boundary")
	_expect_true(director.request_manual_collection(11, 3001), "expiry: next click succeeds")
	_expect_equal(director.get_active_streak_count(), 1, "expiry: next click starts a new streak")
	_expect_equal(director.get_coin_total(), 82, "expiry: both clicks use first-tier bonus")
	_expect_equal(capture.streak_events[1]["streak_count"], 0, "expiry: clear signal precedes restart")


func test_auto_collection_does_not_advance_streak_or_receive_bonus() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(12, 40, 0)
	director.request_manual_collection(12, 0)
	director.register_coin_cluster(13, 40, 100)
	director.process_until(2600)
	_expect_equal(director.get_active_streak_count(), 1, "auto exclusion: auto does not advance streak")
	_expect_equal(capture.resolution_events[1]["bonus_value"], 0, "auto exclusion: auto gets no bonus")
	director.register_coin_cluster(14, 40, 2600)
	director.request_manual_collection(14, 2700)
	_expect_equal(director.get_active_streak_count(), 2, "auto exclusion: next manual is streak two")
	_expect_equal(director.get_coin_total(), 123, "auto exclusion: mixed total is exact")


func test_deterministic_floor_rounding() -> void:
	var director: RewardDirector = _new_director(
		DEFAULT_AUTO_COLLECT_MSEC,
		DEFAULT_STREAK_WINDOW_MSEC,
		PackedInt32Array([333])
	)
	director.register_coin_cluster(15, 101)
	director.request_manual_collection(15, 0)
	_expect_equal(director.get_coin_total(), 104, "rounding: 3.3633 coins floors deterministically to 3")


func test_malicious_schedule_is_capped_at_ten_percent() -> void:
	var director: RewardDirector = _new_director(
		DEFAULT_AUTO_COLLECT_MSEC,
		DEFAULT_STREAK_WINDOW_MSEC,
		PackedInt32Array([50000])
	)
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(16, 99)
	director.request_manual_collection(16, 0)
	_expect_equal(capture.resolution_events[0]["bonus_value"], 9, "cap: malicious 500% tuning clamps to floor(10%)")
	_expect_equal(director.get_coin_total(), 108, "cap: total cannot exceed base plus floor 10%")


func test_mixed_manual_and_auto_totals() -> void:
	var director: RewardDirector = _new_director()
	director.register_coin_cluster(17, 40, 0)
	director.request_manual_collection(17, 0)
	director.register_coin_cluster(18, 80, 0)
	director.process_until(2500)
	director.register_coin_cluster(19, 60, 2500)
	director.request_manual_collection(19, 2600)
	# 40 + 1, 80 auto, 60 + 3 (second manual tier at 5%).
	_expect_equal(director.get_coin_total(), 184, "mixed totals: all bases and only manual bonuses sum exactly")


func test_rewardless_values_are_rejected() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	_expect_false(director.register_coin_cluster(20, 0), "rewardless: zero base is rejected")
	_expect_false(director.register_coin_cluster(21, -10), "rewardless: negative base is rejected")
	_expect_equal(director.get_active_cluster_count(), 0, "rewardless: no presentation record exists")
	_expect_equal(director.get_coin_total(), 0, "rewardless: ledger remains unchanged")
	_expect_equal(capture.resolution_events.size(), 0, "rewardless: no resolution emits")


func test_cluster_ids_are_unique_for_director_lifetime() -> void:
	var director: RewardDirector = _new_director()
	_expect_true(director.register_coin_cluster(22, 40), "unique ID: first registration succeeds")
	_expect_false(director.register_coin_cluster(22, 80), "unique ID: active duplicate is rejected")
	director.request_manual_collection(22, 0)
	_expect_false(director.register_coin_cluster(22, 80), "unique ID: resolved ID cannot be reused")
	_expect_equal(director.get_coin_total(), 41, "unique ID: duplicate registration never awards")


func test_timeout_order_is_deadline_then_cluster_id() -> void:
	var director: RewardDirector = _new_director()
	var capture: RewardSignalCapture = _capture_signals(director)
	director.register_coin_cluster(29, 10, 0)
	director.register_coin_cluster(24, 10, 500)
	director.register_coin_cluster(23, 10, 500)
	director.process_until(3000)
	var resolved_ids: Array[int] = []
	for event: Dictionary in capture.resolution_events:
		resolved_ids.append(event["cluster_id"])
	_expect_equal(resolved_ids, [29, 23, 24], "timeout order: earlier deadline then ascending ID")


func test_record_is_erased_before_resolution_signal() -> void:
	var director: RewardDirector = _new_director()
	var capture: ReentrantResolutionCapture = ReentrantResolutionCapture.new()
	capture.director = director
	director.cluster_resolved.connect(capture.on_cluster_resolved)
	director.register_coin_cluster(25, 40)
	director.request_manual_collection(25, 0)
	_expect_equal(capture.callback_count, 1, "reentrancy: resolution callback occurs once")
	_expect_false(capture.reentrant_request_succeeded, "reentrancy: record is gone before callback")
	_expect_equal(director.get_coin_total(), 41, "reentrancy: callback cannot duplicate award")


func test_simulation_clock_is_monotonic() -> void:
	var director: RewardDirector = _new_director()
	director.process_until(100)
	director.process_until(50)
	_expect_equal(director.get_current_time_msec(), 100, "clock: explicit backwards time is ignored")
	director._process(0.0004)
	_expect_equal(director.get_current_time_msec(), 100, "clock: fractional milliseconds accumulate")
	director._process(0.0006)
	_expect_equal(director.get_current_time_msec(), 101, "clock: accumulated millisecond advances once")


func test_debug_snapshot_reports_authoritative_state() -> void:
	var director: RewardDirector = _new_director()
	director.register_coin_cluster(27, 40)
	director.register_coin_cluster(26, 80)
	var snapshot: Dictionary = director.get_debug_snapshot()
	_expect_equal(snapshot["simulation_time_msec"], 0, "snapshot: current clock")
	_expect_equal(snapshot["coin_total"], 0, "snapshot: current ledger")
	_expect_equal(snapshot["active_cluster_count"], 2, "snapshot: active count")
	_expect_equal(snapshot["active_cluster_ids"], [26, 27], "snapshot: IDs are stable-sorted")
	_expect_equal(director.get_cluster_expires_at_msec(26), 2500, "snapshot: expiry getter")
	_expect_equal(director.get_cluster_expires_at_msec(999), -1, "snapshot: absent expiry sentinel")


func _new_director(
	auto_collect_msec: int = DEFAULT_AUTO_COLLECT_MSEC,
	streak_window_msec: int = DEFAULT_STREAK_WINDOW_MSEC,
	bonus_schedule: PackedInt32Array = PackedInt32Array([250, 500, 750, 1000])
) -> RewardDirector:
	var director: RewardDirector = RewardDirector.new()
	var test_tuning: CoinClusterTuning = CoinClusterTuning.new()
	test_tuning.auto_collect_delay_msec = auto_collect_msec
	test_tuning.manual_streak_window_msec = streak_window_msec
	test_tuning.manual_bonus_basis_points_by_streak = PackedInt32Array(bonus_schedule)
	director.configure(test_tuning)
	return director


func _capture_signals(director: RewardDirector) -> RewardSignalCapture:
	var capture: RewardSignalCapture = RewardSignalCapture.new()
	director.cluster_resolved.connect(capture.on_cluster_resolved)
	director.coins_changed.connect(capture.on_coins_changed)
	director.streak_changed.connect(capture.on_streak_changed)
	return capture


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)
