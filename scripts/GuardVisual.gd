class_name GuardVisual
extends Node2D

# Bekçi görselleri: her 5 level'de bir yeni bekçi (guard'lar Level 6'da başlar).
# Oyuncu ilerledikçe düşmanların "geliştiğini" görsün diye her kademe farklı bir tasarım:
#   0 RUSTY (6-10)  1 VOLT (11-15)  2 TOXIC (16-20)  3 CYCLOPS (21-25)  4 MAGMA (26-30)
#   5 FROST (31-35) 6 PHANTOM (36-40) 7 TITAN (41-45) 8 OVERLORD (46-50)
# Çarpışma kutusu herkes için aynı (Guard.gd / GameManager): görsel ayak hizası y=+22, gövde ~±16 px.
# Hepsi sağa bakar şekilde çizilir; yön, çizim dönüşümüyle (x ölçeği = direction) çevrilir.
# Aynı level'deki tek sıralı bekçiler "alt" renk varyantını kullanır (klon gibi görünmesinler).

const TIERS := [
	{"name": "RUSTY", "title": "SCRAP BRAWLER", "color": Color(1.0, 0.35, 0.15)},
	{"name": "VOLT", "title": "TESLA SENTRY", "color": Color(0.3, 0.9, 1.0)},
	{"name": "TOXIC", "title": "HAZMAT CRUSHER", "color": Color(0.55, 1.0, 0.25)},
	{"name": "CYCLOPS", "title": "HOVER EYE", "color": Color(1.0, 0.3, 0.75)},
	{"name": "MAGMA", "title": "LAVA GOLEM", "color": Color(1.0, 0.55, 0.1)},
	{"name": "FROST", "title": "ICE KNIGHT", "color": Color(0.5, 0.95, 1.0)},
	{"name": "PHANTOM", "title": "SHADOW NINJA", "color": Color(1.0, 0.25, 0.8)},
	{"name": "TITAN", "title": "GOLDEN WARDEN", "color": Color(1.0, 0.82, 0.3)},
	{"name": "OVERLORD", "title": "VOID EMPEROR", "color": Color(0.7, 0.4, 1.0)},
]
const FIRST_GUARD_LEVEL := 6
const LEVELS_PER_TIER := 5

static func tier_for_level(level: int) -> int:
	return clampi((level - FIRST_GUARD_LEVEL) / LEVELS_PER_TIER, 0, TIERS.size() - 1)

static func is_tier_debut(level: int) -> bool:
	return level >= FIRST_GUARD_LEVEL and (level - FIRST_GUARD_LEVEL) % LEVELS_PER_TIER == 0

var time: float = 0.0
var is_dead: bool = false
var direction: int = 1
var walk_time: float = 0.0
var guard_type: int = 0
var alt: bool = false
var preview: bool = false  # UI'daki tanıtım kartında: yerinde yürür
var _parts: Array = []      # buhar / kıvılcım / kor / kar parçacıkları
var _spawn_acc: float = 0.0
var _arc_pts: PackedVector2Array = PackedVector2Array()
var _arc_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = int(get_instance_id())
	time = _rng.randf() * 10.0

func set_direction(dir: int) -> void:
	direction = dir

func set_walk(t: float, dir: int) -> void:
	walk_time = t
	direction = dir

func set_type(t: int, alternate: bool = false) -> void:
	guard_type = clampi(t, 0, TIERS.size() - 1)
	alt = alternate
	_parts.clear()

var _redraw_acc: float = 0.0
const REDRAW_DT := 1.0 / 30.0  # iç animasyon 30 kare/sn yeter; gövdenin yürüyüşü yine her karede akıcı

func _process(delta: float) -> void:
	time += delta
	if preview:
		walk_time += delta
		_update_parts(delta)
		queue_redraw()
		return
	_redraw_acc += delta
	if _redraw_acc < REDRAW_DT:
		return
	var dt = _redraw_acc
	_redraw_acc = 0.0
	# Ekran dışındaysa çizimi yenileme (uzun level'lerde bekçilerin çoğu görünmez)
	var vp = get_viewport()
	if vp:
		var p = get_global_transform_with_canvas().origin
		if not vp.get_visible_rect().grow(70.0).has_point(p):
			return
	_update_parts(dt)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1))
	match guard_type:
		0: _g_rusty()
		1: _g_volt()
		2: _g_toxic()
		3: _g_cyclops()
		4: _g_magma()
		5: _g_frost()
		6: _g_phantom()
		7: _g_titan()
		_: _g_overlord()
	_draw_parts()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ═════════════════════════════════════════════════════════════════════════════
# Yardımcılar
# ═════════════════════════════════════════════════════════════════════════════
func _rr_pts(r: Rect2, rad: float, seg: int = 2) -> PackedVector2Array:
	rad = min(rad, min(r.size.x, r.size.y) * 0.5)
	var pts = PackedVector2Array()
	var cs = [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in 4:
		for i in seg + 1:
			var a = -PI / 2.0 + k * PI / 2.0 + (PI / 2.0) * i / seg
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return pts

func _rr(r: Rect2, rad: float, col: Color) -> void:
	draw_colored_polygon(_rr_pts(r, rad), col)

# Dikey degradeli yuvarlak dikdörtgen (üst aydınlık, alt gölgeli)
func _rrg(r: Rect2, rad: float, top: Color, bot: Color) -> void:
	_pg(_rr_pts(r, rad), top, bot)

# Dikey degradeli çokgen
func _pg(pts: PackedVector2Array, top: Color, bot: Color) -> void:
	var y0 = INF
	var y1 = -INF
	for p in pts:
		y0 = min(y0, p.y)
		y1 = max(y1, p.y)
	var span = max(0.001, y1 - y0)
	var cols = PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bot, (p.y - y0) / span))
	draw_polygon(pts, cols)

