extends Node

signal scene_changed(scene_path: String)

@onready var _world: Node = get_node("../../World")

var current_scene_path := ""


func _ready() -> void:
	if _world.get_child_count() > 0:
		current_scene_path = _world.get_child(0).scene_file_path


func change_scene(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return false

	var next_scene := packed_scene.instantiate()
	for current_scene in _world.get_children():
		_world.remove_child(current_scene)
		current_scene.queue_free()
	_world.add_child(next_scene)

	current_scene_path = scene_path
	scene_changed.emit(current_scene_path)
	return true
