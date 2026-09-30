extends Node2D

@export var pull_strength: float = 900.0
@export var max_pull_distance: float = 500.0
var max_speed: float = 600.0

var is_active: bool = false
var player_ref: RigidBody2D = null
var visual: Node2D = null

func _ready():
	add_to_group("magnet")
	await get_tree().process_frame
	visual = get_node_or_null("Visual")

func _physics_process(_delta):
	if not is_active or not player_ref or player_ref.is_dead:
		return
	var direction = global_position - player_ref.global_position
	var distance = direction.length()
	if distance < 8.0:
		player_ref.linear_velocity = Vector2.ZERO
		return
	var strength = pull_strength * (1.0 - clamp(distance / max_pull_distance, 0.0, 0.6))
	player_ref.apply_central_force(direction.normalized() * strength)
	if player_ref.linear_velocity.length() > max_speed:
		player_ref.linear_velocity = player_ref.linear_velocity.normalized() * max_speed

func activate(player: RigidBody2D):
	# Diğer mıknatısları kapat
	var all_magnets = get_tree().get_nodes_in_group("magnet")
	for m in all_magnets:
		if m != self and m.is_active:
			m.deactivate()
	is_active = true
	player_ref = player
	player.set_active_magnet(self)
	player.gravity_scale = 0.25
	if visual and visual.has_method("set_active"):
		visual.set_active(true)
	if visual and visual.has_method("set_player_ref"):
		visual.set_player_ref(player)

func deactivate():
	is_active = false
	if player_ref:
		player_ref.gravity_scale = 1.0
		player_ref.clear_active_magnet()
	player_ref = null
	if visual and visual.has_method("set_active"):
		visual.set_active(false)
	if visual and visual.has_method("clear_player_ref"):
		visual.clear_player_ref()
