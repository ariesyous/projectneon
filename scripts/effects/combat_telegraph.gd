class_name CombatTelegraph
extends Node2D

## Presentation-only authored threat grammar. Gameplay range and timing remain
## owned by AttackDefinition and CombatDirector; this node receives a snapshot
## and distinguishes melee, projectile, charge, area, and summon intent by
## shape, motion, and one label rather than color alone.

enum TelegraphKind {
	MELEE,
	PROJECTILE,
	CHARGE,
	AREA,
	SUMMON,
}

const AMBER: Color = Color("ffc45c")
const CRITICAL: Color = Color("ff415f")
const MAGENTA: Color = Color("ff5c82")
const CYAN: Color = Color("43e6e8")
const ACID: Color = Color("b8f35d")
const INK: Color = Color("f3f6ff")
const VOID: Color = Color("050712")

var _radius: float = 0.0
var _remaining_seconds: float = 0.0
var _total_seconds: float = 0.0
var _label: Label
var _suspended: bool = false
var _kind: TelegraphKind = TelegraphKind.MELEE
var _target_offset: Vector2 = Vector2(64.0, 0.0)
var _charge_distance: float = 0.0
var _intent_label: String = "THREAT"


func present(
	world_position: Vector2,
	radius: float,
	duration_seconds: float,
	attack_name: String,
	delivery_kind: int = AttackDefinition.DeliveryKind.MELEE,
	target_world_position: Vector2 = Vector2.INF,
	charge_distance: float = 0.0
) -> void:
	global_position = world_position
	_radius = maxf(radius, 8.0)
	_remaining_seconds = maxf(duration_seconds, 0.05)
	_total_seconds = _remaining_seconds
	_kind = _kind_from_delivery(delivery_kind)
	_charge_distance = maxf(charge_distance, 0.0)
	_intent_label = attack_name.to_upper()
	if target_world_position.is_finite():
		_target_offset = target_world_position - world_position
	if _target_offset.length_squared() < 1.0:
		_target_offset = Vector2(maxf(_charge_distance, 64.0), 0.0)
	_create_label()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if _suspended:
		return
	_remaining_seconds = maxf(_remaining_seconds - maxf(delta, 0.0), 0.0)
	_update_label_position()
	queue_redraw()
	if _remaining_seconds <= 0.0:
		queue_free()


func set_suspended(suspended: bool) -> void:
	_suspended = suspended


func get_remaining_seconds() -> float:
	return _remaining_seconds


func get_kind() -> TelegraphKind:
	return _kind


func get_presentation_snapshot() -> Dictionary:
	return {
		"kind": _kind,
		"intent_label": _intent_label,
		"remaining_seconds": _remaining_seconds,
		"total_seconds": _total_seconds,
		"radius": _radius,
		"target_offset": _target_offset,
		"charge_distance": _charge_distance,
	}


func _draw() -> void:
	if _remaining_seconds <= 0.0:
		return
	var progress: float = (
		1.0 - clampf(_remaining_seconds / _total_seconds, 0.0, 1.0)
		if _total_seconds > 0.0
		else 1.0
	)
	match _kind:
		TelegraphKind.CHARGE:
			_draw_charge(progress)
		TelegraphKind.AREA:
			_draw_area(progress)
		TelegraphKind.PROJECTILE:
			_draw_projectile(progress)
		TelegraphKind.SUMMON:
			_draw_summon(progress)
		_:
			_draw_melee(progress)


func _draw_charge(progress: float) -> void:
	var direction: Vector2 = _target_offset.normalized()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var length: float = maxf(maxf(_charge_distance, _target_offset.length()), 72.0)
	var half_width: float = maxf(minf(_radius * 0.42, 26.0), 16.0)
	var start: Vector2 = direction * 14.0
	var finish: Vector2 = direction * length
	var corridor := PackedVector2Array([
		start - normal * half_width,
		finish - normal * half_width,
		finish + normal * half_width,
		start + normal * half_width,
	])
	draw_colored_polygon(corridor, Color(AMBER, 0.10))
	draw_line(start - normal * half_width, finish - normal * half_width, AMBER, 2.0)
	draw_line(start + normal * half_width, finish + normal * half_width, AMBER, 2.0)
	draw_line(finish - normal * half_width, finish + normal * half_width, INK, 2.0)
	for chevron: int in range(6):
		var travel: float = fposmod(float(chevron) / 6.0 + progress * 0.45, 1.0)
		var centre: Vector2 = start.lerp(finish, travel)
		var back: Vector2 = centre - direction * 8.0
		draw_polyline(PackedVector2Array([
			back - normal * 7.0,
			centre,
			back + normal * 7.0,
		]), AMBER, 2.5, false)


func _draw_area(progress: float) -> void:
	draw_circle(Vector2.ZERO, _radius, Color(CRITICAL, 0.08), true)
	for segment: int in range(16):
		if segment % 2 != 0:
			continue
		var start_angle: float = TAU * float(segment) / 16.0
		var end_angle: float = TAU * float(segment + 1) / 16.0
		draw_arc(Vector2.ZERO, _radius, start_angle, end_angle, 5, MAGENTA, 4.0)
	var inner_radius: float = lerpf(_radius * 0.72, _radius * 0.18, progress)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 40, INK, 2.0)
	draw_line(Vector2(-inner_radius, 0.0), Vector2(inner_radius, 0.0), Color(INK, 0.52), 1.0)
	draw_line(Vector2(0.0, -inner_radius), Vector2(0.0, inner_radius), Color(INK, 0.52), 1.0)


