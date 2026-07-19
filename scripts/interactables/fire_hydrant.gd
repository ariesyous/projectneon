class_name FireHydrant
extends Area2D

## Replaceable world presentation and input surface for the Fire Hydrant.
## Cooldown, target filtering, damage, and knockback remain authoritative in
## FireHydrantController; this node only forwards intent and renders state.

signal activation_requested()
signal preview_visibility_changed(is_visible: bool)

const STATE_READY: int = 0
const STATE_NO_TARGET: int = 1
const STATE_COOLING_DOWN: int = 2
const FULL_CIRCLE_RADIANS: float = TAU
const READY_COLOR: Color = Color("72f0d0")
const NO_TARGET_COLOR: Color = Color("ffbf69")
const COOLDOWN_COLOR: Color = Color("a987ff")
const WATER_COLOR: Color = Color("74efff")
const WATER_CORE_COLOR: Color = Color("e5fdff")

@export var tuning: FireHydrantTuning

@onready var _state_label: Label = %StateLabel
@onready var _interaction_label: Label = %InteractionLabel

var _state: int = STATE_NO_TARGET
var _cooldown_remaining: float = 0.0
var _cooldown_duration: float = 0.0
var _valid_enemy_count: int = 0
var _hovered: bool = false
var _external_preview_visible: bool = false
var _water_remaining: float = 0.0
var _rejection_remaining: float = 0.0
var _presentation_clock: float = 0.0


func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_refresh_labels()
	queue_redraw()


func _process(delta: float) -> void:
	_presentation_clock += maxf(delta, 0.0)
	_water_remaining = maxf(0.0, _water_remaining - maxf(delta, 0.0))
	_rejection_remaining = maxf(0.0, _rejection_remaining - maxf(delta, 0.0))
	if (
		_state == STATE_READY
		or _hovered
		or _external_preview_visible
		or _water_remaining > 0.0
		or _rejection_remaining > 0.0
	):
		queue_redraw()


func present_state(
	state: int,
	cooldown_remaining: float,
	cooldown_duration: float,
	valid_enemy_count: int
) -> void:
	_state = state
	_cooldown_remaining = maxf(0.0, cooldown_remaining)
	_cooldown_duration = maxf(0.0, cooldown_duration)
	_valid_enemy_count = maxi(0, valid_enemy_count)
	_refresh_labels()
	queue_redraw()


func set_external_preview_visible(preview_is_visible: bool) -> void:
	if _external_preview_visible == preview_is_visible:
		return
	_external_preview_visible = preview_is_visible
	queue_redraw()


func play_activation() -> void:
	if tuning == null:
		return
	_water_remaining = maxf(_water_remaining, tuning.water_duration)
	_rejection_remaining = 0.0
	queue_redraw()


func play_rejection() -> void:
	if tuning == null:
		return
	_rejection_remaining = maxf(_rejection_remaining, tuning.rejection_duration)
	queue_redraw()


func get_preview_radius() -> float:
	return tuning.range_radius if tuning != null else 0.0


func is_preview_visible() -> bool:
	return _hovered or _external_preview_visible


func _input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if (
		mouse_event != null
		and mouse_event.button_index == MOUSE_BUTTON_LEFT
		and mouse_event.pressed
	):
		get_viewport().set_input_as_handled()
		activation_requested.emit()
		return

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null and touch_event.pressed:
		get_viewport().set_input_as_handled()
		activation_requested.emit()


func _draw() -> void:
	_draw_range_preview()

	var rejection_offset: float = 0.0
	if _rejection_remaining > 0.0:
		rejection_offset = 2.0 if int(_presentation_clock * 30.0) % 2 == 0 else -2.0
	draw_set_transform(Vector2(rejection_offset, 0.0))
	_draw_hydrant_body()
	_draw_water_burst()
	draw_set_transform(Vector2.ZERO)


func _draw_range_preview() -> void:
	if not is_preview_visible() or tuning == null:
		return
	var radius: float = tuning.range_radius
	var state_color: Color = _get_state_color()
	draw_circle(Vector2.ZERO, radius, Color(state_color, 0.13))
	draw_arc(Vector2.ZERO, radius, 0.0, FULL_CIRCLE_RADIANS, 72, Color(state_color, 0.96), 2.5)
	draw_arc(Vector2.ZERO, radius - 5.0, 0.0, FULL_CIRCLE_RADIANS, 72, Color(state_color, 0.42), 1.0)
	draw_dashed_line(
		Vector2.ZERO,
		Vector2(-radius, 0.0),
		Color(state_color, 0.80),
		1.5,
		6.0,
		false,
		false
	)
	draw_circle(Vector2.ZERO, 6.0, Color(state_color, 0.34))
	for segment: int in range(24):
		if segment % 2 != 0:
			continue
		var start_angle: float = FULL_CIRCLE_RADIANS * float(segment) / 24.0
		var end_angle: float = FULL_CIRCLE_RADIANS * float(segment + 1) / 24.0
		draw_arc(Vector2.ZERO, radius - 9.0, start_angle, end_angle, 4, Color(state_color, 0.52), 1.0)


