class_name RunFlowController
extends Node

## Typed orchestration between lifecycle, patrol, encounters, rewards, finite
## cooling, and District Cards. It coordinates authorities without duplicating
## their Heat, route, inventory, reward, or card ledgers.

signal flow_status_changed(snapshot: Dictionary)
signal reward_ready(encounter_instance_id: int, reward: StandardRewardDefinition)
signal equipment_reward_ready(
	encounter_instance_id: int,
	choices: Array[EquipmentDefinition]
)
signal card_reward_ready(
	encounter_instance_id: int,
	choice_token: int,
	choices: Array[DistrictCardDefinition],
	hand_revision: int,
	hand_full: bool
)
signal card_planning_changed(is_active: bool)
signal district_plan_choice_resolved(
	card_id: StringName,
	lap_id: StringName,
	block_id: StringName
)
signal action_feedback(message: String)

const ENCOUNTER_SOURCE_BASELINE: StringName = &"baseline"
const ENCOUNTER_SOURCE_ARCADE: StringName = &"arcade"
const ENCOUNTER_SOURCE_GANG_HIDEOUT: StringName = &"gang_hideout"
const SHOP_SOURCE_BASELINE: StringName = &"baseline_shop"
const SHOP_SOURCE_CONVENIENCE_STORE: StringName = &"convenience_store"

@export var encounter_candidates: Array[EncounterDefinition] = []
@export var boss_encounter_definition: EncounterDefinition

class RouteEntryContext:
	extends RefCounted

	var occurrence_index: int = -1
	var occurrence_id: StringName = &""
	var route_index: int = -1
	var node_id: StringName = &""
	var node_type: StringName = &""


class EncounterRewardContext:
	extends RefCounted

	var encounter_instance_id: int = -1
	var source_id: StringName = ENCOUNTER_SOURCE_BASELINE
	var reward_quality_tier_steps: int = 0
	var allows_card_reward: bool = false


var _run_director: RunDirector
var _patrol_controller: PatrolController
var _encounter_controller: RunEncounterController
var _reward_director: RewardDirector
var _cooling_controller: RunCoolingController
var _combat_director: CombatDirector
var _fire_hydrant_controller: FireHydrantController
var _synergy_system: SynergySystem
var _card_system: CardSystem
var _call_backup_controller: CallBackupController
var _combo_tracker: ComboTracker
var _cadence_tracker: RunCadenceTracker
var _starting_equipment: Array[EquipmentDefinition] = []
var _next_encounter_instance_id: int = 1
var _next_shop_opportunity_id: int = 1
var _pending_reward_encounter_id: int = -1
var _pending_card_reward_eligible: bool = false
var _card_reward_phase_active: bool = false
var _active_encounter_context: EncounterRewardContext
var _deferred_route_entry: RouteEntryContext
var _resetting_run: bool = false


func configure(
	run_director: RunDirector,
	patrol_controller: PatrolController,
	encounter_controller: RunEncounterController,
	reward_director: RewardDirector,
	cooling_controller: RunCoolingController,
	combat_director: CombatDirector,
	fire_hydrant_controller: FireHydrantController,
	synergy_system: SynergySystem = null,
	card_system: CardSystem = null,
	call_backup_controller: CallBackupController = null,
	combo_tracker: ComboTracker = null,
	cadence_tracker: RunCadenceTracker = null
) -> void:
	_run_director = run_director
	_patrol_controller = patrol_controller
	_encounter_controller = encounter_controller
	_reward_director = reward_director
	_cooling_controller = cooling_controller
	_combat_director = combat_director
	_fire_hydrant_controller = fire_hydrant_controller
	_synergy_system = synergy_system
	_card_system = card_system
	_call_backup_controller = call_backup_controller
	_combo_tracker = combo_tracker
	_cadence_tracker = cadence_tracker
	_reward_director.configure_equipment(_synergy_system)
	_reward_director.configure_cards(_card_system)
	if _card_system != null:
		_card_system.configure(_run_director.get_random_streams(), _patrol_controller)

	_run_director.run_started.connect(_on_run_started)
	_run_director.run_state_changed.connect(_on_run_state_changed)
	_run_director.run_completed.connect(_on_run_completed)
	_run_director.snapshot_changed.connect(_on_authority_snapshot_changed)
	_run_director.district_block_completed.connect(_on_district_block_completed)
	_patrol_controller.route_node_entered.connect(_on_route_node_entered)
	_patrol_controller.route_progress_changed.connect(_on_route_progress_changed)
	_patrol_controller.route_slots_changed.connect(_on_route_slots_changed)
	_encounter_controller.encounter_completed.connect(_on_encounter_completed)
	_encounter_controller.crew_defeated.connect(_on_crew_defeated)
	_encounter_controller.boss_defeated.connect(_on_boss_defeated)
	_encounter_controller.status_changed.connect(_on_encounter_status_changed)
	_cooling_controller.cooling_state_changed.connect(_on_cooling_state_changed)
	_cooling_controller.cooling_applied.connect(_on_cooling_applied)
	_cooling_controller.cooling_rejected.connect(_on_cooling_rejected)
	if _card_system != null:
		_card_system.snapshot_changed.connect(_on_card_snapshot_changed)


