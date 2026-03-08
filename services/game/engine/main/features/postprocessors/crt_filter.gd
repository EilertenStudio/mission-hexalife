class_name CrtFilter
extends Control

@onready var screen: MeshInstance2D = $Screen

func _enter_tree() -> void:
	Log.event(self, "Enter Tree")

func _ready() -> void:
	Log.event(self, "Ready")
	self._do_update()

	GameManager.settings.load_init.connect(_do_register)
#	GameManager.settings.load_start.connect(_do_register)
#	GameManager.settings.load_end.connect(_do_settings_fetch)

func _do_register():
	Log.event(self, "Register nodes")
	GameManager.settings.display.crt_filter_set_node(self)

#func _do_settings_fetch():
#	Log.event(self, "Settings fetch")
#
#	GameManager.settings.display.crt_filter_set(GameManager.settings.gameplay.font_size_get()
#	font_size_incremental_slider.value = GameManager.settings.gameplay.font_size_get()

func _do_update():
	Log.debug(self, "Update")
	_do_mesh_init()

func _do_mesh_init():
	Log.debug(self, "Mesh init")
	
	var viewport_size_scale := 1
	var viewport_size := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width") * viewport_size_scale,
		ProjectSettings.get_setting("display/window/size/viewport_height") * viewport_size_scale
	)
	screen.mesh.size = viewport_size
	screen.mesh.center_offset = Vector3(
		viewport_size.x / (viewport_size_scale * 2),
		viewport_size.y / (viewport_size_scale * 2),
		0
	)
