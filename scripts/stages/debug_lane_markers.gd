class_name DebugLaneMarkers
extends Node2D

## Renders the three non-gameplay depth-lane guides used during development.

const LINE_START_X: float = 132.0
const LINE_END_X: float = 505.0
const BACK_LANE_Y: float = 194.0
const MIDDLE_LANE_Y: float = 226.0
const FRONT_LANE_Y: float = 258.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	_draw_lane(BACK_LANE_Y, Color("55d7ff"))
	_draw_lane(MIDDLE_LANE_Y, Color("bd65ff"))
	_draw_lane(FRONT_LANE_Y, Color("ff5fa2"))


func _draw_lane(y_position: float, color: Color) -> void:
	draw_dashed_line(
		Vector2(LINE_START_X, y_position),
		Vector2(LINE_END_X, y_position),
		Color(color, 0.72),
		1.0,
		6.0,
		false,
		false
	)
	draw_circle(Vector2(LINE_START_X, y_position), 3.0, color, true, -1.0, false)
	draw_circle(Vector2(LINE_END_X, y_position), 3.0, color, true, -1.0, false)
