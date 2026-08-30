class_name ActorVisual
extends Node2D

## Replaceable code-drawn placeholder presentation. It observes actor state but
## owns no gameplay decisions, health, targeting, or attack timing.

enum VariantKind {
	JAX,
	STREET_PUNK,
	ZOEY,
	REX,
	BAT_THUG,
	BOTTLE_THROWER,
	VIPER_ENFORCER,
	THE_VIPER,
	BACKUP,
}

const ANIMATION_REDRAW_STEP: float = 1.0 / 30.0

@export var variant_kind: int = VariantKind.JAX

var _state: int = ActorStateMachine.State.IDLE
var _facing: float = 1.0
var _current_health: int = 1
var _maximum_health: int = 1
var _is_targeted: bool = false
var _is_focus_priority: bool = false
var _has_target: bool = false
var _flash_remaining: float = 0.0
var _animation_clock: float = 0.0
var _bleed_stacks: int = 0
var _is_shocked: bool = false
var _hit_flash_reduction: float = 0.0
var _redraw_accumulator: float = 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	_animation_clock += safe_delta
	_flash_remaining = maxf(_flash_remaining - safe_delta, 0.0)
	_redraw_accumulator += safe_delta
	if _redraw_accumulator >= ANIMATION_REDRAW_STEP:
		_redraw_accumulator = fmod(_redraw_accumulator, ANIMATION_REDRAW_STEP)
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


func set_focus_priority(is_focused: bool) -> void:
	_is_focus_priority = is_focused
	queue_redraw()


func set_has_target(has_target: bool) -> void:
	_has_target = has_target
	queue_redraw()


func play_hit_flash(duration: float = 0.09) -> void:
	var reduced_duration: float = maxf(duration, 0.0) * (1.0 - _hit_flash_reduction)
	_flash_remaining = maxf(_flash_remaining, reduced_duration)
	queue_redraw()


func set_hit_flash_reduction(reduction: float) -> void:
	_hit_flash_reduction = clampf(reduction, 0.0, 1.0)
	if is_equal_approx(_hit_flash_reduction, 1.0):
		_flash_remaining = 0.0
	queue_redraw()


func set_statuses(bleed_stacks: int, is_shocked: bool) -> void:
	_bleed_stacks = maxi(bleed_stacks, 0)
	_is_shocked = is_shocked
	queue_redraw()


