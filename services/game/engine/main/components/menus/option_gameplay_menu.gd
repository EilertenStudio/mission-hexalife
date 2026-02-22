extends GameMenu

func _ready():
	super._ready()
	SettingsManager.loaded.connect(_do_setup)
	
func _do_setup():
	Log.debug(self, "Setup menu")

func _on_font_size_incremental_slider_value_changed(new_value: float) -> void:
	Log.event(self, "Font Size changed -> %s" % JSON.stringify({
		'value': new_value
	}))
	SettingsManager.gameplay_font_size_set(new_value)
