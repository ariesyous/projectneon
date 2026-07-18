class_name CombatDirector
extends Node

## Run-scoped authority for Milestone 1 automatic combat: registration, stable
## target coordination, reservations, deterministic hit resolution, and local
## gameplay-only hit-stop. Encounter scheduling remains deferred.

signal actor_registered(actor: ActorController)
signal actor_unregistered(actor: ActorController)
signal actor_died(actor: ActorController)
signal actor_incapacitated(actor: ActorController)
signal hit_landed(
	attacker: ActorController,
	target: ActorController,
	damage: int,
	world_position: Vector2,
	hit_stop_duration: float
)
signal crew_status_changed(actor: ActorController, current_health: int, maximum_health: int, state: int)
signal environmental_hit_landed(
	source_id: StringName,
	target: ActorController,
	damage: int,
	world_position: Vector2,
	knockback_force: float
)

const RESPONSIBILITY: String = "Coordinate encounter-level combat state."
const TARGET_RETALIATION_DISTANCE_MARGIN: float = 18.0
const DEFAULT_COMBAT_SPACE: CombatSpaceDefinition = preload(
	"res://data/combat/downtown_loop_combat_space.tres"
)

@export var combat_space: CombatSpaceDefinition = DEFAULT_COMBAT_SPACE

var _actors: Array[ActorController] = []
var _reservation_registry: AttackPositionRegistry = null
var _next_registration_order: int = 0
var _hit_stop_remaining: float = 0.0


func _ready() -> void:
	if combat_space == null:
		combat_space = DEFAULT_COMBAT_SPACE
	_ensure_reservation_registry()


func _physics_process(delta: float) -> void:
	step_simulation(delta)


func step_simulation(delta: float) -> void:
	var simulation_delta: float = maxf(delta, 0.0)
	if simulation_delta <= 0.0:
		return
	if _hit_stop_remaining > 0.0:
		if simulation_delta <= _hit_stop_remaining:
			_hit_stop_remaining -= simulation_delta
			return
		simulation_delta -= _hit_stop_remaining
		_hit_stop_remaining = 0.0

	var actors_to_step: Array[ActorController] = _actors.duplicate()
	for actor: ActorController in actors_to_step:
		if not _actors.has(actor) or not is_instance_valid(actor) or actor.is_queued_for_deletion():
			continue
		actor.step_simulation(simulation_delta)
		# A landed hit freezes remaining combatants immediately and resumes them
		# on the next authoritative step. Registration order makes this stable.
		if _hit_stop_remaining > 0.0:
			break
	_refresh_target_indicators()


func register_actor(actor: ActorController) -> bool:
	if actor == null or not is_instance_valid(actor) or _actors.has(actor):
		return false
	_ensure_reservation_registry()
	actor.registration_order = _next_registration_order
	_next_registration_order += 1
	_actors.append(actor)
	actor.configure_combat_space(combat_space)
	if not actor.died.is_connected(_on_actor_died):
		actor.died.connect(_on_actor_died)
	if not actor.incapacitated.is_connected(_on_actor_incapacitated):
		actor.incapacitated.connect(_on_actor_incapacitated)
	if not actor.health_changed.is_connected(_on_actor_health_changed):
		actor.health_changed.connect(_on_actor_health_changed)
	if not actor.state_changed.is_connected(_on_actor_state_changed):
		actor.state_changed.connect(_on_actor_state_changed)
	if not actor.target_changed.is_connected(_on_actor_target_changed):
		actor.target_changed.connect(_on_actor_target_changed)
	actor.bind_combat(self)
	actor_registered.emit(actor)
	_emit_crew_status(actor)
	return true


func unregister_actor(actor: ActorController, unbind_actor: bool = true) -> bool:
	if actor == null or not _actors.has(actor):
		return false
	_ensure_reservation_registry()
	_reservation_registry.release_actor(actor)
	_actors.erase(actor)
	for other: ActorController in _actors:
		other.invalidate_target(actor)
	_disconnect_actor_signals(actor)
	if unbind_actor and is_instance_valid(actor):
		actor.unbind_combat()
	actor_unregistered.emit(actor)
	_refresh_target_indicators()
	return true


