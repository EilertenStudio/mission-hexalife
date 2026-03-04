extends Node

func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")
	Log.debug(self, "Setup signals")
	#get_viewport().size_changed.connect(_on_window_resized)

func _on_window_resized():
	Log.event(self, "Window resized -> (%s)" % JSON.stringify(
		{
			"window_mode": DisplayServer.window_get_mode(),
			"window_borderless": DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),
		},
		'\t', false
	))
	#GameManager.settings.display_fullscreen_enabled_set(
		#DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	#)
