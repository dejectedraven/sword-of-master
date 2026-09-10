class_name Entity
extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, BLOCK, DEAD }

@export var speed: float = 400

@export_group("Simple Anim")
@export var idle_texture: Texture2D
@export var run_texture: Texture2D
@export var attack_texture: Texture2D
@export var dead_texture: Texture2D
@export var exhaust_texture: Texture2D
@export var idle_frames: int = 6
@export var run_frames: int = 6
@export var attack_frames: int = 4
@export var dead_frames: int = 10
@export var exhaust_frames: int = 10

var state: State = State.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var move_direction: Vector2 = Vector2.ZERO
var is_ai_controlled: bool = false
var team: int = 0  # 阵营：0=中立, 1=英雄方, 2=魔王方（防友伤）
var input_locked: bool = false  # 开箱小游戏等场景锁定输入
var blink_charges: int = 0      # 闪现道具数量（Q 使用）
var light_spirit_count: int = 0 # 光精灵道具数量（E 放置）
var _flash_timer: float = 0.0
var _frame_timer: float = 0.0
var _recovering: bool = false
var _block_ready: bool = true
var _block_cooldown: float = 0.0
var _invincible: bool = false
var _exhausted: bool = false
var _charging: bool = false
var _charge_bg: ColorRect
var _charge_fill: ColorRect

@onready var sprite: Sprite2D = $Sprite2D
# ⚠ 仅 Warrior 使用 AnimationTree（4 方向 BlendSpace2D）；Troll/Archer 用 Simple Anim（直接换 texture）
@onready var anim_tree: AnimationTree = $AnimationTree if has_node("AnimationTree") else null
@onready var health: HealthComponent = $HealthComponent

signal died()

# ⚠ 通用参数查询：GameConfig 找 [前缀_key]，新英雄须在 GameConfig 建同名前缀变量
# prefix 由 name 推断：含"Archer"→archer, 含"Warrior"→warrior, 其余→troll
# 例：Warrior 查 _cv("speed") → GameConfig.warrior_speed
func _cv(key: String):
	var prefix = "archer" if "Archer" in name else ("warrior" if "Warrior" in name else "troll")
	var v = GameConfig.get(prefix + "_" + key)
	return v if v != null else 0.0

func _ready():
	if anim_tree: anim_tree.active = true
	speed = _cv("speed")
	if health:
		health.max_hp = _cv("hp")
		health.current_hp = health.max_hp
	health.died.connect(func():
		state = State.DEAD
		_charging = false
		_set_dead_anim()
		died.emit()
	)
	if idle_texture: sprite.texture = idle_texture; sprite.hframes = idle_frames
	if get_node_or_null("ChargeShotAbility"):
		_charge_bg = ColorRect.new()
		_charge_bg.size = Vector2(40, 4)
		_charge_bg.color = Color(0, 0, 0, 0.6)
		_charge_bg.position = Vector2(-20, -40)
		_charge_bg.material = Unshaded.material()
		add_child(_charge_bg)
		_charge_bg.hide()
		_charge_fill = ColorRect.new()
		_charge_fill.size = Vector2(0, 4)
		_charge_fill.color = Color(1, 0.8, 0, 0.9)
		_charge_fill.material = Unshaded.material()
		_charge_bg.add_child(_charge_fill)
	# 黑夜视野光：英雄（玩家+AI队友）和玩家操控的巨魔有光圈；AI 巨魔藏在黑暗中
	if not ("Troll" in name and is_ai_controlled):
		_create_vision_light()

func _create_vision_light():
	var l = VisionLight.new()
	l.name = "VisionLight"
	l.configure(_cv("vision_radius"), GameConfig.vision_light_energy, true, GameConfig.vision_light_color)
	add_child(l)
	# 自照小光：不投影，保证角色站在树影/树冠下也可见
	var self_l = VisionLight.new()
	self_l.name = "SelfLight"
	self_l.configure(GameConfig.self_light_radius, GameConfig.self_light_energy, false, GameConfig.vision_light_color)
	add_child(self_l)

# ⚠ 必须每个 _try_*() 的 await 后加 if health.is_dead: return，否则 coroutine 会重置 state 覆盖 DEAD
func _physics_process(_d: float):
	if state == State.DEAD: return
	_read_input(); _apply_movement(); _update_anim_state()

