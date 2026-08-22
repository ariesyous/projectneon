@tool
extends McpTestSuite

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/vertical_slice_overlay.tscn")


class DecisionCapture:
	extends RefCounted

	var extract_tokens: Array[int] = []
	var push_tokens: Array[int] = []

	func on_extract(token: int) -> void:
		extract_tokens.append(token)

	func on_push(token: int) -> void:
		push_tokens.append(token)


class GameFixture:
	extends RefCounted

	var viewport: SubViewport
	var game: GameRun
	var app: NeonAppState
	var service: ProfileSaveService


func suite_name() -> String:
	return "wp02_state_clarity"


func test_fresh_production_menu_exposes_all_crew_before_any_gameplay_draw() -> void:
	var fixture: GameFixture = _new_game()
	assert_eq(fixture.app.get_accessible_crew_ids(), PersistentProfileData.ALL_CREW_IDS, "crew: all three production choices accessible")
	assert_false(fixture.game.vertical_slice_overlay.jax_button.disabled, "crew: Jax selectable")
	assert_false(fixture.game.vertical_slice_overlay.zoey_button.disabled, "crew: Zoey selectable")
	assert_false(fixture.game.vertical_slice_overlay.rex_button.disabled, "crew: Rex selectable")
	var before_draws: Dictionary = fixture.game.run_director.get_random_streams().get_debug_snapshot().get("draw_counts", {})
	for stream_name: StringName in RunRandomStreams.DECLARED_STREAM_NAMES:
		assert_eq(int(before_draws.get(stream_name, 0)), 0, "crew: %s untouched before selection" % stream_name)
	fixture.game.vertical_slice_overlay.rex_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	var access: RunContentAccessSnapshot = fixture.game.get_active_content_access_snapshot()
	assert_eq(access.selected_crew_id, &"rex", "crew: selected Rex latched")
	assert_eq(fixture.game.get_selected_crew_actor().definition_id(), &"rex", "crew: authored Rex actor starts")
	var access_identity: int = fixture.game.get_active_content_access_identity()
	var access_signature: String = access.signature()
	fixture.game.vertical_slice_overlay.restart_same_seed_requested.emit()
	assert_eq(fixture.game.get_active_content_access_identity(), access_identity, "crew: same-seed restart reuses exact access object")
	assert_eq(fixture.game.get_active_content_access_snapshot().signature(), access_signature, "crew: same-seed access signature is unchanged")
	assert_eq(fixture.game.get_selected_crew_actor().definition_id(), &"rex", "crew: same-seed restart retains selected crew")


func test_authoritative_phase_matrix_answers_phase_next_and_action() -> void:
	var hud: GameHUD = _new_hud()
	var cases: Array[Dictionary] = [
		{"state": RunDirector.RunState.PATROLLING, "phase": "PLAN", "next": "NEXT BLOCK"},
		{"state": RunDirector.RunState.ENCOUNTER_ACTIVE, "phase": "FIGHT", "next": "ENEMY ARRIVAL"},
		{"state": RunDirector.RunState.REWARD_SELECTION, "phase": "REWARD", "next": "CHOOSE GEAR"},
		{"state": RunDirector.RunState.SHOP, "phase": "SHOP", "next": "FINITE STOCK"},
		{"state": RunDirector.RunState.EXTRACTION_AVAILABLE, "phase": "LAP DECISION", "next": "FINAL LAP"},
		{"state": RunDirector.RunState.EXTRACTING, "phase": "EXTRACTION", "next": "RUN SUMMARY"},
		{"state": RunDirector.RunState.BOSS_ACTIVE, "phase": "BOSS", "next": "DEFEAT THE VIPER"},
		{"state": RunDirector.RunState.RUN_SUMMARY, "phase": "RESULT", "next": "REVIEW THE RUN"},
	]
	for record: Dictionary in cases:
		hud.present_flow_snapshot(_flow_snapshot(int(record.state)))
		assert_eq(hud.phase_banner.get_phase_text(), record.phase, "matrix: exact %s phase" % record.phase)
		assert_contains(hud.phase_banner.get_next_event_text(), record.next, "matrix: %s names next event" % record.phase)
		assert_contains(hud.phase_banner.get_progress_text(), "LAP 2/3", "matrix: %s shows active lap" % record.phase)
		assert_contains(hud.phase_banner.get_progress_text(), "BLOCK 3/3", "matrix: %s shows active block" % record.phase)

	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.SHOP))
	assert_true(hud.shop_decision_panel.visible, "shop: focused shell is unmistakable")
	assert_contains(hud.shop_cooling_choice.text, "STOCK", "shop: finite stock is explicit")
	assert_contains(hud.shop_leave_choice.text, "LEAVE", "shop: current action is explicit")
	assert_contains(hud.night_pressure_label.text, "LOCKED", "risk: persistent Night Pressure copy fits compact HUD")
	assert_contains(hud.night_pressure_label.tooltip_text, "IRREVERSIBLE", "risk: full permanence language remains available")


