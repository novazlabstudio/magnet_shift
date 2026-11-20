extends Node

# Oyuncuyu geri getiren, tamamen cihazda çalışan ilerleme sistemi (autoload "Progress").
# Google Play Games vb. dış hizmet yok: ücret, ek form veya izin gerektirmez.
#   - AWARDS (ödüller): yerel başarımlar; açılınca ekranın üstünde bildirim + ses
#   - Günlük seri: üst üste kaç gün en az bir level bitirildi (ana sayfada rozet)
#   - Oyun içi değerlendirme isteği (Google Play In-App Review): iyi bir anda ve seyrek
# Ödüller oyun içi avantaj vermez (can/reklam kilidi vb.), reklam gelirini azaltmaz.
#   - Cüzdan (1.3): toplanan her coin cüzdana da girer; mağazada iz (trail) ve kahraman alınır
#   - Günlük ödül takvimi (7 gün) + seri bonusu; en iyi süreler; Endless / Daily Challenge rekorları
# Google Play Games (1.3) yalnızca isteğe bağlı bir ayna: sıralama + başarımlar (PlayGames autoload).

const SAVE_PATH := "user://progress.json"

const AWARDS := [
	{"id": "first_clear", "icon": "🚪", "title": "First Escape", "desc": "Complete Level 1"},
	{"id": "lvl5", "icon": "⚡", "title": "Warming Up", "desc": "Reach Level 5"},
	{"id": "lvl10", "icon": "🧲", "title": "Magnetized", "desc": "Reach Level 10"},
	{"id": "lvl20", "icon": "🚀", "title": "Gravity Defier", "desc": "Reach Level 20"},
	{"id": "lvl30", "icon": "🌌", "title": "Sky Climber", "desc": "Reach Level 30"},
	{"id": "lvl40", "icon": "🔮", "title": "Polar Master", "desc": "Reach Level 40"},
	{"id": "lvl50", "icon": "🏆", "title": "Event Horizon", "desc": "Complete all 50 levels"},
	{"id": "star3", "icon": "⭐", "title": "Perfectionist", "desc": "Get 3 stars on a level"},
	{"id": "star3_10", "icon": "🌟", "title": "Star Collector", "desc": "Get 3 stars on 10 levels"},
	{"id": "star3_30", "icon": "💫", "title": "Constellation", "desc": "Get 3 stars on 30 levels"},
	{"id": "coins100", "icon": "💰", "title": "Coin Hunter", "desc": "Collect 100 coins in total"},
	{"id": "coins500", "icon": "💎", "title": "Treasure Magnet", "desc": "Collect 500 coins in total"},
	{"id": "run50", "icon": "🎯", "title": "Big Run", "desc": "Score 50 coins in a single run"},
	{"id": "clean5", "icon": "🛡️", "title": "Untouchable", "desc": "Clear 5 levels in a row without dying"},
	{"id": "zap10", "icon": "🔌", "title": "Shock Absorber", "desc": "Get zapped 10 times"},
	{"id": "streak3", "icon": "🔥", "title": "Regular", "desc": "Play 3 days in a row"},
	{"id": "streak7", "icon": "📅", "title": "Dedicated", "desc": "Play 7 days in a row"},
	{"id": "collector", "icon": "🦸", "title": "Collector", "desc": "Unlock an ad-reward hero"},
	{"id": "shopper", "icon": "🛍️", "title": "Style Points", "desc": "Buy something in the shop"},
	{"id": "endless10", "icon": "♾️", "title": "Endless Climber", "desc": "Reach stage 10 in Endless"},
	{"id": "daily_clear", "icon": "📅", "title": "Daily Runner", "desc": "Clear a Daily Challenge"},
]

