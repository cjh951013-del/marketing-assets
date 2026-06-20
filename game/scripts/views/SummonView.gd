extends Control
# ============================================================
# SummonView.gd — 소환 탭
# ============================================================

var _result_overlay: Control
var _result_list: VBoxContainer
var _pity_lbl: Label
var _banner_name_lbl: Label

const BANNERS = [
	{"name": "★ 신규 영웅 소환", "color": Color(0.65,0.25,0.95), "featured": [20,19]},
	{"name": "★ 전설 소환", "color": Color(1.00,0.78,0.05), "featured": []},
	{"name": "★ 고급 소환", "color": Color(0.22,0.52,1.00), "featured": []},
]
var _cur_banner := 0

# ─────────────────────────────────────────────────────────────
func _ready():
	_build()

func _build():
	custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)

	var root := UITheme.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# ── 배너 선택 탭 (h=52) ──────────────────────────────────
	var tab_row := _make_banner_tabs()
	root.add_child(tab_row)

	# ── 배너 아트 영역 (h=340) ──────────────────────────────
	var banner_art := _make_banner_art()
	root.add_child(banner_art)

	# ── 픽업 캐릭터 표시 (h=100) ─────────────────────────────
	var pickup_row := _make_pickup_row()
	root.add_child(pickup_row)

	# ── 소환 버튼 영역 (h=120) ───────────────────────────────
	var btn_area := _make_pull_buttons()
	root.add_child(btn_area)

	# ── 픽업 정보 + 피티 (h=80) ──────────────────────────────
	var info_row := _make_info_row()
	root.add_child(info_row)

	# ── 확률 표시 (h=90) ─────────────────────────────────────
	var rate_box := _make_rate_box()
	root.add_child(rate_box)

	# ── 결과 오버레이 (hidden) ───────────────────────────────
	_result_overlay = _make_result_overlay()
	add_child(_result_overlay)

# ── 배너 탭 ───────────────────────────────────────────────────
func _make_banner_tabs() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 52))
	var hb := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(hb)
	for i in BANNERS.size():
		var b := Button.new()
		b.text = ["신규", "전설", "고급"][i]
		b.add_theme_font_size_override("font_size", UITheme.FS_SM)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 52)
		var idx := i
		b.pressed.connect(func(): _switch_banner(idx))
		hb.add_child(b)
	return bg

# ── 배너 아트 ─────────────────────────────────────────────────
func _make_banner_art() -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(UITheme.W, 340)

	var bg := UITheme.crect(Color(0.08, 0.04, 0.18), Vector2(UITheme.W, 340))
	root.add_child(bg)

	# 별빛 장식
	for _i in 12:
		var star := Label.new()
		star.text = "✦"
		star.add_theme_font_size_override("font_size", randi_range(10, 22))
		star.add_theme_color_override("font_color", Color(1,1,1, randf_range(0.15, 0.45)))
		star.position = Vector2(randf_range(20, UITheme.W - 40), randf_range(20, 320))
		root.add_child(star)

	# 중앙 배너 이미지 placeholder
	var art_rect := UITheme.crect(Color(0.18, 0.08, 0.35), Vector2(340, 280))
	art_rect.position = Vector2((UITheme.W - 340) / 2, 30)
	root.add_child(art_rect)

	_banner_name_lbl = UITheme.lbl(BANNERS[0]["name"], UITheme.FS_LG, UITheme.GOLD)
	_banner_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_name_lbl.position = Vector2(0, 298)
	_banner_name_lbl.custom_minimum_size = Vector2(UITheme.W, 30)
	root.add_child(_banner_name_lbl)

	return root

# ── 픽업 캐릭터 행 ────────────────────────────────────────────
func _make_pickup_row() -> Control:
	var bg := UITheme.crect(Color(0.12, 0.06, 0.22), Vector2(UITheme.W, 100))

	var vb := UITheme.vbox(4)
	vb.position = Vector2(16, 8)
	bg.add_child(vb)

	vb.add_child(UITheme.lbl("픽업 캐릭터", UITheme.FS_XS, UITheme.GREY))

	var hb := UITheme.hbox(10)
	vb.add_child(hb)

	var agents := GameData.agents
	for idx in BANNERS[0]["featured"]:
		if idx < agents.size():
			var a = agents[idx]
			var card := UITheme.hbox(6)
			var icon := UITheme.crect(a.color, Vector2(48, 48))
			card.add_child(icon)
			var info := UITheme.vbox(2)
			info.add_child(UITheme.lbl(a.name_kr, UITheme.FS_SM, UITheme.rarity_color(a.rarity)))
			info.add_child(UITheme.lbl(UITheme.rarity_label(a.rarity), UITheme.FS_XS, UITheme.GREY))
			card.add_child(info)
			hb.add_child(card)

	if BANNERS[0]["featured"].is_empty():
		hb.add_child(UITheme.lbl("모든 등급 동일 확률", UITheme.FS_SM, UITheme.GREY))

	return bg

