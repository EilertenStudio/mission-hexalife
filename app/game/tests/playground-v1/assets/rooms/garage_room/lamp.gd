extends Sprite2D

const SWING_ANGLE_DEGREES := 7.0

var _hit_mask: Image
var _rest_rotation := 0.0
var _pivot_offset := Vector2.ZERO
var _anchor_position := Vector2.ZERO
var _current_swing_angle := 0.0
var _swing_direction := 1.0
var _swing_tween: Tween


func _ready() -> void:
	if texture == null:
		return
	_hit_mask = texture.get_image()
	_rest_rotation = rotation
	_pivot_offset = Vector2(0.0, -float(_hit_mask.get_height()) * 0.5) * scale
	_anchor_position = position + _pivot_offset.rotated(_rest_rotation)


func _input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and _contains_opaque_pixel(get_global_mouse_position())
	):
		_swing()
		get_viewport().set_input_as_handled()


func _contains_opaque_pixel(world_point: Vector2) -> bool:
	if _hit_mask == null or _hit_mask.is_empty():
		return false

	var texture_position := (
		to_local(world_point) + Vector2(_hit_mask.get_size()) * 0.5 - offset
	)
	var pixel := Vector2i(floori(texture_position.x), floori(texture_position.y))
	if (
		pixel.x < 0
		or pixel.y < 0
		or pixel.x >= _hit_mask.get_width()
		or pixel.y >= _hit_mask.get_height()
	):
		return false
	return _hit_mask.get_pixelv(pixel).a > 0.0


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
