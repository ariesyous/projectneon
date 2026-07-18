class_name CombatHitSpark
extends Node2D

## Short-lived, code-drawn placeholder impact. CombatFeedback owns spawning and
## caps the number of live presentation transients.

var _primary_color: Color = Color(1.0, 0.86, 0.28, 1.0)
var _secondary_color: Color = Color(1.0, 1.0, 0.82, 1.0)
var _radius: float = 10.0
var _lifetime: float = 0.14
var _heavy: bool = false


func configure(
	primary_color: Color,
	secondary_color: Color,
	radius: float,
	lifetime: float,
	heavy: bool = false
) -> void:
	_primary_color = primary_color
	_secondary_color = secondary_color
	_radius = maxf(radius, 2.0)
	_lifetime = maxf(lifetime, 0.05)
	_heavy = heavy


func _ready() -> void:
	z_index = 40
	scale = Vector2(0.68, 0.68)
	queue_redraw()

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.45, 1.45), _lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, _lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var centre_radius: float = _radius * (0.30 if _heavy else 0.24)
	draw_circle(Vector2.ZERO, centre_radius, _secondary_color)

	for ray_index: int in range(8):
		var angle: float = TAU * float(ray_index) / 8.0
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var inner_point: Vector2 = direction * (_radius * 0.34)
		var length_scale: float = 1.0 if ray_index % 2 == 0 else 0.68
		var outer_point: Vector2 = direction * (_radius * length_scale)
		var width: float = 2.6 if _heavy and ray_index % 2 == 0 else 1.6
		draw_line(inner_point, outer_point, _primary_color, width, false)

	var shard: PackedVector2Array = PackedVector2Array([
		Vector2(-_radius * 0.72, -_radius * 0.18),
		Vector2(-_radius * 0.28, -_radius * 0.06),
		Vector2(-_radius * 0.60, _radius * 0.22),
	])
	draw_colored_polygon(shard, _secondary_color)
