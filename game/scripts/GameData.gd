extends Node
# ============================================================
# GameData.gd — AutoLoad Singleton
# ============================================================

enum AnimalGroup { BEAST, SKY, SCALE, MARINE }
enum PrimaryJob   { COWBOY, VIKING, RONIN, MERCENARY }
enum SecondaryJob { SHERIFF, WARRIOR, HITMAN, SUPPORTER }
enum Environment  { SNOW, DESERT, SWAMP, URBAN }
enum UnitSize     { SMALL, MEDIUM, LARGE }

# ── AgentData ─────────────────────────────────────────────────
class AgentData:
	var id: int;       var name_kr: String; var name_en: String
	var animal: String; var size: int;      var animal_group: int
	var primary_job: int; var secondary_job: int
	var environments: Array; var rarity: int
	var base_atk: float; var base_hp: float
	var skill_name: String; var skill_desc: String
	var color: Color
	# 성장
	var level: int = 1
	var current_core: int = 1
	# 편의 별칭 (뷰에서 직접 접근)
	var group: String = ""
	var job: String = ""
	var skill: String = ""

	func _init(p_id,p_nk,p_ne,p_ani,p_sz,p_grp,p_pj,p_sj,p_envs,p_rar,p_atk,p_hp,p_sn,p_sd,p_col):
		id=p_id; name_kr=p_nk; name_en=p_ne; animal=p_ani
		size=p_sz; animal_group=p_grp; primary_job=p_pj
		secondary_job=p_sj; environments=p_envs; rarity=p_rar
		base_atk=p_atk; base_hp=p_hp; skill_name=p_sn; skill_desc=p_sd; color=p_col
		skill = p_sn
		match p_grp:
			0: group = "포유류"
			1: group = "조류"
			2: group = "파충류"
			3: group = "어류"
		match p_pj:
			0: job = "카우보이"
			1: job = "바이킹"
			2: job = "낭인"
			3: job = "용병"

	func get_atk() -> float: return base_atk * (1.0 + 0.08 * (level - 1))
	func get_hp()  -> float: return base_hp  * (1.0 + 0.10 * (level - 1))
	func get_group_name() -> String: return group
	func get_job_name()   -> String: return job

# ── Equipment ─────────────────────────────────────────────────
class Equipment:
	var id: int; var name_kr: String
	var slot: String   # weapon / armor / helmet / boots / ring / artifact
	var rarity: int; var level: int = 0
	var set_id: String
	var atk_pct: float; var hp_pct: float; var spd_pct: float
	func _init(p_id,p_n,p_sl,p_r,p_a,p_h,p_s,p_set=""):
		id=p_id; name_kr=p_n; slot=p_sl; rarity=p_r
		atk_pct=p_a; hp_pct=p_h; spd_pct=p_s; set_id=p_set
	func total_atk() -> float: return atk_pct * (1.0 + 0.1 * level)
	func total_hp()  -> float: return hp_pct  * (1.0 + 0.1 * level)
	func enhance_cost() -> int: return 200 * rarity * (level + 1)

# ── Relic (팀 전체 수동 버프) ──────────────────────────────────
class Relic:
	var id: int; var name_kr: String; var desc: String
	var rarity: int
	var global_atk: float; var global_hp: float
	var global_gold: float; var crit_bonus: float
	func _init(p_id,p_n,p_d,p_r,p_a,p_h,p_g,p_c):
		id=p_id; name_kr=p_n; desc=p_d; rarity=p_r
		global_atk=p_a; global_hp=p_h; global_gold=p_g; crit_bonus=p_c

# ── 플레이어 기본 상태 ────────────────────────────────────────
var player_name: String   = "대원"
var player_level: int     = 1
var gold: float           = 2000.0
var gems: int             = 300
var current_stage: String = "W1-1"

# ── 소환 재화 ─────────────────────────────────────────────────
var summon_tickets: int  = 5     # 소환권 (일반)
var rare_tickets: int    = 0     # 고급 소환권
var legend_tickets: int  = 2     # 전설 소환권
var friend_points: int   = 100   # 우정 포인트 (50=소환1회)

# ── 가챠 피티 (배너별) ────────────────────────────────────────
# hard_pity: 이벤트=50, 영웅=80, 전설=20, 우정=5(3★)
var banner_pity:  Dictionary = {"event":0,"hero":0,"legend":0,"friend":0}
var banner_4pity: Dictionary = {"event":0,"hero":0,"legend":0}  # 10연 4★ 보장
var last_free_pull: String   = ""  # "YYYY-MM-DD"

# ── 소환 기록 (최근 60회) ────────────────────────────────────
var pull_history: Dictionary = {"event":[],"hero":[],"legend":[]}

# ── 유닛 소유 ─────────────────────────────────────────────────
var unit_copies: Dictionary = {}   # {id: count}
var pity: int = 0                  # legacy (이벤트 배너와 동기)
var all_agents: Array  = []
var owned_ids:  Array  = []
var squad:      Array  = []        # 최대 6

# ── 장비 소유 ─────────────────────────────────────────────────
var equipment_db: Array = []
var owned_equipment: Dictionary = {}   # {equip_id: count}
var unit_gear: Dictionary = {}         # {unit_id: {slot: equip_id}}  (-1=빈칸)

# ── 유물 소유 ─────────────────────────────────────────────────
var relic_db: Array = []
var owned_relics: Array  = []   # [relic_id, ...]
var active_relics: Array = []   # 최대 3

# ── 일일 퀘스트 ───────────────────────────────────────────────
var quest_reset_date: String = ""
var quest_points: int = 0
var quest_completed: Array = []  # [quest_id, ...]

# ── 투기장 ────────────────────────────────────────────────────
var arena_rank: int = 1500
var arena_tickets: int = 5
var arena_wins_today: int = 0
var arena_ticket_date: String = ""

# ── 던전 ──────────────────────────────────────────────────────
var dungeon_keys: Dictionary = {"gold": 3, "material": 3, "elite": 1}
var dungeon_records: Dictionary = {}   # {"gold_3": 3stars, ...}
var dungeon_key_date: String = ""

# ── 파견 (원정) ───────────────────────────────────────────────
var dispatches: Array = []   # [{unit_id, mission_id, end_time, gold, ticket}]

# ── 방치 상자 ─────────────────────────────────────────────────
var idle_chest_start: float = 0.0
const IDLE_CHEST_MAX := 14400.0   # 4시간 (초)
const IDLE_CHEST_GOLD_PER_SEC := 5.0
const IDLE_CHEST_MAT_PER_HOUR := 3

# ── 배틀패스 ──────────────────────────────────────────────────
var bp_season: int  = 1
var bp_level: int   = 1
var bp_exp: int     = 0
var bp_premium: bool = false
var bp_claimed: Array = []   # [level, ...]

# ── 로그인 스트릭 ─────────────────────────────────────────────
var login_streak: int  = 1
var last_login: String = ""

# ── 업적 카운터 ───────────────────────────────────────────────
var ach: Dictionary = {
	"total_pulls": 0, "total_stages": 0,
	"total_gold": 0.0, "arena_wins": 0, "dungeon_clears": 0,
}

# ─────────────────────────────────────────────────────────────
func _ready():
	_build_database()
	_build_equipment_db()
	_build_relic_db()
	_init_prototype()
	idle_chest_start = Time.get_unix_time_from_system()

