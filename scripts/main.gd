
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
}

# ==========================================
# 境界体系（阶段 9）
# 凡人六境，每境初期/中期/圆满；xp 是「升到下一小阶」所需修为
# ==========================================
const REALMS := [
	{
		"name": "炼己",
		"xp": [24, 30, 38],
		"skills": ["剑气诀", "护体灵气", "疾风步", "凝神"],
	},
	{
		"name": "筑基",
		"xp": [46, 56, 66],
		"skills": ["御剑术", "金钟罩", "踏云步", "心眼"],
	},
	{
		"name": "炼精化炁",
		"xp": [78, 90, 104],
		"skills": ["炁冲剑脉", "精元护体", "罡气行云", "目明"],
	},
	{
		"name": "炼炁化神",
		"xp": [118, 134, 152],
		"skills": ["神识御剑", "炁墙", "缩地成寸", "神觉"],
	},
	{
		"name": "炼神返虚",
		"xp": [170, 190, 212],
		"skills": ["虚空剑意", "返虚护体", "踏虚而行", "洞虚"],
	},
	{
		"name": "炼虚合道",
		"xp": [234, 258, 284],
		"skills": ["大道剑诀", "合道金身", "逍遥游", "天眼"],
	},
]

const STAGE_NAMES := ["初期", "中期", "圆满"]

# ==========================================
# 功法表
# stat: sword / armor / speed / crit
# ==========================================
const SKILLS := {
	# ---- 炼己 ----
	"剑气诀":   {"desc": "剑气伤害 +8",   "stat": "sword", "value": 8},
	"护体灵气": {"desc": "减伤 +4",       "stat": "armor", "value": 4},
	"疾风步":   {"desc": "移速 +25",      "stat": "speed", "value": 25},
	"凝神":     {"desc": "暴击率 +5%",    "stat": "crit",  "value": 5},
	# ---- 筑基 ----
	"御剑术":   {"desc": "剑气伤害 +18",  "stat": "sword", "value": 18},
	"金钟罩":   {"desc": "减伤 +10",      "stat": "armor", "value": 10},
	"踏云步":   {"desc": "移速 +45",      "stat": "speed", "value": 45},
	"心眼":     {"desc": "暴击率 +10%",   "stat": "crit",  "value": 10},
	# ---- 炼精化炁 ----
	"炁冲剑脉": {"desc": "剑气伤害 +30",  "stat": "sword", "value": 30},
	"精元护体": {"desc": "减伤 +16",      "stat": "armor", "value": 16},
	"罡气行云": {"desc": "移速 +60",      "stat": "speed", "value": 60},
	"目明":     {"desc": "暴击率 +14%",   "stat": "crit",  "value": 14},
	# ---- 炼炁化神 ----
	"神识御剑": {"desc": "剑气伤害 +45",  "stat": "sword", "value": 45},
	"炁墙":     {"desc": "减伤 +24",      "stat": "armor", "value": 24},
	"缩地成寸": {"desc": "移速 +90",      "stat": "speed", "value": 90},
	"神觉":     {"desc": "暴击率 +20%",   "stat": "crit",  "value": 20},
	# ---- 炼神返虚 ----
	"虚空剑意": {"desc": "剑气伤害 +65",  "stat": "sword", "value": 65},
	"返虚护体": {"desc": "减伤 +32",      "stat": "armor", "value": 32},
	"踏虚而行": {"desc": "移速 +110",     "stat": "speed", "value": 110},
	"洞虚":     {"desc": "暴击率 +26%",   "stat": "crit",  "value": 26},
	# ---- 炼虚合道 ----
	"大道剑诀": {"desc": "剑气伤害 +95",  "stat": "sword", "value": 95},
	"合道金身": {"desc": "减伤 +42",      "stat": "armor", "value": 42},
	"逍遥游":   {"desc": "移速 +150",     "stat": "speed", "value": 150},
	"天眼":     {"desc": "暴击率 +34%",   "stat": "crit",  "value": 34},
}

# 妖兽属性（当前这一只，由 spawn_enemy 从数据表赋值）
var enemy_type: String = "wolf"
var enemy_pos: Vector2 = Vector2(500, 300)
var enemy_speed: float = 75.0
var enemy_size: float = 34.0
var enemy_max_hp: int = 100
var enemy_hp: int = 100

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
var enemy_hit_flash: float = 0.0

