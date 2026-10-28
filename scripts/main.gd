
extends Node2D

# ==========================================
# 《一念成仙》Godot 4.7.2
# 第八阶段：多种妖兽（妖狼 / 疾风雀 / 岩甲兽）
# ==========================================

# 玩家属性
var player_pos: Vector2 = Vector2.ZERO
var player_speed: float = 230.0
var player_size: float = 24.0
var player_max_hp: int = 100
var player_hp: int = 100
var damage_cooldown: float = 0.0
var is_game_over: bool = false

# 妖兽类型数据表（阶段 8）
# size 是直径（不是半径）；speed 单位 px/s；damage 是接触伤害；reward 是击杀修为
const ENEMY_TYPES := {
	"wolf": {
		"name": "妖狼",
		"color": Color("#bd3e85"),
		"size": 34.0,
		"speed": 135.0,
		"max_hp": 100,
		"damage": 18,
		"reward": 35,
	},
	"bird": {
		"name": "疾风雀",
		"color": Color("#d9a441"),
		"size": 24.0,
		"speed": 205.0,
		"max_hp": 55,
		"damage": 12,
		"reward": 28,
	},
	"golem": {
		"name": "岩甲兽",
		"color": Color("#8c4a2f"),
		"size": 52.0,
		"speed": 95.0,
		"max_hp": 180,
		"damage": 32,
		"reward": 90,
	},
	"boss": {
		"name": "魔道老祖",
		"color": Color("#c1121f"),
		"size": 110.0,
		"speed": 85.0,
		"max_hp": 8000,
		"damage": 60,
		"reward": 1500,
	},
}

# ==========================================
# 属性法术（v0.9.0）：给剑气附加元素
# ==========================================
const ELEMENTS := {
	"none":    {"name": "",       "color": "#42f5ff"},
	"fire":    {"name": "烈焰",   "color": "#ff6b35"},
	"ice":     {"name": "寒冰",   "color": "#6bc8ff"},
	"thunder": {"name": "雷霆",   "color": "#c77dff"},
	"wind":    {"name": "罡风",   "color": "#9dffb0"},
}

# ==========================================
# 法器（v0.11.0）：被动装备，3 槽，同类型不可重复
# ==========================================
const ARTIFACTS := {
	"青锋剑匣": {"rarity": "凡", "desc": "剑气伤害 +15",        "stat": "sword",       "value": 15},
	"玄龟甲":   {"rarity": "凡", "desc": "减伤 8%",             "stat": "armor",       "value": 8},
	"疾风铃":   {"rarity": "凡", "desc": "移速 +40",            "stat": "speed",       "value": 40},
	"聚灵珠":   {"rarity": "凡", "desc": "修为获取 +15%",       "stat": "xp_bonus",    "value": 15},
	"雷纹印":   {"rarity": "灵", "desc": "暴击率 +8%",          "stat": "crit",        "value": 8},
	"回春玉":   {"rarity": "灵", "desc": "每秒回复 1.5 生命",    "stat": "regen",       "value": 1.5},
	"破军令":   {"rarity": "灵", "desc": "剑气射程 +80",        "stat": "range",       "value": 80},
	"千机匣":   {"rarity": "灵", "desc": "攻击间隔 -0.06 秒",    "stat": "attack_speed","value": 0.06},
	"太虚镜":   {"rarity": "宝", "desc": "剑气 +1 道（散射）",   "stat": "extra_shot",  "value": 1},
	"不灭灯":   {"rarity": "宝", "desc": "生命低于 30% 时减伤 +30%", "stat": "low_hp_armor", "value": 30},
	"噬魂幡":   {"rarity": "宝", "desc": "击杀回复 3 生命",       "stat": "kill_heal",   "value": 3},
	"天罡印":   {"rarity": "宝", "desc": "暴击伤害 ×2.5（原 ×2）", "stat": "crit_dmg",   "value": 0.5},
}

const MAX_ARTIFACTS := 3

const ELEMENT_SKILLS := {
	"烈焰剑气": {"element": "fire",    "desc": "剑气附带灼烧：每秒 -8 血，持续 3 秒"},
	"寒冰剑气": {"element": "ice",     "desc": "剑气附带减速 35%，持续 2 秒"},
	"雷霆剑气": {"element": "thunder", "desc": "20% 概率连锁到 200px 内另一只"},
	"罡风剑气": {"element": "wind",    "desc": "击退 60px，且剑气 +1 道"},
}

# ==========================================
# 劫难系统（阶段 11）：破境时触发
# ==========================================
const TRIBULATIONS := {
	"strong":  {"name": "强敌劫",   "min": 1, "max": 2, "hp": 3.0, "dmg": 1.8, "size": 1.3, "color": "#a83232"},
	"thunder": {"name": "天罚雷劫", "min": 1, "max": 1, "hp": 4.0, "dmg": 2.5, "size": 1.2, "color": "#4a6fd4"},
	"demon":   {"name": "心魔劫",   "min": 1, "max": 1, "hp": 5.0, "dmg": 1.5, "size": 1.15, "color": "#7a2f8f"},
	"three":   {"name": "斩三尸",   "min": 3, "max": 3, "hp": 3.5, "dmg": 1.7, "size": 1.0, "color": "#2f7a5f"},
}

# 化神（realm_index >= 5）之后才出现雷劫/心魔/三尸
const LATE_TRIBULATIONS := ["thunder", "demon", "three"]

# 劫难奖励三选一
const TRIBULATION_REWARDS := [
	{"name": "道基稳固", "desc": "最大生命 +40 并回满", "stat": "max_hp", "value": 40},
	{"name": "杀伐果断", "desc": "剑气伤害 +50", "stat": "sword", "value": 50},
	{"name": "身法通玄", "desc": "移速 +60，攻击间隔 -0.05 秒", "stat": "multi",
		"effects": [{"stat": "speed", "value": 30}, {"stat": "attack_speed", "value": 0.05}]},
]

# ==========================================
# 关卡流程（阶段 10）：5 波 + 首领
# ==========================================
# 波次仅作记录（每波击杀数），不限制进度、不触发首领
const WAVE_KILLS_PER_WAVE := 20
const ELITE_HP_MUL := 1.6
const ELITE_DMG_MUL := 1.6
const ELITE_SIZE_MUL := 1.25
const ELITE_REWARD_MUL := 2

# ==========================================
# 境界体系（阶段 9）
# 凡人十境，每境初期/中期/圆满；xp 是「升到下一小阶」所需修为
# ==========================================
const REALMS := [
	{
		"name": "炼己",
		"xp": [210, 245, 280],
		"skills": ["剑气诀", "护体灵气", "疾风步", "凝神", "吐纳诀", "养气术", "快剑式", "远击诀"],
	},
	{
		"name": "筑基",
		"xp": [280, 315, 350],
		"skills": ["御剑术", "金钟罩", "踏云步", "心眼", "周天功", "固元术", "流云剑", "穿云式"],
	},
	{
		"name": "炼精",
		"xp": [315, 350, 385],
		"skills": ["精元剑气", "精血护体", "精行步", "精觉", "精元回春", "精血凝体", "精微剑", "精远击"],
	},
	{
		"name": "化炁",
		"xp": [350, 385, 420],
		"skills": ["炁冲剑脉", "炁盾", "罡气行云", "炁感", "炁养周天", "炁凝真身", "炁疾剑", "炁破长空", "烈焰剑气"],
	},
	{
		"name": "炼炁",
		"xp": [385, 420, 455],
		"skills": ["炁御剑", "炁墙", "缩地成寸", "炁视", "炼炁化生", "炼炁铸体", "炼炁快剑", "炼炁远击", "寒冰剑气"],
	},
	{
		"name": "化神",
		"xp": [420, 490, 525],
		"skills": ["神识御剑", "神念护体", "神行术", "神觉", "神元回春", "神元凝体", "神速剑", "神识远照", "雷霆剑气"],
	},
	{
		"name": "炼神",
		"xp": [490, 525, 560],
		"skills": ["炼神剑意", "神元护体", "踏虚而行", "洞神", "炼神养元", "炼神固本", "炼神快剑", "炼神远击", "罡风剑气"],
	},
	{
		"name": "返虚",
		"xp": [525, 595, 630],
		"skills": ["虚空剑意", "返虚护体", "返虚游", "洞虚", "返虚化生", "返虚凝体", "返虚快剑", "返虚远游", "烈焰剑气"],
	},
	{
		"name": "炼虚",
		"xp": [595, 630, 665],
		"skills": ["虚剑破空", "虚元金身", "逍遥游", "虚瞳", "炼虚长生", "炼虚铸体", "炼虚快剑", "炼虚远击", "寒冰剑气"],
	},
	{
		"name": "合道",
		"xp": [700, 770, 840],
		"skills": ["大道剑诀", "合道金身", "天地同游", "天眼", "合道长生", "合道真身", "合道快剑", "合道无疆", "雷霆剑气"],
	},
]

const STAGE_NAMES := ["初期", "中期", "圆满"]

