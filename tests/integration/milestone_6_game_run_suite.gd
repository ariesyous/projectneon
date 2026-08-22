@tool
extends McpTestSuite

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const STANDARD_ENCOUNTER: EncounterDefinition = preload(
	"res://data/encounters/alley_scuffle.tres"
)
const REWARD_EQUIPMENT: EquipmentDefinition = preload(
	"res://data/equipment/spiked_bat.tres"
)
const REWARD_CARD: DistrictCardDefinition = preload(
	"res://data/cards/arcade.tres"
)
const VIPER_CHARGE: AttackDefinition = preload("res://data/attacks/viper_charge.tres")
const VIPER_SUMMON: AttackDefinition = preload("res://data/attacks/viper_summon.tres")
const VIPER_AREA: AttackDefinition = preload("res://data/attacks/viper_area_warning.tres")

class GameFixture:
	extends RefCounted

	var viewport: SubViewport
	var game: GameRun
	var app: NeonAppState
	var service: ProfileSaveService
	var profile_path: String = ""


var _test_paths: Array[String] = []
var _path_nonce: int = 0


func suite_name() -> String:
	return "milestone_6_game_run"


func setup() -> void:
	_test_paths.clear()


func teardown() -> void:
	for path: String in _test_paths:
		_remove_path(path)
		_remove_path(path + ".tmp")
		_remove_path(path + ".bak")


func test_main_scene_waits_for_valid_menu_selection_without_gameplay_draws() -> void:
	var fixture: GameFixture = _new_game(false)
	_expect_equal(
		fixture.game.run_director.current_state,
		RunDirector.RunState.INITIALIZING,
		"menu: no run advances behind the front end"
	)
	_expect_true(fixture.game.vertical_slice_overlay.is_main_menu_visible(), "menu: front end visible")
	_expect_false(fixture.game.game_hud.visible, "menu: run HUD hidden")
	_expect_equal(
		fixture.game.vertical_slice_overlay.get_selected_crew_id(),
		&"jax",
		"menu: production profile selects its one unlocked crew"
	)
	_expect_false(fixture.game.vertical_slice_overlay.zoey_button.disabled, "menu: WP02 exposes Zoey from first launch")
	_expect_false(fixture.game.vertical_slice_overlay.rex_button.disabled, "menu: WP02 exposes Rex from first launch")
	var draw_counts: Dictionary = fixture.game.run_director.get_random_streams().get_debug_snapshot().get(
		"draw_counts",
		{}
	)
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		_expect_equal(int(draw_counts.get(stream_name, 0)), 0, "menu: %s stream untouched" % stream_name)


func test_release_access_latches_before_opening_draw_and_applies_one_authored_starter() -> void:
	var fixture: GameFixture = _new_game(false)
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	_expect_equal(fixture.game.run_director.current_state, RunDirector.RunState.INTRO, "start: run begins")
	var access: RunContentAccessSnapshot = fixture.game.get_active_content_access_snapshot()
	_expect_equal(access.selected_crew_id, &"jax", "start: selected crew ID latched")
	_expect_false(access.allowed_equipment_ids.has(&"hacker_deck"), "start: gated existing gear excluded")
	_expect_false(access.allowed_card_ids.has(&"gang_hideout"), "start: gated existing card excluded")
	_expect_equal(
		fixture.game.reward_director.get_active_equipment_access_ids(),
		access.allowed_equipment_ids,
		"start: reward authority latches exact equipment access"
	)
	_expect_equal(
		fixture.game.card_system.get_active_access_ids(),
		access.allowed_card_ids,
		"start: card authority latches exact card access"
	)
	_expect_equal(fixture.game.card_system.get_hand().size(), 0, "start: INTRO performs no hidden card draw")
	_expect_true(fixture.game.run_director.complete_intro(), "start: intro reaches focused PLAN")
	_expect_equal(fixture.game.card_system.get_hand().size(), 2, "start: PLAN exposes exactly two choices")
	_expect_equal(fixture.game.run_director.current_state, RunDirector.RunState.PAUSED, "start: PLAN owns the reading pause")
	var permanent_crew: Array[ActorController] = fixture.game.encounter_controller.get_permanent_crew()
	_expect_equal(permanent_crew.size(), 1, "start: exactly one permanent crew actor")
	_expect_equal(permanent_crew[0].definition_id(), &"jax", "start: Jax scene selected")
	_expect_equal(
		fixture.game.synergy_system.get_snapshot().get("owned_count", 0),
		1,
		"start: vertical slice enters with exactly one basic equipment item"
	)
	_expect_equal(
		fixture.game.synergy_system.get_equipped_items()[0].id,
		&"spiked_bat",
		"start: Jax receives his authored existing-catalogue starter"
	)


