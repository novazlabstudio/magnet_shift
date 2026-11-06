extends Node2D

# Her level'in arka planı. Level'in kendi renk paleti (bg / platform rengi) korunur; tema bg renginin
# tonundan seçilir, yerleşim level numarasından türetilen tohumla değişir (aynı temadaki level'ler de
# birbirinden farklı görünür).
#
# Katmanlar (arkadan öne):
#   sky   : ekrana sabit degrade (CanvasLayer -20)
#   far   : en yavaş kayan katman — büyük öğeler (güneş, gezegen, kara delik, dağlar, nebula)
#   anim  : uzak katmanda her kare çizilenler (yıldız parıltısı, kuzey ışığı, lav nabzı)
#   mid   : orta katman — siluetler (bulut/ada, yosun, kristal, kaya kuleleri, kum tepeleri)
#   near  : öne yakın, soluk büyük şekiller (derinlik hissi)
#   motes : ekrana sabit parçacıklar (kabarcık, kor, kar, toz, pırıltı) (CanvasLayer -5)
# Statik katmanlar (far/mid/near) level açılırken bir kez SubViewport'ta resme "pişirilir" ve
# her karede tek bir sprite olarak çizilir: binlerce şekil yerine katman başına 1 çizim çağrısı.
# Oynanabilirlik için hepsi düşük kontrastlı tutulur.

const THEME_TITLES = {
	"sky": "SKY ISLANDS", "ocean": "DEEP OCEAN", "nebula": "NEBULA DRIFT", "aurora": "AURORA PEAKS",
	"crystal": "CRYSTAL CAVERNS", "inferno": "INFERNO RIFT", "desert": "GOLDEN DUNES", "void": "EVENT HORIZON",
}
const FAR := 0.12
const MID := 0.32
const NEAR := 0.6
# Kameranın en yüksek tepe noktası (oyuncu çıkışa vardığında); katman kapsamı buna göre hesaplanır
const CAM_TOP_MIN := -900.0

var level: int = 1
var bg: Color = Color(0.05, 0.05, 0.15)
var pc: Color = Color(0.3, 0.5, 0.8)
var lh: float = 854.0
var theme: String = "nebula"
var theme_title: String = ""
var vh: float = 854.0
var cam_top0: float = 0.0
var layers: Array = []
var time: float = 0.0
var _seed: int = 0
var rng := RandomNumberGenerator.new()

func setup(level_number: int, bg_color: Color, platform_color: Color, level_height: float) -> void:
	level = level_number
	bg = bg_color
	pc = platform_color
	lh = level_height
	theme = _pick_theme()
	theme_title = THEME_TITLES[theme]
	_seed = level * 7919 + 101
	vh = get_viewport().get_visible_rect().size.y
	cam_top0 = lh + 40.0 - vh
	z_index = -50
	_build_sky()
	# (id, parallax, pişirme çözünürlüğü): uzak katmanda yıldızlar keskin kalsın diye tam çözünürlük
	var far = _add_baked_layer("far", FAR, 1.0)
	_add_layer("anim", FAR, true)
	var mid = _add_baked_layer("mid", MID, 0.75)
	var near = _add_baked_layer("near", NEAR, 0.5)
	_build_motes()
	_bake(far)
	_bake(mid)
	_bake(near)

func _pick_theme() -> String:
	var lum = bg.r * 0.299 + bg.g * 0.587 + bg.b * 0.114
	if lum > 0.35:
		return "sky"
	if bg.s < 0.12:
		return "void"
	var h = bg.h * 360.0
	if h >= 180.0 and h < 226.0:
		return "ocean"
	if h >= 226.0 and h < 256.0:
		return "nebula"
	if h >= 110.0 and h < 180.0:
		return "aurora"
	if h >= 256.0 and h < 322.0:
		return "crystal"
	if h >= 16.0 and h < 110.0:
		return "desert"
	return "inferno"

func _add_layer(id: String, factor: float, animated: bool) -> void:
	var n = Node2D.new()
	n.set_script(load("res://scripts/BackdropLayer.gd"))
	n.painter = self
	n.id = id
	n.animated = animated
	add_child(n)
	layers.append({"node": n, "factor": factor})

# Parallax ile kayan boş bir taşıyıcı; içine pişmiş resim sprite olarak konur
func _add_baked_layer(id: String, factor: float, res: float) -> Dictionary:
	var holder = Node2D.new()
	holder.name = "Layer_" + id
	add_child(holder)
	var entry = {"node": holder, "factor": factor, "id": id, "res": res}
	layers.append(entry)
	return entry

func _bake(entry: Dictionary) -> void:
	var span = _span(entry.factor)
	var k: float = entry.res
	var vp = SubViewport.new()
	vp.size = Vector2i(int(480 * k), int(ceil((span.y - span.x) * k)))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter = Node2D.new()
	painter.set_script(load("res://scripts/BackdropLayer.gd"))
	painter.painter = self
	painter.id = entry.id
	painter.position = Vector2(0, -span.x * k)
	painter.scale = Vector2(k, k)
	vp.add_child(painter)
	add_child(vp)
	await RenderingServer.frame_post_draw
	if not is_instance_valid(vp):
		return
	var tex = ImageTexture.create_from_image(vp.get_texture().get_image())
	vp.queue_free()
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.position = Vector2(0, span.x)
	spr.scale = Vector2(1.0 / k, 1.0 / k)
	# Saydam zemine çizilen renkler ön-çarpımlı (premultiplied) kaydedilir; öyle karıştır
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	spr.material = mat
	entry.node.add_child(spr)

func _process(delta: float) -> void:
	time += delta
	var xf = get_viewport().get_canvas_transform()
	var zoom = xf.get_scale().y
	var top = -xf.origin.y / zoom
	for l in layers:
		l.node.position.y = (top - cam_top0) * (1.0 - l.factor)

# Katmanın kapsaması gereken yerel y aralığı (x: üst, y: alt)
func _span(f: float) -> Vector2:
	return Vector2(cam_top0 - f * (cam_top0 - CAM_TOP_MIN) - 80.0, cam_top0 + vh + 80.0)

