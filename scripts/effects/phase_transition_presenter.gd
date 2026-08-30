class_name PhaseTransitionPresenter
extends CanvasLayer

## Short presentation-only state punctuation rendered below the native HUD.
## It observes accepted RunDirector states and cannot advance, pause, or delay
## gameplay authority.

signal transition_started(phase_id: StringName, heading: String)
signal transition_finished(phase_id: StringName)

const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const VOID: Color = Color("050712")
const INK: Color = Color("f3f6ff")
const CYAN: Color = Color("43e6e8")
const MAGENTA: Color = Color("ff5c82")
const AMBER: Color = Color("ffc45c")
const ACID: Color = Color("b8f35d")
const VIOLET: Color = Color("9b73ff")
const CRITICAL: Color = Color("ff415f")

var _root: Control
var _veil: ColorRect
var _rail: ColorRect
var _heading: Label
var _detail: Label
var _active_tween: Tween
var _phase_id: StringName = &""
var _transition_count: int = 0


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_surface()
	clear()


func present_state(
	state: int,
	district_snapshot: Dictionary = {},
	card_planning_pause: bool = false
) -> void:
	var phase: Dictionary = _phase_copy(state, district_snapshot, card_planning_pause)
	if phase.is_empty():
		clear()
		return
	present(
		StringName(phase.get("id", &"phase")),
		str(phase.get("heading", "PHASE")),
		str(phase.get("detail", "")),
		Color(phase.get("accent", CYAN)),
		bool(phase.get("major", false))
	)


func present(
	phase_id: StringName,
	heading: String,
	detail: String,
	accent: Color,
	major: bool = false
) -> void:
	if _root == null:
		_build_surface()
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_phase_id = phase_id
	_transition_count += 1
	_heading.text = heading.to_upper()
	_detail.text = detail.to_upper()
	_heading.add_theme_color_override(&"font_color", INK)
	_detail.add_theme_color_override(&"font_color", accent)
	_rail.color = accent
	_veil.color = Color(VOID, 0.76 if major else 0.46)
	_root.visible = true
	_root.modulate.a = 0.0
	_rail.scale = Vector2(0.0, 1.0)
	_heading.position = Vector2(430.0, 304.0)
	_detail.position = Vector2(430.0, 364.0)
	transition_started.emit(_phase_id, _heading.text)

	if not is_inside_tree():
		_root.modulate.a = 1.0
		_rail.scale = Vector2.ONE
		return
	var hold_seconds: float = 0.28 if major else 0.12
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(_root, "modulate:a", 1.0, 0.10)
	_active_tween.tween_property(_rail, "scale:x", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(_heading, "position:x", 452.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(_detail, "position:x", 452.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.set_parallel(false)
	_active_tween.tween_interval(hold_seconds)
	_active_tween.set_parallel(true)
	_active_tween.tween_property(_root, "modulate:a", 0.0, 0.18)
	_active_tween.tween_property(_heading, "position:x", 474.0, 0.18)
	_active_tween.tween_property(_detail, "position:x", 474.0, 0.18)
	_active_tween.set_parallel(false)
	_active_tween.tween_callback(_finish_transition)


func clear() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if _root != null:
		_root.visible = false
		_root.modulate.a = 1.0
	_phase_id = &""


func is_transition_active() -> bool:
	return _root != null and _root.visible


func get_snapshot() -> Dictionary:
	return {
		"phase_id": _phase_id,
		"active": is_transition_active(),
		"transition_count": _transition_count,
		"heading": _heading.text if _heading != null else "",
		"detail": _detail.text if _detail != null else "",
		"mouse_passthrough": _root == null or _root.mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}


func _finish_transition() -> void:
	var completed_phase: StringName = _phase_id
	if _root != null:
		_root.visible = false
	_phase_id = &""
	transition_finished.emit(completed_phase)


func _build_surface() -> void:
	if _root != null:
		return
	_root = Control.new()
	_root.name = "PhaseTransitionRoot"
	_root.size = DESIGN_SIZE
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_veil = ColorRect.new()
	_veil.name = "WorldVeil"
	_veil.size = DESIGN_SIZE
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_veil)
	_rail = ColorRect.new()
	_rail.name = "PhaseRail"
	_rail.position = Vector2(350.0, 346.0)
	_rail.size = Vector2(580.0, 4.0)
	_rail.pivot_offset = Vector2(290.0, 2.0)
	_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_rail)
	_heading = Label.new()
	_heading.name = "Heading"
	_heading.size = Vector2(400.0, 54.0)
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heading.add_theme_font_size_override(&"font_size", 34)
	_heading.add_theme_color_override(&"font_outline_color", VOID)
	_heading.add_theme_constant_override(&"outline_size", 5)
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_heading)
	_detail = Label.new()
	_detail.name = "Detail"
	_detail.size = Vector2(400.0, 34.0)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail.add_theme_font_size_override(&"font_size", 16)
	_detail.add_theme_color_override(&"font_outline_color", VOID)
	_detail.add_theme_constant_override(&"outline_size", 4)
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_detail)


