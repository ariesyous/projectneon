class_name WP05PrototypeRuntime
extends Node

## Development-gated WP05 comparison authority. Default GameRun never creates
## this node. It uses existing combat actors and authorities, records only
## deterministic eligible-time telemetry, and owns no production run state.

signal snapshot_changed(snapshot: Dictionary)
signal action_accepted(role_id: StringName, action_id: StringName, result: Dictionary)
signal action_rejected(role_id: StringName, action_id: StringName, reason: StringName)

const ROLE_ENVIRONMENT: StringName = &"environment"
const ROLE_FOCUS: StringName = &"focus"
const ROLE_BACKUP: StringName = &"backup"
const ROLE_RALLY: StringName = &"rally"

const ACTION_HYDRANT: StringName = &"fire_hydrant"
const ACTION_POWER_BOX: StringName = &"wp05_proto_power_box"
const ACTION_HANGING_SIGN: StringName = &"wp05_proto_hanging_sign"
const ACTION_FOCUS: StringName = &"wp05_proto_focus_priority"
const ACTION_RALLY: StringName = &"wp05_proto_rally_reposition"
const ACTION_BACKUP: StringName = &"call_backup"

const REASON_OK: StringName = &"ok"
const REASON_MALFORMED: StringName = &"malformed_request"
const REASON_STALE: StringName = &"stale_context"
const REASON_REPLAYED: StringName = &"replayed_token"
const REASON_WRONG_ACTION: StringName = &"wrong_context_action"
const REASON_INVALID_STATE: StringName = &"invalid_state"
const REASON_NO_TARGET: StringName = &"no_valid_target"
const REASON_COOLDOWN: StringName = &"cooldown"
const REASON_EXHAUSTED: StringName = &"exhausted"
const REASON_WINDOW_CLOSED: StringName = &"decision_window_closed"
const REASON_TARGET_CHANGED: StringName = &"target_changed"
const REASON_ALREADY_ACTIVE: StringName = &"already_active"

const DEFAULT_CATALOGUE: WP05PrototypeCatalogue = preload(
	"res://data/interventions/prototypes/wp05_prototype_catalogue.tres"
)

@export var catalogue: WP05PrototypeCatalogue = DEFAULT_CATALOGUE

var simulation_enabled: bool = false
var combat_available: bool = false

var _combat_director: CombatDirector
var _fire_hydrant_controller: FireHydrantController
var _call_backup_controller: CallBackupController
var _encounter_controller: RunEncounterController
var _scenario: WP05PrototypeScenarioDefinition
var _crew_id: StringName = &""
var _build_ids: Array[StringName] = []
var _telemetry: WP05PrototypeTelemetry = WP05PrototypeTelemetry.new()

var _selected_environment_id: StringName = ACTION_HYDRANT
var _environment_cooldown_remaining: float = 0.0
var _environment_charges_remaining: int = 0
var _focus_cooldown_remaining: float = 0.0
var _focus_active_remaining: float = 0.0
var _focus_target: ActorController
var _focus_candidate: Dictionary = {}
var _rally_cooldown_remaining: float = 0.0
var _rally_active_remaining: float = 0.0
var _rally_candidate: Dictionary = {}
var _rally_anchor_by_actor: Dictionary[int, Vector2] = {}
var _rally_start_by_actor: Dictionary[int, Vector2] = {}

var _next_request_token: int = 1
var _role_revisions: Dictionary[StringName, int] = {}
var _role_tokens: Dictionary[StringName, int] = {}
var _role_context_signatures: Dictionary[StringName, String] = {}
var _consumed_tokens: Dictionary[int, bool] = {}


func configure(
	combat_director: CombatDirector,
	fire_hydrant_controller: FireHydrantController,
	call_backup_controller: CallBackupController,
	encounter_controller: RunEncounterController
) -> bool:
	_combat_director = combat_director
	_fire_hydrant_controller = fire_hydrant_controller
	_call_backup_controller = call_backup_controller
	_encounter_controller = encounter_controller
	if _fire_hydrant_controller != null and not _fire_hydrant_controller.state_changed.is_connected(
		_on_hydrant_state_changed
	):
		_fire_hydrant_controller.state_changed.connect(_on_hydrant_state_changed)
	if _call_backup_controller != null and not _call_backup_controller.state_changed.is_connected(
		_on_backup_state_changed
	):
		_call_backup_controller.state_changed.connect(_on_backup_state_changed)
	return (
		_combat_director != null
		and _fire_hydrant_controller != null
		and _call_backup_controller != null
		and _encounter_controller != null
		and catalogue != null
		and catalogue.validation_errors().is_empty()
	)