func test_same_seed_reuses_exact_access_snapshot_and_new_seed_recaptures() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.zoey_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	var first_seed: int = fixture.game.run_director.run_seed
	var first_identity: int = fixture.game.get_active_content_access_identity()
	var first_signature: String = fixture.game.get_active_content_access_snapshot().signature()
	fixture.game.vertical_slice_overlay.restart_same_seed_requested.emit()
	_expect_equal(fixture.game.run_director.run_seed, first_seed, "replay: exact seed reused")
	_expect_equal(
		fixture.game.get_active_content_access_identity(),
		first_identity,
		"replay: exact same access object reused"
	)
	_expect_equal(
		fixture.game.get_selected_crew_actor().definition_id(),
		&"zoey",
		"replay: selected crew respawned"
	)
	_expect_equal(
		fixture.game.synergy_system.get_equipped_items()[0].id,
		&"shock_gloves",
		"replay: Zoey's exact authored starter resets deterministically"
	)
	fixture.game.vertical_slice_overlay.restart_new_seed_requested.emit()
	_expect_true(fixture.game.run_director.run_seed != first_seed, "new run: new seed generated")
	_expect_true(
		fixture.game.get_active_content_access_identity() != first_identity,
		"new run: profile access recaptured"
	)
	_expect_equal(
		fixture.game.get_active_content_access_snapshot().signature(),
		first_signature,
		"new run: unchanged profile yields same stable access signature"
	)


func test_numbered_intervention_keys_share_authority_and_backup_never_replaces_crew_hud() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.zoey_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	_expect_true(_confirm_current_district_plan(fixture.game) != null, "keys: first District Plan confirms")
	var hydrant_before: Dictionary = fixture.game.fire_hydrant_controller.get_snapshot()
	var backup_before: Dictionary = fixture.game.call_backup_controller.get_snapshot()
	_press_key(fixture.game, KEY_1)
	_press_key(fixture.game, KEY_2)
	_expect_equal(
		fixture.game.fire_hydrant_controller.get_snapshot().get("cooldown_remaining"),
		hydrant_before.get("cooldown_remaining"),
		"keys: invalid Hydrant spends no cooldown"
	)
	_expect_equal(
		fixture.game.call_backup_controller.get_charges_remaining(),
		int(backup_before.get("charges_remaining", 0)),
		"keys: invalid Backup spends no charge"
	)
	var subway_before: int = fixture.game.cooling_controller.get_subway_charges()
	_press_key(fixture.game, KEY_3)
	_expect_equal(
		fixture.game.cooling_controller.get_subway_charges(),
		subway_before - 1,
		"keys: Subway consumes exactly one finite charge"
	)
	var combat_fixture: GameFixture = _new_game(true)
	combat_fixture.game.vertical_slice_overlay.zoey_button.pressed.emit()
	combat_fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	combat_fixture.game.run_director.complete_intro()
	_expect_true(
		_begin_direct_planned_encounter(combat_fixture.game, STANDARD_ENCOUNTER, &"m6_backup_probe"),
		"keys: test enters an eligible non-boss fight"
	)
	_press_key(combat_fixture.game, KEY_2)
	_expect_equal(combat_fixture.game.call_backup_controller.get_active_allies().size(), 2, "keys: Backup spawns two")
	_expect_contains(
		(combat_fixture.game.game_hud.get_node("Root/CrewPanel/CrewName") as Label).text,
		"ZOEY",
		"HUD: temporary allies never replace selected permanent crew"
	)
	_expect_contains(
		(combat_fixture.game.game_hud.get_node("Root/HelpPanel/AutoHelp") as Label).text,
		"ZOEY AUTO-FIGHTS",
		"HUD: Help names the selected crew"
	)
	_expect_contains(
		combat_fixture.game.debug_overlay.jax_debug_label.text,
		"ZOEY",
		"F1: debug actor status names the selected crew"
	)
	_expect_contains(combat_fixture.game.game_hud.backup_button.text, "2 ALLIES", "HUD: allies have separate status")
	var first_ally: ActorController = combat_fixture.game.call_backup_controller.get_active_allies()[0] as ActorController
	first_ally.receive_damage(100000)
	_expect_equal(
		combat_fixture.game.call_backup_controller.get_active_allies().size(),
		1,
		"backup: defeated temporary ally cleans up once"
	)


