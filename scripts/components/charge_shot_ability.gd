extends AbilityBase

var _charging: bool = false
var _charge_time: float = 0.0

func _ready():
	super._ready()
	cooldown_time = GameConfig.archer_charge_cooldown

func start_charge():
	if is_on_cooldown: return
	_charging = true
	_charge_time = 0.0
	owner_entity.state = Entity.State.ATTACK
	owner_entity.play_attack_anim(owner_entity.facing_direction)

func _process(delta):
	if not _charging: return
	if owner_entity.health.is_dead: _charging = false; return
	_charge_time += delta
	owner_entity._face_mouse()
	if _charge_time >= GameConfig.archer_charge_max_time:
		release_charge()

func release_charge():
	if not _charging: return
	_charging = false
	var ratio = min(_charge_time / max(GameConfig.archer_charge_max_time, 0.001), 1.0)
	var dir = owner_entity.facing_direction
	var base_damage = GameConfig.archer_attack
	var base_speed = GameConfig.archer_arrow_speed
	var range = GameConfig.archer_arrow_range

	var damage = base_damage * (1.0 + ratio * GameConfig.archer_charge_damage_bonus)
	var speed = base_speed * (1.0 + ratio * GameConfig.archer_charge_speed_bonus)

	_fire_arrow(dir, damage, speed, range)
	is_on_cooldown = true
	current_cooldown = cooldown_time

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
	var tween = create_tween()
	tween.tween_property(arrow, "global_position", target_pos, dur)
	tween.tween_callback(func(): if is_instance_valid(arrow): arrow.queue_free())

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
			if body.has_method("take_damage"):
				body.take_damage(damage)
			if is_instance_valid(arrow): arrow.queue_free()
			return
