extends Node2D

const ScreenUtil = preload("res://scripts/ScreenUtil.gd")
const Leaderboard = preload("res://scripts/Leaderboard.gd")

var time: float = 0.0
var play_btn: Button
var title_lbl: Label
var shift_lbl: Label
var sound_btn: Button
var music_player: AudioStreamPlayer = null

func _ready():
	SoundManager.load_setting()
	HeroManager.load_hero()
		# TEST: onboarding'i her seferinde göster
	#if FileAccess.file_exists("user://onboarding_done.dat"):
	#	DirAccess.remove_absolute(OS.get_user_data_dir() + "/onboarding_done.dat")
	_build()
	_play_menu_music()

func _play_menu_music():
	var path = "res://audio/music_01.wav"
	var stream = load(path)
	if stream:
		music_player = AudioStreamPlayer.new()
		music_player.stream = stream
		music_player.volume_db = -10.0
		add_child(music_player)
		if SoundManager.is_on():
			music_player.play()
		music_player.finished.connect(func():
			if SoundManager.is_on():
				music_player.play()
		)

func _load_max_level() -> int:
	if not FileAccess.file_exists("user://max_level.dat"):
		return 1
	var f = FileAccess.open("user://max_level.dat", FileAccess.READ)
	if f:
		var val = f.get_8()
		f.close()
		return clamp(val, 1, 50)
	return 1

func _load_all_stars() -> Array:
	var result = []
	for i in 50:
		result.append(0)
	if not FileAccess.file_exists("user://stars.dat"):
		return result
	var f = FileAccess.open("user://stars.dat", FileAccess.READ)
	if f:
		for i in 50:
			result[i] = f.get_8()
		f.close()
	return result

func _build():
	var canvas = Node2D.new()
	canvas.set_script(_get_bg_script())
	add_child(canvas)

	var ui = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

# ── Logo ──
	var logo = Node2D.new()
	logo.set_script(_get_logo_script())
	logo.position = Vector2(240, 126)
	logo.scale = Vector2(1.08, 1.08)
	ui.add_child(logo)

	# ── Başlık arka dekor (dönen halka + parçacık) ──
	var title_decor = Node2D.new()
	title_decor.set_script(_get_title_decor_script())
	title_decor.position = Vector2(240, 262)
	ui.add_child(title_decor)

	# ── Üst çubuk: BOARD, AWARDS · ses · LEVELS ──
	var max_lvl = _load_max_level()
	var top_bar = []
	top_bar.append_array(_top_button(ui, Vector2(14, 14), 84.0, "podium", Color(1.0, 0.75, 0.0), "BOARD", func(): _show_leaderboard(ui)))
	top_bar.append_array(_top_button(ui, Vector2(104, 14), 84.0, "trophy", Color(1.0, 0.5, 0.85), "AWARDS", func(): _show_awards(ui)))
	top_bar.append_array(_top_button(ui, Vector2(382, 14), 84.0, "portal", Color(0.3, 1.0, 0.5), "LEVELS", func(): _show_level_select(ui)))
	# Ses: eskiden PLAY'in altında büyük butondu; artık üst çubukta küçük simge
	var snd_panel = Node2D.new()
	snd_panel.set_script(_get_hud_button_script("none", Color(0.0, 0.75, 1.0), 52.0))
	snd_panel.position = Vector2(324, 14)
	ui.add_child(snd_panel)
	var sound_vis = Node2D.new()
	sound_vis.set_script(load("res://scripts/SoundButtonVisual.gd"))
	sound_vis.name = "SoundVis"
	sound_vis.position = Vector2(350, 42)
	if sound_vis.has_method("setup"):
		sound_vis.setup(SoundManager.is_on())
	ui.add_child(sound_vis)
	sound_btn = Button.new()
	sound_btn.name = "SoundBtn"
	sound_btn.size = Vector2(52, 56)
	sound_btn.position = Vector2(324, 14)
	sound_btn.flat = true
	sound_btn.focus_mode = Control.FOCUS_NONE
	sound_btn.pressed.connect(_on_sound_toggle)
	ui.add_child(sound_btn)
	top_bar.append_array([snd_panel, sound_vis, sound_btn])

	# ── Başlık: Orbitron, iki satır (süs çizgileri kaldırıldı: harflerin üstünden geçiyorlardı) ──
	title_lbl = Label.new()
	title_lbl.text = "MAGNET"
	title_lbl.position = Vector2(0, 192)
	title_lbl.size = Vector2(480, 72)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", UIFont.title(6))
	title_lbl.add_theme_font_size_override("font_size", 54)
	title_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.55, 1.0, 0.9))
	title_lbl.add_theme_constant_override("shadow_outline_size", 16)
	title_lbl.add_theme_constant_override("outline_size", 6)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.15, 0.3, 1.0))
	ui.add_child(title_lbl)

	shift_lbl = Label.new()
	shift_lbl.text = "SHIFT"
	shift_lbl.position = Vector2(0, 258)
	shift_lbl.size = Vector2(480, 72)
	shift_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shift_lbl.add_theme_font_override("font", UIFont.title(14))
	shift_lbl.add_theme_font_size_override("font_size", 54)
	shift_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	shift_lbl.add_theme_color_override("font_shadow_color", Color(0.85, 0.3, 1.0, 0.85))
	shift_lbl.add_theme_constant_override("shadow_outline_size", 14)
	shift_lbl.add_theme_constant_override("outline_size", 6)
	shift_lbl.add_theme_color_override("font_outline_color", Color(0.25, 0.0, 0.3, 1.0))
	ui.add_child(shift_lbl)

	var tag_lbl = Label.new()
	tag_lbl.text = "TAP · ATTRACT · ESCAPE"
	tag_lbl.position = Vector2(0, 334)
	tag_lbl.size = Vector2(480, 22)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_override("font", UIFont.title(3))
	tag_lbl.add_theme_font_size_override("font_size", 13)
	tag_lbl.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0, 0.9))
	ui.add_child(tag_lbl)

	# ── Günlük seri rozeti (oyuncuyu her gün geri çağırır) ──
	var streak = Progress.streak_info()
	if streak["count"] >= 1:
		var st_lbl = Label.new()
		st_lbl.text = "🔥 %d-DAY STREAK" % streak["count"] + ("" if streak["today"] else "  ·  PLAY TODAY!")
		st_lbl.position = Vector2(0, 362)
		st_lbl.size = Vector2(480, 22)
		st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_lbl.add_theme_font_override("font", UIFont.title(2))
		st_lbl.add_theme_font_size_override("font_size", 12)
		st_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25) if streak["today"] else Color(1.0, 0.85, 0.35))
		ui.add_child(st_lbl)

	var hero_title = Label.new()
	hero_title.text = "SELECT HERO"
	hero_title.position = Vector2(0, 390)
	hero_title.size = Vector2(480, 20)
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_override("font", UIFont.title(3))
	hero_title.add_theme_font_size_override("font_size", 12)
	hero_title.add_theme_color_override("font_color", Color(0.68, 0.72, 0.98, 0.95))
	ui.add_child(hero_title)

	# ── Hero kartlar ──
	var hero_names = ["CYBORG", "PINK", "SHADOW", "MECH", "BLAZE", "POLARIS"]
	var hero_colors = [Color(0.0, 0.83, 1.0), Color(1.0, 0.4, 0.7), Color(0.6, 0.1, 0.9), Color(0.5, 1.0, 0.1), Color(1.0, 0.45, 0.05), Color(0.72, 0.42, 1.0)]
	# BLAZE ve POLARIS level ile değil, 3'er ödüllü reklamla açılır
	var hero_locked = [false, false, max_lvl < 5, max_lvl < 10,
		not HeroManager.is_ad_hero_unlocked(HeroManager.BLAZE_ID), not HeroManager.is_ad_hero_unlocked(HeroManager.POLARIS_ID)]
	var hero_count = hero_names.size()
	# İki sıra: üstte 4 kahraman, altta reklamla açılan 2 kahraman ortalı
	var hero_y = 414.0
	var card_w = 104.0
	var card_h = 116.0
	var gap = 8.0
	var row_gap = 8.0
	var per_row = [4, 2]

	for i in hero_count:
		var row = 0 if i < per_row[0] else 1
		var col_i = i if row == 0 else i - per_row[0]
		var n_in_row = per_row[row]
		var row_x = (480 - (card_w * n_in_row + gap * (n_in_row - 1))) / 2
		var cx = row_x + col_i * (card_w + gap)
		var cy = hero_y + row * (card_h + row_gap)
		var is_locked = hero_locked[i]
		var is_sel = HeroManager.get_hero() == i and not is_locked

		var hbg = ColorRect.new()
		hbg.name = "HeroBg%d" % i
		hbg.size = Vector2(card_w, card_h)
		hbg.position = Vector2(cx, cy)
		if is_locked:
			hbg.color = Color(0.08, 0.06, 0.1, 1.0)
		else:
			hbg.color = Color(hero_colors[i].r*0.15, hero_colors[i].g*0.1, hero_colors[i].b*0.2, 1.0) if is_sel else Color(0.04, 0.03, 0.1, 1.0)
		ui.add_child(hbg)

		var hframe = ColorRect.new()
		hframe.name = "HeroFrame%d" % i
		hframe.size = Vector2(card_w, 4)
		hframe.position = Vector2(cx, cy)
		hframe.color = Color(0.3, 0.3, 0.35, 0.5) if is_locked else (hero_colors[i] if is_sel else Color(0.2, 0.2, 0.3, 0.5))
		ui.add_child(hframe)

		var hbot = ColorRect.new()
		hbot.name = "HeroBotLine%d" % i
		hbot.size = Vector2(card_w, 3)
		hbot.position = Vector2(cx, cy + card_h - 3)
		hbot.color = Color(0.3, 0.3, 0.35, 0.5) if is_locked else (hero_colors[i] if is_sel else Color(0.2, 0.2, 0.3, 0.5))
		ui.add_child(hbot)

		var hvis = Node2D.new()
		if HeroManager.is_ad_hero(i):
			# Reklamla açılan kahramanların önizlemesi oyundaki çizimin kendisi (ayrı kopya tutmamak için)
			hvis.set_script(load("res://scripts/PlayerVisual.gd"))
			hvis.preview_hero = i
		else:
			hvis.set_script(_get_hero_preview_script(i))
		hvis.position = Vector2(cx + card_w / 2, cy + 54)
		if is_locked:
			# reklamla açılanlar "vitrinde": kilitliyken de seçilebilir görünsün
			hvis.modulate = Color(0.6, 0.6, 0.65, 0.85) if HeroManager.is_ad_hero(i) else Color(0.3, 0.3, 0.3, 0.5)
		ui.add_child(hvis)

		if is_locked:
			# Kilit ikonu
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒"
			lock_lbl.position = Vector2(cx + card_w/2 - 16, cy + 30)
			lock_lbl.add_theme_font_size_override("font_size", 28)
			ui.add_child(lock_lbl)
			var unlock_lbl = Label.new()
			unlock_lbl.size = Vector2(card_w, 20)
			unlock_lbl.position = Vector2(cx, cy + 68)
			unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			unlock_lbl.add_theme_font_size_override("font_size", 11)
			if HeroManager.is_ad_hero(i):
				unlock_lbl.text = "🎬 %d/%d ADS" % [HeroManager.ads_watched(i), HeroManager.ads_required(i)]
				unlock_lbl.add_theme_color_override("font_color", hero_colors[i].lightened(0.25))
				# Dokunulabilir olduğunu belli etmek için kart çerçevesi kahramanın renginde
				hframe.color = Color(hero_colors[i].r, hero_colors[i].g, hero_colors[i].b, 0.7)
				hbot.color = Color(hero_colors[i].r, hero_colors[i].g, hero_colors[i].b, 0.7)
			else:
				unlock_lbl.text = "Reach Lvl 5" if i == 2 else "Reach Lvl 10"
				unlock_lbl.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6, 0.8))
			ui.add_child(unlock_lbl)

		var hlbl = Label.new()
		hlbl.name = "HeroLbl%d" % i
		hlbl.text = hero_names[i]
		hlbl.size = Vector2(card_w, 24)
		hlbl.position = Vector2(cx, cy + card_h - 24)
		hlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hlbl.add_theme_font_override("font", UIFont.title(1))
		hlbl.add_theme_font_size_override("font_size", 11)
		hlbl.add_theme_color_override("font_color",
			Color(0.35, 0.3, 0.4, 0.6) if is_locked else (hero_colors[i] if is_sel else Color(0.45, 0.45, 0.6)))
		ui.add_child(hlbl)

		if not is_locked:
			var check = Label.new()
			check.name = "HeroCheck%d" % i
			check.text = "✓" if is_sel else ""
			check.size = Vector2(24, 24)
			check.position = Vector2(cx + card_w - 22, cy + 5)
			check.add_theme_font_size_override("font_size", 14)
			check.add_theme_color_override("font_color", hero_colors[i])
			ui.add_child(check)

		var hbtn = Button.new()
		hbtn.size = Vector2(card_w, card_h)
		hbtn.position = Vector2(cx, cy)
		hbtn.flat = true
		hbtn.text = ""
		var hero_idx = i
		var locked = is_locked
		hbtn.pressed.connect(func():
			if locked:
				if HeroManager.is_ad_hero(hero_idx):
					_show_ad_unlock(ui, hero_idx, hero_colors[hero_idx])
				return
			HeroManager.save_hero(hero_idx)
			HeroManager.selected_hero = hero_idx
			for j in hero_count:
				if hero_locked[j]:
					continue
				var sel = j == hero_idx
				var bg2 = ui.get_node_or_null("HeroBg%d" % j)
				if bg2: bg2.color = Color(hero_colors[j].r*0.15, hero_colors[j].g*0.1, hero_colors[j].b*0.2, 1.0) if sel else Color(0.04, 0.03, 0.1, 1.0)
				var fr2 = ui.get_node_or_null("HeroFrame%d" % j)
				if fr2: fr2.color = hero_colors[j] if sel else Color(0.2, 0.2, 0.3, 0.5)
				var fb2 = ui.get_node_or_null("HeroBotLine%d" % j)
				if fb2: fb2.color = hero_colors[j] if sel else Color(0.2, 0.2, 0.3, 0.5)
				var lb2 = ui.get_node_or_null("HeroLbl%d" % j)
				if lb2: lb2.add_theme_color_override("font_color", hero_colors[j] if sel else Color(0.45, 0.45, 0.6))
				var ck2 = ui.get_node_or_null("HeroCheck%d" % j)
				if ck2: ck2.text = "✓" if sel else ""
		)
		ui.add_child(hbtn)

	# ── PLAY / CONTINUE ──
	# Geri dönen oyuncu kaldığı en yüksek level'den devam eder; Level 1 için küçük NEW GAME
	var play_y = hero_y + card_h * 2 + row_gap + 16
	var can_continue = max_lvl > 1
	var btn_panel = ColorRect.new()
	btn_panel.size = Vector2(300, 72)
	btn_panel.position = Vector2(90, play_y)
	btn_panel.color = Color(0.0, 0.12, 0.3, 1.0)
	ui.add_child(btn_panel)
	var left_line = ColorRect.new()
	left_line.size = Vector2(4, 72)
	left_line.position = Vector2(90, play_y)
	left_line.color = Color(0.0, 0.85, 1.0, 1.0)
	ui.add_child(left_line)
	var top_line2 = ColorRect.new()
	top_line2.size = Vector2(300, 2)
	top_line2.position = Vector2(90, play_y)
	top_line2.color = Color(0.0, 0.85, 1.0, 0.6)
	ui.add_child(top_line2)
	var bot_line2 = ColorRect.new()
	bot_line2.size = Vector2(300, 3)
	bot_line2.position = Vector2(90, play_y + 72)
	bot_line2.color = Color(0.0, 0.85, 1.0, 1.0)
	ui.add_child(bot_line2)
	play_btn = Button.new()
	play_btn.text = "▶ CONTINUE" if can_continue else "▶  PLAY"
	play_btn.size = Vector2(300, 72)
	play_btn.position = Vector2(90, play_y)
	play_btn.flat = true
	play_btn.focus_mode = Control.FOCUS_NONE
	play_btn.add_theme_font_override("font", UIFont.title(2))
	play_btn.add_theme_font_size_override("font_size", 26 if can_continue else 30)
	play_btn.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 1.0))
	play_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	if can_continue:
		var lvl_n = max_lvl
		play_btn.pressed.connect(func(): LevelTransition.flash_and_load("res://scenes/Level%d.tscn" % lvl_n))
	else:
		play_btn.pressed.connect(_on_play)
	ui.add_child(play_btn)
	if can_continue:
		var lvl_tag = Label.new()
		lvl_tag.text = "LEVEL %d" % max_lvl
		lvl_tag.position = Vector2(90, play_y + 50)
		lvl_tag.size = Vector2(292, 18)
		lvl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lvl_tag.add_theme_font_override("font", UIFont.title(2))
		lvl_tag.add_theme_font_size_override("font_size", 11)
		lvl_tag.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 0.8))
		lvl_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(lvl_tag)
		var new_btn = Button.new()
		new_btn.text = "↺  NEW GAME"
		new_btn.size = Vector2(200, 40)
		new_btn.position = Vector2(140, play_y + 82)
		new_btn.flat = true
		new_btn.focus_mode = Control.FOCUS_NONE
		new_btn.add_theme_font_override("font", UIFont.title(2))
		new_btn.add_theme_font_size_override("font_size", 13)
		new_btn.add_theme_color_override("font_color", Color(0.62, 0.68, 0.9, 0.9))
		new_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		new_btn.pressed.connect(_on_play)
		ui.add_child(new_btn)

	# ── Uzun ekran: içerik ortalanır, üst butonlar en üstte (çentik payıyla) kalır ──
	ScreenUtil.shift_children(ui, ScreenUtil.center_offset(self), top_bar)
	var safe_top = ScreenUtil.safe_top(self)
	for n in top_bar:
		n.position.y += safe_top

	# ── Onboarding (sadece ilk açılışta) ──
	_show_onboarding_if_needed(ui)

