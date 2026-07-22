@tool
class_name UnlockRuleDefinition
extends Resource

enum ContentKind {
	CREW,
	EQUIPMENT,
	CARD,
}

enum Trigger {
	FIRST_COMPLETED_RUN,
	FIRST_ELITE_DEFEAT,
	FIRST_EXTRACTION,
	FIRST_VICTORY,
}

@export var id: StringName = &""
@export var content_kind: ContentKind = ContentKind.CREW
@export var content_id: StringName = &""
@export var trigger: Trigger = Trigger.FIRST_COMPLETED_RUN
@export_multiline var description: String = ""


func content_kind_id() -> StringName:
	match content_kind:
		ContentKind.CREW:
			return &"crew"
		ContentKind.EQUIPMENT:
			return &"equipment"
		ContentKind.CARD:
			return &"card"
	return &""


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not _is_lower_snake_case(id):
		errors.append("unlock rule id must be lowercase snake_case")
	if not _is_lower_snake_case(content_id):
		errors.append("unlock content id must be lowercase snake_case")
	if description.strip_edges().is_empty():
		errors.append("unlock rule '%s' has no authored description" % id)
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
