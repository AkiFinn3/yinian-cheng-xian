extends RefCounted

# ==========================================
# 《一念成仙》数据表（从 main.gd 拆分）
# 所有数值集中在此文件，便于调整与查阅
# ==========================================

# ---- 妖兽与劫难 ----
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
const ELEMENTS := {
	"none":    {"name": "",       "color": "#42f5ff"},
	"fire":    {"name": "烈焰",   "color": "#ff6b35"},
	"ice":     {"name": "寒冰",   "color": "#6bc8ff"},
	"thunder": {"name": "雷霆",   "color": "#c77dff"},
	"wind":    {"name": "罡风",   "color": "#9dffb0"},
}
const ELEMENT_SKILLS := {
	"烈焰剑气": {"element": "fire",    "desc": "剑气附带灼烧：每秒 -8 血，持续 3 秒"},
	"寒冰剑气": {"element": "ice",     "desc": "剑气附带减速 35%，持续 2 秒"},
	"雷霆剑气": {"element": "thunder", "desc": "20% 概率连锁到 200px 内另一只"},
	"罡风剑气": {"element": "wind",    "desc": "击退 60px，且剑气 +1 道"},
}
const BASE_MAX_ENEMIES := 5
const ELITE_HP_MUL := 1.6
const ELITE_DMG_MUL := 1.6
const ELITE_SIZE_MUL := 1.25
const ELITE_REWARD_MUL := 2
const TRIBULATIONS := {
	"strong":  {"name": "强敌劫",   "min": 1, "max": 2, "hp": 3.0, "dmg": 1.8, "size": 1.3, "color": "#a83232"},
	"thunder": {"name": "天罚雷劫", "min": 1, "max": 1, "hp": 4.0, "dmg": 2.5, "size": 1.2, "color": "#4a6fd4"},
	"demon":   {"name": "心魔劫",   "min": 1, "max": 1, "hp": 5.0, "dmg": 1.5, "size": 1.15, "color": "#7a2f8f"},
	"three":   {"name": "斩三尸",   "min": 3, "max": 3, "hp": 3.5, "dmg": 1.7, "size": 1.0, "color": "#2f7a5f"},
}
const LATE_TRIBULATIONS := ["thunder", "demon", "three"]
const TRIBULATION_REWARDS := [
	{"name": "道基稳固", "desc": "最大生命 +40 并回满", "stat": "max_hp", "value": 40},
	{"name": "杀伐果断", "desc": "剑气伤害 +50", "stat": "sword", "value": 50},
	{"name": "身法通玄", "desc": "移速 +60，攻击间隔 -0.05 秒", "stat": "multi",
		"effects": [{"stat": "speed", "value": 30}, {"stat": "attack_speed", "value": 0.05}]},
]

# ---- 境界与功法 ----
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
const IMMORTAL_XP := [550, 650]
const IMMORTAL_SKILLS := {
	"神仙": ["阳神御剑", "不坏仙躯", "咫尺天涯"],
	"天仙": ["万剑朝宗", "太虚不灭", "逍遥无极"],
}

# ---- 法器 / 符箓 / 飞剑 / 阵法 ----
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
const TALISMANS := {
	"火球符": {"desc": "火球爆炸 60 伤害", "type": "fireball", "value": 60},
	"冰封符": {"desc": "冻结全场 1.5 秒",  "type": "freeze",   "value": 1.5},
	"雷击符": {"desc": "全场 40 伤害",     "type": "thunder",  "value": 40},
	"护身符": {"desc": "3 秒无敌",         "type": "shield",   "value": 3.0},
	"疾行符": {"desc": "3 秒移速 +150%",   "type": "haste",    "value": 3.0},
	"聚灵符": {"desc": "吸收全场修为晶石", "type": "gather",   "value": 0},
}
const MAX_TALISMANS := 5
const FORMATIONS := {
	"聚灵阵": {"desc": "阵内修为 +50%",     "radius": 180.0, "type": "xp",     "value": 50.0},
	"杀阵":   {"desc": "阵内妖兽 15 伤/秒", "radius": 160.0, "type": "damage", "value": 15.0},
	"护体阵": {"desc": "阵内减伤 +40%",     "radius": 150.0, "type": "armor",  "value": 40.0},
	"疾风阵": {"desc": "阵内移速 +80%",     "radius": 200.0, "type": "haste",  "value": 80.0},
}
const MAX_FORMATIONS := 2
const FORMATION_LIFETIME := 15.0
const FLYING_SWORDS := {
	"一叶飞剑": {"desc": "直线穿透，伤害 ×3", "count": 1,  "spread": 0.0,  "mul": 3.0,  "pierce": true},
	"三才剑阵": {"desc": "3 道扇形，伤害 ×2", "count": 3,  "spread": 0.35, "mul": 2.0,  "pierce": false},
	"万剑归宗": {"desc": "12 道环形，伤害 ×2", "count": 12, "spread": 0.0,  "mul": 2.0,  "pierce": false},
	"斩仙飞刀": {"desc": "巨型剑气，伤害 ×10", "count": 1,  "spread": 0.0,  "mul": 10.0, "pierce": true},
}
const SWORD_UNLOCK := {
	"筑基": "一叶飞剑",
	"化炁": "三才剑阵",
	"炼神": "万剑归宗",
	"天仙": "斩仙飞刀",
}