# ── 소환 버튼 ─────────────────────────────────────────────────
func _make_pull_buttons() -> Control:
	var bg := UITheme.crect(UITheme.BG_PANEL, Vector2(UITheme.W, 120))

	var hb := UITheme.hbox(16)
	hb.position = Vector2(16, 16)
	bg.add_child(hb)

	# 단일 소환
	var b1 := _pull_btn("단일 소환\n💎 100", UITheme.CYAN)
	b1.pressed.connect(func(): _do_pull(1))
	hb.add_child(b1)

	# 10연 소환
	var b10 := _pull_btn("10연 소환\n💎 900", UITheme.GOLD)
	b10.pressed.connect(func(): _do_pull(10))
	hb.add_child(b10)

	# 현재 보유 젬
	var gem_lbl := UITheme.lbl("보유: 💎 %d" % GameData.gems, UITheme.FS_SM, UITheme.GEM)
	gem_lbl.position = Vector2(16, 90)
	bg.add_child(gem_lbl)

	return bg

func _pull_btn(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", UITheme.FS_MD)
	b.add_theme_color_override("font_color", col)
	b.custom_minimum_size = Vector2(320, 80)
	return b

# ── 정보 + 피티 행 ────────────────────────────────────────────
func _make_info_row() -> Control:
	var bg := UITheme.crect(Color(0.09, 0.05, 0.16), Vector2(UITheme.W, 80))

	var hb := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(hb)

	# 천장 정보
	var pity_vb := UITheme.vbox(4)
	pity_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pity_lbl = UITheme.lbl("피티: %d / 50" % GameData.pity, UITheme.FS_MD, UITheme.ORANGE)
	pity_vb.add_child(_pity_lbl)
	pity_vb.add_child(UITheme.lbl("50회 → 5★ 확정", UITheme.FS_XS, UITheme.GREY))
	hb.add_child(pity_vb)

	# 구분선
	hb.add_child(UITheme.crect(UITheme.GREY_DIM, Vector2(1, 60)))

	# 기록 버튼
	var hist_btn := UITheme.btn("기록\n보기", UITheme.FS_SM, UITheme.GREY)
	hist_btn.custom_minimum_size = Vector2(100, 60)
	hb.add_child(hist_btn)

	return bg

# ── 확률 표시 ─────────────────────────────────────────────────
func _make_rate_box() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 90))

	var hb := UITheme.hbox(24)
	hb.position = Vector2(UITheme.W / 2 - 120, 20)
	bg.add_child(hb)

	var rates = [["5★", "2.0%", UITheme.GOLD], ["4★", "8.0%", UITheme.PURPLE], ["3★", "90%", UITheme.CYAN]]
	for r in rates:
		var vb := UITheme.vbox(4)
		vb.add_child(UITheme.lbl(r[0], UITheme.FS_MD, r[2]))
		vb.add_child(UITheme.lbl(r[1], UITheme.FS_SM, UITheme.WHITE))
		hb.add_child(vb)

	return bg

# ── 결과 오버레이 ─────────────────────────────────────────────
func _make_result_overlay() -> Control:
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.85)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.visible = false
	ov.custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)

	var vb := UITheme.vbox(10)
	vb.position = Vector2(20, 60)
	ov.add_child(vb)

	vb.add_child(UITheme.lbl("✨ 소환 결과", UITheme.FS_XL, UITheme.GOLD))
	vb.add_child(UITheme.hsep())

	_result_list = VBoxContainer.new()
	_result_list.add_theme_constant_override("separation", 8)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(UITheme.W - 40, 700)
	scroll.add_child(_result_list)
	vb.add_child(scroll)

	var close_btn := UITheme.btn("닫기", UITheme.FS_LG, UITheme.WHITE)
	close_btn.custom_minimum_size = Vector2(UITheme.W - 40, 60)
	close_btn.pressed.connect(func(): ov.visible = false)
	vb.add_child(close_btn)

	return ov

# ── 로직 ──────────────────────────────────────────────────────
func _switch_banner(idx: int):
	_cur_banner = idx
	if _banner_name_lbl:
		_banner_name_lbl.text = BANNERS[idx]["name"]

func _do_pull(count: int):
	var cost := 100 * count if count == 1 else 900
	if not GameData.spend_gems(cost):
		_show_toast("💎 젬이 부족합니다!")
		return

	var results := GameData.gacha_pull(count)
	_show_results(results)
	if _pity_lbl:
		_pity_lbl.text = "피티: %d / 50" % GameData.pity

func _show_results(results: Array):
	for child in _result_list.get_children():
		child.queue_free()

	for agent in results:
		var row := UITheme.hbox(12)
		var icon := UITheme.crect(agent.color, Vector2(52, 52))
		row.add_child(icon)

		var info := UITheme.vbox(3)
		info.add_child(UITheme.lbl(agent.name_kr, UITheme.FS_MD, UITheme.rarity_color(agent.rarity)))
		info.add_child(UITheme.lbl(UITheme.rarity_label(agent.rarity), UITheme.FS_SM, UITheme.GREY))
		row.add_child(info)

		var is_new := GameData.unit_copies.get(agent.id, 0) == 1
		if is_new:
			row.add_child(UITheme.lbl("NEW!", UITheme.FS_SM, UITheme.GREEN))

		_result_list.add_child(row)

	_result_overlay.visible = true

func _show_toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_MD, UITheme.RED)
	lbl.position = Vector2(UITheme.W / 2 - 120, UITheme.CONT_H / 2)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tw.tween_callback(lbl.queue_free)
