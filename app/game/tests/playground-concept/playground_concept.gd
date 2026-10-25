extends Node2D

const SurfaceTapTarget = preload(
	"res://tests/playground-concept/features/interaction/surface_tap/surface_tap_target.gd"
)
const SurfaceTapRouter = preload(
	"res://tests/playground-concept/features/interaction/surface_tap/surface_tap_router.gd"
)

@onready var _feedback: Label = %Feedback
@onready var _status: Label = %Status
@onready var _top_hint: Label = $HUD/TopHint
@onready var _top_title: Label = $HUD/TopTitle
@onready var _save_button: Button = %SaveButton
@onready var _restore_button: Button = %RestoreButton
@onready var _save_status_label: Label = %SaveStatusLabel
@onready var _bottom_panel: PanelContainer = $HUD/BottomPanel
@onready var _workshop_backdrop: Sprite2D = $Backdrop
@onready var _navigation_backdrop: Sprite2D = $NavigationBackdrop
@onready var _targets_root: Node2D = $Targets
@onready var _left_navigation_button: Button = %LeftNavigationButton
@onready var _right_navigation_button: Button = %RightNavigationButton
@onready var _forward_navigation_button: Button = %ForwardNavigationButton
@onready var _backward_navigation_button: Button = %BackwardNavigationButton
@onready var _workshop_left_exit_hotspot: Button = %WorkshopLeftExitHotspot
@onready var _workshop_right_exit_hotspot: Button = %WorkshopRightExitHotspot
@onready var _left_room_exit_hotspot: Button = %LeftRoomExitHotspot
@onready var _right_room_exit_hotspot: Button = %RightRoomExitHotspot
@onready var _forward_room_exit_hotspot: Button = %ForwardRoomExitHotspot
@onready var _backward_room_exit_hotspot: Button = %BackwardRoomExitHotspot
@onready var _porthole: SurfaceTapTarget = $Targets/Porthole
@onready var _panel: SurfaceTapTarget = $Targets/Panel
@onready var _cabinet: SurfaceTapTarget = $Targets/Cabinet
@onready var _technician: SurfaceTapTarget = $Targets/Technician
@onready var _flask: SurfaceTapTarget = $Targets/Flask
@onready var _table: SurfaceTapTarget = $Targets/Table
@onready var _metal_clip: SurfaceTapTarget = $Targets/MetalClip
@onready var _context_menu: PanelContainer = %ContextMenu
@onready var _context_action_button: Button = %ContextActionButton
@onready var _context_secondary_action_button: Button = %ContextSecondaryActionButton
@onready var _inventory_panel: PanelContainer = %InventoryPanel
@onready var _inventory_flask_slot: Button = %InventoryFlaskSlot
@onready var _inventory_clip_slot: Button = %InventoryClipSlot
@onready var _notebook_button: Button = %NotebookButton
@onready var _notebook_overlay: Control = %NotebookOverlay
@onready var _notebook_count: Label = %NotebookCount
@onready var _notebook_entries: VBoxContainer = %NotebookEntries
@onready var _close_notebook_button: Button = %CloseNotebookButton
@onready var _notebook_entry_title: Label = %NotebookEntryTitle
@onready var _notebook_entry_source: Label = %NotebookEntrySource
@onready var _notebook_entry_text: Label = %NotebookEntryText
@onready var _notebook_action_hint: Label = %NotebookActionHint
@onready var _notebook_link_button: Button = %NotebookLinkButton
@onready var _notebook_cancel_link_button: Button = %NotebookCancelLinkButton
@onready var _notebook_formulate_button: Button = %NotebookFormulateButton
@onready var _notebook_formulation_panel: VBoxContainer = %NotebookFormulationPanel
@onready var _formulation_subject: OptionButton = %FormulationSubject
@onready var _formulation_action: OptionButton = %FormulationAction
@onready var _formulation_object: OptionButton = %FormulationObject
@onready var _formulation_preview: Label = %FormulationPreview
@onready var _formulation_feedback: Label = %FormulationFeedback
@onready var _submit_formulation_button: Button = %SubmitFormulationButton
@onready var _cancel_formulation_button: Button = %CancelFormulationButton
@onready var _dialogue_overlay: Control = %DialogueOverlay
@onready var _dialogue_panel: PanelContainer = $HUD/DialogueOverlay/DialoguePanel
@onready var _dialogue_history_button: Button = %DialogueHistoryButton
@onready var _dialogue_history_overlay: Control = %DialogueHistoryOverlay
@onready var _dialogue_history_entries: VBoxContainer = %DialogueHistoryEntries
@onready var _dialogue_history_scroll: ScrollContainer = %DialogueHistoryScroll
@onready var _dialogue_history_count: Label = %DialogueHistoryCount
@onready var _dialogue_history_empty: Label = %DialogueHistoryEmpty
@onready var _dialogue_speaker: Label = %DialogueSpeaker
@onready var _dialogue_progress: Label = %DialogueProgress
@onready var _dialogue_typewriter_button: Button = %DialogueTypewriterButton
@onready var _dialogue_line: Label = %DialogueLine
@onready var _dialogue_choices: VBoxContainer = %DialogueChoices
@onready var _dialogue_footer: HBoxContainer = %DialogueFooter
@onready var _dialogue_continue_button: Button = %DialogueContinueButton
@onready var _dialogue_choice_buttons: Array[Button] = [
	%DialogueChoiceButtonOne as Button,
	%DialogueChoiceButtonTwo as Button,
	%DialogueChoiceButtonThree as Button,
	%DialogueChoiceButtonFour as Button,
	%DialogueChoiceButtonFive as Button,
]
@onready var _show_evidence_button: Button = %ShowEvidenceButton
@onready var _inspection_overlay: Control = %InspectionOverlay
@onready var _inspection_flask: TextureRect = %InspectionFlask
@onready var _inspection_detail_name: Label = %InspectionDetailName
@onready var _inspection_detail_text: Label = %InspectionDetailText
@onready var _cap_hotspot: Button = %CapHotspot
@onready var _liquid_hotspot: Button = %LiquidHotspot
@onready var _router: SurfaceTapRouter = $SurfaceTapRouter

var _cabinet_is_open := false
var _panel_is_repaired := false
var _flask_is_collected := false
var _flask_is_modified := false
var _flask_is_on_table := false
var _clip_is_collected := false
var _selected_inventory_item := ""
var _context_target: SurfaceTapTarget
var _information_entries: Array[Dictionary] = []
var _dialogue_history: Array[Dictionary] = []
var _dialogue_line_index := -1
var _dialogue_phase := ""
var _dialogue_typewriter_enabled := true
var _dialogue_reveal_text := ""
var _dialogue_reveal_characters := 0
var _dialogue_reveal_elapsed := 0.0
var _dialogue_continue_text := "CONTINUA"
var _asked_technician_topics: Dictionary = {}
var _newly_unlocked_technician_topics: Dictionary = {}
var _shown_technician_evidence: Dictionary = {}
var _notebook_evidence_mode := false
var _notebook_link_mode := false
var _notebook_formulation_mode := false
var _selected_clue_ids: Array[String] = []
var _used_clue_links: Dictionary = {}
var _clue_link_feedback := ""
var _selected_notebook_entry_id := ""
var _current_room := "workshop"
var _workshop_status_text := "NESSUN OGGETTO SELEZIONATO"
var _workshop_feedback_text := "Tasto sinistro: esamina e ascolta. Tasto destro: azioni su armadio, ampolla e fascetta."
var _flask_default_position := Vector2(560, 363)
var _restore_confirmation_dialog: ConfirmationDialog

