extends Node

var selected_hero: int = 0  # 0=Cyborg, 1=Pink Girl, 2=Shadow, 3=Mech, 4=Blaze

# BLAZE seviye ile değil, 3 ödüllü reklam izlenerek açılır. İlerleme her reklamda kaydedilir.
const BLAZE_ID := 4
const BLAZE_ADS_REQUIRED := 3
var blaze_ads: int = 0

func save_hero(idx: int):
	var f = FileAccess.open("user://hero.dat", FileAccess.WRITE)
	if f:
		f.store_8(idx)
		f.close()

func load_hero():
	_load_blaze_ads()
	if not FileAccess.file_exists("user://hero.dat"):
		selected_hero = 0
		return
	var f = FileAccess.open("user://hero.dat", FileAccess.READ)
	if f:
		selected_hero = clamp(f.get_8(), 0, BLAZE_ID)
		f.close()
	if selected_hero == BLAZE_ID and not is_blaze_unlocked():
		selected_hero = 0

func get_hero() -> int:
	return selected_hero

func is_blaze_unlocked() -> bool:
	return blaze_ads >= BLAZE_ADS_REQUIRED

func add_blaze_ad():
	blaze_ads = min(blaze_ads + 1, BLAZE_ADS_REQUIRED)
	var f = FileAccess.open("user://blaze_ads.dat", FileAccess.WRITE)
	if f:
		f.store_8(blaze_ads)
		f.close()

func _load_blaze_ads():
	if not FileAccess.file_exists("user://blaze_ads.dat"):
		blaze_ads = 0
		return
	var f = FileAccess.open("user://blaze_ads.dat", FileAccess.READ)
	if f:
		blaze_ads = clamp(f.get_8(), 0, BLAZE_ADS_REQUIRED)
		f.close()
