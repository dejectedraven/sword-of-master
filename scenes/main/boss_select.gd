extends CanvasLayer

func _ready():
    _bind("TrollBtn", "Troll", "巨魔", "高血量，狂暴冲锋")
    var back = get_node_or_null("BackBtn")
    if back: back.pressed.connect(func():
        get_tree().change_scene_to_file("res://scenes/main/title_screen.tscn")
    )

func _bind(name: String, char: String, label: String, desc: String):
    var btn = get_node_or_null(name)
    if not btn: return
    var lbl = btn.get_node_or_null("Label") as Label
    var dsc = btn.get_node_or_null("Desc") as Label
    if lbl: lbl.text = label
    if dsc: dsc.text = desc
    btn.pressed.connect(func():
        GameState.selected_character = char
        get_tree().change_scene_to_file("res://scenes/main/game_scene.tscn")
    )
