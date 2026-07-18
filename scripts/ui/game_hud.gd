class_name GameHUD
extends CanvasLayer

## Presents authoritative run snapshots and forwards player intent. It never
## calculates or owns combat, health, intervention, timing, or reward state.

signal hydrant_activation_requested()
signal hydrant_preview_requested(is_visible: bool)
signal fullscreen_requested()
signal primary_action_requested()
signal extraction_requested()
signal subway_reroute_requested()
signal shop_cooling_requested()
signal restart_same_seed_requested()
signal restart_new_seed_requested()

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
@onready var heat_label: Label = $Root/RunStatusPanel/HeatLabel
@onready var heat_meter: ProgressBar = $Root/RunStatusPanel/HeatMeter
@onready var night_pressure_label: Label = $Root/RunStatusPanel/NightPressureLabel
@onready var night_pressure_meter: ProgressBar = $Root/RunStatusPanel/NightPressureMeter
@onready var threshold_label: Label = $Root/RunStatusPanel/ThresholdLabel
@onready var route_title: Label = $Root/MinimapPanel/Title
@onready var route_label: Label = $Root/MinimapPanel/Route
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
@onready var run_actions_title: Label = $Root/CardsPanel/Title
@onready var primary_action_button: Button = $Root/CardsPanel/Card01
@onready var subway_reroute_button: Button = $Root/CardsPanel/Card02
@onready var shop_cooling_button: Button = $Root/CardsPanel/Card03
@onready var extraction_button: Button = $Root/ExtractionPanel/ExtractionButton
@onready var summary_panel: Panel = $Root/RunSummaryPanel
@onready var summary_title: Label = $Root/RunSummaryPanel/Title
@onready var summary_details: Label = $Root/RunSummaryPanel/Details
@onready var summary_same_seed_button: Button = $Root/RunSummaryPanel/RestartSameSeed
@onready var summary_new_seed_button: Button = $Root/RunSummaryPanel/RestartNewSeed
@onready var boss_trigger_panel: Panel = $Root/BossTriggerPanel
@onready var boss_same_seed_button: Button = $Root/BossTriggerPanel/RestartSameSeed
@onready var boss_new_seed_button: Button = $Root/BossTriggerPanel/RestartNewSeed

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
var _scrap_total: int = 0
var _last_run_snapshot: Dictionary = {}


func _ready() -> void:
	hydrant_button.pressed.connect(_on_hydrant_button_pressed)
	hydrant_button.mouse_entered.connect(_on_hydrant_preview_entered)
	hydrant_button.mouse_exited.connect(_on_hydrant_preview_exited)
	hydrant_button.focus_entered.connect(_on_hydrant_preview_entered)
	hydrant_button.focus_exited.connect(_on_hydrant_preview_exited)
	help_button.pressed.connect(_toggle_help)
	fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)
	primary_action_button.pressed.connect(_on_primary_action_pressed)
	subway_reroute_button.pressed.connect(_on_subway_reroute_pressed)
	shop_cooling_button.pressed.connect(_on_shop_cooling_pressed)
	extraction_button.pressed.connect(_on_extraction_pressed)
	summary_same_seed_button.pressed.connect(_on_restart_same_seed_pressed)
	summary_new_seed_button.pressed.connect(_on_restart_new_seed_pressed)
	boss_same_seed_button.pressed.connect(_on_restart_same_seed_pressed)
	boss_new_seed_button.pressed.connect(_on_restart_new_seed_pressed)
	help_panel.visible = true
	summary_panel.visible = false
	boss_trigger_panel.visible = false
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
	var message: String = status_message if not status_message.is_empty() else "AUTO • FULL VALUE"
	resource_values.text = "COINS %03d  SCRAP %02d\nSTREAK %s\n%s" % [
		maxi(0, total_coins),
		maxi(0, _scrap_total),
		streak_text,
		message,
	]


func present_scrap_total(total_scrap: int) -> void:
	_scrap_total = maxi(total_scrap, 0)
	var current_coins: int = int(_last_run_snapshot.get("coins", 0))
	var streak_count: int = int(_last_run_snapshot.get("streak_count", 0))
	present_coin_status(current_coins, streak_count, "RUN REWARDS SECURED")


