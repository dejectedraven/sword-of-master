class_name Entity
extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, BLOCK, DEAD }

@export var speed: float = 400
@export var stats: EntityStats

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
var _flash_timer: float = 0.0
var _frame_timer: float = 0.0
var _recovering: bool = false
var _block_ready: bool = true
var _block_cooldown: float = 0.0
var _invincible: bool = false
var _exhausted: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_tree: AnimationTree = $AnimationTree if has_node("AnimationTree") else null
@onready var health: HealthComponent = $HealthComponent

signal died()

func _cv(key: String):
	var w = "Warrior" in name
	match key:
		"hp": return GameConfig.warrior_hp if w else GameConfig.troll_hp
		"speed": return GameConfig.warrior_speed if w else GameConfig.troll_speed
		"defense": return GameConfig.warrior_defense if w else GameConfig.troll_defense
		"block_speed": return GameConfig.warrior_block_speed if w else GameConfig.troll_block_speed
		"block_cooldown": return GameConfig.warrior_block_cooldown if w else GameConfig.troll_block_cooldown
		"block_reduction": return GameConfig.warrior_block_reduction if w else GameConfig.troll_block_reduction
		"attack_time": return GameConfig.warrior_attack_time if w else GameConfig.troll_attack_time
		"recover_time": return GameConfig.warrior_recover_time if w else GameConfig.troll_recover_time
		_: return 0.0

func _ready():
	if anim_tree: anim_tree.active = true
	speed = _cv("speed")
	if health:
		health.max_hp = _cv("hp")
		health.current_hp = health.max_hp
	health.died.connect(func():
		state = State.DEAD
		_set_dead_anim()
		died.emit()
	)
	if idle_texture: sprite.texture = idle_texture; sprite.hframes = idle_frames

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
	elif not anim_tree and state == State.DEAD:
		_frame_timer += delta
		if _frame_timer >= 0.15 and sprite.frame < dead_frames - 1:
			_frame_timer = 0.0; sprite.frame = min(sprite.frame + 1, dead_frames - 1)

func _set_dead_anim():
	if anim_tree: return
	if dead_texture:
		sprite.texture = dead_texture; sprite.hframes = dead_frames; sprite.frame = 0
	elif exhaust_texture:
		sprite.texture = exhaust_texture; sprite.hframes = exhaust_frames; sprite.frame = 0

func _read_input():
	if is_ai_controlled: return
	if _exhausted: move_direction = Vector2.ZERO; return
	if state == State.BLOCK: return _read_block_input()
	if state == State.ATTACK: return
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

func _input(event: InputEvent):
	if state == State.DEAD or is_ai_controlled or _recovering: return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: _try_attack()
			MOUSE_BUTTON_RIGHT: _start_blocking()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE:
				if get_node_or_null("ChargeAbility"): _try_charge()
				elif get_node_or_null("RushAbility"): _try_rush()

func _try_attack():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("SlashAbility") as AbilityBase
	if not ab: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	await get_tree().create_timer(_cv("attack_time")).timeout
	state = State.IDLE
	_recovering = true
	await get_tree().create_timer(_cv("recover_time")).timeout
	_recovering = false
	play_anim("idle")

func _try_charge():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("ChargeAbility") as AbilityBase
	if not ab: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	await get_tree().create_timer(_cv("attack_time")).timeout
	state = State.IDLE
	_recovering = true
	await get_tree().create_timer(_cv("recover_time")).timeout
	_recovering = false
	play_anim("idle")

func _try_rush():
	if state in [State.ATTACK, State.BLOCK]: return
	var ab = get_node_or_null("RushAbility") as AbilityBase
	if not ab: return
	_face_mouse(); state = State.ATTACK
	play_attack_anim(_aim_dir())
	await ab.use()
	state = State.IDLE; play_anim("idle")

func _restore_color():
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
	var mult = 1.0 - _cv("block_reduction") if state == State.BLOCK else 1.0
	if state == State.BLOCK: _break_block()
	var fd = amount * mult * (100.0 / (100.0 + _cv("defense")))
	health.take_damage(fd)
	sprite.modulate = Color.RED; _flash_timer = 0.25
