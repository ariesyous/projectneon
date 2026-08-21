@tool
class_name NeonUiTokens
extends RefCounted

## WP01 presentation tokens. These values style presentation only and never
## participate in gameplay calculations, validation, timing, or randomness.

const FONT_CAPTION: int = 16
const FONT_BODY: int = 18
const FONT_LABEL: int = 20
const FONT_HEADING: int = 26
const FONT_DISPLAY: int = 34

const SPACE_1: int = 4
const SPACE_2: int = 8
const SPACE_3: int = 12
const SPACE_4: int = 16
const SPACE_5: int = 24
const SPACE_6: int = 32

const BORDER_THIN: int = 2
const BORDER_STRONG: int = 3
const RADIUS_SMALL: int = 6
const RADIUS_MEDIUM: int = 10
const RADIUS_LARGE: int = 14
const TOUCH_TARGET_MINIMUM: float = 48.0

const MOTION_FAST: float = 0.10
const MOTION_STANDARD: float = 0.18
const MOTION_EMPHASIS: float = 0.28
const TOAST_DURATION: float = 2.20

const INK: Color = Color("f3f6ff")
const INK_MUTED: Color = Color("a9b4ca")
const INK_DISABLED: Color = Color("738096")
const CANVAS: Color = Color("090d18")
const SURFACE: Color = Color("111827e8")
const SURFACE_RAISED: Color = Color("182235f4")
const SURFACE_SELECTED: Color = Color("123a43f7")
const BORDER: Color = Color("51627c")
const BORDER_SOFT: Color = Color("34445d")
const FOCUS: Color = Color("9afcff")
const PRIMARY: Color = Color("5fe6e1")
const PRIMARY_DARK: Color = Color("12383c")
const HEAT: Color = Color("ff6b86")
const PRESSURE: Color = Color("b18cff")
const HEALTH: Color = Color("63e1a8")
const COINS: Color = Color("ffd166")
const INFO: Color = Color("74c9ff")
const WARNING: Color = Color("ffbd69")
const SAFE: Color = Color("6fe6af")
const DANGER: Color = Color("ff7187")
const DISABLED: Color = Color("3e4859")


static func create_theme() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = FONT_BODY
	_define_text(theme)
	_define_surfaces(theme)
	_define_buttons(theme)
	_define_meters(theme)
	_define_inputs(theme)
	return theme


static func apply_accessibility_defaults(root: Control) -> void:
	_apply_control_defaults(root)


static func _apply_control_defaults(node: Node) -> void:
	if node is Button:
		var button: Button = node as Button
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size.y = maxf(
			button.custom_minimum_size.y,
			TOUCH_TARGET_MINIMUM
		)
		button.clip_text = true
	elif node is OptionButton:
		var option: OptionButton = node as OptionButton
		option.focus_mode = Control.FOCUS_ALL
		option.custom_minimum_size.y = maxf(option.custom_minimum_size.y, TOUCH_TARGET_MINIMUM)
	elif node is Slider:
		var slider: Slider = node as Slider
		slider.focus_mode = Control.FOCUS_ALL
		slider.custom_minimum_size.y = maxf(slider.custom_minimum_size.y, TOUCH_TARGET_MINIMUM)
	for child: Node in node.get_children():
		_apply_control_defaults(child)


