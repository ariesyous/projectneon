@tool
class_name NeonCountdownStatus
extends PanelContainer

var _title: Label = null
var _value: Label = null


func _ready() -> void:
	theme_type_variation = &"RaisedPanel"
	custom_minimum_size = Vector2(164.0, 64.0)
	_ensure_content()


func present(title_text: String, value_text: String, is_warning: bool = false) -> void:
	_ensure_content()
	_title.text = title_text.to_upper()
	_value.text = value_text
	_value.theme_type_variation = &"WarningLabel" if is_warning else &"BodyLabel"


func get_title_text() -> String:
	_ensure_content()
	return _title.text


func get_value_text() -> String:
	_ensure_content()
	return _value.text


func _ensure_content() -> void:
	if _title != null:
		return
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", NeonUiTokens.SPACE_1)
	add_child(column)
	_title = Label.new()
	_title.name = "Title"
	_title.theme_type_variation = &"EyebrowLabel"
	column.add_child(_title)
	_value = Label.new()
	_value.name = "Value"
	_value.theme_type_variation = &"BodyLabel"
	_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_value)