func _show_onboarding_if_needed(ui: CanvasLayer):
	if FileAccess.file_exists("user://onboarding_done.dat"):
		return
	_show_onboarding(ui)

func _show_onboarding(ui: CanvasLayer):
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.96)
	overlay.name = "OnboardingOverlay"
	ui.add_child(overlay)

	var current_page = [0]
	var total_pages = 4

	var page_node = Node2D.new()
	page_node.name = "PageNode"
	overlay.add_child(page_node)

	var page_titles = [
		"TAP & HOLD to attract",
		"Hero follows the magnet!",
		"Reach the EXIT door!",
		"Collect 5 coins = +1 Life!"
	]
	var page_subs = [
		"Touch any magnet to activate it.\nYour hero will fly towards it.",
		"Switch between magnets\nto navigate through obstacles.",
		"Guide your hero into\nthe glowing portal to win!",
		"Every 5 coins you collect\ngives you an extra life!"
	]

	# Nokta indikatörleri
	var dots: Array = []
	for i in total_pages:
		var dot = ColorRect.new()
		dot.size = Vector2(10, 10)
		dot.position = Vector2(240 - (total_pages * 14) / 2 + i * 18, 756)
		dot.color = Color(1, 1, 1, 1) if i == 0 else Color(0.35, 0.35, 0.4, 0.8)
		overlay.add_child(dot)
		dots.append(dot)

	# SKIP butonu
	var skip_bg = ColorRect.new()
	skip_bg.size = Vector2(100, 40)
	skip_bg.position = Vector2(366, 14)
	skip_bg.color = Color(0.12, 0.12, 0.18, 0.9)
	overlay.add_child(skip_bg)
	var skip_btn = Button.new()
	skip_btn.text = "SKIP ▶▶"
	skip_btn.size = Vector2(100, 40)
	skip_btn.position = Vector2(366, 14)
	skip_btn.flat = true
	skip_btn.add_theme_font_size_override("font_size", 14)
	skip_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	overlay.add_child(skip_btn)

	# NEXT butonu
	var next_bg = Node2D.new()
	next_bg.name = "NextBg"
	next_bg.set_script(_get_ob_panel_script(Color(0.0, 0.85, 1.0), 200, 56))
	next_bg.position = Vector2(140, 778)
	overlay.add_child(next_bg)
	var next_btn = Button.new()
	next_btn.name = "NextBtn"
	next_btn.size = Vector2(200, 56)
	next_btn.position = Vector2(140, 778)
	next_btn.flat = true
	next_btn.text = "NEXT  ▶"
	next_btn.add_theme_font_size_override("font_size", 20)
	next_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	overlay.add_child(next_btn)

	var finish_ob = func():
		var f = FileAccess.open("user://onboarding_done.dat", FileAccess.WRITE)
		if f:
			f.store_8(1)
			f.close()
		var tw = overlay.create_tween()
		tw.tween_property(overlay, "modulate:a", 0.0, 0.3)
		tw.tween_callback(overlay.queue_free)

	var show_page = func(page: int):
		for c in page_node.get_children():
			c.queue_free()
		for i in dots.size():
			dots[i].color = Color(1, 1, 1, 1) if i == page else Color(0.35, 0.35, 0.4, 0.8)

		# Animasyon
		var anim = Node2D.new()
		anim.set_script(_get_ob_anim_script(page))
		anim.position = Vector2(240, 320)
		page_node.add_child(anim)

		# Başlık
		var tlbl = Label.new()
		tlbl.text = page_titles[page]
		tlbl.size = Vector2(420, 50)
		tlbl.position = Vector2(30, 530)
		tlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tlbl.add_theme_font_size_override("font_size", 26)
		tlbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
		tlbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.4, 0.8, 0.8))
		tlbl.add_theme_constant_override("shadow_outline_size", 8)
		page_node.add_child(tlbl)

		# Alt açıklama
		var slbl = Label.new()
		slbl.text = page_subs[page]
		slbl.size = Vector2(400, 80)
		slbl.position = Vector2(40, 590)
		slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slbl.add_theme_font_size_override("font_size", 17)
		slbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.9))
		page_node.add_child(slbl)

		# NEXT / START güncelle
		var nb = overlay.get_node_or_null("NextBtn")
		if nb:
			nb.text = "LET'S GO  ▶" if page == total_pages - 1 else "NEXT  ▶"

	ScreenUtil.shift_children(overlay, ScreenUtil.center_offset(self), [skip_bg, skip_btn])
	var ob_top = ScreenUtil.safe_top(self)
	skip_bg.position.y += ob_top
	skip_btn.position.y += ob_top

	show_page.call(0)

	skip_btn.pressed.connect(func(): finish_ob.call())
	next_btn.pressed.connect(func():
		if current_page[0] < total_pages - 1:
			current_page[0] += 1
			show_page.call(current_page[0])
		else:
			finish_ob.call()
	)

