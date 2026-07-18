@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EPSILON: float = 0.0001
const HYDRANT_TUNING: FireHydrantTuning = preload(
	"res://data/interventions/milestone_2_fire_hydrant_tuning.tres"
)
const JAX_DEFINITION: ActorDefinition = preload("res://data/crew/jax.tres")
const STREET_PUNK_DEFINITION: ActorDefinition = preload("res://data/enemies/street_punk.tres")
const JAX_ATTACK: AttackDefinition = preload("res://data/attacks/jax_basic_punch.tres")
const STREET_PUNK_ATTACK: AttackDefinition = preload(
	"res://data/attacks/street_punk_basic_punch.tres"
)
const JAX_SCENE: PackedScene = preload("res://scenes/actors/jax.tscn")
const STREET_PUNK_SCENE: PackedScene = preload("res://scenes/actors/street_punk.tscn")
const COIN_CLUSTER_SCENE: PackedScene = preload("res://scenes/interactables/coin_cluster.tscn")
const FIRE_HYDRANT_SCENE: PackedScene = preload("res://scenes/interactables/fire_hydrant.tscn")
const GAME_HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const HYDRANT_ORIGIN: Vector2 = Vector2(410.0, 239.0)

var _combat_space: CombatSpaceDefinition = CombatSpaceDefinition.new()


class HydrantSignalCapture:
	extends RefCounted

	var states: Array[Dictionary] = []
	var resolved_count: int = 0
	var last_affected_count: int = -1
	var rejection_reasons: Array[int] = []
	var reentrant_controller: FireHydrantController
	var reentrant_result: bool = true

	func on_state_changed(state: int, remaining: float, duration: float) -> void:
		states.append({"state": state, "remaining": remaining, "duration": duration})

	func on_activation_resolved(
		_world_origin: Vector2,
		_range_radius: float,
		affected_count: int
	) -> void:
		resolved_count += 1
		last_affected_count = affected_count
		if reentrant_controller != null:
			reentrant_result = reentrant_controller.request_activation()

	func on_activation_rejected(reason: int) -> void:
		rejection_reasons.append(reason)


class EnvironmentalHitCapture:
	extends RefCounted

	var source_ids: Array[StringName] = []
	var target_orders: Array[int] = []
	var damages: Array[int] = []

	func on_environmental_hit(
		source_id: StringName,
		target: ActorController,
		damage: int,
		_world_position: Vector2,
		_knockback_force: float
	) -> void:
		source_ids.append(source_id)
		target_orders.append(target.registration_order)
		damages.append(damage)


func suite_name() -> String:
	return "milestone_2_intervention"


func test_registration_reservation_knockback_and_recovery_stay_in_safe_region() -> void:
	var director: CombatDirector = _new_director()
	var jax: ActorController = _new_actor(true, -200.0, 1)
	var enemy: ActorController = _new_actor(false, 900.0, 2)
	director.register_actor(jax)
	director.register_actor(enemy)

	_expect_equal(jax.global_position.x, _combat_space.minimum_x(), "bounds: crew spawn clamps left")
	_expect_equal(enemy.global_position.x, _combat_space.maximum_x(), "bounds: enemy spawn clamps right")
	_expect_true(jax.assign_target(enemy), "bounds: target assignment succeeds")
	_expect_true(director.reserve_attack_position(jax, enemy), "bounds: reservation succeeds")
	_expect_true(
		_combat_space.contains_actor_position(director.get_attack_position(jax)),
		"bounds: target-relative reservation stays safe"
	)

	jax.apply_knockback(-1.0, 300.0, 0.30)
	jax.step_simulation(0.30)
	_expect_true(
		_combat_space.contains_actor_position(jax.global_position),
		"bounds: outward knockback remains safe"
	)
	_expect_equal(jax.global_position.x, _combat_space.minimum_x(), "bounds: knockback clamps inclusive edge")
	_expect_equal(
		jax.state_machine.current_state,
		ActorStateMachine.State.APPROACHING_TARGET,
		"bounds: recovery resumes ordinary combat inside region"
	)


