@tool
extends Node3D

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/torch_sconce.tscn"
const BUILDER := preload("res://tests/test-visual-voxel/assets/voxel_asset_builder.gd")

@export_tool_button("GENERATE", "Callable")
var generate_torch: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_default")


func _generate_default() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the torch_sconce asset scene to generate this asset")
		return
	var geometry := BUILDER.load_source("geometry.json")
	configure_voxels(float(geometry.get("voxel_size_meters", 0.125)), self)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(voxel_size: float, scene_owner: Node = null) -> bool:
	if voxel_size <= 0.0:
		return false
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	BUILDER.add_voxel_box(self, owner_node, "StoneMount", Vector3(0.0, 0.0, 0.0), Vector3(4.0, 4.0, 2.0), voxel_size, materials["stone_deep"])
	BUILDER.add_voxel_box(self, owner_node, "IronArm", Vector3(0.0, -1.0, 2.0), Vector3(2.0, 2.0, 4.0), voxel_size, materials["stone_shadow"])
	BUILDER.add_voxel_box(self, owner_node, "WoodenHandle", Vector3(0.0, 0.0, 4.0), Vector3(2.0, 6.0, 2.0), voxel_size, materials["wood_dark"])
	BUILDER.add_voxel_box(self, owner_node, "FireCup", Vector3(0.0, 2.0, 4.0), Vector3(4.0, 2.0, 4.0), voxel_size, materials["stone_light"])
	BUILDER.add_voxel_box(self, owner_node, "TorchFlame_Base", Vector3(0.0, 4.5, 4.0), Vector3(3.0, 3.0, 3.0), voxel_size, materials["fire_amber"])
	BUILDER.add_voxel_box(self, owner_node, "TorchFlame_Core", Vector3(0.0, 5.5, 4.0), Vector3(1.5, 2.0, 1.5), voxel_size, materials["torch_flame"])
	var light_definition := BUILDER.load_light_definition("torch")
	var light_offset: Array = light_definition.get("position_offset_meters", [0.0, 0.5, 0.5])
	BUILDER.add_omni_light(
		self, owner_node, "TorchLight",
		Vector3(float(light_offset[0]), float(light_offset[1]), float(light_offset[2])),
		BUILDER.color_from_rgb(light_definition.get("color_rgb", [255, 140, 56])),
		float(light_definition.get("energy", 1.05)),
		float(light_definition.get("range_meters", 4.6))
	)
	var smoke_definition := BUILDER.load_particle_definition("torch_smoke")
	BUILDER.add_smoke(self, owner_node, "TorchSmoke", Vector3(0.0, 0.72, 0.5), voxel_size, smoke_definition)
	return true
