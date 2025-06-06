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


func _resolve_texture_path(path: String) -> String:
	if path.is_empty():
		return path
	
	if ResourceLoader.exists(path):
		return path
	
	var normalized_path = path.replace("\\", "/")
	
	var components = normalized_path.split("/")
	
	for i in range(components.size() - 1, 0, -1):
		var subpath = "/".join(components.slice(i))
		
		if FileAccess.file_exists(subpath):
			print("Resolved texture path: ", path, " -> ", subpath)
			return subpath
	
	push_error("Could not resolve texture path: ", path)
	return path

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var parser := XMLParser.new()
	if parser.open(source_file) != OK:
		push_error("Failed to open HPL material file: %s" % source_file)
		return ERR_CANT_OPEN
	
	var material := ShaderMaterial.new()
	
	# Load the HPL3 shader
	var shader := load("uid://dm1drv680q102")
	if shader == null:
		push_error("Failed to load HPL3 shader")
		return ERR_CANT_OPEN
	material.shader = shader
	
	# Parse XML and extract texture file paths
	var diffuse_path := ""
	var normal_path := ""
	var specular_path := ""
	
	while true:
		var err := parser.read()
		if err != OK:
			break
		
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var name := parser.get_node_name()
			if name == "Diffuse":
				diffuse_path = parser.get_named_attribute_value("File")
			elif name == "NMap":
				normal_path = parser.get_named_attribute_value("File")
			elif name == "Specular":
				specular_path = parser.get_named_attribute_value("File")
	
	# Resolve and load textures and assign to material uniforms
	if diffuse_path != "":
		var resolved_diffuse_path = _resolve_texture_path(diffuse_path)
		var diffuse_tex = load(resolved_diffuse_path)
		if diffuse_tex != null and diffuse_tex is Texture:
			material.set_shader_parameter("diffuse_texture", diffuse_tex)
	if normal_path != "":
		var resolved_normal_path = _resolve_texture_path(normal_path)
		var normal_tex = load(resolved_normal_path)
		if normal_tex != null and normal_tex is Texture:
			material.set_shader_parameter("normal_texture", normal_tex)
	if specular_path != "":
		var resolved_specular_path = _resolve_texture_path(specular_path)
		var specular_tex = load(resolved_specular_path)
		if specular_tex != null and specular_tex is Texture:
			material.set_shader_parameter("specular_texture", specular_tex)
	
	var err := ResourceSaver.save(material, "%s.%s" % [save_path, _get_save_extension()])
	if err != OK:
		push_error("Failed to save material: %s" % err)
		return err
	return OK