# ==========================================
# 功法表
# stat: sword / armor / speed / crit
# ==========================================
const SKILLS := {
	# ---- 炼己 ----
	"剑气诀":     {"desc": "剑气伤害 +8",    "stat": "sword", "value": 8},
	"护体灵气":   {"desc": "减伤 1.5%",        "stat": "armor", "value": 1.5},
	"疾风步":     {"desc": "移速 +12",       "stat": "speed", "value": 12},
	"凝神":       {"desc": "暴击率 +5%",     "stat": "crit",  "value": 5},
	"吐纳诀":     {"desc": "生命回复 +0.5/秒", "stat": "regen", "value": 0.5},
	"养气术":     {"desc": "生命上限 +20",   "stat": "max_hp", "value": 20},
	"快剑式":     {"desc": "攻击间隔 -0.04 秒", "stat": "attack_speed", "value": 0.04},
	"远击诀":     {"desc": "剑气射程 +40",   "stat": "range", "value": 40},
	# ---- 筑基 ----
	"御剑术":     {"desc": "剑气伤害 +18",   "stat": "sword", "value": 18},
	"金钟罩":     {"desc": "减伤 2.5%",       "stat": "armor", "value": 2.5},
	"踏云步":     {"desc": "移速 +22",       "stat": "speed", "value": 22},
	"心眼":       {"desc": "暴击率 +10%",    "stat": "crit",  "value": 10},
	"周天功":     {"desc": "生命回复 +1.0/秒", "stat": "regen", "value": 1.0},
	"固元术":     {"desc": "生命上限 +40",   "stat": "max_hp", "value": 40},
	"流云剑":     {"desc": "攻击间隔 -0.05 秒", "stat": "attack_speed", "value": 0.05},
	"穿云式":     {"desc": "剑气射程 +70",   "stat": "range", "value": 70},
	# ---- 炼精 ----
	"精元剑气":   {"desc": "剑气伤害 +26",   "stat": "sword", "value": 26},
	"精血护体":   {"desc": "减伤 3.0%",       "stat": "armor", "value": 3.0},
	"精行步":     {"desc": "移速 +30",       "stat": "speed", "value": 30},
	"精觉":       {"desc": "暴击率 +13%",    "stat": "crit",  "value": 13},
	"精元回春":   {"desc": "生命回复 +1.5/秒", "stat": "regen", "value": 1.5},
	"精血凝体":   {"desc": "生命上限 +60",   "stat": "max_hp", "value": 60},
	"精微剑":     {"desc": "攻击间隔 -0.06 秒", "stat": "attack_speed", "value": 0.06},
	"精远击":     {"desc": "剑气射程 +100",  "stat": "range", "value": 100},
	# ---- 化炁 ----
	"炁冲剑脉":   {"desc": "剑气伤害 +36",   "stat": "sword", "value": 36},
	"炁盾":       {"desc": "减伤 3.5%",       "stat": "armor", "value": 3.5},
	"罡气行云":   {"desc": "移速 +40",       "stat": "speed", "value": 40},
	"炁感":       {"desc": "暴击率 +17%",    "stat": "crit",  "value": 17},
	"炁养周天":   {"desc": "生命回复 +2.0/秒", "stat": "regen", "value": 2.0},
	"炁凝真身":   {"desc": "生命上限 +85",   "stat": "max_hp", "value": 85},
	"炁疾剑":     {"desc": "攻击间隔 -0.07 秒", "stat": "attack_speed", "value": 0.07},
	"炁破长空":   {"desc": "剑气射程 +140",  "stat": "range", "value": 140},
	# ---- 炼炁 ----
	"炁御剑":     {"desc": "剑气伤害 +48",   "stat": "sword", "value": 48},
	"炁墙":       {"desc": "减伤 4.0%",       "stat": "armor", "value": 4.0},
	"缩地成寸":   {"desc": "移速 +52",      "stat": "speed", "value": 52},
	"炁视":       {"desc": "暴击率 +22%",    "stat": "crit",  "value": 22},
	"炼炁化生":   {"desc": "生命回复 +2.5/秒", "stat": "regen", "value": 2.5},
	"炼炁铸体":   {"desc": "生命上限 +115",  "stat": "max_hp", "value": 115},
	"炼炁快剑":   {"desc": "攻击间隔 -0.08 秒", "stat": "attack_speed", "value": 0.08},
	"炼炁远击":   {"desc": "剑气射程 +190",  "stat": "range", "value": 190},
	# ---- 化神 ----
	"神识御剑":   {"desc": "剑气伤害 +62",   "stat": "sword", "value": 62},
	"神念护体":   {"desc": "减伤 4.5%",       "stat": "armor", "value": 4.5},
	"神行术":     {"desc": "移速 +65",      "stat": "speed", "value": 65},
	"神觉":       {"desc": "暴击率 +27%",    "stat": "crit",  "value": 27},
	"神元回春":   {"desc": "生命回复 +3.0/秒", "stat": "regen", "value": 3.0},
	"神元凝体":   {"desc": "生命上限 +150",  "stat": "max_hp", "value": 150},
	"神速剑":     {"desc": "攻击间隔 -0.09 秒", "stat": "attack_speed", "value": 0.09},
	"神识远照":   {"desc": "剑气射程 +250",  "stat": "range", "value": 250},
	# ---- 炼神 ----
	"炼神剑意":   {"desc": "剑气伤害 +80",   "stat": "sword", "value": 80},
	"神元护体":   {"desc": "减伤 5.0%",       "stat": "armor", "value": 5.0},
	"踏虚而行":   {"desc": "移速 +80",      "stat": "speed", "value": 80},
	"洞神":       {"desc": "暴击率 +33%",    "stat": "crit",  "value": 33},
	"炼神养元":   {"desc": "生命回复 +3.5/秒", "stat": "regen", "value": 3.5},
	"炼神固本":   {"desc": "生命上限 +190",  "stat": "max_hp", "value": 190},
	"炼神快剑":   {"desc": "攻击间隔 -0.10 秒", "stat": "attack_speed", "value": 0.10},
	"炼神远击":   {"desc": "剑气射程 +320",  "stat": "range", "value": 320},
	# ---- 返虚 ----
	"虚空剑意":   {"desc": "剑气伤害 +100",  "stat": "sword", "value": 100},
	"返虚护体":   {"desc": "减伤 5.5%",       "stat": "armor", "value": 5.5},
	"返虚游":     {"desc": "移速 +97",      "stat": "speed", "value": 97},
	"洞虚":       {"desc": "暴击率 +39%",    "stat": "crit",  "value": 39},
	"返虚化生":   {"desc": "生命回复 +4.0/秒", "stat": "regen", "value": 4.0},
	"返虚凝体":   {"desc": "生命上限 +240",  "stat": "max_hp", "value": 240},
	"返虚快剑":   {"desc": "攻击间隔 -0.11 秒", "stat": "attack_speed", "value": 0.11},
	"返虚远游":   {"desc": "剑气射程 +400",  "stat": "range", "value": 400},
	# ---- 炼虚 ----
	"虚剑破空":   {"desc": "剑气伤害 +125",  "stat": "sword", "value": 125},
	"虚元金身":   {"desc": "减伤 6.0%",       "stat": "armor", "value": 6.0},
	"逍遥游":     {"desc": "移速 +117",      "stat": "speed", "value": 117},
	"虚瞳":       {"desc": "暴击率 +46%",    "stat": "crit",  "value": 46},
	"炼虚长生":   {"desc": "生命回复 +4.5/秒", "stat": "regen", "value": 4.5},
	"炼虚铸体":   {"desc": "生命上限 +300",  "stat": "max_hp", "value": 300},
	"炼虚快剑":   {"desc": "攻击间隔 -0.12 秒", "stat": "attack_speed", "value": 0.12},
	"炼虚远击":   {"desc": "剑气射程 +500",  "stat": "range", "value": 500},
	# ---- 合道 ----
	"大道剑诀":   {"desc": "剑气伤害 +155",  "stat": "sword", "value": 155},
	"合道金身":   {"desc": "减伤 6.5%",       "stat": "armor", "value": 6.5},
	"天地同游":   {"desc": "移速 +140",      "stat": "speed", "value": 140},
	"天眼":       {"desc": "暴击率 +54%",    "stat": "crit",  "value": 54},
	"合道长生":   {"desc": "生命回复 +5.0/秒", "stat": "regen", "value": 5.0},
	"合道真身":   {"desc": "生命上限 +380",  "stat": "max_hp", "value": 380},
	"合道快剑":   {"desc": "攻击间隔 -0.13 秒", "stat": "attack_speed", "value": 0.13},
	"合道无疆":   {"desc": "剑气射程 +620",  "stat": "range", "value": 620},
	# ---- 神仙 ----
	"阳神御剑":   {"desc": "剑气 +200，暴击 +20%", "stat": "multi", "effects": [
		{"stat": "sword", "value": 200}, {"stat": "crit", "value": 20}]},
	"不坏仙躯":   {"desc": "最大生命 +120 并回满，减伤 +85", "stat": "multi", "effects": [
		{"stat": "max_hp", "value": 120}, {"stat": "armor", "value": 8.0}]},
	"咫尺天涯":   {"desc": "移速 +340，攻击间隔 -0.10 秒", "stat": "multi", "effects": [
		{"stat": "speed", "value": 170}, {"stat": "attack_speed", "value": 0.10}]},
	# ---- 天仙 ----
	"万剑朝宗":   {"desc": "剑气 +300，暴击 +30%", "stat": "multi", "effects": [
		{"stat": "sword", "value": 300}, {"stat": "crit", "value": 30}]},
	"太虚不灭":   {"desc": "最大生命 +200 并回满，减伤 +120", "stat": "multi", "effects": [
		{"stat": "max_hp", "value": 200}, {"stat": "armor", "value": 10.0}]},
	"逍遥无极":   {"desc": "移速 +450，攻击间隔 -0.15 秒", "stat": "multi", "effects": [
		{"stat": "speed", "value": 225}, {"stat": "attack_speed", "value": 0.15}]},
	# ---- 属性法术（化炁起出现） ----
	"烈焰剑气":   {"desc": "剑气附带灼烧：每秒 -8 血，3 秒", "stat": "element", "value": 0, "element": "fire"},
	"寒冰剑气":   {"desc": "剑气附带减速 35%，2 秒", "stat": "element", "value": 0, "element": "ice"},
	"雷霆剑气":   {"desc": "20% 概率连锁 200px 内另一只", "stat": "element", "value": 0, "element": "thunder"},
	"罡风剑气":   {"desc": "击退 60px，剑气 +1 道", "stat": "element", "value": 0, "element": "wind"},
}

