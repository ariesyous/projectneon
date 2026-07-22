@tool
class_name RunLoadoutDefinition
extends Resource

## Authored vertical-slice run-entry rules. Profile access determines which of
## these catalogue IDs may be selected; this Resource grants no persistent
## statistical bonus.

@export_range(1, 3, 1) var starting_crew_size: int = 1
@export_range(1, 3, 1) var maximum_active_crew_size: int = 3
@export var selectable_crew_ids: Array[StringName] = [&"jax", &"zoey", &"rex"]


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if starting_crew_size != 1:
		errors.append("The vertical slice must start with exactly one crew member.")
	if maximum_active_crew_size != 3:
		errors.append("The vertical slice maximum active crew size must be three.")
	if selectable_crew_ids.size() != 3:
		errors.append("The vertical slice has exactly three selectable crew IDs.")
	var seen: Dictionary[StringName, bool] = {}
	for crew_id: StringName in selectable_crew_ids:
		if crew_id == &"" or seen.has(crew_id):
			errors.append("Selectable crew IDs must be non-empty and unique.")
		else:
			seen[crew_id] = true
	for required_id: StringName in [&"jax", &"zoey", &"rex"]:
		if not seen.has(required_id):
			errors.append("Selectable crew is missing required ID '%s'." % required_id)
	return errors
