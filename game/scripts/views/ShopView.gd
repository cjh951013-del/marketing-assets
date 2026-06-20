extends Control
# ============================================================
# ShopView.gd — 상점 탭
# 서브탭: 골드상점 / 소환상점 / 재화교환
# ============================================================

var _tab_btns: Array = []
var _content_area: Control
var _cur_tab := 0

# ─────────────────────────────────────────────────────────────
func _ready():
	_build()

func _build():
	custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)

	var root := UITheme.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	root.add_child(_make_header())
	root.add_child(_make_tab_bar())

	_content_area = Control.new()
	_content_area.custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H - 90 - 58)
	_content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content_area)

	_switch_tab(0)

# ── 헤더 (h=90) ──────────────────────────────────────────────
func _make_header() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 90))

	var title := UITheme.lbl("🏪 상점", UITheme.FS_XL, UITheme.GOLD)
	title.position = Vector2(20, 14)
	bg.add_child(title)

	var gold_lbl := UITheme.lbl("🪙 %d" % int(GameData.gold), UITheme.FS_MD, UITheme.GOLD)
	gold_lbl.name = "GoldLbl"
	gold_lbl.position = Vector2(UITheme.W - 220, 14)
	bg.add_child(gold_lbl)

	var gem_lbl := UITheme.lbl("💎 %d" % GameData.gems, UITheme.FS_MD, UITheme.GEM)
	gem_lbl.name = "GemLbl"
	gem_lbl.position = Vector2(UITheme.W - 220, 48)
	bg.add_child(gem_lbl)

	return bg

# ── 서브탭 바 (h=58) ─────────────────────────────────────────
func _make_tab_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_PANEL, Vector2(UITheme.W, 58))

	var hb := UITheme.hbox(0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(hb)

	var tabs := ["💰 골드상점", "🎲 소환상점", "🔄 재화교환"]
	for i in tabs.size():
		var b := Button.new()
		b.text = tabs[i]
		b.add_theme_font_size_override("font_size", UITheme.FS_SM)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 58)
		var idx := i
		b.pressed.connect(func(): _switch_tab(idx))
		_tab_btns.append(b)
		hb.add_child(b)

	return bg

# ── 탭 전환 ──────────────────────────────────────────────────
func _switch_tab(idx: int):
	_cur_tab = idx
	for ch in _content_area.get_children():
		ch.queue_free()

	for i in _tab_btns.size():
		_tab_btns[i].modulate = UITheme.GOLD if i == idx else UITheme.WHITE

	match idx:
		0: _content_area.add_child(_make_gold_shop())
		1: _content_area.add_child(_make_summon_shop())
		2: _content_area.add_child(_make_exchange_shop())

