extends Node2D

var is_horizontal: bool = true
var size: Vector2 = Vector2(80, 10)
var blink_time: float = 0.0
var is_on: bool = true
var blink: bool = false

func setup(s: Vector2, b: bool):
	size = s
	blink = b
	is_horizontal = size.x > size.y
	queue_redraw()

func _process(delta):
	if blink:
		blink_time += delta
		var new_on = fmod(blink_time, 1.4) < 0.7
		if new_on != is_on:
			is_on = new_on
			queue_redraw()
	else:
		queue_redraw()

func _draw():
	var alpha = 1.0 if is_on else 0.12
	var w = size.x
	var h = size.y

	if is_horizontal:
		# Laser beam - horizontal
		# Glow behind
		draw_rect(Rect2(-w/2 - 4, -h/2 - 6, w + 8, h + 12), Color(1.0, 0.0, 0.1, 0.12 * alpha))
		# Main beam
		draw_rect(Rect2(-w/2, -h/2, w, h), Color(1.0, 0.05, 0.05, alpha))
		# Bright core
		draw_rect(Rect2(-w/2, -h/2 + 2, w, h - 4), Color(1.0, 0.6, 0.6, alpha * 0.9))
		# Emitter left
		draw_circle(Vector2(-w/2, 0), h * 0.8, Color(0.5, 0.5, 0.55, 1.0))
		draw_circle(Vector2(-w/2, 0), h * 0.45, Color(1.0, 0.2, 0.2, alpha))
		# Emitter right
		draw_circle(Vector2(w/2, 0), h * 0.8, Color(0.5, 0.5, 0.55, 1.0))
		draw_circle(Vector2(w/2, 0), h * 0.45, Color(1.0, 0.2, 0.2, alpha))
		# Warning stripes on emitters
		if not blink:
			for i in 3:
				var x = -w/2 + 6 + i * (w - 12) / 2.5
				draw_rect(Rect2(x, -h/2 - 8, 4, 6), Color(1.0, 0.8, 0.0, 0.8))
	else:
		# Laser beam - vertical
		draw_rect(Rect2(-w/2 - 6, -h/2 - 4, w + 12, h + 8), Color(1.0, 0.0, 0.1, 0.12 * alpha))
		draw_rect(Rect2(-w/2, -h/2, w, h), Color(1.0, 0.05, 0.05, alpha))
		draw_rect(Rect2(-w/2 + 2, -h/2, w - 4, h), Color(1.0, 0.6, 0.6, alpha * 0.9))
		draw_circle(Vector2(0, -h/2), w * 0.8, Color(0.5, 0.5, 0.55, 1.0))
		draw_circle(Vector2(0, -h/2), w * 0.45, Color(1.0, 0.2, 0.2, alpha))
		draw_circle(Vector2(0, h/2), w * 0.8, Color(0.5, 0.5, 0.55, 1.0))
		draw_circle(Vector2(0, h/2), w * 0.45, Color(1.0, 0.2, 0.2, alpha))
		if not blink:
			for i in 3:
				var y = -h/2 + 6 + i * (h - 12) / 2.5
				draw_rect(Rect2(-w/2 - 10, y, 6, 4), Color(1.0, 0.8, 0.0, 0.8))

	# ⚠ warning sign
	if blink:
		var warn_pos = Vector2(0, -h/2 - 20) if not is_horizontal else Vector2(-w/2 - 20, 0)
		# Triangle
		var pts = PackedVector2Array([
			warn_pos + Vector2(0, -10),
			warn_pos + Vector2(10, 8),
			warn_pos + Vector2(-10, 8)
		])
		draw_colored_polygon(pts, Color(1.0, 0.8, 0.0, 0.9))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]),
			Color(0.8, 0.5, 0.0, 1.0), 1.5)
