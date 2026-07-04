extends CanvasLayer

var chest_ref: Node = null
var _pointer_pos: float = 0.0
var _pointer_dir: float = 1.0
var speed: float = 120.0
var _loop_count: int = 0
var _done: bool = false
var _success: bool = false
var _close_timer: float = 0.0
var _fade_out: bool = false

var _bg: ColorRect
var _title: Label
var _track: ColorRect
var _zone: ColorRect
var _arrow: ColorRect
var _hint: Label
var _result: Label

func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	var vs = get_viewport().get_visible_rect().size
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.6)
	_bg.size = vs
	add_child(_bg)

	_title = Label.new()
	_title.text = "解锁宝箱"
	_title.horizontal_alignment = 1
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_title.position = Vector2(vs.x / 2 - 100, vs.y / 2 - 120)
	_title.size = Vector2(200, 40)
	add_child(_title)

	var cx = vs.x / 2 - 12
	var cy = vs.y / 2
	_track = ColorRect.new()
	_track.color = Color(0.3, 0.3, 0.35)
	_track.size = Vector2(24, 200)
	_track.position = Vector2(cx, cy - 100)
	add_child(_track)

	_zone = ColorRect.new()
	_zone.color = Color(0.2, 0.8, 0.3, 0.6)
	_zone.size = Vector2(24, 60)
	_zone.position = Vector2(cx, cy - 30)
	add_child(_zone)

	_arrow = ColorRect.new()
	_arrow.color = Color(1, 1, 1)
	_arrow.size = Vector2(32, 8)
	_arrow.position = Vector2(cx - 4, cy)
	add_child(_arrow)

	_hint = Label.new()
	_hint.text = "按 F 停指针"
	_hint.horizontal_alignment = 1
	_hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_hint.position = Vector2(vs.x / 2 - 80, cy + 120)
	_hint.size = Vector2(160, 30)
	add_child(_hint)

	_result = Label.new()
	_result.horizontal_alignment = 1
	_result.add_theme_font_size_override("font_size", 20)
	_result.position = Vector2(vs.x / 2 - 100, cy - 140)
	_result.size = Vector2(200, 30)
	_result.hide()
	add_child(_result)

func _process(delta):
	if not _done:
		_pointer_pos += _pointer_dir * speed * delta
		if _pointer_pos > 90:
			_pointer_pos = 90; _pointer_dir = -1; _loop_count += 1
		elif _pointer_pos < -90:
			_pointer_pos = -90; _pointer_dir = 1; _loop_count += 1
		if _loop_count > 6 and _loop_count % 2 == 0:
			speed = min(speed + GameConfig.chest_speed_ramp, GameConfig.chest_max_speed)
		_arrow.position.y = get_viewport().get_visible_rect().size.y / 2 + _pointer_pos
		return
	_close_timer -= delta
	if _close_timer <= 0:
		if chest_ref and chest_ref.has_method("on_minigame_done"):
			chest_ref.on_minigame_done(_success)
		queue_free()

func _input(event):
	if _done: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_done = true
		_success = abs(_pointer_pos) < GameConfig.chest_zone_size
		_result.text = "获得财宝!" if _success else "空的..."
		_result.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if _success else Color(0.6, 0.6, 0.6))
		_result.show()
		_hint.hide()
		_arrow.visible = false
		_close_timer = 0.8

