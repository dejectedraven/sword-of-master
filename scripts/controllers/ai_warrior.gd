extends Node

var entity: Entity
var target: Entity
var _attacking: bool = false
var _skill_timer: float = 0.0
var _retreating: bool = false

func _ready():
    entity = get_parent() as Entity
    entity.is_ai_controlled = true

func _physics_process(delta: float):
    if not entity or entity.health.is_dead: return
    if not target or target.health.is_dead: _find_target(); return
    if _attacking:
        entity.move_direction = Vector2.ZERO
        return

    var dist = entity.global_position.distance_to(target.global_position)
    _skill_timer += delta

    if entity.health.hp_ratio() < GameConfig.warrior_ai_retreat_hp: _retreating = true
    if _retreating:
        if dist < GameConfig.warrior_ai_retreat_out: _retreat(); return
        else: _retreating = false

    if dist < GameConfig.warrior_ai_skill_range and _skill_timer > GameConfig.warrior_ai_skill_cd:
        var c = entity.get_node_or_null("ChargeAbility") as AbilityBase
        if c and not c.is_on_cooldown:
            await _use_charge()
            _skill_timer = 0.0
            return

    if dist < GameConfig.warrior_ai_attack_range:
        await _slash()
        return

    entity.move_direction = (target.global_position - entity.global_position).normalized()

func _retreat():
    entity.move_direction = (entity.global_position - target.global_position).normalized()
    if randf() < GameConfig.warrior_ai_block_chance * 0.02:
        entity._start_blocking()

func _find_target():
    var scene = get_tree().current_scene
    if not scene: return
    target = scene.get_node_or_null("Troll") as Entity

func _slash():
    _attacking = true
    entity.move_direction = Vector2.ZERO
    entity.facing_direction = (target.global_position - entity.global_position).normalized()
    await get_tree().create_timer(GameConfig.warrior_ai_windup).timeout
    if not target or target.health.is_dead: _attacking = false; return

    var dir = (target.global_position - entity.global_position).normalized()
    entity.facing_direction = dir
    entity.state = Entity.State.ATTACK
    entity.play_attack_anim(dir)

    var ab = entity.get_node_or_null("SlashAbility") as AbilityBase
    if ab: await ab.use()
    await get_tree().create_timer(entity._cv("attack_time")).timeout

    entity.state = Entity.State.IDLE
    entity.play_anim("idle")
    await get_tree().create_timer(GameConfig.warrior_ai_recover).timeout
    _attacking = false

func _use_charge():
    _attacking = true
    var dir = (target.global_position - entity.global_position).normalized()
    entity.facing_direction = dir
    entity.state = Entity.State.ATTACK
    entity.play_attack_anim(dir)

    var ab = entity.get_node_or_null("ChargeAbility") as AbilityBase
    if ab: await ab.use()
    await get_tree().create_timer(entity._cv("attack_time")).timeout

    entity.state = Entity.State.IDLE
    entity.play_anim("idle")
    await get_tree().create_timer(GameConfig.warrior_ai_recover).timeout
    _attacking = false
