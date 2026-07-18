@tool
class_name HeatDefinition
extends Resource

## Tactical alert tuning. Heat is always separate from irreversible Night
## Pressure; this Resource only maps immediate danger and reward effects.

@export var tier_lower_bounds: PackedInt32Array = PackedInt32Array([0, 20, 40, 60, 80, 100])
@export var spawn_budget_additions: PackedInt32Array = PackedInt32Array([0, 1, 2, 3, 4, 5])
@export var enemy_damage_multipliers: PackedFloat32Array = PackedFloat32Array([
	1.0,
	1.05,
	1.10,
	1.15,
	1.20,
	1.30,
])
@export var reward_quality_tiers: PackedInt32Array = PackedInt32Array([0, 0, 1, 2, 3, 4])
@export var reward_multipliers: PackedFloat32Array = PackedFloat32Array([
	1.0,
	1.05,
	1.10,
	1.20,
	1.35,
	1.50,
])
@export var elite_available_from_tier: int = 3


func clamp_heat(value: int) -> int:
	return clampi(value, 0, 100)


func tier_for_heat(value: int) -> int:
	var safe_heat: int = clamp_heat(value)
	var result: int = 0
	for tier_index: int in range(tier_lower_bounds.size()):
		if safe_heat < tier_lower_bounds[tier_index]:
			break
		result = tier_index
	return clampi(result, 0, 5)


func spawn_budget_addition_for_tier(tier: int) -> int:
	return _int_at(spawn_budget_additions, tier, 0)


func enemy_damage_multiplier_for_tier(tier: int) -> float:
	return _float_at(enemy_damage_multipliers, tier, 1.0)


func reward_quality_for_tier(tier: int) -> int:
	return _int_at(reward_quality_tiers, tier, 0)


func reward_multiplier_for_tier(tier: int) -> float:
	return _float_at(reward_multipliers, tier, 1.0)


func is_elite_available(tier: int) -> bool:
	return clampi(tier, 0, 5) >= elite_available_from_tier


func _int_at(values: PackedInt32Array, index: int, fallback: int) -> int:
	if values.is_empty():
		return fallback
	return values[clampi(index, 0, values.size() - 1)]


func _float_at(values: PackedFloat32Array, index: int, fallback: float) -> float:
	if values.is_empty():
		return fallback
	return values[clampi(index, 0, values.size() - 1)]
