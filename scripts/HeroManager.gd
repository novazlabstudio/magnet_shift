extends Node

var selected_hero: int = 0  # 0=Cyborg, 1=Pink Girl, 2=Shadow, 3=Mech, 4=Blaze, 5=Polaris, 6=Ferro
const HERO_COUNT := 7
const HERO_NAMES := ["Cyborg", "Pink", "Shadow", "Mech", "Blaze", "Polaris", "Ferro"]

# Reklamla açılan kahramanlar: seviye ile değil, ödüllü reklam izlenerek açılır.
# İlerleme her reklamda ayrı dosyaya kaydedilir (blaze_ads.dat eski sürümle aynı; mevcut ilerleme korunur).
const BLAZE_ID := 4
const POLARIS_ID := 5
const FERRO_ID := 6
const AD_HEROES := {
	BLAZE_ID: {"file": "user://blaze_ads.dat", "required": 3, "name": "BLAZE"},
	POLARIS_ID: {"file": "user://polaris_ads.dat", "required": 3, "name": "POLARIS"},
	FERRO_ID: {"file": "user://ferro_ads.dat", "required": 3, "name": "FERRO"},
}
const BLAZE_ADS_REQUIRED := 3
var ad_progress: Dictionary = {}

# Eski kodla uyumluluk
var blaze_ads: int:
	get:
		return ads_watched(BLAZE_ID)

func save_hero(idx: int):
	var f = FileAccess.open("user://hero.dat", FileAccess.WRITE)
	if f:
		f.store_8(idx)
		f.close()

func load_hero():
	_load_ad_progress()
	if not FileAccess.file_exists("user://hero.dat"):
		selected_hero = 0
		return
	var f = FileAccess.open("user://hero.dat", FileAccess.READ)
	if f:
		selected_hero = clamp(f.get_8(), 0, HERO_COUNT - 1)
		f.close()
	if is_ad_hero(selected_hero) and not is_ad_hero_unlocked(selected_hero):
		selected_hero = 0

func get_hero() -> int:
	return selected_hero

func is_ad_hero(id: int) -> bool:
	return AD_HEROES.has(id)

func ads_required(id: int) -> int:
	return AD_HEROES[id]["required"] if AD_HEROES.has(id) else 0

func ads_watched(id: int) -> int:
	return ad_progress.get(id, 0)

func is_ad_hero_unlocked(id: int) -> bool:
	return ads_watched(id) >= ads_required(id)

func add_ad_view(id: int) -> void:
	if not AD_HEROES.has(id):
		return
	ad_progress[id] = min(ads_watched(id) + 1, ads_required(id))
	var f = FileAccess.open(AD_HEROES[id]["file"], FileAccess.WRITE)
	if f:
		f.store_8(ad_progress[id])
		f.close()

func is_blaze_unlocked() -> bool:
	return is_ad_hero_unlocked(BLAZE_ID)

func add_blaze_ad():
	add_ad_view(BLAZE_ID)

func _load_ad_progress():
	for id in AD_HEROES:
		var path = AD_HEROES[id]["file"]
		ad_progress[id] = 0
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				ad_progress[id] = clamp(f.get_8(), 0, ads_required(id))
				f.close()
