extends Node2D

var time: float = 0.0
var is_dead: bool = false
var direction: int = 1
var walk_time: float = 0.0
var guard_type: int = 0  # 0=kırmızı/kahve, 1=mavi/çelik

func set_direction(dir: int):
	direction = dir

func set_walk(t: float, dir: int):
	walk_time = t
	direction = dir

func set_type(t: int):
	guard_type = t

func _process(delta):
	time += delta
	queue_redraw()

func _draw():
	if is_dead:
		_draw_dead()
		return
	_draw_robot()

func _draw_robot():
	var eye_glow = 0.7 + sin(time * 4.0) * 0.3
	var leg_swing = sin(walk_time * 8.0) * 5.0
	var arm_swing = sin(walk_time * 8.0) * 4.0

	if guard_type == 0:
		# ── Tip 0: Kırmızı/kahverengi (orijinal) ──
		var c1 = Color(0.55, 0.2, 0.05)
		var c2 = Color(0.35, 0.12, 0.02)
		var c3 = Color(0.7, 0.25, 0.05)
		var c4 = Color(0.5, 0.15, 0.02)
		var c5 = Color(0.6, 0.22, 0.04)
		var eye_col = Color(1.0, 0.1, 0.0)

		_draw_ellipse(Vector2(0, 20), 18, 4, Color(0.0, 0.0, 0.0, 0.3))
		draw_rect(Rect2(-10, 8 + leg_swing, 8, 12), c1)
		draw_rect(Rect2(-12, 18 + leg_swing, 10, 5), c2)
		draw_rect(Rect2(2, 8 - leg_swing, 8, 12), c1)
		draw_rect(Rect2(2, 18 - leg_swing, 10, 5), c2)
		draw_rect(Rect2(-13, -10, 26, 20), c3)
		draw_rect(Rect2(-10, -8, 20, 14), c4)
		var tri = PackedVector2Array([Vector2(0, -6), Vector2(5, 2), Vector2(-5, 2)])
		draw_colored_polygon(tri, Color(1.0, 0.8, 0.0, 0.9))
		draw_line(Vector2(0, -4), Vector2(0, 0), Color(0.1, 0.1, 0.1), 1.5)
		draw_circle(Vector2(0, 1), 1, Color(0.1, 0.1, 0.1))
		draw_rect(Rect2(-20, -9 + arm_swing, 8, 14), c5)
		draw_circle(Vector2(-16, 7 + arm_swing), 5, c2)
		draw_rect(Rect2(12, -9 - arm_swing, 8, 14), c5)
		draw_circle(Vector2(16, 7 - arm_swing), 5, c2)
		for i in 3:
			draw_line(Vector2(-19+i*3, 6+arm_swing), Vector2(-20+i*3, 12+arm_swing), Color(0.8,0.8,0.8,0.7), 1.2)
			draw_line(Vector2(13+i*3, 6-arm_swing), Vector2(14+i*3, 12-arm_swing), Color(0.8,0.8,0.8,0.7), 1.2)
		draw_rect(Rect2(-12, -26, 24, 18), Color(0.5, 0.18, 0.04))
		draw_rect(Rect2(-12, -30, 24, 8), Color(0.35, 0.1, 0.02))
		draw_rect(Rect2(-13, -22, 26, 3), Color(0.25, 0.08, 0.01))
		draw_rect(Rect2(-4, -36, 4, 8), Color(0.3, 0.08, 0.01))
		draw_rect(Rect2(0, -36, 4, 8), Color(0.3, 0.08, 0.01))
		draw_circle(Vector2(-5, -20), 5, Color(0.1, 0.0, 0.0))
		draw_circle(Vector2(-5, -20), 3.5, Color(eye_col.r, eye_col.g, eye_col.b, eye_glow))
		draw_circle(Vector2(-5, -20), 1.5, Color(1.0, 0.6, 0.0, eye_glow))
		draw_circle(Vector2(5, -20), 5, Color(0.1, 0.0, 0.0))
		draw_circle(Vector2(5, -20), 3.5, Color(eye_col.r, eye_col.g, eye_col.b, eye_glow))
		draw_circle(Vector2(5, -20), 1.5, Color(1.0, 0.6, 0.0, eye_glow))
		if eye_glow > 0.9:
			draw_circle(Vector2(-5, -20), 7, Color(1.0, 0.1, 0.0, 0.15))
			draw_circle(Vector2(5, -20), 7, Color(1.0, 0.1, 0.0, 0.15))
		draw_rect(Rect2(-8, -14, 16, 5), Color(0.15, 0.0, 0.0))
		for i in 4:
			draw_rect(Rect2(-7 + i * 4, -14, 2, 4), Color(0.9, 0.9, 0.85))

	else:
		# ── Tip 1: Mavi/çelik (ikinci guard) ──
		var c1 = Color(0.15, 0.25, 0.5)
		var c2 = Color(0.08, 0.14, 0.32)
		var c3 = Color(0.2, 0.38, 0.65)
		var c4 = Color(0.12, 0.22, 0.45)
		var c5 = Color(0.18, 0.3, 0.55)
		var eye_col = Color(0.0, 0.8, 1.0)

		_draw_ellipse(Vector2(0, 20), 18, 4, Color(0.0, 0.0, 0.0, 0.3))
		# Bacaklar
		draw_rect(Rect2(-10, 8 + leg_swing, 8, 12), c1)
		draw_rect(Rect2(-12, 18 + leg_swing, 10, 5), c2)
		draw_rect(Rect2(2, 8 - leg_swing, 8, 12), c1)
		draw_rect(Rect2(2, 18 - leg_swing, 10, 5), c2)
		# Gövde
		draw_rect(Rect2(-13, -10, 26, 20), c3)
		draw_rect(Rect2(-10, -8, 20, 14), c4)
		# Göğüs sembolü: tehlike üçgeni
		var tri2 = PackedVector2Array([Vector2(0, -6), Vector2(5, 2), Vector2(-5, 2)])
		draw_colored_polygon(tri2, Color(1.0, 0.8, 0.0, 0.9))
		draw_line(Vector2(0, -4), Vector2(0, 0), Color(0.1, 0.1, 0.1), 1.5)
		draw_circle(Vector2(0, 1), 1, Color(0.1, 0.1, 0.1))
		# Kollar
		draw_rect(Rect2(-20, -9 + arm_swing, 8, 14), c5)
		draw_circle(Vector2(-16, 7 + arm_swing), 5, c2)
		draw_rect(Rect2(12, -9 - arm_swing, 8, 14), c5)
		draw_circle(Vector2(16, 7 - arm_swing), 5, c2)
		# Pençeler (sivriler yerine yuvarlak)
		draw_circle(Vector2(-16, 13 + arm_swing), 3.5, Color(0.0, 0.7, 1.0, 0.8))
		draw_circle(Vector2(16, 13 - arm_swing), 3.5, Color(0.0, 0.7, 1.0, 0.8))
		# Kafa
		draw_rect(Rect2(-12, -26, 24, 18), c4)
		draw_rect(Rect2(-12, -30, 24, 8), c2)
		draw_rect(Rect2(-13, -22, 26, 3), Color(0.05, 0.1, 0.2))
		# Boynuzlar: iki kısa dik
		draw_rect(Rect2(-6, -34, 3, 6), Color(0.0, 0.6, 0.9))
		draw_rect(Rect2(3, -34, 3, 6), Color(0.0, 0.6, 0.9))
		# Gözler (mavi/cyan)
		draw_circle(Vector2(-5, -20), 5, Color(0.0, 0.05, 0.12))
		draw_circle(Vector2(-5, -20), 3.5, Color(eye_col.r, eye_col.g, eye_col.b, eye_glow))
		draw_circle(Vector2(-5, -20), 1.5, Color(1.0, 1.0, 1.0, eye_glow))
		draw_circle(Vector2(5, -20), 5, Color(0.0, 0.05, 0.12))
		draw_circle(Vector2(5, -20), 3.5, Color(eye_col.r, eye_col.g, eye_col.b, eye_glow))
		draw_circle(Vector2(5, -20), 1.5, Color(1.0, 1.0, 1.0, eye_glow))
		if eye_glow > 0.9:
			draw_circle(Vector2(-5, -20), 7, Color(0.0, 0.8, 1.0, 0.15))
			draw_circle(Vector2(5, -20), 7, Color(0.0, 0.8, 1.0, 0.15))
		# Ağız: düz çizgi (daha tehditkâr)
		draw_rect(Rect2(-7, -13, 14, 3), Color(0.0, 0.05, 0.12))
		draw_line(Vector2(-6, -11), Vector2(6, -11), Color(0.0, 0.7, 1.0, 0.7), 1.5)

func _draw_dead():
	draw_rect(Rect2(-12, -8, 24, 30), Color(0.5, 0.15, 0.15, 1.0))
	draw_rect(Rect2(-11, -24, 22, 18), Color(0.4, 0.1, 0.1, 1.0))
	draw_line(Vector2(-8, -22), Vector2(-2, -16), Color(1.0, 0.2, 0.2, 1.0), 2.0)
	draw_line(Vector2(-2, -22), Vector2(-8, -16), Color(1.0, 0.2, 0.2, 1.0), 2.0)
	draw_line(Vector2(2, -22), Vector2(8, -16), Color(1.0, 0.2, 0.2, 1.0), 2.0)
	draw_line(Vector2(8, -22), Vector2(2, -16), Color(1.0, 0.2, 0.2, 1.0), 2.0)

func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color):
	var pts = PackedVector2Array()
	for i in 16:
		var angle = TAU * i / 16.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, color)
