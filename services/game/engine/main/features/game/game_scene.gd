@abstract
class_name GameScene
extends CanvasItem

func _init() -> void:
	Log.cycle(self, "Init")

func _enter_tree() -> void:
	Log.cycle(self, "Enter Tree")

func _exit_tree() -> void:
	Log.cycle(self, "Exit Tree")
#	_stop()
	_unload()
	_unregister()

func _ready() -> void:
	Log.cycle(self, "Ready")
	_register()
	_load()
#	_start()

func _destory() -> void:
	Log.cycle(self, "Destroy")
#	_stop()
	_unload()
	_unregister()

func _register() -> void:
	Log.cycle(self, "Register")

func _unregister() -> void:
	Log.cycle(self, "Register")

func _load() -> void:
	Log.cycle(self, "Load")

func _unload() -> void:
	Log.cycle(self, "Load")

func _start() -> void:
	Log.cycle(self, "Start")

func _stop() -> void:
	Log.cycle(self, "Stop")