# Başlangıç ekranının yerel y'si (k=0 üst, 1 alt) — büyük öğeler oyuncu ilk bakışta görsün diye
func _start_y(k: float) -> float:
	return cam_top0 + vh * k

# ── Renk yardımcıları ────────────────────────────────────────────────────────
func _hue(c: Color, dh: float, s_mul: float = 1.0, v: float = -1.0) -> Color:
	return Color.from_hsv(fposmod(c.h + dh, 1.0), clamp(c.s * s_mul, 0.0, 1.0), c.v if v < 0.0 else v, c.a)

func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)

func _sky_colors() -> Array:
	match theme:
		"sky":
			return [bg.darkened(0.28), bg, bg.lightened(0.42).lerp(Color(1.0, 0.96, 0.88), 0.3)]
		"ocean":
			return [bg.lerp(pc, 0.55).lightened(0.12), bg.lerp(pc, 0.15), bg.darkened(0.55)]
		"inferno":
			return [bg.darkened(0.6), bg, bg.lerp(Color(1.0, 0.32, 0.05), 0.38)]
		"desert":
			return [bg.darkened(0.55), bg.lerp(pc, 0.15), bg.lerp(Color(1.0, 0.55, 0.18), 0.45)]
		"void":
			return [Color(0.0, 0.0, 0.01), Color(0.01, 0.01, 0.025), _a(pc * 0.16, 1.0)]
		"aurora":
			return [bg.darkened(0.6), bg, bg.lerp(_hue(pc, 0.08), 0.3).lightened(0.03)]
		_:
			return [bg.darkened(0.6), bg, bg.lerp(pc, 0.4).lightened(0.04)]

func _build_sky() -> void:
	var cl = CanvasLayer.new()
	cl.layer = -20
	add_child(cl)
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray(_sky_colors())
	var tex = GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 256
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(tr)

# ── Ekrana sabit parçacıklar ─────────────────────────────────────────────────
func _soft_dot() -> GradientTexture2D:
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
	var t = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t

func _build_motes() -> void:
	var cfg = {
		"sky": {"n": 14, "dir": Vector2(1, -0.2), "v": Vector2(8, 20), "g": Vector2(0, 0), "s": Vector2(0.07, 0.14), "c": Color(1, 1, 1, 0.55), "life": 10.0},
		"ocean": {"n": 30, "dir": Vector2(0, -1), "v": Vector2(18, 45), "g": Vector2(0, -12), "s": Vector2(0.08, 0.24), "c": _a(pc.lightened(0.45), 0.45), "life": 9.0},
		"nebula": {"n": 22, "dir": Vector2(0.3, -1), "v": Vector2(3, 9), "g": Vector2(0, 0), "s": Vector2(0.05, 0.12), "c": _a(pc.lightened(0.5), 0.7), "life": 8.0},
		"void": {"n": 22, "dir": Vector2(-0.3, -1), "v": Vector2(3, 9), "g": Vector2(0, 0), "s": Vector2(0.05, 0.11), "c": Color(0.9, 0.92, 1.0, 0.65), "life": 8.0},
		"aurora": {"n": 42, "dir": Vector2(0.2, 1), "v": Vector2(12, 26), "g": Vector2(0, 10), "s": Vector2(0.05, 0.13), "c": Color(0.92, 0.97, 1.0, 0.75), "life": 11.0},
		"crystal": {"n": 24, "dir": Vector2(0, -1), "v": Vector2(4, 14), "g": Vector2(0, 0), "s": Vector2(0.05, 0.16), "c": _a(pc.lightened(0.55), 0.8), "life": 7.0},
		"inferno": {"n": 40, "dir": Vector2(0.15, -1), "v": Vector2(30, 70), "g": Vector2(0, -14), "s": Vector2(0.05, 0.12), "c": Color(1.0, 0.55, 0.15, 0.95), "life": 6.0},
		"desert": {"n": 30, "dir": Vector2(1, 0.06), "v": Vector2(14, 40), "g": Vector2(0, 0), "s": Vector2(0.05, 0.11), "c": Color(1.0, 0.86, 0.6, 0.45), "life": 12.0},
	}[theme]
	var cl = CanvasLayer.new()
	cl.layer = -5
	add_child(cl)
	var p = CPUParticles2D.new()
	p.texture = _soft_dot()
	p.amount = cfg.n
	p.lifetime = cfg.life
	p.preprocess = cfg.life
	p.local_coords = false
	p.position = Vector2(240, vh * 0.5)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(250, vh * 0.55)
	p.direction = cfg.dir
	p.spread = 25.0
	p.gravity = cfg.g
	p.initial_velocity_min = cfg.v.x
	p.initial_velocity_max = cfg.v.y
	p.scale_amount_min = cfg.s.x
	p.scale_amount_max = cfg.s.y
	p.color = cfg.c
	var ramp = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	p.color_ramp = ramp
	cl.add_child(p)

# ── Ortak çizim yardımcıları ─────────────────────────────────────────────────
func _glow(ci: CanvasItem, c: Vector2, r: float, col: Color, rings: int = 8) -> void:
	for i in rings:
		var k = float(i + 1) / rings
		ci.draw_circle(c, r * (1.05 - k * 0.9), _a(col, col.a * k * k / rings * 3.0))

func _stars(ci: CanvasItem, span: Vector2, density: float, tint: Color) -> void:
	var n = int((span.y - span.x) * 480.0 / 1000.0 * density)
	for i in n:
		var p = Vector2(rng.randf_range(0, 480), rng.randf_range(span.x, span.y))
		var s = rng.randf_range(0.5, 1.6)
		var c = Color(1, 1, 1).lerp(tint, rng.randf() * 0.5)
		ci.draw_circle(p, s, _a(c, rng.randf_range(0.25, 0.85)))
		if s > 1.35:
			ci.draw_circle(p, s * 2.6, _a(c, 0.08))

