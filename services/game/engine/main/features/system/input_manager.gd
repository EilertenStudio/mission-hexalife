extends Node

func _init() -> void:
	Log.event(self, "Init")

func _enter_tree() -> void:
	Log.event(self, "Enter Tree")

func _ready() -> void:
	Log.event(self, "Ready")

signal mouse_button_left_event(event: InputEventMouseButton)
signal mouse_button_right_event(event: InputEventMouseButton)

signal escape_key_event(event: InputEventKey)

func _input(event):
	Log.input(self, "Input catch -> (%s)" % event)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				mouse_button_left_event.emit(event)
			MOUSE_BUTTON_RIGHT:
				mouse_button_right_event.emit(event)
	elif event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				escape_key_event.emit(event)
