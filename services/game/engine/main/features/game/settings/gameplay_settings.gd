class_name GameplaySettings
extends Object

func _init() -> void:
	Log.event(self, "Init %s" % get_script().get_global_name())

const FEATURE_ID := "gameplay"

var theme: Theme = preload("res://features/game/settings/gameplay_theme.tres")

func load():
	Log.event(self, "Load settings gameplay")
	font_size_set(font_size_get(), false)

#region font_size
func font_size_get() -> int:
	return GameManager.settings.feature_get(FEATURE_ID, "font_size", 20)
	
func font_size_set(value: int, save := true):
	Log.debug(self, "Font Size changed -> (%s)" % value)
	GameManager.settings.feature_set(FEATURE_ID, "font_size", value, save)
	
	theme.set_font_size("font_size", "Label", value)
#endregion
