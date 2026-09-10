extends Node
# ============================================================
#   Sword of Master — 数值中心
#   所有角色/技能/AI参数在这里调，改一个文件立刻生效
# ════════════════════════════════════════════════════════════
# 命名规则：<前缀>_<参数名>，前缀 = warrior / archer / troll
# entity.gd 的 _cv("<参数名>") 按 name 拼前缀自动查值
# 例：entity.name="Warrior" → _cv("speed") → GameConfig.warrior_speed
# 新增角色须在此文件加同名前缀的整套变量
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
# ⚠ _cv("chest_speed") 查找规则：entity.gd 按 name 前缀拼键名
#   Warrior→warrior_chest_speed, Archer→archer_chest_speed, Troll→troll_chest_speed
#   新增角色须加 <前缀>_chest_speed 变量，否则 _cv 返回 0.0 导致指针冻结
var warrior_chest_speed: float = 120.0   # 开箱指针对位速度 px/s

# ═══════════ 英雄 - 弓箭手 (Archer) ═══════════

var archer_hp: float = 80             # 最大生命（黑夜潜行版本：60→80）
var archer_speed: float = 220.0          # 移动速度 px/s
var archer_attack: float = 12.0          # 射击伤害
var archer_defense: float = 3.0          # 防御

var archer_arrow_cooldown: float = 0.8   # 射击冷却 (秒)
var archer_arrow_speed: float = 600.0    # 箭矢速度 px/s
var archer_arrow_range: float = 500.0    # 箭矢最大射程 (px)

var archer_charge_cooldown: float = 3.0   # 蓄力射冷却 (秒)
var archer_charge_max_time: float = 1.5   # 最大蓄力时长 (秒)
var archer_charge_damage_bonus: float = 1.5 # 满蓄力额外伤害倍率 (1 + ratio * 1.5)
var archer_charge_speed_bonus: float = 0.5  # 满蓄力箭速加成倍率

var archer_triple_cooldown: float = 4.0   # 三连射冷却 (秒)
var archer_triple_damage_mult: float = 0.7 # 每箭伤害倍率
var archer_triple_spread: float = 15.0    # 散布角度 (±度)
var archer_triple_count: int = 3          # 箭数

var archer_attack_time: float = 0.4      # 射击动画时长 (秒)
var archer_recover_time: float = 0.2     # 射击后摇 (秒)
var archer_chest_speed: float = 160.0    # 开箱指针对位速度 px/s

# ═══════════ Boss - 巨魔 (Troll) ═══════════

var troll_hp: float = 300.0             # 最大生命
var troll_speed: float = 130.0           # 移动速度 px/s
var troll_attack: float = 16.0           # 平砍伤害（黑夜潜行版本：22→16）
var troll_defense: float = 10.0          # 防御

var troll_slash_cooldown: float = 1.0    # 横斩冷却 (秒)
var troll_slash_range: float = 64.0      # 判定框长度 (px)
var troll_slash_duration: float = 0.2    # 判定框存活 (秒)

var troll_rush_cooldown: float = 15.0    # 狂暴冲锋冷却 (秒)
var troll_rush_duration: float = 8.0     # 冲刺持续 (秒)
var troll_rush_start: float = 50      # 起始速度 px/s
var troll_rush_max: float = 800.0        # 最高速度 px/s
var troll_rush_damage: float = 32.0      # 碰撞伤害（黑夜潜行版本：45→32）
var troll_rush_hitbox: float = 120.0     # 判定框边长 (px)
var troll_rush_offset: float = 80.0      # 判定框前移量 (px)
var troll_rush_exhaust: float = 2.0      # 力竭时长 (秒)
var troll_rush_shake: float = 8.0       # 震屏强度 (px)

var troll_block_cooldown: float = 3.0    # 盾碎后冷却 (秒)
var troll_block_reduction: float = 0.8   # 减伤比例
var troll_block_speed: float = 0.4       # 格挡时移速倍率

var troll_attack_time: float = 0.35      # 攻击动画时长 (秒)
var troll_recover_time: float = 1.8      # 攻击后摇 (秒)
var troll_chest_speed: float = 80.0      # 开箱指针对位速度 px/s

# ═══════════ 巨魔 - 三连击 (Combo) ═══════════

var troll_combo_cooldown: float = 3.0    # 三连击冷却 (秒)
var troll_combo_duration: float = 0.6    # 三连击总时长 (秒)
var troll_combo_range: float = 64.0      # 判定框长度 (px)
var troll_combo_damage: float = 8.0      # 每击伤害（黑夜潜行版本：12→8）

# ═══════════ AI - 战士 ═══════════

