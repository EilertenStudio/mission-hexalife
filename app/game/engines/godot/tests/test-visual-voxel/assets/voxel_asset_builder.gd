extends RefCounted

const SOURCE_DIRECTORY := "res://../../assets/scenes/test-visual-voxel/sources"


static func load_source(filename: String) -> Dictionary:
	var path := ProjectSettings.globalize_path(SOURCE_DIRECTORY.path_join(filename))
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open canonical scene source: %s" % path)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		push_error("Invalid canonical scene source: %s" % path)
		return {}
	return parser.data


static func load_materials() -> Dictionary:
	var source := load_source("materials.json")
	var result: Dictionary = {}
	for material_id_variant in source.get("materials", {}):
		var material_id := str(material_id_variant)
		var definition: Dictionary = source["materials"][material_id]
		var material := StandardMaterial3D.new()
		material.resource_name = "%s material" % material_id
		material.albedo_color = color_from_rgb(definition.get("color_rgb", [255, 255, 255]))
		material.roughness = float(definition.get("roughness", 0.95))
		material.metallic = float(definition.get("metallic", 0.0))
		var emission: Array = definition.get("emission_rgb", [])
		if not emission.is_empty():
			material.emission_enabled = true
			material.emission = color_from_rgb(emission)
			material.emission_energy_multiplier = float(definition.get("emission_energy", 1.0))
		result[material_id] = material
	return result


static func load_light_definition(anchor: String) -> Dictionary:
	var source := load_source("lighting.json")
	for light_variant in source.get("lights", []):
		var light: Dictionary = light_variant
		if str(light.get("anchor", "")) == anchor:
			return light
	return {}


static func load_particle_definition(particle_id: String) -> Dictionary:
	var source := load_source("lighting.json")
	for particle_variant in source.get("particles", []):
		var particle: Dictionary = particle_variant
		if str(particle.get("id", "")) == particle_id:
			return particle
	return {}


static func clear_generated(root: Node3D) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.free()


static func add_node(parent: Node, root: Node, child: Node) -> Node:
	parent.add_child(child)
	child.owner = root
	return child


static func add_group(parent: Node, root: Node, group_name: String) -> Node3D:
	var group := Node3D.new()
	group.name = group_name
	return add_node(parent, root, group) as Node3D


static func add_voxel_box(
	parent: Node,
	root: Node,
	name: String,
	center_voxels: Vector3,
	size_voxels: Vector3,
	voxel_size: float,
	material: Material,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.resource_name = "%s voxel block" % name
	box.size = size_voxels * voxel_size
	box.material = material
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = box
	instance.position = center_voxels * voxel_size
	instance.rotation_degrees = rotation_degrees
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return add_node(parent, root, instance) as MeshInstance3D


static func add_smoke(
	parent: Node,
	root: Node,
	name: String,
	position_meters: Vector3,
	voxel_size: float,
	definition: Dictionary
) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = name
	particles.position = position_meters
	particles.amount = int(definition.get("amount", 12))
	particles.lifetime = float(definition.get("lifetime_seconds", 2.5))
	particles.preprocess = float(definition.get("preprocess_seconds", 0.7))
	particles.explosiveness = 0.0
	particles.randomness = 0.28
	particles.emitting = true
	particles.local_coords = true
	particles.visibility_aabb = AABB(Vector3(-0.8, -0.5, -0.8), Vector3(1.6, 2.8, 1.6))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = float(definition.get("spread_degrees", 18.0))
	var velocity: Array = definition.get("initial_velocity_meters_per_second", [0.12, 0.38])
	process.initial_velocity_min = float(velocity[0])
	process.initial_velocity_max = float(velocity[1])
	var gravity: Array = definition.get("gravity_meters_per_second_squared", [0.0, 0.05, 0.0])
	process.gravity = Vector3(float(gravity[0]), float(gravity[1]), float(gravity[2]))
	process.scale_min = float(definition.get("minimum_scale", 0.75))
	process.scale_max = float(definition.get("maximum_scale", 1.45))
	var color := color_from_rgba(definition.get("color_rgba", [82, 82, 82, 117]))
	process.color = color
	particles.process_material = process
	var particle_box := BoxMesh.new()
	particle_box.size = Vector3.ONE * voxel_size * float(definition.get("particle_size_voxels", 1.0))
	var particle_material := StandardMaterial3D.new()
	particle_material.albedo_color = Color(color.r, color.g, color.b, 0.88)
	particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_box.material = particle_material
	particles.draw_passes = 1
	particles.draw_pass_1 = particle_box
	return add_node(parent, root, particles) as GPUParticles3D


static func add_omni_light(
	parent: Node,
	root: Node,
	name: String,
	position_meters: Vector3,
	color: Color,
	energy: float,
	range_meters: float
) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = name
	light.position = position_meters
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_meters
	light.shadow_enabled = false
	return add_node(parent, root, light) as OmniLight3D


static func color_from_rgb(values: Array) -> Color:
	return Color(float(values[0]) / 255.0, float(values[1]) / 255.0, float(values[2]) / 255.0)


static func color_from_rgba(values: Array) -> Color:
	var color := color_from_rgb(values)
	if values.size() >= 4:
		color.a = float(values[3]) / 255.0
	return color


static func vector3i_from_array(values: Array, fallback: Vector3i = Vector3i.ZERO) -> Vector3i:
	if values.size() < 3:
		return fallback
	return Vector3i(int(values[0]), int(values[1]), int(values[2]))
