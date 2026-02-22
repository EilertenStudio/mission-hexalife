@tool
class_name GameMenuCheckBox
extends MarginContainer

@onready var button: Button = $Button

@export 
var pressed := false:
	set(value):
		pressed = value
		self._do_button_update()

func _ready() -> void:
	button.toggled.connect(_on_button_toggled)

signal toggled(toggled_one: bool)

func _on_button_toggled(toggled_on: bool) -> void:
	Log.event(self, "Button toggled -> %s" % JSON.stringify(
		{
			'toggled_on': toggled_on
		}
	))
	self.toggled.emit(toggled_on)

func _do_button_update():
	if not self.button: return
	self.button.button_pressed = pressed
