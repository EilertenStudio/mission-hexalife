extends "res://tests/playground-v1/assets/rooms/garage_room/scripts/interactable_sprite.gd"

signal state_changed(is_open: bool)

@export var starts_open := false

const CLOSED_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-door-CLOSED.png"
)
const OPEN_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-door-OPEN.png"
)
const MIDDLE_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-door-MIDDLE.png"
)
const OPEN_SOUND: AudioStream = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/audio/door_open.wav"
)
const CLOSE_SOUND: AudioStream = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/audio/door_close.wav"
)

@onready var _door_audio: AudioStreamPlayer = $DoorAudio

const ANIMATION_FRAME_DURATION := 0.16

var _is_open := false
var _door_animation: Tween


func _ready() -> void:
	super._ready()
	set_open(starts_open, false)


func _perform_interaction() -> void:
	set_open(not _is_open)


func set_open(value: bool, notify := true) -> void:
	var next_texture := OPEN_TEXTURE if value else CLOSED_TEXTURE
	if _is_open == value and texture == next_texture and not _is_animation_running():
		return

	_is_open = value
	_cancel_animation()
	if notify:
		_animate_to(next_texture)
	else:
		set_interaction_texture(next_texture)

	if notify:
		_door_audio.stream = OPEN_SOUND if _is_open else CLOSE_SOUND
		_door_audio.play()
		state_changed.emit(_is_open)


func is_open() -> bool:
	return _is_open


func _animate_to(next_texture: Texture2D) -> void:
	var current_frame := _frame_index_for_texture(texture)
	var target_frame := _frame_index_for_texture(next_texture)
	if current_frame == target_frame:
		return

	var direction := 1 if target_frame > current_frame else -1
	_door_animation = create_tween()
	for frame_index in range(current_frame + direction, target_frame + direction, direction):
		_door_animation.tween_interval(ANIMATION_FRAME_DURATION)
		_door_animation.tween_callback(_set_animation_frame.bind(frame_index))


func _frame_index_for_texture(frame_texture: Texture2D) -> int:
	if frame_texture == OPEN_TEXTURE:
		return 2
	if frame_texture == MIDDLE_TEXTURE:
		return 1
	return 0


func _set_animation_frame(frame_index: int) -> void:
	var frame_texture := CLOSED_TEXTURE
	if frame_index == 1:
		frame_texture = MIDDLE_TEXTURE
	elif frame_index == 2:
		frame_texture = OPEN_TEXTURE
	set_interaction_texture(frame_texture)


func _is_animation_running() -> bool:
	return is_instance_valid(_door_animation) and _door_animation.is_running()


func _cancel_animation() -> void:
	if not is_instance_valid(_door_animation):
		return
	if _door_animation.is_running():
		_door_animation.kill()
	_door_animation = null