func test_subway_cools_before_dispatch_and_hydrant_applies_wet_with_runtime_cues() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	var chosen: DistrictCardDefinition = _confirm_current_district_plan(fixture.game)
	_expect_true(chosen != null, "Subway: focused next block confirms first")
	var cooled_candidate: EncounterDefinition = STANDARD_ENCOUNTER.duplicate(true) as EncounterDefinition
	cooled_candidate.id = &"cooled_candidate"
	cooled_candidate.minimum_heat_tier = 0
	cooled_candidate.minimum_night_pressure = 0.0
	var hot_candidate: EncounterDefinition = STANDARD_ENCOUNTER.duplicate(true) as EncounterDefinition
	hot_candidate.id = &"hot_candidate"
	hot_candidate.minimum_heat_tier = 3
	hot_candidate.minimum_night_pressure = 0.0
	fixture.game.run_flow_controller.encounter_candidates = [cooled_candidate, hot_candidate]
	fixture.game.run_director.apply_heat_delta(60)
	var pressure_before: float = fixture.game.run_director.night_pressure
	var played_ids: Array[StringName] = []
	fixture.game.audio_controller.cue_played.connect(
		func(cue_id: StringName) -> void: played_ids.append(cue_id)
	)
	var heat_before_subway: int = fixture.game.run_director.heat
	_press_key(fixture.game, KEY_3)
	_expect_equal(fixture.game.run_director.heat, heat_before_subway - 15, "Subway: Heat commits before focused dispatch")
	_expect_equal(
		fixture.game.run_director.night_pressure,
		pressure_before,
		"Subway: Night Pressure remains immutable"
	)
	_expect_true(
		&"sfx_intervention_activation" in played_ids,
		"Subway: successful intervention emits its authored cue"
	)
	if chosen != null and CardSystem.focused_block_kind(chosen) == &"fight":
		_expect_equal(
			fixture.game.encounter_controller.get_active_definition().id,
			&"cooled_candidate",
			"Subway: an Arcade choice observes the cooled Heat tier"
		)

	var hydrant_fixture: GameFixture = _new_game(true)
	hydrant_fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	hydrant_fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	hydrant_fixture.game.run_director.complete_intro()
	_expect_true(
		_begin_direct_planned_encounter(hydrant_fixture.game, STANDARD_ENCOUNTER, &"m6_hydrant_probe"),
		"Hydrant Wet: direct planned fight begins"
	)
	hydrant_fixture.game.encounter_controller.start_encounter(8203, STANDARD_ENCOUNTER)
	hydrant_fixture.game.encounter_controller.step_spawn_pacing(
		STANDARD_ENCOUNTER.initial_spawn_delay_seconds
	)
	var enemies: Array[ActorController] = hydrant_fixture.game.combat_director.get_live_actors(
		ActorController.Team.ENEMY
	)
	_expect_true(not enemies.is_empty(), "Hydrant Wet: encounter provides a live target")
	var target: ActorController = enemies[0]
	target.global_position = hydrant_fixture.game.fire_hydrant_controller.get_activation_origin()
	_expect_true(hydrant_fixture.game.fire_hydrant_controller.request_activation(), "Hydrant Wet: valid request resolves")
	_expect_true(target.has_status(&"wet"), "Hydrant Wet: future-compatible marker applied")
	_expect_equal(target.get_status_stacks(&"wet"), 1, "Hydrant Wet: marker never stacks above one")
	_expect_equal(
		target.status_controller.get_remaining(&"wet"),
		4.0,
		"Hydrant Wet: authored marker duration is data-driven"
	)


