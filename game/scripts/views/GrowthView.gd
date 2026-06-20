extends Control
# ============================================================
# GrowthView.gd — 성장 탭
# 서브탭: 성장(레벨/승급/코어) / 장비 / 유물
# ============================================================

const MAX_LEVEL := 60
const SLOTS = ["weapon","armor","helmet","boots","ring","artifact"]
const SLOT_NAMES = {"weapon":"무기","armor":"갑옷","helmet":"투구","boots":"장화","ring":"반지","artifact":"유물"}

var _sub := 0
var _content: Control
var _sub_btns: Array = []
var _selected_agent = null

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

# ─────────────────────────────────────────────────────────────
# 서브 탭 바
# ─────────────────────────────────────────────────────────────
func _make_sub_tab_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 56))
	var hb  := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(hb)
	for i in ["📈 성장","⚔ 장비","💎 유물","📚 도감","🔬 연구소"]:
		var b := Button.new(); b.text = i
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
		0: _content.add_child(_make_growth_tab())
		1: _content.add_child(_make_equipment_tab())
		2: _content.add_child(_make_relic_tab())
		3: _content.add_child(_make_codex_tab())
		4: _content.add_child(_make_research_tab())

func refresh():
	_switch_sub(_sub)

# ═════════════════════════════════════════════════════════════
# 서브탭 0: 성장
# ═════════════════════════════════════════════════════════════
func _make_growth_tab() -> Control:
	var hb := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.add_child(_make_unit_list())
	hb.add_child(_make_growth_detail())
	return hb

func _make_unit_list() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(210, UITheme.CONT_H - 56))

	var title := UITheme.lbl("보유 유닛", UITheme.FS_SM, UITheme.GOLD)
	title.position = Vector2(10, 8)
	bg.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 36)
	scroll.custom_minimum_size = Vector2(210, UITheme.CONT_H - 92)
	bg.add_child(scroll)

	var vb := UITheme.vbox(4)
	vb.custom_minimum_size = Vector2(200, 0)
	scroll.add_child(vb)
	vb.name = "UnitListVB"

	for agent in GameData.get_owned():
		vb.add_child(_make_unit_list_row(agent))
	return bg

func _make_unit_list_row(agent) -> Control:
	var bg := UITheme.crect(UITheme.BG_CARD, Vector2(200, 62))
	var icon := UITheme.crect(agent.color, Vector2(44, 44))
	icon.position = Vector2(6, 9)
	bg.add_child(icon)
	bg.add_child(_lbl_at(agent.name_kr, UITheme.FS_SM, UITheme.rarity_color(agent.rarity), Vector2(58, 10)))
	bg.add_child(_lbl_at("Lv.%d  %s" % [agent.level, "★"*agent.rarity], UITheme.FS_XS, UITheme.GREY, Vector2(58, 32)))
	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.modulate.a = 0.0
	btn.pressed.connect(func(): _select_agent(agent))
	bg.add_child(btn)
	return bg

var _growth_detail_root: Control
var _lv_lbl: Label; var _atk_lbl: Label; var _hp_lbl: Label

func _make_growth_detail() -> Control:
	_growth_detail_root = UITheme.crect(UITheme.BG_PANEL, Vector2(510, UITheme.CONT_H - 56))

	var hint := UITheme.lbl("← 유닛을 선택하세요", UITheme.FS_MD, UITheme.GREY)
	hint.name = "Hint"
	hint.position = Vector2(60, (UITheme.CONT_H - 56) / 2)
	_growth_detail_root.add_child(hint)
	return _growth_detail_root

func _select_agent(agent):
	_selected_agent = agent
	_refresh_growth_detail()

