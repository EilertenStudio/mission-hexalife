class_name SceneManager
extends Object

func _init() -> void:
	Log.cycle(self, "Init")

func _load() -> void:
	Log.cycle(self, "Load")
	InputManager.escape_key_event.connect(_on_game_menu_toggle_event)
	game_menu.visibility_changed.connect(_on_game_menu_visibility_changed)

#region Layers
var game_load: CanvasItem
var game_menu: CanvasItem
var game_scene: CanvasItem

func _start_loading_screen():
	game_load.visible = true
	game_scene.visible = false
#	game_menu.visible = false

func _stop_loading_screen():
	game_load.visible = false
	game_scene.visible = true
#	game_menu.visible = false

#endregion

#region GAME_MENU

var      game_menu_toggle_lock := false
func     game_menu_toggle() -> void:
	var visible := game_menu.visible
	var toggled := !visible
	Log.event(self, "Game menu toggled -> (%s -> %s)" % [visible, toggled])
	if game_menu_toggle_lock:
		Log.warn(self, "Operation interrupted due lock function")
		return
	else:
		game_menu.visible = toggled

func _on_game_menu_toggle_event(event: InputEventKey):
	Log.event(self, "Game menu toggle event -> %s" % event)
	if event.pressed:
		game_menu_toggle()

signal    game_menu_visibility_changed(value: bool)
func  _on_game_menu_visibility_changed():
	var _vl_visible := game_menu.visible
	Log.event(self, "Game menu visibility changed -> %s" % _vl_visible)
	if not _vl_visible:
		GameManager.menu.close_all()
	game_menu_visibility_changed.emit(_vl_visible)

#endregion

#region GAME_SCENE

func _game_scene_set(scene: Node):
	game_scene.add_child(scene)

func _game_scene_clean():
	for child in game_scene.get_children():
		child.queue_free()
#		game_scene.remove_child(child)

signal game_scene_loaded()
func   game_scene_load(path: String):
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

	game_scene_loaded.emit()

#endregion
