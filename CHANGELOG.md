# 更新日志

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
