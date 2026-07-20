class_name PatrolController
extends Node

## Owns fixed-route travel, stable monotonic route occurrences, revisioned
## future-card modifications, and the immediate travel skip used by the finite
## Subway Reroute intervention. Run state and Heat remain external authorities.

signal route_node_entered(route_index: int, node_id: StringName, node_type: StringName)
signal route_occurrence_entered(
	occurrence_index: int,
	occurrence_id: StringName,
	route_index: int,
	node_id: StringName,
	node_type: StringName
)
signal route_progress_changed(route_index: int, progress: float, loop_count: int)
signal reroute_resolved(previous_index: int, new_index: int)
signal route_revision_changed(previous_revision: int, new_revision: int)
signal route_slots_changed(slots: Array[RouteSlotSnapshot], route_revision: int)
signal future_route_modification_applied(record: RouteModificationRecord)
signal route_modification_resolved(record: RouteModificationRecord)
signal route_modification_expired(record: RouteModificationRecord)

const RESPONSIBILITY: String = "Coordinate crew patrol along the district route."
const DEFAULT_ROUTE: PatrolRouteDefinition = preload(
	"res://data/routes/downtown_loop_route.tres"
)
const FUTURE_ROUTE_SLOT_COUNT: int = 5
const ROUTE_SLOT_HISTORY_COUNT: int = 5
const RESOLVED_MODIFICATION_HISTORY_LIMIT: int = 10

const SLOT_STATUS_VALID: StringName = &"valid"
const SLOT_STATUS_OCCUPIED: StringName = &"occupied"
const SLOT_STATUS_CURRENT: StringName = &"current"
const SLOT_STATUS_PAST: StringName = &"past"
const SLOT_STATUS_EXPIRED: StringName = &"expired"
const SLOT_STATUS_INVALID: StringName = &"invalid"

const PLACEMENT_OK: StringName = &"ok"
const PLACEMENT_STALE: StringName = &"stale"
const PLACEMENT_INVALID: StringName = &"invalid"
const PLACEMENT_WRONG_NODE: StringName = &"wrong_node"
const PLACEMENT_DUPLICATE_TOKEN: StringName = &"duplicate_token"

@export var route_definition: PatrolRouteDefinition = DEFAULT_ROUTE

var simulation_enabled: bool = false
var route_index: int = -1
var loop_count: int = 0
var _travel_remaining: float = 0.0
var _awaiting_node_resolution: bool = false
var _current_occurrence_index: int = -1
var _route_revision: int = 0
var _pending_modifications: Dictionary[int, RouteModificationRecord] = {}
var _resolved_modification_history: Array[RouteModificationRecord] = []
var _closed_slot_states: Dictionary[StringName, StringName] = {}
var _used_placement_tokens: Dictionary[int, bool] = {}


func _ready() -> void:
	if route_definition == null:
		route_definition = DEFAULT_ROUTE


func _process(delta: float) -> void:
	step_patrol(delta)


func start_patrol() -> void:
	var previous_revision: int = _route_revision
	simulation_enabled = false
	route_index = -1
	loop_count = 0
	_travel_remaining = 0.0
	_awaiting_node_resolution = false
	_current_occurrence_index = -1
	_pending_modifications.clear()
	_resolved_modification_history.clear()
	_closed_slot_states.clear()
	_used_placement_tokens.clear()
	_route_revision = previous_revision
	_advance_route_revision()
	_begin_segment()


func reset_patrol() -> void:
	simulation_enabled = false
	route_index = -1
	loop_count = 0
	_travel_remaining = 0.0
	_awaiting_node_resolution = false
	_current_occurrence_index = -1
	_pending_modifications.clear()
	_resolved_modification_history.clear()
	_closed_slot_states.clear()
	_used_placement_tokens.clear()
	_advance_route_revision()


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled


func step_patrol(delta: float) -> void:
	if not simulation_enabled or _awaiting_node_resolution or delta <= 0.0:
		return
	_travel_remaining = maxf(_travel_remaining - delta, 0.0)
	var segment_duration: float = maxf(route_definition.travel_seconds_per_segment, 0.001)
	var progress: float = clampf(1.0 - _travel_remaining / segment_duration, 0.0, 1.0)
	route_progress_changed.emit(route_index, progress, loop_count)
	if _travel_remaining <= 0.0:
		_enter_next_node()


func continue_from_current_node() -> bool:
	if not _awaiting_node_resolution:
		return false
	_awaiting_node_resolution = false
	_begin_segment()
	return true


