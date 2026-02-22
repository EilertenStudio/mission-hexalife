class_name DisplaySettings
extends Node

func load():
	fullscreen_set(fullscreen_get(), false, true)
	crt_filter_set(crt_filter_get(), false, true)

#region fullscreen
signal fullscreen_changed(enabled: bool)

func fullscreen_get() -> bool:
	return SettingsManager.feature_get(name.to_snake_case(), "fullscreen", false)
	
func fullscreen_set(enabled: bool, save := true, emit := true):
	Log.debug(self, "Fullscreen changed -> (%s)" % enabled)
	SettingsManager.feature_set(name.to_snake_case(), "fullscreen", enabled, save)
	
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	
	if emit:
		fullscreen_changed.emit(enabled)
	
#endregion

#region crt_filter
signal crt_filter_changed(enabled: bool)

func crt_filter_get() -> bool:
	return SettingsManager.feature_get(name.to_snake_case(), "crt_filter", true)

func crt_filter_set(enabled: bool, save := true, emit := true):
	Log.debug(self, "CRT Filter changed -> (%s)" % enabled)
	SettingsManager.feature_set(name.to_snake_case(), "crt_filter", enabled, save)
	
	if crt_filter_get_node():
		crt_filter_get_node().visible = enabled
	
	if emit:
		#Log.trace(self, "%s" % crt_filter_changed.get_connections())
		crt_filter_changed.emit()
	
#endregion

#region crt_filter__node
var crt_filter__node: Node

func crt_filter_get_node() -> CrtFilter:
	return crt_filter__node

func crt_filter_set_node(node: CrtFilter):
	Log.debug(self, "CRT Filter [Node] changed -> (%s)" % node)
	crt_filter__node = node
	
	crt_filter_set(crt_filter__node.visible, false)
#endregion
