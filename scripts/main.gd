
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
		"speed": 75.0,
		"max_hp": 100,
		"damage": 10,
		"reward": 10,
	},
	"bird": {
		"name": "疾风雀",
		"color": Color("#d9a441"),
		"size": 24.0,
		"speed": 145.0,
		"max_hp": 55,
		"damage": 6,
		"reward": 8,
	},
	"golem": {
		"name": "岩甲兽",
		"color": Color("#8c4a2f"),
		"size": 52.0,
		"speed": 45.0,
		"max_hp": 180,
		"damage": 16,
		"reward": 25,
	},
	"boss": {
		"name": "魔道老祖",
		"color": Color("#c1121f"),
		"size": 110.0,
		"speed": 30.0,
		"max_hp": 3000,
		"damage": 30,
		"reward": 200,
	},
}

# ==========================================
# 关卡流程（阶段 10）：5 波 + 首领
# ==========================================
const WAVE_TARGETS := [8, 12, 16, 20, 24]
const MAX_WAVES := 5
const ELITE_HP_MUL := 1.6
const ELITE_DMG_MUL := 1.4
const ELITE_SIZE_MUL := 1.25
const ELITE_REWARD_MUL := 2

# ==========================================
# 境界体系（阶段 9）
# 凡人十境，每境初期/中期/圆满；xp 是「升到下一小阶」所需修为
# ==========================================
const REALMS := [
	{
		"name": "炼己",
		"xp": [30, 40, 50],
		"skills": ["剑气诀", "护体灵气", "疾风步", "凝神"],
	},
	{
		"name": "筑基",
		"xp": [60, 70, 80],
		"skills": ["御剑术", "金钟罩", "踏云步", "心眼"],
	},
	{
		"name": "炼精",
		"xp": [90, 100, 115],
		"skills": ["精元剑气", "精血护体", "精行步", "精觉"],
	},
	{
		"name": "化炁",
		"xp": [125, 140, 150],
		"skills": ["炁冲剑脉", "炁盾", "罡气行云", "炁感"],
	},
	{
		"name": "炼炁",
		"xp": [160, 175, 190],
		"skills": ["炁御剑", "炁墙", "缩地成寸", "炁视"],
	},
	{
		"name": "化神",
		"xp": [205, 220, 235],
		"skills": ["神识御剑", "神念护体", "神行术", "神觉"],
	},
	{
		"name": "炼神",
		"xp": [255, 275, 295],
		"skills": ["炼神剑意", "神元护体", "踏虚而行", "洞神"],
	},
	{
		"name": "返虚",
		"xp": [315, 335, 360],
		"skills": ["虚空剑意", "返虚护体", "返虚游", "洞虚"],
	},
	{
		"name": "炼虚",
		"xp": [385, 410, 435],
		"skills": ["虚剑破空", "虚元金身", "逍遥游", "虚瞳"],
	},
	{
		"name": "合道",
		"xp": [460, 490, 525],
		"skills": ["大道剑诀", "合道金身", "天地同游", "天眼"],
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
	"护体灵气":   {"desc": "减伤 +4",        "stat": "armor", "value": 4},
	"疾风步":     {"desc": "移速 +25",       "stat": "speed", "value": 25},
	"凝神":       {"desc": "暴击率 +5%",     "stat": "crit",  "value": 5},
	# ---- 筑基 ----
	"御剑术":     {"desc": "剑气伤害 +18",   "stat": "sword", "value": 18},
	"金钟罩":     {"desc": "减伤 +10",       "stat": "armor", "value": 10},
	"踏云步":     {"desc": "移速 +45",       "stat": "speed", "value": 45},
	"心眼":       {"desc": "暴击率 +10%",    "stat": "crit",  "value": 10},
	# ---- 炼精 ----
	"精元剑气":   {"desc": "剑气伤害 +26",   "stat": "sword", "value": 26},
	"精血护体":   {"desc": "减伤 +13",       "stat": "armor", "value": 13},
	"精行步":     {"desc": "移速 +60",       "stat": "speed", "value": 60},
	"精觉":       {"desc": "暴击率 +13%",    "stat": "crit",  "value": 13},
	# ---- 化炁 ----
	"炁冲剑脉":   {"desc": "剑气伤害 +36",   "stat": "sword", "value": 36},
	"炁盾":       {"desc": "减伤 +18",       "stat": "armor", "value": 18},
	"罡气行云":   {"desc": "移速 +80",       "stat": "speed", "value": 80},
	"炁感":       {"desc": "暴击率 +17%",    "stat": "crit",  "value": 17},
	# ---- 炼炁 ----
	"炁御剑":     {"desc": "剑气伤害 +48",   "stat": "sword", "value": 48},
	"炁墙":       {"desc": "减伤 +24",       "stat": "armor", "value": 24},
	"缩地成寸":   {"desc": "移速 +105",      "stat": "speed", "value": 105},
	"炁视":       {"desc": "暴击率 +22%",    "stat": "crit",  "value": 22},
	# ---- 化神 ----
	"神识御剑":   {"desc": "剑气伤害 +62",   "stat": "sword", "value": 62},
	"神念护体":   {"desc": "减伤 +30",       "stat": "armor", "value": 30},
	"神行术":     {"desc": "移速 +130",      "stat": "speed", "value": 130},
	"神觉":       {"desc": "暴击率 +27%",    "stat": "crit",  "value": 27},
	# ---- 炼神 ----
	"炼神剑意":   {"desc": "剑气伤害 +80",   "stat": "sword", "value": 80},
	"神元护体":   {"desc": "减伤 +38",       "stat": "armor", "value": 38},
	"踏虚而行":   {"desc": "移速 +160",      "stat": "speed", "value": 160},
	"洞神":       {"desc": "暴击率 +33%",    "stat": "crit",  "value": 33},
	# ---- 返虚 ----
	"虚空剑意":   {"desc": "剑气伤害 +100",  "stat": "sword", "value": 100},
	"返虚护体":   {"desc": "减伤 +46",       "stat": "armor", "value": 46},
	"返虚游":     {"desc": "移速 +195",      "stat": "speed", "value": 195},
	"洞虚":       {"desc": "暴击率 +39%",    "stat": "crit",  "value": 39},
	# ---- 炼虚 ----
	"虚剑破空":   {"desc": "剑气伤害 +125",  "stat": "sword", "value": 125},
	"虚元金身":   {"desc": "减伤 +56",       "stat": "armor", "value": 56},
	"逍遥游":     {"desc": "移速 +235",      "stat": "speed", "value": 235},
	"虚瞳":       {"desc": "暴击率 +46%",    "stat": "crit",  "value": 46},
	# ---- 合道 ----
	"大道剑诀":   {"desc": "剑气伤害 +155",  "stat": "sword", "value": 155},
	"合道金身":   {"desc": "减伤 +68",       "stat": "armor", "value": 68},
	"逍遥天地":   {"desc": "移速 +280",      "stat": "speed", "value": 280},
	"天眼":       {"desc": "暴击率 +54%",    "stat": "crit",  "value": 54},
	# ---- 神仙 ----
	"阳神御剑":   {"desc": "剑气 +200，暴击 +20%", "stat": "multi", "effects": [
		{"stat": "sword", "value": 200}, {"stat": "crit", "value": 20}]},
	"不坏仙躯":   {"desc": "最大生命 +120 并回满，减伤 +85", "stat": "multi", "effects": [
		{"stat": "max_hp", "value": 120}, {"stat": "armor", "value": 85}]},
	"咫尺天涯":   {"desc": "移速 +340，攻击间隔 -0.10 秒", "stat": "multi", "effects": [
		{"stat": "speed", "value": 340}, {"stat": "attack_speed", "value": 0.10}]},
	# ---- 天仙 ----
	"万剑朝宗":   {"desc": "剑气 +300，暴击 +30%", "stat": "multi", "effects": [
		{"stat": "sword", "value": 300}, {"stat": "crit", "value": 30}]},
	"太虚不灭":   {"desc": "最大生命 +200 并回满，减伤 +120", "stat": "multi", "effects": [
		{"stat": "max_hp", "value": 200}, {"stat": "armor", "value": 120}]},
	"天地同游":   {"desc": "移速 +450，攻击间隔 -0.15 秒", "stat": "multi", "effects": [
		{"stat": "speed", "value": 450}, {"stat": "attack_speed", "value": 0.15}]},
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
		"desc": "最大生命 +60 并回满，减伤 +10",
		"max_hp": 60, "armor": 10, "heal": true,
		"flavor": "长生久视，肉身不坏。",
	},
	"地仙": {
		"desc": "减伤 +25，最大生命 +40，移速 -20",
		"armor": 25, "max_hp": 40, "speed": -20.0,
		"flavor": "住世长生，不慕飞升。",
	},
}