# ── Mağaza: hareket izi (trail). Görünüm TrailFX.gd'de; oynanışa etkisi yok ──
const TRAILS := [
	{"id": "none", "name": "NONE", "price": 0, "c1": Color(1, 1, 1, 0), "c2": Color(1, 1, 1, 0)},
	{"id": "spark", "name": "SPARK", "price": 60, "c1": Color(1.0, 0.95, 0.6), "c2": Color(1.0, 0.6, 0.1)},
	{"id": "neon", "name": "NEON", "price": 100, "c1": Color(0.2, 1.0, 0.9), "c2": Color(0.9, 0.2, 1.0)},
	{"id": "fire", "name": "FIRE", "price": 150, "c1": Color(1.0, 0.85, 0.2), "c2": Color(1.0, 0.15, 0.0)},
	{"id": "ice", "name": "FROST", "price": 150, "c1": Color(0.9, 1.0, 1.0), "c2": Color(0.3, 0.6, 1.0)},
	{"id": "rainbow", "name": "RAINBOW", "price": 250, "c1": Color(1, 0, 0), "c2": Color(0, 0, 1)},
	{"id": "stardust", "name": "STARDUST", "price": 300, "c1": Color(1.0, 1.0, 1.0), "c2": Color(0.6, 0.5, 1.0)},
	{"id": "field", "name": "FIELD", "price": 400, "c1": Color(0.4, 0.8, 1.0), "c2": Color(1.0, 0.3, 0.35)},
	{"id": "golden", "name": "GOLDEN", "price": -1, "c1": Color(1.0, 0.95, 0.55), "c2": Color(1.0, 0.65, 0.0)},
]
# Günlük ödül takvimi (gün 1..7); 7. gün ilk kez alınınca GOLDEN iz de verilir
const DAILY_REWARDS := [20, 30, 40, 50, 60, 80, 150]
# Oyun serisi (üst üste level bitirilen gün) bonusları
const STREAK_BONUS := {3: 50, 7: 150, 14: 300, 30: 500}
const DAILY_CHALLENGE_REWARD := 40
const CONTINUE_COIN_PRICE := 150

var data: Dictionary = {
	"awards": {}, "coins_total": 0, "zaps": 0, "clean_clears": 0,
	"streak": 0, "best_streak": 0, "last_day": "",
	"review_count": 0, "review_last": 0,
	"guards_seen": [],
	"wallet": 0, "wallet_init": false,
	"trails": ["none"], "trail": "none",
	"best_times": {},
	"daily_claim_last": "", "daily_claim_day": 0,
	"dc_date": "", "dc_best_ms": 0, "dc_rewarded": false, "dc_clears": 0,
	"endless_best": 0,
	"fail_level": 0, "fail_count": 0,
	"notif_asked": false,
	"stats_purchases": 0,
	"magnets_seen": [],
}

var _layer: CanvasLayer
var _queue: Array = []
var _showing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)

# ── Kayıt ────────────────────────────────────────────────────────────────────
func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		f.close()
		if d is Dictionary:
			for k in d:
				data[k] = d[k]
	# 1.3: cüzdan ilk kez açılırken o ana kadar toplanan tüm coin'ler hediye edilir
	if not bool(data["wallet_init"]):
		data["wallet"] = int(data["coins_total"])
		data["wallet_init"] = true
		_save()

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

# ── Oyun olayları (GameManager / MainMenu çağırır) ───────────────────────────
func on_coin() -> void:
	data["coins_total"] = int(data["coins_total"]) + 1
	data["wallet"] = int(data["wallet"]) + 1

# ── Cüzdan ───────────────────────────────────────────────────────────────────
signal wallet_changed(amount: int)

func wallet() -> int:
	return int(data["wallet"])

func add_coins(n: int, source: String) -> void:
	if n <= 0:
		return
	data["wallet"] = wallet() + n
	_save()
	wallet_changed.emit(wallet())
	AnalyticsManager.design_event("Coins:Earn:%s" % source, n)

func spend(n: int, item: String) -> bool:
	if n < 0 or wallet() < n:
		return false
	data["wallet"] = wallet() - n
	data["stats_purchases"] = int(data["stats_purchases"]) + 1
	_save()
	wallet_changed.emit(wallet())
	AnalyticsManager.design_event("Coins:Spend:%s" % item, n)
	return true

