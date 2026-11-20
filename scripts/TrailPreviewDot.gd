extends Node2D

var is_dead: bool = false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(0.85, 0.95, 1.0))
	draw_circle(Vector2(-2, -2), 2.5, Color(1, 1, 1))