func _init_prototype():
	# 프로토타입: 전 유닛 보유
	for a in all_agents:
		owned_ids.append(a.id)
		unit_copies[a.id] = 1
	# 기본 스쿼드
	for id in [1, 2, 3, 9, 11, 12]:
		var a = get_by_id(id); if a: squad.append(a)
	# 장비 슬롯 초기화
	for a in all_agents:
		unit_gear[a.id] = {"weapon":-1,"armor":-1,"helmet":-1,"boots":-1,"ring":-1,"artifact":-1}
	# 유물 초기 제공
	owned_relics = [1, 2, 3, 4]
	active_relics = [1, 2]
	# 장비 초기 지급
	owned_equipment = {1:2, 2:1, 5:1, 9:1, 13:1}

# ── 유닛 조회 ─────────────────────────────────────────────────
func get_by_id(id: int) -> AgentData:
	for a in all_agents:
		if a.id == id: return a
	return null

func get_owned() -> Array:
	var r = []
	for id in owned_ids:
		var a = get_by_id(id); if a: r.append(a)
	return r

func is_owned(id: int) -> bool: return id in owned_ids
func is_in_squad(a: AgentData) -> bool: return a in squad

# ── 스쿼드 ────────────────────────────────────────────────────
func add_to_squad(a: AgentData) -> bool:
	if squad.size() >= 6 or a in squad: return false
	squad.append(a); return true

func remove_from_squad(a: AgentData): squad.erase(a)

func squad_power() -> int:
	var p = 0
	for a in squad: p += int(a.get_atk() + a.get_hp() * 0.1) * a.rarity
	# 유물 보너스 포함
	var rb = get_relic_bonuses()
	return int(p * (1.0 + rb.global_atk))

# ── 재화 ──────────────────────────────────────────────────────
func add_gold(n: float):
	gold += n
	ach["total_gold"] += n

func spend_gold(n: float) -> bool:
	if gold < n: return false
	gold -= n; return true

func add_gems(n: int):  gems += n
func spend_gems(n: int) -> bool:
	if gems < n: return false
	gems -= n; return true

# ─────────────────────────────────────────────────────────────
# 가챠 시스템
# ─────────────────────────────────────────────────────────────

const BANNER_CONFIG := {
	"event": {
		"name": "이벤트 배너",
		"rate5": 0.020, "rate4": 0.080,
		"hard5": 50, "hard4": 10,
		"soft_start": 40, "soft_per": 0.04,
		"featured5": [1, 11],   # 50% 확률로 선택
		"featured4": [15],
		"pool3": [16,17,18,19,20,21],
		"pool4": [13,14,15],
		"pool5": [1,2,3,4,5,6,7,8,9,10,11,12],
	},
	"hero": {
		"name": "일반 영웅 소환",
		"rate5": 0.015, "rate4": 0.085,
		"hard5": 80, "hard4": 10,
		"soft_start": 65, "soft_per": 0.03,
		"featured5": [], "featured4": [],
		"pool3": [16,17,18,19,20,21],
		"pool4": [13,14,15],
		"pool5": [1,2,3,4,5,6,7,8,9,10,11,12],
	},
	"legend": {
		"name": "전설 소환",
		"rate5": 0.150, "rate4": 0.850,
		"hard5": 20, "hard4": 5,
		"soft_start": 15, "soft_per": 0.10,
		"featured5": [], "featured4": [],
		"pool3": [],
		"pool4": [13,14,15],
		"pool5": [1,2,3,4,5,6,7,8,9,10,11,12],
	},
	"friend": {
		"name": "우정 소환",
		"rate5": 0.0, "rate4": 0.0,
		"hard5": 999, "hard4": 5,
		"soft_start": 999, "soft_per": 0.0,
		"featured5": [], "featured4": [],
		"pool3": [16,17,18], "pool4": [], "pool5": [],
	},
}

func banner_pull(banner_key: String, count: int) -> Array:
	var cfg = BANNER_CONFIG.get(banner_key, BANNER_CONFIG["hero"])
	var results := []
	var hist: Array = pull_history.get(banner_key, [])

	for _i in count:
		var agent = _pull_one_banner(banner_key, cfg)
		results.append(agent)
		hist.append(agent.rarity)
		if hist.size() > 60: hist.pop_front()

	pull_history[banner_key] = hist
	ach["total_pulls"] += count
	_add_quest_progress("pull", count)
	return results

func _pull_one_banner(key: String, cfg: Dictionary) -> AgentData:
	var p5 = banner_pity.get(key, 0) + 1
	banner_pity[key] = p5
	pity = banner_pity.get("event", 0)  # legacy sync

	var p4 = banner_4pity.get(key, 0) + 1
	banner_4pity[key] = p4

	# 소프트 피티 계산
	var rate5 = cfg["rate5"]
	var over = p5 - cfg["soft_start"]
	if over > 0: rate5 = minf(rate5 + cfg["soft_per"] * over, 1.0)

	var roll = randf()
	var chosen: AgentData

	if p5 >= cfg["hard5"] or roll < rate5:
		# 5★ 확정
		chosen = _pick_from_pool(cfg["pool5"], cfg["featured5"])
		banner_pity[key] = 0
		banner_4pity[key] = 0
	elif p4 >= cfg["hard4"] or roll < cfg["rate5"] + cfg["rate4"]:
		# 4★ 확정
		chosen = _pick_from_pool(cfg["pool4"], cfg["featured4"])
		banner_4pity[key] = 0
	else:
		# 3★
		var pool3: Array = cfg["pool3"]
		if pool3.is_empty(): pool3 = [16,17,18]
		chosen = get_by_id(pool3[randi() % pool3.size()])

	# 보유 처리
	if chosen:
		if not is_owned(chosen.id): owned_ids.append(chosen.id)
		unit_copies[chosen.id] = unit_copies.get(chosen.id, 0) + 1
		if not unit_gear.has(chosen.id):
			unit_gear[chosen.id] = {"weapon":-1,"armor":-1,"helmet":-1,"boots":-1,"ring":-1,"artifact":-1}

	return chosen if chosen else all_agents[0]

func _pick_from_pool(pool: Array, featured: Array) -> AgentData:
	if pool.is_empty(): return all_agents[0]
	var pick_id: int
	if not featured.is_empty() and randf() < 0.5:
		pick_id = featured[randi() % featured.size()]
	else:
		pick_id = pool[randi() % pool.size()]
	return get_by_id(pick_id) if get_by_id(pick_id) else all_agents[0]

# 레거시 (SummonView 구버전 호환)
func gacha_pull(count: int) -> Array:
	return banner_pull("hero", count)

func can_free_pull() -> bool:
	return last_free_pull != _today()

func use_free_pull() -> Array:
	last_free_pull = _today()
	return banner_pull("hero", 1)

func _today() -> String:
	var t = Time.get_datetime_dict_from_system()
	return "%d-%02d-%02d" % [t["year"], t["month"], t["day"]]

# ─────────────────────────────────────────────────────────────
# 장비 시스템
# ─────────────────────────────────────────────────────────────
func get_equipment(id: int) -> Equipment:
	for e in equipment_db:
		if e.id == id: return e
	return null

func get_unit_equipment(unit_id: int) -> Dictionary:
	return unit_gear.get(unit_id, {})

func equip_item(unit_id: int, equip_id: int) -> bool:
	var eq = get_equipment(equip_id)
	if not eq: return false
	if not owned_equipment.get(equip_id, 0) > 0: return false
	var gear = unit_gear.get(unit_id, {})
	var old = gear.get(eq.slot, -1)
	if old != -1:
		# 기존 장비 반환
		owned_equipment[old] = owned_equipment.get(old, 0) + 1
	gear[eq.slot] = equip_id
	unit_gear[unit_id] = gear
	owned_equipment[equip_id] -= 1
	return true

