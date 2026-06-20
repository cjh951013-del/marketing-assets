extends Node2D
# ============================================================
# Main.gd — 메인 씬, 전체 UI를 코드로 생성
# ============================================================

const W = 720
const H = 1280
const C_BG      = Color(0.07, 0.04, 0.12)
const C_PANEL   = Color(0.12, 0.08, 0.20)
const C_GOLD    = Color(1.00, 0.80, 0.20)
const C_WHITE   = Color(1, 1, 1)
const C_RED     = Color(0.90, 0.20, 0.20)
const C_GREEN   = Color(0.20, 0.85, 0.40)
const C_DARK    = Color(0.06, 0.03, 0.10)

# ── UI 노드 참조 ───────────────────────────────────────────
var canvas:          CanvasLayer
var tab_squad:       Button
var tab_battle:      Button
var squad_scroll:    ScrollContainer
var battle_panel:    Control
var synergy_panel:   Control
var log_container:   VBoxContainer
var gold_label:      Label
var wave_label:      Label
var squad_hp_bar:    TextureProgressBar
var squad_hp_label:  Label
var enemy_container: HBoxContainer
var synergy_labels:  VBoxContainer
var squad_grid:      GridContainer  # 배틀씬 스쿼드 표시
var roster_grid:     GridContainer  # 도감 탭

var current_tab: String = "battle"

# ── 초기화 ─────────────────────────────────────────────────
func _ready():
	canvas = CanvasLayer.new()
	add_child(canvas)
	_build_ui()
	_connect_signals()
	BattleManager.start_battle()
	_refresh_squad_display()
	_refresh_synergy()

# ═══════════════════════════════════════════════════════════
# UI 빌드
# ═══════════════════════════════════════════════════════════
func _build_ui():
	# 배경
	var bg = ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	# 상단 HUD
	_build_hud()

	# 탭 바
	_build_tabs()

	# 배틀 패널
	battle_panel = _build_battle_panel()
	canvas.add_child(battle_panel)

	# 도감 패널
	var roster_panel = _build_roster_panel()
	canvas.add_child(roster_panel)
	roster_panel.visible = false
	roster_panel.name = "RosterPanel"

	# 시너지 패널
	synergy_panel = _build_synergy_panel()
	canvas.add_child(synergy_panel)

	# 전투 로그
	_build_battle_log()

func _build_hud():
	var hud = PanelContainer.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud.size.y = 80
	hud.name = "HUD"
	canvas.add_child(hud)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(hbox)

	# 골드
	var gold_icon = Label.new()
	gold_icon.text = "🪙"
	gold_icon.add_theme_font_size_override("font_size", 28)
	hbox.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.text = "500"
	gold_label.add_theme_color_override("font_color", C_GOLD)
	gold_label.add_theme_font_size_override("font_size", 26)
	gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(gold_label)

	# 웨이브
	wave_label = Label.new()
	wave_label.text = "웨이브 1"
	wave_label.add_theme_color_override("font_color", C_WHITE)
	wave_label.add_theme_font_size_override("font_size", 22)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(wave_label)

func _build_tabs():
	var tabs = HBoxContainer.new()
	tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tabs.position.y = 80
	tabs.size.y = 60
	tabs.name = "TabBar"
	canvas.add_child(tabs)

	tab_battle = _make_tab_button("⚔ 전투", true)
	tab_squad  = _make_tab_button("📋 도감", false)
	tabs.add_child(tab_battle)
	tabs.add_child(tab_squad)
	tab_battle.pressed.connect(func(): _switch_tab("battle"))
	tab_squad.pressed.connect(func():  _switch_tab("roster"))

func _make_tab_button(text: String, active: bool) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 20)
	if active:
		btn.add_theme_color_override("font_color", C_GOLD)
	return btn