func test_lap_decision_copy_and_mouse_keyboard_touch_path_forward_exact_token() -> void:
	var hud: GameHUD = _new_hud()
	var capture: DecisionCapture = DecisionCapture.new()
	hud.lap_extract_requested.connect(capture.on_extract)
	hud.lap_push_requested.connect(capture.on_push)
	hud.present_flow_snapshot(_flow_snapshot(RunDirector.RunState.EXTRACTION_AVAILABLE))
	assert_true(hud.extraction_panel.visible, "decision: focused panel visible")
	assert_contains(hud.extraction_title.text, "LAP 2 COMPLETE", "decision: completed lap named")
	assert_contains(hud.extraction_button.text, "SECURE CURRENT RESULT", "decision: Extract consequence exact")
	assert_contains(hud.extraction_continue_button.text, "COMMIT TO FINAL LAP + BOSS", "decision: boss commitment unmistakable")
	assert_contains(hud.extraction_continue_button.text, "REWARD TIER +2", "decision: reward escalation exact")
	assert_contains(hud.extraction_continue_button.text, "PRESSURE x1.30", "decision: pressure escalation exact")
	assert_contains(hud.extraction_continue_button.text, "THE VIPER", "decision: next major threat named")
	assert_true(hud.extraction_button.focus_mode != Control.FOCUS_NONE, "decision: Extract keyboard focusable")
	assert_true(hud.extraction_continue_button.custom_minimum_size.y >= NeonUiTokens.TOUCH_TARGET_MINIMUM, "decision: Push touch target")
	hud.extraction_button.pressed.emit()
	hud.extraction_continue_button.pressed.emit()
	assert_eq(capture.extract_tokens, [42], "decision: Extract forwards exact authoritative token")
	assert_eq(capture.push_tokens, [42], "decision: Push forwards exact authoritative token")


func test_preserved_e_shortcut_confirms_with_exact_wp02_token() -> void:
	var fixture: GameFixture = _new_game()
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	assert_true(fixture.game.run_director.complete_intro(), "keyboard: intro reaches PLAN")
	for block_number: int in range(1, 4):
		assert_true(
			_confirm_current_district_plan(fixture.game) != null,
			"keyboard: required plan %d confirms" % block_number
		)
		var occurrence_id: StringName = StringName("keyboard_block_%02d" % block_number)
		assert_true(
			fixture.game.run_director.begin_district_block(
				occurrence_id,
				&"utility"
			),
			"keyboard: utility block %d begins" % block_number
		)
		assert_true(
			fixture.game.card_system.resolve_focused_district_plan_block(
				block_number,
				occurrence_id,
				block_number,
				StringName("keyboard_route_%02d" % block_number),
				&"travel",
				fixture.game.run_director.get_district_loop_snapshot()
			) != null,
			"keyboard: focused card %d resolves before utility completion" % block_number
		)
		assert_true(
			fixture.game.run_director.complete_district_utility_block(),
			"keyboard: utility block %d completes" % block_number
		)
		if block_number < 3:
			assert_true(
				fixture.game.run_flow_controller._begin_required_focused_district_plan(),
				"keyboard: next required PLAN %d opens" % (block_number + 1)
			)
	assert_eq(
		fixture.game.run_director.current_state,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
		"keyboard: first lap exposes decision"
	)
	var exact_token: int = fixture.game.run_director.get_district_decision_token()
	assert_true(exact_token > 0, "keyboard: decision has an authoritative token")
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.pressed = true
	fixture.game._input(key_event)
	assert_eq(
		fixture.game.run_director.current_state,
		RunDirector.RunState.EXTRACTING,
		"keyboard: E forwards the exact token and begins extraction"
	)
	assert_eq(
		fixture.game.run_director.get_district_loop_snapshot().get("phase_name"),
		"EXTRACTION",
		"keyboard: lifecycle enters EXTRACTION"
	)


