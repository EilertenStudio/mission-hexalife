extends CanvasLayer

signal ambient_level_changed(value: float)
signal window_light_energy_changed(value: float)
signal flashlight_energy_changed(value: float)
signal bulblight_energy_changed(value: float)
signal window_light_range_changed(width_px: float)
signal flashlight_range_changed(radius_px: float)
signal bulb_glow_range_changed(radius_px: float)
signal ceiling_pool_range_changed(radius_px: float)
signal crt_strength_changed(value: float)
signal crt_spacing_changed(value: float)
signal light_ranges_visibility_changed(is_visible: bool)
signal flashlight_toggle_requested
signal bulblight_toggle_requested
signal crt_enabled_changed(is_enabled: bool)
signal rain_source_changed(use_sample: bool)
signal rain_volume_changed(value: float)
signal interaction_visibility_threshold_changed(value: float)
signal interaction_highlight_intensity_changed(value: float)

var _ambient_slider: HSlider
var _window_light_slider: HSlider
var _flashlight_slider: HSlider
var _bulblight_slider: HSlider
var _crt_strength_slider: HSlider
var _crt_spacing_slider: HSlider
var _window_range_slider: HSlider
var _flashlight_range_slider: HSlider
var _bulb_glow_range_slider: HSlider
var _ceiling_pool_range_slider: HSlider
var _rain_volume_slider: HSlider
var _interaction_threshold_slider: HSlider
var _interaction_highlight_slider: HSlider
var _ambient_value: Label
var _window_light_value: Label
var _flashlight_value: Label
var _bulblight_value: Label
var _crt_strength_value: Label
var _crt_spacing_value: Label
var _window_range_value: Label
var _flashlight_range_value: Label
var _bulb_glow_range_value: Label
var _ceiling_pool_range_value: Label
var _rain_volume_value: Label
var _interaction_threshold_value: Label
var _interaction_highlight_value: Label
var _flashlight_toggle: Button
var _bulblight_toggle: Button
var _crt_toggle: Button
var _light_ranges_toggle: Button
var _rain_source_toggle: Button
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


func set_rain_sample_enabled(is_enabled: bool) -> void:
	if not is_instance_valid(_rain_source_toggle):
		return
	_rain_source_toggle.set_pressed_no_signal(is_enabled)
	_rain_source_toggle.text = "SAMPLE" if is_enabled else "PROC"


func set_rain_volume(value: float) -> void:
	_set_percent_slider_value(_rain_volume_slider, _rain_volume_value, value)


func set_interaction_visibility_threshold(value: float) -> void:
	_set_percent_slider_value(_interaction_threshold_slider, _interaction_threshold_value, value)


func set_interaction_highlight_intensity(value: float) -> void:
	_set_percent_slider_value(_interaction_highlight_slider, _interaction_highlight_value, value)


func set_crt_control_values(is_enabled: bool, strength: float, spacing: float) -> void:
	_set_toggle_button(_crt_toggle, is_enabled)
	_set_slider_value(_crt_strength_slider, _crt_strength_value, strength)
	_set_slider_value(_crt_spacing_slider, _crt_spacing_value, spacing)


func set_range_control_values(
	show_ranges: bool,
	window_width: float,
	flashlight_radius: float,
	bulb_glow_radius: float,
	ceiling_pool_radius: float
) -> void:
	_set_toggle_button(_light_ranges_toggle, show_ranges)
	_set_range_slider_value(_window_range_slider, _window_range_value, window_width)
	_set_range_slider_value(_flashlight_range_slider, _flashlight_range_value, flashlight_radius)
	_set_range_slider_value(_bulb_glow_range_slider, _bulb_glow_range_value, bulb_glow_radius)
	_set_range_slider_value(_ceiling_pool_range_slider, _ceiling_pool_range_value, ceiling_pool_radius)


func _set_slider_value(slider: HSlider, value_label: Label, value: float) -> void:
	slider.set_value_no_signal(value)
	value_label.text = "%.2f" % value


func _set_range_slider_value(slider: HSlider, value_label: Label, value: float) -> void:
	slider.set_value_no_signal(value)
	value_label.text = "%.0f px" % value


