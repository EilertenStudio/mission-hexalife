@tool
extends Node3D

const SOURCE_DIRECTORY := "res://../../assets/scenes/test-visual-voxel/sources"
const SET_SCENE_PATH := "res://tests/test-visual-voxel/test_visual_voxel_diorama.tscn"
const BLOCK_SCENE_PATH := "res://tests/test-visual-voxel/assets/stone_masonry_block.tscn"
const SLAB_SCENE_PATH := "res://tests/test-visual-voxel/assets/stone_floor_slab.tscn"
const LOOSE_STONE_SCENE_PATH := "res://tests/test-visual-voxel/assets/loose_stone.tscn"
const RUBBLE_CLUSTER_SCENE_PATH := "res://tests/test-visual-voxel/assets/stone_rubble_cluster.tscn"
const ARCHWAY_SCENE_PATH := "res://tests/test-visual-voxel/assets/archway.tscn"
const DESCENDING_PASSAGE_SCENE_PATH := "res://tests/test-visual-voxel/assets/descending_passage.tscn"
const OPEN_DOOR_PASSAGE_SCENE_PATH := "res://tests/test-visual-voxel/assets/open_door_passage.tscn"
const TORCH_SCENE_PATH := "res://tests/test-visual-voxel/assets/torch_sconce.tscn"
const CAMPFIRE_SCENE_PATH := "res://tests/test-visual-voxel/assets/campfire.tscn"
const JERV_CAMP_SCENE_PATH := "res://tests/test-visual-voxel/assets/jerv_camp.tscn"
const TREASURE_CHEST_SCENE_PATH := "res://tests/test-visual-voxel/assets/treasure_chest.tscn"
const MOSS_VEGETATION_SCENE_PATH := "res://tests/test-visual-voxel/assets/moss_vegetation.tscn"


@export_tool_button("GENERATE", "Callable")
var set_diorama: Callable = _queue_diorama_set


func _queue_diorama_set() -> void:
	if not Engine.is_editor_hint():
		return
	call_deferred("_set_diorama")