func get_presentation_snapshot() -> Dictionary:
	return {
		"variant_kind": variant_kind,
		"silhouette_id": _silhouette_id(),
		"body_scale": _body_scale_for_variant(),
		"focus_shape": &"corner_brackets",
		"target_shape": &"diamond",
		"bleed_shape": &"droplet",
		"shock_shape": &"bolt",
		"bleed_stacks": _bleed_stacks,
		"shocked": _is_shocked,
		"hit_flash_reduction": _hit_flash_reduction,
		"animation_redraw_hz": 30,
	}


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
	var body_scale: Vector2 = _body_scale_for_variant()
	draw_set_transform(draw_offset, body_rotation, body_scale)
	var palette: Array[Color] = _get_palette()
	var main_color: Color = palette[0]
	var dark_color: Color = palette[1]
	var accent_color: Color = palette[2]
	var skin_color: Color = palette[3]
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

	# Variant mass and stance replace palette-only differentiation while the
	# actor origin, hurtbox, and attack timing remain unchanged.
	var leg_spacing: float = _leg_spacing_for_variant()
	var leg_width: float = _leg_width_for_variant()
	draw_line(Vector2(-leg_spacing + lean, -17.0), Vector2(-leg_spacing - 2.0 + stride, -2.0), dark_color, leg_width)
	draw_line(Vector2(leg_spacing + lean, -17.0), Vector2(leg_spacing + 2.0 - stride, -2.0), dark_color, leg_width)
	draw_line(Vector2(-leg_spacing - 5.0 + stride, -1.0), Vector2(-leg_spacing + 2.0 + stride, -1.0), accent_color, 3.0)
	draw_line(Vector2(leg_spacing - 2.0 - stride, -1.0), Vector2(leg_spacing + 5.0 - stride, -1.0), accent_color, 3.0)

	var torso: PackedVector2Array = _torso_points(lean)
	draw_colored_polygon(torso, main_color)
	if variant_kind in [VariantKind.VIPER_ENFORCER, VariantKind.THE_VIPER]:
		var outline: PackedVector2Array = torso.duplicate()
		outline.append(torso[0])
		draw_polyline(outline, accent_color, 2.5, false)
	draw_line(Vector2(-8.0 + lean, -20.0), Vector2(9.0 + lean, -20.0), accent_color, 2.0)

	var shoulder_width: float = _shoulder_width_for_variant()
	var shoulder: Vector2 = Vector2(shoulder_width * _facing + lean, -33.0)
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
	draw_line(shoulder, fist, skin_color, _arm_width_for_variant())
	draw_circle(fist, 4.0 if _state == ActorStateMachine.State.ATTACK_ACTIVE else 3.0, accent_color)
	draw_line(Vector2(-shoulder_width * _facing + lean, -32.0), Vector2(-(shoulder_width + 7.0) * _facing + lean, -20.0), skin_color, maxf(_arm_width_for_variant() - 1.0, 4.0))

	# Head, hair, and role props complete the silhouette grammar.
	draw_rect(Rect2(Vector2(-6.0 + lean, -49.0), Vector2(12.0, 12.0)), skin_color, true)
	if variant_kind in [VariantKind.JAX, VariantKind.ZOEY, VariantKind.REX]:
		var hair := PackedVector2Array([
			Vector2(-8.0 + lean, -48.0), Vector2(-5.0 + lean, -57.0),
			Vector2(-1.0 + lean, -52.0), Vector2(3.0 + lean, -59.0),
			Vector2(5.0 + lean, -52.0), Vector2(9.0 + lean, -55.0),
			Vector2(7.0 + lean, -45.0), Vector2(-7.0 + lean, -44.0),
		])
		draw_colored_polygon(hair, main_color)
		draw_line(Vector2(-8.0 + lean, -41.0), Vector2(9.0 + lean, -41.0), dark_color, 3.0)
	elif variant_kind == VariantKind.THE_VIPER:
		var viper_hair := PackedVector2Array([
			Vector2(-9.0 + lean, -48.0), Vector2(-5.0 + lean, -60.0),
			Vector2(0.0 + lean, -53.0), Vector2(6.0 + lean, -61.0),
			Vector2(10.0 + lean, -48.0), Vector2(5.0 + lean, -44.0),
			Vector2(-7.0 + lean, -44.0),
		])
		draw_colored_polygon(viper_hair, accent_color)
		draw_line(Vector2(-11.0 + lean, -41.0), Vector2(10.0 + lean, -41.0), dark_color, 3.0)
	else:
		draw_rect(Rect2(Vector2(-8.0 + lean, -54.0), Vector2(16.0, 6.0)), accent_color, true)
		draw_line(Vector2(-10.0 + lean, -51.0), Vector2(10.0 + lean, -51.0), dark_color, 3.0)
		draw_rect(Rect2(Vector2(-3.0 + lean, -31.0), Vector2(6.0, 7.0)), accent_color, true)
	_draw_variant_role_details(lean, main_color, dark_color, accent_color)
	if variant_kind == VariantKind.BAT_THUG:
		draw_line(Vector2(-18.0 * _facing, -38.0), Vector2(20.0 * _facing, -13.0), accent_color, 4.0)
	elif variant_kind == VariantKind.BOTTLE_THROWER:
		draw_circle(Vector2(15.0 * _facing + lean, -25.0), 4.0, Color("7dffcf"))
	elif variant_kind == VariantKind.VIPER_ENFORCER:
		draw_arc(Vector2(0.0, -29.0), 17.0, -PI, PI, 24, Color("e9ff62"), 3.0)
	elif variant_kind == VariantKind.THE_VIPER:
		draw_arc(Vector2(0.0, -31.0), 21.0, -PI, PI, 24, Color("fff28a"), 4.0)
		draw_line(Vector2(-13.0, -58.0), Vector2(13.0, -58.0), Color("ff3a8c"), 4.0)
	draw_rect(Rect2(Vector2(2.0 * _facing + lean, -45.0), Vector2(3.0 * _facing, 2.0)), dark_color, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_indicators() -> void:
	if _state != ActorStateMachine.State.DEAD:
		draw_rect(Rect2(-19.0, -67.0, 38.0, 5.0), Color(0.01, 0.02, 0.07, 0.95), true)
		var health_width: float = 36.0 * clampf(float(_current_health) / float(_maximum_health), 0.0, 1.0)
		var health_color: Color = (
			Color("48ef7b")
			if variant_kind in [VariantKind.JAX, VariantKind.ZOEY, VariantKind.REX, VariantKind.BACKUP]
			else Color("ff5b77")
		)
		draw_rect(Rect2(-18.0, -66.0, health_width, 3.0), health_color, true)
	if _is_targeted:
		var marker := PackedVector2Array([
			Vector2(0.0, -76.0), Vector2(5.0, -71.0), Vector2(0.0, -68.0), Vector2(-5.0, -71.0),
		])
		draw_colored_polygon(marker, Color("ffd34e"))
	if _is_focus_priority and _state != ActorStateMachine.State.DEAD:
		var focus_pulse: float = 0.72 + sin(_animation_clock * 12.0) * 0.20
		var focus_color: Color = Color(0.35, 0.96, 1.0, focus_pulse)
		# Corner brackets are deliberately unlike target diamonds, Environment
		# footprints, and enemy danger areas.
		var left: float = -25.0
		var right: float = 25.0
		var top: float = -58.0
		var bottom: float = -6.0
		for segment: PackedVector2Array in [
			PackedVector2Array([Vector2(left, top + 10.0), Vector2(left, top), Vector2(left + 10.0, top)]),
			PackedVector2Array([Vector2(right - 10.0, top), Vector2(right, top), Vector2(right, top + 10.0)]),
			PackedVector2Array([Vector2(left, bottom - 10.0), Vector2(left, bottom), Vector2(left + 10.0, bottom)]),
			PackedVector2Array([Vector2(right - 10.0, bottom), Vector2(right, bottom), Vector2(right, bottom - 10.0)]),
		]:
			draw_polyline(segment, focus_color, 2.5, false)
	if _has_target and _state != ActorStateMachine.State.DEAD:
		var direction_marker := PackedVector2Array([
			Vector2(12.0 * _facing, -55.0),
			Vector2(17.0 * _facing, -52.0),
			Vector2(12.0 * _facing, -49.0),
		])
		draw_colored_polygon(direction_marker, Color("f8f1a6"))
	if _bleed_stacks > 0 and _state != ActorStateMachine.State.DEAD:
		var droplet := PackedVector2Array([
			Vector2(-9.0, -78.0), Vector2(-13.0, -71.0),
			Vector2(-9.0, -68.0), Vector2(-5.0, -71.0),
		])
		draw_colored_polygon(droplet, Color("ff335f"))
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-6.0, -70.0),
			str(_bleed_stacks),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			8,
			Color("ffd4dc")
		)
	if _is_shocked and _state != ActorStateMachine.State.DEAD:
		var pulse: float = 0.65 + sin(_animation_clock * 15.0) * 0.25
		var shock_color: Color = Color(0.2, 0.95, 1.0, pulse)
		draw_polyline(PackedVector2Array([
			Vector2(7.0, -78.0), Vector2(13.0, -74.0),
			Vector2(9.0, -70.0), Vector2(15.0, -67.0),
		]), shock_color, 2.0, false)


