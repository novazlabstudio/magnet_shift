extends Node2D

# Kahraman ölünce oyuncunun (Player) çocuğu olarak eklenen efekt katmanı.
# Kahramanın kendi çizimi PlayerVisual'da (titreme, kömürleşme, devrilme); burada çevresindeki
# efektler çizilir. Hepsi yumuşak daire, çizgi ve çokgenlerle yapılır, dikdörtgen kullanılmaz.
#   "laser": elektrik arkları + kıvılcım -> kor ve alev -> duman -> küle dönüşüp dağılma
#   "guard": darbe halkası + ışın çizgileri -> başında dönen yıldızlar -> dişli/cıvata parçaları

const BODY_CENTER := Vector2(0, -6)

var cause: String = "laser"
var accent: Color = Color(0.0, 0.85, 1.0)
var t: float = 0.0
var parts: Array = []
var bolts: Array = []
var _bolt_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _spawned: Dictionary = {}

func setup(death_cause: String, hero_accent: Color) -> void:
	cause = death_cause if death_cause in ["laser", "guard"] else "guard"
	accent = hero_accent
	z_index = 6
	_rng.randomize()
	if cause == "laser":
		_burst_sparks(22, 260.0)
	else:
		_burst_impact()

func _process(delta: float) -> void:
	t += delta
	if cause == "laser":
		_update_laser(delta)
	else:
		_update_guard(delta)
	for p in parts:
		p.life += delta
		p.vel += p.get("acc", Vector2.ZERO) * delta
		p.vel *= pow(p.get("drag", 1.0), delta * 60.0)
		p.pos += p.vel * delta
		p.rot = p.get("rot", 0.0) + p.get("spin", 0.0) * delta
	parts = parts.filter(func(p): return p.life < p.max_life)
	queue_redraw()

# ── Lazer: elektrik çarpması ve yanma ─────────────────────────────────────────
func _update_laser(delta: float) -> void:
	_bolt_timer -= delta
	if t < 0.62 and _bolt_timer <= 0.0:
		_bolt_timer = 0.045
		bolts.clear()
		var n = 6 if t < 0.4 else 3
		for i in n:
			var a = _rng.randf() * TAU
			var from = BODY_CENTER + Vector2(cos(a) * 9.0, sin(a) * 15.0)
			var to = BODY_CENTER + Vector2(cos(a), sin(a) * 1.2).normalized() * _rng.randf_range(26.0, 44.0)
			bolts.append(_make_bolt(from, to, 4))
		if t < 0.45 and _rng.randf() < 0.6:
			_burst_sparks(3, 180.0)
	elif t >= 0.62:
		bolts.clear()
	if t > 0.42 and t < 0.95 and not _spawned.has("flames"):
		_spawned["flames"] = true
	if t > 0.5 and t < 1.15 and _rng.randf() < 0.35:
		_spawn_smoke()
	if t > 0.86 and not _spawned.has("ash"):
		_spawned["ash"] = true
		for i in 46:
			var p = BODY_CENTER + Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-24, 20))
			parts.append({"kind": "ash", "pos": p, "vel": Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-70, -20)),
				"acc": Vector2(0, -25), "drag": 0.985, "life": 0.0, "max_life": _rng.randf_range(0.6, 1.1),
				"size": _rng.randf_range(1.2, 2.8), "hot": _rng.randf() < 0.45})
		parts.append({"kind": "ring", "pos": BODY_CENTER, "vel": Vector2.ZERO, "life": 0.0, "max_life": 0.4,
			"color": Color(1.0, 0.55, 0.15)})

func _burst_sparks(n: int, speed: float) -> void:
	for i in n:
		var a = _rng.randf() * TAU
		var v = Vector2(cos(a), sin(a)) * _rng.randf_range(speed * 0.4, speed)
		parts.append({"kind": "spark", "pos": BODY_CENTER, "vel": v, "acc": Vector2(0, 420), "drag": 0.96,
			"life": 0.0, "max_life": _rng.randf_range(0.25, 0.5),
			"color": Color(0.7, 0.97, 1.0) if _rng.randf() < 0.7 else Color(1.0, 0.85, 0.4)})

