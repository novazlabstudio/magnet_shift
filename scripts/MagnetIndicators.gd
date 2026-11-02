extends Node2D

# Ekranın üstünde/altında kalan mıknatısları kenarda okla gösterir. Her kenarın sol ve sağ
# yarısı için en yakın mıknatıs gösterilir; oka dokunmak o mıknatısı seçer.

const RADIUS := 24.0
const HIT_RADIUS := 46.0

var game: Node2D = null
var level_color: Color = Color(0.3, 0.6, 1.0)
var top_y: float = 0.0
var show_tap_text: bool = false
var markers: Array = []
var _t: float = 0.0

func setup(g: Node2D, color: Color, hud_bottom: float, tap_text: bool) -> void:
	game = g
	level_color = color
	top_y = hud_bottom
	show_tap_text = tap_text

func _process(delta: float) -> void:
	_t += delta
	_refresh()
	queue_redraw()

func _refresh() -> void:
	markers.clear()
	if game == null or not game.level_active:
		return
	var vp = get_viewport().get_visible_rect().size
	var xf = game.get_canvas_transform()
	var best = {}
	for m in game.magnets:
		if not is_instance_valid(m):
			continue
		var sp = xf * m.global_position
		var up = sp.y < top_y - 10.0
		var down = sp.y > vp.y + 10.0
		if not (up or down):
			continue
		var key = ("U" if up else "D") + ("L" if sp.x < vp.x / 2.0 else "R")
		var dist = (top_y - sp.y) if up else (sp.y - vp.y)
		if not best.has(key) or dist < best[key]["dist"]:
			best[key] = {"magnet": m, "dist": dist, "x": sp.x, "up": up}
	for k in best:
		var b = best[k]
		var x = clamp(b["x"], 34.0, vp.x - 34.0)
		var y = top_y + RADIUS + 8.0 if b["up"] else vp.y - RADIUS - 18.0
		markers.append({"magnet": b["magnet"], "pos": Vector2(x, y), "up": b["up"]})

# Dokunulan oku döndürür: {"magnet", "dist"}; ok yoksa boş sözlük
func magnet_at(screen_pos: Vector2) -> Dictionary:
	var hit = {}
	var hit_d = HIT_RADIUS
	for mk in markers:
		var d = mk["pos"].distance_to(screen_pos)
		if d < hit_d and is_instance_valid(mk["magnet"]):
			hit_d = d
			hit = {"magnet": mk["magnet"], "dist": d}
	return hit

func marker_pos_for(m: Node2D):
	for mk in markers:
		if mk["magnet"] == m:
			return mk["pos"]
	return null

func _draw() -> void:
	for mk in markers:
		var p: Vector2 = mk["pos"]
		var active = is_instance_valid(mk["magnet"]) and mk["magnet"].is_active
		var pulse = 0.5 + 0.5 * sin(_t * 5.0)
		var accent = Color(0.0, 0.9, 1.0)
		draw_circle(p, RADIUS + 6.0 + pulse * 6.0, Color(accent.r, accent.g, accent.b, 0.12 + 0.1 * pulse))
		draw_circle(p, RADIUS, Color(0.02, 0.03, 0.08, 0.8))
		if active:
			draw_circle(p, RADIUS, Color(accent.r, accent.g, accent.b, 0.35))
		draw_arc(p, RADIUS, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.7 + 0.3 * pulse), 2.5, true)
		_draw_magnet_icon(p + Vector2(0, 3 if mk["up"] else -3))
		_draw_arrow(p, mk["up"], pulse)
		if show_tap_text:
			var ty = p.y + RADIUS + 22.0 if mk["up"] else p.y - RADIUS - 10.0
			draw_string(ThemeDB.fallback_font, Vector2(p.x - 30.0, ty), "TAP", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 15, Color(1, 1, 1, 0.75 + 0.25 * pulse))

func _draw_arrow(p: Vector2, up: bool, pulse: float) -> void:
	var dir = -1.0 if up else 1.0
	var tip = p + Vector2(0, dir * (RADIUS + 9.0 + pulse * 3.0))
	var base_y = tip.y - dir * 9.0
	draw_colored_polygon(PackedVector2Array([tip, Vector2(p.x - 8.0, base_y), Vector2(p.x + 8.0, base_y)]), Color(0.0, 0.9, 1.0, 0.9))

func _draw_magnet_icon(c: Vector2) -> void:
	# Küçük U mıknatıs: gövde seviye renginde, uçlar kırmızı/mavi
	var body = level_color.lightened(0.25)
	draw_arc(c + Vector2(0, -1), 8.0, 0.0, PI, 14, body, 5.0, true)
	draw_line(c + Vector2(-8, -1), c + Vector2(-8, -9), body, 5.0)
	draw_line(c + Vector2(8, -1), c + Vector2(8, -9), body, 5.0)
	draw_rect(Rect2(c + Vector2(-10.5, -13), Vector2(5, 5)), Color(0.95, 0.2, 0.25))
	draw_rect(Rect2(c + Vector2(5.5, -13), Vector2(5, 5)), Color(0.25, 0.45, 1.0))
