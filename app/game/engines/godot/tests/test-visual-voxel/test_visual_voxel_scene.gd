@tool
extends Node3D

const SOURCE_DIRECTORY := "res://../../assets/scenes/test-visual-voxel/sources"

@onready var scene_camera: Camera3D = get_node_or_null("Camera3D") as Camera3D
@onready var world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment


func _ready() -> void:
	var lighting := _load_source("lighting.json")
	var camera_source := _load_source("camera.json")
	_configure_camera(camera_source)
	_configure_environment(lighting.get("environment", {}))
	_build_lighting(lighting.get("lights", []))


func supports_gameplay_debug() -> bool:
	return false


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


func _configure_camera(source: Dictionary) -> void:
	if scene_camera == null:
		return
	var projection: Dictionary = source.get("projection", {})
	var initial_view: Dictionary = source.get("initial_view", {})
	if str(projection.get("type", "orthographic")) == "orthographic":
		scene_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		scene_camera.size = float(projection.get("vertical_size_meters", 20.5))
	else:
		scene_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		scene_camera.fov = float(projection.get("field_of_view_degrees", 42.0))
	scene_camera.position = _vector3_from_array(initial_view.get("position_meters", [14.14, 16.2, 14.14]))
	scene_camera.near = float(initial_view.get("near_meters", 0.05))
	scene_camera.far = float(initial_view.get("far_meters", 80.0))
	scene_camera.look_at(
		_vector3_from_array(initial_view.get("target_meters", [0.0, 2.2, 0.0])),
		_vector3_from_array(initial_view.get("up_direction_meters", [0.0, 1.0, 0.0]))
	)
	scene_camera.current = true


func _configure_environment(definition: Dictionary) -> void:
	if world_environment == null:
		return
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = _color_from_rgb(definition.get("background_color_rgb", [226, 231, 232]))
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = _color_from_rgb(definition.get("ambient_color_rgb", [188, 190, 192]))
	environment.ambient_light_energy = float(definition.get("ambient_energy", 0.72))
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = bool(definition.get("glow_enabled", false))
	environment.glow_intensity = float(definition.get("glow_intensity", 0.0))
	environment.glow_bloom = float(definition.get("glow_bloom", 0.0))
	world_environment.environment = environment


func _build_lighting(light_definitions: Array) -> void:
	for definition_variant in light_definitions:
		var definition: Dictionary = definition_variant
		if definition.has("anchor"):
			continue
		var light_name := str(definition.get("id", "soft_daylight_key"))
		if get_node_or_null(NodePath(light_name)) != null:
			continue
		match str(definition.get("type", "")):
			"directional":
				var directional := DirectionalLight3D.new()
				directional.name = light_name
				directional.rotation_degrees = _vector3_from_array(definition.get("rotation_degrees", [-48, -32, 0]))
				directional.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				directional.light_color = _color_from_rgb(definition.get("color_rgb", [168, 192, 228]))
				directional.light_energy = float(definition.get("energy", 0.62))
				directional.shadow_enabled = bool(definition.get("shadows", true))
				add_child(directional)
			"omni":
				var omni := OmniLight3D.new()
				omni.name = light_name
				omni.position = _vector3_from_array(definition.get("position_meters", [0.0, 2.0, 0.0]))
				omni.light_color = _color_from_rgb(definition.get("color_rgb", [130, 165, 220]))
				omni.light_energy = float(definition.get("energy", 0.5))
				omni.omni_range = float(definition.get("range_meters", 5.0))
				omni.shadow_enabled = bool(definition.get("shadows", false))
				add_child(omni)


func _vector3_from_array(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func _color_from_rgb(values: Array) -> Color:
	return Color(float(values[0]) / 255.0, float(values[1]) / 255.0, float(values[2]) / 255.0)
