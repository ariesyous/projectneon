@tool
extends McpTestSuite

const GAME_SCENE: PackedScene = preload("res://scenes/game/game_run.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const CARD_CATALOGUE: DistrictCardCatalogue = preload(
	"res://data/cards/milestone_5_district_card_catalogue.tres"
)


class ChoiceCapture:
	extends RefCounted

	var requests: Array[Dictionary] = []

	func on_choice(
		card_id: StringName,
		offer_revision: int,
		lifecycle_revision: int,
		lap_id: StringName,
		block_id: StringName
	) -> void:
		requests.append({
			"card_id": card_id,
			"offer_revision": offer_revision,
			"lifecycle_revision": lifecycle_revision,
			"lap_id": lap_id,
			"block_id": block_id,
		})


class GameFixture:
	extends RefCounted

	var viewport: SubViewport
	var game: GameRun
	var app: NeonAppState
	var service: ProfileSaveService


func suite_name() -> String:
	return "wp03_district_plan_ui"


func test_release_plan_is_two_large_native_choices_without_legacy_route_clutter() -> void:
	var hud: GameHUD = _new_hud()
	var arcade: DistrictCardDefinition = CARD_CATALOGUE.get_by_id(&"arcade")
	var store: DistrictCardDefinition = CARD_CATALOGUE.get_by_id(&"convenience_store")
	hud.present_district_cards(_card_snapshot([arcade, store]), {})

	assert_true(hud.district_card_panel.visible, "release UI: mandatory PLAN opens automatically")
	assert_contains(hud.district_card_title.text, "DISTRICT PLAN", "release UI: focused decision leads")
	assert_contains(hud.district_card_title.text, "BLOCK 1 / 3", "release UI: exact next-block context leads")
	assert_contains(hud.district_card_instruction.text, "BLOCK, HEAT, AND PAYOFF", "release UI: prediction prompt is explicit")
	assert_contains(hud.district_card_counts.text, "OFFER 2 / 2", "release UI: offer language replaces hand language")
	assert_contains(hud.district_card_choice_01.tooltip_text.to_upper(), "HEAT +10", "release UI: exact positive Heat shown")
	assert_contains(hud.district_card_choice_01.tooltip_text, "FIGHT + REWARD", "release UI: exact block type shown")
	assert_contains(hud.district_card_choice_02.tooltip_text.to_upper(), "HEAT -10", "release UI: exact cooling shown")
	assert_contains(hud.district_card_choice_02.tooltip_text, "ONE PURCHASE", "release UI: special rule shown")
	assert_true(hud.district_card_choice_01.size.x >= 500.0, "release UI: first choice is a large card")
	assert_true(hud.district_card_choice_02.size.x >= 500.0, "release UI: second choice is a large card")
	assert_false(hud.district_card_choice_03.visible, "release UI: no unexplained third choice")
	assert_false(hud.district_card_close_button.visible, "release UI: mandatory choice cannot be dismissed")
	assert_false(hud.district_route_slot_01.visible, "release UI: first future-slot target removed")
	assert_false(hud.district_route_slot_05.visible, "release UI: fifth future-slot target removed")
	assert_false(hud.district_card_choice_01.is_drag_source_enabled(), "release UI: drag-only route path is development-gated")
	assert_true(hud.district_card_choice_01.focus_mode != Control.FOCUS_NONE, "input parity: first card is keyboard focusable")
	assert_true(hud.district_card_choice_01.custom_minimum_size.y >= NeonUiTokens.TOUCH_TARGET_MINIMUM, "input parity: first card meets touch target")
	var release_copy: String = " ".join([
		hud.district_card_title.text,
		hud.district_card_instruction.text,
		hud.district_card_counts.text,
		hud.district_card_route_preview.text,
	])
	for obsolete_term: String in ["FUTURE SLOT", "VALID SLOT", "DRAW PILE", "HAND CAPACITY"]:
		assert_false(obsolete_term in release_copy, "release UI: obsolete '%s' jargon absent" % obsolete_term)


