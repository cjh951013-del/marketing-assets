extends Node2D
# ============================================================
# Main.gd — 루트 씬 / 6탭 뷰 매니저
# ============================================================

const VIEWS := [
	{"label": "⚔\n전투",  "scene": "res://scripts/views/BattleView.gd"},
	{"label": "👥\n편성",  "scene": "res://scripts/views/FormationView.gd"},
	{"label": "🎲\n소환",  "scene": "res://scripts/views/SummonView.gd"},
	{"label": "📈\n성장",  "scene": "res://scripts/views/GrowthView.gd"},
	{"label": "🗺\n탐험",  "scene": "res://scripts/views/ExploreView.gd"},
	{"label": "🏪\n상점",  "scene": "res://scripts/views/ShopView.gd"},
]

var _active_tab   := 0
var _view_nodes:  Array = []
var _nav_buttons: Array = []

var _gold_lbl: Label
var _gem_lbl:  Label
var _lv_lbl:   Label

var _canvas: CanvasLayer

# ─────────────────────────────────────────────────────────────
func _ready():
	_canvas = CanvasLayer.new()
	_canvas.layer = 0
	add_child(_canvas)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.custom_minimum_size = Vector2(UITheme.W, UITheme.H)
	_canvas.add_child(root)

	var bg := UITheme.crect(UITheme.BG_DARK)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	_build_hud(root)
	_build_views(root)
	_build_nav(root)
	_connect_signals()
	_switch_tab(0)
	BattleManager.start_battle()

# ── 상단 HUD (h=90) ──────────────────────────────────────────
func _build_hud(root: Control):
	var hud := UITheme.crect(Color(0.05, 0.02, 0.10), Vector2(UITheme.W, UITheme.HUD_H))
	hud.position = Vector2.ZERO
	root.add_child(hud)

	# 레벨 배지
	var lv_bg := UITheme.crect(UITheme.PURPLE, Vector2(54, 54))
	lv_bg.position = Vector2(10, 18)
	hud.add_child(lv_bg)

	_lv_lbl = UITheme.lbl("Lv\n%d" % GameData.player_level, UITheme.FS_XS, UITheme.WHITE)
	_lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lv_bg.add_child(_lv_lbl)

	# 플레이어 이름
	var name_lbl := UITheme.lbl(GameData.player_name, UITheme.FS_SM, UITheme.WHITE)
	name_lbl.position = Vector2(74, 16)
	hud.add_child(name_lbl)

	# 현재 스테이지
	var stage_lbl := UITheme.lbl(GameData.current_stage, UITheme.FS_XS, UITheme.GREY)
	stage_lbl.name = "StageLbl"
	stage_lbl.position = Vector2(74, 44)
	hud.add_child(stage_lbl)

	# 골드 + 젬 (오른쪽)
	var right_vb := UITheme.vbox(4)
	right_vb.position = Vector2(UITheme.W - 210, 12)
	hud.add_child(right_vb)

	_gold_lbl = UITheme.lbl("🪙 %s" % _fmt_gold(GameData.gold), UITheme.FS_SM, UITheme.GOLD)
	_gold_lbl.name = "GoldLbl"
	right_vb.add_child(_gold_lbl)

	_gem_lbl = UITheme.lbl("💎 %d" % GameData.gems, UITheme.FS_SM, UITheme.GEM)
	_gem_lbl.name = "GemLbl"
	right_vb.add_child(_gem_lbl)

	# 설정 버튼
	var cfg_btn := UITheme.btn("⚙", UITheme.FS_LG, UITheme.GREY)
	cfg_btn.position = Vector2(UITheme.W - 52, 22)
	cfg_btn.custom_minimum_size = Vector2(44, 44)
	hud.add_child(cfg_btn)

# ── 뷰 컨테이너 ──────────────────────────────────────────────
func _build_views(root: Control):
	for i in VIEWS.size():
		var script := load(VIEWS[i]["scene"])
		var view: Control = script.new()
		view.position = Vector2(0, UITheme.HUD_H)
		view.visible  = false
		root.add_child(view)
		_view_nodes.append(view)

# ── 하단 내비 (h=NAV_H) ──────────────────────────────────────
func _build_nav(root: Control):
	var nav_bg := UITheme.crect(Color(0.04, 0.02, 0.08), Vector2(UITheme.W, UITheme.NAV_H))
	nav_bg.position = Vector2(0, UITheme.H - UITheme.NAV_H)
	root.add_child(nav_bg)

	var sep := UITheme.crect(UITheme.GREY_DIM, Vector2(UITheme.W, 1))
	nav_bg.add_child(sep)

	var btn_w := UITheme.W / VIEWS.size()
	for i in VIEWS.size():
		var b := Button.new()
		b.text = VIEWS[i]["label"]
		b.add_theme_font_size_override("font_size", UITheme.FS_XS)
		b.position = Vector2(i * btn_w, 2)
		b.custom_minimum_size = Vector2(btn_w, UITheme.NAV_H - 2)
		_apply_nav_style(b, false)
		var idx := i
		b.pressed.connect(func(): _switch_tab(idx))
		nav_bg.add_child(b)
		_nav_buttons.append(b)

# ── 탭 전환 ──────────────────────────────────────────────────
func _switch_tab(idx: int):
	_active_tab = idx
	for i in _view_nodes.size():
		_view_nodes[i].visible = (i == idx)
		_apply_nav_style(_nav_buttons[i], i == idx)
	var view = _view_nodes[idx]
	if view.has_method("refresh"):
		view.refresh()

func _apply_nav_style(b: Button, active: bool):
	b.add_theme_color_override("font_color", UITheme.GOLD if active else UITheme.GREY)
	b.add_theme_color_override("font_color_hover", UITheme.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.NAV_ACTIVE if active else UITheme.NAV_INACTIVE
	sb.border_color = UITheme.GOLD if active else UITheme.NAV_INACTIVE
	sb.border_width_top = 2 if active else 0
	sb.content_margin_top = 4
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)

# ── 시그널 연결 ──────────────────────────────────────────────
func _connect_signals():
	BattleManager.gold_ticked.connect(_on_gold_ticked)
	BattleManager.wave_started.connect(_on_wave_started)

func _on_gold_ticked(total: float):
	if _gold_lbl:
		_gold_lbl.text = "🪙 %s" % _fmt_gold(total)

func _on_wave_started(_wave: int):
	pass

# ── 유틸 ──────────────────────────────────────────────────────
func _fmt_gold(v: float) -> String:
	if v >= 1_000_000: return "%.1fM" % (v / 1_000_000.0)
	if v >= 1_000:     return "%.1fK" % (v / 1_000.0)
	return "%d" % int(v)
