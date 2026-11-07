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
				_vel = 0.0
				_last_y = event.position.y
				_last_t = Time.get_ticks_msec() / 1000.0
				_samples.clear()
			else:
				_dragging = false
				_vel = _release_velocity()
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
