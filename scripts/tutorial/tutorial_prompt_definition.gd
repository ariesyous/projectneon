@tool
class_name TutorialPromptDefinition
extends Resource

## Nonmodal, once-per-run contextual instruction. Presentation may dismiss the
## prompt at any time; the definition never pauses or mutates gameplay.

@export var id: StringName = &""
@export var trigger_id: StringName = &""
@export var heading: String = ""
@export_multiline var body: String = ""
@export_range(0, 100, 1) var priority: int = 0
@export_range(1.0, 20.0, 0.25) var display_seconds: float = 6.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not _is_lower_snake_case(id):
		errors.append("tutorial prompt id must be lowercase snake_case")
	if not _is_lower_snake_case(trigger_id):
		errors.append("tutorial trigger id must be lowercase snake_case")
	if heading.strip_edges().is_empty():
		errors.append("tutorial prompt '%s' has no heading" % id)
	if body.strip_edges().is_empty():
		errors.append("tutorial prompt '%s' has no body" % id)
	if display_seconds <= 0.0:
		errors.append("tutorial prompt '%s' display duration must be positive" % id)
	return errors


static func _is_lower_snake_case(value: StringName) -> bool:
	var text: String = String(value)
	return (
		not text.is_empty()
		and text == text.to_lower()
		and text == text.to_snake_case()
		and not text.begins_with("_")
		and not text.ends_with("_")
	)
