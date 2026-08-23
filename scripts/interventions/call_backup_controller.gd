class_name CallBackupController
extends Node

## Run-scoped finite Call Backup authority. Factory/registration/removal
## callbacks keep actor scene ownership external while this controller owns
## validation, tokens, charges, cooldown, lifetime, and exact cleanup.

signal state_changed(snapshot: Dictionary)
signal activation_accepted(
	activation_token: int,
	allies: Array[Node2D],
	charges_remaining: int
)
signal activation_rejected(reason: StringName)
signal ally_removed(
	activation_token: int,
	ally: Node2D,
	reason: StringName
)
signal activation_ended(activation_token: int, reason: StringName)

const STATE_UNAVAILABLE: StringName = &"unavailable"
const STATE_READY: StringName = &"ready"
const STATE_ACTIVE: StringName = &"active"
const STATE_COOLDOWN: StringName = &"cooldown"
const STATE_EXHAUSTED: StringName = &"exhausted"

const REASON_OK: StringName = &"ok"
const REASON_UNCONFIGURED: StringName = &"unconfigured"
const REASON_INVALID_STATE: StringName = &"invalid_state"
const REASON_ALREADY_ACTIVE: StringName = &"already_active"
const REASON_NO_CHARGES: StringName = &"no_charges"
const REASON_COOLDOWN: StringName = &"cooldown"
const REASON_SPAWN_FAILED: StringName = &"spawn_failed"
const REASON_REGISTRATION_FAILED: StringName = &"registration_failed"
const REASON_MALFORMED_REQUEST: StringName = &"malformed_request"
const REASON_STALE_REQUEST: StringName = &"stale_request"
const REASON_REPLAYED_REQUEST: StringName = &"replayed_request"

const END_DURATION_EXPIRED: StringName = &"duration_expired"
const END_ALLIES_DEFEATED: StringName = &"allies_defeated"
const END_TERMINAL: StringName = &"terminal"
const END_RESTART: StringName = &"restart"

const DEFAULT_DEFINITION: CallBackupDefinition = preload(
	"res://data/interventions/milestone_6_call_backup.tres"
)

@export var definition: CallBackupDefinition = DEFAULT_DEFINITION

var simulation_enabled: bool = false
var combat_available: bool = false
var _ally_factory: Callable
var _ally_register_callback: Callable
var _ally_remove_callback: Callable
var _charges_remaining: int = 0
var _cooldown_remaining: float = 0.0
var _cooldown_multiplier: float = 1.0
var _active_duration_remaining: float = 0.0
var _active_token: int = -1
var _last_accepted_token: int = -1
var _next_activation_token: int = 1
var _active_allies: Array[Node2D] = []
var _request_in_progress: bool = false
var _request_context_revision: int = 0
var _request_token: int = -1
var _next_request_token: int = 1
var _consumed_request_tokens: Dictionary[int, bool] = {}
var _last_request_context_signature: String = ""


func _ready() -> void:
	if definition == null:
		definition = DEFAULT_DEFINITION
	set_process(false)
	reset_for_run()


## ally_factory(token, ally_index) -> Node2D
## ally_register_callback(ally) -> bool
## ally_remove_callback(ally, reason) -> void
func configure(
	ally_factory: Callable,
	ally_register_callback: Callable,
	ally_remove_callback: Callable = Callable()
) -> void:
	_ally_factory = ally_factory
	_ally_register_callback = ally_register_callback
	_ally_remove_callback = ally_remove_callback
	_emit_state()


func reset_for_run() -> void:
	_cleanup_active_allies(END_RESTART)
	_charges_remaining = maxi(_get_definition().initial_charges, 0)
	_cooldown_remaining = 0.0
	_active_duration_remaining = 0.0
	_active_token = -1
	_last_accepted_token = -1
	_next_activation_token = 1
	_cooldown_multiplier = 1.0
	_request_in_progress = false
	_last_request_context_signature = ""
	simulation_enabled = false
	combat_available = false
	_refresh_request_context(true)
	_emit_state()


func cleanup_for_terminal_state() -> void:
	_cleanup_active_allies(END_TERMINAL)
	simulation_enabled = false
	combat_available = false
	_emit_state()


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled
	_emit_state()


