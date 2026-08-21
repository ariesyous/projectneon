@tool
class_name DistrictLoopDefinition
extends Resource

## Authored WP02 district-lap structure and escalation. RunDirector owns the
## live ledger; this Resource contains no mutable run state.

const APPROVED_LAP_COUNT: int = 3
const APPROVED_BLOCKS_PER_LAP: int = 3

@export var id: StringName = &"wp02_district_loop"
@export_range(1, 3, 1) var lap_count: int = APPROVED_LAP_COUNT
@export_range(1, 3, 1) var blocks_per_lap: int = APPROVED_BLOCKS_PER_LAP
@export_range(0, 100, 1) var push_heat_delta: int = 6
@export var pressure_gain_multipliers: PackedFloat32Array = PackedFloat32Array([
	1.0,
	1.15,
	1.30,
])
@export var reward_quality_tier_bonuses: PackedInt32Array = PackedInt32Array([0, 1, 2])
@export var modifier_ids: Array[StringName] = [
	&"street_watch",
	&"rising_pressure",
	&"boss_commitment",
]
@export var modifier_labels: PackedStringArray = PackedStringArray([
	"STREET WATCH",
	"RISING PRESSURE",
	"BOSS COMMITMENT",
])
@export var risk_labels: PackedStringArray = PackedStringArray([
	"BASELINE DISTRICT RISK",
	"HIGHER ENEMY PRESSURE",
	"FINAL LAP - NO ROUTINE EXTRACTION",
])
@export var next_threat_labels: PackedStringArray = PackedStringArray([
	"STREET PATROLS",
	"VIPER ENFORCER",
	"THE VIPER",
])


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("district loop id must not be empty")
	if lap_count != APPROVED_LAP_COUNT:
		errors.append("WP02 district loop must contain exactly three laps")
	if blocks_per_lap != APPROVED_BLOCKS_PER_LAP:
		errors.append("WP02 district loop must contain exactly three blocks per lap")
	if push_heat_delta < 0:
		errors.append("push Heat delta must not be negative")
	if pressure_gain_multipliers.size() != lap_count:
		errors.append("pressure multiplier count must match lap count")
	if reward_quality_tier_bonuses.size() != lap_count:
		errors.append("reward tier bonus count must match lap count")
	if modifier_ids.size() != lap_count:
		errors.append("modifier ID count must match lap count")
	if modifier_labels.size() != lap_count:
		errors.append("modifier label count must match lap count")
	if risk_labels.size() != lap_count:
		errors.append("risk label count must match lap count")
	if next_threat_labels.size() != lap_count:
		errors.append("next-threat label count must match lap count")
	var seen_modifier_ids: Dictionary[StringName, bool] = {}
	for lap_offset: int in range(lap_count):
		if lap_offset < pressure_gain_multipliers.size() and pressure_gain_multipliers[lap_offset] < 1.0:
			errors.append("lap pressure multipliers must be at least one")
		if lap_offset < reward_quality_tier_bonuses.size() and reward_quality_tier_bonuses[lap_offset] < 0:
			errors.append("lap reward tier bonuses must not be negative")
		if lap_offset < modifier_ids.size():
			var modifier_id: StringName = modifier_ids[lap_offset]
			if modifier_id == &"" or seen_modifier_ids.has(modifier_id):
				errors.append("lap modifier IDs must be non-empty and unique")
			else:
				seen_modifier_ids[modifier_id] = true
	return errors


func pressure_multiplier_for_lap(lap_index: int) -> float:
	return pressure_gain_multipliers[_lap_offset(lap_index)]


func reward_tier_bonus_for_lap(lap_index: int) -> int:
	return reward_quality_tier_bonuses[_lap_offset(lap_index)]


func modifier_id_for_lap(lap_index: int) -> StringName:
	return modifier_ids[_lap_offset(lap_index)]


func modifier_label_for_lap(lap_index: int) -> String:
	return modifier_labels[_lap_offset(lap_index)]


func risk_label_for_lap(lap_index: int) -> String:
	return risk_labels[_lap_offset(lap_index)]


func next_threat_for_lap(lap_index: int) -> String:
	return next_threat_labels[_lap_offset(lap_index)]


func lap_snapshot(lap_index: int) -> Dictionary:
	var safe_lap: int = clampi(lap_index, 1, lap_count)
	return {
		"lap_index": safe_lap,
		"lap_id": lap_id(safe_lap),
		"modifier_id": modifier_id_for_lap(safe_lap),
		"modifier_label": modifier_label_for_lap(safe_lap),
		"risk_label": risk_label_for_lap(safe_lap),
		"pressure_gain_multiplier": pressure_multiplier_for_lap(safe_lap),
		"reward_quality_tier_bonus": reward_tier_bonus_for_lap(safe_lap),
		"next_threat": next_threat_for_lap(safe_lap),
		"boss_commitment": safe_lap == lap_count,
	}


func push_preview(completed_lap_index: int) -> Dictionary:
	if completed_lap_index < 1 or completed_lap_index >= lap_count:
		return {}
	var next_lap: int = completed_lap_index + 1
	var preview: Dictionary = lap_snapshot(next_lap)
	preview["from_lap_index"] = completed_lap_index
	preview["from_lap_id"] = lap_id(completed_lap_index)
	preview["push_heat_delta"] = push_heat_delta
	preview["final_lap_commitment"] = next_lap == lap_count
	preview["next_decision_after_blocks"] = 0 if next_lap == lap_count else blocks_per_lap
	return preview


func lap_id(lap_index: int) -> StringName:
	return StringName("district_lap_%02d" % clampi(lap_index, 1, lap_count))


func block_id(lap_index: int, block_index: int) -> StringName:
	return StringName(
		"%s::block_%02d"
		% [lap_id(lap_index), clampi(block_index, 1, blocks_per_lap)]
	)


func _lap_offset(lap_index: int) -> int:
	return clampi(lap_index, 1, lap_count) - 1
