@tool
extends "res://addons/godot_ai/testing/test_suite.gd"

const STAGE_SCENE: PackedScene = preload("res://scenes/stages/downtown_loop.tscn")
const FEEDBACK_SCENE: PackedScene = preload("res://scenes/effects/combat_feedback.tscn")


func suite_name() -> String:
	return "wp06_world_presentation"


func test_release_composition_hides_route_and_lane_debug_surfaces_by_default() -> void:
	var host: Node2D = track(Node2D.new()) as Node2D
	var stage: DowntownLoop = STAGE_SCENE.instantiate() as DowntownLoop
	host.add_child(stage)
	_add_to_tree(host)
	assert_false(stage.lane_markers.visible, "debug: logical lane drawing defaults hidden")
	assert_false(stage.route_markers.visible, "debug: route-node drawing defaults hidden")
	assert_false(stage.are_debug_lanes_visible(), "debug: stage reports hidden")
	assert_false(stage.get_node("LaneMarkers/BackLaneLabel").is_visible_in_tree(), "debug: lane label is not release-visible")
	assert_false(stage.get_node("RouteNodes/RouteLabel").is_visible_in_tree(), "debug: route placeholder label is not release-visible")
	stage.set_debug_lanes_visible(true)
	if OS.is_debug_build():
		assert_true(stage.lane_markers.visible, "debug: F2 lane tooling remains available in development")
		assert_true(stage.route_markers.visible, "debug: F2 route tooling remains available in development")
	stage.set_debug_lanes_visible(false)
	assert_false(stage.are_debug_lanes_visible(), "debug: tooling hides again")


func test_stage_selects_five_bounded_profiles_from_existing_context_only() -> void:
	var backdrop: DowntownBackdrop = track(DowntownBackdrop.new()) as DowntownBackdrop
	var cases: Array[Dictionary] = [
		{"encounter": &"alley_scuffle", "card": &"", "state": RunDirector.RunState.ENCOUNTER_ACTIVE, "expected": &"alley"},
		{"encounter": &"arcade_ambush", "card": &"", "state": RunDirector.RunState.ENCOUNTER_ACTIVE, "expected": &"arcade"},
		{"encounter": &"none", "card": &"convenience_store", "state": RunDirector.RunState.SHOP, "expected": &"convenience_store"},
		{"encounter": &"none", "card": &"subway_entrance", "state": RunDirector.RunState.PATROLLING, "expected": &"subway_entrance"},
		{"encounter": &"viper_signal", "card": &"", "state": RunDirector.RunState.ENCOUNTER_ACTIVE, "expected": &"viper"},
	]
	var seen: Array[StringName] = []
	for entry: Dictionary in cases:
		backdrop.present_world_snapshot(_world_snapshot(
			int(entry.state),
			StringName(entry.encounter),
			StringName(entry.card),
			2,
			2
		))
		var snapshot: Dictionary = backdrop.get_presentation_snapshot()
		assert_eq(snapshot.profile_id, entry.expected, "profile: existing context maps deterministically")
		assert_eq(snapshot.lap_index, 2, "profile: lap presentation follows authoritative snapshot")
		assert_true(bool(snapshot.static_redraw_only), "profile: stage is static between context changes")
		seen.append(StringName(snapshot.profile_id))
	assert_eq(seen.size(), 5, "profile: exact bounded profile count")
	for required_id: StringName in [&"alley", &"arcade", &"convenience_store", &"subway_entrance", &"viper"]:
		assert_true(seen.has(required_id), "profile: bounded set includes %s" % required_id)


func test_lap_atmosphere_and_phase_change_revision_without_randomness() -> void:
	var backdrop: DowntownBackdrop = track(DowntownBackdrop.new()) as DowntownBackdrop
	backdrop.present_world_snapshot(_world_snapshot(RunDirector.RunState.PATROLLING, &"none", &"arcade", 1, 1))
	var first: Dictionary = backdrop.get_presentation_snapshot()
	backdrop.present_world_snapshot(_world_snapshot(RunDirector.RunState.PATROLLING, &"none", &"arcade", 1, 1))
	assert_eq(backdrop.get_presentation_snapshot().context_revision, first.context_revision, "atmosphere: identical snapshot does not redraw")
	backdrop.present_world_snapshot(_world_snapshot(RunDirector.RunState.SHOP, &"none", &"convenience_store", 2, 3))
	var second: Dictionary = backdrop.get_presentation_snapshot()
	assert_eq(second.lap_index, 2, "atmosphere: rain lap represented")
	assert_eq(second.block_index, 3, "atmosphere: block represented")
	assert_true(int(second.context_revision) > int(first.context_revision), "atmosphere: changed context increments revision")
	backdrop.present_world_snapshot(_world_snapshot(RunDirector.RunState.BOSS_ACTIVE, &"viper_showdown", &"", 3, 3))
	var boss: Dictionary = backdrop.get_presentation_snapshot()
	assert_eq(boss.profile_id, &"viper", "atmosphere: boss uses lockdown profile")
	assert_eq(boss.lap_index, 3, "atmosphere: final lap represented")
	assert_true(bool(boss.boss_active), "atmosphere: major-event treatment explicit")


