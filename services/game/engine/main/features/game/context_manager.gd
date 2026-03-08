class_name ContextManager
extends Object

func _init() -> void:
	Log.event(self, "Init")

func _load() -> void:
	Log.event(self, "Load")
	GameManager.context.action._load()

#region ACTION
var action := Action.new()

#endregion
