extends Node2D

@export_range(0.0, 0.3, 0.01) var ambient_level := 0.0
@export_range(0.0, 2.0, 0.01) var window_light_energy := 0.32
@export_range(0.0, 4.0, 0.05) var flashlight_energy := 2.0
@export_range(0.0, 2.0, 0.05) var bulblight_energy := 2.0

const LEFT_WINDOW_SOURCE_RECT := Rect2i(106, 41, 38, 14)
const RIGHT_WINDOW_SOURCE_RECT := Rect2i(176, 41, 38, 14)

@onready var _flashlight: PointLight2D = $Lighting/Flashlight
@onready var _left_window_light: PointLight2D = $Lighting/LeftWindowLight
@onready var _right_window_light: PointLight2D = $Lighting/RightWindowLight
@onready var _background: Sprite2D = $Background
@onready var _bulb_glow: PointLight2D = $Lighting/BulbGlow
@onready var _ceiling_pool: PointLight2D = $Lighting/CeilingPool
@onready var _bulb_light_origin: Marker2D = $Lamp/BulbLightOrigin
@onready var _ceiling_pool_origin: Marker2D = $Lamp/CeilingPoolOrigin
@onready var _ambient: CanvasModulate = $Lighting/AmbientDarkness
@onready var _switcher: Sprite2D = $Switcher
@onready var _lighting_controls: CanvasLayer = $LightingControls
@onready var _interaction_controller: Node = $InteractionController
@onready var _light_range_overlay: Node2D = $LightRangeOverlay
@onready var _exterior_rain: Node = $ExteriorRain

var _lamp_is_on := false
var _flashlight_is_on := false
var _flicker_random := RandomNumberGenerator.new()
var _flicker_time_until_next := 0.0
var _flicker_steps := PackedFloat32Array()
var _flicker_step_index := 0
var _flicker_step_time_left := 0.0
var _flicker_multiplier := 1.0


func _ready() -> void:
	_flicker_random.randomize()
	_schedule_next_bulb_flicker()
	_left_window_light.position = _get_window_light_position(LEFT_WINDOW_SOURCE_RECT)
	_right_window_light.position = _get_window_light_position(RIGHT_WINDOW_SOURCE_RECT)
	_left_window_light.texture_scale = _background.scale.x
	_right_window_light.texture_scale = _background.scale.x
	_ambient.color = Color(ambient_level, ambient_level, ambient_level, 1.0)
	_flashlight.texture_scale = 3.0
	_flashlight.global_position = get_global_mouse_position()
	_update_lamp_light_positions()
	_flashlight.enabled = false
	_switcher.connect("state_changed", _on_switcher_state_changed)
	_lighting_controls.ambient_level_changed.connect(_on_ambient_level_changed)
	_lighting_controls.window_light_energy_changed.connect(_on_window_light_energy_changed)
	_lighting_controls.flashlight_energy_changed.connect(_on_flashlight_energy_changed)
	_lighting_controls.bulblight_energy_changed.connect(_on_bulblight_energy_changed)
	_lighting_controls.window_light_range_changed.connect(_on_window_light_range_changed)
	_lighting_controls.flashlight_range_changed.connect(_on_flashlight_range_changed)
	_lighting_controls.bulb_glow_range_changed.connect(_on_bulb_glow_range_changed)
	_lighting_controls.ceiling_pool_range_changed.connect(_on_ceiling_pool_range_changed)
	_lighting_controls.light_ranges_visibility_changed.connect(_on_light_ranges_visibility_changed)
	_lighting_controls.flashlight_toggle_requested.connect(_toggle_flashlight)
	_lighting_controls.bulblight_toggle_requested.connect(_toggle_bulblight)
	_lighting_controls.rain_source_changed.connect(_on_rain_source_changed)
	_lighting_controls.rain_volume_changed.connect(_on_rain_volume_changed)
	_lighting_controls.interaction_visibility_threshold_changed.connect(
		_on_interaction_visibility_threshold_changed
	)
	_lighting_controls.interaction_highlight_intensity_changed.connect(
		_on_interaction_highlight_intensity_changed
	)
	_lighting_controls.set_rain_sample_enabled(
		_exterior_rain.get("source_mode") == 0
	)
	_lighting_controls.set_rain_volume(
		db_to_linear(float(_exterior_rain.get("volume_db")))
	)
	_lighting_controls.set_interaction_visibility_threshold(
		float(_interaction_controller.get("visibility_threshold"))
	)
	_lighting_controls.set_interaction_highlight_intensity(
		float(_interaction_controller.get("highlight_intensity"))
	)
	_lighting_controls.set_control_values(
		ambient_level, window_light_energy, flashlight_energy, bulblight_energy
	)
	_lighting_controls.set_flashlight_enabled(_flashlight_is_on)
	_light_range_overlay.call(
		"set_lights",
		[_left_window_light, _right_window_light, _flashlight, _bulb_glow, _ceiling_pool]
	)
	_light_range_overlay.call("set_ranges_visible", false)
	_lighting_controls.call(
		"set_range_control_values",
		false,
		_left_window_light.texture.get_width() * _left_window_light.texture_scale,
		_flashlight.texture.get_width() * _flashlight.texture_scale * 0.5,
		_bulb_glow.texture.get_width() * _bulb_glow.texture_scale * 0.5,
		_ceiling_pool.texture.get_width() * _ceiling_pool.texture_scale * 0.5
	)
	_on_ambient_level_changed(ambient_level)
	_on_window_light_energy_changed(window_light_energy)
	_on_flashlight_energy_changed(flashlight_energy)
	_on_bulblight_energy_changed(bulblight_energy)
	_switcher.call("set_is_on", false)


