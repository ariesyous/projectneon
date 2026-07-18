class_name GameRun
extends Node

## Run-scoped composition root. It wires combat, reward, intervention, display,
## and replaceable presentation nodes without owning their gameplay state.

const HYDRANT_COIN_EXCLUSION_RADIUS: float = 76.0

@onready var downtown_loop: DowntownLoop = $DowntownLoop
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var game_hud: GameHUD = $GameHUD
@onready var combat_director: CombatDirector = $CombatDirector
@onready var reward_director: RewardDirector = $RewardDirector
@onready var combat_lab_controller: CombatLabController = $CombatLabController
@onready var fire_hydrant_controller: FireHydrantController = $FireHydrantController
@onready var display_controller: DisplayController = $DisplayController
@onready var fire_hydrant: FireHydrant = $DowntownLoop/Interactables/FireHydrant
@onready var combat_feedback: CombatFeedback = $DowntownLoop/EffectsContainer/CombatFeedback

var _last_coin_status: String = "AUTO = FULL VALUE"
var _hydrant_feedback_override: String = ""
var _hydrant_feedback_remaining: float = 0.0
var _web_audio_unlocked: bool = false


func _ready() -> void:
	debug_overlay.lane_visibility_requested.connect(_on_lane_visibility_requested)
	debug_overlay.set_lane_visibility(downtown_loop.are_debug_lanes_visible())
	combat_director.actor_registered.connect(_on_actor_registered)
	combat_director.actor_died.connect(_on_actor_died)
	combat_director.hit_landed.connect(_on_hit_landed)
	combat_director.environmental_hit_landed.connect(_on_environmental_hit_landed)
	combat_director.crew_status_changed.connect(_on_crew_status_changed)
	reward_director.coins_changed.connect(_on_coins_changed)
	reward_director.streak_changed.connect(_on_streak_changed)
	reward_director.cluster_resolved.connect(_on_cluster_resolved)
	combat_lab_controller.lab_status_changed.connect(_on_lab_status_changed)
	fire_hydrant_controller.state_changed.connect(_on_hydrant_state_changed)
	fire_hydrant_controller.activation_resolved.connect(_on_hydrant_activation_resolved)
	fire_hydrant_controller.activation_rejected.connect(_on_hydrant_activation_rejected)
	fire_hydrant.activation_requested.connect(_request_hydrant_activation)
	game_hud.hydrant_activation_requested.connect(_request_hydrant_activation)
	game_hud.hydrant_preview_requested.connect(fire_hydrant.set_external_preview_visible)
	game_hud.fullscreen_requested.connect(display_controller.toggle_fullscreen)
	display_controller.fullscreen_changed.connect(game_hud.present_fullscreen_state)
	display_controller.landscape_state_changed.connect(game_hud.present_landscape_state)
	display_controller.safe_area_changed.connect(game_hud.apply_safe_area)

	fire_hydrant_controller.configure(combat_director, fire_hydrant.global_position)
	combat_lab_controller.configure_coin_interaction_exclusion(
		fire_hydrant.global_position,
		HYDRANT_COIN_EXCLUSION_RADIUS
	)
	combat_lab_controller.configure(
		combat_director,
		reward_director,
		$DowntownLoop/CrewContainer,
		$DowntownLoop/EnemyContainer,
		$DowntownLoop/LootContainer,
		$DowntownLoop/SpawnPoints/LeftSpawn,
		$DowntownLoop/SpawnPoints/RightSpawn
	)
	if not combat_lab_controller.start_lab():
		push_error("Combat Lab failed to start because a required dependency is missing.")
	_web_audio_unlocked = not OS.has_feature("web")
	game_hud.present_audio_unlock_required(not _web_audio_unlocked)
	display_controller.refresh_state(true)
	_refresh_hydrant_presentation()
	_refresh_combat_presentation()


func _process(delta: float) -> void:
	if _hydrant_feedback_remaining <= 0.0:
		return
	_hydrant_feedback_remaining = maxf(0.0, _hydrant_feedback_remaining - maxf(delta, 0.0))
	if _hydrant_feedback_remaining <= 0.0:
		_hydrant_feedback_override = ""
		_refresh_hydrant_presentation()


func _input(event: InputEvent) -> void:
	if _web_audio_unlocked or not OS.has_feature("web") or not _is_audio_unlock_gesture(event):
		return
	_web_audio_unlocked = true
	combat_feedback.prime_audio()
	game_hud.present_audio_unlocked()


