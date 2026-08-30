class_name DowntownBackdrop
extends Node2D

## Authored fixed-block presentation for Downtown Loop. It derives a bounded
## visual profile from authoritative snapshots, redraws only when that context
## changes, and owns no route, encounter, combat, or random state.

signal presentation_context_changed(snapshot: Dictionary)

const CANVAS_SIZE: Vector2 = Vector2(640.0, 360.0)
const PROFILE_ALLEY: StringName = &"alley"
const PROFILE_ARCADE: StringName = &"arcade"
const PROFILE_CONVENIENCE: StringName = &"convenience_store"
const PROFILE_SUBWAY: StringName = &"subway_entrance"
const PROFILE_VIPER: StringName = &"viper"

const VOID: Color = Color("050712")
const FAR: Color = Color("0b1025")
const BRICK_DARK: Color = Color("0e1427")
const SIDEWALK: Color = Color("1a253c")
const CURB: Color = Color("53617a")
const ROAD: Color = Color("080d18")
const WET: Color = Color("243650")
const CYAN: Color = Color("43e6e8")
const MAGENTA: Color = Color("ff5c82")
const VIOLET: Color = Color("9b73ff")
const ACID: Color = Color("b8f35d")
const AMBER: Color = Color("ffc45c")
const CRITICAL: Color = Color("ff415f")
const BOSS: Color = Color("c75bff")

var _profile_id: StringName = PROFILE_ALLEY
var _lap_index: int = 1
var _block_index: int = 1
var _phase_name: StringName = &"INITIALIZING"
var _boss_active: bool = false
var _context_revision: int = 0


func _ready() -> void:
	queue_redraw()


func present_world_snapshot(snapshot: Dictionary) -> void:
	var run: Dictionary = snapshot.get("run", {})
	var encounter: Dictionary = snapshot.get("encounter", {})
	var cards: Dictionary = snapshot.get("cards", {})
	var environment: Dictionary = snapshot.get("environment", {})
	var district: Dictionary = run.get("district_loop", {})
	var next_profile: StringName = _profile_from_context(
		int(run.get("state", -1)),
		StringName(encounter.get("active_encounter_id", &"none")),
		cards,
		StringName(environment.get("action_id", &""))
	)
	var next_lap: int = clampi(int(district.get("lap_index", 1)), 1, 3)
	var next_block: int = clampi(int(district.get("block_index", 1)), 1, 3)
	var next_phase: StringName = StringName(run.get("state_name", "INITIALIZING"))
	var next_boss_active: bool = bool(encounter.get("boss_active", false)) or next_phase in [
		&"BOSS_INTRO",
		&"BOSS_ACTIVE",
		&"VICTORY",
	]
	if (
		next_profile == _profile_id
		and next_lap == _lap_index
		and next_block == _block_index
		and next_phase == _phase_name
		and next_boss_active == _boss_active
	):
		return
	_profile_id = next_profile
	_lap_index = next_lap
	_block_index = next_block
	_phase_name = next_phase
	_boss_active = next_boss_active
	_context_revision += 1
	queue_redraw()
	presentation_context_changed.emit(get_presentation_snapshot())


func reset_presentation() -> void:
	_profile_id = PROFILE_ALLEY
	_lap_index = 1
	_block_index = 1
	_phase_name = &"INITIALIZING"
	_boss_active = false
	_context_revision += 1
	queue_redraw()
	presentation_context_changed.emit(get_presentation_snapshot())


func get_presentation_snapshot() -> Dictionary:
	return {
		"profile_id": _profile_id,
		"lap_index": _lap_index,
		"block_index": _block_index,
		"phase_name": _phase_name,
		"boss_active": _boss_active,
		"context_revision": _context_revision,
		"static_redraw_only": true,
	}


