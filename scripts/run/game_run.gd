class_name GameRun
extends Node

## Run-scoped composition root. It wires typed authorities and presentation,
## forwards intent, and contains no duplicated run/combat/reward calculations.

const HYDRANT_COIN_EXCLUSION_RADIUS: float = 76.0
const LOADOUT_DEFINITION: RunLoadoutDefinition = preload(
	"res://data/run/milestone_6_starting_loadout.tres"
)
const JAX_DEFINITION: ActorDefinition = preload("res://data/crew/jax.tres")
const ZOEY_DEFINITION: ActorDefinition = preload("res://data/crew/zoey.tres")
const REX_DEFINITION: ActorDefinition = preload("res://data/crew/rex.tres")
const BOSS_TELEGRAPH_MINIMUM_SECONDS: float = 0.45
const SHOCK_STATUS: StatusEffectDefinition = preload(
	"res://data/equipment/shock_status.tres"
)

@export var loadout_definition: RunLoadoutDefinition = LOADOUT_DEFINITION
var app_state_override: NeonAppState

@onready var run_director: RunDirector = $RunDirector
@onready var patrol_controller: PatrolController = $PatrolController
@onready var combat_director: CombatDirector = $CombatDirector
@onready var reward_director: RewardDirector = $RewardDirector
@onready var fire_hydrant_controller: FireHydrantController = $FireHydrantController
@onready var call_backup_controller: CallBackupController = $CallBackupController
@onready var combo_tracker: ComboTracker = $ComboTracker
@onready var cadence_tracker: RunCadenceTracker = $RunCadenceTracker
@onready var cooling_controller: RunCoolingController = $RunCoolingController
@onready var encounter_controller: RunEncounterController = $RunEncounterController
@onready var run_flow_controller: RunFlowController = $RunFlowController
@onready var card_system: CardSystem = $CardSystem
@onready var synergy_system: SynergySystem = $SynergySystem
@onready var display_controller: DisplayController = $DisplayController
@onready var settings_controller: ApplicationSettingsController = $ApplicationSettingsController
@onready var tutorial_controller: TutorialPromptController = $TutorialPromptController
@onready var screen_shake_controller: ScreenShakeController = $ScreenShakeController
@onready var audio_controller: AudioPresentationController = $AudioPresentationController
@onready var downtown_loop: DowntownLoop = $DowntownLoop
@onready var game_hud: GameHUD = $GameHUD
@onready var vertical_slice_overlay: VerticalSliceOverlay = $VerticalSliceOverlay
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var fire_hydrant: FireHydrant = $DowntownLoop/Interactables/FireHydrant
@onready var combat_feedback: CombatFeedback = $DowntownLoop/EffectsContainer/CombatFeedback
@onready var app_state: NeonAppState = (
	app_state_override
	if app_state_override != null
	else get_node_or_null("/root/AppState") as NeonAppState
)

var _last_coin_status: String = "AUTO = FULL VALUE"
var _hydrant_feedback_override: String = ""
var _hydrant_feedback_remaining: float = 0.0
var _web_audio_unlocked: bool = false
var _active_content_access: RunContentAccessSnapshot
var _selected_crew_actor: ActorController
var _boss_actor: ActorController
var _boss_phase_text: String = "PHASE 1"
var _boss_telegraph_text: String = ""
var _boss_telegraph_remaining: float = 0.0
var _tutorial_remaining: float = 0.0
var _last_recorded_summary: RunSummaryRecord
var _strategic_reward_encounters: Dictionary[int, bool] = {}
var _hit_flash_reduction: float = 0.0


