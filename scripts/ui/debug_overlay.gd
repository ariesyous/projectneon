class_name DebugOverlay
extends CanvasLayer

## Development-only diagnostics shell. F1 toggles the overlay and F2 requests
## a presentation-only change to the stage's lane guides.

signal lane_visibility_requested(lanes_are_visible: bool)
signal add_heat_requested(amount: int)
signal advance_pressure_requested()
signal force_defeat_requested()
signal restart_same_seed_requested()

@onready var fps_label: Label = $Root/Panel/FpsLabel
@onready var lane_state_label: Label = $Root/Panel/LaneStateLabel
@onready var lane_toggle_button: Button = $Root/Panel/LaneToggleButton
@onready var state_label: Label = $Root/Panel/StateLabel
@onready var lab_summary_label: Label = $Root/Panel/LabSummaryLabel
@onready var jax_debug_label: Label = $Root/Panel/JaxDebugLabel
@onready var enemy_debug_label: Label = $Root/Panel/EnemyDebugLabel
@onready var reward_debug_label: Label = $Root/Panel/RewardDebugLabel
@onready var add_heat_button: Button = $Root/Panel/AddHeatButton
@onready var advance_pressure_button: Button = $Root/Panel/AdvancePressureButton
@onready var force_defeat_button: Button = $Root/Panel/ForceDefeatButton
@onready var restart_button: Button = $Root/Panel/RestartButton

var _lanes_visible: bool = true
var _fps_refresh_remaining: float = 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		visible = false
		set_process(false)
		set_process_unhandled_key_input(false)
		return

	lane_toggle_button.pressed.connect(_toggle_lanes)
	add_heat_button.pressed.connect(_on_add_heat_pressed)
	advance_pressure_button.pressed.connect(_on_advance_pressure_pressed)
	force_defeat_button.pressed.connect(_on_force_defeat_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	_refresh_lane_text()
	_refresh_fps_text()


func _process(delta: float) -> void:
	_fps_refresh_remaining -= delta
	if _fps_refresh_remaining <= 0.0:
		_fps_refresh_remaining = 0.25
		_refresh_fps_text()


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_F1:
			visible = not visible
			get_viewport().set_input_as_handled()
		KEY_F2:
			_toggle_lanes()
			get_viewport().set_input_as_handled()


func set_lane_visibility(lanes_are_visible: bool) -> void:
	_lanes_visible = lanes_are_visible
	if is_node_ready():
		_refresh_lane_text()


func present_combat_lab(
	elapsed_seconds: float,
	active_enemy_count: int,
	active_cluster_count: int,
	total_coins: int,
	streak_count: int
) -> void:
	state_label.text = "RUN: COMBAT LAB  |  ACTIVE %.1fs" % maxf(0.0, elapsed_seconds)
	lab_summary_label.text = "ACTORS  JAX 1 / ENEMIES %d    CLUSTERS %d" % [
		maxi(0, active_enemy_count),
		maxi(0, active_cluster_count),
	]


func present_run_flow(snapshot: Dictionary) -> void:
	var run: Dictionary = snapshot.get("run", {})
	var patrol: Dictionary = snapshot.get("patrol", {})
	var encounter: Dictionary = snapshot.get("encounter", {})
	var rewards: Dictionary = snapshot.get("rewards", {})
	var cooling: Dictionary = snapshot.get("cooling", {})
	state_label.text = "RUN %s  |  ACTIVE %.1fs  |  SEED %d / SCHEMA %d" % [
		String(run.get("state_name", "UNKNOWN")),
		float(run.get("run_elapsed_seconds", 0.0)),
		int(run.get("run_seed", 0)),
		int(run.get("random_schema_version", 0)),
	]
	lab_summary_label.text = (
		"HEAT %d T%d  |  PRESSURE %.2f / BOSS %.1f  |  QUEUED %s\n"
		+ "ROUTE %s  |  ENCOUNTER %s  |  BUDGET %d / PENDING %d"
	) % [
		int(run.get("heat", 0)),
		int(run.get("heat_tier", 0)),
		float(run.get("night_pressure", 0.0)),
		float(run.get("boss_threshold", 0.0)),
		"YES" if bool(run.get("boss_queued", false)) else "NO",
		String(patrol.get("route_node_id", &"none")),
		String(encounter.get("active_encounter_id", &"none")),
		int(encounter.get("spawn_budget", 0)),
		int(encounter.get("remaining_to_spawn", 0)),
	]
	reward_debug_label.text = (
		"REWARDS  COINS %d  SCRAP %d  |  STREAK x%d  |  SUBWAY %d  SHOP %d"
	) % [
		int(rewards.get("coin_total", 0)),
		int(rewards.get("scrap_total", 0)),
		int(rewards.get("streak_count", 0)),
		int(cooling.get("subway_charges", 0)),
		int(cooling.get("shop_purchases_remaining", 0)),
	]
func present_jax_debug(
	state_name: StringName,
	target_name: String,
	lane: int,
	reservation: String
) -> void:
	jax_debug_label.text = "JAX  STATE %s\nTARGET %s  |  LANE %d  |  SLOT %s" % [
		String(state_name),
		target_name if not target_name.is_empty() else "NONE",
		lane,
		reservation if not reservation.is_empty() else "NONE",
	]


## Each line should be a compact presentation snapshot containing enemy name,
## state, target, lane, and reserved attack position.
func present_enemy_debug(enemy_lines: PackedStringArray) -> void:
	enemy_debug_label.text = "ENEMIES\n%s" % (
		"NONE" if enemy_lines.is_empty() else "\n".join(enemy_lines)
	)


func _toggle_lanes() -> void:
	_lanes_visible = not _lanes_visible
	_refresh_lane_text()
	lane_visibility_requested.emit(_lanes_visible)


func _refresh_lane_text() -> void:
	var state_text: String = "VISIBLE" if _lanes_visible else "HIDDEN"
	lane_state_label.text = "COMBAT LANES: %s" % state_text
	lane_toggle_button.text = "F2  %s LANES" % ("HIDE" if _lanes_visible else "SHOW")


func _refresh_fps_text() -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _on_add_heat_pressed() -> void:
	add_heat_requested.emit(10)


func _on_advance_pressure_pressed() -> void:
	advance_pressure_requested.emit()


func _on_force_defeat_pressed() -> void:
	force_defeat_requested.emit()


func _on_restart_pressed() -> void:
	restart_same_seed_requested.emit()
