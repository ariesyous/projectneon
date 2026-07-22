class_name RunSummaryRecord
extends RefCounted

## Immutable-at-publication summary snapshot assembled by RunDirector from
## authoritative run and ledger values.

var result: int = 0
var result_label: String = "IN PROGRESS"
var duration_seconds: float = 0.0
var run_seed: int = 0
var random_schema_version: int = 0
var maximum_heat: int = 0
var final_night_pressure: float = 0.0
var encounters_completed: int = 0
var enemies_defeated: int = 0
var elites_defeated: int = 0
var boss_defeated: bool = false
var boss_result: String = "NOT REACHED"
var coins_collected: int = 0
var manual_clusters_collected: int = 0
var maximum_manual_streak: int = 0
var scrap_secured: int = 0
var boss_triggered: bool = false
var highest_combo: int = 0
var equipment_build: String = "NOT AVAILABLE IN MILESTONE 3"
var active_synergies: String = "NOT AVAILABLE IN MILESTONE 3"


func to_dictionary() -> Dictionary:
	return {
		"result": result,
		"result_label": result_label,
		"duration_seconds": duration_seconds,
		"run_seed": run_seed,
		"random_schema_version": random_schema_version,
		"maximum_heat": maximum_heat,
		"final_night_pressure": final_night_pressure,
		"encounters_completed": encounters_completed,
		"enemies_defeated": enemies_defeated,
		"elites_defeated": elites_defeated,
		"boss_defeated": boss_defeated,
		"boss_result": boss_result,
		"coins_collected": coins_collected,
		"manual_clusters_collected": manual_clusters_collected,
		"maximum_manual_streak": maximum_manual_streak,
		"scrap_secured": scrap_secured,
		"boss_triggered": boss_triggered,
		"highest_combo": highest_combo,
		"equipment_build": equipment_build,
		"active_synergies": active_synergies,
	}