func _ridge(ci: CanvasItem, base_y: float, height: float, rough: float, col: Color, peaks: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	pts.append(Vector2(-20, base_y + 400))
	var steps = 48
	var phase = rng.randf() * TAU
	var phase2 = rng.randf() * TAU
	for i in steps + 1:
		var x = -20.0 + 520.0 * i / steps
		var y = base_y - height * (0.55 + 0.45 * sin(x / 520.0 * TAU * peaks * 0.5 + phase)) \
			- rough * sin(x * 0.09 + phase2) - rough * 0.5 * sin(x * 0.23 + phase)
		pts.append(Vector2(x, y))
	pts.append(Vector2(500, base_y + 400))
	ci.draw_colored_polygon(pts, col)
	return pts

func _blob_poly(c: Vector2, r: float, verts: int, jag: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in verts:
		var a = TAU * i / verts
		pts.append(c + Vector2(cos(a), sin(a)) * r * rng.randf_range(1.0 - jag, 1.0 + jag * 0.4))
	return pts

func _twinkle(ci: CanvasItem, span: Vector2, count: int, tint: Color) -> void:
	var r2 = RandomNumberGenerator.new()
	r2.seed = _seed + 77
	for i in count:
		var p = Vector2(r2.randf_range(10, 470), r2.randf_range(span.x, span.y))
		var tw = 0.5 + 0.5 * sin(time * r2.randf_range(1.0, 3.2) + i * 1.7)
		var s = 1.2 + tw * 1.4
		var c = _a(Color(1, 1, 1).lerp(tint, 0.35), 0.35 + 0.6 * tw)
		ci.draw_line(p - Vector2(s * 2.2, 0), p + Vector2(s * 2.2, 0), _a(c, c.a * 0.6), 1.0)
		ci.draw_line(p - Vector2(0, s * 2.2), p + Vector2(0, s * 2.2), _a(c, c.a * 0.6), 1.0)
		ci.draw_circle(p, s * 0.6, c)

# ── Katman çizimi ────────────────────────────────────────────────────────────
func paint_layer(ci: CanvasItem, id: String) -> void:
	rng.seed = _seed + id.hash()
	var f = {"far": FAR, "anim": FAR, "mid": MID, "near": NEAR}[id]
	var span = _span(f)
	var fn = "_paint_%s_%s" % [theme, id]
	if has_method(fn):
		call(fn, ci, span)

# ─── SKY ISLANDS (gündüz) ────────────────────────────────────────────────────
func _paint_sky_far(ci: CanvasItem, span: Vector2) -> void:
	var sun = Vector2(rng.randf_range(300, 420), _start_y(0.22))
	_glow(ci, sun, 150, Color(1.0, 0.98, 0.85, 0.55))
	ci.draw_circle(sun, 30, Color(1.0, 0.98, 0.9, 0.9))
	var hz = span.y - 60
	_ridge(ci, hz - 40, 120, 14, _a(bg.lightened(0.18).lerp(Color(0.75, 0.82, 0.95), 0.4), 0.8), 3)
	_ridge(ci, hz + 10, 80, 10, _a(bg.darkened(0.05).lerp(pc, 0.2), 0.75), 4)
	for i in 3:
		_island(ci, Vector2(rng.randf_range(60, 420), rng.randf_range(span.x, _start_y(0.55))), rng.randf_range(0.35, 0.55), 0.45)

func _paint_sky_mid(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y - 120:
		_cloud(ci, Vector2(rng.randf_range(40, 440), y), rng.randf_range(0.7, 1.25), 0.9)
		if rng.randf() < 0.45:
			_island(ci, Vector2(rng.randf_range(80, 400), y + rng.randf_range(60, 120)), rng.randf_range(0.7, 1.0), 0.85)
		y += rng.randf_range(190, 260)

func _paint_sky_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		var side = -30.0 if rng.randf() < 0.5 else 510.0
		_cloud(ci, Vector2(side, y), rng.randf_range(1.6, 2.2), 0.28)
		y += rng.randf_range(420, 620)

func _cloud(ci: CanvasItem, c: Vector2, s: float, alpha: float) -> void:
	var shade = _a(bg.lightened(0.55).lerp(Color(0.8, 0.86, 0.96), 0.5), alpha)
	var body = _a(Color(1, 1, 1), alpha)
	var puffs = []
	for i in 7:
		puffs.append([c + Vector2(rng.randf_range(-48, 48), rng.randf_range(-14, 6)) * s, rng.randf_range(16, 30) * s])
	for p in puffs:
		ci.draw_circle(p[0] + Vector2(0, 6 * s), p[1], shade)
	for p in puffs:
		ci.draw_circle(p[0], p[1], body)
	for p in puffs:
		ci.draw_circle(p[0] + Vector2(-p[1] * 0.25, -p[1] * 0.3), p[1] * 0.45, _a(Color(1, 1, 1), alpha * 0.6))

func _island(ci: CanvasItem, c: Vector2, s: float, alpha: float) -> void:
	var w = rng.randf_range(60, 110) * s
	var depth = rng.randf_range(40, 70) * s
	var rock = _a(pc.darkened(0.35).lerp(Color(0.45, 0.38, 0.32), 0.5), alpha)
	var pts = PackedVector2Array([c + Vector2(-w, 0)])
	var n = 7
	for i in range(1, n):
		var x = -w + 2.0 * w * i / n
		var d = depth * (1.0 - pow(abs(x) / w, 1.6)) * rng.randf_range(0.75, 1.1)
		pts.append(c + Vector2(x, d))
	pts.append(c + Vector2(w, 0))
	ci.draw_colored_polygon(pts, rock)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w, 0), c + Vector2(w, 0), c + Vector2(w * 0.9, 7 * s), c + Vector2(-w * 0.9, 7 * s)]),
		_a(rock.darkened(0.2), alpha))
	var grass = _a(Color(0.45, 0.78, 0.35).lerp(pc, 0.2), alpha)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w - 3, 1), c + Vector2(-w * 0.6, -5 * s), c + Vector2(w * 0.5, -6 * s), c + Vector2(w + 3, 1)]), grass)
	for i in 3:
		var tx = c.x + rng.randf_range(-w * 0.6, w * 0.6)
		var th = rng.randf_range(14, 24) * s
		ci.draw_line(Vector2(tx, c.y - 2), Vector2(tx, c.y - th * 0.5), _a(Color(0.4, 0.3, 0.22), alpha), 2.0 * s)
		ci.draw_circle(Vector2(tx, c.y - th * 0.7), th * 0.4, _a(Color(0.3, 0.6, 0.3).lerp(pc, 0.15), alpha))