func _process(delta: float) -> void:
	var mouse_position := get_global_mouse_position()
	_flashlight.global_position = mouse_position
	_update_lamp_light_positions()

	if _lamp_is_on:
		_update_bulb_flicker(delta)
		_apply_bulblight_energy()


func _update_lamp_light_positions() -> void:
	_bulb_glow.global_position = _bulb_light_origin.global_position
	_ceiling_pool.global_position = _ceiling_pool_origin.global_position


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if (
		key_event.keycode == KEY_EQUAL
		or key_event.physical_keycode == KEY_EQUAL
		or key_event.unicode == 61
	):
		_lighting_controls.visible = not _lighting_controls.visible
		get_viewport().set_input_as_handled()
	elif key_event.physical_keycode == KEY_F or key_event.keycode == KEY_F:
		_toggle_flashlight()
		get_viewport().set_input_as_handled()


func _get_window_light_position(source_rect: Rect2i) -> Vector2:
	var source_size := Vector2(_background.texture.get_size())
	var source_center := Vector2(source_rect.position) + Vector2(source_rect.size) * 0.5
	return _background.position + (source_center - source_size * 0.5) * _background.scale


func _on_flashlight_energy_changed(value: float) -> void:
	flashlight_energy = value
	_flashlight.energy = value
	_update_flashlight_state()


func _on_ambient_level_changed(value: float) -> void:
	ambient_level = value
	_ambient.color = Color(value, value, value, 1.0)


func _on_window_light_energy_changed(value: float) -> void:
	window_light_energy = value
	var is_enabled := value > 0.0
	_left_window_light.enabled = is_enabled
	_right_window_light.enabled = is_enabled
	_left_window_light.energy = value
	_right_window_light.energy = value


func _toggle_flashlight() -> void:
	_flashlight_is_on = not _flashlight_is_on
	_update_flashlight_state()


func _toggle_bulblight() -> void:
	_switcher.call("set_is_on", not _lamp_is_on)


func _update_flashlight_state() -> void:
	var is_effectively_on := _flashlight_is_on and flashlight_energy > 0.0
	_flashlight.enabled = is_effectively_on
	_lighting_controls.set_flashlight_enabled(_flashlight_is_on)


