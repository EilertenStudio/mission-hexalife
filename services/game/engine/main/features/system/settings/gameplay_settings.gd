class_name GameplaySettings
extends Node

var theme: Theme = preload("res://features/system/settings/gameplay_theme.tres")

func load():
	font_size_set(font_size_get(), false)

#region font_size
func font_size_get() -> int:
	return SettingsManager.feature_get(name.to_snake_case(), "font_size", 20)
	
func font_size_set(value: int, save := true):
	Log.debug(self, "Font Size changed -> (%s)" % value)
	SettingsManager.feature_set(name.to_snake_case(), "font_size", value, save)
	
	theme.set_font_size("font_size", "Label", value)
#endregion
