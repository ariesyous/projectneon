class_name GameHUD
extends CanvasLayer

## Presents authoritative run snapshots and forwards future player intent. It
## never calculates or owns combat, health, timing, or reward state.

const RESPONSIBILITY: String = "Run presentation and player input forwarding"

@onready var timer_label: Label = $Root/RunStatusPanel/TimerLabel
@onready var resource_values: Label = $Root/ResourcesPanel/Values
@onready var crew_state_label: Label = $Root/CrewPanel/CrewState
@onready var health_meter: ProgressBar = $Root/CrewPanel/HealthMeter
@onready var health_label: Label = $Root/CrewPanel/HealthLabel
@onready var crew_status_label: Label = $Root/CrewPanel/StatusLabel


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
