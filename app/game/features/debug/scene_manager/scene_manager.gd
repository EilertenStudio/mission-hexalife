extends CanvasLayer

const COPY_NOTICE_DURATION := 2.5
const AVAILABLE_SCENES := []

@export_group("Leader shortcut")
@export var leader_key: Key = KEY_P
@export var leader_ctrl := true
@export var leader_alt := false
@export var leader_shift := false
@export var leader_meta := false
@export_file("*.tscn") var default_scene_path := "res://scenes/title_screen/title_screen.tscn"

@onready var _shade: ColorRect = $Overlay/Shade
@onready var _center: CenterContainer = $Overlay/MenuCenter
@onready var _title: Label = $Overlay/MenuCenter/MenuPanel/Margins/Layout/Title
@onready var _content: Label = $Overlay/MenuCenter/MenuPanel/Margins/Layout/Content
@onready var _notice: Label = $Overlay/Notice
@onready var _scene_flow: Node = get_node("../SceneFlow")

var _active_menu := ""
var _active_scene_path := ""
var _notice_timer := 0.0


func _ready() -> void:
	layer = 100
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_active_scene_path = str(_scene_flow.get("current_scene_path"))
	_shade.hide()
	_center.hide()
	_refresh_menu()


func _process(delta: float) -> void:
	if _notice_timer > 0.0:
		_notice_timer -= delta
		if _notice_timer <= 0.0:
			_notice.hide()
			if _active_menu.is_empty():
				visible = false


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if _matches_leader_shortcut(key_event):
		if _active_menu.is_empty():
			_open_menu("scene_manager")
		else:
			_close_menu()
		get_viewport().set_input_as_handled()
		return

	if _active_menu.is_empty():
		return
	get_viewport().set_input_as_handled()
	_handle_menu_key(key_event)


func _matches_leader_shortcut(event: InputEventKey) -> bool:
	var matches_key := event.keycode == leader_key or event.physical_keycode == leader_key
	return (
		matches_key
		and event.ctrl_pressed == leader_ctrl
		and event.alt_pressed == leader_alt
		and event.shift_pressed == leader_shift
		and event.meta_pressed == leader_meta
	)


func _handle_menu_key(event: InputEventKey) -> void:
	if _key_matches(event, KEY_ESCAPE):
		if _active_menu == "scene_select":
			_open_menu("scene_manager")
		else:
			_close_menu()
		return

	if _active_menu == "scene_manager":
		match event.keycode:
			KEY_R:
				_reload_scene()
			KEY_M:
				_open_menu("scene_select")
			KEY_C:
				_copy_frame_to_clipboard()
	elif _active_menu == "scene_select":
		if event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			_load_scene(default_scene_path)
			return
		for scene_option in AVAILABLE_SCENES:
			if event.keycode == scene_option["key"] or event.physical_keycode == scene_option["key"]:
				_load_scene(scene_option["path"])
				return


func _key_matches(event: InputEventKey, expected_key: Key) -> bool:
	return event.keycode == expected_key or event.physical_keycode == expected_key


func _open_menu(menu_id: String) -> void:
	_active_menu = menu_id
	visible = true
	_shade.show()
	_center.show()
	_refresh_menu()


func _close_menu() -> void:
	_active_menu = ""
	_shade.hide()
	_center.hide()
	visible = _notice_timer > 0.0


func _refresh_menu() -> void:
	match _active_menu:
		"scene_manager":
			_title.text = "DEBUG SCENE MANAGER // %s" % _leader_shortcut_text()
			_content.text = "R   RICARICA SCENA\nM   CAMBIA SCENA\nC   COPIA FRAME\nESC   CHIUDI"
		"scene_select":
			_title.text = "CAMBIA SCENA // ESC INDIETRO"
			var lines := PackedStringArray(["0   TITLE SCREEN"])
			for scene_option in AVAILABLE_SCENES:
				lines.append("%s   %s" % [OS.get_keycode_string(scene_option["key"]), scene_option["label"]])
			lines.append("ESC   INDIETRO")
			_content.text = "\n".join(lines)


func _leader_shortcut_text() -> String:
	var modifiers := PackedStringArray()
	if leader_ctrl:
		modifiers.append("CTRL")
	if leader_alt:
		modifiers.append("ALT")
	if leader_shift:
		modifiers.append("SHIFT")
	if leader_meta:
		modifiers.append("META")
	modifiers.append(OS.get_keycode_string(leader_key))
	return "+".join(modifiers)


func _load_scene(scene_path: String) -> void:
	if not bool(_scene_flow.call("change_scene", scene_path)):
		_show_notice("SCENA NON DISPONIBILE")
		return

	_active_scene_path = str(_scene_flow.get("current_scene_path"))
	_close_menu()


func _reload_scene() -> void:
	_active_scene_path = str(_scene_flow.get("current_scene_path"))
	if _active_scene_path.is_empty():
		get_tree().reload_current_scene()
		return
	_load_scene(_active_scene_path)


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
	visible = true
	_notice.text = message
	_notice.show()
	_notice_timer = COPY_NOTICE_DURATION
