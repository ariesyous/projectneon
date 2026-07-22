@tool
class_name FireHydrantTuning
extends Resource

## Authored Milestone 2 Fire Hydrant gameplay and presentation timing.

@export var id: StringName = &"fire_hydrant"
@export var display_name: String = "Fire Hydrant"
@export_range(1.0, 640.0, 1.0) var range_radius: float = 112.0
@export_range(0, 10000, 1) var damage: int = 18
@export_range(0.0, 2000.0, 1.0) var knockback_force: float = 300.0
@export_range(0.0, 2.0, 0.01) var knockback_duration: float = 0.30
@export_range(-1.0, 1.0, 0.01) var knockback_direction_x: float = -1.0
@export_range(0.0, 120.0, 0.1) var cooldown_seconds: float = 8.0
@export_range(0.05, 60.0, 0.05) var wet_duration_seconds: float = 4.0
@export_range(0.0, 5.0, 0.01) var water_duration: float = 0.55
@export_range(0.0, 5.0, 0.01) var impact_duration: float = 0.28
@export_range(0.0, 5.0, 0.01) var rejection_duration: float = 0.50