func test_native_button_confirmation_forwards_one_exact_revisioned_intent() -> void:
	var hud: GameHUD = _new_hud()
	var capture: ChoiceCapture = ChoiceCapture.new()
	hud.district_plan_choice_requested.connect(capture.on_choice)
	hud.present_district_cards(
		_card_snapshot([
			CARD_CATALOGUE.get_by_id(&"arcade"),
			CARD_CATALOGUE.get_by_id(&"subway_entrance"),
		]),
		{}
	)
	hud.district_card_choice_02.pressed.emit()
	assert_contains(hud.district_card_feedback.text, "PREDICTION", "input parity: native activation selects and predicts")
	assert_contains(hud.district_card_feedback.text, "TRANSIT + COOLING", "input parity: prediction names exact next block")
	assert_false(hud.district_card_confirm_button.disabled, "input parity: confirm enables after selection")
	hud.district_card_confirm_button.pressed.emit()
	hud.district_card_confirm_button.pressed.emit()
	assert_eq(capture.requests.size(), 1, "input parity: pointer/tap/keyboard native button path emits once")
	if capture.requests.is_empty():
		return
	var request: Dictionary = capture.requests[0]
	assert_eq(request.card_id, &"subway_entrance", "input parity: exact stable card ID")
	assert_eq(request.offer_revision, 9, "input parity: exact offer revision")
	assert_eq(request.lifecycle_revision, 14, "input parity: exact lifecycle revision")
	assert_eq(request.lap_id, &"district_lap_01", "input parity: exact stable lap ID")
	assert_eq(request.block_id, &"district_lap_01::block_01", "input parity: exact stable block ID")


func test_configured_run_pauses_predicts_confirms_heats_and_recognizes_exact_next_block() -> void:
	var fixture: GameFixture = _new_game(false)
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	assert_true(fixture.game.run_director.complete_intro(), "flow: intro reaches authoritative PLAN")
	assert_eq(fixture.game.run_director.current_state, RunDirector.RunState.PAUSED, "flow: PLAN owns a safe-boundary pause")
	assert_true(fixture.game.run_director.is_card_planning_pause_active(), "flow: ordinary pause cannot own/release PLAN")
	assert_false(fixture.game.run_director.toggle_pause(), "flow: ordinary resume cannot bypass required choice")
	assert_false(fixture.game.vertical_slice_overlay.tutorial_panel.visible, "flow: legacy tutorial banner cannot obscure focused prediction")
	assert_true(fixture.game.tutorial_controller.get_active_prompt() == null, "flow: focused PLAN owns its complete first-use teaching surface")
	var time_before: float = float(
		fixture.game.run_director.get_snapshot().get("run_elapsed_seconds", 0.0)
	)
	var pressure_before: float = fixture.game.run_director.night_pressure
	fixture.game.run_director.step_run(12.0)
	assert_eq(
		float(fixture.game.run_director.get_snapshot().get("run_elapsed_seconds", 0.0)),
		time_before,
		"flow: eligible time freezes while reading"
	)
	assert_eq(fixture.game.run_director.night_pressure, pressure_before, "flow: Night Pressure freezes while reading")

	var before: Dictionary = fixture.game.card_system.get_snapshot()
	assert_eq(before.get("offer_count"), 2, "flow: exactly two accessible choices offered")
	var chosen: DistrictCardDefinition = (before.get("offer", []) as Array)[0] as DistrictCardDefinition
	assert_true(chosen != null, "flow: first visible card is authored data")
	if chosen == null:
		return
	fixture.game.run_director.apply_heat_delta(30)
	var heat_before: int = fixture.game.run_director.heat
	fixture.game.game_hud.district_card_choice_01.pressed.emit()
	assert_contains(fixture.game.game_hud.district_card_feedback.text, CardSystem.focused_block_type(chosen), "flow: player can predict chosen block")
	fixture.game.game_hud.district_card_confirm_button.pressed.emit()
	assert_eq(fixture.game.run_director.current_state, RunDirector.RunState.PATROLLING, "flow: exact confirmation releases patrol")
	assert_eq(fixture.game.run_director.heat, heat_before + chosen.heat_delta, "flow: chosen Heat applies exactly once")
	var accepted: Dictionary = fixture.game.card_system.get_snapshot()
	var selected: Dictionary = accepted.get("selected_next_block", {}) as Dictionary
	assert_eq(selected.get("card_id"), chosen.id, "flow: chosen stable ID bound to next block")
	assert_eq(selected.get("block_id"), &"district_lap_01::block_01", "flow: exact stable next block bound")
	var token: int = int(selected.get("selection_token", -1))
	var heat_after: int = fixture.game.run_director.heat
	var replay: Dictionary = fixture.game.run_flow_controller.confirm_focused_district_plan_choice(token)
	assert_false(bool(replay.get("accepted", false)), "flow: replay rejects")
	assert_eq(fixture.game.run_director.heat, heat_after, "flow: replay cannot apply Heat twice")

	fixture.game.patrol_controller.step_patrol(100.0)
	var occurred: Dictionary = fixture.game.card_system.get_snapshot()
	var history: Array = occurred.get("current_lap_history", []) as Array
	assert_eq(history.size(), 1, "flow: one consequence appears in resolved history")
	if not history.is_empty():
		assert_eq((history[0] as Dictionary).get("card_id"), chosen.id, "flow: recognized consequence uses same stable ID")
		assert_true(bool((history[0] as Dictionary).get("resolved", false)), "flow: history marks consequence when it occurs")
	var recognition_copy: String = " ".join([
		fixture.game.game_hud.hydrant_feedback_label.text,
		fixture.game.game_hud.district_card_compact_summary.text,
		fixture.game.game_hud.district_card_route_preview.text,
	])
	assert_contains(recognition_copy, chosen.display_name.to_upper(), "flow: visible occurrence state repeats chosen location name")
	assert_false(bool(fixture.game.run_flow_controller.get_snapshot().get("card_reward_phase_active", true)), "flow: obsolete supplemental hand reward is disabled")


