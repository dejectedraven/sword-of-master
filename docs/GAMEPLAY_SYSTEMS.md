# Sword of Master — 黑夜潜行系统说明

> 本文档说明 v0.7.0 引入的黑夜 / 视野 / 障碍物 / 道具系统，以及全部可调参数。

## 1. 黑夜与视野

### 渲染结构
| 节点 | 作用 |
|------|------|
| `CanvasModulate`（Night） | 全屏压暗（`GameConfig.night_color`），是"未照亮区域"的底色 |
| `VisionLight`（PointLight2D） | 角色视野光圈，程序生成径向渐变纹理（`scripts/components/vision_light.gd`），无需美术素材 |
| `SelfLight`（PointLight2D） | 角色自照小光，**不投影**，保证角色站在树影/树冠下也可见 |
| `Camera2D.zoom` | 相机比例（`GameConfig.camera_zoom`，默认 1.0） |

### 谁有光
- **英雄（玩家 + AI 队友）**：`VisionLight`（半径按职业）+ `SelfLight`
- **玩家操控的巨魔（Boss 模式）**：同上
- **AI 巨魔**：**没有任何光** → 藏在黑暗中，进入玩家光圈才现身

### 视野半径（按职业，`_cv("vision_radius")` 路由）
```gdscript
var warrior_vision_radius := 220.0   # 战士
var archer_vision_radius  := 260.0   # 弓箭手
var troll_vision_radius   := 320.0   # 巨魔（玩家操控）
```

## 2. 障碍物与视线遮挡（LOS）

`scripts/objects/obstacle.gd` 通用组件，类型在 `game_scene.gd` 的 `OBSTACLE_LAYOUT` 定义：

| 类型 | 挡移动 | 挡视线 | 说明 |
|------|--------|--------|------|
| 树 tree | ✅ 树干小碰撞 | ✅ 三角形遮挡（贴树形） | 可躲藏；玩家躲后时树冠淡出至 35% |
| 岩石 rock | ✅ | ✅ 五边形 | 掩体 |
| 灌木 bush | ❌ 可穿行 | ✅ 五边形 | 潜行神器：能穿过去但断视线 |
| 树桩 stump | ✅ | ✅ 小四边形 | 矮掩体 |

- 遮挡用 `LightOccluder2D` + 凸多边形（凹多边形阴影会出错）
- 玩家躲到树/灌木后时自动淡出（`fade_when_behind`），避免盖住角色
- 场景开启 `y_sort_enabled`，角色可走到树前/树后

## 3. 噪声系统（听声辨位）

```gdscript
GameState.emit_noise(position)   # 发出噪声
signal noise_emitted(position, radius)
```

**会发出噪声的行为**：
- 开箱（`chest._start_minigame`）
- 使用闪现（`entity._use_blink`）
- 放置光精灵（`entity._use_light_spirit`）

巨魔 AI 在 `troll_ai_hear_radius`（默认 420px）内听到噪声 → 进入 SEARCH 状态，走向最后已知位置搜索 3 秒。

## 4. 道具系统

| 道具 | 获取 | 使用 | 效果 |
|------|------|------|------|
| 光精灵 | 开箱随机 | **E** 键放置 | 固定在放置点，260px 半径永久照明（青色光） |
| 闪现 | 开箱随机 | **Q** 键消耗 | 朝鼠标位移 180px，撞墙截停，0.2s 无敌 |

- 数量显示在 HUD 技能栏上方（数量为 0 隐藏）
- 输入动作：`project.godot` 的 `skill_q` / `skill_e`（可在项目设置改键）

## 5. 宝箱掉落

```gdscript
var chest_gold_chance := 0.5    # 50% 金币，其余为道具（互斥）
var chest_gold_amount := 50     # 金币数量
var escape_gold_threshold := 100 # 逃生门所需
```

- 成功开箱**必回血 30%**（`chest_heal_ratio`），金币/道具二选一
- 设计意图：道具稀释金币产出，逼迫玩家多开箱 → 多开箱 = 多噪声 = 更容易被巨魔抓到
- 5 个宝箱位置从 10 个候选点随机抽（`game_scene._spawn_chests`）

## 6. 巨魔潜行 AI（`ai_troll.gd`）

```
PATROL（巡逻随机点 4~7 秒）─┐
    ↑                       │ 英雄进入探测半径(320px)
    │                       ↓
SEARCH（走向最后已知位置 3 秒）← CHASE（追击 + 攻击）
    ↑                       │
    └── 听声（420px 内）─────┘
```

- 探测是**纯距离判定**（当前未做视线检查，见 `docs/AI_PLAN.md` 改进项）
- 攻击决策：狂暴冲锋（远）→ 三连击/平砍（近）；低血撤退
- 英雄 AI 队友：离敌人超过 `ally_engage_radius`（380px）就回到玩家身边，不单独送死

## 7. 参数速查（`scripts/state/game_config.gd`）

```gdscript
# 黑夜 / 视野
var night_color := Color(0.07, 0.08, 0.15)  # 越暗视野外越黑
var camera_zoom := 1.0                       # 相机比例
var vision_light_energy := 0.95              # 视野光强度
var vision_light_color := Color(1.0, 0.96, 0.85)
var self_light_radius := 70.0                # 角色自照光
var self_light_energy := 0.8
var chest_glow_radius := 70.0                # 宝箱自发光
var chest_glow_energy := 0.5

# AI
var troll_ai_detect_radius := 320.0          # 探测半径
var troll_ai_hear_radius := 420.0            # 听声半径
var ally_engage_radius := 380.0              # 队友脱离距离

# 道具
var blink_distance := 180.0
var blink_invincible := 0.2
var light_spirit_radius := 260.0
var light_spirit_energy := 1.0
```

## 8. 调试提示

- 无头冒烟测试：`godot --headless --path <项目> res://tools/smoke_test.tscn`（46 项断言）
- 新增 `class_name` 脚本后需运行一次 `godot --editor --quit-after 900` 注册全局类，否则引用会报 "Could not find type"
- 夜晚截图验证：临时场景加载 `game_scene.tscn`，等 1 秒后 `get_viewport().get_texture().get_image().save_png(...)`