func _get_ob_panel_script(accent: Color, w: float, h: float) -> GDScript:
	var s = GDScript.new()
	var r = accent.r; var g = accent.g; var b = accent.b
	s.source_code = """
extends Node2D
var time: float = 0.0
func _process(delta):
	time += delta
	queue_redraw()
func _draw():
	var accent = Color(%f, %f, %f, 1.0)
	var pulse = 0.6 + sin(time * 2.0) * 0.25
	var w = %f; var h = %f
	draw_rect(Rect2(0,0,w,h), Color(0.04,0.05,0.1,0.92))
	draw_rect(Rect2(0,0,w,h), Color(accent.r,accent.g,accent.b,0.07))
	for cx in [3.0, w-3.0]:
		for cy in [3.0, h-3.0]:
			draw_circle(Vector2(cx,cy), 1.4, Color(accent.r,accent.g,accent.b,0.7))
	draw_rect(Rect2(0,0,w,2), Color(accent.r,accent.g,accent.b,0.5+pulse*0.3))
	draw_rect(Rect2(0,h-2,w,2), Color(accent.r,accent.g,accent.b,0.25))
	draw_rect(Rect2(0,0,2,h), Color(accent.r,accent.g,accent.b,0.4))
	draw_rect(Rect2(w-2,0,2,h), Color(accent.r,accent.g,accent.b,0.4))
""" % [r, g, b, w, h]
	s.reload()
	return s

func _get_ob_anim_script(page: int) -> GDScript:
	var s = GDScript.new()
	var p = page
	s.source_code = """
extends Node2D
var time: float = 0.0
var magnet_vis: Node2D = null
var player_vis: Node2D = null
var exit_vis: Node2D = null

func _ready():
	var page = %d
	if page == 0:
		# Gerçek magnet görseli
		magnet_vis = Node2D.new()
		magnet_vis.set_script(load("res://scripts/MagnetVisual.gd"))
		magnet_vis.set_meta("level_color", Color(0.0, 0.7, 1.0))
		magnet_vis.position = Vector2(0, -80)
		magnet_vis.scale = Vector2(1.8, 1.8)
		add_child(magnet_vis)
		# Gerçek hero görseli
		player_vis = Node2D.new()
		player_vis.set_script(load("res://scripts/PlayerVisual.gd"))
		player_vis.position = Vector2(0, 100)
		player_vis.scale = Vector2(1.5, 1.5)
		add_child(player_vis)
	elif page == 1:
		# Sol magnet
		var mag_l = Node2D.new()
		mag_l.set_script(load("res://scripts/MagnetVisual.gd"))
		mag_l.set_meta("level_color", Color(0.0, 0.7, 1.0))
		mag_l.position = Vector2(-120, -60)
		mag_l.scale = Vector2(1.3, 1.3)
		add_child(mag_l)
		# Sağ magnet
		var mag_r = Node2D.new()
		mag_r.set_script(load("res://scripts/MagnetVisual.gd"))
		mag_r.set_meta("level_color", Color(0.8, 0.3, 1.0))
		mag_r.position = Vector2(120, -60)
		mag_r.scale = Vector2(1.3, 1.3)
		add_child(mag_r)
		# Hero
		player_vis = Node2D.new()
		player_vis.set_script(load("res://scripts/PlayerVisual.gd"))
		player_vis.position = Vector2(0, 80)
		player_vis.scale = Vector2(1.5, 1.5)
		add_child(player_vis)
	elif page == 2:
		# Gerçek exit portal
		exit_vis = Node2D.new()
		exit_vis.set_script(load("res://scripts/ExitVisual.gd"))
		exit_vis.position = Vector2(0, -60)
		exit_vis.scale = Vector2(1.4, 1.4)
		add_child(exit_vis)
		# Hero
		player_vis = Node2D.new()
		player_vis.set_script(load("res://scripts/PlayerVisual.gd"))
		player_vis.position = Vector2(0, 100)
		player_vis.scale = Vector2(1.5, 1.5)
		add_child(player_vis)

func _process(delta):
	time += delta
	queue_redraw()
	var page = %d
	if page == 0 and player_vis and is_instance_valid(player_vis):
		# Hero yukarı doğru sallanıyor
		player_vis.position.y = 100 - sin(time * 1.5) * 20
	elif page == 1 and player_vis and is_instance_valid(player_vis):
		# Hero iki magnet arasında gidip geliyor
		player_vis.position.x = sin(time * 0.8) * 80
		player_vis.position.y = 80 - abs(sin(time * 0.8)) * 40
	elif page == 2 and player_vis and is_instance_valid(player_vis):
		# Hero portala yaklaşıyor ve küçülüyor
		var ep = (sin(time * 0.9) + 1.0) / 2.0
		player_vis.position.y = 100 - ep * 140
		player_vis.scale = Vector2(1.5 - ep * 1.0, 1.5 - ep * 1.0)
		player_vis.modulate.a = 1.0 - ep * 0.8

func _draw():
	var page = %d
	var gold = Color(1.0, 0.8, 0.0)
	var cyan = Color(0.0, 0.85, 1.0)
	var pulse = 0.5 + sin(time * 2.0) * 0.5
	if page == 0:
		# Parmak dokunma ikonu
		var fy = 115 + sin(time * 2.5) * 6
		draw_circle(Vector2(80, fy), 16, Color(0.9, 0.78, 0.65, 0.9))
		draw_circle(Vector2(80, fy), 10, Color(1.0, 0.88, 0.75, 0.9))
		draw_circle(Vector2(80, fy), 22, Color(1.0, 1.0, 1.0, 0.18 * pulse))
		# Çekim oku (yukarı)
		var ay = 50 - sin(time * 2.0) * 10
		draw_line(Vector2(0, ay + 20), Vector2(0, ay), Color(gold.r, gold.g, gold.b, 0.9), 3.0)
		draw_line(Vector2(-8, ay + 12), Vector2(0, ay), Color(gold.r, gold.g, gold.b, 0.9), 3.0)
		draw_line(Vector2(8, ay + 12), Vector2(0, ay), Color(gold.r, gold.g, gold.b, 0.9), 3.0)
	elif page == 1:
		# Yön okları
		var ax = sin(time * 0.8) * 80
		var active_side = 1 if ax > 0 else -1
		for i in 3:
			var oy = -10 + i * 16
			var ox = active_side * (30 + i * 10)
			draw_line(Vector2(ox, oy), Vector2(ox + active_side * 14, oy), Color(gold.r, gold.g, gold.b, 0.7), 2.0)
			draw_line(Vector2(ox + active_side * 14, oy), Vector2(ox + active_side * 8, oy - 6), Color(gold.r, gold.g, gold.b, 0.7), 2.0)
			draw_line(Vector2(ox + active_side * 14, oy), Vector2(ox + active_side * 8, oy + 6), Color(gold.r, gold.g, gold.b, 0.7), 2.0)
	elif page == 3:
		# 5 coin = 1 can animasyonu
		# Üstte 5 coin yan yana
		var coin_collected = int(fmod(time * 1.2, 6.0))  # sırayla toplanan coin sayısı
		for i in 5:
			var cx2 = -90 + i * 45
			var cy2 = -90.0
			var collected = i < coin_collected
			# Coin dairesi
			var coin_pulse = 0.7 + sin(time * 3.0 + i * 0.8) * 0.3
			if collected:
				draw_circle(Vector2(cx2, cy2), 18, Color(gold.r, gold.g, gold.b, 0.9))
				draw_circle(Vector2(cx2, cy2), 12, Color(1.0, 0.95, 0.4, 0.9))
				draw_circle(Vector2(cx2, cy2), 6, Color(1.0, 1.0, 0.7, 0.9))
				# Üstüne tik
				draw_line(Vector2(cx2-5, cy2), Vector2(cx2-1, cy2+6), Color(0.3,0.2,0.0,1.0), 2.5)
				draw_line(Vector2(cx2-1, cy2+6), Vector2(cx2+6, cy2-5), Color(0.3,0.2,0.0,1.0), 2.5)
			else:
				draw_circle(Vector2(cx2, cy2), 18, Color(gold.r, gold.g, gold.b, 0.25))
				draw_circle(Vector2(cx2, cy2), 12, Color(gold.r, gold.g, gold.b, 0.15))
				# $ sembolü
				draw_line(Vector2(cx2, cy2-6), Vector2(cx2, cy2+6), Color(gold.r,gold.g,gold.b,0.5*coin_pulse), 1.5)

		# Ok aşağıya (5 coin → can)
		if coin_collected >= 5:
			var arr_pulse = 0.5 + sin(time * 4.0) * 0.5
			draw_line(Vector2(0, -55), Vector2(0, -20), Color(gold.r, gold.g, gold.b, arr_pulse), 3.0)
			draw_line(Vector2(-8, -28), Vector2(0, -20), Color(gold.r, gold.g, gold.b, arr_pulse), 3.0)
			draw_line(Vector2(8, -28), Vector2(0, -20), Color(gold.r, gold.g, gold.b, arr_pulse), 3.0)

		# Altta can gösterimi (kalpler)
		var base_lives = 3
		var bonus = 1 if coin_collected >= 5 else 0
		for i in 5:
			var hx = -90 + i * 45
			var hy = 30.0
			var has_life = i < base_lives + bonus
			var is_new = i == base_lives and bonus == 1
			# Kalp şekli
			if has_life:
				var hp = 0.7 + sin(time * 2.0 + i) * 0.3 if is_new else 0.85
				var hcol = Color(1.0, 0.3, 0.4, hp) if is_new else Color(1.0, 0.25, 0.35, 0.85)
				# Kalp - iki daire + üçgen
				draw_circle(Vector2(hx - 5, hy - 4), 8, hcol)
				draw_circle(Vector2(hx + 5, hy - 4), 8, hcol)
				var heart = PackedVector2Array([Vector2(hx-13,hy-4), Vector2(hx,hy+10), Vector2(hx+13,hy-4)])
				draw_colored_polygon(heart, hcol)
				if is_new:
					draw_circle(Vector2(hx, hy), 20, Color(1.0, 0.3, 0.4, 0.15 + sin(time*3.0)*0.1))
					# +1 yazısı efekti
					var plus_y = hy - 30 - sin(time*2.0)*5
					draw_line(Vector2(hx, plus_y-6), Vector2(hx, plus_y+6), Color(1.0,0.3,0.4,0.9), 2.5)
					draw_line(Vector2(hx-6, plus_y), Vector2(hx+6, plus_y), Color(1.0,0.3,0.4,0.9), 2.5)
			else:
				draw_circle(Vector2(hx - 5, hy - 4), 8, Color(0.4,0.3,0.3,0.35))
				draw_circle(Vector2(hx + 5, hy - 4), 8, Color(0.4,0.3,0.3,0.35))
				var heart2 = PackedVector2Array([Vector2(hx-13,hy-4), Vector2(hx,hy+10), Vector2(hx+13,hy-4)])
				draw_colored_polygon(heart2, Color(0.4,0.3,0.3,0.35))
""" % [p, p, p]
	s.reload()
	return s
