class_name CardSystem
extends Node

## Owns both the historical finite hand/future-slot compatibility contract and
## the WP03 focused District Plan. Configured district runs use a lap-scoped
## one-copy deck, a deterministic next-block offer, revisioned confirmation,
## and exactly-once resolution. PatrolController still owns internal route
## occurrences/safe boundaries; RunDirector remains the only Heat and Night
## Pressure authority.

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
signal district_plan_offer_started(
	lap_index: int,
	block_index: int,
	offer_revision: int,
	choices: Array[DistrictCardDefinition]
)
signal district_plan_choice_staged(
	confirmation_token: int,
	card_id: StringName,
	lap_id: StringName,
	block_id: StringName
)
signal district_plan_choice_confirmed(record: CardPlacementRecord)
signal district_plan_choice_rejected(card_id: StringName, reason: StringName)
signal district_plan_block_resolved(record: CardResolutionRecord)

const RESPONSIBILITY: String = "Own deterministic district card state and placement."
const OPENING_DRAW_COUNT: int = 2
const HAND_CAPACITY: int = 3
const REWARD_CHOICE_COUNT: int = 3
const MAX_RESOLVED_HISTORY: int = 8
const DISTRICT_PLAN_OFFER_COUNT: int = 2
const MAX_ARCHIVED_LAPS: int = 3
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


class StagedDistrictPlanChoice:
	extends RefCounted

	var confirmation_token: int = -1
	var card_id: StringName = &""
	var offer_revision: int = -1
	var lifecycle_revision: int = -1
	var lap_index: int = -1
	var lap_id: StringName = &""
	var block_index: int = -1
	var block_id: StringName = &""


class DistrictPlanRecord:
	extends RefCounted

	var selection_token: int = -1
	var card: DistrictCardDefinition
	var offer_revision: int = -1
	var lifecycle_revision: int = -1
	var lap_index: int = -1
	var lap_id: StringName = &""
	var block_index: int = -1
	var block_id: StringName = &""
	var occurrence_index: int = -1
	var occurrence_id: StringName = &""
	var route_index: int = -1
	var node_id: StringName = &""
	var baseline_node_type: StringName = &""
	var resolved: bool = false
	var completed: bool = false

	func to_dictionary() -> Dictionary:
		var effect: CardEffectDefinition = card.effect_definition if card != null else null
		return {
			"selection_token": selection_token,
			"card_id": card.id if card != null else &"",
			"card_name": card.display_name if card != null else "",
			"card": card,
			"effect_id": effect.id if effect != null else &"",
			"effect_kind": effect.kind if effect != null else -1,
			"heat_delta": card.heat_delta if card != null else 0,
			"progression_implication": (
				card.progression_implications if card != null else ""
			),
			"offer_revision": offer_revision,
			"lifecycle_revision": lifecycle_revision,
			"lap_index": lap_index,
			"lap_id": lap_id,
			"block_index": block_index,
			"block_id": block_id,
			"occurrence_index": occurrence_index,
			"occurrence_id": occurrence_id,
			"route_index": route_index,
			"node_id": node_id,
			"baseline_node_type": baseline_node_type,
			"block_type": CardSystem.focused_block_type(card),
			"special_rule": CardSystem.focused_special_rule(card),
			"status": (
				&"completed" if completed
				else (&"resolved" if resolved else &"selected")
			),
			"resolved": resolved,
			"completed": completed,
		}


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
var _configured_allowed_card_ids: Array[StringName] = []
var _active_allowed_card_ids: Array[StringName] = []
var _focused_district_plan_enabled: bool = false
var _focused_offer_revision: int = 0
var _focused_context_lifecycle_revision: int = -1
var _focused_lap_index: int = -1
var _focused_lap_id: StringName = &""
var _focused_block_index: int = -1
var _focused_block_id: StringName = &""
var _staged_focused_choice: StagedDistrictPlanChoice
var _pending_focused_record: DistrictPlanRecord
var _active_focused_record: DistrictPlanRecord
var _focused_lap_records: Array[DistrictPlanRecord] = []
var _archived_focused_laps: Array[Dictionary] = []


func configure(
	random_streams: RunRandomStreams,
	patrol_controller: PatrolController
) -> void:
	_random_streams = random_streams
	_patrol_controller = patrol_controller


