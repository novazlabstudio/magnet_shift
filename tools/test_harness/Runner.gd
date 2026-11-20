extends Node
# Test sürücüsü (yalnızca test kopyasında autoload). MS_SCENARIO ortam değişkenine göre ekran görüntüsü alır.
var shots := OS.get_environment("MS_SHOTS")
var scen := OS.get_environment("MS_SCENARIO")

func _ready() -> void:
	if scen == "":
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(shots + "/" + name + ".png")
	print("[SHOT] ", name)

func wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout

func seed_save(max_level: int, wallet: int, daily_avail: bool) -> void:
	var f = FileAccess.open("user://max_level.dat", FileAccess.WRITE); f.store_8(max_level); f.close()
	f = FileAccess.open("user://onboarding_done.dat", FileAccess.WRITE); f.store_8(1); f.close()
	f = FileAccess.open("user://tutorial_done.dat", FileAccess.WRITE); f.store_8(1); f.close()
	Progress.data["wallet"] = wallet
	Progress.data["wallet_init"] = true
	Progress.data["streak"] = 3
	Progress.data["last_day"] = Time.get_date_string_from_system()
	if daily_avail:
		Progress.data["daily_claim_last"] = Progress._day_offset(Time.get_date_string_from_system(), -1)
		Progress.data["daily_claim_day"] = 2
	else:
		Progress.data["daily_claim_last"] = Time.get_date_string_from_system()
		Progress.data["daily_claim_day"] = 3
	Progress._save()

func gm() -> Node:
	return get_tree().current_scene

# ── Otopilot: eğitimdeki hedef seçimiyle mıknatıstan mıknatısa uçar ──
var bot_on := false
var _bot_target: Node2D = null
var _bot_hold := 0.0
var _bot_drop := 0.0
func _clear_path(g, a: Vector2, b: Vector2) -> bool:
	var space = g.get_world_2d().direct_space_state
	var q = PhysicsRayQueryParameters2D.create(a, b)
	q.collision_mask = 0xFFFFFFFF
	q.exclude = [g.player.get_rid()]
	q.collide_with_areas = false
	var ex = [g.player.get_rid()]
	for i in 8:
		q.exclude = ex
		var h = space.intersect_ray(q)
		if h.is_empty():
			break
		if h["collider"].is_in_group("guard"):
			return false
		ex.append(h["rid"])
	# Alanlar: lazerler engel, coin'ler değil
	q.collide_with_bodies = false
	q.collide_with_areas = true
	var excl = [g.player.get_rid()]
	for i in 6:
		q.exclude = excl
		var hit = space.intersect_ray(q)
		if hit.is_empty():
			return true
		var c = hit["collider"]
		if c.is_in_group("laser"):
			return false
		excl.append(hit["rid"])
	return true

var _bot_t := 0.0
var _bot_best_y := INF
var _bot_stuck := 0.0
var _bot_black := {}
func _physics_process(delta: float) -> void:
	if not bot_on:
		return
	var g = gm()
	if g == null or not ("player" in g) or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	if g.tap_hint:
		g.tap_hint.visible = false
	if p.is_dead or not g.level_active:
		_bot_target = null
		return
	if g._t_start_ms < 0:
		g._t_start_ms = Time.get_ticks_msec()
	var exit_m = g._exit_magnet()
	var pp = p.global_position
	# Kapı görünür ve yakınsa: kapının üstündeki mıknatısa git, oraya varınca bırak
	if _bot_target == exit_m and pp.distance_to(exit_m.global_position) < 60.0:
		g._deactivate_all_magnets()
		_bot_drop += delta
		if _bot_drop > 1.0:
			_bot_drop = 0.0
			_bot_target = null
		return
	_bot_t += delta
	if pp.y < _bot_best_y - 15.0:
		_bot_best_y = pp.y
		_bot_stuck = 0.0
	else:
		_bot_stuck += delta
	var reached = _bot_target != null and is_instance_valid(_bot_target) and pp.distance_to(_bot_target.global_position) < 50.0
	if _bot_target != null and not reached and _bot_t < 0.25 and _bot_stuck < 1.4:
		return
	_bot_t = 0.0
	var best = null
	var best_score = INF
	for m in g.magnets:
		if not is_instance_valid(m) or m == _bot_target and not _bot_stuck >= 1.4:
			pass
		if not is_instance_valid(m) or ("kind" in m and m.kind == "repel"):
			continue
		var mp = m.global_position
		var d = pp.distance_to(mp)
		if d < 30.0 or _bot_black.has(m) and _bot_black[m] > Time.get_ticks_msec():
			continue
		if mp.y > pp.y - 20.0 and m != exit_m:
			continue
		if not _clear_path(g, pp, mp):
			continue
		var sc = mp.y + (0.0 if m != exit_m else -400.0)
		if _bot_stuck >= 1.4 and m == _bot_target:
			_bot_black[m] = Time.get_ticks_msec() + 2500
			continue
		if sc < best_score:
			best_score = sc
			best = m
	if best == null:
		# yan duvardaki mıknatıslardan görünür olanı dene
		for m in g.magnets:
			if is_instance_valid(m) and m != _bot_target and _clear_path(g, pp, m.global_position):
				best = m
				break
	if best and best != _bot_target:
		_bot_target = best
		_bot_stuck = 0.0
		_bot_best_y = pp.y
		best.activate(p)
	elif best and reached:
		best.activate(p)

