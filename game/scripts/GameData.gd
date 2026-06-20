extends Node
# ============================================================
# GameData.gd — AutoLoad Singleton (전체 게임 데이터)
# ============================================================

enum AnimalGroup { BEAST, SKY, SCALE, MARINE }
enum PrimaryJob   { COWBOY, VIKING, RONIN, MERCENARY }
enum SecondaryJob { SHERIFF, WARRIOR, HITMAN, SUPPORTER }
enum Environment  { SNOW, DESERT, SWAMP, URBAN }
enum UnitSize     { SMALL, MEDIUM, LARGE }

class AgentData:
	var id: int; var name_kr: String; var name_en: String
	var animal: String; var size: int; var animal_group: int
	var primary_job: int; var secondary_job: int
	var environments: Array; var rarity: int
	var base_atk: float; var base_hp: float
	var skill_name: String; var skill_desc: String
	var color: Color
	# 성장 상태
	var level: int = 1
	var current_core: int = 1
	var current_stars: int = 1

	func _init(p_id,p_nk,p_ne,p_ani,p_sz,p_grp,p_pj,p_sj,p_envs,p_rar,p_atk,p_hp,p_sn,p_sd,p_col):
		id=p_id; name_kr=p_nk; name_en=p_ne; animal=p_ani
		size=p_sz; animal_group=p_grp; primary_job=p_pj
		secondary_job=p_sj; environments=p_envs; rarity=p_rar
		base_atk=p_atk; base_hp=p_hp; skill_name=p_sn; skill_desc=p_sd; color=p_col

	func get_atk() -> float: return base_atk * (1.0 + 0.08 * (level - 1))
	func get_hp()  -> float: return base_hp  * (1.0 + 0.10 * (level - 1))
	func level_up_cost() -> int: return 100 * level * rarity
	func star_up_cost()  -> int: return current_stars * 3  # 중복 유닛 수

	func get_group_name() -> String:
		match animal_group:
			GameData.AnimalGroup.BEAST:  return "포유류"
			GameData.AnimalGroup.SKY:    return "조류"
			GameData.AnimalGroup.SCALE:  return "파충류"
			GameData.AnimalGroup.MARINE: return "어류"
		return "?"

	func get_job_name() -> String:
		match primary_job:
			GameData.PrimaryJob.COWBOY:    return "카우보이"
			GameData.PrimaryJob.VIKING:    return "바이킹"
			GameData.PrimaryJob.RONIN:     return "낭인"
			GameData.PrimaryJob.MERCENARY: return "용병"
		return "?"

# ── 플레이어 상태 ──────────────────────────────────────────
var player_name: String  = "대원"
var player_level: int    = 1
var gold: float          = 1000.0
var gems: int            = 50
var pity: int            = 0       # 가챠 천장 카운터
var current_stage: String = "1-1"

# 보유 유닛 수 (중복 카운트용)  {unit_id: count}
var unit_copies: Dictionary = {}

var all_agents:  Array = []
var owned_ids:   Array = []
var squad:       Array = []  # AgentData, 최대 6

# ── 초기화 ────────────────────────────────────────────────
func _ready():
	_build_database()
	# 프로토타입: 전 유닛 보유
	for a in all_agents:
		owned_ids.append(a.id)
		unit_copies[a.id] = 1
	# 기본 스쿼드
	for id in [1, 2, 3, 9, 11, 12]:
		var a = get_by_id(id)
		if a: squad.append(a)

# ── 유닛 조회 ─────────────────────────────────────────────
func get_by_id(id: int) -> AgentData:
	for a in all_agents:
		if a.id == id: return a
	return null

func get_owned() -> Array:
	var r = []
	for id in owned_ids:
		var a = get_by_id(id)
		if a: r.append(a)
	return r

func is_owned(id: int) -> bool: return id in owned_ids
func is_in_squad(a: AgentData) -> bool: return a in squad

# ── 스쿼드 관리 ───────────────────────────────────────────
func add_to_squad(a: AgentData) -> bool:
	if squad.size() >= 6 or a in squad: return false
	squad.append(a); return true

func remove_from_squad(a: AgentData): squad.erase(a)

func squad_power() -> int:
	var p = 0
	for a in squad: p += int(a.get_atk() + a.get_hp() * 0.1) * a.rarity
	return p

# ── 재화 ──────────────────────────────────────────────────
func add_gold(n: float):  gold += n
func spend_gold(n: float) -> bool:
	if gold < n: return false
	gold -= n; return true

func add_gems(n: int):  gems += n
func spend_gems(n: int) -> bool:
	if gems < n: return false
	gems -= n; return true

# ── 레벨업 ────────────────────────────────────────────────
func level_up(a: AgentData) -> bool:
	var cost = a.level_up_cost()
	if not spend_gold(cost): return false
	a.level += 1; return true

