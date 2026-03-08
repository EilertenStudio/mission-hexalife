class_name Action
extends Object

func _init() -> void:
	Log.event(self, "Init")
	_do_type_init()

func _load() -> void:
	Log.event(self, "Load")

signal feature_updated()
func  _feature_update():
	Log.event(self, "Update features")
	feature_updated.emit()

#region TYPE
enum Type {
	SELECT,
	INSPECT,
	PICK,
	USE
}

var type := Type.SELECT:
	set(value):
		type = value
		_do_mouse_wheel_cursor_update()

func _do_type_init() -> void:
	Log.debug(self, "Init type")

#endregion

#region MOUSE_WHEEL
var mouse_wheel_feature: bool:
	set(value):
		mouse_wheel_feature = value
		Log.debug(self, "Set mouse wheel feature -> %s" % value)
		if value:
			_on_mouse_wheel_feature_load()
#			feature_updated.connect(_on_mouse_wheel_feature_load, ConnectFlags.CONNECT_ONE_SHOT)
		else:
			_on_mouse_wheel_feature_unload()
#			feature_updated.connect(_on_mouse_wheel_feature_unload, ConnectFlags.CONNECT_ONE_SHOT)

func _on_mouse_wheel_feature_load() -> void:
	Log.event(self, "Load mouse wheel feature")
	Log.trace(self, "Connections: %s" % [InputManager.mouse_button_right_event.get_connections()])
	if !InputManager.mouse_button_right_event.is_connected(_on_mouse_wheel_change_triggered):
		InputManager.mouse_button_right_event.connect(_on_mouse_wheel_change_triggered)
	_do_mouse_wheel_cursor_update()

func _on_mouse_wheel_feature_unload() -> void:
	Log.event(self, "Unload mouse wheel feature")
	Log.trace(self, "Connections: %s" % [InputManager.mouse_button_right_event.get_connections()])
	if InputManager.mouse_button_right_event.is_connected(_on_mouse_wheel_change_triggered):
		InputManager.mouse_button_right_event.disconnect(_on_mouse_wheel_change_triggered)
	type = Type.SELECT

func _on_mouse_wheel_change_triggered(event: InputEventMouseButton):
	#Log.debug(self, "Mouse button right event -> %s" % event)
	if event.pressed:
		_do_mouse_wheel_next()

func _do_mouse_wheel_next() -> void:
	Log.debug(self, "Mouse wheel next")
	type = (type + 1) % Action.Type.size()

func _do_mouse_wheel_cursor_update() -> void:
	Log.debug(self, "Mouse wheel cursor update")
	match type:
		Type.SELECT:
			GameManager.ui.set_mouse_cursor(
				"res://features/game/contexts/action/action_cursor_icon_select.tres",
				Input.CursorShape.CURSOR_ARROW
			)
		Type.INSPECT:
			GameManager.ui.set_mouse_cursor(
				"res://features/game/contexts/action/action_cursor_icon_inspect.tres",
				Input.CursorShape.CURSOR_ARROW
			)
		Type.PICK:
			GameManager.ui.set_mouse_cursor(
				"res://features/game/contexts/action/action_cursor_icon_pick.tres",
				Input.CursorShape.CURSOR_ARROW
			)
		Type.USE:
			GameManager.ui.set_mouse_cursor(
				"res://features/game/contexts/action/action_cursor_icon_use.tres",
				Input.CursorShape.CURSOR_ARROW
			)
	
#endregion
