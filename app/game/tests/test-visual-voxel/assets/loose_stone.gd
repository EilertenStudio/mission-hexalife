@tool
extends Node3D

const SETTINGS := preload("res://tests/test-visual-voxel/test_visual_voxel_settings.gd")

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/loose_stone.tscn"
static var _cached_materials: Dictionary = {}
static var _cached_voxel_meshes: Dictionary = {}

@export_tool_button("GENERATE", "Callable")
var generate_loose_stone: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_asset")


func _generate_asset() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the loose_stone asset scene to generate this asset")
		return
	var geometry := _load_settings("geometry")
	var definition: Dictionary = geometry.get("room", {}).get("debris", {}).get("loose_stone_asset", {})
	var size := _vector3i_from_array(definition.get("default_size_voxels", [5, 3, 4]))
	_cached_materials.clear()
	if configure_voxels(size, int(definition.get("seed", 1901)), self):
		EditorInterface.mark_scene_as_unsaved()


## Builds a chipped stone from canonical voxels. The local origin is centered
## horizontally and anchored to the stone's bottom face.
func configure_voxels(size_voxels: Vector3i, seed: int = 1901, scene_owner: Node = null) -> bool:
	if size_voxels.x < 3 or size_voxels.y < 2 or size_voxels.z < 3:
		push_error("Loose stone dimensions must be at least 3×2×3 voxels")
		return false
	var geometry := _load_settings("geometry")
	var material_source := _load_settings("materials")
	if geometry.is_empty() or material_source.is_empty():
		return false
	var definition: Dictionary = geometry.get("room", {}).get("debris", {}).get("loose_stone_asset", {})
	var surface_material_ids: Array = definition.get("surface_material_ids", ["stone_main", "stone_mid", "stone_light", "stone_shadow"])
	var core_material_id := str(definition.get("core_material_id", "stone_deep"))
	var materials := _build_materials(material_source)
	if not materials.has(core_material_id):
		push_error("Loose stone references an unknown core material")
		return false
	for material_id in surface_material_ids:
		if not materials.has(str(material_id)):
			push_error("Loose stone references an unknown surface material: %s" % material_id)
			return false
	var voxel_size := float(geometry.get("voxel_size_meters", 0.125))
	if voxel_size <= 0.0 or surface_material_ids.is_empty():
		push_error("Loose stone requires a positive voxel size and at least one surface material")
		return false

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var occupied: Dictionary = {}
	var center_x := (float(size_voxels.x) - 1.0) * 0.5
	var center_z := (float(size_voxels.z) - 1.0) * 0.5
	var radius_x := maxf(1.0, float(size_voxels.x) * 0.5)
	var radius_z := maxf(1.0, float(size_voxels.z) * 0.5)
	for y in range(size_voxels.y):
		var layer_factor := 0.78 if y == 0 or y == size_voxels.y - 1 else 1.0
		for z in range(size_voxels.z):
			for x in range(size_voxels.x):
				var nx := (float(x) - center_x) / (radius_x * layer_factor)
				var nz := (float(z) - center_z) / (radius_z * layer_factor)
				var roughness := rng.randf_range(-0.16, 0.12)
				if nx * nx + nz * nz <= 1.08 + roughness:
					occupied[Vector3i(x, y, z)] = true
	if occupied.is_empty():
		push_error("Loose stone generation produced no voxels")
		return false

	var batches: Dictionary = {}
	for coordinate_variant in occupied:
		var coordinate: Vector3i = coordinate_variant
		var is_exposed := false
		for neighbor in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]:
			if not occupied.has(coordinate + neighbor):
				is_exposed = true
				break
		var material_id := core_material_id
		if is_exposed:
			material_id = str(surface_material_ids[rng.randi_range(0, surface_material_ids.size() - 1)])
		var position := Vector3(
			(float(coordinate.x) + 0.5 - float(size_voxels.x) * 0.5) * voxel_size,
			(float(coordinate.y) + 0.5) * voxel_size,
			(float(coordinate.z) + 0.5 - float(size_voxels.z) * 0.5) * voxel_size
		)
		_append_position(batches, material_id, position)
	var owner_node := scene_owner if scene_owner != null else self
	for material_id_variant in batches:
		var material_id := str(material_id_variant)
		_build_voxel_batch("Voxels_%s" % material_id, batches[material_id], voxel_size, materials[material_id], owner_node)
	_remove_empty_batches(batches)
	return true


