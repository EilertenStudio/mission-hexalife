@tool
extends Control

signal hotspot_pressed(hotspot_id: String, target_knot: String)

var _texture_size := Vector2.ZERO
var _hotspots: Array[Dictionary] = []
var _available_targets: Dictionary = {}
var _hovered_hotspot := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func configure(texture: Texture2D, hotspots: Array) -> void:
	_texture_size = Vector2(texture.get_size()) if texture != null else Vector2.ZERO
	_hotspots.assign(hotspots.duplicate(true))
	queue_redraw()


func set_available_choices(choices: Array[Dictionary]) -> void:
	_available_targets.clear()
	for choice in choices:
		_available_targets[str(choice.get("target", ""))] = true
	_update_hover(Vector2(-1.0, -1.0))
	queue_redraw()


func has_target_hotspot(target_knot: String) -> bool:
	for hotspot in _hotspots:
		for target in hotspot.get("targets", []):
			if str(target) == target_knot:
				return true
	return false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hotspot := _hotspot_at(event.position)
		if hotspot.is_empty():
			return
		for target in hotspot.get("targets", []):
			var target_knot := str(target)
			if _available_targets.has(target_knot):
				hotspot_pressed.emit(str(hotspot.id), target_knot)
				accept_event()
				return


func _update_hover(mouse_position: Vector2) -> void:
	var hotspot := _hotspot_at(mouse_position)
	var next_id := str(hotspot.get("id", ""))
	if next_id == _hovered_hotspot:
		return
	_hovered_hotspot = next_id
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not _hovered_hotspot.is_empty() else Control.CURSOR_ARROW
	queue_redraw()


func _hotspot_at(view_position: Vector2) -> Dictionary:
	if _texture_size.x <= 0.0 or _texture_size.y <= 0.0:
		return {}
	var scale_factor := maxf(size.x / _texture_size.x, size.y / _texture_size.y)
	var rendered_size := _texture_size * scale_factor
	var crop_offset := (size - rendered_size) * 0.5
	var texture_position := (view_position - crop_offset) / scale_factor
	for hotspot in _hotspots:
		if not _hotspot_is_available(hotspot):
			continue
		var hotspot_rect: Rect2 = hotspot.get("rect", Rect2())
		if hotspot_rect.has_point(texture_position):
			return hotspot
	return {}


func _hotspot_is_available(hotspot: Dictionary) -> bool:
	for target in hotspot.get("targets", []):
		if _available_targets.has(str(target)):
			return true
	return false


func _draw() -> void:
	if _hovered_hotspot.is_empty() or _texture_size.x <= 0.0 or _texture_size.y <= 0.0:
		return
	var scale_factor := maxf(size.x / _texture_size.x, size.y / _texture_size.y)
	var crop_offset := (size - _texture_size * scale_factor) * 0.5
	for hotspot in _hotspots:
		if str(hotspot.get("id", "")) != _hovered_hotspot:
			continue
		var source_rect: Rect2 = hotspot.get("rect", Rect2())
		var view_rect := Rect2(crop_offset + source_rect.position * scale_factor, source_rect.size * scale_factor)
		draw_rect(view_rect, Color(0.35, 0.9, 1.0, 0.09), true)
		draw_rect(view_rect, Color(0.48, 0.92, 1.0, 0.9), false, 2.0)
		var font := ThemeDB.fallback_font
		if font != null:
			var label := str(hotspot.get("label", ""))
			draw_string(font, Vector2(view_rect.position.x, maxf(18.0, view_rect.position.y - 7.0)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#bff7ff"))
		return