func _body_scale_for_variant() -> Vector2:
	match variant_kind:
		VariantKind.ZOEY:
			return Vector2(0.94, 1.0)
		VariantKind.REX:
			return Vector2(1.08, 1.05)
		VariantKind.STREET_PUNK:
			return Vector2(0.98, 1.0)
		VariantKind.BAT_THUG:
			return Vector2(1.06, 1.04)
		VariantKind.BOTTLE_THROWER:
			return Vector2(0.92, 1.0)
		VariantKind.VIPER_ENFORCER:
			return Vector2(1.14, 1.10)
		VariantKind.THE_VIPER:
			return Vector2(1.30, 1.30)
		VariantKind.BACKUP:
			return Vector2(0.94, 0.98)
	return Vector2.ONE


func _silhouette_id() -> StringName:
	match variant_kind:
		VariantKind.JAX:
			return &"crew_triangle"
		VariantKind.ZOEY:
			return &"crew_diagonal"
		VariantKind.REX:
			return &"crew_rectangle"
		VariantKind.STREET_PUNK:
			return &"basic_hood_wedge"
		VariantKind.BAT_THUG:
			return &"heavy_diagonal_bat"
		VariantKind.BOTTLE_THROWER:
			return &"ranged_prop_arm"
		VariantKind.VIPER_ENFORCER:
			return &"elite_wide_armour"
		VariantKind.THE_VIPER:
			return &"boss_asymmetric_coat"
		VariantKind.BACKUP:
			return &"backup_runner"
	return &"unknown"