func _build_battle_panel() -> Control:
	var panel = Control.new()
	panel.name = "BattlePanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_top = 140

	# ── 스쿼드 HP 바 ──
	var hp_bg = PanelContainer.new()
	hp_bg.position = Vector2(20, 10)
	hp_bg.size = Vector2(W - 40, 50)
	panel.add_child(hp_bg)

	squad_hp_bar = TextureProgressBar.new()
	squad_hp_bar.position = Vector2(20, 12)
	squad_hp_bar.size = Vector2(W - 80, 22)
	squad_hp_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	# 색상 오버라이드로 단색 바 생성
	squad_hp_bar.tint_progress = C_GREEN
	squad_hp_bar.tint_under = C_RED
	squad_hp_bar.value = 100
	panel.add_child(squad_hp_bar)

	squad_hp_label = Label.new()
	squad_hp_label.position = Vector2(20, 36)
	squad_hp_label.text = "스쿼드 HP: ●●●●●"
	squad_hp_label.add_theme_color_override("font_color", C_WHITE)
	squad_hp_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(squad_hp_label)

	# ── 스쿼드 유닛 표시 (6칸) ──
	var squad_label = Label.new()
	squad_label.position = Vector2(20, 70)
	squad_label.text = "[ 출전 스쿼드 ]"
	squad_label.add_theme_color_override("font_color", C_GOLD)
	squad_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(squad_label)

	squad_grid = GridContainer.new()
	squad_grid.columns = 6
	squad_grid.position = Vector2(10, 96)
	squad_grid.size = Vector2(W - 20, 100)
	panel.add_child(squad_grid)

	# ── 적 표시 ──
	var enemy_label = Label.new()
	enemy_label.position = Vector2(20, 210)
	enemy_label.text = "[ 치즈파 ]"
	enemy_label.add_theme_color_override("font_color", C_RED)
	enemy_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(enemy_label)

	var enemy_scroll = ScrollContainer.new()
	enemy_scroll.position = Vector2(10, 236)
	enemy_scroll.size = Vector2(W - 20, 140)
	panel.add_child(enemy_scroll)

	enemy_container = HBoxContainer.new()
	enemy_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_scroll.add_child(enemy_container)

	return panel

func _build_roster_panel() -> Control:
	var panel = Control.new()
	panel.name = "RosterPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_top = 140

	var title = Label.new()
	title.position = Vector2(20, 10)
	title.text = "도감 — 유닛 터치로 스쿼드 추가/제거"
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 50)
	scroll.size = Vector2(W, H - 200)
	panel.add_child(scroll)

	roster_grid = GridContainer.new()
	roster_grid.columns = 4
	roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(roster_grid)

	_populate_roster()
	return panel

func _build_synergy_panel() -> Control:
	var panel = Control.new()
	panel.name = "SynergyPanel"
	panel.position = Vector2(0, H - 320)
	panel.size = Vector2(W, 160)

	var bg = ColorRect.new()
	bg.color = Color(C_DARK.r, C_DARK.g, C_DARK.b, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)

	var title = Label.new()
	title.position = Vector2(12, 6)
	title.text = "⚡ 활성 시너지"
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_font_size_override("font_size", 17)
	panel.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(8, 32)
	scroll.size = Vector2(W - 16, 120)
	panel.add_child(scroll)

	synergy_labels = VBoxContainer.new()
	scroll.add_child(synergy_labels)

	return panel

func _build_battle_log():
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.08, 0.9)
	bg.position = Vector2(0, H - 155)
	bg.size = Vector2(W, 155)
	canvas.add_child(bg)

	var title = Label.new()
	title.position = Vector2(12, H - 152)
	title.text = "전투 로그"
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_font_size_override("font_size", 15)
	canvas.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(8, H - 135)
	scroll.size = Vector2(W - 16, 128)
	canvas.add_child(scroll)

	log_container = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(log_container)

# ─── 도감 그리드 채우기 ───────────────────────────────────
func _populate_roster():
	for child in roster_grid.get_children():
		child.queue_free()
	for agent in GameData.get_owned_agents():
		var card = _make_agent_card_small(agent, true)
		roster_grid.add_child(card)

func _make_agent_card_small(agent, clickable: bool) -> Control:
	var size = Vector2(160, 180)
	var container = Button.new()
	container.custom_minimum_size = size
	container.flat = true

	var bg = ColorRect.new()
	bg.color = agent.color.darkened(0.4)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)

	# 별 표시 (희귀도)
	var stars = Label.new()
	stars.text = "★".repeat(agent.rarity)
	stars.add_theme_color_override("font_color", C_GOLD)
	stars.add_theme_font_size_override("font_size", 12)
	stars.position = Vector2(4, 4)
	container.add_child(stars)

	# 유닛 색상 아이콘
	var icon = ColorRect.new()
	icon.color = agent.color
	icon.position = Vector2(30, 20)
	icon.size = Vector2(100, 80)
	container.add_child(icon)

	# 이름
	var name_lbl = Label.new()
	name_lbl.text = agent.name_kr
	name_lbl.add_theme_color_override("font_color", C_WHITE)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.position = Vector2(4, 106)
	name_lbl.size = Vector2(152, 20)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_lbl)

	# 스킬명
	var skill_lbl = Label.new()
	skill_lbl.text = agent.skill_name
	skill_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	skill_lbl.add_theme_font_size_override("font_size", 11)
	skill_lbl.position = Vector2(4, 126)
	skill_lbl.size = Vector2(152, 30)
	skill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(skill_lbl)

	# 스쿼드 여부 표시
	var squad_badge = Label.new()
	squad_badge.name = "SquadBadge_%d" % agent.id
	squad_badge.text = "출전중" if GameData.is_in_squad(agent) else ""
	squad_badge.add_theme_color_override("font_color", C_GREEN)
	squad_badge.add_theme_font_size_override("font_size", 13)
	squad_badge.position = Vector2(4, 155)
	squad_badge.size = Vector2(152, 20)
	squad_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(squad_badge)

	if clickable:
		container.pressed.connect(func(): _toggle_squad(agent))

	return container

