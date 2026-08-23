class_name FocusController
extends Node

## Production WP05 Focus authority. It validates one current authored intent,
## applies temporary target priority without direct attacks/movement, and owns
## cooldown, result, caller revision/token, expiry, and cleanup.

signal state_changed(snapshot: Dictionary)
signal activation_accepted(
	request_token: int,
	target: ActorController,
	attack: AttackDefinition,
	retargeted_count: int
)
signal activation_rejected(reason: StringName)
signal focus_result(
	request_token: int,
	result_id: StringName,
	target: ActorController,
	attack_id: StringName
)
signal focus_ended(request_token: int, reason: StringName)

const REASON_OK: StringName = &"ok"
const REASON_UNCONFIGURED: StringName = &"unconfigured"
const REASON_INVALID_STATE: StringName = &"invalid_state"
const REASON_NO_TARGET: StringName = &"no_focus_target"
const REASON_COOLDOWN: StringName = &"cooldown"
const REASON_ALREADY_ACTIVE: StringName = &"already_active"
const REASON_WINDOW_CLOSED: StringName = &"decision_window_closed"
const REASON_TARGET_CHANGED: StringName = &"target_changed"
const REASON_MALFORMED: StringName = &"malformed_request"
const REASON_STALE: StringName = &"stale_context"
const REASON_REPLAYED: StringName = &"replayed_request"
const REASON_REQUEST_ACTIVE: StringName = &"request_in_progress"

const RESULT_INTERRUPTED: StringName = &"interrupted"
const RESULT_INTENT_RESOLVED: StringName = &"intent_resolved"
const END_EXPIRED: StringName = &"expired"
const END_TARGET_DEFEATED: StringName = &"target_defeated"
const END_TARGET_LOST: StringName = &"target_lost"
const END_TERMINAL: StringName = &"terminal"
const END_RESTART: StringName = &"restart"

const DEFAULT_DEFINITION: FocusDefinition = preload(
	"res://data/interventions/wp05_focus.tres"
)

@export var definition: FocusDefinition = DEFAULT_DEFINITION

var simulation_enabled: bool = false
var combat_available: bool = false

var _combat_director: CombatDirector
var _cooldown_remaining: float = 0.0
var _cooldown_multiplier: float = 1.0
var _active_remaining: float = 0.0
var _focused_target: ActorController
var _focused_attack_id: StringName = &""
var _active_request_token: int = -1
var _intent_result_published: bool = false
var _candidate: Dictionary = {}
var _request_in_progress: bool = false
var _context_revision: int = 0
var _request_token: int = -1
var _next_request_token: int = 1
var _consumed_request_tokens: Dictionary[int, bool] = {}
var _last_context_signature: String = ""


func _ready() -> void:
	if definition == null:
		definition = DEFAULT_DEFINITION
	_refresh_context(true)


func _process(delta: float) -> void:
	step_eligible_time(delta)


func configure(combat_director: CombatDirector) -> bool:
	_combat_director = combat_director
	if _combat_director != null and not _combat_director.actor_died.is_connected(_on_actor_died):
		_combat_director.actor_died.connect(_on_actor_died)
	_refresh_context(true)
	return (
		_combat_director != null
		and definition != null
		and definition.validation_errors().is_empty()
	)


func reset_for_run() -> void:
	_end_focus(END_RESTART)
	_cooldown_remaining = 0.0
	_cooldown_multiplier = 1.0
	_request_in_progress = false
	simulation_enabled = false
	combat_available = false
	_candidate.clear()
	_refresh_context(true)


func cleanup_for_terminal_state() -> void:
	_end_focus(END_TERMINAL)
	_request_in_progress = false
	simulation_enabled = false
	combat_available = false
	_candidate.clear()
	_refresh_context(true)


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled
	_refresh_context(false)


func set_combat_available(is_available: bool) -> void:
	combat_available = is_available
	_refresh_context(false)


func step_eligible_time(delta: float) -> void:
	if not simulation_enabled or delta <= 0.0:
		return
	var safe_delta: float = maxf(delta, 0.0)
	var cooldown_was_active: bool = _cooldown_remaining > 0.0
	_cooldown_remaining = maxf(_cooldown_remaining - safe_delta, 0.0)
	if _active_remaining > 0.0:
		_active_remaining = maxf(_active_remaining - safe_delta, 0.0)
		if (
			_focused_target == null
			or not is_instance_valid(_focused_target)
			or not _focused_target.can_be_targeted()
		):
			_end_focus(END_TARGET_LOST)
		elif _active_remaining <= 0.0:
			_end_focus(END_EXPIRED)
		else:
			_apply_priority()
	_candidate = _best_candidate()
	_refresh_context(cooldown_was_active and _cooldown_remaining <= 0.0)


