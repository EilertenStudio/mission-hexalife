extends Sprite2D

const GROUP_NAME := "garage_interactable"

var _interaction_mask: Image
var _interaction_highlight_texture: Texture2D


func _ready() -> void:
	add_to_group(GROUP_NAME)
	set_interaction_texture(texture)


func set_interaction_texture(value: Texture2D) -> void:
	texture = value
	_interaction_mask = value.get_image() if value != null else null
	_interaction_highlight_texture = _make_highlight_texture(_interaction_mask)


func get_interaction_pixel_color_at(world_point: Vector2) -> Color:
	if not is_visible_in_tree() or _interaction_mask == null or _interaction_mask.is_empty():
		return Color.TRANSPARENT
	if self_modulate.a <= 0.0:
		return Color.TRANSPARENT
	var canvas_item: CanvasItem = self
	while canvas_item != null:
		if canvas_item.modulate.a <= 0.0:
			return Color.TRANSPARENT
		canvas_item = canvas_item.get_parent() as CanvasItem

	var image_position := to_local(world_point) + Vector2(_interaction_mask.get_size()) * 0.5 - offset
	if flip_h:
		image_position.x = float(_interaction_mask.get_width()) - image_position.x
	if flip_v:
		image_position.y = float(_interaction_mask.get_height()) - image_position.y
	var pixel := Vector2i(floori(image_position.x), floori(image_position.y))
	if (
		pixel.x < 0
		or pixel.y < 0
		or pixel.x >= _interaction_mask.get_width()
		or pixel.y >= _interaction_mask.get_height()
	):
		return Color.TRANSPARENT
	return _interaction_mask.get_pixelv(pixel)


func activate_interaction() -> void:
	_perform_interaction()


func get_interaction_highlight_texture() -> Texture2D:
	return _interaction_highlight_texture


func _perform_interaction() -> void:
	pass


func _make_highlight_texture(mask: Image) -> Texture2D:
	if mask == null or mask.is_empty():
		return null

	var highlight := Image.create(mask.get_width(), mask.get_height(), false, Image.FORMAT_RGBA8)
	highlight.fill(Color.TRANSPARENT)
	for y in range(mask.get_height()):
		for x in range(mask.get_width()):
			var source_color := mask.get_pixel(x, y)
			if source_color.a > 0.0 and source_color.get_luminance() > 0.0:
				highlight.set_pixel(x, y, Color(1.0, 1.0, 1.0, source_color.a))
	return ImageTexture.create_from_image(highlight)
