## Authoritative Milestone 1 coin ledger and coin-cluster resolver.
## Presentation may request collection, but it never owns award state.
class_name RewardDirector
extends Node

signal cluster_registered(cluster_id: int, base_value: int, expires_at_msec: int)
signal cluster_resolved(
	cluster_id: int,
	manual: bool,
	base_value: int,
	bonus_value: int,
	resulting_streak: int
)
signal coins_changed(total_coins: int)
signal streak_changed(streak_count: int, expires_at_msec: int)
signal scrap_changed(total_scrap: int)
signal standard_reward_prepared(encounter_instance_id: int, reward: StandardRewardDefinition)
signal standard_reward_applied(
	encounter_instance_id: int,
	reward: StandardRewardDefinition,
	total_coins: int,
	total_scrap: int
)

const RESPONSIBILITY: String = "Own the coin ledger and resolve each coin cluster at most once."
const MAX_MANUAL_BONUS_BASIS_POINTS: int = 1000
const BASIS_POINTS_DENOMINATOR: int = 10000
const DEFAULT_TUNING: CoinClusterTuning = preload(
	"res://data/rewards/milestone_1_coin_cluster_tuning.tres"
)

class PendingCoinAward:
	extends RefCounted

	var cluster_id: int
	var base_value: int
	var registered_at_msec: int
	var expires_at_msec: int

	func _init(
		new_cluster_id: int,
		new_base_value: int,
		new_registered_at_msec: int,
		new_expires_at_msec: int
	) -> void:
		cluster_id = new_cluster_id
		base_value = new_base_value
		registered_at_msec = new_registered_at_msec
		expires_at_msec = new_expires_at_msec


@export var tuning: CoinClusterTuning = DEFAULT_TUNING
@export var standard_rewards: Array[StandardRewardDefinition] = []

var _simulation_time_msec: int = 0
var _sub_millisecond_remainder: float = 0.0
var _coin_total: int = 0
var _scrap_total: int = 0
var _active_streak_count: int = 0
var _maximum_manual_streak: int = 0
var _manual_clusters_collected: int = 0
var _last_manual_collection_msec: int = -1
var _streak_expires_at_msec: int = -1
var _active_awards: Dictionary[int, PendingCoinAward] = {}
var _registered_cluster_ids: Dictionary[int, bool] = {}
var _pending_standard_rewards: Dictionary[int, StandardRewardDefinition] = {}
var _applied_standard_reward_ids: Dictionary[int, bool] = {}
var _random_streams: RunRandomStreams
var simulation_enabled: bool = true


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING


func _process(delta: float) -> void:
	if not simulation_enabled or delta <= 0.0:
		return
	_sub_millisecond_remainder += delta * 1000.0
	var elapsed_msec: int = floori(_sub_millisecond_remainder)
	if elapsed_msec <= 0:
		return
	_sub_millisecond_remainder -= float(elapsed_msec)
	process_until(_simulation_time_msec + elapsed_msec)


func configure(new_tuning: CoinClusterTuning) -> void:
	tuning = new_tuning if new_tuning != null else DEFAULT_TUNING


func configure_random_streams(random_streams: RunRandomStreams) -> void:
	_random_streams = random_streams


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled


func reset_for_run() -> void:
	_simulation_time_msec = 0
	_sub_millisecond_remainder = 0.0
	_coin_total = 0
	_scrap_total = 0
	_active_streak_count = 0
	_maximum_manual_streak = 0
	_manual_clusters_collected = 0
	_last_manual_collection_msec = -1
	_streak_expires_at_msec = -1
	_active_awards.clear()
	_registered_cluster_ids.clear()
	_pending_standard_rewards.clear()
	_applied_standard_reward_ids.clear()
	coins_changed.emit(_coin_total)
	scrap_changed.emit(_scrap_total)
	streak_changed.emit(0, -1)