# ==========================================
# 仙道三选一（炼虚合道·圆满后触发，不可逆）
# ==========================================
const IMMORTAL_PATHS := {
	"鬼仙": {
		"desc": "暴击率 +20%，最大生命 -20",
		"crit": 20.0, "max_hp": -20,
		"flavor": "阴神不散，出窍夺舍。",
	},
	"人仙": {
		"desc": "最大生命 +60 并回满，减伤 8%",
		"max_hp": 60, "armor": 8, "heal": true,
		"flavor": "长生久视，肉身不坏。",
	},
	"地仙": {
		"desc": "减伤 12%，最大生命 +40，移速 -20",
		"armor": 12, "max_hp": 40, "speed": -20.0,
		"flavor": "住世长生，不慕飞升。",
	},
}

# 仙阶修为需求：[仙道→神仙, 神仙→天仙]
const IMMORTAL_XP := [550, 650]

# 各仙阶可选的功法
const IMMORTAL_SKILLS := {
	"神仙": ["阳神御剑", "不坏仙躯", "咫尺天涯"],
	"天仙": ["万剑朝宗", "太虚不灭", "逍遥无极"],
}

# 妖兽数组（阶段 9：同屏多只）
# 每只妖兽是一个 Dictionary：type/pos/speed/size/max_hp/hp/hit_flash
# 同屏妖兽上限（v0.8.0：随波次增长）
const BASE_MAX_ENEMIES := 5

var enemies: Array[Dictionary] = []

# ==========================================
# 修为晶石（v0.8.0）：击杀掉落后需靠近拾取
# ==========================================
const ORB_ATTRACT_RADIUS := 150.0
const ORB_PICKUP_RADIUS := 30.0
const ORB_LIFETIME := 30.0
const ORB_MAX_COUNT := 200
const ORB_MERGE_RADIUS := 40.0
const ORB_FLY_SPEED := 420.0

var orbs: Array[Dictionary] = []

# 自动攻击属性
var attack_range: float = 420.0
var attack_damage: int = 20
var attack_interval: float = 0.55
var attack_cooldown: float = 0.0

# 剑气属性
var projectile_speed: float = 460.0
var projectile_size: float = 7.0
var projectile_lifetime: float = 1.5
var projectile_positions: Array[Vector2] = []
var projectile_directions: Array[Vector2] = []
var projectile_damages: Array[int] = []
var projectile_lifetimes: Array[float] = []
var projectile_is_critical: Array[bool] = []
var projectile_elements: Array[String] = []

# 修为与境界
var kill_count: int = 0
var cultivation: int = 0
var realm_index: int = 0        # 凡人境界索引 0..9
var stage_index: int = 0        # 0=初期 1=中期 2=圆满
var upgrade_pending: bool = false

# 仙道（阶段 9 第二刀）
var immortal_path: String = ""      # 鬼仙/人仙/地仙，空=未证道
var immortal_stage: int = 0         # 0=凡人 1=仙道 2=神仙 3=天仙
var path_choice_pending: bool = false
var path_choices: Array[Dictionary] = []

# 功法加成
var sword_bonus: int = 0
var damage_reduction: float = 0.0   # 受伤减免百分比（0.0 ~ 0.7）
var speed_bonus: float = 0.0
var crit_bonus: float = 0.0     # 暴击率加成（百分点，如 5 表示 +5%）
var hp_regen: float = 0.0       # 每秒生命回复

# 法器（v0.11.0）
var artifacts: Array[String] = []           # 已装备法器名
var artifact_drop_pending: bool = false
var artifact_choices: Array[Dictionary] = []
var xp_bonus: float = 0.0                   # 修为获取加成（百分比）
var kill_heal: int = 0                      # 击杀回血
var low_hp_armor: float = 0.0               # 低血减伤（额外）
var crit_dmg_bonus: float = 0.0             # 暴击伤害加成

# 属性法术（v0.9.0）
var sword_element: String = "none"   # 当前剑气元素
var extra_shots: int = 0             # 额外剑气道数
var pierce: bool = false             # 剑气穿透

# 三选一功法
var skill_choices: Array[Dictionary] = []
var learned_skills: Array[String] = []

# 游戏界面
var screen_size: Vector2 = Vector2(960, 600)
var camera_offset: Vector2 = Vector2.ZERO   # 世界坐标 → 屏幕坐标的偏移
var ui_scale: float = 1.0                   # UI 缩放（小窗口自动缩小）
var distance_traveled: float = 0.0          # 累计移动距离（保留，暂不参与计算）
var message_timer: float = 0.0
var message_text: String = ""

# 关卡流程（阶段 10）
var wave: int = 1                 # 1..5，6=首领战
var wave_kills: int = 0
var run_time: float = 0.0
var game_won: bool = false
var boss_active: bool = false

# 劫难系统（阶段 11）
var tribulation_pending: bool = false       # 劫难战进行中
var tribulation_reward_pending: bool = false
var tribulation_name: String = ""
var tribulation_count: int = 0              # 第几劫
var tribulation_reward_choices: Array[Dictionary] = []
var pending_realm_advance: bool = false     # 劫难打赢后再推进境界


func _ready() -> void:
	randomize()
	screen_size = get_viewport_rect().size
	player_pos = Vector2.ZERO
	update_camera()
	reset_enemies()
	queue_redraw()