static func _define_text(theme: Theme) -> void:
	theme.set_color(&"font_color", &"Label", INK)
	theme.set_color(&"font_shadow_color", &"Label", Color(0.0, 0.0, 0.0, 0.65))
	theme.set_constant(&"shadow_offset_x", &"Label", 1)
	theme.set_constant(&"shadow_offset_y", &"Label", 1)
	theme.set_font_size(&"font_size", &"Label", FONT_BODY)

	_define_variation(theme, &"CaptionLabel", &"Label", FONT_CAPTION, INK_MUTED)
	_define_variation(theme, &"BodyLabel", &"Label", FONT_BODY, INK)
	_define_variation(theme, &"MutedLabel", &"Label", FONT_CAPTION, INK_MUTED)
	_define_variation(theme, &"EyebrowLabel", &"Label", FONT_CAPTION, PRIMARY)
	_define_variation(theme, &"HeadingLabel", &"Label", FONT_HEADING, INK)
	_define_variation(theme, &"DisplayLabel", &"Label", FONT_DISPLAY, INK)
	_define_variation(theme, &"HeatLabel", &"Label", FONT_BODY, HEAT)
	_define_variation(theme, &"PressureLabel", &"Label", FONT_BODY, PRESSURE)
	_define_variation(theme, &"HeatCaption", &"Label", FONT_CAPTION, HEAT)
	_define_variation(theme, &"PressureCaption", &"Label", FONT_CAPTION, PRESSURE)
	_define_variation(theme, &"HealthLabel", &"Label", FONT_BODY, HEALTH)
	_define_variation(theme, &"WarningLabel", &"Label", FONT_BODY, WARNING)
	_define_variation(theme, &"SafeLabel", &"Label", FONT_BODY, SAFE)


static func _define_surfaces(theme: Theme) -> void:
	_define_panel_variation(theme, &"SurfacePanel", SURFACE, BORDER_SOFT, BORDER_THIN, RADIUS_MEDIUM)
	_define_panel_variation(theme, &"RaisedPanel", SURFACE_RAISED, BORDER, BORDER_THIN, RADIUS_MEDIUM)
	_define_panel_variation(theme, &"DecisionPanel", Color("0d1424f7"), PRIMARY, BORDER_STRONG, RADIUS_LARGE)
	_define_panel_variation(theme, &"SelectedPanel", SURFACE_SELECTED, PRIMARY, BORDER_STRONG, RADIUS_MEDIUM)
	_define_panel_variation(theme, &"SafePanel", Color("102f2af5"), SAFE, BORDER_STRONG, RADIUS_MEDIUM)
	_define_panel_variation(theme, &"WarningPanel", Color("312219f5"), WARNING, BORDER_STRONG, RADIUS_MEDIUM)
	_define_panel_variation(theme, &"DangerPanel", Color("351a25f5"), DANGER, BORDER_STRONG, RADIUS_MEDIUM)
	_define_panel_variation(theme, &"TooltipPanel", Color("0b111efb"), FOCUS, BORDER_THIN, RADIUS_SMALL)


static func _define_buttons(theme: Theme) -> void:
	theme.set_font_size(&"font_size", &"Button", FONT_BODY)
	theme.set_color(&"font_color", &"Button", INK)
	theme.set_color(&"font_hover_color", &"Button", INK)
	theme.set_color(&"font_pressed_color", &"Button", CANVAS)
	theme.set_color(&"font_focus_color", &"Button", INK)
	theme.set_color(&"font_disabled_color", &"Button", INK_DISABLED)
	theme.set_constant(&"h_separation", &"Button", SPACE_2)
	theme.set_stylebox(&"normal", &"Button", _button_box(SURFACE_RAISED, BORDER_SOFT))
	theme.set_stylebox(&"hover", &"Button", _button_box(Color("20304af8"), PRIMARY))
	theme.set_stylebox(&"pressed", &"Button", _button_box(PRIMARY, PRIMARY))
	theme.set_stylebox(&"focus", &"Button", _focus_box())
	theme.set_stylebox(&"disabled", &"Button", _button_box(Color("171d29e6"), DISABLED))

	_define_button_variation(theme, &"PrimaryButton", PRIMARY_DARK, PRIMARY, PRIMARY)
	_define_button_variation(theme, &"SecondaryButton", SURFACE_RAISED, BORDER, INFO)
	_define_button_variation(theme, &"DangerButton", Color("351a25f7"), DANGER, DANGER)
	_define_button_variation(theme, &"ChoiceCard", SURFACE_RAISED, BORDER, PRIMARY)
	_define_button_variation(theme, &"ChoiceCardSelected", SURFACE_SELECTED, PRIMARY, PRIMARY)
	_define_button_variation(theme, &"InterventionReady", Color("113833f7"), SAFE, SAFE)
	_define_button_variation(theme, &"InterventionCooling", Color("2a2444f7"), PRESSURE, PRESSURE)
	_define_button_variation(theme, &"InterventionUnavailable", Color("251f1bf2"), WARNING, WARNING)


