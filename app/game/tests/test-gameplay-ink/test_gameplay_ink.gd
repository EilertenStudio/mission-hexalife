@tool
extends Control

const DirectorScript := preload("res://addons/ink_scene_director/ink_scene_director.gd")
const HotspotLayerScript := preload("res://tests/test-gameplay-ink/interaction_hotspot_layer.gd")
const CryogenicRoom := preload("res://assets/rooms/cryogenic-room/exports/cryogenic-room-pixelart-v2.png")

const STORY_JSON := "res://tests/test-gameplay-ink/generated/mission-hexalife.json"
const TEST_SCENE_PATH := "res://tests/test-gameplay-ink/test-gameplay-ink.tscn"
const NARRATIVE_PANEL_MIN_HEIGHT := 160.0
const ACTOR_NAMES := {
	"capitano": "CAPITANO",
	"ingegnere": "INGEGNERE",
	"medico": "MEDICO",
	"ufficiale": "PRIMO UFFICIALE",
	"scienziato": "SCIENZIATO",
}

@export var text_writing_enabled := true

var _director: Node
var _room_background: TextureRect
var _hotspot_layer: Control
var _placeholder_background: ColorRect
var _location_label: Label
var _actor_label: Label
var _status_label: Label
var _text_writing_toggle: Button
var _text_panel: PanelContainer
var _dialogue_viewport: Control
var _dialogue_scroll: ScrollContainer
var _current_line_label: RichTextLabel
var _narrative_panel: PanelContainer
var _narrative_scroll: ScrollContainer
var _narrative_viewport: Control
var _action_panel: PanelContainer
var _action_text_label: RichTextLabel
var _action_options_list: VBoxContainer
var _dialog_panel: PanelContainer
var _dialog_speaker_label: Label
var _dialog_text_label: RichTextLabel
var _dialog_options_list: VBoxContainer
var _typewriter_label: RichTextLabel
var _notify_overlay: ColorRect
var _notify_panel: PanelContainer
var _notify_scroll: ScrollContainer
var _notify_text_label: RichTextLabel
var _start_button: Button
var _speaker_plate: PanelContainer
var _speaker_label: Label
var _action_header_row: HBoxContainer
var _action_prompt_label: Label
var _text_size_button: Button
var _advance_button: Button
var _action_advance_button: Button
var _choice_panel: PanelContainer
var _choice_center: Control
var _choice_scroll: ScrollContainer
var _choice_list: VBoxContainer
var _audio_player: AudioStreamPlayer
var _current_actor := "EQUIPAGGIO"
var _is_intro_dialogue := false
var _displayed_knot := ""
var _is_revealing_line := false
var _reveal_character_ends := PackedInt32Array()
var _reveal_index := 0
var _typewriter_timer: Timer
var _pending_choices: Array[Dictionary] = []
var _visible_choices: Array[Dictionary] = []
var _has_pending_choices := false
var _pending_knot_line: Dictionary = {}
var _pending_choices_need_continue := false
var _user_input_transition := false
var _room_context_bbcode := ""
var _room_context_scroll := 0
var _is_action_panel_compact := false
var _history_user_expanded := false
var _story_end_pending := false
var _notify_waiting_for_start := false
var _active_sequence_mode := "narrative"
var _displayed_sequence_mode := "narrative"
var _last_rendered_box_mode := ""
var _typewriter_active_start := 0
var _typewriter_history_start := 0
var _narrative_growth_start := 0


@export_tool_button("GENERATE", "Callable")
var generate_node_tree: Callable = Callable(self, "_queue_node_tree_generation")


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if has_node("UILayout"):
		_bind_interface_nodes()
	else:
		_build_interface()
	_build_director()
	_typewriter_timer = Timer.new()
	_typewriter_timer.name = "TypewriterTimer"
	_typewriter_timer.wait_time = 1.0 / 30.0
	_typewriter_timer.timeout.connect(_reveal_next_word)
	add_child(_typewriter_timer)
	if not _director.load_story(STORY_JSON):
		_show_setup_message("JSON Ink mancante o non valido. Compila la storia con `mise run compile-godot` dalla cartella app/gamebook.")
		return
	_director.start_story()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_responsive_layout()