func acquire_target(seeker: ActorController) -> ActorController:
	if seeker == null or not _actors.has(seeker) or not seeker.can_act():
		return null
	var nearest_distance: float = INF
	for candidate: ActorController in _actors:
		if not is_valid_target(seeker, candidate):
			continue
		nearest_distance = minf(nearest_distance, seeker.global_position.distance_to(candidate.global_position))
	if nearest_distance == INF:
		return null

	var best_candidate: ActorController = null
	var best_prefers_retaliation: bool = false
	var best_distance: float = INF
	for candidate: ActorController in _actors:
		if not is_valid_target(seeker, candidate):
			continue
		var distance: float = seeker.global_position.distance_to(candidate.global_position)
		if distance > nearest_distance + TARGET_RETALIATION_DISTANCE_MARGIN:
			continue
		var prefers_retaliation: bool = candidate.current_target == seeker
		if (
			best_candidate == null
			or (prefers_retaliation and not best_prefers_retaliation)
			or (prefers_retaliation == best_prefers_retaliation and distance < best_distance)
			or (
				prefers_retaliation == best_prefers_retaliation
				and is_equal_approx(distance, best_distance)
				and candidate.registration_order < best_candidate.registration_order
			)
		):
			best_candidate = candidate
			best_prefers_retaliation = prefers_retaliation
			best_distance = distance
	return best_candidate


func is_valid_target(seeker: ActorController, candidate: ActorController) -> bool:
	return (
		seeker != null
		and candidate != null
		and is_instance_valid(seeker)
		and is_instance_valid(candidate)
		and seeker != candidate
		and _actors.has(seeker)
		and _actors.has(candidate)
		and seeker.team != candidate.team
		and seeker.can_act()
		and candidate.can_be_targeted()
	)


func reserve_attack_position(attacker: ActorController, target: ActorController) -> bool:
	if not is_valid_target(attacker, target) or attacker.attack_definition == null:
		return false
	_ensure_reservation_registry()
	return _reservation_registry.reserve(attacker, target, attacker.attack_definition.attack_range)


func has_attack_position(attacker: ActorController, target: ActorController = null) -> bool:
	_ensure_reservation_registry()
	return _reservation_registry.has_reservation(attacker, target)


func get_attack_position(attacker: ActorController) -> Vector2:
	_ensure_reservation_registry()
	return _reservation_registry.get_world_position(attacker)


func release_attack_position(attacker: ActorController) -> void:
	_ensure_reservation_registry()
	_reservation_registry.release_attacker(attacker)


func request_attack_hit(
	attacker: ActorController,
	target: ActorController,
	attack: AttackDefinition
) -> int:
	if (
		attack == null
		or not is_valid_target(attacker, target)
		or attacker.current_target != target
		or not attacker.is_hitbox_active()
		or not attacker.is_target_in_attack_range(target)
	):
		return 0
	var damage: int = DamageCalculator.calculate_damage(
		attacker.actor_definition.base_damage,
		attacker.actor_definition.damage_multiplier,
		attack.damage_multiplier,
		target.actor_definition.damage_taken_multiplier
	)
	var applied_damage: int = target.receive_damage(damage)
	if applied_damage <= 0:
		return 0
	var hit_direction: float = signf(target.global_position.x - attacker.global_position.x)
	if is_zero_approx(hit_direction):
		hit_direction = attacker.facing_direction
	if target.can_act():
		target.apply_knockback(hit_direction, attack.knockback_force, attack.knockback_duration)
	_hit_stop_remaining = maxf(_hit_stop_remaining, attack.hit_stop_duration)
	hit_landed.emit(attacker, target, applied_damage, target.global_position, attack.hit_stop_duration)
	return applied_damage


func get_live_targets_in_circle(
	team: int,
	world_origin: Vector2,
	range_radius: float
) -> Array[ActorController]:
	var result: Array[ActorController] = []
	if range_radius < 0.0:
		return result
	var radius_squared: float = range_radius * range_radius
	for actor: ActorController in _actors:
		if actor == null:
			continue
		if not is_instance_valid(actor):
			continue
		if actor.is_queued_for_deletion():
			continue
		if actor.team != team or not actor.can_be_targeted():
			continue
		if actor.global_position.distance_squared_to(world_origin) > radius_squared:
			continue
		result.append(actor)
	result.sort_custom(_registration_order_before)
	return result


func request_environmental_hit(
	source_id: StringName,
	target: ActorController,
	world_origin: Vector2,
	base_damage: int,
	knockback_force: float,
	knockback_duration: float,
	knockback_direction_override_x: float = 0.0
) -> int:
	if (
		target == null
		or not is_instance_valid(target)
		or not _actors.has(target)
		or not target.can_be_targeted()
		or target.actor_definition == null
	):
		return 0
	var damage: int = DamageCalculator.calculate_damage(
		base_damage,
		1.0,
		1.0,
		target.actor_definition.damage_taken_multiplier
	)
	var hit_position: Vector2 = target.global_position
	var applied_damage: int = target.receive_damage(damage)
	if applied_damage <= 0:
		return 0
	var hit_direction: float = signf(knockback_direction_override_x)
	if is_zero_approx(hit_direction):
		hit_direction = signf(hit_position.x - world_origin.x)
	if is_zero_approx(hit_direction):
		# Stable fallback for a source and target sharing the same X coordinate.
		hit_direction = -1.0
	if target.can_act():
		target.apply_knockback(hit_direction, knockback_force, knockback_duration)
	environmental_hit_landed.emit(
		source_id,
		target,
		applied_damage,
		hit_position,
		maxf(knockback_force, 0.0)
	)
	return applied_damage


