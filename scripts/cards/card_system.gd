class_name CardSystem
extends Node

## Owns the finite authored deck, hand, discard pile, deterministic card
## choices, staged placement validation, pending route effects, and exactly-once
## resolution coordination. PatrolController owns route position/modifications;
## RunDirector remains the only Heat and Night Pressure authority.

signal snapshot_changed(snapshot: Dictionary)
signal card_drawn(card: DistrictCardDefinition, source_id: StringName)
signal card_reward_choices_prepared(
	encounter_instance_id: int,
	choice_token: int,
	choices: Array[DistrictCardDefinition],
	hand_revision: int
)
signal card_reward_acquired(
	encounter_instance_id: int,
	choice_token: int,
	card: DistrictCardDefinition,
	hand_revision: int
)
signal card_reward_skipped(encounter_instance_id: int, choice_token: int)
signal card_placement_staged(
	confirmation_token: int,
	card_id: StringName,
	slot_id: StringName
)
signal card_placement_rejected(card_id: StringName, slot_id: StringName, reason: StringName)
signal card_placed(record: CardPlacementRecord)
signal card_route_effect_resolved(record: CardResolutionRecord)
signal planning_state_changed(is_active: bool, owns_pause: bool)

const RESPONSIBILITY: String = "Own deterministic district card state and placement."
const OPENING_DRAW_COUNT: int = 2
const HAND_CAPACITY: int = 3
const REWARD_CHOICE_COUNT: int = 3
const MAX_RESOLVED_HISTORY: int = 8
const RESULT_OK: StringName = &"ok"

@export var catalogue: DistrictCardCatalogue

class StagedPlacement:
	extends RefCounted

	var confirmation_token: int = -1
	var card_id: StringName = &""
	var slot_id: StringName = &""
	var hand_revision: int = -1
	var route_revision: int = -1


class PendingRewardChoice:
	extends RefCounted

	var encounter_instance_id: int = -1
	var choice_token: int = -1
	var hand_revision: int = -1
	var choices: Array[DistrictCardDefinition] = []


var _random_streams: RunRandomStreams
var _patrol_controller: PatrolController
var _draw_pile: Array[DistrictCardDefinition] = []
var _hand: Array[DistrictCardDefinition] = []
var _discard_pile: Array[DistrictCardDefinition] = []
var _pending_placements: Dictionary[int, CardPlacementRecord] = {}
var _resolved_placements: Array[CardPlacementRecord] = []
var _resolved_placement_tokens: Dictionary[int, bool] = {}
var _resolved_reward_encounters: Dictionary[int, bool] = {}
var _staged_placement: StagedPlacement
var _pending_reward_choice: PendingRewardChoice
var _next_token: int = 1
var _hand_revision: int = 0
var _planning_active: bool = false
var _planning_owns_pause: bool = false
var _last_reward_candidate_order: Array[StringName] = []


func configure(
	random_streams: RunRandomStreams,
	patrol_controller: PatrolController
) -> void:
	_random_streams = random_streams
	_patrol_controller = patrol_controller


func reset_for_run() -> bool:
	_draw_pile.clear()
	_hand.clear()
	_discard_pile.clear()
	_pending_placements.clear()
	_resolved_placements.clear()
	_resolved_placement_tokens.clear()
	_resolved_reward_encounters.clear()
	_staged_placement = null
	_pending_reward_choice = null
	_next_token = 1
	_hand_revision = 1
	_planning_active = false
	_planning_owns_pause = false
	_last_reward_candidate_order.clear()
	if catalogue == null or _random_streams == null:
		_emit_snapshot()
		return false
	var validation: PackedStringArray = catalogue.validation_errors()
	if not validation.is_empty():
		push_error("District card catalogue is invalid: %s" % "; ".join(validation))
		_emit_snapshot()
		return false
	for card: DistrictCardDefinition in catalogue.get_sorted_cards():
		_draw_pile.append(card)
	for _draw_index: int in range(mini(OPENING_DRAW_COUNT, _draw_pile.size())):
		var drawn: DistrictCardDefinition = _draw_one_from_pile(&"opening")
		if drawn == null:
			break
		_hand.append(drawn)
	_emit_snapshot()
	return _hand.size() == mini(OPENING_DRAW_COUNT, catalogue.cards.size())


func begin_planning(owns_pause: bool) -> bool:
	if _planning_active or _pending_reward_choice != null:
		return false
	_planning_active = true
	_planning_owns_pause = owns_pause
	planning_state_changed.emit(true, owns_pause)
	_emit_snapshot()
	return true


func end_planning() -> bool:
	if not _planning_active:
		return false
	var owned_pause: bool = _planning_owns_pause
	_planning_active = false
	_planning_owns_pause = false
	_staged_placement = null
	planning_state_changed.emit(false, owned_pause)
	_emit_snapshot()
	return true


