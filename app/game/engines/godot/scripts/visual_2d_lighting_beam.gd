extends ColorRect

const SOURCE_PIXEL := Vector2(176.0, 144.0)
const ROOM_MIN := Vector2(32.0, 32.0)
const ROOM_MAX := Vector2(352.0, 256.0)
const BEAM_SHADER: Shader = preload("res://scripts/visual_2d_lighting_beam.gdshader")

var beam_material: ShaderMaterial
var last_direction := Vector2.RIGHT
var beam_mode_enabled := false
var impact_enabled := true
var clipped_target := Vector2(352.0, 144.0)
@onready var raytrace_light: Sprite2D = get_parent().get_node("RayTraceLight")


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(384.0, 288.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam_material = ShaderMaterial.new()
	beam_material.shader = BEAM_SHADER
	material = beam_material
	raytrace_light.call("set_beam_direction", last_direction)
	_update_material()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	var mouse := (event as InputEventMouseMotion).position
	if mouse.x < 0.0 or mouse.x >= 384.0 or mouse.y < 0.0 or mouse.y >= 288.0:
		return
	var aim := mouse - SOURCE_PIXEL
	if aim.length_squared() <= 16.0:
		return
	last_direction = aim.normalized()
	clipped_target = _clip_to_inner_wall(last_direction)
	raytrace_light.call("set_beam_direction", last_direction)
	_update_material()


func set_light_modes(shader_enabled: bool, raytrace_enabled: bool, show_impact: bool) -> void:
	beam_mode_enabled = shader_enabled
	impact_enabled = show_impact
	visible = beam_mode_enabled or impact_enabled
	raytrace_light.visible = raytrace_enabled
	_update_material()


func get_target_pixel() -> Vector2:
	return clipped_target


func _clip_to_inner_wall(direction: Vector2) -> Vector2:
	var distance_x := INF
	var distance_y := INF
	if direction.x > 0.0001:
		distance_x = (ROOM_MAX.x - SOURCE_PIXEL.x) / direction.x
	elif direction.x < -0.0001:
		distance_x = (ROOM_MIN.x - SOURCE_PIXEL.x) / direction.x
	if direction.y > 0.0001:
		distance_y = (ROOM_MAX.y - SOURCE_PIXEL.y) / direction.y
	elif direction.y < -0.0001:
		distance_y = (ROOM_MIN.y - SOURCE_PIXEL.y) / direction.y
	var distance := minf(distance_x, distance_y)
	return SOURCE_PIXEL + direction * distance


func _update_material() -> void:
	if beam_material == null:
		return
	beam_material.set_shader_parameter("source_pixel", SOURCE_PIXEL)
	beam_material.set_shader_parameter("target_pixel", clipped_target)
	beam_material.set_shader_parameter("beam_enabled", 1.0 if beam_mode_enabled else 0.0)
	beam_material.set_shader_parameter("impact_enabled", 1.0 if impact_enabled else 0.0)
