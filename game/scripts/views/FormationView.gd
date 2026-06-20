class_name FormationView
extends Control
# ============================================================
# FormationView — 편성 화면
# ┌──────────────────────────────┐
# │  전투력: 12,450  [프리셋▼]    │  ← 전투력/프리셋
# ├──────────────────────────────┤
# │  [슬롯1][슬롯2][슬롯3]         │  ← 스쿼드 슬롯 (2×3)
# │  [슬롯4][슬롯5][슬롯6]         │
# ├──────────────────────────────┤
# │  ⚡ 시너지: 조류2 공속+10%...  │  ← 시너지 미리보기
# ├──── 도감 ─── 필터 [전체▼] ───┤
# │  [카드][카드][카드][카드]        │  ← 보유 유닛 그리드
# │  [카드][카드][카드][카드]        │  (스크롤)
# └──────────────────────────────┘
# ============================================================

const SLOT_ROWS := 2; const SLOT_COLS := 3
const SLOT_W    := 220; const SLOT_H := 130
const CARD_W    := 158; const CARD_H := 190

var power_lbl:     Label
var syn_hbox:      HBoxContainer
var roster_grid:   GridContainer
var filter_rarity: int = 0  # 0 = 전체

func _init():
	name = "FormationView"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

func _build():
	var y = 0

	# ── 1. 전투력 바 ──────────────────────────────────────
	var pbar = UITheme.crect(UITheme.BG_PANEL, Vector2(UITheme.W, 50))
	add_child(pbar)
	var phbox = UITheme.hbox(12)
	phbox.position = Vector2(16, 8)
	phbox.size = Vector2(UITheme.W - 32, 36)
	add_child(phbox)

	phbox.add_child(UITheme.lbl("⚔ 전투력", UITheme.FS_SM, UITheme.GREY))
	power_lbl = UITheme.lbl("0", UITheme.FS_LG, UITheme.GOLD)
	phbox.add_child(power_lbl)
	phbox.add_child(UITheme.spacer())

	var preset_btn = UITheme.btn("프리셋 ▼", UITheme.FS_SM, UITheme.CYAN)
	preset_btn.pressed.connect(_on_preset)
	phbox.add_child(preset_btn)
	y += 50

	# ── 2. 스쿼드 슬롯 (2×3) ──────────────────────────────
	var grid_bg = UITheme.crect(Color(0.08, 0.04, 0.14), Vector2(UITheme.W, SLOT_H * 2 + 30))
	grid_bg.position.y = y
	add_child(grid_bg)

	var slot_grid = GridContainer.new()
	slot_grid.columns = SLOT_COLS
	slot_grid.position = Vector2(10, y + 10)
	slot_grid.add_theme_constant_override("h_separation", 8)
	slot_grid.add_theme_constant_override("v_separation", 8)
	slot_grid.name = "SlotGrid"
	add_child(slot_grid)
	y += SLOT_H * 2 + 30

	# ── 3. 시너지 미리보기 ────────────────────────────────
	var syn_bg = UITheme.crect(UITheme.BG_INNER, Vector2(UITheme.W, 90))
	syn_bg.position.y = y
	add_child(syn_bg)

	var syn_title = UITheme.lbl("⚡ 시너지 미리보기", UITheme.FS_SM, UITheme.GOLD)
	syn_title.position = Vector2(14, y + 6)
	add_child(syn_title)

	var syn_scroll = ScrollContainer.new()
	syn_scroll.position = Vector2(8, y + 28)
	syn_scroll.size = Vector2(UITheme.W - 16, 56)
	syn_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	syn_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(syn_scroll)

	syn_hbox = UITheme.hbox(10)
	syn_scroll.add_child(syn_hbox)
	y += 90

	# ── 4. 도감 헤더 + 필터 ──────────────────────────────
	var roster_hdr = UITheme.crect(UITheme.BG_PANEL, Vector2(UITheme.W, 44))
	roster_hdr.position.y = y
	add_child(roster_hdr)

	var rhbox = UITheme.hbox(12)
	rhbox.position = Vector2(14, y + 6)
	rhbox.size = Vector2(UITheme.W - 28, 32)
	add_child(rhbox)

	rhbox.add_child(UITheme.lbl("📋 도감", UITheme.FS_MD, UITheme.WHITE))
	rhbox.add_child(UITheme.spacer())

	for lbl_text in ["전체", "5★", "4★", "3★이하"]:
		var fb = UITheme.btn(lbl_text, UITheme.FS_XS, UITheme.GREY)
		fb.custom_minimum_size = Vector2(52, 30)
		var idx = ["전체","5★","4★","3★이하"].find(lbl_text)
		fb.pressed.connect(func(): _set_filter(idx, fb))
		rhbox.add_child(fb)
	y += 44

	# ── 5. 도감 그리드 (스크롤) ───────────────────────────
	var roster_scroll = ScrollContainer.new()
	roster_scroll.name = "RosterScroll"
	roster_scroll.position = Vector2(0, y)
	roster_scroll.size = Vector2(UITheme.W, UITheme.CONT_H - y)
	roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(roster_scroll)

	roster_grid = GridContainer.new()
	roster_grid.columns = 4
	roster_grid.add_theme_constant_override("h_separation", 6)
	roster_grid.add_theme_constant_override("v_separation", 6)
	roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_scroll.add_child(roster_grid)

	refresh()

