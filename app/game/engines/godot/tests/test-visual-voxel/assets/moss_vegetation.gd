@tool
extends Node3D

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/moss_vegetation.tscn"
const BUILDER := preload("res://tests/test-visual-voxel/assets/voxel_asset_builder.gd")

@export_tool_button("GENERATE", "Callable")
var generate_moss: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_default")


func _generate_default() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the moss_vegetation asset scene to generate this asset")
		return
	var geometry := BUILDER.load_source("geometry.json")
	var room: Dictionary = geometry.get("room", {})
	var camp: Dictionary = room.get("camp_layout", {})
	var patches: Array = camp.get("vegetation", [])
	var seed := int(patches[0].get("seed", 5101)) if not patches.is_empty() else 5101
	configure_voxels(float(geometry.get("voxel_size_meters", 0.125)), seed, self)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(voxel_size: float, seed: int, scene_owner: Node = null) -> bool:
	if voxel_size <= 0.0:
		return false
	var geometry := BUILDER.load_source("geometry.json")
	var room: Dictionary = geometry.get("room", {})
	var camp: Dictionary = room.get("camp_layout", {})
	var asset_geometry: Dictionary = camp.get("asset_geometry", {})
	var definition: Dictionary = asset_geometry.get("moss_vegetation", {})
	var patch_size := BUILDER.vector3i_from_array(definition.get("patch_size_voxels", [7, 1, 5]))
	var blade_count := int(definition.get("blade_count", 5))
	var height_range: Array = definition.get("blade_height_voxels", [2, 4])
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	BUILDER.add_voxel_box(self, owner_node, "MossBed", Vector3(0.0, float(patch_size.y) * 0.5, 0.0), Vector3(patch_size), voxel_size, materials["moss"])
	for tuft in range(blade_count):
		var x := rng.randi_range(-3, 3)
		var z := rng.randi_range(-2, 2)
		var blade_height := rng.randi_range(int(height_range[0]), int(height_range[1]))
		var lean := rng.randf_range(-18.0, 18.0)
		BUILDER.add_voxel_box(self, owner_node, "GrassBlade_%02d" % tuft, Vector3(float(x), 0.5 + float(blade_height) * 0.5, float(z)), Vector3(1.0, float(blade_height), 1.0), voxel_size, materials["moss_light" if tuft % 2 == 0 else "moss"], Vector3(0.0, 0.0, lean))
	BUILDER.add_voxel_box(self, owner_node, "MossStone", Vector3(2.0, 1.0, -1.0), Vector3(2.0, 2.0, 2.0), voxel_size, materials["stone_shadow"])
	return true
