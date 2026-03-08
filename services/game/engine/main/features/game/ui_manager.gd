class_name UIManager
extends Object

func _init() -> void:
	Log.event(self, "Init")

func load() -> void:
	Log.event(self, "Load")
	_do_mouse_load()

#region MOUSE

func _do_mouse_load():
	Log.debug(self, "Load mouse")
	#_do_mouse_cursor_set(
		#"res://features/game/contexts/action_cursor_icon_select.tres",
		#Input.CursorShape.CURSOR_ARROW
	#)
	#_do_mouse_cursor_set(
		#"res://features/game/contexts/action_cursor_icon_inspect.tres",
		#Input.CursorShape.CURSOR_HELP
	#)
	#_do_mouse_cursor_set(
		#"res://features/game/contexts/action_cursor_icon_pick.tres",
		#Input.CursorShape.CURSOR_DRAG
	#)
	#_do_mouse_cursor_set(
		#"res://features/game/contexts/action_cursor_icon_use.tres",
		#Input.CursorShape.CURSOR_IBEAM
	#)

func set_mouse_cursor(path: String, cursor_type: Input.CursorShape):
	Log.debug(self, "Set mouse cursor -> %s at %s" % [path, cursor_type])
	var _vl_cursor_icon = load(path)
	Input.set_custom_mouse_cursor(_vl_cursor_icon, cursor_type)

#endregion
