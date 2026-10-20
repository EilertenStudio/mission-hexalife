@tool
extends Node3D

const SETTINGS := preload("res://tests/test-visual-voxel/test_visual_voxel_settings.gd")

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/stone_masonry_block.tscn"
static var _cached_materials: Dictionary = {}
static var _cached_voxel_meshes: Dictionary = {}

@export_tool_button("GENERATE", "Callable")
var generate_stone_masonry_block: Callable = _queue_block_generation


func _queue_block_generation() -> void:
	if not Engine.is_editor_hint():
		return
	call_deferred("_generate_block_asset")


func _generate_block_asset() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the stone_masonry_block asset scene to generate this asset")
		return

	var geometry := _load_settings("geometry")
	var room: Dictionary = geometry.get("room", {})
	var walls: Dictionary = room.get("walls", {})
	var definition: Dictionary = walls.get("block_asset", {})
	var default_size: Vector3i = _vector3i_from_array(definition.get("default_size_voxels", [5, 3, 6]))
	var unit_size: Vector3i = _vector3i_from_array(definition.get("unit_size_voxels", [1, 1, 1]))
	_cached_materials.clear()
	if configure_voxels(
		Vector3i(default_size.x * unit_size.x, default_size.y * unit_size.y, default_size.z * unit_size.z),
		str(definition.get("surface_material_id", "stone_main")),
		self
	):
		EditorInterface.mark_scene_as_unsaved()


## Rebuilds this block's voxel batches. Existing asset children retain their
## asset ownership; the optional owner is used only if a batch must be added.
func configure_voxels(size_voxels: Vector3i, surface_material_id: String, scene_owner: Node = null) -> bool:
	if size_voxels.x < 3 or size_voxels.y < 3 or size_voxels.z < 1:
		push_error("Stone masonry block dimensions must be at least 3×3×1 voxels")
		return false

	var geometry := _load_settings("geometry")
	var material_source := _load_settings("materials")
	if geometry.is_empty() or material_source.is_empty():
		return false
	var room: Dictionary = geometry.get("room", {})
	var wall_definition: Dictionary = room.get("walls", {})
	var asset_definition: Dictionary = wall_definition.get("block_asset", {})
	var materials := _build_materials(material_source)
	var joint_material_id := str(asset_definition.get("joint_material_id", "stone_joint"))
	var core_material_id := str(asset_definition.get("core_material_id", "stone_deep"))
	var border := int(asset_definition.get("joint_border_voxels", 1))
	if not materials.has(surface_material_id) or not materials.has(joint_material_id) or not materials.has(core_material_id):
		push_error("Stone masonry block references an unknown material")
		return false
	if size_voxels.x <= border * 2 or size_voxels.y <= border * 2:
		push_error("Stone masonry block dimensions must leave an inner stone voxel layer")
		return false

	var voxel_size := float(geometry.get("voxel_size_meters", 0.125))
	if voxel_size <= 0.0:
		push_error("Canonical voxel size must be positive")
		return false
	var batches: Dictionary = {}
	var owner_node := scene_owner if scene_owner != null else self
	var origin := -Vector3(size_voxels) * voxel_size * 0.5
	for y in range(size_voxels.y):
		for z in range(size_voxels.z):
			for x in range(size_voxels.x):
				var material_id := core_material_id
				var is_joint := (
					x < border
					or x >= size_voxels.x - border
					or y < border
					or y >= size_voxels.y - border
				)
				if is_joint:
					material_id = joint_material_id
				elif z == 0 or z == size_voxels.z - 1:
					material_id = surface_material_id
				var position := origin + Vector3(
					(float(x) + 0.5) * voxel_size,
					(float(y) + 0.5) * voxel_size,
					(float(z) + 0.5) * voxel_size
				)
				_append_position(batches, material_id, position)

	for material_id_variant in batches:
		var material_id := str(material_id_variant)
		var batch_name := "JointVoxels" if material_id == joint_material_id else (
			"CoreVoxels" if material_id == core_material_id else "StoneVoxels"
		)
		_build_voxel_batch(batch_name, batches[material_id], voxel_size, materials[material_id], owner_node)
	for batch_name in ["JointVoxels", "CoreVoxels", "StoneVoxels"]:
		var batch := get_node_or_null(NodePath(batch_name)) as MultiMeshInstance3D
		var material_id := joint_material_id if batch_name == "JointVoxels" else (
			core_material_id if batch_name == "CoreVoxels" else surface_material_id
		)
		if batch != null and not batches.has(material_id):
			remove_child(batch)
			batch.free()
	return true


func _build_voxel_batch(
	batch_name: String,
	voxel_positions: Array,
	voxel_size: float,
	material: StandardMaterial3D,
	scene_owner: Node
) -> void:
	if voxel_positions.is_empty():
		return
	var batch := get_node_or_null(NodePath(batch_name)) as MultiMeshInstance3D
	if batch == null:
		batch = MultiMeshInstance3D.new()
		batch.name = batch_name
		add_child(batch)
		# Existing children of an instanced asset must keep the asset root as
		# their owner. Reassigning them to the composed scene root duplicates
		# them alongside the editable instance's inherited children.
		batch.owner = scene_owner
	batch.visible = true

	var voxel_mesh := _get_voxel_mesh(voxel_size)
	var multimesh := MultiMesh.new()
	multimesh.resource_name = "%s MultiMesh" % batch_name
	multimesh.instance_count = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = voxel_mesh
	multimesh.instance_count = voxel_positions.size()
	var half_voxel := Vector3.ONE * voxel_size * 0.5
	var bounds_min: Vector3 = voxel_positions[0] - half_voxel
	var bounds_max: Vector3 = voxel_positions[0] + half_voxel
	var instance_buffer := PackedFloat32Array()
	for index in range(voxel_positions.size()):
		var voxel_position: Vector3 = voxel_positions[index]
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, voxel_position))
		instance_buffer.append_array(PackedFloat32Array([
			1.0, 0.0, 0.0, voxel_position.x,
			0.0, 1.0, 0.0, voxel_position.y,
			0.0, 0.0, 1.0, voxel_position.z
		]))
		bounds_min = bounds_min.min(voxel_position - half_voxel)
		bounds_max = bounds_max.max(voxel_position + half_voxel)
	multimesh.buffer = instance_buffer
	multimesh.custom_aabb = AABB(bounds_min, bounds_max - bounds_min)
	batch.multimesh = multimesh
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


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
	var voxel_mesh := BoxMesh.new()
	voxel_mesh.resource_name = "Stone Masonry Voxel Mesh"
	voxel_mesh.size = Vector3.ONE * voxel_size
	_cached_voxel_meshes[voxel_size] = voxel_mesh
	return voxel_mesh


func _append_position(groups: Dictionary, material_id: String, position: Vector3) -> void:
	if not groups.has(material_id):
		groups[material_id] = []
	groups[material_id].append(position)


func _vector3i_from_array(values: Array) -> Vector3i:
	return Vector3i(int(values[0]), int(values[1]), int(values[2]))


func _color_from_rgb(values: Array) -> Color:
	return Color(float(values[0]) / 255.0, float(values[1]) / 255.0, float(values[2]) / 255.0)
