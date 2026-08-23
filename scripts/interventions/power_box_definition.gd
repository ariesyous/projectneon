@tool
class_name PowerBoxDefinition
extends Resource

## Data-only authored Power Box Environment action.

@export var id: StringName = &"power_box"
@export var display_name: String = "Power Box"
@export var contextual_verb: String = "BREAKER"
@export_multiline var description: String = (
	"During a named enemy windup, trip the breaker: the marked cluster takes 4 damage, is interrupted, and is Shocked for 3 seconds."
)
@export var icon: Texture2D
@export_range(1.0, 320.0, 1.0) var range_radius: float = 96.0
@export_range(0, 1000, 1) var damage: int = 4
@export_range(0.0, 5.0, 0.05) var stun_seconds: float = 1.0
@export var status_id: StringName = &"shock"
@export_range(0.05, 30.0, 0.05) var status_duration_seconds: float = 3.0
@export_range(0.0, 120.0, 0.1) var cooldown_seconds: float = 12.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id != &"power_box":
		errors.append("WP05 Power Box stable id must be power_box")
	if display_name.strip_edges().is_empty() or contextual_verb.strip_edges().is_empty():
		errors.append("Power Box requires display name and contextual verb")
	if description.strip_edges().is_empty():
		errors.append("Power Box requires player-facing description")
	if icon == null:
		errors.append("Power Box requires a replaceable icon")
	if range_radius <= 0.0:
		errors.append("Power Box range must be positive")
	if damage != 4 or not is_equal_approx(stun_seconds, 1.0):
		errors.append("Approved Power Box must use 4 damage and 1.0 authored stun")
	if status_id != &"shock" or not is_equal_approx(status_duration_seconds, 3.0):
		errors.append("Approved Power Box must apply existing Shock for 3 seconds")
	if not is_equal_approx(cooldown_seconds, 12.0):
		errors.append("Approved Power Box base cooldown must be 12 seconds")
	return errors