## The configured WP03 GameRun enables this before reset. Historical isolated
## fixtures remain in the accepted M5 compatibility mode unless they opt in.
func configure_focused_district_plan(enabled: bool) -> void:
	_focused_district_plan_enabled = enabled


func is_focused_district_plan_enabled() -> bool:
	return _focused_district_plan_enabled


## Configures the stable content-access snapshot to latch on the next reset.
## An empty list preserves the Milestone 5 all-catalogue default.
func configure_run_access(allowed_card_ids: Array[StringName]) -> void:
	_configured_allowed_card_ids.clear()
	for card_id: StringName in allowed_card_ids:
		if card_id != &"" and not _configured_allowed_card_ids.has(card_id):
			_configured_allowed_card_ids.append(card_id)
	_configured_allowed_card_ids.sort_custom(_string_name_before)


func reset_for_run() -> bool:
	_active_allowed_card_ids = _configured_allowed_card_ids.duplicate()
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
	_reset_focused_state()
	if catalogue == null or _random_streams == null:
		_emit_snapshot()
		return false
	var validation: PackedStringArray = catalogue.validation_errors()
	if not validation.is_empty():
		push_error("District card catalogue is invalid: %s" % "; ".join(validation))
		_emit_snapshot()
		return false
	for card: DistrictCardDefinition in catalogue.get_sorted_cards():
		if not _active_allowed_card_ids.is_empty() and not _active_allowed_card_ids.has(card.id):
			continue
		_draw_pile.append(card)
	var accessible_card_count: int = _draw_pile.size()
	if _focused_district_plan_enabled:
		# The first cards-stream draw occurs when authoritative PLAN begins, not
		# during INTRO. Keep the accessible catalogue latched for the lap rebuild.
		_draw_pile.clear()
		_emit_snapshot()
		return accessible_card_count > 0
	for _draw_index: int in range(mini(OPENING_DRAW_COUNT, _draw_pile.size())):
		var drawn: DistrictCardDefinition = _draw_one_from_pile(&"opening")
		if drawn == null:
			break
		_hand.append(drawn)
	_emit_snapshot()
	return _hand.size() == mini(OPENING_DRAW_COUNT, accessible_card_count)


## Clears run-owned ledgers for the main menu without consuming the cards
## stream or creating a hidden opening hand.
func clear_for_main_menu() -> void:
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
	_hand_revision = 0
	_planning_active = false
	_planning_owns_pause = false
	_last_reward_candidate_order.clear()
	_active_allowed_card_ids.clear()
	_reset_focused_state()
	_emit_snapshot()


## Opens the mandatory focused choice for one exact authoritative block. A new
## lap archives the prior trail, rebuilds one accessible copy of every card,
## and draws the deterministic offer without replacement.
func begin_focused_district_plan(
	district_snapshot: Dictionary,
	owns_pause: bool
) -> bool:
	if (
		not _focused_district_plan_enabled
		or _planning_active
		or _pending_reward_choice != null
		or _pending_focused_record != null
		or String(district_snapshot.get("phase_name", "")) != "PLAN"
	):
		return false
	var lap_index: int = int(district_snapshot.get("lap_index", -1))
	var lap_id: StringName = StringName(district_snapshot.get("lap_id", &""))
	var block_index: int = int(district_snapshot.get("block_index", -1))
	var block_id: StringName = StringName(district_snapshot.get("block_id", &""))
	var lifecycle_revision: int = int(
		district_snapshot.get("lifecycle_revision", -1)
	)
	if (
		lap_index < 1
		or lap_id == &""
		or block_index < 1
		or block_id == &""
		or lifecycle_revision < 0
	):
		return false
	if lap_index != _focused_lap_index or lap_id != _focused_lap_id:
		_archive_focused_lap()
		if not _rebuild_focused_lap(lap_index, lap_id):
			_emit_snapshot()
			return false
	if _hand.is_empty():
		_emit_snapshot()
		return false
	_focused_context_lifecycle_revision = lifecycle_revision
	_focused_block_index = block_index
	_focused_block_id = block_id
	_active_focused_record = null
	_staged_focused_choice = null
	_planning_active = true
	_planning_owns_pause = owns_pause
	planning_state_changed.emit(true, owns_pause)
	district_plan_offer_started.emit(
		lap_index,
		block_index,
		_focused_offer_revision,
		_hand.duplicate()
	)
	_emit_snapshot()
	return true


