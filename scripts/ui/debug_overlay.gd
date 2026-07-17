class_name DebugOverlay
extends CanvasLayer

## Development-only diagnostics shell. F1 toggles the overlay and F2 requests
## a presentation-only change to the stage's lane guides.

signal lane_visibility_requested(lanes_are_visible: bool)

@onready var fps_label: Label = $Root/Panel/FpsLabel
@onready var lane_state_label: Label = $Root/Panel/LaneStateLabel
@onready var lane_toggle_button: Button = $Root/Panel/LaneToggleButton

var _lanes_visible: bool = true
var _fps_refresh_remaining: float = 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		visible = false
		set_process(false)
		set_process_unhandled_key_input(false)
		return

	lane_toggle_button.pressed.connect(_toggle_lanes)
	_refresh_lane_text()
	_refresh_fps_text()


func _process(delta: float) -> void:
	_fps_refresh_remaining -= delta
	if _fps_refresh_remaining <= 0.0:
		_fps_refresh_remaining = 0.25
		_refresh_fps_text()


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_F1:
			visible = not visible
			get_viewport().set_input_as_handled()
		KEY_F2:
			_toggle_lanes()
			get_viewport().set_input_as_handled()


func set_lane_visibility(lanes_are_visible: bool) -> void:
	_lanes_visible = lanes_are_visible
	if is_node_ready():
		_refresh_lane_text()


func _toggle_lanes() -> void:
	_lanes_visible = not _lanes_visible
	_refresh_lane_text()
	lane_visibility_requested.emit(_lanes_visible)


func _refresh_lane_text() -> void:
	var state_text: String = "VISIBLE" if _lanes_visible else "HIDDEN"
	lane_state_label.text = "COMBAT LANES: %s" % state_text
	lane_toggle_button.text = "F2  %s LANES" % ("HIDE" if _lanes_visible else "SHOW")


func _refresh_fps_text() -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
