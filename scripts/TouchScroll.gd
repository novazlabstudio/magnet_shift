class_name TouchScroll
extends Control

# Dokunmatik için güvenilir dikey kaydırma alanı (ödüller listesi).
# Godot'nun ScrollContainer'ı satırların üstünden başlayan sürüklemelerde zaman zaman takılıyordu
# (dokunma -> fare öykünmesi + iç içe Container'lar). Burada tüm girdi tek yerde işlenir:
#   - parmağı izler (1:1), bırakınca ataletle kayar ve yavaşlar
#   - uçlarda lastik gibi esner, geri yaylanır
#   - fare tekerleği (masaüstü)
# İçerik `content` altına eklenir; içerikteki Control'lerin girdiyi yutmaması için
# add_content() hepsini MOUSE_FILTER_IGNORE yapar (liste yalnızca gösterim amaçlı).

var content: Control
var _offset: float = 0.0
var _vel: float = 0.0
var _dragging: bool = false
var _last_y: float = 0.0
var _last_t: float = 0.0
var _samples: Array = []
# Dokunma (tap): parmak az oynadıysa bırakıldığı noktadaki butona basılmış sayılır.
# İçerik girdiyi yutmadığı için (IGNORE) butonlar kendi başına tıklanamaz; tap'i burası iletir.
var _press_pos: Vector2 = Vector2.ZERO
var _moved: float = 0.0
const TAP_SLOP := 14.0

const FRICTION := 4.2       # atalet sönümü (1/sn)
const SPRING := 18.0        # uçlarda geri yaylanma
const RUBBER := 0.45        # uçta sürüklerken direnç

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

func add_content(node: Control) -> void:
	content.add_child(node)
	_ignore_input(node)

func _ignore_input(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_input(c)

func _content_height() -> float:
	var h = 0.0
	for c in content.get_children():
		if c is Control:
			h = max(h, c.position.y + c.get_combined_minimum_size().y, c.position.y + c.size.y)
	return h

func _max_offset() -> float:
	return max(0.0, _content_height() - size.y)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_press_pos = event.global_position
				_moved = 0.0
				_vel = 0.0
				_last_y = event.position.y
				_last_t = Time.get_ticks_msec() / 1000.0
				_samples.clear()
			else:
				_dragging = false
				_vel = _release_velocity()
				if _moved < TAP_SLOP:
					_vel = 0.0
					_tap(event.global_position)
			accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_vel = 0.0
			_offset = min(_offset + 60.0, _max_offset())
			accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_vel = 0.0
			_offset = max(_offset - 60.0, 0.0)
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var dy = event.position.y - _last_y
		_last_y = event.position.y
		_moved = max(_moved, event.global_position.distance_to(_press_pos))
		var now = Time.get_ticks_msec() / 1000.0
		# uçların dışındaysa direnç
		if _offset < 0.0 or _offset > _max_offset():
			dy *= RUBBER
		_offset -= dy
		_samples.append([now, -dy])
		while _samples.size() > 0 and now - _samples[0][0] > 0.1:
			_samples.pop_front()
		_last_t = now
		accept_event()

func _tap(gpos: Vector2) -> void:
	var b = _button_at(content, gpos)
	if b:
		b.pressed.emit()

func _button_at(n: Node, gpos: Vector2) -> BaseButton:
	# En üstteki (en son eklenen) önce
	var kids = n.get_children()
	for i in range(kids.size() - 1, -1, -1):
		var c = kids[i]
		if c is CanvasItem and not c.visible:
			continue
		var hit = _button_at(c, gpos)
		if hit:
			return hit
		if c is BaseButton and not c.disabled and c.get_global_rect().has_point(gpos):
			return c
	return null

func _release_velocity() -> float:
	if _samples.is_empty():
		return 0.0
	var now = Time.get_ticks_msec() / 1000.0
	# parmak durup öyle kaldırıldıysa fırlatma yok
	if now - _last_t > 0.08:
		return 0.0
	var total = 0.0
	for s in _samples:
		total += s[1]
	var span = max(0.016, now - _samples[0][0])
	return clamp(total / span, -4000.0, 4000.0)

func _process(delta: float) -> void:
	var mx = _max_offset()
	if not _dragging:
		if abs(_vel) > 1.0:
			_offset += _vel * delta
			_vel *= exp(-FRICTION * delta)
			# uca çarpınca hızı hızla söndür
			if _offset < 0.0 or _offset > mx:
				_vel *= exp(-12.0 * delta)
		else:
			_vel = 0.0
		if _offset < 0.0:
			_offset = lerp(_offset, 0.0, 1.0 - exp(-SPRING * delta))
			if _offset > -0.5: _offset = 0.0
		elif _offset > mx:
			_offset = lerp(_offset, mx, 1.0 - exp(-SPRING * delta))
			if _offset < mx + 0.5: _offset = mx
	content.position.y = -round(_offset)
