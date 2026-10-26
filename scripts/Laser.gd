extends Area2D

var blink: bool = false
var is_on: bool = true
var col_shape: CollisionShape2D
var visual: Node2D

func _ready():
	add_to_group("laser")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false

	if has_meta("blink_on_ready"):
		blink = get_meta("blink_on_ready")

	var sz = get_meta("laser_size") if has_meta("laser_size") else Vector2(80, 10)

	# Collision shape tam ışın boyutunda — ne büyük ne küçük
	col_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = sz  # Görsel ile aynı boyut, sadece ışının kendisi
	col_shape.shape = shape
	add_child(col_shape)

	# Visual
	visual = Node2D.new()
	visual.set_script(load("res://scripts/LaserVisual.gd"))
	add_child(visual)
	if visual.has_method("setup"):
		visual.setup(sz, blink)

	body_entered.connect(_on_body_entered)

	if blink:
		_start_blink()

func _start_blink():
	while true:
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(self):
			break
		is_on = !is_on
		if col_shape:
			col_shape.disabled = !is_on

func _on_body_entered(body):
	if body.is_in_group("player") and is_on:
		body.die("laser")
