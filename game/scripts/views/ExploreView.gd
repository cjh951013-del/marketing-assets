extends Control
# ============================================================
# ExploreView.gd — 탐험 탭 (월드맵 + 스테이지)
# ============================================================

var _world_buttons: Array = []
var _stage_container: Control
var _cur_world := 0
var _world_name_lbl: Label
var _reward_lbl: Label

# ─────────────────────────────────────────────────────────────
func _ready():
	_build()

func _build():
	custom_minimum_size = Vector2(UITheme.W, UITheme.CONT_H)

	var root := UITheme.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	root.add_child(_make_world_header())
	root.add_child(_make_world_tabs())
	root.add_child(_make_world_info_bar())
	root.add_child(_make_stage_scroll())
	root.add_child(_make_bottom_bar())

# ── 월드 헤더 (h=70) ─────────────────────────────────────────
func _make_world_header() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 70))

	_world_name_lbl = UITheme.lbl("", UITheme.FS_XL, UITheme.GOLD)
	_world_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world_name_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(_world_name_lbl)

	return bg

# ── 월드 탭 (h=72) ───────────────────────────────────────────
func _make_world_tabs() -> Control:
	var bg := UITheme.crect(Color(0.06, 0.03, 0.12), Vector2(UITheme.W, 72))

	var hb := UITheme.hbox(4)
	hb.position = Vector2(8, 8)
	bg.add_child(hb)

	var worlds := GameData.get_worlds()
	for i in worlds.size():
		var w = worlds[i]
		var b := Button.new()
		b.text = "W%d\n%s" % [i+1, w.short]
		b.add_theme_font_size_override("font_size", UITheme.FS_XS)
		b.custom_minimum_size = Vector2(128, 56)
		var idx := i
		b.pressed.connect(func(): _switch_world(idx))
		_world_buttons.append(b)
		hb.add_child(b)

	_switch_world(0)
	return bg

# ── 월드 정보 바 (h=54) ──────────────────────────────────────
func _make_world_info_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_PANEL, Vector2(UITheme.W, 54))

	_reward_lbl = UITheme.lbl("", UITheme.FS_SM, UITheme.GREY)
	_reward_lbl.position = Vector2(12, 12)
	bg.add_child(_reward_lbl)

	var progress_lbl := UITheme.lbl("진행: 0 / 10", UITheme.FS_SM, UITheme.CYAN)
	progress_lbl.name = "ProgressLbl"
	progress_lbl.position = Vector2(UITheme.W - 150, 12)
	bg.add_child(progress_lbl)

	return bg

# ── 스테이지 스크롤 (나머지 높이) ───────────────────────────
func _make_stage_scroll() -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(UITheme.W, 792)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_stage_container = GridContainer.new()
	_stage_container.columns = 2
	_stage_container.add_theme_constant_override("h_separation", 12)
	_stage_container.add_theme_constant_override("v_separation", 12)
	_stage_container.custom_minimum_size = Vector2(UITheme.W - 16, 0)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_child(_stage_container)

	scroll.add_child(pad)
	return scroll

# ── 하단 바 (h=94) ───────────────────────────────────────────
func _make_bottom_bar() -> Control:
	var bg := UITheme.crect(UITheme.BG_DARK, Vector2(UITheme.W, 94))

	var hb := UITheme.hbox(16)
	hb.position = Vector2(12, 12)
	bg.add_child(hb)

	var sweep_btn := UITheme.btn("⚡ 쓸기 (×3)", UITheme.FS_MD, UITheme.CYAN)
	sweep_btn.custom_minimum_size = Vector2(200, 66)
	sweep_btn.pressed.connect(_on_sweep)
	hb.add_child(sweep_btn)

	var auto_btn := UITheme.btn("🔄 자동 탐험", UITheme.FS_MD, UITheme.ORANGE)
	auto_btn.custom_minimum_size = Vector2(200, 66)
	hb.add_child(auto_btn)

	return bg

# ── 스테이지 카드 생성 ────────────────────────────────────────
func _build_stages(world_idx: int):
	for ch in _stage_container.get_children():
		ch.queue_free()

	var cleared_key := "cleared_stages"
	var cleared: Dictionary = GameData.get(cleared_key, {})

	for s in range(1, 11):
		var stage_id := "W%d-%d" % [world_idx+1, s]
		var is_boss := (s == 5 or s == 10)
		var is_cleared := cleared.get(stage_id, false)
		var is_locked := not _is_unlocked(world_idx, s, cleared)

		var card := _make_stage_card(stage_id, s, is_boss, is_cleared, is_locked)
		_stage_container.add_child(card)