func unequip_item(unit_id: int, slot: String):
	var gear = unit_gear.get(unit_id, {})
	var old = gear.get(slot, -1)
	if old == -1: return
	owned_equipment[old] = owned_equipment.get(old, 0) + 1
	gear[slot] = -1
	unit_gear[unit_id] = gear

func enhance_equipment(equip_id: int) -> bool:
	var eq = get_equipment(equip_id)
	if not eq or eq.level >= eq.rarity * 5: return false
	if not spend_gold(eq.enhance_cost()): return false
	eq.level += 1
	return true

func get_unit_equip_stats(unit_id: int) -> Dictionary:
	var atk_bonus = 0.0
	var hp_bonus  = 0.0
	var gear = unit_gear.get(unit_id, {})
	for slot in gear:
		var eid = gear[slot]
		if eid == -1: continue
		var eq = get_equipment(eid)
		if eq:
			atk_bonus += eq.total_atk()
			hp_bonus  += eq.total_hp()
	return {"atk": atk_bonus, "hp": hp_bonus}

# ─────────────────────────────────────────────────────────────
# 유물 시스템
# ─────────────────────────────────────────────────────────────
func get_relic(id: int) -> Relic:
	for r in relic_db:
		if r.id == id: return r
	return null

func get_relic_bonuses() -> Dictionary:
	var result = {"global_atk": 0.0, "global_hp": 0.0, "global_gold": 0.0, "crit_bonus": 0.0}
	for rid in active_relics:
		var r = get_relic(rid)
		if r:
			result["global_atk"]   += r.global_atk
			result["global_hp"]    += r.global_hp
			result["global_gold"]  += r.global_gold
			result["crit_bonus"]   += r.crit_bonus
	return result

func equip_relic(relic_id: int) -> bool:
	if relic_id in active_relics: return false
	if not relic_id in owned_relics: return false
	if active_relics.size() >= 3: return false
	active_relics.append(relic_id)
	return true

func unequip_relic(relic_id: int):
	active_relics.erase(relic_id)

# ─────────────────────────────────────────────────────────────
# 일일 퀘스트
# ─────────────────────────────────────────────────────────────
const DAILY_QUEST_DEFS := [
	{"id":1,"type":"pull",   "name":"소환 3회 진행",    "target":3,  "reward_gold":500,  "reward_gems":0,  "points":20},
	{"id":2,"type":"stage",  "name":"스테이지 5회 클리어","target":5, "reward_gold":800,  "reward_gems":5,  "points":30},
	{"id":3,"type":"arena",  "name":"투기장 2회 도전",   "target":2,  "reward_gold":300,  "reward_gems":10, "points":25},
	{"id":4,"type":"levelup","name":"레벨업 3회",        "target":3,  "reward_gold":600,  "reward_gems":0,  "points":20},
	{"id":5,"type":"dungeon","name":"던전 1회 입장",      "target":1,  "reward_gold":0,    "reward_gems":15, "points":35},
	{"id":6,"type":"shop",   "name":"상점 방문",          "target":1,  "reward_gold":200,  "reward_gems":0,  "points":10},
	{"id":7,"type":"pull",   "name":"10연 소환 1회",      "target":10, "reward_gold":0,    "reward_gems":20, "points":40},
	{"id":8,"type":"chest",  "name":"방치 상자 수령",     "target":1,  "reward_gold":300,  "reward_gems":5,  "points":20},
]

var _quest_progress: Dictionary = {}

func _reset_quests_if_needed():
	if quest_reset_date == _today(): return
	quest_reset_date = _today()
	quest_completed.clear()
	_quest_progress.clear()
	quest_points = 0

func get_daily_quests() -> Array:
	_reset_quests_if_needed()
	var result = []
	for q in DAILY_QUEST_DEFS:
		var d = q.duplicate()
		d["progress"] = _quest_progress.get(d["id"], 0)
		d["done"] = d["id"] in quest_completed
		result.append(d)
	return result

func _add_quest_progress(quest_type: String, amount: int):
	_reset_quests_if_needed()
	for q in DAILY_QUEST_DEFS:
		if q["type"] == quest_type and not q["id"] in quest_completed:
			var cur = _quest_progress.get(q["id"], 0) + amount
			_quest_progress[q["id"]] = cur
			if cur >= q["target"]:
				_quest_progress[q["id"]] = q["target"]

func claim_quest(quest_id: int) -> bool:
	_reset_quests_if_needed()
	if quest_id in quest_completed: return false
	var q = null
	for qd in DAILY_QUEST_DEFS:
		if qd["id"] == quest_id: q = qd; break
	if not q: return false
	if _quest_progress.get(quest_id, 0) < q["target"]: return false
	quest_completed.append(quest_id)
	quest_points += q["points"]
	add_gold(q["reward_gold"])
	add_gems(q["reward_gems"])
	_add_bp_exp(15)
	return true

func get_quest_daily_reward(tier: int) -> Dictionary:
	# tier 1=50pts, 2=100pts, 3=150pts, 4=200pts
	const TIERS = [
		{"pts":50,  "gold":1000, "gems":5,  "ticket":0},
		{"pts":100, "gold":2000, "gems":10, "ticket":1},
		{"pts":150, "gold":3000, "gems":20, "ticket":0},
		{"pts":200, "gold":5000, "gems":30, "ticket":1},
	]
	return TIERS[clampi(tier - 1, 0, TIERS.size() - 1)]

# ─────────────────────────────────────────────────────────────
# 투기장
# ─────────────────────────────────────────────────────────────
func get_arena_opponents() -> Array:
	# 고정 AI 덱 (프로토타입)
	return [
		{"name":"치즈단 부두목",   "power": arena_rank + randi_range(-100, 100), "rank": arena_rank - 1},
		{"name":"황야의 갱단장",   "power": arena_rank + randi_range(-200, 200), "rank": arena_rank + 50},
		{"name":"도시 마피아 킹",  "power": arena_rank + randi_range(-300, 50),  "rank": arena_rank + 200},
	]

func do_arena_battle(opponent_power: int) -> bool:
	_reset_arena_if_needed()
	if arena_tickets <= 0: return false
	arena_tickets -= 1
	var my_power = squad_power()
	var win = my_power >= opponent_power * 0.9
	if win:
		arena_rank = maxi(1, arena_rank - randi_range(5, 15))
		arena_wins_today += 1
		ach["arena_wins"] += 1
		add_gold(200)
		add_gems(randi_range(3, 8))
		_add_quest_progress("arena", 1)
		_add_bp_exp(20)
	else:
		arena_rank = mini(9999, arena_rank + randi_range(1, 5))
		_add_quest_progress("arena", 1)
	return win

func _reset_arena_if_needed():
	if arena_ticket_date != _today():
		arena_ticket_date = _today()
		arena_tickets = 5
		arena_wins_today = 0

func get_arena_rank_label() -> String:
	if arena_rank <= 10:    return "🥇 챔피언"
	if arena_rank <= 50:    return "💎 그랜드마스터"
	if arena_rank <= 200:   return "🔵 마스터"
	if arena_rank <= 500:   return "🟣 다이아"
	if arena_rank <= 1000:  return "🟡 플래티넘"
	if arena_rank <= 2000:  return "🟢 골드"
	return "⚪ 실버"

