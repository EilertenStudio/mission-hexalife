extends Sprite2D

signal state_changed(is_on: bool)

const TURN_OFF_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-switcher-TURN-OFF.png"
)
const TURN_ON_TEXTURE: Texture2D = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/exports/garage_room-v006-switcher-TURN-ON.png"
)

var _is_on := false
var _hit_mask: Image


func _ready() -> void:
	_hit_mask = TURN_OFF_TEXTURE.get_image()
	set_is_on(false, false)


func _process(_delta: float) -> void:
	var hovering := _contains_opaque_pixel(get_global_mouse_position())
	Input.set_default_cursor_shape(
		Input.CURSOR_POINTING_HAND if hovering else Input.CURSOR_ARROW
	)


func _input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and _contains_opaque_pixel(get_global_mouse_position())
	):
		set_is_on(not _is_on)
		get_viewport().set_input_as_handled()


func set_is_on(value: bool, notify := true) -> void:
	if _is_on == value:
		texture = TURN_ON_TEXTURE if _is_on else TURN_OFF_TEXTURE
		return

	_is_on = value
	texture = TURN_ON_TEXTURE if _is_on else TURN_OFF_TEXTURE
	if notify:
		state_changed.emit(_is_on)


func _contains_opaque_pixel(global_position: Vector2) -> bool:
	if _hit_mask == null or _hit_mask.is_empty():
		return false

	var texture_position := (
		to_local(global_position) + Vector2(_hit_mask.get_size()) * 0.5
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


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
