class_name SceneMain
extends Control

@onready var version: Label = $Version

func _ready():
	version.text = "v"+ProjectSettings.get_setting("application/config/version")
	pass

	#title_menu.connect(
		#"options_menu_visibility_changed",
		#func(visible):
			#options_menu.visible = visible
	#)

#func _on_title_menu_change_options_menu_visible(is_visible: bool) -> void:
	#options_menu.visible = true