func _refresh_growth_detail():
	if not _growth_detail_root: return
	for c in _growth_detail_root.get_children(): c.queue_free()
	var a = _selected_agent
	if not a: return

	var copies: int = GameData.unit_copies.get(a.id, 0)
	var vb := UITheme.vbox(10)
	vb.position = Vector2(12, 12)
	vb.custom_minimum_size = Vector2(486, 0)
	_growth_detail_root.add_child(vb)

	# 헤더
	var hdr := UITheme.hbox(12)
	hdr.add_child(UITheme.crect(a.color, Vector2(70, 70)))
	var iv := UITheme.vbox(4)
	iv.add_child(UITheme.lbl(a.name_kr, UITheme.FS_LG, UITheme.rarity_color(a.rarity)))
	iv.add_child(UITheme.lbl(UITheme.rarity_label(a.rarity), UITheme.FS_SM, UITheme.GREY))
	iv.add_child(UITheme.lbl("%s · %s" % [a.group, a.job], UITheme.FS_SM, UITheme.CYAN))
	hdr.add_child(iv)
	vb.add_child(hdr)
	vb.add_child(UITheme.hsep())

	# 스탯 행
	var sh := UITheme.hbox(20)
	_lv_lbl  = UITheme.lbl("Lv. %d / %d" % [a.level, MAX_LEVEL], UITheme.FS_MD, UITheme.WHITE)
	_atk_lbl = UITheme.lbl("⚔ %d" % int(a.get_atk()), UITheme.FS_MD, UITheme.ORANGE)
	_hp_lbl  = UITheme.lbl("❤ %d" % int(a.get_hp()),  UITheme.FS_MD, UITheme.HP_GREEN)
	sh.add_child(_lv_lbl); sh.add_child(_atk_lbl); sh.add_child(_hp_lbl)
	vb.add_child(sh)
	vb.add_child(UITheme.lbl("스킬: " + a.skill, UITheme.FS_SM, UITheme.PURPLE))
	vb.add_child(UITheme.hsep())

	# 레벨업
	vb.add_child(UITheme.lbl("■ 레벨업", UITheme.FS_MD, UITheme.GOLD))
	var lv_cost = 100 + a.level * 50 * a.rarity
	vb.add_child(UITheme.lbl("+1 비용: 🪙 %d   보유: 🪙 %d" % [lv_cost, int(GameData.gold)], UITheme.FS_SM, UITheme.GREY))
	var lhb := UITheme.hbox(8)
	for cnt in [1, 10, MAX_LEVEL - a.level]:
		var label = "+%d" % cnt if cnt < MAX_LEVEL else "MAX"
		var b := UITheme.btn(label, UITheme.FS_SM, UITheme.WHITE)
		b.custom_minimum_size = Vector2(110, 50)
		b.pressed.connect(func(): _do_level(a, cnt))
		lhb.add_child(b)
	vb.add_child(lhb)
	vb.add_child(UITheme.hsep())

	# 승급
	var needed = _star_cost(a.rarity)
	vb.add_child(UITheme.lbl("■ 승급  (복사본 필요: %d개, 보유: %d개)" % [needed, copies], UITheme.FS_MD, UITheme.PURPLE))
	var sb := UITheme.btn("승급 (%d개 필요)" % needed, UITheme.FS_MD,
		UITheme.GOLD if copies >= needed else UITheme.GREY_DIM)
	sb.custom_minimum_size = Vector2(280, 52)
	sb.disabled = a.rarity >= 5 or copies < needed
	sb.pressed.connect(func(): _do_star(a))
	vb.add_child(sb)
	if a.rarity >= 5:
		vb.add_child(UITheme.lbl("✓ 최고 등급 달성", UITheme.FS_SM, UITheme.GOLD))
	vb.add_child(UITheme.hsep())

	# 코어 개방
	var core_ok: bool = a.get("core_unlocked", false)
	vb.add_child(UITheme.lbl("■ 코어 개방  (Lv.40 이상, 🪙 5,000)", UITheme.FS_MD, UITheme.CYAN))
	if core_ok:
		vb.add_child(UITheme.lbl("✓ 코어 개방 완료 — 코어 스킬 활성화", UITheme.FS_SM, UITheme.GREEN))
	else:
		var cb := UITheme.btn("코어 개방  🪙 5,000", UITheme.FS_MD,
			UITheme.CYAN if a.level >= 40 else UITheme.GREY_DIM)
		cb.disabled = a.level < 40
		cb.custom_minimum_size = Vector2(280, 52)
		cb.pressed.connect(func(): _do_core(a))
		vb.add_child(cb)
	vb.add_child(UITheme.hsep())

	# 초월 (5★ 전용)
	if a.rarity >= 5:
		var t_lv = GameData.get_transcend_level(a.id)
		var copies_needed = GameData.get_transcend_cost(a.id)
		var cur_copies = GameData.unit_copies.get(a.id, 0)
		var stars_str = "◈".repeat(t_lv) + "◇".repeat(5 - t_lv)
		vb.add_child(UITheme.lbl("■ 초월  %s  (%d/5)" % [stars_str, t_lv], UITheme.FS_MD, UITheme.ORANGE))
		if t_lv < 5:
			vb.add_child(UITheme.lbl("필요 사본: %d개  보유: %d개" % [copies_needed, cur_copies],
				UITheme.FS_SM, UITheme.GREEN if cur_copies >= copies_needed else UITheme.RED))
			var tb := UITheme.btn("초월 (%d개 소모)" % copies_needed, UITheme.FS_MD,
				UITheme.ORANGE if GameData.can_transcend(a.id) else UITheme.GREY_DIM)
			tb.disabled = not GameData.can_transcend(a.id)
			tb.custom_minimum_size = Vector2(280, 52)
			tb.pressed.connect(func(): _do_transcend(a))
			vb.add_child(tb)
			var t_bonus = GameData.get_transcend_bonus(a.id)
			if t_bonus["atk"] > 0 or t_bonus["hp"] > 0:
				vb.add_child(UITheme.lbl("현재 보너스: 공격력 +%d%%  체력 +%d%%" % [
					int(t_bonus["atk"]*100), int(t_bonus["hp"]*100)], UITheme.FS_SM, UITheme.ORANGE))
		else:
			vb.add_child(UITheme.lbl("✓ 최고 초월 달성! 공격력 +75%  체력 +75%", UITheme.FS_SM, UITheme.ORANGE))

