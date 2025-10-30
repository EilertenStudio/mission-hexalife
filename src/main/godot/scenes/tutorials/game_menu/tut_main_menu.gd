extends Control

@onready var button_groups: VBoxContainer = $ButtonGroups
@onready var options: Panel = $Options

func _ready():
	button_groups.visible = true
	options.visible = false

func _on_start_pressed() -> void:
	print("Start pressed")
	get_tree().change_scene_to_file("res://assets/concepts/cryogenic-room.blend")


func _on_settings_pressed() -> void:
	print("Settings pressed")
	button_groups.visible = false
	options.visible = true


func _on_exit_pressed() -> void:
	print("Exit pressed")
	get_tree().quit()


func _on_options_back_pressed() -> void:
	_ready()
