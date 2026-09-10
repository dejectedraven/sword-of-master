class_name VisionLight
extends PointLight2D
# 视野光圈：程序生成径向渐变纹理，无需素材
# 用法：var l = VisionLight.new(); l.configure(半径px, 强度, 是否投影); add_child(l)

static var _cached_tex: GradientTexture2D = null

static func get_radial_texture() -> GradientTexture2D:
	if _cached_tex: return _cached_tex
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.55),
		Color(1, 1, 1, 0.0),
	])
	_cached_tex = GradientTexture2D.new()
	_cached_tex.gradient = grad
	_cached_tex.fill = GradientTexture2D.FILL_RADIAL
	_cached_tex.fill_from = Vector2(0.5, 0.5)
	_cached_tex.fill_to = Vector2(1.0, 0.5)
	_cached_tex.width = 256
	_cached_tex.height = 256
	return _cached_tex

func configure(radius: float, energy: float, casts_shadows: bool = true, light_color: Color = Color.WHITE):
	texture = get_radial_texture()
	texture_scale = max(radius, 1.0) / 128.0  # 256px 纹理 → 基准半径 128px
	self.energy = energy
	self.color = light_color
	shadow_enabled = casts_shadows
