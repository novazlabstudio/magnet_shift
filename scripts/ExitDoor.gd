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
	if body.is_in_group("player") and is_open and not player_entering and not body.is_dead:
		player_entering = true
		body.is_level_complete = true
		_play_enter_animation(body)

# Çekilme süresi ExitVisual.SUCK_TIME ile aynı; patlamadan sonra AFTERGLOW kadar beklenir
const SUCK_TIME := 0.55
const AFTERGLOW := 0.5

func _play_enter_animation(body):
	var gm = get_tree().current_scene
	if gm and gm.has_method("on_exit_started"):
		gm.on_exit_started(self)
	var vis = get_node_or_null("Visual")
	if vis and vis.has_method("play_enter"):
		vis.play_enter()

	# body_entered fizik sorgusu sırasında geliyor; freeze anında değiştirilemez
	body.set_deferred("freeze", true)
	body.set_deferred("linear_velocity", Vector2.ZERO)
	SoundManager.play_sfx("portal", -3.0)

	# Kahraman girdabın merkezine spiral çizerek, uzayıp küçülerek ve parlayarak çekilir
	var center = global_position + Vector2(0, -6)
	var start_off = body.global_position - center
	if start_off.length() < 10.0:
		start_off = Vector2(0, 24)
	var tween = create_tween()
	tween.tween_method(func(k: float):
		if not is_instance_valid(body):
			return
		body.global_position = center + start_off.rotated(k * TAU * 1.25) * (1.0 - k)
		body.rotation = k * TAU * 1.25
		var shrink = 1.0 - 0.85 * k * k
		body.scale = Vector2(1.0 - 0.4 * k, 1.0 + 0.45 * k) * shrink
		var glow = 1.0 + 1.6 * k
		body.modulate = Color(glow, glow, glow, 1.0)
	, 0.0, 1.0, SUCK_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		if is_instance_valid(body):
			body.visible = false
		SoundManager.play_sfx("level_clear", -2.0)
		LevelTransition.flash_color(Color(0.85, 1.0, 0.9, 0.4))
	)
	tween.tween_interval(AFTERGLOW)
	tween.tween_callback(func():
		emit_signal("level_complete")
	)
