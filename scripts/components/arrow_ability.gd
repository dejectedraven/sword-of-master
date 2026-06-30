extends AbilityBase

func _ready():
	super._ready()
	cooldown_time = GameConfig.archer_arrow_cooldown

func use() -> bool:
	if not super.use(): return false
	var dir = owner_entity.facing_direction
	var speed = GameConfig.archer_arrow_speed
	var damage = GameConfig.archer_attack
	var range = GameConfig.archer_arrow_range

	var arrow = Node2D.new()
	arrow.global_position = owner_entity.global_position + dir * 32
	arrow.rotation = dir.angle()
	get_tree().current_scene.add_child(arrow)

	var sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/player/Arrow.png")
	sprite.centered = true
	arrow.add_child(sprite)

	var dur = range / max(speed, 1.0)
	var target_pos = arrow.global_position + dir * range
	var tween = create_tween()
	tween.tween_property(arrow, "global_position", target_pos, dur)
	tween.tween_callback(func(): if is_instance_valid(arrow): arrow.queue_free())

	_raycast_loop(arrow, dir, damage, dur)
	return true

func _raycast_loop(arrow: Node2D, dir: Vector2, damage: float, dur: float):
	var elapsed = 0.0
	while elapsed < dur:
		await get_tree().physics_frame
		if not is_instance_valid(arrow): return
		elapsed += get_physics_process_delta_time()
		var space = arrow.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(arrow.global_position, arrow.global_position + dir * 32, 3)
		query.exclude = [owner_entity]
		var result = space.intersect_ray(query)
		if result:
			var body = result.collider
			if body.has_method("take_damage"):
				body.take_damage(damage)
			if is_instance_valid(arrow): arrow.queue_free()
			return
