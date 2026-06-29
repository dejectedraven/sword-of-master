class_name HealthComponent
extends Node

@export var max_hp: float = 100.0
var current_hp: float = 100.0
var is_dead: bool = false

signal hp_changed(current: float, maximum: float)
signal died()

func _ready():
    current_hp = max_hp

func take_damage(amount: float):
    if is_dead:
        return
    current_hp = max(0.0, current_hp - amount)
    hp_changed.emit(current_hp, max_hp)
    if current_hp <= 0:
        is_dead = true
        died.emit()

func heal(amount: float):
    current_hp = min(max_hp, current_hp + amount)
    hp_changed.emit(current_hp, max_hp)

func hp_ratio() -> float:
    return current_hp / max(1.0, max_hp)
