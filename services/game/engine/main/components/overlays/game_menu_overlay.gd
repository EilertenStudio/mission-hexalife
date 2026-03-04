extends Control

@onready var background: TextureRect = $MenuOverlay/MenuBackground
@onready var quit: GameMenuButton = $MenuOverlay/MenuContainer/MainMenu/ItemContainer/ItemList/QUIT
@onready var main_menu_continue: GameMenuButton = $MenuOverlay/MenuContainer/MainMenu/ItemContainer/ItemList/CONTINUE

func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")

	if OS.has_feature("web"):
		quit.visible = false
	
	background.visible = false
	
	if not GameManager.state.can_continue():
		main_menu_continue.disabled = true

func _on_icon_github_gui_input(event: InputEvent) -> void:
#	Log.debug(self, "Catch GUI input `%s`" % event.get_class())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			OS.shell_open("https://github.com/EilertenStudio/mission-hexalife")
	pass

func _on_icon_itchio_gui_input(event: InputEvent) -> void:
	#Log.debug(self, "Catch GUI input `%s`" % event.get_class())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			OS.shell_open("https://eilertenstudio.itch.io/mission-hexalife")
	pass

func _on_icon_discord_gui_input(event: InputEvent) -> void:
	#Log.debug(self, "Catch GUI input `%s`" % event.get_class())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			OS.shell_open("https://discord.gg/qq2xXPNPxg")
	pass

func _on_main_menu_submenu_toggled(button: GameMenuButton, submenu: GameMenu, is_toggled: bool) -> void:
	#Log.debug(self, "Catch submenu toggled [%s] for `%s` from `%s` " % [is_toggled, submenu.name, button.name.to_pascal_case()])
	background.visible = is_toggled

func _on_main_menu_quit_pressed() -> void:
	Log.event(self, "Quit pressed")
	get_tree().quit()

func _on_main_menu_new_game_pressed() -> void:
	Log.event(self, "New Game pressed")
	GameManager.scene.load("res://components/rooms/cryogenic_room/v2/cryogenic_room_v2.tscn")
