extends Node2D
# 临时工具：验证 gl_compatibility 下 2D 光照 + 阴影是否可用

func _ready():
	# 背景（不透明，否则看不到光照）
	var bg = ColorRect.new()
	bg.color = Color(0.35, 0.45, 0.3)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	# 夜色
	var cm = CanvasModulate.new()
	cm.color = Color(0.16, 0.18, 0.30)
	add_child(cm)

	# 点光源（径向渐变程序生成）
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var light = PointLight2D.new()
	light.texture = tex
	light.energy = 1.2
	light.texture_scale = 2.0
	light.shadow_enabled = true
	light.position = Vector2(400, 360)
	add_child(light)

	# 遮挡物（模拟树：挡光）
	var occ = LightOccluder2D.new()
	var poly = OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-40, -80), Vector2(40, -80), Vector2(40, 80), Vector2(-40, 80)])
	occ.occluder = poly
	occ.position = Vector2(500, 360)
	add_child(occ)

	# 遮挡物可见体
	var spr = ColorRect.new()
	spr.color = Color(0.15, 0.45, 0.15)
	spr.size = Vector2(80, 160)
	spr.position = Vector2(460, 280)
	add_child(spr)

	# 第二个光源在遮挡物另一侧，检验阴影方向
	var light2 = PointLight2D.new()
	light2.texture = tex
	light2.energy = 1.0
	light2.texture_scale = 1.5
	light2.shadow_enabled = true
	light2.position = Vector2(900, 360)
	add_child(light2)

	# 相机 zoom 2.0
	var cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	cam.zoom = Vector2(2, 2)
	cam.make_current()
	add_child(cam)

	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("C:/Users/87344/AppData/Local/Temp/opencode/night_test.png")
	print("night test shot saved")
	get_tree().quit()
