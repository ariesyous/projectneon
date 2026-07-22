@tool
class_name TutorialPromptCatalogue
extends Resource

const REQUIRED_PROMPT_IDS: Array[StringName] = [
	&"tutorial_boss",
	&"tutorial_coin_cluster",
	&"tutorial_district_cards",
	&"tutorial_equipment",
	&"tutorial_extraction",
	&"tutorial_interventions",
	&"tutorial_run_controls",
]

@export var prompts: Array[TutorialPromptDefinition] = []


func get_sorted_prompts() -> Array[TutorialPromptDefinition]:
	var result: Array[TutorialPromptDefinition] = []
	for prompt: TutorialPromptDefinition in prompts:
		if prompt != null:
			result.append(prompt)
	result.sort_custom(_prompt_before)
	return result


func get_for_trigger(trigger_id: StringName) -> Array[TutorialPromptDefinition]:
	var result: Array[TutorialPromptDefinition] = []
	for prompt: TutorialPromptDefinition in prompts:
		if prompt != null and prompt.trigger_id == trigger_id:
			result.append(prompt)
	result.sort_custom(_priority_before)
	return result


func get_by_id(prompt_id: StringName) -> TutorialPromptDefinition:
	for prompt: TutorialPromptDefinition in prompts:
		if prompt != null and prompt.id == prompt_id:
			return prompt
	return null


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if prompts.size() != REQUIRED_PROMPT_IDS.size():
		errors.append(
			"tutorial catalogue must contain exactly %d prompts, found %d"
			% [REQUIRED_PROMPT_IDS.size(), prompts.size()]
		)
	var seen: Dictionary[StringName, bool] = {}
	var seen_triggers: Dictionary[StringName, bool] = {}
	for prompt: TutorialPromptDefinition in prompts:
		if prompt == null:
			errors.append("tutorial catalogue contains a null prompt")
			continue
		errors.append_array(prompt.validation_errors())
		if prompt.id in seen:
			errors.append("tutorial catalogue repeats prompt '%s'" % prompt.id)
		seen[prompt.id] = true
		if prompt.trigger_id in seen_triggers:
			errors.append("tutorial catalogue repeats trigger '%s'" % prompt.trigger_id)
		seen_triggers[prompt.trigger_id] = true
		if prompt.id not in REQUIRED_PROMPT_IDS:
			errors.append("tutorial catalogue contains unexpected prompt '%s'" % prompt.id)
	for required_id: StringName in REQUIRED_PROMPT_IDS:
		if not seen.has(required_id):
			errors.append("tutorial catalogue is missing prompt '%s'" % required_id)
	return errors


static func _prompt_before(
	left: TutorialPromptDefinition,
	right: TutorialPromptDefinition
) -> bool:
	return String(left.id) < String(right.id)


static func _priority_before(
	left: TutorialPromptDefinition,
	right: TutorialPromptDefinition
) -> bool:
	if left.priority != right.priority:
		return left.priority > right.priority
	return String(left.id) < String(right.id)
