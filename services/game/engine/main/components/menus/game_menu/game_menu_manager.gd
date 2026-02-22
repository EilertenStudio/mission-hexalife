@tool
extends Node

var navigator_stack: Array[GameMenu]

#var menu_tree: Dictionary[GameMenu]
#var registered_submenu: Array[GameMenu]

#region Menu
# -----------------------------------------------------------------------------
func register_menu(menu: GameMenu) -> void:
	GameSystem.log(self, "Register `%s` menu" % menu.name)
	if menu.submenu_mode:
		register_submenu(menu)
	pass
# -----------------------------------------------------------------------------
func register_menu_button_events(menu: GameMenu, closure: Callable) -> void:
	GameSystem.log(self, "Register `%s` menu button events" % menu.name)
	
	for button in menu.get_menu_buttons():
		GameSystem.log(menu, "Connect signals from `%s`" % button.name.to_pascal_case())
		
		button.connect("submenu_toggled", func(submenu, is_toggled):
			closure.call("submenu_toggled", [button, submenu, is_toggled])
		)
	
	pass
# -----------------------------------------------------------------------------
func prevent_menu_input(menu: GameMenu, ignore: Array[GameMenuButton] = []) -> void:
	Log.debug(self, "Prevent menu input for `%s`" % [menu.name])
	
	for button in menu.get_menu_buttons():
		if button in ignore:
			continue
		
		Log.trace(self, "Disable mouse input for `%s`" % button.name)
		#button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		#button.focus_mode = Control.FOCUS_NONE
		button.disabled = true
	pass

func allow_menu_input(menu: GameMenu, ignore: Array[GameMenuButton] = []) -> void:
	Log.debug(self, "Allow menu input for `%s`" % [menu.name])
	
	for button in menu.get_menu_buttons():
		if button in ignore:
			continue
		
		Log.trace(self, "Enable mouse input for `%s`" % button.name)
		#button.mouse_filter = Control.MOUSE_FILTER_STOP
		#button.focus_mode = Control.FOCUS_ALL
		button.disabled = false
	pass
# -----------------------------------------------------------------------------
#endregion

#region SubMenu
# -----------------------------------------------------------------------------
func register_submenu(submenu: GameMenu) -> void:
	#GameSystem.log(submenu, "Force hiding as submenu")
	submenu.visible = false
	pass
# -----------------------------------------------------------------------------
func bind_submenu_to_button(submenu: GameMenu, button: GameMenuButton) -> void:
	Log.debug(self, "Bind `%s` to `%s`" % [submenu.name, button.name.to_pascal_case()])
	
	#GameSystem.log(button, "Enable toggle mode")
	button.toggle_mode = true
	
	#GameSystem.log(submenu, "Enable submenu mode")
	submenu.submenu_mode = true
	pass
	
func unbind_submenu_to_button(submenu: GameMenu, button: GameMenuButton) -> void:
	Log.debug(self, "Unbind `%s` to `%s`" % [submenu.name, button.name.to_pascal_case()])
	
	#GameSystem.log(button, "Disable toggle mode")
	button.toggle_mode = false
	
	#GameSystem.log(submenu, "Disable submenu mode")
	submenu.submenu_mode = false
# -----------------------------------------------------------------------------
func open_submenu(button: GameMenuButton, submenu: GameMenu) -> void:
	Log.debug(self, "Update button theme for `%s`" % button.name)
	var menu_showed_stylebox = button.get_theme_stylebox("menu_showed")
	button.add_theme_stylebox_override("pressed", menu_showed_stylebox)
	
	Log.debug(self, "Open submenu `%s`" % submenu.name)
	submenu.visible = true
	pass

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
	
	pass
# -----------------------------------------------------------------------------
#endregion

#region ButtonMenu
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#endregion
