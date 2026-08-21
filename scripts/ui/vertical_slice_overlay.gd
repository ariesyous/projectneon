class_name VerticalSliceOverlay
extends CanvasLayer

## Front-end, pause, settings, boss, tutorial, combo, and final-summary
## presentation. It forwards typed intent and never changes run authority.

signal start_run_requested(crew_id: StringName)
signal resume_requested()
signal restart_same_seed_requested()
signal restart_new_seed_requested()
signal return_to_main_menu_requested()
signal settings_apply_requested(settings: Dictionary)
signal reset_save_requested()
signal ui_confirmed()
signal ui_hovered()

const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const SETTINGS_CONTEXT_MAIN: StringName = &"main_menu"
const SETTINGS_CONTEXT_PAUSE: StringName = &"pause"

@onready var main_menu: Control = $Root/MainMenu
@onready var profile_status: Label = $Root/MainMenu/MenuPanel/ProfileStatus
@onready var crew_details: Label = $Root/MainMenu/MenuPanel/CrewDetails
@onready var start_button: Button = $Root/MainMenu/MenuPanel/StartRun
@onready var settings_button: Button = $Root/MainMenu/MenuPanel/Settings
@onready var reset_save_button: Button = $Root/MainMenu/MenuPanel/ResetSave
@onready var jax_button: Button = $Root/MainMenu/MenuPanel/Jax
@onready var zoey_button: Button = $Root/MainMenu/MenuPanel/Zoey
@onready var rex_button: Button = $Root/MainMenu/MenuPanel/Rex

@onready var pause_menu: Control = $Root/PauseMenu
@onready var resume_button: Button = $Root/PauseMenu/PausePanel/Resume
@onready var pause_settings_button: Button = $Root/PauseMenu/PausePanel/Settings
@onready var pause_restart_button: Button = $Root/PauseMenu/PausePanel/Restart
@onready var pause_main_menu_button: Button = $Root/PauseMenu/PausePanel/MainMenu

@onready var settings_panel: Control = $Root/SettingsPanel
@onready var master_slider: HSlider = $Root/SettingsPanel/Panel/MasterSlider
@onready var music_slider: HSlider = $Root/SettingsPanel/Panel/MusicSlider
@onready var sfx_slider: HSlider = $Root/SettingsPanel/Panel/SfxSlider
@onready var display_mode: OptionButton = $Root/SettingsPanel/Panel/DisplayMode
@onready var shake_slider: HSlider = $Root/SettingsPanel/Panel/ShakeSlider
@onready var damage_numbers_toggle: CheckButton = $Root/SettingsPanel/Panel/DamageNumbers
@onready var hit_flash_slider: HSlider = $Root/SettingsPanel/Panel/HitFlashSlider
@onready var focus_pause_toggle: CheckButton = $Root/SettingsPanel/Panel/FocusPause
@onready var settings_status: Label = $Root/SettingsPanel/Panel/Status
@onready var settings_apply_button: Button = $Root/SettingsPanel/Panel/Apply
@onready var settings_back_button: Button = $Root/SettingsPanel/Panel/Back

@onready var summary_panel: Control = $Root/SummaryPanel
@onready var summary_title: Label = $Root/SummaryPanel/Panel/Title
@onready var summary_left: Label = $Root/SummaryPanel/Panel/LeftDetails
@onready var summary_right: Label = $Root/SummaryPanel/Panel/RightDetails
@onready var replay_button: Button = $Root/SummaryPanel/Panel/Replay
@onready var restart_button: Button = $Root/SummaryPanel/Panel/Restart
@onready var summary_main_menu_button: Button = $Root/SummaryPanel/Panel/MainMenu

@onready var boss_panel: Panel = $Root/BossPanel
@onready var boss_title: Label = $Root/BossPanel/Title
@onready var boss_health: ProgressBar = $Root/BossPanel/Health
@onready var boss_status: Label = $Root/BossPanel/Status
@onready var tutorial_panel: Panel = $Root/TutorialPanel
@onready var tutorial_label: Label = $Root/TutorialPanel/Text
@onready var combo_panel: Panel = $Root/ComboPanel
@onready var combo_label: Label = $Root/ComboPanel/Text

