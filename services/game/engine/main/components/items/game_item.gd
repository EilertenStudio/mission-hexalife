extends Sprite2D

func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")

	_do_collision_init()
	_do_sprite_init()
	_do_outline_init()

func _process(delta: float) -> void:
	_do_outline_update(delta)

#region COLLISION

@onready
var _va_collision_domain := $Control
var _va_collision_hovering := false

func _do_collision_init():
	Log.debug(self, "Init collision")

	self._va_collision_domain.mouse_entered.connect(_on_collision_mouse_entered)
	self._va_collision_domain.mouse_exited.connect(_on_collision_mouse_exited)

func _on_collision_mouse_entered():
	Log.event(self, "Collision mouse entered")
	_va_collision_hovering = true

func _on_collision_mouse_exited():
	Log.event(self, "Collision mouse exited")
	_va_collision_hovering = false

#endregion

#region SPRITE

var _va_sprite_image : Image

func _do_sprite_init():
	Log.debug(self, "Init sprite")

	if texture:
		self._va_sprite_image = texture.get_image()

func _is_sprite_mouse_overed() -> bool:
	var _vl_mouse_pos := get_local_mouse_position()
	var _vl_image_size := Vector2(_va_sprite_image.get_size())
	var _vl_image_uv := (_vl_mouse_pos / _vl_image_size)

	var _vl_pixel_pos := Vector2(_vl_image_uv * _vl_image_size)

	return _is_sprite_pixel_opaque(_vl_pixel_pos)

func _is_sprite_pixel_opaque(pos: Vector2) -> bool:
	if pos.x < 0 || pos.y < 0 || pos.x >= _va_sprite_image.get_width() || pos.y >= _va_sprite_image.get_height():
		return false
	return _va_sprite_image.get_pixelv(pos).a > 0.0

#endregion

#region OUTLINE

var _va_outline_showed := false

func _do_outline_init():
	Log.debug(self, "Init outline")

	self.material = self.material.duplicate()

func _do_outline_update(delta: float):
	if _va_collision_hovering or _va_outline_showed:
		if _is_sprite_mouse_overed():
			_do_outline_show()
		else:
			_do_outline_hide()

func _do_outline_show():
#	Log.debug(self, "Outline show")

	if not _va_outline_showed:
		material.set_shader_parameter("width", 3.0)
		_va_outline_showed = true

func _do_outline_hide():
#	Log.debug(self, "Outline hide")

	if _va_outline_showed:
		material.set_shader_parameter("width", 0.0)
		_va_outline_showed = false

#endregion