func _on_lane_visibility_requested(lanes_are_visible: bool) -> void:
	downtown_loop.set_debug_lanes_visible(lanes_are_visible)


func _on_actor_registered(actor: ActorController) -> void:
	combat_feedback.show_spawn(actor.global_position + Vector2(0.0, -24.0))


func _on_actor_died(actor: ActorController) -> void:
	combat_feedback.show_death(actor.global_position + Vector2(0.0, -25.0))
	_refresh_combat_presentation()


func _on_hit_landed(
	_attacker: ActorController,
	_target: ActorController,
	damage: int,
	world_position: Vector2,
	hit_stop_duration: float
) -> void:
	combat_feedback.show_hit(
		world_position + Vector2(0.0, -28.0),
		float(damage),
		hit_stop_duration >= 0.06
	)


func _on_environmental_hit_landed(
	_source_id: StringName,
	_target: ActorController,
	damage: int,
	world_position: Vector2,
	_knockback_force: float
) -> void:
	combat_feedback.show_hydrant_impact(
		world_position + Vector2(0.0, -28.0),
		float(damage),
		fire_hydrant_controller.tuning.impact_duration
	)


func _on_crew_status_changed(
	actor: ActorController,
	current_health: int,
	maximum_health: int,
	state: int
) -> void:
	var target_name: String = _actor_display_name(actor.current_target)
	game_hud.present_jax_status(
		float(current_health),
		float(maximum_health),
		StringName(ActorStateMachine.state_name(state)),
		target_name
	)


func _on_coins_changed(total_coins: int) -> void:
	game_hud.present_coin_status(
		total_coins,
		reward_director.get_active_streak_count(),
		_last_coin_status
	)


func _on_streak_changed(streak_count: int, _expires_at_msec: int) -> void:
	game_hud.present_coin_status(
		reward_director.get_coin_total(),
		streak_count,
		_last_coin_status
	)
	_refresh_combat_presentation()


func _on_cluster_resolved(
	_cluster_id: int,
	manual: bool,
	base_value: int,
	bonus_value: int,
	resulting_streak: int
) -> void:
	combat_feedback.play_coin(manual, resulting_streak)
	if manual:
		_last_coin_status = "CLICK +%d" % (base_value + bonus_value)
		if bonus_value > 0:
			_last_coin_status += " (+%d BONUS)" % bonus_value
	else:
		_last_coin_status = "AUTO +%d (FULL)" % base_value
	game_hud.present_coin_status(
		reward_director.get_coin_total(),
		reward_director.get_active_streak_count(),
		_last_coin_status
	)
	_refresh_combat_presentation()


func _on_lab_status_changed(
	elapsed_seconds: float,
	_active_enemies: int,
	_total_spawned: int,
	_total_defeated: int,
	_round_number: int
) -> void:
	game_hud.present_lab_elapsed(elapsed_seconds)
	_refresh_combat_presentation()


func _request_hydrant_activation() -> void:
	fire_hydrant_controller.request_activation()


func _on_hydrant_state_changed(
	_state: int,
	_cooldown_remaining: float,
	_cooldown_duration: float
) -> void:
	_refresh_hydrant_presentation()


func _on_hydrant_activation_resolved(
	_world_origin: Vector2,
	_range_radius: float,
	affected_count: int
) -> void:
	fire_hydrant.play_activation()
	combat_feedback.play_hydrant_activation()
	_hydrant_feedback_override = "%d ENEM%s BLASTED" % [
		affected_count,
		"Y" if affected_count == 1 else "IES",
	]
	_hydrant_feedback_remaining = maxf(
		fire_hydrant_controller.tuning.impact_duration,
		0.01
	)
	_refresh_hydrant_presentation()


func _on_hydrant_activation_rejected(reason: int) -> void:
	fire_hydrant.play_rejection()
	combat_feedback.play_hydrant_rejection()
	_hydrant_feedback_override = (
		"NO VALID ENEMY IN RANGE"
		if reason == FireHydrantController.RejectionReason.NO_VALID_TARGET
		else "HYDRANT IS COOLING DOWN"
	)
	_hydrant_feedback_remaining = maxf(
		fire_hydrant_controller.tuning.rejection_duration,
		0.01
	)
	_refresh_hydrant_presentation()