func _profile_from_context(
	state: int,
	encounter_id: StringName,
	cards: Dictionary,
	environment_action_id: StringName
) -> StringName:
	if state in [
		RunDirector.RunState.BOSS_INTRO,
		RunDirector.RunState.BOSS_ACTIVE,
		RunDirector.RunState.VICTORY,
		RunDirector.RunState.DEFEAT,
	] or encounter_id == &"viper_showdown":
		return PROFILE_VIPER
	match encounter_id:
		&"viper_signal":
			return PROFILE_VIPER
		&"arcade_ambush":
			return PROFILE_ARCADE
		&"alley_scuffle":
			return PROFILE_ALLEY
	if state == RunDirector.RunState.SHOP:
		return PROFILE_CONVENIENCE
	var card_id: StringName = _visible_card_context(cards)
	match card_id:
		&"arcade":
			return PROFILE_ARCADE
		&"convenience_store":
			return PROFILE_CONVENIENCE
		&"subway_entrance":
			return PROFILE_SUBWAY
		&"gang_hideout":
			return PROFILE_VIPER
	if environment_action_id == &"power_box":
		return PROFILE_ARCADE
	return _profile_id if _profile_id != &"" else PROFILE_ALLEY


func _visible_card_context(cards: Dictionary) -> StringName:
	for key: String in ["active_block", "selected_next_block"]:
		var record: Dictionary = cards.get(key, {})
		var card_id: StringName = StringName(record.get("card_id", &""))
		if card_id != &"":
			return card_id
	return &""


func _draw() -> void:
	_draw_skyline()
	_draw_main_facade()
	match _profile_id:
		PROFILE_ARCADE:
			_draw_arcade_profile()
		PROFILE_CONVENIENCE:
			_draw_convenience_profile()
		PROFILE_SUBWAY:
			_draw_subway_profile()
		PROFILE_VIPER:
			_draw_viper_profile()
		_:
			_draw_alley_profile()
	_draw_ground()
	_draw_profile_props()
	_draw_atmosphere_escalation()
	_draw_phase_treatment()


func _draw_skyline() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), VOID)
	draw_rect(Rect2(0.0, 30.0, 640.0, 82.0), FAR)
	var skyline: Array[Rect2] = [
		Rect2(0.0, 46.0, 92.0, 69.0), Rect2(96.0, 24.0, 80.0, 91.0),
		Rect2(180.0, 56.0, 108.0, 59.0), Rect2(292.0, 35.0, 76.0, 80.0),
		Rect2(372.0, 18.0, 112.0, 97.0), Rect2(488.0, 50.0, 152.0, 65.0),
	]
	for index: int in range(skyline.size()):
		draw_rect(skyline[index], Color("10172c") if index % 2 == 0 else Color("121a31"))
	for row: int in range(2):
		for column: int in range(12):
			if (column + row * 3) % 4 == 0:
				continue
			var window_color: Color = CYAN if column % 3 == 0 else AMBER
			draw_rect(Rect2(18.0 + float(column) * 51.0, 52.0 + float(row) * 23.0, 8.0, 4.0), Color(window_color, 0.16))


func _draw_main_facade() -> void:
	draw_rect(Rect2(0.0, 108.0, 640.0, 91.0), BRICK_DARK)
	for row: int in range(7):
		var y_position: float = 112.0 + float(row) * 13.0
		draw_line(Vector2(0.0, y_position), Vector2(640.0, y_position), Color("1a2440"), 1.0)
		var offset: float = 11.0 if row % 2 == 0 else 0.0
		for column: int in range(30):
			var x_position: float = offset + float(column) * 22.0
			draw_line(Vector2(x_position, y_position), Vector2(x_position, y_position + 13.0), Color("10182d"), 1.0)
	_draw_fire_escape(Vector2(504.0, 112.0))


func _draw_alley_profile() -> void:
	_draw_storefront(Rect2(20.0, 128.0, 138.0, 71.0), MAGENTA, "LATE SHIFT")
	_draw_rollup_door(Rect2(192.0, 122.0, 166.0, 77.0), CYAN)
	draw_rect(Rect2(382.0, 114.0, 72.0, 85.0), Color("070b14"))
	draw_rect(Rect2(388.0, 120.0, 5.0, 79.0), Color("283653"))
	draw_rect(Rect2(443.0, 120.0, 5.0, 79.0), Color("283653"))
	_draw_service_door(Rect2(534.0, 130.0, 70.0, 69.0), AMBER)


