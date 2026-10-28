
extends Node2D

# 数据表来自 scripts/data.gd（拆分以降低单文件体积）
const Data := preload("res://scripts/data.gd")

const ENEMY_TYPES := Data.ENEMY_TYPES
const ELEMENTS := Data.ELEMENTS
const ELEMENT_SKILLS := Data.ELEMENT_SKILLS
const BASE_MAX_ENEMIES := Data.BASE_MAX_ENEMIES
const ELITE_HP_MUL := Data.ELITE_HP_MUL
const ELITE_DMG_MUL := Data.ELITE_DMG_MUL
const ELITE_SIZE_MUL := Data.ELITE_SIZE_MUL
const ELITE_REWARD_MUL := Data.ELITE_REWARD_MUL
const TRIBULATIONS := Data.TRIBULATIONS
const LATE_TRIBULATIONS := Data.LATE_TRIBULATIONS
const TRIBULATION_REWARDS := Data.TRIBULATION_REWARDS
const REALMS := Data.REALMS
const STAGE_NAMES := Data.STAGE_NAMES
const SKILLS := Data.SKILLS
const IMMORTAL_PATHS := Data.IMMORTAL_PATHS
const IMMORTAL_XP := Data.IMMORTAL_XP
const IMMORTAL_SKILLS := Data.IMMORTAL_SKILLS
const ARTIFACTS := Data.ARTIFACTS
const MAX_ARTIFACTS := Data.MAX_ARTIFACTS
const TALISMANS := Data.TALISMANS
const MAX_TALISMANS := Data.MAX_TALISMANS
const FORMATIONS := Data.FORMATIONS
const MAX_FORMATIONS := Data.MAX_FORMATIONS
const FORMATION_LIFETIME := Data.FORMATION_LIFETIME
const FLYING_SWORDS := Data.FLYING_SWORDS
const SWORD_UNLOCK := Data.SWORD_UNLOCK
const ORB_ATTRACT_RADIUS := Data.ORB_ATTRACT_RADIUS
const ORB_PICKUP_RADIUS := Data.ORB_PICKUP_RADIUS
const ORB_LIFETIME := Data.ORB_LIFETIME
const ORB_MAX_COUNT := Data.ORB_MAX_COUNT
const ORB_MERGE_RADIUS := Data.ORB_MERGE_RADIUS
const ORB_FLY_SPEED := Data.ORB_FLY_SPEED
const WAVE_KILLS_PER_WAVE := Data.WAVE_KILLS_PER_WAVE
const HUD_BAR_H := Data.HUD_BAR_H
const HUD_ICON_SIZE := Data.HUD_ICON_SIZE
const HUD_ICON_GAP := Data.HUD_ICON_GAP
const OBSTACLES := Data.OBSTACLES
const OBSTACLE_GRID := Data.OBSTACLE_GRID
const OBSTACLE_CHANCE := Data.OBSTACLE_CHANCE
const SCENES := Data.SCENES
const REALM_SCENES := Data.REALM_SCENES

# ==========================================
# 《一念成仙》Godot 4.7.2
# 主逻辑：战斗 / 成长 / 关卡 / 界面
# 数据表见 scripts/data.gd
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

# ==========================================
# 属性法术（v0.9.0）：给剑气附加元素
# ==========================================

# ==========================================
# 法器（v0.11.0）：被动装备，3 槽，同类型不可重复
# ==========================================


# ==========================================
# 符箓（v0.13.0）：一次性消耗品，最多 5 张
# Q 释放 / E 切换
# ==========================================


# ==========================================
# 阵法（v0.14.0）：场地增益，最多 2 个，F 放置
# 持续 15 秒，站进去生效
# ==========================================


# ==========================================
# 飞剑（v0.13.0）：境界解锁，空格释放，8 秒冷却
# ==========================================



# ==========================================
# 劫难系统（阶段 11）：破境时触发
# ==========================================

# 化神（realm_index >= 5）之后才出现雷劫/心魔/三尸

# 劫难奖励三选一

# ==========================================
# 关卡流程（阶段 10）：5 波 + 首领
# ==========================================
# 波次仅作记录（每波击杀数），不限制进度、不触发首领

# ==========================================
# 境界体系（阶段 9）
# 凡人十境，每境初期/中期/圆满；xp 是「升到下一小阶」所需修为
# ==========================================


# ==========================================
# 功法表
# stat: sword / armor / speed / crit
# ==========================================

# ==========================================
# 仙道三选一（炼虚合道·圆满后触发，不可逆）
# ==========================================

# 仙阶修为需求：[仙道→神仙, 神仙→天仙]

# 各仙阶可选的功法

# 妖兽数组（阶段 9：同屏多只）
# 每只妖兽是一个 Dictionary：type/pos/speed/size/max_hp/hp/hit_flash
# 主菜单与暂停（v0.17.0）
var in_main_menu: bool = true          # 启动先进主菜单
var is_paused: bool = false            # 游戏中按 ESC 暂停
var menu_selection: int = 0            # 主菜单当前高亮项
var pause_selection: int = 0           # 暂停菜单当前高亮项

