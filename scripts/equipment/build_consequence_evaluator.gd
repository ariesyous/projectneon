class_name BuildConsequenceEvaluator
extends RefCounted

## Pure, deterministic translation from SynergySystem preview data to the
## crew-specific values a player will observe in the next fight. It owns no
## inventory, reward, combat, or UI state.

const BASE_BLEED_STACKS: int = 3
const BASE_SHOCK_SECONDS: float = 3.0


static func enrich_preview(
	preview: Dictionary,
	crew: ActorDefinition,
	attack: AttackDefinition,
	hydrant_base_cooldown: float,
	backup_base_cooldown: float
) -> Dictionary:
	var result: Dictionary = preview.duplicate(true)
	if not bool(result.get("valid", false)) or crew == null or attack == null:
		result["exact_changes"] = []
		return result
	var before_flat: Dictionary = result.get("flat_modifiers_before", {})
	var after_flat: Dictionary = result.get("flat_modifiers_after", {})
	var before_percent: Dictionary = result.get("percent_modifiers_before", {})
	var after_percent: Dictionary = result.get("percent_modifiers_after", {})
	var changes: Array[Dictionary] = []

	_append_change(
		changes,
		&"maximum_health",
		"MAX HEALTH",
		_round_half_up(float(crew.maximum_health) * _positive_factor(before_percent, &"maximum_health")),
		_round_half_up(float(crew.maximum_health) * _positive_factor(after_percent, &"maximum_health")),
		&"integer",
		true
	)
	_append_change(
		changes,
		&"movement_speed",
		"MOVE SPEED",
		crew.movement_speed * _positive_factor(before_percent, &"movement_speed"),
		crew.movement_speed * _positive_factor(after_percent, &"movement_speed"),
		&"decimal_1",
		true
	)
	var base_cycle: float = maxf(
		attack.windup_time + attack.active_time + attack.recovery_time + attack.cooldown_time,
		0.001
	)
	_append_change(
		changes,
		&"attack_cycle",
		"ATTACK CYCLE",
		base_cycle / _positive_factor(before_percent, &"attack_speed"),
		base_cycle / _positive_factor(after_percent, &"attack_speed"),
		&"seconds_2",
		false
	)
	var before_hit_multiplier: float = 1.0
	var after_hit_multiplier: float = 1.0
	if attack.is_heavy():
		before_hit_multiplier += float(before_percent.get(&"heavy_hit_damage", 0.0))
		after_hit_multiplier += float(after_percent.get(&"heavy_hit_damage", 0.0))
	_append_change(
		changes,
		&"primary_hit_damage",
		"PRIMARY HIT",
		_round_half_up(float(crew.base_damage) * maxf(before_hit_multiplier, 0.0)),
		_round_half_up(float(crew.base_damage) * maxf(after_hit_multiplier, 0.0)),
		&"integer",
		true
	)
	_append_change(
		changes,
		&"attack_knockback",
		"ATTACK KNOCKBACK",
		attack.knockback_force * _positive_factor(before_percent, &"knockback_distance"),
		attack.knockback_force * _positive_factor(after_percent, &"knockback_distance"),
		&"integer",
		true
	)
	var crew_cooldown: float = maxf(crew.intervention_cooldown_multiplier, 0.05)
	_append_change(
		changes,
		&"hydrant_cooldown",
		"HYDRANT COOLDOWN",
		maxf(hydrant_base_cooldown, 0.0) * crew_cooldown * _positive_factor(before_percent, &"intervention_cooldown"),
		maxf(hydrant_base_cooldown, 0.0) * crew_cooldown * _positive_factor(after_percent, &"intervention_cooldown"),
		&"seconds_2",
		false
	)
	_append_change(
		changes,
		&"backup_cooldown",
		"BACKUP COOLDOWN",
		maxf(backup_base_cooldown, 0.0) * crew_cooldown * _positive_factor(before_percent, &"intervention_cooldown"),
		maxf(backup_base_cooldown, 0.0) * crew_cooldown * _positive_factor(after_percent, &"intervention_cooldown"),
		&"seconds_2",
		false
	)
	_append_change(
		changes,
		&"environment_damage",
		"ENVIRONMENT DAMAGE",
		100.0 * _positive_factor(before_percent, &"environmental_collision_damage"),
		100.0 * _positive_factor(after_percent, &"environmental_collision_damage"),
		&"percent_0",
		true
	)
	_append_change(
		changes,
		&"environment_knockback",
		"ENVIRONMENT KNOCKBACK",
		100.0 * (
			_positive_factor(before_percent, &"knockback_distance")
			+ float(before_percent.get(&"environmental_knockback", 0.0))
		),
		100.0 * (
			_positive_factor(after_percent, &"knockback_distance")
			+ float(after_percent.get(&"environmental_knockback", 0.0))
		),
		&"percent_0",
		true
	)
	_append_change(
		changes,
		&"bleed_stack_cap",
		"BLEED STACK CAP",
		BASE_BLEED_STACKS + int(floor(float(before_flat.get(&"bleed_maximum_stacks", 0.0)))),
		BASE_BLEED_STACKS + int(floor(float(after_flat.get(&"bleed_maximum_stacks", 0.0)))),
		&"integer",
		true
	)
	_append_change(
		changes,
		&"bleeding_damage",
		"VS BLEEDING",
		100.0 * float(before_percent.get(&"damage_against_bleeding", 0.0)),
		100.0 * float(after_percent.get(&"damage_against_bleeding", 0.0)),
		&"signed_percent_0",
		true
	)
	_append_change(
		changes,
		&"shocked_damage",
		"VS SHOCKED",
		100.0 * float(before_percent.get(&"damage_against_shocked", 0.0)),
		100.0 * float(after_percent.get(&"damage_against_shocked", 0.0)),
		&"signed_percent_0",
		true
	)
	_append_change(
		changes,
		&"shock_duration",
		"SHOCK DURATION",
		BASE_SHOCK_SECONDS + float(before_flat.get(&"shock_duration", 0.0)),
		BASE_SHOCK_SECONDS + float(after_flat.get(&"shock_duration", 0.0)),
		&"seconds_1",
		true
	)
	var before_received: float = (
		maxf(1.0 - crew.knockback_resistance, 0.0)
		* _positive_factor(before_percent, &"knockback_received")
	)
	var after_received: float = (
		maxf(1.0 - crew.knockback_resistance, 0.0)
		* _positive_factor(after_percent, &"knockback_received")
	)
	_append_change(
		changes,
		&"knockback_received",
		"KNOCKBACK TAKEN",
		before_received * 100.0,
		after_received * 100.0,
		&"percent_0",
		false
	)
	_append_proc_changes(
		changes,
		result.get("triggered_effects_before", []),
		result.get("triggered_effects_after", [])
	)
	result["exact_changes"] = changes
	result["next_fight_consequence"] = (
		"STORED - ACTIVE BUILD AND NEXT FIGHT STAY UNCHANGED"
		if bool(result.get("stored_inactive", false))
		else String(result.get("combat_promise", "")).to_upper()
	)
	return result


