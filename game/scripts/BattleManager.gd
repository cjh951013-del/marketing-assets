extends Node
# ============================================================
# BattleManager.gd — AutoLoad Singleton
# 전투 루프, 적 스폰, 골드 관리
# ============================================================

signal damage_dealt(target: String, amount: float, is_crit: bool)
signal enemy_died(enemy_id: int)
signal wave_started(wave_num: int)
signal wave_cleared(wave_num: int, gold_reward: float)
signal squad_hp_changed(current: float, maximum: float)
signal gold_updated(amount: float)
signal battle_log(msg: String)

# ── 적 데이터 구조 ────────────────────────────────────────────
class Enemy:
	var id:       int
	var name_kr:  String
	var hp:       float
	var max_hp:   float
	var atk:      float
	var is_boss:  bool
	var color:    Color

	func _init(p_id, p_name, p_hp, p_atk, p_boss, p_color):
		id = p_id; name_kr = p_name
		hp = p_hp; max_hp = p_hp; atk = p_atk
		is_boss = p_boss; color = p_color

	func is_alive() -> bool:
		return hp > 0.0

	func take_damage(dmg: float) -> float:
		var actual = min(dmg, hp)
		hp -= actual
		return actual

	func hp_ratio() -> float:
		if max_hp <= 0: return 0.0
		return hp / max_hp

# ── 상태 ─────────────────────────────────────────────────────
var current_enemies:  Array  = []
var squad_hp:         float  = 0.0
var squad_max_hp:     float  = 0.0
var synergy:          Dictionary = {}
var owned_effects:    Dictionary = {}

var is_battle_active: bool  = false
var idle_timer:       float = 0.0
const IDLE_GOLD_PER_SEC: float = 2.0  # 방치 골드/초
const ATTACK_INTERVAL:   float = 1.5  # 스쿼드 공격 주기 (초)
const ENEMY_ATTACK_INTERVAL: float = 2.0
var attack_timer: float = 0.0
var enemy_attack_timer: float = 0.0

# ── 시작 ─────────────────────────────────────────────────────
func _ready():
	pass

func start_battle():
	_recalculate_squad_stats()
	_spawn_wave(GameData.wave)
	is_battle_active = true
	emit_signal("wave_started", GameData.wave)

func _recalculate_squad_stats():
	synergy      = SynergyManager.calculate(GameData.squad)
	owned_effects = SynergyManager.calculate_owned_effects(GameData.get_owned_agents())

	squad_max_hp = 0.0
	for agent in GameData.squad:
		var hp = agent.get_hp_at_level(1) * synergy.max_hp * (1.0 + owned_effects.global_hp)
		squad_max_hp += hp
	squad_hp = squad_max_hp
	emit_signal("squad_hp_changed", squad_hp, squad_max_hp)

# ── 메인 루프 ────────────────────────────────────────────────
func _process(delta: float):
	# 방치 골드
	idle_timer += delta
	if idle_timer >= 1.0:
		idle_timer = 0.0
		var gold_bonus = 1.0 + synergy.get("global_gold", 0.0)
		var idle_gold = IDLE_GOLD_PER_SEC * gold_bonus
		GameData.add_gold(idle_gold)
		emit_signal("gold_updated", GameData.gold)

	if not is_battle_active:
		return

	# 스쿼드 공격
	attack_timer += delta
	if attack_timer >= ATTACK_INTERVAL:
		attack_timer = 0.0
		_squad_attack()

	# 적 공격
	enemy_attack_timer += delta
	if enemy_attack_timer >= ENEMY_ATTACK_INTERVAL:
		enemy_attack_timer = 0.0
		_enemies_attack()

# ── 스쿼드 공격 ──────────────────────────────────────────────
func _squad_attack():
	if GameData.squad.is_empty() or current_enemies.is_empty():
		return

	var alive_enemies = current_enemies.filter(func(e): return e.is_alive())
	if alive_enemies.is_empty():
		return

	for agent in GameData.squad:
		if alive_enemies.is_empty():
			break
		var target = _pick_target(alive_enemies)
		_agent_attack(agent, target, alive_enemies)

	# 웨이브 클리어 확인
	var remaining = current_enemies.filter(func(e): return e.is_alive())
	if remaining.is_empty():
		_on_wave_cleared()

