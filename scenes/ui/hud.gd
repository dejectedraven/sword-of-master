extends CanvasLayer

@onready var player_fill = $"PlayerHP/Fill"
@onready var player_label = $"PlayerHP/Label"
@onready var boss_fill = $"BossHP/Fill"
@onready var boss_label = $"BossHP/Label"
@onready var result_label = $"ResultLabel"

var _skill_slots: Array = []
var _skill_labels: Array = []
var _skill_overlays: Array = []
var _player_entity: Entity

func _ready():
	result_label.hide()
	_create_skill_bar()

func _create_skill_bar():
	var bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)
	var vs = get_viewport().get_visible_rect().size
	bar.position = Vector2(vs.x / 2 - 150, vs.y - 60)
	for data in [["LMB", "Slash"], ["SPC", "Skill"], ["RMB", "Block"]]:
		var inf = _make_slot(data[0], data[1])
		bar.add_child(inf["panel"])
		_skill_slots.append(inf["panel"])
		_skill_labels.append(inf["label"])
		_skill_overlays.append(inf["overlay"])

func _make_slot(key: String, label: String) -> Dictionary:
	var p = Panel.new(); p.custom_minimum_size = Vector2(56, 56)
	var bg = ColorRect.new(); bg.size = Vector2(56, 56); bg.color = Color(0.1, 0.1, 0.15, 0.9)
	p.add_child(bg)
	var kl = Label.new(); kl.text = key; kl.horizontal_alignment = 1; kl.vertical_alignment = 1
	kl.add_theme_font_size_override("font_size", 14); kl.add_theme_color_override("font_color", Color.WHITE)
	kl.size = Vector2(56, 56); p.add_child(kl)
	var ov = ColorRect.new(); ov.size = Vector2(56, 56); ov.color = Color(0, 0, 0, 0.7)
	p.add_child(ov)
	var nl = Label.new(); nl.text = label; nl.horizontal_alignment = 1
	nl.add_theme_font_size_override("font_size", 10)
	nl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	nl.position = Vector2(0, 58); nl.size = Vector2(56, 16); p.add_child(nl)
	return {"panel": p, "label": nl, "overlay": ov}

func _process(_d: float):
	_update_hp()
	_update_skill_cd()
	if GameState.is_game_over:
		result_label.show()
		var is_boss = GameState.selected_faction == GameState.Faction.BOSS
		var hw = GameState.victory_type == GameState.VictoryType.HERO_WIN
		result_label.text = "VICTORY!" if ((is_boss and not hw) or (not is_boss and hw)) else "DEFEATED..."

func _update_hp():
	var scene = get_tree().current_scene
	if not scene: return
	var warrior = scene.get_node_or_null("Warrior") as Entity
	var troll = scene.get_node_or_null("Troll") as Entity
	if warrior:
		player_fill.size.x = 200 * warrior.health.hp_ratio()
		player_label.text = "Warrior (YOU)" if not warrior.is_ai_controlled else "Warrior"
		if not warrior.is_ai_controlled: _player_entity = warrior
	if troll:
		boss_fill.size.x = 300 * troll.health.hp_ratio()
		var is_boss = GameState.selected_faction == GameState.Faction.BOSS
		boss_label.text = "Troll (YOU)" if is_boss else "Troll"
		if is_boss: _player_entity = troll

func _update_skill_cd():
	if not _player_entity or _skill_slots.size() < 3: return
	var slash = _player_entity.get_node_or_null("SlashAbility") as AbilityBase
	_skill_slots[0].visible = slash != null
	if slash: _set_overlay(0, slash.is_on_cooldown, _cd_ratio(slash))
	else: _set_overlay(0, false, 0.0)
	var charge = _player_entity.get_node_or_null("ChargeAbility") as AbilityBase
	var rush = _player_entity.get_node_or_null("RushAbility") as AbilityBase
	var ab1 = charge if charge else rush
	_skill_slots[1].visible = ab1 != null
	if ab1 and _skill_labels.size() > 1:
		(_skill_labels[1] as Label).text = "Rush" if rush else "Charge"
	if ab1: _set_overlay(1, ab1.is_on_cooldown, _cd_ratio(ab1))
	else: _set_overlay(1, false, 0.0)
	var ok = _player_entity._block_ready
	var r = 0.0
	if not ok:
		var w = "Warrior" in _player_entity.name
		var cd = GameConfig.warrior_block_cooldown if w else GameConfig.troll_block_cooldown
		r = _player_entity._block_cooldown / max(0.001, cd)
	_set_overlay(2, not ok, r)

func _cd_ratio(ab: AbilityBase) -> float:
	return ab.current_cooldown / max(0.001, ab.cooldown_time) if ab.is_on_cooldown else 0.0

func _set_overlay(idx: int, on_cd: bool, ratio: float):
	if idx >= _skill_overlays.size(): return
	var ov = _skill_overlays[idx] as ColorRect
	ov.size = Vector2(56, int(56 * ratio)) if on_cd else Vector2(56, 0)