# 障碍物（v0.16.0）：按世界格哈希生成，走到哪生成到哪
var obstacles: Array = []
var obstacle_cells: Dictionary = {}     # 已生成过的格子，避免重复

# 场景主题（v0.16.0）
var current_scene: String = "山门初境"

# 同屏妖兽上限（v0.8.0：随波次增长）

var enemies: Array[Dictionary] = []

# ==========================================
# 修为晶石（v0.8.0）：击杀掉落后需靠近拾取
# ==========================================

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

# 符箓与飞剑（v0.13.0）
var talisman_bag: Array[String] = []        # 符箓背包（最多 5）
var selected_talisman: int = 0
var unlocked_sword: String = ""             # 当前可用飞剑
var sword_cooldown: float = 0.0             # 飞剑冷却
var invincible_timer: float = 0.0           # 护身符无敌
var haste_timer: float = 0.0                # 疾行符加速

# 阵法（v0.14.0）
var formation_bag: Array[String] = []
var active_formation: Dictionary = {}   # {name, pos, life, radius, type, value}
var formation_tick: float = 0.0

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
	# 先进主菜单，玩家点「开始」才真正开局（v0.17.0）
	in_main_menu = true
	is_paused = false
	queue_redraw()


func _process(delta: float) -> void:
	screen_size = get_viewport_rect().size
	# UI 自适应：窗口小于 1100 宽时按比例缩小
	ui_scale = clampf(screen_size.x / 1280.0, 0.65, 1.0)

	# 主菜单：不跑任何游戏逻辑
	if in_main_menu:
		queue_redraw()
		return

	# 暂停：冻结一切（但保留重绘，菜单要能画）
	if is_paused:
		queue_redraw()
		return

	if is_game_over:
		queue_redraw()
		return

	if upgrade_pending or path_choice_pending or tribulation_reward_pending or artifact_drop_pending:
		queue_redraw()
		return

	run_time += delta

	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	sword_cooldown = maxf(0.0, sword_cooldown - delta)
	invincible_timer = maxf(0.0, invincible_timer - delta)
	haste_timer = maxf(0.0, haste_timer - delta)

	# 冻结计时
	for e in enemies:
		if e.has("frozen") and float(e["frozen"]) > 0.0:
			e["frozen"] = float(e["frozen"]) - delta

	# 生命回复
	if hp_regen > 0.0 and player_hp < player_max_hp:
		player_hp = mini(player_max_hp, player_hp + int(ceil(hp_regen * delta)))

	for e in enemies:
		e["hit_flash"] = maxf(0.0, float(e["hit_flash"]) - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	message_timer = maxf(0.0, message_timer - delta)

	update_scene()
	update_player(delta)
	update_camera()
	update_obstacles(delta)
	update_enemies(delta)
	update_projectiles(delta)
	update_orbs(delta)
	update_formation(delta)
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
	current_speed *= (1.0 + get_formation_bonus("haste") / 100.0)
	if haste_timer > 0.0:
		current_speed *= 2.5
	var move_vec := direction * current_speed * delta
	player_pos += move_vec

	# 障碍物碰撞：卡住不让穿过去
	player_pos = push_out_of_obstacles(player_pos, player_size / 2.0)

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

		var frozen := (e.has("frozen") and float(e["frozen"]) > 0.0)
		if distance > 0.001 and not frozen:
			var next_pos: Vector2 = e["pos"] + direction.normalized() * float(e["speed"]) * speed_mul * delta
			# 妖兽也绕不开障碍物，会被卡住（贴边滑）
			e["pos"] = push_out_of_obstacles(next_pos, float(e["size"]) / 2.0)

		var contact_distance := (player_size + float(e["size"])) / 2.0

		if distance < contact_distance and damage_cooldown <= 0.0 and invincible_timer <= 0.0:
			var enemy_damage: int = int(e.get("damage", ENEMY_TYPES[e["type"]]["damage"]))
			var reduction: float = clampf(damage_reduction, 0.0, 0.7)

			# 不灭灯：生命低于 30% 时额外减伤
			if low_hp_armor > 0.0 and float(player_hp) / float(player_max_hp) < 0.3:
				reduction = clampf(reduction + low_hp_armor / 100.0, 0.0, 0.85)

			# 护体阵：阵内额外减伤
			reduction = clampf(reduction + get_formation_bonus("armor") / 100.0, 0.0, 0.9)
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

		# 先检查是否撞到障碍物（岩石挡住、古木可打碎）
		if hit_obstacle_at(projectile_positions[i], projectile_damages[i]):
			projectile_positions.remove_at(i)
			projectile_directions.remove_at(i)
			projectile_damages.remove_at(i)
			projectile_lifetimes.remove_at(i)
			projectile_is_critical.remove_at(i)
			if i < projectile_elements.size():
				projectile_elements.remove_at(i)
			continue

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
			var xp_mul := 1.0 + xp_bonus / 100.0 + get_formation_bonus("xp") / 100.0
			var gained := int(round(float(o["value"]) * xp_mul))
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
# ==========================================
# 障碍物系统（v0.16.0）
# 按世界坐标网格程序化生成，同一格永远出同一种东西
# ==========================================

# 当前场景名（按境界决定）
func get_scene_name() -> String:
	if immortal_stage >= 3:
		return "魔界深渊"
	if immortal_stage == 2:
		return "天界云海·极"
	if immortal_stage == 1:
		return "天界云海"
	return str(REALM_SCENES[clampi(realm_index, 0, REALM_SCENES.size() - 1)])


# 更新场景主题（境界变化时切换）
func update_scene() -> void:
	var want := get_scene_name()
	if want != current_scene:
		current_scene = want


# 格子坐标 → 稳定伪随机数（0.0 ~ 1.0）
# 用格子坐标算哈希，保证同一格每次结果一致（不会来回闪烁）
func cell_hash(cx: int, cy: int, salt: int) -> float:
	var h: int = (cx * 73856093) ^ (cy * 19349663) ^ (salt * 83492791)
	h = absi(h)
	return float(h % 10000) / 10000.0


# 为某个格子决定是否生成障碍物，生成则加入 obstacles
func try_spawn_obstacle(cx: int, cy: int) -> void:
	var key := str(cx) + "," + str(cy)
	if obstacle_cells.has(key):
		return
	obstacle_cells[key] = true

	# 玩家出生点附近不放东西，避免一开局被卡住
	var cell_center := Vector2((float(cx) + 0.5) * OBSTACLE_GRID, (float(cy) + 0.5) * OBSTACLE_GRID)
	if cell_center.distance_to(Vector2.ZERO) < 300.0:
		return

	if cell_hash(cx, cy, 1) >= OBSTACLE_CHANCE:
		return

	# 按权重选类型
	var roll := cell_hash(cx, cy, 2) * 100.0
	var picked := "rock"
	var acc := 0.0
	for type_name in OBSTACLES.keys():
		acc += float(OBSTACLES[type_name]["weight"])
		if roll <= acc:
			picked = type_name
			break

	# 格内随机位置（用另一个盐保证不跟概率相关）
	var ox := cell_hash(cx, cy, 3) * OBSTACLE_GRID
	var oy := cell_hash(cx, cy, 4) * OBSTACLE_GRID

	var data: Dictionary = OBSTACLES[picked]
	obstacles.append({
		"type": picked,
		"pos": Vector2(float(cx) * OBSTACLE_GRID + ox, float(cy) * OBSTACLE_GRID + oy),
		"radius": float(data["radius"]),
		"hp": int(data["hits"]),
		"max_hp": int(data["hits"]),
		"flash": 0.0,
		"cell": key,
	})


# 每帧维护：生成视野附近格子，清理走远的
func update_obstacles(delta: float) -> void:
	var view_r := maxf(screen_size.x, screen_size.y) * 0.75
	var cx_min := int(floorf((player_pos.x - view_r) / OBSTACLE_GRID))
	var cx_max := int(floorf((player_pos.x + view_r) / OBSTACLE_GRID))
	var cy_min := int(floorf((player_pos.y - view_r) / OBSTACLE_GRID))
	var cy_max := int(floorf((player_pos.y + view_r) / OBSTACLE_GRID))

	for cx in range(cx_min, cx_max + 1):
		for cy in range(cy_min, cy_max + 1):
			try_spawn_obstacle(cx, cy)

	# 清理离玩家太远的（同时把格子记录删掉，走回来能重新生成）
	var keep_r := view_r + OBSTACLE_GRID * 2.0
	for i in range(obstacles.size() - 1, -1, -1):
		var o: Dictionary = obstacles[i]
		o["flash"] = maxf(0.0, float(o["flash"]) - delta)
		if (o["pos"] as Vector2).distance_to(player_pos) > keep_r:
			obstacle_cells.erase(str(o["cell"]))
			obstacles.remove_at(i)


# 圆形推开：把 pos 推到不与障碍物重叠的位置
func push_out_of_obstacles(pos: Vector2, radius: float) -> Vector2:
	for o in obstacles:
		var data: Dictionary = OBSTACLES[o["type"]]
		if not bool(data["block"]):
			continue
		var orad := float(o["radius"])
		var min_dist := orad + radius
		var diff: Vector2 = pos - (o["pos"] as Vector2)
		var d := diff.length()
		if d < min_dist and d > 0.001:
			pos = (o["pos"] as Vector2) + diff.normalized() * min_dist
		elif d <= 0.001:
			pos = (o["pos"] as Vector2) + Vector2(min_dist, 0.0)
	return pos


# 判断某点是否被障碍物挡住（给妖兽/剑气用）
func is_blocked_at(pos: Vector2, radius: float) -> bool:
	for o in obstacles:
		var data: Dictionary = OBSTACLES[o["type"]]
		if not bool(data["block"]):
			continue
		var min_dist := float(o["radius"]) + radius
		if pos.distance_to(o["pos"] as Vector2) < min_dist:
			return true
	return false


# 剑气打中障碍物：可破坏的扣血，打碎后灵草回血
# 返回 true 表示剑气应该消失
func hit_obstacle_at(pos: Vector2, damage: int) -> bool:
	for i in range(obstacles.size() - 1, -1, -1):
		var o: Dictionary = obstacles[i]
		var data: Dictionary = OBSTACLES[o["type"]]
		if pos.distance_to(o["pos"] as Vector2) >= float(o["radius"]) + 8.0:
			continue

		# 不可破坏（岩石）：挡住剑气，剑气消失
		if not bool(data["breakable"]):
			return true

		# 可破坏（古木 / 灵草）：扣耐久
		o["hp"] = int(o["hp"]) - 1
		o["flash"] = 0.12
		if int(o["hp"]) <= 0:
			var heal := int(data["heal"])
			if heal > 0:
				player_hp = mini(player_max_hp, player_hp + heal)
				message_text = "灵草回气 +" + str(heal)
				message_timer = 0.5
			obstacle_cells.erase(str(o["cell"]))
			obstacles.remove_at(i)

		# 只有阻挡型才让剑气消失；灵草不挡剑气，剑气继续飞
		return bool(data["block"])
	return false


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

	# 符箓掉落：普通 8%，精英 40%
	var talisman_chance := 0.40 if is_elite else 0.08
	if randf() < talisman_chance:
		roll_talisman_drop()

	# 阵法掉落：普通 3%，精英 10%
	var formation_chance := 0.10 if is_elite else 0.03
	if randf() < formation_chance:
		roll_formation_drop()

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


# ==========================================
# 符箓
# ==========================================

# ==========================================
# 阵法
# ==========================================

# 获得阵法
func add_formation(name: String) -> void:
	if not FORMATIONS.has(name):
		return
	if formation_bag.size() >= MAX_FORMATIONS:
		formation_bag.remove_at(0)
	formation_bag.append(name)
	message_text = "获得阵法：" + name
	message_timer = 1.5


# 随机掉落阵法
func roll_formation_drop() -> void:
	var keys: Array = FORMATIONS.keys()
	if keys.size() == 0:
		return
	add_formation(str(keys[randi_range(0, keys.size() - 1)]))


# 放置阵法（脚下）
func place_formation() -> void:
	if formation_bag.size() == 0:
		return
	if not active_formation.is_empty():
		return   # 同时只能有一个

	var name: String = formation_bag[0]
	var data: Dictionary = FORMATIONS[name]

	active_formation = {
		"name": name,
		"pos": player_pos,
		"life": FORMATION_LIFETIME,
		"radius": float(data["radius"]),
		"type": str(data["type"]),
		"value": float(data["value"]),
	}

	formation_bag.remove_at(0)
	message_text = "布下阵法：" + name
	message_timer = 1.5


# 玩家是否在阵内
func is_player_in_formation() -> bool:
	if active_formation.is_empty():
		return false
	return (active_formation["pos"] as Vector2).distance_to(player_pos) <= float(active_formation["radius"])


# 阵法每帧更新
func update_formation(delta: float) -> void:
	if active_formation.is_empty():
		return

	active_formation["life"] = float(active_formation["life"]) - delta
	if float(active_formation["life"]) <= 0.0:
		active_formation.clear()
		return

	var in_zone := is_player_in_formation()
	if not in_zone:
		return

	# 杀阵：每秒伤害阵内妖兽
	if str(active_formation["type"]) == "damage":
		formation_tick += delta
		if formation_tick >= 1.0:
			formation_tick = 0.0
			var dmg := int(active_formation["value"])
			var center: Vector2 = active_formation["pos"]
			var radius := float(active_formation["radius"])
			for i in range(enemies.size() - 1, -1, -1):
				var e: Dictionary = enemies[i]
				if (e["pos"] as Vector2).distance_to(center) <= radius:
					e["hp"] = int(e["hp"]) - dmg
					e["hit_flash"] = 0.12
					if int(e["hp"]) <= 0:
						kill_enemy(i)


# 当前阵法提供的加成
func get_formation_bonus(type: String) -> float:
	if not is_player_in_formation():
		return 0.0
	if str(active_formation["type"]) != type:
		return 0.0
	return float(active_formation["value"])


# 获得符箓（满了则替换最旧）
func add_talisman(name: String) -> void:
	if not TALISMANS.has(name):
		return
	if talisman_bag.size() >= MAX_TALISMANS:
		talisman_bag.remove_at(0)
	talisman_bag.append(name)
	message_text = "获得符箓：" + name
	message_timer = 1.5


# 随机掉落符箓
func roll_talisman_drop() -> void:
	var keys: Array = TALISMANS.keys()
	if keys.size() == 0:
		return
	add_talisman(str(keys[randi_range(0, keys.size() - 1)]))


# 切换符箓
func cycle_talisman() -> void:
	if talisman_bag.size() <= 1:
		return
	selected_talisman = (selected_talisman + 1) % talisman_bag.size()


# 释放符箓
func use_talisman() -> void:
	if talisman_bag.size() == 0:
		return
	if selected_talisman >= talisman_bag.size():
		selected_talisman = 0

	var name: String = talisman_bag[selected_talisman]
	var data: Dictionary = TALISMANS[name]

	match str(data["type"]):
		"fireball":
			cast_fireball(int(data["value"]))
		"freeze":
			for e in enemies:
				e["frozen"] = float(data["value"])
		"thunder":
			cast_thunder_all(int(data["value"]))
		"shield":
			invincible_timer = float(data["value"])
		"haste":
			haste_timer = float(data["value"])
		"gather":
			for o in orbs:
				cultivation += int(round(float(o["value"]) * (1.0 + xp_bonus / 100.0)))
			orbs.clear()
			check_level_up()

	talisman_bag.remove_at(selected_talisman)
	if selected_talisman >= talisman_bag.size():
		selected_talisman = maxi(0, talisman_bag.size() - 1)

	message_text = "使用符箓：" + name
	message_timer = 1.5


# 火球：向最近妖兽爆炸
func cast_fireball(damage: int) -> void:
	if enemies.size() == 0:
		return

	var target: Dictionary = enemies[0]
	var best := 1e20
	for e in enemies:
		var d: float = (e["pos"] as Vector2).distance_to(player_pos)
		if d < best:
			best = d
			target = e

	var center: Vector2 = target["pos"]

	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		if (e["pos"] as Vector2).distance_to(center) <= 80.0:
			e["hp"] = int(e["hp"]) - damage
			e["hit_flash"] = 0.12
			if int(e["hp"]) <= 0:
				kill_enemy(i)


# 雷击：全场伤害
func cast_thunder_all(damage: int) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		e["hp"] = int(e["hp"]) - damage
		e["hit_flash"] = 0.12
		if int(e["hp"]) <= 0:
			kill_enemy(i)


# ==========================================
# 飞剑
# ==========================================

# 检查境界解锁飞剑
func update_sword_unlock() -> void:
	var realm_name := ""
	if immortal_stage >= 3:
		realm_name = "天仙"
	elif immortal_stage >= 1:
		realm_name = ""
	else:
		realm_name = str(REALMS[realm_index]["name"])

	if SWORD_UNLOCK.has(realm_name):
		var sword: String = str(SWORD_UNLOCK[realm_name])
		if unlocked_sword != sword:
			unlocked_sword = sword
			message_text = "领悟飞剑：" + sword
			message_timer = 2.5


# 释放飞剑
func use_flying_sword() -> void:
	if unlocked_sword == "" or sword_cooldown > 0.0:
		return

	var data: Dictionary = FLYING_SWORDS[unlocked_sword]
	var count := int(data["count"])
	var mul := float(data["mul"])
	var spread := float(data["spread"])

	var base_dir := Vector2.RIGHT
	if enemies.size() > 0:
		var best := 1e20
		for e in enemies:
			var d: float = (e["pos"] as Vector2).distance_to(player_pos)
			if d < best:
				best = d
				base_dir = ((e["pos"] as Vector2) - player_pos).normalized()

	for i in range(count):
		var dir := base_dir
		if count == 12:
			dir = base_dir.rotated(TAU * float(i) / 12.0)
		elif count > 1:
			dir = base_dir.rotated(spread * float(i - (count - 1) / 2.0))

		var dmg := int(float(attack_damage + sword_bonus) * mul)
		projectile_positions.append(player_pos + dir * 18.0)
		projectile_directions.append(dir)
		projectile_damages.append(dmg)
		projectile_lifetimes.append(projectile_lifetime * 1.5)
		projectile_is_critical.append(false)
		projectile_elements.append(sword_element)

	sword_cooldown = 8.0
	message_text = "飞剑：" + unlocked_sword
	message_timer = 1.5


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
	update_sword_unlock()
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

	# 25% 额外掉阵法
	if randf() < 0.25:
		roll_formation_drop()

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
	# 主菜单鼠标操作（v0.17.0）
	if in_main_menu:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mi := get_menu_index_at(event.position)
			if mi >= 0:
				select_main_menu(mi)
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion:
			queue_redraw()
		return

	# 暂停菜单鼠标操作（v0.17.0）
	if is_paused:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var pi := get_pause_index_at(event.position)
			if pi >= 0:
				select_pause_menu(pi)
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion:
			queue_redraw()
		return

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
	# 主菜单（v0.17.0）
	if in_main_menu:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_UP, KEY_W:
					menu_selection = (menu_selection + 2) % 3
				KEY_DOWN, KEY_S:
					menu_selection = (menu_selection + 1) % 3
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
					select_main_menu(menu_selection)
				KEY_ESCAPE:
					get_tree().quit()
		return

	# 暂停菜单（v0.17.0）
	if is_paused:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_UP, KEY_W:
					pause_selection = (pause_selection + 1) % 2
				KEY_DOWN, KEY_S:
					pause_selection = (pause_selection + 1) % 2
				KEY_ENTER, KEY_KP_ENTER:
					select_pause_menu(pause_selection)
				KEY_ESCAPE:
					is_paused = false
		return

	if event is InputEventKey and event.pressed and not event.echo:
		# ESC 暂停
		if event.keycode == KEY_ESCAPE:
			if not is_game_over:
				is_paused = true
				pause_selection = 0
			return
		# 符箓与飞剑（游戏中随时可用）
		if not is_game_over and not upgrade_pending and not path_choice_pending \
				and not tribulation_reward_pending and not artifact_drop_pending:
			match event.keycode:
				KEY_Q:
					use_talisman()
					return
				KEY_E:
					cycle_talisman()
					return
				KEY_SPACE:
					use_flying_sword()
					return
				KEY_F:
					place_formation()
					return

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


# ==========================================
# 主菜单与暂停（v0.17.0）
# ==========================================

# 主菜单选项：0 开始游戏 / 1 继续上次 / 2 退出
func select_main_menu(index: int) -> void:
	match index:
		0:
			in_main_menu = false
			is_paused = false
			restart_game()
		1:
			# 暂无存档系统，先按新开处理
			in_main_menu = false
			is_paused = false
			restart_game()
		2:
			get_tree().quit()


func select_pause_menu(index: int) -> void:
	match index:
		0:
			is_paused = false
		1:
			is_paused = false
			in_main_menu = true


# 主菜单选项矩形
func get_menu_item_rect(index: int) -> Rect2:
	var w := 320.0 * ui_scale
	var h := 52.0 * ui_scale
	var gap := 12.0 * ui_scale
	var start_y := screen_size.y / 2.0 - 20.0 * ui_scale
	return Rect2(
		Vector2(screen_size.x / 2.0 - w / 2.0, start_y + float(index) * (h + gap)),
		Vector2(w, h)
	)


func get_menu_index_at(pos: Vector2) -> int:
	for i in range(3):
		if get_menu_item_rect(i).has_point(pos):
			return i
	return -1


# 暂停选项矩形
func get_pause_item_rect(index: int) -> Rect2:
	var w := 300.0 * ui_scale
	var h := 50.0 * ui_scale
	var gap := 12.0 * ui_scale
	var start_y := screen_size.y / 2.0 - 30.0 * ui_scale
	return Rect2(
		Vector2(screen_size.x / 2.0 - w / 2.0, start_y + float(index) * (h + gap)),
		Vector2(w, h)
	)


func get_pause_index_at(pos: Vector2) -> int:
	for i in range(2):
		if get_pause_item_rect(i).has_point(pos):
			return i
	return -1


# 画主菜单
func draw_main_menu() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#0d1512"))

	# 标题
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y / 2.0 - 150.0 * ui_scale),
		"一 念 成 仙",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		56,
		Color("#ffd76e")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y / 2.0 - 100.0 * ui_scale),
		"修仙肉鸽 · 无限世界",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		18,
		Color("#7fbfa0")
	)

	var labels := ["开始游戏", "继续游戏", "退出"]
	var hovered := get_hovered_menu_index()

	for i in range(3):
		var rect := get_menu_item_rect(i)
		var is_hover := (i == hovered) or (i == menu_selection and hovered < 0)

		if is_hover:
			draw_rect(rect, Color("#1e3a2e"))
			draw_rect(rect, Color("#ffd76e"), false, 2.0)
		else:
			draw_rect(rect, Color("#16261f"))
			draw_rect(rect, Color("#3f6b55"), false, 1.0)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(rect.position.x, rect.position.y + rect.size.y / 2.0 + 8.0),
			labels[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			22,
			Color("#ffd76e") if is_hover else Color("#c8e8d8")
		)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y - 60.0),
		"↑↓ 选择    Enter 确认    游戏中按 ESC 暂停",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		15,
		Color("#5f8f75")
	)


