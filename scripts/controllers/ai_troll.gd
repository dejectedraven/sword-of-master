extends Node

var entity: Entity
var target: Entity
var _attacking: bool = false
var _skill_timer: float = 0.0
var _retreating: bool = false

func _ready():
	entity = get_parent() as Entity
	entity.is_ai_controlled = true

func _physics_process(delta: float):
	if not entity or entity.health.is_dead: return
	if not target or target.health.is_dead: _find_target(); return
	if _attacking:
		entity.move_direction = Vector2.ZERO
		return
	var dist = entity.global_position.distance_to(target.global_position)
	_skill_timer += delta
	if entity.health.hp_ratio() < GameConfig.troll_ai_retreat_hp: _retreating = true
	if _retreating:
		if dist < GameConfig.troll_ai_retreat_out: _retreat(); return
		else: _retreating = false
	if dist < GameConfig.troll_ai_skill_range and _skill_timer > GameConfig.troll_ai_skill_cd:
		var r = entity.get_node_or_null("RushAbility") as AbilityBase
		if r and not r.is_on_cooldown:
			await _use_rush()
			_skill_timer = 0.0
			return
	if dist < GameConfig.troll_ai_attack_range:
		await _slash()
		return
	entity.move_direction = (target.global_position - entity.global_position).normalized()

func _retreat():
	entity.move_direction = (entity.global_position - target.global_position).normalized()

func _find_target():
	var scene = get_tree().current_scene
	if not scene: return
	for c in scene.get_children():
		if c is Entity and "Troll" not in c.name and not c.is_ai_controlled:
			target = c
			return

func _slash():
	_attacking = true
	entity.move_direction = Vector2.ZERO
	entity.facing_direction = (target.global_position - entity.global_position).normalized()
	await get_tree().create_timer(GameConfig.troll_ai_windup).timeout
	if not target or target.health.is_dead: _attacking = false; return
	var dir = (target.global_position - entity.global_position).normalized()
	entity.facing_direction = dir
	entity.state = Entity.State.ATTACK
	entity.play_attack_anim(dir)
	var ab = entity.get_node_or_null("SlashAbility") as AbilityBase
	if ab: await ab.use()
	_shake_cam()
	await get_tree().create_timer(entity._cv("attack_time")).timeout
	entity.state = Entity.State.IDLE
	entity._recovering = true
	await get_tree().create_timer(GameConfig.troll_ai_recover).timeout
	entity._recovering = false
	entity.play_anim("idle")
	_attacking = false

func _use_rush():
	_attacking = true
	var dir = (target.global_position - entity.global_position).normalized()
	entity.facing_direction = dir
	entity.state = Entity.State.ATTACK
	entity.play_attack_anim(dir)
	var ab = entity.get_node_or_null("RushAbility") as AbilityBase
	if ab: await ab.use()
	entity.state = Entity.State.IDLE
	entity.play_anim("idle")
	await get_tree().create_timer(0.3).timeout
	_attacking = false

func _shake_cam():
	var cam = entity.get_viewport().get_camera_2d()
	if not cam: return
	var orig = cam.offset
	var t = create_tween()
	t.tween_property(cam, "offset", orig + Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.03)
	t.tween_property(cam, "offset", orig + Vector2(randf_range(-2, 2), randf_range(-2, 2)), 0.03)
	t.tween_property(cam, "offset", orig, 0.06)
