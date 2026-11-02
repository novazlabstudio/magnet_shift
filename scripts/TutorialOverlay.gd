extends Node2D

# Level 1 eğitimi: hedefin üstünde parlayan halka + 👆 el, altta kısa talimat.
# Hangi hedefin gösterileceğine GameManager karar verir (set_state).

var _target: Vector2 = Vector2.ZERO
var _pointer: bool = false
var _t: float = 0.0
var _text: Label
var _hand: Label

func _ready() -> void:
	_text = Label.new()
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 20)
	_text.add_theme_color_override("font_color", Color(1, 1, 1))
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0.1, 0.9))
	_text.add_theme_constant_override("outline_size", 4)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.1, 0.68)
	sb.border_color = Color(0.0, 0.9, 1.0, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_text.add_theme_stylebox_override("normal", sb)
	add_child(_text)

	_hand = Label.new()
	_hand.text = "👆"
	_hand.add_theme_font_size_override("font_size", 40)
	add_child(_hand)
	visible = false

func set_state(text: String, pointer: bool, target: Vector2 = Vector2.ZERO) -> void:
	visible = true
	_text.text = text
	_pointer = pointer
	_target = target

func hide_all() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var vp = get_viewport().get_visible_rect().size
	_text.size = Vector2(vp.x - 60.0, 0)
	_text.position = Vector2(30.0, vp.y - 150.0)
	_hand.visible = _pointer
	if _pointer:
		var bob = sin(_t * 6.0) * 6.0
		_hand.position = _target + Vector2(-16.0, 22.0 + bob)
	queue_redraw()

func _draw() -> void:
	if not _pointer:
		return
	var pulse = fmod(_t * 1.4, 1.0)
	var c = Color(1.0, 0.9, 0.2)
	draw_arc(_target, 26.0 + pulse * 26.0, 0.0, TAU, 40, Color(c.r, c.g, c.b, 1.0 - pulse), 3.0, true)
	draw_arc(_target, 30.0, 0.0, TAU, 40, Color(c.r, c.g, c.b, 0.85), 2.5, true)