# ── Mağaza: izler ────────────────────────────────────────────────────────────
func trail_info(id: String) -> Dictionary:
	for t in TRAILS:
		if t["id"] == id:
			return t
	return TRAILS[0]

func owns_trail(id: String) -> bool:
	return id in data["trails"]

func current_trail() -> String:
	var t = str(data["trail"])
	return t if owns_trail(t) else "none"

func equip_trail(id: String) -> void:
	if owns_trail(id):
		data["trail"] = id
		_save()

func grant_trail(id: String) -> void:
	if not owns_trail(id):
		var arr: Array = data["trails"]
		arr.append(id)
		data["trails"] = arr
	_save()

func buy_trail(id: String) -> bool:
	var t = trail_info(id)
	if owns_trail(id) or int(t["price"]) < 0:
		return false
	if not spend(int(t["price"]), "Trail_%s" % id):
		return false
	grant_trail(id)
	equip_trail(id)
	unlock("shopper")
	return true

func buy_hero(id: int) -> bool:
	if not HeroManager.is_ad_hero(id) or HeroManager.is_ad_hero_unlocked(id):
		return false
	if not spend(HeroManager.COIN_PRICE, "Hero_%s" % HeroManager.HERO_NAMES[id]):
		return false
	HeroManager.unlock_with_coins(id)
	unlock("shopper")
	on_hero_unlocked()
	return true

# ── Günlük ödül (takvim) ─────────────────────────────────────────────────────
# {"available": bugün alınabilir mi, "day": alınacak gün 1..7, "amount": coin}
func daily_reward_state() -> Dictionary:
	var today = Time.get_date_string_from_system()
	var last = str(data["daily_claim_last"])
	var day = int(data["daily_claim_day"])
	if last == today:
		return {"available": false, "day": day, "amount": DAILY_REWARDS[clamp(day - 1, 0, 6)]}
	var next_day = 1
	if last != "" and _day_offset(last, 1) == today:
		next_day = day % 7 + 1
	return {"available": true, "day": next_day, "amount": DAILY_REWARDS[next_day - 1]}

func claim_daily_reward(multiplier: int) -> int:
	var st = daily_reward_state()
	if not st["available"]:
		return 0
	var amount = int(st["amount"]) * max(1, multiplier)
	data["daily_claim_last"] = Time.get_date_string_from_system()
	data["daily_claim_day"] = st["day"]
	add_coins(amount, "Daily")
	AnalyticsManager.design_event("Daily:Claim:Day%d%s" % [st["day"], ":x2" if multiplier > 1 else ""])
	if int(st["day"]) == 7 and not owns_trail("golden"):
		grant_trail("golden")
		toast("✨", "REWARD", "GOLDEN TRAIL UNLOCKED")
	return amount

# ── En iyi süreler (ms) ──────────────────────────────────────────────────────
func best_time(level: int) -> int:
	return int(data["best_times"].get(str(level), 0))

# Yeni rekor ise true
func record_time(level: int, ms: int) -> bool:
	var old = best_time(level)
	if old == 0 or ms < old:
		data["best_times"][str(level)] = ms
		_save()
		return true
	return false

static func format_time(ms: int) -> String:
	return "%d.%02ds" % [ms / 1000, (ms % 1000) / 10]

# ── Zorlanma takibi: aynı level'de üst üste ölüm sayısı (ATLA teklifi için) ──
func note_fail(level: int) -> int:
	if int(data["fail_level"]) != level:
		data["fail_level"] = level
		data["fail_count"] = 0
	data["fail_count"] = int(data["fail_count"]) + 1
	_save()
	return int(data["fail_count"])

func clear_fail(level: int) -> void:
	if int(data["fail_level"]) == level:
		data["fail_count"] = 0
		_save()

# ── Daily Challenge / Endless rekorları ──────────────────────────────────────
func daily_challenge_state() -> Dictionary:
	var today = Time.get_date_string_from_system()
	if str(data["dc_date"]) != today:
		return {"best_ms": 0, "rewarded": false}
	return {"best_ms": int(data["dc_best_ms"]), "rewarded": bool(data["dc_rewarded"])}

