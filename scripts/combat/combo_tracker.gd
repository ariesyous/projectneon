class_name ComboTracker
extends Node

## Observes successful crew/environmental hits and owns only the shared combo
## counter, eligible-time expiry, highest value, and presentation milestones.

signal combo_changed(previous_combo: int, current_combo: int)
signal combo_expired(expired_combo: int)
signal highest_combo_changed(previous_highest: int, current_highest: int)
signal presentation_milestone_reached(milestone: int)
signal snapshot_changed(snapshot: Dictionary)

const SOURCE_CREW: StringName = &"crew"
const SOURCE_ENVIRONMENTAL: StringName = &"environmental"
const DEFAULT_TUNING: ComboTuningDefinition = preload(
	"res://data/combat/milestone_6_combo.tres"
)

@export var tuning: ComboTuningDefinition = DEFAULT_TUNING

var _current_combo: int = 0
var _highest_combo: int = 0
var _expiry_remaining: float = 0.0
var _last_source: StringName = &""


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING
	set_process(false)


func reset_for_run() -> void:
	var previous_combo: int = _current_combo
	var previous_highest: int = _highest_combo
	_current_combo = 0
	_highest_combo = 0
	_expiry_remaining = 0.0
	_last_source = &""
	if previous_combo > 0:
		combo_changed.emit(previous_combo, 0)
	if previous_highest > 0:
		highest_combo_changed.emit(previous_highest, 0)
	snapshot_changed.emit(get_snapshot())


func record_crew_hit() -> bool:
	return record_successful_hit(SOURCE_CREW)


func record_environmental_hit() -> bool:
	return record_successful_hit(SOURCE_ENVIRONMENTAL)


func record_successful_hit(source_id: StringName) -> bool:
	if source_id not in [SOURCE_CREW, SOURCE_ENVIRONMENTAL]:
		return false
	var previous_combo: int = _current_combo
	_current_combo += 1
	_expiry_remaining = maxf(_get_tuning().expiry_seconds, 0.001)
	_last_source = source_id
	combo_changed.emit(previous_combo, _current_combo)
	if _current_combo > _highest_combo:
		var previous_highest: int = _highest_combo
		_highest_combo = _current_combo
		highest_combo_changed.emit(previous_highest, _highest_combo)
	if _get_tuning().presentation_milestones.has(_current_combo):
		presentation_milestone_reached.emit(_current_combo)
	snapshot_changed.emit(get_snapshot())
	return true


## The caller supplies only authoritative eligible simulation time. Pauses,
## modal choices, and introductions therefore cannot age the combo.
func step_eligible_time(delta: float) -> bool:
	if delta <= 0.0 or _current_combo <= 0:
		return false
	_expiry_remaining = maxf(_expiry_remaining - delta, 0.0)
	if _expiry_remaining > 0.0:
		snapshot_changed.emit(get_snapshot())
		return false
	var expired_combo: int = _current_combo
	_current_combo = 0
	_last_source = &""
	combo_changed.emit(expired_combo, 0)
	combo_expired.emit(expired_combo)
	snapshot_changed.emit(get_snapshot())
	return true


func get_current_combo() -> int:
	return _current_combo


func get_highest_combo() -> int:
	return _highest_combo


func get_expiry_remaining() -> float:
	return _expiry_remaining


func get_snapshot() -> Dictionary:
	return {
		"current_combo": _current_combo,
		"highest_combo": _highest_combo,
		"expiry_remaining": _expiry_remaining,
		"expiry_seconds": _get_tuning().expiry_seconds,
		"last_source": _last_source,
		"presentation_milestones": _get_tuning().presentation_milestones,
		"presentation_only": true,
	}


func _get_tuning() -> ComboTuningDefinition:
	return tuning if tuning != null else DEFAULT_TUNING
