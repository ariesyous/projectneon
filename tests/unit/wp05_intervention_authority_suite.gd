@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const POWER_BOX: PowerBoxDefinition = preload("res://data/interventions/wp05_power_box.tres")
const FOCUS: FocusDefinition = preload("res://data/interventions/wp05_focus.tres")
const HYDRANT_TUNING: FireHydrantTuning = preload(
	"res://data/interventions/milestone_2_fire_hydrant_tuning.tres"
)
const RANDOM_SCHEMA: RunRandomSchemaDefinition = preload(
	"res://data/run/milestone_3_random_schema.tres"
)
const JAX: PackedScene = preload("res://scenes/actors/jax.tscn")
const ZOEY: PackedScene = preload("res://scenes/actors/zoey.tscn")
const STREET: PackedScene = preload("res://scenes/actors/street_punk.tscn")
const BAT: PackedScene = preload("res://scenes/actors/bat_thug.tscn")
const BOTTLE: PackedScene = preload("res://scenes/actors/bottle_thrower.tscn")
const ENFORCER: PackedScene = preload("res://scenes/actors/viper_enforcer.tscn")
const VIPER: PackedScene = preload("res://scenes/actors/the_viper.tscn")
const ALLEY: EncounterDefinition = preload("res://data/encounters/alley_scuffle.tres")
const ARCADE: EncounterDefinition = preload("res://data/encounters/arcade_ambush.tres")
const SIGNAL: EncounterDefinition = preload("res://data/encounters/viper_signal.tres")
const SHOWDOWN: EncounterDefinition = preload("res://data/encounters/viper_showdown.tres")


class BackupHarness extends RefCounted:
	var host: Node
	var removed_count: int = 0

	func spawn_ally(_activation_token: int, ally_index: int) -> Node2D:
		var ally: Node2D = Node2D.new()
		ally.name = "WP05Backup%d" % ally_index
		return ally

	func register_ally(ally: Node2D) -> bool:
		host.add_child(ally)
		return true

	func remove_ally(ally: Node2D, _reason: StringName) -> void:
		removed_count += 1
		if ally != null and is_instance_valid(ally) and not ally.is_queued_for_deletion():
			ally.queue_free()


func suite_name() -> String:
	return "wp05_intervention_authority"


