@tool
class_name WP05PrototypeActionDefinition
extends Resource

## Development-only WP05 comparison data. These definitions are not release
## catalogue entries and grant no production mechanic by their existence.

enum EffectKind {
	POWER_BOX,
	HANGING_SIGN,
	FOCUS_PRIORITY,
	RALLY_REPOSITION,
}

@export var id: StringName = &"wp05_prototype_action"
@export var role_id: StringName = &"environment"
@export var display_name: String = "Prototype Action"
@export var contextual_verb: String = "TEST"
@export var effect_kind: int = EffectKind.POWER_BOX
@export var icon: Texture2D
@export_range(0.0, 120.0, 0.1) var cooldown_seconds: float = 0.0
@export_range(0.0, 30.0, 0.05) var active_duration_seconds: float = 0.0
@export_range(0, 8, 1) var initial_charges: int = 0
@export var world_origin: Vector2 = Vector2.ZERO
@export_range(0.0, 320.0, 1.0) var range_radius: float = 0.0
@export_range(0, 1000, 1) var base_damage: int = 0
@export_range(0.0, 1000.0, 1.0) var knockback_force: float = 0.0
@export_range(0.0, 2.0, 0.01) var knockback_duration: float = 0.0
@export_range(-1.0, 1.0, 0.01) var knockback_direction_x: float = 0.0
@export_range(0.0, 5.0, 0.05) var stun_seconds: float = 0.0
@export var status_id: StringName = &""
@export_range(0.0, 30.0, 0.05) var status_duration_seconds: float = 0.0
@export_range(0.0, 10.0, 0.05) var minimum_decision_window_seconds: float = 0.0
@export_range(0.1, 4.0, 0.05) var reposition_speed_multiplier: float = 1.0
@export_multiline var strong_case: String = ""
@export_multiline var weak_case: String = ""
@export_multiline var invalid_case: String = ""
@export_multiline var hold_case: String = ""
@export_multiline var counter_case: String = ""


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if id == &"" or not String(id).begins_with("wp05_proto_"):
		errors.append("WP05 prototype action id must use the wp05_proto_ prefix")
	if role_id not in [&"environment", &"focus", &"rally"]:
		errors.append("WP05 prototype action role must be environment, focus, or rally")
	if display_name.strip_edges().is_empty() or contextual_verb.strip_edges().is_empty():
		errors.append("WP05 prototype action requires display name and contextual verb")
	if effect_kind < EffectKind.POWER_BOX or effect_kind > EffectKind.RALLY_REPOSITION:
		errors.append("WP05 prototype action effect kind is invalid")
	if role_id == &"environment" and range_radius <= 0.0:
		errors.append("WP05 environment prototype requires a positive range")
	if role_id in [&"focus", &"rally"] and minimum_decision_window_seconds <= 0.0:
		errors.append("WP05 timed prototype requires a positive decision window")
	for evidence: String in [strong_case, weak_case, invalid_case, hold_case, counter_case]:
		if evidence.strip_edges().is_empty():
			errors.append("WP05 prototype action requires all decision-evidence cases")
			break
	return errors
