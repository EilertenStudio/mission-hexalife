class_name SceneManager
extends Node

func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")

#region Layers
var game_load: Node
var game_menu: Node
var game_scene: Node

func _start_loading_screen():
	game_load.visible = true
	game_menu.visible = false
	game_scene.visible = false

func _stop_loading_screen():
	game_load.visible = false
	game_menu.visible = false
	game_scene.visible = true

#endregion

#region GameScene

func _game_scene_set(scene: Node):
	game_scene.add_child(scene)

func _game_scene_clean():
	for child in game_scene.get_children():
		game_scene.remove_child(child)

#endregion

func load(path: String, closure := func():pass):
	Log.info(self, "Load scene: %s" % path)
	_start_loading_screen()

	Log.debug(self, "Load scene resource")
	var resource := load(path)

	Log.trace(self, "   > scene resource: %s" % resource)

	if resource is not PackedScene:
		Log.error(self, "Resource of type %s not supported. Refer to a PackedScene" % typeof(resource))

	Log.debug(self, "Instance scene")
	var scene := (resource as PackedScene).instantiate()

	Log.trace(self, "       > scene: %s" % scene)

	if not scene:
		Log.error(self, "Scene not loaded!")
		return

	_game_scene_clean()
	_game_scene_set(scene)

	_stop_loading_screen()

	if closure: closure.call()