func _build_voxel_batch(batch_name: String, positions: Array, voxel_size: float, material: StandardMaterial3D, scene_owner: Node) -> void:
	var batch := get_node_or_null(NodePath(batch_name)) as MultiMeshInstance3D
	if batch == null:
		batch = MultiMeshInstance3D.new()
		batch.name = batch_name
		add_child(batch)
		batch.owner = scene_owner
	var multimesh := MultiMesh.new()
	multimesh.resource_name = "%s MultiMesh" % batch_name
	multimesh.instance_count = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _get_voxel_mesh(voxel_size)
	multimesh.instance_count = positions.size()
	var half_voxel := Vector3.ONE * voxel_size * 0.5
	var bounds_min: Vector3 = positions[0] - half_voxel
	var bounds_max: Vector3 = positions[0] + half_voxel
	var instance_buffer := PackedFloat32Array()
	for index in range(positions.size()):
		var position: Vector3 = positions[index]
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, position))
		instance_buffer.append_array(PackedFloat32Array([
			1.0, 0.0, 0.0, position.x,
			0.0, 1.0, 0.0, position.y,
			0.0, 0.0, 1.0, position.z
		]))
		bounds_min = bounds_min.min(position - half_voxel)
		bounds_max = bounds_max.max(position + half_voxel)
	multimesh.buffer = instance_buffer
	multimesh.custom_aabb = AABB(bounds_min, bounds_max - bounds_min)
	batch.multimesh = multimesh
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	batch.visible = true


func _remove_empty_batches(batches: Dictionary) -> void:
	for child in get_children():
		if child is MultiMeshInstance3D and not batches.has(str(child.name).trim_prefix("Voxels_")):
			remove_child(child)
			child.free()


func _load_settings(section: String) -> Dictionary:
	return SETTINGS.get_section(section)


func _build_materials(source: Dictionary) -> Dictionary:
	if not _cached_materials.is_empty():
		return _cached_materials
	for material_id_variant in source.get("materials", {}):
		var material_id := str(material_id_variant)
		var definition: Dictionary = source["materials"][material_id]
		var material := StandardMaterial3D.new()
		material.resource_name = "%s material" % material_id
		material.albedo_color = _color_from_rgb(definition.get("color_rgb", [255, 255, 255]))
		material.roughness = float(definition.get("roughness", 0.95))
		material.metallic = float(definition.get("metallic", 0.0))
		_cached_materials[material_id] = material
	return _cached_materials


func _get_voxel_mesh(voxel_size: float) -> BoxMesh:
	if _cached_voxel_meshes.has(voxel_size):
		return _cached_voxel_meshes[voxel_size]
	var mesh := BoxMesh.new()
	mesh.resource_name = "Loose Stone Voxel Mesh"
	mesh.size = Vector3.ONE * voxel_size
	_cached_voxel_meshes[voxel_size] = mesh
	return mesh


func _append_position(groups: Dictionary, material_id: String, position: Vector3) -> void:
	if not groups.has(material_id):
		groups[material_id] = []
	groups[material_id].append(position)


func _vector3i_from_array(values: Array) -> Vector3i:
	return Vector3i(int(values[0]), int(values[1]), int(values[2]))


func _color_from_rgb(values: Array) -> Color:
	return Color(float(values[0]) / 255.0, float(values[1]) / 255.0, float(values[2]) / 255.0)