# ── 골드 상점 ─────────────────────────────────────────────────
func _make_gold_shop() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vb := UITheme.vbox(10)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_child(vb)
	scroll.add_child(margin)

	vb.add_child(UITheme.lbl("🛒 골드 상점", UITheme.FS_LG, UITheme.GOLD))
	vb.add_child(UITheme.lbl("매일 오전 5시 리셋", UITheme.FS_XS, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	var items := GameData.get_shop_items()
	for item in items:
		if item.get("type", "") != "gold": continue
		vb.add_child(_make_shop_item(item))

	return scroll

# ── 소환 상점 ─────────────────────────────────────────────────
func _make_summon_shop() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vb := UITheme.vbox(10)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_child(vb)
	scroll.add_child(margin)

	vb.add_child(UITheme.lbl("🎲 소환 상점", UITheme.FS_LG, UITheme.PURPLE))
	vb.add_child(UITheme.lbl("젬으로 소환 아이템 구매", UITheme.FS_XS, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	var items := GameData.get_shop_items()
	for item in items:
		if item.get("type", "") != "summon": continue
		vb.add_child(_make_shop_item(item))

	# 패키지 섹션
	vb.add_child(UITheme.hsep())
	vb.add_child(UITheme.lbl("📦 특별 패키지", UITheme.FS_MD, UITheme.ORANGE))
	vb.add_child(_make_package_card("신규 영웅 패키지", "💎 600 + 소환권 ×5", "💎 900", Color(0.65,0.25,0.95)))
	vb.add_child(_make_package_card("전설 패키지", "💎 3,000 + 전설 확정권 ×1", "💎 4,500", UITheme.GOLD))

	return scroll

# ── 재화 교환 ─────────────────────────────────────────────────
func _make_exchange_shop() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vb := UITheme.vbox(10)
	vb.custom_minimum_size = Vector2(UITheme.W - 16, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_child(vb)
	scroll.add_child(margin)

	vb.add_child(UITheme.lbl("🔄 재화 교환", UITheme.FS_LG, UITheme.CYAN))
	vb.add_child(UITheme.lbl("골드 ↔ 소환 재료", UITheme.FS_XS, UITheme.GREY))
	vb.add_child(UITheme.hsep())

	var exchanges := [
		{"name": "일반 소환권", "desc": "3★ 이상 확정 소환권 ×1", "cost_gold": 500, "cost_gem": 0},
		{"name": "고급 소환권", "desc": "4★ 이상 확정 소환권 ×1", "cost_gold": 0, "cost_gem": 150},
		{"name": "전설 조각", "desc": "전설 조각 ×10", "cost_gold": 2000, "cost_gem": 0},
		{"name": "강화석 (소)", "desc": "장비 강화 재료 ×5", "cost_gold": 300, "cost_gem": 0},
		{"name": "강화석 (대)", "desc": "장비 강화 재료 ×50", "cost_gold": 0, "cost_gem": 50},
		{"name": "골드 → 젬", "desc": "🪙 10,000 → 💎 10", "cost_gold": 10000, "cost_gem": 0, "gives_gem": 10},
	]

	for ex in exchanges:
		vb.add_child(_make_exchange_item(ex))

	return scroll

# ── 아이템 카드 ───────────────────────────────────────────────
func _make_shop_item(item: Dictionary) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 80))

	var icon := UITheme.crect(item.get("color", UITheme.GREY), Vector2(56, 56))
	icon.position = Vector2(12, 12)
	card.add_child(icon)

	var name_lbl := UITheme.lbl(item.get("name", "?"), UITheme.FS_MD, UITheme.WHITE)
	name_lbl.position = Vector2(80, 10)
	card.add_child(name_lbl)

	var desc_lbl := UITheme.lbl(item.get("desc", ""), UITheme.FS_XS, UITheme.GREY)
	desc_lbl.position = Vector2(80, 36)
	card.add_child(desc_lbl)

	var is_gem: bool = item.get("currency", "gold") == "gem"
	var cost_lbl := UITheme.lbl(
		("%s %d" % ["💎" if is_gem else "🪙", item.get("cost", 0)]),
		UITheme.FS_SM, UITheme.GEM if is_gem else UITheme.GOLD
	)
	cost_lbl.position = Vector2(UITheme.W - 160, 10)
	card.add_child(cost_lbl)

	var buy_btn := UITheme.btn("구매", UITheme.FS_SM, UITheme.WHITE)
	buy_btn.custom_minimum_size = Vector2(80, 44)
	buy_btn.position = Vector2(UITheme.W - 110, 18)
	var it := item
	buy_btn.pressed.connect(func(): _buy_item(it))
	card.add_child(buy_btn)

	return card

func _make_exchange_item(ex: Dictionary) -> Control:
	var card := UITheme.crect(UITheme.BG_CARD, Vector2(UITheme.W - 32, 80))

	var name_lbl := UITheme.lbl(ex["name"], UITheme.FS_MD, UITheme.CYAN)
	name_lbl.position = Vector2(12, 10)
	card.add_child(name_lbl)

	var desc_lbl := UITheme.lbl(ex["desc"], UITheme.FS_XS, UITheme.GREY)
	desc_lbl.position = Vector2(12, 36)
	card.add_child(desc_lbl)

	var cost_str: String
	if ex.get("cost_gem", 0) > 0:
		cost_str = "💎 %d" % ex["cost_gem"]
	else:
		cost_str = "🪙 %d" % ex["cost_gold"]

	var cost_lbl := UITheme.lbl(cost_str, UITheme.FS_SM,
		UITheme.GEM if ex.get("cost_gem", 0) > 0 else UITheme.GOLD)
	cost_lbl.position = Vector2(UITheme.W - 180, 10)
	card.add_child(cost_lbl)

	var buy_btn := UITheme.btn("교환", UITheme.FS_SM, UITheme.WHITE)
	buy_btn.custom_minimum_size = Vector2(80, 44)
	buy_btn.position = Vector2(UITheme.W - 110, 18)
	var it := ex
	buy_btn.pressed.connect(func(): _exchange(it))
	card.add_child(buy_btn)

	return card

func _make_package_card(name: String, desc: String, price: String, col: Color) -> Control:
	var card := UITheme.crect(col.darkened(0.6), Vector2(UITheme.W - 32, 90))

	var border := ColorRect.new()
	border.color = col
	border.size = Vector2(4, 90)
	card.add_child(border)

	var name_lbl := UITheme.lbl(name, UITheme.FS_MD, col)
	name_lbl.position = Vector2(16, 10)
	card.add_child(name_lbl)

	var desc_lbl := UITheme.lbl(desc, UITheme.FS_XS, UITheme.WHITE)
	desc_lbl.position = Vector2(16, 38)
	card.add_child(desc_lbl)

	var price_lbl := UITheme.lbl(price, UITheme.FS_SM, UITheme.GEM)
	price_lbl.position = Vector2(UITheme.W - 190, 10)
	card.add_child(price_lbl)

	var buy_btn := UITheme.btn("구매", UITheme.FS_SM, UITheme.GOLD)
	buy_btn.custom_minimum_size = Vector2(80, 52)
	buy_btn.position = Vector2(UITheme.W - 110, 18)
	card.add_child(buy_btn)

	return card

# ── 구매 로직 ─────────────────────────────────────────────────
func _buy_item(item: Dictionary):
	var cost: int = item.get("cost", 0)
	var is_gem: bool = item.get("currency", "gold") == "gem"

	if is_gem:
		if not GameData.spend_gems(cost):
			_show_toast("💎 젬이 부족합니다!")
			return
	else:
		if not GameData.spend_gold(float(cost)):
			_show_toast("🪙 골드가 부족합니다!")
			return

	_show_toast("✅ %s 구매 완료!" % item.get("name", "아이템"))
	_refresh_currency()

func _exchange(ex: Dictionary):
	if ex.get("cost_gem", 0) > 0:
		if not GameData.spend_gems(ex["cost_gem"]):
			_show_toast("💎 젬이 부족합니다!")
			return
	else:
		if not GameData.spend_gold(float(ex["cost_gold"])):
			_show_toast("🪙 골드가 부족합니다!")
			return

	if ex.get("gives_gem", 0) > 0:
		GameData.gems += ex["gives_gem"]

	_show_toast("✅ 교환 완료!")
	_refresh_currency()

func _refresh_currency():
	var gold_lbl = find_child("GoldLbl", true, false)
	if gold_lbl: gold_lbl.text = "🪙 %d" % int(GameData.gold)
	var gem_lbl = find_child("GemLbl", true, false)
	if gem_lbl: gem_lbl.text = "💎 %d" % GameData.gems

func _show_toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_MD, UITheme.GREEN)
	lbl.position = Vector2(UITheme.W / 2 - 130, 200)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 60, 1.5)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.5)
	tw.tween_callback(lbl.queue_free)

func refresh():
	_refresh_currency()
