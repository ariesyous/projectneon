class_name RunCadenceTracker
extends Node

## Observes opportunity timestamps measured by RunDirector's eligible active
## clock. It never schedules interactions or treats coin collection as a
## strategic decision.

signal opportunity_recorded(
	category: StringName,
	event_id: StringName,
	eligible_elapsed_seconds: float,
	gap_seconds: float,
	validation: StringName
)
signal opportunity_rejected(category: StringName, event_id: StringName, reason: StringName)
signal snapshot_changed(snapshot: Dictionary)

const CATEGORY_AMBIENT: StringName = &"ambient"
const CATEGORY_STRATEGIC: StringName = &"strategic"
const CATEGORY_MAJOR: StringName = &"major"
const VALIDATION_WITHIN_TARGET: StringName = &"within_target"
const VALIDATION_TOO_SOON: StringName = &"too_soon"
const VALIDATION_TOO_LATE: StringName = &"too_late"
const MAX_EVENT_HISTORY_PER_CATEGORY: int = 128
const DEFAULT_DEFINITION: RunCadenceDefinition = preload(
	"res://data/run/milestone_6_cadence.tres"
)

@export var definition: RunCadenceDefinition = DEFAULT_DEFINITION

var _latest_eligible_elapsed_seconds: float = 0.0
var _last_timestamps: Dictionary[StringName, float] = {}
var _event_counts: Dictionary[StringName, int] = {}
var _gap_totals: Dictionary[StringName, float] = {}
var _violation_counts: Dictionary[StringName, int] = {}
var _event_history: Dictionary[StringName, Array] = {}
var _coin_cluster_presentations: int = 0


func _ready() -> void:
	if definition == null:
		definition = DEFAULT_DEFINITION
	set_process(false)
	reset_for_run()


func reset_for_run() -> void:
	_latest_eligible_elapsed_seconds = 0.0
	_last_timestamps.clear()
	_event_counts.clear()
	_gap_totals.clear()
	_violation_counts.clear()
	_event_history.clear()
	_coin_cluster_presentations = 0
	for category: StringName in _categories():
		_last_timestamps[category] = 0.0
		_event_counts[category] = 0
		_gap_totals[category] = 0.0
		_violation_counts[category] = 0
		_event_history[category] = []
	snapshot_changed.emit(get_snapshot())


func record_coin_cluster_presented(
	cluster_id: int,
	eligible_elapsed_seconds: float
) -> bool:
	if cluster_id < 0:
		opportunity_rejected.emit(CATEGORY_AMBIENT, &"coin_cluster_presented", &"invalid_id")
		return false
	return _record_opportunity(
		CATEGORY_AMBIENT,
		StringName("coin_cluster_presented:%d" % cluster_id),
		eligible_elapsed_seconds,
		true
	)


func record_ambient_opportunity(
	event_id: StringName,
	eligible_elapsed_seconds: float
) -> bool:
	return _record_opportunity(
		CATEGORY_AMBIENT,
		event_id,
		eligible_elapsed_seconds,
		false
	)


func record_strategic_opportunity(
	event_id: StringName,
	eligible_elapsed_seconds: float
) -> bool:
	if _is_coin_event(event_id):
		opportunity_rejected.emit(CATEGORY_STRATEGIC, event_id, &"coin_is_not_strategic")
		return false
	return _record_opportunity(
		CATEGORY_STRATEGIC,
		event_id,
		eligible_elapsed_seconds,
		false
	)


func record_major_opportunity(
	event_id: StringName,
	eligible_elapsed_seconds: float
) -> bool:
	return _record_opportunity(
		CATEGORY_MAJOR,
		event_id,
		eligible_elapsed_seconds,
		false
	)


func get_event_count(category: StringName) -> int:
	return _event_counts.get(category, 0)


func get_average_gap(category: StringName) -> float:
	var count: int = get_event_count(category)
	return _gap_totals.get(category, 0.0) / float(count) if count > 0 else 0.0


func get_last_gap(category: StringName) -> float:
	var history: Array = _event_history.get(category, [])
	if history.is_empty():
		return 0.0
	var record: Dictionary = history.back() as Dictionary
	return float(record.get("gap_seconds", 0.0))