func _do_level(agent, cnt: int):
	var actual = mini(cnt, MAX_LEVEL - agent.level)
	if actual <= 0: return _toast("최대 레벨입니다!")
	var total = 0
	for i in actual: total += 100 + (agent.level + i) * 50 * agent.rarity
	if not GameData.spend_gold(float(total)):
		return _toast("🪙 골드가 부족합니다!")
	agent.level += actual
	GameData._add_quest_progress("levelup", actual)
	_refresh_growth_detail()

func _do_star(agent):
	var needed = _star_cost(agent.rarity)
	if GameData.unit_copies.get(agent.id, 0) < needed:
		return _toast("복사본이 부족합니다!")
	GameData.unit_copies[agent.id] -= needed
	agent.rarity += 1
	_refresh_growth_detail()

func _do_core(agent):
	if agent.level < 40: return _toast("Lv.40 이상 필요!")
	if not GameData.spend_gold(5000.0): return _toast("🪙 골드 부족!")
	agent.set_meta("core_unlocked", true)
	_refresh_growth_detail()

func _do_transcend(agent):
	if not GameData.transcend_unit(agent.id):
		return _toast("초월 조건 미충족!")
	_refresh_growth_detail()

func _star_cost(rarity: int) -> int:
	match rarity: 1: return 30; 2: return 20; 3: return 10; 4: return 5
	return 999

# ═════════════════════════════════════════════════════════════
# 서브탭 1: 장비
# ═════════════════════════════════════════════════════════════
var _gear_agent = null
var _gear_slot_selected: String = ""

