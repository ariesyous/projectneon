class_name PowerBox
extends Area2D

## Replaceable Power Box world presentation/input. EnvironmentController owns
## context, validation, exact request tokens, effects, and shared cooldown.

signal activation_requested()
signal preview_visibility_changed(is_visible: bool)

const READY_COLOR: Color = Color("72f0d0")
const INVALID_COLOR: Color = Color("ffbf69")
const COOLDOWN_COLOR: Color = Color("a987ff")
const ELECTRIC_COLOR: Color = Color("ffe46b")

@export var definition: PowerBoxDefinition

@onready var _state_label: Label = %StateLabel
@onready var _interaction_label: Label = %InteractionLabel
@onready var _shape: CollisionShape2D = $InteractionShape

var _context_active: bool = false
var _can_activate: bool = false
var _validity_reason: StringName = &"invalid_state"
var _target_count: int = 0
var _cooldown_remaining: float = 0.0
var _hovered: bool = false
var _external_preview_visible: bool = false
var _activation_remaining: float = 0.0
var _rejection_remaining: float = 0.0
var _presentation_clock: float = 0.0


func _ready() -> void:
	input_pickable = false
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_context_active(false)
	_refresh_labels()
	queue_redraw()


func _process(delta: float) -> void:
	_presentation_clock += maxf(delta, 0.0)
	_activation_remaining = maxf(_activation_remaining - maxf(delta, 0.0), 0.0)
	_rejection_remaining = maxf(_rejection_remaining - maxf(delta, 0.0), 0.0)
	if _context_active:
		queue_redraw()


func set_context_active(is_active: bool) -> void:
	_context_active = is_active
	visible = is_active
	input_pickable = is_active
	if _shape != null:
		_shape.set_deferred(&"disabled", not is_active)
	if not is_active:
		_hovered = false
		_external_preview_visible = false
	_refresh_labels()
	queue_redraw()


func present_snapshot(snapshot: Dictionary) -> void:
	_context_active = StringName(snapshot.get("action_id", &"")) == &"power_box"
	_can_activate = bool(snapshot.get("can_activate", false))
	_validity_reason = StringName(snapshot.get("validity_reason", &"invalid_state"))
	_target_count = maxi(int(snapshot.get("target_count", 0)), 0)
	_cooldown_remaining = maxf(float(snapshot.get("cooldown_remaining", 0.0)), 0.0)
	set_context_active(_context_active)


func set_external_preview_visible(is_visible: bool) -> void:
	_external_preview_visible = is_visible and _context_active
	queue_redraw()


func play_activation() -> void:
	_activation_remaining = 0.45
	_rejection_remaining = 0.0
	queue_redraw()


func play_rejection() -> void:
	_rejection_remaining = 0.45
	queue_redraw()


func is_preview_visible() -> bool:
	return _context_active and (_hovered or _external_preview_visible)


func _input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if not _context_active:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		get_viewport().set_input_as_handled()
		activation_requested.emit()
		return
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null and touch_event.pressed:
		get_viewport().set_input_as_handled()
		activation_requested.emit()


func _draw() -> void:
	if not _context_active or definition == null:
		return
	var state_color: Color = _state_color()
	if is_preview_visible():
		draw_circle(Vector2.ZERO, definition.range_radius, Color(state_color, 0.12), true)
		draw_arc(Vector2.ZERO, definition.range_radius, 0.0, TAU, 64, Color(state_color, 0.95), 2.5)
		draw_circle(Vector2.ZERO, 5.0, Color(state_color, 0.42), true)
	var rejection_offset: float = (
		2.0 if _rejection_remaining > 0.0 and int(_presentation_clock * 30.0) % 2 == 0 else 0.0
	)
	draw_set_transform(Vector2(rejection_offset, 0.0))
	var pulse: float = 0.55 + sin(_presentation_clock * 7.0) * 0.18
	draw_rect(Rect2(-12.0, -22.0, 24.0, 35.0), Color("10283b"), true)
	draw_rect(Rect2(-12.0, -22.0, 24.0, 35.0), state_color, false, 2.0)
	var bolt := PackedVector2Array([
		Vector2(2.0, -17.0), Vector2(-6.0, -3.0), Vector2(0.0, -3.0),
		Vector2(-4.0, 8.0), Vector2(8.0, -7.0), Vector2(2.0, -7.0),
	])
	draw_colored_polygon(bolt, Color(ELECTRIC_COLOR, pulse))
	if _activation_remaining > 0.0:
		var progress: float = 1.0 - _activation_remaining / 0.45
		for ring_index: int in range(3):
			draw_arc(
				Vector2.ZERO,
				18.0 + float(ring_index) * 10.0 + progress * 14.0,
				0.0,
				TAU,
				32,
				Color(ELECTRIC_COLOR, (1.0 - progress) * 0.8),
				2.0
			)
	draw_set_transform(Vector2.ZERO)


func _refresh_labels() -> void:
	if _state_label == null or _interaction_label == null:
		return
	if not _context_active:
		_state_label.text = ""
		_interaction_label.text = ""
		return
	_state_label.add_theme_color_override("font_color", _state_color())
	if _can_activate:
		_state_label.text = "READY x%d" % _target_count
		_interaction_label.text = "CLICK / TAP"
	elif _validity_reason == &"cooldown":
		_state_label.text = "COOL %.1fs" % _cooldown_remaining
		_interaction_label.text = "RECHARGING"
	elif _validity_reason == &"no_interruptible_intent":
		_state_label.text = "HOLD FOR TELL"
		_interaction_label.text = "NO LIVE WINDUP"
	else:
		_state_label.text = "NO TARGET"
		_interaction_label.text = "ENEMY IN AREA"


func _state_color() -> Color:
	if _can_activate:
		return READY_COLOR
	if _validity_reason == &"cooldown":
		return COOLDOWN_COLOR
	return INVALID_COLOR


func _on_mouse_entered() -> void:
	if not _context_active:
		return
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
