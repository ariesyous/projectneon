class_name GameRun
extends Node

## Run-scoped composition root. It wires typed authorities and presentation,
## forwards intent, and contains no duplicated run/combat/reward calculations.

const HYDRANT_COIN_EXCLUSION_RADIUS: float = 76.0

@onready var run_director: RunDirector = $RunDirector
@onready var patrol_controller: PatrolController = $PatrolController
@onready var combat_director: CombatDirector = $CombatDirector
@onready var reward_director: RewardDirector = $RewardDirector
@onready var fire_hydrant_controller: FireHydrantController = $FireHydrantController
@onready var cooling_controller: RunCoolingController = $RunCoolingController
@onready var encounter_controller: RunEncounterController = $RunEncounterController
@onready var run_flow_controller: RunFlowController = $RunFlowController
@onready var synergy_system: SynergySystem = $SynergySystem
@onready var display_controller: DisplayController = $DisplayController
@onready var downtown_loop: DowntownLoop = $DowntownLoop
@onready var game_hud: GameHUD = $GameHUD
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var fire_hydrant: FireHydrant = $DowntownLoop/Interactables/FireHydrant
@onready var combat_feedback: CombatFeedback = $DowntownLoop/EffectsContainer/CombatFeedback

var _last_coin_status: String = "AUTO = FULL VALUE"
var _hydrant_feedback_override: String = ""
var _hydrant_feedback_remaining: float = 0.0
var _web_audio_unlocked: bool = false


func _ready() -> void:
	debug_overlay.lane_visibility_requested.connect(_on_lane_visibility_requested)
	debug_overlay.add_heat_requested.connect(run_flow_controller.force_add_heat)
	debug_overlay.advance_pressure_requested.connect(
		run_flow_controller.force_advance_pressure_to_next_threshold
	)
	debug_overlay.force_defeat_requested.connect(run_flow_controller.force_defeat)
	debug_overlay.restart_same_seed_requested.connect(run_flow_controller.restart_same_seed)
	debug_overlay.set_lane_visibility(downtown_loop.are_debug_lanes_visible())

	combat_director.actor_registered.connect(_on_actor_registered)
	combat_director.actor_died.connect(_on_actor_died)
	combat_director.hit_landed.connect(_on_hit_landed)
	combat_director.environmental_hit_landed.connect(_on_environmental_hit_landed)
	combat_director.crew_status_changed.connect(_on_crew_status_changed)
	reward_director.coins_changed.connect(_on_coins_changed)
	reward_director.scrap_changed.connect(_on_scrap_changed)
	reward_director.streak_changed.connect(_on_streak_changed)
	reward_director.cluster_resolved.connect(_on_cluster_resolved)
	reward_director.equipment_choice_resolved.connect(_on_equipment_choice_resolved)
	run_director.run_summary_ready.connect(game_hud.present_run_summary)
	synergy_system.build_changed.connect(_on_build_changed)
	synergy_system.synergy_activated.connect(_on_synergy_activated)
	synergy_system.synergy_deactivated.connect(_on_synergy_deactivated)

	fire_hydrant_controller.state_changed.connect(_on_hydrant_state_changed)
	fire_hydrant_controller.activation_resolved.connect(_on_hydrant_activation_resolved)
	fire_hydrant_controller.activation_rejected.connect(_on_hydrant_activation_rejected)
	fire_hydrant.activation_requested.connect(_request_hydrant_activation)

	game_hud.hydrant_activation_requested.connect(_request_hydrant_activation)
	game_hud.hydrant_preview_requested.connect(fire_hydrant.set_external_preview_visible)
	game_hud.fullscreen_requested.connect(display_controller.toggle_fullscreen)
	game_hud.primary_action_requested.connect(_on_primary_action_requested)
	game_hud.extraction_requested.connect(run_flow_controller.confirm_extraction)
	game_hud.subway_reroute_requested.connect(run_flow_controller.request_subway_reroute)
	game_hud.shop_cooling_requested.connect(run_flow_controller.request_shop_cooling)
	game_hud.restart_same_seed_requested.connect(run_flow_controller.restart_same_seed)
	game_hud.restart_new_seed_requested.connect(run_flow_controller.restart_new_seed)
	game_hud.equipment_acquisition_requested.connect(_on_equipment_acquisition_requested)
	game_hud.equipment_reward_decline_requested.connect(_on_equipment_reward_decline_requested)
	game_hud.inventory_swap_requested.connect(_on_inventory_swap_requested)
	game_hud.inventory_move_requested.connect(_on_inventory_move_requested)
	game_hud.inventory_discard_requested.connect(_on_inventory_discard_requested)
	display_controller.fullscreen_changed.connect(game_hud.present_fullscreen_state)
	display_controller.landscape_state_changed.connect(game_hud.present_landscape_state)
	display_controller.safe_area_changed.connect(game_hud.apply_safe_area)

	fire_hydrant_controller.configure(combat_director, fire_hydrant.global_position)
	combat_director.configure_build_system(synergy_system, run_director.get_random_streams())
	cooling_controller.configure(run_director, reward_director, patrol_controller)
	encounter_controller.configure_coin_interaction_exclusion(
		fire_hydrant.global_position,
		HYDRANT_COIN_EXCLUSION_RADIUS
	)
	encounter_controller.configure(
		run_director,
		combat_director,
		reward_director,
		$DowntownLoop/CrewContainer,
		$DowntownLoop/EnemyContainer,
		$DowntownLoop/LootContainer,
		$DowntownLoop/SpawnPoints/LeftSpawn,
		$DowntownLoop/SpawnPoints/RightSpawn
	)
	run_flow_controller.configure(
		run_director,
		patrol_controller,
		encounter_controller,
		reward_director,
		cooling_controller,
		combat_director,
		fire_hydrant_controller,
		synergy_system
	)
	run_flow_controller.flow_status_changed.connect(_on_flow_status_changed)
	run_flow_controller.action_feedback.connect(_on_action_feedback)
	run_flow_controller.equipment_reward_ready.connect(_on_equipment_reward_ready)

	_web_audio_unlocked = not OS.has_feature("web")
	game_hud.present_audio_unlock_required(not _web_audio_unlocked)
	display_controller.refresh_state(true)
	_refresh_hydrant_presentation()
	_on_build_changed(synergy_system.get_snapshot())
	run_flow_controller.start_initial_run()
	_refresh_combat_presentation()


