@abstract
class_name GameRoom
extends GameScene

@onready
var hud_menu_icon: Button = $HudContainer/Menu

func _load() -> void:
	super._load()

	hud_menu_icon.button_down.connect(_on_hud_menu_icon_clicked)

func _on_hud_menu_icon_clicked():
	Log.event(self, "Menu icon clicked")
	GameManager.scene.game_menu_toggle()
	
