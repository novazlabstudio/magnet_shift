extends Node2D

var time: float = 0.0
var collected: bool = false

func _process(delta):
	if collected:
		return
	time += delta
	position.y = sin(time * 3.0) * 4.0
	queue_redraw()

func _draw():
	if collected:
		return

	# Outer glow
	draw_circle(Vector2.ZERO, 16, Color(1.0, 0.8, 0.0, 0.18))
	# Gold body
	draw_circle(Vector2.ZERO, 12, Color(1.0, 0.75, 0.0, 1.0))
	# Inner shine
	draw_circle(Vector2.ZERO, 9, Color(1.0, 0.88, 0.3, 1.0))
	# Detail circles
	draw_circle(Vector2(-1, -2), 4.5, Color(0.85, 0.55, 0.0, 1.0))
	draw_circle(Vector2(-1, -2), 3.0, Color(1.0, 0.88, 0.3, 1.0))
	draw_circle(Vector2(-1, 2), 4.5, Color(0.85, 0.55, 0.0, 1.0))
	draw_circle(Vector2(-1, 2), 3.0, Color(1.0, 0.88, 0.3, 1.0))
	draw_rect(Rect2(-2, -7, 2, 14), Color(0.85, 0.55, 0.0, 1.0))
	draw_arc(Vector2(-3, -5), 5, -PI*0.8, -PI*0.1, 8, Color(1.0, 1.0, 0.9, 0.7), 2.0)
