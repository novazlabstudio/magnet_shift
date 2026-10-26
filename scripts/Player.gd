extends RigidBody2D

var active_magnet: Node2D = null
var is_dead: bool = false
var is_level_complete: bool = false
# Sonuç ekranındaki mesaj için: "laser" ya da "guard"
var death_cause: String = ""

signal player_died

func _ready():
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	gravity_scale = 1.0
	linear_damp = 0.3
	angular_damp = 5.0
	lock_rotation = true
	max_contacts_reported = 4
	contact_monitor = true

func set_active_magnet(magnet: Node2D):
	active_magnet = magnet

func clear_active_magnet():
	active_magnet = null

func die(cause: String = ""):
	if is_dead:
		return
	is_dead = true
	death_cause = cause
	set_deferred("freeze", true)

	var vis = get_node_or_null("Visual")
	if vis and vis.has_method("set_dead"):
		vis.set_dead(true)

	# Parçacık efekti - kıvılcımlar
	_spawn_death_particles()

	await get_tree().create_timer(0.6).timeout
	emit_signal("player_died")

func _spawn_death_particles():
	for i in 10:
		var p = Node2D.new()
		p.position = global_position
		get_tree().current_scene.add_child(p)

		var angle = TAU * i / 10.0 + randf() * 0.5
		var speed = randf_range(80, 200)
		var vel = Vector2(cos(angle) * speed, sin(angle) * speed)
		var size = randf_range(3, 8)
		var color = [
			Color(1.0, 0.3, 0.1),
			Color(1.0, 0.8, 0.0),
			Color(0.0, 0.8, 1.0),
			Color(1.0, 0.2, 0.2)
		][i % 4]

		var tween = p.create_tween()
		tween.tween_property(p, "position",
			p.position + vel * 0.5, 0.5)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.5)
		tween.tween_callback(p.queue_free)

		# Her parçacık için küçük renkli kare çiz
		var cr = ColorRect.new()
		cr.size = Vector2(size, size)
		cr.position = Vector2(-size/2, -size/2)
		cr.color = color
		p.add_child(cr)

func complete_level():
	if is_level_complete:
		return
	is_level_complete = true
