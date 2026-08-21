@tool
class_name Wp01StateGallery
extends Control

## Deterministic WP01 visual-review fixture. It is never instanced by GameRun
## and owns no gameplay state, authority, timing, or random draws.

const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
const ICON_HEALTH: Texture2D = preload("res://assets/ui/icons/wp01/health.svg")
const ICON_HEAT: Texture2D = preload("res://assets/ui/icons/wp01/heat.svg")
const ICON_PRESSURE: Texture2D = preload("res://assets/ui/icons/wp01/pressure.svg")
const ICON_COINS: Texture2D = preload("res://assets/ui/icons/wp01/coins.svg")
const ICON_PLAN: Texture2D = preload("res://assets/ui/icons/wp01/phase_plan.svg")
const ICON_FIGHT: Texture2D = preload("res://assets/ui/icons/wp01/phase_fight.svg")
const ICON_REWARD: Texture2D = preload("res://assets/ui/icons/wp01/phase_reward.svg")
const ICON_SHOP: Texture2D = preload("res://assets/ui/icons/wp01/phase_shop.svg")
const ICON_EXTRACT: Texture2D = preload("res://assets/ui/icons/wp01/phase_extract.svg")
const ICON_RESULT: Texture2D = preload("res://assets/ui/icons/wp01/phase_result.svg")
const ICON_ENVIRONMENT: Texture2D = preload("res://assets/ui/icons/wp01/environment.svg")
const ICON_FOCUS: Texture2D = preload("res://assets/ui/icons/wp01/focus.svg")
const ICON_BACKUP: Texture2D = preload("res://assets/ui/icons/wp01/backup.svg")
const ICON_KNOCKBACK: Texture2D = preload("res://assets/ui/icons/wp01/knockback.svg")
const ICON_TECH: Texture2D = preload("res://assets/ui/icons/wp01/tech.svg")
const ICON_BLEED: Texture2D = preload("res://assets/ui/icons/wp01/bleed.svg")

@export_enum("combat", "plan", "reward", "shop", "extract", "pause", "settings", "summary")
var representative_state: String = "combat"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = NeonUiTokens.create_theme()
	_render_state(representative_state)
	NeonUiTokens.apply_accessibility_defaults(self)


func present_state(state_name: String) -> void:
	representative_state = state_name
	if is_node_ready():
		_render_state(state_name)
		NeonUiTokens.apply_accessibility_defaults(self)


func _render_state(state_name: String) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.free()
	var canvas: ColorRect = ColorRect.new()
	canvas.name = "Canvas"
	canvas.color = NeonUiTokens.CANVAS
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(canvas, Rect2(Vector2.ZERO, DESIGN_SIZE))
	add_child(canvas)
	_add_stage_texture()
	match state_name:
		"plan":
			_render_plan()
		"reward":
			_render_reward()
		"shop":
			_render_shop()
		"extract":
			_render_extract()
		"pause":
			_render_pause()
		"settings":
			_render_settings()
		"summary":
			_render_summary()
		_:
			_render_combat()


func _add_stage_texture() -> void:
	var skyline: ColorRect = ColorRect.new()
	skyline.color = Color("10182c")
	skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(skyline, Rect2(0.0, 116.0, 1280.0, 494.0))
	add_child(skyline)
	var road: ColorRect = ColorRect.new()
	road.color = Color("15192a")
	road.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(road, Rect2(0.0, 318.0, 1280.0, 226.0))
	add_child(road)
	var lane: ColorRect = ColorRect.new()
	lane.color = Color("32405c")
	lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(lane, Rect2(330.0, 430.0, 620.0, 3.0))
	add_child(lane)


