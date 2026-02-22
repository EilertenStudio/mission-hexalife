class_name GameMenu
extends Control

func _ready():
	GameMenuManager.register_menu(self)
	GameMenuManager.register_menu_button_events(self, _on_button_event)
	
	# TODO: learn about Control focus and navigations
	# https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html
	# https://docs.godotengine.org/en/stable/tutorials/ui/custom_gui_controls.html#so-many-controls
	#if not submenu_mode:
		#start_navigation()
		
	pass

func _on_button_event(event_name: String, event_args: Array) -> void:
	Log.event(self, "Receive button event %s: %s" % [event_name, event_args])
	
	match event_name:
		"submenu_toggled":
			_on_submenu_toggled(event_args[0], event_args[1], event_args[2])
			submenu_toggled.emit(event_args[0], event_args[1], event_args[2])
			

#region Navigation
# -----------------------------------------------------------------------------
@export var navigation_button: GameMenuButton
# -----------------------------------------------------------------------------
func start_navigation():
	navigation_button.grab_focus.call_deferred()
	pass
# -----------------------------------------------------------------------------
#endregion

#region SubMenu
# -----------------------------------------------------------------------------
@export var submenu_mode: bool = false
# -----------------------------------------------------------------------------
signal submenu_toggled(button: GameMenuButton, submenu: GameMenu, is_toggled: bool)
# -----------------------------------------------------------------------------
func _on_submenu_toggled(button: GameMenuButton, submenu: GameMenu, is_toggled: bool) -> void:
	Log.debug(self, "Detect submenu toggled [%s] for `%s` from `%s` " % [is_toggled, submenu.name, button.name.to_pascal_case()])
	if is_toggled:
		GameMenuManager.prevent_menu_input(self, [button])
	else:
		GameMenuManager.allow_menu_input(self)
	pass
# -----------------------------------------------------------------------------
#endregion

#region Button
# -----------------------------------------------------------------------------
func get_menu_buttons() -> Array[GameMenuButton]:
	var array: Array[GameMenuButton]
	array.assign(find_children("*", "GameMenuButton", true, false))
	return array
# -----------------------------------------------------------------------------
#endregion