func _ell_pts(c: Vector2, rx: float, ry: float, n: int = 16) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _ell(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_colored_polygon(_ell_pts(c, rx, ry), col)

# Yumuşak parıltı: azalan yarıçaplı, düşük alfalı halkalar üst üste (kenarı sert daire gibi görünmez)
const GLOW_STEPS := [1.0, 0.76, 0.54, 0.34, 0.2]
func _glow(c: Vector2, r: float, col: Color, k: float = 1.0) -> void:
	var a = 0.055 * k
	for f in GLOW_STEPS:
		draw_circle(c, r * f, Color(col.r, col.g, col.b, a))

func _limb(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	draw_line(a, b, col, w)
	draw_circle(a, w * 0.5, col)
	draw_circle(b, w * 0.5, col)

func _shadow(rx: float, alpha: float = 0.32) -> void:
	_ell(Vector2(0, 21.5), rx, 3.6, Color(0, 0, 0, alpha))

func _eye(c: Vector2, r: float, col: Color, glow: float, core: Color = Color(1, 1, 1)) -> void:
	draw_circle(c, r + 1.2, Color(0.05, 0.02, 0.04))
	draw_circle(c, r, Color(col.r, col.g, col.b, 0.75 + 0.25 * glow))
	draw_circle(c, r * 0.45, Color(core.r, core.g, core.b, 0.9))
	_glow(c, r * 3.2, col, glow)

# Adım döngüsü: iki bacak için ayak konumu (x ileri-geri, havadayken yukarı)
func _foot(phase: float, hip_x: float, stride: float, lift: float) -> Vector2:
	return Vector2(hip_x + cos(phase) * stride, 21.0 - max(0.0, sin(phase)) * lift)

func _step() -> float:
	return walk_time * 8.5

func _bob() -> float:
	return abs(sin(_step())) * 1.4

# İki bacak: kalça -> diz -> ayak (diz öne kırılır)
func _legs(hip_y: float, spread: float, thick: float, col_back: Color, col_front: Color, foot_col: Color, foot_w: float, stride: float = 5.0) -> void:
	var ph = _step()
	for i in 2:
		var hip = Vector2((-spread if i == 0 else spread) * 0.5, hip_y)
		var f = _foot(ph + (PI if i == 0 else 0.0), hip.x, stride, 4.0)
		var knee = (hip + f) * 0.5 + Vector2(2.5, -1.0)
		var c = col_back if i == 0 else col_front
		_limb(hip, knee, thick, c)
		_limb(knee, f + Vector2(0, -2), thick * 0.85, c)
		draw_circle(knee, thick * 0.42, c.lightened(0.18))
		_rr(Rect2(f.x - foot_w * 0.4, f.y - 3.5, foot_w, 4.5), 2.0, foot_col)

# ── Parçacıklar ─────────────────────────────────────────────────────────────
func _emit(p: Vector2, v: Vector2, life: float, size: float, col: Color, kind: int = 0) -> void:
	if _parts.size() > 18:
		return
	_parts.append({"p": p, "v": v, "life": life, "max": life, "s": size, "c": col, "k": kind})

func _update_parts(delta: float) -> void:
	_spawn_acc += delta
	match guard_type:
		0:  # egzozdan buhar
			if _spawn_acc > 0.22:
				_spawn_acc = 0.0
				_emit(Vector2(-14.5, -26), Vector2(_rng.randf_range(-6, -2), _rng.randf_range(-16, -10)), 0.9, 2.2, Color(0.9, 0.88, 0.86, 0.3))
		1:  # elektrik kıvılcımı
			if _spawn_acc > 0.12:
				_spawn_acc = 0.0
				if _rng.randf() < 0.5:
					_emit(Vector2(_rng.randf_range(-8, 8), -40), Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-20, 10)), 0.3, 1.0, Color(0.7, 1.0, 1.0), 1)
		2:  # tanktan kabarcık (tankın içinde çizilir) + egzoz dumanı
			if _spawn_acc > 0.35:
				_spawn_acc = 0.0
				_emit(Vector2(-16, -32), Vector2(_rng.randf_range(-5, 0), -12), 1.0, 2.0, Color(0.8, 1.0, 0.7, 0.22))
		4:  # yükselen korlar
			if _spawn_acc > 0.1:
				_spawn_acc = 0.0
				_emit(Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-30, -10)), Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-30, -18)), 0.8, 1.3, Color(1.0, 0.6, 0.15), 1)
		5:  # ağızdan buz nefesi
			if _spawn_acc > 0.5:
				_spawn_acc = 0.0
				_emit(Vector2(9, -22), Vector2(_rng.randf_range(10, 16), _rng.randf_range(-3, 3)), 0.9, 1.6, Color(0.85, 0.97, 1.0, 0.45))
		8:  # alttan yükselen karanlık sis
			if _spawn_acc > 0.12:
				_spawn_acc = 0.0
				_emit(Vector2(_rng.randf_range(-12, 12), 16), Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-10, -4)), 1.0, 2.6, Color(0.6, 0.35, 0.9, 0.16))
	var alive: Array = []
	for p in _parts:
		p["life"] -= delta
		if p["life"] <= 0.0:
			continue
		p["p"] += p["v"] * delta
		if p["k"] == 0:
			p["s"] += delta * 3.0
		alive.append(p)
	_parts = alive

func _draw_parts() -> void:
	for p in _parts:
		var k = p["life"] / p["max"]
		var c: Color = p["c"]
		if p["k"] == 1:
			draw_circle(p["p"], p["s"] * 2.4, Color(c.r, c.g, c.b, 0.25 * k))
			draw_circle(p["p"], p["s"], Color(1, 1, 0.9, k))
		else:
			draw_circle(p["p"], p["s"], Color(c.r, c.g, c.b, c.a * k))

# ═════════════════════════════════════════════════════════════════════════════
# 0 — RUSTY: hurda dövüşçü (klasik kırmızı bekçinin gelişmiş hâli)
# ═════════════════════════════════════════════════════════════════════════════
func _g_rusty() -> void:
	var base = Color(0.78, 0.26, 0.08)
	var dark = Color(0.38, 0.1, 0.03)
	var light = Color(1.0, 0.55, 0.25)
	var metal = Color(0.6, 0.55, 0.52)
	var eye = Color(1.0, 0.75, 0.1) if alt else Color(1.0, 0.15, 0.05)
	var glow = 0.65 + sin(time * 4.0) * 0.35
	var b = -_bob()
	var sw = sin(_step()) * 0.5
	_shadow(17)
	_legs(7, 11, 6.5, dark.darkened(0.2), dark, Color(0.22, 0.07, 0.02), 11)
	# egzoz borusu
	_rr(Rect2(-18, -24 + b, 6, 18), 2, metal.darkened(0.35))
	_rr(Rect2(-19, -27 + b, 8, 4), 1.5, metal)
	draw_rect(Rect2(-17, -20 + b, 4, 1.5), Color(0, 0, 0, 0.3))
	# arka kol
	var sh_b = Vector2(-9, -7 + b)
	var hand_b = sh_b + Vector2(sin(-sw) * 7.0, 14)
	_limb(sh_b, hand_b, 6, dark.darkened(0.15))
	draw_circle(hand_b, 4.2, Color(0.25, 0.08, 0.02))
	# gövde (aşağı doğru daralan zırh)
	var torso = PackedVector2Array([Vector2(-14, -12 + b), Vector2(14, -12 + b), Vector2(12, 9 + b), Vector2(-12, 9 + b)])
	_pg(torso, light.lerp(base, 0.4), dark)
	_rrg(Rect2(-9.5, -9 + b, 19, 13), 3, base.lightened(0.12), base.darkened(0.3))
	for rv in [Vector2(-8, -7.5), Vector2(8, -7.5), Vector2(-8, 2.5), Vector2(8, 2.5)]:
		draw_circle(rv + Vector2(0, b), 1.1, Color(1.0, 0.75, 0.45, 0.85))
	# uyarı üçgeni
	var tri = PackedVector2Array([Vector2(0, -7 + b), Vector2(5.5, 2 + b), Vector2(-5.5, 2 + b)])
	draw_colored_polygon(tri, Color(1.0, 0.82, 0.0))
	draw_line(Vector2(0, -4.5 + b), Vector2(0, -0.8 + b), Color(0.1, 0.05, 0.0), 1.5)
	draw_circle(Vector2(0, 0.6 + b), 0.8, Color(0.1, 0.05, 0.0))
	# kemer + toka
	_rr(Rect2(-12.5, 6 + b, 25, 4), 1, Color(0.2, 0.07, 0.02))
	_rr(Rect2(-2.5, 5.5 + b, 5, 5), 1, Color(1.0, 0.75, 0.2))
	# kafa
	var hy = -32 + b
	_rrg(Rect2(-11, hy, 24, 20), 4, light, base.darkened(0.15))
	draw_line(Vector2(-9, hy + 2), Vector2(10, hy + 2), Color(1, 0.8, 0.6, 0.45), 1.2)  # üst parlama
	draw_line(Vector2(-8, hy + 14), Vector2(-5, hy + 9), Color(0.3, 0.08, 0.02, 0.6), 1.0)  # çizik
	# boynuz/cıvatalar
	draw_colored_polygon(PackedVector2Array([Vector2(-8, hy), Vector2(-3.5, hy), Vector2(-9, hy - 9)]), metal)
	draw_colored_polygon(PackedVector2Array([Vector2(-5.5, hy), Vector2(-3.5, hy), Vector2(-9, hy - 9)]), metal.darkened(0.35))
	draw_colored_polygon(PackedVector2Array([Vector2(5, hy), Vector2(9.5, hy), Vector2(12, hy - 9)]), metal)
	draw_colored_polygon(PackedVector2Array([Vector2(7.5, hy), Vector2(9.5, hy), Vector2(12, hy - 9)]), metal.darkened(0.35))
	# öfkeli kaş
	draw_colored_polygon(PackedVector2Array([Vector2(-8, hy + 4), Vector2(12, hy + 5.5), Vector2(12, hy + 8), Vector2(-8, hy + 6.5)]), dark.darkened(0.3))
	_eye(Vector2(-2, hy + 10), 3.2, eye, glow, Color(1.0, 0.85, 0.4))
	_eye(Vector2(7, hy + 10), 3.2, eye, glow, Color(1.0, 0.85, 0.4))
	# dişli çene
	draw_rect(Rect2(-8, hy + 14.5, 19, 5), Color(0.12, 0.02, 0.0))
	for i in 5:
		draw_rect(Rect2(-7.2 + i * 3.7, hy + 14.5, 2.6, 3.4), Color(0.95, 0.92, 0.85))
	# ön omuz + kol + pençe
	_ell(Vector2(9, -9 + b), 5.5, 4.5, light.lerp(base, 0.3))
	var sh = Vector2(10, -7 + b)
	var hand = sh + Vector2(sin(sw) * 7.0 + 2, 14)
	_limb(sh, hand, 6, base)
	draw_circle(hand, 4.6, dark)
	for i in 3:
		var a = -0.5 + i * 0.5
		draw_line(hand + Vector2(cos(a) * 3, 2 + sin(a)), hand + Vector2(cos(a) * 6.5 + 1, 5 + sin(a) * 2), Color(0.9, 0.9, 0.85), 1.4)

