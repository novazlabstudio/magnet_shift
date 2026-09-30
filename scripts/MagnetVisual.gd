extends Node2D

var is_active: bool = false
var pulse_time: float = 0.0
var player_ref: Node2D = null
var level_color: Color = Color(0.3, 0.5, 0.8)

func _ready():
	await get_tree().process_frame
	var parent = get_parent()
	if parent and parent.has_meta("level_color"):
		level_color = parent.get_meta("level_color")

func _process(delta):
	pulse_time += delta
	queue_redraw()

func set_active(active: bool):
	is_active = active
	queue_redraw()

func set_player_ref(p: Node2D):
	player_ref = p

func clear_player_ref():
	player_ref = null

func _rrect(pos: Vector2, size: Vector2, radius: float, color: Color, segments: int = 3):
	var r = clamp(radius, 0.0, min(size.x, size.y) / 2.0)
	var x0 = pos.x
	var y0 = pos.y
	var x1 = pos.x + size.x
	var y1 = pos.y + size.y
	var pts = PackedVector2Array()
	var corners = [
		Vector2(x1 - r, y0 + r),
		Vector2(x1 - r, y1 - r),
		Vector2(x0 + r, y1 - r),
		Vector2(x0 + r, y0 + r),
	]
	var start_angles = [-PI / 2.0, 0.0, PI / 2.0, PI]
	for c in 4:
		var center = corners[c]
		var start_angle = start_angles[c]
		for i in range(segments + 1):
			var angle = start_angle + (PI / 2.0) * float(i) / float(segments)
			pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)

func _build_u_shape(outer_r: float, arm_w: float, arm_top: float, bottom_curve_y: float, segments: int = 12) -> PackedVector2Array:
	var inner_r = outer_r - arm_w
	var pts = PackedVector2Array()
	pts.append(Vector2(-outer_r, arm_top))
	pts.append(Vector2(-outer_r, bottom_curve_y))
	for i in range(segments + 1):
		var ang = PI - (PI * i / segments)
		pts.append(Vector2(cos(ang) * outer_r, bottom_curve_y + sin(ang) * outer_r))
	pts.append(Vector2(outer_r, arm_top))
	pts.append(Vector2(inner_r, arm_top))
	pts.append(Vector2(inner_r, bottom_curve_y))
	for i in range(segments + 1):
		var ang2 = (PI * i / segments)
		pts.append(Vector2(cos(ang2) * inner_r, bottom_curve_y + sin(ang2) * inner_r))
	pts.append(Vector2(-inner_r, arm_top))
	pts.append(Vector2(-outer_r, arm_top))
	return pts

func _draw_hologram_ring(center: Vector2, color: Color, alpha_mult: float):
	for i in 3:
		var ry = 3.0 - i * 0.5
		var rx = 13.0 - i * 2.0
		var a = (0.5 - i * 0.13) * alpha_mult
		var pts = PackedVector2Array()
		for s in 20:
			var ang = TAU * s / 20.0
			pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
		for s in pts.size():
			draw_line(pts[s], pts[(s + 1) % pts.size()], Color(color.r, color.g, color.b, a), 1.3)
	var cone = PackedVector2Array([
		center + Vector2(-7, 0), center + Vector2(7, 0),
		center + Vector2(2, -22), center + Vector2(-2, -22)
	])
	draw_colored_polygon(cone, Color(color.r, color.g, color.b, 0.18 * alpha_mult))
	draw_line(center + Vector2(0, 0), center + Vector2(0, -22), Color(color.r, color.g, color.b, 0.6 * alpha_mult), 1.5)