var summary_highlight: Label = null
var _selected_crew_id: StringName = &""
var _crew_entries: Dictionary[StringName, Dictionary] = {}
var _settings_context: StringName = SETTINGS_CONTEXT_MAIN
var _latest_settings: Dictionary = {}
var _reset_confirmation_armed: bool = false


func _ready() -> void:
	($Root as Control).theme = NeonUiTokens.create_theme()
	_install_wp01_summary_highlight()
	display_mode.clear()
	display_mode.add_item("WINDOWED", 0)
	display_mode.add_item("FULLSCREEN", 1)
	_bind_button(jax_button, _select_crew.bind(&"jax"))
	_bind_button(zoey_button, _select_crew.bind(&"zoey"))
	_bind_button(rex_button, _select_crew.bind(&"rex"))
	_bind_button(start_button, _on_start_pressed)
	_bind_button(settings_button, _open_settings_from_main)
	_bind_button(reset_save_button, _on_reset_save_pressed)
	_bind_button(resume_button, _on_resume_pressed)
	_bind_button(pause_settings_button, _open_settings_from_pause)
	_bind_button(pause_restart_button, _on_restart_pressed)
	_bind_button(pause_main_menu_button, _on_main_menu_pressed)
	_bind_button(settings_apply_button, _on_settings_apply_pressed)
	_bind_button(settings_back_button, _close_settings)
	_bind_button(replay_button, _on_replay_pressed)
	_bind_button(restart_button, _on_restart_pressed)
	_bind_button(summary_main_menu_button, _on_main_menu_pressed)
	pause_menu.visible = false
	settings_panel.visible = false
	summary_panel.visible = false
	boss_panel.visible = false
	tutorial_panel.visible = false
	combo_panel.visible = false
	_reset_confirmation_armed = false
	reset_save_button.text = "RESET DEVELOPMENT SAVE"
	_apply_wp01_visual_language()
	NeonUiTokens.apply_accessibility_defaults($Root as Control)


func _install_wp01_summary_highlight() -> void:
	summary_highlight = Label.new()
	summary_highlight.name = "Highlight"
	summary_highlight.theme_type_variation = &"HeadingLabel"
	summary_highlight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_highlight.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_highlight.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Root/SummaryPanel/Panel.add_child(summary_highlight)