var warrior_ai_attack_range: float = 60.0    # 平砍触发距离 (px)
var warrior_ai_windup: float = 0.8           # 攻击前摇 (秒)
var warrior_ai_recover: float = 1           # 攻击后摇 (秒)
var warrior_ai_retreat_hp: float = 0.3        # 低于此血量开始逃跑
var warrior_ai_retreat_out: float = 500.0     # 退到此距离才回头 (px)
var warrior_ai_skill_range: float = 180.0     # 技能触发距离 (px)
var warrior_ai_skill_cd: float = 4.0          # 技能间隔 (秒)
var warrior_ai_block_chance: float = 0.25     # 逃跑时格挡概率

# ═══════════ AI - 弓箭手 ═══════════

var archer_ai_attack_range: float = 350.0      # 射击触发距离 (px)
var archer_ai_preferred_range: float = 200.0   # 保持距离 (px)
var archer_ai_windup: float = 0.4              # 攻击前摇 (秒)
var archer_ai_recover: float = 0.6             # 攻击后摇 (秒)
var archer_ai_retreat_hp: float = 0.3           # 低于此血量开始逃跑
var archer_ai_retreat_out: float = 500.0        # 退到此距离才回头 (px)
var archer_ai_skill_cd: float = 5.0             # 技能间隔 (秒)
var archer_ai_charge_range: float = 250.0       # 蓄力射触发距离 (px)
var archer_ai_triple_range: float = 150.0       # 三连射触发距离 (px)

# ═══════════ 宝箱 (Chest) ═══════════

var chest_gold_amount: int = 50       # 开宝箱获得金币
var chest_gold_chance: float = 0.5    # 开箱给金币的概率（其余概率给道具，两者互斥）
var escape_gold_threshold: int = 100  # 逃生门所需金币

# ═══════════ 黑夜 / 视野 ═══════════
# 全部为测试数值，直接改这里运行看效果
var night_color: Color = Color(0.07, 0.08, 0.15)  # 夜色浓度（越暗视野外越黑，只留周身光圈）
var camera_zoom: float = 1.0                       # 相机缩放（1.0 = 原始比例，角色周身可见即可）
var vision_light_energy: float = 0.95              # 视野光强度（过高角色会过曝发白）
var vision_light_color: Color = Color(1.0, 0.96, 0.85)  # 视野光颜色（暖色像火把）
var self_light_radius: float = 70.0                # 角色自照小光半径（不投影，保证树影下也看得见角色）
var self_light_energy: float = 0.8                 # 角色自照光强度
var chest_glow_radius: float = 70.0                # 宝箱微弱自发光半径（黑暗中可辨认）
var chest_glow_energy: float = 0.5                 # 宝箱自发光强度
var warrior_vision_radius: float = 220.0           # 战士视野光圈半径 px
var archer_vision_radius: float = 260.0            # 弓箭手视野光圈半径 px
var troll_vision_radius: float = 320.0             # 巨魔（玩家操控时）视野半径 px
var troll_ai_detect_radius: float = 320.0          # 巨魔 AI 探测半径 px（阶段4 AI 用）
var troll_ai_hear_radius: float = 420.0            # 巨魔 AI 听声半径 px（阶段4 AI 用）
var ally_engage_radius: float = 380.0              # AI 队友离敌人超过此距离就回到玩家身边

var chest_speed: float = 120.0       # 指针对位初始速度 px/s
var chest_zone_size: float = 30.0    # 成功判定偏移量 (±px)
var chest_heal_ratio: float = 0.3    # 治疗比例 (最大HP)
var chest_speed_ramp: float = 20.0   # 每回合加速 px/s
var chest_max_speed: float = 300.0   # 最高速度 px/s
var chest_count: int = 5             # 每局生成数量

# ═══════════ 道具 (Items) ═══════════
var blink_distance: float = 180.0       # 闪现位移距离 px
var blink_invincible: float = 0.2       # 闪现无敌时间 秒
var light_spirit_radius: float = 260.0  # 光精灵照明半径 px
var light_spirit_energy: float = 1.0    # 光精灵光强度

# ═══════════ Props.png 瓦片尺寸（备忘） ═══════════
# assets/sprites/enemies/Props.png = 576×64
# 每格 16×16，共 36列×4行，不是 32×32！
# 第 12-15 列为冰/水晶物块，不是宝箱（之前误提取过）

# ═══════════ AI - 巨魔 ═══════════

var troll_ai_attack_range: float = 80.0       # 平砍触发距离 (px)
var troll_ai_windup: float = 0.5             # 攻击前摇 (秒)
var troll_ai_recover: float = 2.5             # 攻击后摇 (秒)
var troll_ai_retreat_hp: float = 0.2          # 低于此血量开始逃跑
var troll_ai_retreat_out: float = 600.0       # 退到此距离才回头 (px)
var troll_ai_skill_range: float = 250.0       # 技能触发距离 (px)
var troll_ai_skill_cd: float = 8.0            # 技能间隔 (秒)