func _set_percent_slider_value(slider: HSlider, value_label: Label, value: float) -> void:
	if not is_instance_valid(slider):
		return
	slider.set_value_no_signal(value)
	value_label.text = "%d%%" % roundi(value * 100.0)


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

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(318.0, 660.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	scroll.add_child(stack)

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

	var audio_divider := HSeparator.new()
	stack.add_child(audio_divider)
	var audio_title := Label.new()
	audio_title.text = "AMBIENT AUDIO"
	audio_title.add_theme_font_size_override("font_size", 14)
	audio_title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	stack.add_child(audio_title)
	var rain_source_row := HBoxContainer.new()
	rain_source_row.add_theme_constant_override("separation", 8)
	stack.add_child(rain_source_row)
	var rain_source_label := Label.new()
	rain_source_label.text = "Rain source"
	rain_source_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rain_source_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	rain_source_row.add_child(rain_source_label)
	_rain_source_toggle = _create_toggle_button(true)
	_rain_source_toggle.custom_minimum_size = Vector2(72.0, 24.0)
	_rain_source_toggle.text = "SAMPLE"
	rain_source_row.add_child(_rain_source_toggle)
	_rain_source_toggle.toggled.connect(func(use_sample: bool) -> void:
		_rain_source_toggle.text = "SAMPLE" if use_sample else "PROC"
		rain_source_changed.emit(use_sample)
	)
	_rain_volume_value = _add_audio_control(stack, "Rain volume", 1.0, 0.25, 0.01)
	_rain_volume_slider = _last_slider

	var interaction_divider := HSeparator.new()
	stack.add_child(interaction_divider)
	var interaction_title := Label.new()
	interaction_title.text = "INTERACTION"
	interaction_title.add_theme_font_size_override("font_size", 14)
	interaction_title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	stack.add_child(interaction_title)
	_interaction_threshold_value = _add_interaction_threshold_control(stack)
	_interaction_threshold_slider = _last_slider
	_interaction_highlight_value = _add_interaction_highlight_control(stack)
	_interaction_highlight_slider = _last_slider

	var range_divider := HSeparator.new()
	stack.add_child(range_divider)
	var range_title := Label.new()
	range_title.text = "LIGHT RANGES"
	range_title.add_theme_font_size_override("font_size", 14)
	range_title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	stack.add_child(range_title)
	var range_toggle_row := HBoxContainer.new()
	range_toggle_row.add_theme_constant_override("separation", 8)
	stack.add_child(range_toggle_row)
	var range_toggle_label := Label.new()
	range_toggle_label.text = "Show boundaries"
	range_toggle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	range_toggle_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	range_toggle_row.add_child(range_toggle_label)
	_light_ranges_toggle = _create_toggle_button(false)
	range_toggle_row.add_child(_light_ranges_toggle)

	_window_range_value = _add_range_control(stack, "Window lights", 240.0, 152.0, 4.0)
	_window_range_slider = _last_slider
	_flashlight_range_value = _add_range_control(stack, "Flashlight radius", 640.0, 384.0, 8.0)
	_flashlight_range_slider = _last_slider
	_bulb_glow_range_value = _add_range_control(stack, "Bulb glow radius", 160.0, 54.0, 2.0)
	_bulb_glow_range_slider = _last_slider
	_ceiling_pool_range_value = _add_range_control(stack, "Ceiling spread", 1200.0, 1200.0, 16.0)
	_ceiling_pool_range_slider = _last_slider

	var section_divider := HSeparator.new()
	stack.add_child(section_divider)

	var crt_title := Label.new()
	crt_title.text = "CRT"
	crt_title.add_theme_font_size_override("font_size", 14)
	crt_title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	stack.add_child(crt_title)

	var crt_toggle_row := HBoxContainer.new()
	crt_toggle_row.add_theme_constant_override("separation", 8)
	stack.add_child(crt_toggle_row)
	var crt_toggle_label := Label.new()
	crt_toggle_label.text = "Vertical scanlines"
	crt_toggle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crt_toggle_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	crt_toggle_row.add_child(crt_toggle_label)
	_crt_toggle = _create_toggle_button(true)
	crt_toggle_row.add_child(_crt_toggle)

	_crt_strength_value = _add_light_control(stack, "Strength", 0.5, 0.2, 0.01)
	_crt_strength_slider = _last_slider
	_crt_spacing_value = _add_light_control(stack, "Line spacing", 8.0, 2.0, 1.0, false, 2.0)
	_crt_spacing_slider = _last_slider

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

	var panel_shortcut_row := HBoxContainer.new()
	panel_shortcut_row.add_theme_constant_override("separation", 8)
	stack.add_child(panel_shortcut_row)
	var panel_key_badge := PanelContainer.new()
	panel_key_badge.add_theme_stylebox_override("panel", _make_key_style())
	panel_shortcut_row.add_child(panel_key_badge)
	var panel_shortcut := Label.new()
	panel_shortcut.text = "="
	panel_shortcut.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	panel_key_badge.add_child(panel_shortcut)
	var panel_shortcut_description := Label.new()
	panel_shortcut_description.text = "Show / hide panel"
	panel_shortcut_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_shortcut_description.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	panel_shortcut_row.add_child(panel_shortcut_description)

	var pause_shortcut_row := HBoxContainer.new()
	pause_shortcut_row.add_theme_constant_override("separation", 8)
	stack.add_child(pause_shortcut_row)
	var pause_key_badge := PanelContainer.new()
	pause_key_badge.add_theme_stylebox_override("panel", _make_key_style())
	pause_shortcut_row.add_child(pause_key_badge)
	var pause_shortcut := Label.new()
	pause_shortcut.text = "F5"
	pause_shortcut.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	pause_key_badge.add_child(pause_shortcut)
	var pause_shortcut_description := Label.new()
	pause_shortcut_description.text = "Pause / resume"
	pause_shortcut_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_shortcut_description.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	pause_shortcut_row.add_child(pause_shortcut_description)

	_flashlight_toggle.pressed.connect(func() -> void: flashlight_toggle_requested.emit())
	_bulblight_toggle.pressed.connect(func() -> void: bulblight_toggle_requested.emit())
	_light_ranges_toggle.toggled.connect(
		func(show_ranges: bool) -> void: light_ranges_visibility_changed.emit(show_ranges)
	)
	_crt_toggle.toggled.connect(func(is_enabled: bool) -> void: crt_enabled_changed.emit(is_enabled))


func _add_light_control(
	parent: VBoxContainer,
	label_text: String,
	maximum: float,
	initial: float,
	step: float,
	with_toggle := false,
	minimum := 0.0
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
	slider.min_value = minimum
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
			"Strength": crt_strength_changed.emit(changed_value)
			"Line spacing": crt_spacing_changed.emit(changed_value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value


func _add_range_control(
	parent: VBoxContainer,
	label_text: String,
	maximum: float,
	initial: float,
	step: float
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
	value.text = "%.0f px" % initial
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(54.0, 0.0)
	value.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value)

	var slider := _create_slider(0.0, maximum, initial, step)
	slider.value_changed.connect(func(changed_value: float) -> void:
		value.text = "%.0f px" % changed_value
		match label_text:
			"Window lights": window_light_range_changed.emit(changed_value)
			"Flashlight radius": flashlight_range_changed.emit(changed_value)
			"Bulb glow radius": bulb_glow_range_changed.emit(changed_value)
			"Ceiling spread": ceiling_pool_range_changed.emit(changed_value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value


func _add_audio_control(
	parent: VBoxContainer,
	label_text: String,
	maximum: float,
	initial: float,
	step: float
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
	value.text = "%d%%" % roundi(initial * 100.0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(44.0, 0.0)
	value.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value)

	var slider := _create_slider(0.0, maximum, initial, step)
	slider.value_changed.connect(func(changed_value: float) -> void:
		value.text = "%d%%" % roundi(changed_value * 100.0)
		rain_volume_changed.emit(changed_value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value


func _add_interaction_threshold_control(parent: VBoxContainer) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = "Visibility threshold"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(label)

	var value := Label.new()
	value.text = "8%"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(44.0, 0.0)
	value.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value)

	var slider := _create_slider(0.0, 1.0, 0.08, 0.01)
	slider.value_changed.connect(func(changed_value: float) -> void:
		value.text = "%d%%" % roundi(changed_value * 100.0)
		interaction_visibility_threshold_changed.emit(changed_value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value


func _add_interaction_highlight_control(parent: VBoxContainer) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = "Sprite highlight"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	row.add_child(label)

	var value := Label.new()
	value.text = "18%"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(44.0, 0.0)
	value.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	row.add_child(value)

	var slider := _create_slider(0.0, 1.0, 0.18, 0.01)
	slider.value_changed.connect(func(changed_value: float) -> void:
		value.text = "%d%%" % roundi(changed_value * 100.0)
		interaction_highlight_intensity_changed.emit(changed_value)
	)
	parent.add_child(slider)
	_last_slider = slider
	return value


func _create_slider(minimum: float, maximum: float, initial: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = minimum
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
	return slider


func _create_toggle_button(initially_enabled: bool) -> Button:
	var toggle := Button.new()
	toggle.toggle_mode = true
	toggle.custom_minimum_size = Vector2(48.0, 24.0)
	toggle.add_theme_font_size_override("font_size", 12)
	toggle.add_theme_stylebox_override("normal", _make_toggle_style(false))
	toggle.add_theme_stylebox_override("hover", _make_toggle_style(true))
	toggle.add_theme_stylebox_override("pressed", _make_toggle_style(true))
	_set_toggle_button(toggle, initially_enabled)
	return toggle


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