func test_selected_resources_encounters_and_readable_intents_are_exact_and_bounded() -> void:
	assert_eq(POWER_BOX.validation_errors(), PackedStringArray(), "definitions: Power Box validates")
	assert_eq(FOCUS.validation_errors(), PackedStringArray(), "definitions: Focus validates")
	assert_eq(POWER_BOX.id, &"power_box", "definitions: stable Power Box id")
	assert_eq(POWER_BOX.range_radius, 96.0, "definitions: Power Box exact radius")
	assert_eq(POWER_BOX.damage, 4, "definitions: Power Box exact low damage")
	assert_eq(POWER_BOX.stun_seconds, 1.0, "definitions: Power Box exact authored stun")
	assert_eq(POWER_BOX.status_id, &"shock", "definitions: Power Box reuses Shock")
	assert_eq(POWER_BOX.status_duration_seconds, 3.0, "definitions: exact base Shock duration")
	assert_eq(POWER_BOX.cooldown_seconds, 12.0, "definitions: exact base cooldown")
	assert_eq(FOCUS.id, &"focus_priority", "definitions: stable Focus id")
	assert_eq(FOCUS.priority_duration_seconds, 3.0, "definitions: Focus exact priority duration")
	assert_eq(FOCUS.cooldown_seconds, 10.0, "definitions: Focus exact cooldown")
	assert_eq(FOCUS.minimum_decision_window_seconds, 0.35, "definitions: Focus exact cutoff")
	assert_eq(ALLEY.environment_action_id, EnvironmentController.ACTION_HYDRANT, "encounters: alley uses Hydrant")
	assert_eq(ARCADE.environment_action_id, EnvironmentController.ACTION_POWER_BOX, "encounters: arcade uses Power Box")
	assert_eq(SIGNAL.environment_action_id, EnvironmentController.ACTION_POWER_BOX, "encounters: elite exposes the approved interrupt context")
	assert_eq(SHOWDOWN.environment_action_id, EnvironmentController.ACTION_POWER_BOX, "encounters: boss uses Power Box")
	var exact_intents: Dictionary[StringName, Array] = {
		&"bat_thug_heavy_swing": [0.90, 20, "HEAVY SWING"],
		&"bottle_throw": [0.95, 30, "BOTTLE THROW"],
		&"viper_enforcer_charge": [1.00, 60, "ARMOURED CHARGE"],
		&"viper_charge": [1.05, 70, "VIPER RUSH"],
		&"viper_summon": [1.10, 65, "SUMMON VIPERS"],
		&"viper_area_warning": [1.10, 80, "VENOM AREA"],
	}
	for attack: AttackDefinition in _all_focus_attacks():
		assert_true(exact_intents.has(attack.id), "intents: only approved attack %s is eligible" % attack.id)
		assert_true(attack.focus_priority_eligible, "intents: %s is Focus eligible" % attack.id)
		assert_eq(attack.windup_time, float(exact_intents[attack.id][0]), "intents: %s exact readable windup" % attack.id)
		assert_eq(attack.telegraph_seconds, attack.windup_time, "intents: %s telegraph covers windup" % attack.id)
		assert_eq(attack.focus_threat_priority, int(exact_intents[attack.id][1]), "intents: %s stable rank" % attack.id)
		assert_eq(attack.intent_label, str(exact_intents[attack.id][2]), "intents: %s explicit label" % attack.id)
	assert_eq(_all_focus_attacks().size(), 6, "intents: exact six authored eligible attacks")
	var punk: ActorController = _scene_actor(STREET)
	assert_false(punk.attack_definition.focus_priority_eligible, "intents: low-impact Street Punk remains ineligible")
	assert_eq(punk.attack_definition.windup_time, 0.31, "intents: Street Punk timing is unchanged")
	assert_eq(RANDOM_SCHEMA.random_schema_version, 1, "determinism: random schema remains one")


func test_environment_rejects_malformed_stale_wrong_and_no_target_requests_immutably() -> void:
	var harness: Dictionary = _new_intervention_harness()
	var environment: EnvironmentController = harness.environment
	assert_true(environment.set_context_action(EnvironmentController.ACTION_POWER_BOX), "environment: Power Box context accepts")
	var snapshot: Dictionary = environment.get_snapshot()
	assert_eq(snapshot.validity_reason, EnvironmentController.REASON_NO_TARGET, "environment: empty footprint is invalid")
	var before: Dictionary = snapshot.duplicate(true)
	var malformed: Dictionary = environment.request_activation(&"", -1, -1)
	assert_eq(malformed.reason, EnvironmentController.REASON_MALFORMED, "environment: malformed reason")
	assert_eq(environment.get_snapshot(), before, "environment: malformed request mutates nothing")
	var stale: Dictionary = environment.request_activation(
		EnvironmentController.ACTION_POWER_BOX,
		int(snapshot.context_revision) - 1,
		int(snapshot.request_token)
	)
	assert_eq(stale.reason, EnvironmentController.REASON_STALE, "environment: stale reason")
	assert_eq(environment.get_snapshot(), before, "environment: stale request mutates nothing")
	var wrong: Dictionary = environment.request_activation(
		EnvironmentController.ACTION_HYDRANT,
		int(snapshot.context_revision),
		int(snapshot.request_token)
	)
	assert_eq(wrong.reason, EnvironmentController.REASON_WRONG_ACTION, "environment: wrong context reason")
	assert_eq(environment.get_snapshot(), before, "environment: wrong action mutates nothing")
	var no_target: Dictionary = environment.request_activation(
		EnvironmentController.ACTION_POWER_BOX,
		int(snapshot.context_revision),
		int(snapshot.request_token)
	)
	assert_eq(no_target.reason, EnvironmentController.REASON_NO_TARGET, "environment: exact no-target reason")
	assert_eq(environment.get_shared_cooldown_remaining(), 0.0, "environment: rejection spends no cooldown")


