extends Node2D

var _lights: Array[PointLight2D] = []


func set_lights(lights: Array) -> void:
	_lights.clear()
	for light: Variant in lights:
		if light is PointLight2D:
			_lights.append(light)
	queue_redraw()


func set_ranges_visible(show_ranges: bool) -> void:
	visible = show_ranges
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if not visible:
		return

	for light: PointLight2D in _lights:
		if not is_instance_valid(light) or light.texture == null:
			continue

		var center := to_local(light.global_position)
		var texture_size := Vector2(light.texture.get_size()) * light.texture_scale
		var light_name := str(light.name)
		var color := _get_guide_color(light_name)
		if light_name.begins_with("Window"):
			var bounds := Rect2(center - texture_size * 0.5, texture_size)
			draw_rect(bounds, color, false, 1.5, true)
		else:
			var radius := maxf(texture_size.x, texture_size.y) * 0.5
			draw_arc(center, radius, 0.0, TAU, 96, color, 1.5, true)


func _get_guide_color(light_name: String) -> Color:
	match light_name:
		"Flashlight":
			return Color(0.95, 0.95, 0.95, 0.82)
		"BulbGlow":
			return Color(0.72, 0.72, 0.72, 0.85)
		"CeilingPool":
			return Color(0.5, 0.5, 0.5, 0.72)
		_:
			return Color(0.82, 0.82, 0.82, 0.76)
