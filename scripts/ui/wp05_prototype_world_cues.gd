class_name WP05PrototypeWorldCues
extends Node2D

## Development-only code-drawn comparison cues. Gameplay ranges and target
## identities come from the prototype authority snapshot.

var _snapshot: Dictionary = {}


func present(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	visible = bool(_snapshot.get("enabled", false))
	queue_redraw()


func _draw() -> void:
	if not visible or _snapshot.is_empty():
		return
	var environment: Dictionary = _snapshot.get("environment", {})
	var environment_origin: Vector2 = environment.get("world_origin", Vector2.ZERO)
	var environment_radius: float = float(environment.get("range_radius", 0.0))
	var environment_ready: bool = bool(environment.get("can_activate", false))
	var environment_color: Color = (
		Color(0.35, 0.95, 1.0, 0.88)
		if environment_ready
		else Color(1.0, 0.76, 0.3, 0.72)
	)
	if environment_radius > 0.0:
		draw_circle(environment_origin, environment_radius, Color(environment_color, 0.08), true)
		draw_arc(environment_origin, environment_radius, 0.0, TAU, 48, environment_color, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			environment_origin + Vector2(-52.0, -environment_radius - 8.0),
			str(environment.get("verb", "ENVIRONMENT")),
			HORIZONTAL_ALIGNMENT_CENTER,
			104.0,
			8,
			environment_color
		)
	var focus: Dictionary = _snapshot.get("focus", {})
	var focus_position: Vector2 = focus.get("target_position", Vector2.ZERO)
	if int(focus.get("target_instance_id", -1)) > 0:
		var focus_color: Color = Color(1.0, 0.35, 0.76, 0.95)
		draw_arc(focus_position, 20.0, 0.0, TAU, 24, focus_color, 2.0)
		draw_line(focus_position + Vector2(-28.0, 0.0), focus_position + Vector2(-16.0, 0.0), focus_color, 2.0)
		draw_line(focus_position + Vector2(16.0, 0.0), focus_position + Vector2(28.0, 0.0), focus_color, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			focus_position + Vector2(-60.0, -30.0),
			"FOCUS %.1fs" % float(focus.get("window_seconds", 0.0)),
			HORIZONTAL_ALIGNMENT_CENTER,
			120.0,
			8,
			focus_color
		)
	var rally: Dictionary = _snapshot.get("rally", {})
	for anchor_value: Variant in rally.get("anchors", []):
		if not (anchor_value is Vector2):
			continue
		var anchor: Vector2 = anchor_value
		draw_rect(Rect2(anchor - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), Color(1.0, 0.9, 0.35, 0.18), true)
		draw_rect(Rect2(anchor - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), Color(1.0, 0.9, 0.35, 0.9), false, 2.0)
