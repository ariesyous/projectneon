@tool
class_name EncounterSpawnEntry
extends Resource

## One stable-ID, budgeted actor entry in an authored encounter.

@export var actor_id: StringName = &"street_punk"
@export_range(0, 30, 1) var minimum_count: int = 0
@export_range(1, 30, 1) var maximum_count: int = 30
@export_range(1, 30, 1) var budget_cost: int = 1


func is_valid() -> bool:
	return (
		actor_id != &""
		and minimum_count >= 0
		and maximum_count >= maxi(minimum_count, 1)
		and budget_cost > 0
	)