func test_configured_flow_enters_first_stable_block_and_records_wp02_cadence() -> void:
	var fixture: GameFixture = _new_game()
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	var chosen: DistrictCardDefinition = _confirm_current_district_plan(fixture.game)
	assert_true(chosen != null, "flow: focused next-block choice confirms")
	if chosen == null:
		return
	var planned: Dictionary = fixture.game.card_system.get_snapshot().get(
		"selected_next_block",
		{}
	) as Dictionary
	assert_eq(planned.get("block_id"), &"district_lap_01::block_01", "flow: stable first block ID is selected")
	fixture.game.patrol_controller.step_patrol(100.0)
	var active_loop: Dictionary = fixture.game.run_director.get_district_loop_snapshot()
	assert_eq(active_loop.get("lap_id"), &"district_lap_01", "flow: stable first lap ID")
	assert_eq(fixture.game.cadence_tracker.definition.id, &"wp02_block_lap_cadence", "cadence: WP02 measurement resource configured")
	assert_eq(fixture.game.cadence_tracker.definition.strategic_minimum_seconds, 45.0, "cadence: block minimum is 45 seconds")
	assert_eq(fixture.game.cadence_tracker.definition.strategic_maximum_seconds, 90.0, "cadence: block maximum is 90 seconds")
	var block_kind: StringName = CardSystem.focused_block_kind(chosen)
	match block_kind:
		&"fight", &"elite":
			assert_eq(fixture.game.run_director.current_state, RunDirector.RunState.ENCOUNTER_ACTIVE, "flow: chosen fight enters combat")
			assert_eq(active_loop.get("phase_name"), "FIGHT", "flow: authoritative phase is FIGHT")
			assert_true(StringName(active_loop.get("current_route_occurrence_id", &"")) != &"", "flow: internal route occurrence retained")
			var encounter_id: int = fixture.game.encounter_controller.get_active_encounter_instance_id()
			var definition: EncounterDefinition = fixture.game.encounter_controller.get_active_definition()
			fixture.game.run_flow_controller._on_encounter_completed(encounter_id, definition)
			assert_eq(fixture.game.run_director.current_state, RunDirector.RunState.REWARD_SELECTION, "flow: fight enters reward")
			fixture.game.run_flow_controller.decline_equipment_reward()
		&"shop":
			assert_eq(fixture.game.run_director.current_state, RunDirector.RunState.SHOP, "flow: chosen recovery enters shop")
			assert_true(fixture.game.run_flow_controller.leave_shop(), "flow: leaving shop completes block")
		&"utility":
			assert_eq(active_loop.get("completed_blocks"), 1, "flow: transit utility completes immediately")
	var completed_loop: Dictionary = fixture.game.run_director.get_district_loop_snapshot()
	assert_eq(completed_loop.get("completed_blocks"), 1, "flow: reward closes exactly one block")
	assert_eq(completed_loop.get("block_id"), &"district_lap_01::block_02", "flow: next stable block prepared")
	assert_eq(completed_loop.get("phase_name"), "PLAN", "flow: reward returns to PLAN")
	assert_eq(fixture.game.cadence_tracker.get_event_count(RunCadenceTracker.CATEGORY_STRATEGIC), 1, "cadence: exactly one complete-block opportunity recorded")


func test_result_presentation_recalls_loop_and_decisions_without_dropping_m6_detail() -> void:
	var viewport: SubViewport = _new_viewport()
	var overlay: VerticalSliceOverlay = OVERLAY_SCENE.instantiate() as VerticalSliceOverlay
	viewport.add_child(overlay)
	var summary: RunSummaryRecord = RunSummaryRecord.new()
	summary.result_label = "EXTRACTED"
	summary.duration_seconds = 322.0
	summary.run_seed = 2205
	summary.random_schema_version = 1
	summary.laps_completed = 2
	summary.blocks_completed = 6
	summary.boss_committed = false
	summary.coins_collected = 144
	summary.equipment_build = "SPiked Bat / Shock Gloves"
	summary.active_synergies = "TECH 2"
	summary.lap_decisions = [
		{"decision": &"push"},
		{"decision": &"extract"},
	]
	overlay.present_run_summary(summary)
	assert_contains(overlay.summary_highlight.text, "2 LAPS", "result: completed laps lead the summary")
	assert_contains(overlay.summary_highlight.text, "6 BLOCKS", "result: completed blocks lead the summary")
	assert_contains(overlay.summary_left.text, "DISTRICT LAPS  2 / 3", "result: exact lap total retained")
	assert_contains(overlay.summary_right.text, "PUSH > EXTRACT", "result: decision trail recalled")
	assert_contains(overlay.summary_right.text, "EQUIPMENT BUILD", "result: complete M6 build detail preserved")


