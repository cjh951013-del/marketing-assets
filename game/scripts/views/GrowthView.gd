extends Control
# ============================================================
# GrowthView.gd — 성장 탭 (레벨업, 승급, 코어)
# ============================================================

var _selected_agent = null
var _detail_panel: Control
var _agent_list_vb: VBoxContainer
var _lv_lbl: Label
var _atk_lbl: Label
var _hp_lbl: Label
var _cost_lbl: Label
var _star_info_lbl: Label
var _core_lbl: Label

const MAX_LEVEL := 60

# ─────────────────────────────────────────────────────────────
func _ready():
	_build()

func _build():
	custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)

	# 좌: 유닛 리스트 (w=220), 우: 상세 패널 (w=500)
	var hb := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hb)

	hb.add_child(_make_unit_list())
	hb.add_child(_make_detail_panel())

func _make_unit_list() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(220, UITheme.CONT_H))

	var header := UITheme.lbl("보유 유닛", UITheme.FS_MD, UITheme.GOLD)
	header.position = Vector2(10, 10)
	bg.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 44)
	scroll.custom_minimum_size = Vector2(220, UITheme.CONT_H - 44)
	bg.add_child(scroll)

	_agent_list_vb = UITheme.vbox(4)
	_agent_list_vb.custom_minimum_size = Vector2(210, 0)
	scroll.add_child(_agent_list_vb)

	_populate_list()
	return bg

func _populate_list():
	for ch in _agent_list_vb.get_children():
		ch.queue_free()

	var owned := GameData.get_owned()
	for agent in owned:
		var row := _make_list_item(agent)
		_agent_list_vb.add_child(row)

func _make_list_item(agent) -> Control:
	var bg := UITheme.crect(UITheme.BG_CARD, Vector2(210, 60))
	bg.mouse_filter = Control.MOUSE_FILTER_STOP

	var icon := UITheme.crect(agent.color, Vector2(44, 44))
	icon.position = Vector2(8, 8)
	bg.add_child(icon)

	var name_lbl := UITheme.lbl(agent.name_kr, UITheme.FS_SM, UITheme.rarity_color(agent.rarity))
	name_lbl.position = Vector2(60, 8)
	bg.add_child(name_lbl)

	var lv_lbl := UITheme.lbl("Lv.%d" % agent.level, UITheme.FS_XS, UITheme.GREY)
	lv_lbl.position = Vector2(60, 30)
	bg.add_child(lv_lbl)

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.modulate.a = 0.0
	btn.pressed.connect(func(): _select(agent))
	bg.add_child(btn)

	return bg

# ── 상세 패널 ─────────────────────────────────────────────────
func _make_detail_panel() -> Control:
	_detail_panel = UITheme.crect(UITheme.BG_PANEL, Vector2(500, UITheme.CONT_H))

	var vb := UITheme.vbox(0)
	vb.position = Vector2(10, 10)
	_detail_panel.add_child(vb)

	# 빈 상태
	var hint := UITheme.lbl("← 유닛을 선택하세요", UITheme.FS_MD, UITheme.GREY)
	hint.position = Vector2(60, UITheme.CONT_H / 2)
	_detail_panel.add_child(hint)

	return _detail_panel

func _select(agent):
	_selected_agent = agent
	_refresh_detail()