# 仙阶修为需求：[仙道→神仙, 神仙→天仙]
const IMMORTAL_XP := [310, 380]

# 各仙阶可选的功法
const IMMORTAL_SKILLS := {
	"神仙": ["阳神御剑", "不坏仙躯", "咫尺天涯"],
	"天仙": ["万剑朝宗", "太虚不灭", "天地同游"],
}

# 妖兽数组（阶段 9：同屏多只）
# 每只妖兽是一个 Dictionary：type/pos/speed/size/max_hp/hp/hit_flash
const MAX_ENEMIES := 5
var enemies: Array[Dictionary] = []

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
var armor_reduction: int = 0
var speed_bonus: float = 0.0
var crit_bonus: float = 0.0     # 暴击率加成（百分点，如 5 表示 +5%）

# 三选一功法
var skill_choices: Array[Dictionary] = []
var learned_skills: Array[String] = []

# 游戏界面
var screen_size: Vector2 = Vector2(960, 600)
var message_timer: float = 0.0
var message_text: String = ""

# 关卡流程（阶段 10）
var wave: int = 1                 # 1..5，6=首领战
var wave_kills: int = 0
var run_time: float = 0.0
var game_won: bool = false
var boss_active: bool = false


func _ready() -> void:
	randomize()
	screen_size = get_viewport_rect().size
	player_pos = screen_size / 2.0
	reset_enemies()
	queue_redraw()