static func format_value(change: Dictionary, key: StringName) -> String:
	var value: float = float(change.get(key, 0.0))
	match StringName(change.get("format", &"decimal_1")):
		&"integer":
			return str(_round_half_up(value))
		&"seconds_1":
			return "%.1fs" % value
		&"seconds_2":
			return "%.2fs" % value
		&"percent_0":
			return "%d%%" % _round_half_up(value)
		&"signed_percent_0":
			return "%+d%%" % _round_half_up(value)
		_:
			return "%.1f" % value


static func _append_change(
	changes: Array[Dictionary],
	id: StringName,
	label: String,
	before: float,
	after: float,
	format: StringName,
	higher_is_better: bool
) -> void:
	if is_equal_approx(before, after):
		return
	changes.append({
		"id": id,
		"label": label,
		"before": before,
		"after": after,
		"format": format,
		"higher_is_better": higher_is_better,
	})


static func _append_proc_changes(
	changes: Array[Dictionary],
	before_values: Variant,
	after_values: Variant
) -> void:
	var before: Dictionary[StringName, Dictionary] = _effect_by_id(before_values)
	var after: Dictionary[StringName, Dictionary] = _effect_by_id(after_values)
	var ids: Array[StringName] = []
	for effect_id: StringName in before:
		if not ids.has(effect_id):
			ids.append(effect_id)
	for effect_id: StringName in after:
		if not ids.has(effect_id):
			ids.append(effect_id)
	ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)
	for effect_id: StringName in ids:
		var before_entry: Dictionary = before.get(effect_id, {})
		var after_entry: Dictionary = after.get(effect_id, {})
		var before_chance: float = float(before_entry.get("chance_basis_points", 0)) / 100.0
		var after_chance: float = float(after_entry.get("chance_basis_points", 0)) / 100.0
		if is_equal_approx(before_chance, after_chance):
			continue
		var status_id: String = String(
			after_entry.get("status_id", before_entry.get("status_id", &"STATUS"))
		).to_upper()
		var trigger: int = int(after_entry.get("trigger", before_entry.get("trigger", 0)))
		changes.append({
			"id": StringName("proc_%s" % effect_id),
			"label": "%s %s" % [
				status_id,
				"HEAVY PROC" if trigger == TriggeredEffectDefinition.Trigger.ON_HEAVY_HIT else "HIT PROC",
			],
			"before": before_chance,
			"after": after_chance,
			"format": &"percent_0",
			"higher_is_better": true,
		})


static func _effect_by_id(values: Variant) -> Dictionary[StringName, Dictionary]:
	var result: Dictionary[StringName, Dictionary] = {}
	if not (values is Array):
		return result
	for value: Variant in values as Array:
		var entry: Dictionary = value as Dictionary
		var effect_id: StringName = StringName(entry.get("id", &""))
		if effect_id != &"":
			result[effect_id] = entry
	return result


static func _positive_factor(values: Dictionary, stat_id: StringName) -> float:
	return maxf(0.05, 1.0 + float(values.get(stat_id, 0.0)))


static func _round_half_up(value: float) -> int:
	return maxi(int(floor(maxf(value, 0.0) + 0.5)), 0)