func stage_focused_district_plan_choice(
	card_id: StringName,
	expected_offer_revision: int,
	expected_lifecycle_revision: int,
	expected_lap_id: StringName,
	expected_block_id: StringName
) -> Dictionary:
	var reason: StringName = validate_focused_district_plan_choice(
		card_id,
		expected_offer_revision,
		expected_lifecycle_revision,
		expected_lap_id,
		expected_block_id
	)
	if reason != RESULT_OK:
		district_plan_choice_rejected.emit(card_id, reason)
		return _focused_stage_result(false, reason, -1)
	var staged: StagedDistrictPlanChoice = StagedDistrictPlanChoice.new()
	staged.confirmation_token = _take_token()
	staged.card_id = card_id
	staged.offer_revision = expected_offer_revision
	staged.lifecycle_revision = expected_lifecycle_revision
	staged.lap_index = _focused_lap_index
	staged.lap_id = expected_lap_id
	staged.block_index = _focused_block_index
	staged.block_id = expected_block_id
	_staged_focused_choice = staged
	district_plan_choice_staged.emit(
		staged.confirmation_token,
		card_id,
		expected_lap_id,
		expected_block_id
	)
	_emit_snapshot()
	return _focused_stage_result(true, RESULT_OK, staged.confirmation_token)


func validate_focused_district_plan_choice(
	card_id: StringName,
	expected_offer_revision: int,
	expected_lifecycle_revision: int,
	expected_lap_id: StringName,
	expected_block_id: StringName
) -> StringName:
	if not _focused_district_plan_enabled:
		return &"focused_plan_inactive"
	if not _planning_active:
		return &"planning_inactive"
	if _pending_focused_record != null:
		return &"next_block_already_selected"
	if expected_offer_revision != _focused_offer_revision:
		return &"stale_offer_revision"
	if expected_lifecycle_revision != _focused_context_lifecycle_revision:
		return &"stale_lifecycle_revision"
	if expected_lap_id == &"" or expected_lap_id != _focused_lap_id:
		return &"wrong_lap"
	if expected_block_id == &"" or expected_block_id != _focused_block_id:
		return &"wrong_block"
	if get_hand_card_by_id(card_id) == null:
		return &"card_not_offered"
	return RESULT_OK


func confirm_focused_district_plan_choice(
	confirmation_token: int,
	district_snapshot: Dictionary
) -> CardPlacementRecord:
	var staged: StagedDistrictPlanChoice = _staged_focused_choice
	if staged == null or staged.confirmation_token != confirmation_token:
		return null
	var phase_name: String = String(district_snapshot.get("phase_name", ""))
	var current_lifecycle_revision: int = int(
		district_snapshot.get("lifecycle_revision", -1)
	)
	var current_lap_id: StringName = StringName(district_snapshot.get("lap_id", &""))
	var current_block_id: StringName = StringName(
		district_snapshot.get("block_id", &"")
	)
	var reason: StringName = validate_focused_district_plan_choice(
		staged.card_id,
		staged.offer_revision,
		staged.lifecycle_revision,
		staged.lap_id,
		staged.block_id
	)
	if reason == RESULT_OK and (
		phase_name != "PLAN"
		or current_lifecycle_revision != staged.lifecycle_revision
		or current_lap_id != staged.lap_id
		or current_block_id != staged.block_id
	):
		reason = &"transition_race"
	if reason != RESULT_OK:
		_staged_focused_choice = null
		district_plan_choice_rejected.emit(staged.card_id, reason)
		_emit_snapshot()
		return null
	var card: DistrictCardDefinition = get_hand_card_by_id(staged.card_id)
	if card == null or card.effect_definition == null:
		return null

	# Latch the token and selected block before callbacks. The unselected offer
	# remains and the lap deck refills to two while cards remain.
	var focused: DistrictPlanRecord = DistrictPlanRecord.new()
	focused.selection_token = staged.confirmation_token
	focused.card = card
	focused.offer_revision = staged.offer_revision
	focused.lifecycle_revision = staged.lifecycle_revision
	focused.lap_index = staged.lap_index
	focused.lap_id = staged.lap_id
	focused.block_index = staged.block_index
	focused.block_id = staged.block_id
	_staged_focused_choice = null
	_hand.erase(card)
	_discard_pile.append(card)
	_pending_focused_record = focused
	_focused_lap_records.append(focused)
	_refill_focused_offer()
	_advance_focused_offer_revision()

	var record: CardPlacementRecord = CardPlacementRecord.new()
	record.placement_token = focused.selection_token
	record.card = card
	record.slot_id = focused.block_id
	record.occurrence_index = -1
	record.route_index = -1
	record.loop_count = focused.lap_index - 1
	record.node_id = focused.block_id
	record.node_type = focused_block_kind(card)
	record.hand_revision = _focused_offer_revision
	record.route_revision = focused.lifecycle_revision
	card_placed.emit(record)
	district_plan_choice_confirmed.emit(record)
	_emit_snapshot()
	return record