func is_planning_active() -> bool:
	return _planning_active


func planning_owns_pause() -> bool:
	return _planning_owns_pause


func prepare_reward_choices(
	encounter_instance_id: int
) -> Array[DistrictCardDefinition]:
	var empty_result: Array[DistrictCardDefinition] = []
	if (
		encounter_instance_id < 0
		or _random_streams == null
		or _planning_active
		or _pending_reward_choice != null
		or _resolved_reward_encounters.has(encounter_instance_id)
		or _draw_pile.is_empty()
	):
		return empty_result
	var candidate_by_id: Dictionary[StringName, DistrictCardDefinition] = {}
	for card: DistrictCardDefinition in _draw_pile:
		if card == null or card.id == &"" or candidate_by_id.has(card.id):
			continue
		candidate_by_id[card.id] = card
	_last_reward_candidate_order.clear()
	for candidate_id: StringName in candidate_by_id.keys():
		_last_reward_candidate_order.append(candidate_id)
	_last_reward_candidate_order.sort_custom(_string_name_before)
	var remaining_ids: Array[StringName] = _last_reward_candidate_order.duplicate()
	var choices: Array[DistrictCardDefinition] = []
	for _draw_index: int in range(mini(REWARD_CHOICE_COUNT, remaining_ids.size())):
		var selected_id: StringName = _random_streams.choose_stable_id(
			RunRandomStreams.STREAM_CARDS,
			remaining_ids
		)
		var selected: DistrictCardDefinition = candidate_by_id.get(selected_id)
		if selected == null:
			break
		choices.append(selected)
		remaining_ids.erase(selected_id)
	if choices.is_empty():
		return empty_result
	var pending: PendingRewardChoice = PendingRewardChoice.new()
	pending.encounter_instance_id = encounter_instance_id
	pending.choice_token = _take_token()
	pending.hand_revision = _hand_revision
	pending.choices = choices.duplicate()
	_pending_reward_choice = pending
	card_reward_choices_prepared.emit(
		encounter_instance_id,
		pending.choice_token,
		choices,
		_hand_revision
	)
	_emit_snapshot()
	return choices


func acquire_reward_choice(
	encounter_instance_id: int,
	choice_token: int,
	choice_index: int,
	expected_hand_revision: int
) -> DistrictCardDefinition:
	var pending: PendingRewardChoice = _pending_reward_choice
	if (
		pending == null
		or pending.encounter_instance_id != encounter_instance_id
		or pending.choice_token != choice_token
		or pending.hand_revision != expected_hand_revision
		or _hand_revision != expected_hand_revision
		or choice_index < 0
		or choice_index >= pending.choices.size()
		or _hand.size() >= HAND_CAPACITY
	):
		return null
	var selected: DistrictCardDefinition = pending.choices[choice_index]
	if selected == null or not _draw_pile.has(selected):
		return null
	# Latch and clear before callbacks so repeated or re-entrant confirmation is
	# harmless. Unselected choices remain in the finite draw pile.
	_pending_reward_choice = null
	_resolved_reward_encounters[encounter_instance_id] = true
	_draw_pile.erase(selected)
	_hand.append(selected)
	_hand_revision += 1
	card_reward_acquired.emit(
		encounter_instance_id,
		choice_token,
		selected,
		_hand_revision
	)
	_emit_snapshot()
	return selected


func skip_reward_choice(encounter_instance_id: int, choice_token: int) -> bool:
	var pending: PendingRewardChoice = _pending_reward_choice
	if (
		pending == null
		or pending.encounter_instance_id != encounter_instance_id
		or pending.choice_token != choice_token
	):
		return false
	_pending_reward_choice = null
	_resolved_reward_encounters[encounter_instance_id] = true
	card_reward_skipped.emit(encounter_instance_id, choice_token)
	_emit_snapshot()
	return true


func stage_placement(
	card_id: StringName,
	slot_id: StringName,
	expected_hand_revision: int,
	expected_route_revision: int
) -> Dictionary:
	var reason: StringName = validate_placement(
		card_id,
		slot_id,
		expected_hand_revision,
		expected_route_revision
	)
	if reason != RESULT_OK:
		card_placement_rejected.emit(card_id, slot_id, reason)
		return _stage_result(false, reason, -1)
	var staged: StagedPlacement = StagedPlacement.new()
	staged.confirmation_token = _take_token()
	staged.card_id = card_id
	staged.slot_id = slot_id
	staged.hand_revision = expected_hand_revision
	staged.route_revision = expected_route_revision
	_staged_placement = staged
	card_placement_staged.emit(staged.confirmation_token, card_id, slot_id)
	_emit_snapshot()
	return _stage_result(true, RESULT_OK, staged.confirmation_token)


