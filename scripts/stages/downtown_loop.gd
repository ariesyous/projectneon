class_name DowntownLoop
extends Node2D

## Owns the fixed Downtown Loop stage composition and replaceable presentation
## nodes. Gameplay authority remains in run-scoped controllers.

@onready var lane_markers: DebugLaneMarkers = $LaneMarkers
@onready var fire_hydrant: FireHydrant = $Interactables/FireHydrant


func set_debug_lanes_visible(lanes_are_visible: bool) -> void:
	lane_markers.visible = lanes_are_visible


func are_debug_lanes_visible() -> bool:
	return lane_markers.visible
