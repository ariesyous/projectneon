class_name ScreenShakeController
extends Node

## Deterministic presentation-only camera shake. It never consumes a run RNG
## stream and always restores the authored camera offset on reset.

signal shake_started(magnitude_pixels: float, duration_seconds: float)
signal shake_finished()

const DEFAULT_TUNING: ScreenShakeDefinition = preload(
	"res://data/effects/milestone_6_screen_shake.tres"
)

@export var tuning: ScreenShakeDefinition = DEFAULT_TUNING
@export var camera_path: NodePath = NodePath("../Camera2D")

var _camera: Camera2D
var _setting_intensity: float = 1.0
var _remaining_seconds: float = 0.0
var _total_seconds: float = 0.0
var _magnitude_pixels: float = 0.0
var _phase_seconds: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera2D
	if _camera != null:
		_base_offset = _camera.offset


func _process(delta: float) -> void:
	step_presentation(delta)


func set_intensity(intensity: float) -> void:
	_setting_intensity = clampf(intensity, 0.0, 1.0)
	if is_zero_approx(_setting_intensity):
		reset_presentation()


func get_intensity() -> float:
	return _setting_intensity


func request_shake(magnitude_pixels: float, duration_seconds: float) -> bool:
	var scaled_magnitude: float = maxf(magnitude_pixels, 0.0) * _setting_intensity
	var safe_duration: float = maxf(duration_seconds, 0.0)
	if scaled_magnitude <= 0.0 or safe_duration <= 0.0 or _camera == null:
		return false
	_magnitude_pixels = maxf(_magnitude_pixels, scaled_magnitude)
	_remaining_seconds = maxf(_remaining_seconds, safe_duration)
	_total_seconds = maxf(_total_seconds, safe_duration)
	_phase_seconds = 0.0
	shake_started.emit(_magnitude_pixels, _remaining_seconds)
	return true


func request_light_hit() -> bool:
	return request_shake(tuning.light_hit_pixels, tuning.light_duration_seconds)


func request_heavy_hit() -> bool:
	return request_shake(tuning.heavy_hit_pixels, tuning.heavy_duration_seconds)


func request_environmental_hit() -> bool:
	return request_shake(tuning.environmental_hit_pixels, tuning.heavy_duration_seconds)


func request_boss_hit() -> bool:
	return request_shake(tuning.boss_hit_pixels, tuning.heavy_duration_seconds)


func step_presentation(delta: float) -> void:
	if _camera == null or _remaining_seconds <= 0.0:
		return
	var safe_delta: float = maxf(delta, 0.0)
	_remaining_seconds = maxf(_remaining_seconds - safe_delta, 0.0)
	_phase_seconds += safe_delta
	var envelope: float = (
		clampf(_remaining_seconds / _total_seconds, 0.0, 1.0)
		if _total_seconds > 0.0
		else 0.0
	)
	var phase: float = _phase_seconds * tuning.oscillations_per_second * TAU
	_camera.offset = _base_offset + Vector2(
		sin(phase) * _magnitude_pixels * envelope,
		cos(phase * 1.37) * _magnitude_pixels * 0.55 * envelope
	)
	if _remaining_seconds <= 0.0:
		_camera.offset = _base_offset
		_magnitude_pixels = 0.0
		_total_seconds = 0.0
		shake_finished.emit()


func reset_presentation() -> void:
	_remaining_seconds = 0.0
	_total_seconds = 0.0
	_magnitude_pixels = 0.0
	_phase_seconds = 0.0
	if _camera != null:
		_camera.offset = _base_offset


func get_snapshot() -> Dictionary:
	return {
		"intensity": _setting_intensity,
		"remaining_seconds": _remaining_seconds,
		"magnitude_pixels": _magnitude_pixels,
		"active": _remaining_seconds > 0.0,
	}