func _spawn_smoke() -> void:
	parts.append({"kind": "smoke", "pos": BODY_CENTER + Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-20, 0)),
		"vel": Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-45, -25)), "drag": 0.99,
		"life": 0.0, "max_life": _rng.randf_range(0.7, 1.1), "size": _rng.randf_range(5, 9)})

func _make_bolt(a: Vector2, b: Vector2, depth: int) -> PackedVector2Array:
	var pts = [a, b]
	var disp = a.distance_to(b) * 0.35
	for d in depth:
		var np = [pts[0]]
		for i in range(1, pts.size()):
			var p0: Vector2 = pts[i - 1]
			var p1: Vector2 = pts[i]
			var mid = (p0 + p1) * 0.5
			var nrm = (p1 - p0).orthogonal().normalized()
			np.append(mid + nrm * _rng.randf_range(-disp, disp))
			np.append(p1)
		pts = np
		disp *= 0.5
	return PackedVector2Array(pts)

# ── Bekçi: darbe, sersemleme, parçalanma ──────────────────────────────────────
func _burst_impact() -> void:
	parts.append({"kind": "ring", "pos": BODY_CENTER, "vel": Vector2.ZERO, "life": 0.0, "max_life": 0.35,
		"color": Color(1.0, 0.95, 0.85)})
	for i in 10:
		var a = TAU * i / 10.0 + _rng.randf_range(-0.15, 0.15)
		parts.append({"kind": "streak", "pos": BODY_CENTER, "vel": Vector2(cos(a), sin(a)) * 320.0, "drag": 0.9,
			"life": 0.0, "max_life": 0.22, "color": Color(1.0, 0.9, 0.7)})

func _update_guard(_delta: float) -> void:
	if t > 0.78 and not _spawned.has("scrap"):
		_spawned["scrap"] = true
		var origin = BODY_CENTER + Vector2(20, -2)
		for i in 16:
			var a = _rng.randf_range(-PI, 0.0)
			var v = Vector2(cos(a), sin(a)) * _rng.randf_range(90, 230)
			var gear = i % 3 != 0
			parts.append({"kind": "gear" if gear else "bolt", "pos": origin, "vel": v, "acc": Vector2(0, 520),
				"drag": 0.99, "life": 0.0, "max_life": _rng.randf_range(0.5, 0.8), "rot": _rng.randf() * TAU,
				"spin": _rng.randf_range(-14, 14), "size": _rng.randf_range(3.0, 5.5),
				"color": accent.lerp(Color(0.65, 0.68, 0.75), 0.35 if gear else 0.8)})
		parts.append({"kind": "ring", "pos": origin, "vel": Vector2.ZERO, "life": 0.0, "max_life": 0.35,
			"color": accent})
		for i in 4:
			_spawn_smoke()

# ── Çizim ────────────────────────────────────────────────────────────────────
func _soft_circle(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r, Color(col.r, col.g, col.b, col.a * 0.35))
	draw_circle(c, r * 0.7, Color(col.r, col.g, col.b, col.a * 0.55))
	draw_circle(c, r * 0.4, col)

func _draw() -> void:
	if cause == "laser":
		_draw_laser()
	else:
		_draw_guard()
	for p in parts:
		var k = p.life / p.max_life
		match p.kind:
			"spark":
				var tail = p.pos - p.vel.normalized() * min(10.0, p.vel.length() * 0.03)
				var c: Color = p.color
				draw_line(tail, p.pos, Color(c.r, c.g, c.b, 1.0 - k), 2.0, true)
			"streak":
				var tail2 = p.pos - p.vel.normalized() * 14.0 * (1.0 - k)
				draw_line(tail2, p.pos, Color(p.color.r, p.color.g, p.color.b, 1.0 - k), 3.0 * (1.0 - k) + 0.5, true)
			"smoke":
				var r = p.size * (1.0 + k * 2.2)
				var a = 0.32 * (1.0 - k) * min(1.0, p.life * 8.0)
				_soft_circle(p.pos, r, Color(0.28, 0.27, 0.3, a))
			"ash":
				var col = Color(1.0, 0.6 + 0.3 * (1.0 - k), 0.2, 1.0 - k) if p.hot else Color(0.35, 0.32, 0.3, 0.9 * (1.0 - k))
				if p.hot:
					draw_circle(p.pos, p.size * 2.2, Color(1.0, 0.45, 0.1, 0.25 * (1.0 - k)))
				draw_circle(p.pos, p.size * (1.0 - 0.4 * k), col)
			"ring":
				var rr = 6.0 + k * 34.0
				draw_arc(p.pos, rr, 0.0, TAU, 40, Color(p.color.r, p.color.g, p.color.b, 0.9 * (1.0 - k)), 3.0 * (1.0 - k) + 0.6, true)
			"gear":
				_draw_gear(p.pos, p.size, p.rot, Color(p.color.r, p.color.g, p.color.b, 1.0 - k * k))
			"bolt":
				var d = Vector2(cos(p.rot), sin(p.rot)) * p.size
				var bc = Color(p.color.r, p.color.g, p.color.b, 1.0 - k * k)
				draw_line(p.pos - d, p.pos + d, bc, 2.2, true)
				draw_circle(p.pos - d, 2.0, bc)

