extends AbilityBase

@export var dodge_distance: float = 120.0

func _ready():
	super._ready()
	cooldown_time = GameConfig.archer_dodge_cooldown
	dodge_distance = GameConfig.archer_dodge_distance

func use() -> bool:
	if not super.use(): return false
	var dir = owner_entity.facing_direction
	var target_pos = owner_entity.global_position + dir * dodge_distance
	var space_state = owner_entity.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(owner_entity.global_position, target_pos, 2)
	var result = space_state.intersect_ray(query)
	if result: target_pos = result.position - dir * 16
	owner_entity._invincible = true
	var tween = get_tree().create_tween()
	tween.tween_property(owner_entity, "global_position", target_pos, 0.12)
	await tween.finished
	owner_entity._invincible = false
	return true