# ─────────────────────────────────────────────────────────────
# 던전
# ─────────────────────────────────────────────────────────────
const DUNGEON_DEFS := {
	"gold": {
		"name": "🪙 골드 던전", "desc": "골드 획득",
		"levels": 5, "key_cost": 1,
		"base_reward_gold": [1000,2500,5000,10000,20000],
	},
	"material": {
		"name": "⚒ 재료 던전", "desc": "장비 재료 획득",
		"levels": 5, "key_cost": 1,
		"base_reward_mats": [2,5,10,20,40],
	},
	"elite": {
		"name": "⚔ 정예 던전", "desc": "고급 장비 획득",
		"levels": 3, "key_cost": 1,
		"base_reward_equip": [9,12,15],  # equipment id
	},
}

func enter_dungeon(dungeon_type: String, level: int) -> Dictionary:
	_reset_dungeon_if_needed()
	var keys = dungeon_keys.get(dungeon_type, 0)
	var cfg = DUNGEON_DEFS.get(dungeon_type, {})
	if keys <= 0 or cfg.is_empty(): return {"success": false, "msg": "열쇠 없음"}

	dungeon_keys[dungeon_type] = keys - 1
	var lvl = clampi(level - 1, 0, cfg["levels"] - 1)

	var reward = {}
	if dungeon_type == "gold":
		var g = cfg["base_reward_gold"][lvl]
		add_gold(float(g))
		reward = {"gold": g}
	elif dungeon_type == "material":
		# 재료는 owned_equipment에 범용 재료(id=0) 추가
		var m = cfg["base_reward_mats"][lvl]
		owned_equipment[0] = owned_equipment.get(0, 0) + m
		reward = {"mats": m}
	elif dungeon_type == "elite":
		var eid = cfg["base_reward_equip"][lvl]
		owned_equipment[eid] = owned_equipment.get(eid, 0) + 1
		reward = {"equip_id": eid}

	var record_key = "%s_%d" % [dungeon_type, level]
	dungeon_records[record_key] = 3  # 3스타 (프로토타입)
	ach["dungeon_clears"] += 1
	_add_quest_progress("dungeon", 1)
	_add_bp_exp(25)
	return {"success": true, "reward": reward}

func _reset_dungeon_if_needed():
	if dungeon_key_date != _today():
		dungeon_key_date = _today()
		dungeon_keys = {"gold": 3, "material": 3, "elite": 1}

func get_dungeon_record(dungeon_type: String, level: int) -> int:
	return dungeon_records.get("%s_%d" % [dungeon_type, level], 0)

# ─────────────────────────────────────────────────────────────
# 파견 (원정)
# ─────────────────────────────────────────────────────────────
const MISSION_DEFS := [
	{"id":1,"name":"치즈파 정찰","hours":2,"gold":500, "ticket":0,"slots":1},
	{"id":2,"name":"사막 탐험",   "hours":4,"gold":1200,"ticket":1,"slots":2},
	{"id":3,"name":"설원 소탕",   "hours":8,"gold":3000,"ticket":2,"slots":3},
]

func start_dispatch(unit_ids: Array, mission_id: int) -> bool:
	var mission = null
	for m in MISSION_DEFS:
		if m["id"] == mission_id: mission = m; break
	if not mission: return false
	if unit_ids.size() < mission["slots"]: return false
	# 이미 파견 중인지 체크
	for d in dispatches:
		for uid in unit_ids:
			if uid in d.get("unit_ids", []): return false
	dispatches.append({
		"unit_ids": unit_ids,
		"mission_id": mission_id,
		"end_time": Time.get_unix_time_from_system() + mission["hours"] * 3600,
		"gold": mission["gold"],
		"ticket": mission["ticket"],
	})
	return true

func check_dispatches() -> Array:
	var now = Time.get_unix_time_from_system()
	var completed = []
	var remaining = []
	for d in dispatches:
		if now >= d["end_time"]:
			add_gold(float(d["gold"]))
			summon_tickets += d.get("ticket", 0)
			completed.append(d)
		else:
			remaining.append(d)
	dispatches = remaining
	return completed

func is_unit_dispatched(unit_id: int) -> bool:
	for d in dispatches:
		if unit_id in d.get("unit_ids", []): return true
	return false

# ─────────────────────────────────────────────────────────────
# 방치 상자
# ─────────────────────────────────────────────────────────────
func get_idle_chest_data() -> Dictionary:
	var elapsed = minf(Time.get_unix_time_from_system() - idle_chest_start, IDLE_CHEST_MAX)
	var gold_amt = int(elapsed * IDLE_CHEST_GOLD_PER_SEC)
	var mat_amt  = int(elapsed / 3600.0 * IDLE_CHEST_MAT_PER_HOUR)
	var pct      = elapsed / IDLE_CHEST_MAX
	return {"gold": gold_amt, "mats": mat_amt, "pct": pct, "elapsed": elapsed}

func collect_idle_chest() -> Dictionary:
	var data = get_idle_chest_data()
	add_gold(float(data["gold"]))
	owned_equipment[0] = owned_equipment.get(0, 0) + data["mats"]
	idle_chest_start = Time.get_unix_time_from_system()
	_add_quest_progress("chest", 1)
	_add_bp_exp(10)
	return data

# ─────────────────────────────────────────────────────────────
# 배틀패스
# ─────────────────────────────────────────────────────────────
const BP_LEVEL_EXP := 100   # 레벨당 필요 exp

const BP_REWARDS := [
	{"level":1,  "free":{"gold":500},        "premium":{"gems":50}},
	{"level":2,  "free":{"ticket":1},        "premium":{"gems":50}},
	{"level":3,  "free":{"gold":1000},       "premium":{"rare_ticket":1}},
	{"level":4,  "free":{"gems":20},         "premium":{"gems":100}},
	{"level":5,  "free":{"ticket":2},        "premium":{"legend_ticket":1}},
	{"level":6,  "free":{"gold":2000},       "premium":{"gems":150}},
	{"level":7,  "free":{"gems":30},         "premium":{"rare_ticket":2}},
	{"level":8,  "free":{"ticket":3},        "premium":{"gems":200}},
	{"level":9,  "free":{"gold":5000},       "premium":{"legend_ticket":1}},
	{"level":10, "free":{"gems":50, "ticket":5}, "premium":{"gems":300, "legend_ticket":2}},
]

func _add_bp_exp(amount: int):
	bp_exp += amount
	while bp_exp >= BP_LEVEL_EXP and bp_level < BP_REWARDS.size():
		bp_exp -= BP_LEVEL_EXP
		bp_level += 1

func claim_bp_reward(level: int, premium: bool) -> bool:
	var key = "%d_%s" % [level, "p" if premium else "f"]
	if key in bp_claimed: return false
	if bp_level < level: return false
	if premium and not bp_premium: return false
	var rw = null
	for r in BP_REWARDS:
		if r["level"] == level:
			rw = r["premium"] if premium else r["free"]
			break
	if not rw: return false
	if rw.get("gold", 0) > 0:      add_gold(rw["gold"])
	if rw.get("gems", 0) > 0:      add_gems(rw["gems"])
	if rw.get("ticket", 0) > 0:    summon_tickets += rw["ticket"]
	if rw.get("rare_ticket", 0) > 0:   rare_tickets  += rw["rare_ticket"]
	if rw.get("legend_ticket", 0) > 0: legend_tickets += rw["legend_ticket"]
	bp_claimed.append(key)
	return true

