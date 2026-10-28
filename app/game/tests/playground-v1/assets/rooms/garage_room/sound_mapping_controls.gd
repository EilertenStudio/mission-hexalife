extends CanvasLayer

signal object_sample_changed(event_id: StringName, sample: AudioStream)

const MATERIAL_SAMPLE_LABELS := [
	"Metal tap", "Wood tap", "Glass tap", "Plaster tap", "Concrete tap", "Ceiling tap"
]
const MATERIAL_SAMPLE_STREAMS: Array[AudioStream] = [
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/material_taps/metal_tap.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/material_taps/wood_tap.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/material_taps/glass_tap.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/material_taps/plaster_tap.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/material_taps/concrete_tap.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/material_taps/ceiling_tap.mp3"),
]
const OBJECT_SAMPLE_LABELS := [
	"Mechanical squeak 2",
	"Mechanical squeak 1",
	"Door open",
	"Door close",
	"Switch click",
	"Light switch on",
	"Light switch off",
	"Flashlight toggle",
]
const OBJECT_SAMPLE_STREAMS: Array[AudioStream] = [
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/bulb_squeak_02.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/bulb_squeak.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/door_open.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/door_close.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/switcher_click.wav"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/light_switch_turn_on.mp3"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/light_switch_turn_off.mp3"),
	preload("res://tests/playground-v1/assets/rooms/garage_room/audio/flashlight_toggle.mp3"),
]
const MATERIALS := [
	{"id": &"metal", "label": "Metal"},
	{"id": &"wood", "label": "Wood"},
	{"id": &"glass", "label": "Glass"},
	{"id": &"plaster", "label": "Plaster"},
	{"id": &"concrete", "label": "Concrete"},
	{"id": &"ceiling", "label": "Ceiling"},
]
const OBJECT_EVENTS := [
	{"id": &"bulblight_swing", "object": "Bulblight", "event": "Swing"},
	{"id": &"door_open", "object": "Garage door", "event": "Open"},
	{"id": &"door_close", "object": "Garage door", "event": "Close"},
	{"id": &"switch_on", "object": "Light switch", "event": "Turn on"},
	{"id": &"switch_off", "object": "Light switch", "event": "Turn off"},
	{"id": &"flashlight_toggle", "object": "Flashlight", "event": "Toggle"},
]

var _material_assignments: Dictionary = {
	&"metal": 0,
	&"wood": 1,
	&"glass": 2,
	&"plaster": 3,
	&"concrete": 4,
	&"ceiling": 5,
}
var _object_assignments: Dictionary = {
	&"bulblight_swing": 0,
	&"door_open": 2,
	&"door_close": 3,
	&"switch_on": 5,
	&"switch_off": 6,
	&"flashlight_toggle": 7,
}
var _sample_preview: AudioStreamPlayer
var _material_contact_audio: AudioStreamPlayer


func _ready() -> void:
	layer = 11
	_build_menu()


func toggle_menu() -> void:
	visible = not visible