func set_combat_available(is_available: bool) -> void:
	combat_available = is_available
	_emit_state()


func request_activation(
	expected_context_revision: int = -1,
	request_token: int = -1
) -> bool:
	# The no-argument alias preserves isolated historical M6 fixtures. Production
	# callers always pass the exact published revision/token.
	if expected_context_revision < 0 and request_token < 0:
		expected_context_revision = _request_context_revision
		request_token = _request_token
	elif expected_context_revision < 0 or request_token <= 0:
		activation_rejected.emit(REASON_MALFORMED_REQUEST)
		return false
	if _consumed_request_tokens.has(request_token):
		activation_rejected.emit(REASON_REPLAYED_REQUEST)
		return false
	if (
		expected_context_revision != _request_context_revision
		or request_token != _request_token
	):
		activation_rejected.emit(REASON_STALE_REQUEST)
		return false
	if _request_in_progress:
		activation_rejected.emit(REASON_ALREADY_ACTIVE)
		return false
	var validity: StringName = get_validity_reason()
	if validity != REASON_OK:
		activation_rejected.emit(validity)
		return false
	_request_in_progress = true
	var proposed_token: int = _next_activation_token
	var proposed_allies: Array[Node2D] = []
	for ally_index: int in range(_get_definition().ally_count):
		var ally: Node2D = _ally_factory.call(proposed_token, ally_index) as Node2D
		if ally == null or not is_instance_valid(ally):
			_rollback_proposed_allies(proposed_allies, REASON_SPAWN_FAILED)
			_request_in_progress = false
			activation_rejected.emit(REASON_SPAWN_FAILED)
			return false
		proposed_allies.append(ally)

	for ally: Node2D in proposed_allies:
		var registration_result: Variant = _ally_register_callback.call(ally)
		if not (registration_result is bool) or not bool(registration_result):
			_rollback_proposed_allies(proposed_allies, REASON_REGISTRATION_FAILED)
			_request_in_progress = false
			activation_rejected.emit(REASON_REGISTRATION_FAILED)
			return false

	# Commit only after both allies exist and register successfully. A failed or
	# re-entrant request cannot consume charges, cooldown, or an accepted token.
	_active_token = proposed_token
	_last_accepted_token = proposed_token
	_next_activation_token += 1
	_active_allies = proposed_allies
	_active_duration_remaining = _get_definition().active_combat_duration_seconds
	_charges_remaining -= 1
	_cooldown_remaining = get_cooldown_duration()
	_consumed_request_tokens[request_token] = true
	_request_in_progress = false
	_last_request_context_signature = ""
	_refresh_request_context(true)
	activation_accepted.emit(
		_active_token,
		_active_allies.duplicate(),
		_charges_remaining
	)
	_emit_state()
	return true


## Cooldown uses all eligible active time. The 12-second ally lifetime uses
## eligible combat time only, so pauses, modals, travel, and introductions do
## not consume their promised fighting duration.
func step_eligible_time(delta: float) -> void:
	if not simulation_enabled or delta <= 0.0:
		return
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _active_token >= 0 and combat_available:
		_active_duration_remaining = maxf(_active_duration_remaining - delta, 0.0)
		if _active_duration_remaining <= 0.0:
			_cleanup_active_allies(END_DURATION_EXPIRED)
	_emit_state()


func notify_ally_defeated(ally: Node2D) -> bool:
	if (
		ally == null
		or not is_instance_valid(ally)
		or _active_token < 0
		or not _active_allies.has(ally)
	):
		return false
	var token: int = _active_token
	_active_allies.erase(ally)
	ally_removed.emit(token, ally, END_ALLIES_DEFEATED)
	_remove_ally(ally, END_ALLIES_DEFEATED)
	if _active_allies.is_empty():
		_active_token = -1
		_active_duration_remaining = 0.0
		activation_ended.emit(token, END_ALLIES_DEFEATED)
	_emit_state()
	return true