# ═════════════════════════════════════════════════════════════════════════════
# 1 — VOLT: tesla nöbetçisi (kubbe kafa, iki bobin arasında ark)
# ═════════════════════════════════════════════════════════════════════════════
func _g_volt() -> void:
	var base = Color(0.24, 0.42, 0.75)
	var dark = Color(0.08, 0.15, 0.33)
	var light = Color(0.62, 0.8, 1.0)
	var en = Color(1.0, 0.9, 0.25) if alt else Color(0.35, 0.95, 1.0)
	var glow = 0.6 + sin(time * 6.0) * 0.4
	var b = -_bob()
	var sw = sin(_step()) * 0.5
	_shadow(16)
	_legs(7, 9, 5.0, dark, dark.lightened(0.1), Color(0.05, 0.08, 0.18), 10, 5.5)
	# arka kol
	var shb = Vector2(-9, -6 + b)
	_limb(shb, shb + Vector2(sin(-sw) * 7, 13), 4.5, dark)
	# gövde: kapsül
	_rrg(Rect2(-12, -13 + b, 24, 21), 7, light.lerp(base, 0.35), dark)
	draw_arc(Vector2(0, -2.5 + b), 10, PI * 1.15, PI * 1.85, 10, Color(1, 1, 1, 0.35), 1.2)
	# göğüs bobini
	var cc = Vector2(1, -3 + b)
	draw_circle(cc, 6.2, dark.darkened(0.3))
	draw_arc(cc, 5.2, 0, TAU, 18, Color(en.r, en.g, en.b, 0.9), 1.4)
	draw_arc(cc, 3.4, time * 6.0, time * 6.0 + PI * 1.3, 10, en.lightened(0.4), 1.2)
	draw_circle(cc, 1.8 + glow * 0.6, Color(1, 1, 1, 0.95))
	_glow(cc, 14, en, glow)
	# kemer çizgileri
	for i in 3:
		draw_line(Vector2(-10, 3.5 + i * 1.8 + b), Vector2(10, 3.5 + i * 1.8 + b), Color(0, 0, 0, 0.18), 0.8)
	# omuz
	_ell(Vector2(-10, -10 + b), 5, 4, base.lightened(0.15))
	_ell(Vector2(11, -10 + b), 5.5, 4.5, light.lerp(base, 0.4))
	# kubbe kafa
	var hc = Vector2(1, -23 + b)
	var dome = PackedVector2Array()
	for i in 13:
		var a = PI + PI * i / 12.0
		dome.append(hc + Vector2(cos(a) * 11.5, sin(a) * 10.5))
	dome.append(hc + Vector2(11.5, 6))
	dome.append(hc + Vector2(-11.5, 6))
	_pg(dome, light, base.darkened(0.2))
	draw_arc(hc + Vector2(-2, -1), 8, PI * 1.15, PI * 1.5, 8, Color(1, 1, 1, 0.55), 1.4)
	# vizör + tarayan nokta
	_rr(Rect2(hc.x - 3, hc.y - 1, 14, 5.5), 2.5, Color(0.02, 0.05, 0.12))
	var scan = hc.x + 1 + (sin(time * 3.0) * 0.5 + 0.5) * 8.0
	draw_rect(Rect2(hc.x - 2, hc.y + 0.6, 12, 2.2), Color(en.r, en.g, en.b, 0.35))
	draw_circle(Vector2(scan, hc.y + 1.7), 2.0, en.lightened(0.5))
	_glow(Vector2(scan, hc.y + 1.7), 9, en, glow)
	# tesla bobinleri + ark
	var t1 = Vector2(-6, -40 + b)
	var t2 = Vector2(7, -41 + b)
	for t in [t1, t2]:
		draw_line(t + Vector2(0, 9), t, Color(0.55, 0.6, 0.7), 2.0)
		for k in 3:
			draw_line(t + Vector2(-2, 3 + k * 2), t + Vector2(2, 3 + k * 2), Color(0.9, 0.55, 0.2), 1.0)
		draw_circle(t, 2.6, en.lightened(0.3))
		_glow(t, 9, en, glow)
	_arc_timer -= get_process_delta_time()
	if _arc_timer <= 0.0 or _arc_pts.size() == 0:
		_arc_timer = 0.06
		_arc_pts = PackedVector2Array()
		for i in 7:
			var k = i / 6.0
			var off = 0.0 if i == 0 or i == 6 else _rng.randf_range(-3.0, 3.0)
			_arc_pts.append(Vector2(lerp(t1.x, t2.x, k), lerp(t1.y, t2.y, k) - b + off - sin(k * PI) * 3.0))
	var arc = PackedVector2Array()
	for p in _arc_pts:
		arc.append(p + Vector2(0, b))
	draw_polyline(arc, Color(en.r, en.g, en.b, 0.35), 3.5)
	draw_polyline(arc, Color(1, 1, 1, 0.95), 1.2)
	# ön kol: çatal uçlu
	var sh = Vector2(11, -7 + b)
	var hand = sh + Vector2(sin(sw) * 7 + 2, 13)
	_limb(sh, hand, 4.5, base)
	draw_circle(hand, 3.0, dark)
	draw_line(hand, hand + Vector2(4, 4), Color(0.75, 0.8, 0.9), 1.6)
	draw_line(hand, hand + Vector2(-1, 5.5), Color(0.75, 0.8, 0.9), 1.6)
	if fmod(time, 0.9) < 0.12:
		draw_line(hand + Vector2(4, 4), hand + Vector2(-1, 5.5), Color(1, 1, 1, 0.9), 1.0)
		_glow(hand + Vector2(1.5, 5), 8, en, 1.0)