func test_all_four_cards_execute_their_focused_production_effect_exactly_once() -> void:
	var expected_heat: Dictionary[StringName, int] = {
		&"arcade": 10,
		&"convenience_store": -10,
		&"gang_hideout": 20,
		&"subway_entrance": -15,
	}
	for card_id: StringName in [
		&"arcade",
		&"convenience_store",
		&"gang_hideout",
		&"subway_entrance",
	]:
		var fixture: GameFixture = _new_game(true)
		assert_true(
			_start_game_with_target_card(fixture, card_id),
			"effects/%s: deterministic production access starts" % card_id
		)
		assert_true(
			fixture.game.run_director.complete_intro(),
			"effects/%s: intro reaches focused PLAN" % card_id
		)
		var plan: Dictionary = fixture.game.card_system.get_snapshot()
		assert_eq(
			(plan.get("offer_ids", []) as Array).size(),
			2,
			"effects/%s: focused production offer remains two cards" % card_id
		)
		assert_true(
			(plan.get("offer_ids", []) as Array).has(card_id),
			"effects/%s: target stable ID is offered" % card_id
		)
		var starting_heat: int = 40 if card_id == &"gang_hideout" else 30
		if card_id == &"arcade":
			starting_heat = 0
		fixture.game.run_director.apply_heat_delta(starting_heat)
		var heat_before: int = fixture.game.run_director.heat
		var subway_charges_before: int = fixture.game.cooling_controller.get_subway_charges()
		var staged: Dictionary = fixture.game.run_flow_controller.stage_focused_district_plan_choice(
			card_id,
			int(plan.get("offer_revision", -1)),
			int(plan.get("context_lifecycle_revision", -1)),
			StringName(plan.get("lap_id", &"")),
			StringName(plan.get("block_id", &""))
		)
		assert_true(bool(staged.get("accepted", false)), "effects/%s: exact intent stages" % card_id)
		var token: int = int(staged.get("confirmation_token", -1))
		var confirmed: Dictionary = (
			fixture.game.run_flow_controller.confirm_focused_district_plan_choice(token)
		)
		assert_true(bool(confirmed.get("accepted", false)), "effects/%s: exact intent confirms" % card_id)
		assert_eq(
			fixture.game.run_director.heat,
			heat_before + expected_heat[card_id],
			"effects/%s: authored Heat applies once" % card_id
		)
		var heat_after_confirm: int = fixture.game.run_director.heat
		assert_false(
			bool(
				fixture.game.run_flow_controller.confirm_focused_district_plan_choice(token).get(
					"accepted",
					false
				)
			),
			"effects/%s: confirmation replay rejects" % card_id
		)
		assert_eq(
			fixture.game.run_director.heat,
			heat_after_confirm,
			"effects/%s: replay cannot add Heat" % card_id
		)
		var cards_draws_before_occurrence: int = fixture.game.run_director.get_random_streams().get_draw_count(
			RunRandomStreams.STREAM_CARDS
		)
		var arcade_base_reward_tier: int = fixture.game.run_director.get_reward_quality_tier()
		fixture.game.patrol_controller.step_patrol(100.0)
		var after_occurrence: Dictionary = fixture.game.card_system.get_snapshot()
		var history: Array = after_occurrence.get("current_lap_history", []) as Array
		assert_eq(history.size(), 1, "effects/%s: one resolved history entry" % card_id)
		if not history.is_empty():
			assert_eq(
				(history[0] as Dictionary).get("card_id"),
				card_id,
				"effects/%s: occurrence preserves stable ID" % card_id
			)
			assert_true(
				bool((history[0] as Dictionary).get("resolved", false)),
				"effects/%s: occurrence is visibly resolved" % card_id
			)

		match card_id:
			&"arcade":
				var arcade_encounter: EncounterDefinition = (
					fixture.game.encounter_controller.get_active_definition()
				)
				assert_true(arcade_encounter != null, "effects/arcade: authored standard fight starts")
				if arcade_encounter != null:
					assert_false(arcade_encounter.elite_eligible, "effects/arcade: fight is standard-only")
					assert_false(arcade_encounter.boss, "effects/arcade: fight is not boss content")
					var arcade_instance_id: int = (
						fixture.game.encounter_controller.get_active_encounter_instance_id()
					)
					fixture.game.run_flow_controller._on_encounter_completed(
						arcade_instance_id,
						arcade_encounter
					)
					var arcade_reward: StandardRewardDefinition = (
						fixture.game.reward_director.get_pending_standard_reward(arcade_instance_id)
					)
					assert_true(arcade_reward != null, "effects/arcade: standard reward is prepared")
					if arcade_reward != null:
						assert_eq(
							arcade_reward.quality_tier,
							fixture.game.reward_director.get_advanced_authored_quality_tier(
								arcade_base_reward_tier,
								[],
								1
							),
							"effects/arcade: reward advances one authored tier"
						)
			&"convenience_store":
				assert_eq(
					fixture.game.run_director.current_state,
					RunDirector.RunState.SHOP,
					"effects/store: focused block opens the shop"
				)
				assert_eq(
					fixture.game.cooling_controller.get_shop_visit_source_id(),
					&"convenience_store",
					"effects/store: visit source is exact"
				)
				assert_eq(
					fixture.game.cooling_controller.get_shop_visit_purchases_remaining(),
					1,
					"effects/store: visit permits exactly one purchase"
				)
			&"gang_hideout":
				var elite_encounter: EncounterDefinition = (
					fixture.game.encounter_controller.get_active_definition()
				)
				assert_true(elite_encounter != null, "effects/hideout: authored elite fight starts")
				if elite_encounter != null:
					assert_eq(elite_encounter.id, &"viper_signal", "effects/hideout: exact encounter ID")
					assert_true(elite_encounter.elite_eligible, "effects/hideout: elite eligibility retained")
					var elite_instance_id: int = (
						fixture.game.encounter_controller.get_active_encounter_instance_id()
					)
					fixture.game.run_flow_controller._on_encounter_completed(
						elite_instance_id,
						elite_encounter
					)
					assert_false(
						fixture.game.reward_director.get_pending_equipment_choices(
							elite_instance_id
						).is_empty(),
						"effects/hideout: equipment choice is guaranteed"
					)
			&"subway_entrance":
				assert_eq(
					fixture.game.run_director.get_district_loop_snapshot().get("completed_blocks"),
					1,
					"effects/subway: no-combat utility completes one block"
				)
				assert_false(
					fixture.game.encounter_controller.has_active_encounter(),
					"effects/subway: baseline fight is replaced"
				)
				assert_eq(
					fixture.game.cooling_controller.get_subway_charges(),
					subway_charges_before,
					"effects/subway: finite intervention charge is untouched"
				)

		assert_eq(
			fixture.game.run_director.get_random_streams().get_draw_count(
				RunRandomStreams.STREAM_CARDS
			),
			cards_draws_before_occurrence,
			"effects/%s: resolution consumes no additional cards draw" % card_id
		)
		assert_false(
			bool(fixture.game.run_flow_controller.get_snapshot().get("card_reward_phase_active", true)),
			"effects/%s: focused effect cannot recurse into hand rewards" % card_id
		)
		fixture.game._return_to_main_menu()


