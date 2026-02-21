extends GameMenu

@onready var crt_filter_check_box: GameMenuCheckBox = $ValueContainer/ItemContainer/ItemList/CrtFilter_CheckBox

func _ready():
	SettingsManager.loaded.connect(_do_setup)
	
func _do_setup():
	Log.debug(self, "Setup menu")
	crt_filter_check_box.pressed = SettingsManager.gameplay_crt_filter_enabled_get()

func _on_font_size_incremental_slider_value_changed(new_value: float) -> void:
	Log.event(self, "Font Size changed -> %s" % JSON.stringify({
		'value': new_value
	}))
	SettingsManager.gameplay_font_size_set(new_value)

func _on_ctr_filter_check_box_toggled(toggled_one: bool) -> void:
	Log.event(self, "CRT Filter changed -> %s" % JSON.stringify({
		'enabled': toggled_one
	}))
	SettingsManager.gameplay_crt_filter_enabled_set(toggled_one)
