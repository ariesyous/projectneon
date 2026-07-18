class_name GameHUD
extends CanvasLayer

## Presents authoritative run snapshots and forwards player intent. It never
## calculates or owns combat, health, intervention, timing, or reward state.

signal hydrant_activation_requested()
signal hydrant_preview_requested(is_visible: bool)
signal fullscreen_requested()

enum HydrantPresentationState {
	AVAILABLE,
	UNAVAILABLE,
	COOLING_DOWN,
}

const RESPONSIBILITY: String = "Run presentation and player input forwarding"
const ONBOARDING_EXPANDED_SECONDS: float = 12.0
const DESIGN_SIZE: Vector2 = Vector2(640.0, 360.0)
const MAX_SAFE_INSET: Vector2 = Vector2(16.0, 12.0)
const HYDRANT_PANEL_BASE_POSITION: Vector2 = Vector2(510.0, 155.0)
const HELP_PANEL_BASE_POSITION: Vector2 = Vector2(130.0, 290.0)
const HELP_BUTTON_BASE_POSITION: Vector2 = Vector2(6.0, 290.0)
const FULLSCREEN_BUTTON_BASE_POSITION: Vector2 = Vector2(64.0, 290.0)
const LAB_PURPOSE_BASE_POSITION: Vector2 = Vector2(6.0, 326.0)
const HYDRANT_READY_COLOR: Color = Color("72f0d0")
const HYDRANT_UNAVAILABLE_COLOR: Color = Color("ffbf69")
const HYDRANT_COOLDOWN_COLOR: Color = Color("a987ff")

@onready var timer_label: Label = $Root/RunStatusPanel/TimerLabel
@onready var resource_values: Label = $Root/ResourcesPanel/Values
@onready var crew_state_label: Label = $Root/CrewPanel/CrewState
@onready var health_meter: ProgressBar = $Root/CrewPanel/HealthMeter
@onready var health_label: Label = $Root/CrewPanel/HealthLabel
@onready var crew_status_label: Label = $Root/CrewPanel/StatusLabel

@onready var hydrant_state_label: Label = $Root/InterventionsPanel/StateLabel
@onready var hydrant_button: Button = $Root/InterventionsPanel/HydrantButton
@onready var hydrant_cooldown_meter: ProgressBar = $Root/InterventionsPanel/CooldownMeter
@onready var hydrant_cooldown_label: Label = $Root/InterventionsPanel/CooldownLabel
@onready var hydrant_feedback_label: Label = $Root/InterventionsPanel/FeedbackLabel
@onready var interventions_panel: Panel = $Root/InterventionsPanel

@onready var help_panel: Panel = $Root/HelpPanel
@onready var help_button: Button = $Root/HelpButton
@onready var fullscreen_button: Button = $Root/FullscreenButton
@onready var lab_purpose_label: Label = $Root/LabPurpose
@onready var audio_unlock_panel: Panel = $Root/AudioUnlockPanel
@onready var audio_unlock_label: Label = $Root/AudioUnlockPanel/Label
@onready var landscape_panel: Panel = $Root/LandscapePanel

var _onboarding_remaining: float = ONBOARDING_EXPANDED_SECONDS
var _hydrant_state: int = HydrantPresentationState.UNAVAILABLE
var _hydrant_cooldown_remaining: float = 0.0
var _hydrant_cooldown_total: float = 1.0
var _hydrant_valid_enemy_count: int = 0
var _hydrant_feedback: String = "NO ENEMY IN RANGE"
var _fullscreen_active: bool = false
var _audio_unlock_completed: bool = false
var _pending_safe_area: Rect2i = Rect2i()
var _pending_window_size: Vector2i = Vector2i.ZERO


func _ready() -> void:
	hydrant_button.pressed.connect(_on_hydrant_button_pressed)
	hydrant_button.mouse_entered.connect(_on_hydrant_preview_entered)
	hydrant_button.mouse_exited.connect(_on_hydrant_preview_exited)
	hydrant_button.focus_entered.connect(_on_hydrant_preview_entered)
	hydrant_button.focus_exited.connect(_on_hydrant_preview_exited)
	help_button.pressed.connect(_toggle_help)
	fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)
	help_panel.visible = true
	audio_unlock_panel.visible = false
	landscape_panel.visible = false
	_refresh_hydrant_presentation()
	_refresh_fullscreen_presentation()
	_refresh_safe_area_layout()


func _process(delta: float) -> void:
	if _onboarding_remaining <= 0.0 or not help_panel.visible:
		return
	_onboarding_remaining = maxf(0.0, _onboarding_remaining - maxf(0.0, delta))
	if _onboarding_remaining <= 0.0:
		_set_help_expanded(false)