# ─── DEEP OCEAN ──────────────────────────────────────────────────────────────
func _paint_ocean_far(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	var ray = _a(pc.lightened(0.55), 0.07)
	while y < span.y:
		for i in 4:
			var x0 = rng.randf_range(-40, 480)
			var w = rng.randf_range(18, 46)
			var ln = rng.randf_range(420, 700)
			var dx = ln * 0.25
			ci.draw_polygon(PackedVector2Array([Vector2(x0, y), Vector2(x0 + w, y), Vector2(x0 + w + dx, y + ln), Vector2(x0 + dx, y + ln)]),
				PackedColorArray([ray, ray, _a(ray, 0), _a(ray, 0)]))
		y += rng.randf_range(650, 900)
	_stars(ci, span, 0.08, pc.lightened(0.5))
	var hz = span.y - 50
	var reef = _a(bg.lerp(pc, 0.35).darkened(0.2), 0.85)
	_ridge(ci, hz, 70, 18, reef, 5)

func _paint_ocean_mid(ci: CanvasItem, span: Vector2) -> void:
	var kelp = _a(bg.lerp(Color(0.1, 0.45, 0.35), 0.55).lerp(pc, 0.15), 0.75)
	var y = span.x + 100
	while y < span.y:
		var x = rng.randf_range(30, 80) if rng.randf() < 0.5 else rng.randf_range(400, 450)
		var h = rng.randf_range(160, 300)
		var pts = PackedVector2Array()
		var ph = rng.randf() * TAU
		for i in 13:
			var k = float(i) / 12.0
			pts.append(Vector2(x + sin(k * 5.0 + ph) * 10.0 * k, y - h * k))
		ci.draw_polyline(pts, kelp, 5.0, true)
		for i in range(2, 12, 2):
			var p = pts[i]
			var side = 1.0 if i % 4 == 0 else -1.0
			ci.draw_set_transform(p, side * 0.6, Vector2(1, 0.35))
			ci.draw_circle(Vector2(side * 9, 0), 9, kelp)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if rng.randf() < 0.5:
			_jelly(ci, Vector2(rng.randf_range(120, 360), y - rng.randf_range(80, 200)), rng.randf_range(0.7, 1.2))
		y += rng.randf_range(260, 360)
	var hz = span.y - 30
	for i in 7:
		_coral(ci, Vector2(rng.randf_range(20, 460), hz + rng.randf_range(-10, 20)), rng.randf_range(0.7, 1.3))

func _paint_ocean_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		_glow(ci, Vector2(rng.randf_range(0, 480), y), rng.randf_range(60, 110), _a(pc.lightened(0.6), 0.1), 5)
		y += rng.randf_range(300, 500)

func _jelly(ci: CanvasItem, c: Vector2, s: float) -> void:
	var col = pc.lightened(0.45)
	_glow(ci, c, 34 * s, _a(col, 0.25), 5)
	var bell = PackedVector2Array()
	for i in 13:
		var a = PI + PI * i / 12.0
		bell.append(c + Vector2(cos(a) * 15 * s, sin(a) * 12 * s))
	ci.draw_colored_polygon(bell, _a(col, 0.35))
	for i in 4:
		var x = c.x - 9 * s + i * 6 * s
		var pts = PackedVector2Array()
		for j in 6:
			pts.append(Vector2(x + sin(j * 1.1 + i) * 3 * s, c.y + j * 7 * s))
		ci.draw_polyline(pts, _a(col, 0.3), 1.2, true)

func _coral(ci: CanvasItem, base: Vector2, s: float) -> void:
	var col = _a(bg.lerp(pc, 0.5).lerp(Color(0.9, 0.4, 0.5), 0.25), 0.7)
	_branch(ci, base, -PI / 2, 34 * s, 4, col, 4.0 * s)

func _branch(ci: CanvasItem, p: Vector2, ang: float, ln: float, depth: int, col: Color, w: float) -> void:
	if depth <= 0 or ln < 4:
		ci.draw_circle(p, w * 0.9, col)
		return
	var q = p + Vector2(cos(ang), sin(ang)) * ln
	ci.draw_line(p, q, col, w, true)
	_branch(ci, q, ang - rng.randf_range(0.3, 0.6), ln * 0.7, depth - 1, col, w * 0.75)
	_branch(ci, q, ang + rng.randf_range(0.3, 0.6), ln * 0.7, depth - 1, col, w * 0.75)

# ─── NEBULA DRIFT ────────────────────────────────────────────────────────────
func _paint_nebula_far(ci: CanvasItem, span: Vector2) -> void:
	_stars(ci, span, 0.55, pc.lightened(0.4))
	var y = span.x
	while y < span.y:
		var col = [_hue(pc, 0.08, 1.0, 0.8), _hue(bg, -0.12, 0.9, 0.6), Color(0.85, 0.3, 0.75)][rng.randi() % 3]
		_glow(ci, Vector2(rng.randf_range(40, 440), y), rng.randf_range(140, 230), _a(col, 0.32), 9)
		y += rng.randf_range(380, 560)
	_planet(ci, Vector2(rng.randf_range(110, 370), _start_y(0.3)), rng.randf_range(38, 62), rng.randf() < 0.7)

func _paint_nebula_anim(ci: CanvasItem, span: Vector2) -> void:
	_twinkle(ci, span, 28, pc.lightened(0.4))

func _paint_nebula_mid(ci: CanvasItem, span: Vector2) -> void:
	_asteroids(ci, span, _a(bg.lerp(pc, 0.3).lightened(0.12), 0.85))

func _paint_nebula_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		var x = rng.randf_range(0, 480)
		ci.draw_polygon(PackedVector2Array([Vector2(x - 200, y), Vector2(x + 220, y - 60), Vector2(x + 220, y - 50), Vector2(x - 200, y + 14)]),
			PackedColorArray([_a(pc, 0.0), _a(pc.lightened(0.4), 0.07), _a(pc.lightened(0.4), 0.07), _a(pc, 0.0)]))
		y += rng.randf_range(500, 800)

func _planet(ci: CanvasItem, c: Vector2, r: float, ringed: bool) -> void:
	var base = _hue(pc, rng.randf_range(-0.15, 0.15), 0.8, 0.55)
	_glow(ci, c, r * 2.0, _a(base.lightened(0.3), 0.3), 7)
	var ring_col = _a(base.lightened(0.45), 0.55)
	if ringed:
		ci.draw_set_transform(c, -0.32, Vector2(1, 0.28))
		ci.draw_arc(Vector2.ZERO, r * 1.75, PI, TAU, 48, ring_col, 5.0, true)
		ci.draw_arc(Vector2.ZERO, r * 1.5, PI, TAU, 48, _a(ring_col, 0.3), 3.0, true)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_circle(c, r, base)
	for i in 4:
		var by = c.y - r * 0.6 + i * r * 0.35
		var hw = sqrt(max(0.0, r * r - pow(by - c.y, 2)))
		ci.draw_line(Vector2(c.x - hw, by), Vector2(c.x + hw, by), _a(base.lightened(0.15 + 0.05 * i), 0.35), r * 0.14)
	ci.draw_circle(c + Vector2(r * 0.35, r * 0.25), r * 0.92, _a(Color(0, 0, 0), 0.35))
	ci.draw_arc(c, r, -2.4, -0.6, 32, _a(base.lightened(0.6), 0.7), 2.0, true)
	if ringed:
		ci.draw_set_transform(c, -0.32, Vector2(1, 0.28))
		ci.draw_arc(Vector2.ZERO, r * 1.75, 0, PI, 48, ring_col, 5.0, true)
		ci.draw_arc(Vector2.ZERO, r * 1.5, 0, PI, 48, _a(ring_col, 0.3), 3.0, true)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var moon = c + Vector2(r * 1.9, -r * 0.9)
		ci.draw_circle(moon, r * 0.22, base.lightened(0.35))
		ci.draw_circle(moon + Vector2(r * 0.06, r * 0.05), r * 0.2, _a(Color(0, 0, 0), 0.3))

func _asteroids(ci: CanvasItem, span: Vector2, col: Color) -> void:
	var y = span.x
	while y < span.y:
		var c = Vector2(rng.randf_range(30, 450), y)
		var r = rng.randf_range(6, 17)
		var pts = _blob_poly(c, r, 9, 0.35)
		ci.draw_colored_polygon(pts, col.darkened(0.35))
		ci.draw_arc(c, r * 0.85, -2.6, -1.0, 12, _a(col.lightened(0.35), 0.7), 2.0, true)
		ci.draw_circle(c + Vector2(r * 0.25, r * 0.1), r * 0.22, _a(col.darkened(0.55), 0.8))
		y += rng.randf_range(110, 210)

# ─── AURORA PEAKS ────────────────────────────────────────────────────────────
func _paint_aurora_far(ci: CanvasItem, span: Vector2) -> void:
	_stars(ci, span, 0.45, Color(0.8, 1.0, 0.95))
	var hz = span.y - 70
	var far_col = _a(bg.lerp(pc, 0.25).lightened(0.06), 0.9)
	var pts = _ridge(ci, hz - 30, 170, 22, far_col, 3)
	# kar örtüsü: zirvelerin üst kısmı
	for i in range(1, pts.size() - 2):
		var p = pts[i]
		if p.y < hz - 150:
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 10), p + Vector2(0, -1), p + Vector2(9, 10)]), Color(0.92, 0.97, 1.0, 0.75))
	_ridge(ci, hz + 20, 90, 14, _a(bg.darkened(0.3).lerp(pc, 0.12), 0.95), 5)

