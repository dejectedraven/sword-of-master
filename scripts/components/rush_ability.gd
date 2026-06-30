extends AbilityBase

@export var rush_duration: float = 1.5
@export var start_speed: float = 50.0
@export var max_speed: float = 800.0
@export var rush_damage: float = 40.0
@export var exhaust_duration: float = 2.0

var _hitbox: Area2D

func _ready():
	super._ready()
	cooldown_time = GameConfig.troll_rush_cooldown
	rush_duration = GameConfig.troll_rush_duration
	start_speed = GameConfig.troll_rush_start
	max_speed = GameConfig.troll_rush_max
	rush_damage = GameConfig.troll_rush_damage
	exhaust_duration = GameConfig.troll_rush_exhaust
	var sz = GameConfig.troll_rush_hitbox
	var shape = RectangleShape2D.new()
	shape.size = Vector2(sz, sz)
	_hitbox = _make_hitbox("RushHitbox", shape)

func use() -> bool:
	if not super.use(): return false
	owner_entity._invincible = true
	owner_entity.state = Entity.State.ATTACK
	var dir = owner_entity.facing_direction
	_hitbox.monitoring = true
	_hit_targets.clear()

	var cam = owner_entity.get_viewport().get_camera_2d()
	var cam_offset = cam.offset if cam else Vector2.ZERO
	var shake = GameConfig.troll_rush_shake

	var elapsed: float = 0.0
	while elapsed < rush_duration:
		var t = elapsed / rush_duration
		var speed = lerp(start_speed, max_speed, t * t * t)
		owner_entity.velocity = dir * speed
		owner_entity.move_and_slide()
		_hitbox.global_position = owner_entity.global_position + dir * GameConfig.troll_rush_offset
		_hitbox.rotation = dir.angle()
		if cam:
			cam.offset = cam_offset + Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		await get_tree().process_frame
		elapsed += 0.016

	_hitbox.monitoring = false
	owner_entity._invincible = false
	owner_entity.move_direction = Vector2.ZERO
	owner_entity.state = Entity.State.IDLE
	owner_entity.play_anim("idle")

	if cam:
		var t = create_tween()
		t.tween_property(cam, "offset", cam_offset, 0.3)

	owner_entity._exhausted = true
	await get_tree().create_timer(exhaust_duration).timeout
	owner_entity._exhausted = false
	owner_entity.play_anim("idle")
	return true

func _on_hitbox_body(body: Node):
	if body == owner_entity or body in _hit_targets: return
	_hit_targets.append(body)
	if body.has_method("take_damage"):
		body.take_damage(rush_damage)
