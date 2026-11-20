extends Node

# Yerel bildirimler (autoload "Notifier"). Sunucu/Firebase yok: alarmı telefon kurar.
# Oyun arka plana gidince en fazla 3 hatırlatma zamanlanır, oyun açılınca hepsi iptal edilir:
#   +1 gün akşam : seri hatırlatma (seri ≥2 ise) ya da günlük ödül hazır
#   +3 gün       : yeni Daily Challenge
#   +7 gün       : geri dönüş
# Günde en fazla bir bildirim; oyuncu izin vermezse hiçbir şey olmaz.

const ID_TOMORROW := 101
const ID_DAY3 := 102
const ID_DAY7 := 103
const EVENING_HOUR := 18

var _n = null

func _ready() -> void:
	if Engine.has_singleton("LocalNotify"):
		_n = Engine.get_singleton("LocalNotify")
		_n.permission_result.connect(func(ok: bool):
			AnalyticsManager.design_event("Notif:Permission:%s" % ("Granted" if ok else "Denied")))
	_cancel_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_schedule_all()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_cancel_all()

# Oyuncu oyunu sevmeye başladıktan sonra (Level 3 bitince) bir kez sorulur.
func maybe_ask_permission() -> void:
	if _n == null or bool(Progress.data.get("notif_asked", false)):
		return
	Progress.data["notif_asked"] = true
	Progress._save()
	if _n.hasPermission():
		return
	AnalyticsManager.design_event("Notif:Permission:Asked")
	_n.requestPermission()

func _cancel_all() -> void:
	if _n == null:
		return
	for id in [ID_TOMORROW, ID_DAY3, ID_DAY7]:
		_n.cancel(id)

# Yerel saatle (days gün sonra, hour:00) için şimdiden kaç saniye
func _secs_until(days: int, hour: int) -> int:
	var bias_min = int(Time.get_time_zone_from_system().get("bias", 0))
	var local_now = int(Time.get_unix_time_from_system()) + bias_min * 60
	var local_midnight = local_now - posmod(local_now, 86400)
	return local_midnight + days * 86400 + hour * 3600 - local_now

func _schedule_all() -> void:
	if _n == null or not _n.hasPermission():
		return
	_cancel_all()
	var streak = Progress.streak_info()
	var t1 = _secs_until(1, EVENING_HOUR)
	if int(streak["count"]) >= 2:
		_n.schedule(ID_TOMORROW, "🔥 Keep your %d-day streak!" % int(streak["count"]),
			"Clear one level today to keep it alive.", t1)
	else:
		_n.schedule(ID_TOMORROW, "🎁 Your daily reward is ready",
			"Free coins are waiting. Tap to claim!", t1)
	_n.schedule(ID_DAY3, "📅 A new Daily Challenge is live",
		"One fresh level, one global leaderboard. How fast can you climb?", _secs_until(3, EVENING_HOUR))
	_n.schedule(ID_DAY7, "🧲 The magnets miss you",
		"Your heroes are waiting. Jump back in for a quick climb!", _secs_until(7, EVENING_HOUR))