func test_circle_query_is_inclusive_stable_and_excludes_invalid_actors() -> void:
	var director: CombatDirector = _new_director()
	var exact_boundary: ActorController = _new_actor(false, 432.0, 1)
	var just_outside: ActorController = _new_actor(false, 432.01, 1)
	var dead_enemy: ActorController = _new_actor(false, 350.0, 1)
	var queued_enemy: ActorController = _new_actor(false, 360.0, 1)
	var freed_enemy: ActorController = _new_actor(false, 370.0, 1)
	var crew: ActorController = _new_actor(true, 350.0, 1)
	director.register_actor(just_outside)
	director.register_actor(exact_boundary)
	director.register_actor(dead_enemy)
	director.register_actor(queued_enemy)
	director.register_actor(freed_enemy)
	director.register_actor(crew)
	dead_enemy.state_machine.force_initial_state(ActorStateMachine.State.DEAD)
	queued_enemy.queue_free()
	freed_enemy.free()

	var targets: Array[ActorController] = director.get_live_targets_in_circle(
		ActorController.Team.ENEMY,
		Vector2(320.0, _combat_space.lane_y(1)),
		112.0
	)
	_expect_equal(
		targets,
		[exact_boundary],
		"circle: exact edge included; dead, queued, freed, outside, and crew excluded"
	)
	queued_enemy.free()
	director.clear_all(false)


func test_available_activation_applies_damage_strong_knockback_and_one_cooldown() -> void:
	var director: CombatDirector = _new_director()
	var jax: ActorController = _new_actor(true, 350.0, 1)
	var in_range: ActorController = _new_actor(false, 400.0, 1)
	var out_of_range: ActorController = _new_actor(false, 280.0, 1)
	director.register_actor(jax)
	director.register_actor(in_range)
	director.register_actor(out_of_range)
	in_range.assign_target(jax)
	_expect_true(director.reserve_attack_position(in_range, jax), "hydrant: enemy reserves before blast")
	in_range.attack_controller.start_attack(in_range.attack_definition)
	in_range.state_machine.transition_to(ActorStateMachine.State.ATTACK_WINDUP)

	var hydrant_capture: HydrantSignalCapture = HydrantSignalCapture.new()
	var hit_capture: EnvironmentalHitCapture = EnvironmentalHitCapture.new()
	var hydrant: FireHydrantController = _new_hydrant(director, hydrant_capture)
	director.environmental_hit_landed.connect(hit_capture.on_environmental_hit)
	var starting_x: float = in_range.global_position.x

	_expect_equal(hydrant.get_state(), FireHydrantController.State.READY, "hydrant: valid enemy makes it ready")
	_expect_true(hydrant.request_activation(), "hydrant: ready activation succeeds")
	_expect_equal(in_range.health_component.current_health, 40, "hydrant: deterministic 18 damage")
	_expect_equal(out_of_range.health_component.current_health, 58, "hydrant: out-of-range enemy untouched")
	_expect_equal(
		in_range.state_machine.current_state,
		ActorStateMachine.State.KNOCKED_BACK,
		"hydrant: strong knockback interrupts enemy"
	)
	_expect_false(in_range.attack_controller.is_attacking(), "hydrant: active attack is cancelled")
	_expect_false(director.has_attack_position(in_range), "hydrant: knockback releases reservation")
	in_range.step_simulation(0.10)
	_expect_true(in_range.global_position.x < starting_x - 20.0, "hydrant: displacement is strongly readable")
	_expect_equal(hydrant_capture.resolved_count, 1, "hydrant: one activation resolution")
	_expect_equal(hydrant_capture.last_affected_count, 1, "hydrant: one valid target affected")
	_expect_equal(hit_capture.source_ids, [&"fire_hydrant"], "hydrant: typed environmental source")
	_expect_equal(hit_capture.damages, [18], "hydrant: resolved damage signal is exact")
	_expect_equal(hydrant.get_state(), FireHydrantController.State.COOLING_DOWN, "hydrant: cooldown starts")
	_expect_approx(hydrant.get_cooldown_remaining(), 8.0, "hydrant: full authored cooldown")


