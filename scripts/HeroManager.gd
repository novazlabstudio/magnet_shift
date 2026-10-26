extends Node

var selected_hero: int = 0  # 0=Cyborg, 1=Pink Girl, 2=Shadow, 3=Mech

func save_hero(idx: int):
	var f = FileAccess.open("user://hero.dat", FileAccess.WRITE)
	if f:
		f.store_8(idx)
		f.close()

func load_hero():
	if not FileAccess.file_exists("user://hero.dat"):
		selected_hero = 0
		return
	var f = FileAccess.open("user://hero.dat", FileAccess.READ)
	if f:
		selected_hero = clamp(f.get_8(), 0, 3)
		f.close()

func get_hero() -> int:
	return selected_hero
