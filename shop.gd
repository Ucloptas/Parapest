extends Node2D

signal player_entered_shop
signal player_exited_shop

var is_player_nearby: bool = false
var interact_hint: Label = null

const PX: float = 2.0

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
	
	interact_hint = Label.new()
	interact_hint.text = "Press E to Shop"
	interact_hint.add_theme_font_size_override("font_size", 12)
	interact_hint.add_theme_color_override("font_color", Color(0.90, 0.85, 0.70))
	interact_hint.position = Vector2(-45, 10)
	interact_hint.visible = false
	add_child(interact_hint)
	
	var area = $ShopArea
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)


func _draw():
	var p := PX
	
	var frame := Color(0.18, 0.10, 0.05)
	var dark_wood := Color(0.28, 0.16, 0.07)
	var med_wood := Color(0.42, 0.26, 0.12)
	var light_wood := Color(0.55, 0.38, 0.18)
	var plank := Color(0.50, 0.33, 0.16)
	var tan_w := Color(0.65, 0.50, 0.28)
	var roof_dark := Color(0.35, 0.14, 0.07)
	var roof_mid := Color(0.45, 0.20, 0.09)
	var roof_light := Color(0.52, 0.26, 0.12)
	var roof_edge := Color(0.28, 0.10, 0.05)
	var sign_bg := Color(0.10, 0.25, 0.08)
	var sign_border := Color(0.16, 0.35, 0.12)
	var gold := Color(0.82, 0.65, 0.28)
	var window_glass := Color(0.50, 0.68, 0.58, 0.65)
	var window_light := Color(0.70, 0.82, 0.65, 0.3)
	var win_frame := Color(0.32, 0.20, 0.08)
	var shelf_col := Color(0.40, 0.26, 0.12)
	var jar_amber := Color(0.72, 0.55, 0.22)
	var jar_red := Color(0.62, 0.18, 0.12)
	var jar_green := Color(0.22, 0.48, 0.20)
	var box_brown := Color(0.48, 0.35, 0.22)
	var counter_top := Color(0.52, 0.36, 0.16)
	var counter_face := Color(0.38, 0.24, 0.10)
	var shadow := Color(0.08, 0.05, 0.03, 0.4)
	var awning1 := Color(0.52, 0.22, 0.10)
	var awning2 := Color(0.68, 0.38, 0.16)
	var lamp_glow := Color(0.85, 0.72, 0.35, 0.6)
	var wreath_green := Color(0.22, 0.48, 0.18)
	var wreath_red := Color(0.62, 0.18, 0.12)

	# Shop layout constants (in "pixel" units, multiply by PX for game coords)
	var sw := 80   # shop width in px units
	var wall_h := 38
	var roof_h := 14
	var counter_h := 8
	var sign_h := 8

	var half_w := sw / 2.0 * p
	var x0 := -half_w
	var x1 := half_w

	var gy := 0.0
	var ctr_top := gy - counter_h * p
	var wall_bot := ctr_top
	var wall_top := wall_bot - wall_h * p
	var roof_bot := wall_top
	var roof_top := roof_bot - roof_h * p
	var overhang := 6.0 * p

	# === SHADOW ===
	draw_rect(Rect2(x0 + 6 * p, gy - 2 * p, (sw - 12) * p, 4 * p), shadow)

	# === COUNTER ===
	draw_rect(Rect2(x0 + 2 * p, ctr_top, (sw - 4) * p, counter_h * p), counter_face)
	draw_rect(Rect2(x0 + 2 * p, ctr_top, (sw - 4) * p, 2 * p), counter_top)
	draw_rect(Rect2(x0 + 2 * p, gy - 2 * p, (sw - 4) * p, 2 * p), frame)
	# Counter panel lines
	var ci := 0
	while ci < 7:
		var cx := x0 + (5 + ci * 11) * p
		draw_rect(Rect2(cx, ctr_top + 2 * p, p, (counter_h - 4) * p), dark_wood)
		ci += 1

	# === MAIN WALL ===
	draw_rect(Rect2(x0, wall_top, sw * p, wall_h * p), med_wood)
	# Plank lines
	var pi_idx := 0
	while pi_idx < 5:
		var ly := wall_top + (6 + pi_idx * 7) * p
		draw_rect(Rect2(x0 + 3 * p, ly, (sw - 6) * p, p), dark_wood)
		pi_idx += 1
	# Frame borders
	draw_rect(Rect2(x0, wall_top, 3 * p, wall_h * p), frame)
	draw_rect(Rect2(x1 - 3 * p, wall_top, 3 * p, wall_h * p), frame)
	draw_rect(Rect2(x0, wall_top, sw * p, 2 * p), frame)
	draw_rect(Rect2(x0, wall_bot - 2 * p, sw * p, 2 * p), dark_wood)
	# Center beam
	draw_rect(Rect2(-1.5 * p, wall_top, 3 * p, wall_h * p), frame)

	# === LEFT WINDOW ===
	var lw_x := x0 + 7 * p
	var lw_y := wall_top + 5 * p
	var lw_w := 14 * p
	var lw_h := 11 * p
	draw_rect(Rect2(lw_x, lw_y, lw_w, lw_h), window_glass)
	draw_rect(Rect2(lw_x, lw_y, lw_w / 2.0, lw_h / 2.0), window_light)
	draw_rect(Rect2(lw_x, lw_y, lw_w, p), win_frame)
	draw_rect(Rect2(lw_x, lw_y + lw_h - p, lw_w, p), win_frame)
	draw_rect(Rect2(lw_x, lw_y, p, lw_h), win_frame)
	draw_rect(Rect2(lw_x + lw_w - p, lw_y, p, lw_h), win_frame)
	draw_rect(Rect2(lw_x + lw_w / 2.0 - p * 0.5, lw_y, p, lw_h), win_frame)
	draw_rect(Rect2(lw_x, lw_y + lw_h / 2.0 - p * 0.5, lw_w, p), win_frame)

	# === RIGHT WINDOW ===
	var rw_x := x1 - 21 * p
	draw_rect(Rect2(rw_x, lw_y, lw_w, lw_h), window_glass)
	draw_rect(Rect2(rw_x + lw_w / 2.0, lw_y, lw_w / 2.0, lw_h / 2.0), window_light)
	draw_rect(Rect2(rw_x, lw_y, lw_w, p), win_frame)
	draw_rect(Rect2(rw_x, lw_y + lw_h - p, lw_w, p), win_frame)
	draw_rect(Rect2(rw_x, lw_y, p, lw_h), win_frame)
	draw_rect(Rect2(rw_x + lw_w - p, lw_y, p, lw_h), win_frame)
	draw_rect(Rect2(rw_x + lw_w / 2.0 - p * 0.5, lw_y, p, lw_h), win_frame)
	draw_rect(Rect2(rw_x, lw_y + lw_h / 2.0 - p * 0.5, lw_w, p), win_frame)

	# === DOOR ===
	var door_w := 12.0 * p
	var door_h := 16.0 * p
	var door_x := -door_w / 2.0
	var door_y := wall_bot - door_h
	draw_rect(Rect2(door_x, door_y, door_w, door_h), dark_wood)
	draw_rect(Rect2(door_x + p, door_y + p, door_w - 2 * p, door_h - p), plank)
	draw_rect(Rect2(door_x, door_y, door_w, 2 * p), frame)
	draw_rect(Rect2(door_x, door_y, 2 * p, door_h), frame)
	draw_rect(Rect2(door_x + door_w - 2 * p, door_y, 2 * p, door_h), frame)
	# Door handle
	draw_rect(Rect2(door_x + door_w - 5 * p, door_y + door_h * 0.45, 2 * p, 2 * p), gold)
	# Door cross panels
	draw_rect(Rect2(door_x + door_w / 2.0 - p * 0.5, door_y + 2 * p, p, door_h - 2 * p), frame.lightened(0.15))

	# === SHELVES (left side, below left window) ===
	var sh_y1 := wall_top + 20 * p
	var sh_y2 := wall_top + 28 * p
	draw_rect(Rect2(x0 + 6 * p, sh_y1, 18 * p, 2 * p), shelf_col)
	draw_rect(Rect2(x0 + 6 * p, sh_y2, 18 * p, 2 * p), shelf_col)
	# Left shelf items
	_draw_jar(x0 + 8 * p, sh_y1 - 4 * p, jar_amber, p)
	_draw_jar(x0 + 14 * p, sh_y1 - 4 * p, jar_red, p)
	_draw_jar(x0 + 20 * p, sh_y1 - 4 * p, jar_green, p)
	_draw_box(x0 + 8 * p, sh_y2 - 3 * p, box_brown, p)
	_draw_jar(x0 + 14 * p, sh_y2 - 4 * p, jar_amber, p)
	_draw_jar(x0 + 20 * p, sh_y2 - 4 * p, jar_red, p)

	# === SHELVES (right side, below right window) ===
	draw_rect(Rect2(x1 - 24 * p, sh_y1, 18 * p, 2 * p), shelf_col)
	draw_rect(Rect2(x1 - 24 * p, sh_y2, 18 * p, 2 * p), shelf_col)
	_draw_jar(x1 - 22 * p, sh_y1 - 4 * p, jar_green, p)
	_draw_jar(x1 - 16 * p, sh_y1 - 4 * p, jar_amber, p)
	_draw_box(x1 - 10 * p, sh_y1 - 3 * p, box_brown, p)
	_draw_jar(x1 - 22 * p, sh_y2 - 4 * p, jar_red, p)
	_draw_box(x1 - 16 * p, sh_y2 - 3 * p, box_brown, p)
	_draw_jar(x1 - 10 * p, sh_y2 - 4 * p, jar_green, p)

	# === ROOF ===
	draw_rect(Rect2(x0 - overhang, roof_top, sw * p + overhang * 2, roof_h * p), roof_dark)
	draw_rect(Rect2(x0 - overhang, roof_top, sw * p + overhang * 2, 2 * p), roof_edge)
	draw_rect(Rect2(x0 - overhang, roof_bot - 2 * p, sw * p + overhang * 2, 2 * p), roof_edge)
	# Roof tile rows
	var ri := 0
	while ri < 3:
		var ry := roof_top + (3 + ri * 4) * p
		draw_rect(Rect2(x0 - overhang, ry, sw * p + overhang * 2, p), roof_mid)
		# Tile vertical lines
		var offset := 4.0 * p if ri % 2 == 1 else 0.0
		var rc := 0
		while rc < 14:
			var rx := x0 - overhang + offset + rc * 7 * p
			if rx < x1 + overhang:
				draw_rect(Rect2(rx, ry, p, 3 * p), roof_light)
			rc += 1
		ri += 1

	# === AWNING (below roof) ===
	var aw_y := roof_bot
	var ai := 0
	while ai < 10:
		var sx := x0 - 3 * p + ai * 9 * p
		var col := awning1 if ai % 2 == 0 else awning2
		draw_rect(Rect2(sx, aw_y, 9 * p, 3 * p), col)
		ai += 1
	# Awning bottom trim
	draw_rect(Rect2(x0 - 3 * p, aw_y + 3 * p, sw * p + 6 * p, p), frame)

	# === SIGN ===
	var sign_w := 40 * p
	var sign_x := -sign_w / 2.0
	var sign_y := roof_top - 4 * p - sign_h * p
	draw_rect(Rect2(sign_x - 2 * p, sign_y - 2 * p, sign_w + 4 * p, sign_h * p + 4 * p), sign_border)
	draw_rect(Rect2(sign_x, sign_y, sign_w, sign_h * p), sign_bg)
	# Hanging poles
	draw_rect(Rect2(sign_x + 3 * p, sign_y + sign_h * p, 2 * p, 6 * p), frame)
	draw_rect(Rect2(sign_x + sign_w - 5 * p, sign_y + sign_h * p, 2 * p, 6 * p), frame)
	# "SHOP" text
	_draw_pixel_text_shop(sign_x + 4 * p, sign_y + 2 * p, gold, p)

	# === LANTERNS ===
	_draw_lantern(x0 - 4 * p, roof_bot + p, lamp_glow, p)
	_draw_lantern(x1 + p, roof_bot + p, lamp_glow, p)

	# === WREATH on left wall ===
	_draw_wreath(x0 + 10 * p, wall_top + 18 * p, wreath_green, wreath_red, p)