func _update_sound_btn():
	var ui = get_node_or_null("UI")
	if not ui:
		return
	var vis = ui.get_node_or_null("SoundVis")
	if vis and vis.has_method("setup"):
		vis.setup(SoundManager.is_on())
	var lbl = ui.get_node_or_null("SoundLbl")
	if lbl:
		if SoundManager.is_on():
			lbl.text = "SOUND ON"
			lbl.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 1.0))
		else:
			lbl.text = "SOUND OFF"
			lbl.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 0.8))

func _on_sound_toggle():
	SoundManager.toggle()
	_update_sound_btn()
	if music_player:
		if SoundManager.is_on():
			music_player.play()
		else:
			music_player.stop()

func _process(delta):
	time += delta
	if is_instance_valid(play_btn):
		var glow = 0.85 + sin(time * 3.0) * 0.15
		play_btn.add_theme_color_override("font_color", Color(0.0, glow, 1.0, 1.0))
	if is_instance_valid(title_lbl):
		var s = 1.0 + sin(time * 1.8) * 0.018
		title_lbl.scale = Vector2(s, s)
		title_lbl.pivot_offset = Vector2(240, 36)

# Reklamla açılan kahramanın (BLAZE, POLARIS) kilit açma penceresi: 3 ödüllü reklam, her biri
# ayrı ayrı oyuncunun isteğiyle izlenir. İlerleme her ödülde kaydedilir; pencere kapatılsa da kaybolmaz.
func _show_ad_unlock(ui: CanvasLayer, hid: int, accent: Color):
	var required = HeroManager.ads_required(hid)
	var hname = HeroManager.AD_HEROES[hid]["name"]
	var ga_name = HeroManager.HERO_NAMES[hid]
	var icon = "🔥" if hid == HeroManager.BLAZE_ID else "🧲"
	var blurb = {HeroManager.BLAZE_ID: "Crimson armor, a crest of flames\nand jet boots that roar to life.",
		HeroManager.POLARIS_ID: "Living magnetic field: hovers on\nits own field, compass in its heart."}.get(hid, "")

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.9)
	ui.add_child(overlay)

	var box = ColorRect.new()
	box.size = Vector2(360, 470)
	box.position = Vector2(60, 190)
	box.color = Color(accent.r * 0.07, accent.g * 0.05, accent.b * 0.08 + 0.02, 0.98)
	overlay.add_child(box)
	var box_top = ColorRect.new()
	box_top.size = Vector2(360, 3)
	box_top.position = Vector2(60, 190)
	box_top.color = accent
	overlay.add_child(box_top)

	var title = Label.new()
	title.text = "%s UNLOCK %s" % [icon, hname]
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 206
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", accent.lightened(0.25))
	title.add_theme_color_override("font_shadow_color", Color(accent.r * 0.4, accent.g * 0.3, accent.b * 0.4, 0.8))
	title.add_theme_constant_override("shadow_outline_size", 8)
	overlay.add_child(title)

	var preview = Node2D.new()
	preview.set_script(load("res://scripts/PlayerVisual.gd"))
	preview.preview_hero = hid
	preview.position = Vector2(240, 318)
	preview.scale = Vector2(2.0, 2.0)
	overlay.add_child(preview)

	var desc = Label.new()
	desc.text = "%s\nWatch %d short ads to unlock %s forever!" % [blurb, required, hname]
	desc.set_anchors_preset(Control.PRESET_TOP_WIDE)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.position.y = 390
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.85, 0.8, 0.8))
	overlay.add_child(desc)

	# 3 parçalı ilerleme çubuğu
	var seg_w = 92.0
	var seg_gap = 10.0
	var seg_x = 240.0 - (seg_w * required + seg_gap * (required - 1)) / 2.0
	var segments: Array = []
	for k in required:
		var seg = ColorRect.new()
		seg.size = Vector2(seg_w, 14)
		seg.position = Vector2(seg_x + k * (seg_w + seg_gap), 466)
		overlay.add_child(seg)
		segments.append(seg)

	var prog_lbl = Label.new()
	prog_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog_lbl.position.y = 484
	prog_lbl.add_theme_font_size_override("font_size", 16)
	prog_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	overlay.add_child(prog_lbl)

	var status = Label.new()
	status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.position.y = 510
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 0.9))
	overlay.add_child(status)

	var watch_bg = ColorRect.new()
	watch_bg.size = Vector2(280, 60)
	watch_bg.position = Vector2(100, 538)
	watch_bg.color = Color(accent.r * 0.5, accent.g * 0.4, accent.b * 0.5, 1.0)
	overlay.add_child(watch_bg)
	var watch_btn = Button.new()
	watch_btn.size = Vector2(280, 60)
	watch_btn.position = Vector2(100, 538)
	watch_btn.flat = true
	watch_btn.add_theme_font_size_override("font_size", 22)
	watch_btn.add_theme_color_override("font_color", accent.lightened(0.55))
	overlay.add_child(watch_btn)

	var close_btn = Button.new()
	close_btn.text = "✕  CLOSE"
	close_btn.size = Vector2(160, 44)
	close_btn.position = Vector2(160, 608)
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.6))
	close_btn.pressed.connect(func(): overlay.queue_free())
	overlay.add_child(close_btn)

	var refresh = func():
		var done = HeroManager.ads_watched(hid)
		for k in segments.size():
			segments[k].color = accent if k < done else Color(0.25, 0.15, 0.15, 1.0)
		prog_lbl.text = "%d / %d" % [done, required]
		watch_btn.text = "🎬  WATCH AD  (%d/%d)" % [min(done + 1, required), required]

	watch_btn.pressed.connect(func():
		if not AdManager.is_rewarded_ad_ready():
			status.text = "Ad is loading… try again in a moment"
			AdManager.show_rewarded_ad(func(_earned: bool): pass)  # yüklemeyi tetikler
			return
		watch_btn.disabled = true
		status.text = ""
		AdManager.show_rewarded_ad(func(earned: bool):
			# İlerleme pencere kapatılmış olsa bile kaydedilir
			if earned:
				HeroManager.add_ad_view(hid)
				AnalyticsManager.design_event("HeroUnlock:%s:Ad%d" % [ga_name, HeroManager.ads_watched(hid)])
				if HeroManager.is_ad_hero_unlocked(hid):
					AnalyticsManager.design_event("HeroUnlock:%s:Unlocked" % ga_name)
					HeroManager.selected_hero = hid
					HeroManager.save_hero(hid)
					Progress.on_hero_unlocked()
			if not is_instance_valid(overlay):
				return
			watch_btn.disabled = false
			refresh.call()
			if HeroManager.is_ad_hero_unlocked(hid):
				status.text = "%s %s UNLOCKED!" % [icon, hname]
				status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
				watch_btn.visible = false
				watch_bg.visible = false
				get_tree().create_timer(1.3).timeout.connect(func(): get_tree().reload_current_scene())
			elif earned:
				var left = required - HeroManager.ads_watched(hid)
				status.text = "Nice! %d more to go" % left
			else:
				status.text = "Watch the whole ad to count it"
		)
	)

	refresh.call()
	ScreenUtil.shift_children(overlay, ScreenUtil.center_offset(self))

# Ödüller (Progress.AWARDS): açılanlar parlak + tarih, kilitliler soluk. Tamamen yerel.
func _show_awards(ui: CanvasLayer):
	var vh = ScreenUtil.viewport_height(self)
	var top = ScreenUtil.safe_top(self)
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.02, 0.95)
	ui.add_child(overlay)
	var title = Label.new()
	title.text = "🏆 AWARDS"
	title.position = Vector2(0, 18 + top)
	title.size = Vector2(480, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UIFont.title(3))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.9))
	title.add_theme_color_override("font_shadow_color", Color(0.6, 0.1, 0.4, 0.8))
	title.add_theme_constant_override("shadow_outline_size", 8)
	overlay.add_child(title)
	var sub = Label.new()
	var best = int(Progress.data["best_streak"])
	sub.text = "%d / %d UNLOCKED   ·   BEST STREAK %d DAY%s" % [Progress.unlocked_count(), Progress.AWARDS.size(), best, "" if best == 1 else "S"]
	sub.position = Vector2(0, 60 + top)
	sub.size = Vector2(480, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UIFont.title(1))
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.95, 0.9))
	overlay.add_child(sub)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 92 + top)
	scroll.size = Vector2(480, vh - 92 - top - 66)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	var list = VBoxContainer.new()
	list.custom_minimum_size = Vector2(480, 0)
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for a in Progress.AWARDS:
		var got = Progress.is_unlocked(a["id"])
		var row = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.08, 0.2, 0.95) if got else Color(0.06, 0.06, 0.1, 0.9)
		sb.border_color = Color(1.0, 0.7, 0.3, 0.7) if got else Color(0.25, 0.25, 0.35, 0.6)
		sb.border_width_left = 3
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		row.add_theme_stylebox_override("panel", sb)
		row.custom_minimum_size = Vector2(440, 0)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_child(row)
		list.add_child(margin)
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)
		var icon = Label.new()
		icon.text = a["icon"] if got else "🔒"
		icon.add_theme_font_size_override("font_size", 26)
		if not got:
			icon.modulate = Color(1, 1, 1, 0.45)
		h.add_child(icon)
		var col = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 0)
		h.add_child(col)
		var t = Label.new()
		t.text = a["title"]
		t.add_theme_font_override("font", UIFont.title(1))
		t.add_theme_font_size_override("font_size", 14)
		t.add_theme_color_override("font_color", Color(1, 1, 1) if got else Color(0.6, 0.6, 0.72))
		col.add_child(t)
		var d = Label.new()
		d.text = a["desc"]
		d.add_theme_font_size_override("font_size", 13)
		d.add_theme_color_override("font_color", Color(0.75, 0.78, 0.95, 0.9) if got else Color(0.45, 0.45, 0.55))
		col.add_child(d)
		if got:
			var date = Label.new()
			date.text = str(Progress.data["awards"][a["id"]]).substr(5, 5)
			date.add_theme_font_size_override("font_size", 11)
			date.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4, 0.8))
			h.add_child(date)
	var close_bg = ColorRect.new()
	close_bg.size = Vector2(200, 50)
	close_bg.position = Vector2(140, vh - 58)
	close_bg.color = Color(0.2, 0.05, 0.18, 1.0)
	overlay.add_child(close_bg)
	var close_btn = Button.new()
	close_btn.text = "✕  CLOSE"
	close_btn.size = Vector2(200, 50)
	close_btn.position = Vector2(140, vh - 58)
	close_btn.flat = true
	close_btn.add_theme_font_override("font", UIFont.title(2))
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.9))
	close_btn.pressed.connect(func(): overlay.queue_free())
	overlay.add_child(close_btn)