func test_space_focus_pause_debug_replay_and_telegraph_cleanup_are_lossless() -> void:
	var menu_fixture: GameFixture = _new_game(true)
	menu_fixture.game.debug_overlay.restart_same_seed_requested.emit()
	_expect_equal(
		menu_fixture.game.run_director.current_state,
		RunDirector.RunState.INITIALIZING,
		"debug replay: main-menu request is a no-op"
	)
	menu_fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	menu_fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	menu_fixture.game.settings_controller.handle_focus_changed(false)
	_expect_equal(menu_fixture.game.run_director.current_state, RunDirector.RunState.INTRO, "focus: intro is unskippable")
	menu_fixture.game.run_director.complete_intro()
	_expect_true(_confirm_current_district_plan(menu_fixture.game) != null, "focus: required District Plan confirms")
	menu_fixture.game._apply_latched_focus_pause_if_needed(RunDirector.RunState.PATROLLING)
	_expect_equal(menu_fixture.game.run_director.current_state, RunDirector.RunState.PAUSED, "focus: latch pauses first eligible state")
	_expect_false(menu_fixture.game.patrol_controller.simulation_enabled, "focus: patrol remains frozen")
	_expect_false(menu_fixture.game.combat_director.simulation_enabled, "focus: combat remains frozen")
	_expect_false(menu_fixture.game.reward_director.simulation_enabled, "focus: rewards remain frozen")
	_expect_false(menu_fixture.game.fire_hydrant_controller.simulation_enabled, "focus: Hydrant remains frozen")
	_expect_false(menu_fixture.game.call_backup_controller.simulation_enabled, "focus: Backup remains frozen")
	menu_fixture.game.settings_controller.handle_focus_changed(true)
	_expect_equal(menu_fixture.game.run_director.current_state, RunDirector.RunState.PAUSED, "focus: regain never auto-resumes")

	var telegraph: CombatTelegraph = CombatTelegraph.new()
	menu_fixture.game.get_node("DowntownLoop/EffectsContainer").add_child(telegraph)
	telegraph.present(Vector2(320.0, 210.0), 48.0, 1.0, "Pause Probe")
	telegraph.set_suspended(true)
	var warning_before: float = telegraph.get_remaining_seconds()
	telegraph._process(0.5)
	_expect_equal(telegraph.get_remaining_seconds(), warning_before, "pause: world warning timer is preserved")
	_press_key(menu_fixture.game, KEY_SPACE)
	_expect_equal(menu_fixture.game.run_director.current_state, RunDirector.RunState.PATROLLING, "Space: pause menu resumes")
	telegraph._process(0.2)
	_expect_true(telegraph.get_remaining_seconds() < warning_before, "resume: world warning timer advances again")
	var replay_seed: int = menu_fixture.game.run_director.run_seed
	menu_fixture.game.debug_overlay.restart_same_seed_requested.emit()
	_expect_equal(menu_fixture.game.run_director.run_seed, replay_seed, "debug replay: seed preserved")
	_expect_equal(menu_fixture.game.run_director.current_state, RunDirector.RunState.INTRO, "debug replay: clean intro")
	_expect_equal(
		_count_telegraphs(menu_fixture.game),
		0,
		"debug replay: no stale boss warning survives"
	)
	_expect_false(menu_fixture.game.vertical_slice_overlay.is_pause_visible(), "debug replay: pause modal cleared")


func test_shop_cadence_records_only_successful_unique_visits() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	_expect_true(
		_open_direct_planned_shop(fixture.game, &"baseline_shop", -1, &"m6_shop_probe"),
		"cadence shop: valid visit opens"
	)
	_expect_equal(
		fixture.game.cadence_tracker.get_event_count(RunCadenceTracker.CATEGORY_STRATEGIC),
		0,
		"cadence shop: WP02 measures complete blocks, not shop entry"
	)
	var snapshot_before: Dictionary = fixture.game.cadence_tracker.get_snapshot()
	_expect_false(
		bool(fixture.game.run_flow_controller.call("_open_shop_visit", &"baseline_shop", -1)),
		"cadence shop: duplicate active visit rejects"
	)
	_expect_equal(
		fixture.game.cadence_tracker.get_snapshot(),
		snapshot_before,
		"cadence shop: rejected visit cannot mutate cadence"
	)
	_expect_true(fixture.game.run_flow_controller.leave_shop(), "cadence shop: leave resolves the shop block")
	_expect_equal(
		fixture.game.cadence_tracker.get_event_count(RunCadenceTracker.CATEGORY_STRATEGIC),
		1,
		"cadence shop: exactly one completed block is recorded"
	)