func _apply_wp01_visual_language() -> void:
	_clear_legacy_theme_overrides($Root)
	($Root/MainMenu/MenuPanel as Panel).theme_type_variation = &"DecisionPanel"
	($Root/PauseMenu/PausePanel as Panel).theme_type_variation = &"DecisionPanel"
	($Root/SettingsPanel/Panel as Panel).theme_type_variation = &"DecisionPanel"
	($Root/SummaryPanel/Panel as Panel).theme_type_variation = &"DecisionPanel"
	boss_panel.theme_type_variation = &"DangerPanel"
	tutorial_panel.theme_type_variation = &"RaisedPanel"
	combo_panel.theme_type_variation = &"SafePanel"

	($Root/MainMenu/MenuPanel/Title as Label).theme_type_variation = &"DisplayLabel"
	($Root/MainMenu/MenuPanel/Subtitle as Label).theme_type_variation = &"EyebrowLabel"
	profile_status.theme_type_variation = &"WarningLabel"
	crew_details.theme_type_variation = &"BodyLabel"
	($Root/PauseMenu/PausePanel/Title as Label).theme_type_variation = &"DisplayLabel"
	($Root/PauseMenu/PausePanel/Status as Label).theme_type_variation = &"MutedLabel"
	($Root/SettingsPanel/Panel/Title as Label).theme_type_variation = &"HeadingLabel"
	($Root/SettingsPanel/Panel/ColourNote as Label).theme_type_variation = &"WarningLabel"
	settings_status.theme_type_variation = &"SafeLabel"
	summary_title.theme_type_variation = &"DisplayLabel"
	summary_left.theme_type_variation = &"BodyLabel"
	summary_right.theme_type_variation = &"BodyLabel"
	boss_title.theme_type_variation = &"HeadingLabel"
	boss_status.theme_type_variation = &"WarningLabel"
	tutorial_label.theme_type_variation = &"CaptionLabel"
	combo_label.theme_type_variation = &"SafeLabel"
	_set_rect(tutorial_panel, Rect2(330.0, 472.0, 620.0, 104.0))
	_set_rect(tutorial_label, Rect2(12.0, 8.0, 596.0, 88.0))

	for choice_button: Button in [jax_button, zoey_button, rex_button]:
		choice_button.theme_type_variation = &"ChoiceCard"
	start_button.theme_type_variation = &"PrimaryButton"
	settings_button.theme_type_variation = &"SecondaryButton"
	reset_save_button.theme_type_variation = &"DangerButton"
	resume_button.theme_type_variation = &"PrimaryButton"
	pause_settings_button.theme_type_variation = &"SecondaryButton"
	pause_restart_button.theme_type_variation = &"DangerButton"
	pause_main_menu_button.theme_type_variation = &"SecondaryButton"
	settings_apply_button.theme_type_variation = &"PrimaryButton"
	settings_back_button.theme_type_variation = &"SecondaryButton"
	replay_button.theme_type_variation = &"PrimaryButton"
	restart_button.theme_type_variation = &"SecondaryButton"
	summary_main_menu_button.theme_type_variation = &"SecondaryButton"

	_set_rect(summary_title, Rect2(30.0, 18.0, 960.0, 48.0))
	_set_rect(summary_highlight, Rect2(45.0, 72.0, 930.0, 66.0))
	_set_rect(summary_left, Rect2(45.0, 154.0, 447.0, 352.0))
	_set_rect(summary_right, Rect2(528.0, 154.0, 447.0, 352.0))
	_set_rect(replay_button, Rect2(45.0, 520.0, 300.0, 84.0))
	_set_rect(restart_button, Rect2(360.0, 520.0, 300.0, 84.0))
	_set_rect(summary_main_menu_button, Rect2(675.0, 520.0, 300.0, 84.0))


func _clear_legacy_theme_overrides(node: Node) -> void:
	if node is Control:
		var control: Control = node as Control
		control.remove_theme_font_size_override(&"font_size")
		for color_name: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_focus_color", &"font_disabled_color", &"font_outline_color",
		]:
			control.remove_theme_color_override(color_name)
	if node is Panel:
		(node as Panel).remove_theme_stylebox_override(&"panel")
	for child: Node in node.get_children():
		_clear_legacy_theme_overrides(child)


func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func show_main_menu(crew_entries: Array[Dictionary], status_text: String = "") -> void:
	_reset_confirmation_armed = false
	reset_save_button.text = "RESET DEVELOPMENT SAVE"
	_crew_entries.clear()
	for entry: Dictionary in crew_entries:
		var crew_id: StringName = StringName(str(entry.get("id", "")))
		if crew_id == &"" or _crew_entries.has(crew_id):
			continue
		_crew_entries[crew_id] = entry.duplicate(true)
	_present_crew_button(jax_button, &"jax")
	_present_crew_button(zoey_button, &"zoey")
	_present_crew_button(rex_button, &"rex")
	profile_status.text = status_text if not status_text.is_empty() else "PROFILE READY"
	main_menu.visible = true
	pause_menu.visible = false
	settings_panel.visible = false
	summary_panel.visible = false
	boss_panel.visible = false
	tutorial_panel.visible = false
	combo_panel.visible = false
	_selected_crew_id = &""
	start_button.disabled = true
	for preferred_id: StringName in [&"jax", &"zoey", &"rex"]:
		if bool(_crew_entries.get(preferred_id, {}).get("unlocked", false)):
			_select_crew(preferred_id, false)
			break
	if not start_button.disabled:
		start_button.grab_focus()


