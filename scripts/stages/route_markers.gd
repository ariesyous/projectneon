class_name RouteMarkers
extends Node2D

## Visualizes fixed route nodes and read-only pending/resolved card markers.
## PatrolController remains the route authority.

const ROUTE_COLOR: Color = Color("ffcc5c")
const PENDING_COLOR: Color = Color("65e6c4")
const RESOLVED_COLOR: Color = Color("a987ff")

@onready var route_label: Label = $RouteLabel

var _route_snapshot: Dictionary = {}


func _ready() -> void:
	queue_redraw()


func present_route_snapshot(snapshot: Dictionary) -> void:
	_route_snapshot = snapshot.duplicate(true)
	if is_node_ready():
		var pending_count: int = _array_count(snapshot.get("pending_route_modifications", []))
		var resolved_count: int = _array_count(snapshot.get("resolved_route_modifications", []))
		route_label.text = "ROUTE  CARD P%d / R%d" % [pending_count, resolved_count]
	queue_redraw()


func _draw() -> void:
	var marker_points: PackedVector2Array = PackedVector2Array()
	for child: Node in get_children():
		if child is Marker2D:
			marker_points.append((child as Marker2D).position)

	if marker_points.size() > 1:
		draw_polyline(marker_points, Color(ROUTE_COLOR, 0.7), 1.0, false)

	for index: int in range(marker_points.size()):
		var marker_color: Color = _marker_color(index)
		draw_circle(marker_points[index], 5.0, Color("0b1022"), true, -1.0, false)
		draw_circle(marker_points[index], 4.0, marker_color, false, 1.0, false)
		if _route_index_has_record(index, "pending_route_modifications"):
			draw_line(
				marker_points[index] + Vector2(-3.0, -7.0),
				marker_points[index] + Vector2(3.0, -7.0),
				PENDING_COLOR,
				2.0
			)
		if _route_index_has_record(index, "resolved_route_modifications"):
			draw_line(
				marker_points[index] + Vector2(-3.0, 7.0),
				marker_points[index] + Vector2(3.0, 7.0),
				RESOLVED_COLOR,
				2.0
			)


func _marker_color(route_node_index: int) -> Color:
	if route_node_index == int(_route_snapshot.get("route_index", -1)):
		return ROUTE_COLOR
	if _route_index_has_record(route_node_index, "pending_route_modifications"):
		return PENDING_COLOR
	if _route_index_has_record(route_node_index, "resolved_route_modifications"):
		return RESOLVED_COLOR
	return Color("805f45")


func _route_index_has_record(route_node_index: int, key: String) -> bool:
	var value: Variant = _route_snapshot.get(key, [])
	if not (value is Array):
		return false
	for record_value: Variant in value as Array:
		if record_value is Dictionary and int(record_value.get("route_index", -1)) == route_node_index:
			return true
	return false


func _array_count(value: Variant) -> int:
	return (value as Array).size() if value is Array else 0
