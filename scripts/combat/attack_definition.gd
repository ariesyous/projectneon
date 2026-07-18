class_name AttackDefinition
extends Resource

## Authored timing and impact values for one automatic attack.

@export var id: StringName = &"basic_attack"
@export var display_name: String = "Basic Attack"
@export_range(0.0, 10.0, 0.01) var damage_multiplier: float = 1.0
@export_range(0.0, 5.0, 0.01) var windup_time: float = 0.2
@export_range(0.001, 2.0, 0.001) var active_time: float = 0.08
@export_range(0.0, 5.0, 0.01) var recovery_time: float = 0.35
@export_range(0.0, 5.0, 0.01) var cooldown_time: float = 0.2
@export_range(1.0, 300.0, 1.0) var attack_range: float = 34.0
@export_range(0.0, 1000.0, 1.0) var knockback_force: float = 100.0
@export_range(0.0, 2.0, 0.01) var knockback_duration: float = 0.16
@export_range(0.0, 0.5, 0.001) var hit_stop_duration: float = 0.05
