@tool
class_name SynergyDefinition
extends Resource

## One data-driven tag threshold. Additional 4/6 thresholds can be added as
## independent definitions without changing SynergySystem evaluation code.

@export var id: StringName

@export var display_name: String = "Synergy"
@export var role_label: String = ""
@export_multiline var combat_promise: String = ""
@export var badge: Texture2D
@export var required_tag: StringName
@export_range(1, 99, 1) var threshold: int = 2
@export var modifiers: Array[EquipmentModifierDefinition] = []
@export var triggered_effects: Array[TriggeredEffectDefinition] = []
@export var major_effects: PackedStringArray = PackedStringArray()


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("synergy id is empty")
	if display_name.strip_edges().is_empty():
		errors.append("synergy '%s' has no display name" % id)
	if role_label.strip_edges().is_empty():
		errors.append("synergy '%s' has no role label" % id)
	elif role_label.length() > 40 or "\n" in role_label:
		errors.append("synergy '%s' role label must be one concise line" % id)
	if combat_promise.strip_edges().is_empty():
		errors.append("synergy '%s' has no combat promise" % id)
	elif combat_promise.length() > 160 or "\n" in combat_promise:
		errors.append("synergy '%s' combat promise must be one concise line" % id)
	if required_tag == &"":
		errors.append("synergy '%s' has no required tag" % id)
	if threshold <= 0:
		errors.append("synergy '%s' threshold must be positive" % id)
	if modifiers.is_empty() and triggered_effects.is_empty():
		errors.append("synergy '%s' has no functional effect" % id)
	if major_effects.is_empty():
		errors.append("synergy '%s' has no player-facing effects" % id)
	for modifier: EquipmentModifierDefinition in modifiers:
		if modifier == null:
			errors.append("synergy '%s' contains a null modifier" % id)
		else:
			errors.append_array(modifier.validation_errors())
	for effect: TriggeredEffectDefinition in triggered_effects:
		if effect == null:
			errors.append("synergy '%s' contains a null triggered effect" % id)
		else:
			errors.append_array(effect.validation_errors())
	return errors
