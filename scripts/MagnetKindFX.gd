extends Node2D

# Yeni mıknatıs türlerinin işaretleri (MagnetVisual'ın üstünde).
#   repel : dışa bakan, nabız gibi atan kırmızı oklar + "−" kutup; basılıyken şok halkaları
#   rail  : kayan mıknatısın raylı yolu (mıknatısla birlikte kaymasın diye level'e ayrı eklenir)

var mode: String = "repel"
var rail_len: float = 0.0
var _t: float = 0.0
var _magnet: Node2D = null

const RED := Color(1.0, 0.28, 0.22)

func _ready() -> void:
	if mode == "repel":
		_magnet = get_parent()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if mode == "rail":
		var a = Vector2(0, 0)
		var b = Vector2(rail_len, 0)
		draw_line(a, b, Color(0.6, 0.85, 1.0, 0.18), 10.0)
		var n = int(abs(rail_len) / 12.0)
		for i in n + 1:
			var x = rail_len * float(i) / max(1, n)
			draw_circle(Vector2(x, 0), 2.0, Color(0.7, 0.9, 1.0, 0.55))
		for e in [a, b]:
			draw_circle(e, 5.0, Color(0.7, 0.9, 1.0, 0.7))
			draw_circle(e, 2.5, Color(0.1, 0.15, 0.25, 1.0))
		return
	var active = _magnet != null and _magnet.get("is_active") == true
	var beat = 0.5 + 0.5 * sin(_t * (9.0 if active else 4.0))
	# Dışa bakan oklar
	for i in 6:
		var ang = TAU * i / 6.0 + _t * 0.4
		var dir = Vector2(cos(ang), sin(ang))
		var r0 = 32.0 + beat * 6.0
		var tip = dir * (r0 + 9.0)
		var side = dir.orthogonal() * 6.0
		var col = Color(RED.r, RED.g, RED.b, 0.45 + beat * 0.45)
		draw_line(dir * r0 + side, tip, col, 2.5)
		draw_line(dir * r0 - side, tip, col, 2.5)
	# "−" kutup işareti (itme)
	draw_circle(Vector2(0, -34), 9.0, Color(0.25, 0.02, 0.02, 0.9))
	draw_arc(Vector2(0, -34), 9.0, 0, TAU, 20, RED, 2.0)
	draw_line(Vector2(-4.5, -34), Vector2(4.5, -34), Color(1, 0.9, 0.9), 2.5)
	if active:
		for k in 2:
			var ph = fmod(_t * 1.6 + k * 0.5, 1.0)
			draw_arc(Vector2.ZERO, 30.0 + ph * 120.0, 0, TAU, 40, Color(RED.r, RED.g, RED.b, 0.5 * (1.0 - ph)), 3.0)
