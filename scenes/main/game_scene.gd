extends Node2D

@onready var warrior: Entity = $Warrior
@onready var troll: Entity = $Troll

var map_size: Vector2 = Vector2(1280, 720)

func _ready():
	_add_floor()
	_add_walls()
	_setup_characters()

func _setup_characters():
	warrior.collision_layer = 1; warrior.collision_mask = 2
	troll.collision_layer = 1; troll.collision_mask = 2

	var is_boss = GameState.selected_faction == GameState.Faction.BOSS
	if is_boss:
		troll.is_ai_controlled = false
		troll.get_node("Camera2D").make_current()
		warrior.is_ai_controlled = true
		warrior.add_child(load("res://scripts/controllers/ai_warrior.gd").new())
		troll.health.died.connect(_on_troll_died)
		warrior.health.died.connect(_on_warrior_died)
	else:
		warrior.is_ai_controlled = false
		warrior.get_node("Camera2D").make_current()
		troll.is_ai_controlled = true
		troll.add_child(load("res://scripts/controllers/ai_troll.gd").new())
		warrior.health.died.connect(_on_warrior_died)
		troll.health.died.connect(_on_troll_died)

func _add_floor():
	var floor = ColorRect.new()
	floor.color = Color(0.15, 0.15, 0.18, 1)
	floor.size = map_size
	add_child(floor); move_child(floor, 0)

func _add_walls():
	var walls = StaticBody2D.new()
	walls.collision_layer = 2; walls.collision_mask = 0
	var t = 32.0; var w = map_size.x; var h = map_size.y
	for wall in [
		[Vector2(w / 2, -t / 2), Vector2(w, t)],
		[Vector2(w / 2, h + t / 2), Vector2(w, t)],
		[Vector2(-t / 2, h / 2), Vector2(t, h)],
		[Vector2(w + t / 2, h / 2), Vector2(t, h)],
	]:
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new(); rect.size = wall[1]
		shape.shape = rect; shape.position = wall[0]
		walls.add_child(shape)
	add_child(walls)

func _on_troll_died():
	await get_tree().create_timer(1.0).timeout
	GameState.end_game(GameState.VictoryType.HERO_WIN)

func _on_warrior_died():
	await get_tree().create_timer(1.0).timeout
	GameState.end_game(GameState.VictoryType.TROLL_WIN)