func cancel_focused_district_plan_choice(
	expected_confirmation_token: int = -1
) -> bool:
	if _staged_focused_choice == null:
		return false
	if (
		expected_confirmation_token >= 0
		and _staged_focused_choice.confirmation_token != expected_confirmation_token
	):
		return false
	_staged_focused_choice = null
	_emit_snapshot()
	return true


func has_focused_next_block_selection() -> bool:
	return _pending_focused_record != null


func get_focused_next_block_card() -> DistrictCardDefinition:
	return (
		_pending_focused_record.card
		if _pending_focused_record != null
		else null
	)


## Consumes the selected card only after RunFlow has preserved safe-boundary
## precedence and RunDirector has accepted this exact authoritative block.
func resolve_focused_district_plan_block(
	occurrence_index: int,
	occurrence_id: StringName,
	route_index: int,
	node_id: StringName,
	baseline_node_type: StringName,
	district_snapshot: Dictionary
) -> CardResolutionRecord:
	var focused: DistrictPlanRecord = _pending_focused_record
	if focused == null or focused.resolved or occurrence_id == &"":
		return null
	if (
		String(district_snapshot.get("phase_name", "")) != "BLOCK"
		or int(district_snapshot.get("lap_index", -1)) != focused.lap_index
		or int(district_snapshot.get("block_index", -1)) != focused.block_index
		or StringName(district_snapshot.get("lap_id", &"")) != focused.lap_id
		or StringName(district_snapshot.get("block_id", &"")) != focused.block_id
		or StringName(
			district_snapshot.get("current_route_occurrence_id", &"")
		) != occurrence_id
	):
		return null
	focused.occurrence_index = occurrence_index
	focused.occurrence_id = occurrence_id
	focused.route_index = route_index
	focused.node_id = node_id
	focused.baseline_node_type = baseline_node_type
	focused.resolved = true
	_pending_focused_record = null
	_active_focused_record = focused

	var resolved: CardResolutionRecord = CardResolutionRecord.new()
	resolved.placement_token = focused.selection_token
	resolved.card = focused.card
	resolved.effect = focused.card.effect_definition
	resolved.slot_id = focused.block_id
	resolved.occurrence_index = occurrence_index
	resolved.route_index = route_index
	resolved.loop_count = focused.lap_index - 1
	resolved.node_id = node_id
	resolved.baseline_node_type = baseline_node_type
	card_route_effect_resolved.emit(resolved)
	district_plan_block_resolved.emit(resolved)
	_emit_snapshot()
	return resolved


func complete_focused_district_plan_block(
	lap_index: int,
	block_index: int
) -> bool:
	if (
		_active_focused_record == null
		or _active_focused_record.lap_index != lap_index
		or _active_focused_record.block_index != block_index
	):
		return false
	_active_focused_record.completed = true
	_active_focused_record = null
	_emit_snapshot()
	return true


