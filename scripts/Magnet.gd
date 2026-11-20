extends Node2D

@export var pull_strength: float = 900.0
@export var max_pull_distance: float = 500.0
var max_speed: float = 600.0

var is_active: bool = false
var player_ref: RigidBody2D = null
var visual: Node2D = null
# 1.3 yeni mıknatıslar (Endless / Daily): "pull" normal, "repel" iten (kırmızı)
var kind: String = "pull"
const REPEL_RANGE := 300.0
# Kayan mıknatıs: base_x'ten move_dx kadar gidip gelir (0 = sabit)
var move_dx: float = 0.0
var move_period: float = 3.0
var _base_x: float = 0.0
var _t: float = 0.0

func _ready():
	add_to_group("magnet")
	_base_x = position.x
	if has_meta("kind"):
		kind = get_meta("kind")
	if has_meta("move_dx"):
		move_dx = get_meta("move_dx")
		move_period = get_meta("move_period")
	await get_tree().process_frame
	visual = get_node_or_null("Visual")

func _physics_process(delta):
	if move_dx != 0.0:
		_t += delta
		position.x = _base_x + move_dx * (0.5 - 0.5 * cos(_t * TAU / move_period))
	if not is_active or not player_ref or player_ref.is_dead:
		return
	if kind == "repel":
		var away = player_ref.global_position - global_position
		var dist = away.length()
		if dist < 1.0 or dist > REPEL_RANGE:
			return
		var push = pull_strength * 1.25 * (1.0 - dist / REPEL_RANGE * 0.7)
		player_ref.apply_central_force(away.normalized() * push)
		if player_ref.linear_velocity.length() > max_speed:
			player_ref.linear_velocity = player_ref.linear_velocity.normalized() * max_speed
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
	player.gravity_scale = 0.6 if kind == "repel" else 0.25
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
