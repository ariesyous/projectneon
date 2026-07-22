@tool
class_name LifetimeStatisticsData
extends Resource

## Minimal non-gameplay lifetime accounting. These values never modify actor
## statistics, rewards, run timing, or deterministic random streams.

@export_range(0, 2147483647, 1) var completed_runs: int = 0
@export_range(0, 2147483647, 1) var victories: int = 0
@export_range(0, 2147483647, 1) var extractions: int = 0
@export_range(0, 2147483647, 1) var defeats: int = 0
@export_range(0, 2147483647, 1) var elites_defeated: int = 0


static func from_dictionary(raw_value: Variant) -> LifetimeStatisticsData:
	var result: LifetimeStatisticsData = LifetimeStatisticsData.new()
	if not raw_value is Dictionary:
		return result
	var values: Dictionary = raw_value as Dictionary
	result.completed_runs = _read_count(values, "completed_runs")
	result.victories = _read_count(values, "victories")
	result.extractions = _read_count(values, "extractions")
	result.defeats = _read_count(values, "defeats")
	result.elites_defeated = _read_count(values, "elites_defeated")
	return result


func to_dictionary() -> Dictionary:
	return {
		"completed_runs": maxi(completed_runs, 0),
		"victories": maxi(victories, 0),
		"extractions": maxi(extractions, 0),
		"defeats": maxi(defeats, 0),
		"elites_defeated": maxi(elites_defeated, 0),
	}


func record_completed_run(outcome_id: StringName, elite_count: int) -> bool:
	if outcome_id not in [&"victory", &"extracted", &"defeated"]:
		return false
	completed_runs += 1
	elites_defeated += maxi(elite_count, 0)
	match outcome_id:
		&"victory":
			victories += 1
		&"extracted":
			extractions += 1
		&"defeated":
			defeats += 1
	return true


static func _read_count(values: Dictionary, key: String) -> int:
	var value: Variant = values.get(key, 0)
	if value is int or value is float:
		return maxi(int(value), 0)
	return 0
