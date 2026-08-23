@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const SHOCK_STATUS: StatusEffectDefinition = preload("res://data/equipment/shock_status.tres")
const JAX_DEFINITION: ActorDefinition = preload("res://data/crew/jax.tres")
const STREET_PUNK_DEFINITION: ActorDefinition = preload("res://data/enemies/street_punk.tres")
const VIPER_DEFINITION: ActorDefinition = preload("res://data/enemies/the_viper.tres")
const JAX_ATTACK: AttackDefinition = preload("res://data/attacks/jax_basic_punch.tres")
const STREET_PUNK_ATTACK: AttackDefinition = preload("res://data/attacks/street_punk_basic_punch.tres")
const VIPER_ATTACK: AttackDefinition = preload("res://data/attacks/viper_melee_combo.tres")

const EQUIPMENT_ROLES: Dictionary = {
	&"chain_sneakers": "CHASE + KNOCKBACK",
	&"hacker_deck": "INTERVENTION TECH",
	&"magnetic_flail": "ENVIRONMENT CONTROL",
	&"reinforced_jacket": "SURVIVAL",
	&"serrated_wraps": "BLEED PRESSURE",
	&"shock_gloves": "SHOCK SPEED",
	&"spiked_bat": "HEAVY KNOCKBACK",
	&"steel_toe_boots": "ENVIRONMENT DAMAGE",
	&"voltaic_blade": "BLEED + SHOCK",
}
const SYNERGY_ROLES: Dictionary = {
	&"bleed_2": "STACKING DAMAGE",
	&"knockback_2": "ENVIRONMENT FINISHER",
	&"tech_2": "INTERVENTION SHOCK",
}


func suite_name() -> String:
	return "wp04_balance_runtime"


func test_all_items_and_synergies_have_valid_concise_combat_promises() -> void:
	_expect_equal(EQUIPMENT_CATALOGUE.validation_errors(), PackedStringArray(), "equipment metadata validates")
	_expect_equal(SYNERGY_CATALOGUE.validation_errors(), PackedStringArray(), "synergy metadata validates")
	for item: EquipmentDefinition in EQUIPMENT_CATALOGUE.get_sorted_items():
		_expect_equal(item.role_label, EQUIPMENT_ROLES.get(item.id, ""), "%s role is exact" % item.id)
		_expect_true(not item.combat_promise.strip_edges().is_empty(), "%s promise is present" % item.id)
		_expect_true(item.combat_promise.length() <= 160, "%s promise stays concise" % item.id)
	for synergy: SynergyDefinition in SYNERGY_CATALOGUE.get_sorted_synergies():
		_expect_equal(synergy.role_label, SYNERGY_ROLES.get(synergy.id, ""), "%s role is exact" % synergy.id)
		_expect_true(not synergy.combat_promise.strip_edges().is_empty(), "%s promise is present" % synergy.id)
		_expect_true(synergy.combat_promise.length() <= 160, "%s promise stays concise" % synergy.id)


func test_shock_has_inherent_environment_bonus_only_on_intervention_hits() -> void:
	_expect_approx(SHOCK_STATUS.intervention_damage_taken_bonus, 0.25, "Shock owns +25% intervention damage taken")
	var system: SynergySystem = _new_system()
	var director: CombatDirector = _new_combat_director(system, 40401)
	var jax: ActorController = _new_actor(JAX_DEFINITION, JAX_ATTACK, ActorController.Team.CREW, 220.0)
	var direct_target: ActorController = _new_actor(STREET_PUNK_DEFINITION, STREET_PUNK_ATTACK, ActorController.Team.ENEMY, 260.0)
	var collision_target: ActorController = _new_actor(STREET_PUNK_DEFINITION, STREET_PUNK_ATTACK, ActorController.Team.ENEMY, 300.0)
	var intervention_target: ActorController = _new_actor(STREET_PUNK_DEFINITION, STREET_PUNK_ATTACK, ActorController.Team.ENEMY, 340.0)
	for actor: ActorController in [jax, direct_target, collision_target, intervention_target]:
		director.register_actor(actor)
	_expect_true(direct_target.apply_status(&"shock", 1, 3.0), "direct target is Shocked")
	_expect_true(collision_target.apply_status(&"shock", 1, 3.0), "collision target is Shocked")
	_expect_true(intervention_target.apply_status(&"shock", 1, 3.0), "intervention target is Shocked")
	_expect_equal(director._resolve_direct_hit(jax, direct_target, JAX_ATTACK), 20, "ordinary attack gets no inherent Shock bonus")
	_expect_equal(
		director.request_environmental_collision(&"wall", jax, collision_target, collision_target.global_position, 100.0),
		6,
		"ordinary collision gets no inherent Shock bonus"
	)
	_expect_equal(
		director.request_environmental_hit(&"hydrant", intervention_target, Vector2.ZERO, 18, 1.0, 0.1),
		23,
		"Environment intervention receives the inherent Shock bonus"
	)