func _show_leaderboard(ui: CanvasLayer):
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	ui.add_child(overlay)
	var title = Label.new()
	title.text = "🏆 LEADERBOARD"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 180
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	title.add_theme_color_override("font_shadow_color", Color(0.5, 0.3, 0.0, 0.8))
	title.add_theme_constant_override("shadow_outline_size", 8)
	overlay.add_child(title)
	var lb_bg = ColorRect.new()
	lb_bg.size = Vector2(360, 300)
	lb_bg.position = Vector2(60, 230)
	lb_bg.color = Color(0.04, 0.04, 0.16, 0.98)
	overlay.add_child(lb_bg)
	var lb_top = ColorRect.new()
	lb_top.size = Vector2(360, 3)
	lb_top.position = Vector2(60, 230)
	lb_top.color = Color(1.0, 0.8, 0.0, 0.8)
	overlay.add_child(lb_top)
	var lb_bot = ColorRect.new()
	lb_bot.size = Vector2(360, 3)
	lb_bot.position = Vector2(60, 527)
	lb_bot.color = Color(1.0, 0.8, 0.0, 0.8)
	overlay.add_child(lb_bot)
	var entries = Leaderboard.load_entries()
	var medals = ["🥇", "🥈", "🥉", "4.", "5."]
	if entries.size() == 0:
		var empty = Label.new()
		empty.text = "No scores yet!\nPlay to set a record 🎮"
		empty.set_anchors_preset(Control.PRESET_TOP_WIDE)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.position.y = 340
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7, 0.8))
		overlay.add_child(empty)
	else:
		for i in min(entries.size(), 5):
			var e = entries[i]
			var row_y = 244 + i * 54
			var is_top = i == 0
			var row_bg = ColorRect.new()
			row_bg.size = Vector2(354, 46)
			row_bg.position = Vector2(63, row_y)
			row_bg.color = Color(0.12, 0.1, 0.0, 1.0) if is_top else Color(0.06, 0.06, 0.14, 0.8)
			overlay.add_child(row_bg)
			var medal = Label.new()
			medal.text = medals[i]
			medal.position = Vector2(72, row_y + 10)
			medal.add_theme_font_size_override("font_size", 22)
			overlay.add_child(medal)
			var score_lbl = Label.new()
			score_lbl.text = "%d coins" % e["score"]
			score_lbl.position = Vector2(108, row_y + 10)
			score_lbl.size = Vector2(150, 32)
			score_lbl.add_theme_font_size_override("font_size", 20)
			score_lbl.add_theme_color_override("font_color",
				Color(1.0, 0.85, 0.0) if is_top else Color(0.75, 0.75, 0.95))
			overlay.add_child(score_lbl)
			var lvl_lbl2 = Label.new()
			lvl_lbl2.text = "Lvl %d" % e["level"]
			lvl_lbl2.position = Vector2(268, row_y + 12)
			lvl_lbl2.size = Vector2(60, 28)
			lvl_lbl2.add_theme_font_size_override("font_size", 16)
			lvl_lbl2.add_theme_color_override("font_color", Color(0.5, 0.5, 0.8, 0.8))
			overlay.add_child(lvl_lbl2)
			var date_lbl = Label.new()
			date_lbl.text = e["date"].substr(5, 5)
			date_lbl.position = Vector2(330, row_y + 14)
			date_lbl.size = Vector2(80, 24)
			date_lbl.add_theme_font_size_override("font_size", 13)
			date_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.6, 0.7))
			overlay.add_child(date_lbl)
	var close_bg = ColorRect.new()
	close_bg.size = Vector2(200, 58)
	close_bg.position = Vector2(140, 560)
	close_bg.color = Color(0.1, 0.05, 0.3, 1.0)
	overlay.add_child(close_bg)
	var close_line = ColorRect.new()
	close_line.size = Vector2(200, 3)
	close_line.position = Vector2(140, 560)
	close_line.color = Color(0.6, 0.3, 1.0, 0.8)
	overlay.add_child(close_line)
	var close_btn = Button.new()
	close_btn.text = "✕  CLOSE"
	close_btn.size = Vector2(200, 58)
	close_btn.position = Vector2(140, 560)
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
	close_btn.pressed.connect(func(): overlay.queue_free())
	overlay.add_child(close_btn)
	ScreenUtil.shift_children(overlay, ScreenUtil.center_offset(self))

func _show_level_select(ui: CanvasLayer):
	var max_lvl = _load_max_level()
	var all_stars = _load_all_stars()
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.93)
	ui.add_child(overlay)

	var title = Label.new()
	# Uzun ekranda liste aşağı uzar, CLOSE her zaman en altta kalır
	var vh = ScreenUtil.viewport_height(self)
	var top = ScreenUtil.safe_top(self)

	title.text = "🗺️ SELECT LEVEL"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 14 + top
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.3, 0.1, 0.8))
	title.add_theme_constant_override("shadow_outline_size", 6)
	overlay.add_child(title)

	var sub = Label.new()
	sub.text = "Reached: Level %d / 50" % max_lvl
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position.y = 46 + top
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6, 0.8))
	overlay.add_child(sub)

	var level_emojis = ["🔰","⚡","🔥","💎","🌊","🌙","🎯","🚀","👾","🏆",
						"💥","🎮","🌀","☄️","🔮","💀","🌟","⚔️","🧨","🎖️",
						"🔵","🟣","🔴","🟢","🟡","🌑","🌒","🌓","🌔","🌕",
						"🧊","🌋","🌪️","⚗️","🔬","🧬","🛸","🌈","🎆","💫",
						"🦾","🤖","👁️","🧿","🎯","⚡","🔱","🏴","☠️","🎖️"]

	var btn_w = 86.0
	var btn_h = 72.0
	var cols = 5
	var gap_x = 8.0
	var gap_y = 6.0
	var total_w = cols * btn_w + (cols - 1) * gap_x
	var start_x = (480 - total_w) / 2

	var scroll = ScrollContainer.new()
	scroll.size = Vector2(480, vh - 68 - top - 60)
	scroll.position = Vector2(0, 68 + top)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)

	var content = Control.new()
	var rows = int(ceil(50.0 / cols))
	content.custom_minimum_size = Vector2(480, rows * (btn_h + gap_y) + 10)
	scroll.add_child(content)

	for i in 50:
		var col = i % cols
		var row = i / cols
		var bx = start_x + col * (btn_w + gap_x)
		var by = row * (btn_h + gap_y) + 4
		var lvl = i + 1
		var is_unlocked = lvl <= max_lvl
		var lvl_stars = all_stars[i] if is_unlocked else 0

		var bbg = ColorRect.new()
		bbg.size = Vector2(btn_w, btn_h)
		bbg.position = Vector2(bx, by)
		bbg.color = Color(0.0, 0.15, 0.08, 1.0) if is_unlocked else Color(0.06, 0.06, 0.1, 1.0)
		content.add_child(bbg)

		var btop = ColorRect.new()
		btop.size = Vector2(btn_w, 3)
		btop.position = Vector2(bx, by)
		btop.color = Color(0.3, 1.0, 0.4, 0.8) if is_unlocked else Color(0.2, 0.2, 0.25, 0.5)
		content.add_child(btop)

		var emoji_lbl = Label.new()
		emoji_lbl.text = level_emojis[i] if i < level_emojis.size() else "🎮"
		emoji_lbl.position = Vector2(bx + btn_w/2 - 12, by + 4)
		emoji_lbl.add_theme_font_size_override("font_size", 18)
		if not is_unlocked:
			emoji_lbl.modulate = Color(1, 1, 1, 0.25)
		content.add_child(emoji_lbl)

		var num_lbl = Label.new()
		num_lbl.text = str(lvl) if is_unlocked else "🔒"
		num_lbl.size = Vector2(btn_w, 18)
		num_lbl.position = Vector2(bx, by + 26)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 12)
		num_lbl.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.5) if is_unlocked else Color(0.3, 0.3, 0.4, 0.5))
		content.add_child(num_lbl)

		var star_text = ""
		for s in 3:
			star_text += "⭐" if s < lvl_stars else "☆"
		var star_lbl = Label.new()
		star_lbl.text = star_text
		star_lbl.size = Vector2(btn_w, 18)
		star_lbl.position = Vector2(bx, by + btn_h - 20)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.add_theme_font_size_override("font_size", 10)
		if lvl_stars == 0:
			star_lbl.modulate = Color(1, 1, 1, 0.3)
		content.add_child(star_lbl)

		var bbtn = Button.new()
		bbtn.size = Vector2(btn_w, btn_h)
		bbtn.position = Vector2(bx, by)
		bbtn.flat = true
		bbtn.text = ""
		if is_unlocked:
			var level_num = lvl
			bbtn.pressed.connect(func():
				overlay.queue_free()
				LevelTransition.flash_and_load("res://scenes/Level%d.tscn" % level_num)
			)
		content.add_child(bbtn)

	# CLOSE butonu scroll dışında sabit altta
	var close_bg = ColorRect.new()
	close_bg.size = Vector2(200, 50)
	close_bg.position = Vector2(140, vh - 54)
	close_bg.color = Color(0.05, 0.15, 0.05, 1.0)
	overlay.add_child(close_bg)
	var close_line2 = ColorRect.new()
	close_line2.size = Vector2(200, 3)
	close_line2.position = Vector2(140, vh - 54)
	close_line2.color = Color(0.3, 1.0, 0.4, 0.8)
	overlay.add_child(close_line2)
	var close_btn = Button.new()
	close_btn.text = "✕  CLOSE"
	close_btn.size = Vector2(200, 50)
	close_btn.position = Vector2(140, vh - 54)
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	close_btn.pressed.connect(func(): overlay.queue_free())
	overlay.add_child(close_btn)