func begin_scenario(
	scenario_id: StringName,
	crew_id: StringName,
	build_ids: Array[StringName]
) -> bool:
	if catalogue == null:
		return false
	var requested: WP05PrototypeScenarioDefinition = catalogue.get_scenario(scenario_id)
	if requested == null or not requested.validation_errors().is_empty():
		return false
	_cleanup_active_focus(&"scenario_changed")
	_finish_rally(&"scenario_changed")
	_scenario = requested
	_crew_id = crew_id
	_build_ids = build_ids.duplicate()
	_build_ids.sort_custom(_string_name_before)
	_selected_environment_id = requested.environment_action_id
	_environment_cooldown_remaining = 0.0
	var environment_definition: WP05PrototypeActionDefinition = _environment_definition()
	_environment_charges_remaining = (
		environment_definition.initial_charges if environment_definition != null else 0
	)
	_focus_cooldown_remaining = 0.0
	_rally_cooldown_remaining = 0.0
	_telemetry.begin(requested.id, crew_id, _build_ids)
	simulation_enabled = true
	combat_available = true
	_refresh_contexts(true)
	return true


func reset_for_run() -> void:
	_close_all_opportunities(&"restart")
	_cleanup_active_focus(&"restart")
	_finish_rally(&"restart")
	_scenario = null
	_crew_id = &""
	_build_ids.clear()
	_environment_cooldown_remaining = 0.0
	_environment_charges_remaining = 0
	_focus_cooldown_remaining = 0.0
	_rally_cooldown_remaining = 0.0
	simulation_enabled = false
	combat_available = false
	_refresh_contexts(true)


func cleanup_for_terminal_state() -> void:
	_close_all_opportunities(&"terminal")
	_cleanup_active_focus(&"terminal")
	_finish_rally(&"terminal")
	simulation_enabled = false
	combat_available = false
	_refresh_contexts(true)


func set_simulation_enabled(is_enabled: bool) -> void:
	simulation_enabled = is_enabled
	_refresh_contexts(false)


func set_combat_available(is_available: bool) -> void:
	combat_available = is_available
	_refresh_contexts(false)


func step_eligible_time(delta: float) -> void:
	if not simulation_enabled or delta <= 0.0:
		return
	var safe_delta: float = maxf(delta, 0.0)
	_telemetry.step_eligible_time(safe_delta)
	_environment_cooldown_remaining = maxf(_environment_cooldown_remaining - safe_delta, 0.0)
	_focus_cooldown_remaining = maxf(_focus_cooldown_remaining - safe_delta, 0.0)
	_rally_cooldown_remaining = maxf(_rally_cooldown_remaining - safe_delta, 0.0)
	if _focus_active_remaining > 0.0:
		_focus_active_remaining = maxf(_focus_active_remaining - safe_delta, 0.0)
		if _focus_target == null or not is_instance_valid(_focus_target) or not _focus_target.can_be_targeted():
			_cleanup_active_focus(&"target_lost")
		elif _focus_active_remaining <= 0.0:
			_cleanup_active_focus(&"expired")
		else:
			_apply_focus_priority()
	if _rally_active_remaining > 0.0:
		_step_rally(safe_delta)
	_refresh_contexts(false)


func request_environment(
	action_id: StringName,
	expected_revision: int,
	request_token: int
) -> Dictionary:
	var validation: StringName = _validate_request(
		ROLE_ENVIRONMENT, action_id, expected_revision, request_token
	)
	if validation != REASON_OK:
		return _reject(ROLE_ENVIRONMENT, action_id, validation)
	if action_id != _selected_environment_id:
		return _reject(ROLE_ENVIRONMENT, action_id, REASON_WRONG_ACTION)
	var validity: StringName = _environment_validity_reason()
	if validity != REASON_OK:
		return _reject(ROLE_ENVIRONMENT, action_id, validity)

	var result: Dictionary = {}
	if action_id == ACTION_HYDRANT:
		if not _fire_hydrant_controller.request_activation():
			return _reject(ROLE_ENVIRONMENT, action_id, _environment_validity_reason())
		result = {
			"affected_count": _fire_hydrant_controller.get_valid_target_count(),
			"interrupted_count": 0,
		}
		_environment_cooldown_remaining = _fire_hydrant_controller.get_cooldown_duration()
	elif action_id == ACTION_POWER_BOX:
		result = _resolve_power_box()
	elif action_id == ACTION_HANGING_SIGN:
		result = _resolve_hanging_sign()
	else:
		return _reject(ROLE_ENVIRONMENT, action_id, REASON_WRONG_ACTION)

	_consume_request(ROLE_ENVIRONMENT, request_token)
	var definition: WP05PrototypeActionDefinition = _environment_definition()
	if definition != null:
		_environment_cooldown_remaining = maxf(
			_environment_cooldown_remaining,
			definition.cooldown_seconds
		)
		if definition.initial_charges > 0:
			_environment_charges_remaining = maxi(_environment_charges_remaining - 1, 0)
	_telemetry.record_use(ROLE_ENVIRONMENT, action_id, result)
	_telemetry.record_result(ROLE_ENVIRONMENT, action_id, &"resolved", result)
	action_accepted.emit(ROLE_ENVIRONMENT, action_id, result.duplicate(true))
	_refresh_contexts(true)
	return _accepted(action_id, result)


