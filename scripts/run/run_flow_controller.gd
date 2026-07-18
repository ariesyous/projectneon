class_name RunFlowController
extends Node

## Typed orchestration between lifecycle, patrol, combat encounters, rewards,
## and finite cooling. It owns no duplicated run state or gameplay ledger.

signal flow_status_changed(snapshot: Dictionary)
signal reward_ready(encounter_instance_id: int, reward: StandardRewardDefinition)
signal action_feedback(message: String)

@export var encounter_candidates: Array[EncounterDefinition] = []

var _run_director: RunDirector
var _patrol_controller: PatrolController
var _encounter_controller: RunEncounterController
var _reward_director: RewardDirector
var _cooling_controller: RunCoolingController
var _combat_director: CombatDirector
var _fire_hydrant_controller: FireHydrantController
var _next_encounter_instance_id: int = 1
var _pending_reward_encounter_id: int = -1


func configure(
	run_director: RunDirector,
	patrol_controller: PatrolController,
	encounter_controller: RunEncounterController,
	reward_director: RewardDirector,
	cooling_controller: RunCoolingController,
	combat_director: CombatDirector,
	fire_hydrant_controller: FireHydrantController
) -> void:
	_run_director = run_director
	_patrol_controller = patrol_controller
	_encounter_controller = encounter_controller
	_reward_director = reward_director
	_cooling_controller = cooling_controller
	_combat_director = combat_director
	_fire_hydrant_controller = fire_hydrant_controller

	_run_director.run_started.connect(_on_run_started)
	_run_director.run_state_changed.connect(_on_run_state_changed)
	_run_director.run_completed.connect(_on_run_completed)
	_run_director.snapshot_changed.connect(_on_authority_snapshot_changed)
	_patrol_controller.route_node_entered.connect(_on_route_node_entered)
	_patrol_controller.route_progress_changed.connect(_on_route_progress_changed)
	_encounter_controller.encounter_completed.connect(_on_encounter_completed)
	_encounter_controller.crew_defeated.connect(_on_crew_defeated)
	_encounter_controller.status_changed.connect(_on_encounter_status_changed)
	_cooling_controller.cooling_state_changed.connect(_on_cooling_state_changed)
	_cooling_controller.cooling_applied.connect(_on_cooling_applied)
	_cooling_controller.cooling_rejected.connect(_on_cooling_rejected)


func start_initial_run(supplied_seed: int = 0, use_supplied_seed: bool = false) -> int:
	return _run_director.start_run(supplied_seed, use_supplied_seed)


func claim_standard_reward() -> bool:
	if (
		_run_director.current_state != RunDirector.RunState.REWARD_SELECTION
		or _pending_reward_encounter_id < 0
		or not _reward_director.apply_standard_reward(_pending_reward_encounter_id)
	):
		action_feedback.emit("NO REWARD READY")
		return false
	_pending_reward_encounter_id = -1
	var continued: bool = _run_director.complete_reward_selection()
	_continue_patrol_if_active()
	return continued


func leave_shop() -> bool:
	if not _run_director.leave_shop():
		return false
	_continue_patrol_if_active()
	return true


func decline_extraction() -> bool:
	if not _run_director.decline_extraction():
		return false
	_continue_patrol_if_active()
	return true


func confirm_extraction() -> bool:
	return _run_director.confirm_extraction()


func enter_boss_trigger() -> bool:
	return _run_director.complete_boss_intro()


func request_subway_reroute() -> bool:
	return _cooling_controller.request_subway_reroute()


func request_shop_cooling() -> bool:
	return _cooling_controller.request_shop_cooling()


func restart_same_seed() -> int:
	return _run_director.restart_same_seed()


func restart_new_seed() -> int:
	return _run_director.restart_new_seed()


func force_add_heat(amount: int = 10) -> void:
	_run_director.apply_heat_delta(amount)


func force_advance_pressure_to_next_threshold() -> void:
	var target: float = _run_director.get_next_major_threshold()
	_run_director.add_night_pressure(maxf(target - _run_director.night_pressure, 0.0) + 0.001)


func force_defeat() -> bool:
	var crew: Array[ActorController] = _combat_director.get_live_actors(ActorController.Team.CREW)
	if crew.is_empty():
		return false
	return crew[0].receive_damage(1000000) > 0