# Üst çubuk butonu: buton + ikon + etiket. Dönen: kaydırma için düğümler
func _top_button(ui: CanvasLayer, pos: Vector2, w: float, icon: String, accent: Color, text: String, cb: Callable) -> Array:
	var panel = Node2D.new()
	panel.set_script(_get_hud_button_script(icon, accent, w))
	panel.position = pos
	ui.add_child(panel)
	var lbl = Label.new()
	lbl.text = text
	lbl.size = Vector2(w, 18)
	lbl.position = pos + Vector2(0, 34)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", UIFont.title(1))
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", accent.lightened(0.15))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(lbl)
	var btn = Button.new()
	btn.size = Vector2(w, 56)
	btn.position = pos
	btn.flat = true
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(cb)
	ui.add_child(btn)
	return [panel, lbl, btn]

func _get_hud_button_script(icon_type: String, accent: Color, width: float = 90.0) -> GDScript:
	var s = GDScript.new()
	var r = accent.r
	var g = accent.g
	var b = accent.b
	var icon = icon_type
	s.source_code = """
extends Node2D
var time: float = 0.0
func _process(delta):
	time += delta
	queue_redraw()
func _draw():
	var accent = Color(%f, %f, %f, 1.0)
	var icon_type = "%s"
	var pulse = 0.6 + sin(time * 2.2) * 0.25
	var w = %f
	var h = 56.0
	draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.05, 0.1, 0.92))
	draw_rect(Rect2(0, 0, w, h), Color(accent.r, accent.g, accent.b, 0.06))
	for cx in [3.0, w - 3.0]:
		for cy in [3.0, h - 3.0]:
			draw_circle(Vector2(cx, cy), 1.6, Color(accent.r, accent.g, accent.b, 0.7))
	draw_rect(Rect2(0, 0, w, 2), Color(accent.r, accent.g, accent.b, 0.5 + pulse * 0.3))
	draw_rect(Rect2(0, h - 2, w, 2), Color(accent.r, accent.g, accent.b, 0.3))
	draw_rect(Rect2(0, 0, 2, h), Color(accent.r, accent.g, accent.b, 0.5 + pulse * 0.3))
	draw_rect(Rect2(w - 2, 0, 2, h), Color(accent.r, accent.g, accent.b, 0.3))
	var icon_c = Vector2(w / 2.0, 17)
	if icon_type == "trophy":
		draw_circle(icon_c + Vector2(0, -2), 8, Color(accent.r, accent.g, accent.b, 0.15 + pulse * 0.1))
		var cup = PackedVector2Array([
			Vector2(icon_c.x - 6, icon_c.y - 6), Vector2(icon_c.x + 6, icon_c.y - 6),
			Vector2(icon_c.x + 4, icon_c.y + 3), Vector2(icon_c.x - 4, icon_c.y + 3),
		])
		draw_colored_polygon(cup, accent)
		draw_arc(icon_c + Vector2(-7, -4), 3, PI * 0.3, PI * 1.7, 8, accent, 1.5)
		draw_arc(icon_c + Vector2(7, -4), 3, -PI * 0.3, -PI * 1.7, 8, accent, 1.5)
		draw_rect(Rect2(icon_c.x - 1.5, icon_c.y + 3, 3, 4), accent)
		draw_rect(Rect2(icon_c.x - 5, icon_c.y + 7, 10, 2), accent)
		draw_circle(icon_c + Vector2(-2, -3), 1.3, Color(1, 1, 1, 0.8))
	elif icon_type == "portal":
		draw_circle(icon_c, 9, Color(accent.r, accent.g, accent.b, 0.12 + pulse * 0.1))
		draw_arc(icon_c, 7, time * 2.0, time * 2.0 + TAU * 0.7, 16, accent, 2.0)
		draw_arc(icon_c, 7, time * 2.0 + PI, time * 2.0 + PI + TAU * 0.7, 16, Color(1, 1, 1, 0.5), 1.2)
		draw_circle(icon_c, 3.5, Color(accent.r, accent.g, accent.b, 0.7 + pulse * 0.3))
		draw_circle(icon_c, 1.6, Color(1, 1, 1, 0.8))
	elif icon_type == "podium":
		# skor tablosu: 1-2-3 kürsüsü
		draw_circle(icon_c, 9, Color(accent.r, accent.g, accent.b, 0.12 + pulse * 0.1))
		draw_rect(Rect2(icon_c.x - 3.5, icon_c.y - 6, 7, 13), accent)
		draw_rect(Rect2(icon_c.x - 11, icon_c.y - 1, 7, 8), Color(accent.r, accent.g, accent.b, 0.75))
		draw_rect(Rect2(icon_c.x + 4, icon_c.y + 2, 7, 5), Color(accent.r, accent.g, accent.b, 0.55))
		draw_circle(icon_c + Vector2(0, -10), 2.2, Color(1, 1, 1, 0.85))
""" % [r, g, b, icon, width]
	s.reload()
	return s

func _get_logo_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """
extends Node2D
var time: float = 0.0
func _process(delta):
	time += delta
	queue_redraw()
func _rrect(pos, size, radius, color, segments=3):
	var r = clamp(radius, 0.0, min(size.x, size.y) / 2.0)
	var x0 = pos.x
	var y0 = pos.y
	var x1 = pos.x + size.x
	var y1 = pos.y + size.y
	var pts = PackedVector2Array()
	var corners = [
		Vector2(x1 - r, y0 + r),
		Vector2(x1 - r, y1 - r),
		Vector2(x0 + r, y1 - r),
		Vector2(x0 + r, y0 + r),
	]
	var start_angles = [-PI / 2.0, 0.0, PI / 2.0, PI]
	for c in 4:
		var center = corners[c]
		var start_angle = start_angles[c]
		for i in range(segments + 1):
			var angle = start_angle + (PI / 2.0) * float(i) / float(segments)
			pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)
func _build_u_shape(outer_r, arm_w, arm_top, bottom_curve_y, segments=12):
	var inner_r = outer_r - arm_w
	var pts = PackedVector2Array()
	pts.append(Vector2(-outer_r, arm_top))
	pts.append(Vector2(-outer_r, bottom_curve_y))
	for i in range(segments + 1):
		var ang = PI - (PI * i / segments)
		pts.append(Vector2(cos(ang) * outer_r, bottom_curve_y + sin(ang) * outer_r))
	pts.append(Vector2(outer_r, arm_top))
	pts.append(Vector2(inner_r, arm_top))
	pts.append(Vector2(inner_r, bottom_curve_y))
	for i in range(segments + 1):
		var ang2 = (PI * i / segments)
		pts.append(Vector2(cos(ang2) * inner_r, bottom_curve_y + sin(ang2) * inner_r))
	pts.append(Vector2(-inner_r, arm_top))
	pts.append(Vector2(-outer_r, arm_top))
	return pts
func _draw_hologram_ring(center, color, alpha_mult):
	for i in 3:
		var ry = 3.0 - i * 0.5
		var rx = 13.0 - i * 2.0
		var a = (0.5 - i * 0.13) * alpha_mult
		var pts = PackedVector2Array()
		for s in 20:
			var ang = TAU * s / 20.0
			pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
		for s in pts.size():
			draw_line(pts[s], pts[(s + 1) % pts.size()], Color(color.r, color.g, color.b, a), 1.3)
	var cone = PackedVector2Array([
		center + Vector2(-7, 0), center + Vector2(7, 0),
		center + Vector2(2, -22), center + Vector2(-2, -22)
	])
	draw_colored_polygon(cone, Color(color.r, color.g, color.b, 0.18 * alpha_mult))
	draw_line(center + Vector2(0, 0), center + Vector2(0, -22), Color(color.r, color.g, color.b, 0.6 * alpha_mult), 1.5)
func _draw():
	var pulse = 0.5 + sin(time * 1.8) * 0.5
	var idle_breathe = 0.5 + sin(time * 1.8) * 0.5

	var metal = Color(0.42, 0.43, 0.48)
	var metal_dark = Color(0.22, 0.23, 0.27)
	var metal_light = Color(0.62, 0.63, 0.7)
	var carbon = Color(0.12, 0.12, 0.14)
	var red = Color(0.85, 0.15, 0.15)
	var blue = Color(0.15, 0.5, 0.95)
	var core_color = Color(0.4, 0.75, 1.0)
	var core_glow = Color(0.0, 0.7, 1.0)

	draw_circle(Vector2(0, -2), 50, Color(core_glow.r, core_glow.g, core_glow.b, 0.05 + idle_breathe * 0.05))
	draw_circle(Vector2(0, -2), 70, Color(0.0, 0.5, 1.0, 0.08 + pulse * 0.05))

	var outer_r = 17.0
	var arm_w = 9.0
	var arm_top = -28.0
	var bottom_curve_y = 4.0
	var u_body = _build_u_shape(outer_r, arm_w, arm_top, bottom_curve_y, 12)
	draw_colored_polygon(u_body, metal)

	var inner_r = outer_r - arm_w
	var shadow_pts = PackedVector2Array()
	for i in range(13):
		var ang3 = (PI * i / 12.0)
		shadow_pts.append(Vector2(cos(ang3) * inner_r, bottom_curve_y + sin(ang3) * inner_r))
	shadow_pts.append(Vector2(0, bottom_curve_y))
	draw_colored_polygon(shadow_pts, Color(metal_dark.r, metal_dark.g, metal_dark.b, 0.35))

	_rrect(Vector2(-outer_r, arm_top), Vector2(2.5, 24), 1.0, metal_light)
	_rrect(Vector2(outer_r - 2.5, arm_top), Vector2(2.5, 24), 1.0, metal_light)
	_rrect(Vector2(-13.5, arm_top + 5), Vector2(3, 18), 1.5, carbon)
	_rrect(Vector2(11.5, arm_top + 5), Vector2(3, 18), 1.5, carbon)
	draw_arc(Vector2(0, bottom_curve_y), outer_r - 1.0, PI * 1.05, PI * 1.95, 16,
		Color(metal_light.r, metal_light.g, metal_light.b, 0.3), 1.2)

	_rrect(Vector2(-19, arm_top - 9), Vector2(13, 11), 2.0, metal)
	_rrect(Vector2(6, arm_top - 9), Vector2(13, 11), 2.0, metal)
	draw_circle(Vector2(-12.5, arm_top - 4), 4.0, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2(-12.5, arm_top - 4), 3.0, red)
	draw_rect(Rect2(-14.5, arm_top - 4.6, 4, 1.2), Color(1, 0.8, 0.8, 0.9))
	draw_circle(Vector2(12.5, arm_top - 4), 4.0, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2(12.5, arm_top - 4), 3.0, blue)
	draw_rect(Rect2(10.5, arm_top - 6.6, 1.2, 4), Color(0.8, 0.9, 1, 0.9))
	draw_rect(Rect2(8.9, arm_top - 4.6, 4, 1.2), Color(0.8, 0.9, 1, 0.9))

	var holo_alpha = 0.55 + pulse * 0.35
	_draw_hologram_ring(Vector2(-12.5, arm_top - 9), red, holo_alpha)
	_draw_hologram_ring(Vector2(12.5, arm_top - 9), blue, holo_alpha)

	var gem_scale = 0.9 + pulse * 0.15
	var gem_r = 9.0 * gem_scale
	draw_circle(Vector2(0, -10), gem_r + 6, Color(core_glow.r, core_glow.g, core_glow.b, 0.18 + pulse * 0.12))
	var gem_pts = PackedVector2Array([
		Vector2(0, -10 - gem_r), Vector2(gem_r * 0.55, -10),
		Vector2(0, -10 + gem_r), Vector2(-gem_r * 0.55, -10),
	])
	draw_colored_polygon(gem_pts, Color(core_color.r, core_color.g, core_color.b, 0.9))
	draw_line(Vector2(0, -10 - gem_r), Vector2(0, -10 + gem_r), Color(1, 1, 1, 0.4), 0.8)
	draw_line(Vector2(-gem_r * 0.55, -10), Vector2(gem_r * 0.55, -10), Color(1, 1, 1, 0.4), 0.8)
	draw_circle(Vector2(0, -10), gem_r * 0.3, Color(1.0, 1.0, 1.0, 0.5))
	draw_arc(Vector2(0, -10), gem_r + 3, time * 1.3, time * 1.3 + TAU * 0.55, 16,
		Color(core_glow.r, core_glow.g, core_glow.b, 0.45), 1.3)

	for i in 6:
		var angle = -PI*0.35+i*PI*0.14
		var r1 = 56.0
		var r2 = 74.0+i*3
		var fade = (0.5-i*0.07)*pulse*1.4
		if fade > 0:
			draw_line(Vector2(cos(angle)*r1,sin(angle)*r1), Vector2(cos(angle)*r2,sin(angle)*r2), Color(0.0,0.9,1.0,fade), 2.0)
"""
	s.reload()
	return s

