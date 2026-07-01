# 新增角色指南

基于现有 Warrior / Archer / Troll 三个角色的实现总结。

## 一、新增英雄（如长矛手 Lancer）

### 1. 素材准备

```
assets/sprites/player/[Hero名]_Idle.png    # 待机 (hframes=帧数, 单行条带)
assets/sprites/player/[Hero名]_Run.png     # 跑步
assets/sprites/player/[Hero名]_Attack.png  # 攻击
assets/sprites/player/[Hero名]_Death.png   # 死亡（可选；有就用，没有就是闪红定格）
```

> Warrior 用的是**组合图** (6×8, 192×192/帧) + AnimationTree；Archer 用的是**分条带** + Sprite2D 帧循环。选一种即可，分条带更简单。

### 2. 创建实体场景 `scenes/entities/xxx.tscn`

复制 `archer.tscn` 改：

```
[node name="Xxx" type="CharacterBody2D"]
script = ExtResource(...entity.gd)

- idle_texture = ExtResource(Idle)
- run_texture  = ExtResource(Run)
- attack_texture = ExtResource(Attack)
- dead_texture = ExtResource(Death)   # 可选
- idle_frames  = 6    # 按实际帧数
- run_frames   = 4
- attack_frames = 6
- dead_frames  = 8    # 可选

子节点:
  Sprite2D       (position y=-33)
  CollisionShape2D  (CircleShape2D, radius=20)
  Camera2D
  HealthComponent
  [Abilities...]
```

根节点名必须是 PascalCase 首字母大写（如 Lancer），搭配 `_cv()` 前缀检测。

### 3. 添加技能（如需要新技能）

新建 `scripts/components/xxx_ability.gd`，继承 AbilityBase：

```gdscript
extends AbilityBase
class_name XxxAbility

func use():
    if is_on_cooldown: return
    # ...技能逻辑...
    start_cooldown()
```

在 tscn 里作为子节点挂上即可。

### 4. 编写 AI `scripts/controllers/ai_xxx.gd`

复制 `ai_archer.gd` 改。核心方法：

| 方法 | 说明 |
|------|------|
| `_find_target()` | 遍历场景找目标，通常找 `"Troll" in 名字` 或 `not is_ai_controlled` |
| `_physics_process()` | 距离判断 → 攻击/技能/追击/撤退 |
| `_slash()` / `_use_skill()` | 协程执行攻击，设 `_attacking = true` 阻断移动 |

### 5. 修改的文件清单

#### A. `scripts/state/game_config.gd`

新增角色参数块，命名范式 `xxx_参数名`：

```gdscript
var xxx_hp: float = 80.0
var xxx_speed: float = 220.0
var xxx_attack: float = 18.0
var xxx_defense: float = 4.0
var xxx_attack_time: float = 0.5
var xxx_recover_time: float = 0.25

# 每个技能一个 cooldown
var xxx_stab_cooldown: float = 0.6
var xxx_stab_range: float = 100.0

# AI 参数
var xxx_ai_attack_range: float = 120.0
var xxx_ai_windup: float = 0.5
var xxx_ai_recover: float = 0.8
var xxx_ai_retreat_hp: float = 0.25
var xxx_ai_retreat_out: float = 500.0
var xxx_ai_skill_range: float = 200.0
var xxx_ai_skill_cd: float = 6.0
```

#### B. `scripts/state/entity.gd` — `_cv()` 前缀

第 40 行附近，新增前缀分支：

```gdscript
func _cv(key: String):
    var prefix = "lancer" if "Lancer" in name else ("archer" if "Archer" in name else ...)
    return GameConfig.get(prefix + "_" + key) ?? 0.0
```

只要实体根节点名含对应标识即可自动匹配。

#### C. `scenes/main/hero_select.gd`

在 `_ready()` 的 `setup_cards([])` 里插入新卡牌：

```gdscript
{
    "id": "Lancer",
    "name": "长矛手",
    "desc": "中距离英雄\n突刺 + 横扫 + 格挡",
    "texture": load("res://assets/sprites/player/Lancer_Idle.png"),
    "hframes": 6,
    "vframes": 1,
    "region_rect": Rect2(0, 0, 1152, 192),
    "idle_start": 0,
    "idle_count": 6,
    "scale": Vector2(1.5, 1.5),
    "pos_y": get_viewport().get_visible_rect().size.y / 2 - 100,
    "on_confirm": func(): _start_game("Lancer"),
    "on_back": func(): get_tree().change_scene_to_file("res://scenes/main/title_screen.tscn"),
},
```

