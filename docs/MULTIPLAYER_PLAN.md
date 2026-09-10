# Sword of Master — 联机版架构方案

> 本文档在单机版稳定后实施。当前专注完善单机内容。
> 联机版代码位于独立项目 `sword of master mp`。

## 游戏模式：1v3 非对称多人竞技

- **1 个 Boss 位**（巨魔）vs **最多 3 个英雄位**（战士/弓箭手/未来长矛手）
- 最少 2 人开打，最多 4 人
- 未满的位由 AI 补齐

## 技术选型

| 层 | 当前阶段 | 后续扩展 |
|----|---------|---------|
| 游戏数据传输 | Godot 内置 `ENetMultiplayerPeer` | 不变 |
| 好友发现/邀请 | 手动输入 IP:Port | Steamworks SDK（大厅+好友邀请+NAT穿透） |
| 匹配 | 无 | Steam 大厅或自建 WebSocket 大厅 |
| 权威模型 | **Host-authoritative**（房主跑 AI + 伤害判定） | 不变 |

## 新增文件清单

| 文件 | 用途 |
|------|------|
| `scripts/network/network_manager.gd` | **Autoload 单例**。管理 ENet peer、玩家槽位、RPC 封装、连接状态 |
| `scenes/main/lobby.tscn` + `lobby.gd` | 联机大厅：创建/加入游戏、展示玩家列表、角色选择、准备状态 |
| `scripts/network/player_slot.gd` | 玩家槽位数据结构（peer_id / name / faction / character / ready） |
| `scripts/network/entity_replicator.gd` | Entity 状态同步器：挂在每个 Entity 上，负责 MultiplayerSynchronizer 或手动 RPC |
| `scenes/main/network_game_scene.tscn` | 联机版游戏场景（基於原 game_scene，增加网络逻辑） |

## 修改文件清单

| 文件 | 改动 |
|------|------|
| `project.godot` | 添加 `NetworkManager` autoload；新增联网输入映射（多玩家） |
| `scripts/state/game_state.gd` | 添加 `player_slots`、`is_multiplayer`、`local_player_index` |
| `scripts/state/entity.gd` | `_input()` / `_read_input()` 按 `multiplayer_authority` 分流；添加状态 RPC |
| `scripts/components/health_component.gd` | `take_damage()` / `heal()` 改为仅 host 执行 + RPC 广播 |
| `scripts/components/ability_base.gd` | `use()` 增加 authority 检查 |
| `scenes/main/game_scene.gd` | 按权威分配 Entity；AI 只在 host 运行；替换 `get_node()` 为目标查找系统 |
| `scenes/ui/hud.gd` | 显示全部玩家 HP 条 + 名称 + 延迟 |
| `scenes/entities/*.tscn` | 添加 EntityReplicator 子节点（或 MultiplayerSynchronizer） |
| `所有能力脚本` | Arrow/Triple/Charge/Combo 等：投射物仅 host 生成，客户端 RPC 通知 |
| `所有 AI 脚本` | `_physics_process` 顶层加 `if not is_multiplayer_authority(): return` |

## 联机流程

```
title_screen
  ├─ [本地模式] → 原有单机流程
  └─ [联机模式] → lobby
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
   [创建游戏]               [加入游戏]
   输入端口号                输入 IP:Port
   ENet 创建 server          ENet 连接
        │                         │
        └────────┬────────────────┘
                 ▼
           lobby 等待中
       ┌─────────────────────┐
       │ P1 (Host/Boss)       │ ← 房主，固定 Boss
       │ P2 (Hero 1)          │ ← 客户端
       │ P3 (Hero 2 / AI)     │ ← 未满自动标记 AI
       │ P4 (Hero 3 / AI)     │
       │                      │
       │ 每人选角色 + 点准备   │
       │ 全员就绪 → Host 开始 │
       └─────────────────────┘
                 │
                 ▼
          network_game_scene
       (host-authoritative)
                 │
        ┌────────┴────────┐
        ▼                 ▼
   游戏结束          有人断线
   → 回到 lobby      → 回到 lobby
```

## 网络同步策略

**每帧同步（高频 ~60hz）**：Entity `global_position`、`velocity`、`state`、`facing_direction`

**事件同步（按需 RPC）**：
- `take_damage(amount)` → 仅 host 计算伤害，RPC 通知客户端扣血
- `ability_used(ability_name, position, direction)` → host 生成投射物/判定框
- `arrow_spawned(pos, dir, speed, damage)` → 客户端生成视觉箭头
- `chest_state_change(chest_id, new_state)` → 宝箱同步
- `game_over(victory_type)` → 结算

**不同步（客户端本地）**：相机震屏、蓄力条 UI、宝箱小游戏过程（只同步结果）、粒子特效

## EntityReplicator 设计

每个 Entity 附加一个 `EntityReplicator` 节点：

```
Entity
├── EntityReplicator (Node)
│   ├── MultiplayerSynchronizer
│   │   ├── position @ 60hz
│   │   ├── state @ on_change
│   │   └── facing_direction @ on_change
│   └── 手动 RPC 方法
│       ├── @rpc play_attack_anim
│       ├── @rpc take_damage_result
│       └── @rpc play_anim
```

## 分阶段实施

### Phase 1（本次）：ENet 直连可玩
- NetworkManager autoload
- 大厅（创建/加入）
- 多人角色选择 + 准备机制
- Host-authoritative 游戏
- AI 补位
- HUD 多人血条

### Phase 2（后续）：Steam 集成
- Steamworks SDK 接入
- 好友列表 / 邀请
- 大厅浏览

### Phase 3（后续）：匹配 + 优化
- Steam 匹配或自建大厅
- 延迟补偿 / 插值优化
- 断线重连
