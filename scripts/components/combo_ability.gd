extends AbilityBase

var _hitbox: Area2D

func _ready():
	super._ready()
	cooldown_time = GameConfig.troll_combo_cooldown
	var shape = RectangleShape2D.new()
	shape.size = Vector2(GameConfig.troll_combo_range, GameConfig.troll_combo_range * 2)
	_hitbox = _make_hitbox("ComboHitbox", shape)

func use() -> bool:
	if not super.use(): return false
	var owner = owner_entity
	var dir = owner.facing_direction
	var gap = GameConfig.troll_combo_duration / 3.0
	for i in 3:
		_hit_targets.clear()
		_hitbox.global_position = owner.global_position + dir * 32
		_hitbox.rotation = dir.angle()
		_hitbox.monitoring = true
		owner.play_attack_anim(dir)
		await get_tree().create_timer(gap).timeout
		_hitbox.monitoring = false
		if i < 2:
			await get_tree().create_timer(gap * 0.3).timeout
	return true

func _on_hitbox_body(body: Node):
	if body == owner_entity or body in _hit_targets: return
	_hit_targets.append(body)
	if body.has_method("take_damage"):
		body.take_damage(GameConfig.troll_combo_damage)
