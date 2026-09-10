# 更新日志

## [0.7.0] — 2026-09-10

### ✨ 新增
- **黑夜与视野**：CanvasModulate 夜色 + 角色视野光圈（程序生成径向渐变，无需素材）+ 相机缩放 2.0（GameConfig 可调）
- **视线遮挡（LOS）**：树/岩石/灌木/树桩障碍物 + 凸多边形 LightOccluder2D 挡视线；树=挡人挡视线、灌木=可穿行只挡视线（潜行神器）
- **Y 排序**：角色可走到树后/树前；边界树墙视觉化地图边界
- **巨魔潜行 AI**：巡逻 → 探测(320px)/听声(420px) → 追击 → 搜索最后已知位置 → 回归巡逻（不再无脑直线追）
- **噪声系统**：开箱/闪现/放置光精灵会暴露位置（`GameState.noise_emitted`）
- **AI 队友约束**：离敌人超过 380px 时回到玩家身边，不单独深入黑暗送死
- **道具系统**：宝箱 2→5 个，每箱 50 金币 + 随机道具
  - **光精灵**（E 放置）：固定在放置点永久照明一片区域
  - **闪现**（Q 消耗）：180px 位移 + 0.2s 无敌，撞墙截停
- **HUD 道具栏**：显示 Q/E 道具数量（数量为 0 隐藏）
- **宝箱自发光**：黑暗中可辨认轮廓；伤害飘字/提示/传送门设为 unshaded

### 🔧 平衡
- 巨魔伤害下调：平砍 22→16 / 连击 12→8 / 狂暴冲锋 45→32
- 弓箭手 HP 60→80

### 🛠 工具
- 冒烟测试扩展至 40 项断言（夜色/视野/障碍/道具/AI 状态）
- 工作流修正：新增 `class_name` 脚本需运行 `godot --editor --quit-after 900` 注册全局类

## [0.6.0] — 2026-09-10

### ✨ 新增
- **金币系统**：`GameState.player_gold` + `add_gold()` + `gold_changed` 信号；宝箱成功给 50 金币 + 30% 回血
- **逃生门**：集满 100 金币解锁（红色锁定 → 绿色脉冲 + 粒子），玩家进入触发 `ESCAPE_WIN` 第三种结局
- **伤害飘字**：`scripts/ui/damage_number.gd`，普通白 / 格挡蓝 / 大伤害橙，上飘淡出
- **3 英雄阵容**：英雄模式玩家 + 2 AI 队友（先保证另一职业再随机补位）；Boss 模式 1v3 AI 英雄
- **死亡视角切换**：玩家阵亡后相机自动绑到存活队友（`_camera_holder` + `_bind_camera_to_living_hero()`）
- **结算界面**：游戏结束显示「再来一局」（保留阵营角色）/「返回标题」按钮
- **阵营系统**：`Entity.team`（英雄 1 / 魔王 2），4 处近战 + 3 处箭矢命中过滤，友军穿透免伤
- **地宫生成工具**：`tools/setup_dungeon.gd`（@tool EditorScript），一键生成 TileSet + 80×45 TileMap（6 房间 + 走廊）
- **冒烟测试**：`tools/smoke_test.tscn`，无头运行 21 项断言（`godot --headless --path <项目> res://tools/smoke_test.tscn`）
- **联机方案文档**：`docs/MULTIPLAYER_PLAN.md`（1v3 ENet host-authoritative）

