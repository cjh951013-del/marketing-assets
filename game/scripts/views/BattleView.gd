class_name BattleView
extends Control
# ============================================================
# BattleView — 전투 화면
# ┌────────────────────────────────┐
# │ [스테이지명]    [1x][2x][3x][AUTO] │  ← 스테이지 바
# ├────────────────────────────────┤
# │  [적1][적2][적3][적4]  HP바      │  ← 적 구역
# │        ── W5 치즈파 두목 ──      │  ← 웨이브 구분선
# │  [유닛][유닛][유닛]              │  ← 스쿼드 구역
# │  [유닛][유닛][유닛]   HP바        │
# ├────────────────────────────────┤
# │  ⚡ 조류2 공속+10%  바이킹2 ...   │  ← 시너지 바
# ├────────────────────────────────┤
# │  전투 로그 (스크롤)               │  ← 로그
# └────────────────────────────────┘
# ============================================================

const W = UITheme.W
const STAGE_H  := 54
const ENEMY_H  := 270
const DIV_H    := 36
const SQUAD_H  := 300
const SYN_H    := 110
const LOG_H    := UITheme.CONT_H - STAGE_H - ENEMY_H - DIV_H - SQUAD_H - SYN_H  # ~152

var enemy_cards:  Dictionary = {}   # id → Control
var speed_btns:   Array = []
var stage_lbl:    Label
var wave_div_lbl: Label
var syn_scroll:   HBoxContainer
var log_vbox:     VBoxContainer
var squad_grid:   GridContainer
var squad_hp_bar: Control
var squad_hp_lbl: Label

func _init():
	name = "BattleView"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_connect_signals()

func _build():
	var y = 0

	# ── 1. 스테이지 바 ────────────────────────────────────
	_add_stage_bar(y)
	y += STAGE_H

	# ── 2. 적 구역 배경 ───────────────────────────────────
	var enemy_bg = UITheme.crect(Color(0.12, 0.05, 0.08), Vector2(W, ENEMY_H))
	enemy_bg.position.y = y
	add_child(enemy_bg)
	_add_enemy_area(y)
	y += ENEMY_H

	# ── 3. 웨이브 구분선 ──────────────────────────────────
	_add_divider(y)
	y += DIV_H

	# ── 4. 스쿼드 구역 ────────────────────────────────────
	var squad_bg = UITheme.crect(Color(0.08, 0.04, 0.15), Vector2(W, SQUAD_H))
	squad_bg.position.y = y
	add_child(squad_bg)
	_add_squad_area(y)
	y += SQUAD_H

	# ── 5. 시너지 바 ──────────────────────────────────────
	var syn_bg = UITheme.crect(Color(0.10, 0.06, 0.20), Vector2(W, SYN_H))
	syn_bg.position.y = y
	add_child(syn_bg)
	_add_synergy_bar(y)
	y += SYN_H

	# ── 6. 전투 로그 ──────────────────────────────────────
	_add_battle_log(y)

# ─── 스테이지 바 ─────────────────────────────────────────────
func _add_stage_bar(y: int):
	var bar = UITheme.crect(UITheme.BG_PANEL, Vector2(W, STAGE_H))
	bar.position.y = y
	add_child(bar)

	var hbox = UITheme.hbox(10)
	hbox.position = Vector2(12, y + 8)
	hbox.size = Vector2(W - 24, STAGE_H - 16)
	add_child(hbox)

	stage_lbl = UITheme.lbl("1-1  치즈파 아지트", UITheme.FS_MD, UITheme.GOLD)
	stage_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(stage_lbl)

	# 속도 버튼
	for s in ["1x", "2x", "3x"]:
		var btn = UITheme.btn(s, UITheme.FS_SM)
		btn.custom_minimum_size = Vector2(48, 36)
		var speed_val = float(s.left(1))
		btn.pressed.connect(func(): _on_speed(speed_val, btn))
		speed_btns.append(btn)
		hbox.add_child(btn)

	# AUTO 버튼
	var auto_btn = UITheme.btn("AUTO", UITheme.FS_SM, UITheme.GREEN)
	auto_btn.custom_minimum_size = Vector2(60, 36)
	auto_btn.pressed.connect(func(): _on_auto(auto_btn))
	hbox.add_child(auto_btn)

