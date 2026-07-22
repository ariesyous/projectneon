@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const ActorSceneCatalogueType = preload("res://scripts/actors/actor_scene_catalogue.gd")
const CombatProjectileType = preload("res://scripts/combat/combat_projectile.gd")
const EncounterSpawnEntryType = preload("res://data/encounters/encounter_spawn_entry.gd")

const ACTOR_CATALOGUE: ActorSceneCatalogueType = preload(
	"res://data/actors/milestone_6_actor_catalogue.tres"
)
const ALLEY_SCUFFLE: EncounterDefinition = preload(
	"res://data/encounters/alley_scuffle.tres"
)
const ARCADE_AMBUSH: EncounterDefinition = preload(
	"res://data/encounters/arcade_ambush.tres"
)
const VIPER_SIGNAL: EncounterDefinition = preload(
	"res://data/encounters/viper_signal.tres"
)
const VIPER_SHOWDOWN: EncounterDefinition = preload(
	"res://data/encounters/viper_showdown.tres"
)


func suite_name() -> String:
	return "milestone_6_combat_content"


func test_actor_catalogue_has_exact_stable_vertical_slice_roster() -> void:
	var expected_ids: Array[StringName] = [
		&"backup_runner",
		&"bat_thug",
		&"bottle_thrower",
		&"jax",
		&"rex",
		&"street_punk",
		&"the_viper",
		&"viper_enforcer",
		&"zoey",
	]
	assert_true(ACTOR_CATALOGUE.is_valid(), "actor catalogue: every stable ID maps uniquely")
	assert_eq(ACTOR_CATALOGUE.get_stable_ids(), expected_ids, "actor catalogue: exact stable roster")
	for actor_id: StringName in expected_ids:
		assert_true(ACTOR_CATALOGUE.get_scene(actor_id) != null, "actor catalogue: %s has a scene" % actor_id)


func test_three_permanent_crew_have_authored_mechanical_distinctions() -> void:
	var jax: ActorController = _actor(&"jax")
	var zoey: ActorController = _actor(&"zoey")
	var rex: ActorController = _actor(&"rex")

	assert_true(jax.actor_definition.is_permanent_crew(), "crew: Jax is permanent crew")
	assert_true(zoey.actor_definition.is_permanent_crew(), "crew: Zoey is permanent crew")
	assert_true(rex.actor_definition.is_permanent_crew(), "crew: Rex is permanent crew")
	assert_eq(jax.actor_definition.maximum_health, 520, "crew: Jax has medium health")
	assert_eq(jax.attack_definition.attack_range, 52.0, "crew: Jax is short range")
	assert_eq(jax.attack_definition.knockback_force, 155.0, "crew: Jax has high knockback")
	assert_eq(jax.actor_definition.environmental_collision_damage_multiplier, 1.25, "crew: Jax amplifies sourced wall collisions")
	assert_eq(jax.actor_definition.starting_equipment.size(), 1, "crew: Jax has exactly one starter")
	assert_eq(jax.actor_definition.starting_equipment[0].id, &"spiked_bat", "crew: Jax starts with existing Spiked Bat")
	assert_eq(zoey.actor_definition.maximum_health, 400, "crew: Zoey has lower health")
	assert_true(zoey.attack_definition.cooldown_time < jax.attack_definition.cooldown_time, "crew: Zoey attacks faster than Jax")
	assert_eq(zoey.actor_definition.intervention_cooldown_multiplier, 0.85, "crew: Zoey reduces intervention cooldowns")
	assert_eq(zoey.actor_definition.starting_equipment.size(), 1, "crew: Zoey has exactly one starter")
	assert_eq(zoey.actor_definition.starting_equipment[0].id, &"shock_gloves", "crew: Zoey starts with existing Shock Gloves")
	assert_eq(rex.actor_definition.maximum_health, 720, "crew: Rex has high health")
	assert_true(rex.attack_definition.cooldown_time > jax.attack_definition.cooldown_time, "crew: Rex attacks slower than Jax")
	assert_eq(rex.actor_definition.stagger_resistance, 0.65, "crew: Rex has strong stagger resistance")
	assert_eq(rex.actor_definition.damage_against_elites_multiplier, 1.25, "crew: Rex has elite bonus")
	assert_eq(rex.actor_definition.damage_against_bosses_multiplier, 1.25, "crew: Rex has boss bonus")
	assert_eq(rex.actor_definition.starting_equipment.size(), 1, "crew: Rex has exactly one starter")
	assert_eq(rex.actor_definition.starting_equipment[0].id, &"reinforced_jacket", "crew: Rex starts with existing Reinforced Jacket")


