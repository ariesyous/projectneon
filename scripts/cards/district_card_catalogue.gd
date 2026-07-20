@tool
class_name DistrictCardCatalogue
extends Resource

const CARD_ARCADE: StringName = &"arcade"
const CARD_CONVENIENCE_STORE: StringName = &"convenience_store"
const CARD_GANG_HIDEOUT: StringName = &"gang_hideout"
const CARD_SUBWAY_ENTRANCE: StringName = &"subway_entrance"
const REQUIRED_CARD_IDS: Array[StringName] = [
	CARD_ARCADE,
	CARD_CONVENIENCE_STORE,
	CARD_GANG_HIDEOUT,
	CARD_SUBWAY_ENTRANCE,
]

@export var cards: Array[DistrictCardDefinition] = []


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if cards.size() != REQUIRED_CARD_IDS.size():
		errors.append(
			"district-card catalogue must contain exactly %d cards, found %d"
			% [REQUIRED_CARD_IDS.size(), cards.size()]
		)
	var seen_ids: Dictionary[StringName, bool] = {}
	var seen_effect_ids: Dictionary[StringName, bool] = {}
	var seen_icon_paths: Dictionary[String, bool] = {}
	for card: DistrictCardDefinition in cards:
		if card == null:
			errors.append("district-card catalogue contains a null card")
			continue
		if seen_ids.has(card.id):
			errors.append("district-card catalogue repeats id '%s'" % card.id)
		seen_ids[card.id] = true
		if card.id not in REQUIRED_CARD_IDS:
			errors.append("district-card catalogue contains unexpected id '%s'" % card.id)
		errors.append_array(card.validation_errors())
		if card.effect_definition != null:
			var effect_id: StringName = card.effect_definition.id
			if seen_effect_ids.has(effect_id):
				errors.append("district-card catalogue repeats effect id '%s'" % effect_id)
			seen_effect_ids[effect_id] = true
		if card.icon != null:
			var icon_path: String = card.icon.resource_path
			if icon_path.is_empty():
				errors.append("district card '%s' icon has no stable resource path" % card.id)
			elif seen_icon_paths.has(icon_path):
				errors.append("district-card catalogue repeats icon '%s'" % icon_path)
			seen_icon_paths[icon_path] = true
		errors.append_array(_authored_contract_errors(card))
	for required_id: StringName in REQUIRED_CARD_IDS:
		if not seen_ids.has(required_id):
			errors.append("district-card catalogue is missing required id '%s'" % required_id)
	return errors


func get_by_id(card_id: StringName) -> DistrictCardDefinition:
	for card: DistrictCardDefinition in get_sorted_cards():
		if card.id == card_id:
			return card
	return null


func get_sorted_cards() -> Array[DistrictCardDefinition]:
	var result: Array[DistrictCardDefinition] = []
	for card: DistrictCardDefinition in cards:
		if card != null:
			result.append(card)
	result.sort_custom(_card_before)
	return result


func get_sorted_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for card: DistrictCardDefinition in get_sorted_cards():
		result.append(card.id)
	return result


func _authored_contract_errors(card: DistrictCardDefinition) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var expected_heat_delta: int = 0
	var expected_node_type: StringName = &""
	var expected_effect_kind: int = -1
	var expected_effect_id: StringName = &""
	var expected_tags: Array[StringName] = []
	if card.id == CARD_ARCADE:
		expected_heat_delta = 10
		expected_node_type = DistrictCardDefinition.NODE_TYPE_TRAVEL
		expected_effect_kind = CardEffectDefinition.EffectKind.ADD_STANDARD_ENCOUNTER
		expected_effect_id = &"arcade_standard_encounter_reward_boost"
		expected_tags = [&"FIGHT", &"REWARD"]
	elif card.id == CARD_CONVENIENCE_STORE:
		expected_heat_delta = -10
		expected_node_type = DistrictCardDefinition.NODE_TYPE_TRAVEL
		expected_effect_kind = CardEffectDefinition.EffectKind.OPEN_ONE_PURCHASE_SHOP
		expected_effect_id = &"convenience_store_existing_stock_purchase"
		expected_tags = [&"RECOVERY", &"SHOP"]
	elif card.id == CARD_GANG_HIDEOUT:
		expected_heat_delta = 20
		expected_node_type = DistrictCardDefinition.NODE_TYPE_ENCOUNTER
		expected_effect_kind = CardEffectDefinition.EffectKind.ADD_ELITE_ENCOUNTER
		expected_effect_id = &"gang_hideout_viper_signal_elite"
		expected_tags = [&"ELITE", &"EQUIPMENT"]
	elif card.id == CARD_SUBWAY_ENTRANCE:
		expected_heat_delta = -15
		expected_node_type = DistrictCardDefinition.NODE_TYPE_ENCOUNTER
		expected_effect_kind = CardEffectDefinition.EffectKind.REROUTE_SKIP_STANDARD
		expected_effect_id = &"subway_entrance_reroute_skip"
		expected_tags = [&"REROUTE", &"SKIP"]
	else:
		return errors

	if card.cost != 0:
		errors.append("district card '%s' must have authored cost 0" % card.id)
	if card.heat_delta != expected_heat_delta:
		errors.append(
			"district card '%s' Heat delta must be %d, found %d"
			% [card.id, expected_heat_delta, card.heat_delta]
		)
	if card.valid_node_types.size() != 1 or card.valid_node_types[0] != expected_node_type:
		errors.append(
			"district card '%s' must target only '%s' nodes" % [card.id, expected_node_type]
		)
	if card.sorted_tags() != expected_tags:
		errors.append("district card '%s' has incorrect authored tags" % card.id)
	if card.effect_definition == null:
		return errors
	if card.effect_definition.kind != expected_effect_kind:
		errors.append("district card '%s' has an incorrect effect kind" % card.id)
	if card.effect_definition.id != expected_effect_id:
		errors.append(
			"district card '%s' effect id must be '%s'"
			% [card.id, expected_effect_id]
		)
	if card.id == CARD_GANG_HIDEOUT and card.effect_definition.encounter_id != &"viper_signal":
		errors.append("Gang Hideout must reference the 'viper_signal' elite placeholder")
	return errors


func _card_before(left: DistrictCardDefinition, right: DistrictCardDefinition) -> bool:
	return String(left.id) < String(right.id)
