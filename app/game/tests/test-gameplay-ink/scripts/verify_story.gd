extends SceneTree

const RuntimeScript := preload("res://addons/ink_scene_director/ink_story_runtime.gd")
const DirectorScript := preload("res://addons/ink_scene_director/ink_scene_director.gd")
const GameplayScene := preload("res://tests/test-gameplay-ink/test-gameplay-ink.tscn")
const STORY_JSON := "res://tests/test-gameplay-ink/generated/mission-hexalife.json"

var _director: Node
var _line_count := 0
var _intro_line_count := 0
var _story_text := ""
var _cue_tags := {}
var _node_line_counts := {}
var _error_text := ""
var _story_finished := false


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	if not _verify_generate_button_callable() or not await _verify_ui_layout() or not await _verify_text_writing_toggle() or not await _verify_narrative_typewriter_append() or not await _verify_dialogue_display() or not await _verify_terminal_room_return():
		quit(1)
		return
	_director = DirectorScript.new()
	root.add_child(_director)
	_director.line_emitted.connect(_on_line)
	_director.runtime_error.connect(_on_runtime_error)
	_director.story_ended.connect(func() -> void: _story_finished = true)
	_register_recording_cues()
	if not _director.load_story(STORY_JSON):
		quit(1)
		return
	_director.start_story()
	var steps := 0
	while steps < 2000 and not _story_finished and _error_text.is_empty():
		steps += 1
		if _director.has_pending_content():
			_director.continue_story()
		elif _director.is_waiting_for_choice():
			var choices: Array[Dictionary] = _director.get_choices()
			var selected_index := _choose_route(_director.get_current_knot(), choices, _director.get_variables())
			if selected_index < 0 or not _director.choose(selected_index):
				break
		else:
			break
	if not _error_text.is_empty():
		push_error(_error_text)
		quit(1)
		return
	if not _story_finished:
		push_error("La route di verifica non ha raggiunto la fine della storia.")
		quit(1)
		return
	if _intro_line_count != 1:
		push_error("Il tutorial iniziale deve essere emesso come un solo dialogo, ricevuti: %d." % _intro_line_count)
		quit(1)
		return
	if int(_node_line_counts.get("istruzioni", 0)) != 1 or int(_node_line_counts.get("risveglio", 0)) < 2:
		push_error("I paragrafi emessi devono conservare il nodo Ink di provenienza: %s." % _node_line_counts)
		quit(1)
		return
	var variables: Dictionary = _director.get_variables()
	if int(variables.get("turno", -1)) != 0:
		push_error("La PoC ha fatto avanzare il tempo prima dell'uscita: %s." % variables)
		quit(1)
		return
	if int(variables.get("giorno", -1)) != 1 or int(variables.get("fascia", -1)) != 1 or int(variables.get("fungo", -1)) != 1:
		push_error("Lo stato Ink della PoC ha prodotto valori inattesi: %s." % variables)
		quit(1)
		return
	for expected_text in ["MISSIONE HEXALIFE", "22 miliardi", "Le parole compaiono progressivamente", "Il suono arriva prima dei pensieri", "La porta si apre sul corridoio"]:
		if not _story_text.contains(expected_text):
			push_error("Testo della PoC non emesso dal runtime: %s." % expected_text)
			quit(1)
			return
	if not _cue_tags.has("scene:cryogenic_room") or not _cue_tags.has("scene:corridor") or _cue_tags.has("scene:engine_room") or _cue_tags.has("scene:bridge") or not _cue_tags.has("camera:wide") or not _cue_tags.has("audio:alarm") or not _cue_tags.has("char:capitano") or not _cue_tags.has("ui:intro"):
		push_error("Mancano cue di scena nel percorso: %s." % _cue_tags.keys())
		quit(1)
		return
	var route_line_count := _line_count
	if not _director.start_story() or int(_director.get_variable("turno", -1)) != 0 or not _director.has_pending_content():
		push_error("Il riavvio del runtime non ha ripristinato lo stato iniziale.")
		quit(1)
		return
	print("PASS Ink route: %d righe, turno %d, %d cue distinti; riavvio pulito." % [route_line_count, int(variables.turno), _cue_tags.size()])
	_director.stop_story()
	_director.queue_free()
	_director = null
	if not _verify_object_interactions() or not _verify_unsupported_opcode() or not _verify_unregistered_cue():
		quit(1)
		return
	quit(0)


