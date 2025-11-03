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
	GameSystem.log(self, "Prevent `%s` menu input" % [menu.name])
	
	for button in menu.get_menu_buttons():
		if button in ignore:
			continue
		
		GameSystem.log(button, "Disable mouse input")
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pass

func allow_menu_input(menu: GameMenu, ignore: Array[GameMenuButton] = []) -> void:
	GameSystem.log(self, "Allow `%s` menu input" % [menu.name])
	
	for button in menu.get_menu_buttons():
		if button in ignore:
			continue
		
		GameSystem.log(button, "Enable mouse input")
		button.mouse_filter = Control.MOUSE_FILTER_STOP
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
	GameSystem.log(self, "Bind `%s` to `%s`" % [submenu.name, button.name.to_pascal_case()])
	
	#GameSystem.log(button, "Enable toggle mode")
	button.toggle_mode = true
	
	#GameSystem.log(submenu, "Enable submenu mode")
	submenu.submenu_mode = true
	pass
	
func unbind_submenu_to_button(submenu: GameMenu, button: GameMenuButton) -> void:
	GameSystem.log(self, "Unbind `%s` to `%s`" % [submenu.name, button.name.to_pascal_case()])
	
	#GameSystem.log(button, "Disable toggle mode")
	button.toggle_mode = false
	
	#GameSystem.log(submenu, "Disable submenu mode")
	submenu.submenu_mode = false
# -----------------------------------------------------------------------------
func open_submenu(submenu: GameMenu) -> void:
	GameSystem.log(self, "Open submenu `%s`" % submenu.name)
	submenu.visible = true
	pass

func close_submenu(submenu: GameMenu) -> void:
	GameSystem.log(self, "Looking for nested submenu to close from `%s`" % submenu.name)
	for button in submenu.get_menu_buttons():
		if button.submenu:
			close_submenu(button.submenu)
		button.button_pressed = false
	
	GameSystem.log(self, "Close submenu `%s`" % submenu.name)
	submenu.visible = false
	
	GameSystem.log(self, "Restore submenu `%s` input" % submenu.name)
	allow_menu_input(submenu)
	pass
# -----------------------------------------------------------------------------
#endregion

#region ButtonMenu
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#endregion
