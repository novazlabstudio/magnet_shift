extends CanvasLayer

var overlay: ColorRect
var is_transitioning: bool = false

func _ready():
	layer = 10  # Her şeyin üstünde
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func flash_and_load(scene_path: String):
	if is_transitioning:
		return
	is_transitioning = true

	# Flash beyaz → siyah → sahne yükle → siyahtan aç
	var tween = create_tween()
	# Önce beyaz flash
	tween.tween_property(overlay, "color", Color(1, 1, 1, 0.9), 0.12)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1.0), 0.25)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
	)

func fade_in():
	# Yeni sahne yüklenince siyahtan açılır
	overlay.color = Color(0, 0, 0, 1.0)
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.4)
	tween.tween_callback(func():
		is_transitioning = false
	)

func flash_death():
	# Ölünce kırmızı flash
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.8, 0.0, 0.0, 0.5), 0.08)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.3)
