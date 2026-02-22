@tool
class_name CrtFilter
extends Control

@onready var screen: MeshInstance2D = $Screen

@export_tool_button("Update") var update = _do_update

func _ready() -> void:
	SettingsManager.ready.emit(_do_register())
	self._do_update()

func _do_register():
	Log.debug(self, "SettingManager ready")
	SettingsManager.display.crt_filter_set_node(self)

func _do_update():
	_do_mesh_init()

func _do_mesh_init():
	Log.event(self, "Update mesh")
	
	var viewport_size_scale = 1
	var viewport_size = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width") * viewport_size_scale,
		ProjectSettings.get_setting("display/window/size/viewport_height") * viewport_size_scale
	)
	screen.mesh.size = viewport_size
	screen.mesh.center_offset = Vector3(
		viewport_size.x / (viewport_size_scale * 2),
		viewport_size.y / (viewport_size_scale * 2),
		0
	)
