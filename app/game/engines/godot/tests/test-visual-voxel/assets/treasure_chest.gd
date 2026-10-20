@tool
extends Node3D

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/treasure_chest.tscn"
const BUILDER := preload("res://tests/test-visual-voxel/assets/voxel_asset_builder.gd")

@export_tool_button("GENERATE", "Callable")
var generate_chest: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_default")


func _generate_default() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the treasure_chest asset scene to generate this asset")
		return
	var geometry := BUILDER.load_source("geometry.json")
	configure_voxels(float(geometry.get("voxel_size_meters", 0.125)), self)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(voxel_size: float, scene_owner: Node = null) -> bool:
	if voxel_size <= 0.0:
		return false
	var geometry := BUILDER.load_source("geometry.json")
	var room: Dictionary = geometry.get("room", {})
	var camp: Dictionary = room.get("camp_layout", {})
	var asset_geometry: Dictionary = camp.get("asset_geometry", {})
	var definition: Dictionary = asset_geometry.get("treasure_chest", {})
	var footprint: Array = definition.get("footprint_voxels", [14, 10])
	var chest_width := float(footprint[0])
	var chest_depth := float(footprint[1])
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	BUILDER.add_voxel_box(self, owner_node, "ChestFoot", Vector3(0.0, 1.0, 0.0), Vector3(chest_width, 2.0, chest_depth), voxel_size, materials["wood_dark"])
	BUILDER.add_voxel_box(self, owner_node, "ChestBody", Vector3(0.0, 4.0, 0.0), Vector3(chest_width - 2.0, 5.0, chest_depth - 2.0), voxel_size, materials["wood_main"])
	BUILDER.add_voxel_box(self, owner_node, "ChestRim", Vector3(0.0, 6.7, 0.0), Vector3(chest_width - 1.0, 1.0, chest_depth - 1.0), voxel_size, materials["wood_light"])
	for side in [-1.0, 1.0]:
		BUILDER.add_voxel_box(self, owner_node, "ChestCorner_%s" % int(side), Vector3(side * (chest_width * 0.5 - 1.8), 4.0, 0.0), Vector3(1.5, 5.0, chest_depth - 1.0), voxel_size, materials["gold"])
	BUILDER.add_voxel_box(self, owner_node, "FrontLock", Vector3(0.0, 4.8, chest_depth * 0.5 - 0.3), Vector3(2.0, 2.5, 1.0), voxel_size, materials["gold"])
	var lid := BUILDER.add_group(self, owner_node, "OpenLid")
	var lid_pivot_z := -chest_depth * 0.5 + 0.7
	var lid_center_z := chest_depth * 0.5 - 0.7
	lid.position = Vector3(0.0, 7.0, lid_pivot_z) * voxel_size
	lid.rotation_degrees.x = float(definition.get("lid_open_angle_degrees", -120))
	BUILDER.add_voxel_box(lid, owner_node, "LidPanel", Vector3(0.0, 0.0, lid_center_z), Vector3(chest_width - 1.0, 2.0, chest_depth - 1.0), voxel_size, materials["wood_main"])
	BUILDER.add_voxel_box(lid, owner_node, "LidInner", Vector3(0.0, -0.7, lid_center_z), Vector3(chest_width - 4.0, 0.6, chest_depth - 3.5), voxel_size, materials["wood_dark"])
	BUILDER.add_voxel_box(self, owner_node, "Overflow_Coin_01", Vector3(-4.0, 8.0, 0.5), Vector3(3.0, 1.0, 2.0), voxel_size, materials["gold"])
	BUILDER.add_voxel_box(self, owner_node, "Overflow_Coin_02", Vector3(3.5, 8.3, 0.0), Vector3(2.0, 1.0, 2.0), voxel_size, materials["gold"])
	BUILDER.add_voxel_box(self, owner_node, "Overflow_Gold_03", Vector3(0.0, 8.1, 2.6), Vector3(3.0, 1.0, 2.0), voxel_size, materials["gold"])
	BUILDER.add_voxel_box(self, owner_node, "Ruby", Vector3(-1.6, 9.2, 0.2), Vector3(2.0, 2.0, 2.0), voxel_size, materials["gem_ruby"])
	BUILDER.add_voxel_box(self, owner_node, "Sapphire", Vector3(1.7, 9.3, 1.5), Vector3(2.0, 2.0, 2.0), voxel_size, materials["gem_sapphire"])
	BUILDER.add_voxel_box(self, owner_node, "GoldStack", Vector3(4.3, 9.0, -0.8), Vector3(2.0, 2.0, 3.0), voxel_size, materials["gold"])
	return true