func test_authored_spawn_staging_uses_eligible_time_and_exact_boundaries() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.rex_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	_expect_true(
		_begin_direct_planned_encounter(fixture.game, STANDARD_ENCOUNTER, &"m6_spawn_probe"),
		"spawn cadence: run enters an ordinary encounter"
	)
	_expect_true(
		fixture.game.encounter_controller.start_encounter(8800, STANDARD_ENCOUNTER),
		"spawn cadence: authored encounter starts"
	)
	_expect_equal(
		fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY),
		0,
		"spawn cadence: three-second entry beat starts without an early enemy"
	)
	fixture.game.encounter_controller.step_spawn_pacing(2.99)
	_expect_equal(
		fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY),
		0,
		"spawn cadence: just before entry boundary is immutable"
	)
	fixture.game.encounter_controller.step_spawn_pacing(0.01)
	_expect_equal(
		fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY),
		1,
		"spawn cadence: exact entry boundary spawns one"
	)
	var paused_snapshot: Dictionary = fixture.game.encounter_controller.get_snapshot()
	_expect_true(fixture.game.run_director.toggle_pause(), "spawn cadence: encounter pauses")
	fixture.game.encounter_controller.step_spawn_pacing(120.0)
	_expect_equal(
		fixture.game.encounter_controller.get_snapshot(),
		paused_snapshot,
		"spawn cadence: paused wall time advances no timer, actor, or draw"
	)
	_expect_true(fixture.game.run_director.toggle_pause(), "spawn cadence: encounter resumes")
	fixture.game.encounter_controller.step_spawn_pacing(11.99)
	_expect_equal(
		fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY),
		1,
		"spawn cadence: just before interval boundary remains one"
	)
	fixture.game.encounter_controller.step_spawn_pacing(0.01)
	_expect_equal(
		fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY),
		2,
		"spawn cadence: exact twelve-second boundary stages the second enemy"
	)
	fixture.game.encounter_controller.step_spawn_pacing(12.0)
	_expect_equal(
		fixture.game.combat_director.get_live_count(ActorController.Team.ENEMY),
		3,
		"spawn cadence: next exact interval stages only the final authored enemy"
	)
	_expect_equal(
		fixture.game.encounter_controller.get_snapshot().get("remaining_to_spawn"),
		0,
		"spawn cadence: finite plan is exhausted without reshuffle"
	)
	fixture.game.encounter_controller.reset_for_run()
	_expect_equal(
		fixture.game.encounter_controller.get_snapshot().get("spawn_delay_remaining"),
		0.0,
		"spawn cadence: restart clears staged timing"
	)


func test_viper_dispatch_victory_summary_and_return_to_menu_cleanup() -> void:
	var fixture: GameFixture = _new_game(true)
	var played_ids: Array[StringName] = []
	fixture.game.audio_controller.cue_played.connect(
		func(cue_id: StringName) -> void: played_ids.append(cue_id)
	)
	fixture.game.vertical_slice_overlay.rex_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	fixture.game.run_director.add_night_pressure(
		fixture.game.run_director.escalation_definition.boss_pressure_threshold + 0.1
	)
	_expect_false(fixture.game.run_director.is_boss_queued(), "boss: pressure alone cannot bypass district laps")
	_advance_director_to_wp02_boss(fixture.game)
	_expect_equal(
		fixture.game.run_director.current_state,
		RunDirector.RunState.BOSS_INTRO,
		"boss: threshold has safe-boundary precedence"
	)
	_expect_true(&"sfx_night_pressure_warning" in played_ids, "boss: threshold emits Night Pressure warning")
	_expect_true(&"sfx_boss_introduction" in played_ids, "boss: introduction emits dedicated cue")
	fixture.game.settings_controller.handle_focus_changed(false)
	_expect_equal(fixture.game.run_director.current_state, RunDirector.RunState.BOSS_INTRO, "boss focus: intro remains unskippable")
	fixture.game.run_director.complete_boss_intro()
	fixture.game._apply_latched_focus_pause_if_needed(RunDirector.RunState.BOSS_ACTIVE)
	_expect_equal(fixture.game.run_director.current_state, RunDirector.RunState.PAUSED, "boss focus: first eligible boss frame pauses")
	_expect_false(fixture.game.combat_director.simulation_enabled, "boss focus: boss combat remains frozen")
	fixture.game.settings_controller.handle_focus_changed(true)
	_press_key(fixture.game, KEY_SPACE)
	_expect_equal(fixture.game.run_director.current_state, RunDirector.RunState.BOSS_ACTIVE, "boss: active after explicit resume")
	_expect_true(
		fixture.game.encounter_controller.get_active_definition().boss,
		"boss: authored Viper showdown dispatched"
	)
	_expect_false(
		fixture.game.game_hud.boss_trigger_panel.visible,
		"boss: obsolete Milestone 3 placeholder modal never covers the live encounter"
	)
	var boss: ActorController = null
	for enemy: ActorController in fixture.game.combat_director.get_live_actors(ActorController.Team.ENEMY):
		if enemy.is_boss():
			boss = enemy
			break
	_expect_true(boss != null, "boss: The Viper actor spawned")
	fixture.game._on_attack_telegraphed(boss, VIPER_CHARGE, 0.8, boss.global_position, 0.0)
	fixture.game._on_attack_telegraphed(boss, VIPER_SUMMON, 0.9, boss.global_position, 0.0)
	fixture.game._on_attack_telegraphed(boss, VIPER_AREA, 1.1, boss.global_position, 92.0)
	_expect_equal(_count_telegraphs(fixture.game), 3, "boss: charge, summon, and area each get a written ground marker")
	_expect_true(
		fixture.game.reward_director.register_coin_cluster(9901, 60),
		"boss: pending summon-era base reward staged before terminal hit"
	)
	boss.receive_damage(100000)
	_expect_equal(fixture.game.run_director.current_state, RunDirector.RunState.VICTORY, "boss: defeat begins victory")
	_expect_equal(_count_telegraphs(fixture.game), 0, "boss: terminal sequence clears stale attack warnings")
	_expect_false(fixture.game.audio_controller.is_boss_music_active(), "boss: terminal sequence releases boss layer")
	fixture.game.run_director.step_run(
		fixture.game.run_director.get_victory_presentation_duration_seconds() + 0.1
	)
	var summary: RunSummaryRecord = fixture.game.run_director.get_last_summary()
	_expect_true(summary != null, "summary: finalized after victory presentation")
	_expect_equal(summary.result_label, "VICTORY", "summary: victory result")
	_expect_equal(summary.boss_result, "DEFEATED", "summary: boss result")
	_expect_equal(summary.elites_defeated, 0, "summary: boss is not miscounted as elite")
	_expect_equal(summary.coins_collected, 60, "summary: victory settles pending passive base rewards")
	_expect_equal(summary.manual_clusters_collected, 0, "summary: victory settlement is not manual")
	_expect_equal(summary.highest_combo, fixture.game.combo_tracker.get_highest_combo(), "summary: combo ledger copied")
	fixture.game.vertical_slice_overlay.return_to_main_menu_requested.emit()
	_expect_equal(
		fixture.game.run_director.current_state,
		RunDirector.RunState.INITIALIZING,
		"menu return: authority reset without a second outcome"
	)
	_expect_equal(fixture.game.combat_director.get_registered_count(), 0, "menu return: no stale actors")
	_expect_equal(fixture.game.card_system.get_hand().size(), 0, "menu return: no hidden hand")
	_expect_equal(fixture.game.call_backup_controller.get_active_allies().size(), 0, "menu return: no backup")
	_expect_true(fixture.game.vertical_slice_overlay.is_main_menu_visible(), "menu return: front end visible")
	_expect_equal(_count_telegraphs(fixture.game), 0, "menu return: no stale boss telegraph")


