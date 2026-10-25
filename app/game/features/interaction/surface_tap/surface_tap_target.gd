extends Sprite2D
class_name SurfaceTapTarget

signal tapped(target: SurfaceTapTarget)

@export var target_name := ""
@export_multiline var examine_description := ""
@export_enum("Glass", "Metal", "Wood", "Plaster") var surface_material := "Metal"
@export var tap_sound: AudioStream

@onready var _sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _pixel_image: Image
var _cached_texture: Texture2D
var _hovered := false
var _flash_time := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cache_texture_pixels()
	if tap_sound:
		_sound.stream = tap_sound


func _process(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		_update_tint()


func set_hovered(is_hovered: bool) -> void:
	_hovered = is_hovered
	_update_tint()


func contains_opaque_pixel_at_screen_position(screen_position: Vector2) -> bool:
	if not is_visible_in_tree() or modulate.a <= 0.0 or texture == null:
		return false
	if texture != _cached_texture:
		_cache_texture_pixels()
	if _pixel_image == null:
		return false

	var source_rect := Rect2(Vector2.ZERO, texture.get_size())
	if region_enabled:
		source_rect = region_rect
	var local_position := get_global_transform_with_canvas().affine_inverse() * screen_position
	var drawn_origin := offset
	if centered:
		drawn_origin -= source_rect.size * 0.5
	var point_in_region := local_position - drawn_origin
	if (
		point_in_region.x < 0.0
		or point_in_region.y < 0.0
		or point_in_region.x >= source_rect.size.x
		or point_in_region.y >= source_rect.size.y
	):
		return false

	var pixel := Vector2i(floori(point_in_region.x), floori(point_in_region.y))
	if flip_h:
		pixel.x = floori(source_rect.size.x) - 1 - pixel.x
	if flip_v:
		pixel.y = floori(source_rect.size.y) - 1 - pixel.y
	pixel += Vector2i(source_rect.position)
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= _pixel_image.get_width() or pixel.y >= _pixel_image.get_height():
		return false

	return _pixel_image.get_pixelv(pixel).a > 0.0


func activate() -> void:
	if tap_sound:
		_sound.play()
	_flash_time = 0.22
	_update_tint()
	tapped.emit(self)


func _cache_texture_pixels() -> void:
	_cached_texture = texture
	_pixel_image = texture.get_image() if texture else null


func _update_tint() -> void:
	if _hovered or _flash_time > 0.0:
		var intensity := 1.2 if _hovered else 1.0 + (_flash_time / 0.22) * 0.2
		modulate = Color(intensity, intensity, intensity * 0.92, 1.0)
	else:
		modulate = Color.WHITE
