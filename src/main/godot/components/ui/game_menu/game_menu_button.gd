@tool

class_name GameMenuButton
extends Button


func _ready() -> void:
	if grab_focus:
		self.grab_focus.call_deferred()
	pass

#region Tool
# -----------------------------------------------------------------------------
func _on_renamed() -> void:
	update_text()
	pass
# -----------------------------------------------------------------------------
func update_text() -> void:
	self.text = name
	self.alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	else:
		GameMenuManager.unbind_submenu_to_button(current, self)
	pass
	
func toggle_submenu(value: bool) -> void:
	if value:
		GameMenuManager.open_submenu(submenu)
	else:
		GameMenuManager.close_submenu(submenu)
	
	submenu_toggled.emit(submenu, value)
	pass
# -----------------------------------------------------------------------------
signal submenu_toggled(submenu: GameMenu, is_toggled: bool)
# -----------------------------------------------------------------------------
#endregion

#region Signals
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