func test_power_box_interrupts_applies_build_aware_shock_and_replay_spends_nothing() -> void:
	var harness: Dictionary = _new_intervention_harness()
	var director: CombatDirector = harness.director
	var environment: EnvironmentController = harness.environment
	var crew: ActorController = _spawn_actor(harness.host, JAX, Vector2(300.0, 226.0), director)
	var enemy: ActorController = _spawn_actor(harness.host, ENFORCER, Vector2(370.0, 226.0), director)
	assert_true(enemy.assign_target(crew), "power box: elite target assigns")
	var charge: AttackDefinition = _attack_by_id(enemy, &"viper_enforcer_charge")
	enemy._start_planned_attack(charge)
	assert_eq(enemy.state_machine.current_state, ActorStateMachine.State.ATTACK_WINDUP, "power box: readable charge is live")
	assert_true(environment.set_context_action(EnvironmentController.ACTION_POWER_BOX), "power box: context sets")
	var request: Dictionary = environment.get_snapshot()
	var health_before: int = enemy.health_component.current_health
	var accepted: Dictionary = environment.request_activation(
		request.action_id,
		int(request.context_revision),
		int(request.request_token)
	)
	assert_true(accepted.accepted, "power box: valid request accepts")
	assert_eq(accepted.result.affected_count, 1, "power box: one in-range target affected")
	assert_eq(accepted.result.interrupted_count, 1, "power box: live charge interrupted")
	assert_eq(accepted.result.status_count, 1, "power box: Shock application acknowledged")
	assert_eq(health_before - enemy.health_component.current_health, 4, "power box: exact low damage")
	assert_eq(enemy.state_machine.current_state, ActorStateMachine.State.STUNNED, "power box: enemy enters resisted stun")
	assert_true(enemy.has_status(&"shock"), "power box: existing Shock marker applies")
	assert_eq(enemy.status_controller.get_remaining(&"shock"), 3.0, "power box: base build uses three-second Shock")
	assert_eq(environment.get_shared_cooldown_remaining(), 12.0, "power box: shared cooldown commits once")
	var after_accept: Dictionary = environment.get_snapshot()
	var replay: Dictionary = environment.request_activation(
		request.action_id,
		int(request.context_revision),
		int(request.request_token)
	)
	assert_eq(replay.reason, EnvironmentController.REASON_REPLAYED, "power box: exact token replay rejects")
	assert_eq(environment.get_snapshot(), after_accept, "power box: replay mutates no ledger")


