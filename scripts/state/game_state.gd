extends Node

enum VictoryType { NONE, HERO_WIN, TROLL_WIN, ESCAPE_WIN }
enum Faction { HERO, BOSS }

var selected_faction: Faction = Faction.HERO
var selected_character: String = "Warrior"
var last_selected_hero: String = "Warrior"
var is_game_over: bool = false
var victory_type: VictoryType = VictoryType.NONE
var player_gold: int = 0

signal gold_changed(amount: int)
signal noise_emitted(position: Vector2, radius: float)

func add_gold(amount: int):
	player_gold += amount
	gold_changed.emit(player_gold)

# 噪声事件：开箱/闪现/放置光精灵等会暴露位置，巨魔 AI 听声辨位
func emit_noise(pos: Vector2, radius: float = 0.0):
	noise_emitted.emit(pos, radius)

func end_game(type: VictoryType):
	is_game_over = true
	victory_type = type

func reset():
	selected_faction = Faction.HERO
	selected_character = "Warrior"
	is_game_over = false
	victory_type = VictoryType.NONE
	player_gold = 0
