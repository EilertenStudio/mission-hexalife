extends Node

const TITLE_SCREEN_PATH := "res://scenes/title_screen/title_screen.tscn"
const FIRST_SCENE_PATH := "res://scenes/cryogenic_room/cryogenic_room.tscn"

@onready var _world: Node = $World
@onready var _scene_flow: Node = $Persistent/SceneFlow
@onready var _pause_menu: Node = $UI/PauseMenu


func _ready() -> void:
	_scene_flow.connect("scene_changed", _on_scene_changed)
	_pause_menu.connect("return_to_title_requested", _on_return_to_title_requested)
	_connect_title_screen_if_active()


func _on_scene_changed(_scene_path: String) -> void:
	_connect_title_screen_if_active()


func _connect_title_screen_if_active() -> void:
	if _world.get_child_count() == 0:
		return
	var active_scene := _world.get_child(0)
	if active_scene.has_signal("new_game_requested"):
		var callback := Callable(self, "_on_new_game_requested")
		if not active_scene.is_connected("new_game_requested", callback):
			active_scene.connect("new_game_requested", callback)


func _on_new_game_requested() -> void:
	_scene_flow.call("change_scene", FIRST_SCENE_PATH)


func _on_return_to_title_requested() -> void:
	get_tree().paused = false
	_scene_flow.call("change_scene", TITLE_SCREEN_PATH)
