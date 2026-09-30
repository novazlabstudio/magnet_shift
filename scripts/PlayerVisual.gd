extends Node2D

var time: float = 0.0
var is_dead: bool = false
var is_pulled: bool = false
var pull_intensity: float = 0.0
var hero_id: int = 0  # 0=Cyborg, 1=Pink, 2=Shadow

func _ready():
	hero_id = HeroManager.get_hero()

func _process(delta):
	time += delta
	var player = get_parent()
	if player and "active_magnet" in player:
		var has_magnet = player.active_magnet != null
		pull_intensity = move_toward(pull_intensity, 1.0 if has_magnet else 0.0, delta * 3.0)
		is_pulled = has_magnet
	queue_redraw()

func set_dead(dead: bool):
	is_dead = dead
	queue_redraw()

func _draw():
	if is_dead:
		_draw_dead()
		return
	match hero_id:
		0: _draw_cyborg()
		1: _draw_pink()
		2: _draw_shadow()
		3: _draw_mech()
		_: _draw_cyborg()

# ── CYBORG (orijinal mavi/gri) ────────────────────────────────────────────
# ── CYBORG (mavi/gri, yeniden tasarlandı) ────────────────────────────────────
func _draw_cyborg():
	var pulse = sin(time * 2.5) * 0.5 + 0.5
	var fast_pulse = sin(time * 6.0) * 0.5 + 0.5
	var armor_glow = 0.06 + pull_intensity * 0.25 + pulse * 0.04
	var glow_size = 22 + pull_intensity * 12

	var armor = Color(0.52, 0.54, 0.7)
	var armor_dark = Color(0.3, 0.31, 0.44)
	var armor_light = Color(0.72, 0.74, 0.9)
	var visor_dark = Color(0.0, 0.0, 0.08, 0.95)
	var cyan = Color(0.0, 0.83, 1.0)

	# Aura
	draw_circle(Vector2(0, -4), glow_size + 4, Color(0.0, 0.6, 1.0, armor_glow * 0.4))
	draw_circle(Vector2(0, -4), glow_size, Color(0.0, 0.83, 1.0, armor_glow))

	# Kıvılcımlar
	if pull_intensity > 0.3:
		for i in 6:
			var angle = time * 4.0 + i * TAU / 6.0
			var spark_r = glow_size + 6 + sin(time * 8 + i) * 4
			var sx = cos(angle) * spark_r
			var sy = sin(angle) * spark_r - 4
			var spark_alpha = pull_intensity * (0.4 + sin(time * 7 + i) * 0.3)
			draw_circle(Vector2(sx, sy), 1.5 + pull_intensity, Color(0.0, 0.9, 1.0, spark_alpha))
			draw_line(Vector2(sx * 0.7, sy * 0.7), Vector2(sx, sy), Color(0.0, 0.85, 1.0, spark_alpha * 0.6), 1.0)

	# ── Bacaklar ──
	_rrect(Vector2(-9, 8), Vector2(6, 12), 2.0, armor_dark)
	_rrect(Vector2(3, 8), Vector2(6, 12), 2.0, armor_dark)
	_rrect(Vector2(-9, 8), Vector2(2, 9), 1.0, Color(1, 1, 1, 0.1 + pull_intensity * 0.1))
	_rrect(Vector2(3, 8), Vector2(2, 9), 1.0, Color(1, 1, 1, 0.1 + pull_intensity * 0.1))
	# Botlar
	_rrect(Vector2(-11, 17), Vector2(9, 7), 2.5, armor)
	_rrect(Vector2(2, 17), Vector2(9, 7), 2.5, armor)
	_rrect(Vector2(-11, 17), Vector2(9, 2.5), 1.5, Color(armor_light.r, armor_light.g, armor_light.b, 0.5))
	_rrect(Vector2(2, 17), Vector2(9, 2.5), 1.5, Color(armor_light.r, armor_light.g, armor_light.b, 0.5))

	# ── Gövde (tapered) ──
	var torso_pts = PackedVector2Array([
		Vector2(-13, -9), Vector2(13, -9),
		Vector2(11, 3), Vector2(8, 11),
		Vector2(-8, 11), Vector2(-11, 3),
	])
	draw_colored_polygon(torso_pts, armor)
	_rrect(Vector2(-13, -9), Vector2(26, 4), 2.0, Color(armor_light.r, armor_light.g, armor_light.b, 0.55 + pull_intensity * 0.25))
	_rrect(Vector2(-13, -9), Vector2(3, 14), 1.5, Color(1, 1, 1, 0.08 + pull_intensity * 0.12))

	# Gösterge ışıkları
	draw_circle(Vector2(-8, -5), 1.7, Color(0.15, 0.4, 0.85))
	draw_circle(Vector2(8, -5), 1.7, Color(0.85, 0.2, 0.2))

	# Göğüs paneli
	_rrect(Vector2(-6, -2), Vector2(12, 2), 1.0, Color(cyan.r, cyan.g, cyan.b, 0.18 + pull_intensity * 0.2))

	# Çekirdek
	var core_intensity = 0.5 + pull_intensity * 0.5 + fast_pulse * 0.2
	draw_circle(Vector2(0, 2), 5, Color(0.0, 0.83, 1.0, core_intensity * 0.8))
	draw_circle(Vector2(0, 2), 3, Color(1.0, 1.0, 1.0, core_intensity * 0.6))
	if pull_intensity > 0.1:
		draw_arc(Vector2(0, 2), 7.5 + pull_intensity * 3, time * 3.0, time * 3.0 + TAU * 0.8, 16, Color(0.0, 0.83, 1.0, pull_intensity * 0.5), 1.5)

	# ── Omuzlar ──
	draw_circle(Vector2(-14, -7), 6.0, armor_dark)
	draw_circle(Vector2(-14, -8), 4.2, armor)
	draw_circle(Vector2(14, -7), 6.0, armor_dark)
	draw_circle(Vector2(14, -8), 4.2, armor)

	# ── Kollar ──
	_rrect(Vector2(-19, -6), Vector2(7, 14), 3.0, armor)
	_rrect(Vector2(12, -6), Vector2(7, 14), 3.0, armor)
	_rrect(Vector2(-19, -6), Vector2(2.5, 11), 1.2, Color(1, 1, 1, 0.1 + pull_intensity * 0.1))
	_rrect(Vector2(12, -6), Vector2(2.5, 11), 1.2, Color(1, 1, 1, 0.1 + pull_intensity * 0.1))
	# Eller
	draw_circle(Vector2(-15.5, 10), 4.2, armor_dark)
	draw_circle(Vector2(15.5, 10), 4.2, armor_dark)
	draw_circle(Vector2(-15.5, 10), 2.0, Color(cyan.r, cyan.g, cyan.b, 0.35 + pull_intensity * 0.3))
	draw_circle(Vector2(15.5, 10), 2.0, Color(cyan.r, cyan.g, cyan.b, 0.35 + pull_intensity * 0.3))

	# ── Kafa ──
	_rrect(Vector2(-10, -25), Vector2(20, 17), 5.0, armor_dark)
	_rrect(Vector2(-10, -25), Vector2(20, 5), 4.0, Color(armor_light.r, armor_light.g, armor_light.b, 0.65 + pull_intensity * 0.2))
	# Yan vantilasyon
	_rrect(Vector2(-12, -19), Vector2(2, 8), 1.0, armor)
	_rrect(Vector2(10, -19), Vector2(2, 8), 1.0, armor)

	# Anten
	_rrect(Vector2(-1, -32), Vector2(2, 8), 1.0, armor)
	var ant_speed = 2.5 + pull_intensity * 5.0
	var ant_size = 3.0 + pull_intensity * 2.0 + sin(time * ant_speed) * 1.0
	var ant_alpha = 0.8 + sin(time * ant_speed) * 0.2
	draw_circle(Vector2(0, -33), ant_size, Color(0.0, 0.83, 1.0, ant_alpha))
	draw_circle(Vector2(0, -33), ant_size * 0.5, Color(1.0, 1.0, 1.0, ant_alpha * 0.8))
	if pull_intensity > 0.2:
		for i in 2:
			var ring_r = ant_size + 4 + i * 5 + sin(time * 6 + i) * 2
			draw_arc(Vector2(0, -33), ring_r, 0, TAU, 16, Color(0.0, 0.83, 1.0, pull_intensity * (0.4 - i * 0.15)), 1.2)

	# Vizör
	_rrect(Vector2(-8, -21), Vector2(16, 8), 3.0, visor_dark)
	var eye_glow = 0.7 + pull_intensity * 0.3 + sin(time * 3) * 0.1
	draw_circle(Vector2(-4, -17), 3.2, Color(0.0, 0.83, 1.0, eye_glow))
	draw_circle(Vector2(-4, -17), 1.8, Color(1.0, 1.0, 1.0, 0.85))
	draw_circle(Vector2(4, -17), 3.2, Color(0.0, 0.83, 1.0, eye_glow))
	draw_circle(Vector2(4, -17), 1.8, Color(1.0, 1.0, 1.0, 0.85))
	if pull_intensity > 0.3:
		draw_circle(Vector2(-4, -17), 5.5, Color(0.0, 0.83, 1.0, pull_intensity * 0.2))
		draw_circle(Vector2(4, -17), 5.5, Color(0.0, 0.83, 1.0, pull_intensity * 0.2))

	draw_ellipse_approx(Vector2(0, 24), 14, 3, Color(0.0, 0.0, 0.0, 0.25 - pull_intensity * 0.15))
	
