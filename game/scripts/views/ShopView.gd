extends Control
# ============================================================
# ShopView.gd — 상점 탭
# 서브탭: 골드상점 / 소환상점 / 재화교환 / 일일임무 / 배틀패스
# ============================================================

var _sub := 0
var _sub_btns: Array = []
var _content: Control

# ─────────────────────────────────────────────────────────────
func _ready():
	custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)
	_build()

func _build():
	var root := UITheme.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# HUD
	root.add_child(_make_hud())

	# 서브 탭 바
	root.add_child(_make_sub_tab_bar())

	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H - 88 - 52)
	root.add_child(_content)

	_switch_sub(0)

# ─────────────────────────────────────────────────────────────
func _make_hud() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 88))
	bg.add_child(_lbl_at("🏪 상점", UITheme.FS_XL, UITheme.GOLD, Vector2(16, 14)))
	bg.add_child(_lbl_at("🪙 %d" % int(GameData.gold), UITheme.FS_MD, UITheme.GOLD, Vector2(UITheme.W - 240, 14)))
	bg.add_child(_lbl_at("💎 %d" % GameData.gems, UITheme.FS_MD, UITheme.GEM,  Vector2(UITheme.W - 240, 46)))
	bg.add_child(_lbl_at("🎟 %d" % GameData.summon_tickets, UITheme.FS_SM, UITheme.CYAN, Vector2(UITheme.W - 130, 14)))
	return bg

func _make_sub_tab_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_PANEL, Vector2(UITheme.W, 52))
	var hb  := UITheme.hbox(0); hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.add_child(hb)
	for txt in ["💰 골드","🎲 소환","🔄 교환","📋 임무","🎯 패스","🏆 업적"]:
		var b := Button.new(); b.text = txt
		b.add_theme_font_size_override("font_size", UITheme.FS_XS)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size   = Vector2(0, 52)
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
		0: _content.add_child(_make_gold_shop())
		1: _content.add_child(_make_summon_shop())
		2: _content.add_child(_make_exchange_tab())
		3: _content.add_child(_make_quest_tab())
		4: _content.add_child(_make_bp_tab())
		5: _content.add_child(_make_achievement_tab())

func refresh():
	_switch_sub(_sub)

# ═════════════════════════════════════════════════════════════
# 서브탭 0: 골드 상점
# ═════════════════════════════════════════════════════════════
func _make_gold_shop() -> Control:
	return _make_scroll_shop("💰 골드 상점", "매일 오전 5시 리셋", "gold")

