extends Control
# ============================================================
# ExploreView.gd — 탐험 탭
# 서브탭: 스테이지(월드맵) / 던전 / 투기장 / 파견
# ============================================================

var _sub := 0
var _sub_btns: Array = []
var _content: Control
var _cur_world := 0
var _world_btns: Array = []

# ─────────────────────────────────────────────────────────────
func _ready():
	custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)
	_build()

func _build():
	var root := UITheme.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	root.add_child(_make_sub_tab_bar())  # h=56

	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H - 56)
	root.add_child(_content)

	_switch_sub(0)

func _make_sub_tab_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 56))
	var hb  := UITheme.hbox(0); hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(hb)
	for txt in ["🗺 스테이지","⚒ 던전","🏟 투기장","📦 파견","🗼 무한탑","👹 월드보스"]:
		var b := Button.new(); b.text = txt
		b.add_theme_font_size_override("font_size", UITheme.FS_SM)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size   = Vector2(0, 56)
		var idx := _sub_btns.size()
		b.pressed.connect(func(): _switch_sub(idx))
		_sub_btns.append(b); hb.add_child(b)
	return bg

func _switch_sub(idx: int):
	_sub = idx
	for i in _sub_btns.size():
		_sub_btns[i].add_theme_color_override("font_color", UITheme.GOLD if i == idx else UITheme.GREY)
	for c in _content.get_children(): c.queue_free()
	match idx:
		0: _content.add_child(_make_stage_tab())
		1: _content.add_child(_make_dungeon_tab())
		2: _content.add_child(_make_arena_tab())
		3: _content.add_child(_make_dispatch_tab())
		4: _content.add_child(_make_tower_tab())
		5: _content.add_child(_make_boss_tab())

func refresh():
	_switch_sub(_sub)

# ═════════════════════════════════════════════════════════════
# 서브탭 0: 스테이지 (월드맵)
# ═════════════════════════════════════════════════════════════
func _make_stage_tab() -> Control:
	var root := UITheme.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 월드 탭 행
	root.add_child(_make_world_tabs())

	# 스테이지 그리드 스크롤
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(UITheme.W, 0)
	root.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "StageGrid"; grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(grid); scroll.add_child(pad)

	# 하단 쓸기 바
	root.add_child(_make_sweep_bar())

	_rebuild_stage_grid(grid, _cur_world)
	return root

func _make_world_tabs() -> Control:
	_world_btns.clear()
	var bg := UITheme.crect(Color(0.06, 0.03, 0.12), Vector2(UITheme.W, 68))
	var hb  := UITheme.hbox(4); hb.position = Vector2(6, 6); bg.add_child(hb)
	var worlds := GameData.get_worlds()
	for i in worlds.size():
		var w = worlds[i]
		var b := Button.new()
		b.text = "W%d\n%s" % [i+1, w["short"]]
		b.add_theme_font_size_override("font_size", UITheme.FS_XS)
		b.custom_minimum_size = Vector2(126, 56)
		var idx := i
		b.pressed.connect(func(): _select_world(idx))
		_world_btns.append(b); hb.add_child(b)
	_update_world_btn_colors()
	return bg

func _select_world(idx: int):
	_cur_world = idx
	_update_world_btn_colors()
	var grid = _content.find_child("StageGrid", true, false)
	if grid: _rebuild_stage_grid(grid, idx)

func _update_world_btn_colors():
	for i in _world_btns.size():
		_world_btns[i].add_theme_color_override("font_color",
			UITheme.GOLD if i == _cur_world else UITheme.GREY)

func _rebuild_stage_grid(grid: GridContainer, world_idx: int):
	for c in grid.get_children(): c.queue_free()
	var cleared: Dictionary = GameData.get("cleared_stages", {})
	for s in range(1, 11):
		grid.add_child(_make_stage_card(world_idx, s, cleared))

