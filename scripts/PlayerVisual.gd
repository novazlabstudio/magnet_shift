extends Node2D

var time: float = 0.0
var is_dead: bool = false
var is_pulled: bool = false
var pull_intensity: float = 0.0
var hero_id: int = 0  # 0=Cyborg, 1=Pink, 2=Shadow, 3=Mech, 4=Blaze, 5=Polaris
# Menü önizlemesi için: >= 0 ise seçili kahraman yerine bu çizilir
var preview_hero: int = -1

func _ready():
	hero_id = preview_hero if preview_hero >= 0 else HeroManager.get_hero()

# Ölüm animasyonu: kahraman kendi çizimiyle kalır, üstüne dönüşüm ve renk uygulanır
# (efektler kardeş düğüm DeathFX'te). Süre GameManager/Player ile eşleşmeli: Player.DEATH_TIME
var dying: bool = false
var death_t: float = 0.0
var death_cause: String = ""
const HERO_ACCENTS = [Color(0.0, 0.83, 1.0), Color(1.0, 0.4, 0.7), Color(0.6, 0.1, 0.9),
	Color(0.5, 1.0, 0.1), Color(1.0, 0.45, 0.05), Color(0.72, 0.42, 1.0)]

func accent_color() -> Color:
	return HERO_ACCENTS[clamp(hero_id, 0, HERO_ACCENTS.size() - 1)]

func play_death(cause: String) -> void:
	dying = true
	death_t = 0.0
	death_cause = cause
	z_index = 5

func _process(delta):
	time += delta
	if dying:
		death_t += delta
		modulate = _death_modulate()
		queue_redraw()
		return
	var player = get_parent()
	if player and "active_magnet" in player:
		var has_magnet = player.active_magnet != null
		pull_intensity = move_toward(pull_intensity, 1.0 if has_magnet else 0.0, delta * 3.0)
		is_pulled = has_magnet
	queue_redraw()

func set_dead(dead: bool):
	is_dead = dead
	if dead and not dying:
		play_death("")