# ═════════════════════════════════════════════════════════════
# 서브탭 1: 소환 상점
# ═════════════════════════════════════════════════════════════
func _make_summon_shop() -> Control:
	var scroll := _make_scroll_base()
	var vb     := _get_scroll_vb(scroll)

	vb.add_child(UITheme.lbl("🎲 소환 상점", UITheme.FS_LG, UITheme.PURPLE))
	vb.add_child(UITheme.lbl("젬으로 소환 재화 구매", UITheme.FS_XS, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	for it in GameData.get_shop_items():
		if it["type"] == "summon":
			vb.add_child(_make_item_card(it))

	vb.add_child(UITheme.hsep())
	vb.add_child(UITheme.lbl("📦 패키지", UITheme.FS_MD, UITheme.ORANGE))
	vb.add_child(_make_package("신규 영웅 패키지", "💎 600 + 소환권 ×5", Color(0.65,0.25,0.95)))
	vb.add_child(_make_package("월간 구독 (30일)", "💎 100/일 + 고급권 ×3", UITheme.GOLD))
	vb.add_child(_make_package("전설 패키지", "💎 3,000 + 전설권 ×1", Color(1.0,0.78,0.05)))
	return scroll

# ═════════════════════════════════════════════════════════════
# 서브탭 2: 재화 교환
# ═════════════════════════════════════════════════════════════
func _make_exchange_tab() -> Control:
	var scroll := _make_scroll_base()
	var vb     := _get_scroll_vb(scroll)

	vb.add_child(UITheme.lbl("🔄 재화 교환", UITheme.FS_LG, UITheme.CYAN))
	vb.add_child(UITheme.hsep())

	var exchanges := [
		{"name":"소환권","desc":"일반 소환권 ×1",   "gold":500,   "gives":"ticket"},
		{"name":"고급 소환권","desc":"4★+ 확정 ×1","gems":150,   "gives":"rare_ticket"},
		{"name":"전설 소환권","desc":"전설 풀 ×1",  "gold":50000, "gives":"legend_ticket"},
		{"name":"강화 재료(소)","desc":"장비 강화 ×3","gold":300, "gives":"mat_s"},
		{"name":"강화 재료(대)","desc":"장비 강화 ×30","gems":50, "gives":"mat_l"},
		{"name":"골드 → 젬","desc":"🪙10,000 → 💎10","gold":10000,"gives":"gems_10"},
		{"name":"젬 → 골드","desc":"💎50 → 🪙5,000","gems":50,   "gives":"gold_5k"},
	]
	for ex in exchanges:
		vb.add_child(_make_exchange_card(ex))
	return scroll

# ═════════════════════════════════════════════════════════════
# 서브탭 3: 일일 임무
# ═════════════════════════════════════════════════════════════
func _make_quest_tab() -> Control:
	var scroll := _make_scroll_base()
	var vb     := _get_scroll_vb(scroll)

	vb.add_child(UITheme.lbl("📋 일일 임무", UITheme.FS_LG, UITheme.GOLD))
	vb.add_child(UITheme.lbl("매일 오전 5시 리셋", UITheme.FS_XS, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	# 포인트 누적 보상 바
	vb.add_child(_make_point_track())
	vb.add_child(UITheme.hsep())

	# 퀘스트 목록
	var quests = GameData.get_daily_quests()
	for q in quests:
		vb.add_child(_make_quest_card(q))

	return scroll

func _make_point_track() -> Control:
	var bg := UITheme.crect(Color(0.10, 0.05, 0.18), Vector2(UITheme.W - 32, 80))
	_lbl_at_c(bg, "일일 포인트  %d / 200" % GameData.quest_points, UITheme.FS_MD, UITheme.GOLD, Vector2(10, 8))

	# 포인트 바
	var bar_bg := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 52, 14))
	bar_bg.position = Vector2(10, 36)
	bg.add_child(bar_bg)
	var fill_w = (UITheme.W - 52) * clampf(float(GameData.quest_points) / 200.0, 0.0, 1.0)
	var bar_fill := UITheme.crect(UITheme.GOLD, Vector2(fill_w, 14))
	bar_fill.position = Vector2(10, 36)
	bg.add_child(bar_fill)

	# 단계 보상 표시
	var pts = [50, 100, 150, 200]
	var labels = ["🪙1K", "💎10", "🪙3K", "🎟+💎30"]
	for i in pts.size():
		var x = (UITheme.W - 52) * float(pts[i]) / 200.0 + 10
		_lbl_at_c(bg, "▲\n%s" % labels[i], UITheme.FS_XS,
			UITheme.GREEN if GameData.quest_points >= pts[i] else UITheme.GREY_DIM,
			Vector2(x - 10, 52))
	return bg

func _make_quest_card(q: Dictionary) -> Control:
	var done: bool = q["done"]
	var prog: int  = q["progress"]
	var tgt:  int  = q["target"]
	var bg := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 90))

	# 완료 체크 배경
	if done:
		var tick := UITheme.crect(UITheme.GREEN.darkened(0.7), Vector2(4, 90))
		bg.add_child(tick)

	_lbl_at_c(bg, q["name"], UITheme.FS_MD, UITheme.WHITE if not done else UITheme.GREY, Vector2(14, 8))
	_lbl_at_c(bg, "보상  🪙 %d  💎 %d  포인트 %d" % [q["reward_gold"], q["reward_gems"], q["points"]],
		UITheme.FS_XS, UITheme.GREY, Vector2(14, 34))

	# 진행 바
	var bar_bg := UITheme.crect(UITheme.BG_DARK, Vector2(280, 10))
	bar_bg.position = Vector2(14, 56)
	bg.add_child(bar_bg)
	var fill_w = 280.0 * clampf(float(prog) / float(tgt), 0.0, 1.0)
	var bar_fill := UITheme.crect(UITheme.GOLD if not done else UITheme.GREEN, Vector2(fill_w, 10))
	bar_fill.position = Vector2(14, 56)
	bg.add_child(bar_fill)
	_lbl_at_c(bg, "%d / %d" % [prog, tgt], UITheme.FS_XS, UITheme.WHITE, Vector2(300, 54))

	# 수령/완료 버튼
	if done:
		_lbl_at_c(bg, "✓ 완료", UITheme.FS_SM, UITheme.GREEN, Vector2(UITheme.W - 110, 32))
	elif prog >= tgt:
		var cl := UITheme.btn("수령!", UITheme.FS_SM, UITheme.GOLD)
		cl.position = Vector2(UITheme.W - 120, 20); cl.custom_minimum_size = Vector2(88, 52)
		var qid := q["id"]
		cl.pressed.connect(func(): GameData.claim_quest(qid); _switch_sub(3))
		bg.add_child(cl)
	return bg

