@tool
extends Node3D

const ASSET_SCENE_PATH := "res://tests/test-visual-voxel/assets/campfire.tscn"
const BUILDER := preload("res://tests/test-visual-voxel/assets/voxel_asset_builder.gd")

@export_tool_button("GENERATE", "Callable")
var generate_campfire: Callable = _queue_generation


func _queue_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_default")


func _generate_default() -> void:
	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != self or scene_file_path != ASSET_SCENE_PATH:
		push_error("Open the campfire asset scene to generate this asset")
		return
	var geometry := BUILDER.load_settings("geometry")
	var room: Dictionary = geometry.get("room", {})
	var camp: Dictionary = room.get("camp_layout", {})
	var fire: Dictionary = camp.get("campfire", {})
	configure_voxels(float(geometry.get("voxel_size_meters", 0.125)), int(fire.get("seed", 4101)), self)
	EditorInterface.mark_scene_as_unsaved()


func configure_voxels(voxel_size: float, seed: int, scene_owner: Node = null) -> bool:
	if voxel_size <= 0.0:
		return false
	var geometry := BUILDER.load_settings("geometry")
	var room: Dictionary = geometry.get("room", {})
	var camp: Dictionary = room.get("camp_layout", {})
	var asset_geometry: Dictionary = camp.get("asset_geometry", {})
	var definition: Dictionary = asset_geometry.get("campfire", {})
	BUILDER.clear_generated(self)
	var owner_node: Node = scene_owner if scene_owner != null else self
	var materials := BUILDER.load_materials()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var stone_count := int(definition.get("ring_stone_count", 10))
	var radius_range: Array = definition.get("ring_radius_voxels", [4.0, 5.2])
	var size_range: Array = definition.get("ring_stone_size_voxels", [2.4, 3.5])
	for stone_index in range(stone_count):
		var angle := TAU * float(stone_index) / float(stone_count)
		var radius := rng.randf_range(float(radius_range[0]), float(radius_range[1]))
		var size := rng.randf_range(float(size_range[0]), float(size_range[1]))
		var position := Vector3(cos(angle) * radius, size * 0.25, sin(angle) * radius)
		var stone_material := "stone_light" if stone_index % 4 == 0 else ("stone_main" if stone_index % 2 == 0 else "stone_mid")
		BUILDER.add_voxel_box(self, owner_node, "FireRingStone_%02d" % (stone_index + 1), position, Vector3(size, size * 0.5, size), voxel_size, materials[stone_material])
	BUILDER.add_voxel_box(self, owner_node, "CharredLog_01", Vector3(0.0, 1.0, 0.0), Vector3(2.0, 2.0, 10.0), voxel_size, materials["wood_dark"], Vector3(0.0, 0.0, 90.0))
	BUILDER.add_voxel_box(self, owner_node, "CharredLog_02", Vector3(0.0, 1.5, 0.0), Vector3(2.0, 2.0, 9.0), voxel_size, materials["wood_main"], Vector3(0.0, 0.0, -90.0))
	BUILDER.add_voxel_box(self, owner_node, "FireBed", Vector3(0.0, 2.0, 0.0), Vector3(4.0, 2.0, 5.0), voxel_size, materials["wood_dark"])
	BUILDER.add_voxel_box(self, owner_node, "FlameOuter_A", Vector3(-1.0, 5.0, 0.0), Vector3(3.0, 5.0, 3.0), voxel_size, materials["fire_amber"], Vector3(0.0, 0.0, -12.0))
	BUILDER.add_voxel_box(self, owner_node, "FlameOuter_B", Vector3(1.0, 4.0, 0.5), Vector3(2.0, 4.0, 3.0), voxel_size, materials["fire_amber"], Vector3(0.0, 0.0, 16.0))
	BUILDER.add_voxel_box(self, owner_node, "FlameCore", Vector3(0.0, 4.2, 0.0), Vector3(1.7, 4.4, 1.8), voxel_size, materials["fire_gold"])
	BUILDER.add_voxel_box(self, owner_node, "FlameTip", Vector3(0.0, 7.0, 0.0), Vector3(1.0, 2.0, 1.0), voxel_size, materials["torch_flame"])
	var light_definition := BUILDER.load_light_definition("campfire")
	var light_offset: Array = light_definition.get("position_offset_meters", [0.0, 0.58, 0.0])
	BUILDER.add_omni_light(
		self, owner_node, "Firelight",
		Vector3(float(light_offset[0]), float(light_offset[1]), float(light_offset[2])),
		BUILDER.color_from_rgb(light_definition.get("color_rgb", [255, 129, 49])),
		float(light_definition.get("energy", 2.25)),
		float(light_definition.get("range_meters", 6.5))
	)
	var smoke_definition := BUILDER.load_particle_definition("campfire_smoke")
	BUILDER.add_smoke(self, owner_node, "CampfireSmoke", Vector3(0.0, 0.82, 0.0), voxel_size, smoke_definition)
	return true