func get_validity_reason() -> StringName:
	if not _ally_factory.is_valid() or not _ally_register_callback.is_valid():
		return REASON_UNCONFIGURED
	if not simulation_enabled or not combat_available:
		return REASON_INVALID_STATE
	if _request_in_progress or _active_token >= 0:
		return REASON_ALREADY_ACTIVE
	if _charges_remaining <= 0:
		return REASON_NO_CHARGES
	if _cooldown_remaining > 0.0:
		return REASON_COOLDOWN
	return REASON_OK


func can_activate() -> bool:
	return get_validity_reason() == REASON_OK


func get_charges_remaining() -> int:
	return _charges_remaining


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func get_cooldown_duration() -> float:
	return maxf(_get_definition().cooldown_seconds * _cooldown_multiplier, 0.0)


func get_active_duration_remaining() -> float:
	return _active_duration_remaining


func get_active_token() -> int:
	return _active_token


func get_last_accepted_token() -> int:
	return _last_accepted_token


func get_active_allies() -> Array[Node2D]:
	return _active_allies.duplicate()


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
	_emit_state()


func get_snapshot() -> Dictionary:
	var ally_instance_ids: Array[int] = []
	for ally: Node2D in _active_allies:
		if ally != null and is_instance_valid(ally):
			ally_instance_ids.append(ally.get_instance_id())
	return {
		"id": _get_definition().id,
		"display_name": _get_definition().display_name,
		"description": _get_definition().description,
		"state": get_state_name(),
		"validity_reason": get_validity_reason(),
		"can_activate": can_activate(),
		"charges_remaining": _charges_remaining,
		"initial_charges": _get_definition().initial_charges,
		"cooldown_remaining": _cooldown_remaining,
		"cooldown_duration": get_cooldown_duration(),
		"cooldown_multiplier": _cooldown_multiplier,
		"active_token": _active_token,
		"last_accepted_token": _last_accepted_token,
		"next_activation_token": _next_activation_token,
		"request_context_revision": _request_context_revision,
		"request_token": _request_token,
		"active_ally_count": _active_allies.size(),
		"required_ally_count": _get_definition().ally_count,
		"active_ally_instance_ids": ally_instance_ids,
		"active_duration_remaining": _active_duration_remaining,
		"active_duration_seconds": _get_definition().active_combat_duration_seconds,
		"simulation_enabled": simulation_enabled,
		"combat_available": combat_available,
	}


func get_state_name() -> StringName:
	if _active_token >= 0:
		return STATE_ACTIVE
	if _charges_remaining <= 0:
		return STATE_EXHAUSTED
	if _cooldown_remaining > 0.0:
		return STATE_COOLDOWN
	if can_activate():
		return STATE_READY
	return STATE_UNAVAILABLE


func _cleanup_active_allies(reason: StringName) -> void:
	if _active_token < 0 and _active_allies.is_empty():
		return
	var token: int = _active_token
	var allies_to_remove: Array[Node2D] = _active_allies.duplicate()
	_active_allies.clear()
	_active_token = -1
	_active_duration_remaining = 0.0
	for ally: Node2D in allies_to_remove:
		ally_removed.emit(token, ally, reason)
		_remove_ally(ally, reason)
	activation_ended.emit(token, reason)


func _rollback_proposed_allies(
	allies: Array[Node2D],
	reason: StringName
) -> void:
	for ally: Node2D in allies:
		_remove_ally(ally, reason)


func _remove_ally(ally: Node2D, reason: StringName) -> void:
	if ally == null or not is_instance_valid(ally):
		return
	if _ally_remove_callback.is_valid():
		_ally_remove_callback.call(ally, reason)
	elif not ally.is_queued_for_deletion():
		ally.queue_free()


func _emit_state() -> void:
	_refresh_request_context(false)
	state_changed.emit(get_snapshot())


func _refresh_request_context(force: bool) -> void:
	var signature: String = "%s|%d|%d|%s|%s|%s" % [
		get_state_name(),
		_charges_remaining,
		_active_token,
		_cooldown_remaining > 0.0,
		simulation_enabled,
		combat_available,
	]
	if not force and signature == _last_request_context_signature:
		return
	_last_request_context_signature = signature
	_request_context_revision += 1
	_request_token = _next_request_token
	_next_request_token += 1


func _get_definition() -> CallBackupDefinition:
	return definition if definition != null else DEFAULT_DEFINITION