func request_focus(
	target_instance_id: int,
	attack_id: StringName,
	expected_revision: int,
	request_token: int
) -> Dictionary:
	var validation: StringName = _validate_request(
		ROLE_FOCUS, ACTION_FOCUS, expected_revision, request_token
	)
	if validation != REASON_OK:
		return _reject(ROLE_FOCUS, ACTION_FOCUS, validation)
	var validity: StringName = _focus_validity_reason()
	if validity != REASON_OK:
		return _reject(ROLE_FOCUS, ACTION_FOCUS, validity)
	if (
		int(_focus_candidate.get("target_instance_id", -1)) != target_instance_id
		or StringName(_focus_candidate.get("attack_id", &"")) != attack_id
	):
		return _reject(ROLE_FOCUS, ACTION_FOCUS, REASON_TARGET_CHANGED)
	var target: ActorController = _actor_by_instance_id(target_instance_id)
	if target == null:
		return _reject(ROLE_FOCUS, ACTION_FOCUS, REASON_TARGET_CHANGED)
	var definition: WP05PrototypeActionDefinition = catalogue.get_action(ACTION_FOCUS)
	_focus_target = target
	_focus_active_remaining = definition.active_duration_seconds
	_focus_cooldown_remaining = definition.cooldown_seconds
	var retargeted_count: int = _apply_focus_priority()
	var result: Dictionary = {
		"target_instance_id": target_instance_id,
		"target_id": target.definition_id(),
		"attack_id": attack_id,
		"retargeted_count": retargeted_count,
		"active_seconds": _focus_active_remaining,
		"decision_window_seconds": float(_focus_candidate.get("window_seconds", 0.0)),
	}
	_consume_request(ROLE_FOCUS, request_token)
	_telemetry.record_use(ROLE_FOCUS, ACTION_FOCUS, result)
	action_accepted.emit(ROLE_FOCUS, ACTION_FOCUS, result.duplicate(true))
	_refresh_contexts(true)
	return _accepted(ACTION_FOCUS, result)


func request_backup(expected_revision: int, request_token: int) -> Dictionary:
	var validation: StringName = _validate_request(
		ROLE_BACKUP, ACTION_BACKUP, expected_revision, request_token
	)
	if validation != REASON_OK:
		return _reject(ROLE_BACKUP, ACTION_BACKUP, validation)
	if _call_backup_controller == null:
		return _reject(ROLE_BACKUP, ACTION_BACKUP, REASON_INVALID_STATE)
	var external_reason: StringName = _call_backup_controller.get_validity_reason()
	if external_reason != CallBackupController.REASON_OK:
		return _reject(ROLE_BACKUP, ACTION_BACKUP, external_reason)
	if not _call_backup_controller.request_activation():
		return _reject(
			ROLE_BACKUP,
			ACTION_BACKUP,
			_call_backup_controller.get_validity_reason()
		)
	var result: Dictionary = {
		"activation_token": _call_backup_controller.get_last_accepted_token(),
		"charges_remaining": _call_backup_controller.get_charges_remaining(),
		"active_ally_count": _call_backup_controller.get_active_allies().size(),
	}
	_consume_request(ROLE_BACKUP, request_token)
	_telemetry.record_use(ROLE_BACKUP, ACTION_BACKUP, result)
	action_accepted.emit(ROLE_BACKUP, ACTION_BACKUP, result.duplicate(true))
	_refresh_contexts(true)
	return _accepted(ACTION_BACKUP, result)


func request_rally(
	target_instance_id: int,
	attack_id: StringName,
	expected_revision: int,
	request_token: int
) -> Dictionary:
	var validation: StringName = _validate_request(
		ROLE_RALLY, ACTION_RALLY, expected_revision, request_token
	)
	if validation != REASON_OK:
		return _reject(ROLE_RALLY, ACTION_RALLY, validation)
	var validity: StringName = _rally_validity_reason()
	if validity != REASON_OK:
		return _reject(ROLE_RALLY, ACTION_RALLY, validity)
	if (
		int(_rally_candidate.get("target_instance_id", -1)) != target_instance_id
		or StringName(_rally_candidate.get("attack_id", &"")) != attack_id
	):
		return _reject(ROLE_RALLY, ACTION_RALLY, REASON_TARGET_CHANGED)
	var definition: WP05PrototypeActionDefinition = catalogue.get_action(ACTION_RALLY)
	var crew: Array[ActorController] = _permanent_crew()
	if crew.is_empty():
		return _reject(ROLE_RALLY, ACTION_RALLY, REASON_INVALID_STATE)
	_rally_anchor_by_actor.clear()
	_rally_start_by_actor.clear()
	var combat_space: CombatSpaceDefinition = _combat_director.get_combat_space()
	for actor: ActorController in crew:
		var instance_id: int = actor.get_instance_id()
		_rally_start_by_actor[instance_id] = actor.global_position
		_rally_anchor_by_actor[instance_id] = combat_space.clamp_actor_position(Vector2(
			combat_space.minimum_x() + 40.0,
			combat_space.lane_y(actor.lane_index)
		))
	_rally_active_remaining = definition.active_duration_seconds
	_rally_cooldown_remaining = definition.cooldown_seconds
	var result: Dictionary = {
		"crew_count": crew.size(),
		"attack_id": attack_id,
		"active_seconds": _rally_active_remaining,
		"decision_window_seconds": float(_rally_candidate.get("window_seconds", 0.0)),
	}
	_consume_request(ROLE_RALLY, request_token)
	_telemetry.record_use(ROLE_RALLY, ACTION_RALLY, result)
	action_accepted.emit(ROLE_RALLY, ACTION_RALLY, result.duplicate(true))
	_refresh_contexts(true)
	return _accepted(ACTION_RALLY, result)