func _verify_generate_button_callable() -> bool:
	var scene_root := GameplayScene.instantiate()
	var generate_action: Variant = scene_root.get("generate_node_tree")
	if not generate_action is Callable:
		push_error("Il pulsante GENERATE non espone un Callable valido.")
		scene_root.free()
		return false
	var generate_callable: Callable = generate_action
	if not generate_callable.is_valid() or generate_callable.get_object() != scene_root or generate_callable.get_method() != "_queue_node_tree_generation":
		push_error("Il pulsante GENERATE non è associato al callback della scena.")
		scene_root.free()
		return false
	scene_root.free()
	print("PASS GENERATE: callback Callable valido e associato alla scena.")
	return true


func _verify_ui_layout() -> bool:
	var scene_root := GameplayScene.instantiate()
	var layout := scene_root.get_node_or_null("UILayout") as Control
	var safe_area := scene_root.get_node_or_null("UILayout/SafeArea") as MarginContainer
	var screen_column := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn") as VBoxContainer
	var narrative := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/NarrativeBox") as PanelContainer
	var scroll := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeViewport/NarrativeScroll") as ScrollContainer
	var narrative_text := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/NarrativeBox/NarrativeContent/NarrativeViewport/NarrativeScroll/NarrativeText") as RichTextLabel
	var action := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/BottomBoxDock/ActionBox") as PanelContainer
	var dialog := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox") as PanelContainer
	var dialog_scroll := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogScroll") as ScrollContainer
	var dialog_continue := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/BottomBoxDock/DialogBox/DialogContent/DialogContinueButton") as Button
	var action_continue := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/BottomBoxDock/ActionBox/ActionContent/ActionContinueButton") as Button
	var writing_toggle := scene_root.get_node_or_null("UILayout/SafeArea/ScreenColumn/HeaderPanel/HeaderContent/StatusRow/TextWritingToggle") as Button
	var notify := scene_root.get_node_or_null("UILayout/NotifyOverlay/NotifyCenter/NotifyBox") as PanelContainer
	if layout == null or safe_area == null or screen_column == null or narrative == null or scroll == null or narrative_text == null or action == null or dialog == null or notify == null or dialog_scroll == null or dialog_continue == null or action_continue == null or writing_toggle == null:
		push_error("UILayout deve contenere i box Narrative, Notify, Action e Dialog.")
		scene_root.free()
		return false
	if narrative.get_parent() != screen_column or narrative.get_index() < (screen_column.get_node("HeaderPanel") as Control).get_index() or action.get_parent() != screen_column.get_node("BottomBoxDock") or dialog.get_parent() != action.get_parent():
		push_error("Narrative deve seguire l'header e Action/Dialog devono condividere il dock inferiore.")
		scene_root.free()
		return false
	if narrative.visible or scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED or not narrative_text.fit_content or narrative_text.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT or dialog_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED or dialog_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_AUTO:
		push_error("La cronologia deve essere allineata a sinistra e scorrere solo in verticale.")
		scene_root.free()
		return false
	root.add_child(scene_root)
	await process_frame
	await process_frame
	if safe_area.get_theme_constant("margin_left") != 0 or safe_area.get_theme_constant("margin_right") != 0 or safe_area.get_theme_constant("margin_top") != 0 or safe_area.get_theme_constant("margin_bottom") != 0:
		push_error("La UI deve usare tutta l'area dello schermo senza margini SafeArea.")
		scene_root.free()
		return false
	if safe_area.mouse_filter != Control.MOUSE_FILTER_IGNORE or screen_column.mouse_filter != Control.MOUSE_FILTER_IGNORE or scene_root.get_node("UILayout/SafeArea/ScreenColumn/BottomBoxDock").mouse_filter != Control.MOUSE_FILTER_IGNORE or scene_root.get_node("InteractionHotspots").mouse_filter != Control.MOUSE_FILTER_STOP:
		push_error("I contenitori UI devono lasciare passare i click verso gli hotspot della scena.")
		scene_root.free()
		return false
	if narrative.visible or not narrative_text.fit_content or narrative_text.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT:
		push_error("La cronologia deve partire da un minimo di 160 px e lasciare leggibile il testo a sinistra.")
		scene_root.free()
		return false
	if writing_toggle.text != "SCRITTURA: ON":
		push_error("La scrittura progressiva deve essere attiva all'avvio e regolabile dall'header.")
		scene_root.free()
		return false
	for generated_node in scene_root.find_children("*", "", true, true):
		if generated_node.owner != scene_root:
			push_error("Nodo UI senza owner della scena: %s." % generated_node.get_path())
			scene_root.free()
			return false
	scene_root.free()
	print("PASS UILayout: log nascosto, Dialog scrollabile, CONTINUA dedicati e hotspot cliccabili.")
	return true


