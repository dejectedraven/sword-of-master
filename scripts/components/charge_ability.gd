extends AbilityBase

@export var damage: float = 15.0
@export var damage_multiplier: float = 1.5
@export var dash_distance: float = 180.0

var _hitbox: Area2D

func _ready():
	super._ready()
	cooldown_time = GameConfig.warrior_charge_cooldown
	dash_distance = GameConfig.warrior_charge_distance
	damage_multiplier = GameConfig.warrior_charge_mult
	var shape = RectangleShape2D.new()
	shape.size = Vector2(dash_distance, GameConfig.warrior_charge_hit_width)
	_hitbox = _make_hitbox("ChargeHitbox", shape)

func use() -> bool:
	if not super.use(): return false
	var dir = owner_entity.facing_direction
	var target_pos = owner_entity.global_position + dir * dash_distance
	var space_state = owner_entity.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(owner_entity.global_position, target_pos, 2)
	var result = space_state.intersect_ray(query)
	if result: target_pos = result.position - dir * 16
	_hitbox.global_position = owner_entity.global_position + dir * (dash_distance * 0.5)
	_hitbox.rotation = dir.angle()
	_hitbox.monitoring = true; _hit_targets.clear()
	var tween = get_tree().create_tween()
	tween.tween_property(owner_entity, "global_position", target_pos, 0.15)
	await tween.finished
	_hitbox.monitoring = false
	return true

func _on_hitbox_body(body: Node):
	if body == owner_entity or body in _hit_targets: return
	_hit_targets.append(body)
	if body.has_method("take_damage"):
		body.take_damage(damage_multiplier * GameConfig.warrior_attack)
