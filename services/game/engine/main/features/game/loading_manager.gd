class_name LoadingManager
extends Node

func _enter_tree() -> void:
	Log.event(self, "Enter Tree")

func _ready() -> void:
	Log.event(self, "Ready")

func load(closure: Callable):
	Log.info(self, "Loading resources")
#	GameManager.settings.load()

	closure.call(self)