func test_unsafe_cleanup_invalidates_staged_intent_without_heat_or_hidden_state() -> void:
	var fixture: GameFixture = _new_game(true)
	fixture.game.vertical_slice_overlay.jax_button.pressed.emit()
	fixture.game.vertical_slice_overlay.start_button.pressed.emit()
	fixture.game.run_director.complete_intro()
	fixture.game.run_director.apply_heat_delta(25)
	var cards_before: Dictionary = fixture.game.card_system.get_snapshot()
	var card_id: StringName = StringName((cards_before.get("offer_ids", []) as Array)[0])
	var staged: Dictionary = fixture.game.run_flow_controller.stage_focused_district_plan_choice(
		card_id,
		int(cards_before.get("offer_revision", -1)),
		int(cards_before.get("context_lifecycle_revision", -1)),
		StringName(cards_before.get("lap_id", &"")),
		StringName(cards_before.get("block_id", &""))
	)
	assert_true(bool(staged.get("accepted", false)), "cleanup: exact intent stages")
	var heat_before: int = fixture.game.run_director.heat
	fixture.game._return_to_main_menu()
	var rejected: Dictionary = fixture.game.run_flow_controller.confirm_focused_district_plan_choice(
		int(staged.get("confirmation_token", -1))
	)
	assert_false(bool(rejected.get("accepted", false)), "cleanup: pre-transition token rejects")
	assert_eq(fixture.game.run_director.heat, 0, "cleanup: run Heat resets and stale token cannot restore it")
	assert_true(fixture.game.card_system.get_hand().is_empty(), "cleanup: offer storage clears")
	var cleared: Dictionary = fixture.game.card_system.get_snapshot()
	assert_true((cleared.get("selected_next_block", {}) as Dictionary).is_empty(), "cleanup: selected next block clears")
	assert_true((cleared.get("current_lap_history", []) as Array).is_empty(), "cleanup: history clears")
	assert_false(bool(cleared.get("planning_active", true)), "cleanup: mandatory pause latch clears")
	assert_ne(heat_before, fixture.game.run_director.heat, "cleanup: test established nonzero pre-cleanup Heat")


