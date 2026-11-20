extends Node2D

# Mağaza kartındaki iz önizlemesi: sekiz çizen küçük bir nokta + arkasında TrailFX.
# TrailFX yalnızca hedefin global_position'ını ve is_dead alanını okur.

var is_dead: bool = false
var radius: Vector2 = Vector2(42, 18)
var speed: float = 2.4
var _t: float = 0.0
var _dot: Node2D = null

func setup(trail_id: String) -> void:
	_dot = Node2D.new()
	_dot.set_script(load("res://scripts/TrailPreviewDot.gd"))
	add_child(_dot)
	var fx = Node2D.new()
	fx.set_script(load("res://scripts/TrailFX.gd"))
	add_child(fx)
	fx.setup(_dot, trail_id)
	move_child(fx, 0)

func _process(delta: float) -> void:
	_t += delta * speed
	if _dot:
		_dot.position = Vector2(sin(_t) * radius.x, sin(_t * 2.0) * radius.y)