func begin_planning(owns_pause: bool) -> bool:
	if (
		_focused_district_plan_enabled
		or _planning_active
		or _pending_reward_choice != null
	):
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
	_staged_focused_choice = null
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
		_focused_district_plan_enabled
		or encounter_instance_id < 0
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
	if _focused_district_plan_enabled:
		card_placement_rejected.emit(card_id, slot_id, &"legacy_route_planner_disabled")
		return _stage_result(false, &"legacy_route_planner_disabled", -1)
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
	var snapshot: Dictionary = {
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
		"staged_confirmation_token": _current_staged_confirmation_token(),
		"staged_card_id": _current_staged_card_id(),
		"staged_slot_id": _current_staged_target_id(),
		"pending_route_effects": pending_records,
		"resolved_route_effects": resolved_records,
		"pending_reward_encounter_id": get_pending_reward_encounter_id(),
		"pending_reward_choice_token": get_pending_reward_choice_token(),
		"pending_reward_choices": get_pending_reward_choices(),
		"reward_hand_full": _hand.size() >= HAND_CAPACITY,
		"no_reshuffle": true,
		"active_access_ids": get_active_access_ids(),
	}
	if _focused_district_plan_enabled:
		snapshot.merge({
			"mode": &"focused_next_block",
			"district_plan_enabled": true,
			"legacy_route_planner_enabled": false,
			"supplemental_card_rewards_enabled": false,
			"planning_required": true,
			"offer": _hand.duplicate(),
			"offer_ids": _card_ids(_hand),
			"offer_count": _hand.size(),
			"offer_capacity": DISTRICT_PLAN_OFFER_COUNT,
			"offer_revision": _focused_offer_revision,
			"lap_deck_ids": _card_ids(_draw_pile),
			"lap_deck_remaining": _draw_pile.size(),
			"lap_selected_ids": _card_ids(_discard_pile),
			"lap_selected_count": _discard_pile.size(),
			"lap_index": _focused_lap_index,
			"lap_id": _focused_lap_id,
			"block_index": _focused_block_index,
			"block_id": _focused_block_id,
			"context_lifecycle_revision": _focused_context_lifecycle_revision,
			"selected_next_block": (
				_pending_focused_record.to_dictionary()
				if _pending_focused_record != null
				else {}
			),
			"active_block": (
				_active_focused_record.to_dictionary()
				if _active_focused_record != null
				else {}
			),
			"current_lap_history": _focused_history_dictionaries(),
			"archived_lap_history": _archived_focused_laps.duplicate(true),
		})
	else:
		snapshot.merge({
			"mode": &"legacy_future_slots",
			"district_plan_enabled": false,
			"legacy_route_planner_enabled": true,
			"supplemental_card_rewards_enabled": true,
		})
	return snapshot


func get_active_access_ids() -> Array[StringName]:
	if not _active_allowed_card_ids.is_empty():
		return _active_allowed_card_ids.duplicate()
	var result: Array[StringName] = []
	if catalogue != null:
		result = catalogue.get_sorted_ids()
	return result


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


func _focused_stage_result(
	accepted: bool,
	reason: StringName,
	token: int
) -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"confirmation_token": token,
		"offer_revision": _focused_offer_revision,
		"lifecycle_revision": _focused_context_lifecycle_revision,
		"lap_id": _focused_lap_id,
		"block_id": _focused_block_id,
	}


func _current_staged_confirmation_token() -> int:
	if _focused_district_plan_enabled:
		return (
			_staged_focused_choice.confirmation_token
			if _staged_focused_choice != null
			else -1
		)
	return _staged_placement.confirmation_token if _staged_placement != null else -1


func _current_staged_card_id() -> StringName:
	if _focused_district_plan_enabled:
		return _staged_focused_choice.card_id if _staged_focused_choice != null else &""
	return _staged_placement.card_id if _staged_placement != null else &""


func _current_staged_target_id() -> StringName:
	if _focused_district_plan_enabled:
		return _staged_focused_choice.block_id if _staged_focused_choice != null else &""
	return _staged_placement.slot_id if _staged_placement != null else &""


func _reset_focused_state() -> void:
	_focused_offer_revision = 0
	_focused_context_lifecycle_revision = -1
	_focused_lap_index = -1
	_focused_lap_id = &""
	_focused_block_index = -1
	_focused_block_id = &""
	_staged_focused_choice = null
	_pending_focused_record = null
	_active_focused_record = null
	_focused_lap_records.clear()
	_archived_focused_laps.clear()


