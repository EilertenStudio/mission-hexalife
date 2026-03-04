extends GameMenu

#region SubMenu
# -----------------------------------------------------------------------------
func _on_submenu_toggled(button: GameMenuButton, submenu: GameMenu, is_toggled: bool) -> void:
	GameSystem.log(self, "Detect submenu toggled [%s] for `%s` from `%s` " % [is_toggled, submenu.name, button.name.to_pascal_case()])
	if is_toggled:
		GameManager.menu.prevent_menu_input(self, [button])
		# TODO: use ButtonGroup to auto untoggle other buttons
	else:
		GameManager.menu.allow_menu_input(self)
	pass
# -----------------------------------------------------------------------------
#endregion