func _new_game() -> GameFixture:
	var fixture: GameFixture = GameFixture.new()
	fixture.service = track(ProfileSaveService.new("user://wp02_state_clarity.json")) as ProfileSaveService
	fixture.app = track(NeonAppState.new()) as NeonAppState
	fixture.app.initialize(fixture.service, false)
	fixture.viewport = _new_viewport()
	fixture.game = GAME_SCENE.instantiate() as GameRun
	fixture.game.app_state_override = fixture.app
	fixture.viewport.add_child(fixture.game)
	return fixture


func _confirm_current_district_plan(game: GameRun) -> DistrictCardDefinition:
	var cards: Dictionary = game.card_system.get_snapshot()
	var offer: Array = cards.get("offer", []) as Array
	if offer.is_empty():
		return null
	var card: DistrictCardDefinition = offer[0] as DistrictCardDefinition
	if card == null:
		return null
	var staged: Dictionary = game.run_flow_controller.stage_focused_district_plan_choice(
		card.id,
		int(cards.get("offer_revision", -1)),
		int(cards.get("context_lifecycle_revision", -1)),
		StringName(cards.get("lap_id", &"")),
		StringName(cards.get("block_id", &""))
	)
	if not bool(staged.get("accepted", false)):
		return null
	var confirmed: Dictionary = game.run_flow_controller.confirm_focused_district_plan_choice(
		int(staged.get("confirmation_token", -1))
	)
	return card if bool(confirmed.get("accepted", false)) else null


func _new_hud() -> GameHUD:
	var viewport: SubViewport = _new_viewport()
	var hud: GameHUD = HUD_SCENE.instantiate() as GameHUD
	viewport.add_child(hud)
	return hud


func _new_viewport() -> SubViewport:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(viewport)
	return viewport


func _flow_snapshot(state: int) -> Dictionary:
	var phase_name: String = "PLAN"
	match state:
		RunDirector.RunState.ENCOUNTER_ACTIVE:
			phase_name = "FIGHT"
		RunDirector.RunState.REWARD_SELECTION:
			phase_name = "REWARD"
		RunDirector.RunState.SHOP:
			phase_name = "SHOP"
		RunDirector.RunState.EXTRACTION_AVAILABLE:
			phase_name = "LAP DECISION"
		RunDirector.RunState.EXTRACTING:
			phase_name = "EXTRACTION"
		RunDirector.RunState.BOSS_ACTIVE:
			phase_name = "BOSS"
		RunDirector.RunState.RUN_SUMMARY:
			phase_name = "RESULT"
	return {
		"run": {
			"state": state,
			"run_elapsed_seconds": 360.0,
			"heat": 44,
			"heat_tier": 2,
			"night_pressure": 38.0,
			"boss_threshold": 50.0,
			"next_major_threshold": 50.0,
			"reward_multiplier": 1.2,
			"district_loop": {
				"enabled": true,
				"phase_name": phase_name,
				"lifecycle_revision": 12,
				"lap_index": 2,
				"lap_id": &"district_lap_02",
				"lap_count": 3,
				"block_index": 3,
				"block_id": &"district_lap_02::block_03",
				"blocks_per_lap": 3,
				"completed_laps": 2,
				"completed_blocks": 6,
				"decision_token": 42,
				"boss_committed": false,
				"current_lap": {
					"modifier_label": "RISING PRESSURE",
				},
				"push_preview": {
					"lap_index": 3,
					"lap_id": &"district_lap_03",
					"modifier_label": "BOSS COMMITMENT",
					"risk_label": "FINAL LAP - NO ROUTINE EXTRACTION",
					"pressure_gain_multiplier": 1.3,
					"reward_quality_tier_bonus": 2,
					"next_threat": "THE VIPER",
					"push_heat_delta": 6,
					"final_lap_commitment": true,
				},
			},
		},
		"patrol": {
			"route_index": 2,
			"route_progress": 0.62,
			"route_node_type": &"encounter",
			"route_revision": 4,
			"loop_count": 1,
		},
		"encounter": {
			"active_encounter_name": "Viper Enforcer",
			"remaining_to_spawn": 2,
			"spawn_delay_remaining": 2.4,
		},
		"cooling": {
			"subway_charges": 2,
			"subway_heat_reduction": 15,
			"shop_purchases_remaining": 1,
			"shop_coin_cost": 60,
			"shop_heat_reduction": 18,
		},
		"rewards": {
			"coin_total": 126,
			"scrap_total": 8,
			"streak_count": 3,
		},
	}