> 锁定的角色末尾插 "???" 占位卡，`locked: true`，放最后即可。

#### D. `scenes/main/game_scene.gd`

**英雄池**——`_setup_hero_mode()` 和 `_setup_boss_mode()` 里的 `pool` 数组加新名：

```gdscript
var pool = ["Warrior", "Archer", "Lancer"]
```

**AI 映射**——`_load_ai()` 的字典加条目：

```gdscript
var m = {
    "Warrior": "res://scripts/controllers/ai_warrior.gd",
    "Archer": "res://scripts/controllers/ai_archer.gd",
    "Lancer": "res://scripts/controllers/ai_lancer.gd",
    "Troll": "res://scripts/controllers/ai_troll.gd",
}
```

#### E. `scenes/ui/hud.gd` — 技能标签适配

`_update_skill_cd()` 里检测新能力节点。3 个 slot 对应：

| Slot | 触发键 | 检测优先级 |
|------|--------|-----------|
| 0 | LMB | SlashAbility / ArrowAbility |
| 1 | SPC | ChargeAbility / RushAbility / DodgeAbility |
| 2 | RMB | ComboAbility（若存在则显示 combo CD，否则显示格挡 CD） |

如果你有自定义技能名（非 Slash/Arrow/Charge/Dodge/Rush/Combo），加一行：

```gdscript
var stab = player.get_node_or_null("StabAbility") as AbilityBase
# ...在对应 slot 判断 stab
```

**RMB slot 特殊逻辑**：若有 `ComboAbility` 子节点，slot2 自动切换为 combo CD 遮罩 + 标签 "Combo"；若不存在则退化为格挡 CD。Boss 角色如果取消格挡改用 combo，无需改 HUD。

Abilities 节点命名模式 `<Name>Ability`，HUD 当前已支持自动检测：SlashAbility / ArrowAbility / ChargeAbility / DodgeAbility / RushAbility / ComboAbility。

### 6. 无需修改的文件

| 文件 | 原因 |
|------|------|
| `game_state.gd` | 枚举/变量随角色自增，不需改 |
| `boss_select.gd` | 仅魔王选角，英雄不用动 |
| `title_screen.gd/tscn` | 标题不变 |
| `health_component.gd` | 通用 |
| `ability_base.gd` | 通用基类，不碰 |

---

## 二、新增 Boss / 魔王

流程和英雄一样，区别：

| 项目 | 英雄 | Boss |
|------|------|------|
| 选角界面 | `hero_select.gd` | `boss_select.gd` |
| 游戏内生成 | `game_scene.gd` 池子里选 | 当前硬编码 `Troll`（第 39 行），要改成动态需改 `_setup_boss_mode()` 和 `_setup_hero_mode()` |
| AI 目标 | 找 Troll | 找非自己且非 AI 控制的 Entity |
| 素材路径 | `assets/sprites/player/` | `assets/sprites/enemies/` |

---

## 三、检查清单

- [ ] 精灵图放进 `assets/sprites/player/`（或 `enemies/`）
- [ ] `.tscn` 场景放 `scenes/entities/`，根节点名 PascalCase
- [ ] GameConfig 加参数块（`game_config.gd`）
- [ ] `_cv()` 前缀加分支（`entity.gd:40`）
- [ ] AI 脚本写 `scripts/controllers/`
- [ ] `_load_ai()` 映射加条目（`game_scene.gd:63`）
- [ ] 英雄池数组加名（`game_scene.gd:28/42`）
- [ ] 选角卡片加条目（`hero_select.gd`）
- [ ] `headless --quit` 编译通过
- [ ] 防撞：CollisionShape2D 配好 radius
- [ ] 死亡：有 death 贴图就导出，没有就是闪红定格

---

## 四、当前角色参考速查

| 角色 | 类型 | 动画方式 | skills | ai_script |
|------|------|---------|--------|-----------|
| Warrior | 英雄 | AnimationTree 6×8 组合图 | Slash + Charge + Block | `ai_warrior.gd` |
| Archer | 英雄 | Sprite2D 分条带帧循环 | Arrow + Dodge + Block | `ai_archer.gd` |
| Troll | Boss | Sprite2D 帧循环 | Slash(LMB) + Combo(RMB) + Rush(SPC) | `ai_troll.gd` |
