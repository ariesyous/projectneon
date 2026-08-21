@tool
class_name NeonTooltip
extends PanelContainer

var _label: Label = null


func _ready() -> void:
	theme_type_variation = &"TooltipPanel"
	custom_minimum_size = Vector2(280.0, 0.0)
	_ensure_content()


func present(text_value: String) -> void:
	_ensure_content()
	_label.text = text_value


static func create(text_value: String) -> NeonTooltip:
	var tooltip: NeonTooltip = NeonTooltip.new()
	tooltip.present(text_value)
	return tooltip


func _ensure_content() -> void:
	if _label != null:
		return
	_label = Label.new()
	_label.name = "Text"
	_label.theme_type_variation = &"BodyLabel"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(248.0, 0.0)
	add_child(_label)
