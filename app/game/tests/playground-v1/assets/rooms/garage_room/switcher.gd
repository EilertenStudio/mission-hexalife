extends "res://tests/playground-v1/assets/rooms/garage_room/scripts/interactable_sprite.gd"

signal state_changed(is_on: bool)

const TURN_OFF_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-switcher-TURN-OFF.png"
)
const TURN_ON_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-switcher-TURN-ON.png"
)

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
		state_changed.emit(_is_on)
