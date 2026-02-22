extends GameMenu

@onready var fullscreen_check_box: GameMenuCheckBox = $ValueContainer/ItemContainer/ItemList/Fullscreen_CheckBox
@onready var crt_filter_check_box: GameMenuCheckBox = $ValueContainer/ItemContainer/ItemList/CrtFilter_CheckBox

func _ready():
	super._ready()
	
	_on_fullscreen_settings_fetch()
	SettingsManager.display.fullscreen_changed.connect(_on_fullscreen_settings_fetch)
	
	_on_crt_filter_settings_fetch()
	SettingsManager.display.crt_filter_changed.connect(_on_crt_filter_settings_fetch)
	
func _on_fullscreen_settings_fetch():
	if OS.has_feature("web"):
		Log.debug(self, "Fullscreen is disabled")
		fullscreen_check_box.button.disabled = true
	else:
		Log.debug(self, "Fullscreen fetch -> (%s)" % SettingsManager.display.fullscreen_get())
		fullscreen_check_box.button.set_pressed_no_signal(SettingsManager.display.fullscreen_get())

func _on_fullscreen_check_box_toggled(enabled: bool) -> void:
	Log.event(self, "Fullscreen checkbox changed -> (%s)" % enabled)
	SettingsManager.display.fullscreen_set(enabled)

func _on_crt_filter_settings_fetch():
	Log.debug(self, "CRT Filter fetch -> (%s)" % SettingsManager.display.crt_filter_get())
	crt_filter_check_box.button.set_pressed_no_signal(SettingsManager.display.crt_filter_get())

func _on_crt_filter_check_box_toggled(enabled: bool) -> void:
	Log.event(self, "CRT Filter changed -> %s" % enabled)
	SettingsManager.display.crt_filter_set(enabled)
