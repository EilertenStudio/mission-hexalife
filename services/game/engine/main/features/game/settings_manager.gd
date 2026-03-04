class_name SettingsManager
extends Node

func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")

const CONFIG_PATH := "user://settings.cfg"
var config := ConfigFile.new()

var gameplay := GameplaySettings.new()
var display := DisplaySettings.new()

func save():
	Log.trace(self, "Save configurations -> \n%s" % config.encode_to_text())
	config.save(CONFIG_PATH)

signal load_init()
signal load_start()
signal load_end()
func   load():
	load_init.emit()

	var error := config.load(CONFIG_PATH)

	if error != OK:
		Log.error(self, "Loading configurations failed -> (ERROR_CODE: %s)" % Error.ERR_FILE_NO_PERMISSION)
		return
	else:
		Log.trace(self, "Load configurations -> \n%s" % config.encode_to_text())

	load_start.emit()
		
	gameplay.load()
	display.load()
		
	load_end.emit()
	
func feature_get(section: String, key: String, default: Variant = null) -> Variant:
	return config.get_value(section, key, default)

func feature_set(section: String, key: String, value: Variant, save := true):
	config.set_value(section, key, value)
	if save: save()