func test_three_basic_enemies_are_distinct_melee_heavy_and_ranged_actors() -> void:
	var punk: ActorController = _actor(&"street_punk")
	var thug: ActorController = _actor(&"bat_thug")
	var thrower: ActorController = _actor(&"bottle_thrower")

	assert_eq(punk.actor_definition.combat_role, ActorDefinition.CombatRole.BASIC_ENEMY, "enemy: Punk is basic")
	assert_eq(thug.actor_definition.combat_role, ActorDefinition.CombatRole.BASIC_ENEMY, "enemy: Thug is basic")
	assert_eq(thrower.actor_definition.combat_role, ActorDefinition.CombatRole.BASIC_ENEMY, "enemy: Thrower is basic")
	assert_true(punk.actor_definition.maximum_health < thug.actor_definition.maximum_health, "enemy: Punk is lower health than Thug")
	assert_true(punk.actor_definition.movement_speed > thug.actor_definition.movement_speed, "enemy: Punk moves faster than Thug")
	assert_true(thug.attack_definition.is_heavy(), "enemy: Bat Thug uses a heavy attack")
	assert_true(thug.attack_definition.windup_time > punk.attack_definition.windup_time, "enemy: Bat attack is slower and readable")
	assert_true(thug.attack_definition.knockback_force > punk.attack_definition.knockback_force, "enemy: Bat attack has higher knockback")
	assert_eq(thrower.attack_definition.delivery_kind, AttackDefinition.DeliveryKind.PROJECTILE, "enemy: Bottle Thrower is ranged")
	assert_true(thrower.attack_definition.projectile_definition != null, "enemy: bottle projectile is authored data")
	assert_eq(thrower.attack_definition.minimum_range, 125.0, "enemy: Bottle Thrower maintains distance")
	assert_eq(thrower.attack_definition.projectile_definition.speed, 105.0, "enemy: bottle projectile remains slow")


func test_viper_enforcer_has_elite_charge_armour_reward_and_control_tuning() -> void:
	var enforcer: ActorController = _actor(&"viper_enforcer")
	var definition: ActorDefinition = enforcer.actor_definition

	assert_true(definition.is_elite(), "elite: Enforcer has elite combat role")
	assert_eq(definition.maximum_health, 420, "elite: Enforcer has high health")
	assert_eq(definition.light_stagger_armour, 170.0, "elite: light stagger armour is explicit")
	assert_eq(definition.stagger_resistance, 0.5, "elite: control resistance is explicit")
	assert_eq(definition.maximum_stun_duration, 0.75, "elite: stun duration is capped")
	assert_true(definition.grants_coin_reward, "elite: Enforcer grants a coin reward")
	assert_eq(definition.authored_coin_value, 120, "elite: increased reward is 120 coins")
	assert_eq(enforcer.special_attack_definitions.size(), 1, "elite: one authored charge special")
	var charge: AttackDefinition = enforcer.special_attack_definitions[0]
	assert_eq(charge.delivery_kind, AttackDefinition.DeliveryKind.CHARGE, "elite: special uses charge delivery")
	assert_eq(charge.telegraph_seconds, 0.75, "elite: charge telegraph is readable")
	assert_true(charge.knockback_force > enforcer.attack_definition.knockback_force, "elite: charge is the stronger impact")


func test_viper_boss_has_complete_authored_behavior_and_anti_lock_contract() -> void:
	var boss: ActorController = _actor(&"the_viper")
	var definition: ActorDefinition = boss.actor_definition
	var attacks: Dictionary[StringName, AttackDefinition] = {}
	for attack: AttackDefinition in boss.special_attack_definitions:
		attacks[attack.id] = attack

	assert_true(definition.is_boss(), "boss: Viper has boss role")
	assert_eq(definition.maximum_health, 1800, "boss: Viper has 1800 HP")
	assert_eq(definition.knockback_resistance, 0.85, "boss: Viper has 85 percent knockback resistance")
	assert_eq(definition.maximum_stun_duration, 0.35, "boss: stun duration caps at 0.35 seconds")
	assert_eq(definition.control_lockout_seconds, 2.0, "boss: control lockout is two seconds")
	assert_eq(definition.enrage_health_ratio, 0.4, "boss: enrage threshold is 40 percent")
	assert_eq(definition.enrage_damage_multiplier, 1.2, "boss: enrage adds 20 percent damage")
	assert_eq(definition.enrage_attack_speed_multiplier, 1.25, "boss: enrage adds 25 percent attack speed")
	assert_eq(boss.attack_definition.combo_hit_count, 3, "boss: basic melee is a three-hit combo")
	assert_true(attacks.has(&"viper_charge"), "boss: charge is authored")
	assert_true(attacks.has(&"viper_area_warning"), "boss: area warning is authored")
	assert_true(attacks.has(&"viper_summon"), "boss: summon is authored")
	assert_eq(attacks[&"viper_area_warning"].delivery_kind, AttackDefinition.DeliveryKind.AREA, "boss: warning resolves as an area attack")
	assert_eq(attacks[&"viper_area_warning"].telegraph_seconds, 1.1, "boss: area telegraph duration is explicit")
	assert_eq(attacks[&"viper_summon"].summon_actor_ids, [&"street_punk", &"bat_thug"], "boss: summon contains exactly two basic enemies")