# ─── 적 구역 ─────────────────────────────────────────────────
func _add_enemy_area(y: int):
	# 적 카드 컨테이너: 가로 스크롤
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(8, y + 10)
	scroll.size = Vector2(W - 16, ENEMY_H - 20)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var hbox = UITheme.hbox(10)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(hbox)
	hbox.name = "EnemyHBox"

# ─── 웨이브 구분선 ───────────────────────────────────────────
func _add_divider(y: int):
	var div = UITheme.crect(Color(0.20, 0.10, 0.30), Vector2(W, DIV_H))
	div.position.y = y
	add_child(div)

	wave_div_lbl = UITheme.lbl("── 웨이브 1 ──", UITheme.FS_SM, UITheme.CYAN)
	wave_div_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	wave_div_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_div_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	wave_div_lbl.position.y = y
	wave_div_lbl.size = Vector2(W, DIV_H)
	add_child(wave_div_lbl)

# ─── 스쿼드 구역 ─────────────────────────────────────────────
func _add_squad_area(y: int):
	# 스쿼드 HP 바
	squad_hp_bar = UITheme.hp_bar(W - 24, 14)
	squad_hp_bar.position = Vector2(12, y + 6)
	add_child(squad_hp_bar)

	squad_hp_lbl = UITheme.lbl("스쿼드 HP", UITheme.FS_XS, UITheme.WHITE)
	squad_hp_lbl.position = Vector2(12, y + 22)
	add_child(squad_hp_lbl)

	# 유닛 카드 그리드 (3×2)
	squad_grid = GridContainer.new()
	squad_grid.columns = 3
	squad_grid.position = Vector2(8, y + 40)
	squad_grid.size = Vector2(W - 16, SQUAD_H - 50)
	squad_grid.add_theme_constant_override("h_separation", 6)
	squad_grid.add_theme_constant_override("v_separation", 6)
	add_child(squad_grid)
	_refresh_squad_grid()

# ─── 시너지 바 ───────────────────────────────────────────────
func _add_synergy_bar(y: int):
	var title = UITheme.lbl("⚡ 활성 시너지", UITheme.FS_SM, UITheme.GOLD)
	title.position = Vector2(12, y + 6)
	add_child(title)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(8, y + 30)
	scroll.size = Vector2(W - 16, SYN_H - 38)
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	syn_scroll = UITheme.hbox(12)
	scroll.add_child(syn_scroll)

# ─── 전투 로그 ───────────────────────────────────────────────
func _add_battle_log(y: int):
	var bg = UITheme.crect(Color(0.05, 0.03, 0.08), Vector2(W, LOG_H))
	bg.position.y = y
	add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.name = "LogScroll"
	scroll.position = Vector2(8, y + 4)
	scroll.size = Vector2(W - 16, LOG_H - 8)
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	log_vbox = UITheme.vbox(2)
	log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(log_vbox)

