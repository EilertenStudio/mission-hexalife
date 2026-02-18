@tool
class_name LogManager extends Node

@export var log_level := Log.Level.INFO:
	set(value):
		Log.info(self, "Set logging level to %s" % Log.Level.keys()[value])
		log_level = value
		log_level_root = value

static var log_level_root := Log.Level.INFO
