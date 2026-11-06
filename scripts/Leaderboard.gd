extends RefCounted

# Skor tablosu (BOARD). Her "koşu" (Level 1'den ya da menüden yeniden başlayan oyun) tabloda
# tek satırdır ve her level bitişinde güncellenir. Böylece koşu nasıl biterse bitsin
# (game over, MAIN MENU, RESTART, uygulamayı kapatmak) ulaşılan skor tabloda kalır.
# Eskiden yalnızca game over'da ve Level 50 bitince yazılıyordu; bu yüzden tablo neredeyse hiç dolmuyordu.

const PATH := "user://leaderboard.json"
const LEGACY_PATH := "user://leaderboard.dat"  # eski ikili format; taşındıktan sonra yedek olarak durur
const RUN_PATH := "user://current_run.txt"
const MAX_ENTRIES := 5

static func load_entries() -> Array:
	if FileAccess.file_exists(PATH):
		var f = FileAccess.open(PATH, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			f.close()
			if data is Array:
				var out = []
				for e in data:
					if e is Dictionary and e.has("score"):
						out.append({"score": int(e["score"]), "level": int(e.get("level", 1)),
							"date": str(e.get("date", "")), "run": str(e.get("run", ""))})
				return out
	var legacy = _load_legacy()
	if legacy.size() > 0:
		save_entries(legacy)
	return legacy

static func save_entries(entries: Array) -> void:
	var f = FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(entries))
		f.close()

# Yeni koşu başlatır (skor sıfırlandığında çağrılır)
static func start_new_run() -> void:
	var f = FileAccess.open(RUN_PATH, FileAccess.WRITE)
	if f:
		f.store_string("%d-%d" % [Time.get_unix_time_from_system(), randi() % 100000])
		f.close()

static func current_run() -> String:
	if not FileAccess.file_exists(RUN_PATH):
		start_new_run()
	var f = FileAccess.open(RUN_PATH, FileAccess.READ)
	if not f:
		return ""
	var id = f.get_as_text().strip_edges()
	f.close()
	return id

# Koşunun satırını ekler ya da günceller. 0 puan yazılmaz. Güncel tabloyu döndürür.
static func record(score: int, level: int) -> Array:
	var entries = load_entries()
	if score <= 0:
		return entries
	var run = current_run()
	var found = false
	for e in entries:
		if run != "" and e["run"] == run:
			e["score"] = max(e["score"], score)
			e["level"] = max(e["level"], level)
			e["date"] = Time.get_date_string_from_system()
			found = true
	if not found:
		entries.append({"score": score, "level": level, "date": Time.get_date_string_from_system(), "run": run})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(0, MAX_ENTRIES)
	save_entries(entries)
	return entries

static func is_current_run(e: Dictionary) -> bool:
	return e.get("run", "") != "" and e["run"] == current_run()

static func _load_legacy() -> Array:
	if not FileAccess.file_exists(LEGACY_PATH):
		return []
	var f = FileAccess.open(LEGACY_PATH, FileAccess.READ)
	if not f:
		return []
	var entries = []
	var count = f.get_8()
	for i in count:
		if f.eof_reached():
			break
		var score = f.get_32()
		var level = f.get_8()
		var date_len = f.get_8()
		var date = ""
		for j in date_len:
			date += char(f.get_8())
		entries.append({"score": score, "level": level, "date": date, "run": ""})
	f.close()
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	return entries