# ─────────────────────────────────────────────────────────────
# 레벨업
# ─────────────────────────────────────────────────────────────
func level_up(a: AgentData) -> bool:
	var cost = 100 + a.level * 50 * a.rarity
	if not spend_gold(float(cost)): return false
	a.level += 1
	_add_quest_progress("levelup", 1)
	_add_bp_exp(5)
	return true

# ─────────────────────────────────────────────────────────────
# 세계관 & 상점
# ─────────────────────────────────────────────────────────────
func get_worlds() -> Array:
	return [
		{"id":"1","name":"치즈파 아지트","short":"아지트","drop":"골드·소환권","theme":"도시 뒷골목",
		 "color":Color(0.6,0.3,0.1),"stages":10},
		{"id":"2","name":"사막 황무지",  "short":"황무지","drop":"재료·골드",  "theme":"황야",
		 "color":Color(0.9,0.7,0.2),"stages":10},
		{"id":"3","name":"고산설원",     "short":"설원",  "drop":"고급 재료",  "theme":"빙설",
		 "color":Color(0.7,0.8,1.0),"stages":10},
		{"id":"4","name":"수중습지",     "short":"습지",  "drop":"유물 조각",  "theme":"수중",
		 "color":Color(0.2,0.6,0.4),"stages":10},
		{"id":"5","name":"사이버도시",   "short":"사이버","drop":"전설 파편",  "theme":"미래",
		 "color":Color(0.3,0.2,0.8),"stages":10},
	]

func get_shop_items() -> Array:
	return [
		{"type":"gold","name":"골드 소량",   "desc":"금화 1,000개","cost":5,  "currency":"gem","color":UITheme.GOLD},
		{"type":"gold","name":"골드 중량",   "desc":"금화 5,000개","cost":20, "currency":"gem","color":UITheme.GOLD},
		{"type":"gold","name":"골드 대량",   "desc":"금화 20,000개","cost":70,"currency":"gem","color":UITheme.GOLD},
		{"type":"summon","name":"소환권 ×3", "desc":"일반 소환 3회","cost":150,"currency":"gem","color":UITheme.CYAN},
		{"type":"summon","name":"고급 소환권","desc":"4★이상 확정","cost":300, "currency":"gem","color":UITheme.PURPLE},
		{"type":"summon","name":"전설 소환권","desc":"5★ 풀에서 소환","cost":0,"currency":"gold","cost_gold":50000,"color":UITheme.GOLD},
	]

# ─────────────────────────────────────────────────────────────
# 데이터베이스
# ─────────────────────────────────────────────────────────────
func _build_database():
	var G = AnimalGroup; var P = PrimaryJob
	var S = SecondaryJob; var E = Environment; var Sz = UnitSize
	all_agents = [
		AgentData.new(1, "킹 대령","Colonel King","독수리",Sz.MEDIUM,G.SKY,P.COWBOY,S.SHERIFF,[E.SNOW,E.DESERT],5,320,2800,"정밀 패닝 사격","단일 리볼버 연사",Color(0.95,0.75,0.15)),
		AgentData.new(2, "구스타프","Gustav","악어",Sz.LARGE,G.SCALE,P.VIKING,S.WARRIOR,[E.SNOW,E.SWAMP],5,280,3800,"빙하 진흙 격돌","전방 넉백+기절",Color(0.25,0.70,0.35)),
		AgentData.new(3, "백두","Baek-Du","호랑이",Sz.LARGE,G.BEAST,P.RONIN,S.WARRIOR,[E.SNOW,E.URBAN],5,350,3200,"설산 무영참","광역 얼음+결빙",Color(0.80,0.85,1.00)),
		AgentData.new(4, "펜릴","Fenrir","늑대",Sz.MEDIUM,G.BEAST,P.MERCENARY,S.HITMAN,[E.SNOW,E.URBAN],5,420,2400,"무리의 처형","단일 극대 피해",Color(0.50,0.50,0.62)),
		AgentData.new(5, "레이니","Rainy","독수리",Sz.SMALL,G.SKY,P.RONIN,S.SUPPORTER,[E.DESERT,E.SWAMP],5,290,2200,"폭풍 깃털 연격","다중 연속 피해",Color(0.40,0.62,0.90)),
		AgentData.new(6, "디아블로","Diablo","개구리",Sz.SMALL,G.SCALE,P.MERCENARY,S.SHERIFF,[E.DESERT,E.URBAN],5,260,2000,"맹독 가스 유탄","범위 중독",Color(0.30,0.85,0.25)),
		AgentData.new(7, "블랙마린","Black Marine","청새치",Sz.MEDIUM,G.MARINE,P.COWBOY,S.SUPPORTER,[E.DESERT,E.SWAMP],5,200,2600,"전술 호버 가이드","공속+40%",Color(0.15,0.40,0.90)),
		AgentData.new(8, "타이돈","Tydon","백상아리",Sz.LARGE,G.MARINE,P.VIKING,S.WARRIOR,[E.SWAMP,E.URBAN],5,310,4000,"사슬 닻 처형","부채꼴+출혈",Color(0.10,0.25,0.72)),
		AgentData.new(9, "볼칸","Volkan","타조",Sz.MEDIUM,G.SKY,P.RONIN,S.HITMAN,[E.SWAMP,E.URBAN],5,380,2600,"휠 키보드 돌파","관통+방어 감소",Color(0.70,0.25,0.88)),
		AgentData.new(10,"나야","Naya","킹코브라",Sz.SMALL,G.MARINE,P.RONIN,S.SUPPORTER,[E.SNOW,E.URBAN],5,220,2100,"홀로그램 카드 주작","전체 치명 100%",Color(0.85,0.55,0.95)),
		AgentData.new(11,"나폴레옹","Napoleon","펭귄",Sz.SMALL,G.SKY,P.COWBOY,S.HITMAN,[E.DESERT,E.URBAN],5,520,1800,"스나이퍼 대공포격","최강적 700% 헤드샷",Color(0.20,0.20,0.58)),
		AgentData.new(12,"무극","Wu-Geuk","판다",Sz.LARGE,G.BEAST,P.VIKING,S.SHERIFF,[E.SNOW,E.SWAMP],5,270,4500,"여의봉 블랙홀","전체 집결+기절",Color(0.14,0.14,0.14)),
		AgentData.new(13,"사자","Lion","사자",Sz.LARGE,G.BEAST,P.COWBOY,S.WARRIOR,[E.DESERT,E.URBAN],4,240,3000,"백수의 포효 사격","도탄 피해",Color(0.90,0.60,0.10)),
		AgentData.new(14,"재규어","Jaguar","재규어",Sz.MEDIUM,G.BEAST,P.MERCENARY,S.HITMAN,[E.SWAMP,E.URBAN],4,360,2200,"하수구 야습","최저체력 2연 치명타",Color(0.55,0.35,0.15)),
		AgentData.new(15,"공작","Peacock","공작",Sz.MEDIUM,G.SKY,P.RONIN,S.SUPPORTER,[E.SNOW,E.URBAN],4,180,2400,"천화만발 매혹안","적 이속-50%",Color(0.35,0.82,0.72)),
		AgentData.new(16,"코끼리","Elephant","코끼리",Sz.LARGE,G.BEAST,P.VIKING,S.SHERIFF,[E.DESERT,E.SWAMP],3,200,5000,"고압 수폭탄","전방 방어버프 제거",Color(0.60,0.60,0.72)),
		AgentData.new(17,"코뿔소","Rhino","코뿔소",Sz.LARGE,G.BEAST,P.VIKING,S.WARRIOR,[E.DESERT,E.SWAMP],3,220,4800,"철갑 돌격","일직선 돌진 피해",Color(0.50,0.50,0.55)),
		AgentData.new(18,"물소","Buffalo","물소",Sz.LARGE,G.BEAST,P.COWBOY,S.WARRIOR,[E.SNOW,E.SWAMP],3,210,4200,"대지진 발구르기","전체 공속-50%",Color(0.55,0.35,0.20)),
		AgentData.new(19,"펠리컨","Pelican","펠리컨",Sz.MEDIUM,G.SKY,P.MERCENARY,S.SUPPORTER,[E.SWAMP,E.URBAN],2,160,2000,"부리 보급","랜덤 2명 공격+25%",Color(0.80,0.75,0.45)),
		AgentData.new(20,"송골매","Falcon","송골매",Sz.SMALL,G.SKY,P.RONIN,S.HITMAN,[E.SNOW,E.DESERT],2,280,1600,"마하 수직강하","방어관통 쐐기",Color(0.70,0.55,0.22)),
		AgentData.new(21,"아나콘다","Anaconda","아나콘다",Sz.LARGE,G.SCALE,P.MERCENARY,S.HITMAN,[E.SWAMP,E.URBAN],1,140,3500,"똬리 구속","최대 적 속박+DoT",Color(0.20,0.60,0.20)),
	]