func _get_title_decor_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """
extends Node2D
var time: float = 0.0
var particles: Array = []
func _ready():
	for i in 14:
		particles.append({
			"angle": randf() * TAU,
			"radius": randf_range(140, 200),
			"speed": randf_range(0.08, 0.22) * (1 if randi() % 2 == 0 else -1),
			"size": randf_range(1.0, 2.4),
			"phase": randf() * TAU,
		})
func _process(delta):
	time += delta
	queue_redraw()
func _draw():
	var pulse = 0.5 + sin(time * 1.5) * 0.5
	draw_arc(Vector2(0, 0), 185, time * 0.12, time * 0.12 + TAU * 0.4, 40, Color(0.0, 0.7, 1.0, 0.12 + pulse * 0.06), 1.5)
	draw_arc(Vector2(0, 0), 185, time * 0.12 + PI, time * 0.12 + PI + TAU * 0.4, 40, Color(0.7, 0.3, 1.0, 0.1 + pulse * 0.05), 1.5)
	draw_arc(Vector2(0, 0), 150, -time * 0.18, -time * 0.18 + TAU * 0.25, 30, Color(0.0, 0.9, 1.0, 0.1), 1.0)
	for p in particles:
		var ang = p["angle"] + time * p["speed"]
		var r = p["radius"]
		var pos = Vector2(cos(ang) * r, sin(ang) * r * 0.4)
		var tw = 0.4 + sin(time * 2.0 + p["phase"]) * 0.3
		draw_circle(pos, p["size"], Color(0.4, 0.85, 1.0, tw * 0.5))
"""
	s.reload()
	return s

func _get_bg_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """
extends Node2D
var time: float = 0.0
var pts: Array = []
func _h() -> float:
	return get_viewport_rect().size.y
func _ready():
	for i in 50:
		pts.append({"pos":Vector2(randf()*480,randf()*_h()),"vel":Vector2(randf_range(-15,15),randf_range(-35,-8)),"life":randf()*6.0,"max_life":randf_range(4.0,9.0),"size":randf_range(1.5,3.5),"hue":randf_range(0.55,0.72)})
func _process(delta):
	time += delta
	for p in pts:
		p.life += delta
		p.pos += p.vel * delta
		if p.life >= p.max_life or p.pos.y < -5:
			p.pos = Vector2(randf()*480, _h() + 6)
			p.vel = Vector2(randf_range(-15,15),randf_range(-35,-8))
			p.life = 0.0
			p.max_life = randf_range(4.0,9.0)
	queue_redraw()
func _draw():
	var h = _h()
	draw_rect(Rect2(0,0,480,h), Color(0.03,0.02,0.12))
	for i in 8:
		draw_line(Vector2(i*68,0),Vector2(i*68,h),Color(0.0,0.4,1.0,0.04))
	for i in int(h / 68.0) + 1:
		draw_line(Vector2(0,i*68),Vector2(480,i*68),Color(0.0,0.4,1.0,0.04))
	for p in pts:
		var a = sin(p.life/p.max_life*PI)*0.7
		draw_circle(p.pos, p.size, Color.from_hsv(p.hue,0.8,1.0,a))
"""
	s.reload()
	return s