func _verify_text_writing_toggle() -> bool:
	var scene_root := GameplayScene.instantiate()
	root.add_child(scene_root)
	await process_frame
	scene_root._typewriter_timer.stop()
	scene_root._director.stop_story()
	scene_root._notify_waiting_for_start = false
	scene_root._notify_overlay.hide()
	scene_root._current_line_label.clear()
	scene_root._dialog_text_label.clear()
	scene_root._active_sequence_mode = "narrative"
	scene_root._last_rendered_box_mode = ""
	scene_root._render_story_line("Disattivazione a metà sequenza.", PackedStringArray(["ui:narrative_section"]), "verify_toggle")
	if not scene_root._is_revealing_line:
		push_error("Con SCRITTURA: ON, il testo deve iniziare progressivamente.")
		scene_root.free()
		return false
	scene_root._on_text_writing_toggle_pressed()
	if scene_root._is_revealing_line or scene_root._dialog_text_label.visible_characters != -1 or scene_root._text_writing_toggle.text != "SCRITTURA: OFF":
		push_error("Disattivare la scrittura deve completare subito il testo e aggiornare il pulsante.")
		scene_root.free()
		return false
	scene_root._on_text_writing_toggle_pressed()
	if not scene_root.text_writing_enabled or scene_root._text_writing_toggle.text != "SCRITTURA: ON":
		push_error("La scrittura progressiva deve poter essere riattivata.")
		scene_root.free()
		return false
	scene_root._finish_line_reveal()
	scene_root.free()
	print("PASS toggle scrittura: stato ON/OFF aggiornato anche durante una riga.")
	return true


