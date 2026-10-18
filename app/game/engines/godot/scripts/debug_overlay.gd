extends CanvasLayer

const DEFAULT_TARGET_FPS := 60
const MIN_TARGET_FPS := 1
const MAX_TARGET_FPS := 240
const COPY_NOTICE_DURATION := 2.5

const AVAILABLE_SCENES := [
	{
		"key": KEY_1,
		"label": "Test gameplay rhythm crypto",
		"path": "res://scenes/test-gameplay-rhythm-crypto.tscn",
	},
]

var active_menu := ""
var target_fps := DEFAULT_TARGET_FPS
var use_linear_filter := false
var fps_refresh_timer := 0.0
var notice_timer := 0.0
var rhythm_selected_item := 0

var shade: ColorRect
var menu_panel: PanelContainer
var title_label: Label
var content_label: Label
var notice_label: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = DEFAULT_TARGET_FPS
	_build_overlay()
	get_tree().scene_changed.connect(_on_scene_changed)
	_apply_texture_filter()


func _process(delta: float) -> void:
	fps_refresh_timer -= delta
	if fps_refresh_timer <= 0.0:
		fps_refresh_timer = 0.2
		if active_menu == "system_debug" or active_menu == "rhythm_control":
			_refresh_menu()

	if notice_timer > 0.0:
		notice_timer -= delta
		if notice_timer <= 0.0:
			notice_label.hide()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.ctrl_pressed and key_event.keycode == KEY_P:
		if active_menu.is_empty():
			_open_menu("shortcuts")
		else:
			_close_menu()
		get_viewport().set_input_as_handled()
		return

	if active_menu.is_empty():
		return
	get_viewport().set_input_as_handled()
	_handle_menu_key(key_event)


func _build_overlay() -> void:
	var root := Control.new()
	root.name = "DebugOverlayRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	shade = ColorRect.new()
	shade.name = "Dimmer"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.02, 0.05, 0.68)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.hide()
	root.add_child(shade)

	var center := CenterContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(center)

	menu_panel = PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(336, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color8(8, 13, 24, 248)
	panel_style.border_color = Color8(102, 164, 185)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(3)
	menu_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(menu_panel)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 12)
	margins.add_theme_constant_override("margin_top", 10)
	margins.add_theme_constant_override("margin_right", 12)
	margins.add_theme_constant_override("margin_bottom", 10)
	menu_panel.add_child(margins)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	margins.add_child(layout)

	title_label = Label.new()
	title_label.add_theme_color_override("font_color", Color8(140, 231, 241))
	title_label.add_theme_font_size_override("font_size", 13)
	layout.add_child(title_label)

	content_label = Label.new()
	content_label.add_theme_color_override("font_color", Color8(216, 225, 238))
	content_label.add_theme_font_size_override("font_size", 10)
	content_label.add_theme_constant_override("line_spacing", 3)
	content_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	layout.add_child(content_label)

	notice_label = Label.new()
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notice_label.offset_left = 8
	notice_label.offset_top = 7
	notice_label.offset_right = -8
	notice_label.offset_bottom = 26
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.add_theme_color_override("font_color", Color8(172, 239, 199))
	notice_label.add_theme_font_size_override("font_size", 11)
	notice_label.hide()
	root.add_child(notice_label)

	center.hide()
	_refresh_menu()


func _handle_menu_key(key_event: InputEventKey) -> void:
	if key_event.keycode == KEY_ESCAPE:
		_close_menu()
		return

	match active_menu:
		"shortcuts":
			match key_event.keycode:
				KEY_D:
					_open_menu("system_debug")
				KEY_M:
					_open_menu("scene_select")
				KEY_R:
					_reload_scene()
				KEY_C:
					_copy_frame_to_clipboard()
				KEY_J:
					_open_menu("rhythm_control")
		"system_debug":
			_handle_debug_key(key_event)
		"scene_select":
			_handle_scene_key(key_event.keycode)
		"rhythm_control":
			_handle_rhythm_control_key(key_event.keycode)


func _handle_debug_key(key_event: InputEventKey) -> void:
	var key := key_event.keycode
	if key == KEY_P:
		get_tree().paused = not get_tree().paused
		_refresh_menu()
	elif key == KEY_V:
		use_linear_filter = not use_linear_filter
		_apply_texture_filter()
		_refresh_menu()
	elif key == KEY_MINUS or key == KEY_BRACKETLEFT or key == KEY_KP_SUBTRACT:
		_set_target_fps(target_fps - 1)
	elif key == KEY_PLUS or key == KEY_EQUAL or key == KEY_BRACKETRIGHT or key == KEY_KP_ADD:
		_set_target_fps(target_fps + 1)


func _handle_scene_key(key: int) -> void:
	for scene_option in AVAILABLE_SCENES:
		if key == scene_option["key"]:
			_close_menu()
			get_tree().paused = false
			var result := get_tree().change_scene_to_file(scene_option["path"])
			if result != OK:
				_show_notice("SCENA NON DISPONIBILE")
			return


func _handle_rhythm_control_key(key: int) -> void:
	if key == KEY_UP:
		rhythm_selected_item = posmod(rhythm_selected_item - 1, 3)
		_refresh_menu()
	elif key == KEY_DOWN:
		rhythm_selected_item = posmod(rhythm_selected_item + 1, 3)
		_refresh_menu()
	elif key == KEY_LEFT or key == KEY_RIGHT:
		var controller := _get_rhythm_controller()
		if controller == null or not controller.has_method("adjust_rhythm_setting"):
			return
		var setting_names := ["bpm", "perfect", "good"]
		controller.call("adjust_rhythm_setting", setting_names[rhythm_selected_item], -1 if key == KEY_LEFT else 1)
		_refresh_menu()
	elif key == KEY_0 or key == KEY_KP_0:
		var controller := _get_rhythm_controller()
		if controller != null and controller.has_method("toggle_bpm_enabled"):
			controller.call("toggle_bpm_enabled")
		_refresh_menu()