# ── 가챠 ──────────────────────────────────────────────────
func gacha_pull(count: int) -> Array:
	var cost = 100 * count
	if gems < cost: return []
	spend_gems(cost)
	var results = []
	for _i in range(count):
		pity += 1
		results.append(_pull_one())
	return results

func _pull_one() -> AgentData:
	var pool_5 = all_agents.filter(func(a): return a.rarity == 5)
	var pool_4 = all_agents.filter(func(a): return a.rarity == 4)
	var pool_3 = all_agents.filter(func(a): return a.rarity == 3)

	var roll = randf()
	var chosen: AgentData
	if pity >= 50 or roll < 0.02:
		chosen = pool_5[randi() % pool_5.size()]
		pity = 0
	elif roll < 0.10:
		chosen = pool_4[randi() % pool_4.size()]
	else:
		chosen = pool_3[randi() % pool_3.size()]

	# 보유 처리
	if not is_owned(chosen.id): owned_ids.append(chosen.id)
	unit_copies[chosen.id] = unit_copies.get(chosen.id, 0) + 1
	return chosen

# ── 세계관 스테이지 목록 ──────────────────────────────────
func get_worlds() -> Array:
	return [
		{"id":"1","name":"치즈파 아지트",   "stages":10, "color": Color(0.6,0.3,0.1)},
		{"id":"2","name":"사막 황무지",      "stages":10, "color": Color(0.9,0.7,0.2)},
		{"id":"3","name":"고산설원",          "stages":10, "color": Color(0.7,0.8,1.0)},
		{"id":"4","name":"수중습지",          "stages":10, "color": Color(0.2,0.6,0.4)},
		{"id":"5","name":"사이버도시",        "stages":10, "color": Color(0.3,0.2,0.8)},
	]

# ── 상점 아이템 ───────────────────────────────────────────
func get_shop_items() -> Array:
	return [
		{"name":"골드 소량",  "desc":"금화 1,000개",   "cost_gem":5,  "give":"gold",  "amount":1000},
		{"name":"골드 중량",  "desc":"금화 5,000개",   "cost_gem":20, "give":"gold",  "amount":5000},
		{"name":"골드 대량",  "desc":"금화 20,000개",  "cost_gem":70, "give":"gold",  "amount":20000},
		{"name":"소환석 10개","desc":"소환 10회 가능",  "cost_gem":0,  "give":"summon","amount":10, "cost_gold":5000},
		{"name":"경험치 포션","desc":"유닛 경험치+500", "cost_gem":15, "give":"exp",   "amount":500},
		{"name":"코어 결정체","desc":"코어 돌파 재료",  "cost_gem":30, "give":"core",  "amount":1},
	]

