class_name ActorStateMachine
extends Node

## Explicit, animation-independent state authority for one actor.

signal state_changed(previous_state: int, new_state: int)

enum State {
	IDLE,
	PATROLLING,
	ACQUIRING_TARGET,
	APPROACHING_TARGET,
	ATTACK_WINDUP,
	ATTACK_ACTIVE,
	ATTACK_RECOVERY,
	STUNNED,
	KNOCKED_BACK,
	INCAPACITATED,
	DEAD,
}

var current_state: int = State.IDLE
var state_elapsed: float = 0.0


func transition_to(new_state: int) -> bool:
	if new_state < State.IDLE or new_state > State.DEAD:
		push_error("ActorStateMachine rejected unknown state %d." % new_state)
		return false
	if current_state == State.DEAD:
		return false
	if current_state == State.INCAPACITATED and new_state != State.DEAD:
		return false
	if current_state == new_state:
		return false
	var previous_state: int = current_state
	current_state = new_state
	state_elapsed = 0.0
	state_changed.emit(previous_state, current_state)
	return true


func force_initial_state(new_state: int) -> void:
	current_state = clampi(new_state, State.IDLE, State.DEAD)
	state_elapsed = 0.0


func advance_time(delta: float) -> void:
	state_elapsed += maxf(delta, 0.0)


func is_terminal() -> bool:
	return current_state == State.INCAPACITATED or current_state == State.DEAD


static func state_name(state: int) -> String:
	match state:
		State.IDLE:
			return "IDLE"
		State.PATROLLING:
			return "PATROLLING"
		State.ACQUIRING_TARGET:
			return "ACQUIRING_TARGET"
		State.APPROACHING_TARGET:
			return "APPROACHING_TARGET"
		State.ATTACK_WINDUP:
			return "ATTACK_WINDUP"
		State.ATTACK_ACTIVE:
			return "ATTACK_ACTIVE"
		State.ATTACK_RECOVERY:
			return "ATTACK_RECOVERY"
		State.STUNNED:
			return "STUNNED"
		State.KNOCKED_BACK:
			return "KNOCKED_BACK"
		State.INCAPACITATED:
			return "INCAPACITATED"
		State.DEAD:
			return "DEAD"
	return "UNKNOWN"