func _build_menu() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

	var panel := PanelContainer.new()
	panel.position = Vector2(374.0, 18.0)
	panel.custom_minimum_size = Vector2(650.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	screen.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	panel.add_child(stack)

	_add_title(stack, "SOUND MAPPING")
	_add_subtitle(
		stack,
		"Contact taps are assigned by material. Movement and state sounds belong to object events. "
		+ "Press Shift+0 to close."
	)
	_add_title(stack, "MATERIAL CONTACT")
	_add_material_table(stack)
	_add_title(stack, "OBJECT EVENTS")
	_add_object_table(stack)

	_sample_preview = AudioStreamPlayer.new()
	_sample_preview.name = "SamplePreview"
	add_child(_sample_preview)
	_material_contact_audio = AudioStreamPlayer.new()
	_material_contact_audio.name = "MaterialContactAudio"
	add_child(_material_contact_audio)


func _add_material_table(parent: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 5)
	parent.add_child(grid)
	_add_table_header(grid, "MATERIAL")
	_add_table_header(grid, "TAP SAMPLE")
	_add_table_header(grid, "PREVIEW")

	for material_entry: Dictionary in MATERIALS:
		var material_id: StringName = material_entry["id"]
		var material_label := _make_cell_label(str(material_entry["label"]))
		grid.add_child(material_label)

		var sample_option := OptionButton.new()
		sample_option.custom_minimum_size = Vector2(260.0, 28.0)
		for sample_label in MATERIAL_SAMPLE_LABELS:
			sample_option.add_item(sample_label)
		var selected_sample := int(_material_assignments[material_id])
		sample_option.select(selected_sample)
		grid.add_child(sample_option)

		var preview_button := _make_preview_button()
		preview_button.pressed.connect(_preview_material_sample.bind(material_id))
		grid.add_child(preview_button)
		sample_option.item_selected.connect(
			_on_material_sample_selected.bind(material_id)
		)


func _add_object_table(parent: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 5)
	parent.add_child(grid)
	_add_table_header(grid, "OBJECT")
	_add_table_header(grid, "EVENT")
	_add_table_header(grid, "SOUND")
	_add_table_header(grid, "PREVIEW")

	for object_event: Dictionary in OBJECT_EVENTS:
		var event_id: StringName = object_event["id"]
		grid.add_child(_make_cell_label(str(object_event["object"])))
		grid.add_child(_make_cell_label(str(object_event["event"])))

		var sample_option := OptionButton.new()
		sample_option.custom_minimum_size = Vector2(220.0, 28.0)
		for sample_index in OBJECT_SAMPLE_LABELS.size():
			sample_option.add_item(OBJECT_SAMPLE_LABELS[sample_index], sample_index)
		var selected_sample := int(_object_assignments[event_id])
		sample_option.select(selected_sample)
		grid.add_child(sample_option)

		var preview_button := _make_preview_button()
		preview_button.pressed.connect(_preview_object_sample.bind(event_id))
		grid.add_child(preview_button)
		sample_option.item_selected.connect(
			_on_object_sample_selected.bind(event_id)
		)


func _on_material_sample_selected(option_index: int, material_id: StringName) -> void:
	_material_assignments[material_id] = option_index


func _on_object_sample_selected(option_index: int, event_id: StringName) -> void:
	_object_assignments[event_id] = option_index
	object_sample_changed.emit(event_id, OBJECT_SAMPLE_STREAMS[option_index])


func _preview_material_sample(material_id: StringName) -> void:
	var sample_index := int(_material_assignments[material_id])
	_play_sample(MATERIAL_SAMPLE_STREAMS[sample_index])


func play_material_contact(material_id: StringName) -> void:
	if not _material_assignments.has(material_id):
		return
	var sample_index := int(_material_assignments[material_id])
	if sample_index < 0 or sample_index >= MATERIAL_SAMPLE_STREAMS.size():
		return
	_material_contact_audio.stream = MATERIAL_SAMPLE_STREAMS[sample_index]
	_material_contact_audio.play()


func _preview_object_sample(event_id: StringName) -> void:
	var sample_index := int(_object_assignments[event_id])
	_play_sample(OBJECT_SAMPLE_STREAMS[sample_index])


func _play_sample(sample: AudioStream) -> void:
	_sample_preview.stop()
	_sample_preview.stream = sample
	_sample_preview.play()


func _add_title(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	parent.add_child(label)


func _add_subtitle(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	parent.add_child(label)


func _add_table_header(grid: GridContainer, text_value: String) -> void:
	var label := _make_cell_label(text_value)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.55, 0.72, 0.68))
	grid.add_child(label)


func _make_cell_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	return label


func _make_preview_button() -> Button:
	var button := Button.new()
	button.text = "PLAY"
	button.custom_minimum_size = Vector2(64.0, 28.0)
	return button


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.035, 0.96)
	style.border_color = Color(0.34, 0.34, 0.34, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	return style
