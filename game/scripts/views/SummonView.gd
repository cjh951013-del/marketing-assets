extends Control
# ============================================================
# SummonView.gd — 소환 탭
# 배너 구조 (Cat Hero + AFK Arena 스타일)
#  이벤트 | 일반영웅 | 전설 | 우정
#  소프트 피티(확률 점진 상승) + 하드 피티(천장)
#  10연 4★ 보장 / 무료 1회(일반) / 우정 포인트
# ============================================================

const BANNER_KEYS = ["event", "hero", "legend", "friend"]
const BANNER_LABELS = ["이벤트", "일반영웅", "전설", "우정"]
const HARD_PITY = {"event":50,"hero":80,"legend":20,"friend":5}
const SOFT_START = {"event":40,"hero":65,"legend":15,"friend":999}

var _cur := 0          # 현재 배너 인덱스
var _currency_lbl:  Label
var _pity_bar_fill: Control
var _pity_bar_lbl:  Label
var _fourpity_lbl:  Label
var _free_btn:      Button
var _result_root:   Control   # 결과 오버레이
var _result_grid:   GridContainer
var _result_summary: Label
var _hist_hbox:     HBoxContainer
var _banner_title:  Label
var _featured_row:  HBoxContainer
var _rate_labels:   Array = []

# ─────────────────────────────────────────────────────────────
func _ready():
	custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)
	_build()

func _build():
	var root := UITheme.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	root.add_child(_make_banner_tab_bar())   # h=52
	root.add_child(_make_banner_art_area())  # h=250
	root.add_child(_make_featured_area())    # h=80
	root.add_child(_make_currency_bar())     # h=52
	root.add_child(_make_pity_bar())         # h=72
	root.add_child(_make_pull_buttons())     # h=110
	root.add_child(_make_rate_row())         # h=64
	root.add_child(_make_history_row())      # h=140
	# 나머지: 결과 오버레이 (숨겨진 전체화면)
	_result_root = _make_result_overlay()
	add_child(_result_root)

# ─────────────────────────────────────────────────────────────
# 배너 탭 바
# ─────────────────────────────────────────────────────────────
func _make_banner_tab_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 52))
	var hb  := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(hb)
	for i in 4:
		var b := Button.new()
		b.text = BANNER_LABELS[i]
		b.name = "BannerTab_%d" % i
		b.add_theme_font_size_override("font_size", UITheme.FS_SM)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size   = Vector2(0, 52)
		var idx := i
		b.pressed.connect(func(): _switch_banner(idx))
		hb.add_child(b)
	return bg

# ─────────────────────────────────────────────────────────────
# 배너 아트 영역
# ─────────────────────────────────────────────────────────────
func _make_banner_art_area() -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(UITheme.W, 250)

	var bg := UITheme.crect(Color(0.07, 0.03, 0.18), Vector2(UITheme.W, 250))
	root.add_child(bg)

	# 별빛 장식
	for _i in 16:
		var s := Label.new()
		s.text = ["✦","★","✧"][randi() % 3]
		s.add_theme_font_size_override("font_size", randi_range(9, 20))
		s.add_theme_color_override("font_color", Color(1,1,1, randf_range(0.08, 0.35)))
		s.position = Vector2(randf_range(10, UITheme.W - 30), randf_range(10, 230))
		root.add_child(s)

	# 배너 아트 박스
	var art := UITheme.crect(Color(0.15, 0.06, 0.32), Vector2(300, 200))
	art.position = Vector2((UITheme.W - 300) / 2, 20)
	root.add_child(art)

	# 배너 명칭 오버레이
	_banner_title = UITheme.lbl("", UITheme.FS_XL, UITheme.GOLD)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.position = Vector2(0, 218)
	_banner_title.custom_minimum_size = Vector2(UITheme.W, 28)
	root.add_child(_banner_title)

	return root

