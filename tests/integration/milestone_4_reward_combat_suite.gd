@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const EQUIPMENT_CATALOGUE: EquipmentCatalogue = preload(
	"res://data/equipment/milestone_4_equipment_catalogue.tres"
)
const SYNERGY_CATALOGUE: SynergyCatalogue = preload(
	"res://data/synergies/milestone_4_synergy_catalogue.tres"
)
const JAX_DEFINITION: ActorDefinition = preload("res://data/crew/jax.tres")
const STREET_PUNK_DEFINITION: ActorDefinition = preload("res://data/enemies/street_punk.tres")
const JAX_ATTACK: AttackDefinition = preload("res://data/attacks/jax_basic_punch.tres")
const STREET_PUNK_ATTACK: AttackDefinition = preload("res://data/attacks/street_punk_basic_punch.tres")
const STREET_REWARD: StandardRewardDefinition = preload("res://data/rewards/street_cache.tres")
const SORTED_EQUIPMENT_IDS: Array[StringName] = [
	&"chain_sneakers",
	&"hacker_deck",
	&"magnetic_flail",
	&"reinforced_jacket",
	&"serrated_wraps",
	&"shock_gloves",
	&"spiked_bat",
	&"steel_toe_boots",
	&"voltaic_blade",
]


class IntentCapture:
	extends RefCounted

	var count: int = 0
	var choice_index: int = -1
	var destination: StringName = &""
	var slot_index: int = -1
	var backpack_slot: int = -1

	func on_acquisition(
		_encounter_instance_id: int,
		_choice_token: int,
		choice: int,
		new_destination: StringName,
		slot: int,
		new_backpack_slot: int,
		_replace_confirmed: bool,
		_expected_revision: int
	) -> void:
		count += 1
		choice_index = choice
		destination = new_destination
		slot_index = slot
		backpack_slot = new_backpack_slot


func suite_name() -> String:
	return "milestone_4_reward_combat"


func test_equipment_choices_use_only_equipment_stream_and_stable_candidates() -> void:
	var system: SynergySystem = _new_system()
	var streams: RunRandomStreams = _new_streams(4401)
	var rewards: RewardDirector = _new_rewards(system, streams)
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(1)
	_expect_equal(choices.size(), 3, "stream: exactly three reward choices")
	_expect_equal(rewards.get_last_equipment_candidate_order(), SORTED_EQUIPMENT_IDS, "stream: stable id order")
	for stream_name: StringName in streams.get_declared_stream_names():
		_expect_equal(
			streams.get_draw_count(stream_name),
			3 if stream_name == RunRandomStreams.STREAM_EQUIPMENT else 0,
			"stream: equipment generation draw ownership for %s" % stream_name
		)
	_expect_equal(streams.get_random_schema_version(), 1, "stream: schema unchanged")


func test_same_seed_equipment_choices_are_reproducible() -> void:
	var left: Array[StringName] = _choice_ids(_prepare_choices_for_seed(4402))
	var right: Array[StringName] = _choice_ids(_prepare_choices_for_seed(4402))
	_expect_equal(left, right, "reproducibility: same seed same ordered choices")


func test_different_seed_variation_over_documented_thirty_two_seed_sample() -> void:
	var sequences: Dictionary[String, bool] = {}
	for seed: int in range(1, 33):
		sequences[JSON.stringify(_choice_ids(_prepare_choices_for_seed(seed)))] = true
	_expect_true(
		sequences.size() >= 16,
		"variation: at least 16 unique choice triples across seeds 1 through 32 (got %d)" % sequences.size()
	)


func test_cosmetic_draws_do_not_change_equipment_or_other_gameplay_choices() -> void:
	var baseline_system: SynergySystem = _new_system()
	var noisy_system: SynergySystem = _new_system()
	var baseline_streams: RunRandomStreams = _new_streams(4403)
	var noisy_streams: RunRandomStreams = _new_streams(4403)
	for _draw_index: int in range(200):
		noisy_streams.draw_index(RunRandomStreams.STREAM_COSMETIC, 97)
	var baseline_rewards: RewardDirector = _new_rewards(baseline_system, baseline_streams)
	var noisy_rewards: RewardDirector = _new_rewards(noisy_system, noisy_streams)
	_expect_equal(
		_choice_ids(baseline_rewards.prepare_equipment_choices(1)),
		_choice_ids(noisy_rewards.prepare_equipment_choices(1)),
		"isolation: cosmetic activity leaves equipment choices unchanged"
	)
	_expect_equal(
		baseline_streams.draw_index(RunRandomStreams.STREAM_ENCOUNTERS, 17),
		noisy_streams.draw_index(RunRandomStreams.STREAM_ENCOUNTERS, 17),
		"isolation: other gameplay streams remain unchanged"
	)


