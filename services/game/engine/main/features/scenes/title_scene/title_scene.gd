extends Control

@onready var menu_layer_background: TextureRect = $LayerContainer/MenuLayer/Background

func _on_main_menu_submenu_toggled(button: GameMenuButton, submenu: GameMenu, is_toggled: bool) -> void:
	GameSystem.log(self, "Catch submenu toggled [%s] for `%s` from `%s` " % [is_toggled, submenu.name, button.name.to_pascal_case()])
	show_menu_layer_background(is_toggled)

func show_menu_layer_background(is_toggled):
	if is_toggled:
		menu_layer_background.visible = true
	else:
		menu_layer_background.visible = false
	pass


func _on_icon_github_gui_input(event: InputEvent) -> void:
	GameSystem.log(self, "Catch GUI input `%s`" % event.get_class())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			OS.shell_open("https://github.com/EilertenStudio/mission-hexalife")
	pass


func _on_icon_itchio_gui_input(event: InputEvent) -> void:
	#GameSystem.log(self, "Catch GUI input `%s`" % event.get_class())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			OS.shell_open("https://eilertenstudio.itch.io/mission-hexalife")
	pass


func _on_icon_discord_gui_input(event: InputEvent) -> void:
	#GameSystem.log(self, "Catch GUI input `%s`" % event.get_class())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			OS.shell_open("https://discord.gg/qq2xXPNPxg")
	pass