# ─────────────────────────────────────────────────────────────
# 픽업 캐릭터 행
# ─────────────────────────────────────────────────────────────
func _make_featured_area() -> Control:
	var bg := UITheme.crect(Color(0.10, 0.05, 0.20), Vector2(UITheme.W, 80))
	var label := UITheme.lbl("픽업", UITheme.FS_XS, UITheme.GREY)
	label.position = Vector2(12, 6)
	bg.add_child(label)
	_featured_row = UITheme.hbox(12)
	_featured_row.position = Vector2(12, 24)
	bg.add_child(_featured_row)
	return bg

# ─────────────────────────────────────────────────────────────
# 보유 재화 바
# ─────────────────────────────────────────────────────────────
func _make_currency_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_PANEL, Vector2(UITheme.W, 52))
	_currency_lbl = UITheme.lbl("", UITheme.FS_SM, UITheme.GEM)
	_currency_lbl.position = Vector2(12, 14)
	bg.add_child(_currency_lbl)
	return bg

# ─────────────────────────────────────────────────────────────
# 피티 바
# ─────────────────────────────────────────────────────────────
func _make_pity_bar() -> Control:
	var bg := UITheme.crect(Color(0.08, 0.04, 0.16), Vector2(UITheme.W, 72))

	_pity_bar_lbl = UITheme.lbl("", UITheme.FS_XS, UITheme.ORANGE)
	_pity_bar_lbl.position = Vector2(12, 6)
	bg.add_child(_pity_bar_lbl)

	# 바 배경
	var bar_bg := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 24, 16))
	bar_bg.position = Vector2(12, 24)
	bg.add_child(bar_bg)

	_pity_bar_fill = UITheme.crect(UITheme.ORANGE, Vector2(0, 16))
	_pity_bar_fill.position = Vector2(12, 24)
	bg.add_child(_pity_bar_fill)

	_fourpity_lbl = UITheme.lbl("", UITheme.FS_XS, UITheme.CYAN)
	_fourpity_lbl.position = Vector2(12, 44)
	bg.add_child(_fourpity_lbl)

	return bg

# ─────────────────────────────────────────────────────────────
# 소환 버튼
# ─────────────────────────────────────────────────────────────
func _make_pull_buttons() -> Control:
	var bg  := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 110))
	var hb  := UITheme.hbox(10)
	hb.position = Vector2(10, 12)
	bg.add_child(hb)

	_free_btn = _mk_btn("무료 1회\n(일 1회)", UITheme.GREEN, Vector2(145, 82))
	_free_btn.pressed.connect(_on_free_pull)
	hb.add_child(_free_btn)

	var b1 := _mk_btn("1회\n💎 100 / 🎟 1", UITheme.CYAN, Vector2(185, 82))
	b1.pressed.connect(func(): _on_pull(1))
	hb.add_child(b1)

	var b10 := _mk_btn("10회\n💎 900 / 🎟 10\n▶ 4★ 보장", UITheme.GOLD, Vector2(230, 82))
	b10.add_theme_font_size_override("font_size", UITheme.FS_SM)
	b10.pressed.connect(func(): _on_pull(10))
	hb.add_child(b10)

	return bg

func _mk_btn(text: String, col: Color, sz: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", UITheme.FS_SM)
	b.add_theme_color_override("font_color", col)
	b.custom_minimum_size = sz
	return b

# ─────────────────────────────────────────────────────────────
# 확률 행
# ─────────────────────────────────────────────────────────────
func _make_rate_row() -> Control:
	var bg := UITheme.crect(Color(0.06, 0.03, 0.12), Vector2(UITheme.W, 64))
	var hb := UITheme.hbox(32)
	hb.position = Vector2(UITheme.W / 2 - 180, 12)
	bg.add_child(hb)

	var defs = [["5★","2.0%",UITheme.GOLD],["4★","8.0%",UITheme.PURPLE],["3★","90%",UITheme.CYAN]]
	_rate_labels.clear()
	for d in defs:
		var vb := UITheme.vbox(4)
		var star_lbl := UITheme.lbl(d[0], UITheme.FS_MD, d[2])
		var rate_lbl := UITheme.lbl(d[1], UITheme.FS_SM, UITheme.WHITE)
		rate_lbl.name = "Rate_" + d[0]
		vb.add_child(star_lbl)
		vb.add_child(rate_lbl)
		hb.add_child(vb)
		_rate_labels.append(rate_lbl)

	return bg

# ─────────────────────────────────────────────────────────────
# 소환 기록 행
# ─────────────────────────────────────────────────────────────
func _make_history_row() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 140))

	var title := UITheme.lbl("최근 소환 기록 (최대 60회)", UITheme.FS_XS, UITheme.GREY)
	title.position = Vector2(12, 6)
	bg.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 26)
	scroll.custom_minimum_size = Vector2(UITheme.W, 110)
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bg.add_child(scroll)

	_hist_hbox = UITheme.hbox(3)
	scroll.add_child(_hist_hbox)

	return bg