func present_flow_snapshot(snapshot: Dictionary) -> void:
	var run: Dictionary = snapshot.get("run", {})
	var patrol: Dictionary = snapshot.get("patrol", {})
	var encounter: Dictionary = snapshot.get("encounter", {})
	var rewards: Dictionary = snapshot.get("rewards", {})
	var cooling: Dictionary = snapshot.get("cooling", {})
	_last_run_snapshot = {
		"coins": int(rewards.get("coin_total", 0)),
		"streak_count": int(rewards.get("streak_count", 0)),
	}
	_scrap_total = int(rewards.get("scrap_total", 0))
	present_lab_elapsed(float(run.get("run_elapsed_seconds", 0.0)))
	present_coin_status(
		int(rewards.get("coin_total", 0)),
		int(rewards.get("streak_count", 0)),
		"AUTO • FULL VALUE"
	)

	var heat_value: int = int(run.get("heat", 0))
	var heat_tier: int = int(run.get("heat_tier", 0))
	heat_label.text = "HEAT %03d  •  TIER %d  •  %s" % [
		heat_value,
		heat_tier,
		_heat_implication(heat_tier),
	]
	heat_meter.value = heat_value
	var pressure: float = float(run.get("night_pressure", 0.0))
	var boss_threshold: float = maxf(float(run.get("boss_threshold", 1.0)), 0.001)
	night_pressure_meter.max_value = boss_threshold
	night_pressure_meter.value = pressure
	night_pressure_label.text = "NIGHT PRESSURE %.1f  •  IRREVERSIBLE" % pressure
	threshold_label.text = "NEXT %.1f  •  BOSS %.1f%s" % [
		float(run.get("next_major_threshold", boss_threshold)),
		boss_threshold,
		"  •  QUEUED" if bool(run.get("boss_queued", false)) else "",
	]

	var node_id: String = String(patrol.get("route_node_id", &"departing_hideout"))
	route_title.text = "ROUTE • %s" % node_id.replace("_", " ").to_upper()
	var route_index: int = int(patrol.get("route_index", -1))
	var route_progress: float = float(patrol.get("route_progress", 0.0))
	route_label.text = "NODE %d  •  %02d%%  •  LOOP %d" % [
		route_index + 1,
		int(round(route_progress * 100.0)),
		int(patrol.get("loop_count", 0)),
	]

	var state: int = int(run.get("state", RunDirector.RunState.INITIALIZING))
	var encounter_name: String = String(encounter.get("active_encounter_name", "Patrolling"))
	_refresh_run_actions(state, encounter_name, cooling, rewards)
	if state == RunDirector.RunState.EXTRACTION_AVAILABLE:
		extraction_button.text = "EXTRACT NOW\n%d COINS + %d SCRAP  •  x%.2f" % [
			int(rewards.get("coin_total", 0)),
			int(rewards.get("scrap_total", 0)),
			float(run.get("reward_multiplier", 1.0)),
		]
	summary_panel.visible = state == RunDirector.RunState.RUN_SUMMARY
	boss_trigger_panel.visible = state == RunDirector.RunState.BOSS_ACTIVE


func present_run_summary(summary: RunSummaryRecord) -> void:
	if summary == null:
		return
	summary_title.text = "%s  •  RUN COMPLETE" % summary.result_label
	summary_details.text = (
		"TIME %s   SEED %d   SCHEMA %d\n"
		+ "MAX HEAT %d   NIGHT PRESSURE %.1f   ENCOUNTERS %d\n"
		+ "ENEMIES %d   ELITES %d   BOSS %s   COMBO %d\n"
		+ "COINS %d   SCRAP %d   MANUAL %d   STREAK x%d\n"
		+ "EQUIPMENT %s   SYNERGIES %s"
	) % [
		_format_time(summary.duration_seconds),
		summary.run_seed,
		summary.random_schema_version,
		summary.maximum_heat,
		summary.final_night_pressure,
		summary.encounters_completed,
		summary.enemies_defeated,
		summary.elites_defeated,
		"DEFEATED" if summary.boss_defeated else "NO",
		summary.highest_combo,
		summary.coins_collected,
		summary.scrap_secured,
		summary.manual_clusters_collected,
		summary.maximum_manual_streak,
		summary.equipment_build,
		summary.active_synergies,
	]
	summary_panel.visible = true
	boss_trigger_panel.visible = false


func present_action_feedback(message: String) -> void:
	if message.is_empty():
		return
	_hydrant_feedback = message
	hydrant_feedback_label.text = message


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


