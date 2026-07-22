class_name AttackDefinition
extends Resource

const ProjectileDefinitionType = preload("res://scripts/combat/projectile_definition.gd")

## Authored timing and impact values for one automatic attack.

enum DeliveryKind {
	MELEE,
	PROJECTILE,
	CHARGE,
	AREA,
	SUMMON,
}

enum ImpactKind {
	LIGHT,
	HEAVY,
	BOSS,
}

@export var id: StringName = &"basic_attack"
@export var display_name: String = "Basic Attack"
@export var delivery_kind: int = DeliveryKind.MELEE
@export var impact_kind: int = ImpactKind.LIGHT
@export_range(0.0, 10.0, 0.01) var damage_multiplier: float = 1.0
@export_range(0.0, 5.0, 0.01) var windup_time: float = 0.2
@export_range(0.001, 2.0, 0.001) var active_time: float = 0.08
@export_range(0.0, 5.0, 0.01) var recovery_time: float = 0.35
@export_range(0.0, 5.0, 0.01) var cooldown_time: float = 0.2
@export_range(1.0, 300.0, 1.0) var attack_range: float = 34.0
@export_range(0.0, 1000.0, 1.0) var knockback_force: float = 100.0
@export_range(0.0, 2.0, 0.01) var knockback_duration: float = 0.16
@export_range(0.0, 0.5, 0.001) var hit_stop_duration: float = 0.05
@export_range(0.0, 500.0, 1.0) var minimum_range: float = 0.0
@export_range(0.0, 10.0, 0.01) var special_cooldown_seconds: float = 0.0
@export_range(0.0, 5.0, 0.01) var telegraph_seconds: float = 0.0
@export_range(1, 8, 1) var combo_hit_count: int = 1
@export_range(0.0, 500.0, 1.0) var charge_distance: float = 0.0
@export_range(0.0, 500.0, 1.0) var area_radius: float = 0.0
@export var summon_actor_ids: Array[StringName] = []
@export var one_shot: bool = false
@export var projectile_definition: ProjectileDefinitionType


func is_heavy() -> bool:
	# The hit-stop fallback preserves the accepted Milestone 1/4 contract for
	# existing authored attacks while M6 content uses the explicit impact kind.
	return impact_kind != ImpactKind.LIGHT or hit_stop_duration >= 0.06