func test_terminal_outcome_settles_visible_coin_clusters_as_base_only() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	_expect_true(
		fixture.game.reward_director.register_coin_cluster(9001, 75),
		"terminal coins: pending optional cluster registers"
	)
	_expect_true(
		_begin_direct_planned_encounter(fixture.game, STANDARD_ENCOUNTER, &"m6_defeat_probe"),
		"terminal coins: defeat probe begins eligible encounter"
	)
	_expect_true(
		fixture.game.run_director.notify_all_crew_incapacitated(),
		"terminal coins: defeat transition accepted before ordinary timeout"
	)
	_expect_equal(
		fixture.game.reward_director.get_active_cluster_count(),
		0,
		"terminal coins: visible cluster resolves exactly once"
	)
	_expect_equal(
		fixture.game.reward_director.get_coin_total(),
		75,
		"terminal coins: full passive base value is preserved"
	)
	_expect_equal(
		fixture.game.reward_director.get_manual_clusters_collected(),
		0,
		"terminal coins: forced settlement is never relabelled manual"
	)
	var summary: RunSummaryRecord = fixture.game.run_director.get_last_summary()
	_expect_true(summary != null, "terminal coins: defeat summary published")
	_expect_equal(summary.coins_collected, 75, "terminal coins: summary includes settled base value")
	_expect_equal(summary.maximum_manual_streak, 0, "terminal coins: summary keeps manual streak unchanged")


func test_extraction_settles_pending_passive_coin_before_summary() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	fixture.game.run_director.add_night_pressure(
		fixture.game.run_director.escalation_definition.extraction_pressure_thresholds[0] + 0.1
	)
	_advance_director_to_wp02_lap_decision(fixture.game, 1)
	_expect_equal(
		fixture.game.run_director.current_state,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
		"extraction coins: first safe boundary opens extraction"
	)
	_expect_true(
		fixture.game.reward_director.register_coin_cluster(9002, 85),
		"extraction coins: visible optional cluster staged"
	)
	_expect_true(
		fixture.game.run_flow_controller.confirm_extraction(
			fixture.game.run_director.get_district_decision_token()
		),
		"extraction coins: extraction accepted"
	)
	fixture.game.run_director.step_run(
		fixture.game.run_director.get_extraction_duration_seconds() + 0.1
	)
	var summary: RunSummaryRecord = fixture.game.run_director.get_last_summary()
	_expect_true(summary != null, "extraction coins: summary published")
	_expect_equal(summary.result_label, "EXTRACTED", "extraction coins: result retained")
	_expect_equal(summary.coins_collected, 85, "extraction coins: full base value retained")
	_expect_equal(summary.manual_clusters_collected, 0, "extraction coins: settlement is not manual")


