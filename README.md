# Sword of Master

2D 俯视角非对称竞技游戏 Demo。Godot 4.6 + GDScript。

![Warrior](assets/sprites/player/Warrior_Blue.png)

## 玩法

- **英雄**：WASD 移动 · 左键横斩/射击 · 右键格挡/蓄力射击 · Space 冲锋/三连射
- **巨魔**：追击 · 左键单次攻击 · 右键三连击 · Space 狂暴冲锋（无敌 + 震屏 + 力竭）
- **英雄模式**：你 + 2 AI 队友 vs 巨魔
- **Boss 模式**：你操控巨魔 vs 3 随机 AI 英雄
- **宝箱**：场景中随机生成 2 个，按 F 启动节奏对位小游戏，成功回血 30% + 50 金币
- **逃生**：金币集满 100 解锁逃生门，进入即胜利
- **阵亡**：英雄阵亡后视角自动切到存活队友
- **胜负**：全灭对方阵营 或 集满金币逃离

## 角色

| 角色 | 类型 | 技能 | 开箱速度 |
|------|------|------|---------|
| 战士 | 英雄（近战均衡） | 横斩 + 冲锋 + 格挡 | 中 (120) |
| 弓箭手 | 英雄（远程输出） | 射击 + 三连射 + 蓄力射击 | 快 (160) |
| 巨魔 | Boss（高血量毁灭型） | 单次攻击 + 三连击 + 狂暴冲锋 | 不可开箱 |

新增角色指南见 [docs/ADDING_CHARACTER.md](docs/ADDING_CHARACTER.md)。

## 运行

1. 用 Godot 4.6 打开 `project.godot`
2. F5 运行 → 选阵营 → 选角色 → 战斗

## 参数调校

改 `scripts/state/game_config.gd`，全部中文注释。

## 素材

基于 Tiny Swords (Pixelfrog) 素材包。
- Warrior_Blue/Red/Purple/Yellow：Kenney Tiny Swords Free & Main Pack
- Troll_Idle/Walk/Attack/Dead/Recovery/Windup：Tiny Swords Enemy Pack
- UI 按钮/面板：Tiny Swords Main Pack
- 字体：PirataOne
- 宝箱精灵：Bonsaiheldin — Treasure chests 32x32 (CC-BY 4.0) — https://opengameart.org/content/treasure-chests-32x32

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)

### 最新 [0.6.0] — 2026-09-10
- 金币 + 逃生门：宝箱给 50 金币，集满 100 解锁逃生门，进入即胜利（第三种结局）
- 伤害飘字：普通白 / 格挡蓝 / 大伤害橙
- 3 英雄阵容：英雄模式你 + 2 AI 队友；Boss 模式 1v3 AI 英雄
- 英雄阵亡后视角自动绑到存活队友
- 结算界面「再来一局 / 返回标题」
- 阵营系统（entity.team）阻止友伤
- 地宫生成工具 `tools/setup_dungeon.gd` + 无头冒烟测试 `tools/smoke_test.tscn`（21 断言）
- 修复：蓄力射满蓄吞箭卡死、逃生门不挡人、AI 蓄力射瞄鼠标、AI 战士格挡死锁、相机越界、箭矢 Tween 报错等

### [0.5.0] — 2026-07-05
- Archer 技能重做：RMB 蓄力射击（按住蓄力 0→1.5s，伤害/箭速随蓄力比增长）+ SPC 三连射（±15° 3 箭，0.7x 伤害/箭）
- 移除 Archer 翻滚和格挡技能
- Archer AI 适配：中距离蓄力射、近距离三连射、远程普攻、低血撤退
- GameConfig 新增 charge/triple 参数

### [0.2.0] — 2026-06-29
- 卡片式角色选择（滚轮切换 + 动画预览 + 敬请期待）
- 巨魔死亡动画 + 力竭动画 + 全屏震屏
- 阵营选择 UI（酒馆 / 魔王城）
- 技能键位 Q → Space
- 全文件 Tab 缩进修复
- 格挡碎盾、攻击后摇、AI 协程重入修复
- `game_config.gd` 统一数值中心

### [0.1.0] — 2026-06-28
- 战士 vs 巨魔原型完成
- 移动、横斩、格挡、冲锋、狂暴冲锋
- AI 追击/平砍/撤退
- HUD 血条 + 技能 CD 遮罩