# 修为与境界
var kill_count: int = 0
var cultivation: int = 0
var realm_index: int = 0        # 0=炼己 1=筑基 2=炼精化炁 3=炼炁化神 4=炼神返虚 5=炼虚合道
var stage_index: int = 0        # 0=初期 1=中期 2=圆满
var upgrade_pending: bool = false

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


func _ready() -> void:
	randomize()
	screen_size = get_viewport_rect().size
	player_pos = screen_size / 2.0
	spawn_enemy()
	queue_redraw()


func _process(delta: float) -> void:
	screen_size = get_viewport_rect().size

	if is_game_over:
		queue_redraw()
		return

	if upgrade_pending:
		queue_redraw()
		return

	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	enemy_hit_flash = maxf(0.0, enemy_hit_flash - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	message_timer = maxf(0.0, message_timer - delta)

	update_player(delta)
	update_enemy(delta)
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

func update_enemy(delta: float) -> void:
	var direction := player_pos - enemy_pos
	var distance := direction.length()

	if distance > 0.001:
		enemy_pos += direction.normalized() * enemy_speed * delta

	var contact_distance := (player_size + enemy_size) / 2.0

	if distance < contact_distance and damage_cooldown <= 0.0:
		var enemy_damage: int = int(ENEMY_TYPES[enemy_type]["damage"])
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

	var direction := enemy_pos - player_pos
	var distance := direction.length()

	if distance > attack_range:
		return

	if distance <= 0.001:
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

		var hit_distance := (enemy_size / 2.0) + projectile_size

		if projectile_positions[i].distance_to(enemy_pos) <= hit_distance:
			var damage: int = projectile_damages[i]
			var is_critical: bool = projectile_is_critical[i]

			enemy_hp -= damage
			enemy_hit_flash = 0.12

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

			if enemy_hp <= 0:
				kill_enemy()

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

func kill_enemy() -> void:
	kill_count += 1

	var reward: int = int(ENEMY_TYPES[enemy_type]["reward"])
	var enemy_name: String = str(ENEMY_TYPES[enemy_type]["name"])
	cultivation += reward

	message_text = "击败" + enemy_name + "！修为 +" + str(reward)
	message_timer = 1.0

	# 已封顶：修为停在阈值，不再触发升级
	if is_max_realm():
		cultivation = mini(cultivation, get_next_level_xp())
		spawn_enemy()
		return

	if cultivation >= get_next_level_xp():
		cultivation -= get_next_level_xp()
		begin_upgrade()
		return

	spawn_enemy()


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


func spawn_enemy() -> void:
	enemy_type = pick_enemy_type()

	var data: Dictionary = ENEMY_TYPES[enemy_type]
	enemy_speed = float(data["speed"])
	enemy_size = float(data["size"])
	enemy_max_hp = int(data["max_hp"])

	var margin := 60.0
	var side := randi_range(0, 3)

	match side:
		0:
			enemy_pos = Vector2(randf_range(margin, screen_size.x - margin), margin)
		1:
			enemy_pos = Vector2(randf_range(margin, screen_size.x - margin), screen_size.y - margin)
		2:
			enemy_pos = Vector2(margin, randf_range(margin, screen_size.y - margin))
		3:
			enemy_pos = Vector2(screen_size.x - margin, randf_range(margin, screen_size.y - margin))

	enemy_hp = enemy_max_hp


# ==========================================
# 升级与随机功法三选一
# ==========================================

# 当前境界名称，如「炼精化炁」
func get_realm_name() -> String:
	return str(REALMS[realm_index]["name"])


# 当前小阶名称，如「中期」
func get_stage_name() -> String:
	return str(STAGE_NAMES[stage_index])


# 完整境界，如「炼精化炁·中期」
func get_full_realm_name() -> String:
	return get_realm_name() + "·" + get_stage_name()


# 升到下一小阶需要的修为
func get_next_level_xp() -> int:
	return int(REALMS[realm_index]["xp"][stage_index])


# 总进度 0..17，用于妖兽难度
func get_progress() -> int:
	return realm_index * 3 + stage_index


# 当前境界的功法池
func get_current_skill_pool() -> Array:
	return REALMS[realm_index]["skills"]


# 是否已到本阶段封顶（炼虚合道·圆满）
func is_max_realm() -> bool:
	return realm_index >= REALMS.size() - 1 and stage_index >= STAGE_NAMES.size() - 1


func begin_upgrade() -> void:
	upgrade_pending = true

	var pool: Array = get_current_skill_pool()

	# 从本境界 4 种功法中随机取 3 种
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


func choose_skill(index: int) -> void:
	if not upgrade_pending:
		return

	if index < 0 or index >= skill_choices.size():
		return

	var chosen: Dictionary = skill_choices[index]
	var skill_name: String = chosen["name"]
	var data: Dictionary = SKILLS[skill_name]

	# 统一按 stat 处理效果，加新功法只需在 SKILLS 里加一行
	match str(data["stat"]):
		"sword":
			sword_bonus += int(data["value"])
		"armor":
			armor_reduction += int(data["value"])
		"speed":
			speed_bonus += float(data["value"])
		"crit":
			crit_bonus += float(data["value"])

	learned_skills.append(skill_name)

	# 推进小境界
	stage_index += 1

	if stage_index >= STAGE_NAMES.size():
		stage_index = 0
		realm_index += 1

		# 暂未实现仙道，先封顶在炼虚合道·圆满
		if realm_index >= REALMS.size():
			realm_index = REALMS.size() - 1
			stage_index = STAGE_NAMES.size() - 1

	upgrade_pending = false

	message_text = "习得功法：" + skill_name
	message_timer = 1.5

	# 修为溢出：剩余修为仍够升下一阶时，连续弹升级
	if not is_max_realm() and cultivation >= get_next_level_xp():
		cultivation -= get_next_level_xp()
		begin_upgrade()
		return

	spawn_enemy()


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
	# 鼠标点击选择功法（用事件自带坐标，比查询鼠标位置更可靠）
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if upgrade_pending:
			var index := get_skill_index_at(event.position)
			if index >= 0:
				choose_skill(index)
				get_viewport().set_input_as_handled()
		return

	# 鼠标移动时刷新悬停高亮
	if event is InputEventMouseMotion and upgrade_pending:
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


func restart_game() -> void:
	player_pos = screen_size / 2.0
	player_hp = player_max_hp
	damage_cooldown = 0.0
	is_game_over = false

	enemy_hp = enemy_max_hp
	kill_count = 0
	cultivation = 0
	realm_index = 0
	stage_index = 0

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
	enemy_hit_flash = 0.0

	attack_cooldown = 0.0
	message_timer = 0.0
	message_text = ""

	spawn_enemy()


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

	# 妖兽
	# 妖兽：命中时短暂闪白，按类型取颜色
	var enemy_color: Color = ENEMY_TYPES[enemy_type]["color"]

	if enemy_hit_flash > 0.0:
		enemy_color = Color.WHITE

	draw_rect(
		Rect2(
			enemy_pos - Vector2.ONE * enemy_size / 2.0,
			Vector2.ONE * enemy_size
		),
		enemy_color
	)

	# 妖兽血条
	var bar_width := maxf(54.0, enemy_size + 12.0)
	var bar_pos := enemy_pos + Vector2(-bar_width / 2.0, -enemy_size / 2.0 - 20.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, 6)), Color("#421c31"))

	var hp_ratio := float(enemy_hp) / float(enemy_max_hp)
	draw_rect(
		Rect2(bar_pos, Vector2(bar_width * hp_ratio, 6)),
		Color("#f05276")
	)

	# 妖兽名字
	draw_string(
		ThemeDB.fallback_font,
		enemy_pos + Vector2(-30.0, -enemy_size / 2.0 - 26.0),
		str(ENEMY_TYPES[enemy_type]["name"]),
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

	# 死亡界面
	if is_game_over:
		draw_rect(
			Rect2(Vector2.ZERO, screen_size),
			Color(0, 0, 0, 0.78)
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 140.0, screen_size.y / 2.0 - 35.0),
			"修仙失败！",
			HORIZONTAL_ALIGNMENT_CENTER,
			280,
			36,
			Color("#ff6b83")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 180.0, screen_size.y / 2.0 + 15.0),
			"击败妖兽：" + str(kill_count) + "   最终境界：" + get_full_realm_name(),
			HORIZONTAL_ALIGNMENT_CENTER,
			360,
			20,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(screen_size.x / 2.0 - 140.0, screen_size.y / 2.0 + 60.0),
			"按 R 键重新开始",
			HORIZONTAL_ALIGNMENT_CENTER,
			280,
			22,
			Color("#ffe9a6")
		)