func prepare_standard_reward(
	encounter_instance_id: int,
	maximum_quality_tier: int,
	allowed_reward_ids: Array[StringName] = []
) -> StandardRewardDefinition:
	if (
		encounter_instance_id < 0
		or _pending_standard_rewards.has(encounter_instance_id)
		or _applied_standard_reward_ids.has(encounter_instance_id)
		or _random_streams == null
	):
		return null
	var candidate_by_id: Dictionary[StringName, StandardRewardDefinition] = {}
	var duplicate_ids: Dictionary[StringName, bool] = {}
	for reward: StandardRewardDefinition in standard_rewards:
		if (
			reward == null
			or reward.id == &""
			or reward.quality_tier > maximum_quality_tier
			or (not allowed_reward_ids.is_empty() and not allowed_reward_ids.has(reward.id))
		):
			continue
		if duplicate_ids.has(reward.id):
			continue
		if candidate_by_id.has(reward.id):
			candidate_by_id.erase(reward.id)
			duplicate_ids[reward.id] = true
			continue
		candidate_by_id[reward.id] = reward
	if candidate_by_id.is_empty():
		return null
	var highest_quality: int = -1
	for reward: StandardRewardDefinition in candidate_by_id.values():
		highest_quality = maxi(highest_quality, reward.quality_tier)
	var by_id: Dictionary[StringName, StandardRewardDefinition] = {}
	var ids: Array[StringName] = []
	for reward: StandardRewardDefinition in candidate_by_id.values():
		if reward.quality_tier != highest_quality:
			continue
		by_id[reward.id] = reward
		ids.append(reward.id)
	var selected_id: StringName = _random_streams.choose_stable_id(
		RunRandomStreams.STREAM_REWARDS,
		ids
	)
	var selected: StandardRewardDefinition = by_id.get(selected_id) as StandardRewardDefinition
	if selected == null:
		return null
	_pending_standard_rewards[encounter_instance_id] = selected
	standard_reward_prepared.emit(encounter_instance_id, selected)
	return selected


func apply_standard_reward(encounter_instance_id: int) -> bool:
	if _applied_standard_reward_ids.has(encounter_instance_id):
		return false
	var reward: StandardRewardDefinition = _pending_standard_rewards.get(
		encounter_instance_id
	) as StandardRewardDefinition
	if reward == null:
		return false
	_pending_standard_rewards.erase(encounter_instance_id)
	_applied_standard_reward_ids[encounter_instance_id] = true
	grant_coins(reward.coins)
	grant_scrap(reward.scrap)
	standard_reward_applied.emit(encounter_instance_id, reward, _coin_total, _scrap_total)
	return true


func get_pending_standard_reward(encounter_instance_id: int) -> StandardRewardDefinition:
	return _pending_standard_rewards.get(encounter_instance_id) as StandardRewardDefinition


func grant_coins(amount: int) -> int:
	var granted: int = maxi(amount, 0)
	if granted <= 0:
		return 0
	_coin_total += granted
	coins_changed.emit(_coin_total)
	return granted


func spend_coins(amount: int) -> bool:
	var cost: int = maxi(amount, 0)
	if cost > _coin_total:
		return false
	_coin_total -= cost
	coins_changed.emit(_coin_total)
	return true


func grant_scrap(amount: int) -> int:
	var granted: int = maxi(amount, 0)
	if granted <= 0:
		return 0
	_scrap_total += granted
	scrap_changed.emit(_scrap_total)
	return granted


func register_coin_cluster(
	cluster_id: int,
	base_value: int,
	registered_at_msec: int = -1
) -> bool:
	if base_value <= 0 or _registered_cluster_ids.has(cluster_id):
		return false
	var registration_time: int = _simulation_time_msec
	if registered_at_msec >= 0:
		registration_time = maxi(_simulation_time_msec, registered_at_msec)
		_simulation_time_msec = registration_time
	var delay_msec: int = maxi(1, _get_tuning().auto_collect_delay_msec)
	var expires_at_msec: int = registration_time + delay_msec
	var award: PendingCoinAward = PendingCoinAward.new(
		cluster_id,
		base_value,
		registration_time,
		expires_at_msec
	)
	_registered_cluster_ids[cluster_id] = true
	_active_awards[cluster_id] = award
	cluster_registered.emit(cluster_id, base_value, expires_at_msec)
	return true


func request_manual_collection(cluster_id: int, requested_at_msec: int = -1) -> bool:
	var award: PendingCoinAward = _active_awards.get(cluster_id) as PendingCoinAward
	if award == null:
		return false
	var request_time: int = _simulation_time_msec
	if requested_at_msec >= 0:
		request_time = maxi(_simulation_time_msec, requested_at_msec)
	# A request strictly after the authored deadline cannot overtake timeout.
	# At the exact deadline, call order decides the race through the same guard.
	if request_time > award.expires_at_msec:
		process_until(request_time)
		return false
	_simulation_time_msec = request_time
	_expire_streak_if_needed(request_time)
	return _resolve_cluster(cluster_id, true, request_time)


