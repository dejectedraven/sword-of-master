extends Node2D

var hero_entity: Entity
var troll_entity: Entity
var map_size: Vector2 = Vector2(1280, 720)

func _ready():
	_add_floor()
	_add_walls()
	_instantiate_characters()

func _instantiate_characters():
	var mode = GameState.selected_faction
	var hero_id = GameState.selected_character if mode != GameState.Faction.SPECTATE else GameState.last_selected_hero
	hero_id = hero_id if mode != GameState.Faction.BOSS else GameState.last_selected_hero
	var hero_scene = load("res://scenes/entities/" + hero_id.to_lower() + ".tscn")
	hero_entity = hero_scene.instantiate()
	hero_entity.name = hero_id
	hero_entity.position = Vector2(400, 360)
	add_child(hero_entity)
	var boss_scene = load("res://scenes/entities/troll.tscn")
	troll_entity = boss_scene.instantiate()
	troll_entity.name = "Troll"
	troll_entity.position = Vector2(900, 360)
	add_child(troll_entity)
	_setup_characters()

func _setup_characters():
	hero_entity.collision_layer = 1; hero_entity.collision_mask = 2
	troll_entity.collision_layer = 1; troll_entity.collision_mask = 2
	var mode = GameState.selected_faction
	var is_boss = mode == GameState.Faction.BOSS
	var is_spectate = mode == GameState.Faction.SPECTATE
	if is_spectate:
		hero_entity.is_ai_controlled = true
		hero_entity.add_child(_load_ai(hero_entity.name))
		troll_entity.is_ai_controlled = true
		troll_entity.add_child(load("res://scripts/controllers/ai_troll.gd").new())
		hero_entity.get_node("Camera2D").make_current()
	elif is_boss:
		troll_entity.is_ai_controlled = false
		troll_entity.get_node("Camera2D").make_current()
		hero_entity.is_ai_controlled = true
		hero_entity.add_child(_load_ai(hero_entity.name))
	else:
		hero_entity.is_ai_controlled = false
		hero_entity.get_node("Camera2D").make_current()
		troll_entity.is_ai_controlled = true
		troll_entity.add_child(load("res://scripts/controllers/ai_troll.gd").new())
	hero_entity.health.died.connect(_on_hero_died)
	troll_entity.health.died.connect(_on_troll_died)
	var hud = $HUD
	hud.setup_entities(hero_entity, troll_entity)

func _load_ai(name: String) -> Node:
	var m = {"Warrior": "res://scripts/controllers/ai_warrior.gd", "Archer": "res://scripts/controllers/ai_archer.gd"}
	return load(m.get(name, "res://scripts/controllers/ai_warrior.gd")).new()

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

func _on_hero_died():
	await get_tree().create_timer(1.0).timeout
	GameState.end_game(GameState.VictoryType.TROLL_WIN)