func request_activation(
	target_instance_id: int,
	attack_id: StringName,
	expected_context_revision: int,
	request_token: int
) -> Dictionary:
	var request_validation: StringName = _validate_request_context(
		target_instance_id,
		attack_id,
		expected_context_revision,
		request_token
	)
	if request_validation != REASON_OK:
		return _reject(request_validation)
	var live_candidate: Dictionary = _best_candidate()
	if (
		int(live_candidate.get("target_instance_id", -1)) != target_instance_id
		or StringName(live_candidate.get("attack_id", &"")) != attack_id
	):
		return _reject(REASON_TARGET_CHANGED)
	_candidate = live_candidate
	var validity: StringName = get_validity_reason()
	if validity != REASON_OK:
		return _reject(validity)
	var target: ActorController = _combat_director.get_actor_by_instance_id(target_instance_id)
	var attack: AttackDefinition = _combat_director.get_attack_definition_for_actor(
		target,
		attack_id
	)
	if target == null or attack == null:
		return _reject(REASON_TARGET_CHANGED)
	_request_in_progress = true
	_focused_target = target
	_focused_attack_id = attack_id
	_active_request_token = request_token
	_active_remaining = definition.priority_duration_seconds
	_cooldown_remaining = get_cooldown_duration()
	_intent_result_published = false
	if not target.state_changed.is_connected(_on_focused_target_state_changed):
		target.state_changed.connect(_on_focused_target_state_changed)
	var retargeted_count: int = _apply_priority()
	_consumed_request_tokens[request_token] = true
	_request_in_progress = false
	_last_context_signature = ""
	_refresh_context(true)
	activation_accepted.emit(request_token, target, attack, retargeted_count)
	return {
		"accepted": true,
		"reason": REASON_OK,
		"request_token": request_token,
		"target_instance_id": target_instance_id,
		"target_id": target.definition_id(),
		"attack_id": attack_id,
		"retargeted_count": retargeted_count,
		"active_seconds": _active_remaining,
	}


func get_validity_reason() -> StringName:
	if (
		_combat_director == null
		or definition == null
		or not definition.validation_errors().is_empty()
	):
		return REASON_UNCONFIGURED
	if not simulation_enabled or not combat_available:
		return REASON_INVALID_STATE
	if _request_in_progress:
		return REASON_REQUEST_ACTIVE
	if _active_remaining > 0.0:
		return REASON_ALREADY_ACTIVE
	if _cooldown_remaining > 0.0:
		return REASON_COOLDOWN
	if _candidate.is_empty():
		return REASON_NO_TARGET
	if float(_candidate.get("window_seconds", 0.0)) < definition.minimum_decision_window_seconds:
		return REASON_WINDOW_CLOSED
	return REASON_OK


func can_activate() -> bool:
	return get_validity_reason() == REASON_OK


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
	_refresh_context(true)


func get_cooldown_duration() -> float:
	return maxf(definition.cooldown_seconds * _cooldown_multiplier, 0.0)


func get_snapshot() -> Dictionary:
	var validity: StringName = get_validity_reason()
	var display_context: Dictionary = _candidate
	if (
		_active_remaining > 0.0
		and _focused_target != null
		and is_instance_valid(_focused_target)
	):
		var active_attack: AttackDefinition = _combat_director.get_attack_definition_for_actor(
			_focused_target,
			_focused_attack_id
		)
		display_context = {
			"target_instance_id": _focused_target.get_instance_id(),
			"target_id": _focused_target.definition_id(),
			"target_name": _focused_target.actor_definition.display_name,
			"target_position": _focused_target.global_position,
			"attack_id": _focused_attack_id,
			"attack_name": active_attack.display_name if active_attack != null else String(_focused_attack_id),
			"intent_label": (
				active_attack.intent_label
				if active_attack != null and not active_attack.intent_label.is_empty()
				else (active_attack.display_name if active_attack != null else String(_focused_attack_id))
			),
			"window_seconds": 0.0,
		}
	return {
		"id": definition.id,
		"display_name": definition.display_name,
		"description": definition.description,
		"icon": definition.icon,
		"context_revision": _context_revision,
		"request_token": _request_token,
		"validity_reason": validity,
		"can_activate": validity == REASON_OK,
		"cooldown_remaining": _cooldown_remaining,
		"cooldown_duration": get_cooldown_duration(),
		"cooldown_multiplier": _cooldown_multiplier,
		"active_remaining": _active_remaining,
		"priority_duration_seconds": definition.priority_duration_seconds,
		"active_request_token": _active_request_token,
		"active_target_instance_id": (
			_focused_target.get_instance_id()
			if _focused_target != null and is_instance_valid(_focused_target)
			else -1
		),
		"target_instance_id": int(display_context.get("target_instance_id", -1)),
		"target_id": StringName(display_context.get("target_id", &"")),
		"target_name": str(display_context.get("target_name", "NO THREAT")),
		"attack_id": StringName(display_context.get("attack_id", &"")),
		"attack_name": str(display_context.get("attack_name", "NO INTENT")),
		"intent_label": str(display_context.get("intent_label", "NO INTENT")),
		"window_seconds": float(display_context.get("window_seconds", 0.0)),
		"target_position": display_context.get("target_position", Vector2.ZERO),
		"simulation_enabled": simulation_enabled,
		"combat_available": combat_available,
	}


