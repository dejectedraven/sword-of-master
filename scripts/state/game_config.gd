extends Node
# ============================================================
#   Sword of Master — 数值中心
#   所有角色/技能/AI参数在这里调，改一个文件立刻生效
# ============================================================

# ═══════════ 英雄 - 战士 (Warrior) ═══════════

var warrior_hp: float = 100.0           # 最大生命
var warrior_speed: float = 200.0         # 移动速度 px/s
var warrior_attack: float = 15.0         # 平砍伤害
var warrior_defense: float = 5.0         # 防御（减伤 = 100/(100+防御)）

var warrior_slash_cooldown: float = 0.5  # 横斩冷却 (秒)
var warrior_slash_range: float = 60    # 判定框长度 (px)
var warrior_slash_duration: float = 0.15 # 判定框存活 (秒)

var warrior_charge_cooldown: float = 8 # 冲锋冷却 (秒)
var warrior_charge_mult: float = 1.5     # 伤害倍率
var warrior_charge_distance: float = 180 # 冲刺距离 (px)
var warrior_charge_hit_width: float = 48 # 判定框宽度 (px)

var warrior_block_cooldown: float = 3.0  # 盾碎后冷却 (秒)
var warrior_block_reduction: float = 0.8 # 减伤比例
var warrior_block_speed: float = 0.4     # 格挡时移速倍率

var warrior_attack_time: float = 0.6     # 攻击动画时长 (秒)
var warrior_recover_time: float = 0.3    # 攻击后摇 (秒)

# ═══════════ Boss - 巨魔 (Troll) ═══════════

var troll_hp: float = 300.0             # 最大生命
var troll_speed: float = 130.0           # 移动速度 px/s
var troll_attack: float = 22.0           # 平砍伤害
var troll_defense: float = 10.0          # 防御

var troll_slash_cooldown: float = 1.0    # 横斩冷却 (秒)
var troll_slash_range: float = 64.0      # 判定框长度 (px)
var troll_slash_duration: float = 0.2    # 判定框存活 (秒)

var troll_rush_cooldown: float = 15.0    # 狂暴冲锋冷却 (秒)
var troll_rush_duration: float = 8.0     # 冲刺持续 (秒)
var troll_rush_start: float = 50      # 起始速度 px/s
var troll_rush_max: float = 800.0        # 最高速度 px/s
var troll_rush_damage: float = 45.0      # 碰撞伤害
var troll_rush_hitbox: float = 120.0     # 判定框边长 (px)
var troll_rush_offset: float = 80.0      # 判定框前移量 (px)
var troll_rush_exhaust: float = 2.0      # 力竭时长 (秒)
var troll_rush_shake: float = 8.0       # 震屏强度 (px)

var troll_block_cooldown: float = 3.0    # 盾碎后冷却 (秒)
var troll_block_reduction: float = 0.8   # 减伤比例
var troll_block_speed: float = 0.4       # 格挡时移速倍率

var troll_attack_time: float = 0.8       # 攻击动画时长 (秒)
var troll_recover_time: float = 1.8      # 攻击后摇 (秒)

# ═══════════ AI - 战士 ═══════════

var warrior_ai_attack_range: float = 60.0    # 平砍触发距离 (px)
var warrior_ai_windup: float = 0.8           # 攻击前摇 (秒)
var warrior_ai_recover: float = 1           # 攻击后摇 (秒)
var warrior_ai_retreat_hp: float = 0.3        # 低于此血量开始逃跑
var warrior_ai_retreat_out: float = 500.0     # 退到此距离才回头 (px)
var warrior_ai_skill_range: float = 180.0     # 技能触发距离 (px)
var warrior_ai_skill_cd: float = 4.0          # 技能间隔 (秒)
var warrior_ai_block_chance: float = 0.25     # 逃跑时格挡概率

# ═══════════ AI - 巨魔 ═══════════

var troll_ai_attack_range: float = 80.0       # 平砍触发距离 (px)
var troll_ai_windup: float = 0.5             # 攻击前摇 (秒)
var troll_ai_recover: float = 4             # 攻击后摇 (秒)
var troll_ai_retreat_hp: float = 0.2          # 低于此血量开始逃跑
var troll_ai_retreat_out: float = 600.0       # 退到此距离才回头 (px)
var troll_ai_skill_range: float = 250.0       # 技能触发距离 (px)
var troll_ai_skill_cd: float = 8.0            # 技能间隔 (秒)