func _build_equipment_db():
	# slot: weapon / armor / helmet / boots / ring / artifact
	# atk_pct, hp_pct, spd_pct  (0.1 = +10%)
	equipment_db = [
		# ── 카우보이 세트 (공격형) ──
		Equipment.new(1, "리볼버 홀더",  "weapon",  3, 0.12, 0.00, 0.00, "cowboy"),
		Equipment.new(2, "보안관 배지",  "artifact",3, 0.08, 0.04, 0.00, "cowboy"),
		Equipment.new(3, "카우보이 햇",  "helmet",  3, 0.06, 0.02, 0.02, "cowboy"),
		Equipment.new(4, "가죽 장화",    "boots",   3, 0.04, 0.02, 0.04, "cowboy"),
		# ── 바이킹 세트 (방어형) ──
		Equipment.new(5, "북해 대검",    "weapon",  4, 0.15, 0.05, 0.00, "viking"),
		Equipment.new(6, "철갑 흉갑",    "armor",   4, 0.02, 0.20, 0.00, "viking"),
		Equipment.new(7, "뿔 투구",      "helmet",  4, 0.02, 0.15, 0.00, "viking"),
		Equipment.new(8, "바이킹 반지",  "ring",    4, 0.05, 0.10, 0.00, "viking"),
		# ── 낭인 세트 (속도형) ──
		Equipment.new(9,  "흑요석 도",    "weapon",  4, 0.10, 0.00, 0.08, "ronin"),
		Equipment.new(10, "닌자 복장",    "armor",   4, 0.04, 0.04, 0.10, "ronin"),
		Equipment.new(11, "면사 두건",    "helmet",  3, 0.02, 0.02, 0.08, "ronin"),
		Equipment.new(12, "초경 족보",    "boots",   3, 0.00, 0.00, 0.15, "ronin"),
		# ── 용병 세트 (균형형) ──
		Equipment.new(13, "군용 소총",    "weapon",  3, 0.10, 0.02, 0.02, "merc"),
		Equipment.new(14, "방탄 조끼",    "armor",   3, 0.04, 0.12, 0.00, "merc"),
		Equipment.new(15, "전술 장갑",    "ring",    3, 0.08, 0.04, 0.02, "merc"),
		# ── 전설급 단품 ──
		Equipment.new(16, "치즈파 두목의 지팡이","weapon", 5, 0.25, 0.10, 0.05, "legend"),
		Equipment.new(17, "황금 왕관",    "helmet",  5, 0.10, 0.20, 0.08, "legend"),
		Equipment.new(18, "불사 갑옷",    "armor",   5, 0.05, 0.35, 0.00, "legend"),
		Equipment.new(19, "속력의 부츠",  "boots",   5, 0.05, 0.05, 0.20, "legend"),
		Equipment.new(20, "전설의 반지",  "ring",    5, 0.15, 0.15, 0.10, "legend"),
	]

func _build_relic_db():
	# global_atk, global_hp, global_gold, crit_bonus  (0.1 = +10%)
	relic_db = [
		Relic.new(1, "황야의 심장",    "스쿼드 공격력 +8%",         3, 0.08, 0.00, 0.00, 0.00),
		Relic.new(2, "강철 의지",      "스쿼드 체력 +10%",           3, 0.00, 0.10, 0.00, 0.00),
		Relic.new(3, "금화의 바람",    "방치 골드 +20%",             3, 0.00, 0.00, 0.20, 0.00),
		Relic.new(4, "예리한 눈",      "치명타율 +5%",               4, 0.03, 0.00, 0.00, 0.05),
		Relic.new(5, "치즈파 전리품",  "공격력 +12%, 체력 +6%",      4, 0.12, 0.06, 0.00, 0.00),
		Relic.new(6, "황제의 인장",    "전투력 전방위 +10%",          4, 0.10, 0.10, 0.10, 0.05),
		Relic.new(7, "어둠의 각인",    "공격력 +20%, 체력 -5%",       5, 0.20,-0.05, 0.00, 0.10),
		Relic.new(8, "신성의 그릇",    "체력 +25%, 골드 +15%",        5, 0.00, 0.25, 0.15, 0.00),
		Relic.new(9, "전설의 휘장",    "모든 능력치 +15%",            5, 0.15, 0.15, 0.15, 0.08),
		Relic.new(10,"치즈파 두목 배지","공격력+25%, 치명타율+10%",   5, 0.25, 0.00, 0.00, 0.10),
	]