func test_equipment_attack_speed_scales_every_attack_phase_but_enrage_does_not() -> void:
	var system: SynergySystem = _new_system()
	_expect_true(system.equip_by_id(&"shock_gloves", 0), "speed build equips gloves")
	_expect_true(system.equip_by_id(&"chain_sneakers", 1), "speed build equips sneakers")
	var director: CombatDirector = _new_combat_director(system, 40402)
	var jax: ActorController = _new_actor(JAX_DEFINITION, JAX_ATTACK, ActorController.Team.CREW, 220.0)
	director.register_actor(jax)
	_expect_approx(jax.get_build_attack_speed_multiplier(), 1.14, "crew build speed aggregates")
	jax._start_planned_attack(JAX_ATTACK)
	_expect_approx(jax.attack_controller.phase_remaining, JAX_ATTACK.windup_time / 1.14, "build speed scales windup")
	jax.attack_controller.step(jax.attack_controller.phase_remaining)
	_expect_approx(jax.attack_controller.phase_remaining, JAX_ATTACK.active_time / 1.14, "build speed scales active")
	jax.attack_controller.step(jax.attack_controller.phase_remaining)
	_expect_approx(jax.attack_controller.phase_remaining, JAX_ATTACK.recovery_time / 1.14, "build speed scales recovery")

	var boss: ActorController = _new_actor(VIPER_DEFINITION, VIPER_ATTACK, ActorController.Team.ENEMY, 360.0)
	boss._enraged = true
	_expect_approx(boss.get_attack_speed_multiplier(), 1.25, "boss enrage still accelerates cooldown")
	_expect_approx(boss.get_build_attack_speed_multiplier(), 1.0, "boss enrage is not build phase speed")
	boss._start_planned_attack(VIPER_ATTACK)
	_expect_approx(boss.attack_controller.phase_remaining, VIPER_ATTACK.windup_time, "boss enrage preserves authored windup")


func test_serrated_wraps_uses_shared_on_hit_bleed_and_chain_sneakers_extend_knockback() -> void:
	var system: SynergySystem = _new_system()
	var wraps: EquipmentDefinition = system.get_catalogue_item(&"serrated_wraps")
	var bleed_effect: TriggeredEffectDefinition = _effect(wraps, &"serrated_wraps_bleed")
	_expect_true(bleed_effect != null, "Serrated Wraps has a typed triggered effect")
	_expect_equal(bleed_effect.trigger, TriggeredEffectDefinition.Trigger.ON_HIT, "wraps trigger on every hit class")
	_expect_equal(bleed_effect.status_id, &"bleed", "wraps apply Bleed")
	_expect_equal(bleed_effect.chance_basis_points, 3500, "wraps use exact 35% chance")
	_expect_approx(bleed_effect.duration_seconds, 4.0, "wraps use exact four-second duration")
	var sneakers: EquipmentDefinition = system.get_catalogue_item(&"chain_sneakers")
	_expect_approx(_modifier_amount(sneakers, &"knockback_distance"), 0.10, "sneakers add 10% knockback distance")
	_expect_true(is_nan(_modifier_amount(sneakers, &"knockback_followup")), "sneakers no longer add hidden follow-up damage")


func _new_system() -> SynergySystem:
	var system: SynergySystem = track(SynergySystem.new()) as SynergySystem
	system.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	return system


func _new_combat_director(system: SynergySystem, seed: int) -> CombatDirector:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams.reset_for_seed(seed)
	var director: CombatDirector = track(CombatDirector.new()) as CombatDirector
	director._ready()
	director.set_physics_process(false)
	director.configure_build_system(system, streams)
	return director


func _new_actor(
	definition: ActorDefinition,
	attack: AttackDefinition,
	actor_team: int,
	world_x: float
) -> ActorController:
	var actor: ActorController = track(ActorController.new()) as ActorController
	actor.actor_definition = definition
	actor.attack_definition = attack
	actor.team = actor_team
	actor.initial_lane = 1
	actor.lane_index = 1
	actor.global_position = Vector2(world_x, ActorController.lane_y(1))
	actor.state_machine = ActorStateMachine.new()
	actor.health_component = HealthComponent.new()
	actor.attack_controller = AttackController.new()
	actor.attack_hitbox = Area2D.new()
	actor.actor_visual = ActorVisual.new()
	actor.status_controller = StatusController.new()
	actor.add_child(actor.state_machine)
	actor.add_child(actor.health_component)
	actor.add_child(actor.attack_controller)
	actor.add_child(actor.attack_hitbox)
	actor.add_child(actor.actor_visual)
	actor.add_child(actor.status_controller)
	actor.state_machine.state_changed.connect(actor._on_state_machine_changed)
	actor.health_component.health_changed.connect(actor._on_health_component_changed)
	actor.health_component.depleted.connect(actor._on_health_depleted)
	actor.attack_controller.phase_changed.connect(actor._on_attack_phase_changed)
	actor.attack_controller.active_started.connect(actor._on_attack_active_started)
	actor.attack_controller.attack_finished.connect(actor._on_attack_finished)
	actor._ensure_status_controller()
	actor.attack_hitbox.monitorable = false
	actor.attack_hitbox.monitoring = false
	actor.initialize_runtime()
	actor.set_process(false)
	return actor


func _effect(item: EquipmentDefinition, effect_id: StringName) -> TriggeredEffectDefinition:
	for effect: TriggeredEffectDefinition in item.triggered_effects:
		if effect.id == effect_id:
			return effect
	return null


func _modifier_amount(item: EquipmentDefinition, stat_id: StringName) -> float:
	for modifier: EquipmentModifierDefinition in item.modifiers:
		if modifier.stat_id == stat_id:
			return modifier.amount
	return NAN


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(absf(actual - expected) <= 0.001, "%s (expected %.3f, got %.3f)" % [context, expected, actual])
