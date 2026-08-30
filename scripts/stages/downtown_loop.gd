class_name DowntownLoop
extends Node2D

## Owns the fixed Downtown Loop stage composition and replaceable presentation
## nodes. Gameplay authority remains in run-scoped controllers.

@onready var lane_markers: DebugLaneMarkers = $LaneMarkers
@onready var route_markers: RouteMarkers = $RouteNodes
@onready var backdrop: DowntownBackdrop = $Background
@onready var fire_hydrant: FireHydrant = $Interactables/FireHydrant


func _ready() -> void:
	# Debug geometry remains available through F2 in development, but never
	# appears by default or in a release build.
	_set_debug_visuals_visible(false)


func set_debug_lanes_visible(lanes_are_visible: bool) -> void:
	_set_debug_visuals_visible(lanes_are_visible and OS.is_debug_build())


func are_debug_lanes_visible() -> bool:
	return lane_markers.visible and route_markers.visible


func present_route_snapshot(snapshot: Dictionary) -> void:
	route_markers.present_route_snapshot(snapshot)


func present_world_snapshot(snapshot: Dictionary) -> void:
	backdrop.present_world_snapshot(snapshot)


func reset_world_presentation() -> void:
	backdrop.reset_presentation()


func get_world_presentation_snapshot() -> Dictionary:
	return backdrop.get_presentation_snapshot()


func _set_debug_visuals_visible(is_visible: bool) -> void:
	lane_markers.visible = is_visible
	route_markers.visible = is_visible