func _on_bulblight_energy_changed(value: float) -> void:
	bulblight_energy = value
	_apply_bulblight_energy()


func _on_window_light_range_changed(width_px: float) -> void:
	var texture_width := float(_left_window_light.texture.get_width())
	var texture_scale := width_px / texture_width
	_left_window_light.texture_scale = texture_scale
	_right_window_light.texture_scale = texture_scale
	_light_range_overlay.queue_redraw()


func _on_flashlight_range_changed(radius_px: float) -> void:
	_flashlight.texture_scale = radius_px / (float(_flashlight.texture.get_width()) * 0.5)
	_light_range_overlay.queue_redraw()


func _on_bulb_glow_range_changed(radius_px: float) -> void:
	_bulb_glow.texture_scale = radius_px / (float(_bulb_glow.texture.get_width()) * 0.5)
	_light_range_overlay.queue_redraw()


func _on_ceiling_pool_range_changed(radius_px: float) -> void:
	_ceiling_pool.texture_scale = radius_px / (float(_ceiling_pool.texture.get_width()) * 0.5)
	_light_range_overlay.queue_redraw()


func _on_light_ranges_visibility_changed(show_ranges: bool) -> void:
	_light_range_overlay.call("set_ranges_visible", show_ranges)


func _on_rain_source_changed(use_sample: bool) -> void:
	_exterior_rain.call("set_sample_enabled", use_sample)


func _on_rain_volume_changed(value: float) -> void:
	_exterior_rain.call("set_volume_linear", value)


func _on_interaction_visibility_threshold_changed(value: float) -> void:
	_interaction_controller.call("set_visibility_threshold", value)


func _on_interaction_highlight_intensity_changed(value: float) -> void:
	_interaction_controller.call("set_highlight_intensity", value)


func _on_switcher_state_changed(is_on: bool) -> void:
	_lamp_is_on = is_on
	_bulb_glow.enabled = is_on
	_ceiling_pool.enabled = is_on
	_flicker_steps.clear()
	_flicker_step_index = 0
	_flicker_step_time_left = 0.0
	_flicker_multiplier = 1.0
	if is_on:
		_schedule_next_bulb_flicker()
	_apply_bulblight_energy()
	_lighting_controls.set_bulblight_enabled(is_on)


func _schedule_next_bulb_flicker() -> void:
	_flicker_time_until_next = _flicker_random.randf_range(2.8, 7.0)


func _update_bulb_flicker(delta: float) -> void:
	if _flicker_steps.is_empty():
		_flicker_time_until_next -= delta
		if _flicker_time_until_next <= 0.0:
			_flicker_steps = PackedFloat32Array([
				_flicker_random.randf_range(0.84, 0.95),
				_flicker_random.randf_range(0.60, 0.78),
				_flicker_random.randf_range(0.86, 0.97),
				1.0
			])
			_flicker_step_index = 0
			_flicker_step_time_left = 0.0
		return

	_flicker_step_time_left -= delta
	if _flicker_step_time_left > 0.0:
		return

	if _flicker_step_index >= _flicker_steps.size():
		_flicker_steps.clear()
		_flicker_multiplier = 1.0
		_schedule_next_bulb_flicker()
		return

	_flicker_multiplier = _flicker_steps[_flicker_step_index]
	_flicker_step_index += 1
	_flicker_step_time_left = (
		_flicker_random.randf_range(0.08, 0.14)
		if _flicker_step_index == _flicker_steps.size()
		else _flicker_random.randf_range(0.035, 0.075)
	)


func _apply_bulblight_energy() -> void:
	var flicker := _flicker_multiplier if _lamp_is_on else 1.0
	_bulb_glow.energy = bulblight_energy * flicker
	_ceiling_pool.energy = bulblight_energy * 0.5 * flicker