func cancel_staged_placement(expected_confirmation_token: int = -1) -> bool:
	if _staged_placement == null:
		return false
	if (
		expected_confirmation_token >= 0
		and _staged_placement.confirmation_token != expected_confirmation_token
	):
		return false
	_staged_placement = null
	_emit_snapshot()
	return true


func validate_placement(
	card_id: StringName,
	slot_id: StringName,
	expected_hand_revision: int,
	expected_route_revision: int
) -> StringName:
	if not _planning_active:
		return &"planning_inactive"
	if _patrol_controller == null:
		return &"route_unavailable"
	if expected_hand_revision != _hand_revision:
		return &"stale_hand_revision"
	if expected_route_revision != _patrol_controller.get_route_revision():
		return &"stale_route_revision"
	var card: DistrictCardDefinition = get_hand_card_by_id(card_id)
	if card == null:
		return &"card_not_in_hand"
	var slot_status: StringName = _patrol_controller.get_route_slot_status(slot_id)
	if slot_status != PatrolController.SLOT_STATUS_VALID:
		return slot_status
	var slot: RouteSlotSnapshot = _find_future_slot(slot_id)
	if slot == null:
		return &"invalid_slot"
	if not card.valid_node_types.has(slot.node_type):
		return &"wrong_node_type"
	return RESULT_OK


func confirm_staged_placement(confirmation_token: int) -> CardPlacementRecord:
	var staged: StagedPlacement = _staged_placement
	if staged == null or staged.confirmation_token != confirmation_token:
		return null
	var reason: StringName = validate_placement(
		staged.card_id,
		staged.slot_id,
		staged.hand_revision,
		staged.route_revision
	)
	if reason != RESULT_OK:
		_staged_placement = null
		card_placement_rejected.emit(staged.card_id, staged.slot_id, reason)
		_emit_snapshot()
		return null
	var card: DistrictCardDefinition = get_hand_card_by_id(staged.card_id)
	var slot: RouteSlotSnapshot = _find_future_slot(staged.slot_id)
	if card == null or slot == null or card.effect_definition == null:
		return null
	var application_result: StringName = _patrol_controller.apply_future_route_modification(
		staged.slot_id,
		card.id,
		card.effect_definition.id,
		staged.confirmation_token,
		card.valid_node_types,
		staged.route_revision
	)
	if application_result != RESULT_OK:
		_staged_placement = null
		card_placement_rejected.emit(card.id, staged.slot_id, application_result)
		_emit_snapshot()
		return null
	var record: CardPlacementRecord = CardPlacementRecord.new()
	record.placement_token = staged.confirmation_token
	record.card = card
	record.slot_id = slot.slot_id
	record.occurrence_index = slot.occurrence_index
	record.route_index = slot.route_index
	record.loop_count = slot.loop_count
	record.node_id = slot.node_id
	record.node_type = slot.node_type
	record.hand_revision = _hand_revision + 1
	record.route_revision = _patrol_controller.get_route_revision()
	# No fallible operation occurs after the route authority accepts. The card
	# now moves immediately to discard and the pending effect is tokenized.
	_staged_placement = null
	_hand.erase(card)
	_discard_pile.append(card)
	_hand_revision += 1
	_pending_placements[record.placement_token] = record
	card_placed.emit(record)
	_emit_snapshot()
	return record


func resolve_current_route_effect() -> CardResolutionRecord:
	if _patrol_controller == null:
		return null
	var modification: RouteModificationRecord = (
		_patrol_controller.get_current_route_modification()
	)
	if modification == null or _resolved_placement_tokens.has(modification.placement_token):
		return null
	var placement: CardPlacementRecord = _pending_placements.get(
		modification.placement_token
	) as CardPlacementRecord
	if placement == null:
		return null
	var consumed: RouteModificationRecord = (
		_patrol_controller.resolve_current_route_modification(modification.placement_token)
	)
	if consumed == null:
		return null
	_pending_placements.erase(placement.placement_token)
	_resolved_placement_tokens[placement.placement_token] = true
	placement.resolved = true
	_resolved_placements.append(placement)
	while _resolved_placements.size() > MAX_RESOLVED_HISTORY:
		_resolved_placements.pop_front()
	var resolved: CardResolutionRecord = CardResolutionRecord.new()
	resolved.placement_token = placement.placement_token
	resolved.card = placement.card
	resolved.effect = placement.card.effect_definition
	resolved.slot_id = placement.slot_id
	resolved.occurrence_index = placement.occurrence_index
	resolved.route_index = placement.route_index
	resolved.loop_count = placement.loop_count
	resolved.node_id = placement.node_id
	resolved.baseline_node_type = placement.node_type
	card_route_effect_resolved.emit(resolved)
	_emit_snapshot()
	return resolved


