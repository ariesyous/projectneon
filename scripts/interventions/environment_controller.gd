class_name EnvironmentController
extends Node

## Production WP05 Environment authority. One authored encounter context picks
## Hydrant or Power Box; both share one caller revision/token and cooldown
## ledger. World/HUD surfaces only forward the exact published context.

signal state_changed(snapshot: Dictionary)
signal context_changed(
	previous_action_id: StringName,
	new_action_id: StringName,
	context_revision: int
)
signal activation_accepted(
	action_id: StringName,
	request_token: int,
	result: Dictionary
)
signal activation_rejected(action_id: StringName, reason: StringName)

const ACTION_HYDRANT: StringName = &"fire_hydrant"
const ACTION_POWER_BOX: StringName = &"power_box"

const REASON_OK: StringName = &"ok"
const REASON_UNCONFIGURED: StringName = &"unconfigured"
const REASON_INVALID_STATE: StringName = &"invalid_state"
const REASON_NO_CONTEXT: StringName = &"no_environment_context"
const REASON_WRONG_ACTION: StringName = &"wrong_context_action"
const REASON_NO_TARGET: StringName = &"no_valid_target"
const REASON_NO_INTERRUPT: StringName = &"no_interruptible_intent"
const REASON_COOLDOWN: StringName = &"cooldown"
const REASON_MALFORMED: StringName = &"malformed_request"
const REASON_STALE: StringName = &"stale_context"
const REASON_REPLAYED: StringName = &"replayed_request"
const REASON_REQUEST_ACTIVE: StringName = &"request_in_progress"

const DEFAULT_POWER_BOX: PowerBoxDefinition = preload(
	"res://data/interventions/wp05_power_box.tres"
)

@export var power_box_definition: PowerBoxDefinition = DEFAULT_POWER_BOX

var simulation_enabled: bool = false
var combat_available: bool = false

var _combat_director: CombatDirector
var _hydrant_controller: FireHydrantController
var _hydrant_origin: Vector2 = Vector2.ZERO
var _power_box_origin: Vector2 = Vector2.ZERO
var _current_action_id: StringName = &""
var _shared_cooldown_remaining: float = 0.0
var _cooldown_source_action_id: StringName = &""
var _cooldown_multiplier: float = 1.0
var _request_in_progress: bool = false
var _context_revision: int = 0
var _request_token: int = -1
var _next_request_token: int = 1
var _consumed_request_tokens: Dictionary[int, bool] = {}
var _last_context_signature: String = ""


func _ready() -> void:
	if power_box_definition == null:
		power_box_definition = DEFAULT_POWER_BOX
	_refresh_context(true)


func _process(delta: float) -> void:
	step_eligible_time(delta)


func configure(
	combat_director: CombatDirector,
	hydrant_controller: FireHydrantController,
	hydrant_origin: Vector2,
	power_box_origin: Vector2
) -> bool:
	_combat_director = combat_director
	_hydrant_controller = hydrant_controller
	_hydrant_origin = hydrant_origin
	_power_box_origin = power_box_origin
	if _hydrant_controller != null and not _hydrant_controller.state_changed.is_connected(
		_on_hydrant_state_changed
	):
		_hydrant_controller.state_changed.connect(_on_hydrant_state_changed)
	_refresh_context(true)
	return (
		_combat_director != null
		and _hydrant_controller != null
		and power_box_definition != null
		and power_box_definition.validation_errors().is_empty()
	)


func reset_for_run() -> void:
	_shared_cooldown_remaining = 0.0
	_cooldown_source_action_id = &""
	_cooldown_multiplier = 1.0
	_request_in_progress = false
	simulation_enabled = false
	combat_available = false
	set_context_action(&"")
	_refresh_context(true)


func cleanup_for_terminal_state() -> void:
	_request_in_progress = false
	simulation_enabled = false
	combat_available = false
	set_context_action(&"")
	_refresh_context(true)


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled
	_refresh_context(false)


func set_combat_available(is_available: bool) -> void:
	combat_available = is_available
	_refresh_context(false)


func set_context_action(action_id: StringName) -> bool:
	if action_id not in [&"", ACTION_HYDRANT, ACTION_POWER_BOX]:
		return false
	if action_id == _current_action_id:
		return true
	var previous_action_id: StringName = _current_action_id
	_current_action_id = action_id
	_last_context_signature = ""
	_refresh_context(true)
	context_changed.emit(previous_action_id, _current_action_id, _context_revision)
	return true


func step_eligible_time(delta: float) -> void:
	if not simulation_enabled or delta <= 0.0:
		return
	var previous_cooldown: float = _shared_cooldown_remaining
	_shared_cooldown_remaining = maxf(_shared_cooldown_remaining - delta, 0.0)
	_refresh_context(
		previous_cooldown > 0.0 and _shared_cooldown_remaining <= 0.0
	)