func _ready() -> void:
	debug_overlay.lane_visibility_requested.connect(_on_lane_visibility_requested)
	debug_overlay.add_heat_requested.connect(run_flow_controller.force_add_heat)
	debug_overlay.advance_pressure_requested.connect(
		run_flow_controller.force_advance_pressure_to_next_threshold
	)
	debug_overlay.force_defeat_requested.connect(run_flow_controller.force_defeat)
	debug_overlay.restart_same_seed_requested.connect(_restart_same_seed)
	debug_overlay.set_lane_visibility(downtown_loop.are_debug_lanes_visible())

	combat_director.actor_registered.connect(_on_actor_registered)
	combat_director.actor_died.connect(_on_actor_died)
	combat_director.actor_incapacitated.connect(_on_actor_incapacitated)
	combat_director.hit_landed.connect(_on_hit_landed)
	combat_director.environmental_hit_landed.connect(_on_environmental_hit_landed)
	combat_director.environmental_collision_landed.connect(_on_environmental_collision_landed)
	combat_director.status_applied.connect(_on_equipment_status_applied)
	combat_director.attack_telegraphed.connect(_on_attack_telegraphed)
	combat_director.boss_phase_changed.connect(_on_boss_phase_changed)
	combat_director.crew_status_changed.connect(_on_crew_status_changed)
	encounter_controller.boss_encounter_started.connect(_on_boss_encounter_started)
	encounter_controller.encounter_started.connect(_on_encounter_started_build_expression)
	encounter_controller.boss_defeated.connect(_on_boss_defeated)
	encounter_controller.coin_cluster_presented.connect(_on_coin_cluster_presented)
	reward_director.coins_changed.connect(_on_coins_changed)
	reward_director.scrap_changed.connect(_on_scrap_changed)
	reward_director.streak_changed.connect(_on_streak_changed)
	reward_director.cluster_resolved.connect(_on_cluster_resolved)
	reward_director.equipment_choice_resolved.connect(_on_equipment_choice_resolved)
	reward_director.standard_reward_result_available.connect(_on_standard_reward_result_available)
	cooling_controller.cooling_applied.connect(_on_cooling_audio_applied)
	cooling_controller.shop_purchase_resolved.connect(_on_shop_purchase_resolved)
	run_director.run_started.connect(_on_run_started)
	run_director.run_state_changed.connect(_on_run_state_changed)
	run_director.run_summary_ready.connect(_on_run_summary_ready)
	run_director.heat_tier_changed.connect(_on_heat_tier_changed)
	run_director.extraction_became_available.connect(_on_extraction_became_available)
	run_director.boss_started.connect(_on_boss_intro_started)
	run_director.district_block_completed.connect(_on_district_block_completed)
	synergy_system.build_changed.connect(_on_build_changed)
	synergy_system.synergy_activated.connect(_on_synergy_activated)
	synergy_system.synergy_deactivated.connect(_on_synergy_deactivated)

	fire_hydrant_controller.state_changed.connect(_on_hydrant_state_changed)
	fire_hydrant_controller.activation_resolved.connect(_on_hydrant_activation_resolved)
	fire_hydrant_controller.activation_rejected.connect(_on_hydrant_activation_rejected)
	fire_hydrant.activation_requested.connect(_request_hydrant_activation)

	game_hud.hydrant_activation_requested.connect(_request_hydrant_activation)
	game_hud.backup_activation_requested.connect(_request_backup_activation)
	game_hud.hydrant_preview_requested.connect(fire_hydrant.set_external_preview_visible)
	game_hud.fullscreen_requested.connect(display_controller.toggle_fullscreen)
	game_hud.primary_action_requested.connect(_on_primary_action_requested)
	game_hud.extraction_requested.connect(run_flow_controller.confirm_extraction)
	game_hud.lap_extract_requested.connect(run_flow_controller.confirm_extraction)
	game_hud.lap_push_requested.connect(run_flow_controller.decline_extraction)
	game_hud.subway_reroute_requested.connect(run_flow_controller.request_subway_reroute)
	game_hud.shop_cooling_requested.connect(run_flow_controller.request_shop_cooling)
	game_hud.restart_same_seed_requested.connect(_restart_same_seed)
	game_hud.restart_new_seed_requested.connect(_restart_new_seed)
	game_hud.equipment_acquisition_requested.connect(_on_equipment_acquisition_requested)
	game_hud.equipment_reward_decline_requested.connect(_on_equipment_reward_decline_requested)
	game_hud.inventory_swap_requested.connect(_on_inventory_swap_requested)
	game_hud.inventory_move_requested.connect(_on_inventory_move_requested)
	game_hud.inventory_discard_requested.connect(_on_inventory_discard_requested)
	game_hud.inventory_preview_requested.connect(_on_inventory_preview_requested)
	game_hud.district_card_planning_open_requested.connect(_on_card_planning_open_requested)
	game_hud.district_card_planning_close_requested.connect(_on_card_planning_close_requested)
	game_hud.district_card_placement_staged.connect(_on_card_placement_staged)
	game_hud.district_card_placement_confirm_requested.connect(
		_on_card_placement_confirm_requested
	)
	game_hud.district_card_placement_cancel_requested.connect(
		_on_card_placement_cancel_requested
	)
	game_hud.district_plan_choice_requested.connect(
		_on_district_plan_choice_requested
	)
	game_hud.district_card_reward_acquisition_requested.connect(
		_on_card_reward_acquisition_requested
	)
	game_hud.district_card_reward_skip_requested.connect(_on_card_reward_skip_requested)
	display_controller.fullscreen_changed.connect(game_hud.present_fullscreen_state)
	display_controller.landscape_state_changed.connect(game_hud.present_landscape_state)
	display_controller.safe_area_changed.connect(game_hud.apply_safe_area)

	call_backup_controller.state_changed.connect(game_hud.present_backup_state)
	call_backup_controller.activation_accepted.connect(_on_backup_activation_accepted)
	call_backup_controller.activation_rejected.connect(_on_backup_activation_rejected)
	call_backup_controller.activation_ended.connect(_on_backup_activation_ended)
	combo_tracker.snapshot_changed.connect(_on_combo_snapshot_changed)
	tutorial_controller.prompt_presented.connect(_on_tutorial_prompt_presented)
	tutorial_controller.prompt_dismissed.connect(_on_tutorial_prompt_dismissed)
	settings_controller.focus_pause_intent_requested.connect(_on_focus_pause_intent_requested)
	vertical_slice_overlay.start_run_requested.connect(_on_start_run_requested)
	vertical_slice_overlay.resume_requested.connect(_resume_from_pause)
	vertical_slice_overlay.restart_same_seed_requested.connect(_restart_same_seed)
	vertical_slice_overlay.restart_new_seed_requested.connect(_restart_new_seed)
	vertical_slice_overlay.return_to_main_menu_requested.connect(_return_to_main_menu)
	vertical_slice_overlay.settings_apply_requested.connect(_on_settings_apply_requested)
	vertical_slice_overlay.reset_save_requested.connect(_on_reset_save_requested)
	vertical_slice_overlay.ui_confirmed.connect(_on_ui_confirmed)
	vertical_slice_overlay.ui_hovered.connect(_on_ui_hovered)
	card_system.card_placed.connect(_on_card_placed)
	card_system.district_plan_offer_started.connect(_on_district_plan_offer_started)

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
	call_backup_controller.configure(
		_create_backup_ally,
		_confirm_backup_ally_registered,
		_remove_backup_ally
	)
	card_system.configure_focused_district_plan(
		run_director.is_district_loop_enabled()
	)
	run_flow_controller.configure(
		run_director,
		patrol_controller,
		encounter_controller,
		reward_director,
		cooling_controller,
		combat_director,
		fire_hydrant_controller,
		synergy_system,
		card_system,
		call_backup_controller,
		combo_tracker,
		cadence_tracker
	)
	run_flow_controller.flow_status_changed.connect(_on_flow_status_changed)
	run_flow_controller.action_feedback.connect(_on_action_feedback)
	run_flow_controller.equipment_reward_ready.connect(_on_equipment_reward_ready)
	run_flow_controller.card_reward_ready.connect(_on_card_reward_ready)
	run_flow_controller.reward_ready.connect(_on_standard_reward_ready)
	run_flow_controller.card_planning_changed.connect(
		game_hud.present_district_card_planning_state
	)

	_web_audio_unlocked = not OS.has_feature("web")
	game_hud.present_audio_unlock_required(not _web_audio_unlocked)
	_route_existing_audio_to_sound_effects_bus()
	if app_state != null:
		app_state.settings_changed.connect(_apply_settings)
		app_state.unlocks_granted.connect(_on_unlocks_granted)
		app_state.persistence_rejected.connect(_on_persistence_rejected)
		_apply_settings(app_state.profile.settings)
	else:
		_apply_settings(GameSettingsData.create_default())
	display_controller.refresh_state(true)
	_refresh_hydrant_presentation()
	game_hud.present_backup_state(call_backup_controller.get_snapshot())
	_on_build_changed(synergy_system.get_snapshot())
	game_hud.visible = false
	vertical_slice_overlay.set_development_reset_visible(
		app_state != null and app_state.development_full_content_access
	)
	_show_main_menu()
	_refresh_combat_presentation()


