extends Node

enum VictoryType { NONE, HERO_WIN, TROLL_WIN }
enum Faction { HERO, BOSS }

var selected_faction: Faction = Faction.HERO
var selected_character: String = "Warrior"
var is_game_over: bool = false
var victory_type: VictoryType = VictoryType.NONE

func end_game(type: VictoryType):
	is_game_over = true
	victory_type = type

func reset():
	selected_faction = Faction.HERO
	selected_character = "Warrior"
	is_game_over = false
	victory_type = VictoryType.NONE