func _verify_dialogue_display() -> bool:
	var scene_root := GameplayScene.instantiate()
	root.add_child(scene_root)
	await process_frame
	if not scene_root._is_revealing_line or scene_root._typewriter_timer.is_stopped():
		push_error("Il testo deve iniziare a scriversi progressivamente.")
		scene_root.free()
		return false
	scene_root._finish_line_reveal()
	await process_frame
	var intro_text: String = scene_root._notify_text_label.get_parsed_text()
	if not scene_root._notify_waiting_for_start or not scene_root._notify_overlay.visible or not scene_root._start_button.visible or scene_root._displayed_knot != "istruzioni":
		push_error("L'introduzione deve comparire nel Notify Box con il solo pulsante INIZIA.")
		scene_root.free()
		return false
	if not intro_text.contains("MISSIONE HEXALIFE"):
		push_error("Il Notify Box deve contenere il testo introduttivo completo.")
		scene_root.free()
		return false
	scene_root._on_start_pressed()
	var steps := 0
	while steps < 32 and not scene_root._pending_choices_need_continue:
		steps += 1
		if scene_root._is_revealing_line:
			scene_root._finish_line_reveal()
		await process_frame
	var wake_text: String = scene_root._dialog_text_label.get_parsed_text()
	if not scene_root._displayed_knot == "risveglio" or scene_root._notify_overlay.visible:
		push_error("INIZIA deve avviare direttamente la sequenza narrativa del risveglio.")
		scene_root.free()
		return false
	var scroll_bar: VScrollBar = scene_root._dialogue_scroll.get_v_scroll_bar()
	if not wake_text.contains("Il suono arriva prima dei pensieri") or not wake_text.contains("Un terminale lampeggia accanto alla porta"):
		push_error("I paragrafi del risveglio devono accumularsi nel Narrative Box.")
		scene_root.free()
		return false
	if not scene_root._text_panel.visible or scene_root._narrative_panel.visible:
		push_error("Il Dialog Box deve mostrare la sequenza mentre il log resta nascosto.")
		scene_root.free()
		return false
	if scene_root._is_revealing_line:
		scene_root._finish_line_reveal()
	if scene_root._displayed_sequence_mode != "narrative" or scene_root._is_action_panel_compact:
		push_error("Prima di COMPLETA il risveglio deve mantenere il Narrative Box espanso, anche se la destinazione ha azioni.")
		scene_root.free()
		return false
	if not scene_root._advance_button.visible or scene_root._advance_button.text != "CONTINUA  →":
		push_error("La sequenza narrativa deve offrire CONTINUA nel Dialog Box.")
		scene_root.free()
		return false
	var narrative_max_height: float = scene_root._get_narrative_max_height()
	if scene_root._text_panel.custom_minimum_size.y <= scene_root.NARRATIVE_PANEL_MIN_HEIGHT:
		push_error("La comparsa di COMPLETA non deve resettare l'altezza raggiunta nella sezione narrativa.")
		scene_root.free()
		return false
	if scene_root._text_panel.custom_minimum_size.y < narrative_max_height - 24.0 and scroll_bar.max_value > scroll_bar.page + 1.0:
		push_error("La narrazione deve espandere il Narrative Box prima di rendere il testo scrollabile.")
		scene_root.free()
		return false
	if scene_root._pending_choices_need_continue and scene_root._is_revealing_line:
		scene_root._finish_line_reveal()
	if scene_root._pending_choices_need_continue and not scene_root._is_revealing_line:
		scene_root._on_advance_pressed()
	steps = 0
	while steps < 40 and not scene_root._director.is_waiting_for_choice():
		steps += 1
		if scene_root._is_revealing_line:
			scene_root._finish_line_reveal()
		elif scene_root._pending_choices_need_continue:
			scene_root._on_advance_pressed()
		await process_frame
	if not scene_root._director.is_waiting_for_choice() or scene_root._displayed_knot != "sala_criogenica":
		push_error("Dopo il risveglio devono apparire le azioni disponibili per la sala (knot=%s waiting=%s pending_continue=%s line=%s choices=%s)." % [scene_root._displayed_knot, str(scene_root._director.is_waiting_for_choice()), str(scene_root._pending_choices_need_continue), str(scene_root._pending_knot_line), str(scene_root._has_pending_choices)])
		scene_root.free()
		return false
	if not scene_root._is_action_panel_compact:
		push_error("Dopo COMPLETA, entrando nelle azioni della sala, il Narrative Box deve contrarsi.")
		scene_root.free()
		return false
	var room_context_text: String = scene_root._current_line_label.get_parsed_text()
	if scene_root._narrative_panel.visible or not room_context_text.contains("Il suono arriva prima dei pensieri") or not scene_root._action_panel.visible:
		push_error("Il log deve restare nascosto mentre è visibile l'Action Box.")
		scene_root.free()
		return false
	var has_capsule_info := false
	for item in scene_root._action_options_list.get_children():
		if item is Label and str(item.text).contains("capsula"):
			has_capsule_info = true
	if not has_capsule_info or scene_root._dialog_panel.visible:
		push_error("L'Action Box deve indicare le azioni hotspot senza sostituire i click sulla scena.")
		scene_root.free()
		return false
	scene_root._on_hotspot_pressed("capsule", "capsula_crio")
	if scene_root._displayed_knot != "capsula_crio" or not scene_root._is_revealing_line or not scene_root._pending_knot_line.is_empty():
		push_error("Il click sulla capsula deve entrare subito nel suo nodo di risposta (knot=%s, revealing=%s, waiting=%s, choices=%s, error=%s)." % [scene_root._displayed_knot, str(scene_root._is_revealing_line), str(scene_root._director.is_waiting_for_choice()), str(scene_root._director.get_choices()), scene_root._current_line_label.get_parsed_text()])
		scene_root.free()
		return false
	steps = 0
	while steps < 16 and not scene_root._pending_choices_need_continue:
		steps += 1
		if scene_root._is_revealing_line:
			scene_root._finish_line_reveal()
		await process_frame
	if scene_root._is_revealing_line:
		scene_root._finish_line_reveal()
	if not scene_root._pending_choices_need_continue or not scene_root._action_advance_button.visible:
		push_error("Il ritorno automatico dalla risposta della capsula deve attendere CONTINUA.")
		scene_root.free()
		return false
	scene_root._on_advance_pressed()
	if scene_root._pending_choices_need_continue or not scene_root._director.is_waiting_for_choice() or scene_root._displayed_knot != "sala_criogenica":
		push_error("CONTINUA dopo la risposta deve ripristinare le azioni della sala.")
		scene_root.free()
		return false
	if scene_root._narrative_panel.visible or not scene_root._current_line_label.get_parsed_text().contains(room_context_text) or not scene_root._is_action_panel_compact:
		push_error("Dopo la capsula, il Narrative Box deve conservare il Risveglio e aggiungere la risposta dell'azione.")
		scene_root.free()
		return false
	scene_root.free()
	print("PASS dialogo: contesto sala mantenuto e ripristinato dopo la capsula.")
	return true