func _process(delta: float) -> void:
	screen_size = get_viewport_rect().size

	if is_game_over:
		queue_redraw()
		return

	if upgrade_pending or path_choice_pending:
		queue_redraw()
		return

	run_time += delta

	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	for e in enemies:
		e["hit_flash"] = maxf(0.0, float(e["hit_flash"]) - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	message_timer = maxf(0.0, message_timer - delta)

	update_player(delta)
	update_enemies(delta)
	update_projectiles(delta)
	update_auto_attack()

	queue_redraw()


# ==========================================
# 玩家移动
# ==========================================

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
	player_pos += direction * current_speed * delta

	var margin := player_size / 2.0
	player_pos.x = clampf(player_pos.x, margin, screen_size.x - margin)
	player_pos.y = clampf(player_pos.y, margin, screen_size.y - margin)


# ==========================================
# 妖兽移动与接触伤害
# ==========================================

func update_enemies(delta: float) -> void:
	for e in enemies:
		var direction: Vector2 = player_pos - e["pos"]
		var distance := direction.length()

		if distance > 0.001:
			e["pos"] = e["pos"] + direction.normalized() * float(e["speed"]) * delta

		var contact_distance := (player_size + float(e["size"])) / 2.0

		if distance < contact_distance and damage_cooldown <= 0.0:
			var enemy_damage: int = int(e.get("damage", ENEMY_TYPES[e["type"]]["damage"]))
			var actual_damage := maxi(1, enemy_damage - armor_reduction)
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
	var damage: int = attack_damage + sword_bonus
	var is_critical: bool = randf() < (0.15 + crit_bonus / 100.0)

	if is_critical:
		damage *= 2

	projectile_positions.append(player_pos + direction * 18.0)
	projectile_directions.append(direction)
	projectile_damages.append(damage)
	projectile_lifetimes.append(projectile_lifetime)
	projectile_is_critical.append(is_critical)

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
			var e: Dictionary = enemies[hit_index]
			var damage: int = projectile_damages[i]
			var is_critical: bool = projectile_is_critical[i]

			e["hp"] = int(e["hp"]) - damage
			e["hit_flash"] = 0.12

			if is_critical:
				message_text = "暴击！伤害 -" + str(damage)
			else:
				message_text = "剑气命中 -" + str(damage)

			message_timer = 0.6

			projectile_positions.remove_at(i)
			projectile_directions.remove_at(i)
			projectile_damages.remove_at(i)
			projectile_lifetimes.remove_at(i)
			projectile_is_critical.remove_at(i)

			if int(e["hp"]) <= 0:
				kill_enemy(hit_index)

			continue

		var p := projectile_positions[i]
		var outside_screen := (
			p.x < -20.0
			or p.x > screen_size.x + 20.0
			or p.y < -20.0
			or p.y > screen_size.y + 20.0
		)

		if projectile_lifetimes[i] <= 0.0 or outside_screen:
			projectile_positions.remove_at(i)
			projectile_directions.remove_at(i)
			projectile_damages.remove_at(i)
			projectile_lifetimes.remove_at(i)


# ==========================================
# 妖兽死亡、修为奖励与重生
# ==========================================

func kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return

	var e: Dictionary = enemies[index]
	var reward: int = int(e.get("reward", ENEMY_TYPES[e["type"]]["reward"]))
	var enemy_name: String = str(ENEMY_TYPES[e["type"]]["name"])
	var is_elite: bool = bool(e.get("elite", false))
	var is_boss: bool = (str(e["type"]) == "boss")

	enemies.remove_at(index)
	kill_count += 1
	cultivation += reward

	if is_boss:
		message_text = "★ 击败 " + enemy_name + "！"
		message_timer = 3.0
		boss_active = false
		game_won = true
		is_game_over = true
		return

	message_text = ("精英·" if is_elite else "") + "击败" + enemy_name + "！修为 +" + str(reward)
	message_timer = 1.0

	# 波次推进
	wave_kills += 1

	if wave_kills >= int(WAVE_TARGETS[mini(wave - 1, MAX_WAVES - 1)]):
		advance_wave()

	# 仙道选择界面：不补怪
	if path_choice_pending:
		return

	# 已封顶：修为停在阈值，不再触发升级
	if is_max_realm():
		cultivation = mini(cultivation, get_next_level_xp())
		refill_enemies()
		return

	if cultivation >= get_next_level_xp():
		cultivation -= get_next_level_xp()
		begin_upgrade()
		return

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

	var margin := 60.0
	var pos := Vector2.ZERO
	var side := randi_range(0, 3)

	match side:
		0:
			pos = Vector2(randf_range(margin, screen_size.x - margin), margin)
		1:
			pos = Vector2(randf_range(margin, screen_size.x - margin), screen_size.y - margin)
		2:
			pos = Vector2(margin, randf_range(margin, screen_size.y - margin))
		3:
			pos = Vector2(screen_size.x - margin, randf_range(margin, screen_size.y - margin))

	var max_hp: int = int(data["max_hp"])
	var size: float = float(data["size"])
	var reward: int = int(data["reward"])
	var damage: int = int(data["damage"])

	if elite:
		max_hp = int(max_hp * ELITE_HP_MUL)
		size *= ELITE_SIZE_MUL
		reward = int(reward * ELITE_REWARD_MUL)
		damage = int(damage * ELITE_DMG_MUL)

	enemies.append({
		"type": type_name,
		"pos": pos,
		"speed": float(data["speed"]),
		"size": size,
		"max_hp": max_hp,
		"hp": max_hp,
		"hit_flash": 0.0,
		"elite": elite,
		"damage": damage,
		"reward": reward,
	})


# 生成首领（单独一只，不补普通妖兽）
func spawn_boss() -> void:
	var data: Dictionary = ENEMY_TYPES["boss"]
	enemies.clear()
	enemies.append({
		"type": "boss",
		"pos": Vector2(screen_size.x / 2.0, 120.0),
		"speed": float(data["speed"]),
		"size": float(data["size"]),
		"max_hp": int(data["max_hp"]),
		"hp": int(data["max_hp"]),
		"hit_flash": 0.0,
		"elite": false,
		"damage": int(data["damage"]),
		"reward": int(data["reward"]),
	})
	boss_active = true


# 波次推进
func advance_wave() -> void:
	wave_kills = 0
	wave += 1

	if wave > MAX_WAVES:
		# 5 波打完 → 首领战
		wave = MAX_WAVES + 1
		message_text = "魔道老祖现世！"
		message_timer = 3.0
		spawn_boss()
		return

	message_text = "第 " + str(wave) + " 波来袭！"
	message_timer = 2.0
	reset_enemies()


# 当前波次名称
func get_wave_name() -> String:
	if boss_active or wave > MAX_WAVES:
		return "首领战"
	return "第 " + str(wave) + " / " + str(MAX_WAVES) + " 波"


# 本波进度（0.0 ~ 1.0）
func get_wave_progress() -> float:
	if boss_active or wave > MAX_WAVES:
		return 1.0
	var target: int = int(WAVE_TARGETS[mini(wave - 1, MAX_WAVES - 1)])
	return clampf(float(wave_kills) / float(target), 0.0, 1.0)


# 补满到 MAX_ENEMIES 只（首领战不补）
func refill_enemies() -> void:
	if boss_active:
		return

	# 第 3、5 波带精英
	var allow_elite: bool = (wave == 3 or wave == 5)

	while enemies.size() < MAX_ENEMIES:
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

	if str(data["stat"]) == "multi":
		for eff in data["effects"]:
			apply_stat(str(eff["stat"]), float(eff["value"]))
		return

	apply_stat(str(data["stat"]), float(data["value"]))


# 单项属性加成
func apply_stat(stat: String, value: float) -> void:
	match stat:
		"sword":
			sword_bonus += int(value)
		"armor":
			armor_reduction += int(value)
		"speed":
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

	advance_realm()
	after_advance()


# 推进境界（凡人 → 仙道 → 神仙 → 天仙）
func advance_realm() -> void:
	# 仙阶：神仙 → 天仙 → 封顶
	if immortal_stage >= 1:
		immortal_stage = mini(immortal_stage + 1, 3)
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
		armor_reduction += int(d["armor"])
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
	var card_y := screen_size.y / 2.0 - 45.0 + float(index) * 66.0
	return Rect2(
		Vector2(screen_size.x / 2.0 - 200.0, card_y),
		Vector2(400, 54)
	)


# 仙道卡片矩形（比功法卡片高，因为有道途说明）
func get_path_card_rect(index: int) -> Rect2:
	var card_h := 74.0
	var gap := 8.0
	var total := 3.0 * card_h + 2.0 * gap
	var start_y := screen_size.y / 2.0 - total / 2.0 + 26.0
	return Rect2(
		Vector2(screen_size.x / 2.0 - 250.0, start_y + float(index) * (card_h + gap)),
		Vector2(500, card_h)
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
		return

	# 鼠标移动时刷新悬停高亮
	if event is InputEventMouseMotion and (upgrade_pending or path_choice_pending):
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


func restart_game() -> void:
	player_max_hp = 100
	player_hp = player_max_hp
	player_pos = screen_size / 2.0
	damage_cooldown = 0.0
	is_game_over = false

	kill_count = 0
	cultivation = 0
	wave = 1
	wave_kills = 0
	run_time = 0.0
	game_won = false
	boss_active = false
	realm_index = 0
	stage_index = 0
	immortal_path = ""
	immortal_stage = 0
	path_choice_pending = false
	path_choices.clear()

	attack_interval = 0.55

	sword_bonus = 0
	armor_reduction = 0
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

	attack_cooldown = 0.0
	message_timer = 0.0
	message_text = ""

	reset_enemies()


# ==========================================
# 绘制游戏画面
# ==========================================

func _draw() -> void:
	# 秘境背景
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#173d32"))

	# 简单像素风地面纹理
	for x in range(20, int(screen_size.x), 48):
		for y in range(20, int(screen_size.y), 48):
			draw_rect(
				Rect2(Vector2(x,y), Vector2(2, 2)),
				Color("#285344")
			)

	# 妖兽（遍历数组绘制每一只）
	for e in enemies:
		var pos: Vector2 = e["pos"]
		var size: float = float(e["size"])

		var enemy_color: Color = ENEMY_TYPES[e["type"]]["color"]

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
			str(ENEMY_TYPES[e["type"]]["name"]),
			HORIZONTAL_ALIGNMENT_CENTER,
			60,
			14,
			Color("#e8d8ff")
		)

	# 玩家
	var player_color := Color("#45e5df")

	if damage_cooldown > 0.0:
		player_color = Color("#ffffff")

	draw_rect(
		Rect2(
			player_pos - Vector2.ONE * player_size / 2.0,
			Vector2.ONE * player_size
		),
		player_color
	)

	# 剑气弹幕
	for i in range(projectile_positions.size()):
		var p: Vector2 = projectile_positions[i]
		var d: Vector2 = projectile_directions[i]
		var tail := p - d * 18.0
		var tip := p + d * 7.0

		draw_line(tail, tip, Color("#42f5ff"), 5.0, true)
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
	draw_string(
		ThemeDB.fallback_font,
		Vector2(screen_size.x - 260.0, 30),
		get_wave_name(),
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
		+ "  减伤 " + str(armor_reduction)
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