func _make_stage_card(stage_id: String, stage_num: int, is_boss: bool, is_cleared: bool, is_locked: bool) -> Control:
	var card_h := 110 if is_boss else 90
	var bg_col := Color(0.14, 0.07, 0.24) if not is_locked else Color(0.08, 0.04, 0.12)

	var card := UITheme.crect(bg_col, Vector2(338, card_h))

	# 희귀도 테두리 느낌
	if is_boss:
		var border := UITheme.crect(UITheme.GOLD, Vector2(338, card_h))
		border.position = Vector2.ZERO
		var inner := UITheme.crect(bg_col, Vector2(334, card_h - 4))
		inner.position = Vector2(2, 2)
		card.add_child(border)
		card.add_child(inner)

	var stage_lbl := UITheme.lbl(stage_id, UITheme.FS_LG,
		UITheme.GOLD if is_boss else (UITheme.GREY if is_locked else UITheme.WHITE))
	stage_lbl.position = Vector2(12, 8)
	card.add_child(stage_lbl)

	if is_boss:
		var boss_tag := UITheme.lbl("👑 BOSS", UITheme.FS_SM, UITheme.ORANGE)
		boss_tag.position = Vector2(200, 8)
		card.add_child(boss_tag)

	if is_cleared:
		var clear_lbl := UITheme.lbl("✓ 클리어", UITheme.FS_XS, UITheme.GREEN)
		clear_lbl.position = Vector2(12, 36)
		card.add_child(clear_lbl)
	elif is_locked:
		var lock_lbl := UITheme.lbl("🔒 잠금", UITheme.FS_XS, UITheme.GREY_DIM)
		lock_lbl.position = Vector2(12, 36)
		card.add_child(lock_lbl)
	else:
		var rewards_lbl := UITheme.lbl("보상: 🪙 %d + 💎 %d" % [200 + stage_num * 50, 2 if is_boss else 0],
			UITheme.FS_XS, UITheme.GREY)
		rewards_lbl.position = Vector2(12, 36)
		card.add_child(rewards_lbl)

	# 도전 버튼
	if not is_locked:
		var go_btn := Button.new()
		go_btn.text = "▶ 도전"
		go_btn.add_theme_font_size_override("font_size", UITheme.FS_SM)
		go_btn.add_theme_color_override("font_color", UITheme.WHITE)
		go_btn.custom_minimum_size = Vector2(100, 36)
		go_btn.position = Vector2(226, card_h - 46)
		var sid := stage_id
		go_btn.pressed.connect(func(): _challenge_stage(sid))
		card.add_child(go_btn)

	return card

# ── 월드 전환 ─────────────────────────────────────────────────
func _switch_world(idx: int):
	_cur_world = idx
	var worlds := GameData.get_worlds()
	if idx >= worlds.size(): return

	var w = worlds[idx]
	if _world_name_lbl:
		_world_name_lbl.text = "W%d. %s" % [idx+1, w.name]

	var reward_bar = find_child("ProgressLbl", true, false)
	if reward_bar:
		reward_bar.text = "배경: %s" % w.get("theme", "일반")

	if _reward_lbl:
		_reward_lbl.text = "드롭: %s" % w.get("drop", "골드, 재료")

	for i in _world_buttons.size():
		_world_buttons[i].modulate = UITheme.GOLD if i == idx else UITheme.WHITE

	_build_stages(idx)

# ── 스테이지 잠금 해제 체크 ──────────────────────────────────
func _is_unlocked(world_idx: int, stage_num: int, cleared: Dictionary) -> bool:
	if world_idx == 0 and stage_num == 1: return true
	if stage_num == 1:
		return cleared.get("W%d-10" % world_idx, false)
	return cleared.get("W%d-%d" % [world_idx+1, stage_num-1], false)

# ── 도전 ──────────────────────────────────────────────────────
func _challenge_stage(stage_id: String):
	GameData.current_stage = stage_id
	BattleManager.wave = 1
	BattleManager.restart()
	_show_toast("⚔ %s 시작!" % stage_id)

func _on_sweep():
	_show_toast("쓸기 기능은 준비 중입니다.")

func _show_toast(msg: String):
	var lbl := UITheme.lbl(msg, UITheme.FS_MD, UITheme.GOLD)
	lbl.position = Vector2(UITheme.W / 2 - 140, UITheme.CONT_H / 2)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 50, 1.5)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.5)
	tw.tween_callback(lbl.queue_free)

func refresh():
	_switch_world(_cur_world)