func _process(delta: float):
	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0: _restore_color()
	if not _block_ready:
		_block_cooldown -= delta
		if _block_cooldown <= 0: _block_ready = true
	if not anim_tree and state != State.DEAD:
		if (_exhausted or _recovering) and exhaust_texture:
			sprite.texture = exhaust_texture
			sprite.hframes = exhaust_frames
		_frame_timer += delta
		if _frame_timer >= 0.1: _frame_timer = 0.0; sprite.frame = (sprite.frame + 1) % sprite.hframes
	if _charge_fill:
		var ab = get_node_or_null("ChargeShotAbility")
		if ab and ab._charging:
			_charge_bg.show()
			_charge_fill.size.x = 40 * ab.get_charge_ratio()
		else:
			_charge_bg.hide()
	if not anim_tree and state == State.DEAD:
		_frame_timer += delta
		if _frame_timer >= 0.15 and sprite.frame < dead_frames - 1:
			_frame_timer = 0.0; sprite.frame = min(sprite.frame + 1, dead_frames - 1)

func _set_dead_anim():
	if anim_tree:
		# 战士无死亡帧：停树后倒地（旋转+变暗）
		anim_tree.active = false
		_fall_over()
		return
	if dead_texture:
		sprite.texture = dead_texture; sprite.hframes = dead_frames; sprite.frame = 0
	elif exhaust_texture:
		sprite.texture = exhaust_texture; sprite.hframes = exhaust_frames; sprite.frame = 0
	else:
		_fall_over()

# 无死亡素材的角色：精灵倒向面朝方向 + 变暗
func _fall_over():
	var dir = -90.0 if sprite.flip_h else 90.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(sprite, "rotation_degrees", dir, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate", Color(0.45, 0.45, 0.5), 0.5)

func _read_input():
	if is_ai_controlled: return
	if input_locked: move_direction = Vector2.ZERO; return
	if _exhausted or _recovering:
		move_direction = Vector2.ZERO; return
	if state == State.BLOCK: return _read_block_input()
	if state == State.ATTACK:
		move_direction = Vector2.ZERO
		var charge_ab = get_node_or_null("ChargeShotAbility")
		if charge_ab and charge_ab._charging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var data = charge_ab.release_charge()
			if data.size() > 0:
				_charging = false
				_do_charge_release(data)
		return
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	move_direction = move_direction.normalized()

func _read_block_input():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): stop_blocking()

func _apply_movement():
	if _invincible: return
	var motion = move_direction * speed
	if state == State.BLOCK: motion *= _cv("block_speed")
	set_velocity(motion); move_and_slide()
	if state not in [State.ATTACK, State.BLOCK] and move_direction: facing_direction = move_direction

func _update_anim_state():
	if state in [State.DEAD, State.ATTACK, State.BLOCK] or _invincible: return
	var m = move_direction.length() > 0.01
	if m and state != State.RUN: state = State.RUN; play_anim("run")
	elif not m and state != State.IDLE: state = State.IDLE; play_anim("idle")
	_update_flip()

func play_anim(an: String):
	if anim_tree: anim_tree["parameters/playback"].travel(an)
	else:
		match an:
			"idle": if idle_texture: sprite.texture = idle_texture; sprite.hframes = idle_frames
			"run":  if run_texture:  sprite.texture = run_texture;  sprite.hframes = run_frames
		sprite.frame = 0

func play_attack_anim(dir: Vector2):
	if anim_tree:
		anim_tree["parameters/attack/BlendSpace2D/blend_position"] = dir
		anim_tree["parameters/playback"].travel("attack")
	else:
		if attack_texture: sprite.texture = attack_texture; sprite.hframes = attack_frames; sprite.frame = 0

func _update_flip():
	if state == State.ATTACK: return
	if move_direction.x < -0.01: sprite.flip_h = true
	elif move_direction.x > 0.01: sprite.flip_h = false

# ⚠ 按键路由顺序：
#   LMB → ArrowAbility→SlashAbility（远程优先）
#   RMB → ChargeShotAbility→ComboAbility→_start_blocking
#   SPC → TripleShotAbility→ChargeAbility→RushAbility
func _input(event: InputEvent):
	if state == State.DEAD or is_ai_controlled or _recovering or input_locked: return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: _try_attack()
			MOUSE_BUTTON_RIGHT:
				if get_node_or_null("ChargeShotAbility"): _try_charge_shot()
				elif get_node_or_null("ComboAbility"): _try_combo()
				else: _start_blocking()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("skill_q"): _use_blink(); return
		if event.is_action_pressed("skill_e"): _use_light_spirit(); return
		match event.physical_keycode:
			KEY_SPACE:
				if get_node_or_null("TripleShotAbility"): _try_triple_shot()
				elif get_node_or_null("ChargeAbility"): _try_charge()
				elif get_node_or_null("RushAbility"): _try_rush()

# ===== 道具 =====

func add_item(kind: String):
	match kind:
		"blink": blink_charges += 1
		"light_spirit": light_spirit_count += 1

