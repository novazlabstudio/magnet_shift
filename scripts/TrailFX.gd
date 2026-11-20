extends Node2D

# Kahramanın arkasında mağazadan alınan hareket izi (yalnızca görünüm; oynanışa etkisi yok).
# Level'in içine eklenir (dünya koordinatı); oyuncunun son konumlarını tutar.

var target: Node2D = null
var style: String = "none"
var c1: Color = Color.WHITE
var c2: Color = Color.WHITE
var _pts: Array = []      # [{p: Vector2, t: float}]
var _sparks: Array = []   # [{p, v, life}]
var _t: float = 0.0
const LIFE := 0.38

func setup(player: Node2D, trail_id: String) -> void:
	target = player
	style = trail_id
	var info = Progress.trail_info(trail_id)
	c1 = info["c1"]
	c2 = info["c2"]
	z_index = 1
	set_process(style != "none")

func _process(delta: float) -> void:
	_t += delta
	if target == null or not is_instance_valid(target):
		return
	var dead = target.get("is_dead") == true
	# Kendi koordinatıma çevir: level'de (orijinde) de mağaza kartında da doğru yerde çizilsin
	var p = to_local(target.global_position)
	var moving = _pts.is_empty() or p.distance_to(_pts.back()["p"]) > 1.5
	if moving and not dead:
		_pts.append({"p": p, "t": _t})
		if style in ["spark", "stardust", "golden"] and randf() < 0.55:
			_sparks.append({"p": p + Vector2(randf_range(-8, 8), randf_range(-8, 8)),
				"v": Vector2(randf_range(-30, 30), randf_range(-30, 30)), "life": 0.5})
	while not _pts.is_empty() and _t - _pts[0]["t"] > LIFE:
		_pts.pop_front()
	for s in _sparks:
		s["life"] -= delta
		s["p"] += s["v"] * delta
	_sparks = _sparks.filter(func(s): return s["life"] > 0.0)
	queue_redraw()

func _col(k: float, idx: int) -> Color:
	# k: 0 = kuyruk, 1 = kahramanın yanı
	match style:
		"rainbow":
			return Color.from_hsv(fmod(_t * 0.6 + idx * 0.045, 1.0), 0.85, 1.0, k)
		"field":
			return (c1 if (idx / 3) % 2 == 0 else c2) * Color(1, 1, 1, k)
		"fire":
			var flick = 0.85 + 0.15 * sin(_t * 30.0 + idx)
			return c2.lerp(c1, k) * Color(1, 1, 1, k * flick)
		_:
			return c2.lerp(c1, k) * Color(1, 1, 1, k)

func _draw() -> void:
	var n = _pts.size()
	if n >= 2:
		var base_w = {"spark": 3.0, "neon": 7.0, "fire": 12.0, "ice": 8.0, "rainbow": 9.0,
			"stardust": 5.0, "field": 5.0, "golden": 10.0}.get(style, 6.0)
		for i in range(1, n):
			var k = float(i) / float(n - 1)
			var a = _pts[i - 1]["p"]
			var b = _pts[i]["p"]
			if style == "field":
				var dir = (b - a).normalized().orthogonal()
				a += dir * sin(_t * 18.0 + i * 0.9) * 5.0
				b += dir * sin(_t * 18.0 + (i + 1) * 0.9) * 5.0
			var w = base_w * (0.25 + 0.75 * k)
			var col = _col(k, i)
			if style in ["neon", "golden", "fire", "ice", "rainbow"]:
				draw_line(a, b, Color(col.r, col.g, col.b, col.a * 0.25), w * 2.2)
			draw_line(a, b, col, w)
			if style == "ice" and i % 4 == 0:
				var c = Color(1, 1, 1, k * 0.9)
				draw_line(b + Vector2(-4, 0), b + Vector2(4, 0), c, 1.5)
				draw_line(b + Vector2(0, -4), b + Vector2(0, 4), c, 1.5)
	for s in _sparks:
		var a = clamp(s["life"] / 0.5, 0.0, 1.0)
		var sc = c1 if randf() < 0.5 else c2
		if style == "stardust":
			var r = 3.0 * a
			draw_line(s["p"] + Vector2(-r, 0), s["p"] + Vector2(r, 0), Color(sc.r, sc.g, sc.b, a), 1.5)
			draw_line(s["p"] + Vector2(0, -r), s["p"] + Vector2(0, r), Color(sc.r, sc.g, sc.b, a), 1.5)
		else:
			draw_circle(s["p"], 1.5 + a * 1.5, Color(sc.r, sc.g, sc.b, a))