func get_hand() -> Array[DistrictCardDefinition]:
	return _hand.duplicate()


func get_draw_pile() -> Array[DistrictCardDefinition]:
	return _draw_pile.duplicate()


func get_discard_pile() -> Array[DistrictCardDefinition]:
	return _discard_pile.duplicate()


func get_hand_revision() -> int:
	return _hand_revision


func get_pending_reward_choice_token() -> int:
	return _pending_reward_choice.choice_token if _pending_reward_choice != null else -1


func get_pending_reward_encounter_id() -> int:
	return (
		_pending_reward_choice.encounter_instance_id
		if _pending_reward_choice != null
		else -1
	)


func get_pending_reward_choices() -> Array[DistrictCardDefinition]:
	var result: Array[DistrictCardDefinition] = []
	if _pending_reward_choice != null:
		result = _pending_reward_choice.choices.duplicate()
	return result


func get_last_reward_candidate_order() -> Array[StringName]:
	return _last_reward_candidate_order.duplicate()


func get_hand_card_by_id(card_id: StringName) -> DistrictCardDefinition:
	for card: DistrictCardDefinition in _hand:
		if card != null and card.id == card_id:
			return card
	return null


func get_snapshot() -> Dictionary:
	var pending_records: Array[Dictionary] = []
	var pending_tokens: Array[int] = []
	for token: int in _pending_placements.keys():
		pending_tokens.append(token)
	pending_tokens.sort()
	for token: int in pending_tokens:
		var pending: CardPlacementRecord = _pending_placements.get(token) as CardPlacementRecord
		if pending != null:
			pending_records.append(pending.to_dictionary())
	var resolved_records: Array[Dictionary] = []
	for resolved: CardPlacementRecord in _resolved_placements:
		resolved_records.append(resolved.to_dictionary())
	return {
		"hand": _hand.duplicate(),
		"hand_ids": _card_ids(_hand),
		"draw_ids": _card_ids(_draw_pile),
		"discard_ids": _card_ids(_discard_pile),
		"hand_count": _hand.size(),
		"hand_capacity": HAND_CAPACITY,
		"draw_count": _draw_pile.size(),
		"discard_count": _discard_pile.size(),
		"hand_revision": _hand_revision,
		"planning_active": _planning_active,
		"planning_owns_pause": _planning_owns_pause,
		"staged_confirmation_token": (
			_staged_placement.confirmation_token if _staged_placement != null else -1
		),
		"staged_card_id": _staged_placement.card_id if _staged_placement != null else &"",
		"staged_slot_id": _staged_placement.slot_id if _staged_placement != null else &"",
		"pending_route_effects": pending_records,
		"resolved_route_effects": resolved_records,
		"pending_reward_encounter_id": get_pending_reward_encounter_id(),
		"pending_reward_choice_token": get_pending_reward_choice_token(),
		"pending_reward_choices": get_pending_reward_choices(),
		"reward_hand_full": _hand.size() >= HAND_CAPACITY,
		"no_reshuffle": true,
	}


func _draw_one_from_pile(source_id: StringName) -> DistrictCardDefinition:
	if _draw_pile.is_empty() or _random_streams == null:
		return null
	var ids: Array[StringName] = _card_ids(_draw_pile)
	var selected_id: StringName = _random_streams.choose_stable_id(
		RunRandomStreams.STREAM_CARDS,
		ids
	)
	for card: DistrictCardDefinition in _draw_pile:
		if card != null and card.id == selected_id:
			_draw_pile.erase(card)
			card_drawn.emit(card, source_id)
			return card
	return null


func _find_future_slot(slot_id: StringName) -> RouteSlotSnapshot:
	if _patrol_controller == null:
		return null
	for slot: RouteSlotSnapshot in _patrol_controller.get_future_route_slots():
		if slot != null and slot.slot_id == slot_id:
			return slot
	return null


func _take_token() -> int:
	var result: int = _next_token
	_next_token += 1
	return result


func _stage_result(accepted: bool, reason: StringName, token: int) -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"confirmation_token": token,
		"hand_revision": _hand_revision,
		"route_revision": (
			_patrol_controller.get_route_revision()
			if _patrol_controller != null
			else -1
		),
	}


func _emit_snapshot() -> void:
	snapshot_changed.emit(get_snapshot())


func _card_ids(cards: Array[DistrictCardDefinition]) -> Array[StringName]:
	var result: Array[StringName] = []
	for card: DistrictCardDefinition in cards:
		if card != null:
			result.append(card.id)
	return result


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