# ─── 적 카드 빌드 ────────────────────────────────────────────
func _build_enemy_card(enemy) -> Control:
	var CARD_W = 140
	var card = Control.new()
	card.custom_minimum_size = Vector2(CARD_W, ENEMY_H - 30)
	card.name = "Enemy_%d" % enemy.id

	var bg = UITheme.crect(enemy.color.darkened(0.55))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(bg)

	if enemy.is_boss:
		var boss_bg = UITheme.crect(UITheme.RED.darkened(0.3), Vector2(CARD_W, 22))
		card.add_child(boss_bg)
		var bl = UITheme.lbl("★ BOSS ★", UITheme.FS_XS, UITheme.GOLD)
		bl.size = Vector2(CARD_W, 22)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(bl)

	# 유닛 아이콘 영역 (아트 교체 예정)
	var icon = UITheme.crect(enemy.color, Vector2(CARD_W - 16, 140))
	icon.position = Vector2(8, 26)
	card.add_child(icon)

	# 이름
	var nl = UITheme.lbl(enemy.name_kr, UITheme.FS_XS, UITheme.WHITE)
	nl.position = Vector2(4, 172)
	nl.size = Vector2(CARD_W - 8, 32)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(nl)

	# HP 바
	var hpbar = UITheme.hp_bar(CARD_W - 16, 12)
	hpbar.name = "HPBar"
	hpbar.position = Vector2(8, 210)
	card.add_child(hpbar)

	var hpl = UITheme.lbl("", UITheme.FS_XS, UITheme.WHITE)
	hpl.name = "HPLabel"
	hpl.position = Vector2(4, 224)
	hpl.size = Vector2(CARD_W - 8, 16)
	hpl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(hpl)

	return card

# ─── 스쿼드 슬롯 빌드 ────────────────────────────────────────
func _build_squad_slot(index: int) -> Control:
	var SLOT_W = (UITheme.W - 28) / 3
	var SLOT_H = (SQUAD_H - 56) / 2
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)

	if index < GameData.squad.size():
		var agent = GameData.squad[index]
		var bg = UITheme.crect(UITheme.rarity_bg(agent.rarity))
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(bg)

		# 희귀도 테두리 색
		var border = UITheme.crect(UITheme.rarity_color(agent.rarity), Vector2(SLOT_W, 3))
		slot.add_child(border)

		var icon = UITheme.crect(agent.color, Vector2(SLOT_W - 16, SLOT_H - 50))
		icon.position = Vector2(8, 6)
		slot.add_child(icon)

		var nl = UITheme.lbl(agent.name_kr, UITheme.FS_XS, UITheme.WHITE)
		nl.position = Vector2(2, SLOT_H - 42)
		nl.size = Vector2(SLOT_W - 4, 18)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(nl)

		var atk_l = UITheme.lbl("ATK %d" % int(agent.get_atk()), UITheme.FS_XS, UITheme.GOLD)
		atk_l.position = Vector2(2, SLOT_H - 24)
		atk_l.size = Vector2(SLOT_W - 4, 16)
		atk_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(atk_l)

		var lv_l = UITheme.lbl("Lv.%d" % agent.level, UITheme.FS_XS, UITheme.CYAN)
		lv_l.position = Vector2(2, SLOT_H - 8)
		lv_l.size = Vector2(SLOT_W - 4, 16)
		lv_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(lv_l)
	else:
		var bg = UITheme.crect(Color(0.10, 0.06, 0.20))
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(bg)
		var pl = UITheme.lbl("+", UITheme.FS_XL, UITheme.GREY_DIM)
		pl.set_anchors_preset(Control.PRESET_FULL_RECT)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(pl)

	return slot

# ─── 갱신 함수 ───────────────────────────────────────────────
func refresh_enemies():
	var hbox = get_node_or_null("EnemyHBox")
	if not hbox: return
	enemy_cards.clear()
	for c in hbox.get_children(): c.queue_free()
	for e in BattleManager.get_alive():
		var card = _build_enemy_card(e)
		e.pos = Vector2(hbox.global_position.x + enemy_cards.size() * 150, hbox.global_position.y + 80)
		hbox.add_child(card)
		enemy_cards[e.id] = card

func update_enemy_hp(enemy_id: int):
	var alive = BattleManager.get_alive()
	var e = alive.filter(func(x): return x.id == enemy_id)
	if e.is_empty(): return
	var card = enemy_cards.get(enemy_id)
	if not card: return
	var hpbar = card.get_node_or_null("HPBar")
	var hpl   = card.get_node_or_null("HPLabel")
	if hpbar: UITheme.set_hp_bar(hpbar, e[0].ratio())
	if hpl:   hpl.text = "%d/%d" % [int(e[0].hp), int(e[0].max_hp)]

