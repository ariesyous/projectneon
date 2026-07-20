@tool
class_name DistrictCardDragSlot
extends Button

## Card-specific native drag source and route-slot target. It mirrors the
## verified equipment pointer/touch fallback while keeping all mutation out of
## presentation code.

signal district_card_drag_started(payload: DistrictCardDragPayload)
signal district_card_drag_ended(payload: DistrictCardDragPayload, successful: bool)
signal district_card_drop_requested(
	payload: DistrictCardDragPayload,
	target_slot_id: StringName
)

const VALID_TARGET_MODULATE: Color = Color(0.70, 1.0, 0.84, 1.0)
const INVALID_TARGET_MODULATE: Color = Color(1.0, 0.82, 0.82, 1.0)
const PREVIEW_SIZE: Vector2 = Vector2(360.0, 128.0)
const POINTER_DRAG_THRESHOLD: float = 8.0

var _drag_payload: DistrictCardDragPayload
var _drag_source_enabled: bool = false
var _target_slot_id: StringName = &""
var _target_hand_revision: int = -1
var _target_route_revision: int = -1
var _drop_target_enabled: bool = false
var _drop_target_valid: bool = false
var _active_drag_payload: DistrictCardDragPayload
var _pointer_drag_armed: bool = false
var _pointer_drag_origin: Vector2 = Vector2.ZERO
var _pointer_drag_index: int = -1


func configure_drag_source(
	payload: DistrictCardDragPayload,
	is_enabled: bool
) -> void:
	_drag_payload = payload
	_drag_source_enabled = is_enabled and payload != null and payload.is_valid()
	if not _drag_source_enabled:
		_clear_pointer_drag_candidate()


func configure_route_drop_target(
	slot_id: StringName,
	hand_revision: int,
	route_revision: int,
	is_valid_target: bool,
	is_enabled: bool = true
) -> void:
	_target_slot_id = slot_id
	_target_hand_revision = hand_revision
	_target_route_revision = route_revision
	_drop_target_enabled = is_enabled and slot_id != &""
	_drop_target_valid = _drop_target_enabled and is_valid_target
	if not _drop_target_valid:
		self_modulate = Color.WHITE


func get_configured_drag_payload() -> DistrictCardDragPayload:
	return _drag_payload


func get_target_slot_id() -> StringName:
	return _target_slot_id


func is_drag_source_enabled() -> bool:
	return _drag_source_enabled


func is_drop_target_enabled() -> bool:
	return _drop_target_enabled


func is_valid_drop_target() -> bool:
	return _drop_target_valid


func accepts_drag_payload(data: Variant) -> bool:
	var payload: DistrictCardDragPayload = data as DistrictCardDragPayload
	return (
		_drop_target_enabled
		and _drop_target_valid
		and payload != null
		and payload.is_valid()
		and payload.origin == DistrictCardDragPayload.Origin.HAND
		and payload.hand_revision == _target_hand_revision
		and payload.route_revision == _target_route_revision
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
		"Place district card %s on a valid future route slot"
		% _drag_payload.display_name
	)
	district_card_drag_started.emit(_drag_payload)
	return _drag_payload


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return accepts_drag_payload(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var payload: DistrictCardDragPayload = data as DistrictCardDragPayload
	if payload == null or not accepts_drag_payload(payload):
		return
	district_card_drop_requested.emit(payload, _target_slot_id)


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_DRAG_BEGIN:
		var drag_data: Variant = get_viewport().gui_get_drag_data()
		if accepts_drag_payload(drag_data):
			self_modulate = VALID_TARGET_MODULATE
		elif _drop_target_enabled:
			self_modulate = INVALID_TARGET_MODULATE
		else:
			self_modulate = Color.WHITE
	elif what == NOTIFICATION_DRAG_END:
		_clear_pointer_drag_candidate()
		self_modulate = Color.WHITE
		if _active_drag_payload != null:
			var completed_payload: DistrictCardDragPayload = _active_drag_payload
			_active_drag_payload = null
			district_card_drag_ended.emit(
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
	var payload: DistrictCardDragPayload = _drag_payload
	_clear_pointer_drag_candidate()
	_active_drag_payload = payload
	district_card_drag_started.emit(payload)
	force_drag(payload, _make_drag_preview(payload))
	get_viewport().gui_set_drag_description(
		"Place district card %s on a valid future route slot" % payload.display_name
	)
	accept_event()


func _clear_pointer_drag_candidate() -> void:
	_pointer_drag_armed = false
	_pointer_drag_origin = Vector2.ZERO
	_pointer_drag_index = -1


func _make_drag_preview(payload: DistrictCardDragPayload) -> Control:
	var preview: PanelContainer = PanelContainer.new()
	preview.custom_minimum_size = PREVIEW_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1.0, 1.0, 1.0, 0.96)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(row)
	if payload.icon != null:
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(96.0, 96.0)
		icon_rect.texture = payload.icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)
	var heat_text: String = "%+d HEAT" % payload.heat_delta
	var label: Label = Label.new()
	label.text = "%s\nFREE  •  %s\n%s\nDROP TO STAGE • CONFIRM TO PLAY" % [
		payload.display_name.to_upper(),
		heat_text,
		payload.effect_summary.to_upper(),
	]
	label.add_theme_font_size_override("font_size", 16)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(244.0, 96.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return preview