func get_gap_validation(category: StringName, gap_seconds: float) -> StringName:
	var target: Vector2 = _target_band(category)
	if target.x < 0.0:
		return &"invalid_category"
	if gap_seconds < target.x:
		return VALIDATION_TOO_SOON
	if gap_seconds > target.y:
		return VALIDATION_TOO_LATE
	return VALIDATION_WITHIN_TARGET


func get_snapshot() -> Dictionary:
	var category_snapshots: Dictionary = {}
	for category: StringName in _categories():
		var band: Vector2 = _target_band(category)
		category_snapshots[category] = {
			"count": get_event_count(category),
			"target_minimum_seconds": band.x,
			"target_maximum_seconds": band.y,
			"last_timestamp": _last_timestamps.get(category, 0.0),
			"last_gap": get_last_gap(category),
			"average_gap": get_average_gap(category),
			"violation_count": _violation_counts.get(category, 0),
			"events": (_event_history.get(category, []) as Array).duplicate(true),
		}
	return {
		"definition_id": _get_definition().id,
		"latest_eligible_elapsed_seconds": _latest_eligible_elapsed_seconds,
		"categories": category_snapshots,
		"coin_cluster_presentations": _coin_cluster_presentations,
		"coin_collections_count_as_strategic": false,
		"measurement_only": true,
	}


func _record_opportunity(
	category: StringName,
	event_id: StringName,
	eligible_elapsed_seconds: float,
	is_coin_presentation: bool
) -> bool:
	if not _categories().has(category):
		opportunity_rejected.emit(category, event_id, &"invalid_category")
		return false
	if event_id == &"":
		opportunity_rejected.emit(category, event_id, &"invalid_id")
		return false
	if (
		is_nan(eligible_elapsed_seconds)
		or is_inf(eligible_elapsed_seconds)
		or eligible_elapsed_seconds < _latest_eligible_elapsed_seconds
	):
		opportunity_rejected.emit(category, event_id, &"stale_or_invalid_time")
		return false
	var previous_timestamp: float = _last_timestamps.get(category, 0.0)
	var gap_seconds: float = maxf(eligible_elapsed_seconds - previous_timestamp, 0.0)
	var validation: StringName = get_gap_validation(category, gap_seconds)
	_latest_eligible_elapsed_seconds = eligible_elapsed_seconds
	_last_timestamps[category] = eligible_elapsed_seconds
	_event_counts[category] = get_event_count(category) + 1
	_gap_totals[category] = _gap_totals.get(category, 0.0) + gap_seconds
	if validation != VALIDATION_WITHIN_TARGET:
		_violation_counts[category] = _violation_counts.get(category, 0) + 1
	if is_coin_presentation:
		_coin_cluster_presentations += 1
	var history: Array = _event_history.get(category, [])
	history.append({
		"event_id": event_id,
		"eligible_elapsed_seconds": eligible_elapsed_seconds,
		"gap_seconds": gap_seconds,
		"validation": validation,
	})
	while history.size() > MAX_EVENT_HISTORY_PER_CATEGORY:
		history.pop_front()
	_event_history[category] = history
	opportunity_recorded.emit(
		category,
		event_id,
		eligible_elapsed_seconds,
		gap_seconds,
		validation
	)
	snapshot_changed.emit(get_snapshot())
	return true


func _target_band(category: StringName) -> Vector2:
	match category:
		CATEGORY_AMBIENT:
			return Vector2(
				_get_definition().ambient_minimum_seconds,
				_get_definition().ambient_maximum_seconds
			)
		CATEGORY_STRATEGIC:
			return Vector2(
				_get_definition().strategic_minimum_seconds,
				_get_definition().strategic_maximum_seconds
			)
		CATEGORY_MAJOR:
			return Vector2(
				_get_definition().major_minimum_seconds,
				_get_definition().major_maximum_seconds
			)
	return Vector2(-1.0, -1.0)


func _is_coin_event(event_id: StringName) -> bool:
	return String(event_id).to_lower().contains("coin")


func _categories() -> Array[StringName]:
	return [CATEGORY_AMBIENT, CATEGORY_STRATEGIC, CATEGORY_MAJOR]


func _get_definition() -> RunCadenceDefinition:
	return definition if definition != null else DEFAULT_DEFINITION