# ═════════════════════════════════════════════════════════════
# 서브탭 4: 배틀패스
# ═════════════════════════════════════════════════════════════
func _make_bp_tab() -> Control:
	var scroll := _make_scroll_base()
	var vb     := _get_scroll_vb(scroll)

	vb.add_child(UITheme.lbl("🎯 배틀패스  시즌 %d" % GameData.bp_season, UITheme.FS_LG, UITheme.GOLD))

	# 패스 레벨 바
	var exp_pct = clampf(float(GameData.bp_exp) / float(GameData.BP_LEVEL_EXP), 0.0, 1.0)
	vb.add_child(UITheme.lbl("Lv.%d  EXP %d / %d" % [GameData.bp_level, GameData.bp_exp, GameData.BP_LEVEL_EXP],
		UITheme.FS_MD, UITheme.CYAN))
	var bar_bg := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 16))
	var bar_fill := UITheme.crect(UITheme.CYAN, Vector2((UITheme.W - 32) * exp_pct, 16))
	var bar_root := Control.new(); bar_root.custom_minimum_size = Vector2(UITheme.W - 32, 16)
	bar_root.add_child(bar_bg); bar_root.add_child(bar_fill)
	vb.add_child(bar_root)

	if not GameData.bp_premium:
		var buy_btn := UITheme.btn("프리미엄 패스 구매  💎 1,500", UITheme.FS_MD, UITheme.GOLD)
		buy_btn.custom_minimum_size = Vector2(UITheme.W - 32, 60)
		buy_btn.pressed.connect(func():
			if GameData.spend_gems(1500):
				GameData.bp_premium = true; _switch_sub(4)
			else: _toast("💎 젬이 부족합니다!")
		)
		vb.add_child(buy_btn)

	vb.add_child(UITheme.hsep())

	# 보상 목록
	for rw in GameData.BP_REWARDS:
		vb.add_child(_make_bp_reward_row(rw))

	vb.add_child(UITheme.hsep())
	vb.add_child(UITheme.lbl("EXP 획득 방법: 일일 퀘스트, 던전, 투기장, 소환 진행 시 획득",
		UITheme.FS_XS, UITheme.GREY))
	return scroll

