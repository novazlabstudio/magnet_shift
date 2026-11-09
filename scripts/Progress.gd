extends Node

# Oyuncuyu geri getiren, tamamen cihazda çalışan ilerleme sistemi (autoload "Progress").
# Google Play Games vb. dış hizmet yok: ücret, ek form veya izin gerektirmez.
#   - AWARDS (ödüller): yerel başarımlar; açılınca ekranın üstünde bildirim + ses
#   - Günlük seri: üst üste kaç gün en az bir level bitirildi (ana sayfada rozet)
#   - Oyun içi değerlendirme isteği (Google Play In-App Review): iyi bir anda ve seyrek
# Ödüller oyun içi avantaj vermez (can/reklam kilidi vb.), reklam gelirini azaltmaz.

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
]

var data: Dictionary = {
	"awards": {}, "coins_total": 0, "zaps": 0, "clean_clears": 0,
	"streak": 0, "best_streak": 0, "last_day": "",
	"review_count": 0, "review_last": 0,
	"guards_seen": [],
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

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

# ── Oyun olayları (GameManager / MainMenu çağırır) ───────────────────────────
func on_coin() -> void:
	data["coins_total"] = int(data["coins_total"]) + 1

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
	for a in AWARDS:
		if a["id"] == id:
			_queue.append(a)
			if not _showing:
				_show_next()
			AnalyticsManager.design_event("Award:%s" % id)
			return

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
	head.text = "AWARD UNLOCKED"
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
