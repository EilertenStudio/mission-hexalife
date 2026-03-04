extends Control

@onready var game_menu_overlay: Control = $GameMenuOverlay

func _ready():
	Log.event(self, "Ready")