# ─────────────────────────────────────────────────────────────
# 결과 오버레이
# ─────────────────────────────────────────────────────────────
func _make_result_overlay() -> Control:
	var ov := ColorRect.new()
	ov.color  = Color(0, 0, 0, 0.90)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.visible = false
	ov.custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)

	var vb := UITheme.vbox(10)
	vb.position = Vector2(16, 30)
	ov.add_child(vb)

	vb.add_child(UITheme.lbl("✨ 소환 결과", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.hsep())

	_result_summary = UITheme.lbl("", UITheme.FS_SM, UITheme.GREY)
	vb.add_child(_result_summary)

	_result_grid = GridContainer.new()
	_result_grid.columns = 5
	_result_grid.add_theme_constant_override("h_separation", 6)
	_result_grid.add_theme_constant_override("v_separation", 6)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(UITheme.W - 32, 750)
	scroll.add_child(_result_grid)
	vb.add_child(scroll)

	var close := UITheme.btn("닫기  (탭하여 계속)", UITheme.FS_MD, UITheme.WHITE)
	close.custom_minimum_size = Vector2(UITheme.W - 32, 60)
	close.pressed.connect(func(): ov.visible = false)
	vb.add_child(close)

	return ov

# ─────────────────────────────────────────────────────────────
# 배너 전환
# ─────────────────────────────────────────────────────────────
func _switch_banner(idx: int):
	_cur = idx
	var key = BANNER_KEYS[idx]
	var cfg = GameData.BANNER_CONFIG.get(key, {})

	# 탭 강조
	for i in 4:
		var btn = find_child("BannerTab_%d" % i, true, false)
		if btn:
			btn.add_theme_color_override("font_color", UITheme.GOLD if i == idx else UITheme.GREY)

	# 배너 제목
	if _banner_title:
		_banner_title.text = cfg.get("name", "소환")

	# 픽업 표시
	_update_featured(cfg)

	# 재화 표시
	_update_currency_lbl(key)

	# 피티 바
	_update_pity_display(key, cfg)

	# 확률 표시
	_update_rates(key, cfg)

	# 히스토리
	_update_history(key)

	# 무료 버튼
	if _free_btn:
		var can_free = (key == "hero" and GameData.can_free_pull())
		_free_btn.visible = (key == "hero")
		_free_btn.disabled = not can_free
		_free_btn.add_theme_color_override("font_color",
			UITheme.GREEN if can_free else UITheme.GREY_DIM)

func _update_featured(cfg: Dictionary):
	if not _featured_row: return
	for c in _featured_row.get_children(): c.queue_free()

	var featured5: Array = cfg.get("featured5", [])
	var featured4: Array = cfg.get("featured4", [])
	if featured5.is_empty() and featured4.is_empty():
		_featured_row.add_child(UITheme.lbl("전체 풀 동일 확률", UITheme.FS_SM, UITheme.GREY))
		return

	for aid in featured5 + featured4:
		var a = GameData.get_by_id(aid)
		if not a: continue
		var card := UITheme.hbox(6)
		card.add_child(UITheme.crect(a.color, Vector2(36, 36)))
		var info := UITheme.vbox(1)
		info.add_child(UITheme.lbl(a.name_kr, UITheme.FS_XS, UITheme.rarity_color(a.rarity)))
		info.add_child(UITheme.lbl("PICKUP", UITheme.FS_XS, UITheme.ORANGE))
		card.add_child(info)
		_featured_row.add_child(card)

func _update_currency_lbl(key: String):
	if not _currency_lbl: return
	match key:
		"event":
			_currency_lbl.text = "💎 %d  |  이벤트 소환권 × %d" % [GameData.gems, GameData.summon_tickets]
		"hero":
			_currency_lbl.text = "💎 %d  |  소환권 × %d" % [GameData.gems, GameData.summon_tickets]
		"legend":
			_currency_lbl.text = "전설 소환권 × %d" % GameData.legend_tickets
		"friend":
			_currency_lbl.text = "우정 포인트 %d  (50pt = 1회)" % GameData.friend_points

func _update_pity_display(key: String, cfg: Dictionary):
	if not _pity_bar_lbl: return
	var cur_pity = GameData.banner_pity.get(key, 0)
	var hard = HARD_PITY.get(key, 50)
	var soft = SOFT_START.get(key, 999)
	var pct  = float(cur_pity) / float(hard)

	_pity_bar_lbl.text = "5★ 천장  %d / %d  (소프트 피티 시작: %s회)" % [
		cur_pity, hard, ("없음" if soft >= 999 else str(soft))
	]
	if _pity_bar_fill:
		var bar_w = UITheme.W - 24
		_pity_bar_fill.size = Vector2(bar_w * pct, 16)
		_pity_bar_fill.color = UITheme.RED if cur_pity >= soft else UITheme.ORANGE

	var p4 = GameData.banner_4pity.get(key, 0)
	if _fourpity_lbl:
		if key in ["event", "hero", "legend"]:
			_fourpity_lbl.text = "4★ 보장까지  %d / 10  회" % p4
		else:
			_fourpity_lbl.text = ""

func _update_rates(key: String, cfg: Dictionary):
	var r5 = cfg.get("rate5", 0.0)
	var r4 = cfg.get("rate4", 0.0)
	var r3 = 1.0 - r5 - r4
	var texts = ["%.1f%%" % (r5*100), "%.1f%%" % (r4*100), "%.1f%%" % (r3*100)]
	for i in _rate_labels.size():
		if i < texts.size() and _rate_labels[i]:
			_rate_labels[i].text = texts[i]

func _update_history(key: String):
	if not _hist_hbox: return
	for c in _hist_hbox.get_children(): c.queue_free()
	var hist: Array = GameData.pull_history.get(key, [])
	for rarity in hist:
		var dot := UITheme.crect(UITheme.rarity_color(rarity), Vector2(20, 80))
		_hist_hbox.add_child(dot)

# ─────────────────────────────────────────────────────────────
# 소환 실행
# ─────────────────────────────────────────────────────────────
func _on_free_pull():
	if not GameData.can_free_pull():
		_toast("오늘은 이미 무료 소환을 사용했습니다.")
		return
	var results = GameData.use_free_pull()
	_show_results(results, "무료 소환")
	_refresh_all()

func _on_pull(count: int):
	var key = BANNER_KEYS[_cur]

	if key == "legend":
		if GameData.legend_tickets < count:
			_toast("전설 소환권이 부족합니다! (보유: %d)" % GameData.legend_tickets)
			return
		GameData.legend_tickets -= count
	elif key == "friend":
		var cost = 50 * count
		if GameData.friend_points < cost:
			_toast("우정 포인트가 부족합니다! (필요: %d / 보유: %d)" % [cost, GameData.friend_points])
			return
		GameData.friend_points -= cost
	else:
		# 소환권 우선 사용, 부족하면 젬
		var ticket_used = mini(GameData.summon_tickets, count)
		var gem_needed  = (count - ticket_used) * 100
		if count == 10 and ticket_used == 0:
			gem_needed = 900   # 10연 할인
		if GameData.gems < gem_needed:
			_toast("재화가 부족합니다!\n필요: 💎 %d 또는 🎟 %d개" % [count * 100, count])
			return
		GameData.summon_tickets -= ticket_used
		GameData.spend_gems(gem_needed)

	var results = GameData.banner_pull(key, count)
	_show_results(results, "%s × %d회" % [GameData.BANNER_CONFIG[key]["name"], count])
	_refresh_all()

# ─────────────────────────────────────────────────────────────
# 결과 표시 (5열 카드 그리드)
# ─────────────────────────────────────────────────────────────
func _show_results(results: Array, title_suffix: String):
	for c in _result_grid.get_children(): c.queue_free()

	var count5 = 0; var count4 = 0; var count3 = 0; var new_units = 0

	for agent in results:
		var card := _make_result_card(agent)
		_result_grid.add_child(card)
		match agent.rarity:
			5: count5 += 1
			4: count4 += 1
			_: count3 += 1
		if GameData.unit_copies.get(agent.id, 0) == 1:
			new_units += 1

	# 결과 요약
	var summary_parts = []
	if count5 > 0: summary_parts.append("5★ × %d" % count5)
	if count4 > 0: summary_parts.append("4★ × %d" % count4)
	if count3 > 0: summary_parts.append("3★ × %d" % count3)
	if new_units > 0: summary_parts.append("NEW %d명" % new_units)

	if _result_summary:
		_result_summary.text = title_suffix + "  |  " + "  ".join(summary_parts)

	_result_root.visible = true

func _make_result_card(agent) -> Control:
	var W = (UITheme.W - 32 - 24) / 5   # 5열
	var H = W * 1.5

	var card := Control.new()
	card.custom_minimum_size = Vector2(W, H)

	# 배경 (희귀도 색)
	var bg := UITheme.crect(UITheme.rarity_bg(agent.rarity))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(bg)

	# 상단 희귀도 줄
	var border := UITheme.crect(UITheme.rarity_color(agent.rarity), Vector2(W, 3))
	card.add_child(border)

	# 아이콘
	var icon := UITheme.crect(agent.color, Vector2(W - 8, H - 50))
	icon.position = Vector2(4, 4)
	card.add_child(icon)

	# 신규 뱃지
	if GameData.unit_copies.get(agent.id, 0) <= 1:
		var new_lbl := UITheme.lbl("NEW", UITheme.FS_XS, UITheme.GREEN)
		new_lbl.position = Vector2(2, 4)
		card.add_child(new_lbl)

	# 이름
	var nl := UITheme.lbl(agent.name_kr, UITheme.FS_XS, UITheme.WHITE)
	nl.size = Vector2(W, 20)
	nl.position = Vector2(0, H - 44)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(nl)

	# 별
	var star_count = "★" * agent.rarity + "☆" * (5 - agent.rarity)
	var sl := UITheme.lbl(star_count, UITheme.FS_XS, UITheme.rarity_color(agent.rarity))
	sl.size = Vector2(W, 14)
	sl.position = Vector2(0, H - 24)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(sl)

	# 복사본 수
	var copies = GameData.unit_copies.get(agent.id, 0)
	if copies > 1:
		var cl := UITheme.lbl("+%d" % (copies - 1), UITheme.FS_XS, UITheme.GOLD)
		cl.position = Vector2(W - 22, 4)
		card.add_child(cl)

	# 5★ 반짝 효과
	if agent.rarity == 5:
		var tw := card.create_tween()
		tw.tween_property(bg, "color", UITheme.rarity_bg(5).lightened(0.2), 0.3)
		tw.tween_property(bg, "color", UITheme.rarity_bg(5), 0.3)
		tw.set_loops(3)

	return card

# ─────────────────────────────────────────────────────────────
# 공통 갱신
# ─────────────────────────────────────────────────────────────
func _refresh_all():
	_switch_banner(_cur)

func refresh():
	_switch_banner(_cur)

func _toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_SM, UITheme.RED)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(UITheme.W, 0)
	lbl.position = Vector2(0, UITheme.CONT_H / 2 - 40)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 60, 1.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.8)
	tw.tween_callback(lbl.queue_free)
