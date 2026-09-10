# Sword of Master — AI 改进方案

> 现状：v0.7.0 的 AI 能完成基础战斗循环，但"太简单"——直线追击、隔树能看见、容易卡树。
> 本文档给出分阶段改进方案，每阶段可独立验证、独立上线。

## 1. 现状分析

### 各 AI 行为
| 文件 | 行为 | 主要问题 |
|------|------|---------|
| `ai_troll.gd` | 巡逻 → 距离探测/听声 → 追击 → 搜索 | ① 隔树/隔墙也能"看见"（纯距离判定）② 直线追击撞树卡住 ③ 无目标选择 ④ 冲锋不看预判 |
| `ai_warrior.gd` | 追击 → 前摇 → 平砍 → 后摇；技能距离冲锋；低血撤退+随机格挡 | ① 无视线概念，隔树砍空气 ② 不会绕障碍 ③ 格挡是随机的，不会"看到攻击再格挡" |
| `ai_archer.gd` | 保持 200px → 350px 内射击；近身三连射；中距蓄力射；低血撤退 | ① 射击不做视线检查，箭全打在树上 ② 不会走位（站桩射）③ 不会横向拉扯 |

### 共性问题
1. **感知不真实**：全部用"圆形距离"判定，没有视线（LOS）、没有视野锥、没有最后已知位置的衰减
2. **无寻路**：`move_direction` 直线朝目标，撞上障碍靠 `move_and_slide` 滑动，凹角必卡死
3. **无目标选择**：`_find_target()` 取"第一个遇到的敌人"，不评估威胁/血量/距离
4. **无团队协同**：AI 队友各打各的；巨魔不会优先集火落单者
5. **无卡死自救**：被障碍卡住后没有检测/脱困逻辑
6. **无难度参数**：反应速度、命中精度、进攻欲望全是硬编码
7. **无调试可视化**：看不到 AI 的探测范围/路径/状态

### 可借鉴资产
旧项目 `sword of master/scripts/controllers/ai_controller.gd` 已有：
- 正式状态机 `AIStateMachine`（PATROL/CHASE/ATTACK/BERSERK/RETREAT）
- `NavigationAgent2D` 寻路 + `get_next_path_position()`
- 巡逻点数组循环巡逻
→ 架构可直接移植，替换掉 v2 的 if/else 状态判断。

---

## 2. 改进方案（按优先级）

### 阶段 A — 感知真实化（0.5~1 天）★推荐先做
**目标**：巨魔不再"隔树看见"，弓箭手不再"对着树射"。

```gdscript
# 通用视线检查（放在 Entity 或工具类）
func has_line_of_sight(target_pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	var q = PhysicsRayQueryParameters2D.create(global_position, target_pos, 2)  # mask2=墙/障碍
	q.exclude = [self]
	return space.intersect_ray(q).is_empty()
```

- `ai_troll`：探测条件改为 `dist < detect_radius AND has_line_of_sight(target)`；
  新增 `last_seen_timer`——视线断掉后仍追最后已知位置 2 秒再转 SEARCH
- `ai_archer`：射击前检查视线；被挡则**横向走位**（垂直方向平移找角度）而不是站桩
- `ai_warrior`：进入攻击距离前也检查视线，隔树时绕行
- 可选：巨魔视野锥（`facing.dot(dir) > cos(60°)`）+ 近身 100px 全向感知，让"绕背偷袭"成立

**验收**：躲在树后的英雄不被发现；弓箭手会挪位找角度；冒烟测试加"隔树不被探测"断言。

### 阶段 B — 导航寻路（1 天）
**目标**：AI 不再卡树/卡墙角。