func _process(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	var presentation_delta: float = (
		0.0 if run_director.current_state == RunDirector.RunState.PAUSED else safe_delta
	)
	if RunDirector.is_eligible_active_state(run_director.current_state):
		combo_tracker.step_eligible_time(safe_delta)
		call_backup_controller.step_eligible_time(safe_delta)
	if _hydrant_feedback_remaining > 0.0:
		_hydrant_feedback_remaining = maxf(
			0.0,
			_hydrant_feedback_remaining - presentation_delta
		)
		if _hydrant_feedback_remaining <= 0.0:
			_hydrant_feedback_override = ""
			_refresh_hydrant_presentation()
	if _tutorial_remaining > 0.0:
		_tutorial_remaining = maxf(_tutorial_remaining - presentation_delta, 0.0)
		if _tutorial_remaining <= 0.0:
			tutorial_controller.dismiss_current()
	if _boss_telegraph_remaining > 0.0:
		_boss_telegraph_remaining = maxf(
			_boss_telegraph_remaining - presentation_delta,
			0.0
		)
		if _boss_telegraph_remaining <= 0.0:
			_boss_telegraph_text = ""
	_refresh_boss_presentation()


func _input(event: InputEvent) -> void:
	if not _web_audio_unlocked and OS.has_feature("web") and _is_audio_unlock_gesture(event):
		_web_audio_unlocked = true
		combat_feedback.prime_audio()
		audio_controller.stop_all_audio()
		audio_controller.start_district_music()
		audio_controller.set_boss_music_active(
			run_director.current_state in [
				RunDirector.RunState.BOSS_INTRO,
				RunDirector.RunState.BOSS_ACTIVE,
			]
		)
		game_hud.present_audio_unlocked()

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		if display_controller.is_fullscreen():
			return
		_handle_escape_input()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_SPACE:
		if (
			not vertical_slice_overlay.has_blocking_modal()
			or (
				run_director.current_state == RunDirector.RunState.PAUSED
				and vertical_slice_overlay.is_pause_visible()
			)
		):
			_toggle_pause_from_input()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_E and run_director.current_state == RunDirector.RunState.EXTRACTION_AVAILABLE:
		if vertical_slice_overlay.has_blocking_modal():
			return
		if card_system.is_planning_active():
			_on_action_feedback("CLOSE DISTRICT CARD PLANNING BEFORE EXTRACTION")
		else:
			run_flow_controller.confirm_extraction(
				run_director.get_district_decision_token()
			)
		get_viewport().set_input_as_handled()
	elif key_event.keycode in [KEY_1, KEY_KP_1]:
		if not vertical_slice_overlay.has_blocking_modal():
			_request_hydrant_activation()
		get_viewport().set_input_as_handled()
	elif key_event.keycode in [KEY_2, KEY_KP_2]:
		if not vertical_slice_overlay.has_blocking_modal():
			_request_backup_activation()
		get_viewport().set_input_as_handled()
	elif key_event.keycode in [KEY_3, KEY_KP_3]:
		if not vertical_slice_overlay.has_blocking_modal():
			run_flow_controller.request_subway_reroute()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_TAB:
		if not vertical_slice_overlay.has_blocking_modal():
			game_hud.toggle_build_details()
		get_viewport().set_input_as_handled()


func _show_main_menu() -> void:
	game_hud.visible = false
	vertical_slice_overlay.present_settings(_current_settings_dictionary())
	vertical_slice_overlay.show_main_menu(_build_crew_menu_entries(), _profile_status_text())
	audio_controller.set_boss_music_active(false)
	screen_shake_controller.reset_presentation()
	vertical_slice_overlay.hide_boss()
	vertical_slice_overlay.hide_tutorial()


func get_active_content_access_snapshot() -> RunContentAccessSnapshot:
	return _active_content_access.duplicate_snapshot() if _active_content_access != null else null


func get_active_content_access_identity() -> int:
	return _active_content_access.get_instance_id() if _active_content_access != null else 0


func get_selected_crew_actor() -> ActorController:
	return _selected_crew_actor


func _build_crew_menu_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var accessible_ids: Array[StringName] = (
		app_state.get_accessible_crew_ids()
		if app_state != null
		else [&"jax", &"zoey", &"rex"]
	)
	for definition: ActorDefinition in [JAX_DEFINITION, ZOEY_DEFINITION, REX_DEFINITION]:
		var archetype: String = {
			&"jax": "Brawler",
			&"zoey": "Tech Fighter",
			&"rex": "Bruiser",
		}.get(definition.id, "Crew")
		var summary: String = {
			&"jax": "High knockback, medium health, short reach, and powerful wall collisions.",
			&"zoey": "Fast attacks, lower health, shorter intervention cooldowns, and Shock builds.",
			&"rex": "High health, slow heavy attacks, stagger resistance, and bonus elite/boss damage.",
		}.get(definition.id, "Automatic street fighter.")
		result.append({
			"id": definition.id,
			"display_name": definition.display_name,
			"archetype": archetype,
			"summary": summary,
			"trait_text": "No permanent statistical bonuses are applied.",
			"unlocked": accessible_ids.has(definition.id),
			"unlock_hint": "Core crew available from first launch.",
		})
	return result


func _profile_status_text() -> String:
	if app_state == null:
		return "PROFILE UNAVAILABLE - SAFE DEFAULTS ACTIVE"
	var service: ProfileSaveService = app_state.get_save_service()
	var load_status: String = (
		String(service.last_load_status).replace("_", " ").to_upper()
		if service != null
		else "DEFAULTS"
	)
	var access_text: String = (
		"DEVELOPMENT CATALOGUE ACCESS"
		if app_state.development_full_content_access
		else "ALL CREW + VERSIONED BREADTH PROFILE"
	)
	return "SAVE V%d - %s - %s" % [app_state.profile.save_version, load_status, access_text]


func _on_start_run_requested(crew_id: StringName) -> void:
	var accessible_ids: Array[StringName] = (
		app_state.get_accessible_crew_ids()
		if app_state != null
		else [&"jax", &"zoey", &"rex"]
	)
	if crew_id not in accessible_ids or crew_id not in loadout_definition.selectable_crew_ids:
		vertical_slice_overlay.present_profile_status("CREW SELECTION REJECTED")
		return
	_active_content_access = _capture_content_access(crew_id)
	if not _apply_content_access(_active_content_access):
		vertical_slice_overlay.present_profile_status("RUN CONTENT COULD NOT INITIALIZE")
		return
	_prepare_presentation_for_run()
	run_flow_controller.start_initial_run()


func _capture_content_access(crew_id: StringName) -> RunContentAccessSnapshot:
	return RunContentAccessSnapshot.create(
		crew_id,
		app_state.get_accessible_equipment_ids() if app_state != null else [],
		app_state.get_accessible_card_ids() if app_state != null else [],
		app_state.profile.save_version if app_state != null else PersistentProfileData.SAVE_VERSION,
		app_state.development_full_content_access if app_state != null else true
	)


func _apply_content_access(snapshot: RunContentAccessSnapshot) -> bool:
	if snapshot == null:
		return false
	var crew_definition: ActorDefinition = _crew_definition_by_id(snapshot.selected_crew_id)
	if crew_definition == null or crew_definition.starting_equipment.size() != 1:
		return false
	if crew_definition.starting_equipment[0].id not in snapshot.allowed_equipment_ids:
		return false
	card_system.configure_run_access(snapshot.allowed_card_ids)
	reward_director.configure_equipment_access(snapshot.allowed_equipment_ids)
	return (
		run_flow_controller.configure_starting_equipment(crew_definition.starting_equipment)
		and encounter_controller.configure_starting_crew([snapshot.selected_crew_id])
	)


func _crew_definition_by_id(crew_id: StringName) -> ActorDefinition:
	for definition: ActorDefinition in [JAX_DEFINITION, ZOEY_DEFINITION, REX_DEFINITION]:
		if definition.id == crew_id:
			return definition
	return null


func _prepare_presentation_for_run() -> void:
	game_hud.visible = true
	_clear_combat_telegraphs()
	vertical_slice_overlay.prepare_for_run()
	vertical_slice_overlay.hide_boss()
	vertical_slice_overlay.hide_tutorial()
	_last_recorded_summary = null
	_selected_crew_actor = null
	_boss_actor = null
	_boss_phase_text = "PHASE 1"
	_boss_telegraph_text = ""
	_boss_telegraph_remaining = 0.0
	audio_controller.set_boss_music_active(false)
	screen_shake_controller.reset_presentation()


func _restart_same_seed() -> void:
	if _active_content_access == null:
		return
	if not _apply_content_access(_active_content_access):
		return
	_prepare_presentation_for_run()
	run_flow_controller.restart_same_seed()


func _restart_new_seed() -> void:
	if _active_content_access == null:
		return
	_active_content_access = _capture_content_access(_active_content_access.selected_crew_id)
	if not _apply_content_access(_active_content_access):
		return
	_prepare_presentation_for_run()
	run_flow_controller.restart_new_seed()


func _return_to_main_menu() -> void:
	if not run_flow_controller.return_to_main_menu():
		return
	_clear_combat_telegraphs()
	_active_content_access = null
	_selected_crew_actor = null
	_boss_actor = null
	tutorial_controller.clear_for_run_end()
	_show_main_menu()


func _toggle_pause_from_input() -> void:
	if run_director.current_state == RunDirector.RunState.PAUSED:
		_resume_from_pause()
	elif RunDirector.is_pauseable_state(run_director.current_state):
		run_director.toggle_pause()


func _resume_from_pause() -> void:
	if run_director.current_state != RunDirector.RunState.PAUSED:
		return
	if run_director.is_card_planning_pause_active():
		_on_action_feedback("CLOSE DISTRICT CARD PLANNING TO RESUME")
		return
	if run_director.toggle_pause():
		vertical_slice_overlay.hide_pause()


func _handle_escape_input() -> void:
	if vertical_slice_overlay.is_settings_visible():
		if run_director.current_state == RunDirector.RunState.PAUSED:
			vertical_slice_overlay.show_pause(_current_settings_dictionary())
		else:
			_show_main_menu()
		return
	if vertical_slice_overlay.is_main_menu_visible() or vertical_slice_overlay.is_summary_visible():
		return
	_toggle_pause_from_input()


func _on_settings_apply_requested(values: Dictionary) -> void:
	var settings: GameSettingsData = GameSettingsData.from_dictionary(values)
	if app_state != null:
		var saved: bool = app_state.update_settings(settings)
		if saved:
			vertical_slice_overlay.present_settings_status(
				"SETTINGS SAVED - GAMEPLAY AUTHORITY UNCHANGED"
			)
		else:
			vertical_slice_overlay.present_settings(
				_current_settings_dictionary(),
				"SETTINGS NOT SAVED - PROFILE IS READ-ONLY OR UNWRITABLE"
			)
	else:
		_apply_settings(settings)
		vertical_slice_overlay.present_settings_status(
			"SETTINGS APPLIED FOR THIS SESSION"
		)


func _on_persistence_rejected(reason: StringName) -> void:
	var readable_reason: String = String(reason).replace("_", " ").to_upper()
	vertical_slice_overlay.present_profile_status("PROFILE SAVE REJECTED - %s" % readable_reason)


func _apply_settings(settings: GameSettingsData) -> void:
	var safe_settings: GameSettingsData = (
		settings.sanitized_copy() if settings != null else GameSettingsData.create_default()
	)
	settings_controller.apply_settings(safe_settings, get_window())
	screen_shake_controller.set_intensity(safe_settings.screen_shake_intensity)
	combat_feedback.set_damage_numbers_enabled(safe_settings.damage_numbers_enabled)
	_hit_flash_reduction = safe_settings.hit_flash_reduction
	for actor: ActorController in combat_director.get_live_actors(ActorController.Team.CREW):
		actor.set_hit_flash_reduction(_hit_flash_reduction)
	for actor: ActorController in combat_director.get_live_actors(ActorController.Team.ENEMY):
		actor.set_hit_flash_reduction(_hit_flash_reduction)
	vertical_slice_overlay.present_settings(safe_settings.to_dictionary())
	display_controller.refresh_state(true)


func _current_settings_dictionary() -> Dictionary:
	if app_state != null and app_state.profile != null and app_state.profile.settings != null:
		return app_state.profile.settings.to_dictionary()
	return settings_controller.current_settings.to_dictionary()


func _on_focus_pause_intent_requested(should_pause: bool) -> void:
	# Focus loss may request a pause, but focus regain never silently resumes a
	# player who may have stepped away.
	if (
		should_pause
		and run_director.current_state != RunDirector.RunState.PAUSED
		and RunDirector.is_pauseable_state(run_director.current_state)
	):
		run_director.toggle_pause()


func _on_reset_save_requested() -> void:
	if app_state == null or not app_state.development_full_content_access:
		vertical_slice_overlay.present_profile_status("DEVELOPMENT RESET UNAVAILABLE")
		return
	app_state.reset_profile_for_development()
	_show_main_menu()


func _on_unlocks_granted(content_ids: Array[StringName]) -> void:
	if content_ids.is_empty():
		return
	_on_action_feedback("UNLOCKED: %s" % _join_string_names(content_ids))


func _join_string_names(values: Array[StringName]) -> String:
	var text_values: PackedStringArray = PackedStringArray()
	for value: StringName in values:
		text_values.append(String(value).replace("_", " ").to_upper())
	return ", ".join(text_values)


func _on_run_started(seed: int, _schema_version: int) -> void:
	_strategic_reward_encounters.clear()
	_last_coin_status = "AUTO = FULL VALUE"
	_boss_actor = null
	_boss_phase_text = "PHASE 1"
	_boss_telegraph_text = ""
	_boss_telegraph_remaining = 0.0
	tutorial_controller.begin_run(seed)
	tutorial_controller.request_trigger(&"run_started")
	audio_controller.set_boss_music_active(false)
	audio_controller.start_district_music()
	_refresh_combat_presentation()


func _on_run_state_changed(previous_state: int, new_state: int) -> void:
	_set_combat_telegraphs_suspended(new_state == RunDirector.RunState.PAUSED)
	_refresh_combo_presentation_for_state(new_state)
	if new_state not in [RunDirector.RunState.ENCOUNTER_ACTIVE, RunDirector.RunState.BOSS_ACTIVE]:
		game_hud.clear_build_callout()
	if new_state in [RunDirector.RunState.REWARD_SELECTION, RunDirector.RunState.SHOP]:
		# Focused consequence layers teach themselves; queued legacy banners must
		# never cover exact destinations, prices, stock, or Confirm/Exit actions.
		while tutorial_controller.dismiss_current():
			pass
	if new_state == RunDirector.RunState.PAUSED:
		if not run_director.is_card_planning_pause_active():
			vertical_slice_overlay.show_pause(_current_settings_dictionary())
	elif previous_state == RunDirector.RunState.PAUSED:
		vertical_slice_overlay.hide_pause()
	match new_state:
		RunDirector.RunState.PATROLLING:
			if not card_system.get_hand().is_empty():
				tutorial_controller.request_trigger(&"card_planning_available")
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			tutorial_controller.request_trigger(&"intervention_available")
		RunDirector.RunState.BOSS_INTRO:
			audio_controller.set_boss_music_active(true)
			audio_controller.play_cue(&"sfx_boss_introduction")
			tutorial_controller.request_trigger(&"boss_intro")
		RunDirector.RunState.VICTORY:
			_clear_combat_telegraphs()
			audio_controller.set_boss_music_active(false)
			audio_controller.play_cue(&"sfx_victory")
		RunDirector.RunState.DEFEAT:
			_clear_combat_telegraphs()
			audio_controller.set_boss_music_active(false)
			audio_controller.play_cue(&"sfx_defeat")
		RunDirector.RunState.INITIALIZING:
			audio_controller.set_boss_music_active(false)
			screen_shake_controller.reset_presentation()
	if (
		new_state != RunDirector.RunState.PAUSED
		and settings_controller.is_focus_pause_intent_active()
		and RunDirector.is_pauseable_state(new_state)
	):
		call_deferred("_apply_latched_focus_pause_if_needed", new_state)
	_refresh_boss_presentation()


func _apply_latched_focus_pause_if_needed(expected_state: int) -> void:
	if (
		run_director.current_state == expected_state
		and settings_controller.is_focus_pause_intent_active()
		and RunDirector.is_pauseable_state(expected_state)
	):
		run_director.toggle_pause()


func _on_run_summary_ready(summary: RunSummaryRecord) -> void:
	game_hud.present_run_summary(summary)
	vertical_slice_overlay.present_run_summary(summary)
	tutorial_controller.clear_for_run_end()
	if app_state != null and summary != _last_recorded_summary:
		_last_recorded_summary = summary
		app_state.record_completed_run(_summary_outcome_id(summary.result), summary.elites_defeated)


func _summary_outcome_id(result: int) -> StringName:
	match result:
		RunDirector.RunResult.VICTORY:
			return &"victory"
		RunDirector.RunResult.EXTRACTED:
			return &"extracted"
		RunDirector.RunResult.DEFEATED:
			return &"defeated"
	return &""


func _request_backup_activation() -> void:
	call_backup_controller.request_activation()


func _create_backup_ally(_activation_token: int, ally_index: int) -> Node2D:
	var lane: int = 0 if ally_index == 0 else 2
	return encounter_controller.spawn_temporary_ally(&"backup_runner", lane)


func _confirm_backup_ally_registered(ally: Node2D) -> bool:
	var actor: ActorController = ally as ActorController
	return (
		actor != null
		and actor in combat_director.get_live_actors(ActorController.Team.CREW)
	)


func _remove_backup_ally(ally: Node2D, _reason: StringName) -> void:
	var actor: ActorController = ally as ActorController
	if actor != null:
		encounter_controller.remove_temporary_ally(actor)


func _on_backup_activation_accepted(
	_activation_token: int,
	_allies: Array[Node2D],
	charges_remaining: int
) -> void:
	audio_controller.play_cue(&"sfx_intervention_activation")
	_on_action_feedback("BACKUP DEPLOYED - %d CHARGE%s LEFT" % [
		charges_remaining,
		"" if charges_remaining == 1 else "S",
	])
	_present_tech_cooldown_callout(
		"BACKUP",
		call_backup_controller.definition.cooldown_seconds
	)


func _on_backup_activation_rejected(reason: StringName) -> void:
	_on_action_feedback("CALL BACKUP REJECTED - %s" % String(reason).replace("_", " ").to_upper())


func _on_backup_activation_ended(_activation_token: int, reason: StringName) -> void:
	_on_action_feedback("BACKUP LEFT - %s" % String(reason).replace("_", " ").to_upper())


func _on_actor_incapacitated(actor: ActorController) -> void:
	if actor != null and actor.actor_definition != null and actor.actor_definition.is_temporary_ally():
		call_backup_controller.notify_ally_defeated(actor)


func _on_combo_snapshot_changed(snapshot: Dictionary) -> void:
	if run_director.current_state != RunDirector.RunState.ENCOUNTER_ACTIVE:
		vertical_slice_overlay.hide_combo()
		return
	vertical_slice_overlay.present_combo(
		int(snapshot.get("current_combo", 0)),
		int(snapshot.get("highest_combo", 0))
	)


func _refresh_combo_presentation_for_state(state: int) -> void:
	if state != RunDirector.RunState.ENCOUNTER_ACTIVE:
		vertical_slice_overlay.hide_combo()
		return
	_on_combo_snapshot_changed(combo_tracker.get_snapshot())


func _on_tutorial_prompt_presented(prompt: TutorialPromptDefinition) -> void:
	if prompt == null:
		return
	_tutorial_remaining = prompt.display_seconds
	vertical_slice_overlay.present_tutorial(
		prompt.id,
		"%s - %s" % [prompt.heading.to_upper(), prompt.body]
	)


func _on_tutorial_prompt_dismissed(_prompt_id: StringName) -> void:
	_tutorial_remaining = 0.0
	vertical_slice_overlay.hide_tutorial()


func _on_coin_cluster_presented(cluster: CoinCluster) -> void:
	if cluster == null:
		return
	cadence_tracker.record_coin_cluster_presented(
		cluster.get_cluster_id(),
		run_director.run_elapsed_seconds
	)
	tutorial_controller.request_trigger(&"coin_cluster_available")


func _on_standard_reward_ready(
	encounter_instance_id: int,
	_reward: StandardRewardDefinition
) -> void:
	if run_director.is_district_loop_enabled():
		return
	if _strategic_reward_encounters.has(encounter_instance_id):
		return
	_strategic_reward_encounters[encounter_instance_id] = true
	cadence_tracker.record_strategic_opportunity(
		StringName("encounter_reward:%d" % encounter_instance_id),
		run_director.run_elapsed_seconds
	)


func _on_district_block_completed(
	lap_index: int,
	block_index: int,
	block_id: StringName
) -> void:
	cadence_tracker.record_strategic_opportunity(
		StringName("district_block:%s:%d:%d" % [block_id, lap_index, block_index]),
		run_director.run_elapsed_seconds
	)


func _on_extraction_became_available(threshold_index: int) -> void:
	cadence_tracker.record_major_opportunity(
		StringName("extraction:%d" % threshold_index),
		run_director.run_elapsed_seconds
	)
	tutorial_controller.request_trigger(&"extraction_available")
	audio_controller.play_cue(&"sfx_night_pressure_warning")
	audio_controller.play_cue(&"sfx_extraction_available")


func _on_boss_intro_started() -> void:
	cadence_tracker.record_major_opportunity(
		&"boss_commitment",
		run_director.run_elapsed_seconds
	)
	audio_controller.play_cue(&"sfx_night_pressure_warning")


func _on_heat_tier_changed(_previous_tier: int, _new_tier: int) -> void:
	audio_controller.play_cue(&"sfx_heat_tier_increase")


func _on_card_placed(_record: CardPlacementRecord) -> void:
	audio_controller.play_cue(&"sfx_card_placement")


func _on_ui_confirmed() -> void:
	if _web_audio_unlocked:
		audio_controller.play_cue(&"sfx_ui_confirm")


func _on_ui_hovered() -> void:
	if _web_audio_unlocked:
		audio_controller.play_cue(&"sfx_ui_hover")


func _route_existing_audio_to_sound_effects_bus() -> void:
	AudioBusContract.ensure_required_buses()
	for node: Node in combat_feedback.find_children("*", "AudioStreamPlayer", true, false):
		var player: AudioStreamPlayer = node as AudioStreamPlayer
		if player != null:
			player.bus = AudioBusContract.BUS_SOUND_EFFECTS


func _on_primary_action_requested() -> void:
	match run_director.current_state:
		RunDirector.RunState.REWARD_SELECTION:
			if bool(run_flow_controller.get_snapshot().get("card_reward_phase_active", false)):
				_on_action_feedback("CHOOSE A DISTRICT CARD OR KEEP HAND")
				return
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
			run_flow_controller.decline_extraction(run_director.get_district_decision_token())
		RunDirector.RunState.BOSS_INTRO:
			run_flow_controller.enter_boss_trigger()


func _on_flow_status_changed(snapshot: Dictionary) -> void:
	game_hud.present_flow_snapshot(snapshot)
	game_hud.present_district_cards(
		snapshot.get("cards", {}),
		snapshot.get("patrol", {})
	)
	downtown_loop.present_route_snapshot(snapshot.get("patrol", {}))
	debug_overlay.present_run_flow(snapshot)
	_refresh_hydrant_presentation()
	_refresh_combat_presentation()


func _on_action_feedback(message: String) -> void:
	game_hud.present_action_feedback(message)
	_hydrant_feedback_override = message
	_hydrant_feedback_remaining = 1.2


func _on_build_changed(snapshot: Dictionary) -> void:
	game_hud.present_build_snapshot(snapshot)
	_refresh_intervention_cooldown_multiplier()
	_refresh_hydrant_presentation()


func _refresh_intervention_cooldown_multiplier() -> void:
	var equipment_multiplier: float = maxf(
		0.05,
		1.0 + synergy_system.get_percent_modifier(&"intervention_cooldown")
	)
	var crew_multiplier: float = (
		_selected_crew_actor.get_intervention_cooldown_multiplier()
		if _selected_crew_actor != null and is_instance_valid(_selected_crew_actor)
		else 1.0
	)
	var cooldown_multiplier: float = maxf(crew_multiplier * equipment_multiplier, 0.05)
	fire_hydrant_controller.set_cooldown_multiplier(cooldown_multiplier)
	call_backup_controller.set_cooldown_multiplier(cooldown_multiplier)


func _on_equipment_reward_ready(
	encounter_instance_id: int,
	choices: Array[EquipmentDefinition]
) -> void:
	var previews_by_choice: Array[Dictionary] = []
	for choice_index: int in range(choices.size()):
		var by_slot: Array[Dictionary] = []
		var by_slot_and_backpack: Array = []
		for slot_index: int in range(SynergySystem.SLOT_COUNT):
			by_slot.append(_enrich_build_preview(
				reward_director.get_equipment_choice_preview(
					encounter_instance_id,
					choice_index,
					slot_index
				)
			))
			var by_backpack_target: Array[Dictionary] = []
			for backpack_slot: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
				by_backpack_target.append(_enrich_build_preview(
					reward_director.get_equipment_choice_preview(
						encounter_instance_id,
						choice_index,
						slot_index,
						backpack_slot
					)
				))
			by_slot_and_backpack.append(by_backpack_target)
		var by_backpack_slot: Array[Dictionary] = []
		for backpack_slot: int in range(SynergySystem.BACKPACK_SLOT_COUNT):
			by_backpack_slot.append(_enrich_build_preview(
				synergy_system.preview_stored_equipment(
					choices[choice_index],
					backpack_slot
				)
			))
		previews_by_choice.append({
			"by_slot": by_slot,
			"by_slot_and_backpack": by_slot_and_backpack,
			"by_backpack_slot": by_backpack_slot,
		})
	var standard_preview: Dictionary = reward_director.get_pending_standard_reward_preview(
		encounter_instance_id
	)
	var standard_reward: StandardRewardDefinition = reward_director.get_pending_standard_reward(
		encounter_instance_id
	)
	if standard_reward != null:
		standard_preview["display_name"] = standard_reward.display_name
		standard_preview["reward_id"] = standard_reward.id
	game_hud.present_equipment_reward(
		encounter_instance_id,
		choices,
		previews_by_choice,
		reward_director.get_pending_equipment_choice_token(encounter_instance_id),
		standard_preview
	)
	# The focused WP04 surface contains the complete staged transaction lesson.
	# A legacy tutorial banner would obscure the exact destination and payout.
	while tutorial_controller.dismiss_current():
		pass


func _enrich_build_preview(preview: Dictionary) -> Dictionary:
	if _selected_crew_actor == null or not is_instance_valid(_selected_crew_actor):
		return preview
	return BuildConsequenceEvaluator.enrich_preview(
		preview,
		_selected_crew_actor.actor_definition,
		_selected_crew_actor.attack_definition,
		fire_hydrant_controller.tuning.cooldown_seconds,
		call_backup_controller.definition.cooldown_seconds
	)


func _on_equipment_acquisition_requested(
	encounter_instance_id: int,
	choice_token: int,
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
		expected_revision,
		encounter_instance_id,
		choice_token
	)
	game_hud.present_equipment_action_result(applied)
	if applied:
		game_hud.dismiss_equipment_reward()
	else:
		_on_action_feedback("EQUIPMENT CHOICE REJECTED")


func _on_equipment_reward_decline_requested(
	encounter_instance_id: int,
	choice_token: int
) -> void:
	var declined: bool = run_flow_controller.decline_equipment_reward(
		encounter_instance_id,
		choice_token
	)
	game_hud.present_equipment_action_result(declined)
	if declined:
		game_hud.dismiss_equipment_reward()
		var reward_result: Dictionary = reward_director.get_applied_standard_reward_result(
			encounter_instance_id
		)
		_on_action_feedback("SKIPPED GEAR • CURRENT BUILD KEPT • RUN REWARD +%d COINS +%d SCRAP" % [
			int(reward_result.get("awarded_coins", 0)),
			int(reward_result.get("awarded_scrap", 0)),
		])


func _on_card_reward_ready(
	encounter_instance_id: int,
	choice_token: int,
	choices: Array[DistrictCardDefinition],
	hand_revision: int,
	_hand_full: bool
) -> void:
	game_hud.present_district_card_reward(
		encounter_instance_id,
		choice_token,
		choices,
		hand_revision,
		true
	)


func _on_card_planning_open_requested() -> void:
	if run_flow_controller.begin_card_planning():
		return
	game_hud.dismiss_district_card_panel()
	game_hud.present_district_card_placement_result({
		"accepted": false,
		"reason": &"planning_unavailable",
	})


func _on_card_planning_close_requested() -> void:
	run_flow_controller.end_card_planning()


func _on_card_placement_staged(
	card_id: StringName,
	slot_id: StringName,
	hand_revision: int,
	route_revision: int
) -> void:
	var result: Dictionary = run_flow_controller.stage_card_placement(
		card_id,
		slot_id,
		hand_revision,
		route_revision
	)
	game_hud.present_district_card_placement_result(result)


func _on_card_placement_confirm_requested(confirmation_token: int) -> void:
	var result: Dictionary = run_flow_controller.confirm_card_placement(
		confirmation_token
	)
	result["completed"] = bool(result.get("accepted", false))
	game_hud.present_district_card_placement_result(result)


func _on_card_placement_cancel_requested(confirmation_token: int) -> void:
	run_flow_controller.cancel_card_placement(confirmation_token)


func _on_district_plan_choice_requested(
	card_id: StringName,
	offer_revision: int,
	lifecycle_revision: int,
	lap_id: StringName,
	block_id: StringName
) -> void:
	var staged: Dictionary = run_flow_controller.stage_focused_district_plan_choice(
		card_id,
		offer_revision,
		lifecycle_revision,
		lap_id,
		block_id
	)
	if not bool(staged.get("accepted", false)):
		game_hud.present_district_card_placement_result(staged)
		return
	var confirmed: Dictionary = (
		run_flow_controller.confirm_focused_district_plan_choice(
			int(staged.get("confirmation_token", -1))
		)
	)
	game_hud.present_district_card_placement_result(confirmed)


func _on_district_plan_offer_started(
	_lap_index: int,
	_block_index: int,
	_offer_revision: int,
	_choices: Array[DistrictCardDefinition]
) -> void:
	# The focused plan is already the complete contextual teaching surface. The
	# older nonmodal tutorial banner would otherwise sit over its prediction copy
	# forever because mandatory planning owns a paused safe boundary.
	while tutorial_controller.dismiss_current():
		pass
	tutorial_controller.request_trigger(&"card_planning_available")
	while tutorial_controller.dismiss_current():
		pass
	_tutorial_remaining = 0.0
	vertical_slice_overlay.hide_tutorial()


func _on_card_reward_acquisition_requested(
	encounter_instance_id: int,
	choice_token: int,
	choice_index: int,
	hand_revision: int
) -> void:
	var acquired: bool = run_flow_controller.claim_card_reward(
		encounter_instance_id,
		choice_token,
		choice_index,
		hand_revision
	)
	game_hud.present_district_card_acquisition_result(
		acquired,
		"hand_full_or_stale" if not acquired else ""
	)


func _on_card_reward_skip_requested(
	encounter_instance_id: int,
	choice_token: int
) -> void:
	var skipped: bool = run_flow_controller.skip_card_reward(
		encounter_instance_id,
		choice_token
	)
	game_hud.present_district_card_acquisition_result(
		skipped,
		"stale_reward" if not skipped else ""
	)


func _on_inventory_preview_requested(
	action: StringName,
	source_area: StringName,
	source_slot: int,
	target_slot: int,
	equipment_id: StringName,
	expected_revision: int
) -> void:
	var preview: Dictionary = synergy_system.preview_inventory_transaction(
		action,
		source_area,
		source_slot,
		target_slot,
		equipment_id,
		expected_revision
	)
	game_hud.present_inventory_transaction_preview(_enrich_build_preview(preview))


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
	encounter_instance_id: int,
	_choice_index: int,
	equipment: EquipmentDefinition,
	destination: StringName,
	equipment_slot: int,
	backpack_slot: int
) -> void:
	var reward_result: Dictionary = reward_director.get_applied_standard_reward_result(
		encounter_instance_id
	)
	var reward_suffix: String = " • RUN REWARD +%d COINS +%d SCRAP" % [
		int(reward_result.get("awarded_coins", 0)),
		int(reward_result.get("awarded_scrap", 0)),
	]
	if destination == SynergySystem.AREA_BACKPACK:
		_on_action_feedback("STORED %s IN BACKPACK SLOT %d • ACTIVE BUILD UNCHANGED%s" % [
			equipment.display_name.to_upper(),
			backpack_slot + 1,
			reward_suffix,
		])
	else:
		_on_action_feedback("EQUIPPED %s IN ACTIVE SLOT %d • %s%s" % [
			equipment.display_name.to_upper(),
			equipment_slot + 1,
			equipment.combat_promise.to_upper(),
			reward_suffix,
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
	game_hud.present_build_callout(
		synergy.badge,
		"SYNERGY ACTIVE • %s" % synergy.display_name,
		synergy.combat_promise,
		StringName("synergy_active:%s" % synergy.id)
	)


func _on_synergy_deactivated(synergy: SynergyDefinition) -> void:
	_on_action_feedback("%s DEACTIVATED" % synergy.display_name.to_upper())
	game_hud.present_build_callout(
		synergy.badge,
		"SYNERGY LOST • %s" % synergy.display_name,
		synergy.combat_promise,
		StringName("synergy_lost:%s" % synergy.id)
	)


func _on_lane_visibility_requested(lanes_are_visible: bool) -> void:
	downtown_loop.set_debug_lanes_visible(lanes_are_visible)


func _on_actor_registered(actor: ActorController) -> void:
	actor.set_hit_flash_reduction(_hit_flash_reduction)
	if (
		actor.is_permanent_crew()
		and _active_content_access != null
		and actor.definition_id() == _active_content_access.selected_crew_id
	):
		_selected_crew_actor = actor
		_refresh_intervention_cooldown_multiplier()
	combat_feedback.show_spawn(actor.global_position + Vector2(0.0, -24.0))


func _on_actor_died(actor: ActorController) -> void:
	combat_feedback.show_death(actor.global_position + Vector2(0.0, -25.0))
	_refresh_combat_presentation()


func _on_encounter_started_build_expression(
	_encounter_instance_id: int,
	_definition: EncounterDefinition,
	_spawn_budget: int
) -> void:
	var active_synergies: Array[SynergyDefinition] = synergy_system.get_active_synergies()
	if not active_synergies.is_empty():
		var synergy: SynergyDefinition = active_synergies[0]
		game_hud.present_build_callout(
			synergy.badge,
			"BUILD ONLINE • %s" % synergy.display_name,
			synergy.combat_promise,
			StringName("encounter_build:%s" % synergy.id)
		)
		return
	var active_items: Array[EquipmentDefinition] = synergy_system.get_equipped_items_stable()
	if active_items.is_empty():
		return
	var item: EquipmentDefinition = active_items[0]
	game_hud.present_build_callout(
		item.icon,
		"BUILD ONLINE • %s" % item.display_name,
		item.combat_promise,
		StringName("encounter_build:%s" % item.id)
	)


func _on_boss_encounter_started(
	_encounter_instance_id: int,
	_definition: EncounterDefinition,
	boss: ActorController
) -> void:
	_boss_actor = boss
	_boss_phase_text = "PHASE 1"
	_boss_telegraph_text = "READ THE NAMED WARNING"
	_boss_telegraph_remaining = BOSS_TELEGRAPH_MINIMUM_SECONDS
	if not boss.health_changed.is_connected(_on_boss_health_changed):
		boss.health_changed.connect(_on_boss_health_changed)
	_refresh_boss_presentation()


func _on_boss_health_changed(
	_actor: ActorController,
	_current_health: int,
	_maximum_health: int
) -> void:
	_refresh_boss_presentation()


func _on_boss_defeated(_boss: ActorController) -> void:
	_boss_phase_text = "DEFEATED"
	_boss_telegraph_text = "VIPER DOWN"
	_boss_telegraph_remaining = 2.0
	_refresh_boss_presentation()


func _on_attack_telegraphed(
	attacker: ActorController,
	attack: AttackDefinition,
	duration_seconds: float,
	world_position: Vector2,
	area_radius: float
) -> void:
	if attacker == null or attack == null or not attacker.is_boss():
		return
	_boss_telegraph_text = "WARNING: %s" % attack.display_name.to_upper()
	_boss_telegraph_remaining = maxf(duration_seconds, BOSS_TELEGRAPH_MINIMUM_SECONDS)
	var marker_radius: float = area_radius
	if marker_radius <= 0.0:
		match attack.delivery_kind:
			AttackDefinition.DeliveryKind.CHARGE:
				marker_radius = 48.0
			AttackDefinition.DeliveryKind.SUMMON:
				marker_radius = 64.0
	if marker_radius > 0.0:
		var telegraph: CombatTelegraph = CombatTelegraph.new()
		$DowntownLoop/EffectsContainer.add_child(telegraph)
		telegraph.present(
			world_position,
			marker_radius,
			_boss_telegraph_remaining,
			attack.display_name
		)
	_refresh_boss_presentation()


func _set_combat_telegraphs_suspended(suspended: bool) -> void:
	for child: Node in $DowntownLoop/EffectsContainer.get_children():
		var telegraph: CombatTelegraph = child as CombatTelegraph
		if telegraph != null:
			telegraph.set_suspended(suspended)


func _clear_combat_telegraphs() -> void:
	for child: Node in $DowntownLoop/EffectsContainer.get_children():
		if child is CombatTelegraph:
			child.free()


func _on_cooling_audio_applied(source_id: StringName, _heat_reduction: int) -> void:
	if source_id == &"subway_reroute":
		audio_controller.play_cue(&"sfx_intervention_activation")


func _on_shop_purchase_resolved(result: Dictionary) -> void:
	game_hud.present_shop_purchase_result(result)
	if bool(result.get("accepted", false)):
		audio_controller.play_cue(&"sfx_ui_confirm")


func _on_standard_reward_result_available(result: Dictionary) -> void:
	if not bool(result.get("applied", false)):
		return
	_on_action_feedback("RUN REWARD SECURED • +%d COINS +%d SCRAP" % [
		int(result.get("awarded_coins", 0)),
		int(result.get("awarded_scrap", 0)),
	])


func _on_boss_phase_changed(boss: ActorController, phase_id: StringName) -> void:
	if boss == null or boss != _boss_actor:
		return
	_boss_phase_text = String(phase_id).replace("_", " ").to_upper()
	_boss_telegraph_text = "ENRAGED - FASTER, HARDER HITS"
	_boss_telegraph_remaining = 2.0
	audio_controller.play_cue(&"sfx_night_pressure_warning")
	_refresh_boss_presentation()


func _refresh_boss_presentation() -> void:
	if (
		_boss_actor == null
		or not is_instance_valid(_boss_actor)
		or run_director.current_state not in [
			RunDirector.RunState.BOSS_ACTIVE,
			RunDirector.RunState.VICTORY,
		]
	):
		vertical_slice_overlay.hide_boss()
		return
	var snapshot: Dictionary = _boss_actor.get_snapshot()
	vertical_slice_overlay.present_boss(
		str(snapshot.get("display_name", "The Viper")),
		int(snapshot.get("current_health", 0)),
		int(snapshot.get("maximum_health", 1)),
		_boss_phase_text,
		_boss_telegraph_text
	)


func _on_hit_landed(
	attacker: ActorController,
	target: ActorController,
	damage: int,
	world_position: Vector2,
	hit_stop_duration: float
) -> void:
	if attacker != null and attacker.team == ActorController.Team.CREW and damage > 0:
		combo_tracker.record_crew_hit()
	var heavy_hit: bool = hit_stop_duration >= 0.06
	if target != null and target.is_boss():
		screen_shake_controller.request_boss_hit()
	elif heavy_hit:
		screen_shake_controller.request_heavy_hit()
	else:
		screen_shake_controller.request_light_hit()
	audio_controller.play_cue(&"sfx_heavy_hit" if heavy_hit else &"sfx_light_hit")
	if target != null and target.is_knocked_back():
		audio_controller.play_cue(&"sfx_knockback")
	combat_feedback.show_hit(
		world_position + Vector2(0.0, -28.0),
		float(damage),
		heavy_hit
	)


func _on_equipment_status_applied(
	_target: ActorController,
	status_id: StringName,
	stacks: int,
	duration_seconds: float,
	source_effect_id: StringName
) -> void:
	var source: Dictionary = synergy_system.get_triggered_effect_source(source_effect_id)
	if source.is_empty():
		return
	var detail: String = "%s +%d • %.1fs" % [
		String(status_id).to_upper(),
		maxi(stacks, 1),
		maxf(duration_seconds, 0.0),
	]
	if status_id == &"shock":
		detail = "SHOCKED %.1fs • ENV DMG +%d%%" % [
			maxf(duration_seconds, 0.0),
			int(round(SHOCK_STATUS.intervention_damage_taken_bonus * 100.0)),
		]
	game_hud.present_build_callout(
		source.get("icon") as Texture2D,
		str(source.get("display_name", "BUILD PROC")),
		detail,
		StringName("status_proc:%s" % source_effect_id)
	)


func _on_environmental_hit_landed(
	_source_id: StringName,
	_target: ActorController,
	damage: int,
	world_position: Vector2,
	_knockback_force: float
) -> void:
	if damage > 0:
		combo_tracker.record_environmental_hit()
		screen_shake_controller.request_environmental_hit()
	if _target != null and _knockback_force > 0.0 and _target.is_knocked_back():
		audio_controller.play_cue(&"sfx_knockback")
	combat_feedback.show_hydrant_impact(
		world_position + Vector2(0.0, -28.0),
		float(damage),
		fire_hydrant_controller.tuning.impact_duration
	)


func _on_environmental_collision_landed(
	_source_id: StringName,
	_source_actor: ActorController,
	_target: ActorController,
	damage: int,
	_world_position: Vector2,
	impact_force: float
) -> void:
	if damage <= 0:
		return
	combo_tracker.record_environmental_hit()
	screen_shake_controller.request_environmental_hit()
	audio_controller.play_cue(&"sfx_environment_collision")
	var synergy: SynergyDefinition = synergy_system.get_synergy_definition(&"knockback_2")
	if synergy != null and synergy_system.is_synergy_active(synergy.id):
		game_hud.present_build_callout(
			synergy.badge,
			synergy.display_name,
			"WALL HIT %d DAMAGE • IMPACT %.0f • %s" % [
				damage,
				impact_force,
				str(synergy.major_effects[1]).to_upper() if synergy.major_effects.size() > 1 else "SYNERGY ACTIVE",
			],
			&"knockback_wall_hit"
		)


func _on_crew_status_changed(
	actor: ActorController,
	current_health: int,
	maximum_health: int,
	state: int
) -> void:
	if actor == null or not actor.is_permanent_crew() or actor != _selected_crew_actor:
		return
	game_hud.present_crew_status(
		actor.actor_definition.display_name,
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
	audio_controller.play_cue(
		&"sfx_coin_manual_collect" if manual else &"sfx_coin_auto_collect"
	)
	if manual and resulting_streak > 1:
		audio_controller.play_cue(&"sfx_coin_streak_increase")
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
	audio_controller.play_cue(&"sfx_intervention_activation")
	screen_shake_controller.request_environmental_hit()
	_hydrant_feedback_override = "%d ENEM%s BLASTED" % [
		affected_count,
		"Y" if affected_count == 1 else "IES",
	]
	_hydrant_feedback_remaining = maxf(fire_hydrant_controller.tuning.impact_duration, 0.01)
	_present_tech_cooldown_callout(
		"HYDRANT",
		fire_hydrant_controller.tuning.cooldown_seconds
	)
	_refresh_hydrant_presentation()


func _present_tech_cooldown_callout(action_name: String, base_cooldown: float) -> void:
	var equipment_modifier: float = synergy_system.get_percent_modifier(&"intervention_cooldown")
	if equipment_modifier >= -0.0001:
		return
	var crew_multiplier: float = (
		_selected_crew_actor.get_intervention_cooldown_multiplier()
		if _selected_crew_actor != null and is_instance_valid(_selected_crew_actor)
		else 1.0
	)
	var crew_baseline: float = maxf(base_cooldown, 0.0) * crew_multiplier
	var actual: float = crew_baseline * maxf(1.0 + equipment_modifier, 0.05)
	var synergy: SynergyDefinition = synergy_system.get_synergy_definition(&"tech_2")
	game_hud.present_build_callout(
		synergy.badge if synergy != null else null,
		"TECH BUILD • %s" % action_name,
		"COOLDOWN %.2fs • READY %.2fs SOONER" % [actual, crew_baseline - actual],
		StringName("tech_cooldown:%s" % action_name.to_lower())
	)


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
	var found_selected_crew: bool = false
	for snapshot: Dictionary in snapshots:
		var instance_id: int = int(snapshot.get("instance_id", -1))
		var target_name: String = display_name_by_id.get(
			int(snapshot.get("target_instance_id", -1)),
			"NONE"
		)
		var slot_index: int = reservation_by_attacker.get(instance_id, -1)
		var slot_text: String = str(slot_index) if slot_index >= 0 else "NONE"
		if int(snapshot.get("team", ActorController.Team.ENEMY)) == ActorController.Team.CREW:
			if int(snapshot.get("combat_role", -1)) != ActorDefinition.CombatRole.PERMANENT_CREW:
				continue
			if (
				_active_content_access != null
				and StringName(snapshot.get("definition_id", &""))
				!= _active_content_access.selected_crew_id
			):
				continue
			found_selected_crew = true
			var actor_state_name: StringName = StringName(str(snapshot.get("state_name", "UNKNOWN")))
			game_hud.present_crew_status(
				str(snapshot.get("display_name", "Crew")),
				float(snapshot.get("current_health", 0)),
				float(snapshot.get("maximum_health", 1)),
				actor_state_name,
				target_name
			)
			debug_overlay.present_crew_debug(
				str(snapshot.get("display_name", "Crew")),
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
	if not found_selected_crew:
		debug_overlay.present_crew_debug(
			_selected_crew_debug_name(),
			&"INCAPACITATED",
			"NONE",
			1,
			"NONE"
		)
	debug_overlay.present_enemy_debug(enemy_lines)


func _selected_crew_debug_name() -> String:
	if _active_content_access == null:
		return "CREW"
	for definition: ActorDefinition in [JAX_DEFINITION, ZOEY_DEFINITION, REX_DEFINITION]:
		if definition.id == _active_content_access.selected_crew_id:
			return definition.display_name
	return String(_active_content_access.selected_crew_id).to_upper()


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
