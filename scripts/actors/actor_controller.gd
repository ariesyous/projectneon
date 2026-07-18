class_name ActorController
extends Node2D

## Generic definition-backed automatic combat actor. The scene composes state,
## health, attack timing, logical hitbox, and replaceable presentation nodes.

signal state_changed(actor: ActorController, previous_state: int, new_state: int)
signal target_changed(actor: ActorController, target: ActorController)
signal health_changed(actor: ActorController, current_health: int, maximum_health: int)
signal died(actor: ActorController)
signal incapacitated(actor: ActorController)

enum Team {
	CREW,
	ENEMY,
}

const DEFAULT_COMBAT_SPACE: CombatSpaceDefinition = preload(
	"res://data/combat/downtown_loop_combat_space.tres"
)
const POSITION_ARRIVAL_TOLERANCE: float = 2.0

@export var actor_definition: ActorDefinition
@export var attack_definition: AttackDefinition
@export var team: int = Team.ENEMY
@export_range(0, 2, 1) var initial_lane: int = 1

@onready var state_machine: ActorStateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var attack_controller: AttackController = $AttackController
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var actor_visual: ActorVisual = $ActorVisual

var combat_coordinator: Node = null
var combat_space: CombatSpaceDefinition = DEFAULT_COMBAT_SPACE
var current_target: ActorController = null
var registration_order: int = -1
var lane_index: int = 1
var facing_direction: float = 1.0
var _attack_cooldown_remaining: float = 0.0
var _knockback_remaining: float = 0.0
var _knockback_velocity_x: float = 0.0
var _stun_remaining: float = 0.0
var _cleanup_remaining: float = 0.0
var _runtime_initialized: bool = false
var _runtime_health_multiplier: float = 1.0
var _runtime_damage_multiplier: float = 1.0


func _ready() -> void:
	state_machine.state_changed.connect(_on_state_machine_changed)
	health_component.health_changed.connect(_on_health_component_changed)
	health_component.depleted.connect(_on_health_depleted)
	attack_controller.phase_changed.connect(_on_attack_phase_changed)
	attack_controller.active_started.connect(_on_attack_active_started)
	attack_controller.attack_finished.connect(_on_attack_finished)
	attack_hitbox.monitorable = false
	attack_hitbox.monitoring = false
	lane_index = clampi(initial_lane, 0, 2)
	global_position.y = combat_space.lane_y(lane_index)
	global_position = combat_space.clamp_actor_position(global_position)
	_refresh_lane_depth()
	initialize_runtime()
	set_process(false)
	if combat_coordinator != null:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func initialize_runtime() -> void:
	if _runtime_initialized:
		return
	if actor_definition == null:
		push_error("ActorController '%s' requires an ActorDefinition." % name)
		return
	if attack_definition == null:
		push_error("ActorController '%s' requires an AttackDefinition." % name)
		return
	_runtime_initialized = true
	var scaled_maximum_health: int = maxi(
		int(floor(float(actor_definition.maximum_health) * _runtime_health_multiplier + 0.5)),
		1
	)
	health_component.initialize(scaled_maximum_health)
	actor_visual.set_health(health_component.current_health, health_component.maximum_health)
	actor_visual.set_state(state_machine.current_state)
	actor_visual.set_facing(facing_direction)


func configure_combat_space(definition: CombatSpaceDefinition) -> void:
	combat_space = definition if definition != null else DEFAULT_COMBAT_SPACE
	lane_index = clampi(lane_index, 0, maxi(combat_space.lane_count() - 1, 0))
	global_position = combat_space.clamp_actor_position(global_position)
	if not is_node_ready():
		return
	_refresh_lane_from_position()


func configure_runtime_scaling(health_multiplier: float, damage_multiplier: float) -> void:
	if _runtime_initialized:
		return
	_runtime_health_multiplier = maxf(health_multiplier, 0.0)
	_runtime_damage_multiplier = maxf(damage_multiplier, 0.0)


func get_runtime_damage_multiplier() -> float:
	return _runtime_damage_multiplier


func get_combat_space() -> CombatSpaceDefinition:
	return combat_space


func bind_combat(coordinator: Node) -> void:
	combat_coordinator = coordinator
	if is_node_ready() and can_act():
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func unbind_combat() -> void:
	clear_target()
	combat_coordinator = null
	if is_node_ready() and can_act():
		state_machine.transition_to(ActorStateMachine.State.IDLE)