func _draw_jar(x: float, y: float, color: Color, p: float):
	draw_rect(Rect2(x, y, 4 * p, 4 * p), color)
	draw_rect(Rect2(x + p, y - p, 2 * p, p), color.darkened(0.3))


func _draw_box(x: float, y: float, color: Color, p: float):
	draw_rect(Rect2(x, y, 5 * p, 3 * p), color)
	draw_rect(Rect2(x, y, 5 * p, p), color.lightened(0.15))


func _draw_lantern(x: float, y: float, glow_color: Color, p: float):
	var bracket := Color(0.18, 0.10, 0.05)
	draw_rect(Rect2(x + p, y, 2 * p, p), bracket)
	draw_rect(Rect2(x, y + p, 4 * p, 2 * p), bracket)
	draw_rect(Rect2(x + p, y + p, 2 * p, 4 * p), glow_color)


func _draw_wreath(x: float, y: float, green: Color, red: Color, p: float):
	draw_rect(Rect2(x + p, y, 3 * p, p), green)
	draw_rect(Rect2(x, y + p, p, 3 * p), green)
	draw_rect(Rect2(x + 4 * p, y + p, p, 3 * p), green)
	draw_rect(Rect2(x + p, y + 4 * p, 3 * p, p), green)
	draw_rect(Rect2(x + 2 * p, y - p, p, p), red)