func _ease(x: float) -> float:
	x = clamp(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _death_modulate() -> Color:
	var t = death_t
	if death_cause == "laser":
		if t < 0.05:
			return Color(3.0, 3.0, 3.2)
		if t < 0.55:
			# elektrik: normal ile parlak mavi arasında hızlı titreşim
			return Color(0.55, 1.45, 2.1) if int(t * 30.0) % 2 == 0 else Color(1.1, 1.15, 1.25)
		var charred = Color(0.2, 0.14, 0.12)
		var c = Color(1.0, 1.0, 1.0).lerp(charred, _ease((t - 0.55) / 0.3))
		c.a = 1.0 - _ease((t - 0.88) / 0.3)
		return c
	# bekçi: beyaz darbe parlaması -> kırmızı -> normal -> parçalanırken sönme
	if t < 0.06:
		return Color(2.6, 2.6, 2.6)
	var c2 = Color(1.7, 0.45, 0.45).lerp(Color(1, 1, 1), _ease((t - 0.06) / 0.4))
	c2.a = 1.0 - _ease((t - 0.78) / 0.2)
	return c2

func _draw():
	if dying:
		draw_set_transform_matrix(_current_death_xform())
	_draw_hero()

func _current_death_xform() -> Transform2D:
	var t = death_t
	var off = Vector2.ZERO
	var rot = 0.0
	var sc = Vector2.ONE
	if death_cause == "laser":
		var shake = 2.8 * (1.0 - _ease(t / 0.6))
		off = Vector2(sin(t * 97.0) * shake, cos(t * 83.0) * shake * 0.6)
		var k = _ease((t - 0.5) / 0.35)
		rot = 0.42 * k
		off += Vector2(3.0 * k, 5.0 * k)
		sc = Vector2(1.0 + 0.04 * k, 1.0 - 0.12 * k)
	else:
		# darbeyle havaya fırlayıp bir tur dönerek yere yan yatar
		var u = _ease(t / 0.55)
		off = Vector2(14.0 * u, -30.0 * sin(PI * min(t / 0.55, 1.0)))
		rot = (TAU + PI * 0.5) * u
		var sq = sin(PI * clamp(t / 0.12, 0.0, 1.0)) * 0.25
		sc = Vector2(1.0 + sq, 1.0 - sq)
	# Gövde merkezi (0,-6) etrafında döndür/ölçekle
	var pivot = Vector2(0, -6)
	return Transform2D(0, pivot + off) * Transform2D(rot, sc, 0, Vector2.ZERO) * Transform2D(0, -pivot)

func _draw_hero():
	match hero_id:
		0: _draw_cyborg()
		1: _draw_pink()
		2: _draw_shadow()
		3: _draw_mech()
		4: _draw_blaze()
		5: _draw_polaris()
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
	
# ── BLAZE (kızıl zırh, alev tepelik; 3 reklamla açılır) ───────────────────────
func _draw_blaze():
	var pulse = sin(time * 3.0) * 0.5 + 0.5
	var flicker = sin(time * 13.0) * 0.5 + 0.5
	var glow_size = 22 + pull_intensity * 12
	var heat = 0.08 + pull_intensity * 0.28 + pulse * 0.05
	var crimson = Color(0.62, 0.1, 0.08)
	var dark = Color(0.26, 0.05, 0.05)
	var orange = Color(1.0, 0.45, 0.05)
	var yellow = Color(1.0, 0.88, 0.3)

	# Aura
	draw_circle(Vector2(0, -4), glow_size + 5, Color(1.0, 0.3, 0.0, heat * 0.4))
	draw_circle(Vector2(0, -4), glow_size, Color(1.0, 0.55, 0.1, heat))

	# Yukarı süzülen korlar (çekilirken çoğalır)
	var ember_count = 5 + int(pull_intensity * 5)
	for i in ember_count:
		var phase = fmod(time * (0.8 + i * 0.13) + i * 0.37, 1.0)
		var ex = sin(i * 2.3 + time * 2.0) * (10 + (i % 3) * 4)
		var ey = 10 - phase * 46
		var ea = (1.0 - phase) * (0.45 + pull_intensity * 0.45)
		draw_circle(Vector2(ex, ey), 1.6 * (1.0 - phase) + 0.6, Color(1.0, 0.55 + 0.4 * (1.0 - phase), 0.1, ea))

	# Ayak jetleri
	var jet = 4 + pull_intensity * 9 + flicker * 3
	for fx in [-6.5, 6.5]:
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 4, 24), Vector2(fx + 4, 24), Vector2(fx, 24 + jet)]), Color(1.0, 0.45, 0.0, 0.85))
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 2, 24), Vector2(fx + 2, 24), Vector2(fx, 24 + jet * 0.6)]), Color(1.0, 0.95, 0.5, 0.95))

	# ── Bacaklar ──
	_rrect(Vector2(-9, 8), Vector2(6, 12), 2.0, dark)
	_rrect(Vector2(3, 8), Vector2(6, 12), 2.0, dark)
	_rrect(Vector2(-11, 17), Vector2(9, 7), 2.5, crimson)
	_rrect(Vector2(2, 17), Vector2(9, 7), 2.5, crimson)
	_rrect(Vector2(-11, 21.5), Vector2(9, 2.5), 1.0, orange)
	_rrect(Vector2(2, 21.5), Vector2(9, 2.5), 1.0, orange)

	# ── Gövde ──
	var torso_pts = PackedVector2Array([
		Vector2(-13, -9), Vector2(13, -9),
		Vector2(11, 3), Vector2(8, 11),
		Vector2(-8, 11), Vector2(-11, 3),
	])
	draw_colored_polygon(torso_pts, crimson)
	_rrect(Vector2(-13, -9), Vector2(26, 3), 1.5, Color(orange.r, orange.g, orange.b, 0.8))
	draw_line(Vector2(-10, -6), Vector2(0, 4), Color(orange.r, orange.g, orange.b, 0.7), 2.0)
	draw_line(Vector2(10, -6), Vector2(0, 4), Color(orange.r, orange.g, orange.b, 0.7), 2.0)

	# Çekirdek: küçük alev
	var core = 0.6 + pull_intensity * 0.4 + flicker * 0.2
	draw_circle(Vector2(0, 4), 6.5, Color(1.0, 0.3, 0.0, core * 0.5))
	_flame(Vector2(0, 8), 4.5, 10.0 + flicker * 2.0, Color(1.0, 0.5, 0.05, min(core, 1.0)))
	_flame(Vector2(0, 8), 2.5, 6.0 + flicker * 1.5, Color(1.0, 0.95, 0.55, min(core, 1.0)))

	# ── Omuzlar (alev uçlu) ──
	for sx in [-14.0, 14.0]:
		draw_circle(Vector2(sx, -8), 6.5, dark)
		draw_circle(Vector2(sx, -9), 4.8, crimson)
		var tip = 4.0 + flicker * 2.0 + pull_intensity * 3.0
		_flame(Vector2(sx, -12), 3.0, tip, orange)

	# ── Kollar ──
	_rrect(Vector2(-21, -6), Vector2(7, 15), 3.0, crimson)
	_rrect(Vector2(14, -6), Vector2(7, 15), 3.0, crimson)
	draw_circle(Vector2(-17.5, 11), 4.5, dark)
	draw_circle(Vector2(17.5, 11), 4.5, dark)
	draw_circle(Vector2(-17.5, 11), 2.2, orange)
	draw_circle(Vector2(17.5, 11), 2.2, orange)

	# ── Kafa ──
	_rrect(Vector2(-10, -26), Vector2(20, 18), 4.0, dark)
	_rrect(Vector2(-10, -26), Vector2(20, 6), 3.0, crimson)

	# Alev tepelik (anten yerine)
	var crest = 1.0 + pull_intensity * 0.6
	for k in 3:
		var kx = -5.0 + k * 5.0
		var kh = (8.0 + sin(time * 9.0 + k * 1.7) * 2.5 + (3.0 if k == 1 else 0.0)) * crest
		_flame(Vector2(kx, -25), 3.2, kh, Color(1.0, 0.4, 0.0, 0.95))
		_flame(Vector2(kx, -25), 1.6, kh * 0.6, Color(1.0, 0.9, 0.4, 0.95))

	# Vizör: çekik, sarı gözler
	_rrect(Vector2(-8, -22), Vector2(16, 8), 3.0, Color(0.06, 0.0, 0.0, 0.95))
	var eye = 0.8 + pull_intensity * 0.2 + sin(time * 3) * 0.1
	draw_line(Vector2(-6.5, -20), Vector2(-1.5, -17.5), Color(yellow.r, yellow.g, yellow.b, eye), 2.6)
	draw_line(Vector2(6.5, -20), Vector2(1.5, -17.5), Color(yellow.r, yellow.g, yellow.b, eye), 2.6)
	if pull_intensity > 0.3:
		draw_circle(Vector2(-4, -18.5), 5.5, Color(1.0, 0.6, 0.0, pull_intensity * 0.25))
		draw_circle(Vector2(4, -18.5), 5.5, Color(1.0, 0.6, 0.0, pull_intensity * 0.25))

	draw_ellipse_approx(Vector2(0, 24), 14, 3, Color(0.2, 0.05, 0.0, 0.3 - pull_intensity * 0.1))

