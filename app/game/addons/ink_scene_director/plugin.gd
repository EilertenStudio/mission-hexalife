@tool
extends EditorPlugin

const DIRECTOR_SCRIPT := preload("res://addons/ink_scene_director/ink_scene_director.gd")


func _enter_tree() -> void:
	add_custom_type("InkSceneDirector", "Node", DIRECTOR_SCRIPT, null)


func _exit_tree() -> void:
	remove_custom_type("InkSceneDirector")
