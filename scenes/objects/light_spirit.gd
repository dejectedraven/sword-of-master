class_name LightSpirit
extends Node2D
# 光精灵：开箱获得的固定照明道具（按 E 放置后永久照亮一片区域）

func _ready():
	var light = VisionLight.new()
	light.name = "Light"
	light.configure(GameConfig.light_spirit_radius, GameConfig.light_spirit_energy, false, Color(0.6, 0.9, 1.0))
	add_child(light)

	var orb = Sprite2D.new()
	orb.name = "Orb"
	orb.texture = VisionLight.get_radial_texture()
	orb.modulate = Color(0.6, 0.9, 1.0, 0.9)
	orb.scale = Vector2(0.55, 0.55)
	add_child(orb)

	var p = CPUParticles2D.new()
	p.name = "Sparkles"
	p.amount = 10
	p.lifetime = 1.5
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 20.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(0.7, 0.95, 1.0, 0.9), Color(0.4, 0.7, 1.0, 0.0)])
	p.color_initial_ramp = grad
	add_child(p)

	# 呼吸脉冲
	var tw = create_tween().set_loops()
	tw.tween_property(orb, "scale", Vector2(0.75, 0.75), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(orb, "scale", Vector2(0.5, 0.5), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
