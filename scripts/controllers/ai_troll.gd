extends Node
# 巨魔 AI（黑夜潜行版）
# 状态机：巡逻 → 探测/听声 → 追击 → 搜索最后已知位置 → 回归巡逻
# 英雄躲在黑暗中不会被发现；开箱/闪现/放置光精灵会发出噪声暴露位置

enum AIState { PATROL, CHASE, SEARCH }

const SEARCH_DURATION := 3.0

var entity: Entity
var target: Entity
var _attacking: bool = false
var _skill_timer: float = 0.0
var _retreating: bool = false
var _state: AIState = AIState.PATROL
var _patrol_target: Vector2 = Vector2.ZERO
var _last_known: Vector2 = Vector2.ZERO
var _search_timer: float = 0.0
var _patrol_timer: float = 0.0

func _ready():
	entity = get_parent() as Entity
	entity.is_ai_controlled = true
	_pick_patrol_point()
	GameState.noise_emitted.connect(_on_noise)

func _physics_process(delta: float):
	if not entity or entity.health.is_dead: return
	if not target or target.health.is_dead:
		_find_target()
		if not target and _state == AIState.CHASE:
			_state = AIState.PATROL
	if _attacking:
		entity.move_direction = Vector2.ZERO
		return

	var dist = INF
	if target:
		dist = entity.global_position.distance_to(target.global_position)
		# 视野探测：进入探测半径立即追击
		if dist <= GameConfig.troll_ai_detect_radius:
			_state = AIState.CHASE
			_last_known = target.global_position

	# 低血撤退（优先于一切）
	_skill_timer += delta
	if entity.health.hp_ratio() < GameConfig.troll_ai_retreat_hp: _retreating = true
	if _retreating:
		if target and dist < GameConfig.troll_ai_retreat_out: _retreat(); return
		else: _retreating = false

	# 追击：打人
	if _state == AIState.CHASE and target:
		if dist < GameConfig.troll_ai_skill_range and _skill_timer > GameConfig.troll_ai_skill_cd:
			var r = entity.get_node_or_null("RushAbility") as AbilityBase
			if r and not r.is_on_cooldown:
				await _use_rush()
				_skill_timer = 0.0
				return
		if dist < GameConfig.troll_ai_attack_range:
			var c = entity.get_node_or_null("ComboAbility") as AbilityBase
			if c and not c.is_on_cooldown:
				await _use_combo()
			else:
				await _slash()
			return
		entity.move_direction = (target.global_position - entity.global_position).normalized()
		return

	# 搜索最后已知位置
	if _state == AIState.SEARCH:
		_search_timer -= delta
		var d = _last_known - entity.global_position
		if d.length() < 40.0 or _search_timer <= 0.0:
			_state = AIState.PATROL
			_pick_patrol_point()
		else:
			entity.move_direction = d.normalized()
		return

	# 巡逻
	_patrol_timer -= delta
	var pd = _patrol_target - entity.global_position
	if pd.length() < 40.0 or _patrol_timer <= 0.0:
		_pick_patrol_point()
	else:
		entity.move_direction = pd.normalized()

# 听声辨位：开箱/闪现/放置光精灵会发出噪声
func _on_noise(pos: Vector2, _radius: float):
	if not entity or entity.health.is_dead: return
	if entity.global_position.distance_to(pos) <= GameConfig.troll_ai_hear_radius:
		_last_known = pos
		_state = AIState.SEARCH
		_search_timer = SEARCH_DURATION

func _pick_patrol_point():
	_patrol_target = Vector2(randf_range(100.0, 1180.0), randf_range(100.0, 620.0))
	_patrol_timer = randf_range(4.0, 7.0)

func _retreat():
	if not target: return
	entity.move_direction = (entity.global_position - target.global_position).normalized()

func _find_target():
	var scene = get_tree().current_scene
	if not scene: return
	for c in scene.get_children():
		if c is Entity and "Troll" not in c.name and not c.health.is_dead:
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
	if entity.health.is_dead: _attacking = false; return
	_shake_cam()
	entity.state = Entity.State.IDLE
	entity.play_anim("idle")
	_attacking = false

func _use_combo():
	_attacking = true
	var dir = (target.global_position - entity.global_position).normalized()
	entity.facing_direction = dir
	entity.state = Entity.State.ATTACK
	entity.play_attack_anim(dir)
	var ab = entity.get_node_or_null("ComboAbility") as AbilityBase
	if ab: await ab.use()
	if entity.health.is_dead: _attacking = false; return
	_shake_cam()
	await get_tree().create_timer(entity._cv("attack_time")).timeout
	if entity.health.is_dead: _attacking = false; return
	entity.state = Entity.State.IDLE
	entity._recovering = true
	await get_tree().create_timer(entity._cv("recover_time")).timeout
	if entity.health.is_dead: _attacking = false; return
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
	if entity.health.is_dead: _attacking = false; return
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