func _paint_aurora_anim(ci: CanvasItem, span: Vector2) -> void:
	var r2 = RandomNumberGenerator.new()
	r2.seed = _seed + 5
	# ilk perde başlangıç ekranının üst kısmında, diğerleri yukarı doğru aralıklı
	var ys = [_start_y(0.38)]
	var yy0 = _start_y(0.38) - r2.randf_range(650, 850)
	while yy0 > span.x + 100:
		ys.append(yy0)
		yy0 -= r2.randf_range(700, 950)
	for y in ys:
		var c1 = _hue(pc, 0.0, 1.0, 0.95)
		var c2 = _hue(pc, r2.randf_range(0.12, 0.25), 1.0, 0.9)
		var ph = r2.randf() * TAU
		var h = r2.randf_range(110, 170)
		var prev = Vector2.ZERO
		for i in 61:
			var x = -10.0 + 500.0 * i / 60.0
			var yy = y + sin(x * 0.018 + time * 0.45 + ph) * 26.0 + sin(x * 0.047 - time * 0.8) * 9.0
			var cur = Vector2(x, yy)
			if i > 0:
				var k = float(i) / 60.0
				var col = c1.lerp(c2, k)
				var a = 0.3 * (0.55 + 0.45 * sin(x * 0.03 + time * 1.3 + ph))
				ci.draw_polygon(PackedVector2Array([prev, cur, cur - Vector2(0, h), prev - Vector2(0, h)]),
					PackedColorArray([_a(col, a), _a(col, a), _a(col, 0.0), _a(col, 0.0)]))
			prev = cur
	_twinkle(ci, span, 16, Color(0.8, 1.0, 0.95))

func _paint_aurora_mid(ci: CanvasItem, span: Vector2) -> void:
	var ice = _a(Color(0.75, 0.92, 1.0).lerp(pc, 0.25), 0.55)
	var y = span.x
	while y < span.y - 150:
		var c = Vector2(rng.randf_range(40, 440), y)
		var r = rng.randf_range(10, 22)
		var pts = PackedVector2Array([c + Vector2(0, -r * 1.6), c + Vector2(r * 0.7, -r * 0.2), c + Vector2(r * 0.3, r * 1.1), c + Vector2(-r * 0.5, r * 0.9), c + Vector2(-r * 0.8, -r * 0.3)])
		ci.draw_colored_polygon(pts, ice)
		ci.draw_line(pts[0], pts[2], _a(Color(1, 1, 1), 0.45), 1.5, true)
		y += rng.randf_range(170, 280)
	var hz = span.y - 40
	for i in 9:
		_pine(ci, Vector2(rng.randf_range(0, 480), hz + rng.randf_range(-8, 14)), rng.randf_range(0.7, 1.3))

