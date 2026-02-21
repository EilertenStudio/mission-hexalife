@tool
class_name GameMenuIncrementalSlider
extends MarginContainer

@onready var label: Label = $V2/Value/Label
@onready var slider: HSlider = $V2/Slider/SliderCenter/HSlider:
	set(v):
		slider = v
		if v: _do_slider_update()

@export var min_value: int = 0:
	set(v):
		min_value = v
		if self.slider: _do_slider_update()
			
@export var max_value: int = 100:
	set(v):
		max_value = v
		if self.slider: _do_slider_update()
		
@export var step: int = 10:
	set(v):
		if v < 0: return
		step = v
		if self.slider: _do_slider_update()

@export var value: int = 0:
	set(v):
		if v < min_value or v > max_value: return
		value = v
		if self.slider: _do_slider_update()

signal value_changed(value: float)

func _ready():
	if self.slider: _do_slider_update()

func _on_slider_value_changed(new_value: float):
	Log.event(self, "Slider value changed -> %s" % JSON.stringify({
		'value': new_value
	}))
	_do_label_update(new_value)
	
	value_changed.emit(new_value)

func _do_label_update(to_value: float):
	Log.event(self, "Label update")
	self.label.text = str(to_value).pad_decimals(0)

func _do_slider_update():
	Log.event(self, "Slider update")
	self.slider.min_value = self.min_value
	self.slider.max_value = self.max_value
	self.slider.step = self.step
	self.slider.tick_count = round((self.max_value - self.min_value) / float(self.step)) + 1
	self.slider.value = self.value
