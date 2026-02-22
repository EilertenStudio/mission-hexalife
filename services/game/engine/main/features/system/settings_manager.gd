extends Node

static var gameplay := {}
static var gameplay_theme: Theme = preload("res://features/gameplay/gameplay_theme.tres")

static var display := {}

signal loaded()
func   load():
	Log.info(self, "Loading configurations")
	# TODO: load from file
	gameplay_crt_filter_enabled_set(true)
	
	loaded.emit()


# TODO: SettingManager ready -> Component setup
# TODO: LoadingManager ready -> SettingsManager load -> Component update
# TODO: SettingManager hold data -> Option Menu Inputs send / receive updates

#region Gameplay_FontSize
static func gameplay_font_size_set(value: int):
	Log.info(SettingsManager, "Gameplay Font Size changed -> %s" % JSON.stringify(
		{
			'font_size': value
		}
	))
	var theme = gameplay_theme
	
	theme.set_font_size("font_size", "Label", value)
#endregion

#region Display_Fullscreen
func display_fullscreen_enabled_get() -> bool:
	return gameplay.get_or_add("fullscreen", false)
	
func display_fullscreen_enabled_set(enabled: bool):
	gameplay.set("fullscreen", enabled)
	
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
#endregion

#region Gameplay_CrtFilter
static func gameplay_crt_filter_node_has() -> bool:
	return gameplay.has("crt_filter_node")

static func gameplay_crt_filter_node_get() -> CrtFilter:
	return gameplay.get("crt_filter_node", null)

static func gameplay_crt_filter_node_set(node: CrtFilter):
	Log.info(SettingsManager, "Gameplay CRT Filter [Node] changed -> (%s)" % node)
	gameplay.set("crt_filter_node", node)

static func gameplay_crt_filter_enabled_has() -> bool:
	return gameplay.has("crt_filter_enabled")

static func gameplay_crt_filter_enabled_get() -> bool:
	return gameplay.get("crt_filter_enabled", false)

static func gameplay_crt_filter_enabled_set(value: bool):
	Log.info(SettingsManager, "Gameplay CRT Filter [Enabled] changed -> (%s)" % value)
	gameplay.set("crt_filter_enabled", value)
	if gameplay_crt_filter_node_has():
		gameplay_crt_filter_node_get().visible = value

#endregion