func _pine(ci: CanvasItem, base: Vector2, s: float) -> void:
	var col = _a(bg.darkened(0.45).lerp(pc, 0.08), 0.95)
	for i in 3:
		var w = (16 - i * 4) * s
		var yb = base.y - i * 12 * s
		ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - w, yb), Vector2(base.x, yb - 22 * s), Vector2(base.x + w, yb)]), col)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - w * 0.5, yb - 11 * s), Vector2(base.x, yb - 22 * s), Vector2(base.x + w * 0.5, yb - 11 * s)]), Color(0.9, 0.96, 1.0, 0.5))

func _paint_aurora_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		_glow(ci, Vector2(rng.randf_range(0, 480), y), rng.randf_range(80, 140), Color(0.85, 0.95, 1.0, 0.07), 5)
		y += rng.randf_range(350, 550)

# ─── CRYSTAL CAVERNS ─────────────────────────────────────────────────────────
func _paint_crystal_far(ci: CanvasItem, span: Vector2) -> void:
	var wall = _a(bg.lerp(pc, 0.18).lightened(0.03), 1.0)
	var vein = _a(pc.lightened(0.35), 0.35)
	for side in [0, 1]:
		var pts = PackedVector2Array()
		var x_edge = 0.0 if side == 0 else 480.0
		pts.append(Vector2(x_edge, span.x))
		var y = span.x
		while y < span.y:
			var d = rng.randf_range(25, 70)
			pts.append(Vector2(d if side == 0 else 480.0 - d, y))
			y += rng.randf_range(40, 90)
		pts.append(Vector2(x_edge, span.y))
		ci.draw_colored_polygon(pts, wall)
		for i in range(1, pts.size() - 2, 3):
			var a = pts[i]
			var b = pts[i + 1].lerp(Vector2(x_edge, pts[i + 1].y), 0.5)
			ci.draw_line(a, b, vein, 1.5, true)
	var y2 = span.x
	while y2 < span.y:
		_glow(ci, Vector2(rng.randf_range(80, 400), y2), rng.randf_range(120, 200), _a(_hue(pc, 0.06, 1.0, 0.7), 0.22), 7)
		y2 += rng.randf_range(450, 650)

func _paint_crystal_anim(ci: CanvasItem, span: Vector2) -> void:
	_twinkle(ci, span, 22, pc.lightened(0.5))

