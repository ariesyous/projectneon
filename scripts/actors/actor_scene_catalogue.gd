@tool
class_name ActorSceneCatalogue
extends Resource

const ActorSceneEntryType = preload("res://scripts/actors/actor_scene_entry.gd")

## Typed, stable-ID actor scene catalogue used by encounter composition.

@export var entries: Array[ActorSceneEntryType] = []


func get_stable_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var seen: Dictionary[StringName, bool] = {}
	for entry: ActorSceneEntryType in entries:
		if entry == null or not entry.is_valid() or seen.has(entry.id):
			continue
		seen[entry.id] = true
		result.append(entry.id)
	result.sort_custom(_string_name_before)
	return result


func get_scene(actor_id: StringName) -> PackedScene:
	var result: PackedScene = null
	for entry: ActorSceneEntryType in entries:
		if entry == null or not entry.is_valid() or entry.id != actor_id:
			continue
		if result != null:
			return null
		result = entry.scene
	return result


func is_valid() -> bool:
	var ids: Array[StringName] = get_stable_ids()
	if ids.size() != entries.size():
		return false
	for actor_id: StringName in ids:
		if get_scene(actor_id) == null:
			return false
	return true


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
