class_name StatusController
extends Node

## Actor-owned deterministic status state. Definitions are data; this node owns
## remaining duration, stacks, tick cadence, and cleanup for one actor.

signal status_changed(status_id: StringName, stacks: int, remaining_seconds: float)
signal status_damage_requested(amount: int, status_id: StringName)

const BLEED_DEFINITION: StatusEffectDefinition = preload(
	"res://data/equipment/bleed_status.tres"
)
const SHOCK_DEFINITION: StatusEffectDefinition = preload(
	"res://data/equipment/shock_status.tres"
)
const WET_DEFINITION: StatusEffectDefinition = preload(
	"res://data/effects/wet_status.tres"
)

@export var status_definitions: Array[StatusEffectDefinition] = []

var _definition_by_id: Dictionary[StringName, StatusEffectDefinition] = {}
var _remaining_by_id: Dictionary[StringName, float] = {}
var _stacks_by_id: Dictionary[StringName, int] = {}
var _tick_remaining_by_id: Dictionary[StringName, float] = {}


func _init() -> void:
	status_definitions = []
	_ensure_default_definitions()
	_rebuild_index()


func _ready() -> void:
	# Authored actor scenes may explicitly list older statuses. Merge the
	# versioned shared defaults by stable ID so future-compatible markers such
	# as Wet cannot disappear when an existing scene is loaded.
	_ensure_default_definitions()
	_rebuild_index()


func step(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	if safe_delta <= 0.0:
		return
	var active_ids: Array[StringName] = []
	for status_id: StringName in _remaining_by_id.keys():
		active_ids.append(status_id)
	active_ids.sort_custom(_string_name_before)
	for status_id: StringName in active_ids:
		var definition: StatusEffectDefinition = _definition_by_id.get(status_id)
		if definition == null:
			_clear_status(status_id)
			continue
		var remaining: float = maxf(_remaining_by_id.get(status_id, 0.0) - safe_delta, 0.0)
		_remaining_by_id[status_id] = remaining
		if definition.tick_interval_seconds > 0.0 and definition.damage_per_stack > 0:
			var tick_remaining: float = _tick_remaining_by_id.get(
				status_id,
				definition.tick_interval_seconds
			) - safe_delta
			while tick_remaining <= 0.0 and remaining > 0.0:
				status_damage_requested.emit(
					definition.damage_per_stack * _stacks_by_id.get(status_id, 0),
					status_id
				)
				tick_remaining += definition.tick_interval_seconds
			_tick_remaining_by_id[status_id] = tick_remaining
		if remaining <= 0.0:
			_clear_status(status_id)
		else:
			status_changed.emit(status_id, _stacks_by_id.get(status_id, 0), remaining)


func apply_status(
	status_id: StringName,
	stacks: int,
	duration_seconds: float,
	maximum_stacks_override: int = -1
) -> bool:
	var definition: StatusEffectDefinition = _definition_by_id.get(status_id)
	if definition == null or stacks <= 0 or duration_seconds <= 0.0:
		return false
	var maximum_stacks: int = definition.base_maximum_stacks
	if maximum_stacks_override > 0:
		maximum_stacks = maximum_stacks_override
	var previous_stacks: int = _stacks_by_id.get(status_id, 0)
	_stacks_by_id[status_id] = mini(previous_stacks + stacks, maximum_stacks)
	_remaining_by_id[status_id] = maxf(
		_remaining_by_id.get(status_id, 0.0),
		duration_seconds
	)
	if not _tick_remaining_by_id.has(status_id) and definition.tick_interval_seconds > 0.0:
		_tick_remaining_by_id[status_id] = definition.tick_interval_seconds
	status_changed.emit(status_id, _stacks_by_id[status_id], _remaining_by_id[status_id])
	return true


func has_status(status_id: StringName) -> bool:
	return _remaining_by_id.get(status_id, 0.0) > 0.0 and _stacks_by_id.get(status_id, 0) > 0


func get_stacks(status_id: StringName) -> int:
	return _stacks_by_id.get(status_id, 0)


func get_remaining(status_id: StringName) -> float:
	return _remaining_by_id.get(status_id, 0.0)


func clear_all() -> void:
	var active_ids: Array[StringName] = []
	for status_id: StringName in _remaining_by_id.keys():
		active_ids.append(status_id)
	active_ids.sort_custom(_string_name_before)
	for status_id: StringName in active_ids:
		_clear_status(status_id)


func get_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var active_ids: Array[StringName] = []
	for status_id: StringName in _remaining_by_id.keys():
		active_ids.append(status_id)
	active_ids.sort_custom(_string_name_before)
	for status_id: StringName in active_ids:
		result.append({
			"id": status_id,
			"stacks": _stacks_by_id.get(status_id, 0),
			"remaining_seconds": _remaining_by_id.get(status_id, 0.0),
		})
	return result


func _rebuild_index() -> void:
	_definition_by_id.clear()
	for definition: StatusEffectDefinition in status_definitions:
		if definition == null or definition.id == &"" or _definition_by_id.has(definition.id):
			continue
		_definition_by_id[definition.id] = definition


func _ensure_default_definitions() -> void:
	var existing_ids: Dictionary[StringName, bool] = {}
	for definition: StatusEffectDefinition in status_definitions:
		if definition != null and definition.id != &"":
			existing_ids[definition.id] = true
	for definition: StatusEffectDefinition in [
		BLEED_DEFINITION,
		SHOCK_DEFINITION,
		WET_DEFINITION,
	]:
		if not existing_ids.has(definition.id):
			status_definitions.append(definition)
			existing_ids[definition.id] = true


func _clear_status(status_id: StringName) -> void:
	_remaining_by_id.erase(status_id)
	_stacks_by_id.erase(status_id)
	_tick_remaining_by_id.erase(status_id)
	status_changed.emit(status_id, 0, 0.0)


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