func configure_starting_equipment(items: Array[EquipmentDefinition]) -> bool:
	if items.size() != 1 or items[0] == null or items[0].id == &"":
		return false
	_starting_equipment = items.duplicate()
	return true


func start_initial_run(supplied_seed: int = 0, use_supplied_seed: bool = false) -> int:
	return _run_director.start_run(supplied_seed, use_supplied_seed)


func claim_standard_reward() -> bool:
	if (
		_run_director.current_state != RunDirector.RunState.REWARD_SELECTION
		or _pending_reward_encounter_id < 0
		or _card_reward_phase_active
		or not _reward_director.apply_standard_reward(_pending_reward_encounter_id)
	):
		action_feedback.emit("NO REWARD READY")
		return false
	return _finish_core_reward_selection()


func claim_equipment_reward(choice_index: int, slot_index: int = -1) -> bool:
	if (
		_run_director.current_state != RunDirector.RunState.REWARD_SELECTION
		or _pending_reward_encounter_id < 0
		or _card_reward_phase_active
		or not _reward_director.apply_equipment_choice(
			_pending_reward_encounter_id,
			choice_index,
			slot_index
		)
	):
		action_feedback.emit("EQUIPMENT CHOICE REJECTED")
		return false
	return _finish_core_reward_selection()


func claim_equipment_reward_to_inventory(
	choice_index: int,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int,
	replace_confirmed: bool,
	expected_revision: int
) -> bool:
	if (
		_run_director.current_state != RunDirector.RunState.REWARD_SELECTION
		or _pending_reward_encounter_id < 0
		or _card_reward_phase_active
		or not _reward_director.apply_equipment_choice_to_inventory(
			_pending_reward_encounter_id,
			choice_index,
			destination,
			equipment_slot,
			backpack_slot,
			replace_confirmed,
			expected_revision
		)
	):
		action_feedback.emit("EQUIPMENT CHOICE REJECTED")
		return false
	return _finish_core_reward_selection()


func decline_equipment_reward() -> bool:
	if (
		_run_director.current_state != RunDirector.RunState.REWARD_SELECTION
		or _pending_reward_encounter_id < 0
		or _card_reward_phase_active
		or not _reward_director.decline_equipment_reward(_pending_reward_encounter_id)
	):
		action_feedback.emit("EQUIPMENT REWARD STILL WAITING")
		return false
	return _finish_core_reward_selection()


func claim_card_reward(
	encounter_instance_id: int,
	choice_token: int,
	choice_index: int,
	expected_hand_revision: int
) -> bool:
	if (
		_run_director.current_state != RunDirector.RunState.REWARD_SELECTION
		or not _card_reward_phase_active
		or _pending_reward_encounter_id < 0
		or encounter_instance_id != _pending_reward_encounter_id
	):
		action_feedback.emit("NO DISTRICT CARD READY")
		return false
	var card: DistrictCardDefinition = _reward_director.acquire_card_choice(
		_pending_reward_encounter_id,
		choice_token,
		choice_index,
		expected_hand_revision
	)
	if card == null:
		action_feedback.emit(
			"KEEP HAND OR PLAY A CARD FIRST"
			if _reward_director.is_card_hand_full()
			else "DISTRICT CARD CHOICE REJECTED"
		)
		return false
	action_feedback.emit("%s ADDED TO HAND" % card.display_name.to_upper())
	_card_reward_phase_active = false
	return _finish_reward_selection()


func skip_card_reward(encounter_instance_id: int, choice_token: int) -> bool:
	if (
		_run_director.current_state != RunDirector.RunState.REWARD_SELECTION
		or not _card_reward_phase_active
		or _pending_reward_encounter_id < 0
		or encounter_instance_id != _pending_reward_encounter_id
		or not _reward_director.skip_card_choice(
			_pending_reward_encounter_id,
			choice_token
		)
	):
		action_feedback.emit("DISTRICT CARD REWARD STILL WAITING")
		return false
	_card_reward_phase_active = false
	action_feedback.emit("CURRENT HAND KEPT")
	return _finish_reward_selection()


func begin_card_planning() -> bool:
	if _card_system != null and _card_system.is_focused_district_plan_enabled():
		action_feedback.emit("DISTRICT PLAN OPENS WHEN THE NEXT BLOCK NEEDS A CHOICE")
		return false
	if _card_system == null or _run_director.current_state not in [
		RunDirector.RunState.PATROLLING,
		RunDirector.RunState.SHOP,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
	]:
		action_feedback.emit("PLAN DISTRICT CARDS DURING SAFE TRAVEL")
		return false
	var owns_pause: bool = _run_director.current_state == RunDirector.RunState.PATROLLING
	if owns_pause and not _run_director.begin_card_planning_pause():
		action_feedback.emit("DISTRICT CARD PLANNING UNAVAILABLE")
		return false
	if not _card_system.begin_planning(owns_pause):
		if owns_pause:
			_run_director.end_card_planning_pause()
		action_feedback.emit("DISTRICT CARD PLANNING UNAVAILABLE")
		return false
	card_planning_changed.emit(true)
	_emit_status()
	return true


