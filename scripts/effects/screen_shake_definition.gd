@tool
class_name ScreenShakeDefinition
extends Resource

## Presentation-only camera impulse tuning. Combat never reads these values.

@export_range(0.0, 32.0, 0.1) var light_hit_pixels: float = 1.5
@export_range(0.0, 32.0, 0.1) var heavy_hit_pixels: float = 3.5
@export_range(0.0, 32.0, 0.1) var environmental_hit_pixels: float = 5.0
@export_range(0.0, 32.0, 0.1) var boss_hit_pixels: float = 6.0
@export_range(0.01, 2.0, 0.01) var light_duration_seconds: float = 0.12
@export_range(0.01, 2.0, 0.01) var heavy_duration_seconds: float = 0.20
@export_range(1.0, 120.0, 0.5) var oscillations_per_second: float = 34.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if light_hit_pixels < 0.0 or heavy_hit_pixels < light_hit_pixels:
		errors.append("Heavy camera shake must be at least the light-hit magnitude.")
	if environmental_hit_pixels < heavy_hit_pixels:
		errors.append("Environmental camera shake must be at least the heavy-hit magnitude.")
	if boss_hit_pixels < heavy_hit_pixels:
		errors.append("Boss camera shake must be at least the heavy-hit magnitude.")
	if light_duration_seconds <= 0.0 or heavy_duration_seconds < light_duration_seconds:
		errors.append("Heavy camera shake duration must be at least the light duration.")
	if oscillations_per_second <= 0.0:
		errors.append("Camera shake oscillation rate must be positive.")
	return errors
