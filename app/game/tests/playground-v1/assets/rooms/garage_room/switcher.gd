extends "res://tests/playground-v1/assets/rooms/garage_room/scripts/interactable_sprite.gd"

signal state_changed(is_on: bool)

const TURN_OFF_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-switcher-TURN-OFF.png"
)
const TURN_ON_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-switcher-TURN-ON.png"
)

@export var turn_on_sound: AudioStream = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/audio/light_switch_turn_on.mp3"
)
@export var turn_off_sound: AudioStream = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/audio/light_switch_turn_off.mp3"
)

@onready var _click_audio: AudioStreamPlayer = $ClickAudio

var _is_on := false


func _ready() -> void:
	super._ready()
	set_is_on(false, false)


func _perform_interaction() -> void:
	set_is_on(not _is_on)


func set_is_on(value: bool, notify := true) -> void:
	var next_texture := TURN_ON_TEXTURE if value else TURN_OFF_TEXTURE
	if _is_on == value and texture == next_texture:
		return

	_is_on = value
	set_interaction_texture(next_texture)
	if notify:
		_click_audio.stream = turn_on_sound if _is_on else turn_off_sound
		_click_audio.play()
		state_changed.emit(_is_on)


func set_turn_on_sound(sample: AudioStream) -> void:
	turn_on_sound = sample


func set_turn_off_sound(sample: AudioStream) -> void:
	turn_off_sound = sample