func request_activation(
	action_id: StringName,
	expected_context_revision: int,
	request_token: int
) -> Dictionary:
	var request_validation: StringName = _validate_request_context(
		action_id,
		expected_context_revision,
		request_token
	)
	if request_validation != REASON_OK:
		return _reject(action_id, request_validation)
	var validity: StringName = get_validity_reason()
	if validity != REASON_OK:
		return _reject(action_id, validity)
	_request_in_progress = true
	var result: Dictionary = {}
	if action_id == ACTION_HYDRANT:
		var affected_count: int = _hydrant_controller.get_valid_target_count()
		if not _hydrant_controller.request_activation():
			_request_in_progress = false
			return _reject(action_id, get_validity_reason())
		result = {
			"affected_count": affected_count,
			"interrupted_count": 0,
			"status_count": affected_count,
			"damage_each": _hydrant_controller.tuning.damage,
		}
	else:
		result = _resolve_power_box()
		if int(result.get("affected_count", 0)) <= 0:
			_request_in_progress = false
			return _reject(action_id, REASON_NO_TARGET)

	_consumed_request_tokens[request_token] = true
	_cooldown_source_action_id = action_id
	_shared_cooldown_remaining = get_cooldown_duration_for(_cooldown_source_action_id)
	_request_in_progress = false
	_last_context_signature = ""
	_refresh_context(true)
	activation_accepted.emit(action_id, request_token, result.duplicate(true))
	return {
		"accepted": true,
		"reason": REASON_OK,
		"action_id": action_id,
		"request_token": request_token,
		"result": result.duplicate(true),
	}


func get_validity_reason() -> StringName:
	if (
		_combat_director == null
		or _hydrant_controller == null
		or power_box_definition == null
		or not power_box_definition.validation_errors().is_empty()
	):
		return REASON_UNCONFIGURED
	if not simulation_enabled or not combat_available:
		return REASON_INVALID_STATE
	if _current_action_id == &"":
		return REASON_NO_CONTEXT
	if _request_in_progress:
		return REASON_REQUEST_ACTIVE
	if _shared_cooldown_remaining > 0.0:
		return REASON_COOLDOWN
	if _current_action_id == ACTION_HYDRANT:
		if _hydrant_controller.get_state() == FireHydrantController.State.COOLING_DOWN:
			return REASON_COOLDOWN
		return REASON_OK if _hydrant_controller.has_valid_target() else REASON_NO_TARGET
	if _power_box_targets().is_empty():
		return REASON_NO_TARGET
	return REASON_OK if not _power_box_interruptible_targets().is_empty() else REASON_NO_INTERRUPT


func can_activate() -> bool:
	return get_validity_reason() == REASON_OK


func get_current_action_id() -> StringName:
	return _current_action_id


func get_context_revision() -> int:
	return _context_revision


func get_request_token() -> int:
	return _request_token


func get_shared_cooldown_remaining() -> float:
	return _shared_cooldown_remaining


func get_cooldown_duration_for(action_id: StringName) -> float:
	if action_id == ACTION_HYDRANT and _hydrant_controller != null:
		return _hydrant_controller.get_cooldown_duration()
	if action_id == ACTION_POWER_BOX and power_box_definition != null:
		return maxf(power_box_definition.cooldown_seconds * _cooldown_multiplier, 0.0)
	return 0.0


func set_cooldown_multiplier(multiplier: float) -> void:
	var duration_action_id: StringName = (
		_cooldown_source_action_id
		if _shared_cooldown_remaining > 0.0
		else _current_action_id
	)
	var previous_duration: float = get_cooldown_duration_for(duration_action_id)
	var remaining_ratio: float = (
		clampf(_shared_cooldown_remaining / previous_duration, 0.0, 1.0)
		if previous_duration > 0.0
		else 0.0
	)
	_cooldown_multiplier = maxf(multiplier, 0.05)
	if _hydrant_controller != null:
		_hydrant_controller.set_cooldown_multiplier(_cooldown_multiplier)
	if _shared_cooldown_remaining > 0.0:
		_shared_cooldown_remaining = (
			get_cooldown_duration_for(duration_action_id) * remaining_ratio
		)
	_refresh_context(true)