func _best_candidate() -> Dictionary:
	if _combat_director == null or not combat_available:
		return {}
	var intents: Array[Dictionary] = _combat_director.get_active_threat_intents()
	return intents[0].duplicate(true) if not intents.is_empty() else {}


func _apply_priority() -> int:
	if (
		_combat_director == null
		or _focused_target == null
		or not is_instance_valid(_focused_target)
		or not _focused_target.can_be_targeted()
	):
		return 0
	var retargeted_count: int = 0
	for crew: ActorController in _combat_director.get_live_actors(ActorController.Team.CREW):
		if not crew.is_permanent_crew() or crew.current_target == _focused_target:
			continue
		if crew.state_machine.current_state in [
			ActorStateMachine.State.ATTACK_WINDUP,
			ActorStateMachine.State.ATTACK_ACTIVE,
			ActorStateMachine.State.ATTACK_RECOVERY,
			ActorStateMachine.State.KNOCKED_BACK,
			ActorStateMachine.State.STUNNED,
		]:
			continue
		if crew.assign_target(_focused_target):
			retargeted_count += 1
	return retargeted_count


func _validate_request_context(
	target_instance_id: int,
	attack_id: StringName,
	expected_context_revision: int,
	request_token: int
) -> StringName:
	if (
		target_instance_id <= 0
		or attack_id == &""
		or expected_context_revision < 0
		or request_token <= 0
	):
		return REASON_MALFORMED
	if _consumed_request_tokens.has(request_token):
		return REASON_REPLAYED
	if (
		expected_context_revision != _context_revision
		or request_token != _request_token
	):
		return REASON_STALE
	if (
		int(_candidate.get("target_instance_id", -1)) != target_instance_id
		or StringName(_candidate.get("attack_id", &"")) != attack_id
	):
		return REASON_TARGET_CHANGED
	return REASON_OK


func _on_focused_target_state_changed(
	actor: ActorController,
	previous_state: int,
	new_state: int
) -> void:
	if actor != _focused_target or _intent_result_published:
		return
	if previous_state != ActorStateMachine.State.ATTACK_WINDUP:
		return
	if new_state == ActorStateMachine.State.ATTACK_ACTIVE:
		_intent_result_published = true
		focus_result.emit(
			_active_request_token,
			RESULT_INTENT_RESOLVED,
			actor,
			_focused_attack_id
		)
	elif new_state in [
		ActorStateMachine.State.STUNNED,
		ActorStateMachine.State.KNOCKED_BACK,
		ActorStateMachine.State.DEAD,
	]:
		_intent_result_published = true
		focus_result.emit(
			_active_request_token,
			RESULT_INTERRUPTED,
			actor,
			_focused_attack_id
		)


func _on_actor_died(actor: ActorController) -> void:
	if actor == _focused_target:
		_end_focus(END_TARGET_DEFEATED)


func _end_focus(reason: StringName) -> void:
	if _focused_target == null and _active_request_token < 0:
		return
	var ended_token: int = _active_request_token
	var ended_target: ActorController = _focused_target
	if (
		ended_target != null
		and is_instance_valid(ended_target)
		and ended_target.state_changed.is_connected(_on_focused_target_state_changed)
	):
		ended_target.state_changed.disconnect(_on_focused_target_state_changed)
	_focused_target = null
	_focused_attack_id = &""
	_active_request_token = -1
	_active_remaining = 0.0
	_intent_result_published = false
	focus_ended.emit(ended_token, reason)


func _refresh_context(force: bool) -> void:
	_candidate = _best_candidate()
	var signature: String = "%s|%s|%d|%s|%s" % [
		get_validity_reason(),
		_active_remaining > 0.0,
		int(_candidate.get("target_instance_id", -1)),
		StringName(_candidate.get("attack_id", &"")),
		combat_available,
	]
	if force or signature != _last_context_signature:
		_last_context_signature = signature
		_context_revision += 1
		_request_token = _next_request_token
		_next_request_token += 1
	state_changed.emit(get_snapshot())


func _reject(reason: StringName) -> Dictionary:
	activation_rejected.emit(reason)
	return {
		"accepted": false,
		"reason": reason,
	}
