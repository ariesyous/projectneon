@tool
class_name RunLifecycleDefinition
extends Resource

## Presentation-only lifecycle timing. RunDirector remains the state and
## outcome authority; this Resource only supplies authored durations.

@export var id: StringName = &"milestone_6_run_lifecycle"
@export_range(0.0, 30.0, 0.05) var intro_duration_seconds: float = 1.25
@export_range(0.0, 30.0, 0.05) var extraction_duration_seconds: float = 1.0
@export_range(0.0, 30.0, 0.05) var boss_intro_duration_seconds: float = 2.5
@export_range(0.0, 30.0, 0.05) var victory_presentation_duration_seconds: float = 2.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("run lifecycle id must not be empty")
	if intro_duration_seconds < 0.0:
		errors.append("intro duration must not be negative")
	if extraction_duration_seconds < 0.0:
		errors.append("extraction duration must not be negative")
	if boss_intro_duration_seconds <= 0.0:
		errors.append("Milestone 6 boss intro duration must be positive")
	if victory_presentation_duration_seconds <= 0.0:
		errors.append("Milestone 6 victory presentation duration must be positive")
	return errors
