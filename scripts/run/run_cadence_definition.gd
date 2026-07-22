@tool
class_name RunCadenceDefinition
extends Resource

## Eligible-active-time targets. This Resource describes measurement bands;
## it does not schedule prompts or mutate gameplay.

@export var id: StringName = &"milestone_6_cadence"
@export_range(0.0, 600.0, 0.5) var ambient_minimum_seconds: float = 10.0
@export_range(0.0, 600.0, 0.5) var ambient_maximum_seconds: float = 20.0
@export_range(0.0, 600.0, 0.5) var strategic_minimum_seconds: float = 30.0
@export_range(0.0, 600.0, 0.5) var strategic_maximum_seconds: float = 60.0
@export_range(0.0, 1200.0, 1.0) var major_minimum_seconds: float = 120.0
@export_range(0.0, 1200.0, 1.0) var major_maximum_seconds: float = 180.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("cadence definition id must not be empty")
	_validate_band(
		&"ambient", ambient_minimum_seconds, ambient_maximum_seconds, errors
	)
	_validate_band(
		&"strategic", strategic_minimum_seconds, strategic_maximum_seconds, errors
	)
	_validate_band(&"major", major_minimum_seconds, major_maximum_seconds, errors)
	return errors


func _validate_band(
	label: StringName,
	minimum_seconds: float,
	maximum_seconds: float,
	errors: PackedStringArray
) -> void:
	if minimum_seconds < 0.0:
		errors.append("%s cadence minimum must not be negative" % label)
	if maximum_seconds < minimum_seconds:
		errors.append("%s cadence maximum must be at least its minimum" % label)
