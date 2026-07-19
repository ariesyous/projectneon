@tool
class_name TriggeredEffectDefinition
extends Resource

## Data-only combat effect. Proc rolls are resolved by CombatDirector through
## the run-scoped equipment stream; definitions never own randomness.

enum Trigger {
	ON_HIT,
	ON_HEAVY_HIT,
	ON_ENVIRONMENTAL_HIT,
}

@export var id: StringName
@export var trigger: Trigger = Trigger.ON_HIT
@export var status_id: StringName
@export_range(0, 10000, 1) var chance_basis_points: int = 10000
@export_range(1, 99, 1) var stacks: int = 1
@export_range(0.0, 60.0, 0.05) var duration_seconds: float = 0.0


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"":
		errors.append("triggered-effect id is empty")
	if status_id == &"":
		errors.append("triggered effect '%s' has no status id" % id)
	if chance_basis_points <= 0 or chance_basis_points > 10000:
		errors.append("triggered effect '%s' chance must be 1..10000 basis points" % id)
	if stacks <= 0:
		errors.append("triggered effect '%s' must apply at least one stack" % id)
	if duration_seconds <= 0.0:
		errors.append("triggered effect '%s' must have a positive duration" % id)
	return errors