func _leg_spacing_for_variant() -> float:
	match variant_kind:
		VariantKind.REX, VariantKind.VIPER_ENFORCER, VariantKind.THE_VIPER:
			return 6.0
		VariantKind.ZOEY, VariantKind.BOTTLE_THROWER, VariantKind.BACKUP:
			return 3.5
	return 4.5


func _leg_width_for_variant() -> float:
	return (
		7.0
		if variant_kind in [VariantKind.REX, VariantKind.VIPER_ENFORCER, VariantKind.THE_VIPER]
		else 5.5
	)


func _shoulder_width_for_variant() -> float:
	match variant_kind:
		VariantKind.REX:
			return 10.0
		VariantKind.VIPER_ENFORCER:
			return 12.0
		VariantKind.THE_VIPER:
			return 11.0
		VariantKind.ZOEY, VariantKind.BOTTLE_THROWER:
			return 6.0
	return 7.5


func _arm_width_for_variant() -> float:
	return (
		7.5
		if variant_kind in [VariantKind.REX, VariantKind.VIPER_ENFORCER, VariantKind.THE_VIPER]
		else 5.5
	)


func _torso_points(lean: float) -> PackedVector2Array:
	match variant_kind:
		VariantKind.JAX:
			return PackedVector2Array([
				Vector2(-12.0 + lean, -38.0), Vector2(11.0 + lean, -36.0),
				Vector2(9.0 + lean, -17.0), Vector2(-8.0 + lean, -17.0),
			])
		VariantKind.ZOEY:
			return PackedVector2Array([
				Vector2(-7.0 + lean, -38.0), Vector2(8.0 + lean, -38.0),
				Vector2(11.0 + lean, -17.0), Vector2(-6.0 + lean, -17.0),
			])
		VariantKind.REX:
			return PackedVector2Array([
				Vector2(-14.0 + lean, -39.0), Vector2(14.0 + lean, -39.0),
				Vector2(15.0 + lean, -16.0), Vector2(-14.0 + lean, -16.0),
			])
		VariantKind.BAT_THUG:
			return PackedVector2Array([
				Vector2(-13.0 + lean, -38.0), Vector2(12.0 + lean, -37.0),
				Vector2(13.0 + lean, -16.0), Vector2(-11.0 + lean, -16.0),
			])
		VariantKind.BOTTLE_THROWER, VariantKind.BACKUP:
			return PackedVector2Array([
				Vector2(-7.0 + lean, -37.0), Vector2(8.0 + lean, -37.0),
				Vector2(9.0 + lean, -17.0), Vector2(-7.0 + lean, -17.0),
			])
		VariantKind.VIPER_ENFORCER:
			return PackedVector2Array([
				Vector2(-16.0 + lean, -40.0), Vector2(16.0 + lean, -40.0),
				Vector2(14.0 + lean, -15.0), Vector2(-14.0 + lean, -15.0),
			])
		VariantKind.THE_VIPER:
			return PackedVector2Array([
				Vector2(-13.0 + lean, -41.0), Vector2(17.0 + lean, -38.0),
				Vector2(19.0 + lean, -14.0), Vector2(-15.0 + lean, -14.0),
			])
	return PackedVector2Array([
		Vector2(-10.0 + lean, -37.0), Vector2(9.0 + lean, -37.0),
		Vector2(11.0 + lean, -17.0), Vector2(-9.0 + lean, -17.0),
	])


