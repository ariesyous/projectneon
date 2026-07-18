@tool
class_name RunEscalationDefinition
extends Resource

## Irreversible Night Pressure tuning and deterministic scaling. Spawn budgets
## use non-negative round-half-up: floor(scaled_value + 0.5).

@export_range(0.0, 100.0, 0.01) var passive_pressure_per_second: float = 0.25
@export_range(0.0, 1000.0, 0.1) var pressure_per_standard_encounter: float = 6.0
@export_range(0.0, 1000.0, 0.1) var pressure_per_elite_encounter: float = 10.0
@export var extraction_pressure_thresholds: PackedFloat32Array = PackedFloat32Array([18.0, 36.0])
@export_range(0.0, 10000.0, 0.1) var boss_pressure_threshold: float = 50.0
@export_range(0.0, 10.0, 0.0001) var health_multiplier_per_pressure: float = 0.01
@export_range(0.0, 10.0, 0.0001) var damage_multiplier_per_pressure: float = 0.005
@export_range(0.0, 10.0, 0.0001) var spawn_budget_multiplier_per_pressure: float = 0.0125
@export_range(1, 1000, 1) var global_enemy_concurrency_limit: int = 30


func health_multiplier(pressure: float) -> float:
	return 1.0 + maxf(pressure, 0.0) * maxf(health_multiplier_per_pressure, 0.0)


func damage_multiplier(pressure: float) -> float:
	return 1.0 + maxf(pressure, 0.0) * maxf(damage_multiplier_per_pressure, 0.0)


func spawn_budget_multiplier(pressure: float) -> float:
	return 1.0 + maxf(pressure, 0.0) * maxf(spawn_budget_multiplier_per_pressure, 0.0)


func scaled_spawn_budget(base_budget: int, pressure: float, heat_addition: int = 0) -> int:
	var scaled_value: float = (
		float(maxi(base_budget, 0)) * spawn_budget_multiplier(pressure)
		+ float(maxi(heat_addition, 0))
	)
	return maxi(int(floor(scaled_value + 0.5)), 0)


func capped_concurrency(requested: int, encounter_limit: int, active_global: int = 0) -> int:
	var available_global: int = maxi(global_enemy_concurrency_limit - maxi(active_global, 0), 0)
	return mini(mini(maxi(requested, 0), maxi(encounter_limit, 0)), available_global)