# ---- 修为晶石与波次 ----
const ORB_ATTRACT_RADIUS := 150.0
const ORB_PICKUP_RADIUS := 30.0
const ORB_LIFETIME := 30.0
const ORB_MAX_COUNT := 200
const ORB_MERGE_RADIUS := 40.0
const ORB_FLY_SPEED := 420.0
const WAVE_KILLS_PER_WAVE := 20

# ---- HUD 尺寸 ----
const HUD_BAR_H := 26.0       # 修为条高度
const HUD_ICON_SIZE := 44.0   # 技能图标边长
const HUD_ICON_GAP := 8.0

# ---- 障碍物（v0.16.0）----
# block: 是否阻挡玩家/妖兽/剑气；breakable: 能否被打碎；hits: 需要几下
const OBSTACLES := {
	"rock": {
		"name": "岩石",
		"block": true,
		"breakable": false,
		"hits": 0,
		"radius": 34.0,
		"color": "#4a4a52",
		"edge": "#63636e",
		"heal": 0,
		"weight": 45,
	},
	"tree": {
		"name": "古木",
		"block": true,
		"breakable": true,
		"hits": 3,
		"radius": 30.0,
		"color": "#4a3520",
		"edge": "#2e5c34",
		"heal": 0,
		"weight": 35,
	},
	"herb": {
		"name": "灵草",
		"block": false,
		"breakable": true,
		"hits": 1,
		"radius": 18.0,
		"color": "#2e6b3a",
		"edge": "#6fd8a0",
		"heal": 5,
		"weight": 20,
	},
}

# 障碍物生成：按格子坐标哈希，同一格永远同一种
# 一屏 1280×720 约能容纳 (1280/260)×(720/260) ≈ 4.9×2.8 = 13.6 格
# 30% 概率 → 一屏约 4 个障碍物（v0.16.1 从 400 格 20% 调整，原一屏仅 1.15 个）
const OBSTACLE_GRID := 260.0
const OBSTACLE_CHANCE := 0.30

# ---- 场景主题（v0.16.0）----
# 飞升前 6 个凡俗场景按境界切换；飞升后转天界，天仙入魔界
const SCENES := {
	"山门初境": {"bg": "#173d32", "dot": "#285344", "name": "山门初境"},
	"幽谷灵泉": {"bg": "#123a3a", "dot": "#1e5050", "name": "幽谷灵泉"},
	"赤岩火脉": {"bg": "#3a1f1a", "dot": "#542e26", "name": "赤岩火脉"},
	"罡风荒原": {"bg": "#3a3220", "dot": "#54492e", "name": "罡风荒原"},
	"寒潭冰窟": {"bg": "#1a2a3a", "dot": "#284056", "name": "寒潭冰窟"},
	"太虚星海": {"bg": "#221a3a", "dot": "#352a54", "name": "太虚星海"},
	"天界云海": {"bg": "#3a3320", "dot": "#564c30", "name": "天界云海"},
	"天界云海·极": {"bg": "#4a4028", "dot": "#6b5d3a", "name": "天界云海·极"},
	"魔界深渊": {"bg": "#1a0f1a", "dot": "#2e1a2e", "name": "魔界深渊"},
}

# 境界索引 → 场景名（0-4 各自专属，5-9 共用太虚星海）
const REALM_SCENES := [
	"山门初境", "幽谷灵泉", "赤岩火脉", "罡风荒原", "寒潭冰窟",
	"太虚星海", "太虚星海", "太虚星海", "太虚星海", "太虚星海",
]