func _refresh_squad_grid():
	for c in squad_grid.get_children(): c.queue_free()
	for i in range(6):
		squad_grid.add_child(_build_squad_slot(i))

func refresh_synergy():
	for c in syn_scroll.get_children(): c.queue_free()
	var labels = BattleManager.synergy_labels()
	if labels.is_empty():
		syn_scroll.add_child(UITheme.lbl("시너지 없음 — 편성 탭에서 유닛을 조합하세요", UITheme.FS_SM, UITheme.GREY))
		return
	for txt in labels:
		var badge = Control.new()
		badge.custom_minimum_size = Vector2(0, 40)
		var bg = UITheme.crect(UITheme.BG_CARD)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge.add_child(bg)
		var l = UITheme.lbl("• " + txt, UITheme.FS_SM, UITheme.GREEN)
		l.position = Vector2(8, 8)
		badge.add_child(l)
		syn_scroll.add_child(badge)

func add_log(msg: String):
	var l = UITheme.lbl(msg, UITheme.FS_SM, UITheme.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_vbox.add_child(l)
	if log_vbox.get_child_count() > 30:
		log_vbox.get_child(0).queue_free()

func show_damage_number(pos: Vector2, amount: float, is_crit: bool):
	var lbl = UITheme.lbl(
		("💥 CRIT %d!" % int(amount)) if is_crit else ("-%d" % int(amount)),
		UITheme.FS_LG if is_crit else UITheme.FS_MD,
		UITheme.GOLD if is_crit else UITheme.WHITE
	)
	lbl.position = pos - Vector2(40, 0)
	add_child(lbl)
	var tw = create_tween()
	tw.parallel().tween_property(lbl, "position:y", lbl.position.y - 70, 1.2)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.tween_callback(lbl.queue_free)

# ─── 시그널 연결 ─────────────────────────────────────────────
func _connect_signals():
	BattleManager.damage_dealt.connect(_on_damage)
	BattleManager.enemy_died.connect(_on_enemy_died)
	BattleManager.wave_started.connect(_on_wave_start)
	BattleManager.squad_hp_changed.connect(_on_squad_hp)
	BattleManager.gold_ticked.connect(_on_gold)
	BattleManager.battle_log.connect(add_log)

func _on_damage(eid: int, amt: float, crit: bool, pos: Vector2):
	update_enemy_hp(eid)
	show_damage_number(pos, amt, crit)

func _on_enemy_died(eid: int):
	if enemy_cards.has(eid):
		var card = enemy_cards[eid]
		var tw = create_tween()
		tw.tween_property(card, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func(): card.queue_free(); enemy_cards.erase(eid))

func _on_wave_start(w: int):
	wave_div_lbl.text = "── 웨이브 %d ──" % w
	stage_lbl.text    = "%s  치즈파 아지트" % GameData.current_stage
	refresh_enemies()
	refresh_synergy()
	_refresh_squad_grid()

func _on_squad_hp(cur: float, max: float):
	if max > 0: UITheme.set_hp_bar(squad_hp_bar, cur / max)
	squad_hp_lbl.text = "스쿼드 HP  %d / %d" % [int(cur), int(max)]

func _on_gold(_g: float):
	pass  # Main이 처리

# ─── 버튼 콜백 ───────────────────────────────────────────────
func _on_speed(val: float, pressed_btn: Button):
	BattleManager.set_speed(val)
	for b in speed_btns:
		b.add_theme_color_override("font_color", UITheme.WHITE)
	pressed_btn.add_theme_color_override("font_color", UITheme.GOLD)

func _on_auto(btn: Button):
	BattleManager.toggle_auto()
	btn.add_theme_color_override("font_color",
		UITheme.GREEN if BattleManager.auto_repeat else UITheme.GREY)
