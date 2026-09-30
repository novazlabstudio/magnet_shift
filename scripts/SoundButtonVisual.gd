extends Node2D

var is_on: bool = true
var time: float = 0.0
var hover: bool = false

func setup(sound_on: bool):
	is_on = sound_on
	queue_redraw()

func _process(delta):
	time += delta
	queue_redraw()

func _draw():
	var pulse = 0.85 + sin(time * 3.0) * 0.15 if is_on else 1.0
	
	# Arka panel
	var bg_color = Color(0.0, 0.15, 0.35, 0.85) if is_on else Color(0.15, 0.08, 0.08, 0.85)
	draw_rect(Rect2(-22, -22, 44, 44), bg_color)
	
	# Kenarlık
	var border_color = Color(0.0, 0.75, 1.0, pulse) if is_on else Color(0.5, 0.2, 0.2, 0.6)
	draw_rect(Rect2(-22, -22, 44, 2), border_color)
	draw_rect(Rect2(-22, 20, 44, 2), border_color)
	draw_rect(Rect2(-22, -22, 2, 44), border_color)
	draw_rect(Rect2(20, -22, 2, 44), border_color)
	
	if is_on:
		# Hoparlör gövdesi
		var pts = PackedVector2Array([
			Vector2(-10, -7), Vector2(-3, -7),
			Vector2(5, -13), Vector2(5, 13),
			Vector2(-3, 7), Vector2(-10, 7)
		])
		draw_colored_polygon(pts, Color(0.0, 0.85, 1.0, 1.0))
		
		# Ses dalgaları - 3 yay
		for i in 3:
			var r = 9.0 + i * 5.0
			var alpha = (pulse * 0.9) - i * 0.2
			if alpha > 0:
				draw_arc(Vector2(5, 0), r, -PI*0.45, PI*0.45, 12,
					Color(0.0, 0.85, 1.0, alpha), 2.0 - i * 0.4)
		
		# Glow
		draw_circle(Vector2(0, 0), 18, Color(0.0, 0.6, 1.0, 0.06 * pulse))
	else:
		# Kapalı hoparlör - gri
		var pts = PackedVector2Array([
			Vector2(-10, -7), Vector2(-3, -7),
			Vector2(5, -13), Vector2(5, 13),
			Vector2(-3, 7), Vector2(-10, 7)
		])
		draw_colored_polygon(pts, Color(0.45, 0.3, 0.3, 0.9))
		
		# X işareti
		draw_line(Vector2(9, -10), Vector2(18, -1), Color(1.0, 0.3, 0.3, 0.9), 2.5)
		draw_line(Vector2(18, -10), Vector2(9, -1), Color(1.0, 0.3, 0.3, 0.9), 2.5)
