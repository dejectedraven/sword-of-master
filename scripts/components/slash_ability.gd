extends AbilityBase

@export var range_length: float = 48.0

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
    await _activate_hitbox(_hitbox, owner_entity.global_position + dir * 32,
        dir.angle(), GameConfig.warrior_slash_duration if "Warrior" in owner_entity.name else GameConfig.troll_slash_duration)
    return true

func _on_hitbox_body(body: Node):
    if body == owner_entity or body in _hit_targets: return
    _hit_targets.append(body)
    if body.has_method("take_damage"):
        body.take_damage(GameConfig.warrior_attack if "Warrior" in owner_entity.name else GameConfig.troll_attack)
