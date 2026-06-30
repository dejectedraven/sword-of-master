extends CanvasLayer

var _cards: Array = []
var _index: int = 0
var _sprite: Sprite2D
var _name_label: Label
var _desc_label: Label
var _page_label: Label
var _frame_timer: float = 0.0

func _ready():
	_build_ui()
	_show_card(0)

func setup_cards(cards: Array):
	_cards = cards

func _build_ui():
	var vs = get_viewport().get_visible_rect().size
	var cx = vs.x / 2; var cy = vs.y / 2
	var bg = ColorRect.new(); bg.size = vs; bg.color = Color(0, 0, 0, 0.7)
	add_child(bg)
	var left = _make_arrow("<", -1)
	left.position = Vector2(cx - 160, cy); add_child(left)
	var right = _make_arrow(">", 1)
	right.position = Vector2(cx + 120, cy); add_child(right)
	_sprite = Sprite2D.new()
	_sprite.position = Vector2(cx - 20, cy - 40)
	_sprite.centered = true
	add_child(_sprite)
	_name_label = _mk_label("", 24, Color.WHITE)
	_name_label.position = Vector2(cx - 100, cy + 60)
	_name_label.size = Vector2(200, 30)
	add_child(_name_label)
	_desc_label = _mk_label("", 14, Color(0.7, 0.7, 0.7))
	_desc_label.position = Vector2(cx - 140, cy + 90)
	_desc_label.size = Vector2(280, 50)
	_desc_label.horizontal_alignment = 1
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_desc_label)
	_page_label = _mk_label("", 12, Color(0.5, 0.5, 0.5))
	_page_label.position = Vector2(cx - 100, cy + 145)
	_page_label.size = Vector2(200, 20)
	add_child(_page_label)
	var confirm = Button.new()
	confirm.text = "选择"; confirm.position = Vector2(cx - 50, cy + 170)
	confirm.size = Vector2(100, 36)
	confirm.pressed.connect(_on_confirm)
	add_child(confirm)
	var back = Button.new()
	back.text = "返回"; back.position = Vector2(cx - 50, cy + 215)
	back.size = Vector2(100, 36)
	back.pressed.connect(_on_back)
	add_child(back)

func _mk_label(txt: String, fs: int, clr: Color) -> Label:
	var l = Label.new(); l.text = txt; l.horizontal_alignment = 1
	l.vertical_alignment = 1; l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", clr)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _make_arrow(text: String, dir: int) -> Button:
	var b = Button.new(); b.text = text; b.size = Vector2(36, 60)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func(): _flip(dir))
	return b

func _flip(dir: int):
	_index = wrapi(_index + dir, 0, _cards.size())
	_show_card(_index)

func _show_card(idx: int):
	if idx >= _cards.size(): return
	var card = _cards[idx]
	_name_label.text = card["name"]
	_desc_label.text = card["desc"]
	_page_label.text = str(idx + 1) + " / " + str(_cards.size())
	if card.has("locked") and card["locked"]:
		_sprite.texture = null
		_sprite.hframes = 1
		_sprite.region_enabled = false
	else:
		_sprite.texture = card["texture"]
		_sprite.hframes = card.get("hframes", 6)
		_sprite.vframes = card.get("vframes", 1)
		_sprite.frame = 0
		if card.has("region_rect"):
			_sprite.region_enabled = true
			_sprite.region_rect = card["region_rect"]
		_sprite.scale = card.get("scale", Vector2.ONE)
		_sprite.position.x = card.get("pos_x", get_viewport().get_visible_rect().size.x / 2 - 20)
		_sprite.position.y = card.get("pos_y", get_viewport().get_visible_rect().size.y / 2 - 40)

func _process(delta: float):
	if _cards.is_empty(): return
	var card = _cards[_index]
	if card.has("locked") and card["locked"]: return
	_frame_timer += delta
	if _frame_timer >= 0.1:
		_frame_timer = 0.0
		var start = card.get("idle_start", 0)
		var count = card.get("idle_count", 6)
		var f = _sprite.frame
		if f < start or f >= start + count: f = start
		else: f += 1
		if f >= start + count: f = start
		_sprite.frame = f

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: _flip(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _flip(1)

func _on_confirm():
	var card = _cards[_index]
	if card.has("locked") and card["locked"]: return
	GameState.selected_character = card["id"]
	card["on_confirm"].call()

func _on_back():
	var card = _cards[_index]
	if card.has("on_back"): card["on_back"].call()
