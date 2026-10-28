extends CanvasLayer

signal master_volume_changed(value: float)
signal exterior_volume_changed(value: float)
signal exterior_cutoff_changed(value: float)
signal rain_source_changed(use_sample: bool)
signal wind_frequency_changed(value: float)
signal thunder_frequency_changed(value: float)
signal wind_trigger_requested
signal thunder_trigger_requested

var _master_slider: HSlider
var _master_value: Label
var _exterior_slider: HSlider
var _exterior_value: Label
var _cutoff_slider: HSlider
var _cutoff_value: Label
var _rain_source_toggle: Button
var _wind_frequency_slider: HSlider
var _wind_frequency_value: Label
var _thunder_frequency_slider: HSlider
var _thunder_frequency_value: Label
var _last_slider: HSlider


func _ready() -> void:
	layer = 12
	_build_menu()


func toggle_menu() -> void:
	visible = not visible


func set_audio_values(
	master_volume: float,
	exterior_volume: float,
	wall_cutoff_hz: float,
	use_rain_sample: bool,
	wind_frequency: float,
	thunder_frequency: float
) -> void:
	_set_volume_slider(_master_slider, _master_value, master_volume)
	_set_volume_slider(_exterior_slider, _exterior_value, exterior_volume)
	_cutoff_slider.set_value_no_signal(wall_cutoff_hz)
	_cutoff_value.text = "%d Hz" % roundi(wall_cutoff_hz)
	_rain_source_toggle.set_pressed_no_signal(use_rain_sample)
	_rain_source_toggle.text = "SAMPLE" if use_rain_sample else "PROC"
	_wind_frequency_slider.set_value_no_signal(wind_frequency)
	_wind_frequency_value.text = "%.1fx" % wind_frequency
	_thunder_frequency_slider.set_value_no_signal(thunder_frequency)
	_thunder_frequency_value.text = "%.1fx" % thunder_frequency


func _build_menu() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	screen.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)

	_add_heading(stack, "AUDIO")
	_add_subtitle(
		stack,
		"Exterior weather is routed through a wall filter into the room. Adjust its presence below."
	)
	_add_heading(stack, "OUTPUT")
	_master_value = _add_volume_control(stack, "Master volume", 1.0, &"master")
	_master_slider = _last_slider

	_add_heading(stack, "EXTERIOR AMBIENCE")
	_exterior_value = _add_volume_control(stack, "Ambient volume", 0.79, &"exterior")
	_exterior_slider = _last_slider
	_cutoff_value = _add_cutoff_control(stack)
	_cutoff_slider = _last_slider
	_add_subtitle(
		stack,
		"Lower wall passage values muffle more high frequencies; higher values let more ambience through."
	)

	var route_label := Label.new()
	route_label.text = "ROUTE  Exterior ambience  →  Wall filter  →  Master"
	route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_label.add_theme_font_size_override("font_size", 11)
	route_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.68))
	stack.add_child(route_label)

	_add_rain_source_control(stack)
	_add_ambient_frequency_controls(stack)
	_add_ambient_trigger_controls(stack)
	_add_subtitle(stack, "0 closes this menu · Shift+0 opens sound mapping")


