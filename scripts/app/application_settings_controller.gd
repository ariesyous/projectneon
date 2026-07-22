@tool
class_name ApplicationSettingsController
extends Node

## Applies presentation settings and forwards focus-pause intent. RunDirector
## remains the only authority that may accept, reject, or release gameplay pause;
## this component never writes SceneTree.paused.

signal settings_applied(settings: GameSettingsData)
signal focus_pause_intent_requested(should_pause: bool)

var current_settings: GameSettingsData = GameSettingsData.create_default()
var _focus_pause_intent_active: bool = false


func apply_settings(settings: GameSettingsData, target_window: Window = null) -> void:
	current_settings = (
		settings.sanitized_copy() if settings != null else GameSettingsData.create_default()
	)
	AudioBusContract.ensure_required_buses()
	AudioBusContract.apply_volume_settings(current_settings)
	if target_window != null:
		target_window.mode = (
			Window.MODE_FULLSCREEN if current_settings.fullscreen else Window.MODE_WINDOWED
		)
	if not current_settings.pause_on_focus_loss and _focus_pause_intent_active:
		_focus_pause_intent_active = false
		focus_pause_intent_requested.emit(false)
	settings_applied.emit(current_settings)


func handle_focus_changed(has_focus: bool) -> void:
	if not current_settings.pause_on_focus_loss:
		return
	if not has_focus and not _focus_pause_intent_active:
		_focus_pause_intent_active = true
		focus_pause_intent_requested.emit(true)
	elif has_focus and _focus_pause_intent_active:
		_focus_pause_intent_active = false
		focus_pause_intent_requested.emit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		handle_focus_changed(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		handle_focus_changed(true)


func is_focus_pause_intent_active() -> bool:
	return _focus_pause_intent_active