func hide_main_menu() -> void:
	main_menu.visible = false


func prepare_for_run() -> void:
	main_menu.visible = false
	pause_menu.visible = false
	settings_panel.visible = false
	summary_panel.visible = false
	boss_panel.visible = false
	tutorial_panel.visible = false
	combo_panel.visible = false


func show_pause(settings: Dictionary) -> void:
	present_settings(settings)
	pause_menu.visible = true
	settings_panel.visible = false
	resume_button.grab_focus()


func hide_pause() -> void:
	pause_menu.visible = false
	if _settings_context == SETTINGS_CONTEXT_PAUSE:
		settings_panel.visible = false


func present_settings(settings: Dictionary, status_text: String = "") -> void:
	_latest_settings = settings.duplicate(true)
	master_slider.value = clampf(
		float(settings.get("master_volume", GameSettingsData.DEFAULT_MASTER_VOLUME)),
		0.0,
		1.0
	)
	music_slider.value = clampf(
		float(settings.get("music_volume", GameSettingsData.DEFAULT_MUSIC_VOLUME)),
		0.0,
		1.0
	)
	sfx_slider.value = clampf(
		float(settings.get("sound_effects_volume", GameSettingsData.DEFAULT_SOUND_EFFECTS_VOLUME)),
		0.0,
		1.0
	)
	display_mode.select(1 if bool(settings.get("fullscreen", false)) else 0)
	shake_slider.value = clampf(
		float(settings.get("screen_shake_intensity", GameSettingsData.DEFAULT_SCREEN_SHAKE_INTENSITY)),
		0.0,
		1.0
	)
	damage_numbers_toggle.button_pressed = bool(
		settings.get("damage_numbers_enabled", GameSettingsData.DEFAULT_DAMAGE_NUMBERS_ENABLED)
	)
	hit_flash_slider.value = clampf(float(settings.get("hit_flash_reduction", 0.0)), 0.0, 1.0)
	focus_pause_toggle.button_pressed = bool(
		settings.get("pause_on_focus_loss", GameSettingsData.DEFAULT_PAUSE_ON_FOCUS_LOSS)
	)
	settings_status.text = status_text


func present_settings_status(status_text: String) -> void:
	settings_status.text = status_text


func present_profile_status(status_text: String) -> void:
	profile_status.text = status_text


func set_development_reset_visible(is_visible: bool) -> void:
	reset_save_button.visible = is_visible


func present_boss(
	display_name: String,
	current_health: int,
	maximum_health: int,
	phase_text: String,
	telegraph_text: String
) -> void:
	boss_panel.visible = maximum_health > 0 and current_health > 0
	boss_title.text = "%s - %s" % [display_name.to_upper(), phase_text.to_upper()]
	boss_health.max_value = maxf(float(maximum_health), 1.0)
	boss_health.value = clampf(float(current_health), 0.0, boss_health.max_value)
	boss_status.text = (
		telegraph_text.to_upper()
		if not telegraph_text.is_empty()
		else "WATCH THE VIPER'S SHAPE + TEXT TELEGRAPHS"
	)


func hide_boss() -> void:
	boss_panel.visible = false


func present_tutorial(_prompt_id: StringName, text: String) -> void:
	tutorial_label.text = text
	tutorial_panel.visible = not text.is_empty()


func hide_tutorial() -> void:
	tutorial_panel.visible = false


func present_combo(current_combo: int, highest_combo: int) -> void:
	combo_panel.visible = current_combo > 0
	combo_label.text = "COMBO %d - BEST %d" % [maxi(current_combo, 0), maxi(highest_combo, 0)]