const WORKSHOP_TOP_HINT := "SINISTRO: ESAMINA • DESTRO: AZIONI • MARGINI: CAMBIA STANZA"
const NAVIGATION_TOP_HINT := "CLICCA LA PORTA O USA IL PULSANTE DIREZIONALE"
const FLASK_TABLE_OFFSET := Vector2(0, -50)
const ITEM_FLASK := "flask"
const ITEM_CLIP := "clip"
const DIALOGUE_TYPEWRITER_CHARACTERS_PER_SECOND := 38.0
const SAVE_FILE_PATH := "user://playground_save.json"
const SAVE_FILE_VERSION := 2
const OPEN_CABINET_TEXTURE := preload("res://tests/playground-concept/assets/metal_cabinet_open.svg")
const DEFAULT_FLASK_TEXTURE := preload("res://tests/playground-concept/assets/glass_flask.svg")
const MODIFIED_FLASK_TEXTURE := preload("res://tests/playground-concept/assets/glass_flask_clamped.svg")
const REPAIRED_PANEL_TEXTURE := preload("res://tests/playground-concept/assets/wall_service_panel_repaired.svg")
const ROOM_WORKSHOP := "workshop"
const ROOM_LEFT := "left"
const ROOM_RIGHT := "right"
const ROOM_FORWARD := "forward"
const ROOM_BACKWARD := "backward"
const LEFT_ROOM_TEXTURE := preload("res://tests/playground-concept/assets/left_side_room_backdrop.svg")
const RIGHT_ROOM_TEXTURE := preload("res://tests/playground-concept/assets/right_side_room_backdrop.svg")
const FORWARD_ROOM_TEXTURE := preload("res://tests/playground-concept/assets/forward_corridor_backdrop.svg")
const BACKWARD_ROOM_TEXTURE := preload("res://tests/playground-concept/assets/rear_entry_backdrop.svg")
const TECHNICIAN_DIALOGUE := [
	{
		"speaker": "TECNICO (POC)",
		"text": "Hai notato la spia verde sul pannello?",
	},
	{
		"speaker": "TECNICO (POC)",
		"text": "Che cosa ne pensi?",
	},
]
const TECHNICIAN_CHOICES := [
	{
		"label": "Sì. La spia verde è ancora accesa.",
		"response": "Anch'io l'ho notato. Non so ancora cosa segnali.",
	},
	{
		"label": "Non ho ancora controllato il pannello.",
		"response": "Allora puoi dare un'occhiata al pannello sulla parete.",
	},
]
const TECHNICIAN_TOPICS := [
	{
		"id": "service_light",
		"label": "La spia verde",
		"response": "La spia era già verde al mio arrivo. Non so cosa indichi.",
		"information_id": "technician_service_light",
	},
	{
		"id": "cabinet",
		"label": "L'armadio metallico",
		"response_open": "Sembra vuoto. Non saprei dire se fosse così anche prima.",
		"response_closed": "Non l'ho mai aperto. Non so cosa contenga.",
		"information_id": "technician_cabinet",
	},
	{
		"id": "flask",
		"label": "L'ampolla con il liquido verde",
		"unlock_information_id": "deduction_flask",
		"response": "Non saprei. Non ho esaminato l'ampolla.",
		"information_id": "technician_flask",
	},
]
const INFORMATION_CATALOG := {
	"porthole": {
		"title": "Un pianeta oltre l'oblò",
		"source": "OBLÒ",
		"text": "Oltre il vetro spesso si vede un piccolo pianeta circondato da stelle.",
	},
	"service_light": {
		"title": "La spia verde è accesa",
		"source": "PANNELLO A PARETE",
		"text": "Una spia verde resta accesa accanto alla fila di indicatori del pannello.",
	},
	"panel_bridge_missing": {
		"title": "Manca il ponte del circuito",
		"source": "PANNELLO A PARETE",
		"text": "Nel pannello c'è un contatto ausiliario vuoto. Il fermo elettrico dell'armadio potrebbe dipendere da questo circuito.",
	},
	"panel_bridge_repaired": {
		"title": "Ponte del circuito ripristinato",
		"source": "PANNELLO A PARETE",
		"text": "La fascetta metallica collega i due contatti ausiliari. Il circuito è chiuso e il fermo elettrico dell'armadio ha ripreso ad alimentarsi.",
	},
	"cabinet": {
		"title": "L'armadio è vuoto",
		"source": "ARMADIO METALLICO",
		"text": "Dietro le ante aperte si vedono ripiani spogli, senza oggetti da raccogliere.",
	},
	"flask_cap": {
		"title": "Il tappo dell'ampolla",
		"source": "AMPOLLA DI VETRO",
		"text": "Un tappo chiaro chiude il collo dell'ampolla.",
	},
	"flask_liquid": {
		"title": "Il liquido verde",
		"source": "AMPOLLA DI VETRO",
		"text": "Una piccola quantità di liquido verde si raccoglie sul fondo.",
	},
	"technician_service_light": {
		"title": "Il tecnico e la spia verde",
		"source": "TECNICO (POC)",
		"text": "La spia era già verde al suo arrivo; non sa cosa indichi.",
	},
	"technician_cabinet": {
		"title": "Il tecnico e l'armadio",
		"source": "TECNICO (POC)",
		"text": "Il tecnico non sa cosa contenga l'armadio.",
	},
	"technician_flask": {
		"title": "Il tecnico e l'ampolla",
		"source": "TECNICO (POC)",
		"text": "Il tecnico dice di non aver esaminato l'ampolla.",
	},
	"deduction_service_light": {
		"title": "La spia era già accesa all'arrivo",
		"source": "COLLEGAMENTO DI INDIZI",
		"text": "Il pannello mostra una spia verde; il tecnico riferisce di averla trovata già accesa al suo arrivo.",
	},
	"deduction_cabinet": {
		"title": "L'armadio è vuoto, il passato è incerto",
		"source": "COLLEGAMENTO DI INDIZI",
		"text": "I ripiani sono vuoti al momento dell'esame. Il tecnico non sa dire cosa contenesse prima.",
	},
	"deduction_flask": {
		"title": "Ampolla chiusa con liquido verde",
		"source": "COLLEGAMENTO DI INDIZI",
		"text": "Il tappo chiaro chiude l'ampolla che contiene una piccola quantità di liquido verde.",
	},
	"formulation_service_light": {
		"title": "Ricostruzione: la spia era già accesa",
		"source": "IPOTESI FORMULATA (POC)",
		"text": "La ricostruzione collega ciò che mostra il pannello alla testimonianza del tecnico: la spia verde era già accesa al suo arrivo.",
	},
}
const CLUE_LINK_RULES := {
	"service_light|technician_service_light": "deduction_service_light",
	"cabinet|technician_cabinet": "deduction_cabinet",
	"flask_cap|flask_liquid": "deduction_flask",
}
const REQUIRED_FORMULATION_INFORMATION := ["service_light", "technician_service_light"]

func _ready() -> void:
	_flask_default_position = _flask.position
	_restore_confirmation_dialog = ConfirmationDialog.new()
	_restore_confirmation_dialog.title = "Ripristina sessione"
	_restore_confirmation_dialog.dialog_text = "Il ripristino sostituirà i progressi correnti del playground. Continuare?"
	_restore_confirmation_dialog.ok_button_text = "RIPRISTINA"
	_restore_confirmation_dialog.cancel_button_text = "ANNULLA"
	add_child(_restore_confirmation_dialog)
	_restore_confirmation_dialog.confirmed.connect(_restore_game_state)
	_save_button.pressed.connect(_save_game_state)
	_restore_button.pressed.connect(_request_restore_game_state)
	_router.context_requested.connect(_on_context_requested)
	_context_action_button.pressed.connect(_on_context_action_pressed)
	_context_secondary_action_button.pressed.connect(_on_context_secondary_action_pressed)
	_inventory_flask_slot.pressed.connect(_on_inventory_slot_pressed.bind(ITEM_FLASK))
	_inventory_clip_slot.pressed.connect(_on_inventory_slot_pressed.bind(ITEM_CLIP))
	_notebook_button.pressed.connect(_open_notebook)
	_close_notebook_button.pressed.connect(_close_notebook)
	_notebook_link_button.pressed.connect(_on_notebook_link_button_pressed)
	_notebook_cancel_link_button.pressed.connect(_cancel_notebook_link_mode)
	_notebook_formulate_button.pressed.connect(_open_notebook_formulation)
	_formulation_subject.item_selected.connect(_on_formulation_option_changed)
	_formulation_action.item_selected.connect(_on_formulation_option_changed)
	_formulation_object.item_selected.connect(_on_formulation_option_changed)
	_submit_formulation_button.pressed.connect(_submit_formulation)
	_cancel_formulation_button.pressed.connect(_cancel_notebook_formulation)
	_initialize_formulation_options()
	_left_navigation_button.pressed.connect(_on_navigation_pressed.bind("left"))
	_right_navigation_button.pressed.connect(_on_navigation_pressed.bind("right"))
	_forward_navigation_button.pressed.connect(_on_navigation_pressed.bind("forward"))
	_backward_navigation_button.pressed.connect(_on_navigation_pressed.bind("backward"))
	_workshop_left_exit_hotspot.pressed.connect(_on_navigation_pressed.bind("left"))
	_workshop_right_exit_hotspot.pressed.connect(_on_navigation_pressed.bind("right"))
	_left_room_exit_hotspot.pressed.connect(_on_navigation_pressed.bind("right"))
	_right_room_exit_hotspot.pressed.connect(_on_navigation_pressed.bind("left"))
	_forward_room_exit_hotspot.pressed.connect(_on_navigation_pressed.bind("backward"))
	_backward_room_exit_hotspot.pressed.connect(_on_navigation_pressed.bind("forward"))
	_dialogue_continue_button.pressed.connect(_advance_dialogue)
	_dialogue_typewriter_button.pressed.connect(_toggle_dialogue_typewriter)
	_dialogue_history_button.pressed.connect(_open_dialogue_history)
	%CloseDialogueHistoryButton.pressed.connect(_close_dialogue_history)
	_dialogue_choice_buttons[0].pressed.connect(_on_dialogue_choice_selected.bind(0))
	_dialogue_choice_buttons[1].pressed.connect(_on_dialogue_choice_selected.bind(1))
	for choice_index in range(TECHNICIAN_CHOICES.size()):
		_dialogue_choice_buttons[choice_index].text = str(
			TECHNICIAN_CHOICES[choice_index].get("label", "")
		)
	_dialogue_choice_buttons[2].pressed.connect(_on_dialogue_choice_selected.bind(2))
	_dialogue_choice_buttons[3].pressed.connect(_on_dialogue_choice_selected.bind(3))
	_dialogue_choice_buttons[4].pressed.connect(_on_dialogue_choice_selected.bind(4))
	_show_evidence_button.pressed.connect(_show_selected_evidence_to_technician)
	%CloseInspectionButton.pressed.connect(_close_flask_inspection)
	_cap_hotspot.pressed.connect(_select_flask_detail.bind("TAPPO"))
	_liquid_hotspot.pressed.connect(_select_flask_detail.bind("LIQUIDO"))
	_context_menu.size = _context_menu.get_combined_minimum_size()
	_update_notebook_count()
	_update_dialogue_history_count()
	_update_dialogue_typewriter_button()
	_update_navigation_controls()
	_update_restore_button()

	for target in $Targets.get_children():
		if target is SurfaceTapTarget:
			target.tapped.connect(_on_target_tapped)