static func _define_meters(theme: Theme) -> void:
	theme.set_stylebox(&"background", &"ProgressBar", _meter_box(Color("0a1020"), BORDER_SOFT))
	theme.set_stylebox(&"fill", &"ProgressBar", _meter_box(PRIMARY, PRIMARY))
	theme.set_color(&"font_color", &"ProgressBar", INK)
	theme.set_color(&"font_outline_color", &"ProgressBar", CANVAS)
	theme.set_constant(&"outline_size", &"ProgressBar", 2)
	theme.set_font_size(&"font_size", &"ProgressBar", FONT_CAPTION)


static func _define_inputs(theme: Theme) -> void:
	theme.set_font_size(&"font_size", &"OptionButton", FONT_BODY)
	theme.set_font_size(&"font_size", &"CheckButton", FONT_BODY)
	theme.set_color(&"font_color", &"CheckButton", INK)
	theme.set_color(&"font_disabled_color", &"CheckButton", INK_DISABLED)
	theme.set_stylebox(&"focus", &"CheckButton", _focus_box())
	theme.set_stylebox(&"slider", &"HSlider", _meter_box(Color("172238"), BORDER_SOFT))
	theme.set_stylebox(&"grabber_area", &"HSlider", _meter_box(PRIMARY, PRIMARY))
	theme.set_stylebox(&"grabber_area_highlight", &"HSlider", _meter_box(FOCUS, FOCUS))


static func _define_variation(
	theme: Theme,
	variation: StringName,
	base: StringName,
	font_size: int,
	font_color: Color
) -> void:
	theme.set_type_variation(variation, base)
	theme.set_font_size(&"font_size", variation, font_size)
	theme.set_color(&"font_color", variation, font_color)


static func _define_panel_variation(
	theme: Theme,
	variation: StringName,
	background: Color,
	border: Color,
	border_width: int,
	radius: int
) -> void:
	theme.set_type_variation(variation, &"Panel")
	theme.set_stylebox(&"panel", variation, _surface_box(background, border, border_width, radius))


static func _define_button_variation(
	theme: Theme,
	variation: StringName,
	background: Color,
	border: Color,
	hover_border: Color
) -> void:
	theme.set_type_variation(variation, &"Button")
	theme.set_stylebox(&"normal", variation, _button_box(background, border))
	theme.set_stylebox(&"hover", variation, _button_box(background.lightened(0.08), hover_border))
	theme.set_stylebox(&"pressed", variation, _button_box(PRIMARY, PRIMARY))
	theme.set_stylebox(&"focus", variation, _focus_box())
	theme.set_stylebox(&"disabled", variation, _button_box(Color("171d29e6"), DISABLED))


static func _surface_box(
	background: Color,
	border: Color,
	border_width: int,
	radius: int
) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = SPACE_4
	box.content_margin_top = SPACE_3
	box.content_margin_right = SPACE_4
	box.content_margin_bottom = SPACE_3
	return box


static func _button_box(background: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = _surface_box(background, border, BORDER_THIN, RADIUS_SMALL)
	box.content_margin_left = SPACE_3
	box.content_margin_right = SPACE_3
	box.content_margin_top = SPACE_2
	box.content_margin_bottom = SPACE_2
	return box


static func _focus_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	box.border_color = FOCUS
	box.set_border_width_all(BORDER_STRONG)
	box.set_corner_radius_all(RADIUS_SMALL)
	box.expand_margin_left = 2.0
	box.expand_margin_top = 2.0
	box.expand_margin_right = 2.0
	box.expand_margin_bottom = 2.0
	return box


static func _meter_box(background: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(RADIUS_SMALL)
	return box
