extends Node2D

# Ses aç/kapa butonunun görseli (yalnızca çizim; tıklamayı üstteki Button alır).
#   style "compact": oyun içi HUD, 44x44, merkez = node konumu (pause butonuyla aynı çerçeve)
#   style "menu"   : ana menü üst çubuğu, 84x56, sol üst = node konumu (BOARD/AWARDS/LEVELS ile aynı çerçeve)
# Açıkken: degrade gövdeli hoparlör, dışa doğru akan ses dalgaları, titreşen zar.
# Kapalıyken: soluk hoparlör + parlayan kırmızı çarpı. Her değişimde küçük bir "pop" ve halka.

const ON_COL := Color(0.0, 0.85, 1.0)
const OFF_COL := Color(1.0, 0.36, 0.46)

var style: String = "compact"
var is_on: bool = true
var time: float = 0.0
var pop: float = 0.0
var _initialized: bool = false

func setup(sound_on: bool) -> void:
	if _initialized and sound_on != is_on:
		pop = 1.0
	is_on = sound_on
	_initialized = true
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	pop = max(0.0, pop - delta * 3.2)
	queue_redraw()

func _draw() -> void:
	var accent = ON_COL if is_on else OFF_COL
	var icon_c: Vector2
	var icon_s: float
	if style == "menu":
		_draw_menu_frame(accent)
		icon_c = Vector2(42, 17)
		icon_s = 0.92
	else:
		_draw_compact_frame(accent)
		icon_c = Vector2.ZERO
		icon_s = 1.0
	# Değişimde zıplama
	var bounce = 1.0 + sin(pop * PI) * 0.22
	draw_set_transform(icon_c, 0.0, Vector2(icon_s * bounce, icon_s * bounce))
	if pop > 0.0:
		var r = 6.0 + (1.0 - pop) * 18.0
		draw_arc(Vector2.ZERO, r, 0, TAU, 28, Color(accent.r, accent.g, accent.b, pop * 0.7), 2.0)
	if is_on:
		_draw_waves()
		_draw_speaker(true)
	else:
		_draw_speaker(false)
		_draw_cross()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if style == "menu":
		var font = UIFont.title(1)
		var txt = "SOUND" if is_on else "MUTED"
		draw_string(font, Vector2(0, 46), txt, HORIZONTAL_ALIGNMENT_CENTER, 84, 11, accent.lightened(0.15))

# ── Çerçeveler ────────────────────────────────────────────────────────────────
func _draw_compact_frame(accent: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.1, 0.55)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	draw_style_box(sb, Rect2(-22, -22, 44, 44))
	# iç parıltı
	draw_circle(Vector2.ZERO, 15, Color(accent.r, accent.g, accent.b, 0.06 + (0.03 * sin(time * 2.4) if is_on else 0.0)))

func _draw_menu_frame(accent: Color) -> void:
	# _get_hud_button_script ile aynı dil: koyu panel, köşe noktaları, üst/sol vurgu çizgisi
	var w = 84.0
	var h = 56.0
	var pulse = 0.6 + sin(time * 2.2) * 0.25
	draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.05, 0.1, 0.92))
	draw_rect(Rect2(0, 0, w, h), Color(accent.r, accent.g, accent.b, 0.06))
	for cx in [3.0, w - 3.0]:
		for cy in [3.0, h - 3.0]:
			draw_circle(Vector2(cx, cy), 1.6, Color(accent.r, accent.g, accent.b, 0.7))
	draw_rect(Rect2(0, 0, w, 2), Color(accent.r, accent.g, accent.b, 0.5 + pulse * 0.3))
	draw_rect(Rect2(0, h - 2, w, 2), Color(accent.r, accent.g, accent.b, 0.3))
	draw_rect(Rect2(0, 0, 2, h), Color(accent.r, accent.g, accent.b, 0.5 + pulse * 0.3))
	draw_rect(Rect2(w - 2, 0, 2, h), Color(accent.r, accent.g, accent.b, 0.3))
	draw_circle(Vector2(42, 17), 13, Color(accent.r, accent.g, accent.b, 0.08 + pulse * 0.05))