func step_simulation(delta: float) -> void:
	if not _runtime_initialized or delta <= 0.0 or state_machine.is_terminal():
		return
	state_machine.advance_time(delta)
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)

	if _knockback_remaining > 0.0:
		_step_knockback(delta)
		return
	if _stun_remaining > 0.0:
		_step_stun(delta)
		return

	if current_target != null and not _coordinator_target_is_valid(current_target):
		clear_target()
		attack_controller.cancel()

	if attack_controller.is_attacking():
		attack_controller.step(delta)
		return

	if current_target == null:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)
		_acquire_target()
		if current_target == null:
			return

	if not _has_attack_position():
		if not _reserve_attack_position():
			state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)
			return

	var destination: Vector2 = _get_attack_position()
	if destination == Vector2.INF:
		_release_attack_position()
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)
		return
	face_toward(current_target.global_position.x)
	if global_position.distance_to(destination) > POSITION_ARRIVAL_TOLERANCE:
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
		global_position = global_position.move_toward(destination, actor_definition.movement_speed * delta)
		global_position = combat_space.clamp_actor_position(global_position)
		_refresh_lane_from_position()
		return
	global_position = combat_space.clamp_actor_position(destination)
	_refresh_lane_from_position()

	if not is_target_in_attack_range(current_target):
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
		return
	if _attack_cooldown_remaining <= 0.0:
		attack_controller.start_attack(attack_definition)
	else:
		state_machine.transition_to(ActorStateMachine.State.IDLE)


func assign_target(target: ActorController) -> bool:
	if target == current_target:
		return target != null
	if target != null and not _coordinator_target_is_valid(target):
		return false
	_release_attack_position()
	current_target = target
	actor_visual.set_has_target(current_target != null)
	if current_target != null:
		face_toward(current_target.global_position.x)
		target_changed.emit(self, current_target)
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
	else:
		target_changed.emit(self, null)
		if can_act():
			state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)
	return true


func invalidate_target(invalid_actor: ActorController) -> void:
	if current_target == invalid_actor:
		attack_controller.cancel()
		clear_target()


func clear_target() -> void:
	_release_attack_position()
	if current_target == null:
		return
	current_target = null
	actor_visual.set_has_target(false)
	target_changed.emit(self, null)


func receive_damage(amount: int) -> int:
	if not can_be_targeted():
		return 0
	var applied_damage: int = health_component.apply_damage(maxi(amount, 0))
	if applied_damage > 0:
		actor_visual.play_hit_flash()
	return applied_damage


func apply_knockback(direction_x: float, force: float, duration: float) -> void:
	if not can_act() or force <= 0.0 or duration <= 0.0:
		return
	var resistance: float = clampf(actor_definition.knockback_resistance, 0.0, 1.0)
	_knockback_velocity_x = (-1.0 if direction_x < 0.0 else 1.0) * force * (1.0 - resistance)
	_knockback_remaining = duration
	attack_controller.cancel()
	_release_attack_position()
	state_machine.transition_to(ActorStateMachine.State.KNOCKED_BACK)


func apply_stun(duration: float) -> void:
	if not can_act() or duration <= 0.0:
		return
	_stun_remaining = maxf(_stun_remaining, duration)
	attack_controller.cancel()
	_release_attack_position()
	state_machine.transition_to(ActorStateMachine.State.STUNNED)


func can_act() -> bool:
	return (
		_runtime_initialized
		and not health_component.is_depleted()
		and not state_machine.is_terminal()
	)


func can_be_targeted() -> bool:
	return can_act() and not is_queued_for_deletion()


func is_target_in_attack_range(target: ActorController) -> bool:
	if target == null or not is_instance_valid(target) or attack_definition == null:
		return false
	return global_position.distance_to(target.global_position) <= attack_definition.attack_range


func is_hitbox_active() -> bool:
	return (
		state_machine.current_state == ActorStateMachine.State.ATTACK_ACTIVE
		and attack_controller.is_hitbox_active()
		and attack_hitbox.monitoring
	)


func set_targeted_indicator(is_targeted: bool) -> void:
	actor_visual.set_targeted(is_targeted)


func face_toward(world_x: float) -> void:
	if is_equal_approx(world_x, global_position.x):
		return
	facing_direction = -1.0 if world_x < global_position.x else 1.0
	actor_visual.set_facing(facing_direction)
	attack_hitbox.position.x = 18.0 * facing_direction


func definition_id() -> StringName:
	return actor_definition.id if actor_definition != null else &"missing"


func authored_coin_value() -> int:
	if actor_definition == null or not actor_definition.grants_coin_reward:
		return 0
	return maxi(actor_definition.authored_coin_value, 0)


func grants_coin_reward() -> bool:
	return actor_definition != null and actor_definition.grants_coin_reward


func get_state_name() -> String:
	return ActorStateMachine.state_name(state_machine.current_state)


func get_snapshot() -> Dictionary:
	return {
		"instance_id": get_instance_id(),
		"registration_order": registration_order,
		"definition_id": definition_id(),
		"display_name": actor_definition.display_name if actor_definition != null else String(name),
		"team": team,
		"state": state_machine.current_state,
		"state_name": get_state_name(),
		"current_health": health_component.current_health,
		"maximum_health": health_component.maximum_health,
		"runtime_health_multiplier": _runtime_health_multiplier,
		"runtime_damage_multiplier": _runtime_damage_multiplier,
		"lane": lane_index,
		"target_instance_id": current_target.get_instance_id() if current_target != null else -1,
		"position": global_position,
		"hitbox_active": is_hitbox_active(),
	}


