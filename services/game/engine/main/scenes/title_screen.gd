class_name TitleScreen
extends GameScene

func _load() -> void:
	super._load()
	Log.trace(self, "Connect to scene manager events")
	GameManager.scene.game_scene_loaded.connect(_start)

	Log.trace(self, "Connect to game menu button events")
	GameManager.scene.game_menu.main_menu_continue.pressed.connect(_on_game_menu_continue_pressed)
	GameManager.scene.game_menu.main_menu_new_game.pressed.connect(_on_game_menu_new_game_pressed)
	GameManager.scene.game_menu.main_menu_quit.pressed.connect(_on_game_menu_quit_pressed)

func _start() -> void:
	super._start()

	Log.trace(self, "Setup game menu visibility and toggle")
	GameManager.scene.game_menu.visible = true
	GameManager.scene.game_menu_toggle_lock = true

	Log.trace(self, "Setup game menu buttons")
	GameManager.scene.game_menu.main_menu_continue.disabled = !GameManager.data.can_continue()
	GameManager.scene.game_menu.main_menu_new_game.disabled = false
	GameManager.scene.game_menu.main_menu_quit.visible = !OS.has_feature("web")

	Log.trace(self, "Setup game scene features")
	GameManager.context.action.mouse_wheel_feature = false

func _on_game_menu_continue_pressed():
	Log.event(self, "Game menu continue pressed")
	Log.fatal(self, "Not implemented yet")

func _on_game_menu_new_game_pressed():
	Log.event(self, "Game menu new game pressed")
	GameManager.scene.game_scene_load("res://components/rooms/cryogenic_room/v2/cryogenic_room_v2.tscn")
#	GameManager.scene.game_scene_load("res://components/rooms/game_room.tscn")

func _on_game_menu_quit_pressed():
	Log.event(self, "Game menu quit pressed")
	get_tree().quit()