func test_equipped_items_are_filtered_before_stable_choice_draws() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"spiked_bat", 0)
	var streams: RunRandomStreams = _new_streams(4404)
	var rewards: RewardDirector = _new_rewards(system, streams)
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(1)
	_expect_false(_choice_ids(choices).has(&"spiked_bat"), "filter: equipped id excluded")
	var expected_order: Array[StringName] = SORTED_EQUIPMENT_IDS.duplicate()
	expected_order.erase(&"spiked_bat")
	_expect_equal(rewards.get_last_equipment_candidate_order(), expected_order, "filter: remaining ids stable")


func test_equipment_choice_and_paired_standard_reward_apply_exactly_once() -> void:
	var system: SynergySystem = _new_system()
	var streams: RunRandomStreams = _new_streams(4405)
	var rewards: RewardDirector = _new_rewards(system, streams)
	var standard_catalogue: Array[StandardRewardDefinition] = [STREET_REWARD]
	rewards.standard_rewards = standard_catalogue
	var allowed_ids: Array[StringName] = [STREET_REWARD.id]
	_expect_equal(rewards.prepare_standard_reward(7, 0, allowed_ids), STREET_REWARD, "application: standard prepared")
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(7)
	_expect_true(rewards.apply_equipment_choice(7, 0, 0), "application: first choice applies")
	_expect_false(rewards.apply_equipment_choice(7, 0, 0), "application: repeated choice rejected")
	_expect_equal(system.get_equipped_item(0), choices[0], "application: exactly one selected item")
	_expect_equal(rewards.get_coin_total(), STREET_REWARD.coins, "application: standard coins exactly once")
	_expect_equal(rewards.get_scrap_total(), STREET_REWARD.scrap, "application: standard scrap exactly once")
	_expect_equal(rewards.get_debug_snapshot().get("equipment_rewards_applied"), 1, "application: one latch")


func test_hud_selects_in_one_click_then_confirms_one_intent_and_controls_fit() -> void:
	var system: SynergySystem = _new_system()
	var streams: RunRandomStreams = _new_streams(4406)
	var rewards: RewardDirector = _new_rewards(system, streams)
	var choices: Array[EquipmentDefinition] = rewards.prepare_equipment_choices(1)
	var previews: Array[Dictionary] = []
	for choice_index: int in range(choices.size()):
		var by_slot: Array[Dictionary] = []
		for slot_index: int in range(SynergySystem.SLOT_COUNT):
			by_slot.append(rewards.get_equipment_choice_preview(1, choice_index, slot_index))
		previews.append({"by_slot": by_slot})
	var test_root: Node = track(Node.new()) as Node
	test_root.process_mode = Node.PROCESS_MODE_DISABLED
	var hud_scene: PackedScene = ResourceLoader.load(
		"res://scenes/ui/game_hud.tscn",
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE
	) as PackedScene
	var hud: GameHUD = track(hud_scene.instantiate()) as GameHUD
	test_root.add_child(hud)
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	_expect_true(scene_tree != null, "one click: editor SceneTree is available")
	if scene_tree == null:
		return
	scene_tree.root.add_child(test_root)
	hud.present_build_snapshot(system.get_snapshot())
	hud.present_equipment_reward(1, choices, previews)
	var capture: IntentCapture = IntentCapture.new()
	hud.equipment_acquisition_requested.connect(capture.on_acquisition)
	hud.reward_choice_01.pressed.emit()
	hud.reward_choice_01.pressed.emit()
	_expect_equal(capture.count, 0, "safe selection: item click does not mutate inventory")
	_expect_equal(hud.get_selected_reward_choice(), 0, "one click: first item becomes selected")
	hud.reward_target_01.pressed.emit()
	hud.reward_confirm_button.pressed.emit()
	hud.reward_confirm_button.pressed.emit()
	_expect_equal(capture.count, 1, "confirmation: in-flight guard forwards one intent")
	_expect_equal(capture.choice_index, 0, "confirmation: first choice index")
	_expect_equal(capture.destination, SynergySystem.AREA_EQUIPPED, "confirmation: active destination")
	_expect_equal(capture.slot_index, 0, "confirmation: selected empty active slot")
	_expect_equal(capture.backpack_slot, -1, "confirmation: no outgoing storage needed")
	_expect_true(hud.is_equipment_reward_visible(), "confirmation: authority dismisses modal, not UI press")
	_expect_controls_within_panel(hud.equipment_reward_panel, "layout: reward modal")
	_expect_controls_within_panel(hud.get_node("Root/BuildPanel") as Panel, "layout: compact build")
	hud.dismiss_equipment_reward()
	_expect_false(hud.is_equipment_reward_visible(), "confirmation: authoritative dismissal clears modal")