func _refresh_hydrant_presentation() -> void:
	if fire_hydrant_controller == null or fire_hydrant == null or game_hud == null:
		return
	var state: int = fire_hydrant_controller.get_state()
	var cooldown_remaining: float = fire_hydrant_controller.get_cooldown_remaining()
	var cooldown_duration: float = fire_hydrant_controller.get_cooldown_duration()
	var valid_enemy_count: int = combat_director.get_live_targets_in_circle(
		ActorController.Team.ENEMY,
		fire_hydrant_controller.get_activation_origin(),
		fire_hydrant_controller.get_range_radius()
	).size()
	var feedback: String = _hydrant_feedback_override
	if feedback.is_empty():
		match state:
			FireHydrantController.State.READY:
				feedback = "READY TO CHANGE THE FIGHT"
			FireHydrantController.State.COOLING_DOWN:
				feedback = "WATER PRESSURE RECOVERING"
			_:
				feedback = "WAIT FOR AN ENEMY IN RANGE"
	fire_hydrant.present_state(
		state,
		cooldown_remaining,
		cooldown_duration,
		valid_enemy_count
	)
	game_hud.present_hydrant_state(
		state,
		cooldown_remaining,
		cooldown_duration,
		valid_enemy_count,
		feedback
	)


func _refresh_combat_presentation() -> void:
	var snapshots: Array[Dictionary] = combat_director.get_actor_snapshots()
	var reservation_by_attacker: Dictionary[int, int] = {}
	for reservation: Dictionary in combat_director.get_reservation_snapshot():
		reservation_by_attacker[int(reservation.get("attacker_instance_id", -1))] = int(
			reservation.get("slot_index", -1)
		)

	var display_name_by_id: Dictionary[int, String] = {}
	for snapshot: Dictionary in snapshots:
		var instance_id: int = int(snapshot.get("instance_id", -1))
		display_name_by_id[instance_id] = _snapshot_display_name(snapshot)

	var enemy_lines: PackedStringArray = PackedStringArray()
	var found_jax: bool = false
	for snapshot: Dictionary in snapshots:
		var instance_id: int = int(snapshot.get("instance_id", -1))
		var target_id: int = int(snapshot.get("target_instance_id", -1))
		var target_name: String = display_name_by_id.get(target_id, "NONE")
		var slot_index: int = reservation_by_attacker.get(instance_id, -1)
		var slot_text: String = str(slot_index) if slot_index >= 0 else "NONE"
		if int(snapshot.get("team", ActorController.Team.ENEMY)) == ActorController.Team.CREW:
			found_jax = true
			var state_name: StringName = StringName(str(snapshot.get("state_name", "UNKNOWN")))
			game_hud.present_jax_status(
				float(snapshot.get("current_health", 0)),
				float(snapshot.get("maximum_health", 1)),
				state_name,
				target_name
			)
			debug_overlay.present_jax_debug(
				state_name,
				target_name,
				int(snapshot.get("lane", 1)),
				slot_text
			)
		else:
			enemy_lines.append("%s  %s -> %s  L%d S%s" % [
				_snapshot_display_name(snapshot),
				str(snapshot.get("state_name", "UNKNOWN")),
				target_name,
				int(snapshot.get("lane", 1)),
				slot_text,
			])

	if not found_jax:
		debug_overlay.present_jax_debug(&"INCAPACITATED", "NONE", 1, "NONE")
	debug_overlay.present_enemy_debug(enemy_lines)
	debug_overlay.present_combat_lab(
		combat_lab_controller.get_elapsed_seconds(),
		combat_director.get_live_count(ActorController.Team.ENEMY),
		reward_director.get_active_cluster_count(),
		reward_director.get_coin_total(),
		reward_director.get_active_streak_count()
	)


func _actor_display_name(actor: ActorController) -> String:
	if actor == null or not is_instance_valid(actor):
		return "NONE"
	return "%s #%02d" % [
		actor.actor_definition.display_name,
		maxi(actor.registration_order, 0),
	]


func _snapshot_display_name(snapshot: Dictionary) -> String:
	return "%s #%02d" % [
		str(snapshot.get("display_name", "Actor")),
		maxi(int(snapshot.get("registration_order", 0)), 0),
	]


func _is_audio_unlock_gesture(event: InputEvent) -> bool:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null:
		return mouse_event.pressed
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null:
		return touch_event.pressed
	var key_event: InputEventKey = event as InputEventKey
	return key_event != null and key_event.pressed and not key_event.echo
