@tool
class_name EquipmentDragSlot
extends Button

## Reusable equipment drag source/drop target. It owns only pointer
## presentation; GameHUD stages the resulting intent and gameplay authority
## remains in RewardDirector/SynergySystem.

signal equipment_drag_started(payload: EquipmentDragPayload)
signal equipment_drag_ended(payload: EquipmentDragPayload, successful: bool)
signal equipment_drop_requested(
	payload: EquipmentDragPayload,
	target_area: StringName,
	target_slot: int
)

const VALID_TARGET_MODULATE: Color = Color(0.72, 1.0, 0.84, 1.0)
const PREVIEW_SIZE: Vector2 = Vector2(300.0, 76.0)
const POINTER_DRAG_THRESHOLD: float = 8.0

var _drag_payload: EquipmentDragPayload
var _drag_source_enabled: bool = false
var _target_origin: int = -1
var _target_area: StringName = &""
var _target_slot: int = -1
var _drop_target_enabled: bool = false
var _active_drag_payload: EquipmentDragPayload
var _pointer_drag_armed: bool = false
var _pointer_drag_origin: Vector2 = Vector2.ZERO
var _pointer_drag_index: int = -1


func configure_drag_source(
	payload: EquipmentDragPayload,
	is_enabled: bool
) -> void:
	_drag_payload = payload
	_drag_source_enabled = is_enabled and payload != null and payload.is_valid()
	if not _drag_source_enabled:
		_clear_pointer_drag_candidate()


func configure_drop_target(
	origin: EquipmentDragPayload.Origin,
	area: StringName,
	slot_index: int,
	is_enabled: bool
) -> void:
	_target_origin = origin
	_target_area = area
	_target_slot = slot_index
	_drop_target_enabled = is_enabled and area != &"" and slot_index >= 0
	if not _drop_target_enabled:
		self_modulate = Color.WHITE


func get_configured_drag_payload() -> EquipmentDragPayload:
	return _drag_payload


func is_drag_source_enabled() -> bool:
	return _drag_source_enabled


func is_drop_target_enabled() -> bool:
	return _drop_target_enabled


func accepts_drag_payload(data: Variant) -> bool:
	var payload: EquipmentDragPayload = data as EquipmentDragPayload
	if (
		not _drop_target_enabled
		or payload == null
		or not payload.is_valid()
		or int(payload.origin) != _target_origin
	):
		return false
	if payload.origin == EquipmentDragPayload.Origin.INVENTORY:
		return payload.source_area != _target_area
	return (
		payload.origin == EquipmentDragPayload.Origin.REWARD
		and _target_area != &""
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed and _can_begin_pointer_drag():
			_pointer_drag_armed = true
			_pointer_drag_origin = mouse_button.position
			_pointer_drag_index = -1
		elif not mouse_button.pressed:
			_clear_pointer_drag_candidate()
		return
	if event is InputEventMouseMotion:
		var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
		if not _pointer_drag_armed:
			return
		if (
			not _can_begin_pointer_drag()
			or (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0
		):
			_clear_pointer_drag_candidate()
			return
		if mouse_motion.position.distance_to(_pointer_drag_origin) >= POINTER_DRAG_THRESHOLD:
			_force_pointer_drag()
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and not _pointer_drag_armed and _can_begin_pointer_drag():
			_pointer_drag_armed = true
			_pointer_drag_origin = touch.position
			_pointer_drag_index = touch.index
		elif not touch.pressed and touch.index == _pointer_drag_index:
			_clear_pointer_drag_candidate()
		return
	if event is InputEventScreenDrag:
		var touch_drag: InputEventScreenDrag = event as InputEventScreenDrag
		if (
			_pointer_drag_armed
			and touch_drag.index == _pointer_drag_index
			and _can_begin_pointer_drag()
			and touch_drag.position.distance_to(_pointer_drag_origin) >= POINTER_DRAG_THRESHOLD
		):
			_force_pointer_drag()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if (
		not _drag_source_enabled
		or _drag_payload == null
		or not _drag_payload.is_valid()
	):
		return null
	_clear_pointer_drag_candidate()
	_active_drag_payload = _drag_payload
	set_drag_preview(_make_drag_preview(_drag_payload))
	get_viewport().gui_set_drag_description(
		"Move %s to an equipment destination" % _drag_payload.display_name
	)
	equipment_drag_started.emit(_drag_payload)
	return _drag_payload


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return accepts_drag_payload(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var payload: EquipmentDragPayload = data as EquipmentDragPayload
	if payload == null or not accepts_drag_payload(payload):
		return
	equipment_drop_requested.emit(payload, _target_area, _target_slot)


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_DRAG_BEGIN:
		var drag_data: Variant = get_viewport().gui_get_drag_data()
		self_modulate = (
			VALID_TARGET_MODULATE
			if accepts_drag_payload(drag_data)
			else Color.WHITE
		)
	elif what == NOTIFICATION_DRAG_END:
		_clear_pointer_drag_candidate()
		self_modulate = Color.WHITE
		if _active_drag_payload != null:
			var completed_payload: EquipmentDragPayload = _active_drag_payload
			_active_drag_payload = null
			equipment_drag_ended.emit(
				completed_payload,
				get_viewport().gui_is_drag_successful()
			)


func _can_begin_pointer_drag() -> bool:
	return (
		_drag_source_enabled
		and _drag_payload != null
		and _drag_payload.is_valid()
		and not get_viewport().gui_is_dragging()
	)


func _force_pointer_drag() -> void:
	if not _can_begin_pointer_drag():
		_clear_pointer_drag_candidate()
		return
	var payload: EquipmentDragPayload = _drag_payload
	_clear_pointer_drag_candidate()
	_active_drag_payload = payload
	equipment_drag_started.emit(payload)
	force_drag(payload, _make_drag_preview(payload))
	get_viewport().gui_set_drag_description(
		"Move %s to an equipment destination" % payload.display_name
	)
	accept_event()


func _clear_pointer_drag_candidate() -> void:
	_pointer_drag_armed = false
	_pointer_drag_origin = Vector2.ZERO
	_pointer_drag_index = -1


func _make_drag_preview(payload: EquipmentDragPayload) -> Control:
	var preview: PanelContainer = PanelContainer.new()
	preview.custom_minimum_size = PREVIEW_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1.0, 1.0, 1.0, 0.94)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(row)
	if payload.icon != null:
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(64.0, 64.0)
		icon_rect.texture = payload.icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)
	var label: Label = Label.new()
	label.text = "%s\nDROP TO STAGE • CONFIRM TO APPLY" % payload.display_name.to_upper()
	label.add_theme_font_size_override("font_size", 16)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return preview
