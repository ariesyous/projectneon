extends SceneTree

## Generates deterministic UI-only acceptance captures. These fixtures do not
## enter gameplay authority and consume no gameplay random stream.

const GALLERY_SCENE: PackedScene = preload("res://scenes/ui/wp01_state_gallery.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const OUTPUT_DIRECTORY: String = "res://docs/screenshots/wp01"
const STATES: PackedStringArray = [
	"combat", "plan", "reward", "shop", "extract", "pause", "settings", "summary",
]


func _init() -> void:
	call_deferred("_capture_matrix")


func _capture_matrix() -> void:
	var output_absolute: String = ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(output_absolute)
	if directory_error != OK:
		push_error("WP01 capture directory failed: %s" % error_string(directory_error))
		quit(1)
		return
	var viewport: SubViewport = _new_viewport()
	root.add_child(viewport)
	var gallery: Wp01StateGallery = GALLERY_SCENE.instantiate() as Wp01StateGallery
	viewport.add_child(gallery)
	for _frame: int in range(3):
		await process_frame
	for state_name: String in STATES:
		gallery.present_state(state_name)
		_focus_first_button(gallery)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		for _frame: int in range(3):
			await process_frame
		var capture_error: Error = _save_viewport(
			viewport,
			"%s/wp01_%s_1280x720.png" % [OUTPUT_DIRECTORY, state_name]
		)
		if capture_error != OK:
			push_error("WP01 %s capture failed: %s" % [state_name, error_string(capture_error)])
			quit(1)
			return
	gallery.free()
	viewport.free()
	await process_frame
	var safe_error: Error = await _capture_safe_area_and_web_scale()
	if safe_error != OK:
		push_error("WP01 safe-area capture failed: %s" % error_string(safe_error))
		quit(1)
		return
	print("WP01_CAPTURE_MATRIX=8 native states + safe-area native + 2560x1440 Web integer scale")
	quit(0)


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
	hud.present_flow_snapshot(_combat_snapshot())
	hud.present_crew_status("JAX", 402.0, 520.0, &"ATTACK_ACTIVE", "VIPER ENFORCER")
	hud.present_backup_state({
		"active_allies": 0,
		"charges_remaining": 2,
		"cooldown_remaining": 0.0,
		"can_activate": true,
		"validity_text": "READY",
	})
	hud.present_hydrant_state(GameHUD.HydrantPresentationState.AVAILABLE, 0.0, 8.0, 2, "READY")
	hud.apply_safe_area(Rect2i(32, 24, 1216, 672), Vector2i(1280, 720))
	_focus_first_button(hud.root_control)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for _frame: int in range(3):
		await process_frame
	var native_path: String = "%s/wp01_combat_safe_area_1280x720.png" % OUTPUT_DIRECTORY
	var native_error: Error = _save_viewport(viewport, native_path)
	if native_error != OK:
		return native_error
	var native_image: Image = viewport.get_texture().get_image()
	if native_image == null or native_image.is_empty():
		return ERR_CANT_CREATE
	native_image.resize(2560, 1440, Image.INTERPOLATE_NEAREST)
	var web_error: Error = native_image.save_png(
		ProjectSettings.globalize_path(
			"%s/wp01_combat_web_integer_2560x1440.png" % OUTPUT_DIRECTORY
		)
	)
	hud.free()
	viewport.free()
	return web_error


func _new_viewport() -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.name = "Wp01CaptureViewport"
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


func _combat_snapshot() -> Dictionary:
	return {
		"run": {
			"state": RunDirector.RunState.ENCOUNTER_ACTIVE,
			"run_elapsed_seconds": 145.0,
			"heat": 58,
			"heat_tier": 2,
			"night_pressure": 31.5,
			"boss_threshold": 50.0,
			"next_major_threshold": 36.0,
		},
		"patrol": {
			"route_index": 3,
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
			"shop_heat_reduction": 15,
		},
		"rewards": {
			"coin_total": 126,
			"scrap_total": 8,
			"streak_count": 3,
		},
	}
