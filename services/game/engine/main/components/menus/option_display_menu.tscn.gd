extends GameMenu

@onready var crt_filter_check_box: GameMenuCheckBox = $ValueContainer/ItemContainer/ItemList/CrtFilter_CheckBox

func _ready():
	super._ready()
	SettingsManager.loaded.connect(_do_setup)
	
func _do_setup():
	Log.debug(self, "Setup menu")
	crt_filter_check_box.pressed = SettingsManager.gameplay_crt_filter_enabled_get()

func _on_fullscreen_check_box_toggled(enabled: bool) -> void:
	Log.event(self, "Fullscreen changed -> %s" % JSON.stringify({
		'enabled': enabled
	}))
	SettingsManager.display_fullscreen_enabled_set(enabled)

func _on_crt_filter_check_box_toggled(toggled_one: bool) -> void:
	Log.event(self, "CRT Filter changed -> %s" % JSON.stringify({
		'enabled': toggled_one
	}))
	SettingsManager.gameplay_crt_filter_enabled_set(toggled_one)
