@tool
class_name WP05PrototypeScenarioDefinition
extends Resource

## One bounded, deterministic WP05 comparison scenario built from existing
## actor and attack IDs. It is never an encounter candidate in production.

@export var id: StringName = &"wp05_proto_scenario"
@export var display_name: String = "Prototype Scenario"
@export var context_id: StringName = &"early"
@export var encounter_definition: EncounterDefinition
@export var boss_context: bool = false
@export var environment_action_id: StringName = &"fire_hydrant"
@export var expected_enemy_ids: Array[StringName] = []
@export var primary_threat_attack_id: StringName = &""
@export_range(0, 2, 1) var lap_index: int = 0
@export var fixed_seed: int = 50501
@export_multiline var tactical_question: String = ""


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"" or not String(id).begins_with("wp05_proto_"):
		errors.append("WP05 prototype scenario id must use the wp05_proto_ prefix")
	if display_name.strip_edges().is_empty() or tactical_question.strip_edges().is_empty():
		errors.append("WP05 prototype scenario requires display copy and a tactical question")
	if context_id not in [&"early", &"middle", &"elite", &"boss"]:
		errors.append("WP05 prototype scenario context must be early, middle, elite, or boss")
	if encounter_definition == null:
		errors.append("WP05 prototype scenario requires an encounter definition")
	elif encounter_definition.boss != boss_context:
		errors.append("WP05 prototype scenario boss flag must match its encounter")
	if environment_action_id == &"" or expected_enemy_ids.is_empty():
		errors.append("WP05 prototype scenario requires environment and enemy identities")
	var stable_ids: Array[StringName] = expected_enemy_ids.duplicate()
	stable_ids.sort_custom(_string_name_before)
	if stable_ids != expected_enemy_ids:
		errors.append("WP05 prototype scenario enemy IDs must be in stable order")
	return errors


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