static func lane_y(requested_lane: int) -> float:
	# Compatibility seam for callers that do not yet hold the run-scoped
	# director. Runtime actors use their configured CombatSpaceDefinition.
	return DEFAULT_COMBAT_SPACE.lane_y(requested_lane)


func _acquire_target() -> void:
	if combat_coordinator == null or not combat_coordinator.has_method("acquire_target"):
		return
	var candidate: Variant = combat_coordinator.call("acquire_target", self)
	if candidate is ActorController:
		assign_target(candidate as ActorController)


func _coordinator_target_is_valid(target: ActorController) -> bool:
	if combat_coordinator == null or not combat_coordinator.has_method("is_valid_target"):
		return false
	return bool(combat_coordinator.call("is_valid_target", self, target))


func _reserve_attack_position() -> bool:
	if combat_coordinator == null or not combat_coordinator.has_method("reserve_attack_position"):
		return false
	return bool(combat_coordinator.call("reserve_attack_position", self, current_target))


func _has_attack_position() -> bool:
	if combat_coordinator == null or not combat_coordinator.has_method("has_attack_position"):
		return false
	return bool(combat_coordinator.call("has_attack_position", self, current_target))


func _get_attack_position() -> Vector2:
	if combat_coordinator == null or not combat_coordinator.has_method("get_attack_position"):
		return Vector2.INF
	var result: Variant = combat_coordinator.call("get_attack_position", self)
	return result as Vector2 if result is Vector2 else Vector2.INF


func _release_attack_position() -> void:
	if combat_coordinator != null and combat_coordinator.has_method("release_attack_position"):
		combat_coordinator.call("release_attack_position", self)


func _step_knockback(delta: float) -> void:
	var applied_time: float = minf(delta, _knockback_remaining)
	global_position = combat_space.clamp_actor_position(
		global_position + Vector2(_knockback_velocity_x * applied_time, 0.0)
	)
	_knockback_remaining = maxf(_knockback_remaining - delta, 0.0)
	_knockback_velocity_x = move_toward(_knockback_velocity_x, 0.0, 500.0 * delta)
	if _knockback_remaining <= 0.0:
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)


func _step_stun(delta: float) -> void:
	_stun_remaining = maxf(_stun_remaining - delta, 0.0)
	if _stun_remaining <= 0.0:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func _refresh_lane_from_position() -> void:
	lane_index = combat_space.nearest_lane_index(global_position.y)
	_refresh_lane_depth()


func _refresh_lane_depth() -> void:
	z_index = int(combat_space.lane_y(lane_index))


func _on_attack_phase_changed(_previous_phase: int, new_phase: int) -> void:
	match new_phase:
		AttackController.Phase.WINDUP:
			state_machine.transition_to(ActorStateMachine.State.ATTACK_WINDUP)
		AttackController.Phase.ACTIVE:
			state_machine.transition_to(ActorStateMachine.State.ATTACK_ACTIVE)
		AttackController.Phase.RECOVERY:
			state_machine.transition_to(ActorStateMachine.State.ATTACK_RECOVERY)
		AttackController.Phase.IDLE:
			_set_hitbox_active(false)


func _on_attack_active_started() -> void:
	if combat_coordinator == null or not combat_coordinator.has_method("request_attack_hit"):
		return
	combat_coordinator.call("request_attack_hit", self, current_target, attack_definition)


func _on_attack_finished() -> void:
	_attack_cooldown_remaining = attack_definition.cooldown_time
	if current_target != null:
		state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
	else:
		state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)


func _on_state_machine_changed(previous_state: int, new_state: int) -> void:
	_set_hitbox_active(new_state == ActorStateMachine.State.ATTACK_ACTIVE)
	actor_visual.set_state(new_state)
	state_changed.emit(self, previous_state, new_state)


func _set_hitbox_active(is_active: bool) -> void:
	attack_hitbox.monitoring = is_active


func _on_health_component_changed(current_health: int, maximum_health: int) -> void:
	actor_visual.set_health(current_health, maximum_health)
	health_changed.emit(self, current_health, maximum_health)


func _on_health_depleted() -> void:
	attack_controller.cancel()
	clear_target()
	if team == Team.CREW:
		state_machine.transition_to(ActorStateMachine.State.INCAPACITATED)
		incapacitated.emit(self)
	else:
		state_machine.transition_to(ActorStateMachine.State.DEAD)
		_cleanup_remaining = actor_definition.cleanup_delay
		set_process(true)
		died.emit(self)


func _process(delta: float) -> void:
	if state_machine.current_state != ActorStateMachine.State.DEAD:
		return
	_cleanup_remaining -= maxf(delta, 0.0)
	if _cleanup_remaining <= 0.0:
		queue_free()
