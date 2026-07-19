class_name FireHydrantController
extends Node

## Run-scoped Fire Hydrant authority. Presentation forwards intent and observes
## state; this component alone validates targets and owns cooldown resolution.

signal state_changed(state: int, cooldown_remaining: float, cooldown_duration: float)
signal activation_resolved(world_origin: Vector2, range_radius: float, affected_count: int)
signal activation_rejected(reason: int)

enum State {
	READY,
	NO_TARGET,
	COOLING_DOWN,
}

enum RejectionReason {
	NO_VALID_TARGET,
	UNAVAILABLE,
}

const DEFAULT_TUNING: FireHydrantTuning = preload(
	"res://data/interventions/milestone_2_fire_hydrant_tuning.tres"
)

@export var tuning: FireHydrantTuning = DEFAULT_TUNING

var _combat_director: CombatDirector
var _activation_origin: Vector2 = Vector2.ZERO
var _cooldown_remaining: float = 0.0
var _activation_locked: bool = false
var _request_in_progress: bool = false
var _last_emitted_state: int = -1
var _last_emitted_cooldown: float = -1.0
var _last_emitted_valid_target_count: int = -1
var _cooldown_multiplier: float = 1.0
var simulation_enabled: bool = true


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING
	_emit_state_if_changed(true)


func _process(delta: float) -> void:
	if simulation_enabled:
		step_cooldown(delta)


func configure(combat_director: CombatDirector, activation_origin: Vector2) -> void:
	_combat_director = combat_director
	_activation_origin = activation_origin
	_cooldown_remaining = 0.0
	_activation_locked = false
	_request_in_progress = false
	_emit_state_if_changed(true)


func reset_for_run() -> void:
	_cooldown_remaining = 0.0
	_activation_locked = false
	_request_in_progress = false
	_emit_state_if_changed(true)


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled


func request_activation() -> bool:
	if _request_in_progress:
		return false
	_request_in_progress = true
	if _activation_locked or _cooldown_remaining > 0.0 or _combat_director == null:
		activation_rejected.emit(RejectionReason.UNAVAILABLE)
		_request_in_progress = false
		return false

	var targets: Array[ActorController] = _combat_director.get_live_targets_in_circle(
		ActorController.Team.ENEMY,
		_activation_origin,
		_get_tuning().range_radius
	)
	if targets.is_empty():
		activation_rejected.emit(RejectionReason.NO_VALID_TARGET)
		_request_in_progress = false
		_emit_state_if_changed(true)
		return false

	# Lock availability before any combat or presentation callback can issue a
	# second request in the same authoritative activation.
	_activation_locked = true
	_cooldown_remaining = get_cooldown_duration()
	_emit_state_if_changed(true)

	var affected_count: int = 0
	for target: ActorController in targets:
		var applied_damage: int = _combat_director.request_environmental_hit(
			_get_tuning().id,
			target,
			_activation_origin,
			_get_tuning().damage,
			_get_tuning().knockback_force,
			_get_tuning().knockback_duration,
			_get_tuning().knockback_direction_x
		)
		if applied_damage > 0:
			affected_count += 1

	activation_resolved.emit(
		_activation_origin,
		_get_tuning().range_radius,
		affected_count
	)
	_activation_locked = false
	_request_in_progress = false
	_emit_state_if_changed(true)
	return true


func step_cooldown(delta: float) -> void:
	var previous_cooldown: float = _cooldown_remaining
	if delta > 0.0 and _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	_emit_state_if_changed(not is_equal_approx(previous_cooldown, _cooldown_remaining))


func get_state() -> int:
	if _activation_locked or _cooldown_remaining > 0.0:
		return State.COOLING_DOWN
	return State.READY if get_valid_target_count() > 0 else State.NO_TARGET


func can_activate() -> bool:
	return get_state() == State.READY and not _request_in_progress


func has_valid_target() -> bool:
	return get_valid_target_count() > 0


func get_valid_target_count() -> int:
	if _combat_director == null:
		return 0
	return _combat_director.get_live_targets_in_circle(
		ActorController.Team.ENEMY,
		_activation_origin,
		_get_tuning().range_radius
	).size()


func set_activation_origin(world_origin: Vector2) -> void:
	_activation_origin = world_origin
	_emit_state_if_changed(true)


func get_activation_origin() -> Vector2:
	return _activation_origin


func get_range_radius() -> float:
	return _get_tuning().range_radius


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func get_cooldown_duration() -> float:
	return maxf(_get_tuning().cooldown_seconds * _cooldown_multiplier, 0.0)


func set_cooldown_multiplier(multiplier: float) -> void:
	var previous_duration: float = get_cooldown_duration()
	var remaining_ratio: float = (
		clampf(_cooldown_remaining / previous_duration, 0.0, 1.0)
		if previous_duration > 0.0
		else 0.0
	)
	_cooldown_multiplier = maxf(multiplier, 0.05)
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = get_cooldown_duration() * remaining_ratio
	_emit_state_if_changed(true)


func get_snapshot() -> Dictionary:
	var state: int = get_state()
	var valid_target_count: int = get_valid_target_count()
	return {
		"state": state,
		"state_name": state_name(state),
		"can_activate": can_activate(),
		"has_valid_target": valid_target_count > 0,
		"valid_target_count": valid_target_count,
		"cooldown_remaining": _cooldown_remaining,
		"cooldown_duration": get_cooldown_duration(),
		"cooldown_multiplier": _cooldown_multiplier,
		"range_radius": get_range_radius(),
		"activation_origin": _activation_origin,
	}


static func state_name(state: int) -> String:
	match state:
		State.READY:
			return "READY"
		State.NO_TARGET:
			return "NO_TARGET"
		State.COOLING_DOWN:
			return "COOLING_DOWN"
	return "UNKNOWN"


func _emit_state_if_changed(force: bool) -> void:
	var state: int = get_state()
	var valid_target_count: int = get_valid_target_count()
	if (
		not force
		and state == _last_emitted_state
		and is_equal_approx(_cooldown_remaining, _last_emitted_cooldown)
		and valid_target_count == _last_emitted_valid_target_count
	):
		return
	_last_emitted_state = state
	_last_emitted_cooldown = _cooldown_remaining
	_last_emitted_valid_target_count = valid_target_count
	state_changed.emit(state, _cooldown_remaining, get_cooldown_duration())


func _get_tuning() -> FireHydrantTuning:
	return tuning if tuning != null else DEFAULT_TUNING