func request_current_environment() -> Dictionary:
	var snapshot: Dictionary = _environment_snapshot()
	return request_environment(
		StringName(snapshot.get("action_id", &"")),
		int(snapshot.get("revision", -1)),
		int(snapshot.get("request_token", -1))
	)


func request_current_focus() -> Dictionary:
	var snapshot: Dictionary = _focus_snapshot()
	return request_focus(
		int(snapshot.get("target_instance_id", -1)),
		StringName(snapshot.get("attack_id", &"")),
		int(snapshot.get("revision", -1)),
		int(snapshot.get("request_token", -1))
	)


func request_current_backup() -> Dictionary:
	var snapshot: Dictionary = _backup_snapshot()
	return request_backup(
		int(snapshot.get("revision", -1)),
		int(snapshot.get("request_token", -1))
	)


func request_current_rally() -> Dictionary:
	var snapshot: Dictionary = _rally_snapshot()
	return request_rally(
		int(snapshot.get("target_instance_id", -1)),
		StringName(snapshot.get("attack_id", &"")),
		int(snapshot.get("revision", -1)),
		int(snapshot.get("request_token", -1))
	)


func get_scenario() -> WP05PrototypeScenarioDefinition:
	return _scenario


func get_telemetry_snapshot() -> Dictionary:
	return _telemetry.get_snapshot()


func get_snapshot() -> Dictionary:
	return {
		"enabled": _scenario != null,
		"development_only": true,
		"scenario_id": _scenario.id if _scenario != null else &"",
		"scenario_name": _scenario.display_name if _scenario != null else "WP05 PROTOTYPE OFF",
		"context_id": _scenario.context_id if _scenario != null else &"",
		"tactical_question": _scenario.tactical_question if _scenario != null else "",
		"crew_id": _crew_id,
		"build_ids": _build_ids.duplicate(),
		"simulation_enabled": simulation_enabled,
		"combat_available": combat_available,
		"environment": _environment_snapshot(),
		"focus": _focus_snapshot(),
		"backup": _backup_snapshot(),
		"rally": _rally_snapshot(),
		"telemetry": _telemetry.get_snapshot(),
	}


func _resolve_power_box() -> Dictionary:
	var definition: WP05PrototypeActionDefinition = _environment_definition()
	var affected_count: int = 0
	var interrupted_count: int = 0
	var shocked_count: int = 0
	for target: ActorController in _environment_targets():
		var was_winding_up: bool = _is_actor_winding_up(target)
		var damage: int = _combat_director.request_environmental_hit(
			definition.id,
			target,
			definition.world_origin,
			definition.base_damage,
			definition.knockback_force,
			definition.knockback_duration,
			definition.knockback_direction_x
		)
		if damage <= 0:
			continue
		affected_count += 1
		if target.can_be_targeted() and target.request_stun(definition.stun_seconds):
			if was_winding_up:
				interrupted_count += 1
		if (
			target.can_be_targeted()
			and definition.status_id != &""
			and target.apply_status(
				definition.status_id,
				1,
				definition.status_duration_seconds,
				1
			)
		):
			shocked_count += 1
	return {
		"affected_count": affected_count,
		"interrupted_count": interrupted_count,
		"status_count": shocked_count,
		"damage_each": definition.base_damage,
	}


func _resolve_hanging_sign() -> Dictionary:
	var definition: WP05PrototypeActionDefinition = _environment_definition()
	var targets: Array[ActorController] = _environment_targets()
	if targets.is_empty():
		return {"affected_count": 0, "interrupted_count": 0}
	var target: ActorController = targets[0]
	var was_winding_up: bool = _is_actor_winding_up(target)
	var damage: int = _combat_director.request_environmental_hit(
		definition.id,
		target,
		definition.world_origin,
		definition.base_damage,
		definition.knockback_force,
		definition.knockback_duration,
		definition.knockback_direction_x
	)
	return {
		"affected_count": 1 if damage > 0 else 0,
		"interrupted_count": 1 if damage > 0 and was_winding_up else 0,
		"damage": damage,
		"target_id": target.definition_id(),
	}


