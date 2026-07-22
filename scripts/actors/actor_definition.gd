class_name ActorDefinition
extends Resource

## Immutable authored values shared by the generic ActorController. Runtime
## health, targeting, movement, and combat state live in composed components.

enum CombatRole {
	PERMANENT_CREW,
	TEMPORARY_ALLY,
	BASIC_ENEMY,
	ELITE,
	BOSS,
}

@export var id: StringName = &"actor"
@export var display_name: String = "Actor"
@export var combat_role: int = CombatRole.BASIC_ENEMY
@export_range(1, 10000, 1) var maximum_health: int = 100
@export_range(1.0, 1000.0, 1.0) var movement_speed: float = 90.0
@export_range(0, 1000, 1) var base_damage: int = 10
@export_range(0.0, 10.0, 0.01) var damage_multiplier: float = 1.0
@export_range(0.0, 10.0, 0.01) var damage_taken_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var knockback_resistance: float = 0.0
@export_range(0.0, 1.0, 0.01) var stagger_resistance: float = 0.0
@export_range(0.0, 1000.0, 1.0) var light_stagger_armour: float = 0.0
@export_range(0.0, 5.0, 0.01) var maximum_stun_duration: float = 5.0
@export_range(0.0, 10.0, 0.01) var control_lockout_seconds: float = 0.0
@export_range(0.0, 10.0, 0.01) var damage_against_elites_multiplier: float = 1.0
@export_range(0.0, 10.0, 0.01) var damage_against_bosses_multiplier: float = 1.0
@export_range(0.05, 2.0, 0.01) var intervention_cooldown_multiplier: float = 1.0
@export_range(0.0, 10.0, 0.01) var environmental_collision_damage_multiplier: float = 1.0
@export_range(0.0, 500.0, 1.0) var preferred_minimum_range: float = 0.0
@export_range(0.0, 500.0, 1.0) var preferred_maximum_range: float = 0.0
@export_range(0.0, 1.0, 0.01) var enrage_health_ratio: float = 0.0
@export_range(1.0, 5.0, 0.01) var enrage_damage_multiplier: float = 1.0
@export_range(1.0, 5.0, 0.01) var enrage_attack_speed_multiplier: float = 1.0
@export var grants_coin_reward: bool = false
@export_range(0, 10000, 1) var authored_coin_value: int = 0
@export_range(0.0, 5.0, 0.01) var cleanup_delay: float = 0.65
@export var starting_equipment: Array[EquipmentDefinition] = []


func is_permanent_crew() -> bool:
	return combat_role == CombatRole.PERMANENT_CREW


func is_temporary_ally() -> bool:
	return combat_role == CombatRole.TEMPORARY_ALLY


func is_elite() -> bool:
	return combat_role == CombatRole.ELITE


func is_boss() -> bool:
	return combat_role == CombatRole.BOSS