func test_same_tick_and_reentrant_activation_cannot_duplicate() -> void:
	var director: CombatDirector = _new_director()
	var enemy: ActorController = _new_actor(false, 400.0, 1)
	director.register_actor(enemy)
	var capture: HydrantSignalCapture = HydrantSignalCapture.new()
	var hydrant: FireHydrantController = _new_hydrant(director, capture)
	capture.reentrant_controller = hydrant

	_expect_true(hydrant.request_activation(), "dedupe: first request succeeds")
	_expect_false(capture.reentrant_result, "dedupe: callback request is rejected")
	_expect_false(hydrant.request_activation(), "dedupe: same-tick second request is rejected")
	_expect_equal(enemy.health_component.current_health, 40, "dedupe: damage applies once")
	_expect_equal(capture.resolved_count, 1, "dedupe: resolution emits once")
	_expect_equal(
		capture.rejection_reasons,
		[FireHydrantController.RejectionReason.UNAVAILABLE],
		"dedupe: sequential unavailable request gives one rejection"
	)


func test_authored_hydrant_blast_moves_targets_on_both_sides_left() -> void:
	var director: CombatDirector = _new_director()
	var left_target: ActorController = _new_actor(false, 400.0, 1)
	var right_spawn_target: ActorController = _new_actor(false, _combat_space.maximum_x(), 1)
	director.register_actor(left_target)
	director.register_actor(right_spawn_target)
	var hydrant: FireHydrantController = _new_hydrant(director)
	var left_start_x: float = left_target.global_position.x
	var right_start_x: float = right_spawn_target.global_position.x

	_expect_true(hydrant.request_activation(), "direction: activation succeeds")
	left_target.step_simulation(0.10)
	right_spawn_target.step_simulation(0.10)
	_expect_true(
		left_target.global_position.x < left_start_x - 20.0,
		"direction: target left of hydrant moves strongly left"
	)
	_expect_true(
		right_spawn_target.global_position.x < right_start_x - 20.0,
		"direction: target at right spawn moves strongly left instead of clamping"
	)


func test_ready_state_reemits_when_valid_target_count_changes() -> void:
	var director: CombatDirector = _new_director()
	var first_enemy: ActorController = _new_actor(false, 400.0, 1)
	director.register_actor(first_enemy)
	var capture: HydrantSignalCapture = HydrantSignalCapture.new()
	var hydrant: FireHydrantController = _new_hydrant(director, capture)
	var initial_event_count: int = capture.states.size()
	var second_enemy: ActorController = _new_actor(false, 420.0, 2)
	director.register_actor(second_enemy)

	hydrant.step_cooldown(0.0)
	_expect_equal(
		capture.states.size(),
		initial_event_count + 1,
		"state: READY re-emits when in-range target count changes"
	)
	_expect_equal(
		int(capture.states.back().get("state", -1)),
		FireHydrantController.State.READY,
		"state: availability remains READY after count change"
	)
	_expect_equal(hydrant.get_valid_target_count(), 2, "state: authoritative count reflects both targets")
	hydrant.step_cooldown(0.0)
	_expect_equal(
		capture.states.size(),
		initial_event_count + 1,
		"state: unchanged count does not emit redundant state"
	)


func test_no_target_rejection_does_not_consume_cooldown() -> void:
	var director: CombatDirector = _new_director()
	var dead_enemy: ActorController = _new_actor(false, 400.0, 1)
	director.register_actor(dead_enemy)
	dead_enemy.state_machine.force_initial_state(ActorStateMachine.State.DEAD)
	var capture: HydrantSignalCapture = HydrantSignalCapture.new()
	var hydrant: FireHydrantController = _new_hydrant(director, capture)

	_expect_equal(hydrant.get_state(), FireHydrantController.State.NO_TARGET, "rejection: no live target state")
	_expect_false(hydrant.request_activation(), "rejection: no-target request fails")
	_expect_approx(hydrant.get_cooldown_remaining(), 0.0, "rejection: cooldown is not consumed")
	_expect_equal(capture.resolved_count, 0, "rejection: no activation feedback")
	_expect_equal(
		capture.rejection_reasons,
		[FireHydrantController.RejectionReason.NO_VALID_TARGET],
		"rejection: precise reason is reported"
	)