func _draw_laser() -> void:
	# Elektrik halesi
	if t < 0.62:
		var fade = 1.0 - t / 0.62
		var pulse = 0.6 + 0.4 * sin(t * 70.0)
		_soft_circle(BODY_CENTER, 34.0, Color(0.2, 0.75, 1.0, 0.22 * fade * pulse))
		for b in bolts:
			draw_polyline(b, Color(0.3, 0.8, 1.0, 0.35 * fade), 6.0, true)
			draw_polyline(b, Color(0.85, 0.97, 1.0, 0.95 * fade), 2.0, true)
	# Kor noktaları ve alev dilleri (kömürleşme anı)
	if t > 0.4 and t < 1.05:
		var heat = clamp((t - 0.4) / 0.15, 0.0, 1.0) * clamp((1.05 - t) / 0.25, 0.0, 1.0)
		for i in 7:
			var ex = sin(i * 2.7) * 9.0
			var ey = -24.0 + i * 6.5
			var fl = 0.6 + 0.4 * sin(t * 25.0 + i * 1.9)
			draw_circle(Vector2(ex, ey), 4.5 * fl, Color(1.0, 0.35, 0.05, 0.35 * heat))
			draw_circle(Vector2(ex, ey), 1.8 * fl, Color(1.0, 0.85, 0.4, 0.9 * heat))
		for i in 5:
			var fx = -10.0 + i * 5.0
			var base = Vector2(fx, -22.0 + abs(fx) * 0.4)
			var h = (9.0 + 6.0 * sin(t * 18.0 + i * 1.3)) * heat
			_flame(base, 3.0, h, Color(1.0, 0.45, 0.05, 0.85 * heat))
			_flame(base, 1.5, h * 0.55, Color(1.0, 0.92, 0.55, 0.9 * heat))

func _draw_guard() -> void:
	# Başının üstünde dönen sersemleme yıldızları
	if t > 0.3 and t < 0.9:
		var a = clamp((t - 0.3) / 0.1, 0.0, 1.0) * clamp((0.9 - t) / 0.15, 0.0, 1.0)
		# kahraman 2.5 tur dönüp sağa yatıyor: kafa gövdenin ~38 px sağında
		var head = BODY_CENTER + Vector2(36, -12)
		for i in 3:
			var ang = t * 9.0 + TAU * i / 3.0
			var p = head + Vector2(cos(ang) * 14.0, sin(ang) * 5.0)
			_star(p, 4.0, Color(1.0, 0.9, 0.3, a))

func _flame(base: Vector2, half_w: float, h: float, color: Color) -> void:
	if h < 1.0:
		return
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-half_w, 0), base + Vector2(-half_w * 0.6, -h * 0.5), base + Vector2(0, -h),
		base + Vector2(half_w * 0.6, -h * 0.5), base + Vector2(half_w, 0), base + Vector2(0, half_w * 0.5),
	]), color)

func _star(c: Vector2, r: float, color: Color) -> void:
	var pts = PackedVector2Array()
	for i in 10:
		var rr = r if i % 2 == 0 else r * 0.45
		var a = -PI / 2 + TAU * i / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, color)

func _draw_gear(c: Vector2, r: float, rot: float, color: Color) -> void:
	var pts = PackedVector2Array()
	for i in 16:
		var a = rot + TAU * i / 16.0
		var rr = r if (i / 2) % 2 == 0 else r * 0.72
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, color)
	draw_circle(c, r * 0.32, Color(0.08, 0.08, 0.1, color.a))