func test_hydrant_remains_exact_and_shares_one_environment_cooldown_with_power_box() -> void:
	var harness: Dictionary = _new_intervention_harness()
	var director: CombatDirector = harness.director
	var hydrant: FireHydrantController = harness.hydrant
	var environment: EnvironmentController = harness.environment
	var enemy: ActorController = _spawn_actor(harness.host, STREET, Vector2(410.0, 239.0), director)
	assert_true(environment.set_context_action(EnvironmentController.ACTION_HYDRANT), "hydrant: context sets")
	var health_before: int = enemy.health_component.current_health
	var request: Dictionary = environment.get_snapshot()
	var accepted: Dictionary = environment.request_activation(
		request.action_id,
		int(request.context_revision),
		int(request.request_token)
	)
	assert_true(accepted.accepted, "hydrant: wrapper accepts valid request")
	assert_eq(health_before - enemy.health_component.current_health, 18, "hydrant: preserved exact damage")
	assert_true(enemy.has_status(&"wet"), "hydrant: preserved Wet marker")
	assert_eq(enemy.status_controller.get_remaining(&"wet"), 4.0, "hydrant: preserved Wet duration")
	assert_eq(environment.get_shared_cooldown_remaining(), 8.0, "hydrant: preserved base cooldown in shared ledger")
	assert_true(environment.set_context_action(EnvironmentController.ACTION_POWER_BOX), "environment: context replaces same slot")
	var switched: Dictionary = environment.get_snapshot()
	assert_eq(switched.validity_reason, EnvironmentController.REASON_COOLDOWN, "environment: switch cannot bypass shared cooldown")
	var rejected: Dictionary = environment.request_activation(
		switched.action_id,
		int(switched.context_revision),
		int(switched.request_token)
	)
	assert_eq(rejected.reason, EnvironmentController.REASON_COOLDOWN, "environment: cross-context cooldown reason")
	assert_eq(environment.get_shared_cooldown_remaining(), 8.0, "environment: cooldown rejection spends nothing")
	hydrant.step_cooldown(8.01)
	environment.step_eligible_time(8.01)
	enemy.global_position = Vector2(370.0, 226.0)
	environment.step_eligible_time(0.001)
	assert_eq(environment.get_validity_reason(), EnvironmentController.REASON_NO_INTERRUPT, "environment: harmless body is a reason to hold Power Box")
	var crew: ActorController = _spawn_actor(harness.host, JAX, Vector2(300.0, 226.0), director)
	var threat: ActorController = _spawn_actor(harness.host, BOTTLE, Vector2(370.0, 226.0), director)
	threat.assign_target(crew)
	threat._start_planned_attack(threat.attack_definition)
	environment.step_eligible_time(0.001)
	assert_true(environment.can_activate(), "environment: Power Box becomes valid after shared edge")


func test_environment_cooldown_survives_context_gap_pause_and_multiplier_changes() -> void:
	var harness: Dictionary = _new_intervention_harness()
	var director: CombatDirector = harness.director
	var environment: EnvironmentController = harness.environment
	var crew: ActorController = _spawn_actor(harness.host, JAX, Vector2(300.0, 226.0), director)
	var threat: ActorController = _spawn_actor(harness.host, BOTTLE, Vector2(370.0, 226.0), director)
	threat.assign_target(crew)
	threat._start_planned_attack(threat.attack_definition)
	environment.set_context_action(EnvironmentController.ACTION_POWER_BOX)
	var request: Dictionary = environment.get_snapshot()
	assert_true(bool(environment.request_activation(request.action_id, request.context_revision, request.request_token).accepted), "cooldown: Power Box commits")
	assert_true(environment.set_context_action(&""), "cooldown: context clears between fights")
	environment.set_cooldown_multiplier(0.5)
	assert_eq(environment.get_shared_cooldown_remaining(), 6.0, "cooldown: contextless multiplier preserves ratio")
	assert_eq(environment.get_snapshot().cooldown_source_action_id, EnvironmentController.ACTION_POWER_BOX, "cooldown: source identity survives context gap")
	environment.set_simulation_enabled(false)
	environment.step_eligible_time(3.0)
	assert_eq(environment.get_shared_cooldown_remaining(), 6.0, "cooldown: pause excludes time")
	environment.set_simulation_enabled(true)
	environment.set_context_action(EnvironmentController.ACTION_HYDRANT)
	assert_eq(environment.get_snapshot().cooldown_duration, 6.0, "cooldown: HUD exposes shared source duration")
	environment.set_cooldown_multiplier(0.85)
	assert_eq(environment.get_shared_cooldown_remaining(), 10.2, "cooldown: second multiplier preserves full remaining ratio")
	environment.reset_for_run()
	assert_eq(environment.get_shared_cooldown_remaining(), 0.0, "cooldown: restart clears shared ledger")
	assert_eq(environment.get_current_action_id(), &"", "cooldown: restart clears context")


