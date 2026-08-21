@tool
class_name NeonPhaseBanner
extends PanelContainer

var _phase: Label = null
var _next_event: Label = null
var _progress: Label = null
var _status: NeonCountdownStatus = null
var _icon: TextureRect = null
var _last_phase_text: String = ""
var _phase_tween: Tween = null


func _ready() -> void:
	theme_type_variation = &"RaisedPanel"
	custom_minimum_size = Vector2(720.0, 86.0)
	_ensure_content()


func present(
	phase_text: String,
	progress_text: String,
	next_event_text: String,
	status_title: String,
	status_value: String,
	is_warning: bool = false,
	phase_icon: Texture2D = null
) -> void:
	_ensure_content()
	var normalized_phase: String = phase_text.to_upper()
	var phase_changed: bool = not _last_phase_text.is_empty() and _last_phase_text != normalized_phase
	_last_phase_text = normalized_phase
	_icon.texture = phase_icon
	_icon.visible = phase_icon != null
	_phase.text = normalized_phase
	_progress.text = progress_text.to_upper()
	_next_event.text = "NEXT: %s" % next_event_text
	_status.present(status_title, status_value, is_warning)
	if phase_changed and is_inside_tree():
		if _phase_tween != null and _phase_tween.is_valid():
			_phase_tween.kill()
		modulate.a = 0.62
		_phase_tween = create_tween()
		_phase_tween.tween_property(self, "modulate:a", 1.0, NeonUiTokens.MOTION_STANDARD)


func get_phase_text() -> String:
	_ensure_content()
	return _phase.text


func get_next_event_text() -> String:
	_ensure_content()
	return _next_event.text


func get_status_value() -> String:
	_ensure_content()
	return _status.get_value_text()


func _ensure_content() -> void:
	if _phase != null:
		return
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", NeonUiTokens.SPACE_4)
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
	copy.add_theme_constant_override("separation", NeonUiTokens.SPACE_1)
	row.add_child(copy)
	var heading_row: HBoxContainer = HBoxContainer.new()
	heading_row.name = "Heading"
	heading_row.add_theme_constant_override("separation", NeonUiTokens.SPACE_3)
	copy.add_child(heading_row)
	_phase = Label.new()
	_phase.name = "Phase"
	_phase.theme_type_variation = &"HeadingLabel"
	heading_row.add_child(_phase)
	_progress = Label.new()
	_progress.name = "Progress"
	_progress.theme_type_variation = &"EyebrowLabel"
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading_row.add_child(_progress)
	_next_event = Label.new()
	_next_event.name = "NextEvent"
	_next_event.theme_type_variation = &"BodyLabel"
	_next_event.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_next_event)
	_status = NeonCountdownStatus.new()
	_status.name = "Status"
	row.add_child(_status)