func _draw_arcade_profile() -> void:
	_draw_storefront(Rect2(16.0, 119.0, 226.0, 80.0), MAGENTA, "ARCADE")
	for cabinet: int in range(4):
		var x_position: float = 32.0 + float(cabinet) * 49.0
		draw_rect(Rect2(x_position, 154.0, 30.0, 40.0), Color("101a34"))
		draw_rect(Rect2(x_position + 4.0, 158.0, 22.0, 14.0), Color(CYAN, 0.22))
		draw_circle(Vector2(x_position + 10.0, 181.0), 2.0, MAGENTA)
		draw_circle(Vector2(x_position + 19.0, 181.0), 2.0, AMBER)
	_draw_service_door(Rect2(266.0, 126.0, 92.0, 73.0), CYAN)
	_draw_rollup_door(Rect2(386.0, 119.0, 218.0, 80.0), AMBER)
	_draw_conduit(Vector2(462.0, 126.0), Vector2(558.0, 166.0), AMBER)


func _draw_convenience_profile() -> void:
	_draw_storefront(Rect2(18.0, 120.0, 398.0, 79.0), CYAN, "OPEN 24")
	draw_rect(Rect2(28.0, 145.0, 378.0, 8.0), Color(AMBER, 0.42))
	for pane: int in range(5):
		var x_position: float = 34.0 + float(pane) * 73.0
		draw_rect(Rect2(x_position, 157.0, 58.0, 37.0), Color("10263a"))
		draw_rect(Rect2(x_position + 4.0, 161.0, 50.0, 2.0), Color(CYAN, 0.38))
	_draw_service_door(Rect2(438.0, 125.0, 72.0, 74.0), AMBER)
	draw_rect(Rect2(526.0, 145.0, 78.0, 54.0), Color("0a1326"))


func _draw_subway_profile() -> void:
	_draw_storefront(Rect2(20.0, 130.0, 172.0, 69.0), VIOLET, "DOWNTOWN")
	_draw_rollup_door(Rect2(212.0, 122.0, 142.0, 77.0), CYAN)
	draw_rect(Rect2(392.0, 124.0, 212.0, 75.0), Color("0a1427"))
	draw_rect(Rect2(416.0, 140.0, 156.0, 59.0), Color("07101f"))
	draw_colored_polygon(PackedVector2Array([Vector2(432.0, 145.0), Vector2(556.0, 145.0), Vector2(534.0, 199.0), Vector2(454.0, 199.0)]), Color("102640"))
	for step: int in range(5):
		draw_line(Vector2(447.0 + float(step) * 3.0, 157.0 + float(step) * 8.0), Vector2(541.0 - float(step) * 3.0, 157.0 + float(step) * 8.0), Color("52627d"), 1.0)
	_draw_sign(Rect2(435.0, 126.0, 118.0, 13.0), CYAN, "SUBWAY")


func _draw_viper_profile() -> void:
	_draw_service_door(Rect2(18.0, 132.0, 74.0, 67.0), CRITICAL)
	_draw_rollup_door(Rect2(112.0, 114.0, 280.0, 85.0), BOSS)
	_draw_viper_chevrons(Rect2(152.0, 121.0, 199.0, 19.0))
	_draw_service_door(Rect2(416.0, 128.0, 75.0, 71.0), CRITICAL)
	_draw_rollup_door(Rect2(510.0, 124.0, 112.0, 75.0), ACID)
	for barrier: int in range(3):
		var x_position: float = 42.0 + float(barrier) * 254.0
		draw_rect(Rect2(x_position, 184.0, 84.0, 9.0), Color("323a46"))
		for stripe: int in range(5):
			draw_line(Vector2(x_position + float(stripe) * 18.0, 185.0), Vector2(x_position + 10.0 + float(stripe) * 18.0, 192.0), AMBER, 3.0)


func _draw_ground() -> void:
	draw_rect(Rect2(0.0, 199.0, 640.0, 34.0), SIDEWALK)
	draw_rect(Rect2(0.0, 199.0, 640.0, 2.0), Color("71809a"))
	for seam: int in range(17):
		var x_position: float = float(seam) * 40.0 + (20.0 if seam % 2 == 0 else 0.0)
		draw_line(Vector2(x_position, 201.0), Vector2(x_position - 5.0, 231.0), Color("111a2d"), 1.0)
	draw_rect(Rect2(0.0, 232.0, 640.0, 7.0), CURB)
	draw_rect(Rect2(0.0, 239.0, 640.0, 121.0), ROAD)
	draw_rect(Rect2(0.0, 240.0, 640.0, 2.0), WET)
	draw_line(Vector2(0.0, 304.0), Vector2(640.0, 304.0), Color("101a2c"), 2.0)
	for drain_x: float in [116.0, 508.0]:
		draw_rect(Rect2(drain_x, 326.0, 40.0, 8.0), Color("050812"))
		for grate: int in range(5):
			draw_line(Vector2(drain_x + 5.0 + float(grate) * 7.0, 327.0), Vector2(drain_x + 2.0 + float(grate) * 7.0, 333.0), Color("263651"), 1.0)
	_draw_reflection(76.0, 236.0, MAGENTA, 0.11)
	_draw_reflection(218.0, 240.0, CYAN, 0.10)
	_draw_reflection(458.0, 236.0, _profile_accent(), 0.12)
	_draw_reflection(570.0, 244.0, VIOLET, 0.08)


