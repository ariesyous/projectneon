class_name WP05PrototypeTelemetry
extends RefCounted

## Development-only deterministic observation ledger. It receives eligible
## time from run authority and never schedules or changes gameplay.

const MAX_EVENTS: int = 256

var scenario_id: StringName = &""
var crew_id: StringName = &""
var build_ids: Array[StringName] = []
var eligible_seconds: float = 0.0
var events: Array[Dictionary] = []
var opportunities: Dictionary[StringName, int] = {}
var uses: Dictionary[StringName, int] = {}
var holds: Dictionary[StringName, int] = {}
var rejections: Dictionary[StringName, int] = {}
var results: Dictionary[StringName, int] = {}
var _open_opportunity_keys: Dictionary[StringName, StringName] = {}


func begin(
	requested_scenario_id: StringName,
	requested_crew_id: StringName,
	requested_build_ids: Array[StringName]
) -> void:
	scenario_id = requested_scenario_id
	crew_id = requested_crew_id
	build_ids = requested_build_ids.duplicate()
	build_ids.sort_custom(_string_name_before)
	eligible_seconds = 0.0
	events.clear()
	opportunities.clear()
	uses.clear()
	holds.clear()
	rejections.clear()
	results.clear()
	_open_opportunity_keys.clear()


func step_eligible_time(delta: float) -> void:
	eligible_seconds += maxf(delta, 0.0)


func observe_opportunity(
	role_id: StringName,
	opportunity_key: StringName,
	action_id: StringName,
	decision_window_seconds: float
) -> void:
	if opportunity_key == &"" or _open_opportunity_keys.get(role_id, &"") == opportunity_key:
		return
	if _open_opportunity_keys.has(role_id):
		record_hold(role_id, _open_opportunity_keys[role_id], &"window_passed")
	_open_opportunity_keys[role_id] = opportunity_key
	opportunities[role_id] = opportunities.get(role_id, 0) + 1
	_append_event(&"opportunity", role_id, action_id, &"available", {
		"opportunity_key": opportunity_key,
		"decision_window_seconds": maxf(decision_window_seconds, 0.0),
	})


func close_opportunity(role_id: StringName, reason: StringName = &"window_passed") -> void:
	if not _open_opportunity_keys.has(role_id):
		return
	record_hold(role_id, _open_opportunity_keys[role_id], reason)
	_open_opportunity_keys.erase(role_id)


func record_hold(role_id: StringName, opportunity_key: StringName, reason: StringName) -> void:
	holds[role_id] = holds.get(role_id, 0) + 1
	_append_event(&"hold", role_id, &"", reason, {"opportunity_key": opportunity_key})


func record_use(role_id: StringName, action_id: StringName, detail: Dictionary = {}) -> void:
	uses[role_id] = uses.get(role_id, 0) + 1
	_open_opportunity_keys.erase(role_id)
	_append_event(&"use", role_id, action_id, &"accepted", detail)


func record_rejection(role_id: StringName, action_id: StringName, reason: StringName) -> void:
	rejections[reason] = rejections.get(reason, 0) + 1
	_append_event(&"rejection", role_id, action_id, reason, {})


func record_result(role_id: StringName, action_id: StringName, result_id: StringName, detail: Dictionary = {}) -> void:
	results[result_id] = results.get(result_id, 0) + 1
	_append_event(&"result", role_id, action_id, result_id, detail)


func get_snapshot() -> Dictionary:
	return {
		"development_only": true,
		"authoritative": false,
		"scenario_id": scenario_id,
		"crew_id": crew_id,
		"build_ids": build_ids.duplicate(),
		"eligible_seconds": eligible_seconds,
		"opportunities": opportunities.duplicate(true),
		"uses": uses.duplicate(true),
		"holds": holds.duplicate(true),
		"rejections": rejections.duplicate(true),
		"results": results.duplicate(true),
		"events": events.duplicate(true),
	}


func _append_event(
	event_type: StringName,
	role_id: StringName,
	action_id: StringName,
	result_id: StringName,
	detail: Dictionary
) -> void:
	if events.size() >= MAX_EVENTS:
		events.pop_front()
	events.append({
		"sequence": events.size() + 1,
		"eligible_seconds": eligible_seconds,
		"event_type": event_type,
		"role_id": role_id,
		"action_id": action_id,
		"result_id": result_id,
		"detail": detail.duplicate(true),
	})


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