func present_lab_elapsed(elapsed_seconds: float) -> void:
	var safe_seconds: int = maxi(0, int(floor(elapsed_seconds)))
	var minutes: int = int(floor(float(safe_seconds) / 60.0))
	var seconds: int = safe_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func present_jax_status(
	current_health: float,
	maximum_health: float,
	state_name: StringName,
	target_name: String
) -> void:
	var safe_maximum: float = maxf(1.0, maximum_health)
	var safe_current: float = clampf(current_health, 0.0, safe_maximum)
	health_meter.max_value = safe_maximum
	health_meter.value = safe_current
	health_label.text = "HEALTH %d / %d" % [int(round(safe_current)), int(round(safe_maximum))]
	crew_state_label.text = _compact_state_name(state_name)
	crew_status_label.text = "TARGET\n%s\nAUTO FIGHTING" % (
		target_name if not target_name.is_empty() else "NONE"
	)


func present_coin_status(total_coins: int, streak_count: int, status_message: String) -> void:
	var streak_text: String = "x%d MANUAL" % streak_count if streak_count > 0 else "—"
	var message: String = status_message if not status_message.is_empty() else "AUTO = FULL VALUE"
	resource_values.text = "COINS %03d\nSTREAK %s\n%s" % [maxi(0, total_coins), streak_text, message]


## Presents an authoritative Hydrant snapshot. State values use the local
## HydrantPresentationState mapping; the button intentionally remains enabled
## so unavailable attempts reach gameplay authority and receive feedback.
func present_hydrant_state(
	state: int,
	cooldown_remaining: float,
	cooldown_total: float,
	valid_enemy_count: int,
	feedback: String
) -> void:
	_hydrant_state = state
	_hydrant_cooldown_remaining = maxf(0.0, cooldown_remaining)
	_hydrant_cooldown_total = maxf(0.001, cooldown_total)
	_hydrant_valid_enemy_count = maxi(0, valid_enemy_count)
	_hydrant_feedback = feedback.strip_edges()
	if is_node_ready():
		_refresh_hydrant_presentation()


func present_fullscreen_state(is_fullscreen: bool) -> void:
	_fullscreen_active = is_fullscreen
	if is_node_ready():
		_refresh_fullscreen_presentation()


## The prompt is intentionally presentation-only and ignores mouse input. A
## run-level input observer can unlock audio without stealing the same press
## from a coin, Hydrant, or HUD control.
func present_audio_unlock_required(is_required: bool) -> void:
	if not is_node_ready():
		return
	audio_unlock_panel.modulate = Color.WHITE
	audio_unlock_label.text = "CLICK / TAP / PRESS A KEY FOR SOUND"
	audio_unlock_panel.visible = (
		is_required
		and OS.has_feature("web")
		and not _audio_unlock_completed
	)


