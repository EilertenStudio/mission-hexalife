class_name Log extends Object

enum Level {
	ERROR,
	WARN,
	INFO,
	DEBUG,
	EVENT,
	TRACE,
}

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
	if (level > LogManager.log_level_root) and (handler is not LogManager):
		return
	
	var category := "Unknown"
	
	if typeof(handler) == TYPE_STRING:
		category = handler
	elif handler is Node:
		category = handler.name
	elif handler is Object:
		if handler.get_script() and handler.get_script().get_global_name() != &"":
			category = handler.get_script().get_global_name()
		else:
			category = handler.get_class()

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
			color = "#32c1ed"
		Level.DEBUG:
			color = "#7ab32b"
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
