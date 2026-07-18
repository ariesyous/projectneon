class_name DisplayController
extends Node

## Presentation-only display integration. It polls window state, forwards
## fullscreen requests from valid input callbacks, and never changes combat.

signal fullscreen_changed(is_fullscreen: bool)
signal landscape_state_changed(is_landscape: bool)
signal safe_area_changed(safe_area: Rect2i, window_size: Vector2i)

const STATE_POLL_INTERVAL: float = 0.20

var _poll_remaining: float = 0.0
var _last_fullscreen: bool = false
var _last_landscape: bool = true
var _last_safe_area: Rect2i = Rect2i()
var _last_window_size: Vector2i = Vector2i.ZERO


func _ready() -> void:
	# Parent composition normally connects after child _ready callbacks. Deferred
	# initial publication ensures those connections receive the first snapshot.
	call_deferred("refresh_state", true)


func _process(delta: float) -> void:
	_poll_remaining -= maxf(0.0, delta)
	if _poll_remaining <= 0.0:
		refresh_state()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return

	# Browsers may reserve Escape and exit fullscreen before Godot receives it.
	# When it does reach the game, only consume it while exiting fullscreen.
	if key_event.keycode == KEY_ESCAPE and is_fullscreen():
		set_fullscreen(false)
		get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())


func set_fullscreen(is_enabled: bool) -> void:
	var requested_mode: int = (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if is_enabled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_mode(requested_mode, DisplayServer.MAIN_WINDOW_ID)
	_poll_remaining = 0.0
	# Native and browser display modes may settle asynchronously. Polling will
	# publish the actual result without pretending the request always succeeded.
	call_deferred("refresh_state")


func is_fullscreen() -> bool:
	var mode: int = DisplayServer.window_get_mode(DisplayServer.MAIN_WINDOW_ID)
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func is_landscape() -> bool:
	var window_size: Vector2i = DisplayServer.window_get_size(DisplayServer.MAIN_WINDOW_ID)
	return window_size.x >= window_size.y


func refresh_state(force: bool = false) -> void:
	_poll_remaining = STATE_POLL_INTERVAL
	var current_fullscreen: bool = is_fullscreen()
	var current_window_size: Vector2i = DisplayServer.window_get_size(
		DisplayServer.MAIN_WINDOW_ID
	)
	var current_landscape: bool = current_window_size.x >= current_window_size.y
	var current_safe_area: Rect2i = DisplayServer.get_display_safe_area()

	if force or current_fullscreen != _last_fullscreen:
		_last_fullscreen = current_fullscreen
		fullscreen_changed.emit(current_fullscreen)
	if force or current_landscape != _last_landscape:
		_last_landscape = current_landscape
		landscape_state_changed.emit(current_landscape)
	if (
		force
		or current_safe_area != _last_safe_area
		or current_window_size != _last_window_size
	):
		_last_safe_area = current_safe_area
		_last_window_size = current_window_size
		safe_area_changed.emit(current_safe_area, current_window_size)