func _on_primary_action_pressed() -> void:
	primary_action_requested.emit()


func _on_subway_reroute_pressed() -> void:
	subway_reroute_requested.emit()


func _on_shop_cooling_pressed() -> void:
	shop_cooling_requested.emit()


func _on_extraction_pressed() -> void:
	extraction_requested.emit()


func _on_restart_same_seed_pressed() -> void:
	restart_same_seed_requested.emit()


func _on_restart_new_seed_pressed() -> void:
	restart_new_seed_requested.emit()


func _refresh_run_actions(
	state: int,
	encounter_name: String,
	cooling: Dictionary,
	rewards: Dictionary
) -> void:
	run_actions_title.text = "RUN ACTIONS • %s" % RunDirector.state_name(state).replace("_", " ")
	var primary_disabled: bool = true
	var primary_text: String = "PATROLLING\nAUTOMATIC"
	match state:
		RunDirector.RunState.INTRO:
			primary_text = "RUN STARTING\nSTAND BY"
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			primary_text = "%s\nIN PROGRESS" % encounter_name.to_upper()
		RunDirector.RunState.REWARD_SELECTION:
			primary_disabled = false
			primary_text = "CLAIM\nSTANDARD REWARD"
		RunDirector.RunState.SHOP:
			primary_disabled = false
			primary_text = "LEAVE\nSHOP"
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			primary_disabled = false
			primary_text = "CONTINUE\nRUN (+6 HEAT)"
		RunDirector.RunState.BOSS_INTRO:
			primary_disabled = false
			primary_text = "ENTER\nBOSS THRESHOLD"
		RunDirector.RunState.BOSS_ACTIVE:
			primary_text = "BOSS TRIGGERED\nCONTENT DEFERRED"
		RunDirector.RunState.PAUSED:
			primary_text = "PAUSED\nSPACE TO RESUME"
		RunDirector.RunState.RUN_SUMMARY:
			primary_text = "RUN\nCOMPLETE"
	_present_action_button(primary_action_button, primary_text, primary_disabled)

	var subway_charges: int = int(cooling.get("subway_charges", 0))
	var subway_disabled: bool = (
		state != RunDirector.RunState.PATROLLING or subway_charges <= 0
	)
	var subway_text: String = "SUBWAY REROUTE\n%d LEFT  •  -%d HEAT" % [
		subway_charges,
		int(cooling.get("subway_heat_reduction", 0)),
	]
	_present_action_button(subway_reroute_button, subway_text, subway_disabled)

	var shop_remaining: int = int(cooling.get("shop_purchases_remaining", 0))
	var shop_cost: int = int(cooling.get("shop_coin_cost", 0))
	var shop_disabled: bool = (
		state != RunDirector.RunState.SHOP
		or shop_remaining <= 0
		or int(rewards.get("coin_total", 0)) < shop_cost
	)
	var shop_text: String = "SHOP COOLING\n%d LEFT  •  %d COINS" % [
		shop_remaining,
		shop_cost,
	]
	_present_action_button(shop_cooling_button, shop_text, shop_disabled)

	var extraction_disabled: bool = state != RunDirector.RunState.EXTRACTION_AVAILABLE
	var extraction_text: String = (
		"EXTRACT NOW\nSECURE RUN"
		if state == RunDirector.RunState.EXTRACTION_AVAILABLE
		else "EXTRACTION\nUNAVAILABLE"
	)
	_present_action_button(extraction_button, extraction_text, extraction_disabled)


func _present_action_button(button: Button, text: String, disabled: bool) -> void:
	## Reassigning `disabled` every frame cancels an in-progress mouse press in
	## Godot. Only mutate actual presentation changes so one press/release is
	## always sufficient for reward and route actions.
	if button.text != text:
		button.text = text
	if button.disabled != disabled:
		button.disabled = disabled


func _heat_implication(tier: int) -> String:
	match tier:
		0:
			return "LOW ALERT"
		1:
			return "MORE ENEMIES"
		2:
			return "AGGRESSIVE"
		3:
			return "ELITE ELIGIBLE"
		4:
			return "MAX STANDARD"
		5:
			return "FULL ALERT"
	return "UNKNOWN"


func _format_time(elapsed_seconds: float) -> String:
	var safe_seconds: int = maxi(0, int(floor(elapsed_seconds)))
	return "%02d:%02d" % [safe_seconds / 60, safe_seconds % 60]


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