func _make_equipment_tab() -> Control:
	var hb := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 좌: 유닛 선택
	var left := UITheme.crect(UITheme.BG_DARK, Vector2(200, UITheme.CONT_H - 56))
	var title := UITheme.lbl("유닛 선택", UITheme.FS_SM, UITheme.GOLD)
	title.position = Vector2(10, 8)
	left.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 36); scroll.custom_minimum_size = Vector2(200, UITheme.CONT_H - 92)
	left.add_child(scroll)
	var vb := UITheme.vbox(4); vb.name = "GearListVB"; vb.custom_minimum_size = Vector2(190, 0)
	scroll.add_child(vb)
	for a in GameData.get_owned():
		var btn := Button.new(); btn.text = "%s  Lv.%d" % [a.name_kr, a.level]
		btn.add_theme_font_size_override("font_size", UITheme.FS_SM)
		btn.custom_minimum_size = Vector2(190, 52)
		var ag := a
		btn.pressed.connect(func(): _select_gear_agent(ag))
		vb.add_child(btn)

	# 우: 장비 슬롯 + 장착
	var right := UITheme.crect(UITheme.BG_PANEL, Vector2(520, UITheme.CONT_H - 56))
	right.name = "GearRight"
	var hint := UITheme.lbl("← 유닛을 선택하세요", UITheme.FS_MD, UITheme.GREY)
	hint.name = "GearHint"; hint.position = Vector2(60, 300)
	right.add_child(hint)

	hb.add_child(left); hb.add_child(right)
	return hb

func _select_gear_agent(agent):
	_gear_agent = agent
	_refresh_gear_panel()

func _refresh_gear_panel():
	var right = _content.find_child("GearRight", true, false)
	if not right: return
	for c in right.get_children(): c.queue_free()

	var a = _gear_agent
	if not a: return

	var vb := UITheme.vbox(12)
	vb.position = Vector2(10, 10)
	vb.custom_minimum_size = Vector2(500, 0)
	right.add_child(vb)

	# 유닛 헤더
	var hdr := UITheme.hbox(10)
	hdr.add_child(UITheme.crect(a.color, Vector2(56, 56)))
	var iv := UITheme.vbox(3)
	iv.add_child(UITheme.lbl(a.name_kr, UITheme.FS_LG, UITheme.rarity_color(a.rarity)))
	var es = GameData.get_unit_equip_stats(a.id)
	iv.add_child(UITheme.lbl("장비 보너스  ⚔ +%.0f%%  ❤ +%.0f%%" % [es["atk"]*100, es["hp"]*100],
		UITheme.FS_SM, UITheme.ORANGE))
	hdr.add_child(iv)
	vb.add_child(hdr)
	vb.add_child(UITheme.hsep())

	vb.add_child(UITheme.lbl("── 장착 슬롯 ──", UITheme.FS_SM, UITheme.GOLD))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)

	var gear = GameData.get_unit_equipment(a.id)
	for slot in SLOTS:
		var eid = gear.get(slot, -1)
		var eq  = GameData.get_equipment(eid) if eid != -1 else null
		grid.add_child(_make_gear_slot_card(a, slot, eq))

	vb.add_child(UITheme.hsep())
	vb.add_child(UITheme.lbl("── 보유 장비 ──", UITheme.FS_SM, UITheme.CYAN))

	var inv_scroll := ScrollContainer.new()
	inv_scroll.custom_minimum_size = Vector2(500, 280)
	var inv_grid := GridContainer.new()
	inv_grid.columns = 3
	inv_grid.add_theme_constant_override("h_separation", 8)
	inv_grid.add_theme_constant_override("v_separation", 8)
	inv_scroll.add_child(inv_grid)
	vb.add_child(inv_scroll)

	for eid in GameData.owned_equipment:
		if eid == 0: continue   # 범용 재료 ID
		var cnt = GameData.owned_equipment[eid]
		if cnt <= 0: continue
		var eq := GameData.get_equipment(eid)
		if eq:
			inv_grid.add_child(_make_inv_equip_card(a, eq, cnt))

