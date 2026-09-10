extends StaticBody2D

enum ChestState { CLOSED, MINIGAME, OPENING, OPENED }

var _state: ChestState = ChestState.CLOSED
var _player_nearby: bool = false
var _player_entity: Entity = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Prompt

func _ready():
	$InteractArea.body_entered.connect(_on_entered)
	$InteractArea.body_exited.connect(_on_exited)
	prompt.material = Unshaded.material()  # 夜里提示可见
	prompt.hide()
	# 微弱自发光：黑暗中能辨认宝箱轮廓
	var glow = VisionLight.new()
	glow.name = "ChestGlow"
	glow.configure(GameConfig.chest_glow_radius, GameConfig.chest_glow_energy, false)
	add_child(glow)

func _input(event):
	if _state != ChestState.CLOSED or not _player_nearby: return
	if not is_instance_valid(_player_entity) or _player_entity.health.is_dead: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_start_minigame()

func _on_entered(body):
	# Boss（name 含"Troll"）不可开箱
	if body is Entity and "Troll" not in body.name:
		_player_nearby = true
		_player_entity = body
		if _state == ChestState.CLOSED: prompt.show()

func _on_exited(body):
	if body == _player_entity:
		_player_nearby = false
		_player_entity = null
		prompt.hide()

func _start_minigame():
	if not is_instance_valid(_player_entity) or _player_entity.health.is_dead: return
	_state = ChestState.MINIGAME
	GameState.emit_noise(global_position)  # 开箱出声，可能引来巨魔
	# 小游戏期间锁定玩家输入（不能移动/攻击/格挡）
	_player_entity.stop_blocking()
	_player_entity.input_locked = true
	var mg = preload("res://scripts/ui/chest_minigame.gd").new()
	mg.chest_ref = self
	mg.speed = _player_entity._cv("chest_speed")
	get_tree().current_scene.add_child(mg)

func on_minigame_done(success: bool):
	var player_ok = is_instance_valid(_player_entity) and not _player_entity.health.is_dead
	if is_instance_valid(_player_entity):
		_player_entity.input_locked = false
	_state = ChestState.OPENING
	sprite.frame = 1
	await get_tree().create_timer(0.25).timeout
	if success and player_ok:
		sprite.frame = 2
		_reward()
	else:
		sprite.frame = 3
	await get_tree().create_timer(0.5).timeout
	_state = ChestState.OPENED

func _reward():
	GameState.add_gold(GameConfig.chest_gold_amount)
	if is_instance_valid(_player_entity) and not _player_entity.health.is_dead:
		var hp = _player_entity.health
		hp.current_hp = min(hp.current_hp + hp.max_hp * GameConfig.chest_heal_ratio, hp.max_hp)
		# 随机道具：闪现（Q）/ 光精灵（E）
		var kind = "blink" if randi() % 2 == 0 else "light_spirit"
		_player_entity.add_item(kind)
		var txt = "闪现 x1" if kind == "blink" else "光精灵 x1"
		var col = Color(0.55, 0.8, 1.0) if kind == "blink" else Color(0.6, 1.0, 0.85)
		DamageNumber.spawn_label(get_tree().current_scene, global_position, txt, col)
	# Godot 4.6 CPUParticles2D：initial_velocity→initial_velocity_min/max
	# scale_amount→scale_amount_min/max；color→color_initial_ramp（Gradient）
	var p = CPUParticles2D.new()
	p.one_shot = true; p.explosiveness = 1.0
	p.amount = 20; p.lifetime = 0.8
	p.direction = Vector2(0, -1); p.spread = 180.0
	p.initial_velocity_min = 40.0; p.initial_velocity_max = 120.0
	p.scale_amount_min = 1.0; p.scale_amount_max = 3.0
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1, 0.85, 0.3), Color(1, 0.6, 0.1)])
	p.color_initial_ramp = grad
	p.gravity = Vector2(0, 200)
	add_child(p); p.emitting = true
