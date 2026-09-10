extends Node2D

var hero_entity: Entity
var troll_entity: Entity
var ai_allies: Array = []
var ai_enemies: Array = []
var _heroes_alive: int = 0
var _camera_holder: Entity
var map_size: Vector2 = Vector2(1280, 720)

func _ready():
	_add_floor()
	_add_walls()
	_instantiate_characters()
	_spawn_chests()
	_spawn_escape_door()

func _instantiate_characters():
	var is_boss = GameState.selected_faction == GameState.Faction.BOSS
	if is_boss:
		_setup_boss_mode()
	else:
		_setup_hero_mode()

func _setup_hero_mode():
	hero_entity = _spawn(GameState.selected_character, Vector2(300, 360), false)
	hero_entity.get_node("Camera2D").make_current()
	_camera_holder = hero_entity
	hero_entity.health.died.connect(_on_hero_died.bind(hero_entity))
	_heroes_alive = 1
	# 2 名 AI 队友：先保证另一个职业，再随机补一个（允许重复）
	var all_pool = ["Warrior", "Archer"]
	var other_pool = all_pool.duplicate()
	other_pool.erase(GameState.selected_character)
	var ally_names: Array = []
	if other_pool.size() > 0: ally_names.append(other_pool[0])
	ally_names.append(all_pool[randi() % all_pool.size()])
	var ally_spots = [Vector2(500, 300), Vector2(500, 420)]
	ai_allies = []
	for i in ally_names.size():
		var ally = _spawn(ally_names[i], ally_spots[i], true)
		ally.health.died.connect(_on_hero_died.bind(ally))
		ai_allies.append(ally)
		_heroes_alive += 1
	troll_entity = _spawn("Troll", Vector2(900, 360), true)
	troll_entity.health.died.connect(_on_troll_died)
	$HUD.setup(hero_entity, troll_entity, ai_allies, [])

func _setup_boss_mode():
	troll_entity = _spawn("Troll", Vector2(900, 360), false)
	troll_entity.get_node("Camera2D").make_current()
	_camera_holder = troll_entity
	troll_entity.health.died.connect(_on_troll_died)
	var pool = ["Warrior", "Archer"]
	ai_enemies = []
	for i in 3:
		var hero_type = pool[randi() % pool.size()]
		var e = _spawn(hero_type, Vector2(300 + i * 200, 360), true)
		e.health.died.connect(_on_hero_died.bind(e))
		ai_enemies.append(e)
		_heroes_alive += 1
	hero_entity = ai_enemies[0] if ai_enemies.size() > 0 else null
	$HUD.setup(troll_entity, null, [], ai_enemies)

func _spawn(id: String, pos: Vector2, is_ai: bool) -> Entity:
	var e = load("res://scenes/entities/" + id.to_lower() + ".tscn").instantiate()
	e.name = id
	e.position = pos
	e.collision_layer = 1; e.collision_mask = 2
	e.team = 2 if id == "Troll" else 1
	e.is_ai_controlled = is_ai
	var cam = e.get_node_or_null("Camera2D")
	if cam:
		# 相机限制在地图内，避免看到地图外的空白
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(map_size.x)
		cam.limit_bottom = int(map_size.y)
	if is_ai:
		e.add_child(_load_ai(id))
	add_child(e, true)  # force_readable_name：重复职业自动命名为 Archer2 等
	return e

func _load_ai(name: String) -> Node:
	var m = {"Warrior": "res://scripts/controllers/ai_warrior.gd", "Archer": "res://scripts/controllers/ai_archer.gd", "Troll": "res://scripts/controllers/ai_troll.gd"}
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

func _spawn_chests():
	var cfg = GameConfig
	var count = cfg.chest_count
	var spots = [
		Vector2(200, 200), Vector2(400, 150), Vector2(600, 200),
		Vector2(1000, 200), Vector2(1100, 400), Vector2(1000, 600),
		Vector2(200, 500), Vector2(400, 600), Vector2(600, 550),
		Vector2(800, 350),
	]
	spots.shuffle()
	for i in range(min(count, spots.size())):
		var c = load("res://scenes/objects/chest.tscn").instantiate()
		c.position = spots[i]
		add_child(c)

func _spawn_escape_door():
	var door = load("res://scenes/objects/escape_door.tscn").instantiate()
	door.position = Vector2(1180, 620)  # 右下角
	add_child(door)
	# 绑定方法连接：场景释放时自动断开，避免重开累积连接
	GameState.gold_changed.connect(_on_gold_changed.bind(door))

func _on_gold_changed(gold: int, door: Node):
	if is_instance_valid(door) and door.has_method("try_unlock"):
		door.try_unlock(gold)

func _on_hero_died(who: Entity = null):
	_heroes_alive -= 1
	if _heroes_alive <= 0:
		await get_tree().create_timer(1.0).timeout
		GameState.end_game(GameState.VictoryType.TROLL_WIN)
		return
	# 当前视角持有者（玩家）死亡 → 视角绑到还活着的队友
	if who and who == _camera_holder:
		_bind_camera_to_living_hero()

func _bind_camera_to_living_hero():
	for e in [hero_entity] + ai_allies:
		if is_instance_valid(e) and not e.health.is_dead:
			_camera_holder = e
			var cam = e.get_node_or_null("Camera2D")
			if cam: cam.make_current()
			return

func _on_troll_died():
	await get_tree().create_timer(1.0).timeout
	GameState.end_game(GameState.VictoryType.HERO_WIN)
