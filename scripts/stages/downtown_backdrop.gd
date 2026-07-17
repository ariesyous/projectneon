class_name DowntownBackdrop
extends Node2D

## Draws replaceable Milestone 0 placeholder art for the nighttime street.

const CANVAS_SIZE: Vector2 = Vector2(640.0, 360.0)
const SKY_COLOR: Color = Color("050817")
const ROAD_COLOR: Color = Color("0a1020")
const CYAN: Color = Color("34e8ff")
const MAGENTA: Color = Color("ff3bc8")
const VIOLET: Color = Color("7857ff")
const AMBER: Color = Color("ffb84a")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Night sky and distant glow.
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), SKY_COLOR)
	draw_rect(Rect2(0.0, 76.0, 640.0, 124.0), Color("0b1030"))
	draw_circle(Vector2(548.0, 42.0), 19.0, Color("a9b8ff"))
	draw_circle(Vector2(556.0, 36.0), 19.0, SKY_COLOR)

	# Blocky skyline and lit windows.
	draw_rect(Rect2(0.0, 70.0, 130.0, 132.0), Color("11162f"))
	draw_rect(Rect2(132.0, 45.0, 98.0, 157.0), Color("151936"))
	draw_rect(Rect2(232.0, 86.0, 118.0, 116.0), Color("10152e"))
	draw_rect(Rect2(352.0, 54.0, 126.0, 148.0), Color("171733"))
	draw_rect(Rect2(480.0, 78.0, 160.0, 124.0), Color("10162d"))
	_draw_windows()

	# Storefronts: arcade, convenience store, alley, and subway entrance.
	draw_rect(Rect2(25.0, 119.0, 132.0, 82.0), Color("17152c"))
	draw_rect(Rect2(35.0, 128.0, 112.0, 16.0), Color("32134a"))
	draw_rect(Rect2(39.0, 131.0, 104.0, 2.0), MAGENTA)
	draw_rect(Rect2(67.0, 151.0, 46.0, 50.0), Color("0b1630"))
	draw_rect(Rect2(73.0, 159.0, 34.0, 23.0), Color("162f55"))

	draw_rect(Rect2(169.0, 129.0, 154.0, 72.0), Color("122338"))
	draw_rect(Rect2(177.0, 138.0, 138.0, 14.0), Color("113f4b"))
	draw_rect(Rect2(182.0, 141.0, 128.0, 2.0), CYAN)
	draw_rect(Rect2(188.0, 158.0, 52.0, 43.0), Color("17344a"))
	draw_rect(Rect2(248.0, 158.0, 56.0, 43.0), Color("0c1b30"))

	draw_rect(Rect2(336.0, 113.0, 65.0, 88.0), Color("080b17"))
	draw_rect(Rect2(342.0, 119.0, 5.0, 82.0), Color("3b225c"))
	draw_rect(Rect2(390.0, 119.0, 5.0, 82.0), Color("3b225c"))

	draw_rect(Rect2(414.0, 124.0, 184.0, 77.0), Color("18152f"))
	draw_rect(Rect2(425.0, 133.0, 91.0, 13.0), Color("46254f"))
	draw_rect(Rect2(430.0, 136.0, 81.0, 2.0), AMBER)
	draw_rect(Rect2(527.0, 147.0, 57.0, 54.0), Color("0a1830"))

	# Pavement, curb, road, lane-depth guides, and wet neon reflections.
	draw_rect(Rect2(0.0, 201.0, 640.0, 34.0), Color("18213a"))
	draw_rect(Rect2(0.0, 202.0, 640.0, 2.0), Color("506080"))
	draw_rect(Rect2(0.0, 232.0, 640.0, 128.0), ROAD_COLOR)
	draw_rect(Rect2(0.0, 233.0, 640.0, 2.0), Color("202d48"))
	draw_line(Vector2(0.0, 294.0), Vector2(640.0, 294.0), Color("111c32"), 2.0)
	_draw_reflection(82.0, 220.0, MAGENTA)
	_draw_reflection(216.0, 228.0, CYAN)
	_draw_reflection(458.0, 222.0, AMBER)
	_draw_reflection(557.0, 235.0, VIOLET)

	# Replaceable street props.
	draw_rect(Rect2(365.0, 188.0, 31.0, 18.0), Color("263247"))
	draw_rect(Rect2(368.0, 185.0, 25.0, 4.0), Color("49576c"))
	draw_rect(Rect2(583.0, 182.0, 6.0, 20.0), Color("ad355d"))
	draw_circle(Vector2(586.0, 181.0), 5.0, Color("ff557f"))


func _draw_windows() -> void:
	var window_positions: Array[Vector2] = [
		Vector2(18.0, 88.0), Vector2(48.0, 88.0), Vector2(83.0, 88.0),
		Vector2(151.0, 65.0), Vector2(183.0, 65.0), Vector2(151.0, 91.0),
		Vector2(260.0, 101.0), Vector2(296.0, 101.0), Vector2(374.0, 73.0),
		Vector2(410.0, 73.0), Vector2(446.0, 73.0), Vector2(502.0, 95.0),
		Vector2(538.0, 95.0), Vector2(574.0, 95.0)
	]
	for window_position: Vector2 in window_positions:
		var glow: Color = CYAN if int(window_position.x) % 2 == 0 else MAGENTA
		draw_rect(Rect2(window_position, Vector2(10.0, 5.0)), glow.darkened(0.35))


func _draw_reflection(x_position: float, top: float, color: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(x_position - 8.0, top),
			Vector2(x_position + 10.0, top),
			Vector2(x_position + 24.0, 345.0),
			Vector2(x_position - 20.0, 345.0)
		]),
		Color(color, 0.10)
	)
	draw_line(Vector2(x_position, top + 8.0), Vector2(x_position - 5.0, 328.0), Color(color, 0.24), 2.0)
