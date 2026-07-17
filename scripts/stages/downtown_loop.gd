class_name DowntownLoop
extends Node2D

## Owns the fixed Downtown Loop stage composition. Milestone 0 exposes only
## presentation-level debug lane visibility.

@onready var lane_markers: DebugLaneMarkers = $LaneMarkers


func set_debug_lanes_visible(lanes_are_visible: bool) -> void:
	lane_markers.visible = lanes_are_visible


func are_debug_lanes_visible() -> bool:
	return lane_markers.visible