func _process(delta: float) -> void:
	if _hydrant_feedback_remaining <= 0.0:
		return
	_hydrant_feedback_remaining = maxf(0.0, _hydrant_feedback_remaining - maxf(delta, 0.0))
	if _hydrant_feedback_remaining <= 0.0:
		_hydrant_feedback_override = ""
		_refresh_hydrant_presentation()


func _input(event: InputEvent) -> void:
	if not _web_audio_unlocked and OS.has_feature("web") and _is_audio_unlock_gesture(event):
		_web_audio_unlocked = true
		combat_feedback.prime_audio()
		game_hud.present_audio_unlocked()

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_SPACE:
		run_director.toggle_pause()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_E and run_director.current_state == RunDirector.RunState.EXTRACTION_AVAILABLE:
		run_flow_controller.confirm_extraction()
		get_viewport().set_input_as_handled()


func _on_primary_action_requested() -> void:
	match run_director.current_state:
		RunDirector.RunState.REWARD_SELECTION:
			var pending_id: int = int(
			run_flow_controller.get_snapshot().get("pending_reward_encounter_id", -1)
			)
			if reward_director.get_pending_equipment_choices(pending_id).is_empty():
				run_flow_controller.claim_standard_reward()
			else:
				_on_action_feedback("CHOOSE ONE EQUIPMENT REWARD")
		RunDirector.RunState.SHOP:
			run_flow_controller.leave_shop()
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			run_flow_controller.decline_extraction()
		RunDirector.RunState.BOSS_INTRO:
			run_flow_controller.enter_boss_trigger()


func _on_flow_status_changed(snapshot: Dictionary) -> void:
	game_hud.present_flow_snapshot(snapshot)
	debug_overlay.present_run_flow(snapshot)
	_refresh_hydrant_presentation()
	_refresh_combat_presentation()


func _on_action_feedback(message: String) -> void:
	game_hud.present_action_feedback(message)
	_hydrant_feedback_override = message
	_hydrant_feedback_remaining = 1.2


func _on_build_changed(snapshot: Dictionary) -> void:
	game_hud.present_build_snapshot(snapshot)
	var cooldown_multiplier: float = maxf(
		0.05,
		1.0 + synergy_system.get_percent_modifier(&"intervention_cooldown")
	)
	fire_hydrant_controller.set_cooldown_multiplier(cooldown_multiplier)
	_refresh_hydrant_presentation()


