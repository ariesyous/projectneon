class_name GameRun
extends Node

## Run-scoped composition root. It wires Milestone 1 authorities to replaceable
## stage, HUD, debug, and feedback presentation without owning gameplay state.

@onready var downtown_loop: DowntownLoop = $DowntownLoop
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var game_hud: GameHUD = $GameHUD
@onready var combat_director: CombatDirector = $CombatDirector
@onready var reward_director: RewardDirector = $RewardDirector
@onready var combat_lab_controller: CombatLabController = $CombatLabController
@onready var combat_feedback: CombatFeedback = $DowntownLoop/EffectsContainer/CombatFeedback

var _last_coin_status: String = "AUTO = FULL VALUE"


func _ready() -> void:
	debug_overlay.lane_visibility_requested.connect(_on_lane_visibility_requested)
	debug_overlay.set_lane_visibility(downtown_loop.are_debug_lanes_visible())
	combat_director.actor_registered.connect(_on_actor_registered)
	combat_director.actor_died.connect(_on_actor_died)
	combat_director.hit_landed.connect(_on_hit_landed)
	combat_director.crew_status_changed.connect(_on_crew_status_changed)
	reward_director.coins_changed.connect(_on_coins_changed)
	reward_director.streak_changed.connect(_on_streak_changed)
	reward_director.cluster_resolved.connect(_on_cluster_resolved)
	combat_lab_controller.lab_status_changed.connect(_on_lab_status_changed)
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
	_refresh_combat_presentation()


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