func get_snapshot() -> Dictionary:
	var validity: StringName = get_validity_reason()
	var displayed_cooldown_action_id: StringName = (
		_cooldown_source_action_id
		if _shared_cooldown_remaining > 0.0
		else _current_action_id
	)
	var action_name: String = "NO CONTEXT"
	var verb: String = "UNAVAILABLE"
	var icon: Texture2D
	var origin: Vector2 = Vector2.ZERO
	var radius: float = 0.0
	var description: String = "No Environment action is available."
	if _current_action_id == ACTION_HYDRANT and _hydrant_controller != null:
		action_name = _hydrant_controller.tuning.display_name
		verb = "BLAST HYDRANT"
		origin = _hydrant_origin
		radius = _hydrant_controller.get_range_radius()
		description = "18 damage, strong left knockback, and Wet in the marked area."
	elif _current_action_id == ACTION_POWER_BOX and power_box_definition != null:
		action_name = power_box_definition.display_name
		verb = power_box_definition.contextual_verb
		icon = power_box_definition.icon
		origin = _power_box_origin
		radius = power_box_definition.range_radius
		description = power_box_definition.description
	return {
		"action_id": _current_action_id,
		"display_name": action_name,
		"verb": verb,
		"description": description,
		"icon": icon,
		"context_revision": _context_revision,
		"request_token": _request_token,
		"validity_reason": validity,
		"can_activate": validity == REASON_OK,
		"target_count": _valid_target_count(),
		"interruptible_target_count": _power_box_interruptible_targets().size(),
		"cooldown_remaining": _shared_cooldown_remaining,
		"cooldown_duration": get_cooldown_duration_for(displayed_cooldown_action_id),
		"cooldown_source_action_id": _cooldown_source_action_id,
		"cooldown_multiplier": _cooldown_multiplier,
		"world_origin": origin,
		"range_radius": radius,
		"simulation_enabled": simulation_enabled,
		"combat_available": combat_available,
	}


func _resolve_power_box() -> Dictionary:
	var affected_count: int = 0
	var interrupted_count: int = 0
	var status_count: int = 0
	for target: ActorController in _power_box_targets():
		var was_winding_up: bool = (
			target.state_machine.current_state == ActorStateMachine.State.ATTACK_WINDUP
		)
		var damage: int = _combat_director.request_environmental_hit(
			power_box_definition.id,
			target,
			_power_box_origin,
			power_box_definition.damage,
			0.0,
			0.0,
			0.0
		)
		if damage <= 0:
			continue
		affected_count += 1
		if target.can_be_targeted() and target.request_stun(power_box_definition.stun_seconds):
			if was_winding_up:
				interrupted_count += 1
		if _combat_director.request_intervention_status(
			power_box_definition.id,
			target,
			power_box_definition.status_id,
			1,
			power_box_definition.status_duration_seconds,
			1
		) > 0.0:
			status_count += 1
	return {
		"affected_count": affected_count,
		"interrupted_count": interrupted_count,
		"status_count": status_count,
		"damage_each": power_box_definition.damage,
	}


func _power_box_targets() -> Array[ActorController]:
	if _combat_director == null or power_box_definition == null:
		return []
	return _combat_director.get_live_targets_in_circle(
		ActorController.Team.ENEMY,
		_power_box_origin,
		power_box_definition.range_radius
	)


func _power_box_interruptible_targets() -> Array[ActorController]:
	if _combat_director == null or _current_action_id != ACTION_POWER_BOX:
		return []
	var targets_in_footprint: Array[ActorController] = _power_box_targets()
	var result: Array[ActorController] = []
	for intent: Dictionary in _combat_director.get_active_threat_intents():
		var target: ActorController = _combat_director.get_actor_by_instance_id(
			int(intent.get("target_instance_id", -1))
		)
		if target != null and targets_in_footprint.has(target):
			result.append(target)
	return result


func _valid_target_count() -> int:
	if _current_action_id == ACTION_HYDRANT and _hydrant_controller != null:
		return _hydrant_controller.get_valid_target_count()
	if _current_action_id == ACTION_POWER_BOX:
		return _power_box_targets().size()
	return 0


func _validate_request_context(
	action_id: StringName,
	expected_context_revision: int,
	request_token: int
) -> StringName:
	if action_id == &"" or expected_context_revision < 0 or request_token <= 0:
		return REASON_MALFORMED
	if _consumed_request_tokens.has(request_token):
		return REASON_REPLAYED
	if (
		expected_context_revision != _context_revision
		or request_token != _request_token
	):
		return REASON_STALE
	if action_id != _current_action_id:
		return REASON_WRONG_ACTION
	return REASON_OK


func _refresh_context(force: bool) -> void:
	var signature: String = "%s|%s|%d|%d|%s|%s" % [
		_current_action_id,
		get_validity_reason(),
		_valid_target_count(),
		_power_box_interruptible_targets().size(),
		simulation_enabled,
		combat_available,
	]
	if force or signature != _last_context_signature:
		_last_context_signature = signature
		_context_revision += 1
		_request_token = _next_request_token
		_next_request_token += 1
	state_changed.emit(get_snapshot())


func _reject(action_id: StringName, reason: StringName) -> Dictionary:
	activation_rejected.emit(action_id, reason)
	return {
		"accepted": false,
		"reason": reason,
		"action_id": action_id,
	}


func _on_hydrant_state_changed(
	_state: int,
	_cooldown_remaining: float,
	_cooldown_duration: float
) -> void:
	if _current_action_id == ACTION_HYDRANT:
		_refresh_context(false)
