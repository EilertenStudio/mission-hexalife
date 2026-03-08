class_name MainScene
extends GameScene

@export_category("Debug")
@export
var debug := false

@export_group("Level", "level_")
@export
var level_start: PackedScene

@export_group("Settings", "settings_")
@export
var settings_wipe := false

#@export_category("Features")
#@export_group("Action", "feature_action_")
#@export
#var feature_action_mouse_wheel: bool:
#	set(value):
#		feature_action_mouse_wheel = value
#		GameManager.context.action.mouse_wheel_feature = value

func _ready() -> void:
	super._ready()
	_start()

func _register() -> void:
	Log.info(self, "Register nodes")
	GameManager.scene.game_load = $%GameLoad
	GameManager.scene.game_menu = $%GameMenu
	GameManager.scene.game_scene = $%GameScene

func _load() -> void:
	Log.info(self, "Load")
	GameManager._load()

	if debug:
		Log.info(self, "Apply debug features")

		if settings_wipe:
			Log.info(self, "Wipe settings data")
			GameManager.settings.clear()
			GameManager.settings.save()
			GameManager.settings.load()

func _start() -> void:
	Log.info(self, "Start")

	if not debug:
		Log.debug(self, "Loading title screen")
		GameManager.scene.game_scene_load("res://scenes/title_screen.tscn")
	else:
		if level_start:
			Log.debug(self, "Loading custom scene: %s" % level_start)
			GameManager.scene.game_scene_load(level_start.get_path())