func _set_diorama() -> bool:
	if Engine.is_editor_hint() and (
		EditorInterface.get_edited_scene_root() != self
		or scene_file_path != SET_SCENE_PATH
	):
		push_error("Open the test_visual_voxel_diorama scene to generate this set")
		return false

	var geometry := _load_source("geometry.json")
	if geometry.is_empty():
		return false
	var voxel_size := float(geometry.get("voxel_size_meters", 0.125))
	var room: Dictionary = geometry.get("room", {})
	var footprint: Array = room.get("footprint_voxels", [72, 72])
	var floor_definition: Dictionary = room.get("floor", {})
	var wall_definition: Dictionary = room.get("walls", {})
	var debris_definition: Dictionary = room.get("debris", {})
	var camp_definition: Dictionary = room.get("camp_layout", {})
	var material_source := _load_source("materials.json")
	if material_source.is_empty() or voxel_size <= 0.0:
		return false

	if (
		not _regenerate_default_block_asset(wall_definition)
		or not _regenerate_default_slab_asset(floor_definition)
		or not _regenerate_default_loose_stone_asset(debris_definition)
		or not _regenerate_default_rubble_cluster_asset(debris_definition)
	):
		return false
	var apertures: Array = wall_definition.get("apertures", [])
	var first_aperture: Dictionary = apertures[0] if not apertures.is_empty() else {}
	var arch_asset := _regenerate_generated_asset(ARCHWAY_SCENE_PATH, [
		int(first_aperture.get("width_voxels", 12)),
		int(first_aperture.get("height_voxels", 24)),
		int(first_aperture.get("arch_depth_voxels", 6)),
		voxel_size
	])
	var descending_passage_asset := _regenerate_generated_asset(DESCENDING_PASSAGE_SCENE_PATH, [voxel_size])
	var open_door_passage_asset := _regenerate_generated_asset(OPEN_DOOR_PASSAGE_SCENE_PATH, [voxel_size])
	var torch_asset := _regenerate_generated_asset(TORCH_SCENE_PATH, [voxel_size])
	var campfire_definition: Dictionary = camp_definition.get("campfire", {})
	var campfire_asset := _regenerate_generated_asset(CAMPFIRE_SCENE_PATH, [voxel_size, int(campfire_definition.get("seed", 4101))])
	var jerv_asset := _regenerate_generated_asset(JERV_CAMP_SCENE_PATH, [voxel_size])
	var chest_asset := _regenerate_generated_asset(TREASURE_CHEST_SCENE_PATH, [voxel_size])
	var vegetation_definitions: Array = camp_definition.get("vegetation", [])
	var vegetation_seed := int(vegetation_definitions[0].get("seed", 5101)) if not vegetation_definitions.is_empty() else 5101
	var vegetation_asset := _regenerate_generated_asset(MOSS_VEGETATION_SCENE_PATH, [voxel_size, vegetation_seed])
	if (
		arch_asset == null or descending_passage_asset == null or open_door_passage_asset == null
		or torch_asset == null or campfire_asset == null or jerv_asset == null
		or chest_asset == null or vegetation_asset == null
	):
		return false
	var block_asset := ResourceLoader.load(BLOCK_SCENE_PATH, "PackedScene") as PackedScene
	var slab_asset := ResourceLoader.load(SLAB_SCENE_PATH, "PackedScene") as PackedScene
	var loose_stone_asset := ResourceLoader.load(LOOSE_STONE_SCENE_PATH, "PackedScene") as PackedScene
	var rubble_cluster_asset := ResourceLoader.load(RUBBLE_CLUSTER_SCENE_PATH, "PackedScene") as PackedScene
	if block_asset == null or slab_asset == null or loose_stone_asset == null or rubble_cluster_asset == null:
		push_error("Unable to load one or more voxel assets for the diorama")
		return false

	_remove_named_child(self, "FloorTiles")
	_remove_named_child(self, "MasonryWalls")
	_remove_named_child(self, "StoneDebris")
	_remove_named_child(self, "CampProps")
	_remove_named_child(self, "SconceTorches")
	_remove_named_child(self, "RoomVegetation")

	var floor_node := Node3D.new()
	floor_node.name = "FloorTiles"
	add_child(floor_node)
	floor_node.owner = self
	var floor_count := _compose_floor(
		floor_node,
		self,
		slab_asset,
		floor_definition,
		footprint,
		voxel_size
	)
	if floor_count < 1:
		push_error("No floor slabs were composed")
		return false

	var walls_node := Node3D.new()
	walls_node.name = "MasonryWalls"
	add_child(walls_node)
	walls_node.owner = self
	var block_count := _compose_walls(
		walls_node,
		self,
		block_asset,
		arch_asset,
		descending_passage_asset,
		open_door_passage_asset,
		room,
		wall_definition,
		footprint,
		voxel_size
	)
	if block_count < 1:
		push_error("No masonry blocks were composed")
		return false

	var debris_node := Node3D.new()
	debris_node.name = "StoneDebris"
	add_child(debris_node)
	debris_node.owner = self
	var debris_count := _compose_debris(
		debris_node,
		self,
		loose_stone_asset,
		rubble_cluster_asset,
		debris_definition,
		int(floor_definition.get("thickness_voxels", 3)),
		voxel_size
	)
	if debris_count < 1:
		push_error("No stone debris was composed")
		return false

	var torch_group := Node3D.new()
	torch_group.name = "SconceTorches"
	add_child(torch_group)
	torch_group.owner = self
	var torch_count := _compose_arch_torches(
		torch_group, self, torch_asset, wall_definition, footprint, voxel_size,
		int(floor_definition.get("thickness_voxels", 3))
	)

	var camp_group := Node3D.new()
	camp_group.name = "CampProps"
	add_child(camp_group)
	camp_group.owner = self
	var camp_count := _compose_camp(
		camp_group, self, campfire_asset, jerv_asset, chest_asset, camp_definition,
		int(floor_definition.get("thickness_voxels", 3)), voxel_size
	)
	var vegetation_group := Node3D.new()
	vegetation_group.name = "RoomVegetation"
	add_child(vegetation_group)
	vegetation_group.owner = self
	var vegetation_count := _compose_vegetation(
		vegetation_group, self, vegetation_asset, vegetation_definitions,
		int(floor_definition.get("thickness_voxels", 3)), voxel_size
	)
	if torch_count != 4 or camp_count != 3 or vegetation_count != vegetation_definitions.size():
		push_error("The camp composition is incomplete: %d torches, %d camp props, %d plants" % [torch_count, camp_count, vegetation_count])
		return false

	if Engine.is_editor_hint():
		EditorInterface.mark_scene_as_unsaved()
		EditorInterface.save_scene()
	else:
		var packed_scene := PackedScene.new()
		var pack_error := packed_scene.pack(self)
		if pack_error != OK:
			push_error("Unable to pack the diorama set (error %d)" % pack_error)
			return false
		var save_error := ResourceSaver.save(packed_scene, SET_SCENE_PATH)
		if save_error != OK:
			push_error("Unable to save the diorama set (error %d)" % save_error)
			return false

	print("Set %d floor slabs, %d masonry blocks, %d debris assets, %d torches, %d camp props and %d vegetation patches in %s" % [floor_count, block_count, debris_count, torch_count, camp_count, vegetation_count, SET_SCENE_PATH])
	return true