func _draw_variant_role_details(
	lean: float,
	main_color: Color,
	dark_color: Color,
	accent_color: Color
) -> void:
	match variant_kind:
		VariantKind.JAX:
			draw_line(Vector2(-14.0 * _facing + lean, -25.0), Vector2(-18.0 * _facing + lean, -20.0), accent_color, 3.0)
			draw_line(Vector2(12.0 * _facing + lean, -26.0), Vector2(17.0 * _facing + lean, -22.0), accent_color, 3.0)
		VariantKind.ZOEY:
			var gauntlet: Vector2 = Vector2(15.0 * _facing + lean, -25.0)
			draw_rect(Rect2(gauntlet - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), dark_color)
			draw_polyline(PackedVector2Array([
				gauntlet + Vector2(-2.0, -4.0), gauntlet + Vector2(2.0, -1.0),
				gauntlet + Vector2(-1.0, 2.0), gauntlet + Vector2(3.0, 4.0),
			]), accent_color, 2.0, false)
		VariantKind.REX:
			draw_rect(Rect2(-15.0 + lean, -38.0, 7.0, 8.0), dark_color)
			draw_rect(Rect2(8.0 + lean, -38.0, 7.0, 8.0), dark_color)
			draw_line(Vector2(0.0 + lean, -36.0), Vector2(0.0 + lean, -18.0), accent_color, 2.0)
		VariantKind.STREET_PUNK:
			var hood := PackedVector2Array([
				Vector2(-9.0 + lean, -48.0), Vector2(0.0 + lean, -58.0),
				Vector2(9.0 + lean, -48.0), Vector2(6.0 + lean, -39.0),
				Vector2(-6.0 + lean, -39.0),
			])
			draw_colored_polygon(hood, dark_color)
		VariantKind.BAT_THUG:
			draw_rect(Rect2(-13.0 + lean, -38.0, 9.0, 7.0), accent_color)
		VariantKind.BOTTLE_THROWER:
			draw_line(Vector2(-2.0 + lean, -36.0), Vector2(7.0 + lean, -18.0), accent_color, 2.0)
		VariantKind.VIPER_ENFORCER:
			draw_rect(Rect2(-18.0 + lean, -39.0, 9.0, 9.0), accent_color)
			draw_rect(Rect2(9.0 + lean, -39.0, 9.0, 9.0), accent_color)
			draw_rect(Rect2(-13.0 + lean, -7.0, 9.0, 5.0), accent_color)
			draw_rect(Rect2(4.0 + lean, -7.0, 9.0, 5.0), accent_color)
		VariantKind.THE_VIPER:
			var left_tail := PackedVector2Array([
				Vector2(-13.0 + lean, -17.0), Vector2(-2.0 + lean, -16.0),
				Vector2(-8.0 + lean, -2.0), Vector2(-19.0 + lean, -6.0),
			])
			var right_tail := PackedVector2Array([
				Vector2(4.0 + lean, -16.0), Vector2(18.0 + lean, -14.0),
				Vector2(20.0 + lean, -2.0), Vector2(7.0 + lean, -5.0),
			])
			draw_colored_polygon(left_tail, dark_color)
			draw_colored_polygon(right_tail, main_color)
			draw_line(Vector2(10.0 + lean, -38.0), Vector2(18.0 + lean, -31.0), accent_color, 6.0)
		VariantKind.BACKUP:
			var armband_x: float = (-10.0 if _facing > 0.0 else 5.0) + lean
			draw_rect(Rect2(armband_x, -31.0, 5.0, 4.0), accent_color)


func _body_rotation() -> float:
	if _state == ActorStateMachine.State.KNOCKED_BACK:
		return -0.22 * _facing
	if _state == ActorStateMachine.State.INCAPACITATED:
		return -0.75 * _facing
	return 0.0


func _get_palette() -> Array[Color]:
	match variant_kind:
		VariantKind.JAX:
			return [Color("19d9e7"), Color("07526d"), Color("d5fbff"), Color("f1a36f")]
		VariantKind.ZOEY:
			return [Color("b84dff"), Color("3c176f"), Color("5ff6ff"), Color("d88b61")]
		VariantKind.REX:
			return [Color("ff9d2e"), Color("793612"), Color("fff0a6"), Color("a96948")]
		VariantKind.BAT_THUG:
			return [Color("d14a72"), Color("56152f"), Color("ffd45a"), Color("b9704d")]
		VariantKind.BOTTLE_THROWER:
			return [Color("4bd08a"), Color("145b48"), Color("aaffdf"), Color("d08a5f")]
		VariantKind.VIPER_ENFORCER:
			return [Color("7ad33b"), Color("203f18"), Color("e9ff62"), Color("9e6548")]
		VariantKind.THE_VIPER:
			return [Color("a72ee8"), Color("35125d"), Color("fff28a"), Color("c27b54")]
		VariantKind.BACKUP:
			return [Color("4f83ff"), Color("18366e"), Color("e8f2ff"), Color("d99a6b")]
		_:
			return [Color("ef3f8f"), Color("66214f"), Color("ff9a3d"), Color("d48756")]