func test_equipment_health_speed_attack_speed_and_knockback_received_are_functional() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"reinforced_jacket", 0)
	system.equip_by_id(&"steel_toe_boots", 1)
	system.equip_by_id(&"chain_sneakers", 2)
	var director: CombatDirector = _new_combat_director(system, _new_streams(4407))
	var equipped_jax: ActorController = _new_actor(true, 220.0)
	director.register_actor(equipped_jax)
	_expect_equal(equipped_jax.health_component.maximum_health, 624, "health: jacket grants +20%")
	_expect_approx(equipped_jax.get_movement_speed(), 129.92, "speed: boots + sneakers")
	_expect_approx(equipped_jax.get_attack_speed_multiplier(), 1.06, "attack speed: sneakers")
	var baseline_jax: ActorController = _new_actor(true, 220.0)
	var baseline_start: float = baseline_jax.global_position.x
	baseline_jax.apply_knockback(1.0, 100.0, 0.10)
	baseline_jax.step_simulation(0.05)
	var equipped_start: float = equipped_jax.global_position.x
	equipped_jax.apply_knockback(1.0, 100.0, 0.10)
	equipped_jax.step_simulation(0.05)
	_expect_true(
		equipped_jax.global_position.x - equipped_start < baseline_jax.global_position.x - baseline_start,
		"knockback received: jacket reduces displacement"
	)


func test_heavy_damage_and_damage_against_bleeding_change_combat_results() -> void:
	var baseline_damage: int = _first_attack_damage(_new_system(), 4408, false)
	var bat_system: SynergySystem = _new_system()
	bat_system.equip_by_id(&"spiked_bat", 0)
	var heavy_damage: int = _first_attack_damage(bat_system, 4408, false)
	_expect_equal(baseline_damage, 20, "damage: baseline authored hit")
	_expect_equal(heavy_damage, 25, "damage: Spiked Bat +25% heavy hit")
	var bleed_system: SynergySystem = _new_system()
	bleed_system.equip_by_id(&"spiked_bat", 0)
	bleed_system.equip_by_id(&"serrated_wraps", 1)
	var bleeding_damage: int = _first_attack_damage(bleed_system, 4408, true)
	_expect_equal(bleeding_damage, 32, "damage: heavy plus Bleed build bonus")


func test_voltaic_blade_applies_bleed_with_stack_limit_and_visible_ticks() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"voltaic_blade", 0)
	var director: CombatDirector = _new_combat_director(system, _new_streams(4409))
	var jax: ActorController = _new_actor(true, 220.0)
	var enemy: ActorController = _new_actor(false, 260.0)
	director.register_actor(jax)
	director.register_actor(enemy)
	var starting_health: int = enemy.health_component.current_health
	_advance_until_damaged(director, enemy, starting_health)
	_expect_true(enemy.has_status(&"bleed"), "Bleed: Voltaic hit applies status")
	_expect_equal(enemy.get_status_stacks(&"bleed"), 1, "Bleed: one initial stack")
	var after_hit: int = enemy.health_component.current_health
	enemy.status_controller.step(1.01)
	_expect_equal(enemy.health_component.current_health, after_hit - 2, "Bleed: 2 damage per stack tick")
	var bleed_build: SynergySystem = _new_system()
	bleed_build.equip_by_id(&"spiked_bat", 0)
	bleed_build.equip_by_id(&"serrated_wraps", 1)
	for _application: int in range(10):
		enemy.apply_status(&"bleed", 1, 4.0, 3 + int(bleed_build.get_flat_modifier(&"bleed_maximum_stacks")))
	_expect_equal(enemy.get_status_stacks(&"bleed"), 6, "Bleed: wraps plus synergy raise maximum to six")