func _regenerate_generated_asset(asset_path: String, arguments: Array) -> PackedScene:
	var asset_pack := ResourceLoader.load(asset_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if asset_pack == null:
		push_error("Unable to load generated voxel asset: %s" % asset_path)
		return null
	var asset_root := asset_pack.instantiate() as Node3D
	if asset_root == null or not asset_root.has_method("configure_voxels"):
		push_error("Generated voxel asset has no configure_voxels method: %s" % asset_path)
		if asset_root != null:
			asset_root.free()
		return null
	if not bool(asset_root.callv("configure_voxels", arguments)):
		asset_root.free()
		push_error("Unable to generate voxel asset: %s" % asset_path)
		return null
	var packed_asset := PackedScene.new()
	var pack_error := packed_asset.pack(asset_root)
	asset_root.free()
	if pack_error != OK:
		push_error("Unable to pack voxel asset %s (error %d)" % [asset_path, pack_error])
		return null
	var save_error := ResourceSaver.save(packed_asset, asset_path)
	if save_error != OK:
		push_error("Unable to save voxel asset %s (error %d)" % [asset_path, save_error])
		return null
	return ResourceLoader.load(asset_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene


func _regenerate_default_block_asset(wall_definition: Dictionary) -> bool:
	var block_pack := ResourceLoader.load(BLOCK_SCENE_PATH, "PackedScene") as PackedScene
	if block_pack == null:
		push_error("Unable to load stone_masonry_block asset")
		return false
	var block_root := block_pack.instantiate() as Node3D
	if block_root == null:
		return false
	var definition: Dictionary = wall_definition.get("block_asset", {})
	var size := _vector3i_from_array(definition.get("default_size_voxels", [5, 3, 6]))
	var unit := _vector3i_from_array(definition.get("unit_size_voxels", [1, 1, 1]))
	size = Vector3i(size.x * unit.x, size.y * unit.y, size.z * unit.z)
	if not block_root.call("configure_voxels", size, str(definition.get("surface_material_id", "stone_main")), block_root):
		block_root.free()
		return false
	var packed_asset := PackedScene.new()
	var pack_error := packed_asset.pack(block_root)
	block_root.free()
	if pack_error != OK:
		push_error("Unable to pack the default masonry block (error %d)" % pack_error)
		return false
	var save_error := ResourceSaver.save(packed_asset, BLOCK_SCENE_PATH)
	if save_error != OK:
		push_error("Unable to save the default masonry block (error %d)" % save_error)
		return false
	return true


func _regenerate_default_slab_asset(floor_definition: Dictionary) -> bool:
	var slab_pack := ResourceLoader.load(SLAB_SCENE_PATH, "PackedScene") as PackedScene
	if slab_pack == null:
		push_error("Unable to load stone_floor_slab asset")
		return false
	var slab_root := slab_pack.instantiate() as Node3D
	if slab_root == null:
		return false
	var definition: Dictionary = floor_definition.get("slab_asset", {})
	var size := _vector3i_from_array(definition.get("default_size_voxels", [8, 3, 8]))
	var unit := _vector3i_from_array(definition.get("unit_size_voxels", [1, 1, 1]))
	size = Vector3i(size.x * unit.x, size.y * unit.y, size.z * unit.z)
	if not slab_root.call("configure_voxels", size, str(definition.get("surface_material_id", "stone_main")), slab_root):
		slab_root.free()
		return false
	var packed_asset := PackedScene.new()
	var pack_error := packed_asset.pack(slab_root)
	slab_root.free()
	if pack_error != OK:
		push_error("Unable to pack the default stone floor slab (error %d)" % pack_error)
		return false
	var save_error := ResourceSaver.save(packed_asset, SLAB_SCENE_PATH)
	if save_error != OK:
		push_error("Unable to save the default stone floor slab (error %d)" % save_error)
		return false
	return true


func _regenerate_default_loose_stone_asset(debris_definition: Dictionary) -> bool:
	var asset_pack := ResourceLoader.load(LOOSE_STONE_SCENE_PATH, "PackedScene") as PackedScene
	if asset_pack == null:
		push_error("Unable to load loose_stone asset")
		return false
	var asset_root := asset_pack.instantiate() as Node3D
	if asset_root == null:
		return false
	var definition: Dictionary = debris_definition.get("loose_stone_asset", {})
	var size := _vector3i_from_array(definition.get("default_size_voxels", [5, 3, 4]))
	var seed := int(definition.get("seed", 1901))
	if not asset_root.call("configure_voxels", size, seed, asset_root):
		asset_root.free()
		return false
	var packed_asset := PackedScene.new()
	var pack_error := packed_asset.pack(asset_root)
	asset_root.free()
	if pack_error != OK:
		push_error("Unable to pack the default loose stone (error %d)" % pack_error)
		return false
	var save_error := ResourceSaver.save(packed_asset, LOOSE_STONE_SCENE_PATH)
	if save_error != OK:
		push_error("Unable to save the default loose stone (error %d)" % save_error)
		return false
	return true


func _regenerate_default_rubble_cluster_asset(debris_definition: Dictionary) -> bool:
	var asset_pack := ResourceLoader.load(RUBBLE_CLUSTER_SCENE_PATH, "PackedScene") as PackedScene
	if asset_pack == null:
		push_error("Unable to load stone_rubble_cluster asset")
		return false
	var asset_root := asset_pack.instantiate() as Node3D
	if asset_root == null:
		return false
	var definition: Dictionary = debris_definition.get("rubble_cluster_asset", {})
	var bounds := _vector3i_from_array(definition.get("default_size_voxels", [12, 4, 10]))
	var fragment_count := int(definition.get("fragment_count", 6))
	var seed := int(definition.get("seed", 2901))
	if not asset_root.call("configure_voxels", bounds, fragment_count, seed, asset_root):
		asset_root.free()
		return false
	var packed_asset := PackedScene.new()
	var pack_error := packed_asset.pack(asset_root)
	asset_root.free()
	if pack_error != OK:
		push_error("Unable to pack the default stone rubble cluster (error %d)" % pack_error)
		return false
	var save_error := ResourceSaver.save(packed_asset, RUBBLE_CLUSTER_SCENE_PATH)
	if save_error != OK:
		push_error("Unable to save the default stone rubble cluster (error %d)" % save_error)
		return false
	return true


func _compose_debris(
	parent: Node3D,
	scene_root: Node,
	loose_stone_asset: PackedScene,
	rubble_cluster_asset: PackedScene,
	debris_definition: Dictionary,
	floor_thickness: int,
	voxel_size: float
) -> int:
	var floor_top := float(floor_thickness) * voxel_size
	var count := 0
	var stone_definitions: Array = debris_definition.get("loose_stones", [])
	for index in range(stone_definitions.size()):
		var definition: Dictionary = stone_definitions[index]
		var stone := loose_stone_asset.instantiate() as Node3D
		if stone == null:
			continue
		stone.name = "LooseStone_%02d" % [index + 1]
		parent.add_child(stone)
		stone.owner = scene_root
		scene_root.set_editable_instance(stone, true)
		var point: Array = definition.get("position_voxels", [0, 0])
		stone.position = Vector3(
			float(point[0]) * voxel_size,
			floor_top,
			float(point[1]) * voxel_size
		)
		stone.rotation_degrees.y = float(definition.get("rotation_y_degrees", 0.0))
		var size := _vector3i_from_array(definition.get("size_voxels", [5, 3, 4]))
		var seed := int(definition.get("seed", 1901 + index))
		if not stone.call("configure_voxels", size, seed, scene_root):
			push_error("Failed to generate loose stone %s" % stone.name)
			return 0
		count += 1

	var cluster_definitions: Array = debris_definition.get("rubble_clusters", [])
	var cluster_asset_definition: Dictionary = debris_definition.get("rubble_cluster_asset", {})
	var bounds := _vector3i_from_array(cluster_asset_definition.get("default_size_voxels", [12, 4, 10]))
	var fragment_count := int(cluster_asset_definition.get("fragment_count", 6))
	for index in range(cluster_definitions.size()):
		var definition: Dictionary = cluster_definitions[index]
		var cluster := rubble_cluster_asset.instantiate() as Node3D
		if cluster == null:
			continue
		cluster.name = "RubbleCluster_%02d" % [index + 1]
		parent.add_child(cluster)
		cluster.owner = scene_root
		scene_root.set_editable_instance(cluster, true)
		var point: Array = definition.get("position_voxels", [0, 0])
		cluster.position = Vector3(
			float(point[0]) * voxel_size,
			floor_top,
			float(point[1]) * voxel_size
		)
		cluster.rotation_degrees.y = float(definition.get("rotation_y_degrees", 0.0))
		var seed := int(definition.get("seed", 2901 + index))
		if not cluster.call("configure_voxels", bounds, fragment_count, seed, scene_root):
			push_error("Failed to generate rubble cluster %s" % cluster.name)
			return 0
		count += 1
	return count


func _compose_floor(
	parent: Node3D,
	scene_root: Node,
	asset: PackedScene,
	floor_definition: Dictionary,
	footprint: Array,
	voxel_size: float
) -> int:
	var width := int(footprint[0])
	var depth := int(footprint[1])
	var thickness := int(floor_definition.get("thickness_voxels", 3))
	var width_range: Array = floor_definition.get("slab_width_voxels", [6, 11])
	var depth_range: Array = floor_definition.get("slab_depth_voxels", [6, 10])
	var surface_material_ids: Array = floor_definition.get("surface_material_ids", ["stone_main", "stone_mid"])
	var origin_x := -float(width) * voxel_size * 0.5
	var origin_z := -float(depth) * voxel_size * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = int(floor_definition.get("layout_seed", 271828))
	var count := 0
	var z_cursor := 0
	var row_index := 0
	for slab_depth in _partition(depth, int(depth_range[0]), int(depth_range[1]), rng):
		var x_cursor := 0
		for slab_width in _partition(width, int(width_range[0]), int(width_range[1]), rng):
			var slab := asset.instantiate() as Node3D
			if slab == null:
				continue
			slab.name = "StoneSlab_%02d_%02d" % [row_index + 1, count + 1]
			parent.add_child(slab)
			slab.owner = scene_root
			scene_root.set_editable_instance(slab, true)
			slab.position = Vector3(
				origin_x + (float(x_cursor) + float(slab_width) * 0.5) * voxel_size,
				float(thickness) * voxel_size * 0.5,
				origin_z + (float(z_cursor) + float(slab_depth) * 0.5) * voxel_size
			)
			var surface_material := _pick_material(surface_material_ids, rng, "stone_main")
			if not slab.call("configure_voxels", Vector3i(slab_width, thickness, slab_depth), surface_material, scene_root):
				push_error("Failed to generate floor slab %s" % slab.name)
				return 0
			x_cursor += slab_width
			count += 1
		z_cursor += slab_depth
		row_index += 1
	return count


func _compose_walls(
	parent: Node3D,
	scene_root: Node,
	asset: PackedScene,
	arch_asset: PackedScene,
	descending_passage_asset: PackedScene,
	open_door_passage_asset: PackedScene,
	room: Dictionary,
	wall_definition: Dictionary,
	footprint: Array,
	voxel_size: float
) -> int:
	var width := int(footprint[0])
	var depth := int(footprint[1])
	var height := int(wall_definition.get("height_voxels", 40))
	var thickness := int(wall_definition.get("thickness_voxels", 6))
	var block_width_range: Array = wall_definition.get("block_width_voxels", [5, 10])
	var course_height_range: Array = wall_definition.get("course_height_voxels", [3, 5])
	var relief := int(wall_definition.get("surface_relief_voxels", 1))
	var surface_material_ids: Array = wall_definition.get("surface_material_ids", ["stone_main", "stone_mid", "stone_light", "stone_shadow"])
	var floor_definition: Dictionary = room.get("floor", {})
	var floor_thickness := int(floor_definition.get("thickness_voxels", 3))
	var origin_x := -float(width) * voxel_size * 0.5
	var origin_z := -float(depth) * voxel_size * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = int(wall_definition.get("layout_seed", 314159))
	var apertures: Array = wall_definition.get("apertures", [])
	var back_aperture := _find_aperture(apertures, "back_wall")
	var left_aperture := _find_aperture(apertures, "left_wall")
	var count := 0
	var back_wall := Node3D.new()
	back_wall.name = "BackWall"
	parent.add_child(back_wall)
	back_wall.owner = scene_root
	count += _compose_wall(
		back_wall,
		scene_root,
		asset,
		"Back",
		width,
		0,
		0,
		false,
	back_aperture,
		floor_thickness,
		height,
		thickness,
		block_width_range,
		course_height_range,
		relief,
		surface_material_ids,
		origin_x,
		origin_z,
		voxel_size,
		rng
	)
	count += _compose_aperture_assets(
		back_wall, scene_root, arch_asset, open_door_passage_asset,
		back_aperture, "back_wall", width, depth, thickness,
		floor_thickness, origin_x, origin_z, voxel_size
	)
	var left_wall := Node3D.new()
	left_wall.name = "LeftWall"
	parent.add_child(left_wall)
	left_wall.owner = scene_root
	count += _compose_wall(
		left_wall,
		scene_root,
		asset,
		"Left",
		depth - thickness,
		0,
		thickness,
		true,
	left_aperture,
		floor_thickness,
		height,
		thickness,
		block_width_range,
		course_height_range,
		relief,
		surface_material_ids,
		origin_x,
		origin_z,
		voxel_size,
		rng
	)
	count += _compose_aperture_assets(
		left_wall, scene_root, arch_asset, descending_passage_asset,
		left_aperture, "left_wall", width, depth, thickness,
		floor_thickness, origin_x, origin_z, voxel_size
	)
	return count


func _compose_wall(
	parent: Node3D,
	scene_root: Node,
	asset: PackedScene,
	name_prefix: String,
	length: int,
	start_x: int,
	start_z: int,
	rotate_to_left_wall: bool,
	aperture: Dictionary,
	floor_thickness: int,
	height: int,
	wall_thickness: int,
	block_width_range: Array,
	course_height_range: Array,
	relief: int,
	surface_material_ids: Array,
	origin_x: float,
	origin_z: float,
	voxel_size: float,
	rng: RandomNumberGenerator
) -> int:
	var minimum_course_height := int(course_height_range[0])
	var maximum_course_height := int(course_height_range[1])
	var course_heights: Array[int] = []
	var opening_height := int(aperture.get("height_voxels", 0))
	if not aperture.is_empty() and opening_height > 0 and opening_height < height:
		course_heights.append_array(_partition(opening_height, minimum_course_height, maximum_course_height, rng))
		course_heights.append_array(_partition(height - opening_height, minimum_course_height, maximum_course_height, rng))
	else:
		course_heights = _partition(height, minimum_course_height, maximum_course_height, rng)
	var y_cursor := 0
	var block_count := 0
	var block_index := 0
	var opening_start := int(aperture.get("along_voxels", 0)) - int(aperture.get("width_voxels", 0)) / 2
	var opening_end := opening_start + int(aperture.get("width_voxels", 0))
	for course_index in range(course_heights.size()):
		var course_height: int = course_heights[course_index]
		var spans: Array[Vector2i] = [Vector2i(0, length)]
		if not aperture.is_empty() and y_cursor < opening_height:
			spans = [Vector2i(0, opening_start), Vector2i(opening_end, length)]
		for span in spans:
			var span_length := span.y - span.x
			if span_length < int(block_width_range[0]):
				continue
			var segment_sizes := _partition(span_length, int(block_width_range[0]), int(block_width_range[1]), rng)
			var along_cursor := span.x
			for segment_width_variant in segment_sizes:
				var segment_width := int(segment_width_variant)
				var depth_relief := rng.randi_range(0, relief) if relief > 0 else 0
				var block_depth := wall_thickness + depth_relief
				var block := asset.instantiate() as Node3D
				if block == null:
					continue
				block.name = "%sBlock_%02d_%02d" % [name_prefix, course_index + 1, block_index + 1]
				parent.add_child(block)
				block.owner = scene_root
				scene_root.set_editable_instance(block, true)
				if rotate_to_left_wall:
					block.rotation_degrees.y = 90.0
					block.position = Vector3(
						origin_x + float(block_depth) * voxel_size * 0.5,
						(float(floor_thickness + y_cursor) + float(course_height) * 0.5) * voxel_size,
						origin_z + (float(start_z + along_cursor) + float(segment_width) * 0.5) * voxel_size
					)
				else:
					block.position = Vector3(
						origin_x + (float(start_x + along_cursor) + float(segment_width) * 0.5) * voxel_size,
						(float(floor_thickness + y_cursor) + float(course_height) * 0.5) * voxel_size,
						origin_z + float(block_depth) * voxel_size * 0.5
					)
				var surface_material := _pick_material(surface_material_ids, rng, "stone_main")
				if not block.call("configure_voxels", Vector3i(segment_width, course_height, block_depth), surface_material, scene_root):
					push_error("Failed to generate masonry block %s" % block.name)
					return 0
				along_cursor += segment_width
				block_index += 1
				block_count += 1
		y_cursor += course_height
	return block_count


func _find_aperture(apertures: Array, wall_name: String) -> Dictionary:
	for aperture_variant in apertures:
		var aperture: Dictionary = aperture_variant
		if str(aperture.get("wall", "")) == wall_name:
			return aperture
	return {}


func _compose_aperture_assets(
	parent: Node3D,
	scene_root: Node,
	arch_asset: PackedScene,
	passage_asset: PackedScene,
	aperture: Dictionary,
	wall_name: String,
	width: int,
	depth: int,
	thickness: int,
	floor_thickness: int,
	origin_x: float,
	origin_z: float,
	voxel_size: float
) -> int:
	if aperture.is_empty():
		return 0
	var along := int(aperture.get("along_voxels", 0))
	var wall_center := Vector3.ZERO
	var rotate_left := wall_name == "left_wall"
	if rotate_left:
		wall_center = Vector3(
			origin_x + float(thickness) * voxel_size * 0.5,
			float(floor_thickness) * voxel_size,
			origin_z + float(thickness + along) * voxel_size
		)
	else:
		wall_center = Vector3(
			origin_x + float(along) * voxel_size,
			float(floor_thickness) * voxel_size,
			origin_z + float(thickness) * voxel_size * 0.5
		)
	var arch := arch_asset.instantiate() as Node3D
	if arch != null:
		arch.name = "Archway_%s" % str(aperture.get("id", wall_name))
		parent.add_child(arch)
		arch.owner = scene_root
		scene_root.set_editable_instance(arch, true)
		arch.position = wall_center
		if rotate_left:
			arch.rotation_degrees.y = 90.0
	var passage := passage_asset.instantiate() as Node3D
	if passage != null:
		passage.name = "Passage_%s" % str(aperture.get("id", wall_name))
		parent.add_child(passage)
		passage.owner = scene_root
		scene_root.set_editable_instance(passage, true)
		passage.position = wall_center
		if rotate_left:
			passage.rotation_degrees.y = 90.0
	return int(arch != null) + int(passage != null)


func _compose_arch_torches(
	parent: Node3D,
	scene_root: Node,
	asset: PackedScene,
	wall_definition: Dictionary,
	footprint: Array,
	voxel_size: float,
	floor_thickness: int
) -> int:
	var width := int(footprint[0])
	var depth := int(footprint[1])
	var thickness := int(wall_definition.get("thickness_voxels", 6))
	var origin_x := -float(width) * voxel_size * 0.5
	var origin_z := -float(depth) * voxel_size * 0.5
	var count := 0
	for aperture_variant in wall_definition.get("apertures", []):
		var aperture: Dictionary = aperture_variant
		var wall_name := str(aperture.get("wall", ""))
		var center_along := int(aperture.get("along_voxels", 0))
		for offset_variant in aperture.get("torch_along_offsets_voxels", [-11, 11]):
			var torch := asset.instantiate() as Node3D
			if torch == null:
				continue
			torch.name = "Torch_%s_%02d" % [str(aperture.get("id", wall_name)), count + 1]
			parent.add_child(torch)
			torch.owner = scene_root
			scene_root.set_editable_instance(torch, true)
			var along := center_along + int(offset_variant)
			if wall_name == "left_wall":
				torch.position = Vector3(
					origin_x + float(thickness) * voxel_size,
					float(floor_thickness + 16) * voxel_size,
					origin_z + float(thickness + along) * voxel_size
				)
				torch.rotation_degrees.y = 90.0
			else:
				torch.position = Vector3(
					origin_x + float(along) * voxel_size,
					float(floor_thickness + 16) * voxel_size,
					origin_z + float(thickness) * voxel_size
				)
			count += 1
	return count


func _compose_camp(
	parent: Node3D,
	scene_root: Node,
	fire_asset: PackedScene,
	jerv_asset: PackedScene,
	chest_asset: PackedScene,
	camp_definition: Dictionary,
	floor_thickness: int,
	voxel_size: float
) -> int:
	var floor_top := float(floor_thickness) * voxel_size
	var count := 0
	var fire_definition: Dictionary = camp_definition.get("campfire", {})
	var fire := fire_asset.instantiate() as Node3D
	if fire != null:
		fire.name = "Campfire"
		parent.add_child(fire)
		fire.owner = scene_root
		scene_root.set_editable_instance(fire, true)
		var point: Array = fire_definition.get("position_voxels", [0, 0])
		fire.position = Vector3(float(point[0]) * voxel_size, floor_top, float(point[1]) * voxel_size)
		count += 1
	for definition in [
		{"id": "JervOnBedroll", "asset": jerv_asset, "key": "jerv"},
		{"id": "TreasureChest", "asset": chest_asset, "key": "treasure_chest"}
	]:
		var object_definition: Dictionary = camp_definition.get(str(definition["key"]), {})
		var instance := (definition["asset"] as PackedScene).instantiate() as Node3D
		if instance == null:
			continue
		instance.name = str(definition["id"])
		parent.add_child(instance)
		instance.owner = scene_root
		scene_root.set_editable_instance(instance, true)
		var point: Array = object_definition.get("position_voxels", [0, 0])
		instance.position = Vector3(float(point[0]) * voxel_size, floor_top, float(point[1]) * voxel_size)
		instance.rotation_degrees.y = float(object_definition.get("rotation_y_degrees", 0.0))
		count += 1
	return count


func _compose_vegetation(
	parent: Node3D,
	scene_root: Node,
	asset: PackedScene,
	definitions: Array,
	floor_thickness: int,
	voxel_size: float
) -> int:
	var count := 0
	for index in range(definitions.size()):
		var definition: Dictionary = definitions[index]
		var patch := asset.instantiate() as Node3D
		if patch == null:
			continue
		patch.name = str(definition.get("id", "MossPatch_%02d" % index))
		parent.add_child(patch)
		patch.owner = scene_root
		scene_root.set_editable_instance(patch, true)
		var point: Array = definition.get("position_voxels", [0, 0])
		patch.position = Vector3(float(point[0]) * voxel_size, float(floor_thickness) * voxel_size, float(point[1]) * voxel_size)
		patch.rotation_degrees.y = float(definition.get("rotation_y_degrees", 0.0))
		count += 1
	return count


func _partition(total: int, minimum: int, maximum: int, rng: RandomNumberGenerator) -> Array[int]:
	var result: Array[int] = []
	var remaining := total
	var feasible_cache: Dictionary = {}
	while remaining > 0:
		var options: Array[int] = []
		for size in range(minimum, maximum + 1):
			if size > remaining:
				break
			if _can_partition(remaining - size, minimum, maximum, feasible_cache):
				options.append(size)
		if options.is_empty():
			push_error("Cannot divide %d voxels into segments between %d and %d" % [total, minimum, maximum])
			return []
		var chosen := options[rng.randi_range(0, options.size() - 1)]
		result.append(chosen)
		remaining -= chosen
	return result


func _can_partition(remaining: int, minimum: int, maximum: int, cache: Dictionary) -> bool:
	if remaining == 0:
		return true
	if remaining < minimum:
		return false
	if cache.has(remaining):
		return bool(cache[remaining])
	for size in range(minimum, maximum + 1):
		if size <= remaining and _can_partition(remaining - size, minimum, maximum, cache):
			cache[remaining] = true
			return true
	cache[remaining] = false
	return false


func _pick_material(material_ids: Array, rng: RandomNumberGenerator, fallback: String) -> String:
	if material_ids.is_empty():
		return fallback
	return str(material_ids[rng.randi_range(0, material_ids.size() - 1)])


func _remove_named_child(parent: Node, child_name: String) -> void:
	var existing := parent.get_node_or_null(NodePath(child_name))
	if existing != null:
		parent.remove_child(existing)
		existing.free()


func _load_source(filename: String) -> Dictionary:
	var source_path := ProjectSettings.globalize_path(SOURCE_DIRECTORY.path_join(filename))
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		push_error("Unable to open canonical scene source: %s" % source_path)
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK or not parser.data is Dictionary:
		push_error("Invalid canonical scene source: %s" % source_path)
		return {}
	return parser.data


func _vector3i_from_array(values: Array) -> Vector3i:
	return Vector3i(int(values[0]), int(values[1]), int(values[2]))
