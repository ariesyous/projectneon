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
signal equipment_choices_prepared(
	encounter_instance_id: int,
	choices: Array[EquipmentDefinition]
)
signal equipment_choice_applied(
	encounter_instance_id: int,
	choice_index: int,
	equipment: EquipmentDefinition,
	slot_index: int
)
signal equipment_choice_resolved(
	encounter_instance_id: int,
	choice_index: int,
	equipment: EquipmentDefinition,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int
)
signal equipment_reward_declined(encounter_instance_id: int)
signal card_choices_prepared(
	encounter_instance_id: int,
	choice_token: int,
	choices: Array[DistrictCardDefinition],
	hand_revision: int
)
signal card_choice_acquired(
	encounter_instance_id: int,
	choice_token: int,
	card: DistrictCardDefinition,
	hand_revision: int
)
signal card_choice_skipped(encounter_instance_id: int, choice_token: int)

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
@export_range(1, 3, 1) var equipment_choice_count: int = 3

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
var _pending_equipment_choices: Dictionary = {}
var _applied_equipment_reward_ids: Dictionary[int, bool] = {}
var _resolving_equipment_reward_ids: Dictionary[int, bool] = {}
var _last_equipment_candidate_order: Array[StringName] = []
var _random_streams: RunRandomStreams
var _synergy_system: SynergySystem
var _card_system: CardSystem
var _coordinated_card_encounter_id: int = -1
var _coordinated_card_choice_token: int = -1
var _coordinated_card_hand_revision: int = -1
var _configured_allowed_equipment_ids: Array[StringName] = []
var _active_allowed_equipment_ids: Array[StringName] = []
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


func configure_equipment(synergy_system: SynergySystem) -> void:
	_synergy_system = synergy_system


## Configures the stable content-access snapshot to latch on the next reset.
## Empty preserves the Milestone 4 all-catalogue default used by existing
## development fixtures and deterministic catalogue validation.
func configure_equipment_access(allowed_equipment_ids: Array[StringName]) -> void:
	_configured_allowed_equipment_ids.clear()
	for equipment_id: StringName in allowed_equipment_ids:
		if equipment_id != &"" and not _configured_allowed_equipment_ids.has(equipment_id):
			_configured_allowed_equipment_ids.append(equipment_id)
	_configured_allowed_equipment_ids.sort_custom(_string_name_before)


func configure_cards(card_system: CardSystem) -> void:
	_card_system = card_system
	_clear_card_coordination()


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled


func reset_for_run() -> void:
	_active_allowed_equipment_ids = _configured_allowed_equipment_ids.duplicate()
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
	_pending_equipment_choices.clear()
	_applied_equipment_reward_ids.clear()
	_resolving_equipment_reward_ids.clear()
	_last_equipment_candidate_order.clear()
	# CardSystem owns its deck, hand, discard, tokens, and resolved ledgers. The
	# run coordinator resets that authority separately; RewardDirector clears
	# only its presentation-coordination mirror here.
	_clear_card_coordination()
	coins_changed.emit(_coin_total)
	scrap_changed.emit(_scrap_total)
	streak_changed.emit(0, -1)


## Coordinates card reward presentation without owning candidates, tokens, or
## randomness. CardSystem performs the only cards-stream draws.
func prepare_card_choices(
	encounter_instance_id: int
) -> Array[DistrictCardDefinition]:
	var empty_result: Array[DistrictCardDefinition] = []
	if _card_system == null:
		return empty_result
	var choices: Array[DistrictCardDefinition] = (
		_card_system.prepare_reward_choices(encounter_instance_id)
	)
	if choices.is_empty():
		return empty_result
	var choice_token: int = _card_system.get_pending_reward_choice_token()
	var pending_encounter_id: int = _card_system.get_pending_reward_encounter_id()
	if choice_token < 0 or pending_encounter_id != encounter_instance_id:
		return empty_result
	var hand_revision: int = _card_system.get_hand_revision()
	_coordinated_card_encounter_id = encounter_instance_id
	_coordinated_card_choice_token = choice_token
	_coordinated_card_hand_revision = hand_revision
	card_choices_prepared.emit(
		encounter_instance_id,
		choice_token,
		choices,
		hand_revision
	)
	return choices


func acquire_card_choice(
	encounter_instance_id: int,
	choice_token: int,
	choice_index: int,
	expected_hand_revision: int
) -> DistrictCardDefinition:
	if _card_system == null:
		return null
	var selected: DistrictCardDefinition = _card_system.acquire_reward_choice(
		encounter_instance_id,
		choice_token,
		choice_index,
		expected_hand_revision
	)
	if selected == null:
		return null
	var resulting_hand_revision: int = _card_system.get_hand_revision()
	_clear_card_coordination()
	card_choice_acquired.emit(
		encounter_instance_id,
		choice_token,
		selected,
		resulting_hand_revision
	)
	return selected