func test_cooldown_progresses_completes_and_allows_reactivation() -> void:
	var director: CombatDirector = _new_director()
	var enemy: ActorController = _new_actor(false, 400.0, 1)
	director.register_actor(enemy)
	var hydrant: FireHydrantController = _new_hydrant(director)

	_expect_true(hydrant.request_activation(), "cooldown: first activation succeeds")
	hydrant.step_cooldown(7.999)
	_expect_equal(hydrant.get_state(), FireHydrantController.State.COOLING_DOWN, "cooldown: remains unavailable before edge")
	_expect_true(hydrant.get_cooldown_remaining() > 0.0, "cooldown: positive remainder before edge")
	hydrant.step_cooldown(0.002)
	_expect_approx(hydrant.get_cooldown_remaining(), 0.0, "cooldown: clamps at zero after edge")
	_expect_equal(hydrant.get_state(), FireHydrantController.State.READY, "cooldown: valid target restores ready")
	_expect_true(hydrant.request_activation(), "cooldown: reactivation succeeds")
	_expect_equal(enemy.health_component.current_health, 22, "cooldown: second valid use applies once")


func test_multi_target_resolution_is_stable_and_excludes_dead_unregistered_and_crew() -> void:
	var director: CombatDirector = _new_director()
	var first: ActorController = _new_actor(false, 390.0, 0)
	var second: ActorController = _new_actor(false, 420.0, 2)
	var dead_enemy: ActorController = _new_actor(false, 430.0, 1)
	var unregistered: ActorController = _new_actor(false, 410.0, 1)
	var crew: ActorController = _new_actor(true, 410.0, 1)
	director.register_actor(second)
	director.register_actor(dead_enemy)
	director.register_actor(first)
	director.register_actor(crew)
	dead_enemy.state_machine.force_initial_state(ActorStateMachine.State.DEAD)
	var hit_capture: EnvironmentalHitCapture = EnvironmentalHitCapture.new()
	director.environmental_hit_landed.connect(hit_capture.on_environmental_hit)
	var hydrant: FireHydrantController = _new_hydrant(director)

	_expect_true(hydrant.request_activation(), "multi: activation succeeds")
	_expect_equal(second.health_component.current_health, 40, "multi: first registered live enemy damaged")
	_expect_equal(first.health_component.current_health, 40, "multi: second live enemy damaged")
	_expect_equal(dead_enemy.health_component.current_health, 58, "multi: dead enemy excluded")
	_expect_equal(unregistered.health_component.current_health, 58, "multi: unregistered enemy excluded")
	_expect_equal(crew.health_component.current_health, 520, "multi: crew excluded")
	_expect_equal(hit_capture.target_orders, [second.registration_order, first.registration_order], "multi: stable registration order")


func test_coin_presentation_positions_avoid_hydrant_interaction_footprint() -> void:
	var director: CombatDirector = _new_director()
	var reward_director: RewardDirector = track(RewardDirector.new()) as RewardDirector
	reward_director._ready()
	var lab: CombatLabController = track(CombatLabController.new()) as CombatLabController
	lab.configure(director, reward_director, null, null, null, null, null)
	lab.configure_coin_interaction_exclusion(HYDRANT_ORIGIN, 76.0)

	var defeat_positions: Array[Vector2] = [
		Vector2(360.0, 194.0),
		Vector2(390.0, 226.0),
		Vector2(430.0, 226.0),
		Vector2(476.0, 258.0),
	]
	for defeat_position: Vector2 in defeat_positions:
		var coin_position: Vector2 = lab.calculate_coin_presentation_position(defeat_position)
		_expect_true(_combat_space.contains_actor_position(coin_position), "coin: presentation stays safe")
		_expect_true(
			coin_position.distance_to(HYDRANT_ORIGIN) + EPSILON >= 76.0,
			"coin: generous targets cannot overlap hydrant input"
		)


