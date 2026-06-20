extends Node
# ============================================================
# GameData.gd — AutoLoad Singleton
# 모든 유닛 데이터 및 글로벌 게임 상태
# ============================================================

enum AnimalGroup { BEAST, SKY, SCALE, MARINE }
enum PrimaryJob   { COWBOY, VIKING, RONIN, MERCENARY }
enum SecondaryJob { SHERIFF, WARRIOR, HITMAN, SUPPORTER }
enum Environment  { SNOW, DESERT, SWAMP, URBAN }
enum UnitSize     { SMALL, MEDIUM, LARGE }

class AgentData:
	var id:           int
	var name_kr:      String
	var name_en:      String
	var animal:       String
	var size:         int
	var animal_group: int
	var primary_job:  int
	var secondary_job:int
	var environments: Array
	var rarity:       int    # 1~5성
	var base_atk:     float
	var base_hp:      float
	var skill_name:   String
	var skill_desc:   String
	var color:        Color  # 프로토타입용 대표 색상
	# 현재 성장 상태
	var current_core:  int = 1
	var current_stars: int = 1

	func _init(p_id, p_nk, p_ne, p_ani, p_sz, p_grp, p_pj, p_sj,
			   p_envs, p_rar, p_atk, p_hp, p_sname, p_sdesc, p_col):
		id = p_id; name_kr = p_nk; name_en = p_ne; animal = p_ani
		size = p_sz; animal_group = p_grp; primary_job = p_pj
		secondary_job = p_sj; environments = p_envs; rarity = p_rar
		base_atk = p_atk; base_hp = p_hp; skill_name = p_sname
		skill_desc = p_sdesc; color = p_col

	func get_atk_at_level(lv: int) -> float:
		return base_atk * (1.0 + 0.08 * (lv - 1))

	func get_hp_at_level(lv: int) -> float:
		return base_hp * (1.0 + 0.10 * (lv - 1))

	func get_rarity_stars() -> String:
		return "★".repeat(rarity)

# ─── 플레이어 상태 ─────────────────────────────────────────
var gold:       float = 500.0
var gems:       int   = 10
var wave:       int   = 1
var all_agents: Array = []   # AgentData 전체 도감
var owned_agents: Array = [] # 보유 중인 에이전트 ID 목록
var squad:      Array = []   # 출전 스쿼드 (AgentData, 최대 6)

# ─── 초기화 ───────────────────────────────────────────────
func _ready():
	_build_agent_database()
	# 프로토타입: 전 유닛 보유 상태로 시작
	for agent in all_agents:
		owned_agents.append(agent.id)
	# 기본 스쿼드: 킹대령·구스타프·백두·나폴레옹·무극·볼칸
	var default_squad_ids = [1, 2, 3, 11, 12, 9]
	for id in default_squad_ids:
		var agent = get_agent_by_id(id)
		if agent:
			squad.append(agent)

func get_agent_by_id(id: int) -> AgentData:
	for a in all_agents:
		if a.id == id:
			return a
	return null

func get_owned_agents() -> Array:
	var result = []
	for id in owned_agents:
		var a = get_agent_by_id(id)
		if a:
			result.append(a)
	return result

func add_to_squad(agent: AgentData) -> bool:
	if squad.size() >= 6:
		return false
	if agent in squad:
		return false
	squad.append(agent)
	return true

func remove_from_squad(agent: AgentData):
	squad.erase(agent)

func is_in_squad(agent: AgentData) -> bool:
	return agent in squad

func add_gold(amount: float):
	gold += amount

