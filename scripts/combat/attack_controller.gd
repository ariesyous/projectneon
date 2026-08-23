class_name AttackController
extends Node

## Timeline component for one attack. It emits the active edge exactly once;
## ActorController maps the phase to state and CombatDirector resolves the hit.

signal phase_changed(previous_phase: int, new_phase: int)
signal active_started()
signal attack_finished()

enum Phase {
	IDLE,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

var current_phase: int = Phase.IDLE
var phase_remaining: float = 0.0
var active_edge_count: int = 0
var _definition: AttackDefinition = null
var _phase_speed_multiplier: float = 1.0


func start_attack(definition: AttackDefinition, phase_speed_multiplier: float = 1.0) -> bool:
	if definition == null or current_phase != Phase.IDLE:
		return false
	_definition = definition
	_phase_speed_multiplier = maxf(phase_speed_multiplier, 0.05)
	active_edge_count = 0
	_set_phase(Phase.WINDUP, _scaled_phase_duration(definition.windup_time))
	_advance_through_zero_length_phases()
	return true


func step(delta: float) -> void:
	if current_phase == Phase.IDLE or _definition == null:
		return
	var unconsumed: float = maxf(delta, 0.0)
	while unconsumed > 0.0 and current_phase != Phase.IDLE:
		if phase_remaining > unconsumed:
			phase_remaining -= unconsumed
			unconsumed = 0.0
		else:
			unconsumed -= phase_remaining
			phase_remaining = 0.0
			_advance_phase()
			_advance_through_zero_length_phases()


func cancel() -> void:
	if current_phase == Phase.IDLE:
		return
	var previous_phase: int = current_phase
	current_phase = Phase.IDLE
	phase_remaining = 0.0
	_definition = null
	_phase_speed_multiplier = 1.0
	phase_changed.emit(previous_phase, current_phase)


func is_attacking() -> bool:
	return current_phase != Phase.IDLE


func is_hitbox_active() -> bool:
	return current_phase == Phase.ACTIVE


func _advance_phase() -> void:
	if _definition == null:
		return
	match current_phase:
		Phase.WINDUP:
			_set_phase(Phase.ACTIVE, maxf(_scaled_phase_duration(_definition.active_time), 0.001))
			active_edge_count += 1
			active_started.emit()
		Phase.ACTIVE:
			_set_phase(Phase.RECOVERY, _scaled_phase_duration(_definition.recovery_time))
		Phase.RECOVERY:
			var previous_phase: int = current_phase
			current_phase = Phase.IDLE
			phase_remaining = 0.0
			_definition = null
			_phase_speed_multiplier = 1.0
			phase_changed.emit(previous_phase, current_phase)
			attack_finished.emit()


func _advance_through_zero_length_phases() -> void:
	var guard: int = 0
	while current_phase != Phase.IDLE and phase_remaining <= 0.0 and guard < 4:
		guard += 1
		_advance_phase()


func _set_phase(new_phase: int, duration: float) -> void:
	var previous_phase: int = current_phase
	current_phase = new_phase
	phase_remaining = duration
	phase_changed.emit(previous_phase, current_phase)


func _scaled_phase_duration(authored_duration: float) -> float:
	return maxf(authored_duration, 0.0) / _phase_speed_multiplier