func end_card_planning() -> bool:
	if _card_system == null or not _card_system.is_planning_active():
		return false
	if (
		_card_system.is_focused_district_plan_enabled()
		and not _card_system.has_focused_next_block_selection()
	):
		action_feedback.emit("CHOOSE THE NEXT BLOCK BEFORE CONTINUING")
		return false
	var owns_pause: bool = _card_system.planning_owns_pause()
	_card_system.end_planning()
	var resumed: bool = true
	if owns_pause:
		resumed = _run_director.end_card_planning_pause()
	card_planning_changed.emit(false)
	if _card_system.is_focused_district_plan_enabled():
		_continue_patrol_if_active()
	_emit_status()
	return resumed


func stage_focused_district_plan_choice(
	card_id: StringName,
	expected_offer_revision: int,
	expected_lifecycle_revision: int,
	expected_lap_id: StringName,
	expected_block_id: StringName
) -> Dictionary:
	if _card_system == null or not _card_system.is_focused_district_plan_enabled():
		return _card_action_result(false, &"focused_plan_unavailable")
	if not _is_card_planning_state_allowed(_run_director.current_state):
		var invalid_state: Dictionary = _focused_card_action_result(
			false,
			&"planning_state_invalid"
		)
		_emit_focused_card_rejection(&"planning_state_invalid")
		return invalid_state
	var current: Dictionary = _run_director.get_district_loop_snapshot()
	if (
		String(current.get("phase_name", "")) != "PLAN"
		or int(current.get("lifecycle_revision", -1)) != expected_lifecycle_revision
		or StringName(current.get("lap_id", &"")) != expected_lap_id
		or StringName(current.get("block_id", &"")) != expected_block_id
	):
		var stale: Dictionary = _focused_card_action_result(false, &"transition_race")
		_emit_focused_card_rejection(&"transition_race")
		return stale
	var result: Dictionary = _card_system.stage_focused_district_plan_choice(
		card_id,
		expected_offer_revision,
		expected_lifecycle_revision,
		expected_lap_id,
		expected_block_id
	)
	if bool(result.get("accepted", false)):
		action_feedback.emit(
			"CONFIRM %s AS THE NEXT BLOCK"
			% String(card_id).replace("_", " ").to_upper()
		)
	else:
		_emit_focused_card_rejection(result.get("reason", &"invalid"))
	_emit_status()
	return result


func confirm_focused_district_plan_choice(
	confirmation_token: int
) -> Dictionary:
	if _card_system == null or not _card_system.is_focused_district_plan_enabled():
		return _focused_card_action_result(false, &"focused_plan_unavailable")
	if (
		not _card_system.is_planning_active()
		or not _is_card_planning_state_allowed(_run_director.current_state)
	):
		_end_card_planning_for_unsafe_state(_run_director.current_state)
		var unsafe: Dictionary = _focused_card_action_result(
			false,
			&"planning_state_invalid"
		)
		_emit_focused_card_rejection(&"planning_state_invalid")
		_emit_status()
		return unsafe
	var record: CardPlacementRecord = (
		_card_system.confirm_focused_district_plan_choice(
			confirmation_token,
			_run_director.get_district_loop_snapshot()
		)
	)
	if record == null or record.card == null:
		var rejected: Dictionary = _focused_card_action_result(
			false,
			&"stale_or_invalid"
		)
		_emit_focused_card_rejection(&"stale_or_invalid")
		_emit_status()
		return rejected

	# CardSystem has latched the exact block/token before this sole Heat call.
	# Replayed confirmation cannot return the record and therefore cannot heat.
	_run_director.apply_heat_delta(record.card.heat_delta)
	var result: Dictionary = _focused_card_action_result(true, &"ok")
	result.merge({
		"completed": true,
		"confirmation_token": record.placement_token,
		"card_id": record.card.id,
		"card_name": record.card.display_name,
		"block_id": record.slot_id,
		"block_type": CardSystem.focused_block_type(record.card),
		"special_rule": CardSystem.focused_special_rule(record.card),
		"heat_delta": record.card.heat_delta,
	})
	action_feedback.emit(
		"NEXT BLOCK: %s / %s / HEAT %s%d"
		% [
			record.card.display_name.to_upper(),
			CardSystem.focused_block_type(record.card),
			"+" if record.card.heat_delta >= 0 else "",
			record.card.heat_delta,
		]
	)
	end_card_planning()
	_emit_status()
	return result


func cancel_focused_district_plan_choice(
	confirmation_token: int = -1
) -> bool:
	if (
		_card_system == null
		or not _card_system.cancel_focused_district_plan_choice(confirmation_token)
	):
		return false
	action_feedback.emit("SELECTION CLEARED - OFFER UNCHANGED")
	_emit_status()
	return true


func stage_card_placement(
	card_id: StringName,
	slot_id: StringName,
	expected_hand_revision: int,
	expected_route_revision: int
) -> Dictionary:
	if _card_system == null:
		return _card_action_result(false, &"cards_unavailable")
	var result: Dictionary = _card_system.stage_placement(
		card_id,
		slot_id,
		expected_hand_revision,
		expected_route_revision
	)
	if not bool(result.get("accepted", false)):
		_emit_card_rejection(result.get("reason", &"invalid"))
	else:
		action_feedback.emit("CONFIRM %s PLACEMENT" % String(card_id).replace("_", " ").to_upper())
	_emit_status()
	return result


