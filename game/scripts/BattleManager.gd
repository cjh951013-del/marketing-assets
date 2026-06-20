extends Node
# ============================================================
# BattleManager.gd — AutoLoad: 전투 엔진
# ============================================================

signal damage_dealt(enemy_id: int, amount: float, is_crit: bool, pos: Vector2)
signal enemy_died(enemy_id: int)
signal wave_started(wave_num: int)
signal wave_cleared(wave_num: int, gold: float)
signal squad_hp_changed(cur: float, max: float)
signal gold_ticked(total: float)
signal battle_log(msg: String)
signal stage_cleared(stage: String)

# ── 적 클래스 ───────────────────────────────────────────────
class Enemy:
	var id:int; var name_kr:String; var hp:float; var max_hp:float
	var atk:float; var is_boss:bool; var color:Color
	var pos: Vector2 = Vector2.ZERO  # 화면 내 위치 (뷰에서 설정)

	func _init(p_id,p_n,p_hp,p_atk,p_boss,p_col):
		id=p_id; name_kr=p_n; hp=p_hp; max_hp=p_hp; atk=p_atk
		is_boss=p_boss; color=p_col

	func alive() -> bool:           return hp > 0.0
	func ratio() -> float:          return clampf(hp / max_hp, 0.0, 1.0)
	func take_dmg(d:float) -> float:
		var a = min(d, hp); hp -= a; return a

# ── 상태 ─────────────────────────────────────────────────────
var enemies:     Array   = []
var squad_hp:    float   = 0.0
var squad_max:   float   = 0.0
var synergy:     Dictionary = {}
var owned_fx:    Dictionary = {}

var active:      bool   = false
var auto_repeat: bool   = true
var speed:       float  = 1.0   # 1.0 / 2.0 / 3.0
var wave:        int    = 1

var atk_timer:   float  = 0.0
var eatk_timer:  float  = 0.0
var idle_timer:  float  = 0.0
const ATK_INTERVAL  := 1.6
const EATK_INTERVAL := 2.2
const IDLE_GOLD     := 2.5   # 골드/초

# ── 시작 ──────────────────────────────────────────────────────
func _ready(): pass

func start_battle():
	_recalc_squad()
	_spawn_wave(wave)
	active = true
	emit_signal("wave_started", wave)

func restart():
	wave = 1; start_battle()

func set_speed(s: float): speed = s
func toggle_auto(): auto_repeat = !auto_repeat

# ── 스쿼드 재계산 ─────────────────────────────────────────────
func _recalc_squad():
	synergy   = SynergyManager.calculate(GameData.squad)
	owned_fx  = SynergyManager.calculate_owned_effects(GameData.get_owned())
	squad_max = 0.0
	for a in GameData.squad:
		squad_max += a.get_hp() * synergy.max_hp * (1.0 + owned_fx.global_hp)
	squad_hp = squad_max
	emit_signal("squad_hp_changed", squad_hp, squad_max)

func update_squad():
	_recalc_squad()

# ── 메인 루프 ─────────────────────────────────────────────────
func _process(delta: float):
	var dt = delta * speed

	# 방치 골드
	idle_timer += dt
	if idle_timer >= 1.0:
		idle_timer = 0.0
		var bonus = synergy.get("global_gold", 0.0)
		GameData.add_gold(IDLE_GOLD * (1.0 + bonus))
		emit_signal("gold_ticked", GameData.gold)

	if not active: return

	atk_timer  += dt
	eatk_timer += dt

	if atk_timer  >= ATK_INTERVAL:  atk_timer  = 0.0; _squad_attack()
	if eatk_timer >= EATK_INTERVAL: eatk_timer = 0.0; _enemy_attack()

# ── 스쿼드 공격 ───────────────────────────────────────────────
func _squad_attack():
	if GameData.squad.is_empty(): return
	var alive = enemies.filter(func(e): return e.alive())
	if alive.is_empty(): return

	for agent in GameData.squad:
		alive = enemies.filter(func(e): return e.alive())
		if alive.is_empty(): break
		var target = _pick_target(alive)
		var dmg    = agent.get_atk() * synergy.final_damage * (1.0 + owned_fx.global_atk)
		var is_crit = randf() < synergy.crit_rate
		if is_crit: dmg *= 2.0
		var actual = target.take_dmg(dmg)
		emit_signal("damage_dealt", target.id, actual, is_crit, target.pos)
		if not target.alive():
			emit_signal("enemy_died", target.id)

	if enemies.filter(func(e): return e.alive()).is_empty():
		_on_wave_clear()

# ── 적 공격 ───────────────────────────────────────────────────
func _enemy_attack():
	var alive = enemies.filter(func(e): return e.alive())
	var total_dmg = alive.reduce(func(acc, e): return acc + e.atk, 0.0)
	if synergy.cc_immunity: total_dmg *= 0.5
	squad_hp = maxf(0.0, squad_hp - total_dmg)
	emit_signal("squad_hp_changed", squad_hp, squad_max)
	if total_dmg > 0:
		emit_signal("battle_log", "🩸 치즈파 공격! -%d HP" % int(total_dmg))
	if squad_hp <= 0: _on_defeat()

# ── 웨이브/스테이지 이벤트 ────────────────────────────────────
func _on_wave_clear():
	active = false
	var reward = 50.0 + wave * 25.0
	GameData.add_gold(reward)
	emit_signal("wave_cleared", wave, reward)
	emit_signal("battle_log", "✅ 웨이브 %d 클리어! +%.0f🪙" % [wave, reward])
	wave += 1
	await get_tree().create_timer(1.8 / speed).timeout
	_spawn_wave(wave)
	active = true
	emit_signal("wave_started", wave)

func _on_defeat():
	active = false
	emit_signal("battle_log", "💔 스쿼드 전멸... 재시작")
	await get_tree().create_timer(3.0).timeout
	_recalc_squad()
	wave = maxf(wave - 1, 1) as int
	_spawn_wave(wave)
	active = true
	emit_signal("wave_started", wave)

# ── 적 스폰 ───────────────────────────────────────────────────
func _spawn_wave(w: int):
	enemies.clear()
	var count    = mini(3 + int(w / 2), 8)
	var is_boss  = (w % 5 == 0)
	var scale    = 1.0 + w * 0.18

	var names = ["치즈파 조폭","치즈파 경비대","치즈파 저격수","치즈파 탱커","치즈파 마법사"]
	for i in range(count):
		if is_boss and i == count - 1:
			enemies.append(Enemy.new(i, "치즈파 두목 [%dW]" % w,
				10000.0 * scale, 200.0 * scale, true, Color(0.85,0.10,0.10)))
		else:
			enemies.append(Enemy.new(i, names[i % names.size()],
				1500.0 * scale, 90.0 * scale, false, Color(0.65,0.25,0.18)))

# ── 유틸 ──────────────────────────────────────────────────────
func _pick_target(alive: Array) -> Enemy:
	var t = alive[0]
	for e in alive:
		if e.hp < t.hp: t = e
	return t

func get_alive() -> Array:
	return enemies.filter(func(e): return e.alive())

func synergy_labels() -> Array:
	return synergy.get("active_labels", [])
