extends Node2D

const INTERACTABLE_GROUP := "garage_interactable"

@export_range(0.0, 1.0, 0.01) var visibility_threshold := 0.08:
	set(value):
		visibility_threshold = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_refresh_hover_target()

@export_range(0.0, 1.0, 0.01) var highlight_intensity := 0.18:
	set(value):
		highlight_intensity = clampf(value, 0.0, 1.0)
		if is_instance_valid(_highlight_sprite):
			_highlight_sprite.modulate = Color(1.0, 1.0, 1.0, highlight_intensity)
			_update_highlight_transform()

@onready var _ambient_light: CanvasModulate = $"../Lighting/AmbientDarkness"
@onready var _lighting: Node2D = $"../Lighting"

var _point_lights: Array[PointLight2D] = []
var _light_images: Dictionary[int, Image] = {}
var _hovered_target: CanvasItem
var _highlight_layer: CanvasLayer
var _highlight_sprite: Sprite2D


func _ready() -> void:
	_highlight_layer = CanvasLayer.new()
	_highlight_layer.name = "InteractionHighlights"
	_highlight_layer.layer = 5
	add_child(_highlight_layer)
	_highlight_sprite = Sprite2D.new()
	_highlight_sprite.name = "SpriteHighlight"
	_highlight_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_highlight_sprite.material = _make_highlight_material()
	_highlight_sprite.modulate = Color(1.0, 1.0, 1.0, highlight_intensity)
	_highlight_sprite.visible = false
	_highlight_layer.add_child(_highlight_sprite)

	for child in _lighting.get_children():
		if child is PointLight2D:
			var point_light := child as PointLight2D
			_point_lights.append(point_light)
			if point_light.texture != null:
				_light_images[point_light.get_instance_id()] = point_light.texture.get_image()
	set_process_priority(20)
	_refresh_hover_target()


func _process(_delta: float) -> void:
	_refresh_hover_target()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	_refresh_hover_target()
	if is_instance_valid(_hovered_target):
		_hovered_target.call("activate_interaction")
		get_viewport().set_input_as_handled()


func set_visibility_threshold(value: float) -> void:
	visibility_threshold = value


func set_highlight_intensity(value: float) -> void:
	highlight_intensity = value


func _refresh_hover_target() -> void:
	var target := _find_target_at(get_global_mouse_position())
	if target == _hovered_target:
		_update_highlight_transform()
		Input.set_default_cursor_shape(
			Input.CURSOR_POINTING_HAND if is_instance_valid(target) else Input.CURSOR_ARROW
		)
		return

	_hovered_target = target
	_highlight_sprite.visible = is_instance_valid(_hovered_target)
	_update_highlight_transform()
	Input.set_default_cursor_shape(
		Input.CURSOR_POINTING_HAND if is_instance_valid(_hovered_target) else Input.CURSOR_ARROW
	)


func _find_target_at(world_point: Vector2) -> CanvasItem:
	var hovered_control := get_viewport().gui_get_hovered_control()
	if is_instance_valid(hovered_control):
		return null

	var candidates := get_tree().get_nodes_in_group(INTERACTABLE_GROUP)
	candidates.sort_custom(_is_drawn_before)

	for candidate_index in range(candidates.size() - 1, -1, -1):
		var candidate := candidates[candidate_index] as CanvasItem
		if candidate == null or not candidate.is_visible_in_tree():
			continue
		var pixel_color: Color = candidate.call("get_interaction_pixel_color_at", world_point)
		if pixel_color.a <= 0.0:
			continue

		# Sprite color does not define whether a solid pixel can be clicked:
		# black pixels remain interactive when enough light reaches their position.
		# An opaque object in front still blocks targets behind it when too dark.
		var estimated_visibility := pixel_color.a * _estimate_illumination(world_point)
		if estimated_visibility <= 0.0 or estimated_visibility < visibility_threshold:
			return null
		return candidate
	return null