func test_authored_encounters_use_stable_spawn_tables_and_exact_elite_boss_counts() -> void:
	assert_eq(_spawn_ids(ALLEY_SCUFFLE), [&"bat_thug", &"street_punk"], "encounter: alley has two melee variants")
	assert_eq(_spawn_ids(ARCADE_AMBUSH), [&"bat_thug", &"bottle_thrower", &"street_punk"], "encounter: arcade has all basic variants")
	for definition: EncounterDefinition in [ALLEY_SCUFFLE, ARCADE_AMBUSH, VIPER_SIGNAL]:
		assert_eq(definition.initial_spawn_delay_seconds, 3.0, "encounter: %s has the authored entry beat" % definition.id)
		assert_eq(definition.spawn_interval_seconds, 12.0, "encounter: %s stages ambient opportunities" % definition.id)
	assert_eq(_minimum_count(VIPER_SIGNAL, &"viper_enforcer"), 1, "encounter: signal requires one Enforcer")
	assert_eq(_maximum_count(VIPER_SIGNAL, &"viper_enforcer"), 1, "encounter: signal cannot scale above one Enforcer")
	assert_true(VIPER_SIGNAL.elite_eligible, "encounter: viper signal remains elite")
	assert_true(VIPER_SHOWDOWN.boss, "encounter: showdown is a boss encounter")
	assert_eq(VIPER_SHOWDOWN.initial_spawn_delay_seconds, 0.0, "encounter: boss enters immediately after its intro")
	assert_eq(VIPER_SHOWDOWN.spawn_interval_seconds, 0.0, "encounter: boss timing remains special-attack-owned")
	assert_eq(_spawn_ids(VIPER_SHOWDOWN), [&"the_viper"], "encounter: showdown contains only the Viper")
	assert_eq(_minimum_count(VIPER_SHOWDOWN, &"the_viper"), 1, "encounter: showdown requires one Viper")
	assert_eq(_maximum_count(VIPER_SHOWDOWN, &"the_viper"), 1, "encounter: showdown cannot duplicate the boss")


func test_projectile_sweep_detects_crossed_targets_without_frame_rng() -> void:
	assert_eq(CombatProjectileType._segment_hit_fraction(Vector2.ZERO, Vector2(100.0, 0.0), Vector2(50.0, 0.0), 8.0), 0.5, "projectile: crossed target resolves at exact segment fraction")
	assert_eq(CombatProjectileType._segment_hit_fraction(Vector2.ZERO, Vector2(100.0, 0.0), Vector2(50.0, 9.0), 8.0), -1.0, "projectile: target outside radius is rejected")
	assert_eq(CombatProjectileType._segment_hit_fraction(Vector2.ZERO, Vector2(100.0, 0.0), Vector2(105.0, 0.0), 8.0), 1.0, "projectile: end-cap radius remains hittable")
	var thrower: ActorController = _runtime_actor(&"bottle_thrower", ActorController.Team.ENEMY, 150.0)
	var near_target: ActorController = _runtime_actor(&"jax", ActorController.Team.CREW, 200.0)
	var far_target: ActorController = _runtime_actor(&"rex", ActorController.Team.CREW, 240.0)
	near_target.registration_order = 2
	far_target.registration_order = 1
	var projectile: CombatProjectileType = track(CombatProjectileType.new()) as CombatProjectileType
	var lane_y: float = ActorController.lane_y(1)
	assert_true(projectile.configure(thrower.attack_definition.projectile_definition, thrower, thrower.attack_definition, Vector2(150.0, lane_y), Vector2(300.0, lane_y), 0), "projectile: authored bottle configures")
	var candidates: Array[ActorController] = [far_target, near_target]
	assert_eq(projectile.step(1.0, candidates), near_target, "projectile: earliest swept target wins independent of candidate order")
	assert_true(projectile.global_position.x < far_target.global_position.x, "projectile: sweep resolves before the farther target")


