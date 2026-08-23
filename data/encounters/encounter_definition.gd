@tool
class_name EncounterDefinition
extends Resource

const EncounterSpawnEntryType = preload("res://data/encounters/encounter_spawn_entry.gd")

## One deterministic encounter candidate. Milestone 3 uses the existing Street
## Punk actor only; elite flags expose Heat eligibility without adding the
## later Viper Enforcer content.

@export var id: StringName = &"standard_encounter"
@export var display_name: String = "Street Fight"
@export_range(0, 5, 1) var minimum_heat_tier: int = 0
@export_range(0.0, 10000.0, 0.1) var minimum_night_pressure: float = 0.0
@export_range(1, 100, 1) var base_spawn_budget: int = 3
@export_range(1, 30, 1) var maximum_concurrent_enemies: int = 5
@export_range(0.0, 30.0, 0.1) var initial_spawn_delay_seconds: float = 0.0
@export_range(0.0, 30.0, 0.1) var spawn_interval_seconds: float = 0.0
@export var allowed_enemy_ids: Array[StringName] = [&"street_punk"]
@export var spawn_entries: Array[EncounterSpawnEntryType] = []
@export var spawn_position_ids: Array[StringName] = [&"lane_0", &"lane_1", &"lane_2"]
@export var reward_table_ids: Array[StringName] = [&"street_cache"]
@export var completion_condition: StringName = &"all_required_defeated"
@export_range(0, 100, 1) var heat_gain_on_completion: int = 4
@export var elite_eligible: bool = false
@export var boss: bool = false
@export var environment_action_id: StringName = &"fire_hydrant"