func _apply_focus_priority() -> int:
	if _focus_target == null or not is_instance_valid(_focus_target):
		return 0
	var retargeted_count: int = 0
	for crew: ActorController in _permanent_crew():
		if crew.current_target == _focus_target:
			continue
		if crew.state_machine.current_state in [
			ActorStateMachine.State.ATTACK_WINDUP,
			ActorStateMachine.State.ATTACK_ACTIVE,
			ActorStateMachine.State.ATTACK_RECOVERY,
			ActorStateMachine.State.KNOCKED_BACK,
			ActorStateMachine.State.STUNNED,
		]:
			continue
		if crew.assign_target(_focus_target):
			retargeted_count += 1
	return retargeted_count


func _cleanup_active_focus(reason: StringName) -> void:
	if _focus_target != null or _focus_active_remaining > 0.0:
		_telemetry.record_result(ROLE_FOCUS, ACTION_FOCUS, reason, {
			"remaining_seconds": _focus_active_remaining,
		})
	_focus_target = null
	_focus_active_remaining = 0.0


func _step_rally(delta: float) -> void:
	var definition: WP05PrototypeActionDefinition = catalogue.get_action(ACTION_RALLY)
	for crew: ActorController in _permanent_crew():
		var instance_id: int = crew.get_instance_id()
		if not _rally_anchor_by_actor.has(instance_id):
			continue
		crew.attack_controller.cancel()
		crew.clear_target()
		crew.state_machine.transition_to(ActorStateMachine.State.STUNNED)
		crew.global_position = crew.global_position.move_toward(
			_rally_anchor_by_actor[instance_id],
			crew.get_movement_speed() * definition.reposition_speed_multiplier * delta
		)
	_rally_active_remaining = maxf(_rally_active_remaining - delta, 0.0)
	if _rally_active_remaining <= 0.0:
		_finish_rally(&"completed")


func _finish_rally(reason: StringName) -> void:
	if _rally_anchor_by_actor.is_empty() and _rally_active_remaining <= 0.0:
		return
	var total_displacement: float = 0.0
	for crew: ActorController in _permanent_crew():
		var instance_id: int = crew.get_instance_id()
		if _rally_start_by_actor.has(instance_id):
			total_displacement += crew.global_position.distance_to(
				_rally_start_by_actor[instance_id]
			)
		if crew.can_act():
			crew.state_machine.transition_to(ActorStateMachine.State.ACQUIRING_TARGET)
	_telemetry.record_result(ROLE_RALLY, ACTION_RALLY, reason, {
		"total_displacement": total_displacement,
	})
	_rally_active_remaining = 0.0
	_rally_anchor_by_actor.clear()
	_rally_start_by_actor.clear()


func _refresh_contexts(force: bool) -> void:
	_focus_candidate = _best_threat_candidate(false)
	_rally_candidate = _best_threat_candidate(true)
	_update_role_context(ROLE_ENVIRONMENT, _environment_signature(), force)
	_update_role_context(ROLE_FOCUS, _focus_signature(), force)
	_update_role_context(ROLE_BACKUP, _backup_signature(), force)
	_update_role_context(ROLE_RALLY, _rally_signature(), force)
	_observe_opportunities()
	snapshot_changed.emit(get_snapshot())


func _update_role_context(role_id: StringName, signature: String, force: bool) -> void:
	if not force and _role_context_signatures.get(role_id, "") == signature:
		return
	_role_context_signatures[role_id] = signature
	_role_revisions[role_id] = _role_revisions.get(role_id, 0) + 1
	_role_tokens[role_id] = _next_request_token
	_next_request_token += 1


func _observe_opportunities() -> void:
	if _environment_validity_reason() == REASON_OK:
		_telemetry.observe_opportunity(
			ROLE_ENVIRONMENT,
			StringName("%s:%d" % [_selected_environment_id, _role_revisions.get(ROLE_ENVIRONMENT, 0)]),
			_selected_environment_id,
			0.0
		)
	else:
		_telemetry.close_opportunity(ROLE_ENVIRONMENT)
	if _focus_validity_reason() == REASON_OK:
		_telemetry.observe_opportunity(
			ROLE_FOCUS,
			_threat_opportunity_key(_focus_candidate),
			ACTION_FOCUS,
			float(_focus_candidate.get("window_seconds", 0.0))
		)
	else:
		_telemetry.close_opportunity(ROLE_FOCUS)
	if _backup_validity_reason() == REASON_OK:
		_telemetry.observe_opportunity(
			ROLE_BACKUP,
			StringName("backup:%d" % _role_revisions.get(ROLE_BACKUP, 0)),
			ACTION_BACKUP,
			0.0
		)
	else:
		_telemetry.close_opportunity(ROLE_BACKUP)
	if _rally_validity_reason() == REASON_OK:
		_telemetry.observe_opportunity(
			ROLE_RALLY,
			_threat_opportunity_key(_rally_candidate),
			ACTION_RALLY,
			float(_rally_candidate.get("window_seconds", 0.0))
		)
	else:
		_telemetry.close_opportunity(ROLE_RALLY)