func confirm_card_placement(confirmation_token: int) -> Dictionary:
	if _card_system == null:
		return _card_action_result(false, &"cards_unavailable")
	if (
		not _card_system.is_planning_active()
		or not _is_card_planning_state_allowed(_run_director.current_state)
	):
		_end_card_planning_for_unsafe_state(_run_director.current_state)
		var unsafe_state: Dictionary = _card_action_result(false, &"planning_state_invalid")
		_emit_card_rejection(&"planning_state_invalid")
		_emit_status()
		return unsafe_state
	var record: CardPlacementRecord = _card_system.confirm_staged_placement(
		confirmation_token
	)
	if record == null or record.card == null:
		var rejected: Dictionary = _card_action_result(false, &"stale_or_invalid")
		_emit_card_rejection(&"stale_or_invalid")
		_emit_status()
		return rejected
	# CardSystem latches the placement token and moves the card to discard before
	# this exact-once Heat call. Repeating the confirmation returns null.
	_run_director.apply_heat_delta(record.card.heat_delta)
	var result: Dictionary = _card_action_result(true, &"ok")
	result["confirmation_token"] = record.placement_token
	result["card_id"] = record.card.id
	result["card_name"] = record.card.display_name
	result["slot_id"] = record.slot_id
	result["heat_delta"] = record.card.heat_delta
	action_feedback.emit("%s PLACED - HEAT %s%d" % [
		record.card.display_name.to_upper(),
		"+" if record.card.heat_delta >= 0 else "",
		record.card.heat_delta,
	])
	_emit_status()
	return result


func cancel_card_placement(confirmation_token: int = -1) -> bool:
	if (
		_card_system == null
		or not _card_system.cancel_staged_placement(confirmation_token)
	):
		return false
	action_feedback.emit("CARD RETURNED TO HAND")
	_emit_status()
	return true


func reject_outside_card_drop(_card_id: StringName) -> Dictionary:
	var result: Dictionary = _card_action_result(false, &"outside")
	action_feedback.emit("INVALID DROP - CARD RETURNED TO HAND")
	return result


func leave_shop() -> bool:
	if not _run_director.leave_shop():
		return false
	_cooling_controller.end_shop_visit()
	_continue_patrol_if_active()
	return true


func decline_extraction(decision_token: int = -1) -> bool:
	if not _run_director.decline_extraction(decision_token):
		return false
	if _deferred_route_entry != null:
		var entry: RouteEntryContext = _deferred_route_entry
		_deferred_route_entry = null
		_dispatch_route_entry(entry)
	else:
		_continue_patrol_if_active()
	return true


func confirm_extraction(decision_token: int = -1) -> bool:
	return _run_director.confirm_extraction(decision_token)


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


func return_to_main_menu() -> bool:
	if not _run_director.return_to_initializing():
		return false
	_resetting_run = true
	_next_encounter_instance_id = 1
	_next_shop_opportunity_id = 1
	_pending_reward_encounter_id = -1
	_pending_card_reward_eligible = false
	_card_reward_phase_active = false
	_active_encounter_context = null
	_deferred_route_entry = null
	_encounter_controller.reset_for_run()
	_reward_director.reset_for_run()
	if _synergy_system != null:
		_synergy_system.reset_for_run()
	_cooling_controller.reset_for_run()
	_fire_hydrant_controller.reset_for_run()
	if _card_system != null:
		_card_system.clear_for_main_menu()
	if _call_backup_controller != null:
		_call_backup_controller.reset_for_run()
	if _combo_tracker != null:
		_combo_tracker.reset_for_run()
	if _cadence_tracker != null:
		_cadence_tracker.reset_for_run()
	_starting_equipment.clear()
	_resetting_run = false
	_emit_status()
	return true


func force_add_heat(amount: int = 10) -> void:
	_run_director.apply_heat_delta(amount)


func force_advance_pressure_to_next_threshold() -> void:
	var target: float = _run_director.get_next_major_threshold()
	_run_director.add_night_pressure(maxf(target - _run_director.night_pressure, 0.0) + 0.001)


func force_defeat() -> bool:
	var crew: Array[ActorController] = _combat_director.get_live_actors(ActorController.Team.CREW)
	var affected: bool = false
	for actor: ActorController in crew:
		if actor.is_permanent_crew():
			affected = actor.receive_damage(1000000) > 0 or affected
	return affected


func get_snapshot() -> Dictionary:
	return {
		"run": _run_director.get_snapshot() if _run_director != null else {},
		"patrol": _patrol_controller.get_snapshot() if _patrol_controller != null else {},
		"encounter": _encounter_controller.get_snapshot() if _encounter_controller != null else {},
		"rewards": _reward_director.get_debug_snapshot() if _reward_director != null else {},
		"cooling": _cooling_controller.get_snapshot() if _cooling_controller != null else {},
		"build": _synergy_system.get_snapshot() if _synergy_system != null else {},
		"cards": _card_system.get_snapshot() if _card_system != null else {},
		"backup": (
			_call_backup_controller.get_snapshot()
			if _call_backup_controller != null
			else {}
		),
		"combo": _combo_tracker.get_snapshot() if _combo_tracker != null else {},
		"cadence": _cadence_tracker.get_snapshot() if _cadence_tracker != null else {},
		"pending_reward_encounter_id": _pending_reward_encounter_id,
		"card_reward_phase_active": _card_reward_phase_active,
		"pending_card_reward_eligible": _pending_card_reward_eligible,
		"deferred_route_occurrence_id": (
			_deferred_route_entry.occurrence_id if _deferred_route_entry != null else &""
		),
	}