# ─── 스쿼드 토글 ───────────────────────────────────────────
func _toggle_squad(agent):
	if GameData.is_in_squad(agent):
		GameData.remove_from_squad(agent)
		_add_log("➖ %s 스쿼드 제외" % agent.name_kr)
	else:
		if GameData.add_to_squad(agent):
			_add_log("➕ %s 스쿼드 추가" % agent.name_kr)
		else:
			_add_log("⚠ 스쿼드가 가득 찼습니다 (최대 6명)")
	BattleManager.update_squad()
	_refresh_squad_display()
	_refresh_synergy()
	_populate_roster()

# ─── 스쿼드 디스플레이 갱신 ───────────────────────────────
func _refresh_squad_display():
	for child in squad_grid.get_children():
		child.queue_free()
	for i in range(6):
		var slot = _make_squad_slot(i)
		squad_grid.add_child(slot)

func _make_squad_slot(index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(108, 92)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(bg)

	if index < GameData.squad.size():
		var agent = GameData.squad[index]
		bg.color = agent.color.darkened(0.3)

		var icon = ColorRect.new()
		icon.color = agent.color
		icon.position = Vector2(18, 6)
		icon.size = Vector2(72, 50)
		slot.add_child(icon)

		var lbl = Label.new()
		lbl.text = agent.name_kr
		lbl.add_theme_color_override("font_color", C_WHITE)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.position = Vector2(2, 58)
		lbl.size = Vector2(104, 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(lbl)

		var atk_lbl = Label.new()
		atk_lbl.text = "ATK %d" % int(agent.base_atk)
		atk_lbl.add_theme_color_override("font_color", C_GOLD)
		atk_lbl.add_theme_font_size_override("font_size", 11)
		atk_lbl.position = Vector2(2, 74)
		atk_lbl.size = Vector2(104, 16)
		atk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(atk_lbl)
	else:
		bg.color = Color(0.15, 0.10, 0.22)
		var empty = Label.new()
		empty.text = "+"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty.add_theme_font_size_override("font_size", 28)
		empty.set_anchors_preset(Control.PRESET_FULL_RECT)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(empty)

	return slot

# ─── 적 디스플레이 갱신 ────────────────────────────────────
func _refresh_enemy_display():
	for child in enemy_container.get_children():
		child.queue_free()
	var alive = BattleManager.get_alive_enemies()
	for enemy in alive:
		var card = _make_enemy_card(enemy)
		enemy_container.add_child(card)

func _make_enemy_card(enemy) -> Control:
	var card = Control.new()
	card.custom_minimum_size = Vector2(110, 130)
	card.name = "EnemyCard_%d" % enemy.id

	var bg = ColorRect.new()
	bg.color = enemy.color.darkened(0.4)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(bg)

	var icon = ColorRect.new()
	icon.color = enemy.color
	icon.position = Vector2(15, 6)
	icon.size = Vector2(80, 64)
	card.add_child(icon)

	if enemy.is_boss:
		var boss_lbl = Label.new()
		boss_lbl.text = "BOSS"
		boss_lbl.add_theme_color_override("font_color", C_GOLD)
		boss_lbl.add_theme_font_size_override("font_size", 11)
		boss_lbl.position = Vector2(30, 10)
		card.add_child(boss_lbl)

	var name_lbl = Label.new()
	name_lbl.text = enemy.name_kr
	name_lbl.add_theme_color_override("font_color", C_WHITE)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.position = Vector2(2, 72)
	name_lbl.size = Vector2(106, 24)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(name_lbl)

	# HP 바
	var hp_ratio = enemy.hp_ratio()
	var hp_bg = ColorRect.new()
	hp_bg.color = C_RED
	hp_bg.position = Vector2(6, 100)
	hp_bg.size = Vector2(98, 10)
	card.add_child(hp_bg)

	var hp_fill = ColorRect.new()
	hp_fill.name = "HPFill"
	hp_fill.color = C_GREEN
	hp_fill.position = Vector2(6, 100)
	hp_fill.size = Vector2(98 * hp_ratio, 10)
	card.add_child(hp_fill)

	var hp_lbl = Label.new()
	hp_lbl.name = "HPLabel"
	hp_lbl.text = "%d / %d" % [int(enemy.hp), int(enemy.max_hp)]
	hp_lbl.add_theme_color_override("font_color", C_WHITE)
	hp_lbl.add_theme_font_size_override("font_size", 10)
	hp_lbl.position = Vector2(2, 112)
	hp_lbl.size = Vector2(106, 16)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(hp_lbl)

	return card

# ─── 시너지 패널 갱신 ──────────────────────────────────────
func _refresh_synergy():
	for child in synergy_labels.get_children():
		child.queue_free()
	var syn = SynergyManager.calculate(GameData.squad)
	if syn.active_labels.is_empty():
		var lbl = Label.new()
		lbl.text = "시너지 없음 (동일 직업/생물군 2명 이상 배치)"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lbl.add_theme_font_size_override("font_size", 14)
		synergy_labels.add_child(lbl)
		return
	for text in syn.active_labels:
		var lbl = Label.new()
		lbl.text = "• " + text
		lbl.add_theme_color_override("font_color", C_GREEN)
		lbl.add_theme_font_size_override("font_size", 14)
		synergy_labels.add_child(lbl)

	# 요약 수치
	var summary = Label.new()
	summary.text = "최종피해 ×%.2f  공속 ×%.2f  치명 +%.0f%%" % [
		syn.final_damage, syn.attack_speed, syn.crit_rate * 100
	]
	summary.add_theme_color_override("font_color", C_GOLD)
	summary.add_theme_font_size_override("font_size", 15)
	synergy_labels.add_child(summary)

# ─── 탭 전환 ───────────────────────────────────────────────
func _switch_tab(tab: String):
	current_tab = tab
	battle_panel.visible  = (tab == "battle")
	synergy_panel.visible = (tab == "battle")
	var roster = canvas.find_child("RosterPanel", true, false)
	if roster:
		roster.visible = (tab == "roster")
	tab_battle.add_theme_color_override("font_color", C_GOLD if tab == "battle" else C_WHITE)
	tab_squad.add_theme_color_override("font_color", C_GOLD if tab == "roster" else C_WHITE)

# ─── 시그널 연결 ───────────────────────────────────────────
func _connect_signals():
	BattleManager.damage_dealt.connect(_on_damage_dealt)
	BattleManager.enemy_died.connect(_on_enemy_died)
	BattleManager.wave_started.connect(_on_wave_started)
	BattleManager.wave_cleared.connect(_on_wave_cleared)
	BattleManager.squad_hp_changed.connect(_on_squad_hp_changed)
	BattleManager.gold_updated.connect(_on_gold_updated)
	BattleManager.battle_log.connect(_add_log)

func _on_damage_dealt(target_name: String, amount: float, is_crit: bool):
	_refresh_enemy_display()
	var msg = "⚔ %s에게 %s%d 피해" % [
		target_name,
		"💥CRIT " if is_crit else "",
		int(amount)
	]
	_add_log(msg)

func _on_enemy_died(_id: int):
	_refresh_enemy_display()

func _on_wave_started(wave_num: int):
	wave_label.text = "웨이브 %d" % wave_num
	_refresh_enemy_display()
	_add_log("━━━ 웨이브 %d 시작! ━━━" % wave_num)

func _on_wave_cleared(wave_num: int, gold: float):
	_add_log("🏆 웨이브 %d 클리어! +%.0f🪙" % [wave_num, gold])

func _on_squad_hp_changed(current: float, maximum: float):
	if maximum > 0:
		squad_hp_bar.value = (current / maximum) * 100
	squad_hp_label.text = "스쿼드 HP: %d / %d" % [int(current), int(maximum)]

func _on_gold_updated(amount: float):
	gold_label.text = "%.0f" % amount

# ─── 전투 로그 ────────────────────────────────────────────
func _add_log(msg: String):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", C_WHITE)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_container.add_child(lbl)
	# 최대 20줄 유지
	if log_container.get_child_count() > 20:
		log_container.get_child(0).queue_free()
	# 스크롤 맨 아래로
	await get_tree().process_frame
	var scroll = log_container.get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
