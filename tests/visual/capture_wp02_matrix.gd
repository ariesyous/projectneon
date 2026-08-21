extends SceneTree

## Deterministic WP02 presentation evidence. All gameplay values are authored
## fixture snapshots; the capture script consumes no gameplay random stream.

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/vertical_slice_overlay.tscn")
const OUTPUT_DIRECTORY: String = "res://docs/screenshots/wp02"


func _init() -> void:
	call_deferred("_capture_matrix")


func _capture_matrix() -> void:
	var output_absolute: String = ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(output_absolute)
	if directory_error != OK:
		_fail("capture directory failed: %s" % error_string(directory_error))
		return
	var captures: Array[Dictionary] = [
		{"name": "plan", "snapshot": _snapshot(RunDirector.RunState.PATROLLING, 1, 1, 0, 0)},
		{"name": "fight_arrival", "snapshot": _snapshot(RunDirector.RunState.ENCOUNTER_ACTIVE, 1, 2, 0, 1)},
		{"name": "reward", "snapshot": _snapshot(RunDirector.RunState.REWARD_SELECTION, 1, 2, 0, 1)},
		{"name": "shop", "snapshot": _snapshot(RunDirector.RunState.SHOP, 1, 3, 0, 2)},
		{"name": "lap_1_decision", "snapshot": _decision_snapshot(1)},
		{"name": "final_lap_commitment", "snapshot": _decision_snapshot(2)},
		{"name": "extraction", "snapshot": _snapshot(RunDirector.RunState.EXTRACTING, 1, 3, 1, 3)},
		{"name": "boss", "snapshot": _snapshot(RunDirector.RunState.BOSS_ACTIVE, 3, 3, 3, 9)},
	]
	for capture: Dictionary in captures:
		var capture_error: Error = await _capture_hud(
			str(capture.get("name", "state")),
			capture.get("snapshot", {})
		)
		if capture_error != OK:
			_fail("%s capture failed: %s" % [capture.get("name", "state"), error_string(capture_error)])
			return
	var summary_error: Error = await _capture_summary()
	if summary_error != OK:
		_fail("summary capture failed: %s" % error_string(summary_error))
		return
	var scaling_error: Error = await _capture_safe_area_and_web_scale()
	if scaling_error != OK:
		_fail("scaling capture failed: %s" % error_string(scaling_error))
		return
	print("WP02_CAPTURE_MATRIX=9 native states + safe-area native + 2560x1440 Web integer scale")
	quit(0)


