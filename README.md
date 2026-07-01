# Sword of Master

2D 俯视角非对称竞技游戏 Demo。Godot 4.6 + GDScript。

![Warrior](assets/sprites/player/Warrior_Blue.png)

## 玩法

- **英雄**：WASD 移动 · 左键横斩/射击 · 右键格挡（碎盾机制）· Space 冲锋/翻滚
- **巨魔**：追击 · 平砍 · Space 狂暴冲锋（无敌 + 震屏 + 力竭）
- **英雄模式**：你 + 1 AI 队友 vs 巨魔
- **Boss 模式**：你操控巨魔 vs 2 随机 AI 英雄
- **胜负**：全灭对方阵营即胜利

## 角色

| 角色 | 类型 | 技能 |
|------|------|------|
| 战士 | 英雄（近战均衡） | 横斩 + 冲锋 + 格挡 |
| 弓箭手 | 英雄（远程输出） | 射击 + 翻滚 + 格挡 |
| 巨魔 | Boss（高血量毁灭型） | 横斩 + 狂暴冲锋 + 格挡 |

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

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)

### 最新 [0.3.0] — 2026-06-30
- 弓箭手角色（射击 + 翻滚）
- AI 队友/敌方系统（英雄模式 1 队友，Boss 模式 2 敌人）
- 动态角色系统 + HUD 自动适配
- 通用 _cv() 参数查询 + GameConfig 统一调参
- 新增角色指南 docs/ADDING_CHARACTER.md

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
