@tool
class_name NeonChoiceCard
extends Button

enum VisualState {
	DEFAULT,
	SELECTED,
	WARNING,
	DISABLED,
}

var _visual_state: int = VisualState.DEFAULT
var _state_label: String = ""


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size.y = maxf(custom_minimum_size.y, 96.0)
	clip_text = true
	_apply_visual_state()


func set_visual_state(state: int, state_label: String = "") -> void:
	_visual_state = state
	button_pressed = state == VisualState.SELECTED
	if not _state_label.is_empty() and tooltip_text.begins_with("%s  /  " % _state_label):
		tooltip_text = tooltip_text.trim_prefix("%s  /  " % _state_label)
	_state_label = state_label
	if not state_label.is_empty():
		tooltip_text = "%s  /  %s" % [state_label, tooltip_text]
	_apply_visual_state()


func get_visual_state() -> int:
	return _visual_state


func _make_custom_tooltip(for_text: String) -> Object:
	return NeonTooltip.create(for_text)


func _apply_visual_state() -> void:
	match _visual_state:
		VisualState.SELECTED:
			theme_type_variation = &"ChoiceCardSelected"
		VisualState.WARNING:
			theme_type_variation = &"DangerButton"
		_:
			theme_type_variation = &"ChoiceCard"