func get_snapshot() -> Dictionary:
	return {
		"run": _run_director.get_snapshot() if _run_director != null else {},
		"patrol": _patrol_controller.get_snapshot() if _patrol_controller != null else {},
		"encounter": _encounter_controller.get_snapshot() if _encounter_controller != null else {},
		"rewards": _reward_director.get_debug_snapshot() if _reward_director != null else {},
		"cooling": _cooling_controller.get_snapshot() if _cooling_controller != null else {},
		"pending_reward_encounter_id": _pending_reward_encounter_id,
	}


func _on_run_started(_seed: int, _schema_version: int) -> void:
	_next_encounter_instance_id = 1
	_pending_reward_encounter_id = -1
	_reward_director.configure_random_streams(_run_director.get_random_streams())
	_reward_director.reset_for_run()
	_cooling_controller.reset_for_run()
	_patrol_controller.start_patrol()
	_fire_hydrant_controller.reset_for_run()
	if not _encounter_controller.start_run():
		push_error("Milestone 3 run could not initialize its encounter composition.")
	_emit_status()


func _on_run_state_changed(_previous_state: int, new_state: int) -> void:
	var simulation_active: bool = RunDirector.is_eligible_active_state(new_state)
	_combat_director.set_simulation_enabled(simulation_active)
	_reward_director.set_simulation_enabled(simulation_active)
	_fire_hydrant_controller.set_simulation_enabled(simulation_active)
	_patrol_controller.set_simulation_enabled(new_state == RunDirector.RunState.PATROLLING)
	_emit_status()


func _on_route_node_entered(
	_route_index: int,
	_node_id: StringName,
	node_type: StringName
) -> void:
	if _run_director.current_state != RunDirector.RunState.PATROLLING:
		return
	if _run_director.notify_safe_transition_boundary():
		_emit_status()
		return
	match node_type:
		&"encounter":
			_start_next_encounter()
		&"shop":
			_run_director.open_shop()
		_:
			_patrol_controller.continue_from_current_node()
	_emit_status()


func _start_next_encounter() -> void:
	var definition: EncounterDefinition = _run_director.select_encounter(encounter_candidates)
	if definition == null:
		_patrol_controller.continue_from_current_node()
		action_feedback.emit("NO ELIGIBLE ENCOUNTER")
		return
	var encounter_instance_id: int = _next_encounter_instance_id
	_next_encounter_instance_id += 1
	if not _run_director.begin_encounter(definition):
		return
	if not _encounter_controller.start_encounter(encounter_instance_id, definition):
		push_error("Encounter '%s' failed to start." % definition.id)


func _on_encounter_completed(
	encounter_instance_id: int,
	definition: EncounterDefinition
) -> void:
	if not _run_director.notify_encounter_completed(encounter_instance_id, definition):
		return
	_pending_reward_encounter_id = encounter_instance_id
	var reward: StandardRewardDefinition = _reward_director.prepare_standard_reward(
		encounter_instance_id,
		_run_director.get_reward_quality_tier(),
		definition.reward_table_ids
	)
	if reward != null:
		reward_ready.emit(encounter_instance_id, reward)
	_emit_status()


func _on_crew_defeated() -> void:
	_run_director.notify_all_crew_incapacitated()


func _on_run_completed(_result: int) -> void:
	_run_director.finalize_summary(
		_encounter_controller.get_total_enemies_defeated(),
		_reward_director.get_coin_total(),
		_reward_director.get_manual_clusters_collected(),
		_reward_director.get_maximum_manual_streak(),
		_reward_director.get_scrap_total()
	)


func _continue_patrol_if_active() -> void:
	if _run_director.current_state == RunDirector.RunState.PATROLLING:
		_patrol_controller.continue_from_current_node()


func _on_route_progress_changed(_route_index: int, _progress: float, _loop_count: int) -> void:
	_emit_status()


func _on_encounter_status_changed(_snapshot: Dictionary) -> void:
	_emit_status()


func _on_authority_snapshot_changed(_snapshot: Dictionary) -> void:
	_emit_status()


func _on_cooling_state_changed(_charges: int, _shop_remaining: int) -> void:
	_emit_status()


func _on_cooling_applied(source_id: StringName, heat_reduction: int) -> void:
	action_feedback.emit("%s COOLED HEAT -%d" % [String(source_id).to_upper(), heat_reduction])


func _on_cooling_rejected(source_id: StringName, reason: StringName) -> void:
	action_feedback.emit("%s REJECTED: %s" % [
		String(source_id).to_upper(),
		String(reason).replace("_", " ").to_upper(),
	])


func _emit_status() -> void:
	flow_status_changed.emit(get_snapshot())