func _draw_profile_props() -> void:
	match _profile_id:
		PROFILE_ALLEY:
			_draw_dumpster(Vector2(367.0, 184.0))
			_draw_bollard(Vector2(574.0, 193.0), AMBER)
		PROFILE_ARCADE:
			_draw_bollard(Vector2(254.0, 193.0), MAGENTA)
			_draw_bollard(Vector2(612.0, 193.0), AMBER)
		PROFILE_CONVENIENCE:
			_draw_bollard(Vector2(424.0, 193.0), CYAN)
			draw_rect(Rect2(546.0, 184.0, 50.0, 15.0), Color("29374e"))
		PROFILE_SUBWAY:
			_draw_bollard(Vector2(380.0, 193.0), AMBER)
			draw_line(Vector2(423.0, 146.0), Vector2(454.0, 199.0), Color("71809a"), 3.0)
			draw_line(Vector2(565.0, 146.0), Vector2(534.0, 199.0), Color("71809a"), 3.0)
		PROFILE_VIPER:
			_draw_bollard(Vector2(101.0, 193.0), CRITICAL)
			_draw_bollard(Vector2(500.0, 193.0), CRITICAL)


func _draw_atmosphere_escalation() -> void:
	if _lap_index >= 2:
		draw_rect(Rect2(0.0, 84.0, 640.0, 276.0), Color(VIOLET, 0.025 * float(_lap_index)))
		for rain_index: int in range(18):
			var x_position: float = float((rain_index * 47 + 19) % 640)
			var y_position: float = 88.0 + float((rain_index * 31) % 242)
			draw_line(Vector2(x_position, y_position), Vector2(x_position - 4.0, y_position + 13.0), Color("8fb2d8", 0.12 if _lap_index == 2 else 0.18), 1.0)
	if _lap_index >= 3 or _boss_active:
		for light_x: float in [26.0, 611.0]:
			draw_circle(Vector2(light_x, 188.0), 10.0, Color(CRITICAL, 0.12))
			draw_rect(Rect2(light_x - 3.0, 183.0, 6.0, 6.0), CRITICAL)
		draw_rect(Rect2(0.0, 108.0, 640.0, 91.0), Color(CRITICAL, 0.025))


func _draw_phase_treatment() -> void:
	if _phase_name in [&"PAUSED", &"REWARD_SELECTION", &"SHOP"]:
		draw_rect(Rect2(0.0, 108.0, 640.0, 252.0), Color(VOID, 0.10))
	if _phase_name in [&"BOSS_INTRO", &"BOSS_ACTIVE"]:
		draw_rect(Rect2(0.0, 0.0, 640.0, 108.0), Color(VOID, 0.18))


func _draw_storefront(rect: Rect2, accent: Color, sign_text: String) -> void:
	draw_rect(rect, Color("111a30"))
	draw_rect(Rect2(rect.position + Vector2(5.0, 25.0), rect.size - Vector2(10.0, 30.0)), Color("0b172c"))
	draw_rect(Rect2(rect.position + Vector2(9.0, 30.0), rect.size - Vector2(18.0, 40.0)), Color(accent, 0.10))
	_draw_sign(Rect2(rect.position + Vector2(8.0, 6.0), Vector2(rect.size.x - 16.0, 15.0)), accent, sign_text)
	for mullion: int in range(1, 4):
		var x_position: float = rect.position.x + rect.size.x * float(mullion) / 4.0
		draw_line(Vector2(x_position, rect.position.y + 27.0), Vector2(x_position, rect.end.y), Color("263651"), 2.0)


