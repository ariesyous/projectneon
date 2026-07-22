class_name CombatTelegraph
extends Node2D

## Presentation-only world warning for authored boss area attacks. Gameplay
## range and timing remain owned by AttackDefinition and CombatDirector.

var _radius: float = 0.0
var _remaining_seconds: float = 0.0
var _total_seconds: float = 0.0
var _label: Label
var _suspended: bool = false


func present(
	world_position: Vector2,
	radius: float,
	duration_seconds: float,
	attack_name: String
) -> void:
	global_position = world_position
	_radius = maxf(radius, 8.0)
	_remaining_seconds = maxf(duration_seconds, 0.05)
	_total_seconds = _remaining_seconds
	_label = Label.new()
	_label.text = "WARNING: %s" % attack_name.to_upper()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 8)
	_label.position = Vector2(-72.0, -_radius - 18.0)
	_label.size = Vector2(144.0, 16.0)
	add_child(_label)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if _suspended:
		return
	_remaining_seconds = maxf(_remaining_seconds - maxf(delta, 0.0), 0.0)
	queue_redraw()
	if _remaining_seconds <= 0.0:
		queue_free()


func set_suspended(suspended: bool) -> void:
	_suspended = suspended


func get_remaining_seconds() -> float:
	return _remaining_seconds


func _draw() -> void:
	if _remaining_seconds <= 0.0:
		return
	var progress: float = (
		1.0 - clampf(_remaining_seconds / _total_seconds, 0.0, 1.0)
		if _total_seconds > 0.0
		else 1.0
	)
	var pulse: float = 0.65 + 0.25 * sin(progress * TAU * 4.0)
	var warning_color: Color = Color(1.0, 0.82, 0.18, pulse)
	draw_circle(Vector2.ZERO, _radius, Color(0.35, 0.03, 0.09, 0.20), true)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, warning_color, 3.0)
	draw_line(Vector2(-_radius, 0.0), Vector2(_radius, 0.0), warning_color, 2.0)
	draw_line(Vector2(0.0, -_radius), Vector2(0.0, _radius), warning_color, 2.0)
