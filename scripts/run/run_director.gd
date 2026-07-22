class_name RunDirector
extends Node

## Sole authority for the Milestone 3 lifecycle, active-time clock, tactical
## Heat, irreversible Night Pressure, latched thresholds, outcomes, seed, and
## run-scoped named random streams. It coordinates but never spawns actors,
## credits rewards, advances patrol movement, or owns UI controls.

signal run_state_changed(previous_state: int, new_state: int)
signal transition_rejected(current_state: int, requested_state: int)
signal run_started(seed: int, random_schema_version: int)
signal run_reset_requested(restart_with_same_seed: bool)
signal heat_changed(previous_value: int, new_value: int)
signal heat_tier_changed(previous_tier: int, new_tier: int)
signal night_pressure_changed(previous_value: float, new_value: float)
signal extraction_threshold_latched(threshold_index: int, threshold_value: float)
signal extraction_became_available(threshold_index: int)
signal boss_queued()
signal boss_started()
signal encounter_completed_authoritatively(encounter_instance_id: int, definition: EncounterDefinition)
signal run_completed(result: int)
signal run_summary_ready(summary: RunSummaryRecord)
signal snapshot_changed(snapshot: Dictionary)
signal card_planning_pause_changed(is_active: bool)
signal boss_intro_timing_started(duration_seconds: float)
signal victory_presentation_started(duration_seconds: float)
signal victory_presentation_completed()

enum RunState {
	INITIALIZING,
	INTRO,
	PATROLLING,
	ENCOUNTER_ACTIVE,
	REWARD_SELECTION,
	SHOP,
	EXTRACTION_AVAILABLE,
	EXTRACTING,
	BOSS_INTRO,
	BOSS_ACTIVE,
	VICTORY,
	DEFEAT,
	RUN_SUMMARY,
	PAUSED,
}

enum RunResult {
	NONE,
	VICTORY,
	EXTRACTED,
	DEFEATED,
}

const RESPONSIBILITY: String = "Coordinate the authoritative run lifecycle."
const DEFAULT_HEAT: HeatDefinition = preload("res://data/run/milestone_3_heat.tres")
const DEFAULT_ESCALATION: RunEscalationDefinition = preload(
	"res://data/run/milestone_3_escalation.tres"
)
const INTRO_DURATION_SECONDS: float = 1.25
const EXTRACTION_DURATION_SECONDS: float = 1.0
const SNAPSHOT_INTERVAL_SECONDS: float = 0.10
const GENERATED_SEED_MODULUS: int = 2147483647

@export var heat_definition: HeatDefinition = DEFAULT_HEAT
@export var escalation_definition: RunEscalationDefinition = DEFAULT_ESCALATION
## Null preserves the accepted Milestone 3 behavior: boss intro waits for the
## explicit completion call and victory completes immediately. GameRun assigns
## the Milestone 6 Resource when the vertical-slice composition is enabled.
@export var lifecycle_definition: RunLifecycleDefinition

var current_state: int = RunState.INITIALIZING
var run_seed: int = 0
var run_elapsed_seconds: float = 0.0
var heat: int = 0
var maximum_heat: int = 0
var night_pressure: float = 0.0
var encounters_completed: int = 0

var _run_result: int = RunResult.NONE
var _state_before_pause: int = RunState.PATROLLING
var _intro_remaining: float = 0.0
var _extraction_remaining: float = 0.0
var _boss_intro_remaining: float = 0.0
var _victory_presentation_remaining: float = 0.0
var _snapshot_remaining: float = 0.0
var _boss_threshold_latched: bool = false
var _boss_queued: bool = false
var _boss_started: bool = false
var _extraction_confirmed: bool = false
var _current_extraction_threshold_index: int = -1
var _latched_extraction_thresholds: Dictionary[int, bool] = {}
var _spent_extraction_thresholds: Dictionary[int, bool] = {}
var _pending_extraction_thresholds: Array[int] = []
var _completed_encounter_ids: Dictionary[int, bool] = {}
var _generated_seed_nonce: int = 0
var _last_summary: RunSummaryRecord
var _random_streams: RunRandomStreams
var _card_planning_pause_owned: bool = false
var _ending_card_planning_pause: bool = false
var _run_completion_emitted: bool = false