# ═════════════════════════════════════════════════════════════════════════════
# 2 — TOXIC: zehirli tanklı, paletli ezici
# ═════════════════════════════════════════════════════════════════════════════
func _g_toxic() -> void:
	var yel = Color(1.0, 0.76, 0.12)
	var yel_d = Color(0.62, 0.42, 0.04)
	var blk = Color(0.1, 0.1, 0.12)
	var tox = Color(0.95, 0.35, 1.0) if alt else Color(0.45, 1.0, 0.25)
	var glow = 0.6 + sin(time * 3.0) * 0.4
	var shake = sin(walk_time * 30.0) * 0.4
	_shadow(20, 0.38)
	# paletler
	_rr(Rect2(-18, 10, 36, 12), 6, Color(0.16, 0.16, 0.18))
	_rr(Rect2(-17, 11, 34, 10), 5, Color(0.26, 0.26, 0.28))
	var off = fposmod(walk_time * 26.0, 6.0)
	for i in 7:
		var x = -16.0 + i * 6.0 + off
		if x < 15.5:
			draw_rect(Rect2(x, 9.2, 3, 2), blk)
		var x2 = 15.0 - i * 6.0 - off
		if x2 > -16.5:
			draw_rect(Rect2(x2, 20.8, 3, 2), blk)
	for wx in [-11.0, 0.0, 11.0]:
		draw_circle(Vector2(wx, 16), 4.2, Color(0.4, 0.4, 0.42))
		draw_circle(Vector2(wx, 16), 2.0, Color(0.15, 0.15, 0.17))
		var a = walk_time * 6.0
		draw_line(Vector2(wx, 16) + Vector2(cos(a), sin(a)) * 3.6, Vector2(wx, 16) - Vector2(cos(a), sin(a)) * 3.6, Color(0.6, 0.6, 0.62), 1.0)
	# zehir tankı (sırtta)
	var tk = Rect2(-21, -27 + shake, 10, 26)
	_rrg(tk, 4.5, Color(0.55, 0.6, 0.6), Color(0.3, 0.33, 0.35))
	var liq_top = tk.position.y + 7 + sin(time * 2.0) * 0.8
	_rrg(Rect2(tk.position.x + 2, liq_top, 6, tk.end.y - liq_top - 2), 2.5, tox.lightened(0.3), tox.darkened(0.35))
	for i in 3:
		var by = tk.end.y - 4 - fposmod(time * 9.0 + i * 6.0, tk.end.y - liq_top - 4)
		draw_circle(Vector2(tk.position.x + 3.5 + i * 1.6, by), 0.9, Color(1, 1, 1, 0.6))
	_glow(Vector2(tk.position.x + 5, tk.position.y + 15), 14, tox, glow * 0.7)
	draw_line(Vector2(tk.position.x + 2, tk.position.y + 3), Vector2(tk.position.x + 2, tk.end.y - 4), Color(1, 1, 1, 0.45), 1.0)
	_rr(Rect2(tk.position.x + 1, tk.position.y - 3, 8, 4), 1.5, Color(0.25, 0.25, 0.28))
	# gövde
	var hull = PackedVector2Array([Vector2(-15, -13 + shake), Vector2(11, -13 + shake), Vector2(16, -5 + shake), Vector2(16, 10), Vector2(-15, 10)])
	_pg(hull, yel.lightened(0.15), yel_d)
	# tehlike şeritleri
	for i in 5:
		var x = -14.0 + i * 6.5
		var stripe = PackedVector2Array([Vector2(x, 10), Vector2(x + 3.2, 10), Vector2(min(x + 7.2, 16), 3), Vector2(min(x + 4, 16), 3)])
		draw_colored_polygon(stripe, blk)
	draw_line(Vector2(-15, 3), Vector2(16, 3), blk, 1.0)
	draw_line(Vector2(-14, -12 + shake), Vector2(10, -12 + shake), Color(1, 1, 0.8, 0.6), 1.0)
	# boru: tanktan maskeye
	draw_polyline(PackedVector2Array([Vector2(-12, -18 + shake), Vector2(-6, -16 + shake), Vector2(0, -12 + shake), Vector2(6, -14 + shake)]), Color(0.2, 0.2, 0.22), 2.6)
	# gaz maskeli kafa
	var hc = Vector2(3, -22 + shake)
	_rrg(Rect2(hc.x - 9, hc.y - 9, 19, 17), 7, Color(0.4, 0.42, 0.3), Color(0.18, 0.2, 0.14))
	for g in [Vector2(-1.5, -2), Vector2(5.5, -2)]:
		draw_circle(hc + g, 3.9, yel)
		draw_circle(hc + g, 2.8, tox.darkened(0.2))
		draw_circle(hc + g, 1.6, tox.lightened(0.5))
		_glow(hc + g, 9, tox, glow)
		draw_circle(hc + g + Vector2(-1, -1), 0.7, Color(1, 1, 1, 0.9))
	# filtre
	draw_circle(hc + Vector2(6, 6), 3.8, Color(0.3, 0.3, 0.32))
	draw_circle(hc + Vector2(6, 6), 2.6, Color(0.18, 0.18, 0.2))
	for k in 3:
		draw_line(hc + Vector2(4.5 + k * 1.5, 4.3), hc + Vector2(4.5 + k * 1.5, 7.7), Color(0.5, 0.5, 0.52), 0.7)
	# tepede uyarı lambası
	var lamp = hc + Vector2(0, -10)
	_rr(Rect2(lamp.x - 3, lamp.y - 1, 6, 2.5), 1, blk)
	var on = fmod(time, 0.8) < 0.4
	draw_circle(lamp + Vector2(0, -2), 2.6, Color(1.0, 0.45, 0.0) if on else Color(0.5, 0.2, 0.0))
	if on:
		_glow(lamp + Vector2(0, -2), 12, Color(1.0, 0.5, 0.0), 1.0)
	# hidrolik kıskaç
	var base_p = Vector2(13, -3 + shake)
	var tip = Vector2(21, 3 + shake)
	draw_line(base_p, tip, Color(0.25, 0.25, 0.27), 4.0)
	draw_line(base_p, tip, Color(0.7, 0.72, 0.75), 1.6)
	var open = (sin(time * 3.5) * 0.5 + 0.5) * 0.6
	for s in [-1.0, 1.0]:
		var a = 0.6 + s * (0.25 + open)
		var j1 = tip + Vector2(cos(a), sin(a)) * 5.0
		var j2 = j1 + Vector2(cos(a + s * -1.1), sin(a + s * -1.1)) * 4.0
		draw_polyline(PackedVector2Array([tip, j1, j2]), yel_d, 2.4)
	draw_circle(tip, 2.4, blk)

# ═════════════════════════════════════════════════════════════════════════════
# 3 — CYCLOPS: süzülen tek gözlü küre
# ═════════════════════════════════════════════════════════════════════════════
func _g_cyclops() -> void:
	var base = Color(0.48, 0.22, 0.78)
	var dark = Color(0.18, 0.06, 0.34)
	var light = Color(0.82, 0.62, 1.0)
	var eye = Color(0.3, 1.0, 0.6) if alt else Color(1.0, 0.28, 0.6)
	var glow = 0.6 + sin(time * 4.0) * 0.4
	var hv = sin(time * 2.6) * 2.5
	var c = Vector2(0, -6 + hv)
	_ell(Vector2(0, 21.5), 13.0 - hv * 0.5, 3.2, Color(0, 0, 0, 0.26 - hv * 0.02))
	# itici alev
	var fl = sin(time * 30.0) * 1.5
	var flame = PackedVector2Array([c + Vector2(-5, 13), c + Vector2(5, 13), c + Vector2(0, 25 + fl)])
	draw_polygon(flame, PackedColorArray([Color(eye.r, eye.g, eye.b, 0.85), Color(eye.r, eye.g, eye.b, 0.85), Color(1, 1, 1, 0.0)]))
	var core = PackedVector2Array([c + Vector2(-2.5, 13), c + Vector2(2.5, 13), c + Vector2(0, 19 + fl)])
	draw_colored_polygon(core, Color(1, 1, 1, 0.9))
	_glow(c + Vector2(0, 16), 12, eye, 0.8)
	# arama ışığı (önündeki koni)
	var cone = PackedVector2Array([c + Vector2(6, -2), c + Vector2(40, -14), c + Vector2(40, 12)])
	draw_polygon(cone, PackedColorArray([Color(eye.r, eye.g, eye.b, 0.16), Color(eye.r, eye.g, eye.b, 0.0), Color(eye.r, eye.g, eye.b, 0.0)]))
	# yan kanatçıklar
	for s in [-1.0, 1.0]:
		var fin = PackedVector2Array([c + Vector2(s * 13, -3), c + Vector2(s * 21, 2 + sin(time * 5.0) * 1.5), c + Vector2(s * 13, 6)])
		_pg(fin, light.lerp(base, 0.3), dark)
	# küre
	draw_circle(c, 15.5, dark)
	draw_circle(c + Vector2(-0.8, -0.8), 14.5, base)
	draw_circle(c + Vector2(-3.5, -4.5), 9.0, Color(light.r, light.g, light.b, 0.35))
	draw_circle(c + Vector2(-6, -8), 2.6, Color(1, 1, 1, 0.55))
	draw_arc(c, 14.8, PI * 0.1, PI * 0.9, 14, Color(0, 0, 0, 0.35), 2.5)
	draw_arc(c, 15.0, PI * 0.05, PI * 0.95, 14, Color(1, 1, 1, 0.12), 1.0)
	# perçin şeridi
	for i in 6:
		var a = PI * 0.15 + i * PI * 0.14
		draw_circle(c + Vector2(cos(a), sin(a)) * 11.5, 0.9, Color(1, 1, 1, 0.35))
	# halo anten
	var hc = c + Vector2(0, -20)
	draw_line(c + Vector2(0, -15), hc + Vector2(0, 2), Color(0.7, 0.7, 0.75), 1.4)
	var ring = _ell_pts(hc, 8.5, 2.4, 18)
	ring.append(ring[0])
	draw_polyline(ring, Color(1.0, 0.85, 0.3, 0.35), 3.0)
	draw_polyline(ring, Color(1.0, 0.92, 0.55), 1.2)
	draw_circle(hc + Vector2(0, 2), 1.6, Color(1.0, 0.9, 0.5))
	# dev göz
	var look = Vector2(2.5 + sin(time * 0.9) * 1.8, sin(time * 1.3) * 1.4)
	var ec = c + Vector2(3, -1)
	draw_circle(ec, 9.5, Color(0.05, 0.0, 0.08))
	draw_circle(ec, 8.2, Color(0.95, 0.92, 1.0))
	draw_circle(ec + look, 5.4, eye)
	draw_circle(ec + look, 3.6, eye.darkened(0.35))
	draw_circle(ec + look, 2.2, Color(0.02, 0.0, 0.05))
	draw_circle(ec + look + Vector2(-1.6, -1.8), 1.3, Color(1, 1, 1, 0.95))
	draw_arc(ec, 9.6, 0, TAU, 22, Color(eye.r, eye.g, eye.b, 0.5 + glow * 0.4), 1.4)
	_glow(ec + look, 16, eye, glow)
	# göz kapağı kırpma
	var bl = fmod(time + 0.37 * guard_type, 3.2)
	if bl < 0.14:
		var k = 1.0 - abs(bl - 0.07) / 0.07
		var lid_top = PackedVector2Array()
		var lid_bot = PackedVector2Array()
		for i in 13:
			var a = PI + PI * i / 12.0
			lid_top.append(ec + Vector2(cos(a) * 9.6, sin(a) * 9.6 * k))
			lid_bot.append(ec + Vector2(cos(a) * 9.6, -sin(a) * 9.6 * k))
		draw_colored_polygon(lid_top, base.darkened(0.2))
		draw_colored_polygon(lid_bot, base.darkened(0.35))