func play_level(path: String, max_t: float) -> void:
	_bot_target = null
	_bot_best_y = INF
	get_tree().change_scene_to_file(path)
	await wait(1.4)
	bot_on = true
	var t = 0.0
	while t < max_t:
		await wait(0.1)
		t += 0.1
		var g = gm()
		if g and ("level_active" in g) and not g.level_active:
			break
	bot_on = false

func _run() -> void:
	await wait(0.3)
	match scen:
		"menu":
			seed_save(12, 520, true)
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
			await wait(0.3)
			await shot("01_menu")
			await wait(1.0)
			await shot("02_daily_popup")
			var ui = gm().get_node("UI")
			ui.get_node("DailyReward").queue_free()
			gm()._show_shop(ui)
			await wait(1.2)
			await shot("03_shop")
		"menu_new":
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
			await wait(1.5)
			await shot("04_menu_newplayer")
		"endless":
			seed_save(12, 100, false)
			Progress.data["magnets_seen"] = []
			Progress.data["trail"] = "rainbow"; Progress.data["trails"] = ["none", "rainbow"]
			RunMode.start_endless()
			RunMode.stage = int(OS.get_environment("MS_STAGE") if OS.get_environment("MS_STAGE") != "" else "6")
			await wait(2.6)
			await shot("05_endless_stage")
			var p = gm().player
			# oyuncuyu bir mıknatısa çektir: iz görünsün
			var mags = gm().magnets
			mags.sort_custom(func(a, b): return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
			mags[1].activate(p)
			await wait(0.6)
			await shot("06_endless_trail")
			gm()._on_level_complete()
			await wait(0.8)
			await shot("07_endless_clear")
		"magnets":
			seed_save(20, 100, false)
			Progress.data["guards_seen"] = [0,1,2,3,4,5,6,7,8,9]
			Progress.data["magnets_seen"] = []
			RunMode.start_endless()
			RunMode.stage = 9
			await wait(2.4)
			await shot("14_magnet_card")
			var g = gm()
			var rep = null
			var mov = null
			for m in g.magnets:
				if m.kind == "repel" and rep == null: rep = m
				if m.move_dx != 0.0 and mov == null: mov = m
			print("DBG repel ", rep != null, " mover ", mov != null, " count ", g.magnets.size())
			if rep:
				var p = g.player
				p.global_position = rep.global_position + Vector2(-40, 70)
				p.linear_velocity = Vector2.ZERO
				await wait(0.1)
				var y0 = p.global_position.y
				rep.activate(p)
				await wait(0.5)
				print("DBG repel moved dy ", p.global_position.y - y0, " dx ", p.global_position.x - rep.global_position.x)
				await shot("15_repel_active")
				rep.deactivate()
			if mov:
				var x0 = mov.position.x
				await wait(1.2)
				print("DBG mover dx ", mov.position.x - x0)
				g.player.global_position = mov.global_position + Vector2(0, 120)
				await wait(0.3)
				await shot("16_mover")
		"smoke":
			seed_save(50, 100, false)
			for i in range(1, 51):
				get_tree().change_scene_to_file("res://scenes/Level%d.tscn" % i)
				await wait(0.25)
				var g = gm()
				if g == null or g.player == null:
					print("DBG FAIL level ", i)
			print("DBG campaign ok")
			for k in range(1, 31):
				RunMode.mode = "endless"
				RunMode.stage = k
				get_tree().change_scene_to_file(RunMode.ENDLESS_SCENE)
				await wait(0.25)
				var g = gm()
				var nrep = 0
				var nmov = 0
				for m in g.magnets:
					if m.kind == "repel": nrep += 1
					if m.move_dx != 0.0: nmov += 1
				print("DBG stage %d base %d magnets %d repel %d mover %d" % [k, g.level_number, g.magnets.size(), nrep, nmov])
			RunMode.mode = "daily"
			get_tree().change_scene_to_file(RunMode.ENDLESS_SCENE)
			await wait(0.3)
			print("DBG daily base ", gm().level_number)
		"bot1":
			seed_save(50, 300, false)
			_bot_target = null
			get_tree().change_scene_to_file("res://scenes/Level2.tscn")
			await wait(1.4)
			bot_on = true
			for k in 6:
				await wait(1.5)
				var g = gm()
				print("DBG t=%.1f pos=%s target=%s exit=%s" % [1.5*(k+1), g.player.global_position, _bot_target.global_position if _bot_target else null, g.exit_position])
			await shot("20_bot_stuck")
		"store":
			seed_save(50, 640, false)
			Progress.data["trails"] = ["none", "rainbow", "fire", "neon"]; Progress.data["trail"] = "rainbow"
			Progress.data["guards_seen"] = [0,1,2,3,4,5,6,7,8,9]; Progress.data["magnets_seen"] = ["repel", "mover"]
			Progress._save()
			# 1) uçuş: level 12, otopilot
			_bot_target = null
			get_tree().change_scene_to_file("res://scenes/Level12.tscn")
			await wait(1.5)
			bot_on = true
			await wait(1.6)
			await shot("s1_fly")
			await wait(0.9)
			await shot("s1b_fly")
			bot_on = false
			# 2) endless, yeni mıknatıslar
			RunMode.start_endless(); RunMode.stage = 8
			await wait(2.0)
			bot_on = true
			await wait(1.8)
			await shot("s2_endless")
			await wait(1.0)
			await shot("s2b_endless")
			bot_on = false
			RunMode.clear()
			# 3) menü
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
			await wait(1.2)
			await shot("s3_menu")
			# 4) mağaza
			gm()._show_shop(gm().get_node("UI"))
			await wait(1.3)
			await shot("s4_shop")
			# 5) günlük ödül
			get_tree().reload_current_scene()
			await wait(0.6)
			Progress.data["daily_claim_last"] = Progress._day_offset(Time.get_date_string_from_system(), -1)
			Progress.data["daily_claim_day"] = 5
			gm()._show_daily_reward(gm().get_node("UI"))
			await wait(0.8)
			await shot("s5_daily")
			# 6) ölüm (zap) anı
			get_tree().change_scene_to_file("res://scenes/Level20.tscn")
			await wait(1.6)
			bot_on = true
			for k in 60:
				await wait(0.1)
				if gm().player.is_dead:
					break
			await wait(0.45)
			await shot("s6_death")
			bot_on = false
			# 7) yıldızlı sonuç
			get_tree().change_scene_to_file("res://scenes/Level2.tscn")
			await wait(1.4)
			bot_on = true
			for k in 120:
				await wait(0.1)
				if not gm().level_active:
					break
			bot_on = false
			await wait(2.0)
			await shot("s7_result")
		"video":
			seed_save(50, 640, false)
			Progress.data["trails"] = ["none", "rainbow", "fire", "neon"]; Progress.data["trail"] = "fire"
			Progress.data["guards_seen"] = [0,1,2,3,4,5,6,7,8,9]; Progress.data["magnets_seen"] = ["repel", "mover"]
			Progress._save()
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
			await wait(1.8)
			await play_level("res://scenes/Level2.tscn", 9.0)
			await wait(1.8)
			Progress.data["trail"] = "rainbow"; Progress._save()
			await play_level("res://scenes/Level12.tscn", 4.5)
			await wait(1.4)
			RunMode.start_endless(); RunMode.stage = 7
			await wait(1.9)
			bot_on = true
			await wait(4.0)
			bot_on = false
			RunMode.clear()
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
			await wait(0.8)
			gm()._show_shop(gm().get_node("UI"))
			await wait(2.2)
			get_tree().reload_current_scene()
			await wait(2.0)
		"bot":
			seed_save(50, 300, false)
			for lv in [2, 3, 5, 8, 12, 16]:
				await play_level("res://scenes/Level%d.tscn" % lv, 14.0)
				var g = gm()
				print("DBG bot level ", lv, " done=", not g.level_active, " dead=", g.player.is_dead)
		"endless_over":
			seed_save(12, 100, false)
			RunMode.start_endless()
			RunMode.stage = 4
			RunMode.hearts = 1
			await wait(2.0)
			gm().player.die("laser")
			await wait(2.5)
			await shot("08_endless_over")
		"daily":
			seed_save(12, 100, false)
			RunMode.start_daily()
			await wait(2.2)
			await shot("09_daily")
			gm()._t_start_ms = Time.get_ticks_msec() - 2345
			gm()._on_level_complete()
			await wait(0.8)
			await shot("10_daily_clear")
		"result":
			seed_save(12, 100, false)
			get_tree().change_scene_to_file("res://scenes/Level7.tscn")
			await wait(2.0)
			gm().coins_collected = 4
			gm()._t_start_ms = Time.get_ticks_msec() - 1542
			print("DBG before ", gm()._t_start_ms, " now ", Time.get_ticks_msec())
			gm()._on_level_complete()
			print("DBG after ", gm()._elapsed_ms, " paused ", gm()._paused_ms)
			await wait(1.6)
			await shot("11_result_double")
		"skip":
			seed_save(12, 100, false)
			Progress.data["fail_level"] = 9; Progress.data["fail_count"] = 2
			get_tree().change_scene_to_file("res://scenes/Level9.tscn")
			await wait(2.0)
			gm().player.die("guard")
			await wait(2.2)
			await shot("12_result_skip")
		"gameover":
			seed_save(12, 400, false)
			var f = FileAccess.open("user://lives.dat", FileAccess.WRITE); f.store_8(1); f.store_8(0); f.close()
			get_tree().change_scene_to_file("res://scenes/Level8.tscn")
			await wait(2.0)
			gm().player.die("laser")
			await wait(3.0)
			await shot("13_gameover_coins")
	await wait(0.2)
	get_tree().quit()
