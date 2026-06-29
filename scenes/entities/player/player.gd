# 继承2D角色物理节点（自带移动、碰撞、重力功能）
extends CharacterBody2D

# 状态枚举
enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}

# 给导出变量分组，在编辑器里显示为 Stats 分类
@export_category("Stats")
# 导出变量：角色移动速度，可在编辑器直接修改
@export var speed: int = 400
@export var attack_speed: float = 0.6

var state: State = State.IDLE

# 存储角色移动方向（x:左右，y:上下），初始值为静止(0,0)
var move_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]


func _ready() -> void:
	animation_tree.set_active(true)
	
# 未处理输入回调函数：用于捕获未被UI等控件拦截的鼠标/键盘输入
# 常用于全局输入、点击攻击等逻辑
func _unhandled_input(event: InputEvent) -> void:
	# 条件判断：
	# 1. event is InputEventMouseButton：确保是鼠标按键事件
	# 2. event.button_index == MOUSE_BUTTON_LEFT：确保是鼠标左键
	# 3. event.pressed：确保是按下动作（而非松开）
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 触发攻击函数
		attack()
		
		
# 角色攻击函数：处理攻击状态、方向、动画、状态回退
func attack() -> void:
	# 1. 防重复攻击：如果已经在攻击状态，直接返回，避免重复触发
	if state == State.ATTACK:
		return
	# 2. 切换为攻击状态
	state = State.ATTACK

	# 3. 计算攻击方向（基于鼠标位置），同步到BlendSpace2D实现8方向攻击动画
	# 获取鼠标在世界空间的全局坐标
	var mouse_pos: Vector2 = get_global_mouse_position()
	# 计算从角色到鼠标的方向向量，并归一化（保证方向向量长度为1）
	var attack_dir: Vector2 = (mouse_pos - global_position).normalized()

	# 4. 自动翻转精灵朝向：仅当攻击方向水平分量更大（左右方向）时翻转
	# attack_dir.x < 0：鼠标在角色左侧 → 翻转面朝左
	# abs(attack_dir.x) >= abs(attack_dir.y)：水平分量绝对值≥垂直分量 → 判定为左右方向
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)

	# 5. 将攻击方向同步到AnimationTree的BlendSpace2D，驱动对应方向的攻击动画
	# 参数路径需与AnimationTree内的节点结构完全一致
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)

	# 6. 更新动画状态，触发攻击动画播放
	update_animation()

	# 7. 等待攻击动画时长（attack_speed），结束后自动切回待机状态
	# 创建一个时长为attack_speed的计时器，等待超时信号
	await get_tree().create_timer(attack_speed).timeout
	# 攻击结束，切回IDLE状态
	state = State.IDLE

# 物理帧更新函数（固定60次/秒，专门处理移动/物理）
func _physics_process(_delta: float) -> void:
	# 调用自定义的移动逻辑函数
	if not state == State.ATTACK:
		movement_loop()

# 角色移动循环函数，在_physics_process中调用
func movement_loop() -> void:
	# 1. 计算水平移动方向：右=1，左=-1，无输入=0
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	# 2. 计算垂直移动方向：下=1，上=-1，无输入=0
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	
	# 3. 归一化方向向量（防止斜向移动速度过快），乘以speed得到最终运动速度
	var motion: Vector2 = move_direction.normalized() * speed
	
	# 4. 设置角色速度（CharacterBody2D的标准方法）
	set_velocity(motion)
	# 5. 执行移动（带碰撞检测的滑动移动，2D角色核心移动方法）
	move_and_slide()
	
	# Sprite 翻转逻辑（仅在 idle/run 状态生效，攻击等状态不翻转）
	# 作用：根据角色水平移动方向，自动翻转精灵的左右朝向
	if state == State.IDLE or State.RUN:
		# 向左移动：move_direction.x 为负数，阈值-0.01避免浮点精度问题
		if move_direction.x < -0.01:
			# 水平翻转Sprite，让角色面朝左
			$Sprite2D.flip_h = true
		# 向右移动：move_direction.x 为正数，阈值0.01避免浮点精度问题
		elif move_direction.x > 0.01:
			# 取消水平翻转，让角色面朝右
			$Sprite2D.flip_h = false

	# 6. 状态切换逻辑：从IDLE（待机）→ RUN（奔跑）
	# 条件：有移动输入 且 当前状态是待机
	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.RUN  # 切换为奔跑状态
		update_animation() # 更新动画（播放奔跑动画）
	
	# 7. 状态切换逻辑：从RUN（奔跑）→ IDLE（待机）
	# 条件：无移动输入 且 当前状态是奔跑
	elif motion == Vector2.ZERO and state == State.RUN:
		state = State.IDLE  # 切换为待机状态
		update_animation() # 更新动画（播放待机动画）
		
		
# 根据角色当前状态，更新对应动画的函数
func update_animation() -> void:
	# match 是 GDScript 的多分支匹配语句，等价于其他语言的 switch-case
	# 这里根据 state（角色状态）执行不同的动画逻辑
	match state:
		# 状态1：待机（IDLE）
		State.IDLE:
			# 通知动画状态机，切换到 "idle" 动画状态
			# travel() 会自动处理状态间的平滑过渡（按你在AnimationTree里设置的过渡时间）
			animation_playback.travel("idle")
		
		# 状态2：奔跑（RUN）
		State.RUN:
			# 通知动画状态机，切换到 "run" 动画状态
			animation_playback.travel("run")
		
		# 状态3：攻击（ATTACK）
		State.ATTACK:
			# 通知动画状态机，切换到 "attack" 动画状态
			animation_playback.travel("attack")
