@tool
extends EditorScript

func _run():
	for i in range(21, 51):
		var source = ResourceLoader.load("res://scenes/Level20.tscn")
		var scene = source.instantiate()
		scene.level_number = i
		if i < 50:
			scene.next_level_path = "res://scenes/Level%d.tscn" % (i + 1)
		else:
			scene.next_level_path = ""
		var new_scene = PackedScene.new()
		new_scene.pack(scene)
		ResourceSaver.save(new_scene, "res://scenes/Level%d.tscn" % i)
		scene.queue_free()
		print("Created Level%d.tscn" % i)
	print("Done!")
