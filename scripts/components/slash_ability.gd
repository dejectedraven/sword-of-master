extends AbilityBase

@export var range_length: float = 48.0
@export var hit_count: int = 1

var _hitbox: Area2D

func _ready():
	super._ready()
	var w = "Warrior" in owner_entity.name
	cooldown_time = GameConfig.warrior_slash_cooldown if w else GameConfig.troll_slash_cooldown
	range_length = GameConfig.warrior_slash_range if w else GameConfig.troll_slash_range
	var shape = RectangleShape2D.new()
	shape.size = Vector2(range_length, range_length * 2)
	_hitbox = _make_hitbox("SlashHitbox", shape)

func use() -> bool:
	if not super.use(): return false
	var dir = owner_entity.facing_direction
	var dur = GameConfig.warrior_slash_duration if "Warrior" in owner_entity.name else GameConfig.troll_slash_duration
	var gap = dur * 0.6
	for i in range(hit_count):
		_hit_targets.clear()
		_hitbox.global_position = owner_entity.global_position + dir * 32
		_hitbox.rotation = dir.angle()
		_hitbox.monitoring = true
		await get_tree().create_timer(gap).timeout
		_hitbox.monitoring = false
		if i < hit_count - 1: await get_tree().create_timer(gap * 0.5).timeout
	return true

func _on_hitbox_body(body: Node):
	if body == owner_entity or body in _hit_targets: return
	_hit_targets.append(body)
	if body.has_method("take_damage"):
		var dmg = GameConfig.warrior_attack if "Warrior" in owner_entity.name else GameConfig.troll_attack
		body.take_damage(dmg)