func _card_snapshot(offer: Array[DistrictCardDefinition]) -> Dictionary:
	return {
		"district_plan_enabled": true,
		"legacy_route_planner_enabled": false,
		"supplemental_card_rewards_enabled": false,
		"planning_active": true,
		"planning_owns_pause": true,
		"offer": offer,
		"offer_ids": _card_ids(offer),
		"offer_count": offer.size(),
		"offer_capacity": 2,
		"offer_revision": 9,
		"lap_deck_remaining": 1,
		"lap_selected_count": 0,
		"lap_index": 1,
		"lap_id": &"district_lap_01",
		"block_index": 1,
		"block_id": &"district_lap_01::block_01",
		"context_lifecycle_revision": 14,
		"selected_next_block": {},
		"active_block": {},
		"current_lap_history": [],
		"archived_lap_history": [],
		"staged_confirmation_token": -1,
		"staged_card_id": &"",
		"staged_slot_id": &"",
	}


func _card_ids(cards: Array[DistrictCardDefinition]) -> Array[StringName]:
	var result: Array[StringName] = []
	for card: DistrictCardDefinition in cards:
		result.append(card.id)
	return result


func _new_game(full_content_access: bool) -> GameFixture:
	var fixture: GameFixture = GameFixture.new()
	fixture.service = track(ProfileSaveService.new(
		"user://wp03_district_plan_%d.json" % Time.get_ticks_usec()
	)) as ProfileSaveService
	fixture.app = track(NeonAppState.new()) as NeonAppState
	fixture.app.initialize(fixture.service, full_content_access)
	fixture.viewport = _new_viewport()
	fixture.game = GAME_SCENE.instantiate() as GameRun
	fixture.game.app_state_override = fixture.app
	fixture.viewport.add_child(fixture.game)
	return fixture


func _start_game_with_target_card(fixture: GameFixture, card_id: StringName) -> bool:
	var allowed_card_ids: Array[StringName] = fixture.app.get_accessible_card_ids()
	var seed: int = _seed_with_first_offer_card(card_id, allowed_card_ids)
	if seed < 1:
		return false
	var access: RunContentAccessSnapshot = RunContentAccessSnapshot.create(
		&"jax",
		fixture.app.get_accessible_equipment_ids(),
		allowed_card_ids,
		PersistentProfileData.SAVE_VERSION,
		true
	)
	if not fixture.game._apply_content_access(access):
		return false
	fixture.game._prepare_presentation_for_run()
	fixture.game.run_flow_controller.start_initial_run(seed, true)
	return fixture.game.run_director.current_state == RunDirector.RunState.INTRO


func _seed_with_first_offer_card(
	target_card_id: StringName,
	allowed_card_ids: Array[StringName]
) -> int:
	var stable_ids: Array[StringName] = allowed_card_ids.duplicate()
	stable_ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)
	for seed: int in range(1, 2049):
		var streams: RunRandomStreams = RunRandomStreams.new()
		streams.reset_for_seed(seed)
		var remaining: Array[StringName] = stable_ids.duplicate()
		var offer: Array[StringName] = []
		for _draw_index: int in range(mini(2, remaining.size())):
			var selected: StringName = streams.choose_stable_id(
				RunRandomStreams.STREAM_CARDS,
				remaining
			)
			offer.append(selected)
			remaining.erase(selected)
		streams.free()
		if offer.has(target_card_id):
			return seed
	return -1


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
