extends Node2D

var hero_entity: Entity
var troll_entity: Entity
var ai_allies: Array = []
var ai_enemies: Array = []
var _heroes_alive: int = 0
var map_size: Vector2 = Vector2(1280, 720)

func _ready():
	_add_floor()
	_add_walls()
	_instantiate_characters()

func _instantiate_characters():
	var is_boss = GameState.selected_faction == GameState.Faction.BOSS
	if is_boss:
		_setup_boss_mode()
	else:
		_setup_hero_mode()

func _setup_hero_mode():
	hero_entity = _spawn(GameState.selected_character, Vector2(300, 360), false)
	hero_entity.get_node("Camera2D").make_current()
	hero_entity.health.died.connect(_on_hero_died)
	_heroes_alive = 1
	var pool = ["Warrior", "Archer"]
	pool.erase(GameState.selected_character)
	if pool.size() > 0:
		var ally = _spawn(pool[randi() % pool.size()], Vector2(500, 360), true)
		ally.health.died.connect(_on_hero_died)
		ai_allies = [ally]
		_heroes_alive += 1
	troll_entity = _spawn("Troll", Vector2(900, 360), true)
	troll_entity.health.died.connect(_on_troll_died)
	$HUD.setup(hero_entity, troll_entity, [])

func _setup_boss_mode():
	troll_entity = _spawn("Troll", Vector2(900, 360), false)
	troll_entity.get_node("Camera2D").make_current()
	troll_entity.health.died.connect(_on_troll_died)
	var pool = ["Warrior", "Archer"]
	for i in 2:
		var e = _spawn(pool[randi() % pool.size()], Vector2(300 + i * 200, 360), true)
		e.health.died.connect(_on_hero_died)
		ai_enemies.append(e)
		_heroes_alive += 1
	hero_entity = ai_enemies[0] if ai_enemies.size() > 0 else null
	$HUD.setup(troll_entity, null, ai_enemies)

func _spawn(id: String, pos: Vector2, is_ai: bool) -> Entity:
	var e = load("res://scenes/entities/" + id.to_lower() + ".tscn").instantiate()
	e.name = id
	e.position = pos
	e.collision_layer = 1; e.collision_mask = 2
	e.is_ai_controlled = is_ai
	if is_ai:
		e.add_child(_load_ai(id))
	add_child(e)
	return e

func _load_ai(name: String) -> Node:
	var m = {"Warrior": "res://scripts/controllers/ai_warrior.gd", "Archer": "res://scripts/controllers/ai_archer.gd", "Troll": "res://scripts/controllers/ai_troll.gd"}
	return load(m.get(name, "res://scripts/controllers/ai_warrior.gd")).new()

func _on_hero_died():
	_heroes_alive -= 1
	if _heroes_alive <= 0:
		await get_tree().create_timer(1.0).timeout
		GameState.end_game(GameState.VictoryType.TROLL_WIN)

func _on_troll_died():
	await get_tree().create_timer(1.0).timeout
	GameState.end_game(GameState.VictoryType.HERO_WIN)

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