func test_coin_and_hydrant_authorities_resolve_independently_at_most_once() -> void:
	var director: CombatDirector = _new_director()
	var enemy: ActorController = _new_actor(false, 400.0, 1)
	director.register_actor(enemy)
	var hydrant: FireHydrantController = _new_hydrant(director)
	var reward_director: RewardDirector = track(RewardDirector.new()) as RewardDirector
	reward_director._ready()
	_expect_true(reward_director.register_coin_cluster(77, 40, 0), "interaction: coin award registers")

	_expect_true(hydrant.request_activation(), "interaction: hydrant request succeeds")
	_expect_true(reward_director.request_manual_collection(77, 0), "interaction: coin request succeeds")
	_expect_false(hydrant.request_activation(), "interaction: hydrant cannot duplicate")
	_expect_false(reward_director.request_manual_collection(77, 0), "interaction: coin cannot duplicate")
	_expect_equal(enemy.health_component.current_health, 40, "interaction: hydrant damage credited once")
	_expect_equal(reward_director.get_coin_total(), 41, "interaction: coin base and first manual bonus credited once")


func test_world_preview_and_hud_reflect_the_same_authoritative_tuning_and_state() -> void:
	var director: CombatDirector = _new_director()
	var enemy: ActorController = _new_actor(false, 400.0, 1)
	director.register_actor(enemy)
	var hydrant_controller: FireHydrantController = _new_hydrant(director)
	var world_hydrant: FireHydrant = track(FireHydrant.new()) as FireHydrant
	world_hydrant.tuning = hydrant_controller.tuning
	var hud: GameHUD = track(GameHUD.new()) as GameHUD

	_expect_equal(
		world_hydrant.tuning,
		hydrant_controller.tuning,
		"presentation: world preview and authority load one tuning Resource"
	)
	_expect_approx(
		world_hydrant.get_preview_radius(),
		hydrant_controller.get_range_radius(),
		"presentation: preview circle exactly matches authoritative circle"
	)
	var ready_snapshot: Dictionary = hydrant_controller.get_snapshot()
	hud.present_hydrant_state(
		int(ready_snapshot.get("state", -1)),
		float(ready_snapshot.get("cooldown_remaining", -1.0)),
		float(ready_snapshot.get("cooldown_duration", -1.0)),
		1,
		"READY"
	)
	_expect_equal(hud._hydrant_state, FireHydrantController.State.READY, "presentation: HUD reflects ready authority")
	_expect_approx(hud._hydrant_cooldown_remaining, 0.0, "presentation: HUD reflects zero cooldown")

	_expect_true(hydrant_controller.request_activation(), "presentation: activation starts cooldown")
	var cooldown_snapshot: Dictionary = hydrant_controller.get_snapshot()
	hud.present_hydrant_state(
		int(cooldown_snapshot.get("state", -1)),
		float(cooldown_snapshot.get("cooldown_remaining", -1.0)),
		float(cooldown_snapshot.get("cooldown_duration", -1.0)),
		1,
		"COOLING"
	)
	_expect_equal(
		hud._hydrant_state,
		FireHydrantController.State.COOLING_DOWN,
		"presentation: HUD reflects cooling authority"
	)
	_expect_approx(hud._hydrant_cooldown_remaining, 8.0, "presentation: HUD reflects authoritative remaining time")