func _validate_request(
	role_id: StringName,
	action_id: StringName,
	expected_revision: int,
	request_token: int
) -> StringName:
	if role_id == &"" or action_id == &"" or expected_revision < 0 or request_token <= 0:
		return REASON_MALFORMED
	if _consumed_tokens.has(request_token):
		return REASON_REPLAYED
	if (
		request_token != int(_role_tokens.get(role_id, -1))
		or expected_revision != int(_role_revisions.get(role_id, -1))
	):
		return REASON_STALE
	return REASON_OK


func _consume_request(role_id: StringName, request_token: int) -> void:
	_consumed_tokens[request_token] = true
	_role_context_signatures.erase(role_id)


func _environment_validity_reason() -> StringName:
	if not simulation_enabled or not combat_available or _scenario == null:
		return REASON_INVALID_STATE
	if _environment_cooldown_remaining > 0.0:
		return REASON_COOLDOWN
	var definition: WP05PrototypeActionDefinition = _environment_definition()
	if definition != null and definition.initial_charges > 0 and _environment_charges_remaining <= 0:
		return REASON_EXHAUSTED
	if _selected_environment_id == ACTION_HYDRANT:
		if _fire_hydrant_controller.get_state() == FireHydrantController.State.COOLING_DOWN:
			return REASON_COOLDOWN
		return REASON_OK if _fire_hydrant_controller.has_valid_target() else REASON_NO_TARGET
	return REASON_OK if not _environment_targets().is_empty() else REASON_NO_TARGET


func _focus_validity_reason() -> StringName:
	if not simulation_enabled or not combat_available or _scenario == null:
		return REASON_INVALID_STATE
	if _focus_active_remaining > 0.0:
		return REASON_ALREADY_ACTIVE
	if _focus_cooldown_remaining > 0.0:
		return REASON_COOLDOWN
	if _focus_candidate.is_empty():
		return REASON_NO_TARGET
	var definition: WP05PrototypeActionDefinition = catalogue.get_action(ACTION_FOCUS)
	if float(_focus_candidate.get("window_seconds", 0.0)) < definition.minimum_decision_window_seconds:
		return REASON_WINDOW_CLOSED
	return REASON_OK


func _backup_validity_reason() -> StringName:
	if not simulation_enabled or not combat_available or _scenario == null:
		return REASON_INVALID_STATE
	return (
		_call_backup_controller.get_validity_reason()
		if _call_backup_controller != null
		else REASON_INVALID_STATE
	)


func _rally_validity_reason() -> StringName:
	if not simulation_enabled or not combat_available or _scenario == null:
		return REASON_INVALID_STATE
	if _rally_active_remaining > 0.0:
		return REASON_ALREADY_ACTIVE
	if _rally_cooldown_remaining > 0.0:
		return REASON_COOLDOWN
	if _permanent_crew().is_empty() or _rally_candidate.is_empty():
		return REASON_NO_TARGET
	var definition: WP05PrototypeActionDefinition = catalogue.get_action(ACTION_RALLY)
	if float(_rally_candidate.get("window_seconds", 0.0)) < definition.minimum_decision_window_seconds:
		return REASON_WINDOW_CLOSED
	return REASON_OK


func _environment_snapshot() -> Dictionary:
	var definition: WP05PrototypeActionDefinition = _environment_definition()
	var validity: StringName = _environment_validity_reason()
	var target_count: int = _environment_target_count()
	var display_name: String = (
		_fire_hydrant_controller.tuning.display_name
		if _selected_environment_id == ACTION_HYDRANT
		else definition.display_name if definition != null else "Unavailable"
	)
	var verb: String = (
		"BLAST HYDRANT"
		if _selected_environment_id == ACTION_HYDRANT
		else definition.contextual_verb if definition != null else "UNAVAILABLE"
	)
	var origin: Vector2 = (
		_fire_hydrant_controller.get_activation_origin()
		if _selected_environment_id == ACTION_HYDRANT
		else definition.world_origin if definition != null else Vector2.ZERO
	)
	var radius: float = (
		_fire_hydrant_controller.get_range_radius()
		if _selected_environment_id == ACTION_HYDRANT
		else definition.range_radius if definition != null else 0.0
	)
	return {
		"action_id": _selected_environment_id,
		"display_name": display_name,
		"verb": verb,
		"icon": definition.icon if definition != null else null,
		"revision": _role_revisions.get(ROLE_ENVIRONMENT, -1),
		"request_token": _role_tokens.get(ROLE_ENVIRONMENT, -1),
		"validity_reason": validity,
		"can_activate": validity == REASON_OK,
		"target_count": target_count,
		"cooldown_remaining": _environment_cooldown_remaining,
		"charges_remaining": _environment_charges_remaining,
		"finite_charges": definition != null and definition.initial_charges > 0,
		"world_origin": origin,
		"range_radius": radius,
	}


