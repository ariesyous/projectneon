## Clickable presentation for one authoritative RewardDirector award.
## It forwards input and visualizes time remaining; it never changes coins.
class_name CoinCluster
extends Area2D

const FULL_CIRCLE_RADIANS: float = TAU

@onready var _countdown_label: Label = %CountdownLabel
@onready var _value_label: Label = %ValueLabel

var _cluster_id: int = -1
var _base_value: int = 0
var _expires_at_msec: int = -1
var _reward_director: RewardDirector
var _resolved: bool = false
var _hovered: bool = false


func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_refresh_labels()
	queue_redraw()


func _process(_delta: float) -> void:
	if _resolved or _reward_director == null:
		return
	_refresh_labels()
	queue_redraw()


func bind(
	cluster_id: int,
	base_value: int,
	expires_at_msec: int,
	reward_director: RewardDirector
) -> void:
	_disconnect_director()
	_cluster_id = cluster_id
	_base_value = maxi(0, base_value)
	_expires_at_msec = expires_at_msec
	_reward_director = reward_director
	_resolved = false
	input_pickable = true
	if _reward_director != null:
		_reward_director.cluster_resolved.connect(_on_cluster_resolved)
	if is_node_ready():
		_refresh_labels()
		queue_redraw()


func get_cluster_id() -> int:
	return _cluster_id


func request_manual_collection() -> bool:
	if _resolved or _reward_director == null:
		return false
	return _reward_director.request_manual_collection(_cluster_id)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if (
		mouse_event != null
		and mouse_event.button_index == MOUSE_BUTTON_LEFT
		and mouse_event.pressed
	):
		get_viewport().set_input_as_handled()
		request_manual_collection()


func _draw() -> void:
	var hover_scale: float = 1.08 if _hovered else 1.0
	draw_circle(Vector2.ZERO, 22.0 * hover_scale, Color(0.98, 0.69, 0.12, 0.18))
	draw_arc(Vector2.ZERO, 18.0 * hover_scale, 0.0, FULL_CIRCLE_RADIANS, 32, Color(1.0, 0.83, 0.25, 0.9), 2.0)
	draw_circle(Vector2(-7.0, 2.0), 7.0, Color("ffd43b"))
	draw_circle(Vector2(1.0, -3.0), 7.0, Color("ffed72"))
	draw_circle(Vector2(8.0, 3.0), 6.0, Color("e9a91d"))
	if not _resolved and _reward_director != null:
		var delay_msec: int = maxi(1, _expires_at_msec - _get_registered_at_msec())
		var remaining_msec: int = maxi(0, _expires_at_msec - _reward_director.get_current_time_msec())
		var progress: float = clampf(float(remaining_msec) / float(delay_msec), 0.0, 1.0)
		draw_arc(
			Vector2.ZERO,
			23.0 * hover_scale,
			-PI * 0.5,
			-PI * 0.5 + FULL_CIRCLE_RADIANS * progress,
			32,
			Color("74efff"),
			2.0
		)

func _refresh_labels() -> void:
	if _value_label == null or _countdown_label == null:
		return
	_value_label.text = "%d COINS" % _base_value
	if _reward_director == null or _expires_at_msec < 0:
		_countdown_label.text = "CLICK"
		return
	var remaining_msec: int = maxi(
		0,
		_expires_at_msec - _reward_director.get_current_time_msec()
	)
	_countdown_label.text = "%.1fs" % (float(remaining_msec) / 1000.0)


func _get_registered_at_msec() -> int:
	if _reward_director == null:
		return 0
	var auto_delay: int = maxi(1, _reward_director.tuning.auto_collect_delay_msec)
	return _expires_at_msec - auto_delay


func _on_cluster_resolved(
	resolved_cluster_id: int,
	manual: bool,
	base_value: int,
	bonus_value: int,
	_resulting_streak: int
) -> void:
	if _resolved or resolved_cluster_id != _cluster_id:
		return
	_resolved = true
	input_pickable = false
	if _countdown_label != null:
		_countdown_label.text = "CLICK!" if manual else "AUTO"
	if _value_label != null:
		_value_label.text = "+%d" % (base_value + bonus_value)
		if bonus_value > 0:
			_value_label.text += "  BONUS +%d" % bonus_value
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 8.0, 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(queue_free)


func _on_mouse_entered() -> void:
	if not _resolved:
		_hovered = true
		queue_redraw()


func _on_mouse_exited() -> void:
	if not _resolved:
		_hovered = false
		queue_redraw()


func _disconnect_director() -> void:
	if (
		_reward_director != null
		and is_instance_valid(_reward_director)
		and _reward_director.cluster_resolved.is_connected(_on_cluster_resolved)
	):
		_reward_director.cluster_resolved.disconnect(_on_cluster_resolved)