func test_actor_variants_publish_nine_distinct_silhouettes_and_accessible_shapes() -> void:
	var silhouette_ids: Array[StringName] = []
	var boss_scale: Vector2 = Vector2.ZERO
	var elite_scale: Vector2 = Vector2.ZERO
	for variant: int in range(ActorVisual.VariantKind.size()):
		var visual: ActorVisual = track(ActorVisual.new()) as ActorVisual
		visual.variant_kind = variant
		visual.set_focus_priority(true)
		visual.set_statuses(3, true)
		var snapshot: Dictionary = visual.get_presentation_snapshot()
		var silhouette_id: StringName = StringName(snapshot.silhouette_id)
		assert_false(silhouette_ids.has(silhouette_id), "silhouette: variant ID is unique")
		silhouette_ids.append(silhouette_id)
		assert_eq(snapshot.focus_shape, &"corner_brackets", "silhouette: Focus differs from area rings")
		assert_eq(snapshot.target_shape, &"diamond", "silhouette: ordinary target remains a diamond")
		assert_eq(snapshot.bleed_shape, &"droplet", "silhouette: Bleed has non-color shape")
		assert_eq(snapshot.shock_shape, &"bolt", "silhouette: Shock has non-color shape")
		assert_eq(snapshot.animation_redraw_hz, 30, "performance: actor drawing is capped at 30 Hz")
		if variant == ActorVisual.VariantKind.VIPER_ENFORCER:
			elite_scale = snapshot.body_scale
		elif variant == ActorVisual.VariantKind.THE_VIPER:
			boss_scale = snapshot.body_scale
	assert_eq(silhouette_ids.size(), 9, "silhouette: exact actor catalogue coverage")
	assert_true(boss_scale.y > elite_scale.y and elite_scale.y > 1.0, "silhouette: boss and elite mass escalate")


func test_telegraph_delivery_kinds_use_distinct_shape_contracts() -> void:
	var cases: Array[Dictionary] = [
		{"delivery": AttackDefinition.DeliveryKind.MELEE, "kind": CombatTelegraph.TelegraphKind.MELEE},
		{"delivery": AttackDefinition.DeliveryKind.PROJECTILE, "kind": CombatTelegraph.TelegraphKind.PROJECTILE},
		{"delivery": AttackDefinition.DeliveryKind.CHARGE, "kind": CombatTelegraph.TelegraphKind.CHARGE},
		{"delivery": AttackDefinition.DeliveryKind.AREA, "kind": CombatTelegraph.TelegraphKind.AREA},
		{"delivery": AttackDefinition.DeliveryKind.SUMMON, "kind": CombatTelegraph.TelegraphKind.SUMMON},
	]
	for entry: Dictionary in cases:
		var telegraph: CombatTelegraph = track(CombatTelegraph.new()) as CombatTelegraph
		telegraph.present(Vector2(100.0, 100.0), 48.0, 1.0, "NAMED INTENT", int(entry.delivery), Vector2(220.0, 130.0), 240.0)
		var snapshot: Dictionary = telegraph.get_presentation_snapshot()
		assert_eq(snapshot.kind, entry.kind, "telegraph: delivery maps to unique grammar")
		assert_eq(snapshot.intent_label, "NAMED INTENT", "telegraph: text reinforces shape")
		assert_eq(snapshot.target_offset, Vector2(120.0, 30.0), "telegraph: exact target relationship is presentation input")


func test_phase_presenter_covers_every_required_phase_and_never_intercepts_input() -> void:
	var viewport: SubViewport = _new_viewport()
	var presenter: PhaseTransitionPresenter = PhaseTransitionPresenter.new()
	viewport.add_child(presenter)
	var states: Array[int] = [
		RunDirector.RunState.PATROLLING,
		RunDirector.RunState.ENCOUNTER_ACTIVE,
		RunDirector.RunState.REWARD_SELECTION,
		RunDirector.RunState.SHOP,
		RunDirector.RunState.EXTRACTION_AVAILABLE,
		RunDirector.RunState.BOSS_INTRO,
		RunDirector.RunState.BOSS_ACTIVE,
		RunDirector.RunState.VICTORY,
		RunDirector.RunState.DEFEAT,
		RunDirector.RunState.RUN_SUMMARY,
	]
	for state: int in states:
		presenter.present_state(state, {"lap_index": 2, "block_index": 2}, false)
		var snapshot: Dictionary = presenter.get_snapshot()
		assert_true(bool(snapshot.active), "transition: required phase has authored punctuation")
		assert_true(bool(snapshot.mouse_passthrough), "transition: never intercepts input")
		assert_false(str(snapshot.heading).is_empty(), "transition: non-color heading exists")
	assert_eq(presenter.get_snapshot().transition_count, states.size(), "transition: exact phase coverage count")
	presenter.present_state(RunDirector.RunState.PAUSED, {"lap_index": 1, "block_index": 1}, true)
	assert_eq(presenter.get_snapshot().phase_id, &"district_plan", "transition: mandatory PLAN is distinct from ordinary pause")