func _on_run_started(_seed: int, _schema_version: int) -> void:
	_resetting_run = true
	_next_encounter_instance_id = 1
	_next_shop_opportunity_id = 1
	_pending_reward_encounter_id = -1
	_pending_card_reward_eligible = false
	_card_reward_phase_active = false
	_active_encounter_context = null
	_deferred_route_entry = null
	_reward_director.configure_random_streams(_run_director.get_random_streams())
	_reward_director.reset_for_run()
	if _synergy_system != null:
		_synergy_system.reset_for_run()
		for item: EquipmentDefinition in _starting_equipment:
			if not _synergy_system.equip(item):
				push_error("Starting equipment '%s' could not be equipped." % item.id)
	if _call_backup_controller != null:
		_call_backup_controller.reset_for_run()
	if _combo_tracker != null:
		_combo_tracker.reset_for_run()
	if _cadence_tracker != null:
		_cadence_tracker.reset_for_run()
	_cooling_controller.reset_for_run()
	_patrol_controller.start_patrol()
	if _card_system != null:
		_card_system.configure(_run_director.get_random_streams(), _patrol_controller)
		if not _card_system.reset_for_run():
			push_error("Milestone 5 district cards could not initialize their catalogue.")
	_fire_hydrant_controller.reset_for_run()
	if not _encounter_controller.start_run():
		push_error("Milestone 3 run could not initialize its encounter composition.")
	_resetting_run = false
	_emit_status()


func _on_run_state_changed(_previous_state: int, new_state: int) -> void:
	if new_state == RunDirector.RunState.INITIALIZING:
		_resetting_run = true
	_end_card_planning_for_unsafe_state(new_state)
	var simulation_active: bool = RunDirector.is_eligible_active_state(new_state)
	_combat_director.set_simulation_enabled(simulation_active)
	_reward_director.set_simulation_enabled(simulation_active)
	_fire_hydrant_controller.set_simulation_enabled(simulation_active)
	if _call_backup_controller != null:
		_call_backup_controller.set_simulation_enabled(simulation_active)
		_call_backup_controller.set_combat_available(
			new_state in [
				RunDirector.RunState.ENCOUNTER_ACTIVE,
				RunDirector.RunState.BOSS_ACTIVE,
			]
		)
		if new_state in [
			RunDirector.RunState.EXTRACTING,
			RunDirector.RunState.VICTORY,
			RunDirector.RunState.DEFEAT,
			RunDirector.RunState.RUN_SUMMARY,
			RunDirector.RunState.INITIALIZING,
		]:
			_call_backup_controller.cleanup_for_terminal_state()
	_patrol_controller.set_simulation_enabled(new_state == RunDirector.RunState.PATROLLING)
	if new_state == RunDirector.RunState.BOSS_ACTIVE:
		_start_boss_encounter()
	if new_state == RunDirector.RunState.PATROLLING:
		_begin_required_focused_district_plan()
	_emit_status()


func _start_boss_encounter() -> bool:
	if boss_encounter_definition == null or not boss_encounter_definition.boss:
		push_error("Milestone 6 boss encounter definition is missing or invalid.")
		return false
	if _encounter_controller.has_active_encounter():
		return _encounter_controller.get_active_definition() == boss_encounter_definition
	var encounter_instance_id: int = _next_encounter_instance_id
	_next_encounter_instance_id += 1
	if not _encounter_controller.start_boss_encounter(
		encounter_instance_id,
		boss_encounter_definition
	):
		push_error("The Viper boss encounter failed to start.")
		return false
	return true


func _on_route_node_entered(
	route_index: int,
	node_id: StringName,
	node_type: StringName
) -> void:
	if _run_director.current_state != RunDirector.RunState.PATROLLING:
		return
	var entry: RouteEntryContext = RouteEntryContext.new()
	entry.occurrence_index = _patrol_controller.get_current_occurrence_index()
	entry.occurrence_id = _patrol_controller.get_current_occurrence_id()
	entry.route_index = route_index
	entry.node_id = node_id
	entry.node_type = node_type
	# Progression has precedence. Keep the exact current occurrence deferred so
	# declining extraction resumes it rather than silently advancing past it.
	_deferred_route_entry = entry
	if _run_director.notify_safe_transition_boundary():
		_emit_status()
		return
	_deferred_route_entry = null
	_dispatch_route_entry(entry)


