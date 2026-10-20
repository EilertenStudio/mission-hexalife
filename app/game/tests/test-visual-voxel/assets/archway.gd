@tool
extends Node3D

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/archway.tscn"
const BUILDER := preload("res://tests/test-visual-voxel/assets/voxel_asset_builder.gd")

@export_tool_button("GENERATE", "Callable")
var generate_archway: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_default")


func _generate_default() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the archway asset scene to generate this asset")
		return
	var geometry := BUILDER.load_settings("geometry")
	var room: Dictionary = geometry.get("room", {})
	var walls: Dictionary = room.get("walls", {})
	var apertures: Array = walls.get("apertures", [])
	var aperture: Dictionary = apertures[0] if not apertures.is_empty() else {}
	configure_voxels(
		int(aperture.get("width_voxels", 12)),
		int(aperture.get("height_voxels", 24)),
		int(aperture.get("arch_depth_voxels", 6)),
		float(geometry.get("voxel_size_meters", 0.125)),
		self
	)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(width: int, height: int, depth: int, voxel_size: float, scene_owner: Node = null) -> bool:
	if width < 10 or height < 20 or depth < 2 or voxel_size <= 0.0:
		push_error("Archway dimensions are too small")
		return false
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	var jamb_width := 2.0
	var side_x := float(width) * 0.5 - jamb_width * 0.5
	var clear_half_width := float(width) * 0.5 - jamb_width
	var spring_height := float(height) - 8.0
	var y := 0.0
	var course := 0
	while y < spring_height:
		var course_height := minf(3.0, spring_height - y)
		for side in [-1.0, 1.0]:
			var material_id := "stone_main" if course % 2 == 0 else "stone_mid"
			BUILDER.add_voxel_box(
				self, owner_node, "Jamb_%d_%02d" % [int(side), course],
				Vector3(side * side_x, y + course_height * 0.5, 0.0),
				Vector3(jamb_width, course_height, depth), voxel_size, materials[material_id]
			)
		y += course_height
		course += 1

	# Stepped voussoirs make a rounded silhouette while leaving a clear passage.
	var arch_blocks := [
		{"x": -(clear_half_width - 1.0), "width": 2.0, "y": spring_height + 2.0, "height": 4.0},
		{"x": clear_half_width - 1.0, "width": 2.0, "y": spring_height + 2.0, "height": 4.0},
		{"x": -(clear_half_width - 2.0), "width": 2.0, "y": spring_height + 5.0, "height": 2.0},
		{"x": clear_half_width - 2.0, "width": 2.0, "y": spring_height + 5.0, "height": 2.0},
		{"x": 0.0, "width": clear_half_width * 2.0 - 4.0, "y": spring_height + 7.0, "height": 2.0}
	]
	for index in range(arch_blocks.size()):
		var block: Dictionary = arch_blocks[index]
		var material_id := "stone_light" if index == 4 else ("stone_mid" if index % 2 == 0 else "stone_main")
		BUILDER.add_voxel_box(
			self, owner_node, "Voussoir_%02d" % index,
			Vector3(float(block["x"]), float(block["y"]), 0.0),
			Vector3(float(block["width"]), float(block["height"]), depth),
			voxel_size, materials[material_id]
		)
	return true