func _make_gear_slot_card(agent, slot: String, eq) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(155, 80))
	card.add_child(_lbl_at(SLOT_NAMES.get(slot, slot), UITheme.FS_XS, UITheme.GREY, Vector2(6, 4)))
	if eq:
		card.add_child(_lbl_at(eq.name_kr, UITheme.FS_SM, UITheme.rarity_color(eq.rarity), Vector2(6, 22)))
		card.add_child(_lbl_at("Lv.%d  ⚔+%.0f%%  ❤+%.0f%%" % [eq.level, eq.total_atk()*100, eq.total_hp()*100],
			UITheme.FS_XS, UITheme.ORANGE, Vector2(6, 42)))
		# 강화 버튼
		var enh := UITheme.btn("+강화 🪙%d" % eq.enhance_cost(), UITheme.FS_XS, UITheme.CYAN)
		enh.position = Vector2(6, 58); enh.custom_minimum_size = Vector2(100, 18)
		var eid := eq.id
		enh.pressed.connect(func(): _do_enhance(eid))
		card.add_child(enh)
		# 해제 버튼
		var un := UITheme.btn("해제", UITheme.FS_XS, UITheme.RED)
		un.position = Vector2(112, 58); un.custom_minimum_size = Vector2(38, 18)
		var sl2 := slot; var ag := agent
		un.pressed.connect(func(): GameData.unequip_item(ag.id, sl2); _refresh_gear_panel())
		card.add_child(un)
	else:
		card.add_child(_lbl_at("빈 슬롯", UITheme.FS_SM, UITheme.GREY_DIM, Vector2(6, 28)))
	return card

func _make_inv_equip_card(agent, eq, cnt: int) -> Control:
	var card := UITheme.crect(UITheme.rarity_bg(eq.rarity), Vector2(155, 80))
	var border := UITheme.crect(UITheme.rarity_color(eq.rarity), Vector2(155, 2))
	card.add_child(border)
	card.add_child(_lbl_at(eq.name_kr, UITheme.FS_SM, UITheme.rarity_color(eq.rarity), Vector2(6, 4)))
	card.add_child(_lbl_at("%s  Lv.%d" % [SLOT_NAMES.get(eq.slot,"?"), eq.level], UITheme.FS_XS, UITheme.GREY, Vector2(6, 24)))
	card.add_child(_lbl_at("⚔+%.0f%%  ❤+%.0f%%" % [eq.total_atk()*100, eq.total_hp()*100],
		UITheme.FS_XS, UITheme.ORANGE, Vector2(6, 42)))
	card.add_child(_lbl_at("보유 × %d" % cnt, UITheme.FS_XS, UITheme.CYAN, Vector2(6, 60)))

	var equip_btn := UITheme.btn("장착", UITheme.FS_XS, UITheme.GOLD)
	equip_btn.position = Vector2(106, 56); equip_btn.custom_minimum_size = Vector2(44, 22)
	var eid := eq.id; var ag := agent
	equip_btn.pressed.connect(func(): GameData.equip_item(ag.id, eid); _refresh_gear_panel())
	card.add_child(equip_btn)
	return card

func _do_enhance(equip_id: int):
	if not GameData.enhance_equipment(equip_id):
		_toast("골드 부족 또는 최대 강화 완료!")
	else:
		_refresh_gear_panel()

# ═════════════════════════════════════════════════════════════
# 서브탭 2: 유물
# ═════════════════════════════════════════════════════════════
func _make_relic_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vb := UITheme.vbox(14)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	vb.add_child(UITheme.lbl("■ 활성 유물  (최대 3개)", UITheme.FS_MD, UITheme.GOLD))

	# 총 보너스
	var rb = GameData.get_relic_bonuses()
	vb.add_child(UITheme.lbl(
		"팀 보너스  ⚔ +%.0f%%  ❤ +%.0f%%  🪙 +%.0f%%  치명 +%.0f%%" % [
			rb["global_atk"]*100, rb["global_hp"]*100,
			rb["global_gold"]*100, rb["crit_bonus"]*100],
		UITheme.FS_SM, UITheme.ORANGE))
	vb.add_child(UITheme.hsep())

	# 활성 슬롯
	var active_hb := UITheme.hbox(10)
	for i in 3:
		var rid = GameData.active_relics[i] if i < GameData.active_relics.size() else -1
		active_hb.add_child(_make_relic_slot(rid, i))
	vb.add_child(active_hb)
	vb.add_child(UITheme.hsep())

	vb.add_child(UITheme.lbl("■ 보유 유물", UITheme.FS_MD, UITheme.CYAN))
	for rid in GameData.owned_relics:
		vb.add_child(_make_relic_card(rid))

	return scroll