func test_settings_feedback_is_truthful_when_profile_rejects_persistence() -> void:
	var fixture: GameFixture = _new_game(false)
	var original_master: float = fixture.app.profile.settings.master_volume
	fixture.service.is_read_only = true
	fixture.game.vertical_slice_overlay.master_slider.value = 0.17
	fixture.game.vertical_slice_overlay.settings_apply_button.pressed.emit()
	_expect_contains(
		fixture.game.vertical_slice_overlay.settings_status.text,
		"NOT SAVED",
		"settings: rejected persistence never claims success"
	)
	_expect_equal(
		fixture.app.profile.settings.master_volume,
		original_master,
		"settings: rejected write preserves authoritative profile"
	)
	_expect_contains(
		fixture.game.vertical_slice_overlay.profile_status.text,
		"REJECTED",
		"settings: AppState persistence rejection is visibly surfaced"
	)


func test_equipment_and_card_reward_modals_survive_pause_round_trip() -> void:
	var equipment_fixture: GameFixture = _new_game(true)
	equipment_fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	equipment_fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	equipment_fixture.game.run_director.complete_intro()
	_expect_true(
		_begin_direct_planned_encounter(equipment_fixture.game, STANDARD_ENCOUNTER, &"m6_equipment_reward_probe"),
		"reward pause: equipment probe begins encounter"
	)
	_expect_true(
		equipment_fixture.game.run_director.notify_encounter_completed(8101, STANDARD_ENCOUNTER),
		"reward pause: equipment probe enters reward selection"
	)
	equipment_fixture.game._on_equipment_reward_ready(8101, [REWARD_EQUIPMENT])
	_expect_true(
		&"tutorial_equipment" in equipment_fixture.game.tutorial_controller.get_queued_ids(),
		"reward tutorial: equipment choice queues its authored contextual prompt"
	)
	_press_key(equipment_fixture.game, KEY_SPACE)
	_expect_equal(
		equipment_fixture.game.run_director.current_state,
		RunDirector.RunState.PAUSED,
		"reward pause: ordinary pause retains reward origin"
	)
	_expect_true(
		equipment_fixture.game.game_hud.is_equipment_reward_visible(),
		"reward pause: equipment modal remains staged under pause menu"
	)
	_press_key(equipment_fixture.game, KEY_SPACE)
	_expect_equal(
		equipment_fixture.game.run_director.current_state,
		RunDirector.RunState.REWARD_SELECTION,
		"reward pause: equipment selection resumes"
	)
	_expect_true(
		equipment_fixture.game.game_hud.is_equipment_reward_visible(),
		"reward pause: equipment modal returns without re-emission"
	)

	var card_fixture: GameFixture = _new_game(true)
	card_fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	card_fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	card_fixture.game.run_director.complete_intro()
	_expect_true(
		_begin_direct_planned_encounter(card_fixture.game, STANDARD_ENCOUNTER, &"m6_card_reward_probe"),
		"reward pause: card probe begins encounter"
	)
	_expect_true(
		card_fixture.game.run_director.notify_encounter_completed(8102, STANDARD_ENCOUNTER),
		"reward pause: card probe enters reward selection"
	)
	card_fixture.game.game_hud.present_district_card_reward(
		8102,
		991,
		[REWARD_CARD],
		3,
		true
	)
	_press_key(card_fixture.game, KEY_SPACE)
	_expect_true(
		card_fixture.game.game_hud.district_card_panel.visible,
		"reward pause: card modal remains staged under pause menu"
	)
	_press_key(card_fixture.game, KEY_SPACE)
	_expect_equal(
		card_fixture.game.run_director.current_state,
		RunDirector.RunState.REWARD_SELECTION,
		"reward pause: card selection resumes"
	)
	_expect_true(
		card_fixture.game.game_hud.district_card_panel.visible,
		"reward pause: card modal returns without re-emission"
	)


func _new_game(full_content_access: bool) -> GameFixture:
	_path_nonce += 1
	var fixture: GameFixture = GameFixture.new()
	fixture.profile_path = "user://m6_game_run_%d_%d.json" % [Time.get_ticks_usec(), _path_nonce]
	_test_paths.append(fixture.profile_path)
	fixture.service = track(ProfileSaveService.new()) as ProfileSaveService
	fixture.service.configure_profile_path(fixture.profile_path)
	fixture.app = track(NeonAppState.new()) as NeonAppState
	fixture.app.initialize(fixture.service, full_content_access)
	fixture.viewport = track(SubViewport.new()) as SubViewport
	fixture.viewport.size = Vector2i(1280, 720)
	fixture.viewport.disable_3d = true
	fixture.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	fixture.game = GAME_SCENE.instantiate() as GameRun
	fixture.game.app_state_override = fixture.app
	fixture.viewport.add_child(fixture.game)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(fixture.viewport)
	return fixture