# ── PINK GIRL (pembe/beyaz zırh) ─────────────────────────────────────────────
# ── PINK GIRL (pembe/beyaz zırh, yeniden tasarlandı) ─────────────────────────
func _draw_pink():
	var pulse = sin(time * 2.5) * 0.5 + 0.5
	var fast_pulse = sin(time * 6.0) * 0.5 + 0.5
	var armor_glow = 0.06 + pull_intensity * 0.25 + pulse * 0.04
	var glow_size = 22 + pull_intensity * 12
	var pink = Color(1.0, 0.4, 0.7)
	var light_pink = Color(1.0, 0.75, 0.88)
	var white = Color(0.97, 0.96, 1.0)
	var dark_pink = Color(0.85, 0.25, 0.55)

	# Aura
	draw_circle(Vector2(0, -4), glow_size + 4, Color(1.0, 0.4, 0.7, armor_glow * 0.4))
	draw_circle(Vector2(0, -4), glow_size, Color(1.0, 0.4, 0.7, armor_glow))

	# Kalp kıvılcımları
	if pull_intensity > 0.3:
		for i in 6:
			var angle = time * 3.0 + i * TAU / 6.0
			var spark_r = glow_size + 6 + sin(time * 8 + i) * 4
			var sx = cos(angle) * spark_r
			var sy = sin(angle) * spark_r - 4
			var a = pull_intensity * (0.4 + sin(time * 7 + i) * 0.3)
			draw_circle(Vector2(sx, sy), 2.0 + pull_intensity, Color(1.0, 0.4, 0.7, a))
			draw_line(Vector2(sx * 0.7, sy * 0.7), Vector2(sx, sy), Color(1.0, 0.6, 0.8, a * 0.6), 1.0)

	# ── Bacaklar ──
	_rrect(Vector2(-9, 8), Vector2(6, 12), 2.0, Color(0.9, 0.55, 0.75))
	_rrect(Vector2(3, 8), Vector2(6, 12), 2.0, Color(0.9, 0.55, 0.75))
	_rrect(Vector2(-9, 8), Vector2(2, 9), 1.0, Color(1, 1, 1, 0.2 + pull_intensity * 0.1))
	_rrect(Vector2(3, 8), Vector2(2, 9), 1.0, Color(1, 1, 1, 0.2 + pull_intensity * 0.1))
	_rrect(Vector2(-11, 17), Vector2(9, 7), 3.0, light_pink)
	_rrect(Vector2(2, 17), Vector2(9, 7), 3.0, light_pink)
	_rrect(Vector2(-11, 17), Vector2(9, 2.5), 1.5, Color(1, 1, 1, 0.5))
	_rrect(Vector2(2, 17), Vector2(9, 2.5), 1.5, Color(1, 1, 1, 0.5))

	# ── Gövde ──
	var torso_pts = PackedVector2Array([
		Vector2(-13, -9), Vector2(13, -9),
		Vector2(11, 3), Vector2(8, 11),
		Vector2(-8, 11), Vector2(-11, 3),
	])
	draw_colored_polygon(torso_pts, white)
	_rrect(Vector2(-13, -9), Vector2(26, 4), 2.0, Color(1.0, 0.6 + pull_intensity * 0.2, 0.8, 0.85))
	_rrect(Vector2(-13, -9), Vector2(3, 14), 1.5, Color(1, 1, 1, 0.35))

	# Kalp detayı
	draw_circle(Vector2(-3, -1), 4, pink)
	draw_circle(Vector2(3, -1), 4, pink)
	draw_circle(Vector2(0, 2), 4.5, pink)
	var core_intensity = 0.5 + pull_intensity * 0.5 + fast_pulse * 0.2
	draw_circle(Vector2(0, 0), 3, Color(1.0, 1.0, 1.0, core_intensity * 0.8))
	if pull_intensity > 0.1:
		draw_arc(Vector2(0, 1), 7.5 + pull_intensity * 3, time * 3.0, time * 3.0 + TAU * 0.8, 16, Color(1.0, 0.4, 0.7, pull_intensity * 0.5), 1.5)

	# ── Omuzlar ──
	draw_circle(Vector2(-14, -7), 6.0, light_pink)
	draw_circle(Vector2(-14, -8), 4.2, white)
	draw_circle(Vector2(14, -7), 6.0, light_pink)
	draw_circle(Vector2(14, -8), 4.2, white)

	# ── Kollar ──
	_rrect(Vector2(-19, -6), Vector2(7, 14), 3.0, Color(0.9, 0.65, 0.8))
	_rrect(Vector2(12, -6), Vector2(7, 14), 3.0, Color(0.9, 0.65, 0.8))
	_rrect(Vector2(-19, -6), Vector2(2.5, 11), 1.2, Color(1, 1, 1, 0.25))
	_rrect(Vector2(12, -6), Vector2(2.5, 11), 1.2, Color(1, 1, 1, 0.25))
	draw_circle(Vector2(-15.5, 10), 4.2, light_pink)
	draw_circle(Vector2(15.5, 10), 4.2, light_pink)
	draw_circle(Vector2(-15.5, 10), 2.0, Color(pink.r, pink.g, pink.b, 0.6))
	draw_circle(Vector2(15.5, 10), 2.0, Color(pink.r, pink.g, pink.b, 0.6))

	# ── Kafa ──
	_rrect(Vector2(-10, -25), Vector2(20, 17), 5.0, white)
	_rrect(Vector2(-10, -25), Vector2(20, 5), 4.0, Color(1.0, 0.55 + pull_intensity * 0.2, 0.78, 0.85))
	_rrect(Vector2(-12, -19), Vector2(2, 8), 1.0, light_pink)
	_rrect(Vector2(10, -19), Vector2(2, 8), 1.0, light_pink)

	# Fiyonk + anten
	var ant_speed = 2.5 + pull_intensity * 5.0
	var ant_size = 3.0 + pull_intensity * 2.0 + sin(time * ant_speed) * 1.0
	_rrect(Vector2(-1, -32), Vector2(2, 8), 1.0, light_pink)
	var pts_bow = PackedVector2Array([Vector2(-7,-30), Vector2(-1,-34), Vector2(-1,-28)])
	draw_colored_polygon(pts_bow, dark_pink)
	var pts_bow2 = PackedVector2Array([Vector2(7,-30), Vector2(1,-34), Vector2(1,-28)])
	draw_colored_polygon(pts_bow2, dark_pink)
	draw_circle(Vector2(0, -31), 2.5, Color(1.0, 0.5, 0.75))
	draw_circle(Vector2(0, -33), ant_size, Color(1.0, 0.4, 0.7, 0.9))
	draw_circle(Vector2(0, -33), ant_size * 0.5, Color(1.0, 1.0, 1.0, 0.9))
	if pull_intensity > 0.2:
		for i in 2:
			var ring_r = ant_size + 4 + i * 5 + sin(time * 6 + i) * 2
			draw_arc(Vector2(0, -33), ring_r, 0, TAU, 16, Color(1.0, 0.4, 0.7, pull_intensity * (0.4 - i * 0.15)), 1.2)

	# Vizör
	_rrect(Vector2(-8, -21), Vector2(16, 8), 3.0, Color(0.1, 0.0, 0.05, 0.85))
	var eye_glow = 0.7 + pull_intensity * 0.3 + sin(time * 3) * 0.1
	draw_circle(Vector2(-4, -17), 3.2, Color(1.0, 0.3, 0.6, eye_glow))
	draw_circle(Vector2(-4, -17), 1.8, Color(1.0, 1.0, 1.0, 0.85))
	draw_circle(Vector2(4, -17), 3.2, Color(1.0, 0.3, 0.6, eye_glow))
	draw_circle(Vector2(4, -17), 1.8, Color(1.0, 1.0, 1.0, 0.85))
	if pull_intensity > 0.3:
		draw_circle(Vector2(-4, -17), 5.5, Color(1.0, 0.4, 0.7, pull_intensity * 0.2))
		draw_circle(Vector2(4, -17), 5.5, Color(1.0, 0.4, 0.7, pull_intensity * 0.2))

	draw_ellipse_approx(Vector2(0, 24), 14, 3, Color(0.0, 0.0, 0.0, 0.2 - pull_intensity * 0.1))
	