func can_reroute() -> bool:
	return simulation_enabled and not _awaiting_node_resolution and route_definition.node_count() > 0


func request_reroute() -> bool:
	if not can_reroute():
		return false
	var previous_index: int = route_index
	_travel_remaining = 0.0
	_enter_next_node()
	reroute_resolved.emit(previous_index, route_index)
	return true


func get_route_node_id() -> StringName:
	return route_definition.node_id(route_index) if route_index >= 0 else &"departing_hideout"


func get_route_node_type() -> StringName:
	return route_definition.node_type(route_index) if route_index >= 0 else &"travel"


func get_route_progress() -> float:
	if _awaiting_node_resolution:
		return 1.0
	var duration: float = maxf(route_definition.travel_seconds_per_segment, 0.001)
	return clampf(1.0 - _travel_remaining / duration, 0.0, 1.0)


func get_route_revision() -> int:
	return _route_revision


func get_current_occurrence_index() -> int:
	return _current_occurrence_index


func get_current_occurrence_id() -> StringName:
	if _current_occurrence_index < 0:
		return &"departing_hideout"
	return _occurrence_id(_current_occurrence_index)


func get_future_route_slots() -> Array[RouteSlotSnapshot]:
	var slots: Array[RouteSlotSnapshot] = []
	var count: int = route_definition.node_count()
	if count <= 0:
		return slots
	for offset: int in range(1, FUTURE_ROUTE_SLOT_COUNT + 1):
		var occurrence_index: int = _current_occurrence_index + offset
		var future_route_index: int = wrapi(occurrence_index, 0, count)
		var future_loop_count: int = floori(float(occurrence_index) / float(count))
		var slot_id: StringName = _slot_id(occurrence_index)
		var status: StringName = get_route_slot_status(slot_id)
		var snapshot: RouteSlotSnapshot = RouteSlotSnapshot.new(
			slot_id,
			occurrence_index,
			_occurrence_id(occurrence_index),
			future_route_index,
			future_loop_count,
			route_definition.node_id(future_route_index),
			route_definition.node_type(future_route_index),
			_route_revision,
			status
		)
		var modification: RouteModificationRecord = _pending_modifications.get(
			occurrence_index
		) as RouteModificationRecord
		if modification != null:
			snapshot.occupied_card_id = modification.card_id
			snapshot.occupied_effect_id = modification.effect_id
			snapshot.placement_token = modification.placement_token
		slots.append(snapshot)
	return slots


## Presentation-only history keeps the fixed five future placement targets
## separate while exposing the current and recently closed stable identities.
## These snapshots never become valid placement destinations.
func get_route_slot_history() -> Array[RouteSlotSnapshot]:
	var slots: Array[RouteSlotSnapshot] = []
	var count: int = route_definition.node_count()
	if count <= 0 or _current_occurrence_index < 0:
		return slots
	var oldest_occurrence: int = maxi(
		0,
		_current_occurrence_index - ROUTE_SLOT_HISTORY_COUNT + 1
	)
	for occurrence_index: int in range(_current_occurrence_index, oldest_occurrence - 1, -1):
		var history_route_index: int = wrapi(occurrence_index, 0, count)
		var history_loop_count: int = floori(float(occurrence_index) / float(count))
		var slot_id: StringName = _slot_id(occurrence_index)
		var snapshot: RouteSlotSnapshot = RouteSlotSnapshot.new(
			slot_id,
			occurrence_index,
			_occurrence_id(occurrence_index),
			history_route_index,
			history_loop_count,
			route_definition.node_id(history_route_index),
			route_definition.node_type(history_route_index),
			_route_revision,
			get_route_slot_status(slot_id)
		)
		var modification: RouteModificationRecord = _pending_modifications.get(
			occurrence_index
		) as RouteModificationRecord
		if modification != null:
			snapshot.occupied_card_id = modification.card_id
			snapshot.occupied_effect_id = modification.effect_id
			snapshot.placement_token = modification.placement_token
		slots.append(snapshot)
	return slots


