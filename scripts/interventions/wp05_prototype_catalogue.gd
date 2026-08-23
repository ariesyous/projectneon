@tool
class_name WP05PrototypeCatalogue
extends Resource

@export var action_definitions: Array[WP05PrototypeActionDefinition] = []
@export var scenario_definitions: Array[WP05PrototypeScenarioDefinition] = []


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var action_ids: Dictionary[StringName, bool] = {}
	for action: WP05PrototypeActionDefinition in action_definitions:
		if action == null:
			errors.append("WP05 prototype catalogue contains a null action")
			continue
		if action_ids.has(action.id):
			errors.append("WP05 prototype catalogue has duplicate action %s" % action.id)
		action_ids[action.id] = true
		errors.append_array(action.validation_errors())
	var scenario_ids: Dictionary[StringName, bool] = {}
	for scenario: WP05PrototypeScenarioDefinition in scenario_definitions:
		if scenario == null:
			errors.append("WP05 prototype catalogue contains a null scenario")
			continue
		if scenario_ids.has(scenario.id):
			errors.append("WP05 prototype catalogue has duplicate scenario %s" % scenario.id)
		scenario_ids[scenario.id] = true
		errors.append_array(scenario.validation_errors())
		if scenario.environment_action_id != &"fire_hydrant" and not action_ids.has(
			scenario.environment_action_id
		):
			errors.append("WP05 scenario %s references an unknown environment action" % scenario.id)
	return errors


func get_action(action_id: StringName) -> WP05PrototypeActionDefinition:
	for action: WP05PrototypeActionDefinition in action_definitions:
		if action != null and action.id == action_id:
			return action
	return null


func get_scenario(scenario_id: StringName) -> WP05PrototypeScenarioDefinition:
	for scenario: WP05PrototypeScenarioDefinition in scenario_definitions:
		if scenario != null and scenario.id == scenario_id:
			return scenario
	return null


func get_stable_action_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for action: WP05PrototypeActionDefinition in action_definitions:
		if action != null and action.id != &"" and not result.has(action.id):
			result.append(action.id)
	result.sort_custom(_string_name_before)
	return result


func get_stable_scenario_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for scenario: WP05PrototypeScenarioDefinition in scenario_definitions:
		if scenario != null and scenario.id != &"" and not result.has(scenario.id):
			result.append(scenario.id)
	result.sort_custom(_string_name_before)
	return result


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
