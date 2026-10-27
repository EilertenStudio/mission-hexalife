extends CanvasLayer

signal ambient_level_changed(value: float)
signal window_light_energy_changed(value: float)
signal flashlight_energy_changed(value: float)
signal bulblight_energy_changed(value: float)
signal flashlight_toggle_requested
signal bulblight_toggle_requested

var _ambient_slider: HSlider
var _window_light_slider: HSlider
var _flashlight_slider: HSlider
var _bulblight_slider: HSlider
var _ambient_value: Label
var _window_light_value: Label
var _flashlight_value: Label
var _bulblight_value: Label
var _flashlight_toggle: Button
var _bulblight_toggle: Button
var _last_slider: HSlider


func _ready() -> void:
	layer = 10
	_build_menu()


func set_control_values(ambient: float, window_light: float, flashlight: float, bulblight: float) -> void:
	if not is_instance_valid(_ambient_slider):
		return
	_set_slider_value(_ambient_slider, _ambient_value, ambient)
	_set_slider_value(_window_light_slider, _window_light_value, window_light)
	_set_slider_value(_flashlight_slider, _flashlight_value, flashlight)
	_set_slider_value(_bulblight_slider, _bulblight_value, bulblight)


func set_flashlight_enabled(is_enabled: bool) -> void:
	_set_toggle_button(_flashlight_toggle, is_enabled)


func set_bulblight_enabled(is_enabled: bool) -> void:
	_set_toggle_button(_bulblight_toggle, is_enabled)


func _set_slider_value(slider: HSlider, value_label: Label, value: float) -> void:
	slider.set_value_no_signal(value)
	value_label.text = "%.2f" % value


func _set_toggle_button(button: Button, is_enabled: bool) -> void:
	if not is_instance_valid(button):
		return
	button.set_pressed_no_signal(is_enabled)
	button.text = "ON" if is_enabled else "OFF"
	button.add_theme_color_override(
		"font_color", Color(0.9, 0.9, 0.9) if is_enabled else Color(0.55, 0.55, 0.55)
	)


func _build_menu() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(318.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	screen.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "LIGHTING"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	stack.add_child(title)

	_ambient_value = _add_light_control(stack, "Ambient", 0.3, 0.0, 0.01)
	_ambient_slider = _last_slider
	_window_light_value = _add_light_control(stack, "Window light", 2.0, 0.32, 0.05)
	_window_light_slider = _last_slider
	_flashlight_value = _add_light_control(stack, "Flashlight", 4.0, 2.0, 0.05, true)
	_flashlight_slider = _last_slider
	_bulblight_value = _add_light_control(stack, "Bulblight", 2.0, 1.0, 0.05, true)
	_bulblight_slider = _last_slider

	var shortcut_row := HBoxContainer.new()
	shortcut_row.add_theme_constant_override("separation", 8)
	stack.add_child(shortcut_row)

	var key_badge := PanelContainer.new()
	key_badge.add_theme_stylebox_override("panel", _make_key_style())
	shortcut_row.add_child(key_badge)
	var shortcut := Label.new()
	shortcut.text = "F"
	shortcut.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	key_badge.add_child(shortcut)

	var shortcut_description := Label.new()
	shortcut_description.text = "Toggle flashlight"
	shortcut_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shortcut_description.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	shortcut_row.add_child(shortcut_description)

	_flashlight_toggle.pressed.connect(func() -> void: flashlight_toggle_requested.emit())
	_bulblight_toggle.pressed.connect(func() -> void: bulblight_toggle_requested.emit())


func _add_light_control(
	parent: VBoxContainer,
	label_text: String,
	maximum: float,
	initial: float,
	step: float,
	with_toggle := false
) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(label)

	var value := Label.new()
	value.text = "%.2f" % initial
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(44.0, 0.0)
	value.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value)

	if with_toggle:
		var toggle := Button.new()
		toggle.toggle_mode = true
		toggle.text = "OFF"
		toggle.custom_minimum_size = Vector2(48.0, 24.0)
		toggle.add_theme_font_size_override("font_size", 12)
		toggle.add_theme_stylebox_override("normal", _make_toggle_style(false))
		toggle.add_theme_stylebox_override("hover", _make_toggle_style(true))
		toggle.add_theme_stylebox_override("pressed", _make_toggle_style(true))
		row.add_child(toggle)
		if label_text == "Flashlight":
			_flashlight_toggle = toggle
		elif label_text == "Bulblight":
			_bulblight_toggle = toggle

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(270.0, 18.0)
	var track := _make_slider_style(Color(0.12, 0.12, 0.12))
	var filled_track := _make_slider_style(Color(0.52, 0.52, 0.52))
	var highlighted_track := _make_slider_style(Color(0.68, 0.68, 0.68))
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled_track)
	slider.add_theme_stylebox_override("grabber_area_highlight", highlighted_track)
	var grabber := _create_grabber_texture()
	slider.add_theme_icon_override("grabber", grabber)
	slider.add_theme_icon_override("grabber_highlight", grabber)
	slider.value_changed.connect(func(changed_value: float) -> void:
		value.text = "%.2f" % changed_value
		match label_text:
			"Ambient": ambient_level_changed.emit(changed_value)
			"Window light": window_light_energy_changed.emit(changed_value)
			"Flashlight": flashlight_energy_changed.emit(changed_value)
			"Bulblight": bulblight_energy_changed.emit(changed_value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.035, 0.94)
	style.border_color = Color(0.34, 0.34, 0.34, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	return style


func _make_slider_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _make_toggle_style(is_enabled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.28, 0.28, 1.0) if is_enabled else Color(0.11, 0.11, 0.11, 1.0)
	style.border_color = Color(0.46, 0.46, 0.46, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


func _make_key_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.16, 0.16, 1.0)
	style.border_color = Color(0.42, 0.42, 0.42, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	return style


func _create_grabber_texture() -> Texture2D:
	const SIZE := 14
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := Vector2(SIZE - 1, SIZE - 1) * 0.5
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := Vector2(x, y).distance_to(center)
			if distance <= 6.2:
				var color := Color(0.88, 0.88, 0.88, 1.0)
				if distance >= 5.0:
					color = Color(0.24, 0.24, 0.24, 1.0)
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