func _verify_narrative_typewriter_append() -> bool:
	var scene_root := GameplayScene.instantiate()
	root.add_child(scene_root)
	await process_frame
	scene_root._typewriter_timer.stop()
	scene_root._director.stop_story()
	scene_root._notify_waiting_for_start = false
	scene_root._notify_overlay.hide()
	scene_root._current_line_label.clear()
	scene_root._action_text_label.clear()
	scene_root._dialog_text_label.clear()
	scene_root._active_sequence_mode = "narrative"
	scene_root._last_rendered_box_mode = ""
	scene_root._render_story_line("Primo paragrafo.", PackedStringArray(), "verify_append")
	scene_root._finish_line_reveal()
	var previous_character_count: int = scene_root._dialog_text_label.get_total_character_count()
	scene_root._render_story_line("Secondo paragrafo.", PackedStringArray(), "verify_append")
	if not scene_root._is_revealing_line or scene_root._dialog_text_label.visible_characters != previous_character_count:
		push_error("La scrittura del nuovo paragrafo deve proseguire dal testo già visibile, senza ripartire dall'inizio.")
		scene_root.free()
		return false
	scene_root._finish_line_reveal()
	scene_root._text_panel.custom_minimum_size.y = 360.0
	await process_frame
	await process_frame
	scene_root._render_story_line("Terzo paragrafo della stessa sezione.", PackedStringArray(), "verify_append")
	await process_frame
	if scene_root._text_panel.custom_minimum_size.y < 350.0:
		push_error("Un nuovo paragrafo della stessa sezione non deve contrarre il Narrative Box.")
		scene_root.free()
		return false
	scene_root._finish_line_reveal()
	scene_root._set_history_compact(true)
	scene_root._text_panel.custom_minimum_size.y = 360.0
	scene_root._render_story_line("Nuova sezione.", PackedStringArray(["ui:narrative_section"]), "verify_new_section")
	await process_frame
	await process_frame
	if scene_root._active_sequence_mode != "narrative" or scene_root._is_action_panel_compact:
		push_error("Il tag ui:narrative_section deve riaprire la modalità narrativa espansa.")
		scene_root.free()
		return false
	if scene_root._text_panel.custom_minimum_size.y > 180.0:
		push_error("Una nuova sezione narrativa deve riavviare la crescita dall'altezza minima.")
		scene_root.free()
		return false
	if not scene_root._current_line_label.get_parsed_text().contains("Primo paragrafo.") or not scene_root._current_line_label.get_parsed_text().contains("Nuova sezione."):
		push_error("L'inizio di una nuova sezione deve mantenere la cronologia precedente.")
		scene_root.free()
		return false
	scene_root._finish_line_reveal()
	var long_paragraph := "Un passaggio narrativo abbastanza lungo per riempire il box. ".repeat(150)
	scene_root._render_story_line(long_paragraph, PackedStringArray(), "verify_new_section")
	scene_root._finish_line_reveal()
	await process_frame
	await process_frame
	if scene_root._text_panel.custom_minimum_size.y < scene_root._get_narrative_max_height() - 24.0:
		push_error("Una sequenza narrativa lunga deve espandere il Narrative Box fino al massimo.")
		scene_root.free()
		return false
	if scene_root._dialogue_scroll.get_v_scroll_bar().max_value <= scene_root._dialogue_scroll.get_v_scroll_bar().page + 1.0:
		push_error("Il testo che supera l'altezza massima deve restare scrollabile.")
		scene_root.free()
		return false
	var history: String = scene_root._current_line_label.get_parsed_text()
	if history.count("Primo paragrafo.") != 1 or history.count("Secondo paragrafo.") != 1 or history.count("Terzo paragrafo della stessa sezione.") != 1 or history.count("Nuova sezione.") != 1 or history.count(long_paragraph) != 1:
		push_error("La cronologia deve conservare una sola copia di ciascun paragrafo.")
		scene_root.free()
		return false
	scene_root.free()
	print("PASS narrative: crescita mantenuta tra paragrafi, reset per tag e cronologia conservata.")
	return true