func present_run_summary(summary: RunSummaryRecord) -> void:
	if summary == null:
		return
	main_menu.visible = false
	pause_menu.visible = false
	settings_panel.visible = false
	summary_panel.visible = true
	boss_panel.visible = false
	tutorial_panel.visible = false
	combo_panel.visible = false
	summary_title.text = "%s - RUN COMPLETE" % summary.result_label.to_upper()
	summary_highlight.text = "LOOP  /  %d LAPS  /  %d BLOCKS  /  %s\nBUILD EXPRESSION  /  %s  •  HIGHLIGHT  /  %d COMBO" % [
		summary.laps_completed,
		summary.blocks_completed,
		"BOSS COMMITTED" if summary.boss_committed else summary.result_label.to_upper(),
		summary.active_synergies if not summary.active_synergies.is_empty() else summary.equipment_build,
		summary.highest_combo,
	]
	summary_left.text = "\n".join([
		"RESULT  %s" % summary.result_label.to_upper(),
		"DURATION  %s" % _format_time(summary.duration_seconds),
		"DISTRICT LAPS  %d / 3" % summary.laps_completed,
		"BLOCKS RESOLVED  %d / 9" % summary.blocks_completed,
		"SEED  %d" % summary.run_seed,
		"SCHEMA  %d" % summary.random_schema_version,
		"MAX HEAT  %d" % summary.maximum_heat,
		"FINAL NIGHT PRESSURE  %.1f" % summary.final_night_pressure,
		"ENEMIES DEFEATED  %d" % summary.enemies_defeated,
		"ELITES DEFEATED  %d" % summary.elites_defeated,
		"BOSS RESULT  %s" % summary.boss_result,
	])
	summary_right.text = "\n".join([
		"COINS  %d" % summary.coins_collected,
		"MANUAL CLUSTERS  %d" % summary.manual_clusters_collected,
		"MAX STREAK  %d" % summary.maximum_manual_streak,
		"SCRAP SECURED  %d" % summary.scrap_secured,
		"HIGHEST COMBO  %d" % summary.highest_combo,
		"LAP DECISIONS  %s" % _lap_decision_summary(summary.lap_decisions),
		"EQUIPMENT BUILD",
		summary.equipment_build,
		"ACTIVE SYNERGIES",
		summary.active_synergies,
	])
	replay_button.grab_focus()


func _lap_decision_summary(decisions: Array[Dictionary]) -> String:
	if decisions.is_empty():
		return "NONE"
	var labels: PackedStringArray = PackedStringArray()
	for decision: Dictionary in decisions:
		labels.append(str(decision.get("decision", &"unknown")).to_upper())
	return " > ".join(labels)


func is_main_menu_visible() -> bool:
	return main_menu.visible


func is_pause_visible() -> bool:
	return pause_menu.visible


func is_settings_visible() -> bool:
	return settings_panel.visible


func is_summary_visible() -> bool:
	return summary_panel.visible


func has_blocking_modal() -> bool:
	return main_menu.visible or pause_menu.visible or settings_panel.visible or summary_panel.visible


func get_selected_crew_id() -> StringName:
	return _selected_crew_id


func get_settings_snapshot_from_controls() -> Dictionary:
	return {
		"master_volume": float(master_slider.value),
		"music_volume": float(music_slider.value),
		"sound_effects_volume": float(sfx_slider.value),
		"fullscreen": display_mode.selected == 1,
		"screen_shake_intensity": float(shake_slider.value),
		"damage_numbers_enabled": damage_numbers_toggle.button_pressed,
		"hit_flash_reduction": float(hit_flash_slider.value),
		"pause_on_focus_loss": focus_pause_toggle.button_pressed,
	}


