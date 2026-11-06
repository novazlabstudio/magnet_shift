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

# ── Ses efektleri ────────────────────────────────────────────────────────────
# audio/sfx/*.wav (tools/gen_sfx.py ile üretilir). Aynı anda birkaç efekt çalabilsin diye
# küçük bir oynatıcı havuzu kullanılıyor; sahne değişse de çalmaya devam eder (autoload).
const SFX_POOL_SIZE := 6
var _sfx_players: Array = []
var _sfx_cache: Dictionary = {}

func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _sound_on:
		return
	if not _sfx_cache.has(sfx_name):
		_sfx_cache[sfx_name] = load("res://audio/sfx/%s.wav" % sfx_name)
	var stream = _sfx_cache[sfx_name]
	if stream == null:
		return
	if _sfx_players.is_empty():
		for i in SFX_POOL_SIZE:
			var p = AudioStreamPlayer.new()
			p.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(p)
			_sfx_players.append(p)
	var player: AudioStreamPlayer = _sfx_players[0]
	for p in _sfx_players:
		if not p.playing:
			player = p
			break
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