# ═════════════════════════════════════════════════════════════════════════════
# 4 — MAGMA: lav golemi (çatlaklarından lav sızan kaya, alev tepeli)
# ═════════════════════════════════════════════════════════════════════════════
func _g_magma() -> void:
	var rock = Color(0.4, 0.27, 0.23)
	var rock_d = Color(0.17, 0.1, 0.09)
	var rock_l = Color(0.62, 0.45, 0.38)
	var lava = Color(1.0, 0.85, 0.35) if alt else Color(1.0, 0.45, 0.06)
	var hot = Color(1.0, 0.95, 0.6)
	var pulse = 0.65 + sin(time * 3.2) * 0.35
	var b = -_bob() * 1.3
	var sw = sin(_step()) * 0.45
	_shadow(19, 0.4)
	# kalın bacaklar
	var ph = _step()
	for i in 2:
		var hx = -6.0 if i == 0 else 6.0
		var f = _foot(ph + (PI if i == 0 else 0.0), hx, 4.0, 3.0)
		var leg = PackedVector2Array([Vector2(hx - 5, 5 + b), Vector2(hx + 5, 5 + b), f + Vector2(5, 0), f + Vector2(-6, 0)])
		_pg(leg, rock, rock_d)
		draw_line(Vector2(hx, 7 + b), f + Vector2(-1, -4), Color(lava.r, lava.g, lava.b, 0.8 * pulse), 1.2)
	# arka kol (kaya yumruk)
	var shb = Vector2(-11, -8 + b)
	var hb = shb + Vector2(sin(-sw) * 6, 15)
	_limb(shb, hb, 8, rock_d.lightened(0.05))
	draw_circle(hb, 6, rock_d)
	# gövde kayası
	var body = PackedVector2Array([Vector2(-16, -14 + b), Vector2(-6, -19 + b), Vector2(8, -18 + b), Vector2(17, -10 + b),
		Vector2(16, 5 + b), Vector2(8, 10 + b), Vector2(-9, 10 + b), Vector2(-17, 3 + b)])
	_pg(body, rock_l, rock_d)
	draw_polyline(PackedVector2Array([Vector2(-16, -13 + b), Vector2(-6, -18 + b), Vector2(8, -17 + b), Vector2(16, -10 + b)]), Color(1, 0.75, 0.55, 0.55), 1.3)
	# lav çatlakları
	var cracks = [
		[Vector2(-12, -10), Vector2(-6, -5), Vector2(-8, 2), Vector2(-3, 8)],
		[Vector2(4, -16), Vector2(2, -9), Vector2(7, -5)],
		[Vector2(14, -4), Vector2(9, 0), Vector2(11, 7)],
	]
	for cr in cracks:
		var pts = PackedVector2Array()
		for p in cr:
			pts.append(p + Vector2(0, b))
		draw_polyline(pts, Color(lava.r, lava.g, lava.b, 0.35 * pulse), 3.6)
		draw_polyline(pts, Color(lava.r, lava.g, lava.b, 0.6 + 0.4 * pulse), 1.4)
	# erimiş çekirdek
	var cc = Vector2(2, -4 + b)
	draw_circle(cc, 5.0, Color(lava.r, lava.g, lava.b, 0.9))
	draw_circle(cc, 2.8, hot)
	_glow(cc, 18, lava, pulse)
	# kafa
	var head = PackedVector2Array([Vector2(-7, -30 + b), Vector2(5, -32 + b), Vector2(13, -26 + b), Vector2(12, -17 + b), Vector2(-6, -16 + b), Vector2(-9, -23 + b)])
	_pg(head, rock_l, rock_d)
	draw_polyline(PackedVector2Array([Vector2(-9, -23 + b), Vector2(-7, -30 + b), Vector2(5, -32 + b), Vector2(13, -26 + b)]), Color(1, 0.75, 0.55, 0.5), 1.1)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -27 + b), Vector2(12, -26 + b), Vector2(12, -24.5 + b), Vector2(-5, -25.5 + b)]), rock_d)
	# alev tepe
	for i in 3:
		var bx = -4.0 + i * 6.0
		var h = 9.0 + sin(time * 7.0 + i * 1.7) * 2.5 + (2.0 if i == 1 else 0.0)
		var sway = sin(time * 5.0 + i) * 1.5
		var outer = PackedVector2Array([Vector2(bx - 4, -29 + b), Vector2(bx + 4, -30 + b), Vector2(bx + sway, -30 - h + b)])
		draw_polygon(outer, PackedColorArray([Color(lava.r, lava.g, lava.b, 0.95), Color(lava.r, lava.g, lava.b, 0.95), Color(1, 0.3, 0.0, 0.0)]))
		var inner = PackedVector2Array([Vector2(bx - 2, -29.5 + b), Vector2(bx + 2, -30 + b), Vector2(bx + sway * 0.6, -30 - h * 0.55 + b)])
		draw_colored_polygon(inner, Color(hot.r, hot.g, hot.b, 0.9))
	_glow(Vector2(2, -36 + b), 16, lava, 0.7)
	# yarık gözler
	for ex in [-1.0, 7.0]:
		var e = PackedVector2Array([Vector2(ex - 3.5, -24.5 + b), Vector2(ex + 4, -23.5 + b), Vector2(ex + 3.5, -20.5 + b), Vector2(ex - 3, -21.5 + b)])
		draw_colored_polygon(e, lava)
		draw_line(Vector2(ex - 2, -22.5 + b), Vector2(ex + 2.5, -22 + b), hot, 1.4)
		_glow(Vector2(ex, -22.5 + b), 10, lava, pulse)
	# ağız çatlağı
	draw_polyline(PackedVector2Array([Vector2(-2, -19 + b), Vector2(2, -18 + b), Vector2(5, -19.5 + b), Vector2(9, -18.5 + b)]), Color(lava.r, lava.g, lava.b, 0.9), 1.3)
	# ön kol: lav eklemli yumruk
	var sh = Vector2(12, -9 + b)
	var hand = sh + Vector2(sin(sw) * 6 + 2, 15)
	_limb(sh, hand, 8, rock)
	draw_circle(hand, 6.5, rock_l.lerp(rock, 0.5))
	for k in 3:
		draw_line(hand + Vector2(-3 + k * 3, -3), hand + Vector2(-3 + k * 3, 1), Color(lava.r, lava.g, lava.b, 0.85), 1.2)
	_ell(Vector2(11, -12 + b), 6.5, 5, rock_l)