func get_live_count(team: int) -> int:
	var count: int = 0
	for actor: ActorController in _actors:
		if actor.team == team and actor.can_be_targeted():
			count += 1
	return count


func get_live_counts() -> Dictionary:
	return {
		"crew": get_live_count(ActorController.Team.CREW),
		"enemies": get_live_count(ActorController.Team.ENEMY),
		"registered": _actors.size(),
	}


func get_live_actors(team: int) -> Array[ActorController]:
	var result: Array[ActorController] = []
	for actor: ActorController in _actors:
		if actor.team == team and actor.can_be_targeted():
			result.append(actor)
	return result


func get_combat_space() -> CombatSpaceDefinition:
	return combat_space


func get_actor_snapshots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for actor: ActorController in _actors:
		if is_instance_valid(actor):
			result.append(actor.get_snapshot())
	return result


func get_reservation_snapshot() -> Array[Dictionary]:
	_ensure_reservation_registry()
	return _reservation_registry.get_snapshot()


func get_registered_count() -> int:
	return _actors.size()


func get_hit_stop_remaining() -> float:
	return _hit_stop_remaining


func clear_all(queue_free_actors: bool = true) -> void:
	_ensure_reservation_registry()
	var actors_to_clear: Array[ActorController] = _actors.duplicate()
	_actors.clear()
	_reservation_registry.clear_all()
	_hit_stop_remaining = 0.0
	for actor: ActorController in actors_to_clear:
		if not is_instance_valid(actor):
			continue
		_disconnect_actor_signals(actor)
		actor.unbind_combat()
		actor_unregistered.emit(actor)
		if queue_free_actors:
			actor.queue_free()


func _ensure_reservation_registry() -> void:
	if _reservation_registry == null or not is_instance_valid(_reservation_registry):
		_reservation_registry = AttackPositionRegistry.new()
		_reservation_registry.name = "AttackPositionRegistry"
		add_child(_reservation_registry)
	_reservation_registry.configure(combat_space)


func _on_actor_died(dead_actor: ActorController) -> void:
	# Unregistering and invalidating other actors happens synchronously before
	# reward/presentation listeners observe actor_died.
	unregister_actor(dead_actor, true)
	actor_died.emit(dead_actor)


func _on_actor_incapacitated(downed_actor: ActorController) -> void:
	_ensure_reservation_registry()
	_reservation_registry.release_actor(downed_actor)
	for other: ActorController in _actors:
		if other != downed_actor:
			other.invalidate_target(downed_actor)
	actor_incapacitated.emit(downed_actor)
	_emit_crew_status(downed_actor)
	_refresh_target_indicators()


func _on_actor_health_changed(
	actor: ActorController,
	_current_health: int,
	_maximum_health: int
) -> void:
	_emit_crew_status(actor)


func _on_actor_state_changed(
	actor: ActorController,
	_previous_state: int,
	_new_state: int
) -> void:
	_emit_crew_status(actor)


func _on_actor_target_changed(_actor: ActorController, _target: ActorController) -> void:
	_refresh_target_indicators()


func _emit_crew_status(actor: ActorController) -> void:
	if actor == null or actor.team != ActorController.Team.CREW or not actor.is_node_ready():
		return
	crew_status_changed.emit(
		actor,
		actor.health_component.current_health,
		actor.health_component.maximum_health,
		actor.state_machine.current_state
	)


func _refresh_target_indicators() -> void:
	for candidate: ActorController in _actors:
		var is_targeted: bool = false
		for attacker: ActorController in _actors:
			if attacker.current_target == candidate:
				is_targeted = true
				break
		candidate.set_targeted_indicator(is_targeted)


func _disconnect_actor_signals(actor: ActorController) -> void:
	if actor.died.is_connected(_on_actor_died):
		actor.died.disconnect(_on_actor_died)
	if actor.incapacitated.is_connected(_on_actor_incapacitated):
		actor.incapacitated.disconnect(_on_actor_incapacitated)
	if actor.health_changed.is_connected(_on_actor_health_changed):
		actor.health_changed.disconnect(_on_actor_health_changed)
	if actor.state_changed.is_connected(_on_actor_state_changed):
		actor.state_changed.disconnect(_on_actor_state_changed)
	if actor.target_changed.is_connected(_on_actor_target_changed):
		actor.target_changed.disconnect(_on_actor_target_changed)


func _registration_order_before(left: ActorController, right: ActorController) -> bool:
	return left.registration_order < right.registration_order
