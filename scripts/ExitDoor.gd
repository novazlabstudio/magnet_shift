extends Area2D

var is_open: bool = true
var player_entering: bool = false

signal level_complete

func _ready():
	add_to_group("exit_door")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func open_door():
	is_open = true

func _on_body_entered(body):
	if body.is_in_group("player") and is_open and not player_entering:
		player_entering = true
		_play_enter_animation(body)

func _play_enter_animation(body):
	var vis = get_node_or_null("Visual")
	if vis and vis.has_method("play_open"):
		vis.play_open()

	# body_entered fizik sorgusu sırasında geliyor; freeze anında değiştirilemez
	body.set_deferred("freeze", true)
	body.linear_velocity = Vector2.ZERO

	var target_pos = global_position + Vector2(0, 2)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "position", target_pos, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(body, "rotation", body.rotation - TAU * 2.5, 0.45).set_ease(Tween.EASE_IN)
	tween.tween_property(body, "scale", Vector2(0.05, 0.05), 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(body, "modulate", Color(1, 1, 1, 0), 0.45).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		emit_signal("level_complete")
	)
