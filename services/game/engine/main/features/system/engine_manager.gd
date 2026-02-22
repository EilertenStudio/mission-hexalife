extends Node

func _ready():
	Log.info(self, "Setup signals")
	#get_viewport().size_changed.connect(_on_window_resized)

func _on_window_resized():
	Log.event(self, "Window resized -> (%s)" % JSON.stringify(
		{
			"window_mode": DisplayServer.window_get_mode(),
			"window_borderless": DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),
		},
		'\t', false
	))
	#SettingsManager.display_fullscreen_enabled_set(
		#DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	#)
