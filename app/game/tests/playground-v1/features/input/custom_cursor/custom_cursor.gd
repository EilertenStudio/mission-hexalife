extends Node

const ARROW_CURSOR: Texture2D = preload(
	"res://tests/playground-v1/features/input/custom_cursor/cursor_arrow.png"
)
const POINTING_HAND_CURSOR: Texture2D = preload(
	"res://tests/playground-v1/features/input/custom_cursor/cursor_pointing_hand.png"
)


func _ready() -> void:
	Input.set_custom_mouse_cursor(ARROW_CURSOR, Input.CURSOR_ARROW, Vector2.ZERO)
	Input.set_custom_mouse_cursor(
		POINTING_HAND_CURSOR,
		Input.CURSOR_POINTING_HAND,
		Vector2(20.0, 0.0)
	)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW, Vector2.ZERO)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND, Vector2.ZERO)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
