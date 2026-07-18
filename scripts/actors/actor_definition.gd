class_name ActorDefinition
extends Resource

## Immutable authored values shared by the generic ActorController. Runtime
## health, targeting, movement, and combat state live in composed components.

@export var id: StringName = &"actor"
@export var display_name: String = "Actor"
@export_range(1, 10000, 1) var maximum_health: int = 100
@export_range(1.0, 1000.0, 1.0) var movement_speed: float = 90.0
@export_range(0, 1000, 1) var base_damage: int = 10
@export_range(0.0, 10.0, 0.01) var damage_multiplier: float = 1.0
@export_range(0.0, 10.0, 0.01) var damage_taken_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var knockback_resistance: float = 0.0
@export var grants_coin_reward: bool = false
@export_range(0, 10000, 1) var authored_coin_value: int = 0
@export_range(0.0, 5.0, 0.01) var cleanup_delay: float = 0.65
