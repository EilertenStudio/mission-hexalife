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
	GameSystem.log(self, "Receive button event %s: %s" % [event_name, event_args])
	
	match event_name:
		"submenu_toggled":
			_on_submenu_toggled(event_args[0], event_args[1], event_args[2])

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
func _on_submenu_toggled(_button: GameMenuButton, _submenu: GameMenu, _is_toggled: bool) -> void:
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