# ═════════════════════════════════════════════════════════════════════════════
# 5 — FROST: buz şövalyesi (kristal tepeli miğfer, buz mızrak)
# ═════════════════════════════════════════════════════════════════════════════
func _g_frost() -> void:
	var arm = Color(0.86, 0.94, 1.0)
	var mid = Color(0.56, 0.74, 0.94)
	var dark = Color(0.2, 0.32, 0.55)
	var ice = Color(0.75, 0.6, 1.0) if alt else Color(0.4, 0.95, 1.0)
	var glow = 0.6 + sin(time * 3.5) * 0.4
	var b = -_bob()
	var sw = sin(_step()) * 0.4
	_shadow(17)
	_legs(7, 10, 6, dark, mid.darkened(0.15), dark.darkened(0.2), 11)
	# arka kol + mızrak (arkadan öne uzanır)
	var shb = Vector2(-9, -7 + b)
	var hb = shb + Vector2(10 + sin(-sw) * 3, 9)
	_limb(shb, hb, 5, dark)
	# gövde: göğüs zırhı
	var torso = PackedVector2Array([Vector2(-13, -13 + b), Vector2(13, -13 + b), Vector2(11, 3 + b), Vector2(6, 9 + b), Vector2(-6, 9 + b), Vector2(-11, 3 + b)])
	_pg(torso, arm, mid.darkened(0.2))
	draw_line(Vector2(0, -12 + b), Vector2(0, 8 + b), Color(dark.r, dark.g, dark.b, 0.35), 1.0)
	draw_line(Vector2(-11, -12 + b), Vector2(11, -12 + b), Color(1, 1, 1, 0.7), 1.2)
	# göğüs kristali
	var gc = Vector2(1, -4 + b)
	var gem = PackedVector2Array([gc + Vector2(0, -5.5), gc + Vector2(4, 0), gc + Vector2(0, 5.5), gc + Vector2(-4, 0)])
	draw_polygon(gem, PackedColorArray([Color(1, 1, 1), ice, ice.darkened(0.4), ice.lightened(0.2)]))
	_glow(gc, 14, ice, glow)
	# kemer
	_rr(Rect2(-11, 4 + b, 22, 3.5), 1, dark)
	# omuzluklar + buz dikenleri
	for s in [-1.0, 1.0]:
		var pc = Vector2(s * 11 + (1 if s > 0 else 0), -11 + b)
		_ell(pc, 6, 4.5, arm.lerp(mid, 0.3))
		for k in 3:
			var bx = pc.x + (k - 1) * 3.5
			var spike = PackedVector2Array([Vector2(bx - 1.6, pc.y - 2), Vector2(bx + 1.6, pc.y - 2), Vector2(bx + s * 1.5, pc.y - 8 - (2 if k == 1 else 0))])
			draw_polygon(spike, PackedColorArray([ice, ice.darkened(0.3), Color(1, 1, 1)]))
	# miğfer
	var hy = -33 + b
	_rrg(Rect2(-10, hy, 22, 20), 8, arm, mid)
	draw_arc(Vector2(-1, hy + 9), 8, PI * 1.1, PI * 1.45, 8, Color(1, 1, 1, 0.9), 1.4)
	# kristal tepe
	var crest = [[Vector2(-3, hy + 1), 12.0, -0.25], [Vector2(2, hy), 15.0, 0.0], [Vector2(7, hy + 1), 10.0, 0.3]]
	for cr in crest:
		var p: Vector2 = cr[0]
		var h: float = cr[1]
		var lean: float = cr[2]
		var sh_pts = PackedVector2Array([p + Vector2(-2.4, 1), p + Vector2(2.4, 1), p + Vector2(lean * h, -h)])
		draw_polygon(sh_pts, PackedColorArray([ice.darkened(0.25), ice, Color(1, 1, 1)]))
	_glow(Vector2(2, hy - 6), 12, ice, glow * 0.7)
	# T vizör
	draw_rect(Rect2(-3, hy + 8, 14, 3.4), Color(0.03, 0.06, 0.14))
	draw_rect(Rect2(5.2, hy + 8, 3.4, 9), Color(0.03, 0.06, 0.14))
	draw_rect(Rect2(-2, hy + 8.7, 12, 1.8), Color(ice.r, ice.g, ice.b, 0.8 + 0.2 * glow))
	draw_rect(Rect2(6.0, hy + 9.5, 1.8, 6), Color(ice.r, ice.g, ice.b, 0.7 + 0.3 * glow))
	_glow(Vector2(5, hy + 10), 12, ice, glow)
	# buz mızrak (ön elde, ileri dönük)
	var sh = Vector2(11, -7 + b)
	var hand = sh + Vector2(4 + sin(sw) * 3, 9)
	var shaft_a = hand + Vector2(-14, 5)
	var shaft_b = hand + Vector2(12, -9)
	draw_line(shaft_a, shaft_b, Color(0.35, 0.28, 0.4), 2.2)
	var dirv = (shaft_b - shaft_a).normalized()
	var nrm = Vector2(-dirv.y, dirv.x)
	var blade = PackedVector2Array([shaft_b - nrm * 2.8, shaft_b + dirv * 11.0, shaft_b + nrm * 2.8, shaft_b - dirv * 1.5])
	draw_polygon(blade, PackedColorArray([ice.darkened(0.2), Color(1, 1, 1), ice, ice.lightened(0.3)]))
	_glow(shaft_b + dirv * 5, 10, ice, glow)
	_limb(sh, hand, 5, mid)
	draw_circle(hand, 3.4, arm)
	# kar pırıltıları
	for i in 3:
		var t = fposmod(time * 0.7 + i * 0.33, 1.0)
		var sp = Vector2(-14 + i * 13, -30 + t * 40 + b)
		var s = (1.0 - abs(t - 0.5) * 2.0) * 2.2
		draw_line(sp + Vector2(-s, 0), sp + Vector2(s, 0), Color(1, 1, 1, 0.8), 0.8)
		draw_line(sp + Vector2(0, -s), sp + Vector2(0, s), Color(1, 1, 1, 0.8), 0.8)