func _is_drawn_before(first: Node, second: Node) -> bool:
	var first_canvas_item := first as CanvasItem
	var second_canvas_item := second as CanvasItem
	if first_canvas_item.z_index != second_canvas_item.z_index:
		return first_canvas_item.z_index < second_canvas_item.z_index
	return first.get_index() < second.get_index()


func _estimate_illumination(world_point: Vector2) -> float:
	var illumination := 0.0
	if _ambient_light.is_visible_in_tree():
		illumination = _ambient_light.color.get_luminance() * _ambient_light.color.a
	for point_light in _point_lights:
		if not point_light.enabled or not point_light.is_visible_in_tree() or point_light.energy <= 0.0:
			continue
		var light_image := _light_images.get(point_light.get_instance_id()) as Image
		if light_image == null or light_image.is_empty() or point_light.texture_scale <= 0.0:
			continue
		var texture_position := (
			point_light.to_local(world_point) / point_light.texture_scale
			+ Vector2(light_image.get_size()) * 0.5
		)
		var light_sample := _sample_light_texture(point_light, light_image, texture_position)
		illumination += (
			light_sample.a
			* light_sample.get_luminance()
			* point_light.color.get_luminance()
			* point_light.color.a
			* point_light.energy
		)
	return clampf(illumination, 0.0, 1.0)


func _sample_light_texture(
	point_light: PointLight2D,
	image: Image,
	texture_position: Vector2
) -> Color:
	if (
		texture_position.x < 0.0
		or texture_position.y < 0.0
		or texture_position.x >= image.get_width()
		or texture_position.y >= image.get_height()
	):
		return Color.TRANSPARENT

	if point_light.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST:
		return image.get_pixelv(Vector2i(floori(texture_position.x), floori(texture_position.y)))

	var pixel_position := texture_position - Vector2(0.5, 0.5)
	var x0 := floori(pixel_position.x)
	var y0 := floori(pixel_position.y)
	var fraction := Vector2(pixel_position.x - x0, pixel_position.y - y0)
	var color00 := _get_clamped_pixel(image, x0, y0)
	var color10 := _get_clamped_pixel(image, x0 + 1, y0)
	var color01 := _get_clamped_pixel(image, x0, y0 + 1)
	var color11 := _get_clamped_pixel(image, x0 + 1, y0 + 1)
	return color00.lerp(color10, fraction.x).lerp(
		color01.lerp(color11, fraction.x), fraction.y
	)


func _get_clamped_pixel(image: Image, x: int, y: int) -> Color:
	return image.get_pixel(
		clampi(x, 0, image.get_width() - 1),
		clampi(y, 0, image.get_height() - 1)
	)


func _update_highlight_transform() -> void:
	if not is_instance_valid(_hovered_target) or highlight_intensity <= 0.0:
		_highlight_sprite.visible = false
		return
	var target_sprite := _hovered_target as Sprite2D
	if target_sprite == null or target_sprite.texture == null:
		_highlight_sprite.visible = false
		return
	_highlight_sprite.visible = true
	_highlight_sprite.texture = target_sprite.call("get_interaction_highlight_texture")
	_highlight_sprite.texture_filter = target_sprite.texture_filter
	_highlight_sprite.centered = target_sprite.centered
	_highlight_sprite.offset = target_sprite.offset
	_highlight_sprite.flip_h = target_sprite.flip_h
	_highlight_sprite.flip_v = target_sprite.flip_v
	_highlight_sprite.hframes = target_sprite.hframes
	_highlight_sprite.vframes = target_sprite.vframes
	_highlight_sprite.frame_coords = target_sprite.frame_coords
	_highlight_sprite.region_enabled = target_sprite.region_enabled
	_highlight_sprite.region_rect = target_sprite.region_rect
	_highlight_sprite.transform = (
		_highlight_layer.get_final_transform().affine_inverse()
		* target_sprite.get_global_transform_with_canvas()
	)


func _make_highlight_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return material


func _exit_tree() -> void:
	if is_instance_valid(_highlight_sprite):
		_highlight_sprite.visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