# ─── 갱신 ────────────────────────────────────────────────────
func refresh():
	_refresh_slots()
	_refresh_synergy()
	_refresh_roster()
	power_lbl.text = "%d" % GameData.squad_power()

func _refresh_slots():
	var grid = get_node_or_null("SlotGrid")
	if not grid: return
	for c in grid.get_children(): c.queue_free()
	for i in range(6):
		grid.add_child(_make_squad_slot(i))

func _make_squad_slot(index: int) -> Control:
	var slot = Button.new()
	slot.flat = true
	slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)

	if index < GameData.squad.size():
		var agent = GameData.squad[index]
		var bg = UITheme.crect(UITheme.rarity_bg(agent.rarity))
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(bg)

		# 테두리
		var border = UITheme.crect(UITheme.rarity_color(agent.rarity), Vector2(SLOT_W, 3))
		slot.add_child(border)

		var hbox = UITheme.hbox(8)
		hbox.position = Vector2(6, 8)
		hbox.size = Vector2(SLOT_W - 12, SLOT_H - 16)
		slot.add_child(hbox)

		var icon = UITheme.crect(agent.color, Vector2(80, SLOT_H - 24))
		hbox.add_child(icon)

		var vbox = UITheme.vbox(3)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		vbox.add_child(UITheme.lbl(agent.name_kr, UITheme.FS_MD, UITheme.WHITE))
		vbox.add_child(UITheme.lbl(UITheme.rarity_label(agent.rarity), UITheme.FS_XS, UITheme.rarity_color(agent.rarity)))
		vbox.add_child(UITheme.lbl("Lv.%d  ATK %d" % [agent.level, int(agent.get_atk())], UITheme.FS_XS, UITheme.GOLD))
		vbox.add_child(UITheme.lbl(agent.get_group_name() + " / " + agent.get_job_name(), UITheme.FS_XS, UITheme.CYAN))

		var rm_btn = UITheme.btn("✕", UITheme.FS_SM, UITheme.RED)
		rm_btn.position = Vector2(SLOT_W - 28, 4)
		rm_btn.size = Vector2(24, 24)
		rm_btn.flat = true
		rm_btn.pressed.connect(func(): GameData.remove_from_squad(agent); refresh(); BattleManager.update_squad())
		slot.add_child(rm_btn)
	else:
		var bg = UITheme.crect(Color(0.10, 0.06, 0.18))
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(bg)

		var border = UITheme.crect(UITheme.GREY_DIM, Vector2(SLOT_W, 2))
		slot.add_child(border)

		var pl = UITheme.lbl("+ 유닛 추가", UITheme.FS_MD, UITheme.GREY_DIM)
		pl.set_anchors_preset(Control.PRESET_FULL_RECT)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(pl)

	return slot