两种实现路径（选一）：
| 方案 | 做法 | 优点 | 缺点 |
|------|------|------|------|
| B1 动态避障（推荐） | 障碍物挂 `NavigationObstacle2D`，Entity 挂 `NavigationAgent2D`（开启 avoidance） | 无需烘焙、适配运行时生成的地图 | 极端凹角仍可能绕路 |
| B2 运行时烘焙 | 生成障碍后 `NavigationRegion2D` + `NavigationServer2D` 烘焙导航网格 | 路径最优 | API 复杂、烘焙耗时 |

- 巡逻/追击/搜索全部改走 `agent.get_next_path_position()`
- 参考旧项目 `ai_controller.gd:139-151` 的 `_nav_move()`

**验收**：AI 能绕过树群到达目标；冒烟测试加"卡死检测"（位移 < 阈值持续 2 秒则重选路径）。

### 阶段 C — 战斗智能（1~2 天）
**目标**：AI 打得像人。

- **目标选择评分**：`score = 距离权重 + 血量权重 + 威胁权重`（最近攻击我的目标加分）→ 不再无脑取第一个
- **弓箭手**：保持射程的"横向拉扯"（目标靠近就后退，远离就前进，同时横向走位）；被近身优先三连射
- **战士**：观察到目标进入攻击前摇 → 举盾格挡（替代随机格挡）；目标逃跑 → 冲锋追击
- **巨魔**：
  - 冲锋做**预判**：`aim = target.pos + target.velocity * (dist / rush_speed)`
  - 被绕树风筝时：放弃直线追，用冲锋封路
  - 三连击在目标格挡时改为延迟释放（骗格挡）
- 引入 `reaction_time`（反应延迟，难度参数）

**验收**：巨魔冲锋能命中移动目标；战士会针对性格挡；对局观感明显提升。

### 阶段 D — 团队协同（1~2 天）
**目标**：3 英雄像一个队伍，巨魔会抓落单。

- **AI 队友**：
  - 集火：共享目标（`GameState` 或场景级 coordinator），避免各打各的
  - 阵型：与玩家保持 120~200px 距离；近战在前、弓箭手在后
  - 不挡枪线：射击前检查队友是否在弹道上
- **巨魔 AI**：
  - 优先攻击**落单**英雄（与其他英雄距离 > 300px 者加分）
  - 巡逻点改为"兴趣点"：宝箱位置、逃生门、玩家出生点（守株待兔）
  - 逃生门解锁后进入"守门"模式

**验收**：AI 队友不再排队送死；巨魔会守宝箱/守门。

### 阶段 E — 难度参数化 + 调试可视化（0.5 天）
**目标**：可调难度、可观察 AI 决策。

```gdscript
# ═══════════ AI 难度 ═══════════
var ai_reaction_time := 0.25      # 反应延迟（秒）
var ai_aim_error := 8.0           # 瞄准误差（像素）
var ai_aggression := 1.0          # 进攻欲望倍率（影响探测/追击距离）
var ai_difficulty := 1            # 0=简单 1=普通 2=困难（预设倍率）
```

- 调试层：`_draw()` 画探测半径、视野锥、当前路径、状态文字（`OS.is_debug_build()` 时启用，F3 开关）

---

## 3. 推荐实施顺序

```
A 感知真实化  ← 先做，潜行玩法的根基，改动小收益大
B 导航寻路    ← 解决卡树，体验提升最明显
E 调试可视化  ← 和 B 一起做，方便调 A/B/C
C 战斗智能    ← 手感升级
D 团队协同    ← 最后做，依赖 A/B/C 稳定
```

## 4. 架构建议

- 移植旧项目的 `AIStateMachine`（`scripts/controllers/ai_state_machine.gd`），统一 PATROL/CHASE/ATTACK/SEARCH/RETREAT 状态
- 抽公共基类 `ai_base.gd`：持有 entity/target、视线检查、寻路移动、卡死检测，三个 AI 继承
- 所有阈值进 `GameConfig`，禁止硬编码魔法数字
- 每个阶段结束必须：`--import` 零错误 + 冒烟测试全绿 + 截图/观感确认
