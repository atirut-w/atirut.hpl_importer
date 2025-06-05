class_name EditorSceneFormatImporterHPL
extends EditorSceneFormatImporter


func _get_extensions() -> PackedStringArray:
	return ["hpm"]


func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	var root := Node3D.new()
	# TODO: Load fog settings, skybox, and maybe some other stuff.

	var static_objects := Node3D.new()
	static_objects.name = "StaticObjects"
	_import_static_objects("%s.hpm_StaticObject" % path.get_basename(), static_objects)
	root.add_child(static_objects)

	var primitives := Node3D.new()
	primitives.name = "Primitives"
	_import_primitives("%s.hpm_Primitive" % path.get_basename(), primitives)
	root.add_child(primitives)
	
	_fixup_owner(root, root)
	return root


func _fixup_owner(root: Node, owner: Node) -> void:
	for child in root.get_children():
		child.owner = owner
		_fixup_owner(child, owner)


func _import_static_objects(path: String, root: Node3D) -> void:
	var parser := XMLParser.new()
	if parser.open(path) != OK:
		push_error("Failed to open HPL static object file: %s" % path)
		return

	var file_index_map := {}
	var in_file_index := false
	var in_objects := false

	while true:
		var err := parser.read()
		if err != OK:
			break

		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var name = parser.get_node_name()
			if name == "FileIndex_StaticObjects":
				in_file_index = true
			elif name == "Objects":
				in_objects = true
			elif in_file_index and name == "File":
				var id = parser.get_named_attribute_value("Id")
				var file_path = parser.get_named_attribute_value("Path")
				file_index_map[id] = file_path
			elif in_objects and name == "StaticObject":
				var file_id := parser.get_named_attribute_value("FileIndex")
				var scene_path := file_index_map.get(file_id, null)
				if scene_path == null:
					push_error("StaticObject references unknown FileIndex: %s" % file_id)
					continue

				var scene_res := load(scene_path)
				if scene_res == null or not scene_res is PackedScene:
					push_error("Failed to load scene resource: %s" % scene_path)
					continue

				var instance := scene_res.instantiate() as Node3D
				if not instance is Node3D:
					push_error("Instanced scene root is not a Node3D: %s" % scene_path)
					continue

				# Parse transform attributes
				var pos_str := parser.get_named_attribute_value("WorldPos")
				var rot_str := parser.get_named_attribute_value("Rotation")
				var scale_str := parser.get_named_attribute_value("Scale")

				var pos = Vector3.ZERO
				var rot = Vector3.ZERO
				var scale = Vector3.ONE

				if pos_str != "":
					pos = _parse_vector3(pos_str)
				if rot_str != "":
					rot = _parse_vector3(rot_str)
				if scale_str != "":
					scale = _parse_vector3(scale_str)

				instance.position = pos
				instance.rotation_order = EULER_ORDER_ZYX
				instance.rotation = rot
				instance.scale = scale

				# Set name
				instance.name = parser.get_named_attribute_value("Name")

				# TODO: Set other properties like collision, shadows, occlusion, color, etc.

				root.add_child(instance)

		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			var name = parser.get_node_name()
			if name == "FileIndex_StaticObjects":
				in_file_index = false
			elif name == "Objects":
				in_objects = false


func _parse_vector3(str: String) -> Vector3:
	var parts = str.split(" ")
	if parts.size() != 3:
		return Vector3.ZERO
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())

func _import_primitives(path: String, root: Node3D) -> void:
	var parser := XMLParser.new()
	if parser.open(path) != OK:
		push_error("Failed to open HPL primitive file: %s" % path)
		return

	while true:
		var err := parser.read()
		if err != OK:
			break

		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var name = parser.get_node_name()
			if name == "Plane":
				var pos_str := parser.get_named_attribute_value("WorldPos")
				var rot_str := parser.get_named_attribute_value("Rotation")
				var scale_str := parser.get_named_attribute_value("Scale")
				var material_path := parser.get_named_attribute_value("Material")
				var name_attr := parser.get_named_attribute_value("Name")
				var start_corner_str := parser.get_named_attribute_value("StartCorner")
				var end_corner_str := parser.get_named_attribute_value("EndCorner")

				var pos = Vector3.ZERO
				var rot = Vector3.ZERO
				var scale = Vector3.ONE

				if pos_str != "":
					pos = _parse_vector3(pos_str)
				if rot_str != "":
					rot = _parse_vector3(rot_str)
				if scale_str != "":
					scale = _parse_vector3(scale_str)

				var mesh_instance := MeshInstance3D.new()
				mesh_instance.name = name_attr
				mesh_instance.position = pos
				mesh_instance.rotation_order = EULER_ORDER_ZYX
				mesh_instance.rotation = rot
				mesh_instance.scale = scale

				# Create a simple rectangular plane mesh based on StartCorner and EndCorner
				var start_corner = Vector3.ZERO
				var end_corner = Vector3.ZERO
				if start_corner_str != "":
					start_corner = _parse_vector3(start_corner_str)
				if end_corner_str != "":
					end_corner = _parse_vector3(end_corner_str)

				var size = end_corner - start_corner
				var st = SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)

				var v0 = Vector3(start_corner.x, start_corner.y, start_corner.z)
				var v1 = Vector3(end_corner.x, start_corner.y, start_corner.z)
				var v2 = Vector3(end_corner.x, start_corner.y, end_corner.z)
				var v3 = Vector3(start_corner.x, start_corner.y, end_corner.z)

				st.add_vertex(v0)
				st.add_vertex(v1)
				st.add_vertex(v2)

				st.add_vertex(v0)
				st.add_vertex(v2)
				st.add_vertex(v3)

				st.generate_normals()
				var mesh = st.commit()
				mesh_instance.mesh = mesh

				# Load material if available
				if material_path != "":
					var material_res = load(material_path)
					if material_res != null and material_res is Material:
						mesh_instance.material_override = material_res

				root.add_child(mesh_instance)
