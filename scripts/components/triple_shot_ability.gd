extends AbilityBase

func _ready():
	super._ready()
	cooldown_time = GameConfig.archer_triple_cooldown

func use() -> bool:
	if not super.use(): return false
	_triple_shot()
	return true

func _triple_shot():
	var dir = owner_entity.facing_direction
	var base_damage = GameConfig.archer_attack * GameConfig.archer_triple_damage_mult
	var speed = GameConfig.archer_arrow_speed
	var range = GameConfig.archer_arrow_range
	var spread_deg = GameConfig.archer_triple_spread

	for i in range(GameConfig.archer_triple_count):
		var offset = (i - 1) * spread_deg
		var d = dir.rotated(deg_to_rad(offset))
		_fire_arrow(d, base_damage, speed, range)
		await get_tree().create_timer(0.1).timeout

func _fire_arrow(dir: Vector2, damage: float, speed: float, range: float):
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
	# Tween 绑在箭上：箭被命中释放时 Tween 自动停止，避免回调 lambda 捕获已释放对象
	var tween = arrow.create_tween()
	tween.tween_property(arrow, "global_position", target_pos, dur)
	tween.tween_callback(arrow.queue_free)

	_raycast_loop(arrow, dir, damage, dur)

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
			if body is Entity and body.team == owner_entity.team:
				continue  # 友军穿透
			if body.has_method("take_damage"):
				body.take_damage(damage)
			if is_instance_valid(arrow): arrow.queue_free()
			return