func _make_stage_card(world_idx: int, stage: int, cleared: Dictionary) -> Control:
	var sid     = "W%d-%d" % [world_idx+1, stage]
	var is_boss = (stage == 5 or stage == 10)
	var done    = cleared.get(sid, false)
	var locked  = not _stage_unlocked(world_idx, stage, cleared)
	var bg_col  = Color(0.14, 0.07, 0.24) if not locked else Color(0.07, 0.03, 0.10)
	var h       = 108 if is_boss else 90

	var card := UITheme.crect(bg_col, Vector2(340, h))

	if is_boss:
		var gold_border := UITheme.crect(UITheme.GOLD, Vector2(340, h))
		var inner := UITheme.crect(bg_col, Vector2(336, h - 4))
		inner.position = Vector2(2, 2); card.add_child(gold_border); card.add_child(inner)

	var col = UITheme.GREY if locked else (UITheme.GREEN if done else UITheme.WHITE)
	_lbl_at_c(card, sid, UITheme.FS_LG, col, Vector2(10, 6))
	if is_boss: _lbl_at_c(card, "👑 BOSS", UITheme.FS_SM, UITheme.ORANGE, Vector2(200, 6))
	if done:
		_lbl_at_c(card, "⭐⭐⭐ 클리어", UITheme.FS_XS, UITheme.GREEN, Vector2(10, 34))
	elif locked:
		_lbl_at_c(card, "🔒 잠금", UITheme.FS_XS, UITheme.GREY_DIM, Vector2(10, 34))
	else:
		_lbl_at_c(card, "보상 🪙%d%s" % [200 + stage*50, " 💎%d"%2 if is_boss else ""],
			UITheme.FS_XS, UITheme.GREY, Vector2(10, 34))
	if not locked:
		var go := UITheme.btn("▶ 도전", UITheme.FS_SM, UITheme.WHITE)
		go.position = Vector2(240, h - 44); go.custom_minimum_size = Vector2(92, 38)
		var s := sid
		go.pressed.connect(func(): _challenge(s))
		card.add_child(go)
	return card

func _stage_unlocked(world_idx: int, stage: int, cleared: Dictionary) -> bool:
	if world_idx == 0 and stage == 1: return true
	if stage == 1: return cleared.get("W%d-10" % world_idx, false)
	return cleared.get("W%d-%d" % [world_idx+1, stage-1], false)

func _challenge(sid: String):
	GameData.current_stage = sid
	GameData._add_quest_progress("stage", 1)
	BattleManager.wave = 1
	BattleManager.restart()
	_toast("⚔ %s 시작!" % sid)

func _make_sweep_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 72))
	var hb  := UITheme.hbox(12); hb.position = Vector2(10, 10); bg.add_child(hb)
	var sweep := UITheme.btn("⚡ 쓸기 ×3", UITheme.FS_MD, UITheme.CYAN)
	sweep.custom_minimum_size = Vector2(190, 52); hb.add_child(sweep)
	var autoexp := UITheme.btn("🔄 자동 탐험", UITheme.FS_MD, UITheme.ORANGE)
	autoexp.custom_minimum_size = Vector2(190, 52); hb.add_child(autoexp)
	sweep.pressed.connect(func(): _toast("쓸기 기능은 준비 중입니다."))
	return bg

