extends Node2D

# Level başında kahramanın ışınlanma efekti (oyuncunun konumuna eklenir, kendini siler).
# Çıkış kapısındaki çekilmenin tersi: yukarıdan inen ışık sütunu, ayak hizasında halka, pırıltılar.

const LIFE := 0.75
var t: float = 0.0
var color: Color = Color(0.6, 1.0, 0.85)
var sparkles: Array = []

func _ready() -> void:
	z_index = 3
	for i in 14:
		sparkles.append({"x": randf_range(-16, 16), "y": randf_range(-60, 10), "s": randf_range(1.5, 3.0),
			"v": randf_range(30, 80), "ph": randf() * TAU})

func _process(delta: float) -> void:
	t += delta
	if t >= LIFE:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k = t / LIFE
	var a = 1.0 - k
	# Yukarıdan inen ışık sütunu (köşelerde renk saydamlaşır)
	var w = 22.0 * (1.0 - k * 0.6)
	var top = -320.0 * (1.0 - k * 0.3)
	var foot = 22.0
	draw_polygon(PackedVector2Array([Vector2(-w, top), Vector2(w, top), Vector2(w, foot), Vector2(-w, foot)]),
		PackedColorArray([Color(color.r, color.g, color.b, 0.0), Color(color.r, color.g, color.b, 0.0),
			Color(color.r, color.g, color.b, 0.5 * a), Color(color.r, color.g, color.b, 0.5 * a)]))
	draw_polygon(PackedVector2Array([Vector2(-w * 0.3, top), Vector2(w * 0.3, top), Vector2(w * 0.3, foot), Vector2(-w * 0.3, foot)]),
		PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.8 * a), Color(1, 1, 1, 0.8 * a)]))
	# Ayak hizasında genişleyen halka (perspektif için basık)
	var r = 8.0 + 30.0 * k
	draw_set_transform(Vector2(0, foot), 0.0, Vector2(1.0, 0.35))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.9 * a), 3.0, true)
	draw_arc(Vector2.ZERO, r * 0.6, 0.0, TAU, 32, Color(1, 1, 1, 0.6 * a), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for sp in sparkles:
		var y = sp.y - sp.v * t
		var s = sp.s * (0.6 + 0.4 * sin(t * 18.0 + sp.ph))
		var c = Color(1, 1, 1, a)
		draw_colored_polygon(PackedVector2Array([Vector2(sp.x, y - s * 2), Vector2(sp.x + s * 0.5, y),
			Vector2(sp.x, y + s * 2), Vector2(sp.x - s * 0.5, y)]), c)