func skip_card_choice(encounter_instance_id: int, choice_token: int) -> bool:
	if _card_system == null:
		return false
	if not _card_system.skip_reward_choice(encounter_instance_id, choice_token):
		return false
	_clear_card_coordination()
	card_choice_skipped.emit(encounter_instance_id, choice_token)
	return true


func get_pending_card_choice_token() -> int:
	return _card_system.get_pending_reward_choice_token() if _card_system != null else -1


func get_pending_card_encounter_id() -> int:
	return _card_system.get_pending_reward_encounter_id() if _card_system != null else -1


func get_pending_card_choices() -> Array[DistrictCardDefinition]:
	if _card_system == null:
		var empty_result: Array[DistrictCardDefinition] = []
		return empty_result
	return _card_system.get_pending_reward_choices()


func get_card_hand_revision() -> int:
	return _card_system.get_hand_revision() if _card_system != null else -1


func is_card_hand_full() -> bool:
	if _card_system == null:
		return false
	return bool(_card_system.get_snapshot().get("reward_hand_full", false))


func get_card_state() -> Dictionary:
	return _card_system.get_snapshot() if _card_system != null else {}


func get_card_debug_snapshot() -> Dictionary:
	var pending_ids: Array[StringName] = []
	for card: DistrictCardDefinition in get_pending_card_choices():
		if card != null:
			pending_ids.append(card.id)
	return {
		"configured": _card_system != null,
		"coordinated_encounter_id": _coordinated_card_encounter_id,
		"coordinated_choice_token": _coordinated_card_choice_token,
		"coordinated_hand_revision": _coordinated_card_hand_revision,
		"pending_encounter_id": get_pending_card_encounter_id(),
		"pending_choice_token": get_pending_card_choice_token(),
		"pending_choice_ids": pending_ids,
		"hand_revision": get_card_hand_revision(),
		"hand_full": is_card_hand_full(),
		"state": get_card_state(),
	}


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