func _advance_director_to_wp02_lap_decision(game: GameRun, target_lap: int) -> void:
	while int(game.run_director.get_district_loop_snapshot().get("completed_laps", 0)) < target_lap:
		var loop: Dictionary = game.run_director.get_district_loop_snapshot()
		var lap_index: int = int(loop.get("lap_index", 1))
		var block_index: int = int(loop.get("block_index", 1))
		var encounter_id: int = (lap_index - 1) * 3 + block_index + 6000
		_begin_direct_planned_encounter(
			game,
			STANDARD_ENCOUNTER,
			StringName("m6_compat::lap_%d::block_%d" % [lap_index, block_index])
		)
		game.run_director.notify_encounter_completed(encounter_id, STANDARD_ENCOUNTER)
		game.run_director.complete_reward_selection()


func _advance_director_to_wp02_boss(game: GameRun) -> void:
	for target_lap: int in range(1, 4):
		_advance_director_to_wp02_lap_decision(game, target_lap)
		if target_lap < 3:
			game.run_director.decline_extraction(game.run_director.get_district_decision_token())


func _confirm_current_district_plan(game: GameRun) -> DistrictCardDefinition:
	var snapshot: Dictionary = game.card_system.get_snapshot()
	var offer: Array = snapshot.get("offer", []) as Array
	if offer.is_empty():
		return null
	var card: DistrictCardDefinition = offer[0] as DistrictCardDefinition
	if card == null:
		return null
	var staged: Dictionary = game.run_flow_controller.stage_focused_district_plan_choice(
		card.id,
		int(snapshot.get("offer_revision", -1)),
		int(snapshot.get("context_lifecycle_revision", -1)),
		StringName(snapshot.get("lap_id", &"")),
		StringName(snapshot.get("block_id", &""))
	)
	if not bool(staged.get("accepted", false)):
		return null
	var confirmed: Dictionary = game.run_flow_controller.confirm_focused_district_plan_choice(
		int(staged.get("confirmation_token", -1))
	)
	return card if bool(confirmed.get("accepted", false)) else null


func _begin_direct_planned_encounter(
	game: GameRun,
	definition: EncounterDefinition,
	occurrence_id: StringName
) -> bool:
	if _confirm_current_district_plan(game) == null:
		return false
	if not game.run_director.begin_district_block(occurrence_id, &"encounter"):
		return false
	if not _resolve_direct_focused_block(game, occurrence_id, &"encounter"):
		return false
	return game.run_director.begin_encounter(definition)


func _open_direct_planned_shop(
	game: GameRun,
	source_id: StringName,
	maximum_purchases: int,
	occurrence_id: StringName
) -> bool:
	if _confirm_current_district_plan(game) == null:
		return false
	if not game.run_director.begin_district_block(occurrence_id, &"shop"):
		return false
	if not _resolve_direct_focused_block(game, occurrence_id, &"shop"):
		return false
	return bool(game.run_flow_controller.call("_open_shop_visit", source_id, maximum_purchases))


func _resolve_direct_focused_block(
	game: GameRun,
	occurrence_id: StringName,
	baseline_node_type: StringName
) -> bool:
	var loop: Dictionary = game.run_director.get_district_loop_snapshot()
	return game.card_system.resolve_focused_district_plan_block(
		int(loop.get("block_index", 1)),
		occurrence_id,
		int(loop.get("block_index", 1)),
		occurrence_id,
		baseline_node_type,
		loop
	) != null


func _count_telegraphs(game: GameRun) -> int:
	var count: int = 0
	for child: Node in game.get_node("DowntownLoop/EffectsContainer").get_children():
		if child is CombatTelegraph:
			count += 1
	return count


func _press_key(game: GameRun, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	game._input(event)


func _remove_path(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect_true(actual: bool, context: String) -> void:
	assert_true(actual, context)


func _expect_false(actual: bool, context: String) -> void:
	assert_false(actual, context)


func _expect_equal(actual: Variant, expected: Variant, context: String) -> void:
	assert_eq(actual, expected, "%s (expected %s, got %s)" % [context, expected, actual])


func _expect_contains(actual: String, expected: String, context: String) -> void:
	assert_contains(actual, expected, context)