func _draw_projectile(progress: float) -> void:
	var endpoint: Vector2 = _target_offset
	var direction: Vector2 = endpoint.normalized()
	draw_arc(Vector2.ZERO, maxf(_radius, 20.0), -PI * 0.35, PI * 0.35, 12, AMBER, 2.0)
	for segment: int in range(9):
		var start_t: float = float(segment) / 9.0
		var end_t: float = minf(start_t + 0.055, 1.0)
		draw_line(endpoint * start_t, endpoint * end_t, Color(AMBER, 0.56 + 0.36 * progress), 1.5)
	_draw_corner_brackets(endpoint, Vector2(13.0, 13.0), CYAN)
	draw_colored_polygon(PackedVector2Array([
		direction * 11.0,
		direction * 3.0 + direction.orthogonal() * 4.0,
		direction * 3.0 - direction.orthogonal() * 4.0,
	]), AMBER)


func _draw_summon(progress: float) -> void:
	var pulse: float = 0.58 + 0.28 * sin(progress * TAU * 3.0)
	for side: float in [-1.0, 1.0]:
		var centre: Vector2 = Vector2(side * 48.0, 2.0)
		var color: Color = Color(ACID, pulse)
		draw_line(centre + Vector2(-14.0, 22.0), centre + Vector2(-14.0, -22.0), color, 3.0)
		draw_line(centre + Vector2(-14.0, -22.0), centre + Vector2(14.0, -22.0), color, 3.0)
		draw_line(centre + Vector2(14.0, -22.0), centre + Vector2(14.0, 22.0), color, 3.0)
		draw_line(centre + Vector2(-9.0, 14.0), centre + Vector2(9.0, 14.0), INK, 1.0)
	draw_arc(Vector2.ZERO, _radius * 0.54, 0.0, TAU, 28, Color(ACID, 0.45), 2.0)


func _draw_melee(progress: float) -> void:
	var facing: float = 1.0 if _target_offset.x >= 0.0 else -1.0
	var centre_angle: float = 0.0 if facing > 0.0 else PI
	var arc_radius: float = maxf(_radius, 28.0)
	draw_arc(Vector2.ZERO, arc_radius, centre_angle - 0.65, centre_angle + 0.65, 16, AMBER, 3.0)
	var fill_length: float = lerpf(10.0, arc_radius, progress)
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(centre_angle) * fill_length, INK, 2.0)


func _draw_corner_brackets(centre: Vector2, half_size: Vector2, color: Color) -> void:
	var left: float = centre.x - half_size.x
	var right: float = centre.x + half_size.x
	var top: float = centre.y - half_size.y
	var bottom: float = centre.y + half_size.y
	for segment: PackedVector2Array in [
		PackedVector2Array([Vector2(left, top + 6.0), Vector2(left, top), Vector2(left + 6.0, top)]),
		PackedVector2Array([Vector2(right - 6.0, top), Vector2(right, top), Vector2(right, top + 6.0)]),
		PackedVector2Array([Vector2(left, bottom - 6.0), Vector2(left, bottom), Vector2(left + 6.0, bottom)]),
		PackedVector2Array([Vector2(right - 6.0, bottom), Vector2(right, bottom), Vector2(right, bottom - 6.0)]),
	]:
		draw_polyline(segment, color, 2.0, false)


func _create_label() -> void:
	_label = Label.new()
	_label.text = _intent_label
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", 8)
	_label.add_theme_color_override(&"font_color", _kind_color())
	_label.add_theme_color_override(&"font_outline_color", VOID)
	_label.add_theme_constant_override(&"outline_size", 3)
	_label.size = Vector2(160.0, 16.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_update_label_position()


func _update_label_position() -> void:
	if _label == null:
		return
	match _kind:
		TelegraphKind.CHARGE:
			_label.position = _target_offset * 0.5 + Vector2(-80.0, 24.0)
		TelegraphKind.PROJECTILE:
			_label.position = _target_offset + Vector2(-80.0, -26.0)
		_:
			_label.position = Vector2(-80.0, -_radius - 20.0)


func _kind_from_delivery(delivery_kind: int) -> TelegraphKind:
	match delivery_kind:
		AttackDefinition.DeliveryKind.PROJECTILE:
			return TelegraphKind.PROJECTILE
		AttackDefinition.DeliveryKind.CHARGE:
			return TelegraphKind.CHARGE
		AttackDefinition.DeliveryKind.AREA:
			return TelegraphKind.AREA
		AttackDefinition.DeliveryKind.SUMMON:
			return TelegraphKind.SUMMON
	return TelegraphKind.MELEE


func _kind_color() -> Color:
	match _kind:
		TelegraphKind.AREA:
			return MAGENTA
		TelegraphKind.SUMMON:
			return ACID
		TelegraphKind.PROJECTILE:
			return CYAN
	return AMBER
