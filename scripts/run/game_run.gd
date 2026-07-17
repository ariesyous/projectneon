class_name GameRun
extends Node

## Composition root for a single district run. Milestone 0 only wires debug UI
## requests to stage presentation and owns no gameplay state.

@onready var downtown_loop: DowntownLoop = $DowntownLoop
@onready var debug_overlay: DebugOverlay = $DebugOverlay


func _ready() -> void:
	debug_overlay.lane_visibility_requested.connect(_on_lane_visibility_requested)
	debug_overlay.set_lane_visibility(downtown_loop.are_debug_lanes_visible())


func _on_lane_visibility_requested(lanes_are_visible: bool) -> void:
	downtown_loop.set_debug_lanes_visible(lanes_are_visible)