func test_focus_ranks_live_intent_and_only_redirects_uncommitted_automatic_crew() -> void:
	var harness: Dictionary = _new_intervention_harness()
	var director: CombatDirector = harness.director
	var focus: FocusController = harness.focus
	var crew: ActorController = _spawn_actor(harness.host, JAX, Vector2(300.0, 226.0), director)
	var ordinary: ActorController = _spawn_actor(harness.host, STREET, Vector2(320.0, 226.0), director)
	var bottle: ActorController = _spawn_actor(harness.host, BOTTLE, Vector2(430.0, 226.0), director)
	var enforcer: ActorController = _spawn_actor(harness.host, ENFORCER, Vector2(390.0, 226.0), director)
	assert_true(crew.assign_target(ordinary), "focus: crew starts on ordinary target")
	assert_true(bottle.assign_target(crew), "focus: Bottle target assigns")
	assert_true(enforcer.assign_target(crew), "focus: Enforcer target assigns")
	bottle._start_planned_attack(bottle.attack_definition)
	enforcer._start_planned_attack(_attack_by_id(enforcer, &"viper_enforcer_charge"))
	focus.step_eligible_time(0.001)
	var snapshot: Dictionary = focus.get_snapshot()
	assert_eq(snapshot.target_id, &"viper_enforcer", "focus: higher authored threat rank wins")
	assert_eq(snapshot.attack_id, &"viper_enforcer_charge", "focus: exact live intent is named")
	assert_eq(snapshot.intent_label, "ARMOURED CHARGE", "focus: explicit player-facing intent")
	assert_true(float(snapshot.window_seconds) >= 0.35, "focus: decision window remains open")
	var crew_health: int = crew.health_component.current_health
	var enemy_health: int = enforcer.health_component.current_health
	var crew_position: Vector2 = crew.global_position
	var accepted: Dictionary = focus.request_activation(
		int(snapshot.target_instance_id),
		StringName(snapshot.attack_id),
		int(snapshot.context_revision),
		int(snapshot.request_token)
	)
	assert_true(accepted.accepted, "focus: exact contextual request accepts")
	assert_eq(accepted.retargeted_count, 1, "focus: one available permanent crew redirects")
	assert_eq(crew.current_target, enforcer, "focus: automatic target priority changes")
	assert_eq(crew.health_component.current_health, crew_health, "focus: activation adds no healing or damage")
	assert_eq(enforcer.health_component.current_health, enemy_health, "focus: activation adds no direct damage")
	assert_eq(crew.global_position, crew_position, "focus: activation does not directly move crew")
	assert_true(enforcer.attack_controller.is_attacking(), "focus: activation does not cancel enemy intent")
	assert_eq(focus.get_snapshot().target_name, "Viper Enforcer", "focus: active presentation retains target name")
	assert_eq(focus.get_snapshot().active_remaining, 3.0, "focus: exact priority duration commits")
	assert_eq(focus.get_snapshot().cooldown_remaining, 10.0, "focus: exact cooldown commits")
	var replay: Dictionary = focus.request_activation(
		int(snapshot.target_instance_id),
		StringName(snapshot.attack_id),
		int(snapshot.context_revision),
		int(snapshot.request_token)
	)
	assert_eq(replay.reason, FocusController.REASON_REPLAYED, "focus: exact token cannot replay")


func test_focus_respects_attack_commitment_then_reapplies_priority_during_active_window() -> void:
	var harness: Dictionary = _new_intervention_harness()
	var director: CombatDirector = harness.director
	var focus: FocusController = harness.focus
	var crew: ActorController = _spawn_actor(harness.host, ZOEY, Vector2(300.0, 226.0), director)
	var ordinary: ActorController = _spawn_actor(harness.host, STREET, Vector2(320.0, 226.0), director)
	var bottle: ActorController = _spawn_actor(harness.host, BOTTLE, Vector2(430.0, 226.0), director)
	crew.assign_target(ordinary)
	crew._start_planned_attack(crew.attack_definition)
	bottle.assign_target(crew)
	bottle._start_planned_attack(bottle.attack_definition)
	focus.step_eligible_time(0.001)
	var snapshot: Dictionary = focus.get_snapshot()
	var accepted: Dictionary = focus.request_activation(snapshot.target_instance_id, snapshot.attack_id, snapshot.context_revision, snapshot.request_token)
	assert_true(accepted.accepted, "focus commitment: contextual request accepts")
	assert_eq(accepted.retargeted_count, 0, "focus commitment: current attack is never stolen")
	assert_eq(crew.current_target, ordinary, "focus commitment: target remains through current action")
	crew._cancel_active_attack()
	crew.state_machine.transition_to(ActorStateMachine.State.APPROACHING_TARGET)
	focus.step_eligible_time(0.01)
	assert_eq(crew.current_target, bottle, "focus commitment: priority applies when crew becomes free")


