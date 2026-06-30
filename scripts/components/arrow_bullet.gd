extends Node2D

var speed: float = 600.0
var damage: float = 12.0
var owner_node: Node
var move_dir: Vector2 = Vector2.RIGHT

func _ready():
	move_dir = Vector2.RIGHT.rotated(rotation)

func _physics_process(delta: float):
	var step = move_dir * speed * delta
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	query.exclude = [owner_node]
	var result = space.intersect_ray(query)
	if result:
		var body = result.collider
		if body != owner_node and body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	global_position += step
	var r = get_meta("range") if has_meta("range") else 500.0
	if global_position.distance_to(get_meta("start_pos", global_position)) >= r:
		queue_free()
