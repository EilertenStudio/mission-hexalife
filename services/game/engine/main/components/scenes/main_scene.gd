extends Control


func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")
	_do_register()
	_do_load()
	_do_start()

func _do_register():
	Log.info(self, "Register nodes")
	GameManager.scene.game_load = $%GameLoad
	GameManager.scene.game_menu = $%GameMenu
	GameManager.scene.game_scene = $%GameScene

func _do_load():
	Log.info(self, "Load resources")
	GameManager.settings.load()

func _do_start():
	Log.info(self, "Start")

	if not GameManager.state.can_continue():
		GameManager.scene.load("res://components/scenes/title_screen.tscn", _on_title_screen_loaded)

func _on_title_screen_loaded():
	Log.event(self, "Title Screen loaded")
	GameManager.menu.visible(true)
