extends CanvasLayer

const DEFAULT_TARGET_FPS := 60

var active_menu := ""
var rhythm_selected_item := 0

var shade: ColorRect
var menu_panel: PanelContainer
var title_label: Label
var content_label: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = DEFAULT_TARGET_FPS
	_build_overlay()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if _ctrl_modifier_pressed(key_event) and _event_matches_key(key_event, KEY_D):
		if not _gameplay_debug_is_available():
			return
		if active_menu == "gameplay_prefix":
			_close_menu()
		else:
			_open_menu("gameplay_prefix")
		get_viewport().set_input_as_handled()
		return

	if active_menu.is_empty():
		return
	get_viewport().set_input_as_handled()
	_handle_menu_key(key_event)


func _event_matches_key(event: InputEventKey, expected_key: Key) -> bool:
	return event.keycode == expected_key or event.physical_keycode == expected_key


func _ctrl_modifier_pressed(event: InputEventKey) -> bool:
	return event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL)


func _gameplay_debug_is_available() -> bool:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("supports_gameplay_debug"):
		return true
	return bool(scene.call("supports_gameplay_debug"))


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

	center.hide()
	_refresh_menu()


func _handle_menu_key(key_event: InputEventKey) -> void:
	if key_event.keycode == KEY_ESCAPE:
		_close_menu()
		return

	match active_menu:
		"gameplay_menu":
			if key_event.keycode in [KEY_1, KEY_KP_1]:
				_open_menu("rhythm_control")
			elif key_event.keycode in [KEY_2, KEY_KP_2]:
				_open_menu("spell_visuals")
		"gameplay_prefix":
			if _event_matches_key(key_event, KEY_G):
				_open_menu("gameplay_menu")
		"rhythm_control":
			_handle_rhythm_control_key(key_event.keycode)


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
		"gameplay_menu":
			title_label.text = "GAMEPLAY // CTRL+D → G"
			content_label.text = "1   BPM / JUDGMENT\n2   SPELL // SOLO VFX\nESC   CHIUDI"
		"spell_visuals":
			title_label.text = "SPELL // SOLO VFX"
			content_label.text = "A / SHIFT+A   BLACK HOLE\nS / SHIFT+S   WHITE HOLE\nD / SHIFT+D   STAR\n\nCAST VISIVO: NESSUN EFFETTO\nALT+A/S/D   INTERROMPI CAST\nESC   CHIUDI"
		"gameplay_prefix":
			title_label.text = "DEBUG GAMEPLAY // CTRL+D"
			content_label.text = "G   GAMEPLAY\nESC   CHIUDI"
		"rhythm_control":
			_refresh_rhythm_control_menu()
		_:
			return


func _refresh_rhythm_control_menu() -> void:
	title_label.text = "GAMEPLAY // BPM / JUDGMENT"
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
