extends CanvasLayer

signal return_to_title_requested

const TITLE_SCREEN_PATH := "res://scenes/title_screen/title_screen.tscn"

@onready var _resume_button: Button = $Overlay/Center/MenuPanel/Margins/Layout/ResumeButton
@onready var _options_button: Button = $Overlay/Center/MenuPanel/Margins/Layout/OptionsButton
@onready var _credits_button: Button = $Overlay/Center/MenuPanel/Margins/Layout/CreditsButton
@onready var _return_button: Button = $Overlay/Center/MenuPanel/Margins/Layout/ReturnToTitleButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_resume_game)
	_return_button.pressed.connect(_return_to_title)
	_options_button.disabled = true
	_credits_button.disabled = true
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if (
		not key_event.pressed
		or key_event.echo
		or (key_event.keycode != KEY_ESCAPE and key_event.physical_keycode != KEY_ESCAPE)
	):
		return

	if visible:
		_resume_game()
	elif _is_game_scene_active():
		_open_pause_menu()
	else:
		return
	get_viewport().set_input_as_handled()


func _is_game_scene_active() -> bool:
	var scene_flow := get_node("../../Persistent/SceneFlow")
	var active_scene_path := str(scene_flow.get("current_scene_path"))
	return not active_scene_path.is_empty() and active_scene_path != TITLE_SCREEN_PATH


func _open_pause_menu() -> void:
	visible = true
	get_tree().paused = true
	_resume_button.call_deferred("grab_focus")


func _resume_game() -> void:
	get_tree().paused = false
	visible = false


func _return_to_title() -> void:
	get_tree().paused = false
	visible = false
	return_to_title_requested.emit()
