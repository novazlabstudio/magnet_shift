class_name UIFont
extends RefCounted

# Oyunun başlık/buton fontu: Orbitron Bold (SIL Open Font License, fonts/ klasöründe).
# title(n): harf aralığı n piksel açılmış hali (FontVariation), önbellekli.
static var _base: Font = null
static var _cache: Dictionary = {}

static func title(spacing: int = 0) -> Font:
	if _base == null:
		_base = load("res://fonts/Orbitron-Bold.ttf")
	if spacing == 0:
		return _base
	if not _cache.has(spacing):
		var fv = FontVariation.new()
		fv.base_font = _base
		fv.spacing_glyph = spacing
		_cache[spacing] = fv
	return _cache[spacing]
