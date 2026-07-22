class_name CombatDirector
extends Node

const CombatProjectileType = preload("res://scripts/combat/combat_projectile.gd")

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
signal environmental_collision_landed(
	source_id: StringName,
	source_actor: ActorController,
	target: ActorController,
	damage: int,
	world_position: Vector2,
	impact_force: float
)
signal attack_telegraphed(
	attacker: ActorController,
	attack: AttackDefinition,
	duration_seconds: float,
	world_position: Vector2,
	area_radius: float
)
signal charge_resolved(
	attacker: ActorController,
	target: ActorController,
	damage: int
)
signal area_attack_resolved(
	attacker: ActorController,
	attack: AttackDefinition,
	affected_count: int
)
signal boss_summon_requested(boss: ActorController, actor_ids: Array[StringName])
signal boss_phase_changed(boss: ActorController, phase_id: StringName)
signal projectile_spawned(
	projectile: CombatProjectileType,
	attacker: ActorController,
	attack: AttackDefinition
)
signal projectile_resolved(
	projectile: CombatProjectileType,
	target: ActorController,
	damage: int
)
signal projectile_expired(projectile: CombatProjectileType)
signal status_applied(
	target: ActorController,
	status_id: StringName,
	stacks: int,
	duration_seconds: float,
	source_effect_id: StringName
)

const RESPONSIBILITY: String = "Coordinate encounter-level combat state."
const TARGET_RETALIATION_DISTANCE_MARGIN: float = 18.0
const DEFAULT_COMBAT_SPACE: CombatSpaceDefinition = preload(
	"res://data/combat/downtown_loop_combat_space.tres"
)
const COMBAT_PROJECTILE_SCENE: PackedScene = preload(
	"res://scenes/combat/combat_projectile.tscn"
)
const ENVIRONMENTAL_COLLISION_DAMAGE_PER_FORCE: float = 0.05

@export var combat_space: CombatSpaceDefinition = DEFAULT_COMBAT_SPACE

var _actors: Array[ActorController] = []
var _reservation_registry: AttackPositionRegistry = null
var _next_registration_order: int = 0
var _hit_stop_remaining: float = 0.0
var _synergy_system: SynergySystem
var _random_streams: RunRandomStreams
var _equipment_proc_roll_count: int = 0
var _projectiles: Array[CombatProjectileType] = []
var _next_projectile_order: int = 0
var simulation_enabled: bool = true


func _ready() -> void:
	if combat_space == null:
		combat_space = DEFAULT_COMBAT_SPACE
	_ensure_reservation_registry()


func _physics_process(delta: float) -> void:
	step_simulation(delta)


func step_simulation(delta: float) -> void:
	if not simulation_enabled:
		return
	var simulation_delta: float = maxf(delta, 0.0)
	if simulation_delta <= 0.0:
		return
	if _hit_stop_remaining > 0.0:
		if simulation_delta <= _hit_stop_remaining:
			_hit_stop_remaining -= simulation_delta
			return
		simulation_delta -= _hit_stop_remaining
		_hit_stop_remaining = 0.0
	_step_projectiles(simulation_delta)
	if _hit_stop_remaining > 0.0:
		return

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
	_apply_build_to_actor(actor)
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


func reserve_attack_position_with_range(
	attacker: ActorController,
	target: ActorController,
	maximum_distance: float
) -> bool:
	if not is_valid_target(attacker, target) or maximum_distance <= 0.0:
		return false
	_ensure_reservation_registry()
	return _reservation_registry.reserve(attacker, target, maximum_distance)


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
		or not attacker.is_target_in_attack_range(target, attack)
	):
		return 0
	match attack.delivery_kind:
		AttackDefinition.DeliveryKind.PROJECTILE:
			_spawn_projectile(attacker, target, attack)
			return 0
		AttackDefinition.DeliveryKind.CHARGE:
			return _resolve_charge_attack(attacker, target, attack)
		AttackDefinition.DeliveryKind.AREA:
			return _resolve_area_attack(attacker, attack)
		AttackDefinition.DeliveryKind.SUMMON:
			_request_authored_summon(attacker, attack)
			return 0
		_:
			var total_damage: int = 0
			for _hit_index: int in range(maxi(attack.combo_hit_count, 1)):
				if not is_valid_target(attacker, target):
					break
				total_damage += _resolve_direct_hit(attacker, target, attack)
			return total_damage


