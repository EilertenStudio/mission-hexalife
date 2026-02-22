extends GameMenu

@onready var font_size_incremental_slider: GameMenuIncrementalSlider = $VBoxContainer/FieldContainers/ValueContainer/ItemContainer/ItemList/FontSize_IncrementalSlider

func _ready():
	super._ready()
	SettingsManager.loaded.connect(_do_settings_fetch)
	
func _do_settings_fetch():
	Log.info(self, "Settings fetch")
	
	font_size_incremental_slider.value = SettingsManager.gameplay.font_size_get()

func _on_font_size_incremental_slider_value_changed(value: float) -> void:
	Log.event(self, "Font Size changed -> %s" % value)
	SettingsManager.gameplay.font_size_set(value)
