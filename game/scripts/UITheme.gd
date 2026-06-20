class_name UITheme
# ============================================================
# UITheme.gd — 전체 UI 스타일 상수 + 헬퍼
# 캣히어로 / AFK Arena 스타일 다크 판타지 팔레트
# ============================================================

# ── 색상 팔레트 ───────────────────────────────────────────
const BG_DARK   := Color(0.055, 0.030, 0.100)  # 최외곽 배경
const BG_PANEL  := Color(0.100, 0.060, 0.180)  # 패널/카드 배경
const BG_CARD   := Color(0.130, 0.080, 0.220)  # 개별 카드 배경
const BG_INNER  := Color(0.075, 0.045, 0.145)  # 입력/내부 영역

const GOLD      := Color(1.00, 0.82, 0.18)
const GEM       := Color(0.35, 0.72, 1.00)
const WHITE     := Color(1.00, 1.00, 1.00)
const GREY      := Color(0.55, 0.55, 0.60)
const GREY_DIM  := Color(0.35, 0.35, 0.40)
const RED       := Color(0.90, 0.22, 0.22)
const GREEN     := Color(0.18, 0.88, 0.40)
const ORANGE    := Color(1.00, 0.55, 0.10)
const CYAN      := Color(0.20, 0.88, 0.90)
const PURPLE    := Color(0.65, 0.25, 0.95)
const PINK      := Color(0.95, 0.30, 0.60)
const HP_GREEN  := Color(0.22, 0.80, 0.35)
const HP_RED    := Color(0.80, 0.15, 0.15)
const HP_YELLOW := Color(0.90, 0.78, 0.10)
const NAV_ACTIVE   := Color(0.15, 0.09, 0.28)
const NAV_INACTIVE := Color(0.08, 0.04, 0.14)

# ── 희귀도 색상 ───────────────────────────────────────────
static func rarity_color(r: int) -> Color:
	match r:
		5: return Color(1.00, 0.78, 0.05)   # 금색 (전설)
		4: return Color(0.65, 0.28, 0.98)   # 보라 (영웅)
		3: return Color(0.22, 0.52, 1.00)   # 파랑 (희귀)
		2: return Color(0.22, 0.78, 0.32)   # 초록 (고급)
		_: return Color(0.58, 0.58, 0.62)   # 회색 (일반)

static func rarity_bg(r: int) -> Color:
	return rarity_color(r).darkened(0.60)

static func rarity_label(r: int) -> String:
	match r:
		5: return "★★★★★ 전설"
		4: return "★★★★☆ 영웅"
		3: return "★★★☆☆ 희귀"
		2: return "★★☆☆☆ 고급"
		_: return "★☆☆☆☆ 일반"

# ── 레이아웃 상수 ─────────────────────────────────────────
const W    := 720    # 화면 너비
const H    := 1280   # 화면 높이
const HUD_H := 90    # 상단 HUD 높이
const NAV_H := 108   # 하단 내비 높이
const CONT_Y := 90   # 콘텐츠 시작 Y
const CONT_H := 1082 # 콘텐츠 영역 높이 (1280 - 90 - 108)
const CONT_BTM := 1172 # 콘텐츠 끝 Y (NAV 시작)

# ── 폰트 크기 ─────────────────────────────────────────────
const FS_XS  := 11
const FS_SM  := 14
const FS_MD  := 17
const FS_LG  := 22
const FS_XL  := 28
const FS_XXL := 36

# ── 헬퍼: 노드 생성 ──────────────────────────────────────
static func lbl(text: String, fs: int = FS_MD, col: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l

static func crect(col: Color, sz: Vector2 = Vector2.ZERO) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	if sz != Vector2.ZERO:
		r.custom_minimum_size = sz
	return r

static func btn(text: String, fs: int = FS_MD, col: Color = WHITE) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", col)
	return b

static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func vbox(sep: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func spacer(w: float = 0.0, h: float = 0.0) -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL if w == 0 else 0
	c.custom_minimum_size = Vector2(w, h)
	return c

static func hsep(col: Color = GREY_DIM) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.custom_minimum_size = Vector2(0, 1)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

# HP 바 생성 (배경+전경 쌍)
static func hp_bar(w: float, h: float = 10.0) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(w, h)
	var bg := ColorRect.new()
	bg.color = HP_RED
	bg.size = Vector2(w, h)
	root.add_child(bg)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = HP_GREEN
	fill.size = Vector2(w, h)
	root.add_child(fill)
	return root

static func set_hp_bar(bar: Control, ratio: float):
	ratio = clampf(ratio, 0.0, 1.0)
	var fill = bar.get_node_or_null("Fill")
	if fill:
		fill.size.x = bar.custom_minimum_size.x * ratio
		fill.color = HP_GREEN if ratio > 0.3 else (HP_YELLOW if ratio > 0.15 else HP_RED)
