class_name RouteMarkers
extends Node2D

## Visualizes fixed placeholder route nodes without implementing patrol logic.

const ROUTE_COLOR: Color = Color("ffcc5c")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var marker_points: PackedVector2Array = PackedVector2Array()
	for child: Node in get_children():
		if child is Marker2D:
			marker_points.append((child as Marker2D).position)

	if marker_points.size() > 1:
		draw_polyline(marker_points, Color(ROUTE_COLOR, 0.7), 1.0, false)

	for index: int in range(marker_points.size()):
		var marker_color: Color = ROUTE_COLOR if index == 0 else Color("805f45")
		draw_circle(marker_points[index], 5.0, Color("0b1022"), true, -1.0, false)
		draw_circle(marker_points[index], 4.0, marker_color, false, 1.0, false)
