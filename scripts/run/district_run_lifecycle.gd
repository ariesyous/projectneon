class_name DistrictRunLifecycle
extends RefCounted

## Run-owned WP02 lap/block ledger. It has no scene, UI, route, reward, or
## random-stream authority; RunDirector validates coarse state around it.

enum Phase {
	SELECT_CREW,
	INTRO,
	PLAN,
	BLOCK,
	FIGHT,
	REWARD,
	SHOP,
	LAP_DECISION,
	EXTRACTION,
	BOSS,
	RESULT,
}

const DECISION_EXTRACT: StringName = &"extract"
const DECISION_PUSH: StringName = &"push"

var definition: DistrictLoopDefinition
var phase: int = Phase.SELECT_CREW
var lap_index: int = 1
var block_index: int = 1
var completed_laps: int = 0
var completed_blocks: int = 0
var lifecycle_revision: int = 0
var decision_token: int = -1
var decision_revision: int = -1
var boss_committed: bool = false
var current_route_occurrence_id: StringName = &""
var current_block_kind: StringName = &""

var _next_decision_token: int = 1
var _consumed_decision_tokens: Dictionary[int, bool] = {}
var _accepted_decisions: Array[Dictionary] = []


func _init(authored_definition: DistrictLoopDefinition) -> void:
	definition = authored_definition
	reset()


func reset() -> void:
	phase = Phase.SELECT_CREW
	lap_index = 1
	block_index = 1
	completed_laps = 0
	completed_blocks = 0
	lifecycle_revision = 0
	decision_token = -1
	decision_revision = -1
	boss_committed = false
	current_route_occurrence_id = &""
	current_block_kind = &""
	_next_decision_token = 1
	_consumed_decision_tokens.clear()
	_accepted_decisions.clear()


func start_run() -> bool:
	reset()
	return _set_phase(Phase.INTRO)


func complete_intro() -> bool:
	if phase != Phase.INTRO:
		return false
	return _set_phase(Phase.PLAN)


func begin_block(route_occurrence_id: StringName, block_kind: StringName) -> bool:
	if phase != Phase.PLAN or route_occurrence_id == &"" or block_kind == &"":
		return false
	current_route_occurrence_id = route_occurrence_id
	current_block_kind = block_kind
	return _set_phase(Phase.BLOCK)


func enter_fight() -> bool:
	if phase != Phase.BLOCK:
		return false
	current_block_kind = &"fight"
	return _set_phase(Phase.FIGHT)


func enter_shop() -> bool:
	if phase != Phase.BLOCK:
		return false
	current_block_kind = &"shop"
	return _set_phase(Phase.SHOP)


func enter_reward() -> bool:
	if phase != Phase.FIGHT:
		return false
	return _set_phase(Phase.REWARD)


func complete_block() -> int:
	if phase not in [Phase.BLOCK, Phase.REWARD, Phase.SHOP]:
		return -1
	completed_blocks += 1
	current_route_occurrence_id = &""
	current_block_kind = &""
	if block_index < definition.blocks_per_lap:
		block_index += 1
		_set_phase(Phase.PLAN)
		return phase

	completed_laps = lap_index
	if lap_index < definition.lap_count:
		decision_token = _next_decision_token
		_next_decision_token += 1
		decision_revision = lifecycle_revision + 1
		_set_phase(Phase.LAP_DECISION)
		return phase

	_set_phase(Phase.BOSS)
	return phase


func accept_lap_decision(expected_token: int, decision_id: StringName) -> Dictionary:
	var rejected: Dictionary = {
		"accepted": false,
		"reason": &"invalid_state",
		"decision_token": expected_token,
		"lifecycle_revision": lifecycle_revision,
	}
	if phase != Phase.LAP_DECISION:
		return rejected
	if expected_token < 0 or expected_token != decision_token:
		rejected["reason"] = &"stale_decision_token"
		return rejected
	if _consumed_decision_tokens.has(expected_token):
		rejected["reason"] = &"replayed_decision_token"
		return rejected
	if decision_id not in [DECISION_EXTRACT, DECISION_PUSH]:
		rejected["reason"] = &"invalid_decision"
		return rejected
	if decision_id == DECISION_PUSH and lap_index >= definition.lap_count:
		rejected["reason"] = &"final_lap_has_no_push"
		return rejected

	var record: Dictionary = {
		"decision_token": expected_token,
		"decision_revision": decision_revision,
		"decision": decision_id,
		"completed_lap_index": lap_index,
		"completed_lap_id": definition.lap_id(lap_index),
		"completed_blocks": completed_blocks,
		"boss_commitment": decision_id == DECISION_PUSH and lap_index == definition.lap_count - 1,
	}
	if decision_id == DECISION_PUSH:
		record["push_preview"] = definition.push_preview(lap_index)
	_consumed_decision_tokens[expected_token] = true
	_accepted_decisions.append(record.duplicate(true))
	decision_token = -1
	decision_revision = -1
	if decision_id == DECISION_EXTRACT:
		_set_phase(Phase.EXTRACTION)
	else:
		if lap_index == definition.lap_count - 1:
			boss_committed = true
		lap_index += 1
		block_index = 1
		_set_phase(Phase.PLAN)
	return {
		"accepted": true,
		"reason": &"ok",
		"record": record.duplicate(true),
		"lifecycle_revision": lifecycle_revision,
	}


func mark_result() -> bool:
	if phase == Phase.RESULT:
		return false
	return _set_phase(Phase.RESULT)


func phase_name() -> String:
	return phase_name_for(phase)


func get_snapshot() -> Dictionary:
	var current_lap: Dictionary = definition.lap_snapshot(lap_index)
	return {
		"enabled": true,
		"phase": phase,
		"phase_name": phase_name(),
		"lifecycle_revision": lifecycle_revision,
		"lap_index": lap_index,
		"lap_id": definition.lap_id(lap_index),
		"lap_count": definition.lap_count,
		"block_index": block_index,
		"block_id": definition.block_id(lap_index, block_index),
		"blocks_per_lap": definition.blocks_per_lap,
		"completed_laps": completed_laps,
		"completed_blocks": completed_blocks,
		"decision_token": decision_token,
		"decision_revision": decision_revision,
		"boss_committed": boss_committed,
		"current_route_occurrence_id": current_route_occurrence_id,
		"current_block_kind": current_block_kind,
		"current_lap": current_lap,
		"push_preview": (
			definition.push_preview(lap_index)
			if phase == Phase.LAP_DECISION
			else {}
		),
		"accepted_decisions": _accepted_decisions.duplicate(true),
	}


func get_accepted_decisions() -> Array[Dictionary]:
	return _accepted_decisions.duplicate(true)


static func phase_name_for(phase_value: int) -> String:
	match phase_value:
		Phase.SELECT_CREW:
			return "SELECT CREW"
		Phase.INTRO:
			return "INTRO"
		Phase.PLAN:
			return "PLAN"
		Phase.BLOCK:
			return "BLOCK"
		Phase.FIGHT:
			return "FIGHT"
		Phase.REWARD:
			return "REWARD"
		Phase.SHOP:
			return "SHOP"
		Phase.LAP_DECISION:
			return "LAP DECISION"
		Phase.EXTRACTION:
			return "EXTRACTION"
		Phase.BOSS:
			return "BOSS"
		Phase.RESULT:
			return "RESULT"
	return "UNKNOWN"


func _set_phase(new_phase: int) -> bool:
	if phase == new_phase:
		return false
	phase = new_phase
	lifecycle_revision += 1
	return true
