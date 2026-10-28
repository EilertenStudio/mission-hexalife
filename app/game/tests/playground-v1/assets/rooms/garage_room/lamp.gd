extends "res://tests/playground-v1/assets/rooms/garage_room/scripts/interactable_sprite.gd"

const SWING_ANGLE_DEGREES := 7.0

var _rest_rotation := 0.0
var _pivot_offset := Vector2.ZERO
var _anchor_position := Vector2.ZERO
var _current_swing_angle := 0.0
var _swing_direction := 1.0
var _swing_tween: Tween


func _ready() -> void:
	super._ready()
	if texture == null:
		return
	_rest_rotation = rotation
	_pivot_offset = Vector2(0.0, -float(texture.get_height()) * 0.5) * scale
	_anchor_position = position + _pivot_offset.rotated(_rest_rotation)


func _perform_interaction() -> void:
	_swing()


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