func _draw_rollup_door(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color("0b1223"))
	draw_rect(rect, Color(accent, 0.22), false, 2.0)
	for slat: int in range(8):
		var y_position: float = rect.position.y + 8.0 + float(slat) * 8.0
		draw_line(Vector2(rect.position.x + 4.0, y_position), Vector2(rect.end.x - 4.0, y_position), Color("263651"), 1.0)


func _draw_service_door(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color("0a1222"))
	draw_rect(rect, Color(accent, 0.38), false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(8.0, 9.0), rect.size - Vector2(16.0, 19.0)), Color("111a2d"), false, 1.0)
	draw_circle(Vector2(rect.end.x - 12.0, rect.position.y + rect.size.y * 0.56), 2.0, accent)


func _draw_sign(rect: Rect2, accent: Color, text: String) -> void:
	draw_rect(rect, Color("0b1020"))
	draw_rect(rect, Color(accent, 0.72), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 10.0), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 10.0, 7, Color(accent, 0.88))


func _draw_fire_escape(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(108.0, 0.0), Color("263651"), 3.0)
	draw_line(origin + Vector2(12.0, 0.0), origin + Vector2(12.0, 63.0), Color("263651"), 2.0)
	draw_line(origin + Vector2(94.0, 0.0), origin + Vector2(94.0, 63.0), Color("263651"), 2.0)
	for rung: int in range(5):
		var y_position: float = 11.0 + float(rung) * 11.0
		draw_line(origin + Vector2(12.0, y_position), origin + Vector2(94.0, y_position), Color("1e2b46"), 1.0)


func _draw_conduit(start: Vector2, end: Vector2, accent: Color) -> void:
	var bend: Vector2 = Vector2(end.x, start.y)
	draw_line(start, bend, Color("35425b"), 3.0)
	draw_line(bend, end, Color("35425b"), 3.0)
	draw_circle(start, 3.0, Color(accent, 0.65))
	draw_circle(end, 3.0, Color(accent, 0.65))


func _draw_viper_chevrons(rect: Rect2) -> void:
	draw_rect(rect, Color("0a1020"))
	for chevron: int in range(6):
		var x_position: float = rect.position.x + 8.0 + float(chevron) * 31.0
		draw_line(Vector2(x_position, rect.position.y + 4.0), Vector2(x_position + 10.0, rect.position.y + 9.5), Color(ACID, 0.58), 3.0)
		draw_line(Vector2(x_position + 10.0, rect.position.y + 9.5), Vector2(x_position, rect.position.y + 15.0), Color(ACID, 0.58), 3.0)


func _draw_dumpster(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(38.0, 17.0)), Color("27364b"))
	draw_rect(Rect2(origin + Vector2(3.0, -4.0), Vector2(32.0, 5.0)), Color("41536b"))
	draw_line(origin + Vector2(10.0, 3.0), origin + Vector2(10.0, 15.0), Color("18243a"), 2.0)
	draw_line(origin + Vector2(27.0, 3.0), origin + Vector2(27.0, 15.0), Color("18243a"), 2.0)


func _draw_bollard(origin: Vector2, accent: Color) -> void:
	draw_rect(Rect2(origin - Vector2(3.0, 14.0), Vector2(6.0, 14.0)), Color("263651"))
	draw_rect(Rect2(origin - Vector2(5.0, 2.0), Vector2(10.0, 3.0)), Color("111827"))
	draw_circle(origin - Vector2(0.0, 14.0), 3.0, Color(accent, 0.72))


func _draw_reflection(x_position: float, top: float, color: Color, alpha: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x_position - 10.0, top), Vector2(x_position + 12.0, top), Vector2(x_position + 24.0, 349.0), Vector2(x_position - 21.0, 349.0)]), Color(color, alpha * 0.46))
	for segment: int in range(5):
		var y_position: float = top + 15.0 + float(segment) * 21.0
		var half_width: float = 5.0 + float((segment * 7) % 13)
		draw_line(Vector2(x_position - half_width, y_position), Vector2(x_position + half_width, y_position), Color(color, alpha), 1.0)


func _profile_accent() -> Color:
	match _profile_id:
		PROFILE_ARCADE:
			return MAGENTA
		PROFILE_CONVENIENCE:
			return CYAN
		PROFILE_SUBWAY:
			return AMBER
		PROFILE_VIPER:
			return BOSS
	return CYAN
