@tool
extends Node3D

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/open_door_passage.tscn"
const BUILDER := preload("res://tests/test-visual-voxel/assets/voxel_asset_builder.gd")

@export_tool_button("GENERATE", "Callable")
var generate_passage: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_default")


func _generate_default() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the open_door_passage asset scene to generate this asset")
		return
	var geometry := BUILDER.load_settings("geometry")
	configure_voxels(float(geometry.get("voxel_size_meters", 0.125)), self)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(voxel_size: float, scene_owner: Node = null) -> bool:
	if voxel_size <= 0.0:
		return false
	var geometry := BUILDER.load_settings("geometry")
	var room: Dictionary = geometry.get("room", {})
	var walls: Dictionary = room.get("walls", {})
	var passage_assets: Dictionary = walls.get("passage_assets", {})
	var definition: Dictionary = passage_assets.get("open_door_passage", {})
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	var width := float(definition.get("clear_width_voxels", 10))
	var length := float(definition.get("length_voxels", 24))
	var wall_height := float(definition.get("wall_height_voxels", 14))
	var wall_thickness := float(definition.get("wall_thickness_voxels", 2))
	var segment_length := float(definition.get("wall_segment_length_voxels", 6))
	var wall_clearance := float(definition.get("corridor_start_clearance_voxels", 4))
	var door_position := float(definition.get("door_position_voxels", 23))
	var door_width := float(definition.get("door_leaf_width_voxels", 8))
	var door_height := float(definition.get("door_leaf_height_voxels", 16))
	var door_thickness := float(definition.get("door_leaf_thickness_voxels", 1))
	BUILDER.add_voxel_box(self, owner_node, "Corridor_Floor", Vector3(0.0, -0.5, -length * 0.5), Vector3(width + wall_thickness * 2.0, 1.0, length), voxel_size, materials["stone_deep"])
	for side in [-1.0, 1.0]:
		var wall := BUILDER.add_group(self, owner_node, "DoorCorridorWall_%s" % ("Left" if side < 0.0 else "Right"))
		wall.position.x = side * (width * 0.5 + wall_thickness * 0.5) * voxel_size
		var course_count := ceili(length / segment_length)
		for course in range(course_count):
			var z_center := -wall_clearance - segment_length * 0.5 - float(course) * segment_length
			BUILDER.add_voxel_box(wall, owner_node, "Course_%02d" % course, Vector3(0.0, wall_height * 0.5, z_center), Vector3(wall_thickness, wall_height, segment_length), voxel_size, materials["stone_main" if course % 2 == 0 else "stone_mid"])
	# A far doorway frames the leaf; the door is swung against the right wall.
	var frame_half_width := float(definition.get("door_frame_half_width_voxels", 6))
	var frame_height := float(definition.get("door_frame_height_voxels", 18))
	var lintel_y := float(definition.get("door_lintel_center_y_voxels", 19))
	var door_z := -door_position
	for side in [-1.0, 1.0]:
		BUILDER.add_voxel_box(self, owner_node, "FarDoorJamb_%s" % ("L" if side < 0.0 else "R"), Vector3(side * frame_half_width, frame_height * 0.5, door_z), Vector3(wall_thickness, frame_height, wall_thickness), voxel_size, materials["stone_light"])
	BUILDER.add_voxel_box(self, owner_node, "FarDoorLintel", Vector3(0.0, lintel_y, door_z), Vector3(frame_half_width * 2.0 + wall_thickness, 2.0, wall_thickness), voxel_size, materials["stone_light"])
	var open_leaf := BUILDER.add_group(self, owner_node, "OpenDoorLeaf")
	open_leaf.position = Vector3(float(definition.get("door_hinge_x_voxels", -4.5)), door_height * 0.5, door_z) * voxel_size
	open_leaf.rotation_degrees.y = 0.0
	BUILDER.add_voxel_box(open_leaf, owner_node, "WoodenDoor", Vector3(0.0, 0.0, door_width * 0.5), Vector3(door_thickness, door_height, door_width), voxel_size, materials["wood_main"])
	for stripe in [-door_height * 0.25, door_height * 0.25]:
		BUILDER.add_voxel_box(open_leaf, owner_node, "DoorStrap_%d" % int(stripe), Vector3(-0.6, stripe, door_width * 0.5), Vector3(1.0, 1.0, door_width), voxel_size, materials["wood_dark"])
	BUILDER.add_voxel_box(open_leaf, owner_node, "DoorHandle", Vector3(1.0, 0.0, door_width * 0.125), Vector3(1.0, 2.0, 1.0), voxel_size, materials["gold"])
	return true
