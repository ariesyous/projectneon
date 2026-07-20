@tool
class_name CardEffectDefinition
extends Resource

## Typed, data-only route effect authored by one District Card. Runtime owners
## resolve these values exactly once; definitions never mutate route or run state.

enum EffectKind {
	ADD_STANDARD_ENCOUNTER,
	OPEN_ONE_PURCHASE_SHOP,
	ADD_ELITE_ENCOUNTER,
	REROUTE_SKIP_STANDARD,
}

@export var id: StringName
@export_multiline var summary: String = ""
@export var kind: EffectKind = EffectKind.ADD_STANDARD_ENCOUNTER
@export var encounter_id: StringName
@export_range(0, 5, 1) var reward_quality_tier_steps: int = 0
@export_range(0, 3, 1) var maximum_purchases: int = 0
@export var uses_existing_shop_stock: bool = false
@export var guarantees_equipment_choice: bool = false
@export var reroutes_next_segment: bool = false
@export_range(0, 3, 1) var baseline_standard_encounters_to_skip: int = 0
@export var consumes_subway_charge: bool = false
@export var allows_card_reward: bool = false


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not _is_valid_stable_id(id):
		errors.append("card-effect id '%s' must be lowercase snake_case" % id)
	if summary.strip_edges().is_empty():
		errors.append("card effect '%s' has no player-facing summary" % id)
	if kind < EffectKind.ADD_STANDARD_ENCOUNTER or kind > EffectKind.REROUTE_SKIP_STANDARD:
		errors.append("card effect '%s' has an invalid effect kind" % id)
		return errors
	if reward_quality_tier_steps < 0:
		errors.append("card effect '%s' has a negative reward-quality step count" % id)
	if maximum_purchases < 0:
		errors.append("card effect '%s' has a negative purchase limit" % id)
	if baseline_standard_encounters_to_skip < 0:
		errors.append("card effect '%s' has a negative encounter-skip count" % id)
	if allows_card_reward:
		errors.append("card effect '%s' cannot recursively create card rewards" % id)

	match kind:
		EffectKind.ADD_STANDARD_ENCOUNTER:
			if encounter_id != &"":
				errors.append("standard card effect '%s' must use baseline encounter selection" % id)
			if reward_quality_tier_steps != 1:
				errors.append("standard card effect '%s' must advance exactly one authored reward tier" % id)
			_append_zero_shop_payload_errors(errors)
			_append_zero_elite_payload_errors(errors)
			_append_zero_reroute_payload_errors(errors)
		EffectKind.OPEN_ONE_PURCHASE_SHOP:
			if encounter_id != &"":
				errors.append("shop card effect '%s' cannot reference an encounter" % id)
			if reward_quality_tier_steps != 0:
				errors.append("shop card effect '%s' cannot modify reward quality" % id)
			if maximum_purchases != 1:
				errors.append("shop card effect '%s' must allow exactly one purchase" % id)
			if not uses_existing_shop_stock:
				errors.append("shop card effect '%s' must use existing finite stock" % id)
			_append_zero_elite_payload_errors(errors)
			_append_zero_reroute_payload_errors(errors)
		EffectKind.ADD_ELITE_ENCOUNTER:
			if encounter_id == &"":
				errors.append("elite card effect '%s' has no placeholder encounter id" % id)
			if reward_quality_tier_steps != 0:
				errors.append("elite card effect '%s' cannot modify standard reward quality" % id)
			if not guarantees_equipment_choice:
				errors.append("elite card effect '%s' must guarantee an equipment choice" % id)
			_append_zero_shop_payload_errors(errors)
			_append_zero_reroute_payload_errors(errors)
		EffectKind.REROUTE_SKIP_STANDARD:
			if encounter_id != &"":
				errors.append("reroute card effect '%s' cannot reference an encounter" % id)
			if reward_quality_tier_steps != 0:
				errors.append("reroute card effect '%s' cannot modify reward quality" % id)
			if not reroutes_next_segment:
				errors.append("reroute card effect '%s' must reroute the next segment" % id)
			if baseline_standard_encounters_to_skip != 1:
				errors.append("reroute card effect '%s' must skip exactly one baseline standard encounter" % id)
			if consumes_subway_charge:
				errors.append("reroute card effect '%s' cannot consume Subway intervention charges" % id)
			_append_zero_shop_payload_errors(errors)
			_append_zero_elite_payload_errors(errors)
	return errors


func _append_zero_shop_payload_errors(errors: PackedStringArray) -> void:
	if maximum_purchases != 0:
		errors.append("card effect '%s' has an unexpected purchase limit" % id)
	if uses_existing_shop_stock:
		errors.append("card effect '%s' unexpectedly uses shop stock" % id)


func _append_zero_elite_payload_errors(errors: PackedStringArray) -> void:
	if guarantees_equipment_choice:
		errors.append("card effect '%s' unexpectedly guarantees equipment" % id)


func _append_zero_reroute_payload_errors(errors: PackedStringArray) -> void:
	if reroutes_next_segment:
		errors.append("card effect '%s' unexpectedly reroutes a segment" % id)
	if baseline_standard_encounters_to_skip != 0:
		errors.append("card effect '%s' unexpectedly skips an encounter" % id)
	if consumes_subway_charge:
		errors.append("card effect '%s' unexpectedly consumes a Subway charge" % id)


func _is_valid_stable_id(value: StringName) -> bool:
	var text: String = String(value)
	if text.is_empty() or text.begins_with("_") or text.ends_with("_") or text.contains("__"):
		return false
	for index: int in range(text.length()):
		var code: int = text.unicode_at(index)
		var is_lowercase_letter: bool = code >= 97 and code <= 122
		var is_digit: bool = code >= 48 and code <= 57
		if not is_lowercase_letter and not is_digit and code != 95:
			return false
	return true