func _make_relic_slot(relic_id: int, slot_idx: int) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(220, 100))
	var border_col = UITheme.GOLD if relic_id != -1 else UITheme.GREY_DIM
	var border := UITheme.crect(border_col, Vector2(220, 2))
	card.add_child(border)
	if relic_id != -1:
		var r = GameData.get_relic(relic_id)
		if r:
			card.add_child(_lbl_at(r.name_kr, UITheme.FS_SM, UITheme.rarity_color(r.rarity), Vector2(8, 6)))
			card.add_child(_lbl_at(r.desc, UITheme.FS_XS, UITheme.GREY, Vector2(8, 28)))
			var un := UITheme.btn("해제", UITheme.FS_XS, UITheme.RED)
			un.position = Vector2(170, 70); un.custom_minimum_size = Vector2(42, 24)
			var rid := relic_id
			un.pressed.connect(func(): GameData.unequip_relic(rid); _switch_sub(2))
			card.add_child(un)
	else:
		card.add_child(_lbl_at("슬롯 %d (비어있음)" % (slot_idx+1), UITheme.FS_SM, UITheme.GREY_DIM, Vector2(8, 36)))
	return card

func _make_relic_card(relic_id: int) -> Control:
	var r = GameData.get_relic(relic_id)
	if not r: return Control.new()
	var card := UITheme.crect(UITheme.rarity_bg(r.rarity), Vector2(UITheme.W - 32, 80))
	var border := UITheme.crect(UITheme.rarity_color(r.rarity), Vector2(4, 80))
	card.add_child(border)
	card.add_child(_lbl_at(r.name_kr, UITheme.FS_MD, UITheme.rarity_color(r.rarity), Vector2(14, 8)))
	card.add_child(_lbl_at(r.desc, UITheme.FS_SM, UITheme.WHITE, Vector2(14, 34)))
	var active = relic_id in GameData.active_relics
	var btn_text = "해제" if active else "장착"
	var btn_col = UITheme.RED if active else UITheme.GREEN
	var ab := UITheme.btn(btn_text, UITheme.FS_SM, btn_col)
	ab.custom_minimum_size = Vector2(80, 50); ab.position = Vector2(UITheme.W - 110, 14)
	var rid := relic_id
	if active:
		ab.pressed.connect(func(): GameData.unequip_relic(rid); _switch_sub(2))
	else:
		ab.pressed.connect(func():
			if not GameData.equip_relic(rid): _toast("유물 슬롯이 가득 찼습니다! (최대 3개)")
			else: _switch_sub(2)
		)
	card.add_child(ab)
	return card