func _ready() -> void:
	if heat_definition == null:
		heat_definition = DEFAULT_HEAT
	if escalation_definition == null:
		escalation_definition = DEFAULT_ESCALATION
	_ensure_random_streams()
	set_process(true)


func _process(delta: float) -> void:
	step_run(delta)


func step_run(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	if safe_delta <= 0.0:
		return
	if current_state == RunState.INTRO:
		_intro_remaining = maxf(_intro_remaining - safe_delta, 0.0)
		if _intro_remaining <= 0.0:
			complete_intro()
	elif current_state == RunState.EXTRACTING:
		_extraction_remaining = maxf(_extraction_remaining - safe_delta, 0.0)
		if _extraction_remaining <= 0.0 and _run_result == RunResult.NONE:
			_run_result = RunResult.EXTRACTED
			_emit_run_completed_once()
	elif current_state == RunState.BOSS_INTRO and _boss_intro_remaining > 0.0:
		_boss_intro_remaining = maxf(_boss_intro_remaining - safe_delta, 0.0)
		if _boss_intro_remaining <= 0.0:
			complete_boss_intro()
	elif (
		current_state == RunState.VICTORY
		and _run_result == RunResult.VICTORY
		and not _run_completion_emitted
	):
		_victory_presentation_remaining = maxf(
			_victory_presentation_remaining - safe_delta,
			0.0
		)
		if _victory_presentation_remaining <= 0.0:
			victory_presentation_completed.emit()
			_emit_run_completed_once()
	elif is_eligible_active_state(current_state):
		run_elapsed_seconds += safe_delta
		add_night_pressure(safe_delta * escalation_definition.passive_pressure_per_second)

	_snapshot_remaining -= safe_delta
	if _snapshot_remaining <= 0.0:
		_snapshot_remaining = SNAPSHOT_INTERVAL_SECONDS
		snapshot_changed.emit(get_snapshot())


func start_run(supplied_seed: int = 0, use_supplied_seed: bool = false) -> int:
	_ensure_random_streams()
	_reset_authoritative_state()
	run_seed = supplied_seed if use_supplied_seed else generate_run_seed()
	_random_streams.reset_for_seed(run_seed)
	run_started.emit(run_seed, _random_streams.get_random_schema_version())
	request_transition(RunState.INTRO)
	_intro_remaining = get_intro_duration_seconds()
	snapshot_changed.emit(get_snapshot())
	return run_seed


func restart_same_seed() -> int:
	var preserved_seed: int = run_seed
	run_reset_requested.emit(true)
	return start_run(preserved_seed, true)


func restart_new_seed() -> int:
	run_reset_requested.emit(false)
	return start_run()


## Explicit run abandonment used by the owner-authorized main-menu flow. It
## publishes the same INITIALIZING boundary as a restart but does not create a
## result, summary, seed draw, or persistence record.
func return_to_initializing() -> bool:
	if current_state == RunState.INITIALIZING:
		return true
	_reset_authoritative_state()
	snapshot_changed.emit(get_snapshot())
	return current_state == RunState.INITIALIZING


func generate_run_seed() -> int:
	_generated_seed_nonce += 1
	var time_entropy: int = int(Time.get_unix_time_from_system() * 1000000.0)
	var tick_entropy: int = Time.get_ticks_usec()
	var generated: int = absi(
		(time_entropy ^ tick_entropy ^ get_instance_id() ^ _generated_seed_nonce)
	) % GENERATED_SEED_MODULUS
	return generated if generated != 0 else 1


func request_transition(new_state: int) -> bool:
	if new_state < RunState.INITIALIZING or new_state > RunState.PAUSED:
		transition_rejected.emit(current_state, new_state)
		return false
	if new_state == current_state or not _is_transition_allowed(current_state, new_state):
		transition_rejected.emit(current_state, new_state)
		return false
	if (
		current_state == RunState.PAUSED
		and _card_planning_pause_owned
		and not _ending_card_planning_pause
	):
		transition_rejected.emit(current_state, new_state)
		return false
	var previous_state: int = current_state
	current_state = new_state
	run_state_changed.emit(previous_state, current_state)
	snapshot_changed.emit(get_snapshot())
	return true


func complete_intro() -> bool:
	if current_state != RunState.INTRO:
		return false
	_intro_remaining = 0.0
	return request_transition(RunState.PATROLLING)


func toggle_pause() -> bool:
	if current_state == RunState.PAUSED:
		if _card_planning_pause_owned:
			return false
		return request_transition(_state_before_pause)
	if not is_pauseable_state(current_state):
		return false
	_state_before_pause = current_state
	return request_transition(RunState.PAUSED)


## Card planning owns a pause only when entered from safe route travel. The
## ordinary Space toggle cannot release this pause behind an active card
## gesture or placement review.
func begin_card_planning_pause() -> bool:
	if _card_planning_pause_owned or current_state != RunState.PATROLLING:
		return false
	_state_before_pause = RunState.PATROLLING
	_card_planning_pause_owned = true
	if not request_transition(RunState.PAUSED):
		_card_planning_pause_owned = false
		return false
	card_planning_pause_changed.emit(true)
	return true


func end_card_planning_pause() -> bool:
	if (
		not _card_planning_pause_owned
		or current_state != RunState.PAUSED
		or _state_before_pause != RunState.PATROLLING
	):
		return false
	_ending_card_planning_pause = true
	_card_planning_pause_owned = false
	var resumed: bool = request_transition(RunState.PATROLLING)
	_ending_card_planning_pause = false
	if not resumed:
		_card_planning_pause_owned = true
		return false
	card_planning_pause_changed.emit(false)
	return true


func is_card_planning_pause_active() -> bool:
	return _card_planning_pause_owned and current_state == RunState.PAUSED


func begin_encounter(_definition: EncounterDefinition) -> bool:
	if _definition == null:
		return false
	return request_transition(RunState.ENCOUNTER_ACTIVE)


func notify_encounter_completed(
	encounter_instance_id: int,
	definition: EncounterDefinition
) -> bool:
	if (
		definition == null
		or encounter_instance_id < 0
		or _completed_encounter_ids.has(encounter_instance_id)
		or current_state != RunState.ENCOUNTER_ACTIVE
	):
		return false
	_completed_encounter_ids[encounter_instance_id] = true
	encounters_completed += 1
	apply_heat_delta(definition.heat_gain_on_completion)
	var completion_gain: float = (
		escalation_definition.pressure_per_elite_encounter
		if definition.elite_eligible
		else escalation_definition.pressure_per_standard_encounter
	)
	add_night_pressure(completion_gain)
	encounter_completed_authoritatively.emit(encounter_instance_id, definition)
	return request_transition(RunState.REWARD_SELECTION)


func complete_reward_selection() -> bool:
	if current_state != RunState.REWARD_SELECTION:
		return false
	if _begin_pending_progression():
		return true
	return request_transition(RunState.PATROLLING)


func open_shop() -> bool:
	return request_transition(RunState.SHOP)


func leave_shop() -> bool:
	if current_state != RunState.SHOP:
		return false
	if _begin_pending_progression():
		return true
	return request_transition(RunState.PATROLLING)


func notify_safe_transition_boundary() -> bool:
	if current_state != RunState.PATROLLING:
		return false
	return _begin_pending_progression()


func decline_extraction() -> bool:
	if current_state != RunState.EXTRACTION_AVAILABLE:
		return false
	if _current_extraction_threshold_index >= 0:
		_spent_extraction_thresholds[_current_extraction_threshold_index] = true
	_current_extraction_threshold_index = -1
	apply_heat_delta(6)
	return request_transition(RunState.PATROLLING)


func confirm_extraction() -> bool:
	if current_state != RunState.EXTRACTION_AVAILABLE or _boss_queued:
		return false
	_extraction_confirmed = true
	if _current_extraction_threshold_index >= 0:
		_spent_extraction_thresholds[_current_extraction_threshold_index] = true
	_current_extraction_threshold_index = -1
	if not request_transition(RunState.EXTRACTING):
		return false
	_extraction_remaining = get_extraction_duration_seconds()
	return true


func complete_boss_intro() -> bool:
	if current_state != RunState.BOSS_INTRO:
		return false
	_boss_intro_remaining = 0.0
	return request_transition(RunState.BOSS_ACTIVE)


func notify_boss_defeated() -> bool:
	if current_state != RunState.BOSS_ACTIVE:
		return false
	_run_result = RunResult.VICTORY
	_victory_presentation_remaining = get_victory_presentation_duration_seconds()
	if not request_transition(RunState.VICTORY):
		_run_result = RunResult.NONE
		_victory_presentation_remaining = 0.0
		return false
	victory_presentation_started.emit(_victory_presentation_remaining)
	if _victory_presentation_remaining <= 0.0:
		victory_presentation_completed.emit()
		_emit_run_completed_once()
	return true


func notify_all_crew_incapacitated() -> bool:
	if current_state not in [RunState.ENCOUNTER_ACTIVE, RunState.BOSS_ACTIVE]:
		return false
	_run_result = RunResult.DEFEATED
	if not request_transition(RunState.DEFEAT):
		_run_result = RunResult.NONE
		return false
	_emit_run_completed_once()
	return true


func finalize_summary(
	enemies_defeated: int,
	coins_collected: int,
	manual_clusters_collected: int,
	maximum_manual_streak: int,
	scrap_secured: int,
	equipment_build: String = "NOT AVAILABLE IN MILESTONE 3",
	active_synergies: String = "NOT AVAILABLE IN MILESTONE 3",
	elites_defeated: int = 0,
	highest_combo: int = 0,
	boss_result: String = ""
) -> RunSummaryRecord:
	if current_state not in [RunState.EXTRACTING, RunState.VICTORY, RunState.DEFEAT]:
		return null
	var summary: RunSummaryRecord = RunSummaryRecord.new()
	summary.result = _run_result
	summary.result_label = result_name(_run_result)
	summary.duration_seconds = run_elapsed_seconds
	summary.run_seed = run_seed
	summary.random_schema_version = get_random_schema_version()
	summary.maximum_heat = maximum_heat
	summary.final_night_pressure = night_pressure
	summary.encounters_completed = encounters_completed
	summary.enemies_defeated = maxi(enemies_defeated, 0)
	summary.elites_defeated = maxi(elites_defeated, 0)
	summary.boss_defeated = _run_result == RunResult.VICTORY
	summary.boss_result = (
		boss_result.strip_edges()
		if not boss_result.strip_edges().is_empty()
		else _derived_boss_result()
	)
	summary.coins_collected = maxi(coins_collected, 0)
	summary.manual_clusters_collected = maxi(manual_clusters_collected, 0)
	summary.maximum_manual_streak = maxi(maximum_manual_streak, 0)
	summary.scrap_secured = maxi(scrap_secured, 0)
	summary.equipment_build = equipment_build
	summary.active_synergies = active_synergies
	summary.boss_triggered = _boss_started
	summary.highest_combo = maxi(highest_combo, 0)
	_last_summary = summary
	request_transition(RunState.RUN_SUMMARY)
	run_summary_ready.emit(summary)
	return summary


func apply_heat_delta(delta: int) -> int:
	var previous_heat: int = heat
	var previous_tier: int = get_heat_tier()
	heat = heat_definition.clamp_heat(heat + delta)
	maximum_heat = maxi(maximum_heat, heat)
	if heat != previous_heat:
		heat_changed.emit(previous_heat, heat)
		var new_tier: int = get_heat_tier()
		if new_tier != previous_tier:
			heat_tier_changed.emit(previous_tier, new_tier)
		snapshot_changed.emit(get_snapshot())
	return heat


func add_night_pressure(amount: float) -> bool:
	if amount <= 0.0:
		return false
	var previous_pressure: float = night_pressure
	night_pressure = maxf(previous_pressure + amount, previous_pressure)
	_evaluate_threshold_crossings(previous_pressure, night_pressure)
	night_pressure_changed.emit(previous_pressure, night_pressure)
	return true


func select_encounter(candidates: Array[EncounterDefinition]) -> EncounterDefinition:
	_ensure_random_streams()
	var eligible_by_id: Dictionary[StringName, EncounterDefinition] = {}
	var duplicate_ids: Dictionary[StringName, bool] = {}
	var candidate_ids: Array[StringName] = []
	var current_tier: int = get_heat_tier()
	for candidate: EncounterDefinition in candidates:
		if candidate == null or candidate.boss:
			continue
		if candidate.minimum_heat_tier > current_tier:
			continue
		if candidate.minimum_night_pressure > night_pressure:
			continue
		if candidate.elite_eligible and not heat_definition.is_elite_available(current_tier):
			continue
		if candidate.id == &"" or duplicate_ids.has(candidate.id):
			continue
		if eligible_by_id.has(candidate.id):
			eligible_by_id.erase(candidate.id)
			candidate_ids.erase(candidate.id)
			duplicate_ids[candidate.id] = true
			continue
		eligible_by_id[candidate.id] = candidate
		candidate_ids.append(candidate.id)
	var selected_id: StringName = _random_streams.choose_stable_id(
		RunRandomStreams.STREAM_ENCOUNTERS,
		candidate_ids
	)
	return eligible_by_id.get(selected_id) as EncounterDefinition


func calculate_spawn_budget(definition: EncounterDefinition) -> int:
	if definition == null:
		return 0
	var scaled_budget: int = escalation_definition.scaled_spawn_budget(
		definition.base_spawn_budget,
		night_pressure,
		heat_definition.spawn_budget_addition_for_tier(get_heat_tier())
	)
	return mini(scaled_budget, escalation_definition.global_enemy_concurrency_limit)


func calculate_encounter_concurrency(
	definition: EncounterDefinition,
	remaining_budget: int,
	active_global_enemies: int = 0
) -> int:
	if definition == null:
		return 0
	return escalation_definition.capped_concurrency(
		remaining_budget,
		maxi(definition.maximum_concurrent_enemies - maxi(active_global_enemies, 0), 0),
		active_global_enemies
	)


func get_enemy_health_multiplier() -> float:
	return escalation_definition.health_multiplier(night_pressure)


func get_enemy_damage_multiplier() -> float:
	return (
		escalation_definition.damage_multiplier(night_pressure)
		* heat_definition.enemy_damage_multiplier_for_tier(get_heat_tier())
	)


func get_heat_tier() -> int:
	return heat_definition.tier_for_heat(heat)


func get_reward_quality_tier() -> int:
	return heat_definition.reward_quality_for_tier(get_heat_tier())


func get_reward_multiplier() -> float:
	return heat_definition.reward_multiplier_for_tier(get_heat_tier())


func is_elite_available() -> bool:
	return heat_definition.is_elite_available(get_heat_tier())


func is_boss_queued() -> bool:
	return _boss_queued


func is_boss_threshold_latched() -> bool:
	return _boss_threshold_latched


func was_boss_started() -> bool:
	return _boss_started


func is_extraction_threshold_latched(threshold_index: int) -> bool:
	return _latched_extraction_thresholds.has(threshold_index)


func is_extraction_threshold_spent(threshold_index: int) -> bool:
	return _spent_extraction_thresholds.has(threshold_index)


func get_pending_extraction_count() -> int:
	return _pending_extraction_thresholds.size()


func get_result() -> int:
	return _run_result


func get_last_summary() -> RunSummaryRecord:
	return _last_summary


func get_random_streams() -> RunRandomStreams:
	_ensure_random_streams()
	return _random_streams


func get_random_schema_version() -> int:
	_ensure_random_streams()
	return _random_streams.get_random_schema_version()


func get_intro_duration_seconds() -> float:
	return (
		maxf(lifecycle_definition.intro_duration_seconds, 0.0)
		if lifecycle_definition != null
		else INTRO_DURATION_SECONDS
	)


func get_extraction_duration_seconds() -> float:
	return (
		maxf(lifecycle_definition.extraction_duration_seconds, 0.0)
		if lifecycle_definition != null
		else EXTRACTION_DURATION_SECONDS
	)


func get_boss_intro_duration_seconds() -> float:
	return (
		maxf(lifecycle_definition.boss_intro_duration_seconds, 0.0)
		if lifecycle_definition != null
		else 0.0
	)


func get_victory_presentation_duration_seconds() -> float:
	return (
		maxf(lifecycle_definition.victory_presentation_duration_seconds, 0.0)
		if lifecycle_definition != null
		else 0.0
	)


func get_next_major_threshold() -> float:
	for threshold_index: int in range(escalation_definition.extraction_pressure_thresholds.size()):
		if not _latched_extraction_thresholds.has(threshold_index):
			return escalation_definition.extraction_pressure_thresholds[threshold_index]
	return escalation_definition.boss_pressure_threshold


func get_snapshot() -> Dictionary:
	return {
		"state": current_state,
		"state_name": state_name(current_state),
		"run_seed": run_seed,
		"random_schema_version": get_random_schema_version(),
		"run_elapsed_seconds": run_elapsed_seconds,
		"heat": heat,
		"heat_tier": get_heat_tier(),
		"reward_multiplier": get_reward_multiplier(),
		"maximum_heat": maximum_heat,
		"night_pressure": night_pressure,
		"next_major_threshold": get_next_major_threshold(),
		"boss_threshold": escalation_definition.boss_pressure_threshold,
		"boss_queued": _boss_queued,
		"boss_started": _boss_started,
		"boss_intro_remaining": _boss_intro_remaining,
		"victory_presentation_remaining": _victory_presentation_remaining,
		"extraction_available": current_state == RunState.EXTRACTION_AVAILABLE,
		"current_extraction_threshold_index": _current_extraction_threshold_index,
		"encounters_completed": encounters_completed,
		"eligible_time": is_eligible_active_state(current_state),
		"card_planning_pause_active": is_card_planning_pause_active(),
		"pause_origin_state": _state_before_pause if current_state == RunState.PAUSED else -1,
		"result": _run_result,
		"run_completion_emitted": _run_completion_emitted,
		"random_draw_counts": get_random_streams().get_debug_snapshot().get("draw_counts", {}),
	}


static func is_eligible_active_state(state: int) -> bool:
	return state in [RunState.PATROLLING, RunState.ENCOUNTER_ACTIVE, RunState.BOSS_ACTIVE]


static func is_pauseable_state(state: int) -> bool:
	return state in [
		RunState.PATROLLING,
		RunState.ENCOUNTER_ACTIVE,
		RunState.REWARD_SELECTION,
		RunState.SHOP,
		RunState.EXTRACTION_AVAILABLE,
		RunState.BOSS_ACTIVE,
	]


static func state_name(state: int) -> String:
	match state:
		RunState.INITIALIZING:
			return "INITIALIZING"
		RunState.INTRO:
			return "INTRO"
		RunState.PATROLLING:
			return "PATROLLING"
		RunState.ENCOUNTER_ACTIVE:
			return "ENCOUNTER_ACTIVE"
		RunState.REWARD_SELECTION:
			return "REWARD_SELECTION"
		RunState.SHOP:
			return "SHOP"
		RunState.EXTRACTION_AVAILABLE:
			return "EXTRACTION_AVAILABLE"
		RunState.EXTRACTING:
			return "EXTRACTING"
		RunState.BOSS_INTRO:
			return "BOSS_INTRO"
		RunState.BOSS_ACTIVE:
			return "BOSS_ACTIVE"
		RunState.VICTORY:
			return "VICTORY"
		RunState.DEFEAT:
			return "DEFEAT"
		RunState.RUN_SUMMARY:
			return "RUN_SUMMARY"
		RunState.PAUSED:
			return "PAUSED"
	return "UNKNOWN"


static func result_name(result: int) -> String:
	match result:
		RunResult.VICTORY:
			return "VICTORY"
		RunResult.EXTRACTED:
			return "EXTRACTED"
		RunResult.DEFEATED:
			return "DEFEATED"
	return "IN PROGRESS"


func _evaluate_threshold_crossings(previous_value: float, new_value: float) -> void:
	var newly_latched_extractions: Array[int] = []
	for threshold_index: int in range(escalation_definition.extraction_pressure_thresholds.size()):
		var threshold_value: float = escalation_definition.extraction_pressure_thresholds[threshold_index]
		if (
			_latched_extraction_thresholds.has(threshold_index)
			or previous_value >= threshold_value
			or new_value < threshold_value
		):
			continue
		_latched_extraction_thresholds[threshold_index] = true
		newly_latched_extractions.append(threshold_index)
		extraction_threshold_latched.emit(threshold_index, threshold_value)

	var boss_crossed: bool = (
		not _boss_threshold_latched
		and previous_value < escalation_definition.boss_pressure_threshold
		and new_value >= escalation_definition.boss_pressure_threshold
	)
	if boss_crossed:
		_boss_threshold_latched = true
		_boss_queued = not _extraction_confirmed
		if _boss_queued:
			boss_queued.emit()
			for pending_index: int in _pending_extraction_thresholds:
				_spent_extraction_thresholds[pending_index] = true
			_pending_extraction_thresholds.clear()

	for threshold_index: int in newly_latched_extractions:
		if _extraction_confirmed:
			_spent_extraction_thresholds[threshold_index] = true
		elif boss_crossed:
			_spent_extraction_thresholds[threshold_index] = true
		else:
			_pending_extraction_thresholds.append(threshold_index)


func _begin_pending_progression() -> bool:
	if _boss_queued and not _extraction_confirmed:
		for pending_index: int in _pending_extraction_thresholds:
			_spent_extraction_thresholds[pending_index] = true
		_pending_extraction_thresholds.clear()
		_current_extraction_threshold_index = -1
		_boss_queued = false
		_boss_started = true
		_boss_intro_remaining = get_boss_intro_duration_seconds()
		if request_transition(RunState.BOSS_INTRO):
			boss_started.emit()
			if _boss_intro_remaining > 0.0:
				boss_intro_timing_started.emit(_boss_intro_remaining)
			return true
		_boss_queued = true
		_boss_started = false
		_boss_intro_remaining = 0.0
		return false

	while not _pending_extraction_thresholds.is_empty():
		var threshold_index: int = _pending_extraction_thresholds.pop_front()
		if _spent_extraction_thresholds.has(threshold_index):
			continue
		_current_extraction_threshold_index = threshold_index
		if request_transition(RunState.EXTRACTION_AVAILABLE):
			extraction_became_available.emit(threshold_index)
			return true
		_pending_extraction_thresholds.push_front(threshold_index)
		_current_extraction_threshold_index = -1
		return false
	return false


func _reset_authoritative_state() -> void:
	var card_planning_was_active: bool = _card_planning_pause_owned
	_card_planning_pause_owned = false
	_ending_card_planning_pause = false
	if current_state != RunState.INITIALIZING:
		var previous_state: int = current_state
		current_state = RunState.INITIALIZING
		run_state_changed.emit(previous_state, current_state)
	run_elapsed_seconds = 0.0
	heat = 0
	maximum_heat = 0
	night_pressure = 0.0
	encounters_completed = 0
	_run_result = RunResult.NONE
	_state_before_pause = RunState.PATROLLING
	_intro_remaining = 0.0
	_extraction_remaining = 0.0
	_boss_intro_remaining = 0.0
	_victory_presentation_remaining = 0.0
	_snapshot_remaining = 0.0
	_boss_threshold_latched = false
	_boss_queued = false
	_boss_started = false
	_extraction_confirmed = false
	_current_extraction_threshold_index = -1
	_latched_extraction_thresholds.clear()
	_spent_extraction_thresholds.clear()
	_pending_extraction_thresholds.clear()
	_completed_encounter_ids.clear()
	_last_summary = null
	_run_completion_emitted = false
	if card_planning_was_active:
		card_planning_pause_changed.emit(false)


func _ensure_random_streams() -> void:
	if _random_streams != null and is_instance_valid(_random_streams):
		return
	_random_streams = get_node_or_null("RunRandomStreams") as RunRandomStreams
	if _random_streams == null:
		_random_streams = RunRandomStreams.new()
		_random_streams.name = "RunRandomStreams"
		add_child(_random_streams)


func _is_transition_allowed(from_state: int, to_state: int) -> bool:
	match from_state:
		RunState.INITIALIZING:
			return to_state == RunState.INTRO
		RunState.INTRO:
			return to_state == RunState.PATROLLING
		RunState.PATROLLING:
			return to_state in [
				RunState.ENCOUNTER_ACTIVE,
				RunState.SHOP,
				RunState.EXTRACTION_AVAILABLE,
				RunState.BOSS_INTRO,
				RunState.PAUSED,
			]
		RunState.ENCOUNTER_ACTIVE:
			return to_state in [RunState.REWARD_SELECTION, RunState.DEFEAT, RunState.PAUSED]
		RunState.REWARD_SELECTION:
			return to_state in [
				RunState.PATROLLING,
				RunState.EXTRACTION_AVAILABLE,
				RunState.BOSS_INTRO,
				RunState.PAUSED,
			]
		RunState.SHOP:
			return to_state in [
				RunState.PATROLLING,
				RunState.EXTRACTION_AVAILABLE,
				RunState.BOSS_INTRO,
				RunState.PAUSED,
			]
		RunState.EXTRACTION_AVAILABLE:
			return to_state in [
				RunState.PATROLLING,
				RunState.EXTRACTING,
				RunState.BOSS_INTRO,
				RunState.PAUSED,
			]
		RunState.EXTRACTING:
			return to_state == RunState.RUN_SUMMARY
		RunState.BOSS_INTRO:
			return to_state == RunState.BOSS_ACTIVE
		RunState.BOSS_ACTIVE:
			return to_state in [RunState.VICTORY, RunState.DEFEAT, RunState.PAUSED]
		RunState.VICTORY, RunState.DEFEAT:
			return to_state == RunState.RUN_SUMMARY
		RunState.RUN_SUMMARY:
			return to_state == RunState.INITIALIZING
		RunState.PAUSED:
			return to_state == _state_before_pause
	return false


func _emit_run_completed_once() -> bool:
	if _run_completion_emitted or _run_result == RunResult.NONE:
		return false
	_run_completion_emitted = true
	run_completed.emit(_run_result)
	return true


func _derived_boss_result() -> String:
	if _run_result == RunResult.VICTORY:
		return "DEFEATED"
	if _boss_started and _run_result == RunResult.DEFEATED:
		return "CREW DEFEATED"
	return "NOT REACHED"