# ── SHADOW (siyah/mor ninja) ─────────────────────────────────────────────────
# ── SHADOW (siyah/mor ninja, yeniden tasarlandı) ─────────────────────────────
func _draw_shadow():
	var pulse = sin(time * 2.5) * 0.5 + 0.5
	var fast_pulse = sin(time * 6.0) * 0.5 + 0.5
	var armor_glow = 0.06 + pull_intensity * 0.3 + pulse * 0.04
	var glow_size = 22 + pull_intensity * 14
	var dark = Color(0.1, 0.07, 0.16)
	var darker = Color(0.06, 0.04, 0.1)

	# Mor/kırmızı aura
	draw_circle(Vector2(0, -4), glow_size + 6, Color(0.5, 0.0, 0.8, armor_glow * 0.5))
	draw_circle(Vector2(0, -4), glow_size, Color(0.6, 0.0, 0.9, armor_glow))

	if pull_intensity > 0.3:
		for i in 8:
			var angle = time * 5.0 + i * TAU / 8.0
			var spark_r = glow_size + 8 + sin(time * 9 + i) * 5
			var sx = cos(angle) * spark_r
			var sy = sin(angle) * spark_r - 4
			var a = pull_intensity * (0.5 + sin(time * 8 + i) * 0.3)
			draw_circle(Vector2(sx, sy), 1.5 + pull_intensity, Color(0.7, 0.0, 1.0, a))
			draw_line(Vector2(sx * 0.6, sy * 0.6), Vector2(sx, sy), Color(0.8, 0.0, 1.0, a * 0.7), 1.5)

	# ── Bacaklar ──
	_rrect(Vector2(-9, 8), Vector2(6, 12), 2.0, darker)
	_rrect(Vector2(3, 8), Vector2(6, 12), 2.0, darker)
	_rrect(Vector2(-9, 8), Vector2(2, 9), 1.0, Color(0.6, 0.0, 0.9, 0.2 + pull_intensity * 0.15))
	_rrect(Vector2(3, 8), Vector2(2, 9), 1.0, Color(0.6, 0.0, 0.9, 0.2 + pull_intensity * 0.15))
	_rrect(Vector2(-11, 17), Vector2(9, 7), 2.5, dark)
	_rrect(Vector2(2, 17), Vector2(9, 7), 2.5, dark)
	_rrect(Vector2(-11, 17), Vector2(9, 2.5), 1.5, Color(0.6, 0.0, 0.9, 0.3))
	_rrect(Vector2(2, 17), Vector2(9, 2.5), 1.5, Color(0.6, 0.0, 0.9, 0.3))

	# ── Gövde ──
	var torso_pts = PackedVector2Array([
		Vector2(-13, -9), Vector2(13, -9),
		Vector2(11, 3), Vector2(8, 11),
		Vector2(-8, 11), Vector2(-11, 3),
	])
	draw_colored_polygon(torso_pts, dark)
	_rrect(Vector2(-13, -9), Vector2(26, 4), 2.0, Color(0.5 + pull_intensity * 0.3, 0.0, 0.8, 0.85))
	_rrect(Vector2(-13, -9), Vector2(3, 14), 1.5, Color(0.6, 0.0, 0.9, 0.25))

	# Çekirdek - kuru kafa sembolü
	var core_intensity = 0.5 + pull_intensity * 0.5 + fast_pulse * 0.2
	draw_circle(Vector2(0, 1), 6, Color(0.5, 0.0, 0.8, core_intensity * 0.7))
	draw_circle(Vector2(0, 1), 4, Color(0.8, 0.0, 0.1, core_intensity * 0.9))
	draw_circle(Vector2(0, 1), 2.5, Color(1.0, 0.3, 0.0, core_intensity))
	if pull_intensity > 0.1:
		draw_arc(Vector2(0, 1), 8.5 + pull_intensity * 4, time * 4.0, time * 4.0 + TAU * 0.9, 16, Color(0.7, 0.0, 1.0, pull_intensity * 0.6), 2.0)

	# ── Omuzlar ──
	draw_circle(Vector2(-14, -7), 6.0, darker)
	draw_circle(Vector2(-14, -8), 4.2, dark)
	draw_circle(Vector2(14, -7), 6.0, darker)
	draw_circle(Vector2(14, -8), 4.2, dark)

	# ── Kollar ──
	_rrect(Vector2(-19, -6), Vector2(7, 14), 3.0, dark)
	_rrect(Vector2(12, -6), Vector2(7, 14), 3.0, dark)
	_rrect(Vector2(-19, -6), Vector2(2.5, 11), 1.2, Color(0.6, 0.0, 0.9, 0.2))
	_rrect(Vector2(12, -6), Vector2(2.5, 11), 1.2, Color(0.6, 0.0, 0.9, 0.2))
	# Pençe/Yumruk
	draw_circle(Vector2(-15.5, 10), 4.2, darker)
	draw_circle(Vector2(15.5, 10), 4.2, darker)
	for i in 3:
		draw_line(Vector2(-18 + i*3, 9), Vector2(-19 + i*3, 15), Color(0.5, 0.0, 0.8, 0.7), 1.5)
		draw_line(Vector2(12 + i*3, 9), Vector2(13 + i*3, 15), Color(0.5, 0.0, 0.8, 0.7), 1.5)

	# ── Kafa ──
	_rrect(Vector2(-10, -25), Vector2(20, 17), 5.0, dark)
	_rrect(Vector2(-10, -25), Vector2(20, 5), 4.0, Color(0.55 + pull_intensity * 0.3, 0.0, 0.85, 0.85))
	_rrect(Vector2(-12, -19), Vector2(2, 8), 1.0, dark)
	_rrect(Vector2(10, -19), Vector2(2, 8), 1.0, dark)

	# Boynuzlar
	var horn1 = PackedVector2Array([Vector2(-7,-25), Vector2(-3,-25), Vector2(-6,-33)])
	draw_colored_polygon(horn1, Color(0.5, 0.0, 0.8, 0.85))
	var horn2 = PackedVector2Array([Vector2(7,-25), Vector2(3,-25), Vector2(6,-33)])
	draw_colored_polygon(horn2, Color(0.5, 0.0, 0.8, 0.85))

	# Anten
	_rrect(Vector2(-1, -32), Vector2(2, 8), 1.0, Color(0.15, 0.1, 0.2))
	var ant_speed = 3.0 + pull_intensity * 6.0
	var ant_size = 3.5 + pull_intensity * 2.5 + sin(time * ant_speed) * 1.2
	draw_circle(Vector2(0, -33), ant_size, Color(0.7, 0.0, 1.0, 0.9))
	draw_circle(Vector2(0, -33), ant_size * 0.45, Color(1.0, 0.5, 0.0, 0.9))
	if pull_intensity > 0.2:
		for i in 3:
			var ring_r = ant_size + 4 + i * 5 + sin(time * 7 + i) * 2
			draw_arc(Vector2(0, -33), ring_r, 0, TAU, 16, Color(0.6, 0.0, 0.9, pull_intensity * (0.45 - i * 0.12)), 1.5)

	# Vizör - kırmızı/turuncu gözler
	_rrect(Vector2(-8, -21), Vector2(16, 8), 3.0, Color(0.05, 0.0, 0.08, 0.95))
	var eye_glow = 0.8 + pull_intensity * 0.2 + sin(time * 4) * 0.15
	draw_circle(Vector2(-4, -17), 3.6, Color(0.9, 0.0, 0.0, eye_glow))
	draw_circle(Vector2(-4, -17), 2.2, Color(1.0, 0.4, 0.0, 0.9))
	draw_circle(Vector2(4, -17), 3.6, Color(0.9, 0.0, 0.0, eye_glow))
	draw_circle(Vector2(4, -17), 2.2, Color(1.0, 0.4, 0.0, 0.9))
	if pull_intensity > 0.3:
		draw_circle(Vector2(-4, -17), 6.0, Color(1.0, 0.0, 0.0, pull_intensity * 0.3))
		draw_circle(Vector2(4, -17), 6.0, Color(1.0, 0.0, 0.0, pull_intensity * 0.3))

	draw_ellipse_approx(Vector2(0, 24), 14, 3, Color(0.3, 0.0, 0.5, 0.3 - pull_intensity * 0.1))