### 🔧 修复
- **蓄力射满蓄吞箭 + 永久卡 ATTACK**：满蓄自动释放改为回调 `entity._do_charge_release(data)`，正常射箭并复位
- **AI 蓄力射瞄鼠标**：`charge_shot_ability` 仅对玩家 `_face_mouse()`；AI 等待自动释放
- **逃生门锁定不挡人**：`LockedBody.collision_layer=2`，碰撞形状对齐视觉，`try_unlock` 加重复 guard
- **普攻无 CD 检查**：CD 内不再空放攻击动画
- **攻击中残留移动**：ATTACK 状态清空 `move_direction`
- **AI 战士格挡死锁**：AI 格挡 0.5s 后自动解除（AI 不走 `_read_block_input`）
- **HUD 金币条与 Boss 血条重叠**：金币条移到右上角
- **相机越界**：相机限制在地图 0..1280×0..720 内
- **箭矢 Tween 报错**：Tween 改绑箭节点，命中释放时自动停止（不再 lambda 捕获已释放对象）
- **开箱保护**：小游戏期间锁定玩家输入；死亡后不可开箱、不会被治疗
- **宝箱治疗比例不一致**：统一读 `GameConfig.chest_heal_ratio`（30%）
- **战士死亡表现**：精灵表无死亡帧，改用通用倒地（旋转 + 变暗）；巨魔继续用自带死亡帧
- **地图坐标错乱**：恢复 1280×720 白板地图（灰底 + 四边隐形墙 + 相机限制）
- `chest.tscn` 空 UID 警告

### 💥 移除
- 死代码清理：`arrow.tscn` / `arrow_bullet.gd` / `dodge_ability.gd` / `entity_stats.gd` + `resources/stats/`

## [0.5.0] — 2026-07-05

### ✨ 新增
- **Archer 技能重做**：RMB 蓄力射击（charge_shot_ability.gd，按住蓄力 0→1.5s，伤害/箭速随蓄力比增长，CD 3s）+ SPC 三连射（triple_shot_ability.gd，±15° 散布 3 箭，0.7x 伤害/箭，CD 4s）
- **蓄力射击机制**：按住 RMB 蓄力时角色面朝鼠标方向无法移动，松开释放；满蓄力自动射出
- **三连射机制**：瞬间射出 3 箭（0.1s 间隔），内联生成，适用于近距离爆发
- **Archer AI 适配**：`ai_archer.gd` 重写：中距离→蓄力射、近距离→三连射、远程→普攻、低血撤退
- **GameConfig 新参数**：`archer_charge_cooldown/max_time/damage_bonus/speed_bonus` + `archer_triple_cooldown/damage_mult/spread_deg/count` + `archer_ai_charge_range/triple_range`

### 💥 移除
- Archer 移除翻滚（DodgeAbility）和格挡（Block）
- HUD 技能栏 "Skill" 改为 "Triple"，"Block" 改为 "Charge"（Archer 时）

## [0.4.0] — 2026-07-04

### ✨ 新增
- **宝箱交互系统**：场景随机生成宝箱，按 F 启动节奏对位小游戏，指针摆动时按 F 停在绿色区域即可成功
- **开箱奖励**：成功回血 30% 最大 HP，失败则空箱；宝箱状态机 CLOSED→MINIGAME→OPENING→OPENED
- **节奏对位小游戏**：CanvasLayer 覆盖层，指针 90px 范围内摆动，6 回合后每 2 回合加速，0.8s 结果展示
- **Bonsaiheldin 宝箱素材**：CC-BY 4.0，32×32 四帧动画（关闭→开启暗箱→有宝→空箱）
- **每角色开箱速度**：GameConfig 新增 `warrior_chest_speed=120` / `archer_chest_speed=160` / `troll_chest_speed=80`（Boss 不可开箱）
- **小游戏参数统一调参**：`chest_speed` / `chest_speed_ramp` / `chest_max_speed` / `chest_zone_size` / `chest_count` / `chest_heal_ratio` 全部接入 GameConfig

### 🔧 修复
- 死亡后角色仍可行动：`entity.gd` 攻击 coroutine 每个 `await` 后加 `if health.is_dead: return`
- AI 单位死亡动画不播放：`ai_troll/archer/warrior.gd` 每个 `await` 后加 `if entity.health.is_dead: _attacking = false; return`
- 修复 `chest.png` 错误截取自 Props.png（实为冰/水晶块，非宝箱）

### 💥 移除
- Archer 移除翻滚（DodgeAbility）和格挡（Block）技能

## [0.3.0] — 2026-06-30