# ══════════════════════════════════════════════════════════
# 에이전트 데이터베이스
# ══════════════════════════════════════════════════════════
func _build_database():
	var G = AnimalGroup; var P = PrimaryJob
	var S = SecondaryJob; var E = Environment; var Sz = UnitSize
	all_agents = [
		# ── 5성 ──
		AgentData.new(1, "킹 대령","Colonel King","독수리",Sz.MEDIUM,G.SKY,   P.COWBOY,   S.SHERIFF,  [E.SNOW,E.DESERT], 5,320,2800,"정밀 패닝 사격","단일 리볼버 연사",         Color(0.95,0.75,0.15)),
		AgentData.new(2, "구스타프","Gustav",      "악어",  Sz.LARGE, G.SCALE, P.VIKING,   S.WARRIOR,  [E.SNOW,E.SWAMP],  5,280,3800,"빙하 진흙 격돌","전방 넉백+2초 기절",       Color(0.25,0.70,0.35)),
		AgentData.new(3, "백두",   "Baek-Du",     "호랑이",Sz.LARGE, G.BEAST, P.RONIN,    S.WARRIOR,  [E.SNOW,E.URBAN],  5,350,3200,"설산 무영참","광역 얼음+3초 결빙",         Color(0.80,0.85,1.00)),
		AgentData.new(4, "펜릴",   "Fenrir",       "늑대",  Sz.MEDIUM,G.BEAST, P.MERCENARY,S.HITMAN,   [E.SNOW,E.URBAN],  5,420,2400,"무리의 처형","단일 극대 피해",             Color(0.50,0.50,0.62)),
		AgentData.new(5, "레이니", "Rainy",        "독수리",Sz.SMALL, G.SKY,   P.RONIN,    S.SUPPORTER,[E.DESERT,E.SWAMP],5,290,2200,"폭풍 깃털 연격","다중 연속 피해",           Color(0.40,0.62,0.90)),
		AgentData.new(6, "디아블로","Diablo",      "개구리",Sz.SMALL, G.SCALE, P.MERCENARY,S.SHERIFF,  [E.DESERT,E.URBAN],5,260,2000,"맹독성 가스 유탄","범위 5초 중독",           Color(0.30,0.85,0.25)),
		AgentData.new(7, "블랙마린","Black Marine","청새치",Sz.MEDIUM,G.MARINE,P.COWBOY,   S.SUPPORTER,[E.DESERT,E.SWAMP],5,200,2600,"전술 호버 가이드","공속+40% 4초",            Color(0.15,0.40,0.90)),
		AgentData.new(8, "타이돈", "Tydon",        "백상아리",Sz.LARGE,G.MARINE,P.VIKING,  S.WARRIOR,  [E.SWAMP,E.URBAN], 5,310,4000,"사슬 닻 처형","부채꼴+확정 출혈",          Color(0.10,0.25,0.72)),
		AgentData.new(9, "볼칸",   "Volkan",       "타조",  Sz.MEDIUM,G.SKY,   P.RONIN,    S.HITMAN,   [E.SWAMP,E.URBAN], 5,380,2600,"휠 키보드 돌파","관통+방어-35% 6초",        Color(0.70,0.25,0.88)),
		AgentData.new(10,"나야",   "Naya",         "킹코브라",Sz.SMALL,G.MARINE,P.RONIN,   S.SUPPORTER,[E.SNOW,E.URBAN],  5,220,2100,"홀로그램 카드 주작","전체 치명 100% 3초",    Color(0.85,0.55,0.95)),
		AgentData.new(11,"나폴레옹","Napoleon",    "펭귄",  Sz.SMALL, G.SKY,   P.COWBOY,   S.HITMAN,   [E.DESERT,E.URBAN],5,520,1800,"스나이퍼 대공포격","최강 적 700% 헤드샷",    Color(0.20,0.20,0.58)),
		AgentData.new(12,"무극",   "Wu-Geuk",      "판다",  Sz.LARGE, G.BEAST, P.VIKING,   S.SHERIFF,  [E.SNOW,E.SWAMP],  5,270,4500,"여의봉 블랙홀","전체 집결+기절",            Color(0.14,0.14,0.14)),
		# ── 4성 ──
		AgentData.new(13,"사자",   "Lion",         "사자",  Sz.LARGE, G.BEAST, P.COWBOY,   S.WARRIOR,  [E.DESERT,E.URBAN],4,240,3000,"백수의 포효 사격","도탄 피해",               Color(0.90,0.60,0.10)),
		AgentData.new(14,"재규어", "Jaguar",        "재규어",Sz.MEDIUM,G.BEAST, P.MERCENARY,S.HITMAN,   [E.SWAMP,E.URBAN], 4,360,2200,"하수구 야습 암살","최저체력 2연 치명타",      Color(0.55,0.35,0.15)),
		AgentData.new(15,"공작",   "Peacock",       "공작",  Sz.MEDIUM,G.SKY,   P.RONIN,    S.SUPPORTER,[E.SNOW,E.URBAN],  4,180,2400,"천화만발 매혹안","적 이속-50%+아군+20%",    Color(0.35,0.82,0.72)),
		# ── 3성 ──
		AgentData.new(16,"코끼리", "Elephant",     "코끼리",Sz.LARGE, G.BEAST, P.VIKING,   S.SHERIFF,  [E.DESERT,E.SWAMP],3,200,5000,"코 고압 수폭탄","전방 방어버프 제거",        Color(0.60,0.60,0.72)),
		AgentData.new(17,"코뿔소", "Rhino",         "코뿔소",Sz.LARGE, G.BEAST, P.VIKING,   S.WARRIOR,  [E.DESERT,E.SWAMP],3,220,4800,"철갑 돌격","일직선 돌진 피해",             Color(0.50,0.50,0.55)),
		AgentData.new(18,"물소",   "Buffalo",       "물소",  Sz.LARGE, G.BEAST, P.COWBOY,   S.WARRIOR,  [E.SNOW,E.SWAMP],  3,210,4200,"대지진의 발구르기","전체 공속-50% 3초",     Color(0.55,0.35,0.20)),
		# ── 2성 ──
		AgentData.new(19,"펠리컨", "Pelican",       "펠리컨",Sz.MEDIUM,G.SKY,   P.MERCENARY,S.SUPPORTER,[E.SWAMP,E.URBAN], 2,160,2000,"부리 주머니 보급","랜덤 2명 공격+25%",      Color(0.80,0.75,0.45)),
		AgentData.new(20,"송골매", "Falcon",        "송골매",Sz.SMALL, G.SKY,   P.RONIN,    S.HITMAN,   [E.SNOW,E.DESERT], 2,280,1600,"마하 수직강하","방어관통 쐐기 피해",        Color(0.70,0.55,0.22)),
		# ── 1성 ──
		AgentData.new(21,"아나콘다","Anaconda",     "아나콘다",Sz.LARGE,G.SCALE,P.MERCENARY,S.HITMAN,  [E.SWAMP,E.URBAN], 1,140,3500,"똬리 구속","최대 적 2초 속박+DoT",          Color(0.20,0.60,0.20)),
	]