func present_audio_unlocked() -> void:
	_audio_unlock_completed = true
	if not is_node_ready():
		return
	if not OS.has_feature("web"):
		audio_unlock_panel.visible = false
		return
	audio_unlock_panel.visible = true
	audio_unlock_panel.modulate = Color.WHITE
	audio_unlock_label.text = "SOUND ON"
	var tween: Tween = create_tween()
	tween.tween_interval(0.75)
	tween.tween_property(audio_unlock_panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(audio_unlock_panel.hide)


func present_landscape_state(is_landscape: bool) -> void:
	if not is_node_ready():
		return
	landscape_panel.visible = not is_landscape


## Keeps the edge-critical Hydrant, Help, and fullscreen controls inside native
## mobile safe areas. The standard Web shell already avoids notch overlap; its
## fallback display rect is ignored when it does not describe this window.
func apply_safe_area(safe_area: Rect2i, window_size: Vector2i) -> void:
	_pending_safe_area = safe_area
	_pending_window_size = window_size
	if is_node_ready():
		_refresh_safe_area_layout()


func _refresh_safe_area_layout() -> void:
	var left_inset: float = 0.0
	var right_inset: float = 0.0
	var bottom_inset: float = 0.0
	if _safe_area_matches_window(_pending_safe_area, _pending_window_size):
		var safe_end_x: int = _pending_safe_area.position.x + _pending_safe_area.size.x
		var safe_end_y: int = _pending_safe_area.position.y + _pending_safe_area.size.y
		var scale_x: float = DESIGN_SIZE.x / float(_pending_window_size.x)
		var scale_y: float = DESIGN_SIZE.y / float(_pending_window_size.y)
		left_inset = clampf(
			float(maxi(0, _pending_safe_area.position.x)) * scale_x,
			0.0,
			MAX_SAFE_INSET.x
		)
		right_inset = clampf(
			float(maxi(0, _pending_window_size.x - safe_end_x)) * scale_x,
			0.0,
			MAX_SAFE_INSET.x
		)
		bottom_inset = clampf(
			float(maxi(0, _pending_window_size.y - safe_end_y)) * scale_y,
			0.0,
			MAX_SAFE_INSET.y
		)

	interventions_panel.position = HYDRANT_PANEL_BASE_POSITION + Vector2(-right_inset, 0.0)
	help_panel.position = HELP_PANEL_BASE_POSITION + Vector2(0.0, -bottom_inset)
	help_button.position = HELP_BUTTON_BASE_POSITION + Vector2(left_inset, -bottom_inset)
	fullscreen_button.position = FULLSCREEN_BUTTON_BASE_POSITION + Vector2(left_inset, -bottom_inset)
	lab_purpose_label.position = LAB_PURPOSE_BASE_POSITION + Vector2(left_inset, -bottom_inset)


func _safe_area_matches_window(safe_area: Rect2i, window_size: Vector2i) -> bool:
	if window_size.x <= 0 or window_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return false
	# Desktop/Web fallbacks often report the full monitor rather than the game
	# window. Only apply insets when the rect plausibly shares window coordinates.
	return (
		safe_area.size.x <= ceili(float(window_size.x) * 1.05)
		and safe_area.size.y <= ceili(float(window_size.y) * 1.05)
		and safe_area.position.x >= 0
		and safe_area.position.y >= 0
		and safe_area.position.x <= window_size.x / 4
		and safe_area.position.y <= window_size.y / 4
	)


func _refresh_hydrant_presentation() -> void:
	hydrant_button.disabled = false
	var state_color: Color = HYDRANT_UNAVAILABLE_COLOR
	match _hydrant_state:
		HydrantPresentationState.AVAILABLE:
			state_color = HYDRANT_READY_COLOR
			hydrant_state_label.text = "READY • %d IN RANGE" % _hydrant_valid_enemy_count
			hydrant_button.text = "BLAST WATER"
			hydrant_cooldown_label.text = "READY NOW"
		HydrantPresentationState.COOLING_DOWN:
			state_color = HYDRANT_COOLDOWN_COLOR
			hydrant_state_label.text = "COOLING DOWN"
			hydrant_button.text = "COOLDOWN %.1fs" % _hydrant_cooldown_remaining
			hydrant_cooldown_label.text = "%.1fs REMAINING" % _hydrant_cooldown_remaining
		_:
			state_color = HYDRANT_UNAVAILABLE_COLOR
			hydrant_state_label.text = "NO ENEMY IN RANGE"
			hydrant_button.text = "TRY HYDRANT"
			hydrant_cooldown_label.text = "READY • NEEDS TARGET"

	var elapsed_cooldown: float = clampf(
		_hydrant_cooldown_total - _hydrant_cooldown_remaining,
		0.0,
		_hydrant_cooldown_total
	)
	hydrant_cooldown_meter.max_value = _hydrant_cooldown_total
	hydrant_cooldown_meter.value = elapsed_cooldown
	hydrant_state_label.add_theme_color_override("font_color", state_color)
	hydrant_button.add_theme_color_override("font_color", state_color)
	hydrant_feedback_label.text = (
		_hydrant_feedback
		if not _hydrant_feedback.is_empty()
		else "READY + ENEMY IN RANGE"
	)


func _refresh_fullscreen_presentation() -> void:
	fullscreen_button.text = "EXIT FULL" if _fullscreen_active else "FULLSCREEN"
	fullscreen_button.tooltip_text = (
		"Return to windowed presentation"
		if _fullscreen_active
		else "Fill the display while preserving the 16:9 game view"
	)


func _toggle_help() -> void:
	_set_help_expanded(not help_panel.visible)


func _set_help_expanded(is_expanded: bool) -> void:
	help_panel.visible = is_expanded
	help_button.text = "CLOSE HELP" if is_expanded else "HELP"
	if is_expanded:
		_onboarding_remaining = -1.0


func _on_hydrant_button_pressed() -> void:
	hydrant_activation_requested.emit()


func _on_hydrant_preview_entered() -> void:
	hydrant_preview_requested.emit(true)


func _on_hydrant_preview_exited() -> void:
	hydrant_preview_requested.emit(false)


func _on_fullscreen_button_pressed() -> void:
	fullscreen_requested.emit()


func _compact_state_name(state_name: StringName) -> String:
	match state_name:
		&"ACQUIRING_TARGET":
			return "SEEKING"
		&"APPROACHING_TARGET":
			return "APPROACH"
		&"ATTACK_WINDUP":
			return "WINDUP"
		&"ATTACK_ACTIVE":
			return "STRIKING"
		&"ATTACK_RECOVERY":
			return "RECOVERY"
		&"KNOCKED_BACK":
			return "KNOCKBACK"
		&"INCAPACITATED":
			return "DOWN"
		_:
			return String(state_name).replace("_", " ")