func _get_hero_preview_script(hero_id: int) -> GDScript:
	var s = GDScript.new()
	var hid = hero_id
	s.source_code = """
extends Node2D
var time: float = 0.0
func _process(delta):
	time += delta
	queue_redraw()
func _rrect(pos, size, radius, color, segments=3):
	var r = clamp(radius, 0.0, min(size.x, size.y) / 2.0)
	var x0 = pos.x
	var y0 = pos.y
	var x1 = pos.x + size.x
	var y1 = pos.y + size.y
	var pts = PackedVector2Array()
	var corners = [
		Vector2(x1 - r, y0 + r),
		Vector2(x1 - r, y1 - r),
		Vector2(x0 + r, y1 - r),
		Vector2(x0 + r, y0 + r),
	]
	var start_angles = [-PI / 2.0, 0.0, PI / 2.0, PI]
	for c in 4:
		var center = corners[c]
		var start_angle = start_angles[c]
		for i in range(segments + 1):
			var angle = start_angle + (PI / 2.0) * float(i) / float(segments)
			pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)
func _draw():
	var hid = %d
	if hid == 0:
		var armor = Color(0.52, 0.54, 0.7)
		var armor_dark = Color(0.3, 0.31, 0.44)
		var armor_light = Color(0.72, 0.74, 0.9)
		var visor_dark = Color(0.0, 0.0, 0.08, 0.95)
		var cyan = Color(0.0, 0.83, 1.0)
		_rrect(Vector2(-9, 8), Vector2(6, 12), 2.0, armor_dark)
		_rrect(Vector2(3, 8), Vector2(6, 12), 2.0, armor_dark)
		_rrect(Vector2(-11, 17), Vector2(9, 7), 2.5, armor)
		_rrect(Vector2(2, 17), Vector2(9, 7), 2.5, armor)
		var torso_pts = PackedVector2Array([
			Vector2(-13, -9), Vector2(13, -9),
			Vector2(11, 3), Vector2(8, 11),
			Vector2(-8, 11), Vector2(-11, 3),
		])
		draw_colored_polygon(torso_pts, armor)
		_rrect(Vector2(-13, -9), Vector2(26, 4), 2.0, armor_light)
		draw_circle(Vector2(-8, -5), 1.7, Color(0.15, 0.4, 0.85))
		draw_circle(Vector2(8, -5), 1.7, Color(0.85, 0.2, 0.2))
		_rrect(Vector2(-6, -2), Vector2(12, 2), 1.0, Color(cyan.r, cyan.g, cyan.b, 0.25))
		draw_circle(Vector2(0, 2), 5, Color(cyan.r, cyan.g, cyan.b, 0.7))
		draw_circle(Vector2(0, 2), 3, Color(1.0, 1.0, 1.0, 0.6))
		draw_circle(Vector2(-14, -7), 6.0, armor_dark)
		draw_circle(Vector2(-14, -8), 4.2, armor)
		draw_circle(Vector2(14, -7), 6.0, armor_dark)
		draw_circle(Vector2(14, -8), 4.2, armor)
		_rrect(Vector2(-19, -6), Vector2(7, 14), 3.0, armor)
		_rrect(Vector2(12, -6), Vector2(7, 14), 3.0, armor)
		draw_circle(Vector2(-15.5, 10), 4.2, armor_dark)
		draw_circle(Vector2(15.5, 10), 4.2, armor_dark)
		draw_circle(Vector2(-15.5, 10), 2.0, Color(cyan.r, cyan.g, cyan.b, 0.5))
		draw_circle(Vector2(15.5, 10), 2.0, Color(cyan.r, cyan.g, cyan.b, 0.5))
		_rrect(Vector2(-10, -25), Vector2(20, 17), 5.0, armor_dark)
		_rrect(Vector2(-10, -25), Vector2(20, 5), 4.0, armor_light)
		_rrect(Vector2(-12, -19), Vector2(2, 8), 1.0, armor)
		_rrect(Vector2(10, -19), Vector2(2, 8), 1.0, armor)
		_rrect(Vector2(-1, -32), Vector2(2, 8), 1.0, armor)
		var ant_size0 = 4 + sin(time * 3) * 0.8
		draw_circle(Vector2(0, -33), ant_size0, Color(cyan.r, cyan.g, cyan.b, 0.9))
		draw_circle(Vector2(0, -33), ant_size0 * 0.5, Color(1, 1, 1, 0.9))
		_rrect(Vector2(-8, -21), Vector2(16, 8), 3.0, visor_dark)
		draw_circle(Vector2(-4, -17), 3.2, Color(cyan.r, cyan.g, cyan.b, 0.9))
		draw_circle(Vector2(-4, -17), 1.8, Color(1, 1, 1, 0.85))
		draw_circle(Vector2(4, -17), 3.2, Color(cyan.r, cyan.g, cyan.b, 0.9))
		draw_circle(Vector2(4, -17), 1.8, Color(1, 1, 1, 0.85))
	elif hid == 1:
		var pink = Color(1.0, 0.4, 0.7)
		var light_pink = Color(1.0, 0.75, 0.88)
		var white = Color(0.97, 0.96, 1.0)
		var dark_pink = Color(0.85, 0.25, 0.55)
		_rrect(Vector2(-9, 8), Vector2(6, 12), 2.0, Color(0.9, 0.55, 0.75))
		_rrect(Vector2(3, 8), Vector2(6, 12), 2.0, Color(0.9, 0.55, 0.75))
		_rrect(Vector2(-11, 17), Vector2(9, 7), 3.0, light_pink)
		_rrect(Vector2(2, 17), Vector2(9, 7), 3.0, light_pink)
		var torso_pts1 = PackedVector2Array([
			Vector2(-13, -9), Vector2(13, -9),
			Vector2(11, 3), Vector2(8, 11),
			Vector2(-8, 11), Vector2(-11, 3),
		])
		draw_colored_polygon(torso_pts1, white)
		_rrect(Vector2(-13, -9), Vector2(26, 4), 2.0, Color(1.0, 0.7, 0.85, 0.85))
		draw_circle(Vector2(-3, -1), 4, pink)
		draw_circle(Vector2(3, -1), 4, pink)
		draw_circle(Vector2(0, 2), 4.5, pink)
		draw_circle(Vector2(0, 0), 3, Color(1, 1, 1, 0.7))
		draw_circle(Vector2(-14, -7), 6.0, light_pink)
		draw_circle(Vector2(-14, -8), 4.2, white)
		draw_circle(Vector2(14, -7), 6.0, light_pink)
		draw_circle(Vector2(14, -8), 4.2, white)
		_rrect(Vector2(-19, -6), Vector2(7, 14), 3.0, Color(0.9, 0.65, 0.8))
		_rrect(Vector2(12, -6), Vector2(7, 14), 3.0, Color(0.9, 0.65, 0.8))
		draw_circle(Vector2(-15.5, 10), 4.2, light_pink)
		draw_circle(Vector2(15.5, 10), 4.2, light_pink)
		draw_circle(Vector2(-15.5, 10), 2.0, Color(pink.r, pink.g, pink.b, 0.6))
		draw_circle(Vector2(15.5, 10), 2.0, Color(pink.r, pink.g, pink.b, 0.6))
		_rrect(Vector2(-10, -25), Vector2(20, 17), 5.0, white)
		_rrect(Vector2(-10, -25), Vector2(20, 5), 4.0, Color(1.0, 0.6, 0.8, 0.85))
		_rrect(Vector2(-12, -19), Vector2(2, 8), 1.0, light_pink)
		_rrect(Vector2(10, -19), Vector2(2, 8), 1.0, light_pink)
		_rrect(Vector2(-1, -32), Vector2(2, 8), 1.0, light_pink)
		var pts_bow1 = PackedVector2Array([Vector2(-7,-30), Vector2(-1,-34), Vector2(-1,-28)])
		draw_colored_polygon(pts_bow1, dark_pink)
		var pts_bow2 = PackedVector2Array([Vector2(7,-30), Vector2(1,-34), Vector2(1,-28)])
		draw_colored_polygon(pts_bow2, dark_pink)
		draw_circle(Vector2(0, -31), 2.5, Color(1.0, 0.5, 0.75))
		var ant_size1 = 4 + sin(time * 3) * 0.8
		draw_circle(Vector2(0, -33), ant_size1, Color(1.0, 0.4, 0.7, 0.9))
		draw_circle(Vector2(0, -33), ant_size1 * 0.5, Color(1, 1, 1, 0.9))
		_rrect(Vector2(-8, -21), Vector2(16, 8), 3.0, Color(0.1, 0.0, 0.05, 0.85))
		draw_circle(Vector2(-4, -17), 3.2, Color(1.0, 0.3, 0.6, 0.9))
		draw_circle(Vector2(-4, -17), 1.8, Color(1, 1, 1, 0.85))
		draw_circle(Vector2(4, -17), 3.2, Color(1.0, 0.3, 0.6, 0.9))
		draw_circle(Vector2(4, -17), 1.8, Color(1, 1, 1, 0.85))
	elif hid == 2:
		var dark = Color(0.1, 0.07, 0.16)
		var darker = Color(0.06, 0.04, 0.1)
		_rrect(Vector2(-9, 8), Vector2(6, 12), 2.0, darker)
		_rrect(Vector2(3, 8), Vector2(6, 12), 2.0, darker)
		_rrect(Vector2(-11, 17), Vector2(9, 7), 2.5, dark)
		_rrect(Vector2(2, 17), Vector2(9, 7), 2.5, dark)
		var torso_pts2 = PackedVector2Array([
			Vector2(-13, -9), Vector2(13, -9),
			Vector2(11, 3), Vector2(8, 11),
			Vector2(-8, 11), Vector2(-11, 3),
		])
		draw_colored_polygon(torso_pts2, dark)
		_rrect(Vector2(-13, -9), Vector2(26, 4), 2.0, Color(0.7, 0.0, 0.9, 0.85))
		draw_circle(Vector2(0, 1), 6, Color(0.5, 0.0, 0.8, 0.7))
		draw_circle(Vector2(0, 1), 4, Color(0.8, 0.0, 0.1, 0.9))
		draw_circle(Vector2(0, 1), 2.5, Color(1.0, 0.3, 0.0, 0.9))
		draw_circle(Vector2(-14, -7), 6.0, darker)
		draw_circle(Vector2(-14, -8), 4.2, dark)
		draw_circle(Vector2(14, -7), 6.0, darker)
		draw_circle(Vector2(14, -8), 4.2, dark)
		_rrect(Vector2(-19, -6), Vector2(7, 14), 3.0, dark)
		_rrect(Vector2(12, -6), Vector2(7, 14), 3.0, dark)
		draw_circle(Vector2(-15.5, 10), 4.2, darker)
		draw_circle(Vector2(15.5, 10), 4.2, darker)
		for i in 3:
			draw_line(Vector2(-18 + i*3, 9), Vector2(-19 + i*3, 15), Color(0.5, 0.0, 0.8, 0.7), 1.5)
			draw_line(Vector2(12 + i*3, 9), Vector2(13 + i*3, 15), Color(0.5, 0.0, 0.8, 0.7), 1.5)
		_rrect(Vector2(-10, -25), Vector2(20, 17), 5.0, dark)
		_rrect(Vector2(-10, -25), Vector2(20, 5), 4.0, Color(0.75, 0.0, 0.85, 0.85))
		_rrect(Vector2(-12, -19), Vector2(2, 8), 1.0, dark)
		_rrect(Vector2(10, -19), Vector2(2, 8), 1.0, dark)
		var horn1 = PackedVector2Array([Vector2(-7,-25), Vector2(-3,-25), Vector2(-6,-33)])
		draw_colored_polygon(horn1, Color(0.5, 0.0, 0.8, 0.85))
		var horn2 = PackedVector2Array([Vector2(7,-25), Vector2(3,-25), Vector2(6,-33)])
		draw_colored_polygon(horn2, Color(0.5, 0.0, 0.8, 0.85))
		_rrect(Vector2(-1, -32), Vector2(2, 8), 1.0, Color(0.15, 0.1, 0.2))
		var ant_size2 = 4.5 + sin(time * 4) * 1.0
		draw_circle(Vector2(0, -33), ant_size2, Color(0.7, 0.0, 1.0, 0.9))
		draw_circle(Vector2(0, -33), ant_size2 * 0.45, Color(1.0, 0.5, 0.0, 0.9))
		_rrect(Vector2(-8, -21), Vector2(16, 8), 3.0, Color(0.05, 0.0, 0.08, 0.95))
		draw_circle(Vector2(-4, -17), 3.6, Color(0.9, 0.0, 0.0, 0.9))
		draw_circle(Vector2(-4, -17), 2.2, Color(1.0, 0.4, 0.0, 0.9))
		draw_circle(Vector2(4, -17), 3.6, Color(0.9, 0.0, 0.0, 0.9))
		draw_circle(Vector2(4, -17), 2.2, Color(1.0, 0.4, 0.0, 0.9))
	elif hid == 3:
		var gold = Color(0.85, 0.65, 0.0)
		var light_gold = Color(1.0, 0.88, 0.3)
		var green = Color(0.22, 0.4, 0.16)
		var dark_green = Color(0.12, 0.24, 0.08)
		_rrect(Vector2(-10, 8), Vector2(8, 12), 2.0, dark_green)
		_rrect(Vector2(2, 8), Vector2(8, 12), 2.0, dark_green)
		_rrect(Vector2(-12, 17), Vector2(10, 8), 3.0, green)
		_rrect(Vector2(2, 17), Vector2(10, 8), 3.0, green)
		_rrect(Vector2(-12, 17), Vector2(10, 2.5), 1.5, gold)
		_rrect(Vector2(2, 17), Vector2(10, 2.5), 1.5, gold)
		var torso_pts3 = PackedVector2Array([
			Vector2(-15, -10), Vector2(15, -10),
			Vector2(12, 4), Vector2(9, 12),
			Vector2(-9, 12), Vector2(-12, 4),
		])
		draw_colored_polygon(torso_pts3, green)
		_rrect(Vector2(-15, -10), Vector2(30, 4), 1.5, gold)
		draw_circle(Vector2(0, 2), 7, Color(0.2, 0.6, 0.0, 0.7))
		draw_circle(Vector2(0, 2), 5, Color(0.5, 1.0, 0.1, 0.9))
		draw_circle(Vector2(0, 2), 3, Color(1.0, 1.0, 0.5, 1.0))
		draw_arc(Vector2(0, 2), 8.5, 0, TAU, 16, gold, 2.0)
		draw_circle(Vector2(-15, -8), 7.0, dark_green)
		draw_circle(Vector2(-15, -9), 5.0, green)
		draw_circle(Vector2(-15, -9), 2.0, gold)
		draw_circle(Vector2(15, -8), 7.0, dark_green)
		draw_circle(Vector2(15, -9), 5.0, green)
		draw_circle(Vector2(15, -9), 2.0, gold)
		_rrect(Vector2(-23, -7), Vector2(9, 16), 3.0, green)
		_rrect(Vector2(14, -7), Vector2(9, 16), 3.0, green)
		draw_circle(Vector2(-18.5, 11), 5.0, dark_green)
		draw_circle(Vector2(18.5, 11), 5.0, dark_green)
		draw_circle(Vector2(-18.5, 11), 2.6, gold)
		draw_circle(Vector2(18.5, 11), 2.6, gold)
		_rrect(Vector2(-11, -27), Vector2(22, 19), 4.0, dark_green)
		_rrect(Vector2(-11, -27), Vector2(22, 6), 3.0, green)
		_rrect(Vector2(-11, -27), Vector2(22, 2), 1.5, light_gold)
		_rrect(Vector2(-1.5, -35), Vector2(3, 9), 1.5, green)
		var ant_size3 = 4.5 + sin(time * 2.5) * 1.0
		draw_circle(Vector2(0, -36), ant_size3, Color(0.4, 1.0, 0.0, 0.95))
		draw_circle(Vector2(0, -36), ant_size3 * 0.5, Color(1.0, 1.0, 0.5, 0.95))
		_rrect(Vector2(-9, -23), Vector2(18, 9), 3.0, Color(0.0, 0.05, 0.0, 0.95))
		_rrect(Vector2(-7, -20), Vector2(14, 4), 2.0, Color(0.3, 1.0, 0.1, 0.5))
		draw_circle(Vector2(-4.5, -18), 3.6, Color(0.2, 1.0, 0.0, 0.9))
		draw_circle(Vector2(-4.5, -18), 2.0, Color(0.8, 1.0, 0.3, 0.9))
		draw_circle(Vector2(4.5, -18), 3.6, Color(0.2, 1.0, 0.0, 0.9))
		draw_circle(Vector2(4.5, -18), 2.0, Color(0.8, 1.0, 0.3, 0.9))
""" % hid
	s.reload()
	return s

func _on_play():
	LevelTransition.flash_and_load("res://scenes/Level1.tscn")