## Returns the quality tier reached by advancing through authored tiers rather
## than assuming the integer immediately above the baseline exists. The
## baseline is the highest eligible tier at or below maximum_quality_tier;
## advancement clamps to the highest remaining authored tier. No random stream
## is consumed.
func get_advanced_authored_quality_tier(
	maximum_quality_tier: int,
	allowed_reward_ids: Array[StringName] = [],
	tier_steps: int = 1
) -> int:
	var candidate_by_id: Dictionary[StringName, StandardRewardDefinition] = {}
	var duplicate_ids: Dictionary[StringName, bool] = {}
	for reward: StandardRewardDefinition in standard_rewards:
		if (
			reward == null
			or reward.id == &""
			or reward.quality_tier < 0
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
	var authored_tiers: Array[int] = []
	for reward: StandardRewardDefinition in candidate_by_id.values():
		if not authored_tiers.has(reward.quality_tier):
			authored_tiers.append(reward.quality_tier)
	authored_tiers.sort()
	var baseline_index: int = -1
	for index: int in range(authored_tiers.size()):
		if authored_tiers[index] > maximum_quality_tier:
			break
		baseline_index = index
	if baseline_index < 0:
		return -1
	var advanced_index: int = mini(
		baseline_index + maxi(tier_steps, 0),
		authored_tiers.size() - 1
	)
	return authored_tiers[advanced_index]


func apply_standard_reward(encounter_instance_id: int) -> bool:
	if (
		_applied_standard_reward_ids.has(encounter_instance_id)
		or _pending_equipment_choices.has(encounter_instance_id)
	):
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


func prepare_equipment_choices(encounter_instance_id: int) -> Array[EquipmentDefinition]:
	var empty_result: Array[EquipmentDefinition] = []
	if (
		encounter_instance_id < 0
		or _pending_equipment_choices.has(encounter_instance_id)
		or _applied_equipment_reward_ids.has(encounter_instance_id)
		or _random_streams == null
		or _synergy_system == null
	):
		return empty_result
	var candidate_by_id: Dictionary[StringName, EquipmentDefinition] = {}
	for item: EquipmentDefinition in _synergy_system.get_sorted_catalogue():
		if (
			item == null
			or item.id == &""
			or (
				not _active_allowed_equipment_ids.is_empty()
				and not _active_allowed_equipment_ids.has(item.id)
			)
			or _synergy_system.owns_equipment(item.id)
			or candidate_by_id.has(item.id)
		):
			continue
		candidate_by_id[item.id] = item
	_last_equipment_candidate_order.clear()
	for equipment_id: StringName in candidate_by_id.keys():
		_last_equipment_candidate_order.append(equipment_id)
	_last_equipment_candidate_order.sort_custom(_string_name_before)

	var remaining_ids: Array[StringName] = _last_equipment_candidate_order.duplicate()
	var choices: Array[EquipmentDefinition] = []
	var draw_count: int = mini(equipment_choice_count, remaining_ids.size())
	for _draw_index: int in range(draw_count):
		var selected_id: StringName = _random_streams.choose_stable_id(
			RunRandomStreams.STREAM_EQUIPMENT,
			remaining_ids
		)
		var selected: EquipmentDefinition = candidate_by_id.get(selected_id)
		if selected == null:
			break
		choices.append(selected)
		remaining_ids.erase(selected_id)
	if choices.is_empty():
		return empty_result
	_pending_equipment_choices[encounter_instance_id] = choices
	equipment_choices_prepared.emit(encounter_instance_id, choices)
	return choices


func get_active_equipment_access_ids() -> Array[StringName]:
	if not _active_allowed_equipment_ids.is_empty():
		return _active_allowed_equipment_ids.duplicate()
	var result: Array[StringName] = []
	if _synergy_system != null:
		for item: EquipmentDefinition in _synergy_system.get_sorted_catalogue():
			if item != null:
				result.append(item.id)
	return result


func apply_equipment_choice(
	encounter_instance_id: int,
	choice_index: int,
	slot_index: int = -1
) -> bool:
	if (
		_applied_equipment_reward_ids.has(encounter_instance_id)
		or _resolving_equipment_reward_ids.has(encounter_instance_id)
		or _synergy_system == null
	):
		return false
	var choices: Array = _pending_equipment_choices.get(encounter_instance_id, [])
	if choice_index < 0 or choice_index >= choices.size():
		return false
	var equipment: EquipmentDefinition = choices[choice_index] as EquipmentDefinition
	if equipment == null:
		return false
	_resolving_equipment_reward_ids[encounter_instance_id] = true
	if not _synergy_system.acquire_equipped(equipment, slot_index):
		_resolving_equipment_reward_ids.erase(encounter_instance_id)
		return false
	var applied_slot: int = slot_index
	if applied_slot < 0:
		for equipped_slot: int in range(SynergySystem.SLOT_COUNT):
			if _synergy_system.get_equipped_item(equipped_slot) == equipment:
				applied_slot = equipped_slot
				break
	_finalize_equipment_reward(
		encounter_instance_id,
		choice_index,
		equipment,
		SynergySystem.AREA_EQUIPPED,
		applied_slot,
		-1
	)
	return true


## Applies a previously selected reward only after presentation has gathered a
## destination and explicit confirmation. The inventory revision makes stale
## modal confirmations fail safely.
func apply_equipment_choice_to_inventory(
	encounter_instance_id: int,
	choice_index: int,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int,
	replace_confirmed: bool,
	expected_revision: int
) -> bool:
	if (
		_applied_equipment_reward_ids.has(encounter_instance_id)
		or _resolving_equipment_reward_ids.has(encounter_instance_id)
		or _synergy_system == null
	):
		return false
	var choices: Array = _pending_equipment_choices.get(encounter_instance_id, [])
	if choice_index < 0 or choice_index >= choices.size():
		return false
	var equipment: EquipmentDefinition = choices[choice_index] as EquipmentDefinition
	if equipment == null:
		return false
	_resolving_equipment_reward_ids[encounter_instance_id] = true
	var applied: bool = false
	if destination == SynergySystem.AREA_EQUIPPED:
		applied = _synergy_system.acquire_equipped(
			equipment,
			equipment_slot,
			backpack_slot,
			replace_confirmed,
			expected_revision
		)
	elif destination == SynergySystem.AREA_BACKPACK:
		applied = _synergy_system.store(
			equipment,
			backpack_slot,
			replace_confirmed,
			expected_revision
		)
	if not applied:
		_resolving_equipment_reward_ids.erase(encounter_instance_id)
		return false
	_finalize_equipment_reward(
		encounter_instance_id,
		choice_index,
		equipment,
		destination,
		equipment_slot if destination == SynergySystem.AREA_EQUIPPED else -1,
		backpack_slot
	)
	return true


## Keeps the current inventory while still resolving the encounter's paired
## standard reward. This is the safe default when all six positions are full.
func decline_equipment_reward(encounter_instance_id: int) -> bool:
	if (
		_applied_equipment_reward_ids.has(encounter_instance_id)
		or _resolving_equipment_reward_ids.has(encounter_instance_id)
		or not _pending_equipment_choices.has(encounter_instance_id)
	):
		return false
	_pending_equipment_choices.erase(encounter_instance_id)
	_applied_equipment_reward_ids[encounter_instance_id] = true
	_resolving_equipment_reward_ids.erase(encounter_instance_id)
	apply_standard_reward(encounter_instance_id)
	equipment_reward_declined.emit(encounter_instance_id)
	return true


func get_pending_equipment_choices(
	encounter_instance_id: int
) -> Array[EquipmentDefinition]:
	var result: Array[EquipmentDefinition] = []
	var stored: Array = _pending_equipment_choices.get(encounter_instance_id, [])
	for value: Variant in stored:
		var item: EquipmentDefinition = value as EquipmentDefinition
		if item != null:
			result.append(item)
	return result


func get_equipment_choice_preview(
	encounter_instance_id: int,
	choice_index: int,
	slot_index: int = -1,
	backpack_slot: int = -1
) -> Dictionary:
	if _synergy_system == null:
		return {"valid": false, "reason": &"not_configured"}
	var choices: Array[EquipmentDefinition] = get_pending_equipment_choices(encounter_instance_id)
	if choice_index < 0 or choice_index >= choices.size():
		return {"valid": false, "reason": &"invalid_choice"}
	return _synergy_system.preview_equipment(
		choices[choice_index],
		slot_index,
		backpack_slot
	)


func get_last_equipment_candidate_order() -> Array[StringName]:
	return _last_equipment_candidate_order.duplicate()


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


func settle_pending_coin_clusters_as_base() -> int:
	# A terminal run outcome must not turn the optional click window into a
	# requirement. Resolve every still-visible cluster through the same
	# authoritative at-most-once path, in the normal deterministic deadline/ID
	# order, without granting a manual bonus or advancing the streak.
	var pending_awards: Array[PendingCoinAward] = []
	for award: PendingCoinAward in _active_awards.values():
		pending_awards.append(award)
	pending_awards.sort_custom(_award_expires_before)
	var resolved_count: int = 0
	for award: PendingCoinAward in pending_awards:
		if _resolve_cluster(award.cluster_id, false, _simulation_time_msec):
			resolved_count += 1
	return resolved_count


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
	var pending_equipment_ids: Array[StringName] = []
	var pending_encounter_ids: Array[int] = []
	for pending_id: Variant in _pending_equipment_choices.keys():
		pending_encounter_ids.append(int(pending_id))
	pending_encounter_ids.sort()
	if not pending_encounter_ids.is_empty():
		for item: EquipmentDefinition in get_pending_equipment_choices(pending_encounter_ids[0]):
			pending_equipment_ids.append(item.id)
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
		"pending_equipment_encounter_id": (
			pending_encounter_ids[0] if not pending_encounter_ids.is_empty() else -1
		),
		"pending_equipment_ids": pending_equipment_ids,
		"equipment_rewards_applied": _applied_equipment_reward_ids.size(),
		"card_reward": get_card_debug_snapshot(),
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


func _finalize_equipment_reward(
	encounter_instance_id: int,
	choice_index: int,
	equipment: EquipmentDefinition,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int
) -> void:
	# Clear and latch before callbacks. Repeated clicks cannot reapply either
	# inventory mutation or the paired standard encounter reward.
	_pending_equipment_choices.erase(encounter_instance_id)
	_applied_equipment_reward_ids[encounter_instance_id] = true
	_resolving_equipment_reward_ids.erase(encounter_instance_id)
	apply_standard_reward(encounter_instance_id)
	equipment_choice_applied.emit(
		encounter_instance_id,
		choice_index,
		equipment,
		equipment_slot
	)
	equipment_choice_resolved.emit(
		encounter_instance_id,
		choice_index,
		equipment,
		destination,
		equipment_slot,
		backpack_slot
	)


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


func _clear_card_coordination() -> void:
	_coordinated_card_encounter_id = -1
	_coordinated_card_choice_token = -1
	_coordinated_card_hand_revision = -1


func _award_expires_before(left: PendingCoinAward, right: PendingCoinAward) -> bool:
	if left.expires_at_msec == right.expires_at_msec:
		return left.cluster_id < right.cluster_id
	return left.expires_at_msec < right.expires_at_msec


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
