class_name Obstacle
extends Node2D
# 通用障碍物：树 / 岩石 / 灌木 / 树桩
# - blocks_movement=true → StaticBody2D(layer2) 挡移动
# - blocks_vision=true  → LightOccluder2D 挡夜色视线（可躲藏）
# - 所有尺寸按贴图高度比例自动计算，换贴图不用改参数
# - 多帧贴图（摇摆动画）自动循环

@export var texture: Texture2D
@export var frames: int = 1               # 横向帧数（1=静态）
@export var base_ratio: float = 0.9       # 底部（树干/脚）在贴图高度中的比例
@export var blocks_movement: bool = true
@export var blocks_vision: bool = true
@export var collision_size: Vector2 = Vector2(32, 20)  # 底部碰撞盒（像素）
@export var collision_offset_y: float = -10.0
@export var occluder_points: PackedVector2Array = PackedVector2Array()  # 遮挡多边形（贴图比例坐标 0~1，需凸多边形）
@export var sway_interval: float = 0.15   # 摇摆帧切换间隔（秒）
@export var fade_when_behind: bool = false # 玩家躲到后面时淡出（避免遮挡角色）

var _sprite: Sprite2D
var _timer: float = 0.0

func _ready():
	if not texture: return
	var h = float(texture.get_height())
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = texture
	_sprite.hframes = frames
	_sprite.centered = true
	_sprite.frame = randi() % frames if frames > 1 else 0
	_sprite.offset = Vector2(0, (0.5 - base_ratio) * h)  # 让底部落在节点原点
	add_child(_sprite)

	if blocks_movement:
		var body = StaticBody2D.new()
		body.name = "Body"
		body.collision_layer = 2
		body.collision_mask = 0
		var col = CollisionShape2D.new()
		col.name = "Shape"
		var shape = RectangleShape2D.new()
		shape.size = collision_size
		col.shape = shape
		col.position = Vector2(0, collision_offset_y)
		body.add_child(col)
		add_child(body)

	if blocks_vision and occluder_points.size() >= 3:
		var fw = float(texture.get_width()) / float(frames)
		var base_pt = Vector2(fw / 2.0, h * base_ratio)
		var pts = PackedVector2Array()
		for p in occluder_points:
			pts.append(Vector2(p.x * fw, p.y * h) - base_pt)
		var occ = LightOccluder2D.new()
		occ.name = "Occluder"
		var poly = OccluderPolygon2D.new()
		poly.polygon = pts
		occ.occluder = poly
		add_child(occ)

func _process(delta):
	if not _sprite: return
	if frames > 1:
		_timer += delta
		if _timer >= sway_interval:
			_timer = 0.0
			_sprite.frame = (_sprite.frame + 1) % frames
	# 玩家躲到障碍物后面时淡出，避免树冠/灌木盖住角色
	if fade_when_behind:
		var target_a = 1.0
		var cam = get_viewport().get_camera_2d()
		var focus = cam.get_parent() if cam else null
		if focus is Entity:
			var canopy = global_position + Vector2(0, _sprite.offset.y)
			var radius = float(_sprite.texture.get_height()) * 0.5
			if focus.global_position.distance_to(canopy) < radius and focus.global_position.y < global_position.y:
				target_a = 0.35
		_sprite.modulate.a = lerp(_sprite.modulate.a, target_a, delta * 8.0)