func _resolve_direct_hit(
	attacker: ActorController,
	target: ActorController,
	attack: AttackDefinition
) -> int:
	if not is_valid_target(attacker, target) or attack == null:
		return 0
	var build_damage_multiplier: float = 1.0
	if attacker.team == ActorController.Team.CREW and _synergy_system != null:
		if attack.is_heavy():
			build_damage_multiplier += _synergy_system.get_percent_modifier(&"heavy_hit_damage")
		if target.has_status(&"bleed"):
			build_damage_multiplier += _synergy_system.get_percent_modifier(
				&"damage_against_bleeding"
			)
		if target.has_status(&"shock"):
			build_damage_multiplier += _synergy_system.get_percent_modifier(
				&"damage_against_shocked"
			)
		if target.is_knocked_back():
			build_damage_multiplier += _synergy_system.get_percent_modifier(&"knockback_followup")
	var authored_target_multiplier: float = 1.0
	if attacker.actor_definition != null and target.actor_definition != null:
		if target.actor_definition.is_elite():
			authored_target_multiplier = attacker.actor_definition.damage_against_elites_multiplier
		elif target.actor_definition.is_boss():
			authored_target_multiplier = attacker.actor_definition.damage_against_bosses_multiplier
	var damage: int = DamageCalculator.calculate_damage(
		attacker.actor_definition.base_damage,
		(
			attacker.actor_definition.damage_multiplier
			* attacker.get_runtime_damage_multiplier()
			* maxf(build_damage_multiplier, 0.0)
			* maxf(authored_target_multiplier, 0.0)
		),
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
		var knockback_multiplier: float = 1.0
		if attacker.team == ActorController.Team.CREW and _synergy_system != null:
			knockback_multiplier += _synergy_system.get_percent_modifier(&"knockback_distance")
		target.apply_knockback(
			hit_direction,
			attack.knockback_force * maxf(knockback_multiplier, 0.0),
			attack.knockback_duration,
			attack.id,
			attacker
		)
	_apply_triggered_effects(attacker, target, attack)
	_hit_stop_remaining = maxf(_hit_stop_remaining, attack.hit_stop_duration)
	hit_landed.emit(attacker, target, applied_damage, target.global_position, attack.hit_stop_duration)
	return applied_damage


func _resolve_charge_attack(
	attacker: ActorController,
	target: ActorController,
	attack: AttackDefinition
) -> int:
	var direction: Vector2 = attacker.global_position.direction_to(target.global_position)
	if direction.is_zero_approx():
		direction = Vector2(attacker.facing_direction, 0.0)
	var maximum_travel: float = maxf(attack.charge_distance, 0.0)
	var stop_distance: float = 20.0
	var available_travel: float = maxf(
		attacker.global_position.distance_to(target.global_position) - stop_distance,
		0.0
	)
	attacker.global_position = combat_space.clamp_actor_position(
		attacker.global_position + direction * minf(maximum_travel, available_travel)
	)
	var damage: int = _resolve_direct_hit(attacker, target, attack)
	charge_resolved.emit(attacker, target, damage)
	return damage


func _resolve_area_attack(attacker: ActorController, attack: AttackDefinition) -> int:
	var target_team: int = (
		ActorController.Team.ENEMY
		if attacker.team == ActorController.Team.CREW
		else ActorController.Team.CREW
	)
	var targets: Array[ActorController] = get_live_targets_in_circle(
		target_team,
		attacker.global_position,
		maxf(attack.area_radius, 0.0)
	)
	var total_damage: int = 0
	var affected_count: int = 0
	for area_target: ActorController in targets:
		var damage: int = _resolve_direct_hit(attacker, area_target, attack)
		if damage <= 0:
			continue
		total_damage += damage
		affected_count += 1
	area_attack_resolved.emit(attacker, attack, affected_count)
	return total_damage


func _request_authored_summon(attacker: ActorController, attack: AttackDefinition) -> void:
	var stable_ids: Array[StringName] = []
	for actor_id: StringName in attack.summon_actor_ids:
		if actor_id == &"" or stable_ids.has(actor_id):
			continue
		stable_ids.append(actor_id)
	stable_ids.sort_custom(_string_name_before)
	if stable_ids.is_empty():
		return
	boss_summon_requested.emit(attacker, stable_ids)


func notify_attack_telegraph(attacker: ActorController, attack: AttackDefinition) -> void:
	if attacker == null or attack == null or not _actors.has(attacker):
		return
	attack_telegraphed.emit(
		attacker,
		attack,
		maxf(attack.telegraph_seconds, 0.0),
		attacker.global_position,
		maxf(attack.area_radius, 0.0)
	)


func notify_boss_enraged(boss: ActorController) -> void:
	if boss == null or not _actors.has(boss) or not boss.is_boss():
		return
	boss_phase_changed.emit(boss, &"enraged")


func _spawn_projectile(
	attacker: ActorController,
	target: ActorController,
	attack: AttackDefinition
) -> CombatProjectileType:
	if attack.projectile_definition == null or not attack.projectile_definition.is_valid():
		return null
	var projectile: CombatProjectileType = COMBAT_PROJECTILE_SCENE.instantiate() as CombatProjectileType
	if projectile == null:
		return null
	add_child(projectile)
	if not projectile.configure(
		attack.projectile_definition,
		attacker,
		attack,
		attacker.global_position + Vector2(0.0, -24.0),
		target.global_position,
		_next_projectile_order
	):
		projectile.queue_free()
		return null
	_next_projectile_order += 1
	_projectiles.append(projectile)
	projectile_spawned.emit(projectile, attacker, attack)
	return projectile


func _step_projectiles(delta: float) -> void:
	var projectiles_to_step: Array[CombatProjectileType] = _projectiles.duplicate()
	projectiles_to_step.sort_custom(_projectile_order_before)
	for projectile: CombatProjectileType in projectiles_to_step:
		if (
			projectile == null
			or not is_instance_valid(projectile)
			or projectile.is_queued_for_deletion()
			or not _projectiles.has(projectile)
		):
			continue
		var source: ActorController = projectile.source_actor
		if source == null or not is_instance_valid(source) or not _actors.has(source):
			_remove_projectile(projectile, false)
			continue
		var target: ActorController = projectile.step(delta, _actors)
		if target != null:
			var damage: int = _resolve_direct_hit(
				source,
				target,
				projectile.attack_definition
			)
			projectile_resolved.emit(projectile, target, damage)
			_remove_projectile(projectile, true)
			if _hit_stop_remaining > 0.0:
				return
		elif projectile.is_expired():
			_remove_projectile(projectile, false)


func _remove_projectile(projectile: CombatProjectileType, resolved: bool) -> void:
	if projectile == null or not _projectiles.has(projectile):
		return
	_projectiles.erase(projectile)
	if not resolved:
		projectile_expired.emit(projectile)
	if is_instance_valid(projectile):
		projectile.queue_free()


func get_live_projectile_count() -> int:
	return _projectiles.size()


func get_projectile_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var stable_projectiles: Array[CombatProjectileType] = _projectiles.duplicate()
	stable_projectiles.sort_custom(_projectile_order_before)
	for projectile: CombatProjectileType in stable_projectiles:
		if projectile == null or not is_instance_valid(projectile):
			continue
		result.append({
			"spawn_order": projectile.spawn_order,
			"definition_id": (
				projectile.projectile_definition.id
				if projectile.projectile_definition != null
				else &""
			),
			"position": projectile.global_position,
			"remaining_seconds": projectile.remaining_seconds,
		})
	return result


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
	var environmental_damage_multiplier: float = 1.0
	var environmental_knockback_multiplier: float = 1.0
	if _synergy_system != null:
		environmental_damage_multiplier += _synergy_system.get_percent_modifier(
			&"environmental_collision_damage"
		)
		environmental_knockback_multiplier += (
			_synergy_system.get_percent_modifier(&"environmental_knockback")
			+ _synergy_system.get_percent_modifier(&"knockback_distance")
		)
		if target.has_status(&"shock"):
			environmental_damage_multiplier += _synergy_system.get_percent_modifier(
				&"damage_against_shocked"
			)
	var damage: int = DamageCalculator.calculate_damage(
		base_damage,
		maxf(environmental_damage_multiplier, 0.0),
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
		target.apply_knockback(
			hit_direction,
			knockback_force * maxf(environmental_knockback_multiplier, 0.0),
			knockback_duration,
			source_id,
			null
		)
	environmental_hit_landed.emit(
		source_id,
		target,
		applied_damage,
		hit_position,
		maxf(knockback_force * environmental_knockback_multiplier, 0.0)
	)
	return applied_damage


func request_environmental_collision(
	source_id: StringName,
	source_actor: ActorController,
	target: ActorController,
	world_position: Vector2,
	impact_force: float
) -> int:
	if (
		target == null
		or not is_instance_valid(target)
		or not _actors.has(target)
		or not target.can_be_targeted()
		or target.actor_definition == null
		or impact_force <= 0.0
	):
		return 0
	var source_multiplier: float = 1.0
	if source_actor != null and is_instance_valid(source_actor) and source_actor.actor_definition != null:
		source_multiplier *= source_actor.actor_definition.environmental_collision_damage_multiplier
	var build_multiplier: float = 1.0
	if (
		_synergy_system != null
		and source_actor != null
		and is_instance_valid(source_actor)
		and source_actor.team == ActorController.Team.CREW
	):
		build_multiplier += _synergy_system.get_percent_modifier(
			&"environmental_collision_damage"
		)
	var base_damage: int = maxi(
		int(floor(impact_force * ENVIRONMENTAL_COLLISION_DAMAGE_PER_FORCE + 0.5)),
		1
	)
	var damage: int = DamageCalculator.calculate_damage(
		base_damage,
		maxf(source_multiplier * build_multiplier, 0.0),
		1.0,
		target.actor_definition.damage_taken_multiplier
	)
	var applied_damage: int = target.receive_damage(damage)
	if applied_damage <= 0:
		return 0
	environmental_collision_landed.emit(
		source_id,
		source_actor,
		target,
		applied_damage,
		world_position,
		impact_force
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


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled


func configure_build_system(
	synergy_system: SynergySystem,
	random_streams: RunRandomStreams
) -> void:
	if _synergy_system != null and _synergy_system.modifiers_changed.is_connected(
		_on_build_modifiers_changed
	):
		_synergy_system.modifiers_changed.disconnect(_on_build_modifiers_changed)
	_synergy_system = synergy_system
	_random_streams = random_streams
	if _synergy_system != null and not _synergy_system.modifiers_changed.is_connected(
		_on_build_modifiers_changed
	):
		_synergy_system.modifiers_changed.connect(_on_build_modifiers_changed)
	_on_build_modifiers_changed({}, {})


func get_equipment_proc_roll_count() -> int:
	return _equipment_proc_roll_count


func clear_all(queue_free_actors: bool = true) -> void:
	_ensure_reservation_registry()
	var actors_to_clear: Array[ActorController] = _actors.duplicate()
	_actors.clear()
	_reservation_registry.clear_all()
	_hit_stop_remaining = 0.0
	_next_registration_order = 0
	_equipment_proc_roll_count = 0
	_next_projectile_order = 0
	var projectiles_to_clear: Array[CombatProjectileType] = _projectiles.duplicate()
	_projectiles.clear()
	for projectile: CombatProjectileType in projectiles_to_clear:
		if is_instance_valid(projectile):
			projectile.queue_free()
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


func _on_build_modifiers_changed(
	_flat_modifiers: Dictionary,
	_percent_modifiers: Dictionary
) -> void:
	for actor: ActorController in _actors:
		_apply_build_to_actor(actor)


func _apply_build_to_actor(actor: ActorController) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if _synergy_system == null or actor.team != ActorController.Team.CREW:
		var empty_flat: Dictionary[StringName, float] = {}
		var empty_percent: Dictionary[StringName, float] = {}
		actor.apply_build_modifiers(empty_flat, empty_percent)
		return
	actor.apply_build_modifiers(
		_synergy_system.get_flat_modifiers(),
		_synergy_system.get_percent_modifiers()
	)


func _apply_triggered_effects(
	attacker: ActorController,
	target: ActorController,
	attack: AttackDefinition
) -> void:
	if (
		_synergy_system == null
		or attacker == null
		or attacker.team != ActorController.Team.CREW
		or target == null
		or not target.can_be_targeted()
	):
		return
	for effect: TriggeredEffectDefinition in _synergy_system.get_triggered_effects():
		var trigger_matches: bool = effect.trigger == TriggeredEffectDefinition.Trigger.ON_HIT
		if effect.trigger == TriggeredEffectDefinition.Trigger.ON_HEAVY_HIT:
			trigger_matches = attack != null and attack.hit_stop_duration >= 0.06
		if not trigger_matches or not _roll_equipment_proc(effect.chance_basis_points):
			continue
		var duration: float = effect.duration_seconds
		var maximum_stacks_override: int = -1
		if effect.status_id == &"shock":
			duration += _synergy_system.get_flat_modifier(&"shock_duration")
		elif effect.status_id == &"bleed":
			maximum_stacks_override = 3 + maxi(
				int(floor(_synergy_system.get_flat_modifier(&"bleed_maximum_stacks"))),
				0
			)
		if target.apply_status(
			effect.status_id,
			effect.stacks,
			maxf(duration, 0.05),
			maximum_stacks_override
		):
			status_applied.emit(
				target,
				effect.status_id,
				effect.stacks,
				maxf(duration, 0.05),
				effect.id
			)


func _roll_equipment_proc(chance_basis_points: int) -> bool:
	var safe_chance: int = clampi(chance_basis_points, 0, 10000)
	if safe_chance <= 0:
		return false
	if safe_chance >= 10000:
		return true
	if _random_streams == null:
		return false
	_equipment_proc_roll_count += 1
	return _random_streams.draw_index(
		RunRandomStreams.STREAM_EQUIPMENT,
		10000
	) < safe_chance


func _registration_order_before(left: ActorController, right: ActorController) -> bool:
	return left.registration_order < right.registration_order


func _projectile_order_before(left: CombatProjectileType, right: CombatProjectileType) -> bool:
	return left.spawn_order < right.spawn_order


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