# 画暂停菜单
func draw_pause_menu() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0, 0, 0, 0.75))

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y / 2.0 - 90.0 * ui_scale),
		"暂 停",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		40,
		Color("#ffd76e")
	)

	var labels := ["继续游戏", "返回主菜单"]
	var hovered := get_hovered_pause_index()

	for i in range(2):
		var rect := get_pause_item_rect(i)
		var is_hover := (i == hovered) or (i == pause_selection and hovered < 0)

		if is_hover:
			draw_rect(rect, Color("#1e3a2e"))
			draw_rect(rect, Color("#ffd76e"), false, 2.0)
		else:
			draw_rect(rect, Color("#16261f"))
			draw_rect(rect, Color("#3f6b55"), false, 1.0)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(rect.position.x, rect.position.y + rect.size.y / 2.0 + 8.0),
			labels[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			21,
			Color("#ffd76e") if is_hover else Color("#c8e8d8")
		)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y - 60.0),
		"ESC 继续",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		15,
		Color("#5f8f75")
	)


func get_hovered_menu_index() -> int:
	var mouse := get_viewport().get_mouse_position()
	return get_menu_index_at(mouse)


func get_hovered_pause_index() -> int:
	var mouse := get_viewport().get_mouse_position()
	return get_pause_index_at(mouse)