# ── ÖLÜM ─────────────────────────────────────────────────────────────────────
func _draw_dead():
	var body_color = [Color(0.5, 0.15, 0.15), Color(0.6, 0.3, 0.4), Color(0.15, 0.05, 0.2), Color(0.1, 0.25, 0.1)][hero_id]
	draw_rect(Rect2(-12, -8, 24, 30), body_color)
	draw_rect(Rect2(-11, -24, 22, 18), body_color * 0.8)
	draw_line(Vector2(-8, -22), Vector2(-2, -16), Color(1.0, 0.2, 0.2), 2.0)
	draw_line(Vector2(-2, -22), Vector2(-8, -16), Color(1.0, 0.2, 0.2), 2.0)
	draw_line(Vector2(2, -22), Vector2(8, -16), Color(1.0, 0.2, 0.2), 2.0)
	draw_line(Vector2(8, -22), Vector2(2, -16), Color(1.0, 0.2, 0.2), 2.0)
	for i in 4:
		var angle = TAU * i / 4.0 + time
		var r = 16 + sin(time * 5 + i) * 4
		draw_circle(Vector2(cos(angle) * r, sin(angle) * r - 4), 2.0, Color(1.0, 0.3 + sin(time * 8 + i) * 0.3, 0.0, 0.7))

