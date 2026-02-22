class_name Log extends Object

enum Level {
	ERROR,
	WARN,
	INFO,
	DEBUG,
	EVENT,
	TRACE,
}

static var log_level_root := Level.TRACE:
	set(value):
		Log.info(Log, "Set logging level to %s" % Log.Level.keys()[value])
		log_level_root = value

static var log_level_map := {}

static func log_level_category_get(handler: Variant):
	var category := ""
	
	if typeof(handler) == TYPE_STRING:
		category = handler
	elif handler is Node:
		category = handler.name
	
	if category.is_empty():
		if handler.get_script() and handler.get_script().get_global_name() != &"":
			category = handler.get_script().get_global_name()
		else:
			category = handler.get_class()
	
	if category.is_empty():
		category = "Unknown"
	
	return category

static func log_level_set(handler: Variant, level: Level):
	log_level_map.set(handler, level)

static func error(handler: Variant, message: String):
	_log(Level.ERROR, handler, message)

static func warn(handler: Variant, message: String):
	_log(Level.WARN, handler, message)
static func info(handler: Variant, message: String):
	_log(Level.INFO, handler, message)

static func debug(handler: Variant, message: String):
	_log(Level.DEBUG, handler, message)

static func event(handler: Variant, message: String):
	_log(Level.EVENT, handler, message)

static func trace(handler: Variant, message: String):
	_log(Level.TRACE, handler, message)

static func _log(level: Level, handler: Variant, message: String):
	if log_level_root and (level > log_level_root):# and (handler is not log_level_map):
		return

	var category = log_level_category_get(handler)
	var category_level = log_level_map.get(handler, log_level_root)
	
	if level > category_level:
		return

	var time = Time.get_time_string_from_system()
	var level_name = Level.keys()[level]
	var formatted_msg = "[%s] %-5s [%s] %s" % [time, level_name, category, message]
	
	var color
	match level:
		Level.ERROR:
			color = "#ed4532"
		Level.WARN:
			color = "#edd132"
		Level.INFO:
			color = "#7ab32b"
		Level.DEBUG:
			color = "#32c1ed"
		Level.EVENT:
			color = "#e68e37"
		Level.TRACE:
			color = "#8080f9"
	
	match level:
		#Level.ERROR:
			#printerr(formatted_msg)
		#Level.INFO:
			#print(formatted_msg)
		_:
			print_rich("[color=%s]%s[/color]" % [color, formatted_msg])