func _present_crew_button(button: Button, crew_id: StringName) -> void:
	var entry: Dictionary = _crew_entries.get(crew_id, {})
	var display_name: String = str(entry.get("display_name", String(crew_id).capitalize()))
	var archetype: String = str(entry.get("archetype", "CREW"))
	var unlocked: bool = bool(entry.get("unlocked", false))
	button.text = "%s\n%s" % [display_name.to_upper(), archetype.to_upper() if unlocked else "LOCKED"]
	button.disabled = not unlocked
	button.tooltip_text = (
		str(entry.get("summary", ""))
		if unlocked
		else str(entry.get("unlock_hint", "LOCKED IN THIS PROFILE"))
	)
	button.theme_type_variation = &"ChoiceCard"


func _select_crew(crew_id: StringName, emit_ui_feedback: bool = true) -> void:
	var entry: Dictionary = _crew_entries.get(crew_id, {})
	if not bool(entry.get("unlocked", false)):
		return
	_selected_crew_id = crew_id
	start_button.disabled = false
	crew_details.text = "%s - %s\n%s\n%s" % [
		str(entry.get("display_name", String(crew_id))).to_upper(),
		str(entry.get("archetype", "CREW")).to_upper(),
		str(entry.get("summary", "")),
		str(entry.get("trait_text", "NO PERMANENT STAT BONUS")),
	]
	jax_button.button_pressed = crew_id == &"jax"
	zoey_button.button_pressed = crew_id == &"zoey"
	rex_button.button_pressed = crew_id == &"rex"
	for crew_button: Button in [jax_button, zoey_button, rex_button]:
		crew_button.theme_type_variation = (
			&"ChoiceCardSelected" if crew_button.button_pressed else &"ChoiceCard"
		)
	if emit_ui_feedback:
		ui_confirmed.emit()


func _on_start_pressed() -> void:
	if _selected_crew_id == &"":
		return
	ui_confirmed.emit()
	start_run_requested.emit(_selected_crew_id)


func _open_settings_from_main() -> void:
	_settings_context = SETTINGS_CONTEXT_MAIN
	settings_panel.visible = true
	pause_menu.visible = false
	master_slider.grab_focus()
	ui_confirmed.emit()


func _open_settings_from_pause() -> void:
	_settings_context = SETTINGS_CONTEXT_PAUSE
	settings_panel.visible = true
	pause_menu.visible = false
	master_slider.grab_focus()
	ui_confirmed.emit()


func _close_settings() -> void:
	settings_panel.visible = false
	if _settings_context == SETTINGS_CONTEXT_PAUSE:
		pause_menu.visible = true
	ui_confirmed.emit()


func _on_settings_apply_pressed() -> void:
	_latest_settings = get_settings_snapshot_from_controls()
	settings_status.text = "SAVING SETTINGS..."
	settings_apply_requested.emit(_latest_settings.duplicate(true))
	ui_confirmed.emit()


func _on_reset_save_pressed() -> void:
	if not _reset_confirmation_armed:
		_reset_confirmation_armed = true
		reset_save_button.text = "CONFIRM RESET SAVE"
		profile_status.text = "RESET CLEARS ONLY THE VERSIONED DEVELOPMENT PROFILE"
		ui_confirmed.emit()
		return
	_reset_confirmation_armed = false
	reset_save_button.text = "RESET DEVELOPMENT SAVE"
	reset_save_requested.emit()
	ui_confirmed.emit()


func _on_resume_pressed() -> void:
	resume_requested.emit()
	ui_confirmed.emit()


func _on_replay_pressed() -> void:
	restart_same_seed_requested.emit()
	ui_confirmed.emit()


func _on_restart_pressed() -> void:
	restart_new_seed_requested.emit()
	ui_confirmed.emit()


func _on_main_menu_pressed() -> void:
	return_to_main_menu_requested.emit()
	ui_confirmed.emit()


func _bind_button(button: Button, callback: Callable) -> void:
	button.pressed.connect(callback)
	button.mouse_entered.connect(_on_button_hovered)


func _on_button_hovered() -> void:
	ui_hovered.emit()


func _format_time(elapsed_seconds: float) -> String:
	var total_seconds: int = maxi(int(floor(elapsed_seconds)), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