func _dispatch_route_entry(entry: RouteEntryContext) -> void:
	if entry == null or _run_director.current_state != RunDirector.RunState.PATROLLING:
		return
	if (
		_card_system != null
		and _card_system.is_focused_district_plan_enabled()
		and _run_director.is_district_loop_enabled()
	):
		_dispatch_focused_district_plan_entry(entry)
		return
	var current_modification: RouteModificationRecord = null
	if _card_system != null:
		current_modification = _patrol_controller.get_current_route_modification()
	var resolves_district_block: bool = (
		entry.node_type in [&"encounter", &"shop"]
		or current_modification != null
	)
	if (
		_run_director.is_district_loop_enabled()
		and resolves_district_block
		and not _run_director.begin_district_block(entry.occurrence_id, entry.node_type)
	):
		action_feedback.emit("BLOCK START REJECTED - ROUTE HELD")
		return
	var resolved: CardResolutionRecord
	if _card_system != null:
		resolved = _card_system.resolve_current_route_effect()
	if resolved != null and resolved.effect != null:
		_resolve_card_route_effect(resolved)
	else:
		_resolve_baseline_route_node(entry.node_type)
	_emit_status()


func _dispatch_focused_district_plan_entry(entry: RouteEntryContext) -> void:
	var card: DistrictCardDefinition = _card_system.get_focused_next_block_card()
	if card == null:
		action_feedback.emit("ROUTE HELD - CHOOSE THE NEXT DISTRICT BLOCK")
		return
	var block_kind: StringName = CardSystem.focused_block_kind(card)
	if not _run_director.begin_district_block(entry.occurrence_id, block_kind):
		action_feedback.emit("BLOCK START REJECTED - ROUTE HELD")
		return
	var resolved: CardResolutionRecord = (
		_card_system.resolve_focused_district_plan_block(
			entry.occurrence_index,
			entry.occurrence_id,
			entry.route_index,
			entry.node_id,
			entry.node_type,
			_run_director.get_district_loop_snapshot()
		)
	)
	if resolved == null or resolved.card == null or resolved.effect == null:
		push_error("Focused District Plan could not resolve its accepted next block.")
		action_feedback.emit("DISTRICT PLAN RESOLUTION FAILED - ROUTE HELD")
		return
	action_feedback.emit(
		"%s NOW: %s - %s"
		% [
			resolved.card.display_name.to_upper(),
			CardSystem.focused_block_type(resolved.card),
			CardSystem.focused_special_rule(resolved.card),
		]
	)
	district_plan_choice_resolved.emit(
		resolved.card.id,
		StringName(_run_director.get_district_loop_snapshot().get("lap_id", &"")),
		StringName(_run_director.get_district_loop_snapshot().get("block_id", &""))
	)
	_resolve_card_route_effect(resolved)
	_emit_status()


func _resolve_baseline_route_node(node_type: StringName) -> void:
	match node_type:
		&"encounter":
			_start_selected_encounter(ENCOUNTER_SOURCE_BASELINE, true, 0)
		&"shop":
			_open_shop_visit(SHOP_SOURCE_BASELINE, -1)
		_:
			_patrol_controller.continue_from_current_node()


func _resolve_card_route_effect(resolved: CardResolutionRecord) -> void:
	var effect: CardEffectDefinition = resolved.effect
	match effect.kind:
		CardEffectDefinition.EffectKind.ADD_STANDARD_ENCOUNTER:
			_start_selected_encounter(
				ENCOUNTER_SOURCE_ARCADE,
				false,
				effect.reward_quality_tier_steps,
				true
			)
		CardEffectDefinition.EffectKind.OPEN_ONE_PURCHASE_SHOP:
			_open_shop_visit(SHOP_SOURCE_CONVENIENCE_STORE, effect.maximum_purchases)
		CardEffectDefinition.EffectKind.ADD_ELITE_ENCOUNTER:
			var elite: EncounterDefinition = _get_unique_encounter_by_id(effect.encounter_id)
			if elite == null or not _start_encounter(
				elite,
				ENCOUNTER_SOURCE_GANG_HIDEOUT,
				false,
				0
			):
				action_feedback.emit("ELITE PLACEHOLDER UNAVAILABLE")
				_complete_failed_or_utility_block()
		CardEffectDefinition.EffectKind.REROUTE_SKIP_STANDARD:
			# This resolves the authored future-node reroute directly. It never
			# calls the finite Subway intervention and therefore changes no charge.
			action_feedback.emit("SUBWAY ROUTE SKIPPED ONE STANDARD ENCOUNTER")
			_complete_failed_or_utility_block()


func _start_selected_encounter(
	source_id: StringName,
	allows_card_reward: bool,
	reward_quality_tier_steps: int,
	standard_only: bool = false
) -> bool:
	var candidates: Array[EncounterDefinition] = encounter_candidates
	if standard_only:
		candidates = []
		for candidate: EncounterDefinition in encounter_candidates:
			if candidate != null and not candidate.elite_eligible and not candidate.boss:
				candidates.append(candidate)
	var definition: EncounterDefinition = _run_director.select_encounter(candidates)
	if definition == null:
		action_feedback.emit("NO ELIGIBLE ENCOUNTER")
		_complete_failed_or_utility_block()
		return false
	return _start_encounter(
		definition,
		source_id,
		allows_card_reward and not definition.elite_eligible,
		reward_quality_tier_steps
	)


