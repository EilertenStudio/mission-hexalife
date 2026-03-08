@tool
class_name ProjectVersionManager
extends Label

func _ready():
	text = "v"+ProjectSettings.get_setting("application/config/version")
