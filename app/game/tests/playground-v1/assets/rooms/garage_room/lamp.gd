extends "res://tests/playground-v1/assets/rooms/garage_room/scripts/interactable_sprite.gd"

const SWING_ANGLE_DEGREES := 7.0
const BULB_HOTSPOT := Rect2i(156, 15, 8, 7)

@onready var _squeak_audio: AudioStreamPlayer = $SqueakAudio

var _rest_rotation := 0.0
var _pivot_offset := Vector2.ZERO
var _anchor_position := Vector2.ZERO
var _current_swing_angle := 0.0
var _swing_direction := 1.0
var _swing_tween: Tween
var _bulb_highlight_texture: Texture2D


func _ready() -> void:
	super._ready()
	if texture == null:
		return
	_rest_rotation = rotation
	_pivot_offset = Vector2(0.0, -float(texture.get_height()) * 0.5) * scale
	_anchor_position = position + _pivot_offset.rotated(_rest_rotation)
	_bulb_highlight_texture = _make_bulb_highlight_texture()


func get_interaction_pixel_color_at(world_point: Vector2) -> Color:
	if texture == null:
		return Color.TRANSPARENT
	var image_position := to_local(world_point) + Vector2(texture.get_size()) * 0.5 - offset
	if flip_h:
		image_position.x = float(texture.get_width()) - image_position.x
	if flip_v:
		image_position.y = float(texture.get_height()) - image_position.y
	var pixel := Vector2i(floori(image_position.x), floori(image_position.y))
	if not BULB_HOTSPOT.has_point(pixel):
		return Color.TRANSPARENT
	return super.get_interaction_pixel_color_at(world_point)


func get_interaction_highlight_texture() -> Texture2D:
	return _bulb_highlight_texture


func set_squeak_sample(sample: AudioStream) -> void:
	_squeak_audio.stream = sample


func _perform_interaction() -> void:
	_squeak_audio.play()
	_swing()


func _make_bulb_highlight_texture() -> Texture2D:
	if texture == null:
		return null
	var source := texture.get_image()
	if source == null or source.is_empty():
		return null
	var highlight := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	highlight.fill(Color.TRANSPARENT)
	for y in range(BULB_HOTSPOT.position.y, BULB_HOTSPOT.end.y):
		for x in range(BULB_HOTSPOT.position.x, BULB_HOTSPOT.end.x):
			var source_color := source.get_pixel(x, y)
			if source_color.a > 0.0 and source_color.get_luminance() > 0.0:
				highlight.set_pixel(x, y, Color(1.0, 1.0, 1.0, source_color.a))
	return ImageTexture.create_from_image(highlight)


func _swing() -> void:
	if _swing_tween != null and _swing_tween.is_running():
		_swing_tween.kill()

	_swing_direction *= -1.0
	var first_peak := deg_to_rad(SWING_ANGLE_DEGREES) * _swing_direction
	var second_peak := -first_peak * 0.55
	var third_peak := first_peak * 0.28
	_swing_tween = create_tween()
	_swing_tween.tween_method(
		_set_swing_angle, _current_swing_angle, first_peak, 0.1
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_method(
		_set_swing_angle, first_peak, second_peak, 0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_swing_tween.tween_method(
		_set_swing_angle, second_peak, third_peak, 0.18
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_swing_tween.tween_method(
		_set_swing_angle, third_peak, 0.0, 0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_swing_angle(angle: float) -> void:
	_current_swing_angle = angle
	var absolute_rotation := _rest_rotation + angle
	rotation = absolute_rotation
	position = _anchor_position - _pivot_offset.rotated(absolute_rotation)