func _render_combat() -> void:
	var banner: NeonPhaseBanner = NeonPhaseBanner.new()
	banner.name = "PhaseBanner"
	_set_rect(banner, Rect2(20.0, 16.0, 744.0, 92.0))
	add_child(banner)
	banner.present(
		"FIGHT",
		"CURRENT ROUTE  /  NODE 4  /  62%",
		"VIPER ENFORCER  /  ENEMY ARRIVAL",
		"ARRIVAL",
		"2.4s",
		true,
		ICON_FIGHT
	)
	var pressure: Panel = _add_surface("RunStatus", Rect2(776.0, 16.0, 292.0, 92.0))
	_add_icon(pressure, ICON_HEAT, Rect2(12.0, 8.0, 24.0, 24.0))
	_add_label_to(pressure, "HEAT 061  /  AGGRESSIVE", Rect2(42.0, 6.0, 236.0, 24.0), &"HeatLabel")
	_add_meter(pressure, Rect2(42.0, 34.0, 238.0, 10.0), 61.0, 100.0)
	_add_icon(pressure, ICON_PRESSURE, Rect2(12.0, 52.0, 24.0, 24.0))
	_add_label_to(pressure, "NIGHT 31.5  /  ONE-WAY", Rect2(42.0, 49.0, 238.0, 24.0), &"PressureLabel")
	_add_meter(pressure, Rect2(42.0, 76.0, 238.0, 10.0), 31.5, 50.0)
	var resources: Panel = _add_surface("Resources", Rect2(1080.0, 16.0, 180.0, 92.0))
	_add_icon(resources, ICON_COINS, Rect2(12.0, 12.0, 28.0, 28.0))
	_add_label_to(resources, "COINS 126\nSCRAP 08\nSTREAK x3", Rect2(48.0, 8.0, 120.0, 76.0), &"BodyLabel")
	_render_combat_side_panels()
	_render_stage_actors()
	_render_combat_actions()


func _render_combat_side_panels() -> void:
	var crew: Panel = _add_surface("Crew", Rect2(20.0, 122.0, 270.0, 136.0), &"RaisedPanel")
	_add_label_to(crew, "JAX  /  AUTO FIGHT", Rect2(12.0, 8.0, 246.0, 24.0), &"EyebrowLabel")
	_add_icon(crew, ICON_HEALTH, Rect2(12.0, 48.0, 30.0, 30.0))
	_add_label_to(crew, "STRIKING\nHEALTH 402 / 520", Rect2(52.0, 39.0, 198.0, 50.0), &"HealthLabel")
	_add_meter(crew, Rect2(12.0, 105.0, 246.0, 12.0), 402.0, 520.0)
	var build: Panel = _add_surface("Build", Rect2(990.0, 122.0, 270.0, 136.0), &"RaisedPanel")
	_add_label_to(build, "BUILD  /  KNOCKBACK 2 ACTIVE", Rect2(12.0, 8.0, 246.0, 24.0), &"EyebrowLabel")
	_add_icon(build, ICON_KNOCKBACK, Rect2(16.0, 50.0, 52.0, 52.0))
	_add_icon(build, ICON_KNOCKBACK, Rect2(84.0, 50.0, 52.0, 52.0))
	_add_icon(build, ICON_TECH, Rect2(152.0, 50.0, 52.0, 52.0))
	_add_label_to(build, "INSPECT >", Rect2(154.0, 104.0, 98.0, 22.0), &"MutedLabel", HORIZONTAL_ALIGNMENT_RIGHT)