func test_shock_duration_and_voltaic_shock_interaction_change_environmental_damage() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"voltaic_blade", 0)
	system.equip_by_id(&"shock_gloves", 1)
	_expect_true(system.is_synergy_active(&"tech_2"), "Shock: Voltaic plus gloves activates Tech")
	var director: CombatDirector = _new_combat_director(system, _new_streams(4410))
	var enemy: ActorController = _new_actor(false, 260.0)
	director.register_actor(enemy)
	var shock_duration: float = 3.0 + system.get_flat_modifier(&"shock_duration")
	_expect_true(enemy.apply_status(&"shock", 1, shock_duration), "Shock: status applies")
	_expect_approx(enemy.status_controller.get_remaining(&"shock"), 4.5, "Shock: Tech adds 1.5 seconds")
	var starting_health: int = enemy.health_component.current_health
	director.request_environmental_hit(&"test", enemy, Vector2(220.0, enemy.global_position.y), 18, 1.0, 0.1)
	_expect_equal(starting_health - enemy.health_component.current_health, 26, "Shock: inherent +25% plus Voltaic +20% interaction damage")


func test_knockback_build_changes_environmental_damage_and_force() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"steel_toe_boots", 1)
	var director: CombatDirector = _new_combat_director(system, _new_streams(4411))
	var enemy: ActorController = _new_actor(false, 260.0)
	director.register_actor(enemy)
	var starting_health: int = enemy.health_component.current_health
	var starting_x: float = enemy.global_position.x
	director.request_environmental_hit(&"test", enemy, Vector2(220.0, enemy.global_position.y), 18, 100.0, 0.1)
	_expect_equal(starting_health - enemy.health_component.current_health, 25, "Knockback: +40% environmental damage rounds to 25")
	enemy.step_simulation(0.05)
	_expect_true(enemy.global_position.x - starting_x > 5.5, "Knockback: +35% force creates visibly longer displacement")


func test_tech_intervention_cooldown_is_finite_and_does_not_mutate_run_pressure() -> void:
	var system: SynergySystem = _new_system()
	system.equip_by_id(&"shock_gloves", 0)
	system.equip_by_id(&"hacker_deck", 1)
	var run: RunDirector = track(RunDirector.new()) as RunDirector
	run._ready()
	run.start_run(4412, true)
	var starting_heat: int = run.heat
	var starting_pressure: float = run.night_pressure
	var combat: CombatDirector = _new_combat_director(system, run.get_random_streams())
	var hydrant: FireHydrantController = track(FireHydrantController.new()) as FireHydrantController
	hydrant.configure(combat, Vector2.ZERO)
	hydrant.set_cooldown_multiplier(1.0 + system.get_percent_modifier(&"intervention_cooldown"))
	_expect_approx(hydrant.get_cooldown_duration(), 6.0, "Tech: 8s authored cooldown reduced by 25%")
	hydrant._cooldown_remaining = hydrant.get_cooldown_duration()
	hydrant.step_cooldown(6.0)
	_expect_approx(hydrant.get_cooldown_remaining(), 0.0, "Tech: cooling remains finite")
	_expect_equal(run.heat, starting_heat, "Tech: equipment change does not mutate Heat")
	_expect_approx(run.night_pressure, starting_pressure, "Tech: equipment change does not mutate Night Pressure")


func test_clean_restart_clears_equipment_synergies_status_reward_modal_and_stream_state() -> void:
	var system: SynergySystem = _new_system()
	var streams: RunRandomStreams = _new_streams(4413)
	var rewards: RewardDirector = _new_rewards(system, streams)
	system.equip_by_id(&"spiked_bat", 0)
	system.equip_by_id(&"steel_toe_boots", 1)
	var status: StatusController = track(StatusController.new()) as StatusController
	status.apply_status(&"bleed", 2, 4.0, 5)
	rewards.prepare_equipment_choices(1)
	_expect_true(system.is_synergy_active(&"knockback_2"), "restart: precondition synergy")
	_expect_true(status.has_status(&"bleed"), "restart: precondition status")
	_expect_true(streams.get_draw_count(RunRandomStreams.STREAM_EQUIPMENT) > 0, "restart: precondition draws")
	system.reset_for_run()
	status.clear_all()
	rewards.reset_for_run()
	streams.reset_for_seed(4413)
	_expect_equal(system.get_equipped_items().size(), 0, "restart: equipment empty")
	_expect_equal(system.get_active_synergies().size(), 0, "restart: synergies empty")
	_expect_equal(system.get_percent_modifiers().size(), 0, "restart: modifiers empty")
	_expect_false(status.has_status(&"bleed"), "restart: status empty")
	_expect_equal(rewards.get_debug_snapshot().get("pending_equipment_encounter_id"), -1, "restart: reward modal state empty")
	for stream_name: StringName in streams.get_declared_stream_names():
		_expect_equal(streams.get_draw_count(stream_name), 0, "restart: %s stream reset" % stream_name)