func _on_equipment_reward_ready(
	encounter_instance_id: int,
	choices: Array[EquipmentDefinition]
) -> void:
	var previews_by_choice: Array[Dictionary] = []
	for choice_index: int in range(choices.size()):
		var by_slot: Array[Dictionary] = []
		for slot_index: int in range(SynergySystem.SLOT_COUNT):
			by_slot.append(
				reward_director.get_equipment_choice_preview(
					encounter_instance_id,
					choice_index,
					slot_index
				)
			)
		previews_by_choice.append({"by_slot": by_slot})
	game_hud.present_equipment_reward(encounter_instance_id, choices, previews_by_choice)


func _on_equipment_acquisition_requested(
	choice_index: int,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int,
	replace_confirmed: bool,
	expected_revision: int
) -> void:
	var applied: bool = run_flow_controller.claim_equipment_reward_to_inventory(
		choice_index,
		destination,
		equipment_slot,
		backpack_slot,
		replace_confirmed,
		expected_revision
	)
	game_hud.present_equipment_action_result(applied)
	if applied:
		game_hud.dismiss_equipment_reward()
	else:
		_on_action_feedback("EQUIPMENT CHOICE REJECTED")


func _on_equipment_reward_decline_requested() -> void:
	var declined: bool = run_flow_controller.decline_equipment_reward()
	game_hud.present_equipment_action_result(declined)
	if declined:
		game_hud.dismiss_equipment_reward()
		_on_action_feedback("CURRENT BUILD KEPT - RUN REWARD SECURED")


func _on_inventory_swap_requested(
	equipment_slot: int,
	backpack_slot: int,
	expected_revision: int
) -> void:
	if not _inventory_management_allowed():
		game_hud.present_inventory_action_result(false)
		_on_action_feedback("MANAGE EQUIPMENT BETWEEN FIGHTS")
		return
	var stored: EquipmentDefinition = synergy_system.get_backpack_item(backpack_slot)
	var swapped: bool = synergy_system.swap_equipped_with_backpack(
		equipment_slot,
		backpack_slot,
		expected_revision
	)
	game_hud.present_inventory_action_result(swapped)
	if swapped and stored != null:
		_on_action_feedback("EQUIPPED %s FROM BACKPACK" % stored.display_name.to_upper())


func _on_inventory_move_requested(
	equipment_slot: int,
	backpack_slot: int,
	replace_confirmed: bool,
	expected_revision: int
) -> void:
	if not _inventory_management_allowed():
		game_hud.present_inventory_action_result(false)
		_on_action_feedback("MANAGE EQUIPMENT BETWEEN FIGHTS")
		return
	var equipped: EquipmentDefinition = synergy_system.get_equipped_item(equipment_slot)
	var moved: bool = synergy_system.move_equipped_to_backpack(
		equipment_slot,
		backpack_slot,
		replace_confirmed,
		expected_revision
	)
	game_hud.present_inventory_action_result(moved)
	if moved and equipped != null:
		_on_action_feedback("STORED %s IN BACKPACK" % equipped.display_name.to_upper())


func _on_inventory_discard_requested(
	area: StringName,
	slot_index: int,
	equipment_id: StringName,
	expected_revision: int
) -> void:
	if not _inventory_management_allowed():
		game_hud.present_inventory_action_result(false)
		_on_action_feedback("MANAGE EQUIPMENT BETWEEN FIGHTS")
		return
	var item: EquipmentDefinition = synergy_system.get_catalogue_item(equipment_id)
	var discarded: bool = synergy_system.discard_confirmed(
		area,
		slot_index,
		equipment_id,
		expected_revision
	)
	game_hud.present_inventory_action_result(discarded)
	if discarded and item != null:
		_on_action_feedback("DISCARDED %s" % item.display_name.to_upper())


func _on_equipment_choice_resolved(
	_encounter_instance_id: int,
	_choice_index: int,
	equipment: EquipmentDefinition,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int
) -> void:
	if destination == SynergySystem.AREA_BACKPACK:
		_on_action_feedback("STORED %s IN BACKPACK SLOT %d" % [
			equipment.display_name.to_upper(),
			backpack_slot + 1,
		])
	else:
		_on_action_feedback("EQUIPPED %s IN ACTIVE SLOT %d" % [
			equipment.display_name.to_upper(),
			equipment_slot + 1,
		])


func _inventory_management_allowed() -> bool:
	return run_director.current_state in [
		RunDirector.RunState.INTRO,
		RunDirector.RunState.PATROLLING,
		RunDirector.RunState.SHOP,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
	]


func _on_synergy_activated(synergy: SynergyDefinition) -> void:
	_on_action_feedback("%s ACTIVATED" % synergy.display_name.to_upper())