# ═════════════════════════════════════════════════════════════════════════════
# 6 — PHANTOM: gölge ninja (dalgalanan atkı, iz bırakan hayalet, dönen shuriken)
# ═════════════════════════════════════════════════════════════════════════════
func _g_phantom() -> void:
	var blk = Color(0.09, 0.08, 0.13)
	var dv = Color(0.22, 0.14, 0.32)
	var acc = Color(0.2, 1.0, 0.8) if alt else Color(1.0, 0.22, 0.78)
	var glow = 0.6 + sin(time * 5.0) * 0.4
	var ph = walk_time * 11.0
	var b = -abs(sin(ph)) * 1.6
	_shadow(15, 0.3)
	# hayalet izleri (arkada)
	for g in 2:
		var gx = -7.0 - g * 7.0
		var ga = (0.1 - g * 0.04) * (0.6 + 0.4 * sin(time * 7.0 + g))
		draw_circle(Vector2(gx + 2, -22 + b), 8.5, Color(acc.r, acc.g, acc.b, ga))
		_rr(Rect2(gx - 7, -14 + b, 15, 22), 5, Color(acc.r, acc.g, acc.b, ga * 0.8))
	# atkı (arkaya dalgalanır)
	var scarf_top = PackedVector2Array()
	var scarf_bot = PackedVector2Array()
	for i in 9:
		var k = i / 8.0
		var x = -2.0 - k * 24.0
		var wave = sin(time * 9.0 - k * 5.0) * (1.0 + k * 3.5)
		scarf_top.append(Vector2(x, -17 + b + wave - k * 2.0))
		scarf_bot.append(Vector2(x, -13 + b + wave - k * 1.0 - k * 2.0))
	var scarf = PackedVector2Array(scarf_top)
	for i in range(scarf_bot.size() - 1, -1, -1):
		scarf.append(scarf_bot[i])
	draw_colored_polygon(scarf, acc.darkened(0.25))
	draw_polyline(scarf_top, acc.lightened(0.2), 1.0)
	# bacaklar: ince, hızlı
	for i in 2:
		var hip = Vector2(-2.5 if i == 0 else 2.5, 6 + b)
		var f = Vector2(hip.x + cos(ph + (PI if i == 0 else 0.0)) * 7.0, 21.0 - max(0.0, sin(ph + (PI if i == 0 else 0.0))) * 5.0)
		var knee = (hip + f) * 0.5 + Vector2(3.5, -1.5)
		var col = blk if i == 0 else dv
		_limb(hip, knee, 4.5, col)
		_limb(knee, f + Vector2(0, -1.5), 4.0, col)
		_rr(Rect2(f.x - 3, f.y - 3, 7, 3.5), 1.5, blk)
	# sırttaki çapraz kılıçlar
	draw_line(Vector2(-12, -24 + b), Vector2(8, 4 + b), Color(0.75, 0.78, 0.85), 1.6)
	draw_line(Vector2(-12, -24 + b), Vector2(-9, -20 + b), acc, 2.6)
	draw_line(Vector2(10, -25 + b), Vector2(-9, 4 + b), Color(0.7, 0.72, 0.8), 1.4)
	draw_line(Vector2(10, -25 + b), Vector2(7, -21 + b), acc, 2.6)
	# gövde (ileri eğik)
	var torso = PackedVector2Array([Vector2(-8, -14 + b), Vector2(9, -15 + b), Vector2(8, 7 + b), Vector2(-7, 7 + b)])
	_pg(torso, dv, blk)
	_rr(Rect2(-8, 1 + b, 16, 3.5), 1, acc.darkened(0.2))
	draw_rect(Rect2(-1, 0 + b, 3, 5.5), acc)
	# kafa: başlık + parlayan vizör bandı
	var hc = Vector2(2, -22 + b)
	draw_circle(hc, 9.5, blk)
	draw_circle(hc + Vector2(-1.5, -2), 7.5, dv.darkened(0.2))
	draw_arc(hc, 9.0, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.18), 1.2)
	# kenar ışığı: siyah ninja koyu arka planlarda kaybolmasın
	draw_arc(hc, 9.8, PI * 0.95, PI * 2.05, 14, Color(acc.r, acc.g, acc.b, 0.6), 1.2)
	draw_line(Vector2(9.5, -14 + b), Vector2(8.5, 6 + b), Color(acc.r, acc.g, acc.b, 0.45), 1.0)
	draw_line(Vector2(-8.5, -13 + b), Vector2(-7.5, 6 + b), Color(acc.r, acc.g, acc.b, 0.3), 1.0)
	var visor = PackedVector2Array([hc + Vector2(-3, -2.2), hc + Vector2(10, -3.4), hc + Vector2(10, 0.8), hc + Vector2(-3, 1)])
	draw_colored_polygon(visor, Color(0.02, 0.0, 0.04))
	draw_line(hc + Vector2(-1, -0.6), hc + Vector2(9.5, -1.4), acc.lightened(0.3), 1.6)
	_glow(hc + Vector2(6, -1), 12, acc, glow)
	# bandana kuyrukları
	for k in 2:
		var tail = PackedVector2Array()
		for i in 5:
			var t = i / 4.0
			tail.append(hc + Vector2(-8 - t * 10, -4 + k * 2 + sin(time * 12 - t * 4 + k) * t * 2.5))
		draw_polyline(tail, acc, 1.6 - k * 0.4)
	# ön kol + dönen shuriken
	var sh = Vector2(7, -10 + b)
	var hand = sh + Vector2(9, 4)
	_limb(sh, hand, 4, blk.lightened(0.08))
	var sc = hand + Vector2(5, -2)
	var rot = time * 14.0
	var star = PackedVector2Array()
	for i in 8:
		var a = rot + PI * i / 4.0
		var r = 5.0 if i % 2 == 0 else 1.6
		star.append(sc + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(star, Color(0.8, 0.82, 0.9))
	draw_circle(sc, 1.2, blk)
	_glow(sc, 9, acc, 0.6)

# ═════════════════════════════════════════════════════════════════════════════
# 7 — TITAN: altın muhafız (kule kalkanı, sorguçlu miğfer, pelerin)
# ═════════════════════════════════════════════════════════════════════════════
func _g_titan() -> void:
	var gold = Color(1.0, 0.78, 0.26)
	var gold_d = Color(0.58, 0.36, 0.06)
	var gold_l = Color(1.0, 0.95, 0.62)
	var royal = Color(0.55, 0.12, 0.6) if alt else Color(0.14, 0.24, 0.68)
	var eye = Color(0.75, 0.95, 1.0)
	var glow = 0.6 + sin(time * 3.0) * 0.4
	var b = -_bob() * 1.2
	var sw = sin(_step()) * 0.35
	_shadow(19, 0.38)
	# pelerin
	var cape = PackedVector2Array([Vector2(-8, -16 + b), Vector2(-2, -16 + b)])
	for i in 6:
		var k = i / 5.0
		cape.append(Vector2(-2 - k * 18.0, 14 + sin(time * 4.0 + k * 3.0) * 2.0 - k * 4.0))
	draw_colored_polygon(cape, Color(0.62, 0.06, 0.1))
	draw_line(Vector2(-8, -16 + b), Vector2(-20, 10), Color(0.4, 0.02, 0.05), 1.2)
	# zırhlı bacaklar
	_legs(7, 11, 7, gold_d, gold.darkened(0.15), gold_d.darkened(0.2), 12, 4.5)
	# gövde
	var torso = PackedVector2Array([Vector2(-14, -15 + b), Vector2(14, -15 + b), Vector2(12, 8 + b), Vector2(-12, 8 + b)])
	_pg(torso, gold_l, gold_d)
	_rrg(Rect2(-6, -10 + b, 12, 18), 2, royal.lightened(0.2), royal.darkened(0.3))
	draw_line(Vector2(-13, -14 + b), Vector2(13, -14 + b), Color(1, 1, 0.9, 0.85), 1.2)
	_rr(Rect2(-13, 5 + b, 26, 4), 1, gold_d)
	draw_circle(Vector2(0, 7 + b), 2.2, Color(0.9, 0.15, 0.2))
	# omuzluklar
	_ell(Vector2(-12, -13 + b), 6.5, 5, gold)
	_ell(Vector2(-12, -14 + b), 4, 2.5, Color(gold_l.r, gold_l.g, gold_l.b, 0.6))
	# miğfer
	var hy = -35 + b
	_rrg(Rect2(-10, hy, 22, 21), 9, gold_l, gold_d)
	draw_rect(Rect2(-3, hy + 9, 14, 3.4), Color(0.05, 0.03, 0.0))
	draw_rect(Rect2(-2, hy + 9.7, 12, 2), Color(eye.r, eye.g, eye.b, 0.8 + glow * 0.2))
	_glow(Vector2(4, hy + 10.5), 12, eye, glow)
	for k in 3:
		draw_line(Vector2(1 + k * 3.5, hy + 14), Vector2(1 + k * 3.5, hy + 19), Color(0.25, 0.15, 0.0, 0.8), 1.0)
	draw_arc(Vector2(-1, hy + 9), 8, PI * 1.1, PI * 1.45, 8, Color(1, 1, 1, 0.7), 1.4)
	# sorguç (dalgalanan kırmızı tüy)
	var plume = PackedVector2Array([Vector2(-2, hy + 1)])
	for i in 7:
		var k = i / 6.0
		var a = -PI * 0.5 - k * 1.9
		plume.append(Vector2(2, hy + 3) + Vector2(cos(a), sin(a)) * (9.0 + sin(time * 6.0 + k * 4.0) * 0.8))
	plume.append(Vector2(5, hy + 1))
	draw_colored_polygon(plume, Color(0.85, 0.1, 0.15))
	draw_polyline(plume.slice(1, 7), Color(1.0, 0.45, 0.45), 1.0)
	# ön kol
	var sh = Vector2(12, -10 + b)
	var hand = sh + Vector2(4, 10)
	_limb(sh, hand, 6, gold.darkened(0.1))
	# kule kalkanı (manyetik amblem)
	var sy = sin(_step()) * 1.0
	var sr = Rect2(9, -18 + b + sy, 13, 32)
	_rrg(sr, 4, gold_l, gold_d)
	_rrg(Rect2(sr.position.x + 2, sr.position.y + 2, sr.size.x - 4, sr.size.y - 4), 3, royal.lightened(0.15), royal.darkened(0.35))
	var mc = sr.get_center() + Vector2(0, -1)
	draw_arc(mc + Vector2(0, 2), 4.0, 0.0, PI, 10, Color(0.85, 0.85, 0.9), 2.6)
	draw_line(mc + Vector2(-4, 2), mc + Vector2(-4, -3), Color(0.95, 0.2, 0.2), 2.6)
	draw_line(mc + Vector2(4, 2), mc + Vector2(4, -3), Color(0.25, 0.5, 1.0), 2.6)
	_glow(mc, 12, gold_l, glow * 0.6)
	# kalkan parlaması (kayan ışık)
	var sx = fposmod(time * 0.8, 2.2)
	if sx < 1.0:
		var x = sr.position.x + sx * sr.size.x
		draw_line(Vector2(x, sr.position.y + 2), Vector2(x - 4, sr.end.y - 2), Color(1, 1, 1, 0.35 * (1.0 - abs(sx - 0.5) * 2.0)), 2.0)

# ═════════════════════════════════════════════════════════════════════════════
# 8 — OVERLORD: boşluk imparatoru (süzülen taç, kara delik çekirdek, yörüngede kristaller)
# ═════════════════════════════════════════════════════════════════════════════
func _g_overlord() -> void:
	var obs = Color(0.08, 0.05, 0.12)
	var dp = Color(0.22, 0.08, 0.34)
	var vio = Color(1.0, 0.28, 0.38) if alt else Color(0.7, 0.35, 1.0)
	var core = Color(0.95, 0.85, 1.0)
	var glow = 0.6 + sin(time * 3.0) * 0.4
	var hv = sin(time * 2.0) * 2.0
	_ell(Vector2(0, 21.5), 16, 3.5, Color(0, 0, 0, 0.35))
	_glow(Vector2(0, 14), 28, vio, 0.6)
	# yörüngedeki kristaller (arka yarı)
	_overlord_shards(false, hv, vio)
	# yırtık pelerin
	var cape = PackedVector2Array([Vector2(-10, -18 + hv), Vector2(10, -18 + hv)])
	for i in 7:
		var k = i / 6.0
		var x = 12.0 - k * 30.0
		var y = 16.0 + (3.0 if i % 2 == 0 else -2.0) + sin(time * 3.0 + k * 5.0) * 1.5
		cape.append(Vector2(x, y))
	_pg(cape, dp, Color(dp.r, dp.g, dp.b, 0.15))
	# cübbe gövde (alt kenar sise karışır)
	var robe = PackedVector2Array([Vector2(-11, -16 + hv), Vector2(12, -16 + hv), Vector2(15, 10 + hv), Vector2(9, 15 + hv), Vector2(3, 12 + hv), Vector2(-3, 16 + hv), Vector2(-9, 12 + hv), Vector2(-14, 10 + hv)])
	_pg(robe, dp.lightened(0.1), obs)
	# kenar ışığı: koyu gövde koyu arka planlarda kaybolmasın
	draw_polyline(PackedVector2Array([Vector2(-14, 10 + hv), Vector2(-11, -16 + hv), Vector2(12, -16 + hv), Vector2(15, 10 + hv)]), Color(vio.r, vio.g, vio.b, 0.55), 1.1)
	draw_line(Vector2(1, -15 + hv), Vector2(1, 12 + hv), Color(vio.r, vio.g, vio.b, 0.5), 1.0)
	# kara delik çekirdek
	var cc = Vector2(1, -4 + hv)
	_glow(cc, 20, vio, glow)
	for i in 3:
		var a0 = -time * 3.0 + i * TAU / 3.0
		draw_arc(cc, 6.5 - i * 0.6, a0, a0 + PI * 0.9, 10, Color(vio.r, vio.g, vio.b, 0.9 - i * 0.2), 1.6)
	draw_arc(cc, 4.2, 0, TAU, 16, core, 1.2)
	draw_circle(cc, 3.2, Color(0, 0, 0))
	# sivri omuzluklar
	for s in [-1.0, 1.0]:
		var pc = Vector2(s * 12 + 1, -15 + hv)
		var tip_out = pc + Vector2(s * 9, -6)
		var tip_in = pc + Vector2(s * 2, -3)
		var pad = PackedVector2Array([pc + Vector2(-6, 3), pc + Vector2(6, 3), tip_out, tip_in]) if s > 0 \
			else PackedVector2Array([pc + Vector2(-6, 3), pc + Vector2(6, 3), tip_in, tip_out])
		_pg(pad, dp.lightened(0.25), obs)
		draw_line(pc + Vector2(s * 2, -3), pc + Vector2(s * 9, -6), Color(vio.r, vio.g, vio.b, 0.8), 1.0)
	# kafa: boynuzlu miğfer
	var hc = Vector2(2, -26 + hv)
	# boynuzlar: taban -> iç kenar -> uç -> dış kenar -> taban (kendini kesmeyen sıra)
	for hp in [[Vector2(-3, -6), Vector2(-8, -8), Vector2(-15, -15), Vector2(-13, -6), Vector2(-7, -2)],
			[Vector2(5, -7), Vector2(9, -10), Vector2(12, -16), Vector2(12, -7), Vector2(9, -3)]]:
		var horn = PackedVector2Array()
		for q in hp:
			horn.append(hc + q)
		_pg(horn, Color(0.45, 0.32, 0.55), obs)
		draw_line(hc + hp[1], hc + hp[2], Color(vio.r, vio.g, vio.b, 0.6), 0.9)
	draw_circle(hc, 9, obs)
	draw_circle(hc + Vector2(-1, -1.5), 7.5, dp.darkened(0.1))
	draw_arc(hc, 8.6, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1, 0.2), 1.2)
	draw_arc(hc, 9.4, PI * 0.95, PI * 2.05, 14, Color(vio.r, vio.g, vio.b, 0.6), 1.1)
	for ex in [1.5, 7.0]:
		var e = PackedVector2Array([hc + Vector2(ex - 3, -1.5), hc + Vector2(ex + 3, -0.5), hc + Vector2(ex + 2.5, 1.5), hc + Vector2(ex - 2.5, 0.8)])
		draw_colored_polygon(e, core)
		_glow(hc + Vector2(ex, 0), 9, vio, glow)
	# süzülen taç
	var cy = hc.y - 15 + sin(time * 2.6) * 1.2
	var crown = PackedVector2Array([Vector2(hc.x - 8, cy + 4), Vector2(hc.x - 8, cy - 1), Vector2(hc.x - 5, cy + 1), Vector2(hc.x - 2.5, cy - 5),
		Vector2(hc.x, cy), Vector2(hc.x + 2.5, cy - 6), Vector2(hc.x + 5, cy + 1), Vector2(hc.x + 8, cy - 1), Vector2(hc.x + 8, cy + 4)])
	_glow(Vector2(hc.x, cy), 14, vio, glow)
	_pg(crown, Color(0.95, 0.8, 1.0), vio.darkened(0.3))
	draw_circle(Vector2(hc.x, cy + 2), 1.4, core)
	# pençe el + enerji küresi
	var sh = Vector2(12, -10 + hv)
	var hand = sh + Vector2(6, 8)
	_limb(sh, hand, 4.5, obs.lightened(0.1))
	var orb = hand + Vector2(4, -4 + sin(time * 4.0) * 1.0)
	_glow(orb, 12, vio, 1.0)
	draw_circle(orb, 3.4, vio)
	draw_circle(orb, 1.8, core)
	# yörüngedeki kristaller (ön yarı)
	_overlord_shards(true, hv, vio)

func _overlord_shards(front: bool, hv: float, vio: Color) -> void:
	for i in 4:
		var a = time * 1.6 + i * TAU / 4.0
		var is_front = sin(a) > 0.0
		if is_front != front:
			continue
		var p = Vector2(cos(a) * 21.0, -6 + hv + sin(a) * 6.0)
		var s = 2.4 + (0.8 if is_front else 0.0)
		var d = PackedVector2Array([p + Vector2(0, -s * 1.8), p + Vector2(s, 0), p + Vector2(0, s * 1.8), p + Vector2(-s, 0)])
		var a_mul = 1.0 if is_front else 0.5
		draw_polygon(d, PackedColorArray([Color(1, 1, 1, a_mul), Color(vio.r, vio.g, vio.b, a_mul), Color(vio.r * 0.5, vio.g * 0.5, vio.b * 0.5, a_mul), Color(vio.r, vio.g, vio.b, a_mul)]))
		_glow(p, 8, vio, 0.5 * a_mul)
