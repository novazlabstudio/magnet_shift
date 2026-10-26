extends CharacterBody2D

var patrol_distance: float = 120.0
var speed: float = 80.0
var start_position: Vector2
var direction: int = 1
var visual: Node2D = null
var walk_time: float = 0.0
var settled: bool = false
var wall_cooldown: float = 0.0
const WALL_COOLDOWN_TIME: float = 0.3
const WALL_DETECT_DIST: float = 18.0
var last_reverse_x: float = -99999.0
const MIN_TRAVEL_AFTER_REVERSE: float = 20.0

signal guard_caught_player

func _ready():
	add_to_group("guard")
	collision_layer = 1
	collision_mask = 1
	if has_meta("patrol_distance"):
		patrol_distance = get_meta("patrol_distance")
	await get_tree().process_frame
	visual = get_node_or_null("Visual")
	var det = get_node_or_null("DetectionArea")
	if det:
		det.collision_layer = 0
		det.collision_mask = 2
		det.monitoring = true
		det.monitorable = false
		det.body_entered.connect(_on_detection_body_entered)

func _physics_process(delta):
	walk_time += delta

	if wall_cooldown > 0:
		wall_cooldown = max(0, wall_cooldown - delta)

	if not is_on_floor():
		velocity.x = 0
		velocity.y += 15
		velocity.y = min(velocity.y, 400)
		move_and_slide()
		return

	if not settled:
		settled = true
		velocity.y = 0
		start_position = global_position

	velocity.y = 0

	if wall_cooldown <= 0 and abs(global_position.x - last_reverse_x) >= MIN_TRAVEL_AFTER_REVERSE and (_is_wall_ahead() or not _is_floor_ahead() or _is_past_patrol_limit()):
		direction = -direction
		if visual and visual.has_method("set_direction"):
			visual.set_direction(direction)
		wall_cooldown = WALL_COOLDOWN_TIME
		last_reverse_x = global_position.x
		return

	velocity.x = speed * direction
	var prev_x = global_position.x
	move_and_slide()

	if visual and visual.has_method("set_walk"):
		visual.set_walk(walk_time, direction)

	if is_on_wall() and wall_cooldown <= 0 and abs(global_position.x - last_reverse_x) >= MIN_TRAVEL_AFTER_REVERSE:
		direction = -direction
		if visual and visual.has_method("set_direction"):
			visual.set_direction(direction)
		wall_cooldown = WALL_COOLDOWN_TIME
		last_reverse_x = global_position.x
		velocity.x = speed * direction
		move_and_slide()
		return

	var moved = abs(global_position.x - prev_x)
	if moved < 0.5 and wall_cooldown <= 0 and abs(global_position.x - last_reverse_x) >= MIN_TRAVEL_AFTER_REVERSE:
		direction = -direction
		if visual and visual.has_method("set_direction"):
			visual.set_direction(direction)
		wall_cooldown = WALL_COOLDOWN_TIME
		last_reverse_x = global_position.x
		return

func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("guard_caught_player")
		body.die()

# Platform kenarından düşmemek için önündeki zemini kontrol eder
func _is_floor_ahead() -> bool:
	var space = get_world_2d().direct_space_state
	if not space:
		return true
	var from = global_position + Vector2(WALL_DETECT_DIST * direction, 0)
	var to = from + Vector2(0, 32)
	var params = PhysicsRayQueryParameters2D.create(from, to)
	params.exclude = [self]
	params.collision_mask = collision_mask
	return space.intersect_ray(params).size() > 0

func _is_past_patrol_limit() -> bool:
	return (global_position.x - start_position.x) * direction >= patrol_distance

func _is_wall_ahead() -> bool:
	var space = get_world_2d().direct_space_state
	if not space:
		return false
	var from = global_position
	var to = from + Vector2(WALL_DETECT_DIST * direction, 0)
	var params = PhysicsRayQueryParameters2D.create(from, to)
	params.exclude = [self]
	params.collision_mask = collision_mask
	var res = space.intersect_ray(params)
	return res.size() > 0