func _add_volume_control(
	parent: VBoxContainer,
	label_text: String,
	initial: float,
	control_id: StringName
) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "%d%%" % roundi(initial * 100.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(48.0, 0.0)
	value_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value_label)

	var slider := _create_slider(0.0, 1.0, initial, 0.01)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%d%%" % roundi(value * 100.0)
		if control_id == &"master":
			master_volume_changed.emit(value)
		else:
			exterior_volume_changed.emit(value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value_label


func _add_cutoff_control(parent: VBoxContainer) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.text = "Wall passage"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "4750 Hz"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(64.0, 0.0)
	value_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value_label)

	var slider := _create_slider(500.0, 6000.0, 4750.0, 50.0)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%d Hz" % roundi(value)
		exterior_cutoff_changed.emit(value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value_label


func _add_rain_source_control(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = "Rain source"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(label)

	_rain_source_toggle = Button.new()
	_rain_source_toggle.toggle_mode = true
	_rain_source_toggle.text = "SAMPLE"
	_rain_source_toggle.custom_minimum_size = Vector2(84.0, 26.0)
	_rain_source_toggle.add_theme_stylebox_override("normal", _make_toggle_style(false))
	_rain_source_toggle.add_theme_stylebox_override("hover", _make_toggle_style(true))
	_rain_source_toggle.add_theme_stylebox_override("pressed", _make_toggle_style(true))
	_rain_source_toggle.toggled.connect(func(use_sample: bool) -> void:
		_rain_source_toggle.text = "SAMPLE" if use_sample else "PROC"
		rain_source_changed.emit(use_sample)
	)
	row.add_child(_rain_source_toggle)


func _add_ambient_frequency_controls(parent: VBoxContainer) -> void:
	_add_heading(parent, "AMBIENT EVENTS")
	_wind_frequency_value = _add_frequency_control(parent, "Wind frequency", &"wind")
	_wind_frequency_slider = _last_slider
	_thunder_frequency_value = _add_frequency_control(parent, "Thunder frequency", &"thunder")
	_thunder_frequency_slider = _last_slider
	_add_subtitle(
		parent,
		"1.0x keeps the current intervals; higher values trigger each sound more often."
	)


func _add_ambient_trigger_controls(parent: VBoxContainer) -> void:
	_add_heading(parent, "TRIGGER NOW")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var wind_button := _create_trigger_button("PLAY WIND")
	wind_button.pressed.connect(func() -> void:
		wind_trigger_requested.emit()
	)
	row.add_child(wind_button)

	var thunder_button := _create_trigger_button("PLAY THUNDER")
	thunder_button.pressed.connect(func() -> void:
		thunder_trigger_requested.emit()
	)
	row.add_child(thunder_button)


func _create_trigger_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, 30.0)
	button.add_theme_stylebox_override("normal", _make_toggle_style(false))
	button.add_theme_stylebox_override("hover", _make_toggle_style(true))
	button.add_theme_stylebox_override("pressed", _make_toggle_style(true))
	button.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	return button


func _add_frequency_control(
	parent: VBoxContainer,
	label_text: String,
	control_id: StringName
) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "1.0x"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(48.0, 0.0)
	value_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value_label)

	var slider := _create_slider(0.5, 3.0, 1.0, 0.1)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.1fx" % value
		if control_id == &"wind":
			wind_frequency_changed.emit(value)
		else:
			thunder_frequency_changed.emit(value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value_label


func _create_slider(minimum: float, maximum: float, initial: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(270.0, 18.0)
	slider.add_theme_stylebox_override("slider", _make_slider_style(Color(0.12, 0.12, 0.12)))
	slider.add_theme_stylebox_override("grabber_area", _make_slider_style(Color(0.52, 0.52, 0.52)))
	slider.add_theme_stylebox_override(
		"grabber_area_highlight", _make_slider_style(Color(0.68, 0.68, 0.68))
	)
	var grabber := _create_grabber_texture()
	slider.add_theme_icon_override("grabber", grabber)
	slider.add_theme_icon_override("grabber_highlight", grabber)
	return slider


func _set_volume_slider(slider: HSlider, value_label: Label, value: float) -> void:
	var normalized := clampf(value, 0.0, 1.0)
	slider.set_value_no_signal(normalized)
	value_label.text = "%d%%" % roundi(normalized * 100.0)


func _add_heading(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14 if text == "AUDIO" else 12)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	parent.add_child(label)


func _add_subtitle(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	parent.add_child(label)


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


func _make_toggle_style(is_highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.28, 0.28, 1.0) if is_highlighted else Color(0.11, 0.11, 0.11, 1.0)
	style.border_color = Color(0.46, 0.46, 0.46, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
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
