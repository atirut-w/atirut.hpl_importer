@tool
extends EditorPlugin


var hpl_importer: EditorSceneFormatImporterHPL
var mat_importer: ResourceImporterHPLMat


func _enter_tree() -> void:
	hpl_importer = EditorSceneFormatImporterHPL.new()
	mat_importer = ResourceImporterHPLMat.new()

	add_scene_format_importer_plugin(hpl_importer)
	add_import_plugin(mat_importer)


func _exit_tree() -> void:
	remove_scene_format_importer_plugin(hpl_importer)
	remove_import_plugin(mat_importer)

	hpl_importer = null
	mat_importer = null
