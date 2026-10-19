@tool
extends Node3D

const SOURCE_DIRECTORY := "res://../../assets/scenes/test-visual-voxel/sources"
const SET_SCENE_PATH := "res://tests/test-visual-voxel/test_visual_voxel_diorama.tscn"
const BLOCK_SCENE_PATH := "res://tests/test-visual-voxel/assets/stone_masonry_block.tscn"
const SLAB_SCENE_PATH := "res://tests/test-visual-voxel/assets/stone_floor_slab.tscn"
const LOOSE_STONE_SCENE_PATH := "res://tests/test-visual-voxel/assets/loose_stone.tscn"
const RUBBLE_CLUSTER_SCENE_PATH := "res://tests/test-visual-voxel/assets/stone_rubble_cluster.tscn"


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

	print("Set %d floor slabs, %d masonry blocks and %d debris assets in %s" % [floor_count, block_count, debris_count, SET_SCENE_PATH])
	return true


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
	var course_heights := _partition(height, int(course_height_range[0]), int(course_height_range[1]), rng)
	var y_cursor := 0
	var block_count := 0
	var block_index := 0
	for course_index in range(course_heights.size()):
		var course_height: int = course_heights[course_index]
		var segment_sizes := _partition(length, int(block_width_range[0]), int(block_width_range[1]), rng)
		var along_cursor := 0
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