# ═════════════════════════════════════════════════════════════
# 서브탭 1: 던전
# ═════════════════════════════════════════════════════════════
func _make_dungeon_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := UITheme.vbox(14)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	vb.add_child(UITheme.lbl("⚒ 던전", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.lbl("매일 오전 5시 리셋 · 키는 자동 충전", UITheme.FS_XS, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	for dtype in ["gold","material","elite"]:
		vb.add_child(_make_dungeon_section(dtype))
		vb.add_child(UITheme.hsep())

	return scroll

func _make_dungeon_section(dtype: String) -> Control:
	var cfg = GameData.DUNGEON_DEFS.get(dtype, {})
	if cfg.is_empty(): return Control.new()

	var keys = GameData.dungeon_keys.get(dtype, 0)
	var vb   := UITheme.vbox(8)

	var hdr := UITheme.hbox(12)
	hdr.add_child(UITheme.lbl(cfg["name"], UITheme.FS_LG, UITheme.GOLD))
	hdr.add_child(UITheme.lbl("열쇠 %d/%d" % [keys, 3 if dtype != "elite" else 1],
		UITheme.FS_SM, UITheme.CYAN if keys > 0 else UITheme.GREY_DIM))
	vb.add_child(hdr)
	vb.add_child(UITheme.lbl(cfg["desc"], UITheme.FS_SM, UITheme.GREY))

	var levels: int = cfg["levels"]
	var grid := GridContainer.new()
	grid.columns = minf(levels, 3) as int
	grid.add_theme_constant_override("h_separation", 8)
	vb.add_child(grid)

	for lv in range(1, levels + 1):
		var stars = GameData.get_dungeon_record(dtype, lv)
		var card := UITheme.crect(UITheme.BG_CARD, Vector2(216, 80))

		_lbl_at_c(card, "Lv.%d" % lv, UITheme.FS_MD, UITheme.WHITE, Vector2(8, 6))
		_lbl_at_c(card, "★" * stars + "☆" * (3 - stars), UITheme.FS_SM, UITheme.GOLD, Vector2(8, 30))
		var en := UITheme.btn("입장" if keys > 0 else "열쇠 없음", UITheme.FS_SM,
			UITheme.GREEN if keys > 0 else UITheme.GREY_DIM)
		en.position = Vector2(8, 52); en.custom_minimum_size = Vector2(200, 24)
		en.disabled = keys <= 0
		var dt := dtype; var lvl := lv
		en.pressed.connect(func(): _enter_dungeon(dt, lvl))
		card.add_child(en)
		grid.add_child(card)

	return vb

func _enter_dungeon(dtype: String, level: int):
	var result = GameData.enter_dungeon(dtype, level)
	if not result["success"]:
		_toast(result.get("msg", "입장 실패"))
		return
	var rw = result.get("reward", {})
	var msg = "던전 클리어! "
	if rw.get("gold", 0) > 0: msg += "🪙 %d" % rw["gold"]
	elif rw.get("mats", 0) > 0: msg += "재료 × %d" % rw["mats"]
	elif rw.get("equip_id", -1) != -1:
		var eq = GameData.get_equipment(rw["equip_id"])
		if eq: msg += "장비: %s 획득!" % eq.name_kr
	_toast(msg)
	_switch_sub(1)

# ═════════════════════════════════════════════════════════════
# 서브탭 2: 투기장
# ═════════════════════════════════════════════════════════════
func _make_arena_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := UITheme.vbox(14)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	# 내 랭크 헤더
	var rank_bg := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 110))
	_lbl_at_c(rank_bg, GameData.get_arena_rank_label(), UITheme.FS_XL, UITheme.GOLD, Vector2(16, 12))
	_lbl_at_c(rank_bg, "랭킹 #%d" % GameData.arena_rank, UITheme.FS_LG, UITheme.WHITE, Vector2(16, 50))
	_lbl_at_c(rank_bg, "티켓 %d/5  ·  오늘 승리 %d회" % [GameData.arena_tickets, GameData.arena_wins_today],
		UITheme.FS_SM, UITheme.CYAN, Vector2(16, 82))
	vb.add_child(rank_bg)
	vb.add_child(UITheme.hsep())

	# 랭킹 보상
	vb.add_child(UITheme.lbl("일일 랭킹 보상", UITheme.FS_MD, UITheme.GOLD))
	var reward_defs = [
		{"rank":"#1~10","gems":100,"gold":5000},
		{"rank":"#11~50","gems":50,"gold":3000},
		{"rank":"#51~200","gems":30,"gold":2000},
		{"rank":"#201~500","gems":15,"gold":1000},
		{"rank":"#501+","gems":5,"gold":500},
	]
	for rd in reward_defs:
		var row := UITheme.hbox(16)
		row.add_child(UITheme.lbl(rd["rank"], UITheme.FS_SM, UITheme.WHITE))
		row.add_child(UITheme.lbl("💎 %d" % rd["gems"], UITheme.FS_SM, UITheme.GEM))
		row.add_child(UITheme.lbl("🪙 %d" % rd["gold"], UITheme.FS_SM, UITheme.GOLD))
		vb.add_child(row)
	vb.add_child(UITheme.hsep())

	# 도전 상대 목록
	vb.add_child(UITheme.lbl("도전 상대", UITheme.FS_MD, UITheme.CYAN))
	var opponents = GameData.get_arena_opponents()
	for op in opponents:
		vb.add_child(_make_opponent_card(op))

	return scroll

func _make_opponent_card(op: Dictionary) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 90))
	_lbl_at_c(card, op["name"], UITheme.FS_MD, UITheme.WHITE, Vector2(12, 10))
	_lbl_at_c(card, "랭킹 #%d" % op["rank"], UITheme.FS_SM, UITheme.GREY, Vector2(12, 36))
	_lbl_at_c(card, "전투력 %d" % op["power"], UITheme.FS_SM, UITheme.ORANGE, Vector2(12, 58))

	var color = UITheme.GREEN if op["power"] < GameData.squad_power() else UITheme.ORANGE
	var battle_btn := UITheme.btn("⚔ 도전", UITheme.FS_MD, color)
	battle_btn.position = Vector2(UITheme.W - 140, 20)
	battle_btn.custom_minimum_size = Vector2(100, 52)
	battle_btn.disabled = GameData.arena_tickets <= 0
	var p := op["power"]
	battle_btn.pressed.connect(func(): _do_arena(p))
	card.add_child(battle_btn)
	return card

