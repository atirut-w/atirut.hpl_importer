class_name EditorSceneFormatImporterHPL
extends EditorSceneFormatImporter


func _get_extensions() -> PackedStringArray:
	return ["hpm"]


func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	return Node3D.new()
