class_name ResourceImporterHPLMat
extends EditorImportPlugin


enum Presets {
	DEFAULT
}


func _get_importer_name() -> String:
	return "atirut.hpl_mat"


func _get_visible_name() -> String:
	return "HPL3 Material"


func _get_recognized_extensions() -> PackedStringArray:
	return ["mat"]


func _get_save_extension() -> String:
	return "tres"


func _get_resource_type() -> String:
	return "ShaderMaterial"


func _get_priority() -> float:
	return 1.0


func _get_preset_count() -> int:
	return Presets.size()


func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown Preset"


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	match preset_index:
		Presets.DEFAULT:
			return [] # TODO: Think of possible import options
		_:
			return []


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var parser := XMLParser.new()
	if parser.open(source_file) != OK:
		push_error("Failed to open HPL material file: %s" % source_file)
		return ERR_CANT_OPEN
	
	var material := ShaderMaterial.new()

	var err := ResourceSaver.save(material, "%s.%s" % [save_path, _get_save_extension()])
	if err != OK:
		push_error("Failed to save material: %s" % err)
		return err
	return OK