# 闪现：朝鼠标方向位移，撞墙截停，短暂无敌
func _use_blink():
	if blink_charges <= 0 or state == State.DEAD: return
	blink_charges -= 1
	GameState.emit_noise(global_position)  # 闪现出声暴露位置
	var dir = _aim_dir()
	if dir.length() < 0.01: dir = facing_direction
	var target = global_position + dir * GameConfig.blink_distance
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target, 2)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	if result: target = result.position - dir * 20.0
	_invincible = true
	var tw = create_tween()
	tw.tween_property(self, "global_position", target, 0.12)
	await tw.finished
	_invincible = false

# 光精灵：在当前位置放置一个固定光源
func _use_light_spirit():
	if light_spirit_count <= 0 or state == State.DEAD: return
	light_spirit_count -= 1
	GameState.emit_noise(global_position)  # 放置出声暴露位置
	var s = load("res://scenes/objects/light_spirit.tscn").instantiate()
	s.position = global_position
	get_tree().current_scene.add_child(s)

func _try_attack():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("ArrowAbility") as AbilityBase
	if not ab: ab = get_node_or_null("SlashAbility") as AbilityBase
	if not ab or ab.is_on_cooldown: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	if health.is_dead: return
	await get_tree().create_timer(_cv("attack_time")).timeout
	if health.is_dead: return
	state = State.IDLE; play_anim("idle")

func _try_combo():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("ComboAbility") as AbilityBase
	if not ab or ab.is_on_cooldown: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	if health.is_dead: return
	await get_tree().create_timer(_cv("attack_time")).timeout
	if health.is_dead: return
	state = State.IDLE
	_recovering = true
	await get_tree().create_timer(_cv("recover_time")).timeout
	if health.is_dead: return
	_recovering = false
	play_anim("idle")

func _try_charge():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("ChargeAbility") as AbilityBase
	if not ab: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	if health.is_dead: return
	await get_tree().create_timer(_cv("attack_time")).timeout
	if health.is_dead: return
	state = State.IDLE
	_recovering = true
	await get_tree().create_timer(_cv("recover_time")).timeout
	if health.is_dead: return
	_recovering = false
	play_anim("idle")

func _try_rush():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("RushAbility") as AbilityBase
	if not ab: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	if health.is_dead: return
	state = State.IDLE; play_anim("idle")

func _try_charge_shot():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("ChargeShotAbility")
	if not ab or ab.is_on_cooldown: return
	_face_mouse(); state = State.ATTACK; _charging = true
	ab.start_charge()

func _do_charge_release(data: Dictionary):
	state = State.ATTACK
	play_attack_anim(data.dir)
	await get_tree().create_timer(_cv("attack_time")).timeout
	if health.is_dead: return
	var ab = get_node_or_null("ChargeShotAbility")
	if ab: ab.fire_arrow(data.dir, data.damage, data.speed, data.range)
	await get_tree().create_timer(0.1).timeout
	if health.is_dead: return
	state = State.IDLE; play_anim("idle")

func _try_triple_shot():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("TripleShotAbility") as AbilityBase
	if not ab or ab.is_on_cooldown: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	if health.is_dead: return
	await get_tree().create_timer(_cv("attack_time")).timeout
	if health.is_dead: return
	state = State.IDLE; play_anim("idle")

func _restore_color():
	if state == State.DEAD: return  # 死亡变暗不可被受击闪白覆盖
	sprite.modulate = Color(0.3, 0.5, 1.0) if state == State.BLOCK else Color.WHITE

func _start_blocking():
	if state in [State.ATTACK, State.BLOCK] or not _block_ready: return
	state = State.BLOCK; move_direction = Vector2.ZERO
	sprite.modulate = Color(0.3, 0.5, 1.0)

func stop_blocking():
	if state != State.BLOCK: return
	state = State.IDLE; sprite.modulate = Color.WHITE

func _break_block():
	state = State.IDLE
	_block_ready = false; _block_cooldown = _cv("block_cooldown")
	sprite.modulate = Color.WHITE

func _aim_dir() -> Vector2:
	return (get_global_mouse_position() - global_position).normalized()

func _face_mouse():
	var d = _aim_dir()
	if d.length() > 0: facing_direction = d; sprite.flip_h = d.x < 0

func take_damage(amount: float):
	if _invincible: return
	var blocked = state == State.BLOCK
	var mult = 1.0 - _cv("block_reduction") if blocked else 1.0
	if blocked: _break_block()
	var fd = amount * mult * (100.0 / (100.0 + _cv("defense")))
	health.take_damage(fd)
	# 伤害飘字：格挡=蓝，大伤害(蓄力箭)=橙，普通=白
	var col = Color(0.5, 0.75, 1.0) if blocked else (Color(1, 0.8, 0.2) if fd >= 25.0 else Color(1, 1, 1))
	DamageNumber.spawn(get_tree().current_scene, global_position, fd, col)
	sprite.modulate = Color.RED; _flash_timer = 0.25