func _draw_pixel_text_shop(x: float, y: float, c: Color, p: float):
	# S
	draw_rect(Rect2(x + p, y, 4 * p, p), c)
	draw_rect(Rect2(x, y + p, p, 2 * p), c)
	draw_rect(Rect2(x + p, y + 3 * p, 3 * p, p), c)
	draw_rect(Rect2(x + 4 * p, y + 4 * p, p, 2 * p), c)
	draw_rect(Rect2(x, y + 6 * p, 4 * p, p), c)
	# H
	var hx := x + 8 * p
	draw_rect(Rect2(hx, y, p, 7 * p), c)
	draw_rect(Rect2(hx + 4 * p, y, p, 7 * p), c)
	draw_rect(Rect2(hx + p, y + 3 * p, 3 * p, p), c)
	# O
	var ox := x + 16 * p
	draw_rect(Rect2(ox + p, y, 3 * p, p), c)
	draw_rect(Rect2(ox, y + p, p, 5 * p), c)
	draw_rect(Rect2(ox + 4 * p, y + p, p, 5 * p), c)
	draw_rect(Rect2(ox + p, y + 6 * p, 3 * p, p), c)
	# P
	var px := x + 24 * p
	draw_rect(Rect2(px, y, p, 7 * p), c)
	draw_rect(Rect2(px + p, y, 3 * p, p), c)
	draw_rect(Rect2(px + 4 * p, y + p, p, 2 * p), c)
	draw_rect(Rect2(px + p, y + 3 * p, 3 * p, p), c)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		if interact_hint:
			interact_hint.visible = true
		player_entered_shop.emit()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		if interact_hint:
			interact_hint.visible = false
		player_exited_shop.emit()
