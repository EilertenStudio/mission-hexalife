extends Node2D

const FRAME_SIZE := 32
const LOOP_FIRST_COLUMN := 4
const LOOP_FRAME_COUNT := 4
const LOOP_FRAME_DURATION := 0.18
const LOOP_DURATION := LOOP_FRAME_DURATION * LOOP_FRAME_COUNT
const LIGHT_TEXTURE_SIZE := 256
const LIGHT_TEXTURE_RADIUS := 128.0
const LIGHT_RADIUS_PIXELS := 168.0
const LIGHT_ENERGY := 2.2
const LIGHT_PULSE_AMOUNT := 0.08

@onready var star_sprite: Sprite2D = $Sprite
@onready var local_light: PointLight2D = $Light

var animation_time := 0.0
var current_frame := -1


func _ready() -> void:
	star_sprite.region_enabled = true
	star_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	local_light.texture = _create_radial_light_texture()
	local_light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	local_light.texture_scale = LIGHT_RADIUS_PIXELS * 2.0 / LIGHT_TEXTURE_SIZE
	local_light.color = Color(1.0, 0.78, 0.41, 1.0)
	local_light.energy = LIGHT_ENERGY
	local_light.enabled = true
	_update_loop_frame()


func _process(delta: float) -> void:
	animation_time = fmod(animation_time + delta, LOOP_DURATION)
	_update_loop_frame()
	var pulse_phase := animation_time / LOOP_DURATION * TAU
	local_light.energy = LIGHT_ENERGY + sin(pulse_phase) * LIGHT_PULSE_AMOUNT
	local_light.enabled = star_sprite.visible


func _update_loop_frame() -> void:
	var frame := int(animation_time / LOOP_FRAME_DURATION) % LOOP_FRAME_COUNT
	if frame == current_frame:
		return
	current_frame = frame
	var column := LOOP_FIRST_COLUMN + frame
	star_sprite.region_rect = Rect2(Vector2(column * FRAME_SIZE, 0), Vector2(FRAME_SIZE, FRAME_SIZE))


func _create_radial_light_texture() -> ImageTexture:
	var image := Image.create(LIGHT_TEXTURE_SIZE, LIGHT_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for y in range(LIGHT_TEXTURE_SIZE):
		for x in range(LIGHT_TEXTURE_SIZE):
			var offset := Vector2(x, y) - Vector2.ONE * (LIGHT_TEXTURE_SIZE - 1) * 0.5
			var normalized_distance := offset.length() / LIGHT_TEXTURE_RADIUS
			var falloff := pow(maxf(0.0, 1.0 - normalized_distance), 2.2)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, falloff))
	return ImageTexture.create_from_image(image)