# ─── 에이전트 데이터베이스 ─────────────────────────────────
func _build_agent_database():
	var G = AnimalGroup; var P = PrimaryJob
	var S = SecondaryJob; var E = Environment; var Sz = UnitSize

	all_agents = [
		# ──── 5성 ────
		AgentData.new(1,  "킹 대령",   "Colonel King",  "독수리",  Sz.MEDIUM, G.SKY,    P.COWBOY,    S.SHERIFF,   [E.SNOW, E.DESERT],  5, 320, 2800, "정밀 패닝 사격",   "단일 타겟에 리볼버 전탄 발사",        Color(0.95,0.75,0.15)),
		AgentData.new(2,  "구스타프",  "Gustav",         "악어",    Sz.LARGE,  G.SCALE,  P.VIKING,    S.WARRIOR,   [E.SNOW, E.SWAMP],   5, 280, 3800, "빙하 진흙 격돌",   "전방 범위 넉백 + 2초 기절",           Color(0.25,0.70,0.35)),
		AgentData.new(3,  "백두",      "Baek-Du",        "호랑이",  Sz.LARGE,  G.BEAST,  P.RONIN,     S.WARRIOR,   [E.SNOW, E.URBAN],   5, 350, 3200, "설산 무영참",      "전방 광역 얼음 대미지 + 3초 결빙",    Color(0.80,0.85,1.00)),
		AgentData.new(4,  "펜릴",      "Fenrir",          "회색늑대",Sz.MEDIUM, G.BEAST,  P.MERCENARY, S.HITMAN,    [E.SNOW, E.URBAN],   5, 420, 2400, "무리의 처형",      "단일 타겟 극대 피해",                 Color(0.50,0.50,0.60)),
		AgentData.new(5,  "레이니",    "Rainy",           "독수리",  Sz.SMALL,  G.SKY,    P.RONIN,     S.SUPPORTER, [E.DESERT, E.SWAMP], 5, 290, 2200, "폭풍 깃털 연격",   "전방 다중 타겟 연속 피해",            Color(0.40,0.60,0.90)),
		AgentData.new(6,  "디아블로",  "Diablo",          "독개구리",Sz.SMALL,  G.SCALE,  P.MERCENARY, S.SHERIFF,   [E.DESERT, E.URBAN], 5, 260, 2000, "맹독성 가스 유탄", "전방 범위 5초 중독 DoT",              Color(0.30,0.85,0.25)),
		AgentData.new(7,  "블랙마린",  "Black Marine",    "청새치",  Sz.MEDIUM, G.MARINE, P.COWBOY,    S.SUPPORTER, [E.DESERT, E.SWAMP], 5, 200, 2600, "전술 호버 가이드", "아군 전체 공격속도 +40% 4초",         Color(0.15,0.40,0.90)),
		AgentData.new(8,  "타이돈",    "Tydon",           "백상아리",Sz.LARGE,  G.MARINE, P.VIKING,    S.WARRIOR,   [E.SWAMP, E.URBAN],  5, 310, 4000, "사슬 닻 처형",     "부채꼴 전방 공격 + 확정 출혈",        Color(0.10,0.25,0.70)),
		AgentData.new(9,  "볼칸",      "Volkan",          "타조",    Sz.MEDIUM, G.SKY,    P.RONIN,     S.HITMAN,    [E.SWAMP, E.URBAN],  5, 380, 2600, "휠 키보드 돌파",   "적진 관통 + 방어력 -35% 6초",        Color(0.70,0.25,0.85)),
		AgentData.new(10, "나야",      "Naya",            "킹코브라",Sz.SMALL,  G.MARINE, P.RONIN,     S.SUPPORTER, [E.SNOW, E.URBAN],   5, 220, 2100, "홀로그램 카드 주작","아군 전체 치명타 100% 3초 고정",     Color(0.85,0.55,0.95)),
		AgentData.new(11, "나폴레옹",  "Napoleon",        "펭귄",    Sz.SMALL,  G.SKY,    P.COWBOY,    S.HITMAN,    [E.DESERT, E.URBAN], 5, 520, 1800, "스나이퍼 대공포격","최강 적 단일 700% 헤드샷",            Color(0.20,0.20,0.55)),
		AgentData.new(12, "무극",      "Wu-Geuk",         "판다",    Sz.LARGE,  G.BEAST,  P.VIKING,    S.SHERIFF,   [E.SNOW, E.SWAMP],   5, 270, 4500, "여의봉 블랙홀",    "전체 적 중앙 집결 + 기절",            Color(0.15,0.15,0.15)),
		# ──── 4성 ────
		AgentData.new(13, "사자",      "Lion",            "사자",    Sz.LARGE,  G.BEAST,  P.COWBOY,    S.WARRIOR,   [E.DESERT, E.URBAN], 4, 240, 3000, "백수의 포효 사격", "일직선 도탄 피해",                    Color(0.90,0.60,0.10)),
		AgentData.new(14, "재규어",    "Jaguar",          "재규어",  Sz.MEDIUM, G.BEAST,  P.MERCENARY, S.HITMAN,    [E.SWAMP, E.URBAN],  4, 360, 2200, "하수구 야습 암살", "최저 체력 적에게 2연 치명타",         Color(0.55,0.35,0.15)),
		AgentData.new(15, "공작",      "Peacock",         "공작",    Sz.MEDIUM, G.SKY,    P.RONIN,     S.SUPPORTER, [E.SNOW, E.URBAN],   4, 180, 2400, "천화만발 매혹안",  "적 이동속도 -50% + 아군 공격력+20%", Color(0.35,0.80,0.70)),
		# ──── 3성 ────
		AgentData.new(16, "코끼리",    "Elephant",        "코끼리",  Sz.LARGE,  G.BEAST,  P.VIKING,    S.SHERIFF,   [E.DESERT, E.SWAMP], 3, 200, 5000, "코 고압 수폭탄",   "전방 광역 방어 버프 제거",            Color(0.60,0.60,0.70)),
		AgentData.new(17, "코뿔소",    "Rhino",           "코뿔소",  Sz.LARGE,  G.BEAST,  P.VIKING,    S.WARRIOR,   [E.DESERT, E.SWAMP], 3, 220, 4800, "철갑 돌격",        "전방 일직선 돌진 피해",               Color(0.50,0.50,0.55)),
		AgentData.new(18, "물소",      "Buffalo",         "물소",    Sz.LARGE,  G.BEAST,  P.COWBOY,    S.WARRIOR,   [E.SNOW, E.SWAMP],   3, 210, 4200, "대지진의 발구르기","전체 적 공격속도 -50% 3초",           Color(0.55,0.35,0.20)),
		# ──── 2성 ────
		AgentData.new(19, "펠리컨",    "Pelican",         "펠리컨",  Sz.MEDIUM, G.SKY,    P.MERCENARY, S.SUPPORTER, [E.SWAMP, E.URBAN],  2, 160, 2000, "부리 주머니 보급", "아군 2명 랜덤 공격력 +25% 4초",      Color(0.80,0.75,0.45)),
		AgentData.new(20, "송골매",    "Falcon",          "송골매",  Sz.SMALL,  G.SKY,    P.RONIN,     S.HITMAN,    [E.SNOW, E.DESERT],  2, 280, 1600, "마하 수직강하",    "단일 방어관통 쐐기 피해",             Color(0.70,0.55,0.20)),
		# ──── 1성 ────
		AgentData.new(21, "아나콘다",  "Anaconda",        "아나콘다",Sz.LARGE,  G.SCALE,  P.MERCENARY, S.HITMAN,    [E.SWAMP, E.URBAN],  1, 140, 3500, "똬리 구속",        "최대 적 2초 속박 + 압착 DoT",        Color(0.20,0.60,0.20)),
	]