func get_route_slot_status(slot_id: StringName) -> StringName:
	var occurrence_index: int = _occurrence_from_slot_id(slot_id)
	if occurrence_index < 0 or route_definition.node_count() <= 0:
		return SLOT_STATUS_INVALID
	if occurrence_index == _current_occurrence_index:
		return SLOT_STATUS_CURRENT
	if occurrence_index < _current_occurrence_index:
		var closed_state: StringName = _closed_slot_states.get(slot_id, &"")
		if closed_state == RouteModificationRecord.STATE_EXPIRED:
			return SLOT_STATUS_EXPIRED
		return SLOT_STATUS_PAST
	if occurrence_index > _current_occurrence_index + FUTURE_ROUTE_SLOT_COUNT:
		return SLOT_STATUS_INVALID
	if _pending_modifications.has(occurrence_index):
		return SLOT_STATUS_OCCUPIED
	return SLOT_STATUS_VALID


func apply_future_route_modification(
	slot_id: StringName,
	card_id: StringName,
	effect_id: StringName,
	placement_token: int,
	valid_node_types: Array[StringName],
	expected_revision: int
) -> StringName:
	if expected_revision != _route_revision:
		return PLACEMENT_STALE
	if (
		slot_id == &""
		or card_id == &""
		or effect_id == &""
		or placement_token < 0
		or valid_node_types.is_empty()
	):
		return PLACEMENT_INVALID
	if _used_placement_tokens.has(placement_token):
		return PLACEMENT_DUPLICATE_TOKEN
	var status: StringName = get_route_slot_status(slot_id)
	if status != SLOT_STATUS_VALID:
		return status
	var occurrence_index: int = _occurrence_from_slot_id(slot_id)
	var count: int = route_definition.node_count()
	if occurrence_index < 0 or count <= 0:
		return PLACEMENT_INVALID
	var target_route_index: int = wrapi(occurrence_index, 0, count)
	var target_node_type: StringName = route_definition.node_type(target_route_index)
	if not valid_node_types.has(target_node_type):
		return PLACEMENT_WRONG_NODE

	var record: RouteModificationRecord = RouteModificationRecord.new()
	record.slot_id = slot_id
	record.occurrence_index = occurrence_index
	record.occurrence_id = _occurrence_id(occurrence_index)
	record.route_index = target_route_index
	record.loop_count = floori(float(occurrence_index) / float(count))
	record.node_id = route_definition.node_id(target_route_index)
	record.node_type = target_node_type
	record.card_id = card_id
	record.effect_id = effect_id
	record.placement_token = placement_token
	record.applied_route_revision = _route_revision + 1
	record.state = RouteModificationRecord.STATE_PENDING
	_pending_modifications[occurrence_index] = record
	_used_placement_tokens[placement_token] = true
	_advance_route_revision()
	future_route_modification_applied.emit(record.duplicate_record())
	return PLACEMENT_OK


func get_current_route_modification() -> RouteModificationRecord:
	if not _awaiting_node_resolution or _current_occurrence_index < 0:
		return null
	var record: RouteModificationRecord = _pending_modifications.get(
		_current_occurrence_index
	) as RouteModificationRecord
	return record.duplicate_record() if record != null else null


func resolve_current_route_modification(expected_token: int) -> RouteModificationRecord:
	if not _awaiting_node_resolution or _current_occurrence_index < 0:
		return null
	var record: RouteModificationRecord = _pending_modifications.get(
		_current_occurrence_index
	) as RouteModificationRecord
	if record == null or record.placement_token != expected_token:
		return null
	_pending_modifications.erase(_current_occurrence_index)
	record.state = RouteModificationRecord.STATE_RESOLVED
	record.resolved_route_revision = _route_revision + 1
	_closed_slot_states[record.slot_id] = record.state
	_append_resolved_record(record)
	_advance_route_revision()
	var result: RouteModificationRecord = record.duplicate_record()
	route_modification_resolved.emit(result.duplicate_record())
	return result


