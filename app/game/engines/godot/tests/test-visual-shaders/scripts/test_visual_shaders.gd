extends Control

const DEFAULT_LENSING := 0.78
const DEFAULT_ORBIT_SPEED := 0.55
const DEFAULT_RAY_STEPS := 128
const LANDSCAPE_SIZE := Vector2i(1280, 720)

@onready var preview: MeshInstance3D = $PreviewViewport/Viewport/World/ScreenQuad

var shader_material: ShaderMaterial
var lensing_value: Label
var orbit_value: Label
var ray_steps_value: Label
var lensing_slider: HSlider
var orbit_slider: HSlider
var ray_steps_slider: HSlider
var display_window: Window
var previous_window_size := Vector2i.ZERO
var previous_content_scale_size := Vector2i.ZERO


func _ready() -> void:
	display_window = get_window()
	previous_window_size = display_window.size
	previous_content_scale_size = display_window.content_scale_size
	display_window.content_scale_size = LANDSCAPE_SIZE
	display_window.size = LANDSCAPE_SIZE

	shader_material = preview.material_override as ShaderMaterial
	_build_overlay()


func _exit_tree() -> void:
	if is_instance_valid(display_window):
		display_window.content_scale_size = previous_content_scale_size
		display_window.size = previous_window_size


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset_parameters()
		get_viewport().set_input_as_handled()


func _build_overlay() -> void:
	var safe_area := MarginContainer.new()
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.add_theme_constant_override("margin_left", 24)
	safe_area.add_theme_constant_override("margin_top", 24)
	safe_area.add_theme_constant_override("margin_right", 24)
	safe_area.add_theme_constant_override("margin_bottom", 24)
	safe_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe_area)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_area.add_child(column)
	column.add_child(_build_header())

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	column.add_child(_build_controls())


func _build_header() -> PanelContainer:
	var panel := _make_panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(_with_margins(row, 16, 12, 16, 12))

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	row.add_child(titles)

	var eyebrow := _make_label("MISSION HEXALIFE  /  VFX LAB", 10, Color8(112, 201, 226))
	titles.add_child(eyebrow)
	titles.add_child(_make_label("BLACK HOLE", 25, Color8(241, 245, 255)))
	titles.add_child(_make_label("Gravitational lens  ·  Accretion disc", 12, Color8(157, 175, 204)))

	var badge := _make_label("3D RAYMARCH\n128 STEPS · HDR", 10, Color8(174, 215, 239))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(badge)
	return panel


func _build_controls() -> PanelContainer:
	var panel := _make_panel()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(_with_margins(content, 16, 14, 16, 13))

	var heading := HBoxContainer.new()
	content.add_child(heading)
	heading.add_child(_make_label("LIVE PARAMETERS", 11, Color8(112, 201, 226)))
	var hint := _make_label("R  RESET", 10, Color8(132, 149, 177))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(hint)

	lensing_slider = _make_slider(0.0, 1.5, DEFAULT_LENSING)
	lensing_value = _make_label("0.78", 11, Color8(241, 197, 133))
	content.add_child(_build_slider_row("LENSING", lensing_slider, lensing_value))
	lensing_slider.value_changed.connect(_on_lensing_changed)

	orbit_slider = _make_slider(0.0, 2.0, DEFAULT_ORBIT_SPEED)
	orbit_value = _make_label("0.55×", 11, Color8(241, 197, 133))
	content.add_child(_build_slider_row("ORBIT SPEED", orbit_slider, orbit_value))
	orbit_slider.value_changed.connect(_on_orbit_speed_changed)

	ray_steps_slider = _make_slider(48.0, 128.0, DEFAULT_RAY_STEPS, 8.0)
	ray_steps_value = _make_label("128", 11, Color8(241, 197, 133))
	content.add_child(_build_slider_row("RAY STEPS", ray_steps_slider, ray_steps_value))
	ray_steps_slider.value_changed.connect(_on_ray_steps_changed)

	var footer := _make_label("Tune gravity, disc rotation and ray integration quality in real time.", 10, Color8(132, 149, 177))
	content.add_child(footer)
	return panel


func _build_slider_row(caption: String, slider: HSlider, value_label: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var title := _make_label(caption, 10, Color8(190, 204, 226))
	title.custom_minimum_size.x = 102
	row.add_child(title)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 44
	row.add_child(value_label)
	return row


func _make_slider(minimum: float, maximum: float, initial: float, step: float = 0.01) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.custom_minimum_size.y = 20
	slider.focus_mode = Control.FOCUS_ALL
	return slider


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.029, 0.055, 0.88)
	style.border_color = Color(0.19, 0.34, 0.48, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _with_margins(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", left)
	margins.add_theme_constant_override("margin_top", top)
	margins.add_theme_constant_override("margin_right", right)
	margins.add_theme_constant_override("margin_bottom", bottom)
	margins.add_child(child)
	return margins


func _make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_lensing_changed(value: float) -> void:
	shader_material.set_shader_parameter("lensing_strength", value)
	lensing_value.text = "%.2f" % value


func _on_orbit_speed_changed(value: float) -> void:
	shader_material.set_shader_parameter("orbit_speed", value)
	orbit_value.text = "%.2f×" % value


func _on_ray_steps_changed(value: float) -> void:
	shader_material.set_shader_parameter("ray_steps", int(value))
	ray_steps_value.text = "%d" % int(value)


func _reset_parameters() -> void:
	lensing_slider.value = DEFAULT_LENSING
	orbit_slider.value = DEFAULT_ORBIT_SPEED
	ray_steps_slider.value = DEFAULT_RAY_STEPS