func _open_menu(menu_id: String) -> void:
	active_menu = menu_id
	if menu_id == "rhythm_control":
		rhythm_selected_item = 0
	shade.show()
	menu_panel.get_parent().show()
	_refresh_menu()


func _close_menu() -> void:
	active_menu = ""
	shade.hide()
	menu_panel.get_parent().hide()


func _refresh_menu() -> void:
	if not is_instance_valid(title_label) or not is_instance_valid(content_label):
		return
	match active_menu:
		"shortcuts":
			title_label.text = "SYSTEM // CTRL+P"
			content_label.text = "D   DEBUG SISTEMA\nJ   BPM / JUDGMENT\nM   CAMBIA SCENA\nR   RICARICA SCENA\nC   COPIA FRAME\nESC   CHIUDI"
		"system_debug":
			title_label.text = "DEBUG SISTEMA // ESC CHIUDE"
			var filter_name := "LINEAR" if use_linear_filter else "NEAREST"
			var pause_state := "IN PAUSA" if get_tree().paused else "ATTIVO"
			content_label.text = "FPS EFFETTIVI: %d\n- / [   LIMITE FPS: %d\n+ / = / ]   LIMITE FPS: %d\nV   FILTRO TEXTURE: %s\nP   PAUSA / AVVIA: %s\nESC   CHIUDI" % [Engine.get_frames_per_second(), target_fps, target_fps, filter_name, pause_state]
		"scene_select":
			title_label.text = "CAMBIA SCENA // ESC CHIUDE"
			var lines := PackedStringArray()
			for scene_option in AVAILABLE_SCENES:
				lines.append("%s   %s" % [OS.get_keycode_string(scene_option["key"]), scene_option["label"]])
			lines.append("ESC   CHIUDI")
			content_label.text = "\n".join(lines)
		"rhythm_control":
			_refresh_rhythm_control_menu()
		_:
			return


func _refresh_rhythm_control_menu() -> void:
	title_label.text = "RITMO // BPM E JUDGMENT"
	var controller := _get_rhythm_controller()
	if controller == null or not controller.has_method("get_rhythm_settings"):
		content_label.text = "CONTROLLO RITMICO NON DISPONIBILE\nESC   CHIUDI"
		return
	var settings: Dictionary = controller.call("get_rhythm_settings")
	var bpm_state := "ON" if settings["bpm_enabled"] else "OFF / MOSSA LIBERA"
	var entries := [
		"BPM: %d %s" % [settings["bpm"], settings["profile"]],
		"PERFECT: ±%d ms" % settings["perfect_window_ms"],
		"GOOD: ±%d ms   MAX %d ms" % [settings["good_window_ms"], settings["good_window_max_ms"]],
	]
	for index in range(entries.size()):
		entries[index] = ("> " if index == rhythm_selected_item else "  ") + entries[index]
	content_label.text = "↑ / ↓   SELEZIONA\n← / →   REGOLA (5 BPM / 5 ms)\n%s\n\n0   VINCOLO BPM: %s\nESC   CHIUDI" % ["\n".join(entries), bpm_state]


func _get_rhythm_controller() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("Jerv", true, false)


func _set_target_fps(value: int) -> void:
	target_fps = clampi(value, MIN_TARGET_FPS, MAX_TARGET_FPS)
	Engine.max_fps = target_fps
	_refresh_menu()


func _apply_texture_filter() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		_set_texture_filter_recursive(scene, CanvasItem.TEXTURE_FILTER_LINEAR if use_linear_filter else CanvasItem.TEXTURE_FILTER_NEAREST)


func _set_texture_filter_recursive(node: Node, filter_mode: CanvasItem.TextureFilter) -> void:
	if node is CanvasItem:
		(node as CanvasItem).texture_filter = filter_mode
	for child in node.get_children():
		_set_texture_filter_recursive(child, filter_mode)


func _on_scene_changed() -> void:
	_apply_texture_filter()


func _reload_scene() -> void:
	_close_menu()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _copy_frame_to_clipboard() -> void:
	_close_menu()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var png_data := image.save_png_to_buffer()
	if png_data.is_empty():
		_show_notice("IMPOSSIBILE CATTURARE IL FRAME")
		return

	var commands: Array[Dictionary] = []
	if OS.has_environment("WAYLAND_DISPLAY"):
		commands = [
			{"path": "wl-copy", "args": PackedStringArray(["--type", "image/png"])},
			{"path": "xclip", "args": PackedStringArray(["-selection", "clipboard", "-t", "image/png", "-i"])},
		]
	else:
		commands = [
			{"path": "xclip", "args": PackedStringArray(["-selection", "clipboard", "-t", "image/png", "-i"])},
			{"path": "wl-copy", "args": PackedStringArray(["--type", "image/png"])},
		]

	for command in commands:
		var process := OS.execute_with_pipe(command["path"], command["args"], false)
		if not process.has("stdio") or process["stdio"] == null:
			continue
		var input_pipe: FileAccess = process["stdio"]
		input_pipe.store_buffer(png_data)
		input_pipe.close()
		_show_notice("FRAME COPIATO NEGLI APPUNTI")
		return

	_show_notice("CLIPBOARD IMMAGINE NON DISPONIBILE: INSTALLA WL-COPY O XCLIP")


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_label.show()
	notice_timer = COPY_NOTICE_DURATION