func test_focus_revalidates_races_cutoff_pause_death_expiry_and_restart() -> void:
	var race: Dictionary = _new_intervention_harness()
	var race_director: CombatDirector = race.director
	var race_focus: FocusController = race.focus
	var race_crew: ActorController = _spawn_actor(race.host, JAX, Vector2(300.0, 226.0), race_director)
	var race_enemy: ActorController = _spawn_actor(race.host, BOTTLE, Vector2(430.0, 226.0), race_director)
	race_enemy.assign_target(race_crew)
	race_enemy._start_planned_attack(race_enemy.attack_definition)
	race_focus.step_eligible_time(0.001)
	var stale_live: Dictionary = race_focus.get_snapshot()
	race_enemy.attack_controller.step(1.0)
	var raced: Dictionary = race_focus.request_activation(stale_live.target_instance_id, stale_live.attack_id, stale_live.context_revision, stale_live.request_token)
	assert_eq(raced.reason, FocusController.REASON_TARGET_CHANGED, "focus race: closed live windup rejects even before next UI tick")
	assert_eq(race_focus.get_snapshot().cooldown_remaining, 0.0, "focus race: rejection spends no cooldown")

	var cutoff: Dictionary = _new_intervention_harness()
	var cutoff_director: CombatDirector = cutoff.director
	var cutoff_focus: FocusController = cutoff.focus
	var cutoff_crew: ActorController = _spawn_actor(cutoff.host, JAX, Vector2(300.0, 226.0), cutoff_director)
	var cutoff_enemy: ActorController = _spawn_actor(cutoff.host, BOTTLE, Vector2(430.0, 226.0), cutoff_director)
	cutoff_enemy.assign_target(cutoff_crew)
	cutoff_enemy._start_planned_attack(cutoff_enemy.attack_definition)
	cutoff_enemy.attack_controller.step(0.61)
	cutoff_focus.step_eligible_time(0.001)
	var closed: Dictionary = cutoff_focus.get_snapshot()
	assert_eq(closed.validity_reason, FocusController.REASON_WINDOW_CLOSED, "focus cutoff: sub-0.35 window is named")
	var cutoff_result: Dictionary = cutoff_focus.request_activation(closed.target_instance_id, closed.attack_id, closed.context_revision, closed.request_token)
	assert_eq(cutoff_result.reason, FocusController.REASON_WINDOW_CLOSED, "focus cutoff: exact closed-window request rejects")
	assert_eq(cutoff_focus.get_snapshot().cooldown_remaining, 0.0, "focus cutoff: rejection spends nothing")

	var lifecycle: Dictionary = _new_intervention_harness()
	var lifecycle_director: CombatDirector = lifecycle.director
	var lifecycle_focus: FocusController = lifecycle.focus
	var lifecycle_crew: ActorController = _spawn_actor(lifecycle.host, JAX, Vector2(300.0, 226.0), lifecycle_director)
	var lifecycle_enemy: ActorController = _spawn_actor(lifecycle.host, ENFORCER, Vector2(390.0, 226.0), lifecycle_director)
	lifecycle_enemy.assign_target(lifecycle_crew)
	lifecycle_enemy._start_planned_attack(_attack_by_id(lifecycle_enemy, &"viper_enforcer_charge"))
	lifecycle_focus.step_eligible_time(0.001)
	var current: Dictionary = lifecycle_focus.get_snapshot()
	assert_true(bool(lifecycle_focus.request_activation(current.target_instance_id, current.attack_id, current.context_revision, current.request_token).accepted), "focus lifecycle: activation accepts")
	lifecycle_focus.set_simulation_enabled(false)
	lifecycle_focus.step_eligible_time(2.0)
	assert_eq(lifecycle_focus.get_snapshot().active_remaining, 3.0, "focus lifecycle: pause freezes active duration")
	lifecycle_focus.set_simulation_enabled(true)
	lifecycle_enemy.receive_damage(99999)
	assert_eq(lifecycle_focus.get_snapshot().active_target_instance_id, -1, "focus lifecycle: target death clears synchronously")
	lifecycle_focus.reset_for_run()
	assert_eq(lifecycle_focus.get_snapshot().cooldown_remaining, 0.0, "focus lifecycle: restart clears cooldown")
	var replay_after_restart: Dictionary = lifecycle_focus.request_activation(current.target_instance_id, current.attack_id, current.context_revision, current.request_token)
	assert_eq(replay_after_restart.reason, FocusController.REASON_REPLAYED, "focus lifecycle: old accepted token stays unusable after restart")


