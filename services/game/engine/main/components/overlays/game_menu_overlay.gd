extends Control

@onready var background: TextureRect = $MenuOverlay/MenuBackground
@onready var quit: GameMenuButton = $MenuOverlay/MenuContainer/MainMenu/ItemContainer/ItemList/QUIT
@onready var main_menu_continue: GameMenuButton = $MenuOverlay/MenuContainer/MainMenu/ItemContainer/ItemList/CONTINUE
@onready var main_menu_new_game: GameMenuButton = $MenuOverlay/MenuContainer/MainMenu/ItemContainer/ItemList/NEW_GAME
@onready var main_menu_quit: GameMenuButton = $MenuOverlay/MenuContainer/MainMenu/ItemContainer/ItemList/QUIT

func _enter_tree() -> void:
	Log.cycle(self, "Enter Tree")

func _ready() -> void:
	Log.cycle(self, "Ready")
	
	background.visible = false

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
