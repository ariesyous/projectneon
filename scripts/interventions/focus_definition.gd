@tool
class_name FocusDefinition
extends Resource

## Data-only approved WP05 Focus priority tuning.

@export var id: StringName = &"focus_priority"
@export var display_name: String = "Focus"
@export_multiline var description: String = (
	"Temporarily prioritize the named enemy intent. Crew movement and attacks remain automatic."
)
@export var icon: Texture2D
@export_range(0.05, 30.0, 0.05) var priority_duration_seconds: float = 3.0
@export_range(0.0, 120.0, 0.1) var cooldown_seconds: float = 10.0
@export_range(0.05, 5.0, 0.05) var minimum_decision_window_seconds: float = 0.35


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id != &"focus_priority":
		errors.append("WP05 Focus stable id must be focus_priority")
	if display_name.strip_edges().is_empty() or description.strip_edges().is_empty():
		errors.append("Focus requires player-facing name and description")
	if icon == null:
		errors.append("Focus requires a replaceable icon")
	if not is_equal_approx(priority_duration_seconds, 3.0):
		errors.append("Approved Focus priority duration must be 3 seconds")
	if not is_equal_approx(cooldown_seconds, 10.0):
		errors.append("Approved Focus base cooldown must be 10 seconds")
	if not is_equal_approx(minimum_decision_window_seconds, 0.35):
		errors.append("Approved Focus decision cutoff must be 0.35 seconds")
	return errors
