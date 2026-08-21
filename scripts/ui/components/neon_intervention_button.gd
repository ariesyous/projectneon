@tool
class_name NeonInterventionButton
extends Button

enum VisualState {
	READY,
	COOLING,
	UNAVAILABLE,
	EXHAUSTED,
}

var _state: int = VisualState.UNAVAILABLE


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 160.0), maxf(custom_minimum_size.y, 56.0))
	clip_text = true
	_apply_state()


func present(
	role_label: String,
	action_label: String,
	status_label: String,
	state: int,
	is_disabled: bool = false
) -> void:
	_state = state
	text = "%s  %s\n%s" % [role_label.to_upper(), action_label.to_upper(), status_label.to_upper()]
	disabled = is_disabled
	_apply_state()


func get_visual_state() -> int:
	return _state


func _make_custom_tooltip(for_text: String) -> Object:
	return NeonTooltip.create(for_text)


func _apply_state() -> void:
	match _state:
		VisualState.READY:
			theme_type_variation = &"InterventionReady"
		VisualState.COOLING:
			theme_type_variation = &"InterventionCooling"
		_:
			theme_type_variation = &"InterventionUnavailable"