## Editor test suites run non-@tool production PackedScenes as placeholders, so
## this runtime-only probe is intentionally not auto-discovered. The equivalent
## authority lifecycle remains covered below and the real scene is soak-tested.
func _runtime_only_production_combat_lab_replaces_defeated_enemies_without_stale_state() -> void:
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	_expect_true(scene_tree != null, "lab lifecycle: an editor SceneTree is available")
	if scene_tree == null:
		return

	var host: Node2D = track(Node2D.new()) as Node2D
	host.name = "Milestone2CombatLabTestHost"
	host.process_mode = Node.PROCESS_MODE_DISABLED
	var director: CombatDirector = CombatDirector.new()
	director.combat_space = _combat_space
	var reward_director: RewardDirector = RewardDirector.new()
	var lab: CombatLabController = CombatLabController.new()
	lab.jax_scene = JAX_SCENE
	lab.street_punk_scene = STREET_PUNK_SCENE
	lab.coin_cluster_scene = COIN_CLUSTER_SCENE
	var crew_container: Node2D = Node2D.new()
	var enemy_container: Node2D = Node2D.new()
	var loot_container: Node2D = Node2D.new()
	var left_spawn: Marker2D = Marker2D.new()
	var right_spawn: Marker2D = Marker2D.new()
	left_spawn.position = Vector2(_combat_space.minimum_x(), _combat_space.lane_y(1))
	right_spawn.position = Vector2(_combat_space.maximum_x(), _combat_space.lane_y(1))
	host.add_child(director)
	host.add_child(reward_director)
	host.add_child(lab)
	host.add_child(crew_container)
	host.add_child(enemy_container)
	host.add_child(loot_container)
	host.add_child(left_spawn)
	host.add_child(right_spawn)
	scene_tree.root.add_child(host)
	director.set_physics_process(false)
	lab.set_process(false)
	lab.configure(
		director,
		reward_director,
		crew_container,
		enemy_container,
		loot_container,
		left_spawn,
		right_spawn
	)

	_expect_true(lab.start_lab(), "lab lifecycle: production scenes start one-versus-five")
	_expect_equal(director.get_live_count(ActorController.Team.CREW), 1, "lab lifecycle: Jax starts live")
	_expect_equal(director.get_live_count(ActorController.Team.ENEMY), 5, "lab lifecycle: five enemies start live")
	_expect_equal(director.get_registered_count(), 6, "lab lifecycle: initial registry has six actors")
	_expect_equal(lab.get_total_spawned(), 5, "lab lifecycle: initial spawn accounting")

	for cycle: int in range(3):
		var crew: Array[ActorController] = director.get_live_actors(ActorController.Team.CREW)
		var enemies: Array[ActorController] = director.get_live_actors(ActorController.Team.ENEMY)
		_expect_equal(crew.size(), 1, "lab lifecycle: cycle %d keeps one Jax" % cycle)
		_expect_equal(enemies.size(), 5, "lab lifecycle: cycle %d starts with five enemies" % cycle)
		if crew.is_empty() or enemies.is_empty():
			return
		var jax: ActorController = crew[0]
		var victim: ActorController = enemies[0]
		var rewardless_definition: ActorDefinition = victim.actor_definition.duplicate(true) as ActorDefinition
		_expect_true(rewardless_definition != null, "lab lifecycle: rewardless test definition duplicates")
		if rewardless_definition == null:
			return
		rewardless_definition.grants_coin_reward = false
		rewardless_definition.authored_coin_value = 0
		victim.actor_definition = rewardless_definition
		_expect_true(jax.assign_target(victim), "lab lifecycle: cycle %d target assigns" % cycle)
		_expect_true(director.reserve_attack_position(jax, victim), "lab lifecycle: cycle %d reserves" % cycle)
		_expect_true(victim.receive_damage(9999) > 0, "lab lifecycle: cycle %d defeat resolves" % cycle)
		_expect_equal(director.get_live_count(ActorController.Team.ENEMY), 4, "lab lifecycle: death unregisters immediately")
		_expect_equal(director.get_registered_count(), 5, "lab lifecycle: registry drops defeated actor")
		_expect_equal(jax.current_target, null, "lab lifecycle: stale target clears immediately")
		_expect_equal(director.get_reservation_snapshot().size(), 0, "lab lifecycle: stale reservation clears")
		_expect_equal(lab.get_total_defeated(), cycle + 1, "lab lifecycle: defeat accounts once")
		victim.step_simulation(1.0)
		_expect_true(victim.is_queued_for_deletion(), "lab lifecycle: authored cleanup queues defeated actor")
		victim.free()
		lab.step_lab(0.76)
		_expect_equal(director.get_live_count(ActorController.Team.ENEMY), 5, "lab lifecycle: replacement restores five")
		_expect_equal(director.get_registered_count(), 6, "lab lifecycle: replacement restores registry")
		_expect_equal(lab.get_total_spawned(), 6 + cycle, "lab lifecycle: replacement accounts once")
		_expect_equal(enemy_container.get_child_count(), 5, "lab lifecycle: no stale enemy child remains")
		for live_enemy: ActorController in director.get_live_actors(ActorController.Team.ENEMY):
			_expect_true(
				_combat_space.contains_actor_position(live_enemy.global_position),
				"lab lifecycle: replacement actor origin remains combat-safe"
			)

	lab.stop_lab()