func test_elite_armour_and_boss_enrage_anti_lock_rules_apply_at_runtime() -> void:
	var enforcer: ActorController = _runtime_actor(&"viper_enforcer", ActorController.Team.ENEMY, 320.0)
	enforcer.apply_knockback(1.0, 100.0, 0.2)
	assert_false(enforcer.is_knocked_back(), "runtime elite: light force below armour is ignored")
	enforcer.apply_knockback(1.0, 200.0, 0.2)
	assert_true(enforcer.is_knocked_back(), "runtime elite: heavy force can break armour")

	var boss: ActorController = _runtime_actor(&"the_viper", ActorController.Team.ENEMY, 320.0)
	assert_false(boss.is_enraged(), "runtime boss: starts calm")
	assert_eq(boss.receive_damage(1081), 1081, "runtime boss: threshold-crossing damage applies")
	assert_true(boss.is_enraged(), "runtime boss: enrages below 40 percent health")
	assert_eq(boss.get_runtime_damage_multiplier(), 1.2, "runtime boss: enrage damage multiplier applies")
	assert_eq(boss.get_attack_speed_multiplier(), 1.25, "runtime boss: enrage speed multiplier applies")
	assert_true(boss.request_stun(5.0), "runtime boss: first stun can apply")
	boss.step_simulation(0.34)
	assert_eq(boss.state_machine.current_state, ActorStateMachine.State.STUNNED, "runtime boss: capped stun remains active just before 0.35 seconds")
	boss.step_simulation(0.02)
	assert_true(boss.state_machine.current_state != ActorStateMachine.State.STUNNED, "runtime boss: stun ends at the 0.35-second cap")
	assert_false(boss.request_stun(5.0), "runtime boss: two-second lockout blocks permanent stun-lock")
	assert_true(boss.get_control_lockout_remaining() > 1.6, "runtime boss: lockout outlasts the capped stun")
	boss.step_simulation(1.65)
	assert_true(boss.request_stun(5.0), "runtime boss: control becomes available after lockout")


func test_attack_position_registry_supports_six_unique_attackers() -> void:
	var registry: AttackPositionRegistry = track(AttackPositionRegistry.new()) as AttackPositionRegistry
	var target: ActorController = track(ActorController.new()) as ActorController
	target.global_position = Vector2(320.0, 180.0)
	var attackers: Array[ActorController] = []
	for index: int in range(7):
		var attacker: ActorController = track(ActorController.new()) as ActorController
		attacker.global_position = Vector2(200.0 + float(index), 180.0)
		attackers.append(attacker)
	for index: int in range(6):
		assert_true(registry.reserve(attackers[index], target, 100.0), "reservations: slot %d is available" % index)
	assert_eq(registry.get_snapshot().size(), 6, "reservations: six unique slots are authoritative")
	assert_false(registry.reserve(attackers[6], target, 100.0), "reservations: seventh attacker is rejected")


func _actor(actor_id: StringName) -> ActorController:
	var scene: PackedScene = ACTOR_CATALOGUE.get_scene(actor_id)
	var actor: ActorController = track(scene.instantiate()) as ActorController
	return actor


func _runtime_actor(actor_id: StringName, team: int, world_x: float) -> ActorController:
	var template: ActorController = _actor(actor_id)
	var actor: ActorController = track(ActorController.new()) as ActorController
	actor.actor_definition = template.actor_definition
	actor.attack_definition = template.attack_definition
	actor.special_attack_definitions = template.special_attack_definitions
	actor.team = team
	actor.initial_lane = 1
	actor.lane_index = 1
	actor.position = Vector2(world_x, ActorController.lane_y(1))
	actor.state_machine = ActorStateMachine.new()
	actor.health_component = HealthComponent.new()
	actor.attack_controller = AttackController.new()
	actor.attack_hitbox = Area2D.new()
	actor.actor_visual = ActorVisual.new()
	actor.status_controller = StatusController.new()
	actor.state_machine.name = "StateMachine"
	actor.health_component.name = "HealthComponent"
	actor.attack_controller.name = "AttackController"
	actor.attack_hitbox.name = "AttackHitbox"
	actor.actor_visual.name = "ActorVisual"
	actor.status_controller.name = "StatusController"
	actor.add_child(actor.state_machine)
	actor.add_child(actor.health_component)
	actor.add_child(actor.attack_controller)
	actor.add_child(actor.attack_hitbox)
	actor.add_child(actor.actor_visual)
	actor.add_child(actor.status_controller)
	# SceneTree normally calls this wiring seam. Focused out-of-tree fixtures call
	# it explicitly so health/enrage and attack-phase signals match runtime.
	actor._ready()
	return actor


func _spawn_ids(definition: EncounterDefinition) -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: EncounterSpawnEntryType in definition.spawn_entries:
		result.append(entry.actor_id)
	result.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	return result


func _minimum_count(definition: EncounterDefinition, actor_id: StringName) -> int:
	for entry: EncounterSpawnEntryType in definition.spawn_entries:
		if entry.actor_id == actor_id:
			return entry.minimum_count
	return -1


func _maximum_count(definition: EncounterDefinition, actor_id: StringName) -> int:
	for entry: EncounterSpawnEntryType in definition.spawn_entries:
		if entry.actor_id == actor_id:
			return entry.maximum_count
	return -1
