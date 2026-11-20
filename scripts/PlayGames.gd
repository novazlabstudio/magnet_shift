extends Node

# Google Play Games Services köprüsü (autoload "PlayGames").
# Sıralama ve başarımları Google'ın sunucusu tutar: bizim sunucumuz yok, ücret yok.
# Eklenti yoksa (masaüstü) ya da APP_ID girilmemişse her çağrı sessizce hiçbir şey yapmaz.
# Yerel kayıt (Progress) asıl kaynaktır; giriş yapılınca tüm ödüller ve rekorlar Play Games'e aynalanır.

const Ids = preload("res://scripts/PlayGamesIds.gd")
const Leaderboard = preload("res://scripts/Leaderboard.gd")

signal signed_in_changed(ok: bool)

var signed_in: bool = false
var _p = null
var _pending_ui: String = ""   # giriş bitince açılacak ekran: "lb:<anahtar>" | "ach"

func _ready() -> void:
	if not Engine.has_singleton("PlayGamesV2"):
		return
	var p = Engine.get_singleton("PlayGamesV2")
	if not p.isConfigured():
		return
	_p = p
	_p.sign_in_result.connect(_on_sign_in_result)
	_p.checkSignIn()

func available() -> bool:
	return _p != null

func sign_in() -> void:
	if _p:
		_p.signIn()

func _on_sign_in_result(ok: bool) -> void:
	var changed = ok != signed_in
	signed_in = ok
	if changed:
		signed_in_changed.emit(ok)
		AnalyticsManager.design_event("PlayGames:SignIn:%s" % ("OK" if ok else "Fail"))
	if ok:
		_sync()
		var ui = _pending_ui
		_pending_ui = ""
		if ui == "ach":
			_p.showAchievements()
		elif ui.begins_with("lb:"):
			_p.showLeaderboard(_lb_id(ui.substr(3)))
	else:
		_pending_ui = ""

func _lb_id(key: String) -> String:
	return str(Ids.LEADERBOARDS.get(key, ""))

func submit_score(key: String, value: int) -> void:
	if _p == null or not signed_in or value <= 0:
		return
	var id = _lb_id(key)
	if id != "":
		_p.submitScore(id, value)

func unlock_achievement(award_id: String) -> void:
	if _p == null or not signed_in:
		return
	var id = str(Ids.ACHIEVEMENTS.get(award_id, ""))
	if id != "":
		_p.unlockAchievement(id)

# key boşsa tüm sıralamalar. Giriş yoksa önce giriş penceresi açılır.
func show_leaderboards(key: String = "") -> void:
	if _p == null:
		return
	AnalyticsManager.design_event("PlayGames:Open:%s" % (key if key != "" else "All"))
	if signed_in:
		_p.showLeaderboard(_lb_id(key))
	else:
		_pending_ui = "lb:" + key
		_p.signIn()

func show_achievements() -> void:
	if _p == null:
		return
	AnalyticsManager.design_event("PlayGames:Open:Achievements")
	if signed_in:
		_p.showAchievements()
	else:
		_pending_ui = "ach"
		_p.signIn()

# Yerel ilerlemeyi Play Games'e aktar (oyun Play Games'ten önce oynanmışsa da kaybolmasın).
# Google aynı başarımı/daha düşük skoru tekrar gönderince yok sayar; tekrar göndermek zararsız.
func _sync() -> void:
	for id in Progress.data["awards"]:
		unlock_achievement(str(id))
	var best_run = 0
	for e in Leaderboard.load_entries():
		best_run = max(best_run, int(e.get("score", 0)))
	submit_score("run", best_run)
	var stars = 0
	if FileAccess.file_exists("user://stars.dat"):
		var f = FileAccess.open("user://stars.dat", FileAccess.READ)
		if f:
			for i in 50:
				stars += f.get_8()
			f.close()
	submit_score("stars", stars)
	submit_score("endless", int(Progress.data.get("endless_best", 0)))
	var dc = Progress.daily_challenge_state()
	submit_score("daily", int(dc["best_ms"]))
