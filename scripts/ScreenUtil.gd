extends RefCounted

# Ekran yardımcıları. Taban tasarım 480x854; stretch aspect = keep_width olduğu için
# uzun ekranlı telefonlarda viewport genişlik 480 kalıp dikeyde uzar (siyah bant yerine).
# Sabit koordinatlarla yerleştirilmiş UI bu fonksiyonlarla ortalanır / çentikten kaçırılır.

const BASE_H := 854.0

static func viewport_height(node: Node) -> float:
	return node.get_viewport().get_visible_rect().size.y

# Sabit konumlu içeriği (paneller, menü) dikeyde ortalamak için kaydırma miktarı
static func center_offset(node: Node) -> float:
	return max(0.0, viewport_height(node) - BASE_H) / 2.0

# Çentik / kamera deliği / durum çubuğu için üstte bırakılacak pay (viewport biriminde)
static func safe_top(node: Node) -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var win_h = DisplayServer.window_get_size().y
	if win_h <= 0:
		return 0.0
	var safe = DisplayServer.get_display_safe_area()
	var inset_px = safe.position.y - DisplayServer.window_get_position().y
	if inset_px <= 0:
		return 0.0
	return inset_px * viewport_height(node) / win_h

# Ebeveynin doğrudan çocuklarını dikeyde kaydırır. Alta/tam ekrana anchor'lı
# Control'ler (overlay, alt ipucu) zaten ekrana göre yerleştiği için atlanır.
static func shift_children(parent: Node, dy: float, skip: Array = []) -> void:
	if dy == 0.0:
		return
	for c in parent.get_children():
		if c in skip:
			continue
		if c is Control:
			if c.anchor_bottom >= 1.0:
				continue
			c.position.y += dy
		elif c is Node2D:
			c.position.y += dy