func _focus_snapshot() -> Dictionary:
	var definition: WP05PrototypeActionDefinition = catalogue.get_action(ACTION_FOCUS)
	var validity: StringName = _focus_validity_reason()
	return {
		"action_id": ACTION_FOCUS,
		"display_name": definition.display_name,
		"verb": definition.contextual_verb,
		"icon": definition.icon,
		"revision": _role_revisions.get(ROLE_FOCUS, -1),
		"request_token": _role_tokens.get(ROLE_FOCUS, -1),
		"validity_reason": validity,
		"can_activate": validity == REASON_OK,
		"cooldown_remaining": _focus_cooldown_remaining,
		"active_remaining": _focus_active_remaining,
		"active_target_instance_id": (
			_focus_target.get_instance_id()
			if _focus_target != null and is_instance_valid(_focus_target)
			else -1
		),
		"target_instance_id": int(_focus_candidate.get("target_instance_id", -1)),
		"target_id": StringName(_focus_candidate.get("target_id", &"")),
		"target_name": str(_focus_candidate.get("target_name", "NO THREAT")),
		"attack_id": StringName(_focus_candidate.get("attack_id", &"")),
		"attack_name": str(_focus_candidate.get("attack_name", "NO WINDUP")),
		"window_seconds": float(_focus_candidate.get("window_seconds", 0.0)),
		"target_position": _focus_candidate.get("target_position", Vector2.ZERO),
	}


func _backup_snapshot() -> Dictionary:
	var external: Dictionary = (
		_call_backup_controller.get_snapshot() if _call_backup_controller != null else {}
	)
	var result: Dictionary = external.duplicate(true)
	var validity: StringName = _backup_validity_reason()
	result["action_id"] = ACTION_BACKUP
	result["revision"] = _role_revisions.get(ROLE_BACKUP, -1)
	result["request_token"] = _role_tokens.get(ROLE_BACKUP, -1)
	result["prototype_validity_reason"] = validity
	result["can_activate"] = validity == REASON_OK
	return result


func _rally_snapshot() -> Dictionary:
	var definition: WP05PrototypeActionDefinition = catalogue.get_action(ACTION_RALLY)
	var validity: StringName = _rally_validity_reason()
	return {
		"action_id": ACTION_RALLY,
		"display_name": definition.display_name,
		"verb": definition.contextual_verb,
		"icon": definition.icon,
		"revision": _role_revisions.get(ROLE_RALLY, -1),
		"request_token": _role_tokens.get(ROLE_RALLY, -1),
		"validity_reason": validity,
		"can_activate": validity == REASON_OK,
		"cooldown_remaining": _rally_cooldown_remaining,
		"active_remaining": _rally_active_remaining,
		"target_instance_id": int(_rally_candidate.get("target_instance_id", -1)),
		"target_id": StringName(_rally_candidate.get("target_id", &"")),
		"target_name": str(_rally_candidate.get("target_name", "NO AREA THREAT")),
		"attack_id": StringName(_rally_candidate.get("attack_id", &"")),
		"attack_name": str(_rally_candidate.get("attack_name", "NO AREA THREAT")),
		"window_seconds": float(_rally_candidate.get("window_seconds", 0.0)),
		"target_position": _rally_candidate.get("target_position", Vector2.ZERO),
		"anchors": _rally_anchor_by_actor.values(),
	}


func _environment_signature() -> String:
	return "%s|%s|%d|%d" % [
		_selected_environment_id,
		_environment_validity_reason(),
		_environment_target_count(),
		_environment_charges_remaining,
	]


func _focus_signature() -> String:
	return "%s|%s|%d|%s" % [
		_focus_validity_reason(),
		_focus_active_remaining > 0.0,
		int(_focus_candidate.get("target_instance_id", -1)),
		StringName(_focus_candidate.get("attack_id", &"")),
	]


func _backup_signature() -> String:
	var snapshot: Dictionary = (
		_call_backup_controller.get_snapshot() if _call_backup_controller != null else {}
	)
	return "%s|%d|%d|%d" % [
		_backup_validity_reason(),
		int(snapshot.get("charges_remaining", 0)),
		int(snapshot.get("active_token", -1)),
		int(snapshot.get("active_ally_count", 0)),
	]


func _rally_signature() -> String:
	return "%s|%s|%d|%s" % [
		_rally_validity_reason(),
		_rally_active_remaining > 0.0,
		int(_rally_candidate.get("target_instance_id", -1)),
		StringName(_rally_candidate.get("attack_id", &"")),
	]


func _environment_definition() -> WP05PrototypeActionDefinition:
	return (
		catalogue.get_action(_selected_environment_id)
		if catalogue != null and _selected_environment_id != ACTION_HYDRANT
		else null
	)


