@tool
extends Node3D

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/jerv_camp.tscn"
const BUILDER := preload("res://tests/test-visual-voxel/assets/voxel_asset_builder.gd")

@export_tool_button("GENERATE", "Callable")
var generate_jerv: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_default")


func _generate_default() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the jerv_camp asset scene to generate this asset")
		return
	var geometry := BUILDER.load_settings("geometry")
	configure_voxels(float(geometry.get("voxel_size_meters", 0.125)), self)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(voxel_size: float, scene_owner: Node = null) -> bool:
	if voxel_size <= 0.0:
		return false
	var geometry := BUILDER.load_settings("geometry")
	var room: Dictionary = geometry.get("room", {})
	var camp: Dictionary = room.get("camp_layout", {})
	var asset_geometry: Dictionary = camp.get("asset_geometry", {})
	var definition: Dictionary = asset_geometry.get("jerv_camp", {})
	var bedroll_size := BUILDER.vector3i_from_array(definition.get("sleeping_bag_size_voxels", [13, 1, 18]))
	var character_height := float(definition.get("character_height_voxels", 18))
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	# Padded green bedroll, pillow roll and folded blanket.
	BUILDER.add_voxel_box(self, owner_node, "SleepingBag", Vector3(0.0, float(bedroll_size.y) * 0.5, -1.0), Vector3(bedroll_size), voxel_size, materials["jerv_cloth_dark"])
	BUILDER.add_voxel_box(self, owner_node, "SleepingBagTop", Vector3(0.0, 1.25, -1.0), Vector3(11.0, 0.7, 15.0), voxel_size, materials["jerv_cloth"])
	BUILDER.add_voxel_box(self, owner_node, "BedrollPillow", Vector3(0.0, 1.7, -6.5), Vector3(10.0, 2.0, 3.0), voxel_size, materials["jerv_cloth_light"])
	BUILDER.add_voxel_box(self, owner_node, "FoldedBlanket", Vector3(0.0, 1.8, 5.2), Vector3(10.0, 1.2, 3.0), voxel_size, materials["jerv_cloth_dark"])

	# Bent legs and boots sit forward on the bedroll; the torso stays upright.
	for side in [-1.0, 1.0]:
		BUILDER.add_voxel_box(self, owner_node, "SeatedThigh_%s" % int(side), Vector3(side * 1.6, 4.2, 0.6), Vector3(3.0, 3.0, 5.0), voxel_size, materials["jerv_cloth"])
		BUILDER.add_voxel_box(self, owner_node, "LowerLeg_%s" % int(side), Vector3(side * 1.6, 2.7, 3.4), Vector3(2.6, 3.0, 3.0), voxel_size, materials["jerv_cloth_dark"])
		BUILDER.add_voxel_box(self, owner_node, "Boot_%s" % int(side), Vector3(side * 1.6, 1.8, 5.1), Vector3(3.0, 2.0, 3.0), voxel_size, materials["jerv_boot"])
		BUILDER.add_voxel_box(self, owner_node, "Sleeve_%s" % int(side), Vector3(side * 3.4, 7.8, -0.5), Vector3(2.0, 5.0, 3.0), voxel_size, materials["jerv_cloth_light"])
		BUILDER.add_voxel_box(self, owner_node, "Hand_%s" % int(side), Vector3(side * 3.4, 5.0, 1.0), Vector3(2.0, 2.0, 2.0), voxel_size, materials["jerv_skin"])
	BUILDER.add_voxel_box(self, owner_node, "JacketTorso", Vector3(0.0, 8.0, -0.8), Vector3(6.0, 7.0, 4.0), voxel_size, materials["jerv_cloth"])
	BUILDER.add_voxel_box(self, owner_node, "JacketHem", Vector3(0.0, 5.3, -0.5), Vector3(7.0, 2.0, 4.5), voxel_size, materials["jerv_cloth_dark"])
	BUILDER.add_voxel_box(self, owner_node, "ShoulderMantle", Vector3(0.0, 10.7, -0.6), Vector3(8.0, 2.0, 4.5), voxel_size, materials["jerv_cloth_light"])
	BUILDER.add_voxel_box(self, owner_node, "Belt", Vector3(0.0, 6.3, 1.2), Vector3(5.0, 1.0, 1.0), voxel_size, materials["wood_dark"])
	BUILDER.add_voxel_box(self, owner_node, "Head", Vector3(0.0, character_height - 4.2, -0.6), Vector3(5.0, 5.0, 4.5), voxel_size, materials["jerv_skin"])
	BUILDER.add_voxel_box(self, owner_node, "HairBack", Vector3(0.0, character_height - 4.5, -2.7), Vector3(5.5, 4.0, 1.2), voxel_size, materials["jerv_hair"])
	BUILDER.add_voxel_box(self, owner_node, "HairCap", Vector3(0.0, character_height - 1.9, -0.6), Vector3(5.5, 1.5, 5.0), voxel_size, materials["jerv_hair"])
	BUILDER.add_voxel_box(self, owner_node, "HairFringe", Vector3(0.0, character_height - 2.9, 1.45), Vector3(4.5, 1.5, 1.0), voxel_size, materials["jerv_hair_light"])
	for side in [-1.0, 1.0]:
		BUILDER.add_voxel_box(self, owner_node, "HairLock_%s" % int(side), Vector3(side * 2.4, character_height - 3.9, 0.1), Vector3(1.0, 3.0, 3.0), voxel_size, materials["jerv_hair_light"])
		BUILDER.add_voxel_box(self, owner_node, "Eye_%s" % int(side), Vector3(side * 1.0, character_height - 4.0, 1.72), Vector3(0.8, 0.8, 0.45), voxel_size, materials["jerv_hair"])
	BUILDER.add_voxel_box(self, owner_node, "Nose", Vector3(0.0, character_height - 4.8, 1.78), Vector3(1.0, 1.0, 0.7), voxel_size, materials["jerv_skin"])
	return true