func _process(delta: float) -> void:
	screen_size = get_viewport_rect().size
	# UI 自适应：窗口小于 1100 宽时按比例缩小
	ui_scale = clampf(screen_size.x / 1280.0, 0.65, 1.0)

	if is_game_over:
		queue_redraw()
		return

	if upgrade_pending or path_choice_pending or tribulation_reward_pending or artifact_drop_pending:
		queue_redraw()
		return

	run_time += delta

	damage_cooldown = maxf(0.0, damage_cooldown - delta)

	# 生命回复
	if hp_regen > 0.0 and player_hp < player_max_hp:
		player_hp = mini(player_max_hp, player_hp + int(ceil(hp_regen * delta)))

	for e in enemies:
		e["hit_flash"] = maxf(0.0, float(e["hit_flash"]) - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	message_timer = maxf(0.0, message_timer - delta)

	update_player(delta)
	update_camera()
	update_enemies(delta)
	update_projectiles(delta)
	update_orbs(delta)
	update_auto_attack()

	queue_redraw()


# ==========================================
# 玩家移动
# ==========================================

# 摄像机跟随：玩家始终在屏幕中心
func update_camera() -> void:
	camera_offset = screen_size / 2.0 - player_pos


# 世界坐标 → 屏幕坐标
func w2s(p: Vector2) -> Vector2:
	return p + camera_offset


# 屏幕坐标 → 世界坐标
func s2w(p: Vector2) -> Vector2:
	return p - camera_offset


func update_player(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		direction.x += 1.0

	if direction.length() > 0.0:
		direction = direction.normalized()

	var current_speed := player_speed + speed_bonus
	var move_vec := direction * current_speed * delta
	player_pos += move_vec

	# 无限地图：累计移动距离，用于提升同屏妖兽数量
	distance_traveled += move_vec.length()


# ==========================================
# 妖兽移动与接触伤害
# ==========================================

func update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var e: Dictionary = enemies[i]

		# 灼烧结算
		if e.has("burn") and float(e.get("burn_timer", 0.0)) > 0.0:
			e["burn_timer"] = float(e["burn_timer"]) - delta
			e["hp"] = int(e["hp"]) - int(e.get("burn", 0))
			if int(e["hp"]) <= 0:
				kill_enemy(i)
				continue
			if float(e["burn_timer"]) <= 0.0:
				e.erase("burn")
				e.erase("burn_timer")

		# 减速结算
		var speed_mul := 1.0
		if e.has("slow") and float(e.get("slow_timer", 0.0)) > 0.0:
			speed_mul = float(e["slow"])
			e["slow_timer"] = float(e["slow_timer"]) - delta
			if float(e["slow_timer"]) <= 0.0:
				e.erase("slow")
				e.erase("slow_timer")

		var direction: Vector2 = player_pos - e["pos"]
		var distance := direction.length()

		if distance > 0.001:
			e["pos"] = e["pos"] + direction.normalized() * float(e["speed"]) * speed_mul * delta

		var contact_distance := (player_size + float(e["size"])) / 2.0

		if distance < contact_distance and damage_cooldown <= 0.0:
			var enemy_damage: int = int(e.get("damage", ENEMY_TYPES[e["type"]]["damage"]))
			var reduction: float = clampf(damage_reduction, 0.0, 0.7)

			# 不灭灯：生命低于 30% 时额外减伤
			if low_hp_armor > 0.0 and float(player_hp) / float(player_max_hp) < 0.3:
				reduction = clampf(reduction + low_hp_armor / 100.0, 0.0, 0.85)
			var actual_damage := maxi(1, int(round(float(enemy_damage) * (1.0 - reduction))))
			player_hp -= actual_damage
			damage_cooldown = 0.8

			message_text = "受到伤害 -" + str(actual_damage)
			message_timer = 0.5

			if player_hp <= 0:
				player_hp = 0
				is_game_over = true


# ==========================================
# 自动寻找妖兽并发射剑气
# ==========================================

func update_auto_attack() -> void:
	if attack_cooldown > 0.0:
		return

	# 锁定射程内最近的妖兽
	var target: Dictionary = {}
	var best_distance := attack_range

	for e in enemies:
		var d: float = (e["pos"] as Vector2).distance_to(player_pos)
		if d < best_distance:
			best_distance = d
			target = e

	if target.is_empty():
		return

	var direction: Vector2 = (target["pos"] as Vector2) - player_pos

	if direction.length() <= 0.001:
		return

	fire_sword_energy(direction.normalized())
	attack_cooldown = attack_interval


func fire_sword_energy(direction: Vector2) -> void:
	var shots: int = 1 + extra_shots

	for i in range(shots):
		var d := direction

		# 多重剑气：扇形散开
		if shots > 1:
			var spread := 0.18 * float(i - (shots - 1) / 2.0)
			d = direction.rotated(spread)

		var damage: int = attack_damage + sword_bonus
		var is_critical: bool = randf() < (0.15 + crit_bonus / 100.0)

		if is_critical:
			damage = int(float(damage) * (2.0 + crit_dmg_bonus))

		projectile_positions.append(player_pos + d * 18.0)
		projectile_directions.append(d)
		projectile_damages.append(damage)
		projectile_lifetimes.append(projectile_lifetime)
		projectile_is_critical.append(is_critical)
		projectile_elements.append(sword_element)

# ==========================================
# 剑气飞行、命中与消失
# ==========================================

func update_projectiles(delta: float) -> void:
	for i in range(projectile_positions.size() - 1, -1, -1):
		projectile_positions[i] += projectile_directions[i] * projectile_speed * delta
		projectile_lifetimes[i] -= delta

		# 找被这一发剑气命中的妖兽（取最近的一只）
		var hit_index := -1
		var hit_distance_best := 1e20

		for j in range(enemies.size()):
			var e: Dictionary = enemies[j]
			var reach: float = (float(e["size"]) / 2.0) + projectile_size
			var d: float = projectile_positions[i].distance_to(e["pos"])

			if d <= reach and d < hit_distance_best:
				hit_distance_best = d
				hit_index = j

		if hit_index >= 0:
			var element: String = projectile_elements[i] if i < projectile_elements.size() else "none"
			var damage: int = projectile_damages[i]
			var is_critical: bool = projectile_is_critical[i]

			apply_hit(hit_index, damage, is_critical, element)

			# 穿透：不消耗剑气
			if not pierce:
				projectile_positions.remove_at(i)
				projectile_directions.remove_at(i)
				projectile_damages.remove_at(i)
				projectile_lifetimes.remove_at(i)
				projectile_is_critical.remove_at(i)
				if i < projectile_elements.size():
					projectile_elements.remove_at(i)
			else:
				# 穿透时同一只不重复命中，简单处理为剑气消失
				projectile_positions.remove_at(i)
				projectile_directions.remove_at(i)
				projectile_damages.remove_at(i)
				projectile_lifetimes.remove_at(i)
				projectile_is_critical.remove_at(i)
				if i < projectile_elements.size():
					projectile_elements.remove_at(i)

			continue

		var p := projectile_positions[i]
		# 无限地图：超出视野较远才消失
		var outside_screen := p.distance_to(player_pos) > maxf(screen_size.x, screen_size.y) * 1.2

		if projectile_lifetimes[i] <= 0.0 or outside_screen:
			projectile_positions.remove_at(i)
			projectile_directions.remove_at(i)
			projectile_damages.remove_at(i)
			projectile_lifetimes.remove_at(i)
			if i < projectile_elements.size():
				projectile_elements.remove_at(i)


# 对某只妖兽造成伤害并施加元素效果
func apply_hit(index: int, damage: int, is_critical: bool, element: String) -> void:
	if index < 0 or index >= enemies.size():
		return

	var e: Dictionary = enemies[index]
	e["hp"] = int(e["hp"]) - damage
	e["hit_flash"] = 0.12

	# 元素效果
	match element:
		"fire":
			e["burn"] = 8
			e["burn_timer"] = 3.0
		"ice":
			e["slow"] = 0.65
			e["slow_timer"] = 2.0
		"wind":
			var dir: Vector2 = (e["pos"] as Vector2) - player_pos
			if dir.length() > 0.001:
				e["pos"] = (e["pos"] as Vector2) + dir.normalized() * 60.0
		"thunder":
			if randf() < 0.20:
				chain_thunder(index, damage)

	if is_critical:
		message_text = "暴击！伤害 -" + str(damage)
	else:
		message_text = "剑气命中 -" + str(damage)

	message_timer = 0.6

	# 首领阶段推进
	if str(e["type"]) == "boss" and int(e["hp"]) > 0:
		check_boss_phase(e)

	if int(e["hp"]) <= 0:
		kill_enemy(index)


# 首领三阶段：70% / 40% 血量时强化
func check_boss_phase(e: Dictionary) -> void:
	var ratio := float(e["hp"]) / float(e["max_hp"])
	var phase := int(e.get("phase", 1))

	if phase < 2 and ratio <= 0.70:
		e["phase"] = 2
		e["speed"] = float(e.get("base_speed", 30.0)) * 1.3
		e["damage"] = int(float(e.get("base_damage", 60)) * 1.25)
		message_text = "★ 魔道老祖狂暴！速度与伤害提升"
		message_timer = 2.5
	elif phase < 3 and ratio <= 0.40:
		e["phase"] = 3
		e["speed"] = float(e.get("base_speed", 30.0)) * 1.6
		e["damage"] = int(float(e.get("base_damage", 60)) * 1.6)
		message_text = "★ 魔道老祖拼命了！"
		message_timer = 2.5


# 雷霆连锁：对 200px 内另一只造成一半伤害
func chain_thunder(origin_index: int, damage: int) -> void:
	var origin: Dictionary = enemies[origin_index]
	var target_index := -1
	var best := 200.0

	for j in range(enemies.size()):
		if j == origin_index:
			continue
		var d: float = (enemies[j]["pos"] as Vector2).distance_to(origin["pos"])
		if d < best:
			best = d
			target_index = j

	if target_index < 0:
		return

	var t: Dictionary = enemies[target_index]
	var chain_dmg: int = maxi(1, damage / 2)
	t["hp"] = int(t["hp"]) - chain_dmg
	t["hit_flash"] = 0.12

	if int(t["hp"]) <= 0:
		kill_enemy(target_index)


# ==========================================
# 妖兽死亡、修为奖励与重生
# ==========================================

# ==========================================
# 修为晶石：掉落、合并、吸附、拾取
# ==========================================

# 在指定位置掉落修为晶石（同位置附近自动合并）
func spawn_orb(pos: Vector2, value: int) -> void:
	if value <= 0:
		return

	# 先尝试合并到附近已有的晶石
	for o in orbs:
		if (o["pos"] as Vector2).distance_to(pos) <= ORB_MERGE_RADIUS:
			o["value"] = int(o["value"]) + value
			o["life"] = ORB_LIFETIME
			return

	# 数量上限：超了直接吸收最老的
	if orbs.size() >= ORB_MAX_COUNT:
		var oldest: Dictionary = orbs[0]
		cultivation += int(oldest["value"])
		orbs.remove_at(0)

	orbs.append({
		"pos": pos,
		"value": value,
		"life": ORB_LIFETIME,
	})


# 每帧更新晶石：吸附、拾取、超时
func update_orbs(delta: float) -> void:
	for i in range(orbs.size() - 1, -1, -1):
		var o: Dictionary = orbs[i]
		o["life"] = float(o["life"]) - delta

		var pos: Vector2 = o["pos"]
		var dist := pos.distance_to(player_pos)

		# 超时自动吸收
		if float(o["life"]) <= 0.0:
			cultivation += int(round(float(o["value"]) * (1.0 + xp_bonus / 100.0)))
			orbs.remove_at(i)
			continue

		# 拾取
		if dist <= ORB_PICKUP_RADIUS:
			var gained := int(round(float(o["value"]) * (1.0 + xp_bonus / 100.0)))
			cultivation += gained
			orbs.remove_at(i)
			check_level_up()
			continue

		# 吸附飞行
		if dist <= ORB_ATTRACT_RADIUS:
			var dir := (player_pos - pos).normalized()
			var speed := ORB_FLY_SPEED * (1.0 + (ORB_ATTRACT_RADIUS - dist) / ORB_ATTRACT_RADIUS)
			o["pos"] = pos + dir * speed * delta


# 待拾取修为总数
func get_pending_xp() -> int:
	var total := 0
	for o in orbs:
		total += int(o["value"])
	return total


# 修为变化后检查是否升级
func check_level_up() -> void:
	if is_max_realm():
		cultivation = mini(cultivation, get_next_level_xp())
		return

	if upgrade_pending or path_choice_pending or tribulation_reward_pending or tribulation_pending:
		return

	if cultivation >= get_next_level_xp():
		cultivation -= get_next_level_xp()
		begin_upgrade()


func kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return

	var e: Dictionary = enemies[index]
	var reward: int = int(e.get("reward", ENEMY_TYPES[e["type"]]["reward"]))
	var enemy_name: String = str(ENEMY_TYPES[e["type"]]["name"])
	var is_elite: bool = bool(e.get("elite", false))
	var is_boss: bool = (str(e["type"]) == "boss")

	var drop_pos: Vector2 = e["pos"]

	enemies.remove_at(index)
	kill_count += 1

	# 噬魂幡：击杀回血
	if kill_heal > 0 and not is_boss:
		player_hp = mini(player_max_hp, player_hp + kill_heal)

	# 修为改为掉落晶石，需玩家靠近拾取
	spawn_orb(drop_pos, reward)

	if is_boss:
		message_text = "★ 击败 " + enemy_name + "！"
		message_timer = 3.0
		boss_active = false
		game_won = true
		is_game_over = true
		return

	message_text = ("精英·" if is_elite else "") + "击败" + enemy_name + "！修为掉落 " + str(reward)
	message_timer = 1.0

	# 波次仅作记录：累计击杀数，满 20 只记一波
	wave_kills += 1
	if wave_kills >= WAVE_KILLS_PER_WAVE:
		wave_kills = 0
		wave += 1
		message_text = "第 " + str(wave) + " 波"
		message_timer = 1.5

	# 劫难战：全部清完则结算
	if tribulation_pending:
		if enemies.is_empty():
			finish_tribulation()
		return

	# 仙道选择界面：不补怪
	if path_choice_pending:
		return

	# 精英 15% 概率掉法器
	if is_elite and artifacts.size() < MAX_ARTIFACTS and randf() < 0.15:
		roll_artifact_choices()

	# 升级由晶石拾取时触发，这里只补怪
	refill_enemies()


# 按等级加权随机选择妖兽类型
func pick_enemy_type() -> String:
	var level_bonus: int = mini(get_progress(), 6)

	var golem_weight: int = mini(15 + level_bonus * 5, 45)
	var bird_weight: int = mini(30 + level_bonus * 2, 40)
	var wolf_weight: int = maxi(100 - golem_weight - bird_weight, 10)

	var total: int = golem_weight + bird_weight + wolf_weight
	var roll: int = randi_range(1, total)

	if roll <= wolf_weight:
		return "wolf"
	if roll <= wolf_weight + bird_weight:
		return "bird"
	return "golem"


# 生成一只妖兽并加入数组
# elite: 精英（波次 3/5 出现，血厚伤高奖励翻倍）
func spawn_enemy(elite: bool = false) -> void:
	var type_name: String = pick_enemy_type()
	var data: Dictionary = ENEMY_TYPES[type_name]

	# 在屏幕内随机位置生成（避开玩家周围的安全区）
	var margin := 70.0
	var safe_radius := 180.0   # 不在玩家身边直接刷出来
	var pos := Vector2.ZERO

	for attempt in range(20):
		var screen_x := randf_range(margin, screen_size.x - margin)
		var screen_y := randf_range(margin, screen_size.y - margin)
		var candidate := s2w(Vector2(screen_x, screen_y))

		if candidate.distance_to(player_pos) >= safe_radius:
			pos = candidate
			break
		pos = candidate   # 兜底：最后一次结果

	var max_hp: int = int(data["max_hp"])
	var size: float = float(data["size"])
	var reward: int = int(data["reward"])
	var damage: int = int(data["damage"])
	var speed: float = float(data["speed"])

	# 随境界成长：血量 +35%/境，伤害 +25%/境，移速 +12%/境
	var progress := float(get_progress()) / 3.0
	max_hp = int(float(max_hp) * (1.0 + progress * 0.35))
	damage = int(float(damage) * (1.0 + progress * 0.25))
	speed = float(data["speed"]) * (1.0 + progress * 0.12)

	if elite:
		max_hp = int(max_hp * ELITE_HP_MUL)
		size *= ELITE_SIZE_MUL
		reward = int(reward * ELITE_REWARD_MUL)
		damage = int(damage * ELITE_DMG_MUL)

	enemies.append({
		"type": type_name,
		"pos": pos,
		"speed": speed,
		"size": size,
		"max_hp": max_hp,
		"hp": max_hp,
		"hit_flash": 0.0,
		"elite": elite,
		"damage": damage,
		"reward": reward,
	})


# 生成首领（单独一只，不补普通妖兽）
# 估算玩家当前 DPS（用于首领动态血量）
func estimate_player_dps() -> float:
	var per_hit := float(attack_damage + sword_bonus)
	var crit_rate := clampf(0.15 + crit_bonus / 100.0, 0.0, 1.0)
	var avg_hit := per_hit * (1.0 + crit_rate)      # 暴击 ×2 的期望
	var interval := maxf(0.1, attack_interval)
	return avg_hit / interval * float(1 + extra_shots)


# 飞升试炼：达到天仙后自动触发（原由波次触发）
func spawn_boss() -> void:
	var data: Dictionary = ENEMY_TYPES["boss"]
	enemies.clear()
	# 动态血量：按玩家 DPS 反推，目标约 25 秒击杀
	var dps := estimate_player_dps()
	# 目标约 25 秒击杀；绝对下限 1500（防秒杀），上限 200000
	var boss_hp := int(clampf(dps * 25.0, 1500.0, 200000.0))

	enemies.append({
		"type": "boss",
		"pos": player_pos + Vector2(0, -260),
		"speed": float(data["speed"]),
		"size": float(data["size"]),
		"max_hp": boss_hp,
		"hp": boss_hp,
		"hit_flash": 0.0,
		"elite": false,
		"damage": int(data["damage"]),
		"reward": int(data["reward"]),
		"phase": 1,
		"base_speed": float(data["speed"]),
		"base_damage": int(data["damage"]),
	})
	boss_active = true
	message_text = "★ 魔道老祖降临！血量 " + str(boss_hp)
	message_timer = 3.0


# 当前波次名称（仅记录）
func get_wave_name() -> String:
	return "第 " + str(wave) + " 波"


# 本波进度（0.0 ~ 1.0，仅记录）
func get_wave_progress() -> float:
	return clampf(float(wave_kills) / float(WAVE_KILLS_PER_WAVE), 0.0, 1.0)


# 同屏上限：基础 5，随波次增长，封顶 12 只
# 同屏上限 = 基础 + 波次成长 + 移动距离成长，封顶 30
# 每移动 2000px 多 1 只，最多贡献 +8 只
func get_max_enemies() -> int:
	var wave_bonus := (wave - 1) / 2
	# 时长成长：每 60 秒 +1 只，最多 +8 只
	var time_bonus := mini(int(run_time / 60.0), 8)
	return mini(BASE_MAX_ENEMIES + wave_bonus + time_bonus, 30)


# 补满到当前上限（首领战不补）
func refill_enemies() -> void:
	if boss_active or tribulation_pending or tribulation_reward_pending:
		return

	# 第 3 波起每 2 波出现精英，后期密度提升
	var allow_elite: bool = (wave >= 3 and wave % 2 == 1)

	while enemies.size() < get_max_enemies():
		spawn_enemy(allow_elite and randf() < 0.4)


# 清空并重新铺满（重开 / 升级后）
func reset_enemies() -> void:
	enemies.clear()
	refill_enemies()


# ==========================================
# 升级与随机功法三选一
# ==========================================

# 当前境界名称，如「炼精化炁」
func get_realm_name() -> String:
	if immortal_stage == 1:
		return immortal_path
	if immortal_stage == 2:
		return "神仙"
	if immortal_stage >= 3:
		return "天仙"
	return str(REALMS[realm_index]["name"])


# 当前小阶名称，如「中期」
func get_stage_name() -> String:
	if immortal_stage >= 1:
		return ""
	return str(STAGE_NAMES[stage_index])


# 完整境界，如「炼精·中期」或「鬼仙」
func get_full_realm_name() -> String:
	if immortal_stage >= 1:
		return get_realm_name()
	return get_realm_name() + "·" + get_stage_name()


# 升到下一阶段需要的修为
func get_next_level_xp() -> int:
	if immortal_stage == 0:
		return int(REALMS[realm_index]["xp"][stage_index])
	if immortal_stage == 1:
		return int(IMMORTAL_XP[0])      # 仙道 → 神仙
	if immortal_stage == 2:
		return int(IMMORTAL_XP[1])      # 神仙 → 天仙
	return 999999                        # 天仙封顶


# 总进度，用于妖兽难度
func get_progress() -> int:
	if immortal_stage >= 1:
		return 30 + (immortal_stage - 1) * 3
	return realm_index * 3 + stage_index


# 当前阶段可选功法池
func get_current_skill_pool() -> Array:
	if immortal_stage == 1:
		return IMMORTAL_SKILLS["神仙"]
	if immortal_stage == 2:
		return IMMORTAL_SKILLS["天仙"]
	return REALMS[realm_index]["skills"]


# 是否已到封顶（天仙）
func is_max_realm() -> bool:
	return immortal_stage >= 3


# 是否已证仙道
func is_immortal() -> bool:
	return immortal_stage >= 1


func begin_upgrade() -> void:
	upgrade_pending = true

	var pool: Array = get_current_skill_pool()
	var picked: Array = pool.duplicate()
	picked.shuffle()

	skill_choices = []

	for i in range(mini(3, picked.size())):
		var skill_name: String = str(picked[i])
		var data: Dictionary = SKILLS[skill_name]
		skill_choices.append({
			"name": skill_name,
			"description": str(data["desc"]),
		})


# 应用一个功法的效果（支持单效果与 multi 多效果）
func apply_skill_effect(skill_name: String) -> void:
	var data: Dictionary = SKILLS[skill_name]
	var stat: String = str(data["stat"])

	if stat == "multi":
		for eff in data["effects"]:
			apply_stat(str(eff["stat"]), float(eff["value"]))
		return

	# 属性法术：切换剑气元素
	if stat == "element":
		sword_element = str(data["element"])
		# 罡风剑气额外 +1 道
		if str(data["element"]) == "wind":
			extra_shots += 1
		return

	apply_stat(stat, float(data["value"]))


# 装备一件法器（应用效果）
func equip_artifact(name: String) -> void:
	if not ARTIFACTS.has(name):
		return
	if artifacts.has(name):
		return
	if artifacts.size() >= MAX_ARTIFACTS:
		return

	artifacts.append(name)
	var data: Dictionary = ARTIFACTS[name]
	apply_stat(str(data["stat"]), float(data["value"]))

	message_text = "获得法器：" + name
	message_timer = 2.0


# 随机抽 3 件未拥有的法器作为候选
func roll_artifact_choices() -> void:
	var pool: Array = []
	for k in ARTIFACTS.keys():
		if not artifacts.has(k):
			pool.append(k)

	artifact_choices.clear()
	pool.shuffle()

	for i in range(mini(3, pool.size())):
		var k: String = str(pool[i])
		var d: Dictionary = ARTIFACTS[k]
		artifact_choices.append({
			"name": k,
			"rarity": str(d["rarity"]),
			"desc": str(d["desc"]),
		})

	if artifact_choices.size() > 0:
		artifact_drop_pending = true


# 选择法器
func choose_artifact(index: int) -> void:
	if not artifact_drop_pending:
		return
	if index < 0 or index >= artifact_choices.size():
		return

	var chosen: Dictionary = artifact_choices[index]
	equip_artifact(str(chosen["name"]))
	artifact_drop_pending = false
	artifact_choices.clear()


# 单项属性加成
func apply_stat(stat: String, value: float) -> void:
	match stat:
		"sword":
			sword_bonus += int(value)
		"armor":
			damage_reduction = minf(0.7, damage_reduction + value / 100.0)
		"speed":
			# 软上限：超过 600 后收益减半，避免后期失控
			var current_total := player_speed + speed_bonus
			if current_total >= 600.0:
				speed_bonus += value * 0.5
			else:
				speed_bonus += value
		"crit":
			crit_bonus = minf(100.0, crit_bonus + value)
		"max_hp":
			player_max_hp += int(value)
			player_hp = mini(player_hp + maxi(0, int(value)), player_max_hp)
			if value > 0:
				player_hp = player_max_hp   # 提升上限时回满
		"attack_speed":
			attack_interval = maxf(0.1, attack_interval - value)
		"range":
			attack_range += value
		"regen":
			hp_regen += value
		"element":
			sword_element = str(value)   # value 由调用方传元素名
		"extra_shot":
			extra_shots += int(value)
		"xp_bonus":
			xp_bonus += value
		"kill_heal":
			kill_heal += int(value)
		"low_hp_armor":
			low_hp_armor += value
		"crit_dmg":
			crit_dmg_bonus += value


func choose_skill(index: int) -> void:
	if not upgrade_pending:
		return

	if index < 0 or index >= skill_choices.size():
		return

	var chosen: Dictionary = skill_choices[index]
	var skill_name: String = chosen["name"]

	apply_skill_effect(skill_name)
	learned_skills.append(skill_name)

	upgrade_pending = false
	message_text = "习得功法：" + skill_name
	message_timer = 1.5

	# 破境前先打劫难
	if should_trigger_tribulation():
		begin_tribulation()
		return

	advance_realm()
	after_advance()


# ==========================================
# 劫难战
# ==========================================

# 判断该境界破境时是否触发劫难（合道→仙道不触发）
func should_trigger_tribulation() -> bool:
	if immortal_stage >= 1:
		return false
	return stage_index >= STAGE_NAMES.size() - 1 and realm_index < REALMS.size() - 1


# 随机选一个劫难类型
func pick_tribulation_type() -> String:
	# 化神（index 5）之后才用雷劫/心魔/三尸
	if realm_index >= 5:
		return str(LATE_TRIBULATIONS[randi_range(0, LATE_TRIBULATIONS.size() - 1)])
	return "strong"


# 开始劫难战
func begin_tribulation() -> void:
	var tname: String = pick_tribulation_type()
	var data: Dictionary = TRIBULATIONS[tname]

	tribulation_name = str(data["name"])
	tribulation_count += 1
	tribulation_pending = true
	pending_realm_advance = true

	var count: int = randi_range(int(data["min"]), int(data["max"]))

	enemies.clear()

	for i in range(count):
		var base_type: String = pick_enemy_type()
		var base: Dictionary = ENEMY_TYPES[base_type]

		var angle := TAU * float(i) / float(count) + randf() * 0.5
		var dist := 260.0
		var pos: Vector2 = player_pos + Vector2(cos(angle), sin(angle)) * dist

		var hp := int(float(base["max_hp"]) * float(data["hp"]))

		enemies.append({
			"type": base_type,
			"pos": pos,
			"speed": float(base["speed"]) * 0.9,
			"size": float(base["size"]) * float(data["size"]),
			"max_hp": hp,
			"hp": hp,
			"hit_flash": 0.0,
			"elite": true,
			"damage": int(float(base["damage"]) * float(data["dmg"])),
			"reward": int(float(base["reward"]) * 3.0),
			"tribulation": true,
			"trib_color": str(data["color"]),
		})

	message_text = "★ " + tribulation_name + " 降临！"
	message_timer = 3.0


# 劫难全部打完 → 给奖励三选一
func finish_tribulation() -> void:
	tribulation_pending = false
	tribulation_reward_pending = true

	tribulation_reward_choices.clear()
	for r in TRIBULATION_REWARDS:
		tribulation_reward_choices.append({
			"name": str(r["name"]),
			"desc": str(r["desc"]),
		})


# 选择劫难奖励
func choose_tribulation_reward(index: int) -> void:
	if not tribulation_reward_pending:
		return
	if index < 0 or index >= tribulation_reward_choices.size():
		return

	var r: Dictionary = TRIBULATION_REWARDS[index]
	apply_stat(str(r["stat"]), float(r["value"]) if r["stat"] != "multi" else 0.0)

	if str(r["stat"]) == "multi":
		for eff in r["effects"]:
			apply_stat(str(eff["stat"]), float(eff["value"]))

	tribulation_reward_pending = false
	message_text = "劫难奖励：" + str(r["name"])
	message_timer = 2.0

	# 20% 额外掉法器
	if artifacts.size() < MAX_ARTIFACTS and randf() < 0.20:
		roll_artifact_choices()

	# 奖励选完才真正推进境界
	if pending_realm_advance:
		pending_realm_advance = false
		advance_realm()
		after_advance()


# 推进境界（凡人 → 仙道 → 神仙 → 天仙）
func advance_realm() -> void:
	# 仙阶：神仙 → 天仙 → 封顶
	if immortal_stage >= 1:
		immortal_stage = mini(immortal_stage + 1, 3)

		# 达到天仙 → 飞升试炼（首领战）
		if immortal_stage >= 3:
			message_text = "天仙已成！魔道老祖现世，破之则飞升！"
			message_timer = 3.0
			spawn_boss()
		return

	stage_index += 1

	if stage_index < STAGE_NAMES.size():
		return

	stage_index = 0
	realm_index += 1

	# 凡人十境走完 → 仙道三选一
	if realm_index >= REALMS.size():
		realm_index = REALMS.size() - 1
		stage_index = STAGE_NAMES.size() - 1
		begin_path_choice()


# 升级后：检查是否连续升级，否则补怪
func after_advance() -> void:
	if not is_max_realm() and cultivation >= get_next_level_xp():
		cultivation -= get_next_level_xp()
		begin_upgrade()
		return

	refill_enemies()


# ==========================================
# 仙道三选一
# ==========================================

func begin_path_choice() -> void:
	path_choice_pending = true
	path_choices.clear()

	for key in IMMORTAL_PATHS.keys():
		var d: Dictionary = IMMORTAL_PATHS[key]
		path_choices.append({
			"name": key,
			"desc": str(d["desc"]),
			"flavor": str(d["flavor"]),
		})


func choose_path(index: int) -> void:
	if not path_choice_pending:
		return

	if index < 0 or index >= path_choices.size():
		return

	var chosen: Dictionary = path_choices[index]
	var path_name: String = chosen["name"]
	var d: Dictionary = IMMORTAL_PATHS[path_name]

	immortal_path = path_name
	immortal_stage = 1
	path_choice_pending = false

	if d.has("crit"):
		crit_bonus = minf(100.0, crit_bonus + float(d["crit"]))
	if d.has("armor"):
		damage_reduction = minf(0.7, damage_reduction + float(d["armor"]) / 100.0)
	if d.has("max_hp"):
		player_max_hp += int(d["max_hp"])
		if bool(d.get("heal", false)):
			player_hp = player_max_hp
		else:
			player_hp = mini(player_hp, player_max_hp)
	if d.has("speed"):
		speed_bonus += float(d["speed"])

	message_text = "证道" + path_name + "！"
	message_timer = 2.0

	refill_enemies()


# ==========================================
# 键盘 / 鼠标操作：升级选择、重开游戏
# ==========================================

# 功法卡片的矩形范围（绘制和点击共用，避免两处坐标不一致）
func get_skill_card_rect(index: int) -> Rect2:
	var w := 400.0 * ui_scale
	var h := 54.0 * ui_scale
	var gap := 66.0 * ui_scale
	var card_y := screen_size.y / 2.0 - 45.0 * ui_scale + float(index) * gap
	return Rect2(
		Vector2(screen_size.x / 2.0 - w / 2.0, card_y),
		Vector2(w, h)
	)


# 仙道卡片矩形（比功法卡片高，因为有道途说明）
func get_path_card_rect(index: int) -> Rect2:
	var card_h := 74.0 * ui_scale
	var gap := 8.0 * ui_scale
	var w := 500.0 * ui_scale
	var total := 3.0 * card_h + 2.0 * gap
	var start_y := screen_size.y / 2.0 - total / 2.0 + 26.0 * ui_scale
	return Rect2(
		Vector2(screen_size.x / 2.0 - w / 2.0, start_y + float(index) * (card_h + gap)),
		Vector2(w, card_h)
	)


func get_path_index_at(pos: Vector2) -> int:
	if not path_choice_pending:
		return -1
	for i in range(path_choices.size()):
		if get_path_card_rect(i).has_point(pos):
			return i
	return -1


func get_hovered_path_index() -> int:
	if not path_choice_pending:
		return -1
	return get_path_index_at(get_viewport().get_mouse_position())


# 劫难奖励卡片（复用功法卡片几何）
func get_reward_card_rect(index: int) -> Rect2:
	return get_skill_card_rect(index)


func get_reward_index_at(pos: Vector2) -> int:
	if not tribulation_reward_pending:
		return -1
	for i in range(tribulation_reward_choices.size()):
		if get_reward_card_rect(i).has_point(pos):
			return i
	return -1


func get_hovered_reward_index() -> int:
	if not tribulation_reward_pending:
		return -1
	return get_reward_index_at(get_viewport().get_mouse_position())


# 法器卡片（复用功法卡片几何）
func get_artifact_card_rect(index: int) -> Rect2:
	return get_skill_card_rect(index)


func get_artifact_index_at(pos: Vector2) -> int:
	if not artifact_drop_pending:
		return -1
	for i in range(artifact_choices.size()):
		if get_artifact_card_rect(i).has_point(pos):
			return i
	return -1


func get_hovered_artifact_index() -> int:
	if not artifact_drop_pending:
		return -1
	return get_artifact_index_at(get_viewport().get_mouse_position())


# 某个坐标点落在哪张卡片上，-1 表示没有
func get_skill_index_at(pos: Vector2) -> int:
	if not upgrade_pending:
		return -1

	for i in range(skill_choices.size()):
		if get_skill_card_rect(i).has_point(pos):
			return i

	return -1


# 鼠标当前悬停在哪张卡片上，-1 表示没有
func get_hovered_skill_index() -> int:
	if not upgrade_pending:
		return -1

	return get_skill_index_at(get_viewport().get_mouse_position())


func _input(event: InputEvent) -> void:
	# 鼠标点击选择（功法或仙道）
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if upgrade_pending:
			var index := get_skill_index_at(event.position)
			if index >= 0:
				choose_skill(index)
				get_viewport().set_input_as_handled()
		elif path_choice_pending:
			var pindex := get_path_index_at(event.position)
			if pindex >= 0:
				choose_path(pindex)
				get_viewport().set_input_as_handled()
		elif tribulation_reward_pending:
			var rindex := get_reward_index_at(event.position)
			if rindex >= 0:
				choose_tribulation_reward(rindex)
				get_viewport().set_input_as_handled()
		elif artifact_drop_pending:
			var aindex := get_artifact_index_at(event.position)
			if aindex >= 0:
				choose_artifact(aindex)
				get_viewport().set_input_as_handled()
		return

	# 鼠标移动时刷新悬停高亮
	if event is InputEventMouseMotion and (upgrade_pending or path_choice_pending or tribulation_reward_pending or artifact_drop_pending):
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if is_game_over:
			if event.keycode == KEY_R:
				restart_game()
			return

		if upgrade_pending:
			match event.keycode:
				KEY_1:
					choose_skill(0)
				KEY_2:
					choose_skill(1)
				KEY_3:
					choose_skill(2)

		if path_choice_pending:
			match event.keycode:
				KEY_1:
					choose_path(0)
				KEY_2:
					choose_path(1)
				KEY_3:
					choose_path(2)

		if tribulation_reward_pending:
			match event.keycode:
				KEY_1:
					choose_tribulation_reward(0)
				KEY_2:
					choose_tribulation_reward(1)
				KEY_3:
					choose_tribulation_reward(2)

		if artifact_drop_pending:
			match event.keycode:
				KEY_1:
					choose_artifact(0)
				KEY_2:
					choose_artifact(1)
				KEY_3:
					choose_artifact(2)


func restart_game() -> void:
	player_max_hp = 100
	player_hp = player_max_hp
	player_pos = Vector2.ZERO
	update_camera()
	damage_cooldown = 0.0
	is_game_over = false

	kill_count = 0
	cultivation = 0
	wave = 1
	wave_kills = 0
	run_time = 0.0
	game_won = false
	boss_active = false

	distance_traveled = 0.0

	artifacts.clear()
	artifact_drop_pending = false
	artifact_choices.clear()
	xp_bonus = 0.0
	kill_heal = 0
	low_hp_armor = 0.0
	crit_dmg_bonus = 0.0

	tribulation_pending = false
	tribulation_reward_pending = false
	tribulation_name = ""
	tribulation_count = 0
	tribulation_reward_choices.clear()
	pending_realm_advance = false
	realm_index = 0
	stage_index = 0
	immortal_path = ""
	immortal_stage = 0
	path_choice_pending = false
	path_choices.clear()

	attack_interval = 0.55
	attack_range = 420.0
	hp_regen = 0.0

	sword_bonus = 0
	damage_reduction = 0.0
	speed_bonus = 0.0
	crit_bonus = 0.0

	upgrade_pending = false
	skill_choices.clear()
	learned_skills.clear()

	projectile_positions.clear()
	projectile_directions.clear()
	projectile_damages.clear()
	projectile_lifetimes.clear()
	projectile_is_critical.clear()
	orbs.clear()

	attack_cooldown = 0.0
	message_timer = 0.0
	message_text = ""

	reset_enemies()


# ==========================================
# 绘制游戏画面
# ==========================================

func _draw() -> void:
	# 秘境背景（铺满视口）
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#173d32"))

	# 地面纹理：按世界坐标计算可视范围，无限滚动
	var grid: float = 48.0
	var start_x: float = floorf((player_pos.x - screen_size.x / 2.0) / grid) * grid
	var start_y: float = floorf((player_pos.y - screen_size.y / 2.0) / grid) * grid

	var gx := start_x
	while gx < player_pos.x + screen_size.x / 2.0 + grid:
		var gy := start_y
		while gy < player_pos.y + screen_size.y / 2.0 + grid:
			var sp := w2s(Vector2(gx + 20.0, gy + 20.0))
			draw_rect(Rect2(sp, Vector2(2, 2)), Color("#285344"))
			gy += grid
		gx += grid

	# 妖兽（遍历数组绘制每一只）
	for e in enemies:
		var pos: Vector2 = w2s(e["pos"])
		var size: float = float(e["size"])

		var enemy_color: Color = ENEMY_TYPES[e["type"]]["color"]

		# 劫难敌人用专属颜色
		if e.has("trib_color"):
			enemy_color = Color(str(e["trib_color"]))

		if float(e["hit_flash"]) > 0.0:
			enemy_color = Color.WHITE

		draw_rect(
			Rect2(pos - Vector2.ONE * size / 2.0, Vector2.ONE * size),
			enemy_color
		)

		# 血条
		var bar_width := maxf(54.0, size + 12.0)
		var bar_pos := pos + Vector2(-bar_width / 2.0, -size / 2.0 - 20.0)
		draw_rect(Rect2(bar_pos, Vector2(bar_width, 6)), Color("#421c31"))

		var hp_ratio := float(e["hp"]) / float(e["max_hp"])
		draw_rect(
			Rect2(bar_pos, Vector2(bar_width * hp_ratio, 6)),
			Color("#f05276")
		)

		# 名字
		draw_string(
			ThemeDB.fallback_font,
			pos + Vector2(-30.0, -size / 2.0 - 26.0),
			(str(ENEMY_TYPES[e["type"]]["name"]) if not e.has("tribulation") else "劫·" + str(ENEMY_TYPES[e["type"]]["name"])),
			HORIZONTAL_ALIGNMENT_CENTER,
			90,
			14,
			Color("#ff9b4a") if e.has("tribulation") else Color("#e8d8ff")
		)

	# 修为晶石
	for o in orbs:
		var op: Vector2 = w2s(o["pos"])
		var val := int(o["value"])

		# 数值越大越亮、越大
		var orb_size := clampf(4.0 + float(val) / 12.0, 4.0, 11.0)
		var glow := clampf(float(val) / 60.0, 0.25, 1.0)

		if val >= 50:
			draw_circle(op, orb_size * 2.2, Color(0.45, 0.85, 1.0, 0.18 * glow))

		draw_rect(
			Rect2(op - Vector2.ONE * orb_size / 2.0, Vector2.ONE * orb_size),
			Color(0.55, 0.9, 1.0, 0.55 + 0.45 * glow)
		)
		draw_rect(
			Rect2(op - Vector2.ONE * orb_size / 4.0, Vector2.ONE * orb_size / 2.0),
			Color(1, 1, 1, 0.8)
		)

	# 玩家
	var player_color := Color("#45e5df")

	if damage_cooldown > 0.0:
		player_color = Color("#ffffff")

	var psp := w2s(player_pos)
	draw_rect(
		Rect2(psp - Vector2.ONE * player_size / 2.0, Vector2.ONE * player_size),
		player_color
	)

	# 剑气弹幕
	for i in range(projectile_positions.size()):
		var p: Vector2 = w2s(projectile_positions[i])
		var d: Vector2 = projectile_directions[i]
		var tail := p - d * 18.0
		var tip := p + d * 7.0

		var elem := "none"
		if i < projectile_elements.size():
			elem = projectile_elements[i]
		var pcolor := Color("#42f5ff")
		if ELEMENTS.has(elem):
			pcolor = Color(str(ELEMENTS[elem]["color"]))

		draw_line(tail, tip, pcolor, 5.0, true)
		draw_circle(p, projectile_size, Color("#d5ffff"))

	# 玩家生命条
	draw_string(
		ThemeDB.fallback_font,
		Vector2(20, 30),
		"生命：" + str(player_hp) + " / " + str(player_max_hp),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.WHITE
	)

	draw_rect(Rect2(Vector2(20, 40), Vector2(180, 10)), Color("#421c31"))
	draw_rect(
		Rect2(Vector2(20, 40), Vector2(180.0 * float(player_hp) / float(player_max_hp), 10)),
		Color("#48df91")
	)

	# 修为与等级
	draw_string(
		ThemeDB.fallback_font,
		Vector2(20, 78),
		"境界：" + get_full_realm_name() + "   修为：" + str(cultivation) + " / " + str(get_next_level_xp()),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color.WHITE
	)

	if get_pending_xp() > 0:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(20, screen_size.y - 44.0),
			"待拾取修为：" + str(get_pending_xp()),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color("#7fd8ff")
		)

	# 法器栏
	if artifacts.size() > 0:
		var art_text := "法器："
		for a in artifacts:
			art_text += "[" + str(a) + "] "
		draw_string(
			ThemeDB.fallback_font,
			Vector2(20, screen_size.y - 70.0),
			art_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			15,
			Color("#ffd76e")
		)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(20, 105),
		"击败妖兽：" + str(kill_count),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color.WHITE
	)

	# 波次与时间
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	var hud_title := get_wave_name()
	if tribulation_pending:
		hud_title = "★ " + tribulation_name

	draw_string(
		ThemeDB.fallback_font,
		Vector2(screen_size.x - 260.0, 30),
		hud_title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#ffd76e") if boss_active else Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(screen_size.x - 260.0, 56),
		"时间 %02d:%02d" % [mins, secs],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#b9f5d7")
	)

	# 波次进度条
	if not boss_active:
		draw_rect(Rect2(Vector2(screen_size.x - 260.0, 68), Vector2(180, 8)), Color("#421c31"))
		draw_rect(
			Rect2(Vector2(screen_size.x - 260.0, 68), Vector2(180.0 * get_wave_progress(), 8)),
			Color("#ffd76e")
		)

	# 当前功法加成
	draw_string(
		ThemeDB.fallback_font,
		Vector2(20, 132),
		"剑气 +" + str(sword_bonus)
		+ "  减伤 " + str(int(round(damage_reduction * 100.0))) + "%"
		+ "  移速 +" + str(int(speed_bonus))
		+ "  暴击 +" + str(int(crit_bonus)) + "%",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#b9f5d7")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(20, screen_size.y - 18),
		"WASD / 方向键移动",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#d4e9dc")
	)

	# 临时提示
	if message_timer > 0.0:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 100.0, 70),
			message_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			200,
			20,
			Color("#fff1a8")
		)

	# 法器选择界面（金色主题）
	if artifact_drop_pending:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.10, 0.08, 0.02, 0.9))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 - 130.0),
			"✦ 获 得 法 器 ✦",
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			32,
			Color("#ffd76e")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 - 96.0),
			"已装备 " + str(artifacts.size()) + " / " + str(MAX_ARTIFACTS),
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			16,
			Color("#d4c090")
		)

		for i in range(artifact_choices.size()):
			var ac := get_artifact_card_rect(i)
			var ahev := (i == get_hovered_artifact_index())

			if ahev:
				draw_rect(ac, Color("#5a4a1a"))
				draw_rect(ac, Color("#ffd76e"), false, 3.0)
			else:
				draw_rect(ac, Color("#3a3010"))
				draw_rect(ac, Color("#b89a3a"), false, 2.0)

			var art: Dictionary = artifact_choices[i]

			draw_string(
				ThemeDB.fallback_font,
				Vector2(ac.position.x + 14.0, ac.position.y + 24.0),
				str(i + 1) + ". [" + str(art["rarity"]) + "] " + str(art["name"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				370,
				18,
				Color("#ffd76e")
			)

			draw_string(
				ThemeDB.fallback_font,
				Vector2(ac.position.x + 14.0, ac.position.y + 45.0),
				str(art["desc"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				370,
				15,
				Color.WHITE
			)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 180.0, screen_size.y / 2.0 + 185.0),
			"按键盘 1、2、3 或用鼠标点击选择",
			HORIZONTAL_ALIGNMENT_CENTER,
			360,
			18,
			Color("#ffd76e")
		)

	# 劫难奖励界面（暗红主题）
	if tribulation_reward_pending:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.12, 0.02, 0.02, 0.9))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 - 120.0),
			"✦ 渡 劫 成 功 ✦",
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			32,
			Color("#ff9b4a")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 - 86.0),
			tribulation_name + " · 第 " + str(tribulation_count) + " 劫",
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			18,
			Color("#ffd0a0")
		)

		for i in range(tribulation_reward_choices.size()):
			var rc := get_reward_card_rect(i)
			var rhov := (i == get_hovered_reward_index())

			if rhov:
				draw_rect(rc, Color("#5a2a1a"))
				draw_rect(rc, Color("#ff9b4a"), false, 3.0)
			else:
				draw_rect(rc, Color("#3a1a12"))
				draw_rect(rc, Color("#c46a3a"), false, 2.0)

			var rw: Dictionary = tribulation_reward_choices[i]

			draw_string(
				ThemeDB.fallback_font,
				Vector2(rc.position.x + 14.0, rc.position.y + 24.0),
				str(i + 1) + ". " + str(rw["name"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				370,
				18,
				Color("#ffd0a0")
			)

			draw_string(
				ThemeDB.fallback_font,
				Vector2(rc.position.x + 14.0, rc.position.y + 45.0),
				str(rw["desc"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				370,
				15,
				Color.WHITE
			)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 180.0, screen_size.y / 2.0 + 185.0),
			"按键盘 1、2、3 或用鼠标点击选择",
			HORIZONTAL_ALIGNMENT_CENTER,
			360,
			18,
			Color("#ff9b4a")
		)

	# 升级界面
	if upgrade_pending:
		draw_rect(
			Rect2(Vector2.ZERO, screen_size),
			Color(0, 0, 0, 0.72)
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 180.0, screen_size.y / 2.0 - 100.0),
			"【" + get_full_realm_name() + "】选择一门功法",
			HORIZONTAL_ALIGNMENT_CENTER,
			360,
			26,
			Color("#ffe9a6")
		)

		for i in range(skill_choices.size()):
			var card_rect := get_skill_card_rect(i)
			var hovered := (i == get_hovered_skill_index())

			# 悬停时卡片变亮、边框变金色
			if hovered:
				draw_rect(card_rect, Color("#3d6f68"))
				draw_rect(card_rect, Color("#ffe9a6"), false, 3.0)
			else:
				draw_rect(card_rect, Color("#294d48"))
				draw_rect(card_rect, Color("#69d9c5"), false, 2.0)

			var skill: Dictionary = skill_choices[i]
			var line_text := str(i + 1) + ". " + str(skill["name"]) + " — " + str(skill["description"])

			draw_string(
				ThemeDB.fallback_font,
				Vector2(card_rect.position.x + 14.0, card_rect.position.y + 33.0),
				line_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				370,
				17,
				Color("#fff7d6") if hovered else Color.WHITE
			)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 180.0, screen_size.y / 2.0 + 185.0),
			"按键盘 1、2、3 或用鼠标点击选择",
			HORIZONTAL_ALIGNMENT_CENTER,
			360,
			18,
			Color("#ffe9a6")
		)

	# 仙道三选一界面（紫色主题，与普通升级区分）
	if path_choice_pending:
		draw_rect(
			Rect2(Vector2.ZERO, screen_size),
			Color(0.08, 0.02, 0.12, 0.88)
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 220.0, screen_size.y / 2.0 - 190.0),
			"✦ 仙 道 抉 择 ✦",
			HORIZONTAL_ALIGNMENT_CENTER,
			440,
			34,
			Color("#ffd76e")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 220.0, screen_size.y / 2.0 - 150.0),
			"合道 · 圆满  →  证道成仙",
			HORIZONTAL_ALIGNMENT_CENTER,
			440,
			20,
			Color("#e0c8ff")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 220.0, screen_size.y / 2.0 - 122.0),
			"此择不可逆，慎之。",
			HORIZONTAL_ALIGNMENT_CENTER,
			440,
			16,
			Color("#b89ad6")
		)

		for i in range(path_choices.size()):
			var card := get_path_card_rect(i)
			var hovered := (i == get_hovered_path_index())

			if hovered:
				draw_rect(card, Color("#3a2050"))
				draw_rect(card, Color("#ffd76e"), false, 3.0)
			else:
				draw_rect(card, Color("#241433"))
				draw_rect(card, Color("#8f6bb5"), false, 2.0)

			var pc: Dictionary = path_choices[i]

			draw_string(
				ThemeDB.fallback_font,
				Vector2(card.position.x + 18.0, card.position.y + 30.0),
				str(i + 1) + ". " + str(pc["name"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				460,
				24,
				Color("#ffd76e") if hovered else Color("#ffe9b0")
			)

			draw_string(
				ThemeDB.fallback_font,
				Vector2(card.position.x + 18.0, card.position.y + 54.0),
				str(pc["desc"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				460,
				16,
				Color.WHITE
			)

			draw_string(
				ThemeDB.fallback_font,
				Vector2(card.position.x + 18.0, card.position.y + 74.0),
				str(pc["flavor"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				460,
				14,
				Color("#b89ad6")
			)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 + 200.0),
			"按键盘 1、2、3 或用鼠标点击选择",
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			18,
			Color("#ffd76e")
		)

	# 结算界面（胜利 / 失败）
	if is_game_over:
		draw_rect(
			Rect2(Vector2.ZERO, screen_size),
			Color(0, 0, 0, 0.82) if not game_won else Color(0.10, 0.06, 0.02, 0.88)
		)

		var title := "飞升成仙！" if game_won else "修仙失败！"
		var title_color := Color("#ffd76e") if game_won else Color("#ff6b83")

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 - 60.0),
			title,
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			40,
			title_color
		)

		if game_won:
			draw_string(
				ThemeDB.fallback_font,
				Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 - 20.0),
				"击破魔道老祖，位列" + get_full_realm_name(),
				HORIZONTAL_ALIGNMENT_CENTER,
				400,
				20,
				Color("#ffe9a6")
			)

		var mins2 := int(run_time) / 60
		var secs2 := int(run_time) % 60

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 + 20.0),
			"击败妖兽：" + str(kill_count) + "   最终境界：" + get_full_realm_name(),
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			20,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 + 52.0),
			"用时 %02d:%02d   到达 %s" % [mins2, secs2, get_wave_name()],
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			18,
			Color("#b9f5d7")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 200.0, screen_size.y / 2.0 + 100.0),
			"按 R 键重新开始",
			HORIZONTAL_ALIGNMENT_CENTER,
			400,
			22,
			Color("#ffe9a6")
		)