func get_snapshot() -> Dictionary:
	var future_slot_snapshots: Array[Dictionary] = []
	for slot: RouteSlotSnapshot in get_future_route_slots():
		future_slot_snapshots.append(slot.to_dictionary())
	var route_slot_history: Array[Dictionary] = []
	for slot: RouteSlotSnapshot in get_route_slot_history():
		route_slot_history.append(slot.to_dictionary())
	var pending_snapshots: Array[Dictionary] = []
	var pending_occurrences: Array[int] = []
	for occurrence_value: Variant in _pending_modifications.keys():
		pending_occurrences.append(int(occurrence_value))
	pending_occurrences.sort()
	for occurrence_index: int in pending_occurrences:
		var pending: RouteModificationRecord = _pending_modifications.get(
			occurrence_index
		) as RouteModificationRecord
		if pending != null:
			pending_snapshots.append(pending.to_dictionary())
	var resolved_snapshots: Array[Dictionary] = []
	for resolved: RouteModificationRecord in _resolved_modification_history:
		resolved_snapshots.append(resolved.to_dictionary())
	var current_modification: RouteModificationRecord = get_current_route_modification()
	return {
		"route_id": route_definition.id,
		"route_index": route_index,
		"route_node_id": get_route_node_id(),
		"route_node_type": get_route_node_type(),
		"route_progress": get_route_progress(),
		"loop_count": loop_count,
		"awaiting_node_resolution": _awaiting_node_resolution,
		"simulation_enabled": simulation_enabled,
		"route_revision": _route_revision,
		"current_occurrence_index": _current_occurrence_index,
		"current_occurrence_id": get_current_occurrence_id(),
		"future_route_slots": future_slot_snapshots,
		"route_slot_history": route_slot_history,
		"pending_route_modifications": pending_snapshots,
		"resolved_route_modifications": resolved_snapshots,
		"current_route_modification": (
			current_modification.to_dictionary() if current_modification != null else {}
		),
	}


func _begin_segment() -> void:
	_travel_remaining = maxf(route_definition.travel_seconds_per_segment, 0.001)
	route_progress_changed.emit(route_index, 0.0, loop_count)


func _enter_next_node() -> void:
	var count: int = route_definition.node_count()
	if count <= 0:
		return
	var next_index: int = route_index + 1
	if next_index >= count:
		next_index = 0
		loop_count += 1
	_current_occurrence_index += 1
	var expired_records: Array[RouteModificationRecord] = _expire_modifications_before(
		_current_occurrence_index
	)
	route_index = next_index
	_awaiting_node_resolution = true
	_advance_route_revision()
	for expired: RouteModificationRecord in expired_records:
		route_modification_expired.emit(expired.duplicate_record())
	route_progress_changed.emit(route_index, 1.0, loop_count)
	route_occurrence_entered.emit(
		_current_occurrence_index,
		get_current_occurrence_id(),
		route_index,
		route_definition.node_id(route_index),
		route_definition.node_type(route_index)
	)
	route_node_entered.emit(
		route_index,
		route_definition.node_id(route_index),
		route_definition.node_type(route_index)
	)


func _advance_route_revision() -> void:
	var previous_revision: int = _route_revision
	_route_revision += 1
	route_revision_changed.emit(previous_revision, _route_revision)
	route_slots_changed.emit(get_future_route_slots(), _route_revision)


func _expire_modifications_before(
	occurrence_limit: int
) -> Array[RouteModificationRecord]:
	var expired_records: Array[RouteModificationRecord] = []
	var pending_occurrences: Array[int] = []
	for occurrence_value: Variant in _pending_modifications.keys():
		var occurrence_index: int = int(occurrence_value)
		if occurrence_index < occurrence_limit:
			pending_occurrences.append(occurrence_index)
	pending_occurrences.sort()
	for occurrence_index: int in pending_occurrences:
		var record: RouteModificationRecord = _pending_modifications.get(
			occurrence_index
		) as RouteModificationRecord
		_pending_modifications.erase(occurrence_index)
		if record == null:
			continue
		record.state = RouteModificationRecord.STATE_EXPIRED
		record.resolved_route_revision = _route_revision + 1
		_closed_slot_states[record.slot_id] = record.state
		_append_resolved_record(record)
		expired_records.append(record.duplicate_record())
	return expired_records


func _append_resolved_record(record: RouteModificationRecord) -> void:
	_resolved_modification_history.append(record)
	while _resolved_modification_history.size() > RESOLVED_MODIFICATION_HISTORY_LIMIT:
		_resolved_modification_history.pop_front()


func _slot_id(occurrence_index: int) -> StringName:
	return StringName("%s::route_slot::%d" % [route_definition.id, occurrence_index])


func _occurrence_id(occurrence_index: int) -> StringName:
	return StringName("%s::occurrence::%d" % [route_definition.id, occurrence_index])


func _occurrence_from_slot_id(slot_id: StringName) -> int:
	var prefix: String = "%s::route_slot::" % String(route_definition.id)
	var slot_text: String = String(slot_id)
	if not slot_text.begins_with(prefix):
		return -1
	var occurrence_text: String = slot_text.trim_prefix(prefix)
	if not occurrence_text.is_valid_int():
		return -1
	return int(occurrence_text)
