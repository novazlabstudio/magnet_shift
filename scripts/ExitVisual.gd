extends Node2D

var open_anim: float = 0.0
var is_open: bool = true
var pulse_time: float = 0.0
var is_playing_open: bool = false
var open_flash: float = 0.0

func _ready():
	z_index = 1

func _process(delta):
	pulse_time += delta
	if is_open:
		open_anim = min(open_anim + delta * 2.0, 1.0)
	if is_playing_open:
		open_flash = min(open_flash + delta * 4.0, 1.0)
	queue_redraw()

func play_open():
	is_playing_open = true

func _octagon_points(center: Vector2, radius: float, rotation_offset: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in 8:
		var angle = rotation_offset + i * TAU / 8.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _draw():
	var center = Vector2(0, -6)
	var outer_r = 30.0
	var inner_r = 25.0
	var portal_open = open_anim

	var bronze_dark = Color(0.32, 0.24, 0.1, 1.0)
	var gold = Color(0.85, 0.65, 0.15, 1.0)

	# Flash efekti - kapıya girilince
	if is_playing_open and open_flash < 1.0:
		var flash_alpha = sin(open_flash * PI) * 0.9
		draw_circle(center, outer_r + 20, Color(0.6, 1.0, 0.5, flash_alpha * 0.5))
		draw_circle(center, outer_r, Color(0.8, 1.0, 0.9, flash_alpha))

	# ── Dış parlama ──
	var pulse = 0.5 + sin(pulse_time * 2.0) * 0.3
	draw_circle(center, outer_r + 14, Color(0.0, 1.0, 0.4, 0.06 * pulse * portal_open))
	draw_circle(center, outer_r + 6, Color(0.0, 1.0, 0.4, 0.1 * pulse * portal_open))

	# ── Sekizgen çerçeve (bronz/altın) ──
	var outer_pts = _octagon_points(center, outer_r, PI / 8.0)
	var inner_frame_pts = _octagon_points(center, outer_r - 6.0, PI / 8.0)

	draw_colored_polygon(outer_pts, bronze_dark)

	# Köşe pimleri
	for p in outer_pts:
		draw_circle(p, 2.4, gold)
		draw_circle(p, 1.2, Color(1.0, 0.9, 0.5, 1.0))

	# Dış çerçeve kenar çizgisi (parlayan)
	var rim_alpha = 0.6 + sin(pulse_time * 1.5) * 0.2
	for i in 8:
		draw_line(outer_pts[i], outer_pts[(i + 1) % 8], Color(gold.r, gold.g, gold.b, rim_alpha), 3.0)

	# İç çerçeve kenar çizgisi (ince)
	for i in 8:
		draw_line(inner_frame_pts[i], inner_frame_pts[(i + 1) % 8], Color(gold.r, gold.g, gold.b, 0.35), 1.0)

	# ── Vorteks (girdap) ──
	if portal_open > 0.02:
		var vr = inner_r * portal_open
		# Karanlık taban
		draw_circle(center, vr, Color(0.0, 0.08, 0.04, 1.0))

		# Dönen halkalar
		for ring in 4:
			var ring_r = vr * (0.35 + ring * 0.18)
			var speed = 1.2 + ring * 0.8
			var dir = 1.0 if ring % 2 == 0 else -1.0
			var rot = pulse_time * speed * dir
			var seg_alpha = 0.35 - ring * 0.05
			draw_arc(center, ring_r, rot, rot + PI * 1.3, 20, Color(0.0, 1.0, 0.45, seg_alpha), 3.0)
			draw_arc(center, ring_r, rot + PI, rot + PI * 1.7, 20, Color(0.5, 1.0, 0.6, seg_alpha * 0.8), 2.0)

		# Spiral kollar
		for arm in 3:
			var arm_offset = arm * TAU / 3.0
			var pts = PackedVector2Array()
			for i in 14:
				var t = float(i) / 13.0
				var ang = arm_offset + pulse_time * 1.5 + t * TAU * 1.4
				var r = vr * t
				pts.append(center + Vector2(cos(ang), sin(ang)) * r)
			for i in pts.size() - 1:
				var a2 = float(i) / float(pts.size() - 1)
				draw_line(pts[i], pts[i + 1], Color(0.4, 1.0, 0.5, 0.5 * a2), 1.5)

		# Merkez parlaması
		var core_glow = 0.6 + sin(pulse_time * 3.0) * 0.2
		draw_circle(center, vr * 0.35, Color(0.6, 1.0, 0.7, core_glow * 0.6))
		draw_circle(center, vr * 0.18, Color(0.9, 1.0, 0.95, core_glow))

		# ── Şimşekler ──
		for b in 3:
			if sin(pulse_time * 5.0 + b * 2.1) > 0.6:
				var start_ang = randf() * TAU
				var start_r = vr * 0.7
				var end_r = outer_r - 8
				var p0 = center + Vector2(cos(start_ang), sin(start_ang)) * start_r
				var mid_ang = start_ang + randf_range(-0.3, 0.3)
				var p_mid = center + Vector2(cos(mid_ang), sin(mid_ang)) * ((start_r + end_r) * 0.5)
				var p1 = center + Vector2(cos(start_ang), sin(start_ang)) * end_r
				draw_line(p0, p_mid, Color(0.7, 1.0, 0.6, 0.8), 1.5)
				draw_line(p_mid, p1, Color(0.7, 1.0, 0.6, 0.8), 1.5)

	# ── EXIT tabela ──
	var sign_w = 50.0
	var sign_h = 14.0
	var sign_pos = Vector2(-sign_w / 2.0, (center.y - outer_r) - sign_h - 8.0)
	var sign_glow = 0.7 + sin(pulse_time * 2.5) * 0.3

	draw_rect(Rect2(sign_pos, Vector2(sign_w, sign_h)), Color(0.08, 0.1, 0.08, 1.0))
	draw_rect(Rect2(sign_pos + Vector2(2, 2), Vector2(sign_w - 4, sign_h - 4)), Color(0.0, 0.15, 0.08, 1.0))
	draw_rect(Rect2(sign_pos, Vector2(sign_w, 2)), gold)
	draw_rect(Rect2(sign_pos + Vector2(0, sign_h - 2), Vector2(sign_w, 2)), gold)

	# Çift ok (>>)
	var arrow_color = Color(0.3, 1.0, 0.5, sign_glow)
	for i in 2:
		var ax = sign_pos.x + 14 + i * 11
		var ay = sign_pos.y + sign_h / 2.0
		var arrow_pts = PackedVector2Array([
			Vector2(ax - 4, ay - 5), Vector2(ax + 4, ay), Vector2(ax - 4, ay + 5)
		])
		draw_colored_polygon(arrow_pts, arrow_color)

	# Bağlantı borusu - tabeladan portala
	draw_line(Vector2(0, sign_pos.y + sign_h), Vector2(0, center.y - outer_r), Color(gold.r, gold.g, gold.b, 0.7), 4.0)
	draw_circle(Vector2(0, sign_pos.y + sign_h), 3.5, gold)
	draw_circle(Vector2(0, center.y - outer_r), 3.5, gold)