func test_backup_exact_caller_context_rejects_stale_replay_and_restart_aliases() -> void:
	var host: Node2D = _new_host("WP05BackupAuthority")
	var controller: CallBackupController = CallBackupController.new()
	host.add_child(controller)
	controller.set_process(false)
	var backup_harness: BackupHarness = BackupHarness.new()
	backup_harness.host = host
	controller.configure(
		Callable(backup_harness, "spawn_ally"),
		Callable(backup_harness, "register_ally"),
		Callable(backup_harness, "remove_ally")
	)
	controller.set_simulation_enabled(true)
	controller.set_combat_available(true)
	var snapshot: Dictionary = controller.get_snapshot()
	var charges_before: int = controller.get_charges_remaining()
	assert_false(controller.request_activation(-1, int(snapshot.request_token)), "backup gate: malformed revision rejects")
	assert_eq(controller.get_charges_remaining(), charges_before, "backup gate: malformed request spends no charge")
	assert_false(controller.request_activation(int(snapshot.request_context_revision) - 1, int(snapshot.request_token)), "backup gate: stale context rejects")
	assert_eq(controller.get_cooldown_remaining(), 0.0, "backup gate: stale request spends no cooldown")
	assert_true(controller.request_activation(int(snapshot.request_context_revision), int(snapshot.request_token)), "backup gate: exact context accepts")
	assert_eq(controller.get_active_allies().size(), 2, "backup gate: exact two allies")
	assert_eq(controller.get_charges_remaining(), charges_before - 1, "backup gate: exactly one finite charge commits")
	var accepted_state: Dictionary = controller.get_snapshot()
	assert_false(controller.request_activation(int(snapshot.request_context_revision), int(snapshot.request_token)), "backup gate: exact token replay rejects")
	assert_eq(controller.get_snapshot(), accepted_state, "backup gate: replay mutates nothing")
	controller.cleanup_for_terminal_state()
	assert_eq(backup_harness.removed_count, 2, "backup gate: terminal removes both allies once")
	controller.reset_for_run()
	assert_eq(controller.get_charges_remaining(), 2, "backup gate: restart restores two run charges")
	assert_false(controller.request_activation(int(snapshot.request_context_revision), int(snapshot.request_token)), "backup gate: pre-restart accepted token remains replayed")
	assert_eq(controller.get_charges_remaining(), 2, "backup gate: restart replay spends nothing")