func _paint_crystal_mid(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x + 60
	while y < span.y:
		var left = rng.randf() < 0.5
		var base = Vector2(rng.randf_range(10, 60) if left else rng.randf_range(420, 470), y)
		# kristaller duvardan içeriye ve yukarı doğru büyür
		var dir = -PI / 2 + (0.55 if left else -0.55)
		for i in rng.randi_range(3, 5):
			var ang = dir + rng.randf_range(-0.45, 0.45)
			_crystal(ci, base + Vector2(rng.randf_range(-8, 8), rng.randf_range(-6, 6)), ang, rng.randf_range(24, 52), rng.randf_range(6, 11))
		if rng.randf() < 0.5:
			var fc = Vector2(rng.randf_range(140, 340), y - rng.randf_range(60, 140))
			_crystal(ci, fc + Vector2(0, 14), -PI / 2, 22, 8)
			_crystal(ci, fc - Vector2(0, 14), PI / 2, 14, 8)
		y += rng.randf_range(200, 300)

func _crystal(ci: CanvasItem, base: Vector2, ang: float, ln: float, w: float) -> void:
	var col = _hue(pc, rng.randf_range(-0.05, 0.08), 0.9, 0.75)
	var d = Vector2(cos(ang), sin(ang))
	var n = d.orthogonal()
	var tip = base + d * ln
	var shoulder = base + d * (ln * 0.78)
	_glow(ci, base + d * ln * 0.5, ln * 0.9, _a(col.lightened(0.2), 0.16), 5)
	ci.draw_colored_polygon(PackedVector2Array([base - n * w, shoulder - n * w, tip, base]), _a(col.darkened(0.25), 0.85))
	ci.draw_colored_polygon(PackedVector2Array([base, tip, shoulder + n * w, base + n * w]), _a(col.lightened(0.15), 0.85))
	ci.draw_line(base, tip, _a(Color(1, 1, 1), 0.5), 1.2, true)

func _paint_crystal_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		var left = rng.randf() < 0.5
		_crystal(ci, Vector2(-10 if left else 490, y), -PI / 2 + (0.6 if left else -0.6), rng.randf_range(90, 140), 22)
		y += rng.randf_range(500, 750)

# ─── INFERNO RIFT ────────────────────────────────────────────────────────────
func _paint_inferno_far(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y - 300:
		_glow(ci, Vector2(rng.randf_range(0, 480), y), rng.randf_range(150, 240), Color(0.15, 0.06, 0.05, 0.5), 6)
		y += rng.randf_range(300, 450)
	var hz = span.y - 60
	var rock = _a(bg.lerp(Color(0.1, 0.03, 0.02), 0.5), 1.0)
	for i in 2:
		var cx = rng.randf_range(80, 400) if i == 0 else fposmod(rng.randf_range(80, 400) + 220.0, 480.0)
		var top_y = hz - rng.randf_range(150, 230) + i * 40
		var w = rng.randf_range(150, 210)
		var crater = 22.0
		var pts = PackedVector2Array([Vector2(cx - w, hz + 80), Vector2(cx - crater, top_y), Vector2(cx + crater, top_y), Vector2(cx + w, hz + 80)])
		ci.draw_colored_polygon(pts, rock.lightened(0.03 * i))
		_glow(ci, Vector2(cx, top_y), 70, Color(1.0, 0.45, 0.1, 0.5), 7)
		for j in 3:
			var lx = cx + rng.randf_range(-crater, crater)
			var lava = PackedVector2Array([Vector2(lx, top_y)])
			for k in 6:
				lava.append(Vector2(lx + (k + 1) * rng.randf_range(-12, 12) * 0.6, top_y + (k + 1) * (hz - top_y) / 6.5))
			ci.draw_polyline(lava, Color(1.0, 0.45, 0.08, 0.75), 2.5, true)
		for j in 4:
			_glow(ci, Vector2(cx + rng.randf_range(-20, 20), top_y - 40 - j * 45), 30 + j * 14, Color(0.12, 0.08, 0.08, 0.45), 5)
	_ridge(ci, hz + 30, 50, 12, _a(rock.darkened(0.3), 1.0), 6)

func _paint_inferno_anim(ci: CanvasItem, span: Vector2) -> void:
	var hz = span.y - 60
	var pulse = 0.5 + 0.5 * sin(time * 2.2)
	ci.draw_polygon(PackedVector2Array([Vector2(-10, hz - 40), Vector2(490, hz - 40), Vector2(490, hz + 120), Vector2(-10, hz + 120)]),
		PackedColorArray([Color(1.0, 0.3, 0.05, 0.0), Color(1.0, 0.3, 0.05, 0.0), Color(1.0, 0.35, 0.05, 0.12 + 0.08 * pulse), Color(1.0, 0.35, 0.05, 0.12 + 0.08 * pulse)]))

func _paint_inferno_mid(ci: CanvasItem, span: Vector2) -> void:
	var rock = bg.lerp(Color(0.12, 0.04, 0.03), 0.6).lightened(0.04)
	var y = span.x
	while y < span.y - 80:
		var left = rng.randf() < 0.5
		var bx = rng.randf_range(0, 70) if left else rng.randf_range(410, 480)
		var h = rng.randf_range(90, 170)
		var w = rng.randf_range(22, 40)
		var pts = PackedVector2Array([Vector2(bx - w, y + 30), Vector2(bx - w * 0.45, y - h * 0.55), Vector2(bx + rng.randf_range(-6, 6), y - h),
			Vector2(bx + w * 0.4, y - h * 0.5), Vector2(bx + w, y + 30)])
		ci.draw_colored_polygon(pts, _a(rock, 0.95))
		var crack = PackedVector2Array([Vector2(bx, y - h * 0.85)])
		for k in 5:
			crack.append(Vector2(bx + rng.randf_range(-w * 0.35, w * 0.35), y - h * 0.85 + (k + 1) * h * 0.18))
		ci.draw_polyline(crack, Color(1.0, 0.4, 0.08, 0.35), 4.0, true)
		ci.draw_polyline(crack, Color(1.0, 0.75, 0.3, 0.85), 1.5, true)
		if rng.randf() < 0.45:
			var c = Vector2(rng.randf_range(140, 340), y - rng.randf_range(40, 120))
			var bp = _blob_poly(c, rng.randf_range(10, 18), 8, 0.3)
			ci.draw_colored_polygon(bp, _a(rock, 0.9))
			ci.draw_line(bp[1], bp[5], Color(1.0, 0.55, 0.15, 0.7), 1.5, true)
		y += rng.randf_range(220, 320)

func _paint_inferno_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		_glow(ci, Vector2(rng.randf_range(0, 480), y), rng.randf_range(90, 150), Color(0.08, 0.04, 0.04, 0.35), 5)
		y += rng.randf_range(350, 550)

# ─── GOLDEN DUNES ────────────────────────────────────────────────────────────
func _paint_desert_far(ci: CanvasItem, span: Vector2) -> void:
	_stars(ci, Vector2(span.x, _start_y(0.15)), 0.3, Color(1.0, 0.9, 0.7))
	var sun = Vector2(rng.randf_range(150, 330), _start_y(0.5))
	var r = rng.randf_range(70, 95)
	_glow(ci, sun, r * 2.4, Color(1.0, 0.6, 0.2, 0.45), 9)
	var top_c = Color(1.0, 0.85, 0.35)
	var bot_c = Color(1.0, 0.35, 0.35)
	var slices = 22
	for i in slices:
		var y0 = sun.y - r + 2.0 * r * i / slices
		var y1 = sun.y - r + 2.0 * r * (i + 1) / slices
		var k = float(i) / slices
		# alt yarıda kesik çizgiler (gün batımı güneşi)
		if k > 0.55 and i % 3 == 0:
			continue
		var hw0 = sqrt(max(0.0, r * r - pow(y0 - sun.y, 2)))
		var hw1 = sqrt(max(0.0, r * r - pow(y1 - sun.y, 2)))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sun.x - hw0, y0), Vector2(sun.x + hw0, y0), Vector2(sun.x + hw1, y1), Vector2(sun.x - hw1, y1)]),
			top_c.lerp(bot_c, k))
	var hz = span.y - 70
	var sil = _a(bg.lerp(Color(0.25, 0.1, 0.05), 0.4), 1.0)
	for i in 3:
		var px = rng.randf_range(30, 450)
		var ph = rng.randf_range(50, 110)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(px - ph * 0.95, hz), Vector2(px, hz - ph), Vector2(px + ph * 0.95, hz)]), sil.lightened(0.04 * i))
	_ridge(ci, hz + 20, 40, 6, sil.darkened(0.2), 2)

