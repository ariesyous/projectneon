class_name CombatProjectile
extends Node2D

const ProjectileDefinitionType = preload("res://scripts/combat/projectile_definition.gd")

## Deterministic, director-stepped projectile presentation and swept-hit state.
## CombatDirector remains the damage authority.

var projectile_definition: ProjectileDefinitionType
var source_actor: ActorController
var source_team: int = ActorController.Team.ENEMY
var attack_definition: AttackDefinition
var direction: Vector2 = Vector2.RIGHT
var remaining_seconds: float = 0.0
var spawn_order: int = -1


func configure(
	definition: ProjectileDefinitionType,
	attacker: ActorController,
	attack: AttackDefinition,
	origin: Vector2,
	target_position: Vector2,
	order: int
) -> bool:
	if definition == null or not definition.is_valid() or attacker == null or attack == null:
		return false
	projectile_definition = definition
	source_actor = attacker
	source_team = attacker.team
	attack_definition = attack
	global_position = origin
	direction = origin.direction_to(target_position)
	if direction.is_zero_approx():
		direction = Vector2(attacker.facing_direction, 0.0)
	direction = direction.normalized()
	remaining_seconds = definition.lifetime_seconds
	spawn_order = order
	queue_redraw()
	return true


func step(delta: float, candidates: Array[ActorController]) -> ActorController:
	if projectile_definition == null or remaining_seconds <= 0.0:
		return null
	var safe_delta: float = maxf(delta, 0.0)
	if safe_delta <= 0.0:
		return null
	var start_position: Vector2 = global_position
	var applied_time: float = minf(safe_delta, remaining_seconds)
	var end_position: Vector2 = (
		start_position
		+ direction * projectile_definition.speed * applied_time
	)
	remaining_seconds = maxf(remaining_seconds - safe_delta, 0.0)

	var best_target: ActorController = null
	var best_fraction: float = INF
	for candidate: ActorController in candidates:
		if candidate == null or not is_instance_valid(candidate) or not candidate.can_be_targeted():
			continue
		if candidate.team == source_team:
			continue
		var fraction: float = _segment_hit_fraction(
			start_position,
			end_position,
			candidate.global_position,
			projectile_definition.collision_radius
		)
		if fraction < 0.0:
			continue
		if (
			best_target == null
			or fraction < best_fraction
			or (
				is_equal_approx(fraction, best_fraction)
				and candidate.registration_order < best_target.registration_order
			)
		):
			best_target = candidate
			best_fraction = fraction

	global_position = end_position if best_target == null else start_position.lerp(end_position, best_fraction)
	return best_target


func is_expired() -> bool:
	return remaining_seconds <= 0.0


func _draw() -> void:
	if projectile_definition == null:
		return
	draw_line(
		-direction * projectile_definition.visual_radius * 2.2,
		Vector2.ZERO,
		projectile_definition.primary_color,
		maxf(projectile_definition.visual_radius * 0.75, 2.0)
	)
	draw_circle(
		Vector2.ZERO,
		projectile_definition.visual_radius,
		projectile_definition.primary_color
	)
	draw_circle(
		Vector2.ZERO,
		maxf(projectile_definition.visual_radius * 0.42, 1.0),
		projectile_definition.accent_color
	)


static func _segment_hit_fraction(
	start_position: Vector2,
	end_position: Vector2,
	point: Vector2,
	radius: float
) -> float:
	var segment: Vector2 = end_position - start_position
	var length_squared: float = segment.length_squared()
	var fraction: float = 0.0
	if length_squared > 0.000001:
		fraction = clampf(
			(point - start_position).dot(segment) / length_squared,
			0.0,
			1.0
		)
	var closest: Vector2 = start_position + segment * fraction
	if closest.distance_squared_to(point) > radius * radius:
		return -1.0
	return fraction