func _save_game_state() -> void:
	if _current_room == ROOM_WORKSHOP:
		_workshop_status_text = _status.text
		_workshop_feedback_text = _feedback.text

	var save_data := {
		"version": SAVE_FILE_VERSION,
		"current_room": _current_room,
		"cabinet_is_open": _cabinet_is_open,
		"panel_is_repaired": _panel_is_repaired,
		"flask_is_collected": _flask_is_collected,
		"flask_is_modified": _flask_is_modified,
		"flask_is_on_table": _flask_is_on_table,
		"clip_is_collected": _clip_is_collected,
		"information_entries": _information_entries,
		"dialogue_history": _dialogue_history,
		"asked_topics": _dictionary_keys(_asked_technician_topics),
		"shown_evidence": _dictionary_keys(_shown_technician_evidence),
		"used_clue_links": _dictionary_keys(_used_clue_links),
		"workshop_status_text": _workshop_status_text,
		"workshop_feedback_text": _workshop_feedback_text,
		"dialogue_typewriter_enabled": _dialogue_typewriter_enabled,
	}
	var save_file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		_save_status_label.text = "ERRORE: SALVATAGGIO NON RIUSCITO"
		return

	save_file.store_string(JSON.stringify(save_data, "\t"))
	var write_error := save_file.get_error()
	save_file.close()
	if write_error != OK:
		_save_status_label.text = "ERRORE: SALVATAGGIO NON RIUSCITO"
		return
	_save_status_label.text = "SALVATAGGIO COMPLETATO"
	_update_restore_button()


func _request_restore_game_state() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		_save_status_label.text = "NESSUN SALVATAGGIO DISPONIBILE"
		_update_restore_button()
		return
	_restore_confirmation_dialog.popup_centered()