func process_until(requested_time_msec: int) -> void:
	var target_time_msec: int = maxi(_simulation_time_msec, requested_time_msec)
	_simulation_time_msec = target_time_msec
	_expire_streak_if_needed(target_time_msec)
	var expired_awards: Array[PendingCoinAward] = []
	for award: PendingCoinAward in _active_awards.values():
		if award.expires_at_msec <= target_time_msec:
			expired_awards.append(award)
	expired_awards.sort_custom(_award_expires_before)
	for award: PendingCoinAward in expired_awards:
		_resolve_cluster(award.cluster_id, false, award.expires_at_msec)


func get_current_time_msec() -> int:
	return _simulation_time_msec


func get_coin_total() -> int:
	return _coin_total


func get_scrap_total() -> int:
	return _scrap_total


func get_manual_clusters_collected() -> int:
	return _manual_clusters_collected


func get_maximum_manual_streak() -> int:
	return _maximum_manual_streak


func get_active_cluster_count() -> int:
	return _active_awards.size()


func get_active_streak_count() -> int:
	return _active_streak_count


func get_cluster_expires_at_msec(cluster_id: int) -> int:
	var award: PendingCoinAward = _active_awards.get(cluster_id) as PendingCoinAward
	return award.expires_at_msec if award != null else -1


func has_active_cluster(cluster_id: int) -> bool:
	return _active_awards.has(cluster_id)


func get_debug_snapshot() -> Dictionary:
	var active_ids: Array[int] = []
	for cluster_id: int in _active_awards.keys():
		active_ids.append(cluster_id)
	active_ids.sort()
	return {
		"simulation_time_msec": _simulation_time_msec,
		"coin_total": _coin_total,
		"scrap_total": _scrap_total,
		"active_cluster_count": _active_awards.size(),
		"active_cluster_ids": active_ids,
		"streak_count": _active_streak_count,
		"maximum_manual_streak": _maximum_manual_streak,
		"manual_clusters_collected": _manual_clusters_collected,
		"streak_expires_at_msec": _streak_expires_at_msec,
	}


func _resolve_cluster(cluster_id: int, manual: bool, resolution_time_msec: int) -> bool:
	var award: PendingCoinAward = _active_awards.get(cluster_id) as PendingCoinAward
	if award == null:
		return false
	# Erase before any state-change or presentation signal. Reentrant requests,
	# repeated clicks, and a timeout arriving during a callback are all no-ops.
	_active_awards.erase(cluster_id)

	var bonus_value: int = 0
	if manual:
		_advance_manual_streak(resolution_time_msec)
		_manual_clusters_collected += 1
		_maximum_manual_streak = maxi(_maximum_manual_streak, _active_streak_count)
		bonus_value = _calculate_manual_bonus(award.base_value, _active_streak_count)
	_coin_total += award.base_value + bonus_value
	coins_changed.emit(_coin_total)
	if manual:
		streak_changed.emit(_active_streak_count, _streak_expires_at_msec)
	cluster_resolved.emit(
		award.cluster_id,
		manual,
		award.base_value,
		bonus_value,
		_active_streak_count
	)
	return true


func _advance_manual_streak(collection_time_msec: int) -> void:
	var window_msec: int = maxi(1, _get_tuning().manual_streak_window_msec)
	if (
		_last_manual_collection_msec >= 0
		and collection_time_msec - _last_manual_collection_msec <= window_msec
	):
		_active_streak_count += 1
	else:
		_active_streak_count = 1
	_last_manual_collection_msec = collection_time_msec
	_streak_expires_at_msec = collection_time_msec + window_msec


func _expire_streak_if_needed(at_time_msec: int) -> void:
	if _active_streak_count <= 0 or at_time_msec <= _streak_expires_at_msec:
		return
	_active_streak_count = 0
	_last_manual_collection_msec = -1
	_streak_expires_at_msec = -1
	streak_changed.emit(0, -1)


func _calculate_manual_bonus(base_value: int, resulting_streak: int) -> int:
	var schedule: PackedInt32Array = _get_tuning().manual_bonus_basis_points_by_streak
	if schedule.is_empty() or resulting_streak <= 0:
		return 0
	var schedule_index: int = mini(resulting_streak - 1, schedule.size() - 1)
	var basis_points: int = clampi(
		schedule[schedule_index],
		0,
		MAX_MANUAL_BONUS_BASIS_POINTS
	)
	return floori(
		(float(base_value) * float(basis_points))
		/ float(BASIS_POINTS_DENOMINATOR)
	)


func _get_tuning() -> CoinClusterTuning:
	return tuning if tuning != null else DEFAULT_TUNING


func _award_expires_before(left: PendingCoinAward, right: PendingCoinAward) -> bool:
	if left.expires_at_msec == right.expires_at_msec:
		return left.cluster_id < right.cluster_id
	return left.expires_at_msec < right.expires_at_msec