func _start_encounter(
	definition: EncounterDefinition,
	source_id: StringName,
	allows_card_reward: bool,
	reward_quality_tier_steps: int
) -> bool:
	if definition == null:
		return false
	var encounter_instance_id: int = _next_encounter_instance_id
	_next_encounter_instance_id += 1
	if not _run_director.begin_encounter(definition):
		return false
	var context: EncounterRewardContext = EncounterRewardContext.new()
	context.encounter_instance_id = encounter_instance_id
	context.source_id = source_id
	context.allows_card_reward = allows_card_reward
	context.reward_quality_tier_steps = maxi(reward_quality_tier_steps, 0)
	_active_encounter_context = context
	if not _encounter_controller.start_encounter(encounter_instance_id, definition):
		_active_encounter_context = null
		push_error("Encounter '%s' failed to start." % definition.id)
		return false
	return true


func _open_shop_visit(source_id: StringName, maximum_purchases: int) -> bool:
	if not _cooling_controller.begin_shop_visit(source_id, maximum_purchases):
		action_feedback.emit("SHOP VISIT UNAVAILABLE")
		_complete_failed_or_utility_block()
		return false
	if not _run_director.open_shop():
		_cooling_controller.end_shop_visit()
		return false
	if _cadence_tracker != null and not _run_director.is_district_loop_enabled():
		_cadence_tracker.record_strategic_opportunity(
			StringName("shop:%s:%d" % [source_id, _next_shop_opportunity_id]),
			_run_director.run_elapsed_seconds
		)
	_next_shop_opportunity_id += 1
	return true


func _on_encounter_completed(
	encounter_instance_id: int,
	definition: EncounterDefinition
) -> void:
	if not _run_director.notify_encounter_completed(encounter_instance_id, definition):
		return
	var context: EncounterRewardContext = _active_encounter_context
	if context == null or context.encounter_instance_id != encounter_instance_id:
		context = EncounterRewardContext.new()
		context.encounter_instance_id = encounter_instance_id
		context.source_id = ENCOUNTER_SOURCE_BASELINE
		context.allows_card_reward = not definition.elite_eligible
	_active_encounter_context = null
	_pending_reward_encounter_id = encounter_instance_id
	_pending_card_reward_eligible = (
		not (
			_card_system != null
			and _card_system.is_focused_district_plan_enabled()
		)
		and context.source_id == ENCOUNTER_SOURCE_BASELINE
		and context.allows_card_reward
		and not definition.elite_eligible
	)
	_card_reward_phase_active = false

	var maximum_quality_tier: int = _run_director.get_reward_quality_tier()
	var allowed_reward_ids: Array[StringName] = definition.reward_table_ids
	if context.reward_quality_tier_steps > 0:
		# Arcade advances through the globally authored tier ladder (0, 1, 3 in
		# this slice), skips absent tiers, and clamps at the catalogue maximum.
		maximum_quality_tier = _reward_director.get_advanced_authored_quality_tier(
			maximum_quality_tier,
			[],
			context.reward_quality_tier_steps
		)
		allowed_reward_ids = []
	var reward: StandardRewardDefinition = _reward_director.prepare_standard_reward(
		encounter_instance_id,
		maximum_quality_tier,
		allowed_reward_ids
	)
	if reward != null:
		reward_ready.emit(encounter_instance_id, reward)
	var equipment_choices: Array[EquipmentDefinition] = (
		_reward_director.prepare_equipment_choices(encounter_instance_id)
	)
	if not equipment_choices.is_empty():
		equipment_reward_ready.emit(encounter_instance_id, equipment_choices)
	_emit_status()


func _finish_core_reward_selection() -> bool:
	if _prepare_supplemental_card_reward():
		return true
	return _finish_reward_selection()


func _prepare_supplemental_card_reward() -> bool:
	if (
		(_card_system != null and _card_system.is_focused_district_plan_enabled())
		or not _pending_card_reward_eligible
		or _card_system == null
		or _pending_reward_encounter_id < 0
	):
		return false
	var choices: Array[DistrictCardDefinition] = _reward_director.prepare_card_choices(
		_pending_reward_encounter_id
	)
	if choices.is_empty():
		return false
	_pending_card_reward_eligible = false
	_card_reward_phase_active = true
	card_reward_ready.emit(
		_pending_reward_encounter_id,
		_reward_director.get_pending_card_choice_token(),
		choices,
		_reward_director.get_card_hand_revision(),
		_reward_director.is_card_hand_full()
	)
	_emit_status()
	return true


func _on_crew_defeated() -> void:
	_run_director.notify_all_crew_incapacitated()


func _on_boss_defeated(_boss: ActorController) -> void:
	_run_director.notify_boss_defeated()


func _on_run_completed(_result: int) -> void:
	# Optional coin input never gates base rewards. Terminal outcomes can arrive
	# before a visible cluster's ordinary timeout (notably extraction or defeat),
	# so settle those awards before freezing the summary ledger.
	_reward_director.settle_pending_coin_clusters_as_base()
	_run_director.finalize_summary(
		_encounter_controller.get_total_enemies_defeated(),
		_reward_director.get_coin_total(),
		_reward_director.get_manual_clusters_collected(),
		_reward_director.get_maximum_manual_streak(),
		_reward_director.get_scrap_total(),
		_synergy_system.get_build_summary() if _synergy_system != null else "None",
		_synergy_system.get_active_synergy_summary() if _synergy_system != null else "None",
		_encounter_controller.get_total_elites_defeated(),
		_combo_tracker.get_highest_combo() if _combo_tracker != null else 0,
		""
	)


