@tool
class_name StatusEffectDefinition
extends Resource

## Shared milestone-four status tuning. Actor-owned StatusController instances
## apply these definitions; equipment and synergies only reference stable ids.

@export var id: StringName
@export var display_name: String = "Status"
@export_range(0.05, 60.0, 0.05) var base_duration_seconds: float = 1.0
@export_range(1, 99, 1) var base_maximum_stacks: int = 1
@export_range(0.0, 60.0, 0.05) var tick_interval_seconds: float = 0.0
@export_range(0, 999, 1) var damage_per_stack: int = 0
@export_range(0.0, 5.0, 0.05) var intervention_damage_taken_bonus: float = 0.0
@export var presentation_color: Color = Color.WHITE


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("status id is empty")
	if display_name.strip_edges().is_empty():
		errors.append("status '%s' has no display name" % id)
	if base_duration_seconds <= 0.0:
		errors.append("status '%s' duration must be positive" % id)
	if base_maximum_stacks <= 0:
		errors.append("status '%s' maximum stacks must be positive" % id)
	if tick_interval_seconds < 0.0 or damage_per_stack < 0:
		errors.append("status '%s' tick tuning cannot be negative" % id)
	if intervention_damage_taken_bonus < 0.0:
		errors.append("status '%s' intervention damage bonus cannot be negative" % id)
	return errors
