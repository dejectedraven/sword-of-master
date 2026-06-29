class_name AbilityBase
extends Node

@export var cooldown_time: float = 1.0

var is_on_cooldown: bool = false
var current_cooldown: float = 0.0
var owner_entity: CharacterBody2D
var _hit_targets: Array[Node] = []

signal ability_used()
signal cooldown_ready()

func _ready():
    owner_entity = get_parent() as CharacterBody2D

func use() -> bool:
    if is_on_cooldown:
        return false
    is_on_cooldown = true
    current_cooldown = cooldown_time
    ability_used.emit()
    return true

func _process(delta: float):
    if is_on_cooldown:
        current_cooldown -= delta
        if current_cooldown <= 0:
            current_cooldown = 0
            is_on_cooldown = false
            cooldown_ready.emit()

func _make_hitbox(box_name: String, shape: Shape2D) -> Area2D:
    var area = Area2D.new()
    area.collision_layer = 4
    area.collision_mask = 1
    var col_shape = CollisionShape2D.new()
    col_shape.shape = shape
    area.add_child(col_shape)
    area.monitoring = false
    area.body_entered.connect(_on_hitbox_body)
    add_child(area)
    return area

func _activate_hitbox(hitbox: Area2D, pos: Vector2, rot: float, duration: float):
    _hit_targets.clear()
    hitbox.global_position = pos
    hitbox.rotation = rot
    hitbox.monitoring = true
    await get_tree().create_timer(duration).timeout
    hitbox.monitoring = false

func _on_hitbox_body(body: Node):
    pass