func _refresh_detail():
	for ch in _detail_panel.get_children():
		ch.queue_free()

	if _selected_agent == null:
		return

	var a = _selected_agent
	var copies: int = GameData.unit_copies.get(a.id, 0)

	var vb := UITheme.vbox(12)
	vb.position = Vector2(12, 12)
	vb.custom_minimum_size = Vector2(476, 0)
	_detail_panel.add_child(vb)

	# ── 헤더 ──────────────────────────────────────────────
	var hdr := UITheme.hbox(12)
	var icon := UITheme.crect(a.color, Vector2(72, 72))
	hdr.add_child(icon)
	var info_vb := UITheme.vbox(4)
	info_vb.add_child(UITheme.lbl(a.name_kr, UITheme.FS_LG, UITheme.rarity_color(a.rarity)))
	info_vb.add_child(UITheme.lbl(UITheme.rarity_label(a.rarity), UITheme.FS_SM, UITheme.GREY))
	info_vb.add_child(UITheme.lbl("%s · %s" % [a.group, a.job], UITheme.FS_SM, UITheme.CYAN))
	hdr.add_child(info_vb)
	vb.add_child(hdr)
	vb.add_child(UITheme.hsep())

	# ── 스탯 ──────────────────────────────────────────────
	var stat_hb := UITheme.hbox(24)
	_lv_lbl = UITheme.lbl("Lv. %d / %d" % [a.level, MAX_LEVEL], UITheme.FS_MD, UITheme.WHITE)
	_atk_lbl = UITheme.lbl("⚔ %d" % int(a.get_atk()), UITheme.FS_MD, UITheme.ORANGE)
	_hp_lbl  = UITheme.lbl("❤ %d" % int(a.get_hp()),  UITheme.FS_MD, UITheme.HP_GREEN)
	stat_hb.add_child(_lv_lbl)
	stat_hb.add_child(_atk_lbl)
	stat_hb.add_child(_hp_lbl)
	vb.add_child(stat_hb)

	# 스킬
	vb.add_child(UITheme.lbl("스킬: " + a.skill, UITheme.FS_SM, UITheme.PURPLE))
	vb.add_child(UITheme.hsep())

	# ── 레벨업 섹션 ───────────────────────────────────────
	vb.add_child(UITheme.lbl("■ 레벨업", UITheme.FS_MD, UITheme.GOLD))

	var lv_cost := _level_cost(a.level)
	_cost_lbl = UITheme.lbl("비용: 🪙 %d" % lv_cost, UITheme.FS_SM, UITheme.GREY)
	vb.add_child(_cost_lbl)

	var lv_hb := UITheme.hbox(8)
	var btn1 := UITheme.btn("+1 레벨", UITheme.FS_MD, UITheme.WHITE)
	btn1.custom_minimum_size = Vector2(140, 52)
	btn1.pressed.connect(func(): _level_up(1))
	lv_hb.add_child(btn1)
	var btn10 := UITheme.btn("+10 레벨", UITheme.FS_MD, UITheme.WHITE)
	btn10.custom_minimum_size = Vector2(140, 52)
	btn10.pressed.connect(func(): _level_up(10))
	lv_hb.add_child(btn10)
	var btn_max := UITheme.btn("MAX", UITheme.FS_MD, UITheme.GOLD)
	btn_max.custom_minimum_size = Vector2(100, 52)
	btn_max.pressed.connect(func(): _level_up(MAX_LEVEL - a.level))
	lv_hb.add_child(btn_max)
	vb.add_child(lv_hb)

	vb.add_child(UITheme.hsep())

	# ── 승급 섹션 ─────────────────────────────────────────
	vb.add_child(UITheme.lbl("■ 승급 (복사본 필요)", UITheme.FS_MD, UITheme.PURPLE))
	var star_needed := _star_up_copies(a.rarity)
	_star_info_lbl = UITheme.lbl(
		"현재: %d성 · 복사본 %d개 보유 · 승급 필요: %d개" % [a.rarity, copies, star_needed],
		UITheme.FS_SM, UITheme.GREY
	)
	vb.add_child(_star_info_lbl)

	var star_btn := UITheme.btn("승급 (%d개 필요)" % star_needed, UITheme.FS_MD,
		UITheme.GOLD if copies >= star_needed else UITheme.GREY_DIM)
	star_btn.custom_minimum_size = Vector2(300, 52)
	star_btn.pressed.connect(func(): _star_up())
	vb.add_child(star_btn)

	if a.rarity >= 5:
		star_btn.text = "최고 등급 달성"
		star_btn.disabled = true

	vb.add_child(UITheme.hsep())

	# ── 코어 개방 ─────────────────────────────────────────
	vb.add_child(UITheme.lbl("■ 코어 개방 (Lv.40 이상)", UITheme.FS_MD, UITheme.CYAN))
	var core_unlocked: bool = a.get("core_unlocked", false)
	_core_lbl = UITheme.lbl(
		"코어: %s" % ("개방 완료 ✓" if core_unlocked else "미개방"),
		UITheme.FS_SM, UITheme.GREEN if core_unlocked else UITheme.GREY
	)
	vb.add_child(_core_lbl)

	if not core_unlocked:
		var core_btn := UITheme.btn("코어 개방 🪙 5,000", UITheme.FS_MD,
			UITheme.CYAN if a.level >= 40 else UITheme.GREY_DIM)
		core_btn.custom_minimum_size = Vector2(300, 52)
		core_btn.disabled = a.level < 40
		core_btn.pressed.connect(func(): _unlock_core())
		vb.add_child(core_btn)
	else:
		vb.add_child(UITheme.lbl("코어 스킬 활성화됨", UITheme.FS_SM, UITheme.GREEN))

# ── 액션 ──────────────────────────────────────────────────────
func _level_up(count: int):
	if _selected_agent == null: return
	var a = _selected_agent
	var levels := mini(count, MAX_LEVEL - a.level)
	if levels <= 0:
		_show_toast("최대 레벨입니다!")
		return

	var total_cost := 0
	for i in levels:
		total_cost += _level_cost(a.level + i)

	if not GameData.spend_gold(total_cost):
		_show_toast("🪙 골드가 부족합니다!")
		return

	a.level += levels
	_populate_list()
	_refresh_detail()

func _star_up():
	if _selected_agent == null: return
	var a = _selected_agent
	if a.rarity >= 5:
		_show_toast("최고 등급입니다!")
		return
	var needed := _star_up_copies(a.rarity)
	var copies: int = GameData.unit_copies.get(a.id, 0)
	if copies < needed:
		_show_toast("복사본이 부족합니다! (%d / %d)" % [copies, needed])
		return
	GameData.unit_copies[a.id] = copies - needed
	a.rarity += 1
	_populate_list()
	_refresh_detail()

func _unlock_core():
	if _selected_agent == null: return
	var a = _selected_agent
	if a.level < 40:
		_show_toast("Lv.40 이상 필요!")
		return
	if not GameData.spend_gold(5000):
		_show_toast("🪙 골드가 부족합니다!")
		return
	a.set("core_unlocked", true)
	_refresh_detail()

# ── 헬퍼 ──────────────────────────────────────────────────────
func _level_cost(lv: int) -> int:
	return 100 + lv * 50

func _star_up_copies(rarity: int) -> int:
	match rarity:
		5: return 999
		4: return 5
		3: return 10
		2: return 20
		_: return 30

func _show_toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_MD, UITheme.RED)
	lbl.position = Vector2(230, UITheme.CONT_H / 2)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 40, 1.2)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.tween_callback(lbl.queue_free)

func refresh():
	_populate_list()
	if _selected_agent != null:
		_refresh_detail()