func _paint_desert_mid(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x + 80
	var rune = pc.lightened(0.35)
	while y < span.y - 260:
		var x = rng.randf_range(40, 90) if rng.randf() < 0.5 else rng.randf_range(390, 440)
		var h = rng.randf_range(70, 120)
		var w = rng.randf_range(12, 18)
		_glow(ci, Vector2(x, y - h * 0.5), h * 0.9, _a(rune, 0.2), 6)
		var stone = _a(bg.lerp(Color(0.2, 0.12, 0.06), 0.5).lightened(0.05), 0.95)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w, y), Vector2(x - w * 0.7, y - h), Vector2(x, y - h - w * 0.9), Vector2(x + w * 0.7, y - h), Vector2(x + w, y)]), stone)
		for k in 4:
			var ry = y - h * (0.2 + 0.18 * k)
			ci.draw_line(Vector2(x - w * 0.35, ry), Vector2(x + w * 0.35, ry - 4), _a(rune, 0.85), 1.6, true)
		ci.draw_set_transform(Vector2(x, y + 12), 0.0, Vector2(1, 0.3))
		ci.draw_circle(Vector2.ZERO, w * 1.8, _a(Color(0, 0, 0), 0.25))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		y += rng.randf_range(300, 420)
	var hz = span.y - 40
	for i in 3:
		var col = _a(bg.lerp(Color(0.85, 0.5, 0.2), 0.3 - i * 0.07).darkened(0.1 + i * 0.12), 1.0)
		_dune(ci, hz - 30 + i * 32, 30 - i * 5, col)

func _dune(ci: CanvasItem, base_y: float, amp: float, col: Color) -> void:
	var pts = PackedVector2Array([Vector2(-20, base_y + 300)])
	var ph = rng.randf() * TAU
	var freq = rng.randf_range(0.008, 0.014)
	for i in 41:
		var x = -20.0 + 520.0 * i / 40.0
		pts.append(Vector2(x, base_y - amp * (0.5 + 0.5 * sin(x * freq + ph))))
	pts.append(Vector2(500, base_y + 300))
	ci.draw_colored_polygon(pts, col)
	var crest = PackedVector2Array()
	for i in range(1, pts.size() - 1):
		crest.append(pts[i])
	ci.draw_polyline(crest, _a(col.lightened(0.25), 0.6), 1.5, true)

func _paint_desert_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		_glow(ci, Vector2(rng.randf_range(0, 480), y), rng.randf_range(100, 160), Color(1.0, 0.75, 0.45, 0.06), 5)
		y += rng.randf_range(400, 600)

# ─── EVENT HORIZON (kara delik) ──────────────────────────────────────────────
func _paint_void_far(ci: CanvasItem, span: Vector2) -> void:
	_stars(ci, span, 0.9, Color(0.75, 0.85, 1.0))
	var y = span.x
	while y < span.y - 400:
		_galaxy(ci, Vector2(rng.randf_range(60, 420), y), rng.randf_range(40, 70))
		y += rng.randf_range(700, 1000)
	_black_hole(ci, Vector2(rng.randf_range(150, 330), _start_y(0.32)), rng.randf_range(34, 46))

func _paint_void_anim(ci: CanvasItem, span: Vector2) -> void:
	_twinkle(ci, span, 30, Color(0.8, 0.9, 1.0))

func _paint_void_mid(ci: CanvasItem, span: Vector2) -> void:
	_asteroids(ci, span, _a(Color(0.35, 0.36, 0.42).lerp(pc, 0.2), 0.8))

func _paint_void_near(ci: CanvasItem, span: Vector2) -> void:
	var y = span.x
	while y < span.y:
		var x = rng.randf_range(40, 440)
		var ln = rng.randf_range(60, 120)
		ci.draw_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + ln, y - ln * 0.35), Vector2(x + ln, y - ln * 0.35 + 2), Vector2(x, y + 2.5)]),
			PackedColorArray([Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.5)]))
		ci.draw_circle(Vector2(x, y + 1), 2.2, Color(1, 1, 1, 0.8))
		y += rng.randf_range(600, 900)

func _galaxy(ci: CanvasItem, c: Vector2, r: float) -> void:
	var col = _hue(pc, rng.randf_range(-0.1, 0.1), 0.6, 0.9)
	_glow(ci, c, r, _a(col, 0.35), 6)
	ci.draw_set_transform(c, rng.randf_range(-0.6, 0.6), Vector2(1, 0.45))
	for arm in 2:
		for i in 60:
			var k = float(i) / 60.0
			var a = arm * PI + k * TAU * 1.2
			var p = Vector2(cos(a), sin(a)) * r * k
			ci.draw_circle(p + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)), rng.randf_range(0.6, 1.4), _a(Color(1, 1, 1).lerp(col, 0.4), 0.55 * (1.0 - k * 0.6)))
	ci.draw_circle(Vector2.ZERO, r * 0.12, Color(1, 0.97, 0.9, 0.9))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _black_hole(ci: CanvasItem, c: Vector2, r: float) -> void:
	var hot = pc.lightened(0.2)
	_glow(ci, c, r * 3.2, _a(hot, 0.35), 9)
	var disk_back = [Color(1.0, 0.95, 0.8), hot, Color(1.0, 0.45, 0.15)]
	# diskin arka yarısı (merkezin üstünden bükülen ışık)
	ci.draw_set_transform(c, -0.18, Vector2(1, 0.3))
	for i in 7:
		var rr = r * (1.35 + i * 0.22)
		var col = disk_back[i % 3].lerp(hot, 0.4)
		ci.draw_arc(Vector2.ZERO, rr, PI, TAU, 64, _a(col, 0.55 - i * 0.05), 4.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# kütle çekimiyle bükülmüş üst halka
	ci.draw_arc(c, r * 1.15, PI + 0.15, TAU - 0.15, 48, _a(Color(1.0, 0.9, 0.7), 0.75), 3.0, true)
	ci.draw_arc(c, r * 1.3, PI + 0.3, TAU - 0.3, 48, _a(hot, 0.45), 4.0, true)
	ci.draw_circle(c, r, Color(0, 0, 0, 1))
	ci.draw_arc(c, r * 1.02, 0.0, TAU, 64, _a(Color(1.0, 0.92, 0.75), 0.9), 1.6, true)
	# diskin ön yarısı
	ci.draw_set_transform(c, -0.18, Vector2(1, 0.3))
	for i in 7:
		var rr2 = r * (1.35 + i * 0.22)
		var col2 = disk_back[(i + 1) % 3].lerp(hot, 0.3)
		ci.draw_arc(Vector2.ZERO, rr2, 0.0, PI, 64, _a(col2, 0.8 - i * 0.07), 4.5, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
