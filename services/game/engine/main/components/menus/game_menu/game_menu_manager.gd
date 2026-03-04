@tool
class_name GameMenuManager
extends Node

var navigator_stack: Array[GameMenu]

func _init() -> void:
	Log.log_level_set(self, Log.Level.INFO)

func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")

#region Menu

func register_menu(menu: GameMenu) -> void:
	Log.debug(self, "Register `%s` menu" % menu.name)
	if menu.submenu_mode:
		register_submenu(menu)

func register_menu_button_events(menu: GameMenu, closure: Callable) -> void:
	Log.debug(self, "Register `%s` menu button events" % menu.name)
	
	for button in menu.get_menu_buttons():
		Log.debug(self, "[%s] Connect signals from `%s`" % [menu.name, button.name.to_pascal_case()])
		
		button.connect("submenu_toggled", func(submenu, is_toggled):
			closure.call("submenu_toggled", [button, submenu, is_toggled])
		)

func prevent_menu_input(menu: GameMenu, ignore: Array[GameMenuButton] = []) -> void:
	Log.debug(self, "Prevent menu input for `%s`" % [menu.name])
	
	for button in menu.get_menu_buttons():
		if button in ignore:
			continue
		
		Log.trace(self, "Disable mouse input for `%s`" % button.name)
		#button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		#button.focus_mode = Control.FOCUS_NONE
		button.disabled = true

func allow_menu_input(menu: GameMenu, ignore: Array[GameMenuButton] = []) -> void:
	Log.debug(self, "Allow menu input for `%s`" % [menu.name])
	
	for button in menu.get_menu_buttons():
		if button in ignore:
			continue
		
		Log.trace(self, "Enable mouse input for `%s`" % button.name)
		#button.mouse_filter = Control.MOUSE_FILTER_STOP
		#button.focus_mode = Control.FOCUS_ALL
		button.disabled = false

#endregion

#region SubMenu

func register_submenu(submenu: GameMenu) -> void:
	Log.debug(self, "[%s] Force hiding as submenu" % submenu.name)
	submenu.visible = false

func bind_submenu_to_button(submenu: GameMenu, button: GameMenuButton) -> void:
	Log.debug(self, "Bind `%s` to `%s`" % [submenu.name, button.name.to_pascal_case()])
	
	Log.trace(self, "[%s] Enable toggle mode" % button)
	button.toggle_mode = true
	
	Log.trace(self, "[%s] Enable submenu mode" % submenu)
	submenu.submenu_mode = true
	
func unbind_submenu_to_button(submenu: GameMenu, button: GameMenuButton) -> void:
	Log.debug(self, "Unbind `%s` to `%s`" % [submenu.name, button.name.to_pascal_case()])
	
	Log.debug(self, "[%s] Disable toggle mode" % button)
	button.toggle_mode = false
	
	Log.debug(self, "[%s] Disable submenu mode" % submenu)
	submenu.submenu_mode = false

func open_submenu(button: GameMenuButton, submenu: GameMenu) -> void:
	Log.debug(self, "Update button theme for `%s`" % button.name)
	var menu_showed_stylebox = button.get_theme_stylebox("menu_showed")
	button.add_theme_stylebox_override("pressed", menu_showed_stylebox)
	
	Log.debug(self, "Open submenu `%s`" % submenu.name)
	submenu.visible = true

func close_submenu(button: GameMenuButton, submenu: GameMenu) -> void:
	Log.debug(self, "Update button theme for `%s`" % button.name)
	button.remove_theme_stylebox_override("pressed")
	
	Log.debug(self, "Looking for nested submenu to close from `%s`" % submenu.name)
	for sub_button in submenu.get_menu_buttons():
		if sub_button.submenu:
			close_submenu(sub_button, sub_button.submenu)
		sub_button.button_pressed = false
	
	Log.debug(self, "Close submenu `%s`" % submenu.name)
	submenu.visible = false

#endregion

func visible(value : bool):
	GameManager.scene.game_menu.visible = value