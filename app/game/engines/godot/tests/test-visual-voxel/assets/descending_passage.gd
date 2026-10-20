@tool
extends Node3D

const SOURCE_DIRECTORY := "res://../../assets/scenes/test-visual-voxel/sources"
const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/descending_passage.tscn"
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
		push_error("Open the descending_passage asset scene to generate this asset")
		return
	var geometry := BUILDER.load_source("geometry.json")
	configure_voxels(float(geometry.get("voxel_size_meters", 0.125)), self)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(voxel_size: float, scene_owner: Node = null) -> bool:
	if voxel_size <= 0.0:
		return false
	var geometry := BUILDER.load_source("geometry.json")
	var room: Dictionary = geometry.get("room", {})
	var walls: Dictionary = room.get("walls", {})
	var passage_assets: Dictionary = walls.get("passage_assets", {})
	var definition: Dictionary = passage_assets.get("descending_passage", {})
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	var corridor_width := float(definition.get("clear_width_voxels", 10))
	var corridor_length := float(definition.get("length_voxels", 24))
	var wall_height := float(definition.get("wall_height_voxels", 9))
	var wall_thickness := float(definition.get("wall_thickness_voxels", 2))
	var segment_length := float(definition.get("wall_segment_length_voxels", 6))
	var wall_clearance := float(definition.get("wall_start_clearance_voxels", 4))
	var threshold_depth := float(definition.get("threshold_depth_voxels", 3))
	BUILDER.add_voxel_box(self, owner_node, "Threshold", Vector3(0.0, -0.5, -threshold_depth * 0.5), Vector3(corridor_width + 4.0, 1.0, threshold_depth), voxel_size, materials["stone_light"])
	BUILDER.add_voxel_box(self, owner_node, "Passage_Floor", Vector3(0.0, -1.0, -corridor_length * 0.5), Vector3(corridor_width + wall_thickness, 1.0, corridor_length), voxel_size, materials["stone_deep"])
	for side in [-1.0, 1.0]:
		var wall := BUILDER.add_group(self, owner_node, "CorridorWall_%s" % ("Left" if side < 0.0 else "Right"))
		wall.position.x = side * (corridor_width * 0.5 + wall_thickness * 0.5) * voxel_size
		var row_count := ceili(corridor_length / segment_length)
		for row in range(row_count):
			var z_center := -wall_clearance - segment_length * 0.5 - float(row) * segment_length
			BUILDER.add_voxel_box(wall, owner_node, "Course_%02d" % row, Vector3(0.0, wall_height * 0.5, z_center), Vector3(wall_thickness, wall_height, segment_length), voxel_size, materials["stone_mid" if row % 2 == 0 else "stone_main"])
	# Seven broad stone treads descend away from the room into the passage.
	var step_count := int(definition.get("step_count", 7))
	var rise := float(definition.get("step_rise_voxels", 2))
	var step_depth := float(definition.get("step_depth_voxels", 3))
	var step_start := float(definition.get("step_start_voxels", 2))
	var step_width := float(definition.get("step_width_voxels", corridor_width))
	for step in range(step_count):
		var top_y := -rise - float(step) * rise
		var block_center_y := top_y - rise * 0.5
		var z_center := -step_start - float(step) * step_depth - step_depth * 0.5
		BUILDER.add_voxel_box(self, owner_node, "DescendingStep_%02d" % (step + 1), Vector3(0.0, block_center_y, z_center), Vector3(step_width, rise, step_depth), voxel_size, materials["stone_light" if step % 3 == 0 else "stone_main"])
	return true