func _update_responsive_layout(viewport_width: float = 0.0) -> void:
	var layout_width := viewport_width if viewport_width > 0.0 else size.x
	if layout_width <= 0.0:
		layout_width = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	if is_instance_valid(_choice_panel):
		_choice_panel.custom_minimum_size.x = maxf(240.0, layout_width)
	if is_instance_valid(_notify_scroll):
		var layout_height := size.y
		if layout_height <= 0.0:
			layout_height = float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
		_notify_scroll.custom_minimum_size.y = 0.0
		_notify_scroll.custom_maximum_size.y = maxf(180.0, layout_height - 120.0)
	var font_scale := clampf(layout_width / 1280.0, 0.78, 1.0)
	if is_instance_valid(_current_line_label):
		var base_size := 17 if _is_intro_dialogue else 19
		_current_line_label.add_theme_font_size_override("normal_font_size", roundi(float(base_size) * font_scale))
	if is_instance_valid(_dialog_text_label):
		_dialog_text_label.add_theme_font_size_override("normal_font_size", roundi(17.0 * font_scale))
	if is_instance_valid(_location_label):
		_location_label.add_theme_font_size_override("font_size", roundi(24.0 * font_scale))
	if is_instance_valid(_actor_label):
		_actor_label.add_theme_font_size_override("font_size", roundi(16.0 * font_scale))
	if is_instance_valid(_status_label):
		_status_label.add_theme_font_size_override("font_size", roundi(15.0 * font_scale))
	var setup_notice := get_node_or_null("UILayout/NoticeOverlay/SetupNotice") as Control
	if setup_notice != null:
		setup_notice.custom_minimum_size.x = minf(560.0, maxf(240.0, layout_width - 64.0))


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	_placeholder_background = ColorRect.new()
	_placeholder_background.name = "PlaceholderBackground"
	_placeholder_background.color = Color("#12202b")
	_placeholder_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_placeholder_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_placeholder_background)

	_room_background = TextureRect.new()
	_room_background.name = "RoomBackground"
	_room_background.texture = CryogenicRoom
	_room_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_room_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_room_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_room_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room_background.visible = true
	add_child(_room_background)

	var shade := ColorRect.new()
	shade.name = "SceneShade"
	shade.color = Color(0.015, 0.025, 0.045, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_hotspot_layer = HotspotLayerScript.new()
	_hotspot_layer.name = "InteractionHotspots"
	add_child(_hotspot_layer)

	var ui_layout := Control.new()
	ui_layout.name = "UILayout"
	ui_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_layout)

	var safe_area := MarginContainer.new()
	safe_area.name = "SafeArea"
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for margin_name in ["margin_left", "margin_right"]:
		safe_area.add_theme_constant_override(margin_name, 0)
	for margin_name in ["margin_top", "margin_bottom"]:
		safe_area.add_theme_constant_override(margin_name, 0)
	ui_layout.add_child(safe_area)

	var screen_column := VBoxContainer.new()
	screen_column.name = "ScreenColumn"
	screen_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_column.add_theme_constant_override("separation", 12)
	safe_area.add_child(screen_column)

	var header := PanelContainer.new()
	header.name = "HeaderPanel"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(header, Color(0.025, 0.055, 0.08, 0.93))
	screen_column.add_child(header)
	var header_content := VBoxContainer.new()
	header_content.name = "HeaderContent"
	header_content.add_theme_constant_override("separation", 3)
	header.add_child(header_content)
	var header_row := HBoxContainer.new()
	header_row.name = "HeaderTitleRow"
	header_row.add_theme_constant_override("separation", 12)
	header_content.add_child(header_row)
	_location_label = _new_label("SALA CRIOGENICA", 24, Color("#bcefff"))
	_location_label.name = "LocationLabel"
	_location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_location_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_row.add_child(_location_label)
	_actor_label = _new_label(_current_actor, 16, Color("#61dabb"))
	_actor_label.name = "ActorLabel"
	_actor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(_actor_label)
	var status_row := HBoxContainer.new()
	status_row.name = "StatusRow"
	status_row.add_theme_constant_override("separation", 12)
	header_content.add_child(status_row)
	_status_label = _new_label("TURNO 0   •   ENERGIA 2   •   CRESCITA 1", 15, Color("#8fa3b7"))
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(_status_label)
	_text_writing_toggle = Button.new()
	_text_writing_toggle.name = "TextWritingToggle"
	_text_writing_toggle.custom_minimum_size = Vector2(148, 32)
	_text_writing_toggle.pressed.connect(_on_text_writing_toggle_pressed)
	_style_green_button(_text_writing_toggle)
	status_row.add_child(_text_writing_toggle)
	_update_text_writing_toggle()

	_narrative_panel = _make_story_panel("NarrativeBox", Color("#03050bf5"))
	_narrative_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_narrative_panel.custom_minimum_size.y = NARRATIVE_PANEL_MIN_HEIGHT
	_narrative_panel.hide()
	screen_column.add_child(_narrative_panel)
	var narrative_content := VBoxContainer.new()
	narrative_content.name = "NarrativeContent"
	narrative_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	narrative_content.add_theme_constant_override("separation", 8)
	_narrative_panel.add_child(narrative_content)
	_action_header_row = HBoxContainer.new()
	_action_header_row.name = "NarrativeHeaderRow"
	_action_header_row.add_theme_constant_override("separation", 8)
	narrative_content.add_child(_action_header_row)
	_action_prompt_label = _new_label("CRONOLOGIA", 14, Color("#61dabb"))
	_action_prompt_label.name = "HistoryLabel"
	_action_prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_header_row.add_child(_action_prompt_label)
	_text_size_button = Button.new()
	_text_size_button.name = "TextSizeButton"
	_text_size_button.custom_minimum_size = Vector2(142, 36)
	_text_size_button.text = "ESPANDI"
	_text_size_button.pressed.connect(_on_text_size_pressed)
	_style_green_button(_text_size_button)
	_action_header_row.add_child(_text_size_button)
	_action_header_row.hide()
	_narrative_viewport = Control.new()
	_narrative_viewport.name = "NarrativeViewport"
	_narrative_viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_narrative_viewport.custom_minimum_size.y = 48
	_narrative_viewport.clip_contents = true
	narrative_content.add_child(_narrative_viewport)
	_narrative_scroll = ScrollContainer.new()
	_narrative_scroll.name = "NarrativeScroll"
	_narrative_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_narrative_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_narrative_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_narrative_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_narrative_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_narrative_viewport.add_child(_narrative_scroll)
	_current_line_label = _make_rich_text_label("NarrativeText", 19)
	_current_line_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_narrative_scroll.add_child(_current_line_label)
	var narrative_controls := HBoxContainer.new()
	narrative_controls.name = "NarrativeControls"
	narrative_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narrative_content.add_child(narrative_controls)
	var narrative_spacer := Control.new()
	narrative_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narrative_controls.add_child(narrative_spacer)
	_advance_button = _make_advance_button()
	_advance_button.name = "DialogContinueButton"
	narrative_controls.add_child(_advance_button)

	var vertical_spacer := Control.new()
	vertical_spacer.name = "NarrativeBottomSpacer"
	vertical_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_column.add_child(vertical_spacer)
	var bottom_box_dock := VBoxContainer.new()
	bottom_box_dock.name = "BottomBoxDock"
	bottom_box_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_column.add_child(bottom_box_dock)

	_action_panel = _make_story_panel("ActionBox", Color("#03050bf2"))
	_action_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_action_panel.custom_minimum_size.y = 160
	_action_panel.hide()
	bottom_box_dock.add_child(_action_panel)
	var action_content := VBoxContainer.new()
	action_content.name = "ActionContent"
	action_content.add_theme_constant_override("separation", 8)
	_action_panel.add_child(action_content)
	var action_heading := _new_label("AZIONE", 14, Color("#61dabb"))
	action_heading.name = "ActionHeading"
	action_content.add_child(action_heading)
	_action_text_label = _make_rich_text_label("ActionText", 17)
	_action_text_label.custom_minimum_size.y = 0
	_action_text_label.fit_content = true
	action_content.add_child(_action_text_label)
	_action_options_list = VBoxContainer.new()
	_action_options_list.name = "ActionOptions"
	_action_options_list.add_theme_constant_override("separation", 5)
	_action_options_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_content.add_child(_action_options_list)
	_action_advance_button = _make_advance_button()
	_action_advance_button.name = "ActionContinueButton"
	action_content.add_child(_action_advance_button)

	_dialog_panel = _make_story_panel("DialogBox", Color("#03050bf2"))
	_dialog_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_dialog_panel.custom_minimum_size.y = 140
	_dialog_panel.hide()
	bottom_box_dock.add_child(_dialog_panel)
	var dialog_content := VBoxContainer.new()
	dialog_content.name = "DialogContent"
	dialog_content.add_theme_constant_override("separation", 8)
	_dialog_panel.add_child(dialog_content)
	_speaker_label = _new_label("", 14, Color("#071412"))
	_speaker_label.name = "DialogSpeaker"
	var speaker_plate := PanelContainer.new()
	speaker_plate.name = "DialogSpeakerPlate"
	speaker_plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var speaker_style := StyleBoxFlat.new()
	speaker_style.bg_color = Color("#61dabb")
	speaker_style.set_content_margin_all(8)
	speaker_plate.add_theme_stylebox_override("panel", speaker_style)
	speaker_plate.add_child(_speaker_label)
	dialog_content.add_child(speaker_plate)
	var dialog_scroll := ScrollContainer.new()
	dialog_scroll.name = "DialogScroll"
	dialog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_scroll.custom_minimum_size.y = 64
	dialog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	dialog_content.add_child(dialog_scroll)
	_dialog_text_label = _make_rich_text_label("DialogText", 17)
	_dialog_text_label.fit_content = true
	dialog_scroll.add_child(_dialog_text_label)
	_dialog_options_list = VBoxContainer.new()
	_dialog_options_list.name = "DialogOptions"
	_dialog_options_list.add_theme_constant_override("separation", 5)
	_dialog_options_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_content.add_child(_dialog_options_list)
	narrative_controls.remove_child(_advance_button)
	dialog_content.add_child(_advance_button)

	_choice_panel = _action_panel
	_choice_center = ui_layout
	_choice_scroll = null
	_choice_list = _action_options_list
	_dialogue_viewport = dialog_scroll
	_dialogue_scroll = dialog_scroll
	_speaker_plate = speaker_plate

	_notify_overlay = ColorRect.new()
	_notify_overlay.name = "NotifyOverlay"
	_notify_overlay.color = Color(0, 0, 0, 0.74)
	_notify_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_notify_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_notify_overlay.hide()
	ui_layout.add_child(_notify_overlay)
	var notify_center := MarginContainer.new()
	notify_center.name = "NotifyCenter"
	notify_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notify_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for margin_name in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		notify_center.add_theme_constant_override(margin_name, 24)
	_notify_overlay.add_child(notify_center)
	_notify_panel = _make_story_panel("NotifyBox", Color("#071019f5"))
	_notify_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notify_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notify_center.add_child(_notify_panel)
	var notify_content := VBoxContainer.new()
	notify_content.name = "NotifyContent"
	notify_content.add_theme_constant_override("separation", 16)
	_notify_panel.add_child(notify_content)
	_notify_scroll = ScrollContainer.new()
	_notify_scroll.name = "NotifyScroll"
	_notify_scroll.custom_minimum_size.y = 0
	_notify_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notify_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_notify_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_notify_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	notify_content.add_child(_notify_scroll)
	_notify_text_label = _make_rich_text_label("NotifyText", 18)
	_notify_text_label.fit_content = true
	_notify_text_label.custom_minimum_size.y = 0
	_notify_scroll.add_child(_notify_text_label)
	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.custom_minimum_size = Vector2(150, 46)
	_start_button.text = "INIZIA"
	_start_button.pressed.connect(_on_start_pressed)
	_style_green_button(_start_button)
	_start_button.hide()
	var start_row := HBoxContainer.new()
	start_row.name = "StartRow"
	start_row.add_child(Control.new())
	start_row.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_row.add_child(_start_button)
	notify_content.add_child(start_row)

	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "AudioPlayer"
	_audio_player.bus = "Master"
	add_child(_audio_player)

	var notice_overlay := CenterContainer.new()
	notice_overlay.name = "NoticeOverlay"
	notice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layout.add_child(notice_overlay)
	var missing_notice := _new_label("", 16, Color("#ffb2a8"))
	missing_notice.name = "SetupNotice"
	missing_notice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	missing_notice.custom_minimum_size.x = 320
	missing_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missing_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	missing_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	missing_notice.hide()
	notice_overlay.add_child(missing_notice)
	_bind_interface_nodes()