### ✨ 新增
- **弓箭手角色**：全新远程英雄，6 帧待机/4 帧跑步/8 帧射击动画（Blue Archer）
- **AI 队友/敌方系统**：英雄模式下携带 1 随机 AI 队友共战巨魔；Boss 模式下单挑 2 随机 AI 英雄
- **远程射击**：LMB 射箭，箭矢飞行 600px/s，Tween 驱动 + Raycast 碰撞检测
- **翻滚技能**：SPC 向前翻滚 120px，0.12s 无敌帧，CD 5s
- **弓箭手 AI**：保持距离（200px）→ 350px 射击 → 近身翻滚逃跑 → 低血撤退
- **动态角色系统**：`game_scene.gd` 改为根据 `selected_character` 动态实例化英雄场景，任意新英雄只需加 .tscn 和 AI 即可接入
- **HUD 自动适配**：技能栏动态检测 Arrow/Slash/Charge/Dodge/RushAbility，按角色显示对应标签
- **通用 _cv() 模式**：entity.gd 用 `游戏配置.get(前缀_key)` 统一查参，新增角色只需加前缀
- **新增角色指南**：`docs/ADDING_CHARACTER.md` 记录英雄/Boss 新增全流程与文件清单
- **巨魔技能重做**：LMB 改为单次快速攻击（低后摇、无喘息）；RMB 改为三连击（ComboAbility，三段伤害 + 后摇 + 喘息 + 禁步）

### 🔧 修复
- 箭矢子弹改为全部在 arrow_ability.gd 内联生成（放弃独立 .tscn 因节点 `_process` 不触发）
- DodgeAbility 撞墙预防（raycast 检测墙壁）
- Boss 模式敌人英雄固定为上次选的英雄（`last_selected_hero`），不再硬编码为 Warrior
- `GameState.reset()` 不再清空 `last_selected_hero`，跨局保留
- 巨魔 AI 脚本漏挂修复（`_load_ai()` 缺少 Troll 条目导致用错 AI）
- Boss 模式血条改为独立分条显示每个 AI 英雄 HP

## [0.2.0] — 2026-06-29

### ✨ 新增
- **卡片式角色选择**：英雄和魔王选角界面改为卡片式，支持滚轮左右切换，含待机动画预览和角色特性描述，末尾有"敬请期待"占位卡
- **死亡动画**：巨魔 HP 归零后播放 `Troll_Dead.png` 死亡帧（10 帧），最后定格
- **力竭动画**：巨魔狂暴冲锋结束后，播放 `Troll_Recovery.png` 力竭帧（10 帧）循环 2 秒
- **震屏效果**：巨魔使用狂暴冲锋时全屏抖动（可调强度 `troll_rush_shake`）
- **阵营选择**：标题画面分为"进入酒馆"和"进入魔王城"两级 UI 流程
- **技能键位改为空格**：原 Q 键改为 Space 触发技能

### 🔧 修复
- 全部 `.gd` 文件统一为 Tab 缩进，消除混用导致的编译错误
- Camera2D.current 改为 `make_current()`
- TSCN 颜色值补全 4 参数（含 Alpha）
- Boss 血条每帧重拿引用防丢失
- 受伤闪烁统一用 `modulate`，不再和 `self_modulate` 冲突
- AI 协程重入修复：`await` 调攻击方法确保顺序执行
- 攻击动画播放后强制 `play_anim("idle")` 切回
- 体力初期化：`current_hp = max_hp` 确保开局满血
- 格挡碎盾机制：挡一次 80% 减伤 → 3 秒冷却
- 攻击后摇恢复期禁止重复攻击

### 📊 参数中心
- `scripts/state/game_config.gd` 统一管理所有角色/技能/AI 数值，含中文注释

---

## [0.1.0] — 2026-06-28

### 🏗 基础
- Godot 4.6 项目初始化，基于 Tiny Swords 素材包
- 玩家战士：WASD 移动、左键横斩、右键格挡、空格冲锋
- AI 巨魔：追击、平砍、狂暴冲锋、低血撤退
- 1280×720 地图带围墙壁碰撞
- HUD：双血条 + 技能 CD 遮罩图标
- 阵营选择：英雄 vs Boss
- 胜负判定：击杀对方或全部英雄死亡
