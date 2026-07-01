extends CanvasLayer

@onready var player_fill = $"PlayerHP/Fill"
@onready var player_label = $"PlayerHP/Label"
@onready var boss_fill = $"BossHP/Fill"
@onready var boss_label = $"BossHP/Label"
@onready var boss_panel = $"BossHP"
@onready var result_label = $"ResultLabel"

var _skill_slots: Array = []
var _skill_labels: Array = []
var _skill_overlays: Array = []
var _player_entity: Entity
var _boss_entity: Entity
var _extra_bars: Array = []

func setup(pl: Entity, boss: Entity, allies: Array = [], enemies: Array = []):
	_player_entity = pl
	_boss_entity = boss
	for b in _extra_bars:
		if is_instance_valid(b.bg): b.bg.queue_free()
	_extra_bars = []
	if enemies.size() > 0:
		boss_panel.hide()
		var y = 50
		for e in enemies:
			_extra_bars.append(_make_bar(e, y, Color(0.8, 0.2, 0.2)))
			y += 28
	else:
		var shift = 0
		if allies.size() > 0:
			var y = 50
			for a in allies:
				_extra_bars.append(_make_bar(a, y, Color(0.2, 0.7, 0.5)))
				y += 28
			shift = allies.size() * 28
		boss_panel.position = Vector2(20, 50 + shift)
		boss_panel.show()

func _make_bar(ent: Entity, y_pos: float, col: Color) -> Dictionary:
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6); bg.size = Vector2(300, 22)
	bg.position = Vector2(20, y_pos)
	var fill = ColorRect.new()
	fill.color = col; fill.position = Vector2(10, 0)
	fill.size = Vector2(280, 22)
	bg.add_child(fill)
	var label = Label.new()
	label.horizontal_alignment = 1; label.vertical_alignment = 1
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 13)
	label.size = Vector2(280, 22); label.position = Vector2(10, 0)
	bg.add_child(label)
	add_child(bg)
	var dname = str(ent.name)
	label.text = dname
	return {"fill": fill, "label": label, "entity": ent, "bg": bg, "name_str": dname}

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
	if not _player_entity or not is_instance_valid(_player_entity): return
	player_fill.size.x = 200 * _player_entity.health.hp_ratio()
	player_label.text = _player_entity.name + " (YOU)"
	if _extra_bars.size() > 0:
		for b in _extra_bars:
			var e = b.entity
			if is_instance_valid(e) and e.health:
				b.fill.size.x = 280 * e.health.hp_ratio()
				# label text stays as cached name_str
	elif _boss_entity and is_instance_valid(_boss_entity) and _boss_entity.health:
		boss_fill.size.x = 300 * _boss_entity.health.hp_ratio()
		boss_label.text = _boss_entity.name

func _update_skill_cd():
	var player = _player_entity
	if not player or not is_instance_valid(player) or _skill_slots.size() < 3: return
	var slash = player.get_node_or_null("SlashAbility") as AbilityBase
	var arrow = player.get_node_or_null("ArrowAbility") as AbilityBase
	_skill_slots[0].visible = slash != null or arrow != null
	if slash: _set_overlay(0, slash.is_on_cooldown, _cd_ratio(slash))
	elif arrow: _set_overlay(0, arrow.is_on_cooldown, _cd_ratio(arrow))
	else: _set_overlay(0, false, 0.0)
	var charge = player.get_node_or_null("ChargeAbility") as AbilityBase
	var rush = player.get_node_or_null("RushAbility") as AbilityBase
	var dodge = player.get_node_or_null("DodgeAbility") as AbilityBase
	var ab1 = charge if charge else (rush if rush else dodge)
	_skill_slots[1].visible = ab1 != null
	if ab1 and _skill_labels.size() > 1:
		(_skill_labels[1] as Label).text = "Rush" if rush else ("Dodge" if dodge else "Charge")
	if ab1: _set_overlay(1, ab1.is_on_cooldown, _cd_ratio(ab1))
	else: _set_overlay(1, false, 0.0)
	var ok = player._block_ready
	var r = 0.0
	if not ok:
		r = player._block_cooldown / max(0.001, player._cv("block_cooldown"))
	_set_overlay(2, not ok, r)

func _cd_ratio(ab: AbilityBase) -> float:
	return ab.current_cooldown / max(0.001, ab.cooldown_time) if ab.is_on_cooldown else 0.0

func _set_overlay(idx: int, on_cd: bool, ratio: float):
	if idx >= _skill_overlays.size(): return
	var ov = _skill_overlays[idx] as ColorRect
	ov.size = Vector2(56, int(56 * ratio)) if on_cd else Vector2(56, 0)
