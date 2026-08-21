@tool
class_name NeonToast
extends PanelContainer

enum Tone {
	INFO,
	SUCCESS,
	WARNING,
	DANGER,
}

var _label: Label = null
var _active_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(360.0, 52.0)
	_ensure_content()
	visible = false


func show_message(
	message: String,
	tone: int = Tone.INFO,
	duration: float = NeonUiTokens.TOAST_DURATION
) -> void:
	if message.is_empty():
		return
	_ensure_content()
	_label.text = message
	match tone:
		Tone.SUCCESS:
			theme_type_variation = &"SafePanel"
		Tone.WARNING:
			theme_type_variation = &"WarningPanel"
		Tone.DANGER:
			theme_type_variation = &"DangerPanel"
		_:
			theme_type_variation = &"RaisedPanel"
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	visible = true
	modulate.a = 1.0
	if not is_inside_tree():
		return
	_active_tween = create_tween()
	_active_tween.tween_interval(maxf(duration, 0.0))
	_active_tween.tween_property(self, "modulate:a", 0.0, NeonUiTokens.MOTION_STANDARD)
	_active_tween.tween_callback(hide)


func get_message() -> String:
	_ensure_content()
	return _label.text


func _ensure_content() -> void:
	if _label != null:
		return
	_label = Label.new()
	_label.name = "Text"
	_label.theme_type_variation = &"BodyLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)
