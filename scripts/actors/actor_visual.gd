class_name ActorVisual
extends Node2D

## Replaceable code-drawn placeholder presentation. It observes actor state but
## owns no gameplay decisions, health, targeting, or attack timing.

enum VariantKind {
	JAX,
	STREET_PUNK,
}

@export var variant_kind: int = VariantKind.JAX

var _state: int = ActorStateMachine.State.IDLE
var _facing: float = 1.0
var _current_health: int = 1
var _maximum_health: int = 1
var _is_targeted: bool = false
var _has_target: bool = false
var _flash_remaining: float = 0.0
var _animation_clock: float = 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_animation_clock += maxf(delta, 0.0)
	_flash_remaining = maxf(_flash_remaining - maxf(delta, 0.0), 0.0)
	queue_redraw()


func set_state(state: int) -> void:
	_state = state
	queue_redraw()


func set_facing(facing: float) -> void:
	_facing = -1.0 if facing < 0.0 else 1.0
	queue_redraw()


func set_health(current_health: int, maximum_health: int) -> void:
	_current_health = maxi(current_health, 0)
	_maximum_health = maxi(maximum_health, 1)
	queue_redraw()


func set_targeted(is_targeted: bool) -> void:
	_is_targeted = is_targeted
	queue_redraw()


func set_has_target(has_target: bool) -> void:
	_has_target = has_target
	queue_redraw()


func play_hit_flash(duration: float = 0.09) -> void:
	_flash_remaining = maxf(_flash_remaining, maxf(duration, 0.0))
	queue_redraw()


func _draw() -> void:
	_draw_shadow()
	if _state == ActorStateMachine.State.DEAD:
		_draw_body(Vector2(0.0, -3.0), -1.35 * _facing)
	else:
		var bob: float = 0.0
		if _state == ActorStateMachine.State.IDLE:
			bob = round(sin(_animation_clock * 5.0))
		_draw_body(Vector2(0.0, bob), _body_rotation())
	_draw_indicators()


func _draw_shadow() -> void:
	var shadow_points := PackedVector2Array([
		Vector2(-15.0, -1.0),
		Vector2(-10.0, -4.0),
		Vector2(10.0, -4.0),
		Vector2(15.0, -1.0),
		Vector2(10.0, 2.0),
		Vector2(-10.0, 2.0),
	])
	draw_colored_polygon(shadow_points, Color(0.01, 0.02, 0.08, 0.72))


