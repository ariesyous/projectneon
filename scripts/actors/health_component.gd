class_name HealthComponent
extends Node

## Authoritative integer health for one actor. Damage calculation itself is
## kept in DamageCalculator so it can be tested without a scene tree.

signal health_changed(current_health: int, maximum_health: int)
signal depleted()

var maximum_health: int = 1
var current_health: int = 1


func initialize(authored_maximum: int) -> void:
	maximum_health = maxi(authored_maximum, 1)
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)


func apply_damage(amount: int) -> int:
	if amount <= 0 or current_health <= 0:
		return 0
	var previous_health: int = current_health
	current_health = maxi(current_health - amount, 0)
	var applied_damage: int = previous_health - current_health
	health_changed.emit(current_health, maximum_health)
	if current_health == 0:
		depleted.emit()
	return applied_damage


func heal(amount: int) -> int:
	if amount <= 0 or current_health <= 0:
		return 0
	var previous_health: int = current_health
	current_health = mini(current_health + amount, maximum_health)
	health_changed.emit(current_health, maximum_health)
	return current_health - previous_health


func set_maximum_health(authored_maximum: int, preserve_health_ratio: bool = true) -> void:
	var new_maximum: int = maxi(authored_maximum, 1)
	if new_maximum == maximum_health:
		return
	var previous_ratio: float = normalized_health()
	maximum_health = new_maximum
	if preserve_health_ratio:
		current_health = clampi(
			int(floor(previous_ratio * float(maximum_health) + 0.5)),
			1 if current_health > 0 else 0,
			maximum_health
		)
	else:
		current_health = mini(current_health, maximum_health)
	health_changed.emit(current_health, maximum_health)


func is_depleted() -> bool:
	return current_health <= 0


func normalized_health() -> float:
	return float(current_health) / float(maxi(maximum_health, 1))