# Döner: {"new_best": bool, "reward": int}
func on_daily_challenge_clear(ms: int) -> Dictionary:
	var today = Time.get_date_string_from_system()
	if str(data["dc_date"]) != today:
		data["dc_date"] = today
		data["dc_best_ms"] = 0
		data["dc_rewarded"] = false
	var new_best = int(data["dc_best_ms"]) == 0 or ms < int(data["dc_best_ms"])
	if new_best:
		data["dc_best_ms"] = ms
	var reward = 0
	if not bool(data["dc_rewarded"]):
		data["dc_rewarded"] = true
		data["dc_clears"] = int(data["dc_clears"]) + 1
		reward = DAILY_CHALLENGE_REWARD
	_mark_day()
	unlock("daily_clear")
	_save()
	if reward > 0:
		add_coins(reward, "DailyChallenge")
	PlayGames.submit_score("daily", ms)
	return {"new_best": new_best, "reward": reward}

func on_endless_stage(stage: int) -> bool:
	var new_best = stage > int(data["endless_best"])
	if new_best:
		data["endless_best"] = stage
	if stage >= 10:
		unlock("endless10")
	_save()
	PlayGames.submit_score("endless", stage)
	return new_best

func total_stars(all_stars: Array) -> int:
	var t = 0
	for s in all_stars:
		t += int(s)
	return t

func on_level_complete(level: int, stars: int, all_stars: Array, run_score: int) -> void:
	_mark_day()
	data["clean_clears"] = int(data["clean_clears"]) + 1
	if level >= 1: unlock("first_clear")
	var reached = level + 1
	if reached >= 5: unlock("lvl5")
	if reached >= 10: unlock("lvl10")
	if reached >= 20: unlock("lvl20")
	if reached >= 30: unlock("lvl30")
	if reached >= 40: unlock("lvl40")
	if level >= 50: unlock("lvl50")
	var three = 0
	for s in all_stars:
		if s >= 3:
			three += 1
	if stars >= 3 or three >= 1: unlock("star3")
	if three >= 10: unlock("star3_10")
	if three >= 30: unlock("star3_30")
	_check_coins()
	if run_score >= 50: unlock("run50")
	if int(data["clean_clears"]) >= 5: unlock("clean5")
	_save()
	PlayGames.submit_score("stars", total_stars(all_stars))
	PlayGames.submit_score("run", run_score)

func on_death(cause: String) -> void:
	data["clean_clears"] = 0
	if cause == "laser":
		data["zaps"] = int(data["zaps"]) + 1
		if int(data["zaps"]) >= 10: unlock("zap10")
	_check_coins()
	_save()

func on_hero_unlocked() -> void:
	unlock("collector")
	_save()

func _check_coins() -> void:
	if int(data["coins_total"]) >= 100: unlock("coins100")
	if int(data["coins_total"]) >= 500: unlock("coins500")

# Yeni bekçi tanıtımı: her kademe yalnızca ilk karşılaşmada tanıtılır. Yeni görüldüyse true döner.
func mark_guard_seen(tier: int) -> bool:
	var seen: Array = data["guards_seen"]
	if tier in seen or float(tier) in seen:
		return false
	seen.append(tier)
	data["guards_seen"] = seen
	_save()
	return true

# Yeni mıknatıs türü tanıtımı ("repel" | "mover"): ilk karşılaşmada true
func mark_magnet_seen(key: String) -> bool:
	var seen: Array = data["magnets_seen"]
	if key in seen:
		return false
	seen.append(key)
	data["magnets_seen"] = seen
	_save()
	return true

# ── Günlük seri ──────────────────────────────────────────────────────────────
func _day_offset(day: String, days: int) -> String:
	var t = Time.get_unix_time_from_datetime_string(day + "T12:00:00")
	return Time.get_date_string_from_unix_time(t + days * 86400)