func _make_bp_reward_row(rw: Dictionary) -> Control:
	var lv    = rw["level"]
	var unlocked = lv <= GameData.bp_level
	var card  := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 74))
	if lv == GameData.bp_level:
		var glow := UITheme.crect(UITheme.GOLD.darkened(0.7), Vector2(UITheme.W - 32, 74))
		card.add_child(glow)

	_lbl_at_c(card, "Lv.%d" % lv, UITheme.FS_MD, UITheme.GOLD if unlocked else UITheme.GREY_DIM, Vector2(10, 10))

	# 무료 보상
	_lbl_at_c(card, "무료: %s" % _fmt_reward(rw["free"]),
		UITheme.FS_SM, UITheme.WHITE if unlocked else UITheme.GREY_DIM, Vector2(80, 10))
	var free_key := "%d_f" % lv
	if not free_key in GameData.bp_claimed and unlocked:
		var fb := UITheme.btn("수령", UITheme.FS_XS, UITheme.GREEN)
		fb.position = Vector2(UITheme.W - 230, 8); fb.custom_minimum_size = Vector2(66, 32)
		var l := lv
		fb.pressed.connect(func(): GameData.claim_bp_reward(l, false); _switch_sub(4))
		card.add_child(fb)
	elif free_key in GameData.bp_claimed:
		_lbl_at_c(card, "✓", UITheme.FS_MD, UITheme.GREEN, Vector2(UITheme.W - 220, 8))

	# 프리미엄 보상
	var prem_col = UITheme.GOLD if GameData.bp_premium and unlocked else UITheme.GREY_DIM
	_lbl_at_c(card, "프리미엄: %s" % _fmt_reward(rw["premium"]),
		UITheme.FS_SM, prem_col, Vector2(80, 42))
	var prem_key := "%d_p" % lv
	if GameData.bp_premium and unlocked and not prem_key in GameData.bp_claimed:
		var pb := UITheme.btn("수령", UITheme.FS_XS, UITheme.GOLD)
		pb.position = Vector2(UITheme.W - 230, 40); pb.custom_minimum_size = Vector2(66, 32)
		var l := lv
		pb.pressed.connect(func(): GameData.claim_bp_reward(l, true); _switch_sub(4))
		card.add_child(pb)
	elif prem_key in GameData.bp_claimed:
		_lbl_at_c(card, "✓", UITheme.FS_MD, UITheme.GOLD, Vector2(UITheme.W - 220, 40))
	elif not GameData.bp_premium:
		_lbl_at_c(card, "🔒", UITheme.FS_MD, UITheme.GREY_DIM, Vector2(UITheme.W - 220, 40))

	return card