func _rebuild_focused_lap(lap_index: int, lap_id: StringName) -> bool:
	_draw_pile.clear()
	_hand.clear()
	_discard_pile.clear()
	_focused_lap_records.clear()
	_focused_lap_index = lap_index
	_focused_lap_id = lap_id
	for card: DistrictCardDefinition in _accessible_catalogue_cards():
		_draw_pile.append(card)
	_refill_focused_offer()
	_advance_focused_offer_revision()
	return not _hand.is_empty()


func _refill_focused_offer() -> void:
	while _hand.size() < DISTRICT_PLAN_OFFER_COUNT and not _draw_pile.is_empty():
		var card: DistrictCardDefinition = _draw_one_from_pile(&"district_plan_offer")
		if card == null:
			break
		_hand.append(card)


func _advance_focused_offer_revision() -> void:
	_focused_offer_revision += 1
	_hand_revision = _focused_offer_revision


func _accessible_catalogue_cards() -> Array[DistrictCardDefinition]:
	var result: Array[DistrictCardDefinition] = []
	if catalogue == null:
		return result
	for card: DistrictCardDefinition in catalogue.get_sorted_cards():
		if (
			card != null
			and (
				_active_allowed_card_ids.is_empty()
				or _active_allowed_card_ids.has(card.id)
			)
		):
			result.append(card)
	return result


func _archive_focused_lap() -> void:
	if _focused_lap_index < 1 or _focused_lap_records.is_empty():
		return
	_archived_focused_laps.append({
		"lap_index": _focused_lap_index,
		"lap_id": _focused_lap_id,
		"history": _focused_history_dictionaries(),
	})
	while _archived_focused_laps.size() > MAX_ARCHIVED_LAPS:
		_archived_focused_laps.pop_front()


func _focused_history_dictionaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: DistrictPlanRecord in _focused_lap_records:
		if record != null:
			result.append(record.to_dictionary())
	return result


static func focused_block_kind(card: DistrictCardDefinition) -> StringName:
	if card == null or card.effect_definition == null:
		return &"utility"
	match card.effect_definition.kind:
		CardEffectDefinition.EffectKind.ADD_STANDARD_ENCOUNTER:
			return &"fight"
		CardEffectDefinition.EffectKind.OPEN_ONE_PURCHASE_SHOP:
			return &"shop"
		CardEffectDefinition.EffectKind.ADD_ELITE_ENCOUNTER:
			return &"elite"
		CardEffectDefinition.EffectKind.REROUTE_SKIP_STANDARD:
			return &"utility"
	return &"utility"


static func focused_block_type(card: DistrictCardDefinition) -> String:
	if card == null or card.effect_definition == null:
		return "UTILITY"
	match card.effect_definition.kind:
		CardEffectDefinition.EffectKind.ADD_STANDARD_ENCOUNTER:
			return "FIGHT + REWARD"
		CardEffectDefinition.EffectKind.OPEN_ONE_PURCHASE_SHOP:
			return "SHOP + RECOVERY"
		CardEffectDefinition.EffectKind.ADD_ELITE_ENCOUNTER:
			return "ELITE + GEAR"
		CardEffectDefinition.EffectKind.REROUTE_SKIP_STANDARD:
			return "TRANSIT + COOLING"
	return "UTILITY"


static func focused_special_rule(card: DistrictCardDefinition) -> String:
	if card == null or card.effect_definition == null:
		return "NO AUTHORED EFFECT"
	var effect: CardEffectDefinition = card.effect_definition
	match effect.kind:
		CardEffectDefinition.EffectKind.ADD_STANDARD_ENCOUNTER:
			return "STANDARD FIGHT; REWARD QUALITY +%d TIER" % (
				maxi(effect.reward_quality_tier_steps, 0)
			)
		CardEffectDefinition.EffectKind.OPEN_ONE_PURCHASE_SHOP:
			return "ONE PURCHASE FROM EXISTING FINITE STOCK"
		CardEffectDefinition.EffectKind.ADD_ELITE_ENCOUNTER:
			return "VIPER ENFORCER; GUARANTEED GEAR CHOICE"
		CardEffectDefinition.EffectKind.REROUTE_SKIP_STANDARD:
			return "NO COMBAT; REPLACES ONE BASELINE FIGHT"
	return "AUTHORED DISTRICT EFFECT"


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
