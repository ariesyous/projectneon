class_name CombatHitSpark
extends Node2D

## Short-lived, code-drawn placeholder impact. CombatFeedback owns spawning and
## caps the number of live presentation transients.

var _primary_color: Color = Color(1.0, 0.86, 0.28, 1.0)
var _secondary_color: Color = Color(1.0, 1.0, 0.82, 1.0)
var _radius: float = 10.0
var _lifetime: float = 0.14
var _heavy: bool = false
var _style_id: StringName = &"light"
var _direction: Vector2 = Vector2.RIGHT


func configure(
	primary_color: Color,
	secondary_color: Color,
	radius: float,
	lifetime: float,
	heavy: bool = false,
	style_id: StringName = &"",
	direction: Vector2 = Vector2.RIGHT
) -> void:
	_primary_color = primary_color
	_secondary_color = secondary_color
	_radius = maxf(radius, 2.0)
	_lifetime = maxf(lifetime, 0.05)
	_heavy = heavy
	_style_id = style_id if style_id != &"" else (&"heavy" if heavy else &"light")
	_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT


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
	match _style_id:
		&"heavy":
			_draw_heavy_contact()
			return
		&"boss":
			_draw_boss_contact()
			return
		&"electric":
			_draw_electric_contact()
			return
		&"water":
			_draw_water_contact()
			return
		&"status_shock":
			_draw_status_shock()
			return
		&"status_bleed":
			_draw_status_bleed()
			return
		&"elite_death", &"boss_death", &"death":
			_draw_defeat_burst()
			return
		&"spawn":
			_draw_spawn_gate()
			return
	_draw_light_contact()


func _draw_light_contact() -> void:
	var centre_radius: float = _radius * (0.30 if _heavy else 0.24)
	draw_circle(Vector2.ZERO, centre_radius, _secondary_color)

	for ray_index: int in range(6):
		var angle: float = TAU * float(ray_index) / 6.0
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var inner_point: Vector2 = direction * (_radius * 0.34)
		var length_scale: float = 1.0 if ray_index % 2 == 0 else 0.62
		var outer_point: Vector2 = direction * (_radius * length_scale)
		var width: float = 2.6 if _heavy and ray_index % 2 == 0 else 1.6
		draw_line(inner_point, outer_point, _primary_color, width, false)

	var shard: PackedVector2Array = PackedVector2Array([
		Vector2(-_radius * 0.72, -_radius * 0.18),
		Vector2(-_radius * 0.28, -_radius * 0.06),
		Vector2(-_radius * 0.60, _radius * 0.22),
	])
	draw_colored_polygon(shard, _secondary_color)


func _draw_heavy_contact() -> void:
	var normal: Vector2 = _direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		-_direction * _radius * 0.55 - normal * 2.0,
		_direction * _radius + normal * 4.0,
		_direction * _radius * 0.45 - normal * 4.0,
	]), _primary_color)
	draw_circle(Vector2.ZERO, _radius * 0.28, _secondary_color)
	for shard_index: int in range(5):
		var angle: float = -0.9 + float(shard_index) * 0.45
		var direction: Vector2 = _direction.rotated(angle)
		draw_line(direction * 4.0, direction * _radius * (0.68 + float(shard_index % 2) * 0.28), _primary_color, 2.4)


func _draw_boss_contact() -> void:
	draw_circle(Vector2.ZERO, _radius * 0.34, _secondary_color)
	for segment: int in range(12):
		if segment % 2 == 0:
			var start_angle: float = TAU * float(segment) / 12.0
			var end_angle: float = TAU * float(segment + 1) / 12.0
			draw_arc(Vector2.ZERO, _radius, start_angle, end_angle, 4, _primary_color, 3.0)
	draw_line(-_direction * _radius * 0.6, _direction * _radius, _secondary_color, 3.0)


func _draw_electric_contact() -> void:
	draw_circle(Vector2.ZERO, _radius * 0.22, _secondary_color)
	for bolt_index: int in range(4):
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(bolt_index) / 4.0)
		var normal: Vector2 = direction.orthogonal()
		draw_polyline(PackedVector2Array([
			direction * 3.0,
			direction * (_radius * 0.40) + normal * 3.0,
			direction * (_radius * 0.67) - normal * 3.0,
			direction * _radius,
		]), _primary_color, 2.0, false)


func _draw_water_contact() -> void:
	draw_circle(Vector2.ZERO, _radius * 0.28, _secondary_color)
	for drop_index: int in range(7):
		var angle: float = PI + (-0.75 + float(drop_index) * 0.25)
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		draw_line(direction * 4.0, direction * _radius, _primary_color, 2.2)
		draw_circle(direction * (_radius + 2.0), 2.0, _secondary_color)


func _draw_status_shock() -> void:
	draw_polyline(PackedVector2Array([
		Vector2(-4.0, -_radius), Vector2(4.0, -3.0),
		Vector2(-1.0, 1.0), Vector2(6.0, _radius),
	]), _primary_color, 3.0, false)
	draw_arc(Vector2.ZERO, _radius * 0.72, -PI, PI, 18, Color(_secondary_color, 0.72), 2.0)


func _draw_status_bleed() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -_radius), Vector2(-_radius * 0.55, 2.0),
		Vector2(0.0, _radius), Vector2(_radius * 0.55, 2.0),
	]), _primary_color)
	draw_circle(Vector2.ZERO, _radius * 0.24, _secondary_color)


func _draw_defeat_burst() -> void:
	var scale_multiplier: float = 1.35 if _style_id == &"boss_death" else (1.15 if _style_id == &"elite_death" else 1.0)
	draw_arc(Vector2.ZERO, _radius * scale_multiplier, 0.0, TAU, 28, _primary_color, 3.0)
	for shard_index: int in range(8):
		var angle: float = TAU * float(shard_index) / 8.0
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var inner: Vector2 = direction * _radius * 0.28
		var outer: Vector2 = direction * _radius * scale_multiplier
		draw_line(inner, outer, _secondary_color if shard_index % 2 == 0 else _primary_color, 2.5)


func _draw_spawn_gate() -> void:
	var half_width: float = _radius * 0.62
	var half_height: float = _radius
	draw_line(Vector2(-half_width, half_height), Vector2(-half_width, -half_height), _primary_color, 2.0)
	draw_line(Vector2(-half_width, -half_height), Vector2(half_width, -half_height), _primary_color, 2.0)
	draw_line(Vector2(half_width, -half_height), Vector2(half_width, half_height), _primary_color, 2.0)
	draw_line(Vector2(-half_width * 0.72, half_height * 0.66), Vector2(half_width * 0.72, half_height * 0.66), _secondary_color, 2.0)