func _draw_hydrant_body() -> void:
	var state_color: Color = _get_state_color()
	var pulse: float = 0.5 + 0.5 * sin(_presentation_clock * 5.0)
	var glow_alpha: float = 0.16 + pulse * 0.12 if _state == STATE_READY else 0.10
	draw_circle(Vector2(0.0, 2.0), 27.0 if _hovered else 23.0, Color(state_color, glow_alpha))
	draw_ellipse(
		Vector2(0.0, 13.0),
		18.0,
		5.0,
		Color(0.03, 0.04, 0.10, 0.62),
		true,
		-1.0,
		false
	)

	# Side nozzles and their bright rims make the interaction readable at the
	# native 640 x 360 presentation without requiring production sprites.
	draw_rect(Rect2(-18.0, -7.0, 10.0, 12.0), Color("a91e4d"), true)
	draw_rect(Rect2(8.0, -7.0, 10.0, 12.0), Color("7e1740"), true)
	draw_circle(Vector2(-19.0, -1.0), 6.0, Color("ff5d7f"))
	draw_circle(Vector2(-19.0, -1.0), 3.0, Color("ffd0a6"))
	draw_circle(Vector2(19.0, -1.0), 6.0, Color("b51f51"))
	draw_circle(Vector2(19.0, -1.0), 3.0, Color("ff9a76"))

	draw_rect(Rect2(-11.0, -14.0, 22.0, 27.0), Color("d9295f"), true)
	draw_rect(Rect2(-8.0, -12.0, 5.0, 23.0), Color("ff5d7f"), true)
	draw_rect(Rect2(5.0, -12.0, 4.0, 23.0), Color("8d1744"), true)
	draw_rect(Rect2(-13.0, 9.0, 26.0, 6.0), Color("85133d"), true)
	draw_rect(Rect2(-15.0, 13.0, 30.0, 4.0), Color("ffbd62"), true)

	draw_rect(Rect2(-13.0, -18.0, 26.0, 5.0), Color("ffbd62"), true)
	draw_rect(Rect2(-10.0, -22.0, 20.0, 5.0), Color("e93366"), true)
	draw_rect(Rect2(-7.0, -25.0, 14.0, 4.0), Color("ff7c8d"), true)
	draw_circle(Vector2(0.0, -25.0), 2.0, Color("fff0a8"))

	# The jewel is a compact authored-state light: cyan ready, amber no target,
	# and violet while cooling down.
	draw_rect(Rect2(-5.0, -7.0, 10.0, 8.0), Color(0.04, 0.06, 0.14, 0.88), true)
	draw_circle(Vector2.ZERO + Vector2(0.0, -3.0), 3.0, state_color)
	draw_circle(Vector2(-1.0, -4.0), 1.0, Color(1.0, 1.0, 1.0, 0.8))

	if _state == STATE_COOLING_DOWN and _cooldown_duration > 0.0:
		var progress: float = clampf(1.0 - _cooldown_remaining / _cooldown_duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 25.0, -PI * 0.5, -PI * 0.5 + FULL_CIRCLE_RADIANS * progress, 32, COOLDOWN_COLOR, 2.5)


func _draw_water_burst() -> void:
	if _water_remaining <= 0.0 or tuning == null or tuning.water_duration <= 0.0:
		return
	var progress: float = clampf(1.0 - _water_remaining / tuning.water_duration, 0.0, 1.0)
	var envelope: float = sin(progress * PI)
	var reach: float = lerpf(24.0, minf(tuning.range_radius, 102.0), minf(1.0, progress * 3.0))
	var alpha: float = clampf(envelope * 1.4, 0.0, 1.0)
	var source: Vector2 = Vector2(-19.0, -2.0)
	var end_point: Vector2 = Vector2(-reach, lerpf(-8.0, 7.0, progress))
	draw_line(source, end_point, Color(WATER_COLOR, alpha * 0.72), 12.0, false)
	draw_line(source + Vector2(0.0, -2.0), end_point + Vector2(0.0, -3.0), Color(WATER_CORE_COLOR, alpha), 4.0, false)
	for splash_index: int in range(5):
		var splash_progress: float = fmod(progress + float(splash_index) * 0.17, 1.0)
		var splash_position: Vector2 = source.lerp(end_point, splash_progress)
		splash_position.y += sin(float(splash_index) * 1.7 + progress * 8.0) * 8.0
		draw_circle(splash_position, 2.0 + float(splash_index % 2), Color(WATER_CORE_COLOR, alpha * 0.85))


func _refresh_labels() -> void:
	if _state_label == null or _interaction_label == null:
		return
	_state_label.add_theme_color_override("font_color", _get_state_color())
	match _state:
		STATE_READY:
			_state_label.text = "READY x%d" % _valid_enemy_count
			_interaction_label.text = "CLICK / TAP"
		STATE_NO_TARGET:
			_state_label.text = "NO TARGET"
			_interaction_label.text = "ENEMY IN RANGE"
		STATE_COOLING_DOWN:
			_state_label.text = "COOL %.1fs" % _cooldown_remaining
			_interaction_label.text = "RECHARGING"
		_:
			_state_label.text = "OFFLINE"
			_interaction_label.text = "UNAVAILABLE"


func _get_state_color() -> Color:
	match _state:
		STATE_READY:
			return READY_COLOR
		STATE_COOLING_DOWN:
			return COOLDOWN_COLOR
		_:
			return NO_TARGET_COLOR


func _on_mouse_entered() -> void:
	_hovered = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	preview_visibility_changed.emit(true)
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	preview_visibility_changed.emit(false)
	queue_redraw()


func _exit_tree() -> void:
	if _hovered:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
