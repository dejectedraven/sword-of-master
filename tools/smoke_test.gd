extends Node
# ============================================================
#   无头冒烟测试
#   运行：godot --headless --path <项目路径> res://tools/smoke_test.tscn
#   退出码 0 = 全部通过，1 = 有失败
# ============================================================

var _pass: int = 0
var _fail: int = 0

func _ready():
	await _run()

func _check(cond: bool, label: String):
	if cond:
		_pass += 1
		print("[PASS] ", label)
	else:
		_fail += 1
		print("[FAIL] ", label)

func _wait_frames(n: int):
	for i in n:
		await get_tree().physics_frame

func _run():
	print("=== 冒烟测试开始 ===")
	GameState.reset()
	GameState.selected_faction = GameState.Faction.HERO
	GameState.selected_character = "Warrior"

	var scene = load("res://scenes/main/game_scene.tscn").instantiate()
	add_child(scene)
	await _wait_frames(5)

	var player = scene.hero_entity
	var troll = scene.troll_entity
	_check(player != null and is_instance_valid(player), "玩家实体存在")
	_check(troll != null and is_instance_valid(troll), "Boss 实体存在")

	# 出生点必须在地图范围内（0..1280, 0..720）
	if player:
		var p = player.global_position
		_check(p.x > 0 and p.x < 1280 and p.y > 0 and p.y < 720, "玩家出生在地图内 " + str(p))
		_check(player.team == 1, "玩家阵营=英雄")
	if troll:
		var tp = troll.global_position
		_check(tp.x > 0 and tp.x < 1280 and tp.y > 0 and tp.y < 720, "Boss 出生在地图内 " + str(tp))
		_check(troll.team == 2, "Boss 阵营=魔王")

	# 伤害飘字：造成伤害后场景中出现 DamageNumber
	if player:
		player.take_damage(10.0)
		await _wait_frames(2)
		var found = false
		for c in get_children():
			if c is DamageNumber: found = true
		_check(found, "伤害飘字已生成")

	# 黑夜与视野
	_check(scene.get_node_or_null("Night") != null, "夜色 CanvasModulate 存在")
	if player:
		_check(player.get_node_or_null("VisionLight") != null, "玩家有视野光")
	if troll:
		_check(troll.get_node_or_null("VisionLight") == null, "AI 巨魔无视野光（藏黑暗中）")
	if scene.ai_allies.size() > 0:
		_check(scene.ai_allies[0].get_node_or_null("VisionLight") != null, "AI 队友有视野光")
	var p_cam = player.get_node_or_null("Camera2D") if player else null
	_check(p_cam != null and is_equal_approx(p_cam.zoom.x, GameConfig.camera_zoom), "相机缩放生效")

	# 英雄方 3 人：玩家 + 2 AI 队友
	_check(scene.ai_allies.size() == 2, "AI 队友数量 = 2")
	_check(scene._heroes_alive == 3, "英雄方总数 = 3")

	# 宝箱与逃生门存在（用方法判定，避免重名节点 @Chest@2 漏数）
	var chest_count = 0
	var first_chest = null
	var door = null
	for c in scene.get_children():
		if c.has_method("on_minigame_done"):
			chest_count += 1
			if not first_chest: first_chest = c
		elif c.name == "EscapeDoor":
			door = c
	_check(chest_count == GameConfig.chest_count, "宝箱已生成 x" + str(chest_count) + "/" + str(GameConfig.chest_count))
	_check(door != null, "逃生门已生成")
	_check(first_chest != null and first_chest.get_node_or_null("ChestGlow") != null, "宝箱有自发光")

	# 逃生门：金币不足锁定，达到阈值解锁
	if door:
		_check(door.door_state == 0, "逃生门初始锁定")
		GameState.add_gold(100)
		await _wait_frames(2)
		_check(door.door_state == 1, "100 金币后逃生门解锁")

	# 蓄力射：满蓄自动释放后必须回到 IDLE（原 bug 会永久卡 ATTACK）
	var archer = load("res://scenes/entities/archer.tscn").instantiate()
	archer.name = "Archer"
	archer.position = Vector2(640, 360)
	archer.team = 1
	archer.is_ai_controlled = true
	add_child(archer)
	await _wait_frames(3)
	var ab = archer.get_node_or_null("ChargeShotAbility")
	_check(ab != null, "弓箭手有蓄力射技能")
	if ab:
		ab.start_charge()
		ab._charge_time = GameConfig.archer_charge_max_time
		await get_tree().create_timer(1.0).timeout
		_check(archer.state == Entity.State.IDLE, "满蓄释放后回到 IDLE（原 bug 卡 ATTACK）")
		_check(ab.is_on_cooldown, "蓄力射进入冷却")

	# 战士死亡倒地（无死亡帧素材，用旋转+变暗表现）
	if player and player.anim_tree:
		player.health.take_damage(99999.0)
		await get_tree().create_timer(0.7).timeout
		_check(not player.anim_tree.active, "战士死亡后 AnimationTree 停用")
		_check(absf(player.sprite.rotation_degrees) > 45.0, "战士死亡倒地动画生效")
		var cam = get_viewport().get_camera_2d()
		_check(cam != null and cam.get_parent() != player, "玩家死亡后视角绑到队友")

	# 结算按钮：游戏结束后显示
	GameState.end_game(GameState.VictoryType.HERO_WIN)
	await _wait_frames(3)
	var hud = scene.get_node_or_null("HUD")
	var end_btns = hud.get_node_or_null("EndButtons") if hud else null
	_check(end_btns != null and end_btns.visible, "结算按钮已显示")

	# Boss 模式：3 个 AI 英雄
	scene.queue_free()
	await _wait_frames(2)
	GameState.reset()
	GameState.selected_faction = GameState.Faction.BOSS
	GameState.selected_character = "Troll"
	var boss_scene = load("res://scenes/main/game_scene.tscn").instantiate()
	add_child(boss_scene)
	await _wait_frames(5)
	_check(boss_scene.ai_enemies.size() == 3, "Boss 模式 AI 英雄 = 3")
	_check(boss_scene.troll_entity.get_node_or_null("VisionLight") != null, "Boss 模式玩家巨魔有视野光")

	print("=== 冒烟测试结束: ", _pass, " 通过, ", _fail, " 失败 ===")
	get_tree().quit(0 if _fail == 0 else 1)
