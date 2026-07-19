@tool
class_name EquipmentModifierDefinition
extends Resource

## One stable, composable contribution to a build stat. Percent values are
## authored as decimal fractions (0.20 = +20%); flat values use stat units.

enum Operation {
	FLAT,
	PERCENT,
}

@export var id: StringName
@export var stat_id: StringName
@export var operation: Operation = Operation.PERCENT
@export var amount: float = 0.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("modifier id is empty")
	if stat_id == &"":
		errors.append("modifier '%s' has no stat id" % id)
	if not is_finite(amount):
		errors.append("modifier '%s' amount is not finite" % id)
	return errors
