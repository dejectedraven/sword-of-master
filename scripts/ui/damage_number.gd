class_name DamageNumber
extends Label
# 伤害飘字：世界空间浮动数字，上飘 + 淡出后自毁
# 用法：DamageNumber.spawn(get_tree().current_scene, global_position, 伤害值, 颜色)

static func spawn(parent: Node, world_pos: Vector2, amount: float, color: Color = Color.WHITE):
	if not is_instance_valid(parent): return
	var n = DamageNumber.new()
	n.text = str(int(round(amount)))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.size = Vector2(60, 24)
	n.position = world_pos + Vector2(randf_range(-12, 12) - 30, -56)
	n.z_index = 100
	n.add_theme_font_size_override("font_size", 18)
	n.add_theme_color_override("font_color", color)
	n.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	n.add_theme_constant_override("outline_size", 4)
	parent.add_child(n)
	n._animate()

func _animate():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 42.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(queue_free)
