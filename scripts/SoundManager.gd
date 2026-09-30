extends Node

# Global singleton - autoload olarak eklenecek
var _sound_on: bool = true

func is_on() -> bool:
	return _sound_on

func toggle():
	_sound_on = !_sound_on
	# Kaydet
	var f = FileAccess.open("user://sound_setting.dat", FileAccess.WRITE)
	if f:
		f.store_8(1 if _sound_on else 0)
		f.close()

func load_setting():
	if FileAccess.file_exists("user://sound_setting.dat"):
		var f = FileAccess.open("user://sound_setting.dat", FileAccess.READ)
		if f:
			_sound_on = f.get_8() == 1
			f.close()
