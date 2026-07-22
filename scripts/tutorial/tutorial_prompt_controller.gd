@tool
class_name TutorialPromptController
extends Node

## Stable-ID once-per-run prompt coordination. This node is deliberately
## nonmodal: it never pauses the SceneTree or writes gameplay state.

signal prompt_presented(prompt: TutorialPromptDefinition)
signal prompt_dismissed(prompt_id: StringName)

const DEFAULT_CATALOGUE: TutorialPromptCatalogue = preload(
	"res://data/tutorials/milestone_6_tutorial_catalogue.tres"
)

@export var catalogue: TutorialPromptCatalogue = DEFAULT_CATALOGUE

var _shown_ids: Dictionary[StringName, bool] = {}
var _queued_ids: Array[StringName] = []
var _active_prompt: TutorialPromptDefinition = null
var _run_serial: int = 0


func begin_run(run_serial: int = 0) -> void:
	_shown_ids.clear()
	_queued_ids.clear()
	_active_prompt = null
	_run_serial = run_serial


func request_trigger(trigger_id: StringName) -> bool:
	if catalogue == null or trigger_id == &"":
		return false
	var accepted: bool = false
	for prompt: TutorialPromptDefinition in catalogue.get_for_trigger(trigger_id):
		if _shown_ids.has(prompt.id) or prompt.id in _queued_ids:
			continue
		if _active_prompt != null and _active_prompt.id == prompt.id:
			continue
		_queued_ids.append(prompt.id)
		accepted = true
	_present_next_if_available()
	return accepted


func dismiss_current() -> bool:
	if _active_prompt == null:
		return false
	var dismissed_id: StringName = _active_prompt.id
	_active_prompt = null
	prompt_dismissed.emit(dismissed_id)
	_present_next_if_available()
	return true


func clear_for_run_end() -> void:
	_queued_ids.clear()
	_active_prompt = null


func get_active_prompt() -> TutorialPromptDefinition:
	return _active_prompt


func get_shown_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for prompt_id: StringName in _shown_ids.keys():
		result.append(prompt_id)
	result.sort_custom(_string_name_before)
	return result


func get_queued_ids() -> Array[StringName]:
	return _queued_ids.duplicate()


func get_run_serial() -> int:
	return _run_serial


func _present_next_if_available() -> void:
	if _active_prompt != null or _queued_ids.is_empty():
		return
	var prompt_id: StringName = _queued_ids.pop_front()
	var prompt: TutorialPromptDefinition = catalogue.get_by_id(prompt_id)
	if prompt == null or _shown_ids.has(prompt_id):
		_present_next_if_available()
		return
	_active_prompt = prompt
	_shown_ids[prompt_id] = true
	prompt_presented.emit(prompt)


static func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
