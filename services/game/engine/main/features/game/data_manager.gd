class_name DataManager
extends Object

func _init() -> void:
	Log.event(self, "Init")

func save():
	Log.info(self, "Save game -> \n%s" % config.encode_to_text())
	config.save(CONFIG_PATH)

func load():
	var error := config.load(CONFIG_PATH)
	if error != OK:
		Log.error(self, "Load game -> (ERROR_CODE: %s)" % error)
	else:
		Log.info(self, "Load game -> \n%s" % config.encode_to_text())

func can_continue() -> bool:
	return false

#region _config

const CONFIG_PATH := "user://saves.cfg"
var config := ConfigFile.new()

#endregion

#region _slot

func _slot_get(index: int) -> Dictionary:
	return self.config.get("slot_%s" % index)

func _slot_set(index: int, slot: Dictionary):
	self.config.set("slot_%s" % index, slot)

#endregion
