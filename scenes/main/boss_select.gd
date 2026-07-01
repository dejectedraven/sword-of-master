extends "res://scenes/main/character_select.gd"

func _ready():
	var tex = load("res://assets/sprites/enemies/troll/Troll_Idle.png")
	setup_cards([
	{
	"id": "Troll",
	"name": "巨魔",
	"desc": "毁灭型魔王\n高血量，狂暴冲锋\n技能：单次攻击 + 三连击(RMB) + 狂暴冲锋(SPC)",
	"texture": tex,
	"hframes": 12,
	"idle_start": 0,
	"idle_count": 12,
	"scale": Vector2(0.6, 0.6),
	"pos_y": get_viewport().get_visible_rect().size.y / 2 - 120,
	"on_confirm": func(): _start_game("Troll"),
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
	get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn")