# ── MECH (altın/yeşil ağır zırh) ─────────────────────────────────────────────
# ── MECH (altın/yeşil ağır zırh, yeniden tasarlandı) ──────────────────────────
func _draw_mech():
	var pulse = sin(time * 2.0) * 0.5 + 0.5
	var fast_pulse = sin(time * 7.0) * 0.5 + 0.5
	var armor_glow = 0.06 + pull_intensity * 0.3 + pulse * 0.05
	var glow_size = 24 + pull_intensity * 14
	var gold = Color(0.85, 0.65, 0.0)
	var light_gold = Color(1.0, 0.88, 0.3)
	var green = Color(0.22, 0.4, 0.16)
	var dark_green = Color(0.12, 0.24, 0.08)

	# Aura
	draw_circle(Vector2(0, -4), glow_size + 5, Color(0.3, 0.8, 0.1, armor_glow * 0.4))
	draw_circle(Vector2(0, -4), glow_size, Color(0.5, 1.0, 0.1, armor_glow))

	if pull_intensity > 0.3:
		for i in 8:
			var angle = time * 3.5 + i * TAU / 8.0
			var spark_r = glow_size + 8 + sin(time * 9 + i) * 5
			var sx = cos(angle) * spark_r
			var sy = sin(angle) * spark_r - 4
			var a = pull_intensity * (0.5 + sin(time * 8 + i) * 0.3)
			draw_circle(Vector2(sx, sy), 2.0 + pull_intensity, Color(0.6, 1.0, 0.1, a))
			draw_line(Vector2(sx * 0.6, sy * 0.6), Vector2(sx, sy), Color(0.5, 0.9, 0.0, a * 0.7), 1.5)

	# ── Bacaklar (ağır) ──
	_rrect(Vector2(-10, 8), Vector2(8, 12), 2.0, dark_green)
	_rrect(Vector2(2, 8), Vector2(8, 12), 2.0, dark_green)
	_rrect(Vector2(-10, 8), Vector2(2.5, 9), 1.0, Color(gold.r, gold.g, gold.b, 0.35))
	_rrect(Vector2(2, 8), Vector2(2.5, 9), 1.0, Color(gold.r, gold.g, gold.b, 0.35))
	_rrect(Vector2(-12, 17), Vector2(10, 8), 3.0, green)
	_rrect(Vector2(2, 17), Vector2(10, 8), 3.0, green)
	_rrect(Vector2(-12, 17), Vector2(10, 2.5), 1.5, gold)
	_rrect(Vector2(2, 17), Vector2(10, 2.5), 1.5, gold)

	# ── Gövde (masif) ──
	var torso_pts = PackedVector2Array([
		Vector2(-15, -10), Vector2(15, -10),
		Vector2(12, 4), Vector2(9, 12),
		Vector2(-9, 12), Vector2(-12, 4),
	])
	draw_colored_polygon(torso_pts, green)
	_rrect(Vector2(-15, -10), Vector2(30, 4), 1.5, gold)
	_rrect(Vector2(-15, -10), Vector2(3, 15), 1.0, Color(light_gold.r, light_gold.g, light_gold.b, 0.25))

	# Çekirdek
	var core_intensity = 0.5 + pull_intensity * 0.5 + fast_pulse * 0.2
	draw_circle(Vector2(0, 2), 7, Color(0.2, 0.6, 0.0, core_intensity * 0.7))
	draw_circle(Vector2(0, 2), 5, Color(0.5, 1.0, 0.1, core_intensity * 0.9))
	draw_circle(Vector2(0, 2), 3, Color(1.0, 1.0, 0.5, core_intensity))
	draw_arc(Vector2(0, 2), 8.5, 0, TAU, 16, gold, 2.0)
	if pull_intensity > 0.1:
		draw_arc(Vector2(0, 2), 10.5 + pull_intensity * 4, time * 2.0, time * 2.0 + TAU * 0.75, 16, Color(0.5, 1.0, 0.1, pull_intensity * 0.6), 2.5)

	# ── Omuzlar ──
	draw_circle(Vector2(-15, -8), 7.0, dark_green)
	draw_circle(Vector2(-15, -9), 5.0, green)
	draw_circle(Vector2(-15, -9), 2.0, gold)
	draw_circle(Vector2(15, -8), 7.0, dark_green)
	draw_circle(Vector2(15, -9), 5.0, green)
	draw_circle(Vector2(15, -9), 2.0, gold)

	# ── Kollar (geniş) ──
	_rrect(Vector2(-23, -7), Vector2(9, 16), 3.0, green)
	_rrect(Vector2(14, -7), Vector2(9, 16), 3.0, green)
	_rrect(Vector2(-23, -7), Vector2(3, 13), 1.2, Color(gold.r, gold.g, gold.b, 0.3))
	_rrect(Vector2(14, -7), Vector2(3, 13), 1.2, Color(gold.r, gold.g, gold.b, 0.3))
	draw_circle(Vector2(-18.5, 11), 5.0, dark_green)
	draw_circle(Vector2(18.5, 11), 5.0, dark_green)
	draw_circle(Vector2(-18.5, 11), 2.6, gold)
	draw_circle(Vector2(18.5, 11), 2.6, gold)

	# ── Kafa ──
	_rrect(Vector2(-11, -27), Vector2(22, 19), 4.0, dark_green)
	_rrect(Vector2(-11, -27), Vector2(22, 6), 3.0, green)
	_rrect(Vector2(-11, -27), Vector2(22, 2), 1.5, light_gold)

	# Anten
	_rrect(Vector2(-1.5, -35), Vector2(3, 9), 1.5, green)
	var ant_speed = 2.0 + pull_intensity * 4.0
	var ant_size = 4.0 + pull_intensity * 3.0 + sin(time * ant_speed) * 1.2
	draw_circle(Vector2(0, -36), ant_size, Color(0.4, 1.0, 0.0, 0.95))
	draw_circle(Vector2(0, -36), ant_size * 0.5, Color(1.0, 1.0, 0.5, 0.95))
	if pull_intensity > 0.2:
		for i in 3:
			var ring_r = ant_size + 5 + i * 6 + sin(time * 5 + i) * 2
			draw_arc(Vector2(0, -36), ring_r, 0, TAU, 16, Color(0.4, 1.0, 0.0, pull_intensity * (0.45 - i * 0.12)), 1.8)

	# Vizör - geniş
	_rrect(Vector2(-9, -23), Vector2(18, 9), 3.0, Color(0.0, 0.05, 0.0, 0.95))
	var eye_glow = 0.8 + pull_intensity * 0.2 + sin(time * 3) * 0.1
	_rrect(Vector2(-7, -20), Vector2(14, 4), 2.0, Color(0.3, 1.0, 0.1, eye_glow * 0.6))
	draw_circle(Vector2(-4.5, -18), 3.6, Color(0.2, 1.0, 0.0, eye_glow))
	draw_circle(Vector2(-4.5, -18), 2.0, Color(0.8, 1.0, 0.3, 0.9))
	draw_circle(Vector2(4.5, -18), 3.6, Color(0.2, 1.0, 0.0, eye_glow))
	draw_circle(Vector2(4.5, -18), 2.0, Color(0.8, 1.0, 0.3, 0.9))
	if pull_intensity > 0.3:
		draw_circle(Vector2(-4.5, -18), 6.0, Color(0.2, 1.0, 0.0, pull_intensity * 0.25))
		draw_circle(Vector2(4.5, -18), 6.0, Color(0.2, 1.0, 0.0, pull_intensity * 0.25))

	draw_ellipse_approx(Vector2(0, 24), 16, 3, Color(0.0, 0.2, 0.0, 0.3 - pull_intensity * 0.1))
	
func draw_ellipse_approx(center: Vector2, rx: float, ry: float, color: Color):
	var pts = PackedVector2Array()
	for i in 16:
		var angle = TAU * i / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, color)

func _rrect(pos: Vector2, size: Vector2, radius: float, color: Color, segments: int = 3):
	var r = clamp(radius, 0.0, min(size.x, size.y) / 2.0)
	var x0 = pos.x
	var y0 = pos.y
	var x1 = pos.x + size.x
	var y1 = pos.y + size.y
	var pts = PackedVector2Array()
	var corners = [
		Vector2(x1 - r, y0 + r),
		Vector2(x1 - r, y1 - r),
		Vector2(x0 + r, y1 - r),
		Vector2(x0 + r, y0 + r),
	]
	var start_angles = [-PI / 2.0, 0.0, PI / 2.0, PI]
	for c in 4:
		var center = corners[c]
		var start_angle = start_angles[c]
		for i in range(segments + 1):
			var angle = start_angle + (PI / 2.0) * float(i) / float(segments)
			pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)