func _refresh_synergy():
	for c in syn_hbox.get_children(): c.queue_free()
	var syn = SynergyManager.calculate(GameData.squad)
	var labels = syn.get("active_labels", [])
	if labels.is_empty():
		syn_hbox.add_child(UITheme.lbl("없음 — 같은 직업/생물군 2명 이상 편성 시 활성화", UITheme.FS_XS, UITheme.GREY))
		return
	for txt in labels:
		var badge = Control.new()
		badge.custom_minimum_size = Vector2(0, 36)
		var bg = UITheme.crect(UITheme.BG_CARD)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge.add_child(bg)
		var l = UITheme.lbl(" • " + txt + " ", UITheme.FS_XS, UITheme.GREEN)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(l)
		syn_hbox.add_child(badge)

func _refresh_roster():
	for c in roster_grid.get_children(): c.queue_free()
	var agents = GameData.get_owned()
	# 필터
	if filter_rarity > 0:
		var target = 6 - filter_rarity  # 1→5★, 2→4★, 3→3★이하
		if filter_rarity == 3:
			agents = agents.filter(func(a): return a.rarity <= 3)
		else:
			agents = agents.filter(func(a): return a.rarity == target)
	# 정렬: 희귀도→스쿼드 여부
	agents.sort_custom(func(a, b):
		if GameData.is_in_squad(a) != GameData.is_in_squad(b):
			return GameData.is_in_squad(a)
		return a.rarity > b.rarity
	)
	for agent in agents:
		roster_grid.add_child(_make_agent_card(agent))

func _make_agent_card(agent) -> Control:
	var card = Button.new()
	card.flat = true
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)

	var bg = UITheme.crect(UITheme.rarity_bg(agent.rarity))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(bg)

	var border = UITheme.crect(UITheme.rarity_color(agent.rarity), Vector2(CARD_W, 3))
	card.add_child(border)

	# 출전 중 배지
	if GameData.is_in_squad(agent):
		var badge_bg = UITheme.crect(UITheme.GREEN.darkened(0.3), Vector2(CARD_W, 22))
		badge_bg.position.y = 3
		card.add_child(badge_bg)
		var bl = UITheme.lbl("⚔ 출전 중", UITheme.FS_XS, UITheme.WHITE)
		bl.size = Vector2(CARD_W, 22)
		bl.position.y = 3
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(bl)

	# 아트 영역
	var icon_y = 28 if GameData.is_in_squad(agent) else 6
	var icon = UITheme.crect(agent.color, Vector2(CARD_W - 16, 96))
	icon.position = Vector2(8, icon_y)
	card.add_child(icon)

	# 희귀도 별
	var stars = UITheme.lbl("★".repeat(agent.rarity), UITheme.FS_XS, UITheme.rarity_color(agent.rarity))
	stars.position = Vector2(4, icon_y + 98)
	stars.size = Vector2(CARD_W - 8, 16)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(stars)

	# 이름
	var nl = UITheme.lbl(agent.name_kr, UITheme.FS_SM, UITheme.WHITE)
	nl.position = Vector2(4, icon_y + 116)
	nl.size = Vector2(CARD_W - 8, 20)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(nl)

	# Lv + ATK
	var sl = UITheme.lbl("Lv.%d  ATK %d" % [agent.level, int(agent.get_atk())], UITheme.FS_XS, UITheme.GOLD)
	sl.position = Vector2(4, icon_y + 138)
	sl.size = Vector2(CARD_W - 8, 16)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(sl)

	# 그룹/직업
	var gl = UITheme.lbl(agent.get_group_name() + " · " + agent.get_job_name(), UITheme.FS_XS, UITheme.CYAN)
	gl.position = Vector2(4, icon_y + 156)
	gl.size = Vector2(CARD_W - 8, 16)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(gl)

	card.pressed.connect(func(): _toggle_squad(agent))
	return card

# ─── 이벤트 ──────────────────────────────────────────────────
func _toggle_squad(agent):
	if GameData.is_in_squad(agent):
		GameData.remove_from_squad(agent)
	else:
		if not GameData.add_to_squad(agent):
			return  # 가득 참
	BattleManager.update_squad()
	refresh()

func _set_filter(idx: int, _btn: Button):
	filter_rarity = idx
	_refresh_roster()

func _on_preset():
	var presets = ["황야의 보안관들", "북해의 칼날", "방랑 무사단"]
	for p in presets:
		if SynergyManager.check_preset(p, GameData.squad):
			pass  # TODO: 프리셋 팝업