func _draw():
	var pulse = 0.5 + sin(pulse_time * 3.0) * 0.5 if is_active else 0.0
	var idle_breathe = 0.5 + sin(pulse_time * 1.8) * 0.5

	var metal = Color(0.42, 0.43, 0.48)
	var metal_dark = Color(0.22, 0.23, 0.27)
	var metal_light = Color(0.62, 0.63, 0.7)
	var carbon = Color(0.12, 0.12, 0.14)
	var red = Color(0.85, 0.15, 0.15)
	var blue = Color(0.15, 0.5, 0.95)

	var core_color = Color(
		level_color.r * 0.5 + 0.4,
		level_color.g * 0.5 + 0.4,
		level_color.b * 0.5 + 0.45,
		1.0
	)
	var core_glow = Color(level_color.r * 0.6 + 0.2, level_color.g * 0.6 + 0.2, level_color.b * 0.6 + 0.3, 1.0)

	# ── Dış glow ──
	if is_active:
		draw_circle(Vector2(0, -2), 50, Color(core_glow.r, core_glow.g, core_glow.b, 0.06 + pulse * 0.08))
		draw_circle(Vector2(0, -2), 36, Color(core_glow.r, core_glow.g, core_glow.b, 0.1 + pulse * 0.12))
	else:
		draw_circle(Vector2(0, -2), 26, Color(core_glow.r, core_glow.g, core_glow.b, 0.07 + idle_breathe * 0.06))

	# ── U gövde - TEK PARÇA kapalı poligon ──
	var outer_r = 17.0
	var arm_w = 9.0
	var arm_top = -28.0
	var bottom_curve_y = 4.0
	var u_body = _build_u_shape(outer_r, arm_w, arm_top, bottom_curve_y, 12)
	draw_colored_polygon(u_body, metal)

	# İç gölge (köprünün iç kavisi biraz koyu görünsün)
	var inner_r = outer_r - arm_w
	var shadow_pts = PackedVector2Array()
	for i in range(13):
		var ang3 = (PI * i / 12.0)
		shadow_pts.append(Vector2(cos(ang3) * inner_r, bottom_curve_y + sin(ang3) * inner_r))
	shadow_pts.append(Vector2(0, bottom_curve_y))
	draw_colored_polygon(shadow_pts, Color(metal_dark.r, metal_dark.g, metal_dark.b, 0.35))

	# Kenar parlama şeritleri (kollar)
	_rrect(Vector2(-outer_r, arm_top), Vector2(2.5, 24), 1.0, metal_light)
	_rrect(Vector2(outer_r - 2.5, arm_top), Vector2(2.5, 24), 1.0, metal_light)
	# Karbon fiber şeritler
	_rrect(Vector2(-13.5, arm_top + 5), Vector2(3, 18), 1.5, carbon)
	_rrect(Vector2(11.5, arm_top + 5), Vector2(3, 18), 1.5, carbon)
	# Üst kavis parlama çizgisi
	draw_line(Vector2(-outer_r + 2, bottom_curve_y - outer_r + 2), Vector2(outer_r - 2, bottom_curve_y - outer_r + 2),
		Color(metal_light.r, metal_light.g, metal_light.b, 0.0), 0.0)
	draw_arc(Vector2(0, bottom_curve_y), outer_r - 1.0, PI * 1.05, PI * 1.95, 16,
		Color(metal_light.r, metal_light.g, metal_light.b, 0.3), 1.2)

	# Mini paneller (köprü üstü)
	_rrect(Vector2(-12.5, 5), Vector2(7, 5), 1.0, Color(0.05, 0.08, 0.12, 0.9))
	_rrect(Vector2(-3, 7.5), Vector2(7, 5), 1.0, Color(0.05, 0.08, 0.12, 0.9))
	_rrect(Vector2(6.5, 5), Vector2(7, 5), 1.0, Color(0.05, 0.08, 0.12, 0.9))
	draw_line(Vector2(-9.5, 7.5), Vector2(-5.5, 7.5), Color(core_glow.r, core_glow.g, core_glow.b, 0.7), 0.8)
	draw_line(Vector2(0.5, 10), Vector2(4.5, 10), Color(core_glow.r, core_glow.g, core_glow.b, 0.7), 0.8)

	# ── Kutup başlıkları (kırmızı/mavi, kare üst) ──
	_rrect(Vector2(-19, arm_top - 9), Vector2(13, 11), 2.0, metal)
	_rrect(Vector2(6, arm_top - 9), Vector2(13, 11), 2.0, metal)
	draw_circle(Vector2(-12.5, arm_top - 4), 4.0, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2(-12.5, arm_top - 4), 3.0, red)
	draw_rect(Rect2(-14.5, arm_top - 4.6, 4, 1.2), Color(1, 0.8, 0.8, 0.9))
	draw_circle(Vector2(12.5, arm_top - 4), 4.0, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2(12.5, arm_top - 4), 3.0, blue)
	draw_rect(Rect2(10.5, arm_top - 6.6, 1.2, 4), Color(0.8, 0.9, 1, 0.9))
	draw_rect(Rect2(8.9, arm_top - 4.6, 4, 1.2), Color(0.8, 0.9, 1, 0.9))

	# ── Hologram halkalar (her zaman aktif, pasifken soluk) ──
	var holo_alpha = (0.35 + idle_breathe * 0.25) if not is_active else (0.75 + pulse * 0.25)
	_draw_hologram_ring(Vector2(-12.5, arm_top - 9), red, holo_alpha)
	_draw_hologram_ring(Vector2(12.5, arm_top - 9), blue, holo_alpha)

	# ── Merkez gem (level rengi, elmas/baklava şekli) ──
	var gem_scale = (0.85 + idle_breathe * 0.1) if not is_active else (1.0 + pulse * 0.15)
	var gem_r = 9.0 * gem_scale
	draw_circle(Vector2(0, -10), gem_r + 6, Color(core_glow.r, core_glow.g, core_glow.b, (0.12 + idle_breathe * 0.08) if not is_active else (0.2 + pulse * 0.15)))
	var gem_pts = PackedVector2Array([
		Vector2(0, -10 - gem_r), Vector2(gem_r * 0.55, -10),
		Vector2(0, -10 + gem_r), Vector2(-gem_r * 0.55, -10),
	])
	draw_colored_polygon(gem_pts, Color(core_color.r, core_color.g, core_color.b, 0.85))
	draw_line(Vector2(0, -10 - gem_r), Vector2(0, -10 + gem_r), Color(1, 1, 1, 0.4), 0.8)
	draw_line(Vector2(-gem_r * 0.55, -10), Vector2(gem_r * 0.55, -10), Color(1, 1, 1, 0.4), 0.8)
	draw_circle(Vector2(0, -10), gem_r * 0.3, Color(1.0, 1.0, 1.0, 0.55 if is_active else 0.35))
	var spin_speed = 2.0 if is_active else 0.7
	draw_arc(Vector2(0, -10), gem_r + 3, pulse_time * spin_speed, pulse_time * spin_speed + TAU * 0.55, 16,
		Color(core_glow.r, core_glow.g, core_glow.b, 0.5 if is_active else 0.3), 1.3)

	# ── Aktifken elektrik çizgileri ──
	if is_active:
		var line_count = 8
		for i in line_count:
			var angle = (TAU / line_count) * i + pulse_time * 0.5
			var r1 = 22.0
			var r2 = 42.0 + sin(pulse_time * 4 + i) * 8.0
			var alpha = 0.4 + sin(pulse_time * 3 + i * 0.8) * 0.3
			draw_line(
				Vector2(cos(angle) * r1, sin(angle) * r1 - 8),
				Vector2(cos(angle) * r2, sin(angle) * r2 - 8),
				Color(core_glow.r, core_glow.g, core_glow.b, alpha), 2.0
			)
		draw_arc(Vector2(0, -8), 46,
			pulse_time * 1.5,
			pulse_time * 1.5 + TAU * 0.7,
			24, Color(core_glow.r, core_glow.g, core_glow.b, 0.5 * pulse), 2.5)
		draw_arc(Vector2(0, -8), 46,
			pulse_time * 1.5 + PI,
			pulse_time * 1.5 + PI + TAU * 0.7,
			24, Color(core_glow.r, core_glow.g, core_glow.b, 0.3 * pulse), 1.5)

	# ── Oyuncuya enerji bağı ──
	if is_active and player_ref and is_instance_valid(player_ref):
		var local_player = to_local(player_ref.global_position)
		var dist = local_player.length()
		if dist > 20:
			for i in 3:
				var offset = (i - 1) * 4.0
				var mid = local_player / 2.0 + Vector2(
					sin(pulse_time * 5.0 + i) * 14.0,
					cos(pulse_time * 4.0 + i) * 14.0
				)
				var alpha = (0.55 - i * 0.15) * (0.5 + sin(pulse_time * 3.0) * 0.5)
				draw_line(Vector2(0, -10 + offset), mid,
					Color(core_glow.r, core_glow.g, core_glow.b, alpha), 1.5)
				draw_line(mid, local_player + Vector2(0, offset),
					Color(core_glow.r, core_glow.g, core_glow.b, alpha * 0.7), 1.0)
			draw_arc(local_player, 16,
				0, TAU, 20,
				Color(core_glow.r, core_glow.g, core_glow.b, 0.3 + pulse * 0.3), 1.5)