# ── 단일 에이전트 공격 ───────────────────────────────────────
func _agent_attack(agent, target: Enemy, alive_enemies: Array):
	var base_dmg = agent.get_atk_at_level(1)
	var dmg = base_dmg * synergy.final_damage * (1.0 + owned_effects.global_atk)

	var is_crit = false
	var crit_chance = synergy.crit_rate
	if crit_chance > 0 and randf() < crit_chance:
		dmg *= 2.0
		is_crit = true

	var actual = target.take_damage(dmg)
	emit_signal("damage_dealt", target.name_kr, actual, is_crit)

	if not target.is_alive():
		emit_signal("enemy_died", target.id)
		emit_signal("battle_log", "💀 %s 격파!" % target.name_kr)

# ── 적 공격 ──────────────────────────────────────────────────
func _enemies_attack():
	var alive = current_enemies.filter(func(e): return e.is_alive())
	if alive.is_empty():
		return
	var total_dmg = 0.0
	for enemy in alive:
		total_dmg += enemy.atk
	if synergy.cc_immunity:
		total_dmg *= 0.5  # CC 면역 시 적 대미지 50% 감소 (단순화)
	squad_hp = max(0.0, squad_hp - total_dmg)
	emit_signal("squad_hp_changed", squad_hp, squad_max_hp)
	emit_signal("battle_log", "🩸 치즈파 공격! -%d HP" % int(total_dmg))

	if squad_hp <= 0:
		_on_squad_defeated()

# ── 웨이브 클리어 ────────────────────────────────────────────
func _on_wave_cleared():
	is_battle_active = false
	var gold_reward = 50.0 + GameData.wave * 20.0
	GameData.add_gold(gold_reward)
	emit_signal("gold_updated", GameData.gold)
	emit_signal("wave_cleared", GameData.wave, gold_reward)
	emit_signal("battle_log", "✅ 웨이브 %d 클리어! +%.0f 골드" % [GameData.wave, gold_reward])
	GameData.wave += 1
	await get_tree().create_timer(2.0).timeout
	_spawn_wave(GameData.wave)
	is_battle_active = true
	emit_signal("wave_started", GameData.wave)

func _on_squad_defeated():
	is_battle_active = false
	emit_signal("battle_log", "💔 스쿼드 전멸... 5초 후 재도전")
	await get_tree().create_timer(5.0).timeout
	_recalculate_squad_stats()
	_spawn_wave(GameData.wave)
	is_battle_active = true

# ── 적 스폰 ──────────────────────────────────────────────────
func _spawn_wave(wave_num: int):
	current_enemies.clear()
	var enemy_count = 3 + int(wave_num / 3)
	var is_boss_wave = wave_num % 5 == 0

	for i in range(enemy_count):
		var scale = 1.0 + wave_num * 0.15
		if is_boss_wave and i == enemy_count - 1:
			current_enemies.append(Enemy.new(
				i, "치즈파 대장 [%d웨이브]" % wave_num,
				8000 * scale, 180 * scale, true, Color(0.8, 0.1, 0.1)
			))
		else:
			var names = ["치즈파 조폭", "치즈파 경비대", "치즈파 저격수", "치즈파 탱크"]
			current_enemies.append(Enemy.new(
				i, names[i % names.size()],
				1200 * scale, 80 * scale, false, Color(0.7, 0.3, 0.2)
			))

	attack_timer = 0.0
	enemy_attack_timer = 0.0

# ── 유틸 ────────────────────────────────────────────────────
func _pick_target(alive_enemies: Array) -> Enemy:
	# 기본: 가장 체력 낮은 적 타겟
	var target = alive_enemies[0]
	for e in alive_enemies:
		if e.hp < target.hp:
			target = e
	return target

func get_alive_enemies() -> Array:
	return current_enemies.filter(func(e): return e.is_alive())

func update_squad():
	_recalculate_squad_stats()
