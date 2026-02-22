extends Node

const SETTINGS_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var gameplay := GameplaySettings.new()
var display := DisplaySettings.new()

func save():
	Log.info(self, "Save configurations -> \n%s" % config.encode_to_text())
	config.save(SETTINGS_PATH)

signal loaded()
func   load():
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		Log.error(self, "Loading configurations failed -> (ERROR_CODE: %s)" % Error.ERR_FILE_NO_PERMISSION)
		return
	else:
		Log.info(self, "Load configurations -> \n%s" % config.encode_to_text())
		
	gameplay.load()
	display.load()
		
	loaded.emit()
	
# TODO: SettingManager ready -> Component setup
# TODO: LoadingManager ready -> SettingsManager load -> Component update
# TODO: SettingManager hold data -> Option Menu Inputs send / receive updates

func feature_get(section: String, key: String, default: Variant = null) -> Variant:
	return config.get_value(section, key, default)

func feature_set(section: String, key: String, value: Variant, save := true):
	config.set_value(section, key, value)
	if save: save()