func test_repeated_boundary_lifecycle_leaves_no_stale_target_or_reservation() -> void:
	var director: CombatDirector = _new_director()
	var jax: ActorController = _new_actor(true, _combat_space.minimum_x(), 1)
	director.register_actor(jax)
	for cycle: int in range(30):
		var enemy: ActorController = _new_actor(false, 900.0, cycle % 3)
		director.register_actor(enemy)
		_expect_true(_combat_space.contains_actor_position(enemy.global_position), "lifecycle: spawn %d clamps" % cycle)
		_expect_true(jax.assign_target(enemy), "lifecycle: target %d assigns" % cycle)
		_expect_true(director.reserve_attack_position(jax, enemy), "lifecycle: slot %d reserves" % cycle)
		_expect_true(
			_combat_space.contains_actor_position(director.get_attack_position(jax)),
			"lifecycle: slot %d remains safe" % cycle
		)
		enemy.apply_knockback(1.0, 300.0, 0.30)
		enemy.step_simulation(0.30)
		_expect_true(_combat_space.contains_actor_position(enemy.global_position), "lifecycle: knockback %d clamps" % cycle)
		enemy.state_machine.force_initial_state(ActorStateMachine.State.DEAD)
		_expect_true(director.unregister_actor(enemy, false), "lifecycle: enemy %d unregisters" % cycle)
		_expect_equal(jax.current_target, null, "lifecycle: target %d clears" % cycle)
		_expect_equal(director.get_reservation_snapshot().size(), 0, "lifecycle: slot %d clears" % cycle)
	_expect_equal(director.get_registered_count(), 1, "lifecycle: only Jax remains")


func _new_director() -> CombatDirector:
	var director: CombatDirector = track(CombatDirector.new()) as CombatDirector
	director.combat_space = _combat_space
	director._ready()
	director.set_physics_process(false)
	return director


func _new_hydrant(
	director: CombatDirector,
	capture: HydrantSignalCapture = null
) -> FireHydrantController:
	var hydrant: FireHydrantController = track(FireHydrantController.new()) as FireHydrantController
	hydrant.tuning = HYDRANT_TUNING
	hydrant.set_process(false)
	if capture != null:
		hydrant.state_changed.connect(capture.on_state_changed)
		hydrant.activation_resolved.connect(capture.on_activation_resolved)
		hydrant.activation_rejected.connect(capture.on_activation_rejected)
	hydrant.configure(director, HYDRANT_ORIGIN)
	return hydrant


func _new_actor(is_crew: bool, world_x: float, lane: int) -> ActorController:
	var actor: ActorController = track(ActorController.new()) as ActorController
	actor.actor_definition = JAX_DEFINITION if is_crew else STREET_PUNK_DEFINITION
	actor.attack_definition = JAX_ATTACK if is_crew else STREET_PUNK_ATTACK
	actor.team = ActorController.Team.CREW if is_crew else ActorController.Team.ENEMY
	actor.initial_lane = lane
	actor.lane_index = lane
	actor.configure_combat_space(_combat_space)
	actor.position = Vector2(world_x, _combat_space.lane_y(lane))
	actor.state_machine = ActorStateMachine.new()
	actor.health_component = HealthComponent.new()
	actor.attack_controller = AttackController.new()
	actor.attack_hitbox = Area2D.new()
	actor.actor_visual = ActorVisual.new()
	actor.add_child(actor.state_machine)
	actor.add_child(actor.health_component)
	actor.add_child(actor.attack_controller)
	actor.add_child(actor.attack_hitbox)
	actor.add_child(actor.actor_visual)
	actor.initialize_runtime()
	return actor


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, context)


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(
		absf(actual - expected) <= EPSILON,
		"%s (expected %.6f, got %.6f)" % [context, expected, actual]
	)