# ═════════════════════════════════════════════════════════════
# 서브탭 5: 업적
# ═════════════════════════════════════════════════════════════
func _make_achievement_tab() -> Control:
	var scroll := _make_scroll_base()
	var vb     := _get_scroll_vb(scroll)

	var achs = GameData.get_achievements()
	var done_count     = achs.filter(func(a): return a["done"]).size()
	var claimable_count = achs.filter(func(a): return a["claimable"]).size()

	vb.add_child(UITheme.lbl("🏆 업적", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.lbl("달성: %d / %d" % [done_count, achs.size()], UITheme.FS_MD, UITheme.CYAN))
	if claimable_count > 0:
		vb.add_child(UITheme.lbl("⚡ 수령 가능: %d개" % claimable_count, UITheme.FS_SM, UITheme.GREEN))
	vb.add_child(UITheme.hsep())

	for ach_data in achs:
		vb.add_child(_make_achievement_card(ach_data))
	return scroll

func _make_achievement_card(ach_data: Dictionary) -> Control:
	var done      = ach_data["done"]
	var claimable = ach_data["claimable"]
	var progress  = ach_data["progress"]
	var goal      = ach_data["goal"]
	var card      := UITheme.crect(UITheme.BG_CARD if not done else UITheme.BG_INNER, Vector2(UITheme.W - 32, 88))
	var bdr_col   = UITheme.GOLD if done else (UITheme.GREEN if claimable else UITheme.GREY_DIM)
	card.add_child(UITheme.crect(bdr_col, Vector2(4, 88)))

	_lbl_at_c(card, ach_data["name"], UITheme.FS_MD,
		UITheme.GOLD if done else (UITheme.WHITE if claimable else UITheme.GREY), Vector2(14, 8))
	_lbl_at_c(card, ach_data["desc"], UITheme.FS_SM, UITheme.GREY, Vector2(14, 34))

	var pct = clampf(float(progress) / float(goal), 0.0, 1.0)
	var pb_bg   := UITheme.crect(UITheme.BG_INNER, Vector2(260, 8)); pb_bg.position = Vector2(14, 58)
	var pb_fill := UITheme.crect(UITheme.GREEN if done else UITheme.CYAN, Vector2(260 * pct, 8))
	pb_fill.position = Vector2(14, 58)
	card.add_child(pb_bg); card.add_child(pb_fill)
	_lbl_at_c(card, "%d / %d" % [mini(progress, goal), goal], UITheme.FS_XS, UITheme.GREY, Vector2(14, 70))

	var rw = ach_data["reward"]
	var rw_parts = []
	if rw.get("gold",          0) > 0: rw_parts.append("🪙%d" % rw["gold"])
	if rw.get("gems",          0) > 0: rw_parts.append("💎%d" % rw["gems"])
	if rw.get("legend_ticket", 0) > 0: rw_parts.append("전설권×%d" % rw["legend_ticket"])
	_lbl_at_c(card, "보상: %s" % " ".join(rw_parts), UITheme.FS_XS,
		UITheme.GOLD if done else UITheme.GREY, Vector2(290, 8))

	if done:
		_lbl_at_c(card, "✓ 완료", UITheme.FS_MD, UITheme.GREEN, Vector2(UITheme.W - 100, 30))
	elif claimable:
		var cb := UITheme.btn("수령", UITheme.FS_MD, UITheme.GOLD)
		cb.position = Vector2(UITheme.W - 110, 18); cb.custom_minimum_size = Vector2(86, 52)
		var aid := ach_data["id"]
		cb.pressed.connect(func(): GameData.claim_achievement(aid); _switch_sub(5))
		card.add_child(cb)
	return card

func _fmt_reward(rw: Dictionary) -> String:
	var parts = []
	if rw.get("gold", 0) > 0:          parts.append("🪙 %d" % rw["gold"])
	if rw.get("gems", 0) > 0:          parts.append("💎 %d" % rw["gems"])
	if rw.get("ticket", 0) > 0:        parts.append("소환권 ×%d" % rw["ticket"])
	if rw.get("rare_ticket", 0) > 0:   parts.append("고급권 ×%d" % rw["rare_ticket"])
	if rw.get("legend_ticket", 0) > 0: parts.append("전설권 ×%d" % rw["legend_ticket"])
	return "  ".join(parts)

# ─────────────────────────────────────────────────────────────
# 공통 헬퍼
# ─────────────────────────────────────────────────────────────
func _make_scroll_shop(title: String, subtitle: String, item_type: String) -> Control:
	var scroll := _make_scroll_base()
	var vb     := _get_scroll_vb(scroll)
	vb.add_child(UITheme.lbl(title, UITheme.FS_LG, UITheme.GOLD))
	vb.add_child(UITheme.lbl(subtitle, UITheme.FS_XS, UITheme.GREY))
	vb.add_child(UITheme.hsep())
	for it in GameData.get_shop_items():
		if it["type"] == item_type:
			vb.add_child(_make_item_card(it))
	return scroll

func _make_scroll_base() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return s

func _get_scroll_vb(scroll: ScrollContainer) -> VBoxContainer:
	var vb := UITheme.vbox(10)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(vb); scroll.add_child(pad)
	return vb

func _make_item_card(it: Dictionary) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 80))
	var col = it.get("color", UITheme.WHITE)
	var icon := UITheme.crect(col, Vector2(56, 56)); icon.position = Vector2(10, 12)
	card.add_child(icon)
	_lbl_at_c(card, it.get("name","?"), UITheme.FS_MD, UITheme.WHITE, Vector2(78, 10))
	_lbl_at_c(card, it.get("desc",""),  UITheme.FS_XS, UITheme.GREY,  Vector2(78, 36))
	var is_gem = it.get("currency","gem") == "gem"
	var cost = it.get("cost", 0)
	var cost_lbl = ("💎 %d" % cost) if is_gem else ("🪙 %d" % it.get("cost_gold", 0))
	_lbl_at_c(card, cost_lbl, UITheme.FS_SM, UITheme.GEM if is_gem else UITheme.GOLD, Vector2(UITheme.W - 180, 10))
	var buy := UITheme.btn("구매", UITheme.FS_SM, UITheme.WHITE)
	buy.position = Vector2(UITheme.W - 110, 18); buy.custom_minimum_size = Vector2(78, 44)
	var item := it
	buy.pressed.connect(func(): _buy(item))
	card.add_child(buy)
	return card