# Tabanı base'de, ucu yukarıda damla biçimli alev
func _flame(base: Vector2, half_w: float, h: float, color: Color):
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-half_w, 0),
		base + Vector2(-half_w * 0.6, -h * 0.5),
		base + Vector2(0, -h),
		base + Vector2(half_w * 0.6, -h * 0.5),
		base + Vector2(half_w, 0),
		base + Vector2(0, half_w * 0.5),
	]), color)

# ── POLARIS (manyetik alanın kendisi: kutuplara bölünmüş, havada süzülen android) ──
# Omuzları başını çevreleyen bir at nalı mıknatıs (uçlarda N kırmızı / S mavi başlık),
# göğsünde oyuncunun tuttuğu mıknatısa dönen pusula, gövdeden ayrık süzülen eldivenler,
# yörüngede dönen minik mıknatıslar ve dalgalanan alan çizgisi pelerini. Bacakları yok;
# altındaki alan halkalarıyla süzülür. Not: burada draw_set_transform kullanılmaz (ölüm
# animasyonunun dönüşümünü bozmasın diye); elipsler noktalarla çizilir.
func _draw_polaris():
	var pulse = sin(time * 2.2) * 0.5 + 0.5
	var p = pull_intensity
	var north = Color(0.9, 0.18, 0.26)
	var north_dark = Color(0.5, 0.07, 0.13)
	var south = Color(0.22, 0.45, 1.0)
	var south_dark = Color(0.08, 0.17, 0.52)
	var silver = Color(0.84, 0.87, 0.94)
	var silver_dark = Color(0.48, 0.51, 0.62)
	var violet = Color(0.72, 0.42, 1.0)
	var hover = sin(time * 2.6) * 1.6
	var o = Vector2(0, hover)

	# Aura
	var glow_size = 23 + p * 13
	draw_circle(o + Vector2(0, -6), glow_size + 5, Color(violet.r, violet.g, violet.b, (0.05 + p * 0.12) * 0.6))
	draw_circle(o + Vector2(0, -6), glow_size, Color(violet.r, violet.g, violet.b, 0.06 + p * 0.2 + pulse * 0.04))

	# Alan çizgisi pelerini (arkada): omuzlardan aşağı dalgalanır, çekilince gerilir
	for i in 5:
		var side = -1.0 if i < 2 else (1.0 if i > 2 else 0.0)
		var start = o + Vector2(side * 11.0, -8.0)
		var spread = (i - 2) * 6.5
		var pts = PackedVector2Array()
		var cols = PackedColorArray()
		for j in 9:
			var k = j / 8.0
			var wave = sin(time * 4.0 + i * 1.3 + k * 5.0) * (4.0 - p * 2.5) * k
			pts.append(start + Vector2(spread * k * 1.6 + wave, k * (30.0 - p * 6.0)))
			cols.append(north.lerp(violet, k).lerp(south, clamp((i - 1) / 3.0, 0.0, 1.0) * k) * Color(1, 1, 1, 0.75 * (1.0 - k * 0.7)))
		draw_polyline_colors(pts, cols, 1.6, true)

	# Yörüngedeki mıknatıs parçaları: arkadakiler
	var shards = []
	for i in 3:
		var a = time * (1.5 + p * 2.0) + i * TAU / 3.0
		shards.append({"a": a, "pos": o + Vector2(cos(a) * 27.0, -5.0 + sin(a) * 8.0), "front": sin(a) > 0.0})
	for sh in shards:
		if not sh.front:
			_mini_magnet(sh.pos, 3.2, sh.a * 0.5, 0.5)

	# Süzülme alanı: aşağı akan halkalar + demir tozu
	for i in 3:
		var ph = fmod(time * (0.9 + p) + i / 3.0, 1.0)
		var ry = 2.5 + ph * 3.0
		var rx = 8.0 + ph * 11.0
		var ring_a = (1.0 - ph) * (0.45 + p * 0.4)
		_ellipse_ring(o + Vector2(0, 15.0 + ph * 12.0), rx, ry, Color(violet.r, violet.g, violet.b, ring_a), 1.4)
	for i in 6:
		var dk = fmod(time * 0.8 + i * 0.37, 1.0)
		draw_circle(o + Vector2(sin(i * 2.1) * 9.0, 12.0 + dk * 18.0), 0.9, Color(0.75, 0.78, 0.9, 0.7 * (1.0 - dk)))

	# Enerji kuyruğu (bacak yerine)
	draw_polygon(PackedVector2Array([o + Vector2(-9, 7), o + Vector2(9, 7), o + Vector2(0, 23 + p * 3.0)]),
		PackedColorArray([Color(violet.r, violet.g, violet.b, 0.95), Color(violet.r, violet.g, violet.b, 0.95), Color(1, 1, 1, 0.0)]))
	draw_polygon(PackedVector2Array([o + Vector2(-4, 7), o + Vector2(4, 7), o + Vector2(0, 17 + p * 3.0)]),
		PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.0)]))

	# Gövde: sol yarı kuzey (kırmızı), sağ yarı güney (mavi), ortada gümüş omurga
	draw_colored_polygon(PackedVector2Array([o + Vector2(-12, -9), o + Vector2(0, -9), o + Vector2(0, 9), o + Vector2(-7, 9), o + Vector2(-11, 2)]), north)
	draw_colored_polygon(PackedVector2Array([o + Vector2(0, -9), o + Vector2(12, -9), o + Vector2(11, 2), o + Vector2(7, 9), o + Vector2(0, 9)]), south)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-12, -9), o + Vector2(-9, -9), o + Vector2(-9.5, 3), o + Vector2(-11, 2)]), north_dark)
	draw_colored_polygon(PackedVector2Array([o + Vector2(9, -9), o + Vector2(12, -9), o + Vector2(11, 2), o + Vector2(9.5, 3)]), south_dark)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-1.6, -9), o + Vector2(1.6, -9), o + Vector2(1.2, 9), o + Vector2(-1.2, 9)]), silver)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-8, 6), o + Vector2(8, 6), o + Vector2(7, 9), o + Vector2(-7, 9)]), silver_dark)

	# Pusula çekirdeği: iğne tutulan mıknatısa döner, yoksa hafifçe salınır
	var needle_ang = -PI / 2 + sin(time * 1.3) * 0.5
	var pl = get_parent()
	if pl and "active_magnet" in pl and pl.active_magnet and is_instance_valid(pl.active_magnet):
		needle_ang = (pl.active_magnet.global_position - pl.global_position).angle()
	var cc = o + Vector2(0, -1)
	draw_circle(cc, 6.2, Color(0.05, 0.06, 0.16))
	draw_arc(cc, 6.2, 0.0, TAU, 20, silver, 1.4, true)
	for t in 4:
		var ta = t * PI / 2
		draw_line(cc + Vector2(cos(ta), sin(ta)) * 4.6, cc + Vector2(cos(ta), sin(ta)) * 5.6, Color(silver.r, silver.g, silver.b, 0.7), 1.0)
	var nd = Vector2(cos(needle_ang), sin(needle_ang))
	var nn = nd.orthogonal() * 1.6
	draw_colored_polygon(PackedVector2Array([cc + nn, cc + nd * 5.0, cc - nn]), north.lightened(0.2))
	draw_colored_polygon(PackedVector2Array([cc - nn, cc - nd * 4.0, cc + nn]), Color(0.9, 0.92, 1.0))
	draw_circle(cc, 1.1, silver)
	if p > 0.2:
		draw_circle(cc, 8.0, Color(violet.r, violet.g, violet.b, p * 0.25))

	# Süzülen eldivenler ve onları omuza bağlayan alan çizgileri
	for side in [-1.0, 1.0]:
		var hand = o + Vector2(side * 20.0, 3.0 + sin(time * 2.0 + side) * 2.2 - p * 3.0)
		var col = north if side < 0 else south
		var arc = PackedVector2Array()
		for j in 7:
			var k = j / 6.0
			arc.append((o + Vector2(side * 13.0, -6.0)).lerp(hand, k) + Vector2(side * sin(k * PI) * 4.0, 0))
		draw_polyline(arc, Color(violet.r, violet.g, violet.b, 0.35 + p * 0.3), 1.0, true)
		draw_circle(hand, 6.0, Color(col.r, col.g, col.b, 0.18 + p * 0.2))
		draw_circle(hand, 4.4, silver_dark)
		draw_circle(hand + Vector2(-0.8, -0.8), 3.4, silver)
		draw_circle(hand + Vector2(side * 0.6, 0.6), 1.8, col)
		for f in 3:
			draw_circle(hand + Vector2(side * 3.6, -2.6 + f * 2.4), 1.2, silver_dark)

	# At nalı omuzlar: başın iki yanından yükselen mıknatıs kolları + kutup başlıkları
	var collar = PackedVector2Array()
	for j in 13:
		var a2 = PI * j / 12.0
		collar.append(o + Vector2(0, -12) + Vector2(cos(a2) * 12.5, sin(a2) * 4.0))
	draw_polyline(collar, silver, 4.0, true)
	for side in [-1.0, 1.0]:
		var col2 = north if side < 0 else south
		var dark2 = north_dark if side < 0 else south_dark
		var arm = PackedVector2Array()
		for j in 9:
			var k = j / 8.0
			arm.append(o + Vector2(side * (12.5 + sin(k * PI) * 2.0), -10.0 - k * 19.0))
		draw_polyline(arm, dark2, 8.0, true)
		draw_polyline(arm, col2, 5.5, true)
		var tip = arm[arm.size() - 1]
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-4.5, 1), tip + Vector2(4.5, 1), tip + Vector2(4.5, -4), tip + Vector2(-4.5, -4)]), silver)
		var cap_glow = 0.55 + pulse * 0.3 + p * 0.4
		draw_circle(tip + Vector2(0, -6), 3.2, Color(col2.r, col2.g, col2.b, 0.25 * cap_glow))
		draw_circle(tip + Vector2(0, -6), 1.8, col2.lightened(0.35))

	# Kafa: gümüş oval kask, mor vizör, yanıp sönen göz parıltıları, küçük tepe
	draw_ellipse_approx(o + Vector2(0, -20), 8.8, 9.6, silver_dark)
	draw_ellipse_approx(o + Vector2(-0.6, -20.6), 8.0, 8.8, silver)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-2, -29), o + Vector2(2, -29), o + Vector2(0, -34.5)]), silver)
	draw_circle(o + Vector2(0, -30), 1.3, violet.lightened(0.3))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-7.5, -22.5), o + Vector2(7.5, -22.5), o + Vector2(6, -16.5), o + Vector2(-6, -16.5)]), Color(0.06, 0.04, 0.16))
	var eye = 0.75 + 0.25 * sin(time * 3.0) + p * 0.2
	var blink = 1.0 if fmod(time, 3.7) > 0.12 else 0.15
	draw_line(o + Vector2(-6, -19.5), o + Vector2(6, -19.5), Color(violet.r, violet.g, violet.b, 0.45 * eye), 3.0)
	draw_circle(o + Vector2(-3.2, -19.6), 1.6 * blink, Color(1, 0.95, 1, eye))
	draw_circle(o + Vector2(3.2, -19.6), 1.6 * blink, Color(1, 0.95, 1, eye))
	draw_line(o + Vector2(-5.5, -23.5), o + Vector2(-1, -25.5), Color(1, 1, 1, 0.55), 1.0)

	# Yörüngedeki mıknatıs parçaları: öndekiler
	for sh in shards:
		if sh.front:
			_mini_magnet(sh.pos, 3.6, sh.a * 0.5, 1.0)

	# Zemin gölgesi
	draw_ellipse_approx(Vector2(0, 27), 12.0 - hover, 2.6, Color(0.1, 0.0, 0.2, 0.22 - p * 0.08))

func _mini_magnet(c: Vector2, s: float, rot: float, alpha: float) -> void:
	var u = PackedVector2Array()
	for j in 9:
		var a = rot + PI * j / 8.0
		u.append(c + Vector2(cos(a), sin(a)) * s)
	draw_polyline(u, Color(0.8, 0.82, 0.9, alpha), 2.2, true)
	var d = Vector2(cos(rot), sin(rot))
	var back = d.orthogonal() * -s * 0.9
	draw_line(u[0], u[0] + back, Color(0.95, 0.25, 0.3, alpha), 2.2)
	draw_line(u[8], u[8] + back, Color(0.3, 0.5, 1.0, alpha), 2.2)

func _ellipse_ring(c: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
	var pts = PackedVector2Array()
	for j in 25:
		var a = TAU * j / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, w, true)

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
