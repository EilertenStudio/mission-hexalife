@tool

class_name GameMenuButton
extends Button


func _ready() -> void:
	#if grab_focus:
		#self.grab_focus.call_deferred()
	pass

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			update_from_theme()
	pass

#region Property
# -----------------------------------------------------------------------------
func update_text() -> void:
	GameSystem.log(self, "Update text")
	self.text = name
	#self.alignment = HORIZONTAL_ALIGNMENT_LEFT
	pass
func update_from_theme() -> void:
	GameSystem.log(self, "Update from theme")
	self.custom_minimum_size = Vector2(
		get_theme_constant("minimum_size_x"),
		get_theme_constant("minimum_size_y")
	)
	pass
# -----------------------------------------------------------------------------
#endregion

#region SubMenu
# -----------------------------------------------------------------------------
@export var submenu: GameMenu:
	set(value):
		update_submenu(submenu, value)
		submenu = value
		pass
# -----------------------------------------------------------------------------
func update_submenu(current: GameMenu, next: GameMenu) -> void:
	if next:
		GameMenuManager.bind_submenu_to_button(next, self)
	elif current:
		GameMenuManager.unbind_submenu_to_button(current, self)
	pass
	
func toggle_submenu(value: bool) -> void:
	if value:
		GameMenuManager.open_submenu(self, submenu)
	else:
		GameMenuManager.close_submenu(self, submenu)
	
	submenu_toggled.emit(submenu, value)
	pass
# -----------------------------------------------------------------------------
signal submenu_toggled(submenu: GameMenu, is_toggled: bool)
# -----------------------------------------------------------------------------
#endregion

#region Signals
# -----------------------------------------------------------------------------
func _on_renamed() -> void:
	update_text()
	pass
# -----------------------------------------------------------------------------
func _on_pressed() -> void:
	#GameSystem.log(self, "Get PRESSED event")
	pass
	
func _on_button_up() -> void:
	#GameSystem.log(self, "Get BUTTON_UP event")
	pass
	
func _on_button_down() -> void:
	#GameSystem.log(self, "Get BUTTON_DOWN event")
	pass
	
func _on_toggled(value: bool) -> void:
	#GameSystem.log(self, "Get TOGGLED event [%s]" % value)
	toggle_submenu(value)
	pass
# -----------------------------------------------------------------------------
#endregion
