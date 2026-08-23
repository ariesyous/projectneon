@tool
class_name NeonBuildCallout
extends PanelContainer

## Rate-limited icon-plus-label acknowledgement for authoritative build
## expression. Repeated procs aggregate visually and never affect combat.

const DUPLICATE_WINDOW_MSEC: int = 900

var _icon: TextureRect
var _heading: Label
var _detail: Label
var _active_tween: Tween
var _last_event_key: StringName = &""
var _last_event_msec: int = -100000
var _repeat_count: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(440.0, 68.0)
	theme_type_variation = &"RaisedPanel"
	_ensure_content()
	visible = false


func present(
	icon: Texture2D,
	heading: String,
	detail: String,
	event_key: StringName,
	at_msec: int = -1,
	duration_seconds: float = 1.7
) -> bool:
	if heading.strip_edges().is_empty() or detail.strip_edges().is_empty():
		return false
	_ensure_content()
	var now_msec: int = at_msec if at_msec >= 0 else Time.get_ticks_msec()
	if (
		event_key != &""
		and event_key == _last_event_key
		and now_msec - _last_event_msec < DUPLICATE_WINDOW_MSEC
	):
		_repeat_count += 1
		_detail.text = "%s  /  x%d" % [detail.to_upper(), _repeat_count]
		return false
	_last_event_key = event_key
	_last_event_msec = now_msec
	_repeat_count = 1
	_icon.texture = icon
	_icon.visible = icon != null
	_heading.text = heading.to_upper()
	_detail.text = detail.to_upper()
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	visible = true
	modulate.a = 1.0
	if not is_inside_tree():
		return true
	_active_tween = create_tween()
	_active_tween.tween_interval(maxf(duration_seconds, 0.0))
	_active_tween.tween_property(self, "modulate:a", 0.0, NeonUiTokens.MOTION_STANDARD)
	_active_tween.tween_callback(hide)
	return true


func clear() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	visible = false
	modulate.a = 1.0
	_last_event_key = &""
	_last_event_msec = -100000
	_repeat_count = 0


func get_heading() -> String:
	_ensure_content()
	return _heading.text


func get_detail() -> String:
	_ensure_content()
	return _detail.text


func _ensure_content() -> void:
	if _heading != null:
		return
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override(&"separation", 12)
	add_child(row)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.custom_minimum_size = Vector2(48.0, 48.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)
	var copy: VBoxContainer = VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override(&"separation", 0)
	row.add_child(copy)
	_heading = Label.new()
	_heading.name = "Heading"
	_heading.theme_type_variation = &"EyebrowLabel"
	_heading.clip_text = true
	copy.add_child(_heading)
	_detail = Label.new()
	_detail.name = "Detail"
	_detail.theme_type_variation = &"BodyLabel"
	_detail.clip_text = true
	copy.add_child(_detail)
