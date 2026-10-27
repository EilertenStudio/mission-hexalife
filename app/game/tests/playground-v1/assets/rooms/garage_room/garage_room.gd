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
@onready var _ambient: CanvasModulate = $Lighting/AmbientDarkness
@onready var _switcher: Sprite2D = $Switcher
@onready var _lighting_controls: CanvasLayer = $LightingControls

var _lamp_is_on := false
var _flashlight_is_on := false
var _flicker_clock := 0.0


func _ready() -> void:
	var soft_light := _create_soft_light_texture()
	_bulb_glow.texture = soft_light
	_ceiling_pool.texture = soft_light
	_flashlight.texture = soft_light
	var background_image := _background.texture.get_image()
	_left_window_light.texture = _create_window_light_texture(
		background_image, LEFT_WINDOW_SOURCE_RECT
	)
	_right_window_light.texture = _create_window_light_texture(
		background_image, RIGHT_WINDOW_SOURCE_RECT
	)
	_left_window_light.position = _get_window_light_position(LEFT_WINDOW_SOURCE_RECT)
	_right_window_light.position = _get_window_light_position(RIGHT_WINDOW_SOURCE_RECT)
	_left_window_light.texture_scale = _background.scale.x
	_right_window_light.texture_scale = _background.scale.x
	_ambient.color = Color(ambient_level, ambient_level, ambient_level, 1.0)
	_flashlight.texture_scale = 3.0
	_flashlight.global_position = get_global_mouse_position()
	_flashlight.enabled = false
	_switcher.connect("state_changed", _on_switcher_state_changed)
	_lighting_controls.ambient_level_changed.connect(_on_ambient_level_changed)
	_lighting_controls.window_light_energy_changed.connect(_on_window_light_energy_changed)
	_lighting_controls.flashlight_energy_changed.connect(_on_flashlight_energy_changed)
	_lighting_controls.bulblight_energy_changed.connect(_on_bulblight_energy_changed)
	_lighting_controls.flashlight_toggle_requested.connect(_toggle_flashlight)
	_lighting_controls.bulblight_toggle_requested.connect(_toggle_bulblight)
	_lighting_controls.set_control_values(
		ambient_level, window_light_energy, flashlight_energy, bulblight_energy
	)
	_lighting_controls.set_flashlight_enabled(_flashlight_is_on)
	_on_ambient_level_changed(ambient_level)
	_on_window_light_energy_changed(window_light_energy)
	_on_flashlight_energy_changed(flashlight_energy)
	_on_bulblight_energy_changed(bulblight_energy)
	_switcher.call("set_is_on", false)


func _process(delta: float) -> void:
	_flicker_clock += delta
	var mouse_position := get_global_mouse_position()
	_flashlight.global_position = mouse_position

	if _lamp_is_on:
		var small_flicker := (
			0.97
			+ sin(_flicker_clock * 17.0) * 0.018
			+ sin(_flicker_clock * 5.3) * 0.012
		)
		_bulb_glow.energy = bulblight_energy * small_flicker
		_ceiling_pool.energy = bulblight_energy * 0.5 * (0.98 + sin(_flicker_clock * 7.1) * 0.02)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		_toggle_flashlight()
		get_viewport().set_input_as_handled()


func _create_soft_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.12, Color(1.0, 1.0, 1.0, 0.88))
	gradient.add_point(0.55, Color(1.0, 1.0, 1.0, 0.24))

	var light_texture := GradientTexture2D.new()
	light_texture.gradient = gradient
	light_texture.width = 256
	light_texture.height = 256
	light_texture.fill = GradientTexture2D.FILL_RADIAL
	light_texture.fill_from = Vector2(0.5, 0.5)
	light_texture.fill_to = Vector2(1.0, 0.5)
	return light_texture


func _create_window_light_texture(source: Image, source_rect: Rect2i) -> ImageTexture:
	var mask := Image.create(source_rect.size.x, source_rect.size.y, false, Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	for y in range(source_rect.size.y):
		for x in range(source_rect.size.x):
			var source_pixel := source.get_pixel(
				source_rect.position.x + x, source_rect.position.y + y
			)
			if source_pixel.r > 0.0:
				mask.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(mask)


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
	_bulb_glow.energy = value
	_ceiling_pool.energy = value * 0.5


func _on_switcher_state_changed(is_on: bool) -> void:
	_lamp_is_on = is_on
	_bulb_glow.enabled = is_on
	_ceiling_pool.enabled = is_on
	_lighting_controls.set_bulblight_enabled(is_on)
