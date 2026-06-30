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
	if _attacking: entity.move_direction = Vector2.ZERO; return
	var dist = entity.global_position.distance_to(target.global_position)
	_skill_timer += delta
	if entity.health.hp_ratio() < GameConfig.archer_ai_retreat_hp: _retreating = true
	if _retreating:
		if dist < GameConfig.archer_ai_retreat_out: _retreat(); return
		else: _retreating = false
	if dist < GameConfig.archer_ai_skill_range and _skill_timer > GameConfig.archer_ai_skill_cd:
		var d = entity.get_node_or_null("DodgeAbility") as AbilityBase
		if d and not d.is_on_cooldown:
			await _use_dodge()
			_skill_timer = 0.0
			return
	if dist < GameConfig.archer_ai_attack_range:
		await _shoot()
		return
	var d2 = (target.global_position - entity.global_position).normalized()
	if dist > GameConfig.archer_ai_preferred_range:
		entity.move_direction = d2
	else:
		entity.move_direction = Vector2.ZERO

func _retreat():
	entity.move_direction = (entity.global_position - target.global_position).normalized()

func _find_target():
	var scene = get_tree().current_scene
	if not scene: return
	target = scene.get_node_or_null("Troll") as Entity

func _shoot():
	_attacking = true
	entity.move_direction = Vector2.ZERO
	var dir = (target.global_position - entity.global_position).normalized()
	entity.facing_direction = dir
	entity.state = Entity.State.ATTACK
	entity.play_attack_anim(dir)
	await get_tree().create_timer(GameConfig.archer_ai_windup).timeout
	if not target or target.health.is_dead: _attacking = false; return
	var ab = entity.get_node_or_null("ArrowAbility") as AbilityBase
	if ab: await ab.use()
	await get_tree().create_timer(entity._cv("attack_time")).timeout
	entity.state = Entity.State.IDLE
	entity._recovering = true
	await get_tree().create_timer(GameConfig.archer_ai_recover).timeout
	entity._recovering = false
	entity.play_anim("idle")
	_attacking = false

func _use_dodge():
	_attacking = true
	var dir = (target.global_position - entity.global_position).normalized()
	entity.facing_direction = dir
	entity.state = Entity.State.ATTACK
	entity.play_attack_anim(dir)
	var ab = entity.get_node_or_null("DodgeAbility") as AbilityBase
	if ab: await ab.use()
	await get_tree().create_timer(entity._cv("attack_time")).timeout
	entity.state = Entity.State.IDLE
	entity._recovering = true
	await get_tree().create_timer(GameConfig.archer_ai_recover).timeout
	entity._recovering = false
	entity.play_anim("idle")
	_attacking = false
