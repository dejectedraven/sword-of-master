extends Area2D

enum DoorState { LOCKED, UNLOCKED }

var door_state: DoorState = DoorState.LOCKED
var _pulse: float = 0.0
var _particles: CPUParticles2D

@onready var locked_body: StaticBody2D = $LockedBody
@onready var glow: ColorRect = $Glow
@onready var hint: Label = $Hint

func _ready():
	body_entered.connect(_on_body_entered)
	# 夜里传送门的光/提示始终可见（当灯塔用）
	glow.material = Unshaded.material()
	hint.material = Unshaded.material()
	_particles = _make_portal_particles()
	add_child(_particles)
	_update_visual()

func _make_portal_particles() -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.amount = 8; p.lifetime = 1.2; p.one_shot = false; p.explosiveness = 0.5
	p.direction = Vector2(0, -1); p.spread = 180.0; p.gravity = Vector2(0, 0)
	p.initial_velocity_min = 10.0; p.initial_velocity_max = 30.0
	p.scale_amount_min = 1.0; p.scale_amount_max = 2.0
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0, 0.5, 1])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(0.1, 0.8, 0.3, 0.5), Color(0, 0, 0, 0)])
	p.color_initial_ramp = grad
	p.emitting = false
	return p

func _process(delta):
	_pulse += delta * 2.0
	if door_state == DoorState.LOCKED:
		glow.color = Color(0.8, 0.1, 0.1, 0.4 + sin(_pulse) * 0.2)
		hint.text = "需要 " + str(GameConfig.escape_gold_threshold) + " 金币才能开启"
	elif door_state == DoorState.UNLOCKED:
		glow.color = Color(0.1, 0.8, 0.3, 0.5 + sin(_pulse) * 0.3)
		hint.text = "逃离!"

func try_unlock(gold: int):
	if door_state == DoorState.UNLOCKED: return
	if gold >= GameConfig.escape_gold_threshold:
		door_state = DoorState.UNLOCKED
		locked_body.queue_free()
		_particles.emitting = true
		_update_visual()

func _update_visual():
	match door_state:
		DoorState.LOCKED:
			glow.color = Color(0.8, 0.1, 0.1, 0.5)
			hint.show()
		DoorState.UNLOCKED:
			glow.color = Color(0.1, 0.8, 0.3, 0.7)
			hint.text = "逃离!"

func _on_body_entered(body):
	if door_state != DoorState.UNLOCKED: return
	if body is Entity and not body.health.is_dead:
		if not body.is_ai_controlled:
			GameState.end_game(GameState.VictoryType.ESCAPE_WIN)