func _environment_targets() -> Array[ActorController]:
	var definition: WP05PrototypeActionDefinition = _environment_definition()
	if _combat_director == null or definition == null:
		return []
	return _combat_director.get_live_targets_in_circle(
		ActorController.Team.ENEMY,
		definition.world_origin,
		definition.range_radius
	)


func _environment_target_count() -> int:
	if _selected_environment_id == ACTION_HYDRANT:
		return (
			_fire_hydrant_controller.get_valid_target_count()
			if _fire_hydrant_controller != null
			else 0
		)
	return _environment_targets().size()


func _best_threat_candidate(defensive_only: bool) -> Dictionary:
	if _combat_director == null or not combat_available:
		return {}
	var candidates: Array[Dictionary] = []
	for actor: ActorController in _combat_director.get_live_actors(ActorController.Team.ENEMY):
		if not _is_actor_winding_up(actor):
			continue
		var attack: AttackDefinition = _active_attack(actor)
		if attack == null:
			continue
		if defensive_only and attack.delivery_kind not in [
			AttackDefinition.DeliveryKind.CHARGE,
			AttackDefinition.DeliveryKind.AREA,
		]:
			continue
		var role_score: int = 100
		if actor.is_boss():
			role_score = 300
		elif actor.is_elite():
			role_score = 200
		var delivery_score: int = {
			AttackDefinition.DeliveryKind.AREA: 60,
			AttackDefinition.DeliveryKind.CHARGE: 50,
			AttackDefinition.DeliveryKind.PROJECTILE: 40,
			AttackDefinition.DeliveryKind.SUMMON: 35,
			AttackDefinition.DeliveryKind.MELEE: 20 if attack.is_heavy() else 5,
		}.get(attack.delivery_kind, 0)
		candidates.append({
			"target_instance_id": actor.get_instance_id(),
			"target_id": actor.definition_id(),
			"target_name": actor.actor_definition.display_name,
			"target_position": actor.global_position,
			"registration_order": actor.registration_order,
			"attack_id": attack.id,
			"attack_name": attack.display_name,
			"delivery_kind": attack.delivery_kind,
			"window_seconds": maxf(actor.attack_controller.phase_remaining, 0.0),
			"score": role_score + delivery_score,
		})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(_threat_before)
	return candidates[0]


func _active_attack(actor: ActorController) -> AttackDefinition:
	if actor == null:
		return null
	var active_id: StringName = StringName(actor.get_snapshot().get("active_attack_id", &""))
	if actor.attack_definition != null and actor.attack_definition.id == active_id:
		return actor.attack_definition
	for attack: AttackDefinition in actor.special_attack_definitions:
		if attack != null and attack.id == active_id:
			return attack
	return null


func _is_actor_winding_up(actor: ActorController) -> bool:
	return (
		actor != null
		and is_instance_valid(actor)
		and actor.can_be_targeted()
		and actor.state_machine.current_state == ActorStateMachine.State.ATTACK_WINDUP
		and actor.attack_controller.current_phase == AttackController.Phase.WINDUP
	)


func _actor_by_instance_id(instance_id: int) -> ActorController:
	if _combat_director == null or instance_id <= 0:
		return null
	for actor: ActorController in _combat_director.get_live_actors(ActorController.Team.ENEMY):
		if actor.get_instance_id() == instance_id:
			return actor
	return null


func _permanent_crew() -> Array[ActorController]:
	return _encounter_controller.get_permanent_crew() if _encounter_controller != null else []


func _threat_opportunity_key(candidate: Dictionary) -> StringName:
	if candidate.is_empty():
		return &""
	return StringName("%d:%s" % [
		int(candidate.get("target_instance_id", -1)),
		StringName(candidate.get("attack_id", &"")),
	])


func _close_all_opportunities(reason: StringName) -> void:
	for role_id: StringName in [ROLE_ENVIRONMENT, ROLE_FOCUS, ROLE_BACKUP, ROLE_RALLY]:
		_telemetry.close_opportunity(role_id, reason)


func _accepted(action_id: StringName, result: Dictionary) -> Dictionary:
	return {
		"accepted": true,
		"reason": REASON_OK,
		"action_id": action_id,
		"result": result.duplicate(true),
	}


func _reject(role_id: StringName, action_id: StringName, reason: StringName) -> Dictionary:
	_telemetry.record_rejection(role_id, action_id, reason)
	action_rejected.emit(role_id, action_id, reason)
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
	_refresh_contexts(false)


func _on_backup_state_changed(_snapshot: Dictionary) -> void:
	_refresh_contexts(false)


func _threat_before(left: Dictionary, right: Dictionary) -> bool:
	var left_score: int = int(left.get("score", 0))
	var right_score: int = int(right.get("score", 0))
	if left_score != right_score:
		return left_score > right_score
	var left_window: float = float(left.get("window_seconds", 0.0))
	var right_window: float = float(right.get("window_seconds", 0.0))
	if not is_equal_approx(left_window, right_window):
		return left_window < right_window
	return int(left.get("registration_order", 0)) < int(right.get("registration_order", 0))


func _string_name_before(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
