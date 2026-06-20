class_name SynergyManager
# ============================================================
# SynergyManager.gd
# C# 블루프린트의 시너지 계산 로직을 GDScript로 포팅
# ============================================================

static func calculate(squad: Array) -> Dictionary:
	var result = {
		"attack_speed":   1.0,
		"crit_rate":      0.0,
		"final_damage":   1.0,
		"max_hp":         1.0,
		"cc_immunity":    false,
		"dot_multiplier": 1.0,
		"active_labels":  []   # UI 표시용 활성 시너지 목록
	}
	if squad.is_empty():
		return result

	# ── 1. 생물군 시너지 (Animal Group) ──────────────────────
	var group_counts = {}
	for agent in squad:
		var g = agent.animal_group
		group_counts[g] = group_counts.get(g, 0) + 1

	for grp in group_counts:
		var cnt = group_counts[grp]
		var gname = _group_name(grp)
		if cnt >= 6:
			result.final_damage   += 0.30
			result.crit_rate      += 0.15
			result.attack_speed   += 0.10
			result.active_labels.append("%s 6: 최종피해+30%% 치명+15%%" % gname)
		elif cnt >= 4:
			result.crit_rate    += 0.15
			result.attack_speed += 0.10
			result.active_labels.append("%s 4: 치명+15%% 공속+10%%" % gname)
		elif cnt >= 2:
			result.attack_speed += 0.10
			result.active_labels.append("%s 2: 공속+10%%" % gname)

	# ── 2. 주직업 시너지 (Primary Job) ───────────────────────
	var job_counts = {}
	for agent in squad:
		var j = agent.primary_job
		job_counts[j] = job_counts.get(j, 0) + 1

	for job in job_counts:
		var cnt = job_counts[job]
		var jname = _job_name(job)
		if cnt >= 4:
			result.final_damage += 0.30
			result.active_labels.append("%s 4: 최종피해+30%%" % jname)
		elif cnt >= 2:
			result.final_damage += 0.15
			result.active_labels.append("%s 2: 최종피해+15%%" % jname)

	# ── 3. 지형 시너지 (Environment) ─────────────────────────
	var env_list = []
	for agent in squad:
		if agent.environments.size() > 0:
			env_list.append(agent.environments[0])
		# 4성 이상 진화 시 서브지형 해금
		if agent.current_stars >= 4 and agent.environments.size() > 1:
			env_list.append(agent.environments[1])

	var env_counts = {}
	for e in env_list:
		env_counts[e] = env_counts.get(e, 0) + 1

	for env in env_counts:
		var cnt = env_counts[env]
		var ename = _env_name(env)
		if cnt >= 6:
			result.dot_multiplier += 0.50
			result.cc_immunity     = true
			result.max_hp         += 0.15
			result.active_labels.append("%s 6: DoT+50%% CC면역 HP+15%%" % ename)
		elif cnt >= 4:
			result.cc_immunity = true
			result.max_hp     += 0.15
			result.active_labels.append("%s 4: CC면역 HP+15%%" % ename)
		elif cnt >= 2:
			result.max_hp += 0.15
			result.active_labels.append("%s 2: HP+15%%" % ename)

	return result

# ── 계정 전체 창고 효과 (Owned Passive) ──────────────────────
static func calculate_owned_effects(all_owned: Array) -> Dictionary:
	var fx = {
		"global_atk": 0.0, "global_gold": 0.0,
		"global_hp":  0.0, "global_gem":  0.0,
		"hero_dmg":   0.0
	}
	for agent in all_owned:
		for i in range(1, agent.current_core + 1):
			match i:
				1: fx.global_atk  += 0.02
				2: fx.global_gold += 0.05
				3: fx.global_hp   += 0.03
				4: fx.global_gem  += 0.02
				5: fx.hero_dmg    += 0.05
	return fx

# ── 프리셋 확인 ───────────────────────────────────────────────
static func check_preset(preset_name: String, squad: Array) -> bool:
	var presets = {
		"황야의 보안관들": ["킹 대령", "나폴레옹"],
		"북해의 칼날":    ["구스타프", "무극"],
		"방랑 무사단":    ["백두", "볼칸"],
	}
	if not presets.has(preset_name):
		return false
	var cores = presets[preset_name]
	var has_c1 = false
	var has_c2 = false
	var four_star_count = 0
	for agent in squad:
		if agent.name_kr == cores[0]: has_c1 = true
		if agent.name_kr == cores[1]: has_c2 = true
		if agent.name_kr != cores[0] and agent.name_kr != cores[1] and agent.rarity == 4:
			four_star_count += 1
	return has_c1 and has_c2 and four_star_count >= 3

# ── 이름 헬퍼 ────────────────────────────────────────────────
static func _group_name(g: int) -> String:
	match g:
		GameData.AnimalGroup.BEAST:  return "포유류"
		GameData.AnimalGroup.SKY:    return "조류"
		GameData.AnimalGroup.SCALE:  return "파충류"
		GameData.AnimalGroup.MARINE: return "어류"
	return "?"

static func _job_name(j: int) -> String:
	match j:
		GameData.PrimaryJob.COWBOY:    return "카우보이"
		GameData.PrimaryJob.VIKING:    return "바이킹"
		GameData.PrimaryJob.RONIN:     return "낭인"
		GameData.PrimaryJob.MERCENARY: return "용병"
	return "?"

static func _env_name(e: int) -> String:
	match e:
		GameData.Environment.SNOW:   return "고산설원"
		GameData.Environment.DESERT: return "사막"
		GameData.Environment.SWAMP:  return "습지"
		GameData.Environment.URBAN:  return "사이버도시"
	return "?"