func _verify_terminal_room_return() -> bool:
	var scene_root := GameplayScene.instantiate()
	root.add_child(scene_root)
	await process_frame
	scene_root._finish_line_reveal()
	await process_frame
	scene_root._on_start_pressed()
	var steps := 0
	while steps < 40 and not scene_root._pending_choices_need_continue:
		steps += 1
		if scene_root._is_revealing_line:
			scene_root._finish_line_reveal()
		await process_frame
	if scene_root._is_revealing_line:
		scene_root._finish_line_reveal()
	if scene_root._is_revealing_line:
		scene_root._finish_line_reveal()
	scene_root._on_advance_pressed()
	if not scene_root._director.is_waiting_for_choice():
		await process_frame
	var room_context_text: String = scene_root._current_line_label.get_parsed_text()
	scene_root._on_hotspot_pressed("terminal", "terminale_crio")
	steps = 0
	while steps < 32 and (not scene_root._director.is_waiting_for_choice() or scene_root._is_revealing_line or not scene_root._choice_panel.visible):
		steps += 1
		if scene_root._is_revealing_line:
			scene_root._finish_line_reveal()
		await process_frame
	var close_index := -1
	var terminal_choices: Array[Dictionary] = scene_root._director.get_choices()
	for index in range(terminal_choices.size()):
		if str(terminal_choices[index].get("text", "")).contains("Chiudere"):
			close_index = index
			break
	if close_index < 0:
		push_error("Il terminale deve esporre la scelta per tornare alla sala (knot=%s waiting=%s panel=%s choices=%s)." % [scene_root._director.get_current_knot(), str(scene_root._director.is_waiting_for_choice()), str(scene_root._choice_panel.visible), str(terminal_choices)])
		scene_root.free()
		return false
	scene_root._on_choice_pressed(close_index)
	if scene_root._narrative_panel.visible or not scene_root._current_line_label.get_parsed_text().contains(room_context_text) or not scene_root._director.is_waiting_for_choice() or not scene_root._is_action_panel_compact:
		push_error("Chiudendo il terminale, il contesto del Risveglio deve tornare visibile insieme alle azioni.")
		scene_root.free()
		return false
	scene_root.free()
	print("PASS dialogo: chiusura terminale ripristina il contesto e le azioni della sala.")
	return true


func _verify_object_interactions() -> bool:
	_error_text = ""
	_story_finished = false
	_director = DirectorScript.new()
	root.add_child(_director)
	_director.runtime_error.connect(_on_runtime_error)
	_director.story_ended.connect(func() -> void: _story_finished = true)
	_register_recording_cues()
	if not _director.load_story(STORY_JSON) or not _director.start_story():
		push_error("Impossibile avviare la storia per verificare gli hotspot.")
		return false
	if not _advance_to_choice("sala_criogenica"):
		push_error("L'introduzione e il risveglio non hanno portato alle interazioni della sala.")
		return false
	if _director.choose_target("azione_inesistente"):
		push_error("Il runtime ha accettato un'interazione Ink non disponibile.")
		return false
	if not _director.choose_target("capsula_crio") or not _advance_to_choice("sala_criogenica"):
		push_error("Il click sulla capsula non ha selezionato la relativa scelta Ink.")
		return false
	if not bool(_director.get_variable("visto_capsula_crio", false)):
		push_error("La scelta della capsula non ha applicato la conseguenza Ink.")
		return false
	if _director.choose_target("capsula_crio"):
		push_error("La capsula esaminata è rimasta interagibile senza una scelta Ink.")
		return false
	if not _director.choose_target("porta_crio") or not _advance_to_choice("sala_criogenica"):
		push_error("Il primo click sulla porta non ha eseguito il tentativo bloccato.")
		return false
	if not _director.choose_target("terminale_crio") or not _advance_to_choice("terminale_crio"):
		push_error("Il click sul terminale non ha aperto le scelte Ink del terminale.")
		return false
	if not _director.jump_to_knot("uscita_crio") or not _director.choose_target("fine_poc"):
		push_error("Il click sulla porta in uscita non ha selezionato la fine della PoC.")
		return false
	var end_steps := 0
	while end_steps < 100 and not _story_finished and _director.has_pending_content():
		end_steps += 1
		_director.continue_story()
	if not _story_finished or _director.get_current_knot() != "fine_poc":
		push_error("Il percorso giocabile non si è concluso all'uscita dalla sala criogenica.")
		return false
	if not _error_text.is_empty():
		push_error("Errore durante la verifica delle interazioni: " + _error_text)
		return false
	print("PASS Ink interactions: capsula, terminale, porta bloccata e fine PoC all'uscita.")
	_director.stop_story()
	_director.queue_free()
	_director = null
	return true