func _render_stage_actors() -> void:
	var crew_marker: Panel = _add_surface("CrewMarker", Rect2(462.0, 345.0, 96.0, 96.0), &"SafePanel")
	_add_label_to(crew_marker, "JAX\nAUTO", Rect2(8.0, 18.0, 80.0, 58.0), &"SafeLabel", HORIZONTAL_ALIGNMENT_CENTER)
	var enemy_marker: Panel = _add_surface("EnemyMarker", Rect2(716.0, 334.0, 118.0, 118.0), &"DangerPanel")
	_add_label_to(enemy_marker, "VIPER\nENFORCER", Rect2(8.0, 26.0, 102.0, 64.0), &"WarningLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("Telegraph", "CHARGE  /  0.7s  /  MOVE SHAPE", Rect2(512.0, 274.0, 370.0, 34.0), &"WarningLabel", HORIZONTAL_ALIGNMENT_CENTER)


func _render_combat_actions() -> void:
	var environment: NeonInterventionButton = NeonInterventionButton.new()
	environment.name = "Environment"
	environment.icon = ICON_ENVIRONMENT
	environment.expand_icon = true
	environment.add_theme_constant_override(&"icon_max_width", 44)
	_set_rect(environment, Rect2(990.0, 280.0, 270.0, 112.0))
	add_child(environment)
	environment.present("1  ENV", "HYDRANT", "READY  /  2 TARGETS", NeonInterventionButton.VisualState.READY)
	var strip: Panel = _add_surface("ActionStrip", Rect2(280.0, 610.0, 700.0, 94.0))
	_add_label_to(strip, "INTERVENE  /  COMBAT CONTINUES", Rect2(14.0, 5.0, 400.0, 24.0), &"EyebrowLabel")
	var backup: NeonInterventionButton = NeonInterventionButton.new()
	backup.icon = ICON_BACKUP
	backup.expand_icon = true
	backup.add_theme_constant_override(&"icon_max_width", 30)
	_set_rect(backup, Rect2(14.0, 32.0, 310.0, 56.0))
	strip.add_child(backup)
	backup.present("2  BACKUP", "CALL BACKUP", "READY  /  2 LEFT", NeonInterventionButton.VisualState.READY)
	var focus: NeonInterventionButton = NeonInterventionButton.new()
	focus.icon = ICON_FOCUS
	focus.expand_icon = true
	focus.add_theme_constant_override(&"icon_max_width", 30)
	_set_rect(focus, Rect2(338.0, 32.0, 348.0, 56.0))
	strip.add_child(focus)
	focus.present("FOCUS", "PRECISION", "NO ACTION EQUIPPED", NeonInterventionButton.VisualState.UNAVAILABLE, true)


func _render_plan() -> void:
	var panel: Panel = _decision_panel("DistrictPlan", "DISTRICT PLAN", "PLAN NEXT BLOCK  /  SEE EXACT CONSEQUENCES", ICON_PLAN)
	_add_label_to(panel, "LAP 1  /  BLOCK 2  /  NEXT: FIGHT", Rect2(32.0, 104.0, 976.0, 30.0), &"EyebrowLabel")
	var left: NeonChoiceCard = _choice(panel, Rect2(32.0, 154.0, 472.0, 238.0), ICON_PLAN, "QUIET STREETS\nLOWER HEAT  /  LIGHT ENCOUNTER\nBUILD SPACE  /  CALMER RISK")
	left.set_visual_state(NeonChoiceCard.VisualState.SELECTED, "SELECTED")
	_choice(panel, Rect2(536.0, 154.0, 472.0, 238.0), ICON_FIGHT, "VIPER TERRITORY\n+20 HEAT  /  ELITE ENCOUNTER\nGEAR OPPORTUNITY  /  HIGH RISK")
	var preview: NeonStatComparison = NeonStatComparison.new()
	_set_rect(preview, Rect2(32.0, 416.0, 976.0, 108.0))
	panel.add_child(preview)
	preview.present("EXACT CONSEQUENCE", "HEAT 42", "HEAT 32", "NEXT BLOCK: QUIET STREETS  /  NIGHT PRESSURE UNCHANGED", true)
	_add_button(panel, "CONFIRM NEXT BLOCK", Rect2(536.0, 536.0, 472.0, 58.0), &"PrimaryButton")
	_add_button(panel, "BACK", Rect2(32.0, 536.0, 220.0, 58.0), &"SecondaryButton")


func _render_reward() -> void:
	var panel: Panel = _decision_panel("Reward", "REWARD", "CHOOSE GEAR  /  SEE BUILD CHANGE BEFORE CONFIRM", ICON_REWARD)
	_choice(panel, Rect2(32.0, 142.0, 300.0, 230.0), ICON_KNOCKBACK, "SPIKED BAT\nKNOCKBACK  /  HEAVY HIT\nACTIVE SLOT")
	var selected: NeonChoiceCard = _choice(panel, Rect2(370.0, 142.0, 300.0, 230.0), ICON_TECH, "SIGNAL JAMMER\nTECH  /  COOLDOWN\nACTIVATES TECH 2")
	selected.set_visual_state(NeonChoiceCard.VisualState.SELECTED, "SELECTED")
	_choice(panel, Rect2(708.0, 142.0, 300.0, 230.0), ICON_BLEED, "RAZOR CHAIN\nBLEED  /  TRIGGER\nBACKPACK OPTION")
	var comparison: NeonStatComparison = NeonStatComparison.new()
	_set_rect(comparison, Rect2(32.0, 396.0, 976.0, 126.0))
	panel.add_child(comparison)
	comparison.present("ACTIVE BUILD PREVIEW", "TECH 1/2", "TECH 2/2 ACTIVE", "ACTIVATES SHOCK CHAIN  /  REPLACES EMPTY ACTIVE SLOT  /  CONFIRM REQUIRED", true)
	_add_button(panel, "SKIP GEAR  /  KEEP RUN REWARD", Rect2(32.0, 540.0, 400.0, 54.0), &"SecondaryButton")
	_add_button(panel, "CONFIRM GEAR", Rect2(536.0, 540.0, 472.0, 54.0), &"PrimaryButton")


func _render_shop() -> void:
	var panel: Panel = _decision_panel("Shop", "SHOP", "ONE PURCHASE FROM FINITE STOCK  /  OR LEAVE", ICON_SHOP)
	_choice(panel, Rect2(32.0, 148.0, 472.0, 210.0), ICON_HEAT, "COOL THE DISTRICT\n60 COINS  /  HEAT 58 -> 43\nSTOCK 1")
	_choice(panel, Rect2(536.0, 148.0, 472.0, 210.0), ICON_SHOP, "LEAVE SHOP\nKEEP 126 COINS\nCONTINUE CURRENT ROUTE")
	var comparison: NeonStatComparison = NeonStatComparison.new()
	_set_rect(comparison, Rect2(32.0, 386.0, 976.0, 130.0))
	panel.add_child(comparison)
	comparison.present("PURCHASE PREVIEW", "HEAT 58", "HEAT 43", "COINS 126 -> 66  /  NIGHT PRESSURE UNCHANGED", true)
	_add_label_to(panel, "NIGHT PRESSURE IS IRREVERSIBLE  /  NOTHING CHANGES UNTIL CONFIRM", Rect2(32.0, 536.0, 976.0, 34.0), &"WarningLabel", HORIZONTAL_ALIGNMENT_CENTER)


func _render_extract() -> void:
	var panel: Panel = _decision_panel("Extract", "EXTRACT OR PUSH", "SECURE THE RUN OR CONTINUE AT GREATER RISK", ICON_EXTRACT)
	var extract: NeonChoiceCard = _choice(panel, Rect2(32.0, 148.0, 472.0, 238.0), ICON_EXTRACT, "EXTRACT\nSECURE 126 COINS  /  08 SCRAP\nEND RUN WITH CURRENT BUILD")
	extract.set_visual_state(NeonChoiceCard.VisualState.SELECTED, "SELECTED")
	var push: NeonChoiceCard = _choice(panel, Rect2(536.0, 148.0, 472.0, 238.0), ICON_FIGHT, "PUSH\nHEAT 58 -> 64\nNIGHT PRESSURE CONTINUES")
	push.set_visual_state(NeonChoiceCard.VisualState.WARNING, "HIGH RISK")
	var comparison: NeonStatComparison = NeonStatComparison.new()
	_set_rect(comparison, Rect2(32.0, 410.0, 976.0, 120.0))
	panel.add_child(comparison)
	comparison.present("DECISION PREVIEW", "CURRENT RESULT", "EXTRACTED", "FINAL ON CONFIRM  /  PUSH KEEPS IRREVERSIBLE NIGHT PRESSURE", false)
	_add_button(panel, "CONFIRM EXTRACT", Rect2(536.0, 542.0, 472.0, 54.0), &"PrimaryButton")


func _render_pause() -> void:
	var panel: Panel = _add_surface("Pause", Rect2(390.0, 94.0, 500.0, 532.0), &"DecisionPanel")
	_add_label_to(panel, "RUN PAUSED", Rect2(30.0, 28.0, 440.0, 46.0), &"DisplayLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_add_label_to(panel, "CURRENT RUN PRESERVED\nELIGIBLE TIME, COMBAT, AND NIGHT PRESSURE ARE STOPPED", Rect2(40.0, 82.0, 420.0, 66.0), &"MutedLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_add_button(panel, "RESUME RUN", Rect2(70.0, 172.0, 360.0, 64.0), &"PrimaryButton")
	_add_button(panel, "SETTINGS + ACCESSIBILITY", Rect2(70.0, 254.0, 360.0, 64.0), &"SecondaryButton")
	_add_button(panel, "RESTART RUN  /  NEW SEED", Rect2(70.0, 336.0, 360.0, 64.0), &"DangerButton")
	_add_button(panel, "RETURN TO MAIN MENU", Rect2(70.0, 418.0, 360.0, 64.0), &"SecondaryButton")


func _render_settings() -> void:
	var panel: Panel = _add_surface("Settings", Rect2(230.0, 35.0, 820.0, 650.0), &"DecisionPanel")
	_add_label_to(panel, "SETTINGS + ACCESSIBILITY", Rect2(30.0, 20.0, 760.0, 44.0), &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_add_settings_row(panel, "MASTER VOLUME", 86.0, 0.80)
	_add_settings_row(panel, "MUSIC VOLUME", 142.0, 0.65)
	_add_settings_row(panel, "SOUND-EFFECTS VOLUME", 198.0, 0.80)
	_add_settings_row(panel, "SCREEN-SHAKE INTENSITY", 282.0, 0.75)
	_add_settings_row(panel, "HIT-FLASH REDUCTION", 394.0, 0.0)
	_add_button(panel, "DISPLAY MODE  /  WINDOWED", Rect2(345.0, 246.0, 415.0, 48.0), &"SecondaryButton")
	_add_button(panel, "[X] SHOW DAMAGE NUMBERS", Rect2(45.0, 338.0, 715.0, 48.0), &"SecondaryButton")
	_add_button(panel, "[X] PAUSE ON FOCUS LOSS  /  MANUAL RESUME", Rect2(45.0, 450.0, 715.0, 48.0), &"SecondaryButton")
	_add_label_to(panel, "WARNINGS, COOLDOWNS, AND TELEGRAPHS ALWAYS INCLUDE TEXT + SHAPE.", Rect2(45.0, 510.0, 715.0, 36.0), &"WarningLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_add_button(panel, "APPLY + SAVE", Rect2(45.0, 570.0, 345.0, 54.0), &"PrimaryButton")
	_add_button(panel, "BACK", Rect2(415.0, 570.0, 345.0, 54.0), &"SecondaryButton")


func _render_summary() -> void:
	var panel: Panel = _add_surface("Summary", Rect2(130.0, 35.0, 1020.0, 650.0), &"DecisionPanel")
	_add_label_to(panel, "VICTORY  /  RUN COMPLETE", Rect2(30.0, 18.0, 960.0, 48.0), &"DisplayLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_add_label_to(panel, "BUILD EXPRESSION  /  KNOCKBACK 2 + TECH 2\nHIGHLIGHT  /  30 COMBO  /  1 ELITE  /  THE VIPER DEFEATED", Rect2(45.0, 72.0, 930.0, 66.0), &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_add_label_to(panel, "OUTCOME + PRESSURE\nDURATION  09:42\nMAX HEAT  76\nFINAL NIGHT PRESSURE  50.0\nENEMIES  31\nELITES  1\nBOSS  DEFEATED\nSEED  48291  /  SCHEMA 1", Rect2(45.0, 154.0, 447.0, 352.0), &"BodyLabel")
	_add_label_to(panel, "BUILD + REWARDS\nCOINS  286\nSCRAP SECURED  18\nMANUAL CLUSTERS  4\nMAX STREAK  3\nHIGHEST COMBO  30\nEQUIPMENT  BAT / JACKET / GLOVES\nSYNERGIES  KNOCKBACK 2 / TECH 2", Rect2(528.0, 154.0, 447.0, 352.0), &"BodyLabel")
	_add_button(panel, "REPLAY SAME SEED\nTRY A DIFFERENT PLAN", Rect2(45.0, 520.0, 300.0, 84.0), &"PrimaryButton")
	_add_button(panel, "NEW SEED\nNEW DISTRICT RUN", Rect2(360.0, 520.0, 300.0, 84.0), &"SecondaryButton")
	_add_button(panel, "RETURN TO\nMAIN MENU", Rect2(675.0, 520.0, 300.0, 84.0), &"SecondaryButton")


func _decision_panel(panel_name: String, title: String, subtitle: String, icon: Texture2D) -> Panel:
	var panel: Panel = _add_surface(panel_name, Rect2(120.0, 56.0, 1040.0, 620.0), &"DecisionPanel")
	_add_icon(panel, icon, Rect2(32.0, 24.0, 52.0, 52.0))
	_add_label_to(panel, title, Rect2(100.0, 22.0, 650.0, 42.0), &"DisplayLabel")
	_add_label_to(panel, subtitle, Rect2(100.0, 64.0, 850.0, 30.0), &"EyebrowLabel")
	return panel


func _choice(parent: Control, rect: Rect2, icon: Texture2D, text_value: String) -> NeonChoiceCard:
	var choice: NeonChoiceCard = NeonChoiceCard.new()
	choice.text = text_value
	choice.icon = icon
	choice.expand_icon = true
	choice.add_theme_constant_override(&"icon_max_width", 64)
	choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_set_rect(choice, rect)
	parent.add_child(choice)
	return choice


func _add_settings_row(parent: Control, title: String, y: float, value: float) -> void:
	_add_label_to(parent, title, Rect2(45.0, y, 280.0, 32.0), &"BodyLabel")
	var slider: HSlider = HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	_set_rect(slider, Rect2(345.0, y - 4.0, 415.0, 40.0))
	parent.add_child(slider)


func _add_surface(
	control_name: String,
	rect: Rect2,
	variation: StringName = &"SurfacePanel"
) -> Panel:
	var panel: Panel = Panel.new()
	panel.name = control_name
	panel.theme_type_variation = variation
	_set_rect(panel, rect)
	add_child(panel)
	return panel


func _add_label(
	label_name: String,
	text_value: String,
	rect: Rect2,
	variation: StringName = &"BodyLabel",
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.text = text_value
	label.theme_type_variation = variation
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(label, rect)
	add_child(label)
	return label


func _add_label_to(
	parent: Control,
	text_value: String,
	rect: Rect2,
	variation: StringName = &"BodyLabel",
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.theme_type_variation = variation
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(label, rect)
	parent.add_child(label)
	return label


func _add_icon(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(icon, rect)
	parent.add_child(icon)
	return icon


func _add_meter(parent: Control, rect: Rect2, value: float, maximum: float) -> ProgressBar:
	var meter: ProgressBar = ProgressBar.new()
	meter.max_value = maximum
	meter.value = value
	meter.show_percentage = false
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(meter, rect)
	parent.add_child(meter)
	return meter


func _add_button(
	parent: Control,
	text_value: String,
	rect: Rect2,
	variation: StringName
) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.theme_type_variation = variation
	_set_rect(button, rect)
	parent.add_child(button)
	return button


func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
