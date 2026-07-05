extends "res://scenes/main/character_select.gd"

func _ready():
	setup_cards([
	{
	"id": "Warrior",
	"name": "战士",
	"desc": "均衡型英雄\n攻防兼备，冲锋陷阵\n技能：横斩 + 冲锋 + 格挡",
	"texture": load("res://assets/sprites/player/Warrior_Blue.png"),
	"hframes": 6,
	"vframes": 1,
	"region_rect": Rect2(0, 0, 1152, 192),
	"idle_start": 0,
	"idle_count": 6,
	"scale": Vector2(1.5, 1.5),
	"pos_y": get_viewport().get_visible_rect().size.y / 2 - 100,
	"on_confirm": func(): _start_game("Warrior"),
	"on_back": func(): get_tree().change_scene_to_file("res://scenes/main/title_screen.tscn"),
	},
	{
	"id": "Archer",
	"name": "弓箭手",
	"desc": "远程输出型英雄\n放风筝，精准射击\n技能：射击 + 翻滚 + 格挡",
	"texture": load("res://assets/sprites/player/Archer_Idle.png"),
	"hframes": 6,
	"vframes": 1,
	"region_rect": Rect2(0, 0, 1152, 192),
	"idle_start": 0,
	"idle_count": 6,
	"scale": Vector2(1.5, 1.5),
	"pos_y": get_viewport().get_visible_rect().size.y / 2 - 100,
	"on_confirm": func(): _start_game("Archer"),
	"on_back": func(): get_tree().change_scene_to_file("res://scenes/main/title_screen.tscn"),
	},
	{
	"id": "",
	"name": "???",
	"desc": "敬请期待",
	"locked": true,
	"on_confirm": func(): pass,
	"on_back": func(): get_tree().change_scene_to_file("res://scenes/main/title_screen.tscn"),
	},
	])
	super._ready()

func _start_game(char: String):
	GameState.selected_character = char
	GameState.last_selected_hero = char
	get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn")