# ─────────────────────────────────────────────────────────────
# 업적 시스템
# ─────────────────────────────────────────────────────────────
const ACHIEVEMENT_DEFS := [
	{"id":"first_win",    "name":"첫 승리",       "desc":"스테이지 클리어 1회",     "type":"total_stages",   "goal":1,       "reward":{"gold":500}},
	{"id":"stage_10",     "name":"신병 탈출",      "desc":"스테이지 10회 클리어",    "type":"total_stages",   "goal":10,      "reward":{"gems":30}},
	{"id":"stage_50",     "name":"중급 전사",       "desc":"스테이지 50회 클리어",    "type":"total_stages",   "goal":50,      "reward":{"gems":80}},
	{"id":"stage_200",    "name":"정예 대원",       "desc":"스테이지 200회 클리어",   "type":"total_stages",   "goal":200,     "reward":{"gems":200}},
	{"id":"summon_10",    "name":"첫 소환",         "desc":"총 소환 10회",            "type":"total_pulls",    "goal":10,      "reward":{"gold":1000}},
	{"id":"summon_100",   "name":"소환 중독자",     "desc":"총 소환 100회",           "type":"total_pulls",    "goal":100,     "reward":{"gems":50}},
	{"id":"summon_500",   "name":"가챠 고수",       "desc":"총 소환 500회",           "type":"total_pulls",    "goal":500,     "reward":{"legend_ticket":1}},
	{"id":"collect_5",    "name":"팀 빌더",         "desc":"유닛 5종 보유",           "type":"unit_count",     "goal":5,       "reward":{"gold":2000}},
	{"id":"collect_10",   "name":"수집광",          "desc":"유닛 10종 보유",          "type":"unit_count",     "goal":10,      "reward":{"gems":50}},
	{"id":"collect_21",   "name":"완전 수집",       "desc":"전 유닛 21종 보유",       "type":"unit_count",     "goal":21,      "reward":{"legend_ticket":2}},
	{"id":"arena_win_10", "name":"투기장 참가자",   "desc":"투기장 10승",             "type":"arena_wins",     "goal":10,      "reward":{"gems":30}},
	{"id":"arena_win_50", "name":"투기장 강자",     "desc":"투기장 50승",             "type":"arena_wins",     "goal":50,      "reward":{"gems":100}},
	{"id":"dungeon_10",   "name":"던전 탐험가",     "desc":"던전 10회 클리어",        "type":"dungeon_clears", "goal":10,      "reward":{"gold":5000}},
	{"id":"tower_10",     "name":"탑 도전자",       "desc":"무한의 탑 10층 달성",     "type":"tower_record",   "goal":10,      "reward":{"gems":50}},
	{"id":"tower_50",     "name":"탑의 정복자",     "desc":"무한의 탑 50층 달성",     "type":"tower_record",   "goal":50,      "reward":{"gems":200}},
	{"id":"gold_100k",    "name":"황금 손",         "desc":"누적 골드 100,000",       "type":"total_gold",     "goal":100000,  "reward":{"gems":30}},
	{"id":"gold_1m",      "name":"골드 부자",       "desc":"누적 골드 1,000,000",     "type":"total_gold",     "goal":1000000, "reward":{"gems":100}},
	{"id":"boss_5",       "name":"보스 사냥꾼",     "desc":"월드 보스 5회 공격",       "type":"boss_attacks",   "goal":5,       "reward":{"gems":20}},
	{"id":"boss_30",      "name":"보스 킬러",       "desc":"월드 보스 30회 공격",      "type":"boss_attacks",   "goal":30,      "reward":{"gems":80}},
	{"id":"transcend_1",  "name":"초월의 시작",     "desc":"유닛 초월 1회",            "type":"transcend",      "goal":1,       "reward":{"gems":50}},
]

var ach_claimed: Array = []

func get_achievements() -> Array:
	var result = []
	for d in ACHIEVEMENT_DEFS:
		var entry = d.duplicate()
		entry["progress"]  = _get_ach_value(d["type"])
		entry["done"]      = d["id"] in ach_claimed
		entry["claimable"] = entry["progress"] >= d["goal"] and not entry["done"]
		result.append(entry)
	return result

func _get_ach_value(type_key: String) -> int:
	match type_key:
		"total_stages":   return int(ach.get("total_stages",   0))
		"total_pulls":    return int(ach.get("total_pulls",    0))
		"unit_count":     return owned_ids.size()
		"arena_wins":     return int(ach.get("arena_wins",     0))
		"dungeon_clears": return int(ach.get("dungeon_clears", 0))
		"tower_record":   return tower_record
		"total_gold":     return int(ach.get("total_gold",   0.0))
		"boss_attacks":   return int(ach.get("boss_attacks",   0))
		"transcend":      return int(ach.get("transcend",      0))
	return 0

func claim_achievement(ach_id: String) -> bool:
	if ach_id in ach_claimed: return false
	var d: Dictionary = {}
	for a in ACHIEVEMENT_DEFS:
		if a["id"] == ach_id: d = a; break
	if d.is_empty(): return false
	if _get_ach_value(d["type"]) < d["goal"]: return false
	ach_claimed.append(ach_id)
	var rw: Dictionary = d["reward"]
	if rw.get("gold",          0) > 0: add_gold(float(rw["gold"]))
	if rw.get("gems",          0) > 0: add_gems(rw["gems"])
	if rw.get("legend_ticket", 0) > 0: legend_tickets += rw["legend_ticket"]
	return true

# ─────────────────────────────────────────────────────────────
# 무한의 탑 (Endless Tower)
# ─────────────────────────────────────────────────────────────
var tower_floor:  int = 1   # 현재 도전 층
var tower_record: int = 0   # 최고 기록 층
var tower_attempts_today: int = 0
var tower_date: String = ""
const TOWER_DAILY_MAX := 3

func can_challenge_tower() -> bool:
	_reset_tower_if_needed()
	return tower_attempts_today < TOWER_DAILY_MAX

func challenge_tower() -> Dictionary:
	_reset_tower_if_needed()
	if not can_challenge_tower():
		return {"success": false, "msg": "오늘 도전 횟수 초과 (%d/%d)" % [tower_attempts_today, TOWER_DAILY_MAX]}
	tower_attempts_today += 1
	var power_req = 500 + tower_floor * 180
	var win = squad_power() >= int(power_req * 0.88)
	if win:
		var cleared = tower_floor
		tower_floor += 1
		tower_record = maxi(tower_record, cleared)
		var gold_r = cleared * 120
		var gem_r  = cleared * 2 if cleared % 10 == 0 else 0
		add_gold(float(gold_r))
		if gem_r > 0: add_gems(gem_r)
		_add_bp_exp(15)
		return {"success": true, "floor": cleared, "gold": gold_r, "gems": gem_r}
	else:
		return {"success": false, "floor": tower_floor,
			"msg": "전투력 부족 (필요 %d / 현재 %d)" % [power_req, squad_power()]}

func _reset_tower_if_needed():
	if tower_date != _today():
		tower_date = _today()
		tower_attempts_today = 0

# ─────────────────────────────────────────────────────────────
# 월드 보스 (World Boss)
# ─────────────────────────────────────────────────────────────
var world_boss_stage: int = 1
var world_boss_max_hp: int = 10_000_000
var world_boss_current_hp: int = 10_000_000
var world_boss_my_damage: int = 0
var world_boss_attacks_today: int = 0
var world_boss_date: String = ""
const WORLD_BOSS_DAILY_MAX := 3

func can_attack_boss() -> bool:
	_reset_boss_if_needed()
	return world_boss_attacks_today < WORLD_BOSS_DAILY_MAX

func attack_world_boss() -> Dictionary:
	_reset_boss_if_needed()
	if not can_attack_boss():
		return {"success": false, "msg": "오늘 도전 횟수 초과"}
	world_boss_attacks_today += 1
	ach["boss_attacks"] = ach.get("boss_attacks", 0) + 1
	var dmg = int(squad_power() * randf_range(0.85, 1.25) * 800)
	world_boss_my_damage += dmg
	world_boss_current_hp = maxi(0, world_boss_current_hp - dmg)
	var gem_r  = clampi(dmg / 4000, 1, 40)
	var gold_r = dmg / 8
	add_gems(gem_r); add_gold(float(gold_r))
	_add_bp_exp(20)
	var cleared = world_boss_current_hp <= 0
	if cleared:
		world_boss_stage  += 1
		world_boss_max_hp  = int(10_000_000 * pow(1.35, world_boss_stage - 1))
		world_boss_current_hp = world_boss_max_hp
		add_gems(100)
	return {"success": true, "damage": dmg, "gems": gem_r, "gold": gold_r, "cleared": cleared}

func get_boss_hp_pct() -> float:
	if world_boss_max_hp <= 0: return 0.0
	return float(world_boss_current_hp) / float(world_boss_max_hp)

func _reset_boss_if_needed():
	if world_boss_date != _today():
		world_boss_date = _today()
		world_boss_attacks_today = 0
		world_boss_my_damage = 0