func _continue_patrol_if_active() -> void:
	if _run_director.current_state == RunDirector.RunState.PATROLLING:
		_patrol_controller.continue_from_current_node()


func _complete_failed_or_utility_block() -> void:
	if _run_director.is_district_loop_enabled():
		if not _run_director.complete_district_utility_block():
			action_feedback.emit("BLOCK COMPLETION REJECTED - ROUTE HELD")
			return
		# A utility completion can keep the run in PATROLLING while advancing the
		# lifecycle back to PLAN. Open the required choice only after the
		# completion call has returned, avoiding a re-entrant pause transition.
		_begin_required_focused_district_plan()
	_continue_patrol_if_active()


func _finish_reward_selection() -> bool:
	_pending_reward_encounter_id = -1
	_pending_card_reward_eligible = false
	_card_reward_phase_active = false
	var continued: bool = _run_director.complete_reward_selection()
	_continue_patrol_if_active()
	_emit_status()
	return continued


func _get_unique_encounter_by_id(encounter_id: StringName) -> EncounterDefinition:
	var result: EncounterDefinition = null
	for candidate: EncounterDefinition in encounter_candidates:
		if candidate == null or candidate.id != encounter_id:
			continue
		if result != null:
			return null
		result = candidate
	return result


func _card_action_result(accepted: bool, reason: StringName) -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"confirmation_token": -1,
		"hand_revision": _card_system.get_hand_revision() if _card_system != null else -1,
		"route_revision": (
			_patrol_controller.get_route_revision()
			if _patrol_controller != null
			else -1
		),
	}


func _focused_card_action_result(accepted: bool, reason: StringName) -> Dictionary:
	var district: Dictionary = (
		_run_director.get_district_loop_snapshot()
		if _run_director != null
		else {}
	)
	var cards: Dictionary = _card_system.get_snapshot() if _card_system != null else {}
	return {
		"accepted": accepted,
		"reason": reason,
		"confirmation_token": -1,
		"offer_revision": int(cards.get("offer_revision", -1)),
		"lifecycle_revision": int(district.get("lifecycle_revision", -1)),
		"lap_id": StringName(district.get("lap_id", &"")),
		"block_id": StringName(district.get("block_id", &"")),
	}


func _emit_card_rejection(reason_value: Variant) -> void:
	var reason: String = String(reason_value).replace("_", " ").to_upper()
	action_feedback.emit("INVALID CARD PLACEMENT: %s - RETURNED TO HAND" % reason)


func _emit_focused_card_rejection(reason_value: Variant) -> void:
	var reason: String = String(reason_value).replace("_", " ").to_upper()
	action_feedback.emit("DISTRICT PLAN UNCHANGED: %s" % reason)


func _is_card_planning_state_allowed(state: int) -> bool:
	if state in [RunDirector.RunState.SHOP, RunDirector.RunState.EXTRACTION_AVAILABLE]:
		return true
	return (
		state == RunDirector.RunState.PAUSED
		and _card_system != null
		and _card_system.planning_owns_pause()
		and _run_director != null
		and _run_director.is_card_planning_pause_active()
	)


func _end_card_planning_for_unsafe_state(state: int) -> bool:
	if (
		_card_system == null
		or not _card_system.is_planning_active()
		or _is_card_planning_state_allowed(state)
	):
		return false
	# The run state has already changed synchronously. Clear CardSystem's staged
	# token and planning latch without attempting a second lifecycle transition.
	_card_system.end_planning()
	card_planning_changed.emit(false)
	return true


func _on_route_progress_changed(_route_index: int, _progress: float, _loop_count: int) -> void:
	_emit_status()


func _on_route_slots_changed(_slots: Array[RouteSlotSnapshot], _revision: int) -> void:
	_emit_status()


func _on_encounter_status_changed(_snapshot: Dictionary) -> void:
	_emit_status()


func _on_authority_snapshot_changed(_snapshot: Dictionary) -> void:
	_emit_status()


func _on_district_block_completed(
	lap_index: int,
	block_index: int,
	_block_id: StringName
) -> void:
	if _card_system != null and _card_system.is_focused_district_plan_enabled():
		_card_system.complete_focused_district_plan_block(lap_index, block_index)


func _begin_required_focused_district_plan() -> bool:
	if (
		_resetting_run
		or _card_system == null
		or not _card_system.is_focused_district_plan_enabled()
		or _card_system.is_planning_active()
		or _card_system.has_focused_next_block_selection()
		or _run_director.current_state != RunDirector.RunState.PATROLLING
	):
		return false
	var district: Dictionary = _run_director.get_district_loop_snapshot()
	if String(district.get("phase_name", "")) != "PLAN":
		return false
	if not _run_director.begin_card_planning_pause():
		action_feedback.emit("DISTRICT PLAN COULD NOT PAUSE AT THE SAFE BOUNDARY")
		return false
	if not _card_system.begin_focused_district_plan(district, true):
		_run_director.end_card_planning_pause()
		action_feedback.emit("NO DISTRICT PLAN CHOICE IS AVAILABLE")
		return false
	card_planning_changed.emit(true)
	_emit_status()
	return true


func _on_card_snapshot_changed(_snapshot: Dictionary) -> void:
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
	if _resetting_run:
		return
	flow_status_changed.emit(get_snapshot())
