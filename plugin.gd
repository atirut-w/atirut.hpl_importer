@tool
extends EditorPlugin


var importer: EditorSceneFormatImporterHPL


func _enter_tree() -> void:
	importer = EditorSceneFormatImporterHPL.new()
	add_scene_format_importer_plugin(importer)


func _exit_tree() -> void:
	remove_scene_format_importer_plugin(importer)
	importer = null