func _advance_to_choice(expected_knot: String) -> bool:
	var steps := 0
	while steps < 1000 and not _director.is_waiting_for_choice() and _director.has_pending_content():
		steps += 1
		_director.continue_story()
	return _director.is_waiting_for_choice() and _director.get_current_knot() == expected_knot


func _choose_route(knot: String, choices: Array[Dictionary], variables: Dictionary) -> int:
	if choices.is_empty():
		return -1
	if knot == "sala_criogenica":
		if not bool(variables.get("visto_capsula_crio", false)):
			return _find_choice(choices, "capsula")
		if not bool(variables.get("visto_terminale_crio", false)):
			return _find_choice(choices, "terminale")
		return _find_choice(choices, "terminale")
	if knot == "terminale_crio":
		if not bool(variables.get("visto_mappa_crio", false)):
			return _find_choice(choices, "mappa")
		if not bool(variables.get("visto_qc_crio", false)):
			return _find_choice(choices, "allarme")
		return _find_choice(choices, "Chiudere")
	return 0


func _find_choice(choices: Array[Dictionary], fragment: String) -> int:
	for index in range(choices.size()):
		if str(choices[index].get("text", "")).to_lower().contains(fragment.to_lower()):
			return index
	return -1


func _on_line(text: String, tags: PackedStringArray, knot_name: String) -> void:
	_line_count += 1
	_node_line_counts[knot_name] = int(_node_line_counts.get(knot_name, 0)) + 1
	if tags.has("ui:intro"):
		_intro_line_count += 1
	_story_text += text + "\n"
	for tag in tags:
		_cue_tags[tag] = true


func _on_runtime_error(message: String) -> void:
	_error_text = message
	if not _story_finished and _line_count > 0:
		push_error("Cue registry: " + message)


func _register_recording_cues() -> void:
	for scene_id in ["cryogenic_room", "corridor", "engine_room", "bridge"]:
		_director.register_scene_cue(scene_id, _record_scene_cue)
	for actor_id in ["capitano", "ingegnere", "medico", "ufficiale", "scienziato"]:
		_director.register_actor_cue(actor_id, _record_actor_cue)
	_director.register_camera_cue("wide", _record_camera_cue)
	_director.register_camera_cue("close", _record_camera_cue)
	_director.register_audio_cue("alarm", _record_audio_cue)


func _record_scene_cue(id: String) -> void:
	_cue_tags["scene:" + id] = true


func _record_actor_cue(id: String) -> void:
	_cue_tags["actor:" + id] = true


func _record_camera_cue(id: String) -> void:
	_cue_tags["camera:" + id] = true


func _record_audio_cue(id: String) -> void:
	_cue_tags["audio:" + id] = true


func _verify_unsupported_opcode() -> bool:
	var runtime: RefCounted = RuntimeScript.new()
	_error_text = ""
	runtime.runtime_error.connect(_on_runtime_error)
	var source := '{"inkVersion":21,"root":[[],"done",{"global decl":[],"istruzioni":["unsupported_opcode",null]}],"listDefs":{}}'
	if runtime.load_json_text(source):
		push_error("Il runtime ha accettato un opcode non supportato.")
		return false
	if not _error_text.contains("opcode"):
		push_error("Il runtime non ha segnalato chiaramente l'opcode non supportato.")
		return false
	return true


func _verify_unregistered_cue() -> bool:
	_error_text = ""
	_director = DirectorScript.new()
	root.add_child(_director)
	_director.runtime_error.connect(func(message: String) -> void: _error_text = message)
	var source := '{"inkVersion":21,"root":[[{"->":"istruzioni"}],"done",{"global decl":[],"istruzioni":["#","^scene:missing","/#","^Test cue.","\\n","end",null]}],"listDefs":{}}'
	if not _director.load_story_text(source):
		return false
	_director.start_story()
	if not _error_text.contains("Cue non registrato: scene:missing"):
		push_error("Un cue non registrato non è stato rifiutato: %s." % _error_text)
		return false
	_director.stop_story()
	_director.queue_free()
	_director = null
	return true
