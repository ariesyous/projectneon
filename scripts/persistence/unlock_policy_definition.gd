@tool
class_name UnlockPolicyDefinition
extends Resource

## Authored minimal unlock policy:
## - first completed run -> Zoey
## - first run with an elite defeat -> Hacker Deck
## - first extraction -> Gang Hideout
## - first victory -> Rex
## Existing unlock arrays make every grant idempotent; no rule grants stats.

const OUTCOME_VICTORY: StringName = &"victory"
const OUTCOME_EXTRACTED: StringName = &"extracted"
const OUTCOME_DEFEATED: StringName = &"defeated"
const REQUIRED_RULE_IDS: Array[StringName] = [
	&"first_completed_run_zoey",
	&"first_elite_defeat_hacker_deck",
	&"first_extraction_gang_hideout",
	&"first_victory_rex",
]

@export var rules: Array[UnlockRuleDefinition] = []


func apply_completed_run(
	profile: PersistentProfileData,
	outcome_id: StringName,
	elites_defeated: int
) -> Array[StringName]:
	var granted_ids: Array[StringName] = []
	if profile == null or not is_valid_outcome(outcome_id):
		return granted_ids
	for rule: UnlockRuleDefinition in get_sorted_rules():
		if not _trigger_matches(rule.trigger, outcome_id, elites_defeated):
			continue
		if profile.unlock_content(rule.content_kind_id(), rule.content_id):
			granted_ids.append(rule.content_id)
	return granted_ids


func is_valid_outcome(outcome_id: StringName) -> bool:
	return outcome_id in [OUTCOME_VICTORY, OUTCOME_EXTRACTED, OUTCOME_DEFEATED]


func get_sorted_rules() -> Array[UnlockRuleDefinition]:
	var result: Array[UnlockRuleDefinition] = []
	for rule: UnlockRuleDefinition in rules:
		if rule != null:
			result.append(rule)
	result.sort_custom(_rule_before)
	return result


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rules.size() != REQUIRED_RULE_IDS.size():
		errors.append("unlock policy must contain exactly four authored rules")
	var seen: Dictionary[StringName, bool] = {}
	for rule: UnlockRuleDefinition in rules:
		if rule == null:
			errors.append("unlock policy contains a null rule")
			continue
		errors.append_array(rule.validation_errors())
		if rule.id in seen:
			errors.append("unlock policy repeats rule '%s'" % rule.id)
		seen[rule.id] = true
		errors.append_array(_authored_rule_errors(rule))
	for required_id: StringName in REQUIRED_RULE_IDS:
		if not seen.has(required_id):
			errors.append("unlock policy is missing rule '%s'" % required_id)
	return errors


func _authored_rule_errors(rule: UnlockRuleDefinition) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var expected_kind: UnlockRuleDefinition.ContentKind
	var expected_content_id: StringName
	var expected_trigger: UnlockRuleDefinition.Trigger
	match rule.id:
		&"first_completed_run_zoey":
			expected_kind = UnlockRuleDefinition.ContentKind.CREW
			expected_content_id = PersistentProfileData.CREW_ZOEY
			expected_trigger = UnlockRuleDefinition.Trigger.FIRST_COMPLETED_RUN
		&"first_elite_defeat_hacker_deck":
			expected_kind = UnlockRuleDefinition.ContentKind.EQUIPMENT
			expected_content_id = PersistentProfileData.EQUIPMENT_HACKER_DECK
			expected_trigger = UnlockRuleDefinition.Trigger.FIRST_ELITE_DEFEAT
		&"first_extraction_gang_hideout":
			expected_kind = UnlockRuleDefinition.ContentKind.CARD
			expected_content_id = PersistentProfileData.CARD_GANG_HIDEOUT
			expected_trigger = UnlockRuleDefinition.Trigger.FIRST_EXTRACTION
		&"first_victory_rex":
			expected_kind = UnlockRuleDefinition.ContentKind.CREW
			expected_content_id = PersistentProfileData.CREW_REX
			expected_trigger = UnlockRuleDefinition.Trigger.FIRST_VICTORY
		_:
			errors.append("unlock policy has unexpected rule '%s'" % rule.id)
			return errors
	if rule.content_kind != expected_kind:
		errors.append("unlock rule '%s' has incorrect content kind" % rule.id)
	if rule.content_id != expected_content_id:
		errors.append("unlock rule '%s' has incorrect content id" % rule.id)
	if rule.trigger != expected_trigger:
		errors.append("unlock rule '%s' has incorrect trigger" % rule.id)
	return errors


static func _trigger_matches(
	trigger: UnlockRuleDefinition.Trigger,
	outcome_id: StringName,
	elites_defeated: int
) -> bool:
	match trigger:
		UnlockRuleDefinition.Trigger.FIRST_COMPLETED_RUN:
			return true
		UnlockRuleDefinition.Trigger.FIRST_ELITE_DEFEAT:
			return elites_defeated > 0
		UnlockRuleDefinition.Trigger.FIRST_EXTRACTION:
			return outcome_id == OUTCOME_EXTRACTED
		UnlockRuleDefinition.Trigger.FIRST_VICTORY:
			return outcome_id == OUTCOME_VICTORY
	return false


static func _rule_before(left: UnlockRuleDefinition, right: UnlockRuleDefinition) -> bool:
	return String(left.id) < String(right.id)
