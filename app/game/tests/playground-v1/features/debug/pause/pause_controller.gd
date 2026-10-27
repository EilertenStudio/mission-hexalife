extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and (event.keycode == KEY_F5 or event.physical_keycode == KEY_F5)
	):
		get_tree().paused = not get_tree().paused
		get_viewport().set_input_as_handled()
