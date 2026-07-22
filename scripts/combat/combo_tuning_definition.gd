@tool
class_name ComboTuningDefinition
extends Resource

## Run-scoped shared combo timing. Milestones request presentation only and
## never change damage, rewards, Heat, Night Pressure, or random streams.

@export var id: StringName = &"milestone_6_combo"
@export_range(0.05, 30.0, 0.05) var expiry_seconds: float = 2.5
@export var presentation_milestones: PackedInt32Array = PackedInt32Array([10, 20, 30, 50])


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("combo tuning id must not be empty")
	if expiry_seconds <= 0.0:
		errors.append("combo expiry must be positive")
	var seen: Dictionary[int, bool] = {}
	var previous: int = 0
	for milestone: int in presentation_milestones:
		if milestone <= 0:
			errors.append("combo milestones must be positive")
		if seen.has(milestone):
			errors.append("combo milestone %d is repeated" % milestone)
		if milestone < previous:
			errors.append("combo milestones must use stable ascending order")
		seen[milestone] = true
		previous = milestone
	return errors