func _make_package(name: String, desc: String, col: Color) -> Control:
	var card := UITheme.crect(col.darkened(0.6), Vector2(UITheme.W - 32, 80))
	var stripe := UITheme.crect(col, Vector2(4, 80)); card.add_child(stripe)
	_lbl_at_c(card, name, UITheme.FS_MD, col, Vector2(14, 10))
	_lbl_at_c(card, desc, UITheme.FS_SM, UITheme.WHITE, Vector2(14, 38))
	var buy := UITheme.btn("구매", UITheme.FS_SM, UITheme.GOLD)
	buy.position = Vector2(UITheme.W - 110, 18); buy.custom_minimum_size = Vector2(78, 44)
	buy.pressed.connect(func(): _toast("결제 기능은 런칭 후 오픈됩니다."))
	card.add_child(buy)
	return card

func _make_exchange_card(ex: Dictionary) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 80))
	_lbl_at_c(card, ex["name"], UITheme.FS_MD, UITheme.CYAN, Vector2(12, 10))
	_lbl_at_c(card, ex["desc"], UITheme.FS_SM, UITheme.GREY,  Vector2(12, 36))
	var use_gold = ex.has("gold")
	var cost_str = ("🪙 %d" % ex.get("gold",0)) if use_gold else ("💎 %d" % ex.get("gems",0))
	_lbl_at_c(card, cost_str, UITheme.FS_SM, UITheme.GOLD if use_gold else UITheme.GEM, Vector2(UITheme.W - 190, 10))
	var xbtn := UITheme.btn("교환", UITheme.FS_SM, UITheme.WHITE)
	xbtn.position = Vector2(UITheme.W - 110, 18); xbtn.custom_minimum_size = Vector2(78, 44)
	var e := ex
	xbtn.pressed.connect(func(): _exchange(e))
	card.add_child(xbtn)
	return card

func _buy(item: Dictionary):
	var is_gem = item.get("currency","gem") == "gem"
	var ok = GameData.spend_gems(item.get("cost",0)) if is_gem else GameData.spend_gold(item.get("cost_gold",0.0))
	if not ok: return _toast("재화 부족!")
	var give = item.get("give","")
	match give:
		"gold":   GameData.add_gold(item.get("amount",0))
		"ticket": GameData.summon_tickets += item.get("amount",0)
	_toast("✅ %s 구매 완료!" % item.get("name",""))
	GameData._add_quest_progress("shop", 1)
	_switch_sub(_sub)

func _exchange(ex: Dictionary):
	var use_gold = ex.has("gold")
	var ok = GameData.spend_gold(float(ex.get("gold",0))) if use_gold else GameData.spend_gems(ex.get("gems",0))
	if not ok: return _toast("재화 부족!")
	match ex.get("gives",""):
		"ticket":        GameData.summon_tickets  += 1
		"rare_ticket":   GameData.rare_tickets    += 1
		"legend_ticket": GameData.legend_tickets  += 1
		"gems_10":       GameData.add_gems(10)
		"gold_5k":       GameData.add_gold(5000)
		"mat_s":         GameData.owned_equipment[0] = GameData.owned_equipment.get(0,0) + 3
		"mat_l":         GameData.owned_equipment[0] = GameData.owned_equipment.get(0,0) + 30
	_toast("✅ 교환 완료!")
	_switch_sub(_sub)

func _lbl_at(t:String,f:int,c:Color,p:Vector2)->Label:
	var l=UITheme.lbl(t,f,c); l.position=p; return l

func _lbl_at_c(parent:Control,t:String,f:int,c:Color,p:Vector2):
	parent.add_child(_lbl_at(t,f,c,p))

func _toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_SM, UITheme.GREEN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(UITheme.W, 0)
	lbl.position = Vector2(0, 200)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 60, 1.6)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.6)
	tw.tween_callback(lbl.queue_free)
