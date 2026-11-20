extends Node

# Oyun modu (autoload "RunMode"): "" = normal 50 level, "endless" = Endless Climb, "daily" = Daily Challenge.
# Yeni modlar sunucusuz: level'ler cihazda, el yapımı 50 level'den "remix" ile üretilir.
#   - Taban level seçilir (zorluğa göre), %50 aynalanır (sağ↔sol; aynalanmış level de aynı şekilde
#     çözülebilir), tema rengi başka bir level'den gelir.
#   - Yeni mıknatıslar: KAYAN mıknatıs (sütun mıknatısı içeri doğru gidip gelir) ve İTEN mıknatıs
#     (kırmızı; basılı tutunca oyuncuyu uzağa iter, alttaysa yukarı fırlatır). İten mıknatıslar yalnızca
#     EKLENİR, hiçbir mıknatısın yerini almaz: level'in çözümü bozulmaz.
# Daily Challenge tohumu tarihtir: o gün herkes aynı level'i oynar, Play Games'te süre yarışır.

const ENDLESS_SCENE := "res://scenes/Endless.tscn"
const ENDLESS_HEARTS := 3

var mode: String = ""
var stage: int = 1          # endless: şu anki stage
var hearts: int = ENDLESS_HEARTS
var run_coins: int = 0      # endless koşusunda toplanan coin
var continued: bool = false # endless: reklamla devam bir kez
var _cache_key: String = ""
var _run_salt: int = 0
var _cache: Dictionary = {}

func start_endless() -> void:
	mode = "endless"
	stage = 1
	hearts = ENDLESS_HEARTS
	run_coins = 0
	continued = false
	_run_salt = randi()
	AnalyticsManager.design_event("Endless:Start")
	LevelTransition.flash_and_load(ENDLESS_SCENE)

func start_daily() -> void:
	mode = "daily"
	AnalyticsManager.design_event("DailyChallenge:Start")
	LevelTransition.flash_and_load(ENDLESS_SCENE)

func clear() -> void:
	mode = ""

func is_active() -> bool:
	return mode != ""

static func today_seed() -> int:
	var d = Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])

func _rng() -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	if mode == "daily":
		r.seed = hash("daily-%d" % today_seed())
	else:
		# Aynı stage tekrar denenirse (can kaybı) aynı level gelsin; her yeni koşu farklı
		r.seed = hash("endless-%d-%d" % [stage, _run_salt])
	return r

func base_level() -> int:
	var r = _rng()
	if mode == "daily":
		return 12 + r.randi_range(0, 24)
	# Stage 1 → level 4-6 civarı; her stage ~2 level zorlaşır; 23. stage'den sonra 36-50 arası
	if stage >= 23:
		return r.randi_range(36, 50)
	return clamp(4 + stage * 2 + r.randi_range(-1, 1), 4, 50)

func title() -> String:
	return "DAILY CHALLENGE" if mode == "daily" else "STAGE %d" % stage

# GameManager.get_level_data bunu çağırır: levels = tüm el yapımı level sözlüğü
func remix(levels: Dictionary, base_num: int) -> Dictionary:
	var key = "%s-%d-%d-%d" % [mode, stage, base_num, _run_salt if mode == "endless" else today_seed()]
	if key == _cache_key:
		return _cache
	var r = _rng()
	r.randi()  # base_level ile aynı ilk sayıyı tekrar kullanma
	var src: Dictionary = levels.get(base_num, levels[1])
	var mirror = r.randf() < 0.5
	var mx = func(x: float) -> float: return 480.0 - x if mirror else x
	var d := {}
	# Tema: başka bir level'in renkleri (aynı yapı, farklı dünya)
	var theme_src: Dictionary = levels.get(r.randi_range(1, 50), src)
	d["bg"] = theme_src["bg"]
	d["pc"] = theme_src["pc"]
	var plats = []
	for p in src["platforms"]:
		plats.append(Vector4(480.0 - (p.x + p.z) if mirror else p.x, p.y, p.z, p.w))
	d["platforms"] = plats
	var mags = []
	var column = []
	for m in src["extra_magnets"]:
		var nm = Vector2(mx.call(m.x), m.y)
		mags.append(nm)
		if nm.x == 80.0 or nm.x == 400.0:
			column.append(nm)
	d["coins"] = src["coins"].map(func(c): return Vector2(mx.call(c.x), c.y))
	d["lasers"] = src["lasers"].map(func(l): return {"pos": Vector2(mx.call(l["pos"].x), l["pos"].y), "size": l["size"], "blink": l["blink"]})
	d["guards"] = src["guards"].map(func(g): return {"pos": Vector2(mx.call(g["pos"].x), g["pos"].y), "patrol": g["patrol"]})
	d["exit"] = Vector2(mx.call(src["exit"].x), src["exit"].y)
	# KAYAN mıknatıslar: sütun mıknatıslarından bazıları (en fazla 3) içeri doğru 70 px gidip gelir
	var movers = []
	var difficulty = base_num
	var n_move = 0 if column.is_empty() else min(column.size(), 1 + difficulty / 18)
	column.sort_custom(func(a, b): return a.y < b.y)  # sıra sabit: Daily herkeste aynı
	for i in n_move:
		var pick = column[r.randi_range(0, column.size() - 1)]
		if pick in movers.map(func(mv): return mv["pos"]):
			continue
		mags.erase(pick)
		movers.append({"pos": pick, "dx": 70.0 if pick.x < 240.0 else -70.0, "period": r.randf_range(2.6, 3.6)})
	d["extra_magnets"] = mags
	d["movers"] = movers
	# İTEN mıknatıslar: ortada, rastgele platform hizalarında (tasarım koordinatı, ölçeklenir)
	var repels = []
	var rows = src["platforms"].map(func(p): return p.y)
	rows.sort()
	var n_rep = 1 + (1 if difficulty >= 15 else 0) + (1 if difficulty >= 30 else 0)
	for i in n_rep:
		if rows.size() < 3:
			break
		var y = rows[r.randi_range(1, rows.size() - 2)]
		if not y in repels.map(func(v): return v.y):
			repels.append(Vector2(240.0, y))
	d["repels"] = repels
	_cache_key = key
	_cache = d
	return d