func _mark_day() -> void:
	var today = Time.get_date_string_from_system()
	var last = str(data["last_day"])
	if last == today:
		return
	if last != "" and _day_offset(last, 1) == today:
		data["streak"] = int(data["streak"]) + 1
	else:
		data["streak"] = 1
	data["best_streak"] = max(int(data["best_streak"]), int(data["streak"]))
	data["last_day"] = today
	if int(data["streak"]) >= 3: unlock("streak3")
	if int(data["streak"]) >= 7: unlock("streak7")
	var bonus = int(STREAK_BONUS.get(int(data["streak"]), 0))
	if bonus > 0:
		add_coins(bonus, "Streak")
		toast("🔥", "%d-DAY STREAK BONUS" % int(data["streak"]), "+%d COINS" % bonus)

# {"count": seri, "today": bugün oynandı mı, "alive": seri hâlâ sürüyor mu (bugün ya da dün oynandı)}
func streak_info() -> Dictionary:
	var today = Time.get_date_string_from_system()
	var last = str(data["last_day"])
	var played_today = last == today
	var alive = played_today or (last != "" and _day_offset(last, 1) == today)
	return {"count": int(data["streak"]) if alive else 0, "today": played_today, "alive": alive}

# ── Ödüller ──────────────────────────────────────────────────────────────────
func is_unlocked(id: String) -> bool:
	return data["awards"].has(id)

func unlocked_count() -> int:
	return data["awards"].size()

func unlock(id: String) -> void:
	if is_unlocked(id):
		return
	data["awards"][id] = Time.get_date_string_from_system()
	PlayGames.unlock_achievement(id)
	for a in AWARDS:
		if a["id"] == id:
			_queue.append({"icon": a["icon"], "head": "AWARD UNLOCKED", "title": a["title"]})
			if not _showing:
				_show_next()
			AnalyticsManager.design_event("Award:%s" % id)
			return

# Üstten kayan kısa bildirim (ödül, bonus coin vb.)
func toast(icon: String, head: String, title: String) -> void:
	_queue.append({"icon": icon, "head": head, "title": title})
	if not _showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var a = _queue.pop_front()
	SoundManager.play_sfx("trophy", -4.0)
	var top = 74.0
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.14, 0.95)
	sb.border_color = Color(1.0, 0.78, 0.2, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 14
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(1.0, 0.7, 0.1, 0.35)
	sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var icon = Label.new()
	icon.text = a["icon"]
	icon.add_theme_font_size_override("font_size", 30)
	row.add_child(icon)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	var head = Label.new()
	head.text = a["head"]
	head.add_theme_font_override("font", UIFont.title(2))
	head.add_theme_font_size_override("font_size", 11)
	head.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	col.add_child(head)
	var name_lbl = Label.new()
	name_lbl.text = a["title"]
	name_lbl.add_theme_font_override("font", UIFont.title(1))
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	col.add_child(name_lbl)
	_layer.add_child(panel)
	# Ortala, ekranın üstünden kayarak gelsin
	await get_tree().process_frame
	var w = panel.size.x
	panel.position = Vector2(240 - w / 2.0, -90)
	var tw = panel.create_tween()
	tw.tween_property(panel, "position:y", top, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_property(panel, "position:y", -90.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		panel.queue_free()
		_show_next()
	)

# ── Oyun içi değerlendirme (Google Play In-App Review) ───────────────────────
# Yalnızca oyuncu ilerlemiş ve iyi bir sonuç almışken; en fazla 3 kez, aralarında en az 21 gün.
# Pencereyi gösterip göstermemeye Google karar verir; puan sorulmadan önce "beğendin mi?" gibi
# bir ara soru SORULMAZ (Google politikası).
func maybe_request_review(level: int, stars: int) -> void:
	if not Engine.has_singleton("InAppReview"):
		return
	if level < 5 or stars < 2:
		return
	var count = int(data["review_count"])
	if count >= 3:
		return
	var now = int(Time.get_unix_time_from_system())
	if count > 0 and now - int(data["review_last"]) < 21 * 86400:
		return
	data["review_count"] = count + 1
	data["review_last"] = now
	_save()
	AnalyticsManager.design_event("Review:Requested")
	Engine.get_singleton("InAppReview").requestReview()