func _on_synergy_deactivated(synergy: SynergyDefinition) -> void:
	_on_action_feedback("%s DEACTIVATED" % synergy.display_name.to_upper())


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
	game_hud.present_jax_status(
		float(current_health),
		float(maximum_health),
		StringName(ActorStateMachine.state_name(state)),
		_actor_display_name(actor.current_target)
	)


func _on_coins_changed(total_coins: int) -> void:
	game_hud.present_coin_status(
		total_coins,
		reward_director.get_active_streak_count(),
		_last_coin_status
	)


func _on_scrap_changed(total_scrap: int) -> void:
	game_hud.present_scrap_total(total_scrap)


func _on_streak_changed(streak_count: int, _expires_at_msec: int) -> void:
	game_hud.present_coin_status(reward_director.get_coin_total(), streak_count, _last_coin_status)
	_refresh_combat_presentation()


func _on_cluster_resolved(
	_cluster_id: int,
	manual: bool,
	base_value: int,
	bonus_value: int,
	resulting_streak: int
) -> void:
	combat_feedback.play_coin(manual, resulting_streak)
	_last_coin_status = (
		"CLICK +%d%s" % [
			base_value + bonus_value,
			" (+%d BONUS)" % bonus_value if bonus_value > 0 else "",
		]
		if manual
		else "AUTO +%d (FULL)" % base_value
	)
	game_hud.present_coin_status(
		reward_director.get_coin_total(),
		reward_director.get_active_streak_count(),
		_last_coin_status
	)
	_refresh_combat_presentation()


func _request_hydrant_activation() -> void:
	if RunDirector.is_eligible_active_state(run_director.current_state):
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
	_hydrant_feedback_remaining = maxf(fire_hydrant_controller.tuning.impact_duration, 0.01)
	_refresh_hydrant_presentation()


func _on_hydrant_activation_rejected(reason: int) -> void:
	fire_hydrant.play_rejection()
	combat_feedback.play_hydrant_rejection()
	_hydrant_feedback_override = (
		"NO VALID ENEMY IN RANGE"
		if reason == FireHydrantController.RejectionReason.NO_VALID_TARGET
		else "HYDRANT IS COOLING DOWN"
	)
	_hydrant_feedback_remaining = maxf(fire_hydrant_controller.tuning.rejection_duration, 0.01)
	_refresh_hydrant_presentation()


func _refresh_hydrant_presentation() -> void:
	if fire_hydrant_controller == null or fire_hydrant == null or game_hud == null:
		return
	var state: int = fire_hydrant_controller.get_state()
	var cooldown_remaining: float = fire_hydrant_controller.get_cooldown_remaining()
	var cooldown_duration: float = fire_hydrant_controller.get_cooldown_duration()
	var valid_enemy_count: int = fire_hydrant_controller.get_valid_target_count()
	var feedback: String = _hydrant_feedback_override
	if feedback.is_empty():
		match state:
			FireHydrantController.State.READY:
				feedback = "READY TO INTERVENE"
			FireHydrantController.State.COOLING_DOWN:
				feedback = "WATER PRESSURE RECOVERING"
			_:
				feedback = "WAIT FOR AN ENEMY IN RANGE"
	fire_hydrant.present_state(state, cooldown_remaining, cooldown_duration, valid_enemy_count)
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
		display_name_by_id[int(snapshot.get("instance_id", -1))] = _snapshot_display_name(snapshot)

	var enemy_lines: PackedStringArray = PackedStringArray()
	var found_jax: bool = false
	for snapshot: Dictionary in snapshots:
		var instance_id: int = int(snapshot.get("instance_id", -1))
		var target_name: String = display_name_by_id.get(
			int(snapshot.get("target_instance_id", -1)),
			"NONE"
		)
		var slot_index: int = reservation_by_attacker.get(instance_id, -1)
		var slot_text: String = str(slot_index) if slot_index >= 0 else "NONE"
		if int(snapshot.get("team", ActorController.Team.ENEMY)) == ActorController.Team.CREW:
			found_jax = true
			var actor_state_name: StringName = StringName(str(snapshot.get("state_name", "UNKNOWN")))
			game_hud.present_jax_status(
				float(snapshot.get("current_health", 0)),
				float(snapshot.get("maximum_health", 1)),
				actor_state_name,
				target_name
			)
			debug_overlay.present_jax_debug(
				actor_state_name,
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


func _actor_display_name(actor: ActorController) -> String:
	if actor == null or not is_instance_valid(actor):
		return "NONE"
	return "%s #%02d" % [actor.actor_definition.display_name, maxi(actor.registration_order, 0)]


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