# ─────────────────────────────────────────────────────────────
# 도감 (Collection Codex)
# ─────────────────────────────────────────────────────────────
func get_codex_bonus() -> Dictionary:
	var count = owned_ids.size()
	var atk = 0.0; var hp = 0.0
	if count >= 5:  atk += 0.02; hp += 0.02
	if count >= 10: atk += 0.03; hp += 0.03
	if count >= 15: atk += 0.05; hp += 0.05
	if count >= 21: atk += 0.10; hp += 0.10
	return {"atk": atk, "hp": hp, "count": count, "total": 21}

# ─────────────────────────────────────────────────────────────
# 초월 시스템 (Transcendence — 5★ 이후 성장)
# ─────────────────────────────────────────────────────────────
var unit_transcend: Dictionary = {}   # {unit_id: level 0-5}

func get_transcend_level(unit_id: int) -> int:
	return unit_transcend.get(unit_id, 0)

func get_transcend_cost(unit_id: int) -> int:
	return (get_transcend_level(unit_id) + 1) * 3

func can_transcend(unit_id: int) -> bool:
	var a = get_by_id(unit_id)
	if not a or a.rarity < 5: return false
	if get_transcend_level(unit_id) >= 5: return false
	return unit_copies.get(unit_id, 0) >= get_transcend_cost(unit_id)

func transcend_unit(unit_id: int) -> bool:
	if not can_transcend(unit_id): return false
	unit_copies[unit_id]      = unit_copies.get(unit_id, 0) - get_transcend_cost(unit_id)
	unit_transcend[unit_id]   = get_transcend_level(unit_id) + 1
	ach["transcend"]          = ach.get("transcend", 0) + 1
	_add_bp_exp(50)
	return true

func get_transcend_bonus(unit_id: int) -> Dictionary:
	const STEPS := [
		{"atk":0.00,"hp":0.00},
		{"atk":0.15,"hp":0.00},
		{"atk":0.15,"hp":0.15},
		{"atk":0.35,"hp":0.15},
		{"atk":0.35,"hp":0.35},
		{"atk":0.75,"hp":0.75},
	]
	var t = clampi(get_transcend_level(unit_id), 0, 5)
	return STEPS[t]

# ─────────────────────────────────────────────────────────────
# VIP 시스템
# ─────────────────────────────────────────────────────────────
var vip_level: int       = 0
var vip_total_spent: int = 0   # 누적 구매 원화 (₩)

const VIP_THRESHOLDS := [0, 10000, 30000, 100000, 300000, 1000000, 3000000]
const VIP_PERKS := [
	{"label":"없음",  "daily_gems":0,   "arena_bonus":0,  "gold_bonus":0.00},
	{"label":"VIP 1", "daily_gems":30,  "arena_bonus":1,  "gold_bonus":0.05},
	{"label":"VIP 2", "daily_gems":60,  "arena_bonus":2,  "gold_bonus":0.10},
	{"label":"VIP 3", "daily_gems":100, "arena_bonus":3,  "gold_bonus":0.15},
	{"label":"VIP 4", "daily_gems":150, "arena_bonus":5,  "gold_bonus":0.20},
	{"label":"VIP 5", "daily_gems":200, "arena_bonus":7,  "gold_bonus":0.25},
	{"label":"VIP 6", "daily_gems":300, "arena_bonus":10, "gold_bonus":0.30},
]

func get_vip_perks() -> Dictionary:
	return VIP_PERKS[clampi(vip_level, 0, VIP_PERKS.size() - 1)]

func get_vip_progress() -> float:
	if vip_level >= VIP_THRESHOLDS.size() - 1: return 1.0
	var cur = VIP_THRESHOLDS[vip_level]
	var nxt = VIP_THRESHOLDS[vip_level + 1]
	return float(vip_total_spent - cur) / float(nxt - cur)

func buy_gems_package(pkg_gems: int, pkg_krw: int):
	vip_total_spent += pkg_krw
	add_gems(pkg_gems)
	while vip_level < VIP_THRESHOLDS.size() - 1 and vip_total_spent >= VIP_THRESHOLDS[vip_level + 1]:
		vip_level += 1

# ─────────────────────────────────────────────────────────────
# 연구소 (Research Lab)
# ─────────────────────────────────────────────────────────────
const RESEARCH_DEFS := [
	{"id":"atk1",  "name":"공격력 연구 I",  "desc":"공격력 +2%/레벨", "type":"atk",  "cost_gold":5000,  "cost_gems":0, "max_lv":5},
	{"id":"hp1",   "name":"체력 연구 I",    "desc":"체력 +2%/레벨",   "type":"hp",   "cost_gold":5000,  "cost_gems":0, "max_lv":5},
	{"id":"gold1", "name":"채굴 연구 I",    "desc":"골드 +5%/레벨",   "type":"gold", "cost_gold":8000,  "cost_gems":0, "max_lv":5},
	{"id":"crit1", "name":"치명타 연구 I",  "desc":"치명타 +3%/레벨", "type":"crit", "cost_gold":10000, "cost_gems":0, "max_lv":5},
	{"id":"atk2",  "name":"공격력 연구 II", "desc":"공격력 +5%/레벨", "type":"atk",  "cost_gold":30000, "cost_gems":0, "max_lv":5, "req":"atk1:5"},
	{"id":"hp2",   "name":"체력 연구 II",   "desc":"체력 +5%/레벨",   "type":"hp",   "cost_gold":30000, "cost_gems":0, "max_lv":5, "req":"hp1:5"},
	{"id":"spd1",  "name":"이속 연구 I",    "desc":"이속 +3%/레벨",   "type":"spd",  "cost_gold":15000, "cost_gems":0, "max_lv":3},
	{"id":"pity1", "name":"소환 연구 I",    "desc":"피티 -2/레벨",    "type":"pity", "cost_gold":0,     "cost_gems":50,"max_lv":3},
]

const RESEARCH_PER_LV := {"atk":0.02,"hp":0.02,"gold":0.05,"crit":0.03,"spd":0.03}
const RESEARCH_PER_LV2 := {"atk2":0.05,"hp2":0.05}

var research_levels: Dictionary = {}

func get_research_level(rid: String) -> int:
	return research_levels.get(rid, 0)

func can_research(rid: String) -> bool:
	for d in RESEARCH_DEFS:
		if d["id"] != rid: continue
		if get_research_level(rid) >= d["max_lv"]: return false
		if d.has("req"):
			var parts = d["req"].split(":")
			if get_research_level(parts[0]) < int(parts[1]): return false
		return true
	return false

func do_research(rid: String) -> bool:
	if not can_research(rid): return false
	for d in RESEARCH_DEFS:
		if d["id"] != rid: continue
		if d["cost_gold"] > 0 and not spend_gold(float(d["cost_gold"])): return false
		if d["cost_gems"] > 0 and not spend_gems(d["cost_gems"]):        return false
		research_levels[rid] = get_research_level(rid) + 1
		_add_bp_exp(30)
		return true
	return false

func get_research_bonus() -> Dictionary:
	var r := {"atk":0.0,"hp":0.0,"gold":0.0,"crit":0.0,"spd":0.0}
	for d in RESEARCH_DEFS:
		var lvl = get_research_level(d["id"])
		if lvl <= 0: continue
		var per = RESEARCH_PER_LV2.get(d["id"], RESEARCH_PER_LV.get(d["type"], 0.0))
		r[d["type"]] = r.get(d["type"], 0.0) + per * lvl
	return r