func restart_game() -> void:
	player_max_hp = 100
	player_hp = player_max_hp
	player_pos = Vector2.ZERO
	update_camera()
	damage_cooldown = 0.0
	is_game_over = false
	is_paused = false

	kill_count = 0
	cultivation = 0
	wave = 1
	wave_kills = 0
	run_time = 0.0
	game_won = false
	boss_active = false

	distance_traveled = 0.0
	obstacles.clear()
	obstacle_cells.clear()
	current_scene = "山门初境"
	formation_bag.clear()
	active_formation.clear()
	formation_tick = 0.0

	talisman_bag.clear()
	selected_talisman = 0
	unlocked_sword = ""
	sword_cooldown = 0.0
	invincible_timer = 0.0
	haste_timer = 0.0

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

# ==========================================
# 底部 HUD（网游式）：修为进度条 + 技能图标栏
# ==========================================

# 计算图标栏起点（居中）
func get_hud_icon_start(count: int) -> float:
	var total_w := float(count) * HUD_ICON_SIZE + float(count - 1) * HUD_ICON_GAP
	return (screen_size.x - total_w) / 2.0


# 绘制单个技能图标
func draw_hud_icon(pos: Vector2, label: String, sub: String, color: Color, ready: bool, active: bool) -> void:
	var r := Rect2(pos, Vector2.ONE * HUD_ICON_SIZE)
	var bg := Color("#2a3d38") if ready else Color("#1a2420")
	draw_rect(r, bg)
	draw_rect(r, color if ready else Color("#4a5a55"), false, 2.0 if active else 1.5)

	# 图标内文字（取标签首字）
	draw_string(
		ThemeDB.fallback_font,
		pos + Vector2(0, 28),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		HUD_ICON_SIZE,
		20,
		color if ready else Color("#6a7a75")
	)

	# 下方小字
	draw_string(
		ThemeDB.fallback_font,
		pos + Vector2(0, HUD_ICON_SIZE + 13),
		sub,
		HORIZONTAL_ALIGNMENT_CENTER,
		HUD_ICON_SIZE,
		11,
		Color("#9ab5ad")
	)


