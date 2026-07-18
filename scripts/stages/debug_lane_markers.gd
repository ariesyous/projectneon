class_name DebugLaneMarkers
extends Node2D

## Renders the three non-gameplay depth-lane guides used during development.

const DEFAULT_COMBAT_SPACE: CombatSpaceDefinition = preload(
	"res://data/combat/downtown_loop_combat_space.tres"
)

@export var combat_space: CombatSpaceDefinition = DEFAULT_COMBAT_SPACE


func _ready() -> void:
	if combat_space == null:
		combat_space = DEFAULT_COMBAT_SPACE
	queue_redraw()


func configure(definition: CombatSpaceDefinition) -> void:
	combat_space = definition if definition != null else DEFAULT_COMBAT_SPACE
	queue_redraw()


func _draw() -> void:
	draw_rect(combat_space.actor_origin_bounds, Color(0.45, 0.88, 1.0, 0.18), false, 1.0)
	var lane_colors: Array[Color] = [Color("55d7ff"), Color("bd65ff"), Color("ff5fa2")]
	for lane_index: int in range(combat_space.lane_count()):
		_draw_lane(
			combat_space.lane_y(lane_index),
			lane_colors[lane_index % lane_colors.size()]
		)


func _draw_lane(y_position: float, color: Color) -> void:
	draw_dashed_line(
		Vector2(combat_space.minimum_x(), y_position),
		Vector2(combat_space.maximum_x(), y_position),
		Color(color, 0.72),
		1.0,
		6.0,
		false,
		false
	)
	draw_circle(Vector2(combat_space.minimum_x(), y_position), 3.0, color, true, -1.0, false)
	draw_circle(Vector2(combat_space.maximum_x(), y_position), 3.0, color, true, -1.0, false)