# ═════════════════════════════════════════════════════════════
# 서브탭 3: 도감 (Collection Codex)
# ═════════════════════════════════════════════════════════════
func _make_codex_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := UITheme.vbox(12)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	var bonus = GameData.get_codex_bonus()
	var count = bonus["count"]; var total = bonus["total"]
	vb.add_child(UITheme.lbl("📚 수집 도감", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.lbl("더 많은 유닛을 수집할수록 팀 전체가 강해집니다", UITheme.FS_SM, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	vb.add_child(UITheme.lbl("수집 현황: %d / %d" % [count, total], UITheme.FS_LG, UITheme.CYAN))
	var cb_root := Control.new(); cb_root.custom_minimum_size = Vector2(UITheme.W - 32, 22)
	cb_root.add_child(UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 22)))
	cb_root.add_child(UITheme.crect(UITheme.CYAN, Vector2((UITheme.W - 32) * float(count)/float(total), 22)))
	vb.add_child(cb_root)

	if bonus["atk"] > 0 or bonus["hp"] > 0:
		var brow := UITheme.hbox(16)
		brow.add_child(UITheme.lbl("팀 보너스:", UITheme.FS_MD, UITheme.GOLD))
		brow.add_child(UITheme.lbl("공격력 +%d%%" % int(bonus["atk"]*100), UITheme.FS_MD, UITheme.ORANGE))
		brow.add_child(UITheme.lbl("체력 +%d%%"   % int(bonus["hp"]*100),  UITheme.FS_MD, UITheme.GREEN))
		vb.add_child(brow)
	vb.add_child(UITheme.hsep())

	vb.add_child(UITheme.lbl("■ 수집 달성 보너스", UITheme.FS_MD, UITheme.CYAN))
	const MILES := [[5,"공격력 +2%  체력 +2%"],[10,"공격력 +5%  체력 +5%"],
	                [15,"공격력 +10%  체력 +10%"],[21,"공격력 +20%  체력 +20% ✦ 완전 수집"]]
	for ms in MILES:
		var col  = UITheme.GREEN if count >= ms[0] else UITheme.GREY
		var mark = "✓ " if count >= ms[0] else "□ "
		vb.add_child(UITheme.lbl("%s%d종: %s" % [mark, ms[0], ms[1]], UITheme.FS_SM, col))
	vb.add_child(UITheme.hsep())

	vb.add_child(UITheme.lbl("■ 유닛 도감", UITheme.FS_MD, UITheme.GOLD))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for a in GameData.all_agents:
		grid.add_child(_make_codex_card(a))
	vb.add_child(grid)
	return scroll

func _make_codex_card(a) -> Control:
	var owned  = GameData.is_owned(a.id)
	var card   := UITheme.crect(UITheme.rarity_bg(a.rarity) if owned else UITheme.BG_DARK, Vector2(162, 88))
	card.add_child(UITheme.crect(UITheme.rarity_color(a.rarity) if owned else UITheme.GREY_DIM, Vector2(162, 3)))
	var name_c = UITheme.rarity_color(a.rarity) if owned else UITheme.GREY_DIM
	var n  := UITheme.lbl(a.name_kr if owned else "???", UITheme.FS_SM, name_c); n.position = Vector2(6, 8)
	var st := UITheme.lbl(("★" * a.rarity) if owned else "- -", UITheme.FS_XS, name_c); st.position = Vector2(6, 32)
	card.add_child(n); card.add_child(st)
	if owned:
		var t_lv = GameData.get_transcend_level(a.id)
		var cp := UITheme.lbl("사본 %d개" % GameData.unit_copies.get(a.id, 0), UITheme.FS_XS, UITheme.GREY)
		cp.position = Vector2(6, 54); card.add_child(cp)
		if t_lv > 0:
			var tl := UITheme.lbl("초월 %d" % t_lv, UITheme.FS_XS, UITheme.ORANGE)
			tl.position = Vector2(86, 54); card.add_child(tl)
	return card

# ═════════════════════════════════════════════════════════════
# 서브탭 4: 연구소 (Research Lab)
# ═════════════════════════════════════════════════════════════
func _make_research_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := UITheme.vbox(10)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)

	vb.add_child(UITheme.lbl("🔬 연구소", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.lbl("연구를 통해 팀의 능력치를 영구적으로 강화합니다", UITheme.FS_SM, UITheme.GREY))

	var rb = GameData.get_research_bonus()
	vb.add_child(UITheme.lbl(
		"현재 효과: 공격력 +%d%%  체력 +%d%%  골드 +%d%%" % [
		int(rb["atk"]*100), int(rb["hp"]*100), int(rb["gold"]*100)],
		UITheme.FS_SM, UITheme.CYAN))
	vb.add_child(UITheme.lbl("보유: 🪙 %d  💎 %d" % [int(GameData.gold), GameData.gems],
		UITheme.FS_SM, UITheme.GOLD))
	vb.add_child(UITheme.hsep())

	for d in GameData.RESEARCH_DEFS:
		vb.add_child(_make_research_card(d))
	return scroll

func _make_research_card(d: Dictionary) -> Control:
	var rid    = d["id"]
	var lv     = GameData.get_research_level(rid)
	var max_lv = d["max_lv"]
	var can    = GameData.can_research(rid)
	var locked = d.has("req") and lv == 0 and not can
	var card   := UITheme.crect(UITheme.BG_CARD if not locked else UITheme.BG_DARK, Vector2(UITheme.W - 32, 100))
	card.add_child(UITheme.crect(
		UITheme.CYAN if can else (UITheme.GREY_DIM if locked else UITheme.GREY), Vector2(4, 100)))

	var nm := UITheme.lbl(d["name"], UITheme.FS_MD, UITheme.WHITE if not locked else UITheme.GREY_DIM)
	nm.position = Vector2(14, 8); card.add_child(nm)
	var lv_l := UITheme.lbl("Lv.%d / %d" % [lv, max_lv], UITheme.FS_SM,
		UITheme.GOLD if lv > 0 else UITheme.GREY_DIM)
	lv_l.position = Vector2(14, 34); card.add_child(lv_l)
	var ds := UITheme.lbl(d["desc"], UITheme.FS_XS, UITheme.GREY)
	ds.position = Vector2(14, 56); card.add_child(ds)

	var bar_root := Control.new(); bar_root.custom_minimum_size = Vector2(280, 10)
	bar_root.position = Vector2(14, 80)
	bar_root.add_child(UITheme.crect(UITheme.BG_INNER, Vector2(280, 10)))
	bar_root.add_child(UITheme.crect(UITheme.CYAN, Vector2(280 * float(lv)/float(max_lv), 10)))
	card.add_child(bar_root)

	if locked:
		var req_str = d.get("req", "").replace(":", " Lv.")
		var lk := UITheme.lbl("🔒 선행: " + req_str, UITheme.FS_XS, UITheme.GREY_DIM)
		lk.position = Vector2(UITheme.W - 280, 40); card.add_child(lk)
		return card

	if lv >= max_lv:
		var dn := UITheme.lbl("✓ 완료", UITheme.FS_MD, UITheme.GREEN)
		dn.position = Vector2(UITheme.W - 110, 30); card.add_child(dn)
	else:
		var cost_str = "🪙 %d" % d["cost_gold"] if d["cost_gold"] > 0 else "💎 %d" % d["cost_gems"]
		var cl := UITheme.lbl(cost_str, UITheme.FS_SM, UITheme.GOLD)
		cl.position = Vector2(UITheme.W - 190, 18); card.add_child(cl)
		var rb := UITheme.btn("연구", UITheme.FS_SM, UITheme.CYAN if can else UITheme.GREY_DIM)
		rb.position = Vector2(UITheme.W - 112, 38); rb.custom_minimum_size = Vector2(86, 44)
		rb.disabled = not can
		var r_id := rid
		rb.pressed.connect(func():
			if not GameData.do_research(r_id): _toast("조건 미충족 또는 재화 부족!")
			else: _switch_sub(4)
		)
		card.add_child(rb)
	return card

# ─────────────────────────────────────────────────────────────
# 헬퍼
# ─────────────────────────────────────────────────────────────
func _lbl_at(text: String, fs: int, col: Color, pos: Vector2) -> Label:
	var l := UITheme.lbl(text, fs, col); l.position = pos; return l

func _toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_SM, UITheme.RED)
	lbl.position = Vector2(UITheme.W / 2 - 160, UITheme.CONT_H / 2)
	lbl.custom_minimum_size = Vector2(320, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 50, 1.4)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.4)
	tw.tween_callback(lbl.queue_free)
