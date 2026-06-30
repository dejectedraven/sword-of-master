extends CanvasLayer

func _ready():
	GameState.reset()
	var tavern = get_node_or_null("TavernBtn")
	var castle = get_node_or_null("CastleBtn")
	if tavern: tavern.pressed.connect(func():
		GameState.selected_faction = GameState.Faction.HERO
		get_tree().change_scene_to_file("res://scenes/main/hero_select.tscn")
	)
	if castle: castle.pressed.connect(func():
		GameState.selected_faction = GameState.Faction.BOSS
		get_tree().change_scene_to_file("res://scenes/main/boss_select.tscn")
	)