func _do_arena(opp_power: int):
	var win = GameData.do_arena_battle(opp_power)
	var msg = "🏆 승리! 랭킹 상승" if win else "💔 패배... 다음에 다시 도전하세요"
	_toast(msg)
	_switch_sub(2)

# ═════════════════════════════════════════════════════════════
# 서브탭 3: 파견 (원정)
# ═════════════════════════════════════════════════════════════
func _make_dispatch_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := UITheme.vbox(14)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	vb.add_child(UITheme.lbl("📦 파견 원정", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.lbl("유닛을 파견 보내고 자원을 수확하세요", UITheme.FS_SM, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	# 완료 수령
	var completed = GameData.check_dispatches()
	if not completed.is_empty():
		var coll_vb := UITheme.vbox(4)
		coll_vb.add_child(UITheme.lbl("✅ 파견 완료 — 보상이 자동 지급되었습니다!", UITheme.FS_SM, UITheme.GREEN))
		for c in completed:
			coll_vb.add_child(UITheme.lbl("  🪙 %d  🎟 %d" % [c["gold"], c["ticket"]], UITheme.FS_SM, UITheme.GOLD))
		vb.add_child(coll_vb)
		vb.add_child(UITheme.hsep())

	# 진행 중인 파견
	if not GameData.dispatches.is_empty():
		vb.add_child(UITheme.lbl("진행 중인 파견", UITheme.FS_MD, UITheme.CYAN))
		var now = Time.get_unix_time_from_system()
		for d in GameData.dispatches:
			var remaining = maxf(d["end_time"] - now, 0)
			var h = int(remaining / 3600)
			var m = int(int(remaining) % 3600 / 60)
			var row := UITheme.hbox(10)
			var names = []
			for uid in d.get("unit_ids", []):
				var a = GameData.get_by_id(uid)
				if a: names.append(a.name_kr)
			row.add_child(UITheme.lbl("%s" % "·".join(names), UITheme.FS_SM, UITheme.WHITE))
			row.add_child(UITheme.lbl("남은 시간: %02d:%02d" % [h, m], UITheme.FS_SM, UITheme.ORANGE))
			vb.add_child(row)
		vb.add_child(UITheme.hsep())

	# 임무 목록
	vb.add_child(UITheme.lbl("파견 임무", UITheme.FS_MD, UITheme.GOLD))
	for mission in GameData.MISSION_DEFS:
		vb.add_child(_make_mission_card(mission))

	return scroll

func _make_mission_card(mission: Dictionary) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 100))
	_lbl_at_c(card, mission["name"], UITheme.FS_MD, UITheme.WHITE, Vector2(12, 8))
	_lbl_at_c(card, "소요: %d시간  보상: 🪙%d  🎟%d" % [mission["hours"], mission["gold"], mission["ticket"]],
		UITheme.FS_SM, UITheme.GREY, Vector2(12, 34))
	_lbl_at_c(card, "필요 유닛: %d명" % mission["slots"], UITheme.FS_SM, UITheme.CYAN, Vector2(12, 58))

	var go := UITheme.btn("파견 보내기", UITheme.FS_SM, UITheme.ORANGE)
	go.position = Vector2(UITheme.W - 160, 25)
	go.custom_minimum_size = Vector2(120, 52)
	var mid := mission["id"]; var slots := mission["slots"]
	go.pressed.connect(func(): _start_dispatch(mid, slots))
	card.add_child(go)
	return card

func _start_dispatch(mission_id: int, slots: int):
	# 파견 가능한 유닛 자동 선택 (스쿼드 제외 유닛 우선)
	var available = []
	for a in GameData.get_owned():
		if not GameData.is_in_squad(a) and not GameData.is_unit_dispatched(a.id):
			available.append(a.id)
	if available.size() < slots:
		_toast("파견 가능한 유닛이 부족합니다! (%d명 필요)" % slots)
		return
	var selected = available.slice(0, slots)
	if GameData.start_dispatch(selected, mission_id):
		var names = []
		for uid in selected:
			var a = GameData.get_by_id(uid); if a: names.append(a.name_kr)
		_toast("파견 출발! %s" % "·".join(names))
		_switch_sub(3)
	else:
		_toast("파견 시작 실패")

# ═════════════════════════════════════════════════════════════
# 서브탭 4: 무한의 탑
# ═════════════════════════════════════════════════════════════
func _make_tower_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := UITheme.vbox(14)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	vb.add_child(UITheme.lbl("🗼 무한의 탑", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.lbl("층을 올라갈수록 강해지는 영원의 시험", UITheme.FS_SM, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	var floor   = GameData.tower_floor
	var record  = GameData.tower_record
	var att     = GameData.tower_attempts_today
	var row1    := UITheme.hbox(20)
	row1.add_child(UITheme.lbl("🏆 최고 기록: %d층" % record, UITheme.FS_LG, UITheme.GOLD))
	row1.add_child(UITheme.lbl("📍 현재: %d층 도전" % floor,  UITheme.FS_LG, UITheme.CYAN))
	vb.add_child(row1)
	vb.add_child(UITheme.lbl("도전 횟수: %d / %d" % [att, GameData.TOWER_DAILY_MAX],
		UITheme.FS_MD, UITheme.GREEN if att < GameData.TOWER_DAILY_MAX else UITheme.RED))
	vb.add_child(UITheme.hsep())

	var req      = 500 + floor * 180
	var my_power = GameData.squad_power()
	var pct      = clampf(float(my_power) / float(req), 0.0, 1.0)
	vb.add_child(UITheme.lbl("필요 전투력: %d" % req, UITheme.FS_MD, UITheme.WHITE))
	vb.add_child(UITheme.lbl("내 전투력:   %d" % my_power, UITheme.FS_MD,
		UITheme.GREEN if my_power >= req else UITheme.ORANGE))
	var bar_root := Control.new(); bar_root.custom_minimum_size = Vector2(UITheme.W - 32, 22)
	bar_root.add_child(UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 22)))
	bar_root.add_child(UITheme.crect(UITheme.GREEN if pct >= 1.0 else UITheme.ORANGE,
		Vector2((UITheme.W - 32) * pct, 22)))
	vb.add_child(bar_root)
	vb.add_child(UITheme.hsep())

	var can = GameData.can_challenge_tower()
	var ch_btn := UITheme.btn("⚔ 도전하기  (%d층)" % floor, UITheme.FS_LG,
		UITheme.GOLD if can else UITheme.GREY_DIM)
	ch_btn.custom_minimum_size = Vector2(UITheme.W - 32, 72)
	ch_btn.disabled = not can
	ch_btn.pressed.connect(func(): _do_tower_challenge())
	vb.add_child(ch_btn)
	vb.add_child(UITheme.hsep())

	vb.add_child(UITheme.lbl("■ 층 달성 보상", UITheme.FS_MD, UITheme.CYAN))
	const FLOOR_RW := [[10,"💎 20 + 🪙 1,200"],[20,"💎 50 + 소환권 ×1"],
	                   [30,"💎 100 + 소환권 ×2"],[50,"💎 200 + 전설 소환권 ×1"],
	                   [100,"💎 500 + 전설 소환권 ×3"]]
	for fr in FLOOR_RW:
		var col  = UITheme.GOLD if record >= fr[0] else UITheme.GREY
		var mark = "✓ " if record >= fr[0] else "□ "
		vb.add_child(UITheme.lbl("%s%d층: %s" % [mark, fr[0], fr[1]], UITheme.FS_SM, col))
	return scroll

func _do_tower_challenge():
	var result = GameData.challenge_tower()
	if result["success"]:
		var gm = "  💎 +%d" % result["gems"] if result.get("gems", 0) > 0 else ""
		_toast("🎉 %d층 클리어! 🪙 +%d%s" % [result["floor"], result["gold"], gm])
	else:
		_toast("❌ 실패: %s" % result.get("msg", "전투력 부족"))
	_switch_sub(4)

# ═════════════════════════════════════════════════════════════
# 서브탭 5: 월드 보스
# ═════════════════════════════════════════════════════════════
func _make_boss_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := UITheme.vbox(14)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	vb.add_child(UITheme.lbl("👹 월드 보스", UITheme.FS_XL, UITheme.RED))
	vb.add_child(UITheme.lbl("서버 전체가 함께 쓰러뜨리는 대형 적", UITheme.FS_SM, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	var stage = GameData.world_boss_stage
	vb.add_child(UITheme.lbl("치즈파 대두목  [단계 %d]" % stage, UITheme.FS_LG, UITheme.ORANGE))

	var hp_pct = GameData.get_boss_hp_pct()
	var hp_col = UITheme.HP_GREEN if hp_pct > 0.5 else (UITheme.HP_YELLOW if hp_pct > 0.2 else UITheme.HP_RED)
	var hp_root := Control.new(); hp_root.custom_minimum_size = Vector2(UITheme.W - 32, 30)
	var hp_bg   := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 30))
	var hp_fill := UITheme.crect(hp_col, Vector2((UITheme.W - 32) * hp_pct, 30))
	var hp_txt  := UITheme.lbl("%d / %d  (%.1f%%)" % [
		GameData.world_boss_current_hp, GameData.world_boss_max_hp, hp_pct * 100],
		UITheme.FS_SM, UITheme.WHITE)
	hp_txt.position = Vector2(8, 6)
	hp_root.add_child(hp_bg); hp_root.add_child(hp_fill); hp_root.add_child(hp_txt)
	vb.add_child(hp_root)
	vb.add_child(UITheme.hsep())

	var attacks = GameData.world_boss_attacks_today
	var can     = GameData.can_attack_boss()
	vb.add_child(UITheme.lbl("오늘 내 피해: %s" % _fmt_big(GameData.world_boss_my_damage),
		UITheme.FS_MD, UITheme.CYAN))
	vb.add_child(UITheme.lbl("도전 횟수: %d / %d" % [attacks, GameData.WORLD_BOSS_DAILY_MAX],
		UITheme.FS_MD, UITheme.GREEN if can else UITheme.RED))

	var atk_btn := UITheme.btn("⚔ 보스 공격하기", UITheme.FS_LG,
		UITheme.RED if can else UITheme.GREY_DIM)
	atk_btn.custom_minimum_size = Vector2(UITheme.W - 32, 72)
	atk_btn.disabled = not can
	atk_btn.pressed.connect(func(): _do_boss_attack())
	vb.add_child(atk_btn)
	vb.add_child(UITheme.hsep())

	vb.add_child(UITheme.lbl("■ 주간 랭킹 보상 (매주 월요일 지급)", UITheme.FS_MD, UITheme.GOLD))
	const RANK_RW := [["1위","💎 500 + 전설권 ×2"],["2~3위","💎 300 + 전설권 ×1"],
	                  ["4~10위","💎 150 + 소환권 ×3"],["11~50위","💎 80 + 소환권 ×1"],
	                  ["51~100위","💎 40"],["참가자","💎 20"]]
	for rr in RANK_RW:
		var row := UITheme.hbox(20)
		row.add_child(UITheme.lbl(rr[0], UITheme.FS_SM, UITheme.GOLD))
		row.add_child(UITheme.lbl(rr[1], UITheme.FS_SM, UITheme.WHITE))
		vb.add_child(row)
	return scroll

func _do_boss_attack():
	var result = GameData.attack_world_boss()
	if result["success"]:
		var clr = " 🎉 보스 처치!" if result.get("cleared", false) else ""
		_toast("⚔ 피해: %s  💎 +%d  🪙 +%d%s" % [
			_fmt_big(result["damage"]), result["gems"], result["gold"], clr])
	else:
		_toast("❌ %s" % result.get("msg", ""))
	_switch_sub(5)

func _fmt_big(n: int) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:     return "%.1fK" % (n / 1_000.0)
	return str(n)

# ─────────────────────────────────────────────────────────────
# 헬퍼
# ─────────────────────────────────────────────────────────────
func _lbl_at_c(parent: Control, text: String, fs: int, col: Color, pos: Vector2):
	var l := UITheme.lbl(text, fs, col); l.position = pos; parent.add_child(l)

func _toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_MD, UITheme.GREEN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(UITheme.W, 0)
	lbl.position = Vector2(0, UITheme.CONT_H / 2 - 40)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 60, 1.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.8)
	tw.tween_callback(lbl.queue_free)