func test_production_authorities_use_no_unseeded_rng_and_release_has_no_rejected_roles() -> void:
	for path: String in [
		"res://scripts/interventions/environment_controller.gd",
		"res://scripts/interventions/focus_controller.gd",
		"res://scripts/interventions/call_backup_controller.gd",
	]:
		var source: String = FileAccess.get_file_as_string(path)
		for forbidden: String in ["randi(", "randf(", "randomize(", ".shuffle(", ".pick_random("]:
			assert_false(source.contains(forbidden), "determinism: %s has no %s" % [path, forbidden])
	var game_source: String = FileAccess.get_file_as_string("res://scripts/run/game_run.gd")
	var hud_source: String = FileAccess.get_file_as_string("res://scripts/ui/game_hud.gd")
	for forbidden_role: String in ["rally", "hanging_sign", "4 DEV", "prototype_visual_freeze"]:
		assert_false(game_source.to_lower().contains(forbidden_role.to_lower()), "release: GameRun omits %s" % forbidden_role)
		assert_false(hud_source.to_lower().contains(forbidden_role.to_lower()), "release: GameHUD omits %s" % forbidden_role)
	assert_true(FileAccess.file_exists("res://scripts/interventions/wp05_prototype_runtime.gd"), "evidence: isolated Part A runtime remains available")


func _new_intervention_harness() -> Dictionary:
	var host: Node2D = _new_host("WP05InterventionHarness")
	var director: CombatDirector = CombatDirector.new()
	host.add_child(director)
	director.set_process(false)
	director.set_physics_process(false)
	director.set_simulation_enabled(false)
	var hydrant: FireHydrantController = FireHydrantController.new()
	hydrant.tuning = HYDRANT_TUNING
	host.add_child(hydrant)
	hydrant.set_process(false)
	hydrant.configure(director, Vector2(410.0, 239.0))
	hydrant.set_simulation_enabled(true)
	var environment: EnvironmentController = EnvironmentController.new()
	environment.power_box_definition = POWER_BOX
	host.add_child(environment)
	environment.set_process(false)
	assert_true(environment.configure(director, hydrant, Vector2(410.0, 239.0), Vector2(370.0, 226.0)), "harness: Environment configures")
	environment.set_simulation_enabled(true)
	environment.set_combat_available(true)
	var focus: FocusController = FocusController.new()
	focus.definition = FOCUS
	host.add_child(focus)
	focus.set_process(false)
	assert_true(focus.configure(director), "harness: Focus configures")
	focus.set_simulation_enabled(true)
	focus.set_combat_available(true)
	return {
		"host": host,
		"director": director,
		"hydrant": hydrant,
		"environment": environment,
		"focus": focus,
	}


func _new_host(host_name: String) -> Node2D:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "harness: SceneTree exists")
	var host: Node2D = track(Node2D.new()) as Node2D
	host.name = host_name
	host.process_mode = Node.PROCESS_MODE_DISABLED
	tree.root.add_child(host)
	return host


func _spawn_actor(
	host: Node,
	scene: PackedScene,
	world_position: Vector2,
	director: CombatDirector
) -> ActorController:
	var actor: ActorController = scene.instantiate() as ActorController
	assert_true(actor != null, "actor: scene instantiates")
	host.add_child(actor)
	actor.set_process(false)
	actor.set_physics_process(false)
	actor.global_position = actor.get_combat_space().clamp_actor_position(world_position)
	assert_true(director.register_actor(actor), "actor: %s registers" % actor.definition_id())
	return actor


func _scene_actor(scene: PackedScene) -> ActorController:
	return track(scene.instantiate()) as ActorController


func _attack_by_id(actor: ActorController, attack_id: StringName) -> AttackDefinition:
	if actor.attack_definition != null and actor.attack_definition.id == attack_id:
		return actor.attack_definition
	for attack: AttackDefinition in actor.special_attack_definitions:
		if attack != null and attack.id == attack_id:
			return attack
	return null


func _all_focus_attacks() -> Array[AttackDefinition]:
	var result: Array[AttackDefinition] = []
	for scene: PackedScene in [BAT, BOTTLE, ENFORCER, VIPER]:
		var actor: ActorController = _scene_actor(scene)
		if actor.attack_definition != null and actor.attack_definition.focus_priority_eligible:
			result.append(actor.attack_definition)
		for attack: AttackDefinition in actor.special_attack_definitions:
			if attack != null and attack.focus_priority_eligible:
				result.append(attack)
	result.sort_custom(func(left: AttackDefinition, right: AttackDefinition) -> bool: return String(left.id) < String(right.id))
	return result
