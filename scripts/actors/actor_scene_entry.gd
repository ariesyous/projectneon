@tool
class_name ActorSceneEntry
extends Resource

## Stable content-ID to replaceable actor-scene mapping.

@export var id: StringName = &"actor"
@export var scene: PackedScene


func is_valid() -> bool:
	return id != &"" and scene != null
