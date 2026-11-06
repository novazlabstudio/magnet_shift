extends Node2D

# LevelBackdrop'un tek bir çizim katmanı. Çizimi sahibine (painter) devreder.
# animated=false katmanlar bir kez çizilip önbellekte kalır; true olanlar her kare yeniden çizilir.
var painter: Object = null
var id: String = ""
var animated: bool = false

func _process(_delta: float) -> void:
	if animated:
		queue_redraw()

func _draw() -> void:
	if painter:
		painter.paint_layer(self, id)
