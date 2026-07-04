extends StaticBody2D

enum ChestState { CLOSED, MINIGAME, OPENING, OPENED }

var _state: ChestState = ChestState.CLOSED
var _player_nearby: bool = false
var _player_entity: CharacterBody2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Prompt

func _ready():
	$InteractArea.body_entered.connect(_on_entered)
	$InteractArea.body_exited.connect(_on_exited)
	prompt.hide()

func _input(event):
	if _state != ChestState.CLOSED or not _player_nearby: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_start_minigame()

func _on_entered(body):
	if body is CharacterBody2D and "Troll" not in body.name:
		_player_nearby = true
		_player_entity = body
		if _state == ChestState.CLOSED: prompt.show()

func _on_exited(body):
	if body == _player_entity:
		_player_nearby = false
		_player_entity = null
		prompt.hide()

func _start_minigame():
	_state = ChestState.MINIGAME
	get_tree().paused = true
	var mg = preload("res://scripts/ui/chest_minigame.gd").new()
	mg.chest_ref = self
	if _player_entity and _player_entity.has_method("_cv"):
		mg.speed = _player_entity._cv("chest_speed")
	get_tree().current_scene.add_child(mg)

func on_minigame_done(success: bool):
	get_tree().paused = false
	_state = ChestState.OPENING
	sprite.frame = 1
	await get_tree().create_timer(0.25).timeout
	if success:
		sprite.frame = 2
		_reward()
	else:
		sprite.frame = 3
	await get_tree().create_timer(0.5).timeout
	_state = ChestState.OPENED

func _reward():
	if _player_entity and _player_entity.has_method("take_damage"):
		var hp = _player_entity.get("health")
		if hp:
			hp.current_hp = min(hp.current_hp + hp.max_hp * 0.3, hp.max_hp)
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