func _capture_hud(capture_name: String, snapshot: Dictionary) -> Error:
	var viewport: SubViewport = _new_viewport()
	root.add_child(viewport)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("10182c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(backdrop)
	var hud: GameHUD = HUD_SCENE.instantiate() as GameHUD
	viewport.add_child(hud)
	for _frame: int in range(2):
		await process_frame
	if hud.help_panel.visible:
		hud.help_button.pressed.emit()
	hud.present_flow_snapshot(snapshot)
	hud.present_crew_status("ZOEY", 338.0, 400.0, &"ATTACK_ACTIVE", "VIPER ENFORCER")
	hud.present_build_snapshot({
		"inventory_revision": 4,
		"slots": [
			{"id": &"shock_gloves", "display_name": "Shock Gloves"},
			{"id": &"hacker_deck", "display_name": "Hacker Deck"},
			{"id": &"voltaic_blade", "display_name": "Voltaic Blade"},
		],
		"backpack_slots": [{}, {}, {}],
		"active_synergies": [{"display_name": "Tech 2"}],
		"synergy_progress": [],
	})
	hud.present_backup_state({
		"active_allies": 0,
		"charges_remaining": 1,
		"cooldown_remaining": 0.0,
		"can_activate": true,
		"validity_text": "READY",
	})
	hud.present_hydrant_state(GameHUD.HydrantPresentationState.AVAILABLE, 0.0, 8.0, 2, "READY")
	_focus_first_button(hud.root_control)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for _frame: int in range(3):
		await process_frame
	var error: Error = _save_viewport(
		viewport,
		"%s/wp02_%s_1280x720.png" % [OUTPUT_DIRECTORY, capture_name]
	)
	viewport.free()
	await process_frame
	return error


func _capture_summary() -> Error:
	var viewport: SubViewport = _new_viewport()
	root.add_child(viewport)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("10182c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(backdrop)
	var overlay: VerticalSliceOverlay = OVERLAY_SCENE.instantiate() as VerticalSliceOverlay
	viewport.add_child(overlay)
	for _frame: int in range(2):
		await process_frame
	var summary: RunSummaryRecord = RunSummaryRecord.new()
	summary.result_label = "EXTRACTED"
	summary.duration_seconds = 347.0
	summary.run_seed = 6062026
	summary.random_schema_version = 1
	summary.maximum_heat = 64
	summary.final_night_pressure = 40.6
	summary.enemies_defeated = 24
	summary.elites_defeated = 1
	summary.boss_result = "NOT REACHED"
	summary.coins_collected = 186
	summary.manual_clusters_collected = 4
	summary.maximum_manual_streak = 3
	summary.scrap_secured = 18
	summary.highest_combo = 24
	summary.equipment_build = "Shock Gloves / Hacker Deck / Voltaic Blade"
	summary.active_synergies = "TECH 2 / BLEED 2"
	summary.laps_completed = 2
	summary.blocks_completed = 6
	summary.boss_committed = false
	summary.lap_decisions = [{"decision": &"push"}, {"decision": &"extract"}]
	overlay.present_run_summary(summary)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for _frame: int in range(3):
		await process_frame
	var error: Error = _save_viewport(
		viewport,
		"%s/wp02_result_1280x720.png" % OUTPUT_DIRECTORY
	)
	viewport.free()
	await process_frame
	return error


func _capture_safe_area_and_web_scale() -> Error:
	var viewport: SubViewport = _new_viewport()
	root.add_child(viewport)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("10182c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(backdrop)
	var hud: GameHUD = HUD_SCENE.instantiate() as GameHUD
	viewport.add_child(hud)
	for _frame: int in range(2):
		await process_frame
	if hud.help_panel.visible:
		hud.help_button.pressed.emit()
	hud.present_flow_snapshot(_decision_snapshot(2))
	hud.apply_safe_area(Rect2i(32, 24, 1216, 672), Vector2i(1280, 720))
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for _frame: int in range(3):
		await process_frame
	var native_error: Error = _save_viewport(
		viewport,
		"%s/wp02_final_commit_safe_area_1280x720.png" % OUTPUT_DIRECTORY
	)
	if native_error != OK:
		return native_error
	var native_image: Image = viewport.get_texture().get_image()
	if native_image == null or native_image.is_empty():
		return ERR_CANT_CREATE
	native_image.resize(2560, 1440, Image.INTERPOLATE_NEAREST)
	var web_error: Error = native_image.save_png(
		ProjectSettings.globalize_path(
			"%s/wp02_final_commit_web_integer_2560x1440.png" % OUTPUT_DIRECTORY
		)
	)
	viewport.free()
	await process_frame
	return web_error


func _decision_snapshot(completed_lap: int) -> Dictionary:
	var snapshot: Dictionary = _snapshot(
		RunDirector.RunState.EXTRACTION_AVAILABLE,
		completed_lap,
		3,
		completed_lap,
		completed_lap * 3
	)
	var district: Dictionary = (snapshot.get("run", {}) as Dictionary).get("district_loop", {})
	district["decision_token"] = completed_lap
	var next_lap: int = completed_lap + 1
	district["push_preview"] = {
		"lap_index": next_lap,
		"lap_id": StringName("district_lap_%02d" % next_lap),
		"modifier_label": "BOSS COMMITMENT" if next_lap == 3 else "RISING PRESSURE",
		"risk_label": "FINAL LAP - NO ROUTINE EXTRACTION" if next_lap == 3 else "HIGHER ENEMY PRESSURE",
		"pressure_gain_multiplier": 1.30 if next_lap == 3 else 1.15,
		"reward_quality_tier_bonus": 2 if next_lap == 3 else 1,
		"next_threat": "THE VIPER" if next_lap == 3 else "VIPER ENFORCER",
		"push_heat_delta": 6,
		"final_lap_commitment": next_lap == 3,
	}
	return snapshot


func _snapshot(
	state: int,
	lap_index: int,
	block_index: int,
	completed_laps: int,
	completed_blocks: int
) -> Dictionary:
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
	return {
		"run": {
			"state": state,
			"run_elapsed_seconds": 145.0 + float(completed_blocks * 48),
			"heat": 52,
			"heat_tier": 2,
			"night_pressure": 34.8,
			"boss_threshold": 50.0,
			"next_major_threshold": 50.0,
			"reward_multiplier": 1.2,
			"district_loop": {
				"enabled": true,
				"phase_name": phase_name,
				"lap_index": lap_index,
				"lap_id": StringName("district_lap_%02d" % lap_index),
				"lap_count": 3,
				"block_index": block_index,
				"block_id": StringName("district_lap_%02d::block_%02d" % [lap_index, block_index]),
				"blocks_per_lap": 3,
				"completed_laps": completed_laps,
				"completed_blocks": completed_blocks,
				"decision_token": -1,
				"boss_committed": lap_index == 3,
				"current_lap": {
					"modifier_label": (
						"BOSS COMMITMENT" if lap_index == 3
						else "RISING PRESSURE" if lap_index == 2
						else "STREET WATCH"
					),
					"pressure_gain_multiplier": 1.30 if lap_index == 3 else 1.15 if lap_index == 2 else 1.0,
				},
				"push_preview": {},
			},
		},
		"patrol": {
			"route_index": block_index - 1,
			"route_progress": 0.62,
			"route_node_type": &"encounter",
			"route_revision": completed_blocks + 1,
			"loop_count": completed_laps,
		},
		"encounter": {
			"active_encounter_name": "Viper Enforcer",
			"remaining_to_spawn": 2,
			"spawn_delay_remaining": 2.4,
		},
		"cooling": {
			"subway_charges": 1,
			"subway_heat_reduction": 15,
			"shop_purchases_remaining": 1,
			"shop_coin_cost": 60,
			"shop_heat_reduction": 18,
		},
		"rewards": {
			"coin_total": 126,
			"scrap_total": 12,
			"streak_count": 3,
		},
	}


func _new_viewport() -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return viewport


func _save_viewport(viewport: SubViewport, resource_path: String) -> Error:
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return ERR_CANT_CREATE
	return image.save_png(ProjectSettings.globalize_path(resource_path))


func _focus_first_button(node: Node) -> bool:
	if node is Button and (node as Button).visible and not (node as Button).disabled:
		(node as Button).grab_focus()
		return true
	for child: Node in node.get_children():
		if _focus_first_button(child):
			return true
	return false


func _fail(message: String) -> void:
	push_error("WP02_CAPTURE_MATRIX=FAIL %s" % message)
	quit(1)