func draw_bottom_hud() -> void:
	if is_game_over:
		return

	var bar_y := screen_size.y - HUD_BAR_H

	# --- 修为进度条（最底部，通栏）---
	draw_rect(Rect2(Vector2(0, bar_y), Vector2(screen_size.x, HUD_BAR_H)), Color("#101a17"))

	var need := get_next_level_xp()
	var ratio := 1.0 if is_max_realm() else clampf(float(cultivation) / float(need), 0.0, 1.0)

	# 进度条本体（渐变色条）
	draw_rect(
		Rect2(Vector2(0, bar_y), Vector2(screen_size.x * ratio, HUD_BAR_H)),
		Color("#2f8f6f")
	)
	draw_rect(
		Rect2(Vector2(0, bar_y), Vector2(screen_size.x * ratio, HUD_BAR_H * 0.45)),
		Color("#3fbf92")
	)

	# 进度条文字
	var bar_text := "修为 %d / %d" % [cultivation, need]
	if is_max_realm():
		bar_text = "已至天仙·圆满"
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, bar_y + 18),
		bar_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		14,
		Color.WHITE
	)

	# --- 技能图标栏（进度条上方，居中）---
	var icons: Array[Dictionary] = []

	# 飞剑
	if unlocked_sword != "":
		var ready := sword_cooldown <= 0.0
		icons.append({
			"label": "剑",
			"sub": "空格" if ready else "%.1fs" % sword_cooldown,
			"color": Color("#ffd76e"),
			"ready": ready,
			"active": false,
		})

	# 符箓（显示前 5 个）
	for i in range(mini(talisman_bag.size(), 5)):
		var tname: String = talisman_bag[i]
		icons.append({
			"label": str(tname).substr(0, 1),
			"sub": "Q" if i == selected_talisman else "E切",
			"color": Color("#a8d8ff"),
			"ready": true,
			"active": i == selected_talisman,
		})

	# 阵法
	if not active_formation.is_empty():
		icons.append({
			"label": "阵",
			"sub": "%.0fs" % float(active_formation["life"]),
			"color": Color("#6fd8a0"),
			"ready": true,
			"active": true,
		})
	elif formation_bag.size() > 0:
		icons.append({
			"label": "阵",
			"sub": "F",
			"color": Color("#6fd8a0"),
			"ready": true,
			"active": false,
		})

	# 法器（显示为图标）
	for a in artifacts:
		icons.append({
			"label": str(a).substr(0, 1),
			"sub": str(a).substr(0, 3),
			"color": Color("#d4a05a"),
			"ready": true,
			"active": false,
		})

	if icons.size() > 0:
		var start_x := get_hud_icon_start(icons.size())
		var icon_y := bar_y - HUD_ICON_SIZE - 22.0

		for i in range(icons.size()):
			var ic: Dictionary = icons[i]
			var px := start_x + float(i) * (HUD_ICON_SIZE + HUD_ICON_GAP)
			draw_hud_icon(
				Vector2(px, icon_y),
				str(ic["label"]),
				str(ic["sub"]),
				ic["color"],
				bool(ic["ready"]),
				bool(ic["active"])
			)