func _make_story_panel(panel_name: String, background: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(panel, background)
	return panel


func _make_rich_text_label(label_name: String, font_size: int) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.name = label_name
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = false
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", Color("#ffffff"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _bind_interface_nodes() -> void:
	_placeholder_background = get_node("PlaceholderBackground") as ColorRect
	_room_background = get_node("RoomBackground") as TextureRect
	_hotspot_layer = get_node("InteractionHotspots") as Control
	_location_label = get_node("UILayout/SafeArea/ScreenColumn/HeaderPanel/HeaderContent/HeaderTitleRow/LocationLabel") as Label
	_actor_label = get_node("UILayout/SafeArea/ScreenColumn/HeaderPanel/HeaderContent/HeaderTitleRow/ActorLabel") as Label
	_status_label = get_node("UILayout/SafeArea/ScreenColumn/HeaderPanel/HeaderContent/StatusRow/StatusLabel") as Label
	_text_writing_toggle = get_node("UILayout/SafeArea/ScreenColumn/HeaderPanel/HeaderContent/StatusRow/TextWritingToggle") as Button
	_narrative_panel = get_node("UILayout/SafeArea/ScreenColumn/NarrativeBox") as PanelContainer
	_text_panel = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox") as PanelContainer
	_narrative_viewport = get_node("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeViewport") as Control
	_dialogue_viewport = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogScroll") as Control
	_narrative_scroll = get_node("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeViewport/NarrativeScroll") as ScrollContainer
	_dialogue_scroll = _dialogue_viewport as ScrollContainer
	_current_line_label = get_node("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeViewport/NarrativeScroll/NarrativeText") as RichTextLabel
	_advance_button = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogContinueButton") as Button
	_action_header_row = get_node("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeHeaderRow") as HBoxContainer
	_action_prompt_label = get_node("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeHeaderRow/HistoryLabel") as Label
	_text_size_button = get_node("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeHeaderRow/TextSizeButton") as Button
	_action_panel = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/ActionBox") as PanelContainer
	_action_text_label = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/ActionBox/ActionContent/ActionText") as RichTextLabel
	_action_options_list = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/ActionBox/ActionContent/ActionOptions") as VBoxContainer
	_dialog_panel = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox") as PanelContainer
	_speaker_label = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogSpeakerPlate/DialogSpeaker") as Label
	_dialog_text_label = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogScroll/DialogText") as RichTextLabel
	_dialog_options_list = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogOptions") as VBoxContainer
	_action_advance_button = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/ActionBox/ActionContent/ActionContinueButton") as Button
	_notify_overlay = get_node("UILayout/NotifyOverlay") as ColorRect
	_notify_panel = get_node("UILayout/NotifyOverlay/NotifyCenter/NotifyBox") as PanelContainer
	_notify_scroll = get_node("UILayout/NotifyOverlay/NotifyCenter/NotifyBox/NotifyContent/NotifyScroll") as ScrollContainer
	_notify_text_label = get_node("UILayout/NotifyOverlay/NotifyCenter/NotifyBox/NotifyContent/NotifyScroll/NotifyText") as RichTextLabel
	_start_button = get_node("UILayout/NotifyOverlay/NotifyCenter/NotifyBox/NotifyContent/StartRow/StartButton") as Button
	_choice_panel = _action_panel
	_choice_center = get_node("UILayout") as Control
	_choice_scroll = null
	_choice_list = _action_options_list
	_dialogue_viewport = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogScroll") as Control
	_dialogue_scroll = _dialogue_viewport as ScrollContainer
	_speaker_plate = get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogSpeakerPlate") as PanelContainer
	_style_green_button(_start_button)
	_style_green_button(_advance_button)
	_style_green_button(_action_advance_button)
	_style_green_button(_text_size_button)
	_style_green_button(_text_writing_toggle)
	_update_text_writing_toggle()
	_text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(get_node("UILayout/SafeArea") as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	(get_node("UILayout/SafeArea/ScreenColumn") as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	(get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock") as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narrative_panel.get_node("NarrativeContent").mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_audio_player = get_node("AudioPlayer") as AudioStreamPlayer
	_update_responsive_layout()
	_hotspot_layer.configure(CryogenicRoom, [
		{"id": "capsule", "label": "ESAMINA CAPSULA", "rect": Rect2(16, 170, 230, 500), "targets": ["capsula_crio"]},
		{"id": "terminal", "label": "CONSULTA TERMINALE", "rect": Rect2(705, 428, 112, 190), "targets": ["terminale_crio"]},
		{"id": "door", "label": "INTERAGISCI CON LA PORTA", "rect": Rect2(805, 298, 292, 315), "targets": ["porta_crio", "fine_poc"]},
	])
	if not _hotspot_layer.is_connected("hotspot_pressed", _on_hotspot_pressed):
		_hotspot_layer.connect("hotspot_pressed", _on_hotspot_pressed)
	if not _advance_button.pressed.is_connected(_on_advance_pressed):
		_advance_button.pressed.connect(_on_advance_pressed)
	if not _action_advance_button.pressed.is_connected(_on_advance_pressed):
		_action_advance_button.pressed.connect(_on_advance_pressed)
	if not _text_writing_toggle.pressed.is_connected(_on_text_writing_toggle_pressed):
		_text_writing_toggle.pressed.connect(_on_text_writing_toggle_pressed)
	if not _text_size_button.pressed.is_connected(_on_text_size_pressed):
		_text_size_button.pressed.connect(_on_text_size_pressed)
	if not _start_button.pressed.is_connected(_on_start_pressed):
		_start_button.pressed.connect(_on_start_pressed)


func _queue_node_tree_generation() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate_node_tree")


func _generate_node_tree() -> bool:
	if not Engine.is_editor_hint():
		return false
	var generator_script: Script = load("res://tests/test-gameplay-ink/editor_node_tree_generator.gd")
	var generator: RefCounted = generator_script.new()
	return generator.generate(self, TEST_SCENE_PATH)


func _materialize_node_tree() -> bool:
	for child in get_children():
		if child == _director:
			continue
		remove_child(child)
		child.free()
	_build_interface()
	_set_generated_owners(self)
	return true


func _set_generated_owners(parent: Node) -> void:
	for child in parent.get_children():
		child.owner = self
		_set_generated_owners(child)


func _build_director() -> void:
	_director = DirectorScript.new()
	_director.name = "InkSceneDirector"
	add_child(_director)
	_director.runtime_error.connect(_on_runtime_error)
	_director.line_emitted.connect(_on_story_line)
	_director.choices_available.connect(_on_choices_available)
	_director.variables_changed.connect(_on_variables_changed)
	_director.story_ended.connect(_on_story_ended)
	_director.register_scene_cue("cryogenic_room", _set_scene)
	_director.register_scene_cue("corridor", _set_scene)
	_director.register_scene_cue("engine_room", _set_scene)
	_director.register_scene_cue("bridge", _set_scene)
	_director.register_camera_cue("wide", _set_camera)
	_director.register_camera_cue("close", _set_camera)
	_director.register_audio_cue("alarm", _play_audio_cue)
	for actor_id in ACTOR_NAMES.keys():
		_director.register_actor_cue(actor_id, _set_actor)


func _on_story_line(text: String, tags: PackedStringArray, knot_name: String) -> void:
	if text.strip_edges().is_empty():
		if _director.has_pending_content() and not _notify_waiting_for_start:
			call_deferred("_continue_pending_story")
		return
	if not _displayed_knot.is_empty() and knot_name != _displayed_knot and not _user_input_transition:
		_pending_knot_line = {"text": text, "tags": tags, "knot": knot_name}
		_show_knot_continue()
		return
	_render_story_line(text, tags, knot_name)


func _render_story_line(text: String, tags: PackedStringArray, knot_name: String) -> void:
	_typewriter_timer.stop()
	_story_end_pending = false
	var color := Color("#dbe8f3")
	if tags.has("ui:allarme"):
		color = Color("#ff9793")
	elif tags.has("ui:qc"):
		color = Color("#78e4f4")
	elif tags.has("ui:stato"):
		color = Color("#99a9bc")
	var speaker := ""
	if not tags.is_empty():
		for tag in tags:
			if tag.begins_with("char:") or tag.begins_with("actor:"):
				speaker = str(ACTOR_NAMES.get(tag.get_slice(":", 1), tag.get_slice(":", 1).to_upper()))
				break
	var is_intro := tags.has("ui:intro")
	var starts_narrative_section := tags.has("ui:narrative_section")
	_is_intro_dialogue = is_intro
	var formatted_text := _format_intro_text(text, clampf(size.x / 1280.0, 0.78, 1.0)) if is_intro else "[color=#%s]%s[/color]" % [color.to_html(false), _escape_bbcode(text)]
	_displayed_knot = knot_name
	if tags.has("ui:dialogue"):
		_active_sequence_mode = "dialogue"
	elif tags.has("ui:action"):
		_active_sequence_mode = "action"
	if starts_narrative_section:
		_active_sequence_mode = "narrative"
	var box_mode := "notify" if is_intro else "dialogue" if not speaker.is_empty() or _active_sequence_mode == "dialogue" else _active_sequence_mode
	_displayed_sequence_mode = box_mode
	_typewriter_label = _get_box_text_label(box_mode)
	if _last_rendered_box_mode != box_mode and box_mode != "narrative" and box_mode != "notify":
		_typewriter_label.clear()
	var history_start := _current_line_label.get_total_character_count()
	if starts_narrative_section:
		_is_action_panel_compact = false
		_history_user_expanded = false
		_dialog_text_label.clear()
		_speaker_label.text = ""
		_speaker_plate.hide()
		_reset_narrative_panel_height()
		_narrative_growth_start = 0
	var active_start := 0 if box_mode == "notify" else _typewriter_label.get_total_character_count()
	if box_mode != "notify":
		var history_separator := "" if _current_line_label.get_total_character_count() == 0 else "\n\n"
		_current_line_label.append_text(history_separator + formatted_text)
		_current_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_narrative_panel.hide()
		_hide_advance_buttons()
		_update_responsive_layout()
		if box_mode != "narrative":
			var active_separator := "" if _typewriter_label.get_total_character_count() == 0 else "\n\n"
			_typewriter_label.append_text(active_separator + formatted_text)
			_typewriter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			var active_separator := "" if _typewriter_label.get_total_character_count() == 0 else "\n\n"
			_typewriter_label.append_text(active_separator + formatted_text)
			_dialog_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if box_mode == "action":
			_set_history_compact(true)
			_action_panel.show()
			_dialog_panel.hide()
		elif box_mode == "dialogue":
			_set_history_compact(true)
			_dialog_panel.show()
			_action_panel.hide()
			_speaker_label.text = speaker if not speaker.is_empty() else _speaker_label.text
		elif box_mode == "narrative":
			_action_panel.hide()
			_dialog_panel.show()
			_speaker_label.text = ""
			_speaker_plate.hide()
			_active_sequence_mode = "narrative"
		_action_header_row.hide()
	else:
		_notify_waiting_for_start = true
		_notify_overlay.show()
		_text_writing_toggle.hide()
		_notify_text_label.clear()
		_notify_text_label.append_text(formatted_text)
		_typewriter_label = _notify_text_label
		_start_button.hide()
		_narrative_panel.hide()
		_action_panel.hide()
		_dialog_panel.hide()
		active_start = 0
	_typewriter_history_start = history_start
	_typewriter_active_start = active_start
	_last_rendered_box_mode = box_mode
	_reveal_character_ends = _get_word_character_ends(_typewriter_label.get_parsed_text(), active_start) if text_writing_enabled else PackedInt32Array()
	_reveal_index = 0
	_is_revealing_line = not _reveal_character_ends.is_empty()
	_typewriter_label.visible_characters = active_start if _is_revealing_line else -1
	if box_mode != "notify":
		_current_line_label.visible_characters = history_start if _is_revealing_line else -1
	if _is_revealing_line:
		_typewriter_timer.start()
	else:
		_update_narrative_panel_height()
		call_deferred("_on_line_reveal_finished")


func _get_box_text_label(box_mode: String) -> RichTextLabel:
	match box_mode:
		"action":
			return _action_text_label
		"dialogue":
			return _dialog_text_label
		"narrative":
			return _dialog_text_label
		"notify":
			return _notify_text_label
		_:
			return _dialog_text_label


func _on_text_writing_toggle_pressed() -> void:
	_set_text_writing_enabled(not text_writing_enabled)


func _set_text_writing_enabled(enabled: bool) -> void:
	text_writing_enabled = enabled
	_update_text_writing_toggle()
	if not text_writing_enabled and _is_revealing_line:
		_finish_line_reveal()


func _update_text_writing_toggle() -> void:
	if is_instance_valid(_text_writing_toggle):
		_text_writing_toggle.text = "SCRITTURA: ON" if text_writing_enabled else "SCRITTURA: OFF"


func _get_word_character_ends(text: String, after_character: int = 0) -> PackedInt32Array:
	var ends := PackedInt32Array()
	var word_pattern := RegEx.new()
	word_pattern.compile("\\S+")
	for match_result in word_pattern.search_all(text):
		if match_result.get_end() > after_character:
			ends.append(match_result.get_end())
	return ends


func _reveal_next_word() -> void:
	if not _is_revealing_line or _reveal_index >= _reveal_character_ends.size():
		_finish_line_reveal()
		return
	var active_visible_characters := _reveal_character_ends[_reveal_index]
	_typewriter_label.visible_characters = active_visible_characters
	if _typewriter_label != _current_line_label:
		_current_line_label.visible_characters = _typewriter_history_start + (active_visible_characters - _typewriter_active_start)
	_reveal_index += 1
	_update_narrative_panel_height()
	if _reveal_index >= _reveal_character_ends.size():
		_finish_line_reveal()


func _finish_line_reveal() -> void:
	_typewriter_timer.stop()
	_is_revealing_line = false
	if is_instance_valid(_typewriter_label):
		_typewriter_label.visible_characters = -1
	if is_instance_valid(_current_line_label):
		_current_line_label.visible_characters = -1
	_update_narrative_panel_height()
	call_deferred("_update_narrative_panel_height")
	_on_line_reveal_finished()


func _on_line_reveal_finished() -> void:
	if _notify_waiting_for_start:
		_start_button.show()
		return
	if _has_pending_choices:
		_show_knot_continue()
	elif _story_end_pending:
		_story_end_pending = false
		_show_story_end()
	elif _director.has_pending_content():
		call_deferred("_continue_pending_story")


func _continue_pending_story() -> void:
	if not _is_revealing_line and not _has_pending_choices and _director.has_pending_content():
		_director.continue_story()


func _reset_dialogue_scroll() -> void:
	if is_instance_valid(_dialogue_scroll):
		_dialogue_scroll.scroll_vertical = 0


func _format_intro_text(text: String, font_scale: float) -> String:
	var title_separator := text.find(" — ")
	if title_separator < 0:
		return "[font_size=%d]%s[/font_size]" % [roundi(17.0 * font_scale), _escape_bbcode(text)]
	var title := _escape_bbcode(text.substr(0, title_separator))
	var remainder := text.substr(title_separator + " — ".length())
	var subtitle_separator := remainder.find(". ")
	var subtitle := remainder if subtitle_separator < 0 else remainder.substr(0, subtitle_separator)
	var body := "" if subtitle_separator < 0 else remainder.substr(subtitle_separator + 2)
	var formatted := "[left][font_size=%d][b]%s[/b][/font_size]\n[color=#61dabb]%s[/color][/left]" % [roundi(25.0 * font_scale), title, _escape_bbcode(subtitle)]
	if body.is_empty():
		return formatted
	formatted += "\n\n"
	var paragraphs := body.split(". ", false)
	for index in range(paragraphs.size()):
		var paragraph := str(paragraphs[index]).strip_edges()
		if paragraph.is_empty():
			continue
		if index > 0:
			formatted += "\n\n"
		formatted += "[left]%s%s[/left]" % [_escape_bbcode(paragraph), "" if paragraph.ends_with(".") else "."]
	return formatted


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")


func _on_choices_available(choices: Array[Dictionary]) -> void:
	var choice_knot := str(_director.get_current_knot())
	_active_sequence_mode = "dialogue" if choice_knot.begins_with("confronto_") else "action"
	if choices.is_empty():
		_pending_choices.clear()
		_has_pending_choices = false
		_pending_choices_need_continue = false
		_hotspot_layer.set_available_choices(choices)
		_clear_action_panel()
		return
	_pending_choices = choices.duplicate(true)
	_has_pending_choices = true
	if _director.get_current_knot() == "sala_criogenica" and _user_input_transition and not _is_revealing_line:
		_restore_room_context()
	if _user_input_transition and not _is_revealing_line:
		_displayed_knot = _director.get_current_knot()
		_pending_choices_need_continue = false
	else:
		_pending_choices_need_continue = not _displayed_knot.is_empty() and _director.get_current_knot() != _displayed_knot
	if _notify_waiting_for_start:
		return
	if not _is_revealing_line:
		if _pending_choices_need_continue:
			_show_knot_continue()
		else:
			_present_pending_choices()


func _present_pending_choices() -> void:
	if not _has_pending_choices:
		return
	var choices := _pending_choices
	_visible_choices = choices.duplicate(true)
	_pending_choices = []
	_has_pending_choices = false
	_pending_choices_need_continue = false
	_hotspot_layer.set_available_choices(choices)
	var current_knot: String = str(_director.get_current_knot())
	var is_dialogue: bool = current_knot.begins_with("confronto_")
	var list: VBoxContainer = _dialog_options_list if is_dialogue else _action_options_list
	for child in list.get_children():
		child.queue_free()
	if choices.is_empty():
		_clear_action_panel()
		return
	_hide_advance_buttons()
	_set_history_compact(true)
	_action_panel.visible = not is_dialogue
	_dialog_panel.visible = is_dialogue
	for choice in choices:
		var choice_index := int(choice.index)
		var target := str(choice.get("target", ""))
		var has_hotspot: bool = _hotspot_layer.has_method("has_target_hotspot") and _hotspot_layer.has_target_hotspot(target)
		if not is_dialogue and has_hotspot:
			var info := _new_label("%02d   %s" % [choice_index + 1, str(choice.text)], 16, Color("#dff6ff"))
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(info)
		else:
			var button := Button.new()
			button.text = "%02d   %s" % [choice_index + 1, str(choice.text)]
			button.custom_minimum_size.y = 38
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_color_override("font_color", Color("#dff6ff"))
			button.add_theme_color_override("font_hover_color", Color("#ffffff"))
			_style_green_button(button)
			button.pressed.connect(_on_choice_pressed.bind(choice_index))
			list.add_child(button)


func _on_variables_changed(variables: Dictionary) -> void:
	_status_label.text = "TURNO %s   •   ENERGIA %s   •   CRESCITA %s" % [
		str(variables.get("turno", 0)),
		str(variables.get("energia", 0)),
		str(variables.get("fungo", 0)),
	]


func _on_advance_pressed() -> void:
	if _is_revealing_line:
		_finish_line_reveal()
		return
	if not _pending_knot_line.is_empty():
		var next_line := _pending_knot_line
		_pending_knot_line = {}
		_pending_choices_need_continue = _has_pending_choices and _director.get_current_knot() != str(next_line.knot)
		_render_story_line(str(next_line.text), next_line.tags, str(next_line.knot))
		return
	if _has_pending_choices and not _pending_choices_need_continue:
		_present_pending_choices()
		return
	if _pending_choices_need_continue:
		var target_knot: String = _director.get_current_knot()
		_pending_choices_need_continue = false
		if target_knot == "sala_criogenica":
			if _room_context_bbcode.is_empty():
				_capture_room_context()
			else:
				_restore_room_context()
		else:
			call_deferred("_reset_dialogue_scroll")
			_text_panel.hide()
		_displayed_knot = target_knot
		_present_pending_choices()


func _on_choice_pressed(index: int) -> void:
	for list in [_action_options_list, _dialog_options_list]:
		for child in list.get_children():
			child.queue_free()
	_action_panel.hide()
	_dialog_panel.hide()
	_clear_action_panel()
	_action_text_label.clear()
	_dialog_text_label.clear()
	_speaker_label.text = ""
	_user_input_transition = true
	var selected_choice := {}
	for choice in _visible_choices:
		if int(choice.get("index", -1)) == index:
			selected_choice = choice
			break
	var target := str(selected_choice.get("target", ""))
	_active_sequence_mode = "dialogue" if target.begins_with("dialogo_") or target.begins_with("confronto_") else "action"
	_visible_choices.clear()
	_director.choose(index)
	_user_input_transition = false


func _on_hotspot_pressed(_hotspot_id: String, target_knot: String) -> void:
	if _displayed_knot == "sala_criogenica":
		_room_context_scroll = _dialogue_scroll.scroll_vertical
	for list in [_action_options_list, _dialog_options_list]:
		for child in list.get_children():
			child.queue_free()
	_active_sequence_mode = "action"
	_action_text_label.clear()
	_dialog_text_label.clear()
	_dialog_panel.hide()
	_clear_action_panel()
	_user_input_transition = true
	var selected: bool = _director.choose_target(target_knot)
	_user_input_transition = false
	if not selected:
		return
	_hide_advance_buttons()
	_choice_panel.hide()


func _capture_room_context() -> void:
	_room_context_bbcode = _current_line_label.text
	_room_context_scroll = _dialogue_scroll.scroll_vertical
	_displayed_knot = "sala_criogenica"


func _restore_room_context() -> void:
	if _room_context_bbcode.is_empty():
		return
	_displayed_knot = "sala_criogenica"
	_reset_narrative_panel_height()
	_advance_button.hide()
	_text_panel.show()
	call_deferred("_update_narrative_panel_height")
	call_deferred("_restore_room_scroll")


func _restore_room_scroll() -> void:
	if is_instance_valid(_dialogue_scroll):
		_dialogue_scroll.scroll_vertical = _room_context_scroll


func _clear_action_panel(reset_narrative_height: bool = true) -> void:
	_action_panel.hide()
	_dialog_panel.hide()
	if reset_narrative_height:
		_set_history_compact(false)
		call_deferred("_update_narrative_panel_height")


func _set_history_compact(compact: bool) -> void:
	_is_action_panel_compact = compact
	_history_user_expanded = false
	_narrative_panel.hide()
	call_deferred("_update_narrative_panel_height")


func _on_text_size_pressed() -> void:
	if not _action_header_row.visible:
		return
	_history_user_expanded = not _history_user_expanded
	_text_size_button.text = "CONTRAI" if _history_user_expanded else "ESPANDI"
	_text_panel.custom_minimum_size.y = _get_narrative_max_height() if _history_user_expanded else NARRATIVE_PANEL_MIN_HEIGHT
	_text_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	call_deferred("_update_narrative_panel_height")


func _reset_narrative_panel_height() -> void:
	if not is_instance_valid(_text_panel):
		return
	_text_panel.custom_minimum_size.y = NARRATIVE_PANEL_MIN_HEIGHT
	_text_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if is_instance_valid(_dialogue_scroll):
		_dialogue_scroll.scroll_vertical = 0
	call_deferred("_update_narrative_panel_height")


func _update_narrative_panel_height() -> void:
	if not is_instance_valid(_text_panel) or not is_instance_valid(_dialog_text_label):
		return
	if not _text_panel.visible:
		return
	if _is_action_panel_compact and not _history_user_expanded:
		_text_panel.custom_minimum_size.y = NARRATIVE_PANEL_MIN_HEIGHT
		return
	var character_count := _dialog_text_label.get_total_character_count()
	if character_count <= 0:
		_text_panel.custom_minimum_size.y = NARRATIVE_PANEL_MIN_HEIGHT
		return
	var visible_character_count := character_count if _dialog_text_label.visible_characters < 0 else mini(_dialog_text_label.visible_characters, character_count)
	if visible_character_count <= 0:
		_text_panel.custom_minimum_size.y = NARRATIVE_PANEL_MIN_HEIGHT
		return
	var growth_start := _narrative_growth_start if _active_sequence_mode == "narrative" and not _is_action_panel_compact else 0
	var first_line_index := _dialog_text_label.get_character_line(mini(growth_start, visible_character_count - 1))
	var line_index := _dialog_text_label.get_character_line(visible_character_count - 1)
	var required_text_height := _dialog_text_label.get_line_offset(line_index) + _dialog_text_label.get_line_height(line_index) - _dialog_text_label.get_line_offset(first_line_index)
	var max_panel_height := _get_narrative_max_height()
	if max_panel_height <= 0.0:
		return
	var min_panel_height := minf(NARRATIVE_PANEL_MIN_HEIGHT, max_panel_height)
	var desired_height := clampf(required_text_height + 96.0, min_panel_height, max_panel_height)
	var is_narrative_growth := _active_sequence_mode == "narrative" and not _is_action_panel_compact
	var target_height := maxf(_text_panel.custom_minimum_size.y, desired_height) if is_narrative_growth else desired_height
	if absf(_text_panel.custom_minimum_size.y - target_height) > 1.0:
		_text_panel.custom_minimum_size.y = ceilf(target_height)


func _get_narrative_max_height() -> float:
	if not is_instance_valid(_text_panel):
		return NARRATIVE_PANEL_MIN_HEIGHT
	var dock := _text_panel.get_parent() as Control
	var column := dock.get_parent() as Control
	var header := column.get_node("HeaderPanel") as Control
	var max_panel_height := column.size.y - header.size.y - 24.0
	if _action_panel.visible:
		max_panel_height -= _action_panel.size.y + 12.0
	return maxf(NARRATIVE_PANEL_MIN_HEIGHT, max_panel_height)


func _show_knot_continue() -> void:
	if _is_revealing_line:
		return
	_typewriter_timer.stop()
	_hide_advance_buttons()
	var show_action := _displayed_sequence_mode == "action" and not _action_text_label.get_parsed_text().strip_edges().is_empty()
	_action_panel.visible = show_action
	_dialog_panel.visible = not show_action and not _dialog_text_label.get_parsed_text().strip_edges().is_empty()
	_narrative_panel.hide()
	if show_action:
		_action_advance_button.text = "CONTINUA  →"
		_action_advance_button.show()
	else:
		_advance_button.text = "CONTINUA  →"
		_advance_button.show()


func _on_start_pressed() -> void:
	if not _notify_waiting_for_start:
		return
	_notify_waiting_for_start = false
	_notify_overlay.hide()
	_start_button.hide()
	_text_writing_toggle.show()
	_displayed_knot = ""
	_active_sequence_mode = "narrative"
	_continue_pending_story()


func _on_runtime_error(message: String) -> void:
	_typewriter_timer.stop()
	_is_revealing_line = false
	_current_line_label.text = "ERRORE RUNTIME  " + message
	_current_line_label.add_theme_color_override("default_color", Color("#ff8f88"))
	_speaker_plate.hide()
	_text_panel.show()
	_advance_button.hide()
	_pending_knot_line = {}
	_pending_choices_need_continue = false


func _on_story_ended() -> void:
	if _is_revealing_line:
		_story_end_pending = true
		return
	_show_story_end()


func _show_story_end() -> void:
	_hide_advance_buttons()
	var end_label := _new_label("FINE DELLA PoC", 15, Color("#ffc878"))
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_list.add_child(end_label)
	_action_panel.show()
	_dialog_panel.hide()


func _set_scene(id: String) -> void:
	var display_names := {
		"cryogenic_room": "SALA CRIOGENICA",
		"corridor": "CORRIDOIO",
		"engine_room": "SALA MOTORI",
		"bridge": "CENTRO DI COMANDO",
	}
	_location_label.text = str(display_names.get(id, id.to_upper()))
	_room_background.visible = id == "cryogenic_room"
	_hotspot_layer.visible = id == "cryogenic_room"
	_placeholder_background.visible = id != "cryogenic_room"
	_placeholder_background.color = {
		"corridor": Color("#1b2734"),
		"engine_room": Color("#292317"),
		"bridge": Color("#172b38"),
	}.get(id, Color("#12202b"))


func _set_actor(id: String) -> void:
	_current_actor = str(ACTOR_NAMES.get(id, id.to_upper()))
	_actor_label.text = _current_actor


func _set_camera(id: String) -> void:
	var camera_scale := 1.0 if id == "wide" else 1.1
	_room_background.pivot_offset = _room_background.size * 0.5
	var tween := create_tween()
	tween.tween_property(_room_background, "scale", Vector2.ONE * camera_scale, 0.25)


func _play_audio_cue(_id: String) -> void:
	_audio_player.stream = _make_alarm_tone()
	_audio_player.play()


func _make_alarm_tone() -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := 3308
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var envelope := 0.14 * (1.0 - float(index) / float(sample_count))
		var pcm := int(sin(TAU * 660.0 * time) * envelope * 32767.0)
		samples[index * 2] = pcm & 0xff
		samples[index * 2 + 1] = (pcm >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = samples
	return stream


func _show_setup_message(message: String) -> void:
	var notice := get_node_or_null("UILayout/NoticeOverlay/SetupNotice") as Label
	if notice != null:
		notice.text = message
		notice.show()
	_hide_advance_buttons()


func _make_advance_button() -> Button:
	var button := Button.new()
	button.name = "AdvanceButton"
	button.text = "CONTINUA  →"
	button.custom_minimum_size = Vector2(142, 42)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_green_button(button)
	button.hide()
	return button


func _style_green_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("#071412"))
	button.add_theme_color_override("font_hover_color", Color("#071412"))
	button.add_theme_color_override("font_pressed_color", Color("#071412"))
	button.add_theme_color_override("font_focus_color", Color("#071412"))
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("#61dabb")
	button_style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("normal", button_style)
	var hover_style := button_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color("#93f0d7")
	button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := button_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color("#42bb98")
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)


func _hide_advance_buttons() -> void:
	if is_instance_valid(_advance_button):
		_advance_button.hide()
	if is_instance_valid(_action_advance_button):
		_action_advance_button.hide()


func _new_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _apply_panel_style(panel: PanelContainer, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.35, 0.65, 0.78, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