func _phase_copy(
	state: int,
	district: Dictionary,
	card_planning_pause: bool
) -> Dictionary:
	var progress: String = "LAP %d/3  /  BLOCK %d/3" % [
		clampi(int(district.get("lap_index", 1)), 1, 3),
		clampi(int(district.get("block_index", 1)), 1, 3),
	]
	match state:
		RunDirector.RunState.INTRO:
			return {"id": &"intro", "heading": "DOWNTOWN LOOP", "detail": "CREW ENTERING  /  NEXT: PLAN", "accent": CYAN}
		RunDirector.RunState.PATROLLING:
			return {"id": &"plan", "heading": "PLAN", "detail": progress + "  /  CHOOSE THE NEXT BLOCK", "accent": CYAN}
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			return {"id": &"fight", "heading": "FIGHT", "detail": progress + "  /  READ INTENT  /  INTERVENE", "accent": AMBER}
		RunDirector.RunState.REWARD_SELECTION:
			return {"id": &"reward", "heading": "REWARD", "detail": "CHOOSE GEAR OR KEEP THE BUILD", "accent": ACID}
		RunDirector.RunState.SHOP:
			return {"id": &"shop", "heading": "SHOP", "detail": "FINITE STOCK  /  BUY OR LEAVE", "accent": CYAN}
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			return {"id": &"decision", "heading": "PUSH / EXTRACT", "detail": "FINAL ON CONFIRM", "accent": MAGENTA, "major": true}
		RunDirector.RunState.EXTRACTING:
			return {"id": &"extract", "heading": "EXTRACTION", "detail": "RESULT INCOMING", "accent": CYAN, "major": true}
		RunDirector.RunState.BOSS_INTRO:
			return {"id": &"boss_intro", "heading": "THE VIPER", "detail": "LOCKDOWN  /  READ EVERY TELL", "accent": CRITICAL, "major": true}
		RunDirector.RunState.BOSS_ACTIVE:
			return {"id": &"boss", "heading": "BOSS", "detail": "DEFEAT THE VIPER", "accent": VIOLET, "major": true}
		RunDirector.RunState.VICTORY:
			return {"id": &"victory", "heading": "VICTORY", "detail": "THE VIPER IS DOWN", "accent": ACID, "major": true}
		RunDirector.RunState.DEFEAT:
			return {"id": &"defeat", "heading": "DEFEATED", "detail": "RUN ENDED", "accent": CRITICAL, "major": true}
		RunDirector.RunState.RUN_SUMMARY:
			return {"id": &"result", "heading": "RESULT", "detail": "REVIEW THE BUILD AND DECISIONS", "accent": VIOLET, "major": true}
		RunDirector.RunState.PAUSED:
			return {
				"id": &"district_plan" if card_planning_pause else &"paused",
				"heading": "DISTRICT PLAN" if card_planning_pause else "PAUSED",
				"detail": "SELECT ONE NEXT BLOCK" if card_planning_pause else "ELIGIBLE TIME STOPPED",
				"accent": CYAN if card_planning_pause else VIOLET,
			}
	return {}