func test_feedback_cap_and_accessibility_reductions_preserve_nonflash_expression() -> void:
	var viewport: SubViewport = _new_viewport()
	var feedback: CombatFeedback = FEEDBACK_SCENE.instantiate() as CombatFeedback
	viewport.add_child(feedback)
	feedback.set_damage_numbers_enabled(false)
	for index: int in range(60):
		feedback.show_hit(Vector2(20.0 + float(index), 40.0), 12.0, index % 3 == 0, &"electric" if index % 5 == 0 else &"")
	assert_false(feedback.are_damage_numbers_enabled(), "accessibility: damage numbers can be disabled")
	assert_true(feedback.get_live_transient_count() <= feedback.get_transient_cap(), "performance: peak feedback remains capped")
	assert_eq(feedback.get_transient_cap(), 48, "performance: inherited bounded transient ceiling retained")
	var visual: ActorVisual = track(ActorVisual.new()) as ActorVisual
	visual.set_hit_flash_reduction(1.0)
	visual.play_hit_flash(0.2)
	visual.set_statuses(2, true)
	var visual_snapshot: Dictionary = visual.get_presentation_snapshot()
	assert_eq(visual_snapshot.hit_flash_reduction, 1.0, "accessibility: flash can be fully reduced")
	assert_eq(visual_snapshot.bleed_shape, &"droplet", "accessibility: status remains shape-coded without flash")
	assert_eq(visual_snapshot.shock_shape, &"bolt", "accessibility: Shock remains shape-coded without flash")


func test_audio_phase_mix_uses_existing_cues_and_buses_only() -> void:
	var audio: AudioPresentationController = track(AudioPresentationController.new()) as AudioPresentationController
	assert_true(audio.initialize_audio(), "audio: existing catalogue initializes")
	audio.set_presentation_phase(&"fight")
	var fight: Dictionary = audio.get_mix_snapshot()
	assert_eq(fight.district_volume_db, 0.0, "audio: fight keeps district layer present")
	audio.set_presentation_phase(&"reward")
	var reward: Dictionary = audio.get_mix_snapshot()
	assert_true(float(reward.district_volume_db) < float(fight.district_volume_db), "audio: decision layer makes room for consequence SFX")
	audio.set_boss_music_active(true)
	audio.set_presentation_phase(&"boss")
	var boss: Dictionary = audio.get_mix_snapshot()
	assert_eq(boss.boss_volume_db, 0.0, "audio: boss layer owns major event")
	assert_eq(audio.catalogue.get_sorted_ids(), AudioCueCatalogue.REQUIRED_CUE_IDS, "audio: stable cue catalogue remains exact")
	assert_true(bool(boss.semantic_cue_ids_unchanged), "audio: presentation mix changes no semantic ID")


func test_wp06_presentation_sources_use_no_unseeded_gameplay_randomness() -> void:
	for path: String in [
		"res://scripts/stages/downtown_backdrop.gd",
		"res://scripts/actors/actor_visual.gd",
		"res://scripts/effects/combat_feedback.gd",
		"res://scripts/effects/combat_telegraph.gd",
		"res://scripts/effects/phase_transition_presenter.gd",
	]:
		var source: String = FileAccess.get_file_as_string(path)
		assert_false(source.contains("randi("), "randomness: %s has no randi" % path)
		assert_false(source.contains("randf("), "randomness: %s has no randf" % path)
		assert_false(source.contains("randomize("), "randomness: %s has no randomize" % path)
		assert_false(source.contains("pick_random("), "randomness: %s has no pick_random" % path)
		assert_false(source.contains("shuffle("), "randomness: %s has no shuffle" % path)


func _world_snapshot(
	state: int,
	encounter_id: StringName,
	card_id: StringName,
	lap_index: int,
	block_index: int
) -> Dictionary:
	return {
		"run": {
			"state": state,
			"state_name": RunDirector.state_name(state),
			"district_loop": {"lap_index": lap_index, "block_index": block_index},
		},
		"encounter": {
			"active_encounter_id": encounter_id,
			"boss_active": encounter_id == &"viper_showdown",
		},
		"cards": {
			"active_block": {"card_id": card_id} if card_id != &"" else {},
		},
		"environment": {},
	}


func _new_viewport() -> SubViewport:
	var viewport: SubViewport = track(SubViewport.new()) as SubViewport
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_add_to_tree(viewport)
	return viewport


func _add_to_tree(node: Node) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and node.get_parent() == null:
		tree.root.add_child(node)
