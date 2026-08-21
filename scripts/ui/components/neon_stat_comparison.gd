@tool
class_name NeonStatComparison
extends PanelContainer

var _heading: Label = null
var _before_after: Label = null
var _expression: Label = null


func _ready() -> void:
	theme_type_variation = &"RaisedPanel"
	custom_minimum_size = Vector2(360.0, 98.0)
	_ensure_content()


func present(
	heading_text: String,
	before_text: String,
	after_text: String,
	expression_text: String,
	is_improvement: bool = true
) -> void:
	_ensure_content()
	_heading.text = heading_text.to_upper()
	_before_after.text = "%s  ->  %s" % [before_text, after_text]
	_before_after.theme_type_variation = &"SafeLabel" if is_improvement else &"WarningLabel"
	_expression.text = expression_text


func get_comparison_text() -> String:
	_ensure_content()
	return _before_after.text


func _ensure_content() -> void:
	if _heading != null:
		return
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", NeonUiTokens.SPACE_1)
	add_child(column)
	_heading = Label.new()
	_heading.name = "Heading"
	_heading.theme_type_variation = &"EyebrowLabel"
	column.add_child(_heading)
	_before_after = Label.new()
	_before_after.name = "BeforeAfter"
	_before_after.theme_type_variation = &"SafeLabel"
	column.add_child(_before_after)
	_expression = Label.new()
	_expression.name = "Expression"
	_expression.theme_type_variation = &"MutedLabel"
	_expression.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_expression)