func _draw_body(draw_offset: Vector2, body_rotation: float) -> void:
	draw_set_transform(draw_offset, body_rotation, Vector2.ONE)
	var main_color: Color = Color("19d9e7") if variant_kind == VariantKind.JAX else Color("ef3f8f")
	var dark_color: Color = Color("07526d") if variant_kind == VariantKind.JAX else Color("66214f")
	var accent_color: Color = Color("d5fbff") if variant_kind == VariantKind.JAX else Color("ff9a3d")
	var skin_color: Color = Color("f1a36f") if variant_kind == VariantKind.JAX else Color("d48756")
	if _flash_remaining > 0.0:
		main_color = Color.WHITE
		dark_color = Color("b9f9ff")
		accent_color = Color.WHITE
		skin_color = Color.WHITE

	var stride: float = 0.0
	if _state == ActorStateMachine.State.APPROACHING_TARGET or _state == ActorStateMachine.State.PATROLLING:
		stride = round(sin(_animation_clock * 12.0) * 4.0)
	var lean: float = 0.0
	if _state == ActorStateMachine.State.ATTACK_WINDUP:
		lean = -2.0 * _facing
	elif _state == ActorStateMachine.State.ATTACK_ACTIVE:
		lean = 5.0 * _facing
	elif _state == ActorStateMachine.State.KNOCKED_BACK:
		lean = -4.0 * _facing

	# Legs and bright shoes provide a readable walking cadence.
	draw_line(Vector2(-4.0 + lean, -17.0), Vector2(-6.0 + stride, -2.0), dark_color, 6.0)
	draw_line(Vector2(4.0 + lean, -17.0), Vector2(6.0 - stride, -2.0), dark_color, 6.0)
	draw_line(Vector2(-9.0 + stride, -1.0), Vector2(-2.0 + stride, -1.0), accent_color, 3.0)
	draw_line(Vector2(2.0 - stride, -1.0), Vector2(9.0 - stride, -1.0), accent_color, 3.0)

	var torso := PackedVector2Array([
		Vector2(-10.0 + lean, -37.0),
		Vector2(9.0 + lean, -37.0),
		Vector2(11.0 + lean, -17.0),
		Vector2(-9.0 + lean, -17.0),
	])
	draw_colored_polygon(torso, main_color)
	draw_line(Vector2(-8.0 + lean, -20.0), Vector2(9.0 + lean, -20.0), accent_color, 2.0)

	var shoulder: Vector2 = Vector2(7.0 * _facing + lean, -33.0)
	var fist: Vector2 = Vector2(14.0 * _facing + lean, -22.0)
	match _state:
		ActorStateMachine.State.ATTACK_WINDUP:
			fist = Vector2(-17.0 * _facing + lean, -27.0)
		ActorStateMachine.State.ATTACK_ACTIVE:
			fist = Vector2(29.0 * _facing + lean, -30.0)
		ActorStateMachine.State.ATTACK_RECOVERY:
			fist = Vector2(16.0 * _facing + lean, -17.0)
		ActorStateMachine.State.KNOCKED_BACK, ActorStateMachine.State.STUNNED:
			fist = Vector2(-13.0 * _facing + lean, -38.0)
	draw_line(shoulder, fist, skin_color, 6.0)
	draw_circle(fist, 4.0 if _state == ActorStateMachine.State.ATTACK_ACTIVE else 3.0, accent_color)
	draw_line(Vector2(-7.0 * _facing + lean, -32.0), Vector2(-14.0 * _facing + lean, -20.0), skin_color, 5.0)

	# Head, hair, and palette-specific details keep the two silhouettes distinct.
	draw_rect(Rect2(Vector2(-6.0 + lean, -49.0), Vector2(12.0, 12.0)), skin_color, true)
	if variant_kind == VariantKind.JAX:
		var hair := PackedVector2Array([
			Vector2(-8.0 + lean, -48.0), Vector2(-5.0 + lean, -57.0),
			Vector2(-1.0 + lean, -52.0), Vector2(3.0 + lean, -59.0),
			Vector2(5.0 + lean, -52.0), Vector2(9.0 + lean, -55.0),
			Vector2(7.0 + lean, -45.0), Vector2(-7.0 + lean, -44.0),
		])
		draw_colored_polygon(hair, main_color)
		draw_line(Vector2(-8.0 + lean, -41.0), Vector2(9.0 + lean, -41.0), dark_color, 3.0)
	else:
		draw_rect(Rect2(Vector2(-8.0 + lean, -54.0), Vector2(16.0, 6.0)), accent_color, true)
		draw_line(Vector2(-10.0 + lean, -51.0), Vector2(10.0 + lean, -51.0), dark_color, 3.0)
		draw_rect(Rect2(Vector2(-3.0 + lean, -31.0), Vector2(6.0, 7.0)), accent_color, true)
	draw_rect(Rect2(Vector2(2.0 * _facing + lean, -45.0), Vector2(3.0 * _facing, 2.0)), dark_color, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_indicators() -> void:
	if _state != ActorStateMachine.State.DEAD:
		draw_rect(Rect2(-19.0, -67.0, 38.0, 5.0), Color(0.01, 0.02, 0.07, 0.95), true)
		var health_width: float = 36.0 * clampf(float(_current_health) / float(_maximum_health), 0.0, 1.0)
		var health_color: Color = Color("48ef7b") if variant_kind == VariantKind.JAX else Color("ff5b77")
		draw_rect(Rect2(-18.0, -66.0, health_width, 3.0), health_color, true)
	if _is_targeted:
		var marker := PackedVector2Array([
			Vector2(0.0, -76.0), Vector2(5.0, -71.0), Vector2(0.0, -68.0), Vector2(-5.0, -71.0),
		])
		draw_colored_polygon(marker, Color("ffd34e"))
	if _has_target and _state != ActorStateMachine.State.DEAD:
		var direction_marker := PackedVector2Array([
			Vector2(12.0 * _facing, -55.0),
			Vector2(17.0 * _facing, -52.0),
			Vector2(12.0 * _facing, -49.0),
		])
		draw_colored_polygon(direction_marker, Color("f8f1a6"))


func _body_rotation() -> float:
	if _state == ActorStateMachine.State.KNOCKED_BACK:
		return -0.22 * _facing
	if _state == ActorStateMachine.State.INCAPACITATED:
		return -0.75 * _facing
	return 0.0