func _new_system() -> SynergySystem:
	var system: SynergySystem = track(SynergySystem.new()) as SynergySystem
	system.configure(EQUIPMENT_CATALOGUE, SYNERGY_CATALOGUE)
	return system


func _new_streams(seed: int) -> RunRandomStreams:
	var streams: RunRandomStreams = track(RunRandomStreams.new()) as RunRandomStreams
	streams.reset_for_seed(seed)
	return streams


func _new_rewards(system: SynergySystem, streams: RunRandomStreams) -> RewardDirector:
	var rewards: RewardDirector = track(RewardDirector.new()) as RewardDirector
	rewards.configure_random_streams(streams)
	rewards.configure_equipment(system)
	return rewards


func _prepare_choices_for_seed(seed: int) -> Array[EquipmentDefinition]:
	var system: SynergySystem = _new_system()
	var rewards: RewardDirector = _new_rewards(system, _new_streams(seed))
	return rewards.prepare_equipment_choices(1)


func _choice_ids(choices: Array[EquipmentDefinition]) -> Array[StringName]:
	var result: Array[StringName] = []
	for item: EquipmentDefinition in choices:
		result.append(item.id)
	return result


func _new_combat_director(
	system: SynergySystem,
	streams: RunRandomStreams
) -> CombatDirector:
	var director: CombatDirector = track(CombatDirector.new()) as CombatDirector
	director._ready()
	director.set_physics_process(false)
	director.configure_build_system(system, streams)
	return director


func _new_actor(is_crew: bool, world_x: float) -> ActorController:
	var actor: ActorController = track(ActorController.new()) as ActorController
	actor.actor_definition = JAX_DEFINITION if is_crew else STREET_PUNK_DEFINITION
	actor.attack_definition = JAX_ATTACK if is_crew else STREET_PUNK_ATTACK
	actor.team = ActorController.Team.CREW if is_crew else ActorController.Team.ENEMY
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
	# Editor-hosted authority fixtures remain out of the live scene tree, so wire
	# the same component signals that ActorController._ready() owns at runtime.
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


func _first_attack_damage(
	system: SynergySystem,
	seed: int,
	target_starts_bleeding: bool
) -> int:
	var director: CombatDirector = _new_combat_director(system, _new_streams(seed))
	var jax: ActorController = _new_actor(true, 220.0)
	var enemy: ActorController = _new_actor(false, 260.0)
	if target_starts_bleeding:
		enemy.apply_status(&"bleed", 1, 4.0, 6)
	director.register_actor(jax)
	director.register_actor(enemy)
	var starting_health: int = enemy.health_component.current_health
	_advance_until_damaged(director, enemy, starting_health)
	return starting_health - enemy.health_component.current_health


func _advance_until_damaged(
	director: CombatDirector,
	target: ActorController,
	starting_health: int
) -> void:
	for _step_index: int in range(80):
		director.step_simulation(0.05)
		if target.health_component.current_health < starting_health:
			return


func _expect_controls_within_panel(panel: Panel, context: String) -> void:
	for child: Node in panel.get_children():
		var control: Control = child as Control
		if control == null:
			continue
		_expect_true(control.position.x >= 0.0 and control.position.y >= 0.0, "%s: %s starts inside" % [context, child.name])
		_expect_true(
			control.position.x + control.size.x <= panel.size.x + 0.01
			and control.position.y + control.size.y <= panel.size.y + 0.01,
			"%s: %s ends inside (child %s + %s, panel %s)" % [
				context,
				child.name,
				control.position,
				control.size,
				panel.size,
			]
		)


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])


func _expect_approx(actual: float, expected: float, context: String) -> void:
	assert_true(
		absf(actual - expected) <= 0.001,
		"%s (expected %.3f, got %.3f)" % [context, expected, actual]
	)
