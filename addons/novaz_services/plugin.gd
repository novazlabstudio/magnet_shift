@tool
extends EditorPlugin

# Android dışa aktarımında Play Games + bildirim kütüphanesini ve Godot eklentisini ekler.
var _export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	_export_plugin = preload("res://addons/novaz_services/export_plugin.gd").new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null
