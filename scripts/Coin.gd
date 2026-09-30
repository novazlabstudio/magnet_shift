extends Area2D

var value: int = 10
var collected: bool = false

signal coin_collected(value)

func _ready():
	add_to_group("coin")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if collected:
		return
	if body.is_in_group("player"):
		collected = true
		emit_signal("coin_collected", value)
		_collect_effect()

func _collect_effect():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

	var lbl = Label.new()
	lbl.text = "+1"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.5, 0.3, 0.0, 0.8))
	lbl.add_theme_constant_override("shadow_outline_size", 4)
	lbl.position = global_position + Vector2(-10, -20)
	get_tree().current_scene.add_child(lbl)

	var ltween = lbl.create_tween()
	ltween.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.4)
	ltween.tween_interval(0.8)
	ltween.tween_property(lbl, "modulate:a", 0.0, 0.4)
	ltween.tween_callback(lbl.queue_free)
