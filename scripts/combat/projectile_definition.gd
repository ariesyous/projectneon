@tool
class_name ProjectileDefinition
extends Resource

## Data-only tuning for a deterministic lane projectile.

@export var id: StringName = &"projectile"
@export_range(1.0, 1000.0, 1.0) var speed: float = 100.0
@export_range(0.05, 10.0, 0.01) var lifetime_seconds: float = 2.5
@export_range(1.0, 64.0, 1.0) var collision_radius: float = 8.0
@export_range(0.0, 64.0, 1.0) var visual_radius: float = 5.0
@export var primary_color: Color = Color("9de7ff")
@export var accent_color: Color = Color("ffffff")


func is_valid() -> bool:
	return (
		id != &""
		and speed > 0.0
		and lifetime_seconds > 0.0
		and collision_radius > 0.0
	)
