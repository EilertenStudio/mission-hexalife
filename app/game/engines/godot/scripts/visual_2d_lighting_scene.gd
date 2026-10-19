extends Node2D

enum LightMode { RAYTRACE_2D, SHADER_2D, STAR_RADIAL }

const MODE_LABELS := ["2D RAYTRACE", "2D SHADER", "STAR RADIAL"]

var light_mode: LightMode = LightMode.RAYTRACE_2D

@onready var central_star: Node = $GravityStar
@onready var spell_vfx: Node = $SpellVFX
@onready var beam_overlay: ColorRect = $BeamOverlay/Beam
@onready var raytrace_light: Sprite2D = $BeamOverlay/RayTraceLight


func _ready() -> void:
	_set_light_mode(LightMode.RAYTRACE_2D)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_TAB:
		_set_light_mode((int(light_mode) + 1) % LightMode.size())
		get_viewport().set_input_as_handled()


func supports_gameplay_debug() -> bool:
	return false


func get_lighting_mode_label() -> String:
	return MODE_LABELS[int(light_mode)]


func get_lighting_mode_id() -> String:
	match light_mode:
		LightMode.RAYTRACE_2D:
			return "beam_2d_raytrace"
		LightMode.SHADER_2D:
			return "beam_2d_shader"
		_:
			return "star_radial"


func get_light_probe_state() -> Dictionary:
	return {
		"mode": get_lighting_mode_id(),
		"aim_pixel": beam_overlay.call("get_target_pixel"),
		"raytrace_lightmap_size": raytrace_light.texture.get_size() if raytrace_light.texture != null else Vector2.ZERO,
		"rendering_method": "2d",
	}


func _set_light_mode(next_mode: LightMode) -> void:
	light_mode = next_mode
	var radial_enabled := light_mode == LightMode.STAR_RADIAL
	var shader_enabled := light_mode == LightMode.SHADER_2D
	var raytrace_enabled := light_mode == LightMode.RAYTRACE_2D
	central_star.call("set_radial_mode_enabled", radial_enabled)
	spell_vfx.call("set_radial_lights_enabled", radial_enabled)
	beam_overlay.call("set_light_modes", shader_enabled, raytrace_enabled, shader_enabled or raytrace_enabled)
	queue_redraw()