func _restore_game_state() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		_save_status_label.text = "NESSUN SALVATAGGIO DISPONIBILE"
		_update_restore_button()
		return

	var save_file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file == null:
		_save_status_label.text = "ERRORE: SALVATAGGIO ILLEGGIBILE"
		return
	var parsed_data: Variant = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	if typeof(parsed_data) != TYPE_DICTIONARY:
		_save_status_label.text = "ERRORE: SALVATAGGIO NON VALIDO"
		return

	var save_data: Dictionary = parsed_data
	var save_version := int(save_data.get("version", -1))
	if save_version < 1 or save_version > SAVE_FILE_VERSION:
		_save_status_label.text = "ERRORE: VERSIONE SALVATAGGIO NON SUPPORTATA"
		return

	var restored_room := str(save_data.get("current_room", ""))
	if not (
		restored_room in [ROOM_WORKSHOP, ROOM_LEFT, ROOM_RIGHT, ROOM_FORWARD, ROOM_BACKWARD]
	):
		_save_status_label.text = "ERRORE: STANZA SALVATA NON VALIDA"
		return

	_current_room = restored_room
	_cabinet_is_open = bool(save_data.get("cabinet_is_open", false))
	_panel_is_repaired = bool(save_data.get("panel_is_repaired", false))
	_flask_is_collected = bool(save_data.get("flask_is_collected", false))
	_flask_is_modified = bool(save_data.get("flask_is_modified", false))
	_flask_is_on_table = bool(save_data.get("flask_is_on_table", false)) and not _flask_is_collected
	_clip_is_collected = bool(save_data.get("clip_is_collected", false))
	_workshop_status_text = str(
		save_data.get("workshop_status_text", "NESSUN OGGETTO SELEZIONATO")
	)
	_workshop_feedback_text = str(
		save_data.get(
			"workshop_feedback_text",
			"Tasto sinistro: esamina e ascolta. Tasto destro: azioni su armadio, ampolla e fascetta.",
		)
	)
	_dialogue_typewriter_enabled = bool(save_data.get("dialogue_typewriter_enabled", true))

	var known_topic_ids: Array[String] = []
	for topic in TECHNICIAN_TOPICS:
		known_topic_ids.append(str(topic.get("id", "")))
	_asked_technician_topics = _dictionary_from_saved_keys(
		save_data.get("asked_topics", []), known_topic_ids
	)
	_shown_technician_evidence = _dictionary_from_saved_keys(
		save_data.get("shown_evidence", []), INFORMATION_CATALOG.keys()
	)
	_used_clue_links = _dictionary_from_saved_keys(
		save_data.get("used_clue_links", []), CLUE_LINK_RULES.keys()
	)
	_restore_information_entries(save_data.get("information_entries", []))
	_rebuild_unlocked_technician_topics()
	_restore_dialogue_history(save_data.get("dialogue_history", []))

	_apply_restored_item_state()
	_reset_transient_interface_state()
	_update_notebook_count()
	_update_dialogue_history_count()
	_update_dialogue_typewriter_button()
	_show_current_room()
	_save_status_label.text = "SESSIONE RIPRISTINATA"
	_update_restore_button()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _dictionary_keys(source: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in source.keys():
		keys.append(str(key))
	return keys


func _dictionary_from_saved_keys(saved_keys: Variant, allowed_keys: Array) -> Dictionary:
	var restored: Dictionary = {}
	if not saved_keys is Array:
		return restored
	for saved_key in saved_keys:
		var key := str(saved_key)
		if allowed_keys.has(key):
			restored[key] = true
	return restored


func _rebuild_unlocked_technician_topics() -> void:
	_newly_unlocked_technician_topics.clear()
	for topic in TECHNICIAN_TOPICS:
		var unlock_information_id := str(topic.get("unlock_information_id", ""))
		var topic_id := str(topic.get("id", ""))
		if (
			not unlock_information_id.is_empty()
			and _information_entry_index(unlock_information_id) >= 0
			and not _asked_technician_topics.has(topic_id)
		):
			_newly_unlocked_technician_topics[topic_id] = true


func _restore_information_entries(saved_entries: Variant) -> void:
	_information_entries.clear()
	if not saved_entries is Array:
		return
	for saved_entry in saved_entries:
		if typeof(saved_entry) != TYPE_DICTIONARY:
			continue
		var saved_entry_data: Dictionary = saved_entry
		var entry_id := str(saved_entry_data.get("id", ""))
		if not INFORMATION_CATALOG.has(entry_id):
			continue
		var entry: Dictionary = INFORMATION_CATALOG[entry_id].duplicate()
		entry["id"] = entry_id
		var saved_text := str(saved_entry_data.get("text", ""))
		if not saved_text.is_empty():
			entry["text"] = saved_text
		_information_entries.append(entry)


func _restore_dialogue_history(saved_entries: Variant) -> void:
	_dialogue_history.clear()
	if not saved_entries is Array:
		return
	for saved_entry in saved_entries:
		if typeof(saved_entry) != TYPE_DICTIONARY:
			continue
		var speaker := str(saved_entry.get("speaker", "")).strip_edges()
		var text := str(saved_entry.get("text", "")).strip_edges()
		if not speaker.is_empty() and not text.is_empty():
			_dialogue_history.append({"speaker": speaker, "text": text})


func _apply_restored_item_state() -> void:
	_panel.texture = REPAIRED_PANEL_TEXTURE if _panel_is_repaired else preload("res://tests/playground-concept/assets/wall_service_panel.svg")
	_panel.examine_description = (
		"La fascetta metallica collega i due contatti ausiliari. La spia verde è stabile e il circuito alimenta il fermo dell'armadio."
		if _panel_is_repaired
		else "La spia verde è accesa, ma nel pannello manca un ponte metallico tra i contatti ausiliari."
	)
	_cabinet.texture = (
		OPEN_CABINET_TEXTURE
		if _cabinet_is_open
		else preload("res://tests/playground-concept/assets/metal_cabinet.svg")
	)
	if _cabinet_is_open:
		_cabinet.examine_description = "Le ante sono aperte e lasciano vedere l'interno dell'armadio."
	elif _panel_is_repaired:
		_cabinet.examine_description = "Le due ante sono chiuse dal fermo elettrico. Ora che il circuito è alimentato, il fermo dovrebbe cedere."
	else:
		_cabinet.examine_description = "Le due ante sono chiuse dal fermo elettrico. Il pannello a parete potrebbe alimentarne il circuito."

	_flask.texture = MODIFIED_FLASK_TEXTURE if _flask_is_modified else DEFAULT_FLASK_TEXTURE
	_flask.target_name = "Ampolla con fascetta" if _flask_is_modified else "Ampolla di vetro"
	_flask.examine_description = (
		"La fascetta metallica tiene salda l'ampolla e protegge il vetro da urti laterali."
		if _flask_is_modified
		else "Sul fondo dell'ampolla resta del liquido verde."
	)
	_flask.position = _table.position + FLASK_TABLE_OFFSET if _flask_is_on_table else _flask_default_position
	_flask.visible = not _flask_is_collected
	_metal_clip.visible = not _clip_is_collected and not _panel_is_repaired

	_selected_inventory_item = ""
	_inventory_flask_slot.button_pressed = false
	_inventory_clip_slot.button_pressed = false
	_inventory_flask_slot.visible = _flask_is_collected
	_inventory_clip_slot.visible = _clip_is_collected
	_inventory_panel.visible = _flask_is_collected or _clip_is_collected
	_update_flask_inventory_slot()


func _reset_transient_interface_state() -> void:
	_context_menu.hide()
	_context_target = null
	_notebook_overlay.hide()
	_dialogue_overlay.hide()
	_dialogue_history_overlay.hide()
	_inspection_overlay.hide()
	_notebook_evidence_mode = false
	_notebook_link_mode = false
	_notebook_formulation_mode = false
	_selected_clue_ids.clear()
	_selected_notebook_entry_id = ""
	_clue_link_feedback = ""
	_dialogue_line_index = -1
	_dialogue_phase = ""
	_dialogue_reveal_text = ""
	_dialogue_reveal_characters = 0
	_dialogue_reveal_elapsed = 0.0
	_dialogue_choices.hide()
	_dialogue_footer.show()
	_dialogue_panel.offset_top = -252.0
	_bottom_panel.show()
	_router.clear_hover()


func _update_restore_button() -> void:
	var has_save := FileAccess.file_exists(SAVE_FILE_PATH)
	_restore_button.disabled = not has_save
	if (
		_save_status_label.text.is_empty()
		or _save_status_label.text == "NESSUN SALVATAGGIO"
	):
		_save_status_label.text = "SALVATAGGIO DISPONIBILE" if has_save else "NESSUN SALVATAGGIO"


func _on_navigation_pressed(direction: String) -> void:
	if (
		_dialogue_overlay.visible
		or _dialogue_history_overlay.visible
		or _notebook_overlay.visible
		or _inspection_overlay.visible
	):
		return

	var next_room := ""
	match _current_room:
		ROOM_WORKSHOP:
			match direction:
				"left":
					next_room = ROOM_LEFT
				"right":
					next_room = ROOM_RIGHT
				"forward":
					next_room = ROOM_FORWARD
				"backward":
					next_room = ROOM_BACKWARD
		ROOM_LEFT:
			if direction == "right":
				next_room = ROOM_WORKSHOP
		ROOM_RIGHT:
			if direction == "left":
				next_room = ROOM_WORKSHOP
		ROOM_FORWARD:
			if direction == "backward":
				next_room = ROOM_WORKSHOP
		ROOM_BACKWARD:
			if direction == "forward":
				next_room = ROOM_WORKSHOP

	if next_room.is_empty():
		return

	if not _selected_inventory_item.is_empty():
		_cancel_inventory_selection()
	if _current_room == ROOM_WORKSHOP:
		_workshop_status_text = _status.text
		_workshop_feedback_text = _feedback.text
	_context_menu.hide()
	_context_target = null
	_router.clear_hover()
	_current_room = next_room
	_show_current_room()


func _show_current_room() -> void:
	var is_workshop := _current_room == ROOM_WORKSHOP
	_workshop_backdrop.visible = is_workshop
	_targets_root.visible = is_workshop
	_navigation_backdrop.visible = not is_workshop
	_router.set_process_unhandled_input(is_workshop)
	if is_workshop:
		_top_title.text = "OFFICINA // TEST DI INTERAZIONE"
		_top_hint.text = WORKSHOP_TOP_HINT
		_status.text = _workshop_status_text
		_feedback.text = _workshop_feedback_text
	else:
		_top_hint.text = NAVIGATION_TOP_HINT
		match _current_room:
			ROOM_LEFT:
				_navigation_backdrop.texture = LEFT_ROOM_TEXTURE
				_top_title.text = "STANZA A SINISTRA // TEST DI NAVIGAZIONE"
				_status.text = "POSIZIONE  /  STANZA A SINISTRA"
				_feedback.text = "Ambiente laterale sinistro. Per tornare all'officina, esci verso destra."
			ROOM_RIGHT:
				_navigation_backdrop.texture = RIGHT_ROOM_TEXTURE
				_top_title.text = "STANZA A DESTRA // TEST DI NAVIGAZIONE"
				_status.text = "POSIZIONE  /  STANZA A DESTRA"
				_feedback.text = "Ambiente laterale destro. Per tornare all'officina, esci verso sinistra."
			ROOM_FORWARD:
				_navigation_backdrop.texture = FORWARD_ROOM_TEXTURE
				_top_title.text = "CORRIDOIO FRONTALE // TEST DI NAVIGAZIONE"
				_status.text = "POSIZIONE  /  CORRIDOIO FRONTALE"
				_feedback.text = "Il percorso prosegue in avanti. Puoi tornare all'officina procedendo indietro."
			ROOM_BACKWARD:
				_navigation_backdrop.texture = BACKWARD_ROOM_TEXTURE
				_top_title.text = "INGRESSO POSTERIORE // TEST DI NAVIGAZIONE"
				_status.text = "POSIZIONE  /  INGRESSO POSTERIORE"
				_feedback.text = "Sei tornato verso l'ingresso. Procedi avanti per rientrare nell'officina."
	_update_navigation_controls()


func _update_navigation_controls() -> void:
	_workshop_left_exit_hotspot.visible = _current_room == ROOM_WORKSHOP
	_workshop_right_exit_hotspot.visible = _current_room == ROOM_WORKSHOP
	_left_room_exit_hotspot.visible = _current_room == ROOM_LEFT
	_right_room_exit_hotspot.visible = _current_room == ROOM_RIGHT
	_forward_room_exit_hotspot.visible = _current_room == ROOM_FORWARD
	_backward_room_exit_hotspot.visible = _current_room == ROOM_BACKWARD
	_left_navigation_button.disabled = not (_current_room in [ROOM_WORKSHOP, ROOM_RIGHT])
	_right_navigation_button.disabled = not (_current_room in [ROOM_WORKSHOP, ROOM_LEFT])
	_forward_navigation_button.disabled = not (_current_room in [ROOM_WORKSHOP, ROOM_BACKWARD])
	_backward_navigation_button.disabled = not (_current_room in [ROOM_WORKSHOP, ROOM_FORWARD])
	_left_navigation_button.text = (
		"◀ SINISTRA · OFFICINA" if _current_room == ROOM_RIGHT else "◀ SINISTRA"
	)
	_right_navigation_button.text = (
		"DESTRA · OFFICINA ▶" if _current_room == ROOM_LEFT else "DESTRA ▶"
	)
	_forward_navigation_button.text = (
		"AVANTI · OFFICINA ▲" if _current_room == ROOM_BACKWARD else "AVANTI ▲"
	)
	_backward_navigation_button.text = (
		"INDIETRO · OFFICINA ▼" if _current_room == ROOM_FORWARD else "INDIETRO ▼"
	)


func _restore_room_hint() -> void:
	_top_hint.text = WORKSHOP_TOP_HINT if _current_room == ROOM_WORKSHOP else NAVIGATION_TOP_HINT


func _initialize_formulation_options() -> void:
	_formulation_subject.add_item("SCEGLI UNA PERSONA", 0)
	_formulation_subject.add_item("Il tecnico", 1)
	_formulation_subject.add_item("Una persona non identificata", 2)
	_formulation_action.add_item("SCEGLI UN FATTO", 0)
	_formulation_action.add_item("ha trovato già accesa", 1)
	_formulation_action.add_item("ha acceso", 2)
	_formulation_action.add_item("ha spento", 3)
	_formulation_action.add_item("ha esaminato", 4)
	_formulation_object.add_item("SCEGLI UN ELEMENTO", 0)
	_formulation_object.add_item("la spia verde", 1)
	_formulation_object.add_item("l'armadio metallico", 2)
	_formulation_object.add_item("l'ampolla", 3)
	_formulation_subject.select(0)
	_formulation_action.select(0)
	_formulation_object.select(0)
	_refresh_formulation_preview()


func _input(event: InputEvent) -> void:
	if _dialogue_history_overlay.visible:
		if event is InputEventKey:
			var history_key := event as InputEventKey
			if (
				history_key.pressed
				and not history_key.echo
				and history_key.keycode == KEY_ESCAPE
			):
				_close_dialogue_history()
				get_viewport().set_input_as_handled()
		return

	if _notebook_overlay.visible:
		if event is InputEventKey:
			var notebook_key := event as InputEventKey
			if (
				notebook_key.pressed
				and not notebook_key.echo
				and notebook_key.keycode == KEY_ESCAPE
			):
				_close_notebook()
				get_viewport().set_input_as_handled()
		return

	if _dialogue_overlay.visible:
		if event is InputEventKey:
			var dialogue_key := event as InputEventKey
			if (
				dialogue_key.pressed
				and not dialogue_key.echo
				and dialogue_key.keycode == KEY_ESCAPE
			):
				_finish_dialogue()
				get_viewport().set_input_as_handled()
		return

	if _inspection_overlay.visible:
		if event is InputEventKey:
			var inspection_key := event as InputEventKey
			if (
				inspection_key.pressed
				and not inspection_key.echo
				and inspection_key.keycode == KEY_ESCAPE
			):
				_close_flask_inspection()
				get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if _context_menu.visible:
				_context_menu.hide()
				_context_target = null
			if not _selected_inventory_item.is_empty():
				_cancel_inventory_selection()
			get_viewport().set_input_as_handled()
	elif (
		not _selected_inventory_item.is_empty()
		and event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		_cancel_inventory_selection()
		get_viewport().set_input_as_handled()
		return

	if not _context_menu.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		if not _context_menu.get_global_rect().has_point(event.position):
			_context_menu.hide()
			_context_target = null
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _is_dialogue_revealing():
		return

	_dialogue_reveal_elapsed += delta
	var visible_character_count := floori(
		_dialogue_reveal_elapsed * DIALOGUE_TYPEWRITER_CHARACTERS_PER_SECOND
	)
	_dialogue_reveal_characters = mini(visible_character_count, _dialogue_reveal_text.length())
	_dialogue_line.text = _dialogue_reveal_text.substr(0, _dialogue_reveal_characters)
	if not _is_dialogue_revealing():
		_dialogue_continue_button.text = _dialogue_continue_text


func _is_dialogue_revealing() -> bool:
	return _dialogue_reveal_characters < _dialogue_reveal_text.length()


func _set_dialogue_text(text: String, continue_text := "CONTINUA") -> void:
	_dialogue_reveal_text = text
	_dialogue_continue_text = continue_text
	_dialogue_reveal_elapsed = 0.0
	if _dialogue_typewriter_enabled and not text.is_empty():
		_dialogue_reveal_characters = 0
		_dialogue_line.text = ""
		_dialogue_continue_button.text = "COMPLETA"
		return

	_dialogue_reveal_characters = text.length()
	_dialogue_line.text = text
	_dialogue_continue_button.text = continue_text


func _complete_dialogue_reveal() -> void:
	_dialogue_reveal_characters = _dialogue_reveal_text.length()
	_dialogue_line.text = _dialogue_reveal_text
	_dialogue_continue_button.text = _dialogue_continue_text


func _toggle_dialogue_typewriter() -> void:
	_dialogue_typewriter_enabled = not _dialogue_typewriter_enabled
	_update_dialogue_typewriter_button()
	if not _dialogue_typewriter_enabled and _is_dialogue_revealing():
		_complete_dialogue_reveal()


func _update_dialogue_typewriter_button() -> void:
	_dialogue_typewriter_button.text = (
		"SCRITTURA: ON" if _dialogue_typewriter_enabled else "SCRITTURA: OFF"
	)


func _on_target_tapped(target: SurfaceTapTarget) -> void:
	if not _selected_inventory_item.is_empty():
		_use_inventory_item_on_target(target)
		return

	if target == _technician:
		_status.text = "INTERLOCUTORE  /  TECNICO (POC)"
		_feedback.text = "Una conversazione di prova è disponibile con il tasto destro."
		return

	var surface_material := str(target.get("surface_material"))
	var target_name := str(target.get("target_name"))
	_status.text = "%s  /  %s" % [surface_material.to_upper(), target_name.to_upper()]
	_feedback.text = str(target.get("examine_description"))
	if _record_target_information(target):
		_status.text = "NUOVA INFORMAZIONE  /  %s" % target_name.to_upper()


func _on_context_requested(target: SurfaceTapTarget, screen_position: Vector2) -> void:
	_context_secondary_action_button.hide()

	if target == _cabinet:
		if _cabinet_is_open:
			return
		_context_action_button.text = "APRI"
	elif target == _technician:
		_context_action_button.text = "PARLA"
	elif target == _flask:
		if _flask_is_collected:
			return
		_context_action_button.text = "OSSERVA DA VICINO"
		_context_secondary_action_button.text = "RACCOGLI"
		_context_secondary_action_button.show()
	elif target == _metal_clip:
		if _clip_is_collected:
			return
		_context_action_button.text = "RACCOGLI"
	else:
		return

	_context_target = target
	_context_menu.reset_size()
	_context_menu.size = _context_menu.get_combined_minimum_size()
	var viewport_size := get_viewport_rect().size
	var menu_size := _context_menu.size
	_context_menu.position = Vector2(
		clampf(screen_position.x, 0.0, viewport_size.x - menu_size.x),
		clampf(screen_position.y, 0.0, viewport_size.y - menu_size.y)
	)
	_context_menu.show()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_context_action_pressed() -> void:
	if _context_target == _cabinet:
		_open_cabinet()
	elif _context_target == _technician:
		_start_dialogue()
	elif _context_target == _flask:
		_open_flask_inspection()
	elif _context_target == _metal_clip:
		_collect_metal_clip()


func _on_context_secondary_action_pressed() -> void:
	if _context_target == _flask:
		_collect_flask()


func _open_cabinet() -> void:
	if _cabinet_is_open:
		return
	if not _panel_is_repaired:
		_status.text = "AZIONE BLOCCATA  /  SERRATURA ELETTRICA"
		_feedback.text = "Il fermo non cede. L'armadio non è alimentato: controlla il pannello a parete e il contatto vuoto."
		_context_menu.hide()
		_context_target = null
		return

	_cabinet_is_open = true
	_cabinet.texture = OPEN_CABINET_TEXTURE
	_cabinet.examine_description = "Le ante sono aperte e lasciano vedere l'interno dell'armadio."
	var information_added := _record_information("cabinet")
	_status.text = "NUOVA INFORMAZIONE  /  INTERNO ARMADIO" if information_added else "AZIONE  /  ARMADIO METALLICO"
	_feedback.text = "Hai aperto l'armadio e annotato i ripiani vuoti."
	_context_menu.hide()
	_context_target = null


func _open_flask_inspection() -> void:
	_context_menu.hide()
	_context_target = null
	_inspection_flask.texture = _flask.texture
	_inspection_detail_name.text = "SELEZIONA UN PARTICOLARE"
	_inspection_detail_text.text = "Passa sui riquadri per evidenziare i dettagli, poi clicca per osservarli."
	_cap_hotspot.button_pressed = false
	_liquid_hotspot.button_pressed = false
	_inspection_overlay.show()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _collect_flask() -> void:
	if _flask_is_collected:
		return

	_flask_is_collected = true
	_flask_is_on_table = false
	_flask.hide()
	_selected_inventory_item = ""
	_set_inventory_slot_pressed(ITEM_FLASK, false)
	_inventory_flask_slot.show()
	_update_flask_inventory_slot()
	_inventory_panel.show()
	_status.text = "OGGETTO RACCOLTO  /  %s" % _inventory_item_name(ITEM_FLASK).to_upper()
	_feedback.text = "Hai raccolto %s." % _inventory_item_name(ITEM_FLASK).to_lower()
	_context_menu.hide()
	_context_target = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _collect_metal_clip() -> void:
	if _clip_is_collected:
		return

	_clip_is_collected = true
	_metal_clip.hide()
	_selected_inventory_item = ""
	_set_inventory_slot_pressed(ITEM_CLIP, false)
	_inventory_clip_slot.show()
	_inventory_panel.show()
	_status.text = "OGGETTO RACCOLTO  /  FASCETTA METALLICA"
	_feedback.text = "Hai raccolto la fascetta. Puoi combinarla con l'ampolla oppure usarla sul pannello a parete."
	_context_menu.hide()
	_context_target = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_inventory_slot_pressed(item_id: String) -> void:
	if _selected_inventory_item.is_empty():
		_selected_inventory_item = item_id
		_set_inventory_slot_pressed(item_id, true)
		_show_selected_inventory_item(item_id)
		return

	if _selected_inventory_item == item_id:
		_set_inventory_slot_pressed(item_id, true)
		_status.text = "COMBINAZIONE NON VALIDA"
		_feedback.text = "Non puoi combinare un oggetto con sé stesso. Seleziona un altro oggetto."
		return

	_combine_inventory_items(_selected_inventory_item, item_id)


func _show_selected_inventory_item(item_id: String) -> void:
	_top_hint.text = "ALTRO OGGETTO: COMBINA • BERSAGLIO: USA • ESC/DESTRO: ANNULLA"
	_status.text = "SELEZIONATO  /  %s" % _inventory_item_name(item_id).to_upper()
	_feedback.text = _inventory_item_description(item_id)


func _cancel_inventory_selection() -> void:
	if _selected_inventory_item.is_empty():
		return

	var previous_item := _selected_inventory_item
	_selected_inventory_item = ""
	_set_inventory_slot_pressed(previous_item, false)
	_restore_room_hint()
	_status.text = "INVENTARIO  /  %s" % _inventory_item_name(previous_item).to_upper()
	_feedback.text = _inventory_item_description(previous_item)


func _combine_inventory_items(first_item: String, second_item: String) -> void:
	if (
		(first_item == ITEM_FLASK and second_item == ITEM_CLIP)
		or (first_item == ITEM_CLIP and second_item == ITEM_FLASK)
	):
		_flask_is_modified = true
		_flask.texture = MODIFIED_FLASK_TEXTURE
		_flask.target_name = "Ampolla con fascetta"
		_flask.examine_description = "La fascetta metallica tiene salda l'ampolla e protegge il vetro da urti laterali."
		_clip_is_collected = false
		_inventory_flask_slot.button_pressed = false
		_inventory_flask_slot.show()
		_update_flask_inventory_slot()
		_set_inventory_slot_pressed(ITEM_CLIP, false)
		_inventory_clip_slot.hide()
		_selected_inventory_item = ""
		_restore_room_hint()
		_status.text = "COMBINAZIONE  /  AMPOLLA CON FASCETTA"
		_feedback.text = "Hai fissato la fascetta metallica all'ampolla."
		return

	var first_name := _inventory_item_name(first_item)
	var second_name := _inventory_item_name(second_item)
	_set_inventory_slot_pressed(second_item, false)
	_set_inventory_slot_pressed(first_item, true)
	_status.text = "COMBINAZIONE NON RIUSCITA"
	_feedback.text = "%s e %s non si combinano. %s resta selezionato." % [
		first_name,
		second_name,
		first_name,
	]


func _set_inventory_slot_pressed(item_id: String, is_pressed: bool) -> void:
	if item_id == ITEM_FLASK:
		_inventory_flask_slot.button_pressed = is_pressed
	elif item_id == ITEM_CLIP:
		_inventory_clip_slot.button_pressed = is_pressed


func _inventory_item_name(item_id: String) -> String:
	if item_id == ITEM_FLASK:
		return _flask.target_name
	return _metal_clip.target_name


func _inventory_item_description(item_id: String) -> String:
	if item_id == ITEM_FLASK:
		return _flask.examine_description
	return _metal_clip.examine_description


func _update_flask_inventory_slot() -> void:
	_inventory_flask_slot.icon = _flask.texture
	_inventory_flask_slot.text = _flask.target_name.to_upper()


func _use_inventory_item_on_target(target: SurfaceTapTarget) -> void:
	if target == _panel and _selected_inventory_item == ITEM_CLIP:
		_repair_service_panel(false)
		return
	if target == _panel and _selected_inventory_item == ITEM_FLASK and _flask_is_modified:
		_repair_service_panel(true)
		return
	if _selected_inventory_item == ITEM_FLASK and target == _table:
		_place_flask_on_table()
		return

	var item_name := _inventory_item_name(_selected_inventory_item).to_lower()
	var target_name := str(target.get("target_name")).to_lower()
	_status.text = "NESSUN EFFETTO  /  %s" % target_name.to_upper()
	_feedback.text = "Non trovi un modo per usare %s su %s. Resta selezionato." % [
		item_name,
		target_name,
	]


func _repair_service_panel(clip_is_attached_to_flask: bool) -> void:
	if _panel_is_repaired:
		_status.text = "NESSUN EFFETTO  /  CIRCUITO GIÀ ATTIVO"
		_feedback.text = "Il ponte metallico è già al suo posto e il fermo dell'armadio è alimentato."
		return

	_panel_is_repaired = true
	_panel.texture = REPAIRED_PANEL_TEXTURE
	_panel.examine_description = "La fascetta metallica collega i due contatti ausiliari. La spia verde è stabile e il circuito alimenta il fermo dell'armadio."
	_cabinet.examine_description = "Le due ante sono chiuse dal fermo elettrico. Ora che il circuito è alimentato, il fermo dovrebbe cedere."
	_metal_clip.hide()
	_clip_is_collected = false
	_inventory_clip_slot.hide()
	_set_inventory_slot_pressed(ITEM_CLIP, false)
	if clip_is_attached_to_flask:
		_flask_is_modified = false
		_flask.texture = DEFAULT_FLASK_TEXTURE
		_flask.target_name = "Ampolla di vetro"
		_flask.examine_description = "Sul fondo dell'ampolla resta del liquido verde."
		_update_flask_inventory_slot()
		_inventory_flask_slot.show()
		_set_inventory_slot_pressed(ITEM_FLASK, false)
	_selected_inventory_item = ""
	_inventory_panel.visible = _flask_is_collected or _clip_is_collected
	_restore_room_hint()
	_record_information("panel_bridge_repaired")
	_status.text = "CIRCUITO RIPRISTINATO  /  FASCETTA INSTALLATA"
	_feedback.text = "La fascetta chiude il circuito e alimenta il fermo elettrico dell'armadio."


func _place_flask_on_table() -> void:
	_flask.position = _table.position + FLASK_TABLE_OFFSET
	_flask_is_on_table = true
	_flask.show()
	_flask_is_collected = false
	_selected_inventory_item = ""
	_set_inventory_slot_pressed(ITEM_FLASK, false)
	_inventory_flask_slot.hide()
	_inventory_panel.visible = _clip_is_collected
	_restore_room_hint()
	_status.text = "AZIONE  /  AMPOLLA SUL BANCO"
	_feedback.text = "Hai appoggiato l'ampolla sul banco da lavoro."


func _close_flask_inspection() -> void:
	_inspection_overlay.hide()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _select_flask_detail(detail_name: String) -> void:
	var selected_hotspot := _cap_hotspot if detail_name == "TAPPO" else _liquid_hotspot
	var other_hotspot := _liquid_hotspot if detail_name == "TAPPO" else _cap_hotspot
	selected_hotspot.button_pressed = true
	other_hotspot.button_pressed = false
	_inspection_detail_name.text = detail_name
	if detail_name == "TAPPO":
		_inspection_detail_text.text = "Il tappo chiaro chiude il collo dell'ampolla."
		_record_information("flask_cap")
	else:
		_inspection_detail_text.text = "Una piccola quantità di liquido verde si raccoglie sul fondo."
		_record_information("flask_liquid")


func _record_target_information(target: SurfaceTapTarget) -> bool:
	if target == _porthole:
		return _record_information("porthole")
	if target == _panel:
		var added_information := _record_information("service_light")
		if _panel_is_repaired:
			added_information = _record_information("panel_bridge_repaired") or added_information
		else:
			added_information = _record_information("panel_bridge_missing") or added_information
		return added_information
	if target == _cabinet and _cabinet_is_open:
		return _record_information("cabinet")
	return false


func _record_information(entry_id: String, replacement_text := "") -> bool:
	for existing_entry in _information_entries:
		if str(existing_entry.get("id", "")) == entry_id:
			return false
	if not INFORMATION_CATALOG.has(entry_id):
		return false

	var entry: Dictionary = INFORMATION_CATALOG[entry_id].duplicate()
	entry["id"] = entry_id
	if not replacement_text.is_empty():
		entry["text"] = replacement_text
	_information_entries.append(entry)
	_update_notebook_count()
	_flag_newly_unlocked_technician_topics(entry_id)
	return true


func _update_notebook_count() -> void:
	var entry_count := _information_entries.size()
	var information_label := "INFORMAZIONE" if entry_count == 1 else "INFORMAZIONI"
	_notebook_button.text = "TACCUINO  •  %02d" % entry_count
	_notebook_count.text = "%d %s" % [entry_count, information_label]


func _append_dialogue_history(speaker: String, text: String) -> void:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return
	_dialogue_history.append({"speaker": speaker, "text": clean_text})
	_update_dialogue_history_count()


func _update_dialogue_history_count() -> void:
	var entry_count := _dialogue_history.size()
	_dialogue_history_button.text = "CRONOLOGIA  •  %02d" % entry_count
	_dialogue_history_count.text = "%d VOCI" % entry_count


func _open_dialogue_history() -> void:
	_refresh_dialogue_history()
	_dialogue_history_overlay.show()
	var hud := _dialogue_history_overlay.get_parent()
	hud.move_child(_dialogue_history_overlay, hud.get_child_count() - 1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	await get_tree().process_frame
	_dialogue_history_scroll.scroll_vertical = int(_dialogue_history_scroll.get_v_scroll_bar().max_value)


func _close_dialogue_history() -> void:
	_dialogue_history_overlay.hide()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _refresh_dialogue_history() -> void:
	for child in _dialogue_history_entries.get_children():
		child.free()

	_dialogue_history_empty.visible = _dialogue_history.is_empty()
	_dialogue_history_scroll.visible = not _dialogue_history.is_empty()
	for entry_index in range(_dialogue_history.size()):
		var entry: Dictionary = _dialogue_history[entry_index]
		var entry_panel := PanelContainer.new()
		entry_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var entry_style := StyleBoxFlat.new()
		entry_style.bg_color = Color(0.035, 0.075, 0.11, 0.9)
		entry_style.border_width_left = 2
		entry_style.border_color = Color(0.25, 0.7, 0.65, 0.82)
		entry_style.set_corner_radius_all(3)
		entry_panel.add_theme_stylebox_override("panel", entry_style)
		_dialogue_history_entries.add_child(entry_panel)

		var margins := MarginContainer.new()
		margins.add_theme_constant_override("margin_left", 12)
		margins.add_theme_constant_override("margin_top", 10)
		margins.add_theme_constant_override("margin_right", 12)
		margins.add_theme_constant_override("margin_bottom", 10)
		entry_panel.add_child(margins)

		var entry_content := VBoxContainer.new()
		entry_content.add_theme_constant_override("separation", 5)
		margins.add_child(entry_content)

		var speaker_label := Label.new()
		var speaker := str(entry.get("speaker", ""))
		speaker_label.text = speaker
		var speaker_color := (
			Color(0.94, 0.79, 0.45, 1)
			if speaker == "GIOCATORE"
			else Color(0.52, 0.91, 0.79, 1)
		)
		speaker_label.add_theme_color_override("font_color", speaker_color)
		speaker_label.add_theme_font_size_override("font_size", 12)
		entry_content.add_child(speaker_label)

		var line_label := Label.new()
		line_label.text = str(entry.get("text", ""))
		line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_label.add_theme_color_override("font_color", Color(0.91, 0.93, 0.91, 1))
		line_label.add_theme_font_size_override("font_size", 15)
		entry_content.add_child(line_label)

		if entry_index < _dialogue_history.size() - 1:
			var separator := HSeparator.new()
			_dialogue_history_entries.add_child(separator)


func _flag_newly_unlocked_technician_topics(information_id: String) -> void:
	for topic in TECHNICIAN_TOPICS:
		if str(topic.get("unlock_information_id", "")) != information_id:
			continue
		var topic_id := str(topic.get("id", ""))
		if not _asked_technician_topics.has(topic_id):
			_newly_unlocked_technician_topics[topic_id] = true


func _available_technician_topics() -> Array[Dictionary]:
	var available_topics: Array[Dictionary] = []
	for topic in TECHNICIAN_TOPICS:
		var unlock_information_id := str(topic.get("unlock_information_id", ""))
		if unlock_information_id.is_empty() or _information_entry_index(unlock_information_id) >= 0:
			available_topics.append(topic)
	return available_topics


func _open_notebook() -> void:
	_notebook_evidence_mode = false
	_notebook_link_mode = false
	_notebook_formulation_mode = false
	_selected_clue_ids.clear()
	_clue_link_feedback = ""
	_close_notebook_button.text = "CHIUDI"
	_context_menu.hide()
	_context_target = null
	_refresh_notebook_entries()
	_notebook_overlay.show()
	var hud := _notebook_overlay.get_parent()
	hud.move_child(_notebook_overlay, hud.get_child_count() - 1)
	if _information_entries.is_empty():
		_notebook_entry_title.text = "NESSUNA INFORMAZIONE"
		_notebook_entry_source.text = "ESAMINA L'AMBIENTE PER COMINCIARE"
		_notebook_entry_text.text = "Le osservazioni più rilevanti verranno raccolte qui."
		_selected_notebook_entry_id = ""
		_show_evidence_button.hide()
		_update_notebook_action_buttons()
	else:
		_show_information_entry(0)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _close_notebook() -> void:
	_notebook_overlay.hide()
	_notebook_evidence_mode = false
	_notebook_link_mode = false
	_notebook_formulation_mode = false
	_selected_clue_ids.clear()
	_clue_link_feedback = ""
	_close_notebook_button.text = "CHIUDI"
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _refresh_notebook_entries() -> void:
	for child in _notebook_entries.get_children():
		child.queue_free()

	for index in range(_information_entries.size()):
		var entry: Dictionary = _information_entries[index]
		var entry_button := Button.new()
		entry_button.custom_minimum_size = Vector2(270, 44)
		entry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_button.focus_mode = Control.FOCUS_NONE
		entry_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		entry_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var entry_id := str(entry.get("id", ""))
		entry_button.text = "%s%02d  %s" % [
			"✓ " if _selected_clue_ids.has(entry_id) else "",
			index + 1,
			str(entry.get("title", "")),
		]
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.08, 0.29, 0.25, 1)
		normal_style.set_corner_radius_all(3)
		var hover_style := normal_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(0.12, 0.43, 0.34, 1)
		entry_button.add_theme_color_override("font_color", Color(0.91, 1, 0.95, 1))
		entry_button.add_theme_color_override("font_hover_color", Color.WHITE)
		entry_button.add_theme_stylebox_override("normal", normal_style)
		entry_button.add_theme_stylebox_override("hover", hover_style)
		entry_button.add_theme_stylebox_override("pressed", hover_style)
		entry_button.pressed.connect(_on_notebook_entry_pressed.bind(index))
		_notebook_entries.add_child(entry_button)


func _update_notebook_entry_selection_indicators() -> void:
	for index in range(min(_information_entries.size(), _notebook_entries.get_child_count())):
		var entry: Dictionary = _information_entries[index]
		var entry_button := _notebook_entries.get_child(index) as Button
		var entry_id := str(entry.get("id", ""))
		entry_button.text = "%s%02d  %s" % [
			"✓ " if _selected_clue_ids.has(entry_id) else "",
			index + 1,
			str(entry.get("title", "")),
		]


func _show_information_entry(index: int) -> void:
	if index < 0 or index >= _information_entries.size():
		return
	var entry: Dictionary = _information_entries[index]
	_selected_notebook_entry_id = str(entry.get("id", ""))
	_notebook_entry_title.text = str(entry.get("title", ""))
	_notebook_entry_source.text = "FONTE  /  %s" % str(entry.get("source", ""))
	_notebook_entry_text.text = str(entry.get("text", ""))
	_show_evidence_button.visible = _notebook_evidence_mode
	_show_evidence_button.disabled = _shown_technician_evidence.has(_selected_notebook_entry_id)
	_show_evidence_button.text = (
		"GIÀ MOSTRATA" if _show_evidence_button.disabled else "MOSTRA AL TECNICO"
	)
	_update_notebook_action_buttons()


func _on_notebook_entry_pressed(index: int) -> void:
	if index < 0 or index >= _information_entries.size():
		return
	if _notebook_formulation_mode:
		return
	if not _notebook_link_mode:
		_show_information_entry(index)
		return

	var entry_id := str(_information_entries[index].get("id", ""))
	if _selected_clue_ids.has(entry_id):
		_selected_clue_ids.erase(entry_id)
	elif _selected_clue_ids.size() < 2:
		_selected_clue_ids.append(entry_id)
	else:
		_clue_link_feedback = "Puoi selezionare solo due indizi. Deselezionane uno per cambiare coppia."
		_show_information_entry(index)
		return

	_clue_link_feedback = ""
	_update_notebook_entry_selection_indicators()
	_show_information_entry(index)


func _update_notebook_action_buttons() -> void:
	var show_entry_detail := not _notebook_formulation_mode
	_show_evidence_button.visible = (
		_notebook_evidence_mode and not _selected_notebook_entry_id.is_empty()
	)
	_notebook_link_button.visible = (
		show_entry_detail and not _notebook_evidence_mode
	)
	_notebook_cancel_link_button.visible = (
		show_entry_detail and not _notebook_evidence_mode and _notebook_link_mode
	)
	_notebook_action_hint.visible = (
		show_entry_detail and not _notebook_evidence_mode and _notebook_link_mode
	)
	_notebook_formulate_button.visible = (
		show_entry_detail and not _notebook_evidence_mode and not _notebook_link_mode
	)
	_notebook_formulation_panel.visible = (
		_notebook_formulation_mode and not _notebook_evidence_mode
	)
	_notebook_entry_title.visible = show_entry_detail
	_notebook_entry_source.visible = show_entry_detail
	_notebook_entry_text.visible = show_entry_detail

	if _notebook_evidence_mode or _notebook_formulation_mode:
		return

	if not _notebook_link_mode:
		_notebook_link_button.text = "COLLEGA DUE INDIZI"
		_notebook_link_button.disabled = _information_entries.size() < 2
		_notebook_formulate_button.disabled = _information_entries.is_empty()
		return

	var selection_count := _selected_clue_ids.size()
	_notebook_link_button.text = "COLLEGA INDIZI (%d/2)" % selection_count
	_notebook_link_button.disabled = selection_count != 2
	if selection_count == 2:
		var pair_key := _selected_clue_link_key()
		if _used_clue_links.has(pair_key):
			_notebook_link_button.text = "INDIZI GIÀ COLLEGATI"
			_notebook_link_button.disabled = true
			_notebook_action_hint.text = "Questa coppia è già stata collegata."
		elif not _clue_link_feedback.is_empty():
			_notebook_action_hint.text = _clue_link_feedback
		else:
			_notebook_action_hint.text = "Hai selezionato due indizi. Prova a collegarli."
	else:
		_notebook_action_hint.text = _clue_link_feedback
		if _notebook_action_hint.text.is_empty():
			_notebook_action_hint.text = "Seleziona due voci dall'elenco. (%d/2)" % selection_count


func _on_notebook_link_button_pressed() -> void:
	if not _notebook_link_mode:
		_notebook_link_mode = true
		_selected_clue_ids.clear()
		_clue_link_feedback = ""
		_update_notebook_action_buttons()
		return
	if _selected_clue_ids.size() != 2:
		return

	var pair_key := _selected_clue_link_key()
	if _used_clue_links.has(pair_key):
		return
	if not CLUE_LINK_RULES.has(pair_key):
		_clue_link_feedback = "Da questi indizi non emerge un collegamento in questa PoC. Scegline altri due."
		_selected_clue_ids.clear()
		_update_notebook_entry_selection_indicators()
		_show_information_entry(_information_entry_index(_selected_notebook_entry_id))
		return

	var deduction_id := str(CLUE_LINK_RULES[pair_key])
	if not _record_information(deduction_id):
		_clue_link_feedback = "Questo collegamento è già annotato."
		_used_clue_links[pair_key] = true
		_update_notebook_action_buttons()
		return

	_used_clue_links[pair_key] = true
	_notebook_link_mode = false
	_selected_clue_ids.clear()
	_clue_link_feedback = ""
	_refresh_notebook_entries()
	_show_information_entry(_information_entries.size() - 1)


func _cancel_notebook_link_mode() -> void:
	_notebook_link_mode = false
	_selected_clue_ids.clear()
	_clue_link_feedback = ""
	_update_notebook_entry_selection_indicators()
	if not _selected_notebook_entry_id.is_empty():
		_show_information_entry(_information_entry_index(_selected_notebook_entry_id))
	else:
		_update_notebook_action_buttons()


func _selected_clue_link_key() -> String:
	var sorted_ids := _selected_clue_ids.duplicate()
	sorted_ids.sort()
	return "%s|%s" % [sorted_ids[0], sorted_ids[1]] if sorted_ids.size() == 2 else ""


func _information_entry_index(entry_id: String) -> int:
	for index in range(_information_entries.size()):
		if str(_information_entries[index].get("id", "")) == entry_id:
			return index
	return -1


func _open_notebook_formulation() -> void:
	_notebook_formulation_mode = true
	_notebook_link_mode = false
	_selected_clue_ids.clear()
	_clue_link_feedback = ""
	_formulation_subject.select(0)
	_formulation_action.select(0)
	_formulation_object.select(0)
	_formulation_feedback.text = ""
	_refresh_formulation_preview()
	_update_notebook_action_buttons()


func _cancel_notebook_formulation() -> void:
	_notebook_formulation_mode = false
	_formulation_feedback.text = ""
	if not _selected_notebook_entry_id.is_empty():
		_show_information_entry(_information_entry_index(_selected_notebook_entry_id))
	else:
		_update_notebook_action_buttons()


func _on_formulation_option_changed(_selected_index: int) -> void:
	_formulation_feedback.text = ""
	_refresh_formulation_preview()


func _refresh_formulation_preview() -> void:
	if (
		_formulation_subject.get_selected_id() == 0
		or _formulation_action.get_selected_id() == 0
		or _formulation_object.get_selected_id() == 0
	):
		_formulation_preview.text = "Completa le tre parti della ricostruzione."
		return
	_formulation_preview.text = "%s %s %s." % [
		_formulation_subject.get_item_text(_formulation_subject.selected),
		_formulation_action.get_item_text(_formulation_action.selected),
		_formulation_object.get_item_text(_formulation_object.selected),
	]


func _submit_formulation() -> void:
	if not _notebook_formulation_mode:
		return
	if (
		_formulation_subject.get_selected_id() == 0
		or _formulation_action.get_selected_id() == 0
		or _formulation_object.get_selected_id() == 0
	):
		_formulation_feedback.text = "Scegli una persona, un fatto e un elemento."
		return

	var is_supported_reconstruction := (
		_formulation_subject.get_selected_id() == 1
		and _formulation_action.get_selected_id() == 1
		and _formulation_object.get_selected_id() == 1
	)
	if not is_supported_reconstruction:
		_formulation_feedback.text = "Questa ricostruzione non trova riscontro nelle informazioni raccolte."
		return

	for required_entry_id in REQUIRED_FORMULATION_INFORMATION:
		if _information_entry_index(str(required_entry_id)) == -1:
			_formulation_feedback.text = "Mancano riscontri nel taccuino per sostenere questa ricostruzione."
			return

	if not _record_information("formulation_service_light"):
		_formulation_feedback.text = "Hai già annotato questa ricostruzione."
		return

	_notebook_formulation_mode = false
	_refresh_notebook_entries()
	_show_information_entry(_information_entries.size() - 1)


func _start_dialogue() -> void:
	_context_menu.hide()
	_context_target = null
	_dialogue_line_index = -1
	_dialogue_phase = "opening"
	_dialogue_reveal_text = ""
	_dialogue_reveal_characters = 0
	_dialogue_reveal_elapsed = 0.0
	_dialogue_panel.offset_top = -252.0
	_dialogue_choices.hide()
	_dialogue_footer.show()
	_status.text = "DIALOGO  /  TECNICO (POC)"
	_bottom_panel.hide()
	_dialogue_overlay.show()
	_advance_dialogue()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _advance_dialogue() -> void:
	if _is_dialogue_revealing():
		_complete_dialogue_reveal()
		return

	if (
		_dialogue_phase == "response_choice_result"
		or _dialogue_phase == "topic_response"
		or _dialogue_phase == "evidence_response"
	):
		_show_interrogation_topics()
		return

	if _dialogue_phase != "opening":
		return

	if _dialogue_line_index >= TECHNICIAN_DIALOGUE.size() - 1:
		_show_initial_response_choices()
		return

	_dialogue_line_index += 1
	var line: Dictionary = TECHNICIAN_DIALOGUE[_dialogue_line_index]
	_dialogue_speaker.text = str(line.get("speaker", ""))
	_dialogue_progress.text = "%02d / %02d" % [
		_dialogue_line_index + 1,
		TECHNICIAN_DIALOGUE.size(),
	]
	var dialogue_text := str(line.get("text", ""))
	_set_dialogue_text(dialogue_text)
	_append_dialogue_history(_dialogue_speaker.text, dialogue_text)


func _show_initial_response_choices() -> void:
	_dialogue_phase = "response_choices"
	_dialogue_panel.offset_top = -252.0
	_dialogue_progress.text = "SCELTA"
	_dialogue_choice_buttons[0].text = str(TECHNICIAN_CHOICES[0].get("label", ""))
	_dialogue_choice_buttons[1].text = str(TECHNICIAN_CHOICES[1].get("label", ""))
	_dialogue_choice_buttons[0].disabled = false
	_dialogue_choice_buttons[1].disabled = false
	_dialogue_choice_buttons[0].show()
	_dialogue_choice_buttons[1].show()
	_dialogue_choice_buttons[2].hide()
	_dialogue_choice_buttons[3].hide()
	_dialogue_choice_buttons[4].hide()
	_dialogue_choices.show()
	_dialogue_footer.hide()


func _show_interrogation_topics() -> void:
	var available_topics := _available_technician_topics()
	_dialogue_phase = "topic_menu"
	_dialogue_panel.offset_top = -340.0 - maxi(available_topics.size() - 2, 0) * 48.0
	_dialogue_speaker.text = "TECNICO (POC)"
	_set_dialogue_text("Di cosa vuoi parlare?")
	_dialogue_progress.text = "ARGOMENTI"
	for choice_button in _dialogue_choice_buttons:
		choice_button.hide()
		choice_button.disabled = false
	for topic_index in range(available_topics.size()):
		var topic: Dictionary = available_topics[topic_index]
		var topic_id := str(topic.get("id", ""))
		var already_asked := _asked_technician_topics.has(topic_id)
		var topic_state := "GIÀ CHIESTO" if already_asked else "CHIEDI"
		if _newly_unlocked_technician_topics.has(topic_id) and not already_asked:
			topic_state = "NUOVO"
		_dialogue_choice_buttons[topic_index].text = "%s: %s" % [
			topic_state,
			str(topic.get("label", "")),
		]
		_dialogue_choice_buttons[topic_index].disabled = already_asked
		_dialogue_choice_buttons[topic_index].show()
	var evidence_choice_index := available_topics.size()
	_dialogue_choice_buttons[evidence_choice_index].text = "MOSTRA UNA PROVA"
	_dialogue_choice_buttons[evidence_choice_index].disabled = _information_entries.is_empty()
	_dialogue_choice_buttons[evidence_choice_index].show()
	var end_choice_index := evidence_choice_index + 1
	_dialogue_choice_buttons[end_choice_index].text = "TERMINA LA CONVERSAZIONE"
	_dialogue_choice_buttons[end_choice_index].show()
	_dialogue_choices.show()
	_dialogue_footer.hide()


func _on_dialogue_choice_selected(choice_index: int) -> void:
	if _dialogue_phase == "response_choices":
		if choice_index < 0 or choice_index >= TECHNICIAN_CHOICES.size():
			return
		var response_choice: Dictionary = TECHNICIAN_CHOICES[choice_index]
		var player_response := str(response_choice.get("label", ""))
		var technician_response := str(response_choice.get("response", ""))
		_append_dialogue_history("GIOCATORE", player_response)
		_append_dialogue_history("TECNICO (POC)", technician_response)
		_set_dialogue_text(technician_response)
		_dialogue_progress.text = "RISPOSTA"
		_dialogue_choices.hide()
		_dialogue_footer.show()
		_dialogue_phase = "response_choice_result"
		return

	if _dialogue_phase != "topic_menu":
		return
	var available_topics := _available_technician_topics()
	var evidence_choice_index := available_topics.size()
	if choice_index == evidence_choice_index:
		_open_notebook_for_evidence()
		return
	if choice_index == evidence_choice_index + 1:
		_finish_dialogue()
		return
	if choice_index < 0 or choice_index >= available_topics.size():
		return

	var topic: Dictionary = available_topics[choice_index]
	var topic_id := str(topic.get("id", ""))
	if _asked_technician_topics.has(topic_id):
		return
	var response_text := str(topic.get("response", ""))
	if topic_id == "cabinet":
		response_text = str(
			topic.get("response_open", "")
			if _cabinet_is_open
			else topic.get("response_closed", "")
		)
	_append_dialogue_history("GIOCATORE", "Chiedi: %s" % str(topic.get("label", "")))
	_append_dialogue_history("TECNICO (POC)", response_text)
	_set_dialogue_text(response_text, "ALTRI ARGOMENTI")
	_dialogue_progress.text = "RISPOSTA"
	_dialogue_panel.offset_top = -252.0
	_dialogue_choices.hide()
	_dialogue_footer.show()
	_dialogue_phase = "topic_response"
	_asked_technician_topics[topic_id] = true
	_newly_unlocked_technician_topics.erase(topic_id)
	_record_information(str(topic.get("information_id", "")), response_text)


func _open_notebook_for_evidence() -> void:
	_notebook_evidence_mode = true
	_notebook_link_mode = false
	_selected_clue_ids.clear()
	_clue_link_feedback = ""
	_close_notebook_button.text = "TORNA AL DIALOGO"
	_context_menu.hide()
	_context_target = null
	_refresh_notebook_entries()
	_notebook_overlay.show()
	var hud := _notebook_overlay.get_parent()
	hud.move_child(_notebook_overlay, hud.get_child_count() - 1)
	if _information_entries.is_empty():
		_notebook_entry_title.text = "NESSUNA INFORMAZIONE"
		_notebook_entry_source.text = "ESAMINA L'AMBIENTE PER COMINCIARE"
		_notebook_entry_text.text = "Non hai ancora prove da mostrare."
		_selected_notebook_entry_id = ""
		_show_evidence_button.hide()
		_update_notebook_action_buttons()
	else:
		_show_information_entry(0)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _show_selected_evidence_to_technician() -> void:
	if not _notebook_evidence_mode or _selected_notebook_entry_id.is_empty():
		return
	if _shown_technician_evidence.has(_selected_notebook_entry_id):
		return

	var evidence_id := _selected_notebook_entry_id
	_shown_technician_evidence[evidence_id] = true
	var evidence_title := _information_title(evidence_id)
	var evidence_response := _technician_evidence_response(evidence_id)
	_append_dialogue_history("GIOCATORE", "Mostri: %s" % evidence_title)
	_append_dialogue_history("TECNICO (POC)", evidence_response)
	_notebook_overlay.hide()
	_notebook_evidence_mode = false
	_dialogue_overlay.show()
	_dialogue_speaker.text = "TECNICO (POC)"
	var evidence_dialogue_text := "Mostri: %s\n\n%s" % [
		evidence_title,
		evidence_response,
	]
	_set_dialogue_text(evidence_dialogue_text, "ALTRI ARGOMENTI")
	_dialogue_progress.text = "REAZIONE"
	_dialogue_panel.offset_top = -252.0
	_dialogue_choices.hide()
	_dialogue_footer.show()
	_dialogue_phase = "evidence_response"
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _information_title(entry_id: String) -> String:
	for entry in _information_entries:
		if str(entry.get("id", "")) == entry_id:
			return str(entry.get("title", "un'informazione"))
	return "un'informazione"


func _technician_evidence_response(evidence_id: String) -> String:
	match evidence_id:
		"service_light":
			return "Sì, è la spia che ho visto. Non so ancora che cosa indichi."
		"technician_service_light":
			return "È quello che ti ho detto. Non ho altro da aggiungere sulla spia."
		"cabinet":
			return "Sì, i ripiani sono vuoti. Non so dirti altro sull'armadio."
		"technician_cabinet":
			return "È quello che ti ho detto. Non so altro sull'armadio."
		"porthole":
			return "Non ho guardato fuori dall'oblò. Non saprei aggiungere altro."
		"flask_cap", "flask_liquid":
			return "Non so dirti altro su quell'ampolla."
		_:
			return "Non saprei aggiungere altro su questa informazione."


func _finish_dialogue() -> void:
	_dialogue_overlay.hide()
	_dialogue_history_overlay.hide()
	_dialogue_reveal_text = ""
	_dialogue_reveal_characters = 0
	_dialogue_reveal_elapsed = 0.0
	_notebook_overlay.hide()
	_notebook_evidence_mode = false
	_notebook_link_mode = false
	_selected_clue_ids.clear()
	_dialogue_choices.hide()
	_dialogue_footer.show()
	_dialogue_panel.offset_top = -252.0
	_bottom_panel.show()
	_status.text = "DIALOGO CONCLUSO  /  TECNICO (POC)"
	_feedback.text = "La conversazione di prova è terminata."
	_dialogue_line_index = -1
	_dialogue_phase = ""
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