func _draw() -> void:
	# 主菜单独占画面（v0.17.0）
	if in_main_menu:
		draw_main_menu()
		return

	# 场景主题背景（v0.16.0：随境界切换）
	var scene_data: Dictionary = SCENES.get(current_scene, SCENES["山门初境"])
	var bg_color := Color(str(scene_data["bg"]))
	var dot_color := Color(str(scene_data["dot"]))
	draw_rect(Rect2(Vector2.ZERO, screen_size), bg_color)

	# 地面纹理：按世界坐标计算可视范围，无限滚动
	var grid: float = 48.0
	var start_x: float = floorf((player_pos.x - screen_size.x / 2.0) / grid) * grid
	var start_y: float = floorf((player_pos.y - screen_size.y / 2.0) / grid) * grid

	var gx := start_x
	while gx < player_pos.x + screen_size.x / 2.0 + grid:
		var gy := start_y
		while gy < player_pos.y + screen_size.y / 2.0 + grid:
			var sp := w2s(Vector2(gx + 20.0, gy + 20.0))
			draw_rect(Rect2(sp, Vector2(2, 2)), dot_color)
			gy += grid
		gx += grid

	# 障碍物（v0.16.0）
	for o in obstacles:
		var op: Vector2 = w2s(o["pos"])
		var orad := float(o["radius"])
		# 视口外跳过
		if op.x < -orad * 2.0 or op.x > screen_size.x + orad * 2.0:
			continue
		if op.y < -orad * 2.0 or op.y > screen_size.y + orad * 2.0:
			continue

		var od: Dictionary = OBSTACLES[o["type"]]
		var ocol := Color(str(od["color"]))
		var oedge := Color(str(od["edge"]))
		if float(o["flash"]) > 0.0:
			ocol = Color.WHITE

		# 岩石画方块，古木画三角树冠，灵草画小菱形
		match str(o["type"]):
			"rock":
				draw_rect(Rect2(op - Vector2.ONE * orad, Vector2.ONE * orad * 2.0), ocol)
				draw_rect(Rect2(op - Vector2.ONE * orad, Vector2.ONE * orad * 2.0), oedge, false, 2.0)
			"tree":
				draw_rect(Rect2(op - Vector2(orad * 0.18, orad * 0.9), Vector2(orad * 0.36, orad * 1.6)), ocol)
				draw_colored_polygon(
					PackedVector2Array([
						op + Vector2(0.0, -orad * 1.5),
						op + Vector2(-orad, orad * 0.25),
						op + Vector2(orad, orad * 0.25),
					]),
					oedge
				)
			"herb":
				draw_colored_polygon(
					PackedVector2Array([
						op + Vector2(0.0, -orad),
						op + Vector2(orad, 0.0),
						op + Vector2(0.0, orad),
						op + Vector2(-orad, 0.0),
					]),
					oedge
				)

		# 可破坏的显示剩余耐久
		if bool(od["breakable"]) and int(o["max_hp"]) > 1 and int(o["hp"]) < int(o["max_hp"]):
			var bw := orad * 2.0
			var bpos := op + Vector2(-orad, -orad - 10.0)
			draw_rect(Rect2(bpos, Vector2(bw, 4)), Color("#421c31"))
			draw_rect(
				Rect2(bpos, Vector2(bw * float(o["hp"]) / float(o["max_hp"]), 4)),
				Color("#6fd8a0")
			)

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

	# 阵法（地面光圈）
	if not active_formation.is_empty():
		var fpos: Vector2 = w2s(active_formation["pos"])
		var frad := float(active_formation["radius"])
		var flife := float(active_formation["life"])
		var alpha := clampf(flife / 3.0, 0.15, 0.55)

		var fcolor := Color("#6fd8a0")
		match str(active_formation["type"]):
			"damage": fcolor = Color("#e05a5a")
			"armor":  fcolor = Color("#6f9fe0")
			"haste":  fcolor = Color("#e0d06f")
			"xp":     fcolor = Color("#6fd8a0")

		# 外圈
		draw_arc(fpos, frad, 0.0, TAU, 48, Color(fcolor.r, fcolor.g, fcolor.b, alpha), 3.0, true)
		# 内圈
		draw_arc(fpos, frad * 0.55, 0.0, TAU, 32, Color(fcolor.r, fcolor.g, fcolor.b, alpha * 0.6), 2.0, true)
		# 填充
		draw_circle(fpos, frad, Color(fcolor.r, fcolor.g, fcolor.b, alpha * 0.12))
		# 名字
		draw_string(
			ThemeDB.fallback_font,
			fpos + Vector2(-60.0, -frad - 8.0),
			str(active_formation["name"]) + " %.0fs" % flife,
			HORIZONTAL_ALIGNMENT_CENTER,
			120,
			14,
			Color(fcolor.r, fcolor.g, fcolor.b, 0.9)
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
			Vector2(20, screen_size.y - HUD_BAR_H - 96.0),
			"待拾取修为：" + str(get_pending_xp()),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color("#7fd8ff")
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

	# 场景名（v0.16.0）
	draw_string(
		ThemeDB.fallback_font,
		Vector2(screen_size.x - 260.0, 76),
		"境域 " + current_scene,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color("#9ecfff")
	)

	# 波次进度条
	if not boss_active:
		draw_rect(Rect2(Vector2(screen_size.x - 260.0, 86), Vector2(180, 8)), Color("#421c31"))
		draw_rect(
			Rect2(Vector2(screen_size.x - 260.0, 86), Vector2(180.0 * get_wave_progress(), 8)),
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
		Vector2(20, screen_size.y - HUD_BAR_H - 118.0),
		"WASD 移动 · Q 符箓 · E 切换 · 空格 飞剑",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color("#8aa89e")
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

	# ==========================================
	# 底部 HUD（网游式）
	# ==========================================
	draw_bottom_hud()

	# 暂停菜单（v0.17.0）
	if is_paused:
		draw_pause_menu()

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