# ── Hoparlör ──────────────────────────────────────────────────────────────────
func _draw_speaker(on: bool) -> void:
	var ox = -6.0  # ikon merkezde dursun diye sola kaydır (dalgalar sağda)
	var thump = (sin(time * 9.0) * 0.5 + 0.5) * 0.8 if on else 0.0
	var light = Color(0.75, 0.97, 1.0) if on else Color(0.62, 0.6, 0.68)
	var mid = Color(0.1, 0.7, 0.95) if on else Color(0.38, 0.36, 0.45)
	var dark = Color(0.02, 0.32, 0.55) if on else Color(0.2, 0.19, 0.26)
	# Arka kutu (mıknatıs gövdesi): yuvarlatılmış, üstten alta degrade
	var box = _rrect_pts(Rect2(ox - 9, -5.5, 8, 11), 2.0)
	var box_cols = PackedColorArray()
	for p in box:
		box_cols.append(light.lerp(dark, clamp((p.y + 5.5) / 11.0, 0.0, 1.0)))
	draw_polygon(box, box_cols)
	# Koni: dışa açılan huni, üst kenar aydınlık
	var cone = PackedVector2Array([
		Vector2(ox - 1.5, -5.5), Vector2(ox + 7.5, -12.0 - thump),
		Vector2(ox + 7.5, 12.0 + thump), Vector2(ox - 1.5, 5.5)])
	var cone_cols = PackedColorArray([light, light.lerp(mid, 0.3), dark, dark.lerp(mid, 0.4)])
	draw_polygon(cone, cone_cols)
	# Koni ağzı: ön çember (elips) + zar
	_ellipse(Vector2(ox + 7.5, 0), 2.6, 12.0 + thump, mid.darkened(0.25))
	_ellipse(Vector2(ox + 8.2, 0), 1.6, 8.5 + thump * 0.7, light.lerp(mid, 0.5))
	draw_circle(Vector2(ox + 8.6, 0), 1.6 + thump * 0.4, Color(1, 1, 1, 0.9 if on else 0.4))
	# Parlama çizgisi
	draw_line(Vector2(ox - 0.5, -5.0), Vector2(ox + 7.0, -11.0 - thump), Color(1, 1, 1, 0.75 if on else 0.3), 1.2)
	draw_line(Vector2(ox - 8.0, -4.5), Vector2(ox - 2.5, -4.5), Color(1, 1, 1, 0.55 if on else 0.25), 1.0)

func _draw_waves() -> void:
	var c = Vector2(4.0, 0)
	for i in 3:
		var r = 6.0 + i * 5.2
		var ph = fposmod(time * 1.4 - i * 0.28, 1.0)
		var a = 0.35 + 0.65 * pow(1.0 - abs(ph - 0.5) * 2.0, 2.0)
		var span = PI * (0.36 - i * 0.03)
		draw_arc(c, r, -span, span, 14, Color(0.0, 0.85, 1.0, a * 0.25), 5.0)
		draw_arc(c, r, -span, span, 14, Color(0.55, 0.95, 1.0, a), 2.0)
	# Uçuşan küçük nota parıltıları
	for k in 2:
		var t = fposmod(time * 0.6 + k * 0.5, 1.0)
		var p = Vector2(10 + t * 9.0, -7 + k * 12 - t * 6.0)
		draw_circle(p, 1.2, Color(0.7, 1.0, 1.0, (1.0 - t) * 0.8))

func _draw_cross() -> void:
	var c = Vector2(8.5, 0)
	var s = 5.0
	var glow = 0.55 + sin(time * 3.0) * 0.2
	for pair in [[Vector2(-s, -s), Vector2(s, s)], [Vector2(s, -s), Vector2(-s, s)]]:
		draw_line(c + pair[0], c + pair[1], Color(OFF_COL.r, OFF_COL.g, OFF_COL.b, 0.25 * glow), 6.0)
		draw_line(c + pair[0], c + pair[1], OFF_COL, 2.6)
	draw_circle(c, 1.4, Color(1, 0.85, 0.88, 0.9))

# ── Yardımcılar ───────────────────────────────────────────────────────────────
func _ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 14:
		var a = TAU * i / 14.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)

func _rrect_pts(r: Rect2, rad: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var cs = [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in 4:
		for i in 3:
			var a = -PI / 2.0 + k * PI / 2.0 + (PI / 2.0) * i / 2.0
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return pts
