extends RefCounted

signal line_emitted(text: String, tags: PackedStringArray, knot_name: String)
signal choices_available(choices: Array[Dictionary])
signal variables_changed(variables: Dictionary)
signal story_ended
signal runtime_error(message: String)

const SUPPORTED_INK_VERSION := 21
const MAX_EXECUTION_STEPS := 250000

var _program: Dictionary = {}
var _variables: Dictionary = {}
var _default_start_knot := ""
var _current_knot := ""
var _current_index := 0
var _choices: Array[Dictionary] = []
var _line_queue: Array[Dictionary] = []
var _line_buffer := ""
var _line_tags := PackedStringArray()
var _line_buffer_knot := ""
var _evaluation_stack: Array = []
var _taken_choices: Dictionary = {}
var _loaded := false
var _running := false
var _finished := false
var _stopped := false


func load_json_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("File JSON Ink non trovato: %s" % path)
	return load_json_text(FileAccess.get_file_as_string(path))


func load_json_text(source: String) -> bool:
	var parsed: Variant = JSON.parse_string(source)
	if not parsed is Dictionary:
		return _fail("Il JSON Ink deve contenere un oggetto alla radice.")
	if int(parsed.get("inkVersion", -1)) != SUPPORTED_INK_VERSION:
		return _fail("Versione Ink non supportata: %s (questa PoC richiede %d)." % [str(parsed.get("inkVersion", "assente")), SUPPORTED_INK_VERSION])
	if not parsed.get("root") is Array or parsed.root.size() < 3 or not parsed.root[0] is Array or not parsed.root[2] is Dictionary:
		return _fail("Struttura JSON Ink non riconosciuta: manca il contenitore dei knot.")
	if not parsed.get("listDefs", {}).is_empty():
		return _fail("Le Ink list non sono supportate da questo runtime.")

	_program = parsed.root[2]
	_default_start_knot = _read_start_knot(parsed.root[0])
	var validation_error := _validate_program(_program)
	if not validation_error.is_empty():
		return _fail(validation_error)
	_variables = _read_global_variables(_program.get("global decl", []))
	_current_knot = ""
	_current_index = 0
	_choices.clear()
	_line_queue.clear()
	_line_buffer_knot = ""
	_taken_choices.clear()
	_loaded = true
	_running = false
	_finished = false
	_stopped = false
	variables_changed.emit(_variables.duplicate(true))
	return true


func start(knot_name: String = "") -> bool:
	if not _loaded:
		return _fail("Carica un JSON Ink prima di avviare la storia.")
	var selected_knot := knot_name if not knot_name.is_empty() else _default_start_knot
	var target := _parse_divert_target(selected_knot)
	if target.is_empty():
		return _fail("Il knot iniziale non è disponibile o non è supportato: %s." % selected_knot)
	_variables = _read_global_variables(_program.get("global decl", []))
	_current_knot = str(target.knot)
	_current_index = int(target.index)
	_evaluation_stack.clear()
	_choices.clear()
	_line_queue.clear()
	_line_buffer = ""
	_line_tags.clear()
	_line_buffer_knot = ""
	_taken_choices.clear()
	_running = true
	_finished = false
	_stopped = false
	variables_changed.emit(_variables.duplicate(true))
	choices_available.emit(_copy_choices())
	_run_to_pause()
	_publish_next()
	return not _stopped


func continue_story() -> void:
	if not _running or _stopped:
		return
	if _line_queue.is_empty() and (not _choices.is_empty() or _finished):
		return
	_publish_next()


func choose(index: int) -> bool:
	if not _running or _stopped:
		return _fail("La storia non è in attesa di una scelta.")
	if not _line_queue.is_empty():
		return _fail("Continua il testo prima di selezionare una scelta.")
	if index < 0 or index >= _choices.size():
		return _fail("Indice di scelta fuori intervallo: %d." % index)
	var selected: Dictionary = _choices[index]
	if bool(selected.get("once_only", false)):
		_taken_choices[str(selected.get("key", ""))] = true
	_current_knot = str(selected.get("target", ""))
	_current_index = int(selected.get("target_index", 0))
	_choices.clear()
	choices_available.emit(_copy_choices())
	_run_to_pause()
	_publish_next()
	return not _stopped


func choose_target(target_knot: String) -> bool:
	if not _running or _stopped:
		return false
	if not _line_queue.is_empty() or _choices.is_empty():
		return false
	for index in range(_choices.size()):
		if str(_choices[index].get("target", "")) == target_knot:
			return choose(index)
	return false


func jump_to_knot(knot_name: String) -> bool:
	if not _loaded:
		return _fail("Carica un JSON Ink prima di saltare a un knot.")
	var target := _parse_divert_target(knot_name)
	if target.is_empty():
		return _fail("Knot non trovato o percorso non supportato: %s." % knot_name)
	_current_knot = str(target.knot)
	_current_index = int(target.index)
	_running = true
	_finished = false
	_stopped = false
	_choices.clear()
	_line_queue.clear()
	_line_buffer = ""
	_line_tags.clear()
	_line_buffer_knot = ""
	choices_available.emit(_copy_choices())
	_run_to_pause()
	_publish_next()
	return not _stopped


func stop() -> void:
	_stopped = true
	_running = false
	_line_queue.clear()
	_choices.clear()


func get_variable(name: String, fallback: Variant = null) -> Variant:
	return _variables.get(name, fallback)


func get_variables() -> Dictionary:
	return _variables.duplicate(true)


func get_current_knot() -> String:
	return _current_knot


func get_choices() -> Array[Dictionary]:
	return _copy_choices()


func has_pending_content() -> bool:
	return not _line_queue.is_empty()


func is_waiting_for_choice() -> bool:
	return _line_queue.is_empty() and not _choices.is_empty()


func _run_to_pause() -> void:
	_line_queue.clear()
	_choices.clear()
	_line_buffer = ""
	_line_tags.clear()
	var steps := 0
	while not _finished and not _stopped:
		steps += 1
		if steps > MAX_EXECUTION_STEPS:
			_fail("Interruzione di sicurezza: superato il limite di istruzioni senza pausa.")
			return
		var sequence := _get_knot_sequence(_current_knot)
		if sequence.is_empty():
			_fail("Knot vuoto o non trovato: %s." % _current_knot)
			return
		var result := _execute_sequence(sequence, _current_index)
		if _stopped:
			return
		if bool(result.get("ended", false)):
			_finished = true
			break
		if bool(result.get("diverted", false)):
			_current_knot = str(result.target)
			_current_index = int(result.index)
			continue
		if not _choices.is_empty():
			break
		_finished = true
		break
	_flush_line()


func _publish_next() -> void:
	if _stopped:
		return
	if not _line_queue.is_empty():
		var item: Dictionary = _line_queue.pop_front()
		line_emitted.emit(str(item.text), item.tags, str(item.knot))
		if _stopped:
			return
	if _line_queue.is_empty():
		if not _choices.is_empty():
			choices_available.emit(_copy_choices())
		elif _finished:
			story_ended.emit()


func _execute_sequence(sequence: Array, start_index: int) -> Dictionary:
	var index := maxi(start_index, 0)
	while index < sequence.size() and not _stopped:
		var token: Variant = sequence[index]
		if token == null or (token is String and token == "nop"):
			index += 1
			continue
		if token is String and (token == "end" or token == "done"):
			return {"ended": true}
		if token is String and token == "ev":
			var expression_end := _find_eval_end(sequence, index + 1)
			if expression_end < 0:
				return _error_result("Blocco 'ev' senza '/ev' nel knot %s." % _current_knot)
			_run_expression(sequence.slice(index + 1, expression_end))
			if _stopped:
				return {"ended": true}
			index = expression_end + 1
			if index < sequence.size() and _is_branch_entry(sequence[index]):
				var branch_result := _execute_branch_group(sequence, index, _last_value(), true)
				if branch_result.has("diverted") or branch_result.has("ended"):
					return branch_result
				if branch_result.has("jump_index"):
					index = int(branch_result.jump_index)
				else:
					index = int(branch_result.next_index)
			continue
		if token is Array:
			if _is_branch_entry(token):
				var nested_branch := _execute_branch_group(sequence, index, null, false)
				if nested_branch.has("diverted") or nested_branch.has("ended"):
					return nested_branch
				if nested_branch.has("jump_index"):
					index = int(nested_branch.jump_index)
				else:
					index = int(nested_branch.next_index)
				continue
			var nested_result := _execute_sequence(token, 0)
			if nested_result.has("diverted") or nested_result.has("ended"):
				return nested_result
			if nested_result.has("jump_index"):
				return nested_result
			index += 1
			continue
		if token is Dictionary:
			if token.has("VAR="):
				var variable_name := str(token["VAR="])
				_variables[variable_name] = _pop_value("assegnazione a %s" % variable_name)
				variables_changed.emit(_variables.duplicate(true))
			elif token.has("*"):
				_add_choice(token)
			elif token.has("->"):
				_flush_line()
				var divert_path := str(token["->"])
				if divert_path.begins_with(".^"):
					var local_index := _relative_index(divert_path)
					if local_index >= 0:
						return {"jump_index": local_index}
				else:
					var target := _parse_divert_target(divert_path)
					if target.is_empty():
						return _error_result("Divert verso un knot non supportato: %s." % divert_path)
					return {"diverted": true, "target": target.knot, "index": target.index}
			elif _is_named_child_dictionary(token):
				pass
			else:
				return _error_result("Istruzione JSON non supportata nel knot %s: %s." % [_current_knot, str(token.keys())])
			index += 1
			continue
		if token is String:
			var text_token := str(token)
			match text_token:
				"#":
					if _line_buffer_knot.is_empty():
						_line_buffer_knot = _current_knot
					_line_tags.append("__tag_start__")
				"/#":
					if not _line_tags.is_empty() and _line_tags[-1] == "__tag_start__":
						_line_tags.remove_at(_line_tags.size() - 1)
				"\n":
					_flush_line()
				"/ev":
					return _error_result("'/ev' non associato a 'ev' nel knot %s." % _current_knot)
				"out", "/str", "!", "&&", "||", "+", "-", "*", "/", "%", "==", "!=", ">", ">=", "<", "<=", "str":
					return _error_result("Operatore Ink fuori da un blocco 'ev': %s." % text_token)
				_:
					if text_token.begins_with("^"):
						var value := text_token.substr(1)
						if _has_open_tag():
							_line_tags.remove_at(_line_tags.size() - 1)
							_line_tags.append(value)
						else:
							if _line_buffer_knot.is_empty():
								_line_buffer_knot = _current_knot
							_line_buffer += value
					else:
						return _error_result("Opcode Ink non supportato: %s." % text_token)
			index += 1
			continue
		return _error_result("Token JSON Ink non supportato: %s." % str(token))
	return {}


func _execute_branch_group(sequence: Array, start_index: int, outer_condition: Variant, has_outer_condition: bool) -> Dictionary:
	var branches: Array[Dictionary] = []
	var index := start_index
	var common_join := -1
	while index < sequence.size():
		var branch := _parse_branch_entry(sequence[index])
		if branch.is_empty():
			break
		var join_index := int(branch.get("join_index", -1))
		if not branches.is_empty() and common_join >= 0 and join_index >= 0 and join_index != common_join:
			break
		if common_join < 0 and join_index >= 0:
			common_join = join_index
		branches.append(branch)
		index += 1
	if branches.is_empty():
		return {"next_index": start_index + 1}

	for branch in branches:
		var branch_condition: Variant = true
		if bool(branch.get("has_condition", false)):
			if bool(branch.get("has_local_condition", false)):
				branch_condition = branch.condition
			elif has_outer_condition:
				branch_condition = outer_condition
			else:
				return _error_result("Ramo condizionale senza espressione nel knot %s." % _current_knot)
		if not bool(branch_condition):
			continue
		var body_result := _execute_sequence(branch.body, 0)
		if body_result.has("diverted") or body_result.has("ended"):
			return body_result
		if body_result.has("jump_index"):
			return body_result
		var body_join := int(branch.get("join_index", -1))
		if body_join >= 0:
			return {"jump_index": body_join}
		return {"next_index": index}

	if common_join >= 0:
		return {"jump_index": common_join}
	return {"next_index": index}


func _parse_branch_entry(entry: Variant) -> Dictionary:
	if not entry is Array:
		return {}
	var values: Array = entry
	var local_condition: Variant = null
	var has_local_condition := false
	var marker: Dictionary = {}
	var body: Array = []
	var index := 0
	while index < values.size():
		if values[index] is String and values[index] == "ev":
			var expression_end := _find_eval_end(values, index + 1)
			if expression_end < 0:
				return {}
			local_condition = _evaluate_expression(values.slice(index + 1, expression_end))
			if _stopped:
				return {}
			has_local_condition = true
			index = expression_end + 1
			continue
		var value: Variant = values[index]
		if value is Dictionary and str(value.get("->", "")) == ".^.b":
			marker = value
			if index + 1 < values.size() and values[index + 1] is Dictionary and values[index + 1].has("b") and values[index + 1].b is Array:
				body = values[index + 1].b
				break
			return {}
		index += 1
	if marker.is_empty():
		return {}
	var has_condition := bool(marker.get("c", false))
	var join_index := _find_join_index(body)
	return {
		"has_condition": has_condition,
		"has_local_condition": has_local_condition,
		"condition": local_condition,
		"body": body,
		"join_index": join_index,
	}


func _run_expression(tokens: Array) -> void:
	_evaluation_stack.clear()
	var string_capture := false
	var captured_string := ""
	for token in tokens:
		if _stopped:
			return
		if token is Dictionary and token.has("VAR?"):
			var name := str(token["VAR?"])
			if not _variables.has(name):
				_fail("Variabile Ink non inizializzata: %s." % name)
				return
			_evaluation_stack.append(_variables[name])
		elif token is String:
			match str(token):
				"str":
						string_capture = true
						captured_string = ""
				"/str":
						_evaluation_stack.append(captured_string)
						string_capture = false
				"out":
						var output_value: Variant = _pop_value("out")
						if string_capture:
							captured_string += _format_value(output_value)
						else:
							if _line_buffer_knot.is_empty():
								_line_buffer_knot = _current_knot
							_line_buffer += _format_value(output_value)
				"!":
						_evaluation_stack.append(not bool(_pop_value("!")))
				"&&", "||", "+", "-", "*", "/", "%", "==", "!=", ">", ">=", "<", "<=":
						_apply_operator(str(token))
				"ev", "/ev", "nop":
						pass
				_:
						if str(token).begins_with("^") and string_capture:
							captured_string += str(token).substr(1)
						else:
							_fail("Opcode in espressione Ink non supportato: %s." % str(token))
							return
		elif token is bool or token is int or token is float:
			_evaluation_stack.append(_normalize_number(token))
		else:
			_fail("Valore in espressione Ink non supportato: %s." % str(token))


func _evaluate_expression(tokens: Array) -> Variant:
	var previous_stack := _evaluation_stack
	_evaluation_stack = []
	_run_expression(tokens)
	var result: Variant = _last_value()
	_evaluation_stack = previous_stack
	return result


func _apply_operator(operator: String) -> void:
	var right: Variant = _pop_value(operator)
	var left: Variant = _pop_value(operator)
	match operator:
		"&&": _evaluation_stack.append(bool(left) and bool(right))
		"||": _evaluation_stack.append(bool(left) or bool(right))
		"+": _evaluation_stack.append(int(left) + int(right) if left is int and right is int else left + right)
		"-": _evaluation_stack.append(int(left) - int(right) if left is int and right is int else left - right)
		"*": _evaluation_stack.append(int(left) * int(right) if left is int and right is int else left * right)
		"/":
			if float(right) == 0.0:
				_fail("Divisione per zero in espressione Ink.")
			elif left is int and right is int:
				_evaluation_stack.append(int(float(left) / float(right)))
			else:
				_evaluation_stack.append(float(left) / float(right))
		"%":
			if int(right) == 0:
				_fail("Modulo per zero in espressione Ink.")
			else:
				_evaluation_stack.append(int(left) % int(right))
		"==": _evaluation_stack.append(left == right)
		"!=": _evaluation_stack.append(left != right)
		">": _evaluation_stack.append(left > right)
		">=": _evaluation_stack.append(left >= right)
		"<": _evaluation_stack.append(left < right)
		"<=": _evaluation_stack.append(left <= right)


func _add_choice(point: Dictionary) -> void:
	var flags := int(point.get("flg", 0))
	var has_condition := (flags & 1) != 0
	var condition: Variant = true
	if has_condition:
		condition = _pop_value("condizione scelta")
	var label_value: Variant = _pop_value("testo scelta")
	if not bool(condition):
		return
	var route := str(point.get("*", ""))
	var choice_id := route.get_slice(".", route.get_slice_count(".") - 1)
	var key := "%s/%s" % [_current_knot, choice_id]
	var once_only := (flags & 16) != 0
	if once_only and _taken_choices.has(key):
		return
	var target := _find_choice_target(_get_knot_sequence(_current_knot), choice_id)
	if target.is_empty():
		_fail("Destinazione della scelta non trovata: %s in %s." % [choice_id, _current_knot])
		return
	_choices.append({
		"index": _choices.size(),
		"text": _format_value(label_value).strip_edges(),
		"target": target.knot,
		"target_index": target.index,
		"once_only": once_only,
		"key": key,
		"tags": PackedStringArray(),
	})


func _find_choice_target(value: Variant, choice_id: String) -> Dictionary:
	if value is Dictionary:
		if value.has(choice_id):
			var direct_target := _find_first_divert(value[choice_id])
			if not direct_target.is_empty():
				return _parse_divert_target(direct_target)
		for key in value.keys():
			var nested := _find_choice_target(value[key], choice_id)
			if not nested.is_empty():
				return nested
	elif value is Array:
		for child in value:
			var nested := _find_choice_target(child, choice_id)
			if not nested.is_empty():
				return nested
	return {}


func _find_first_divert(value: Variant) -> String:
	if value is Dictionary:
		if value.has("->"):
			var path := str(value["->"])
			if not path.begins_with("."):
				return path
		for key in value.keys():
			var nested := _find_first_divert(value[key])
			if not nested.is_empty():
				return nested
	elif value is Array:
		for child in value:
			var nested := _find_first_divert(child)
			if not nested.is_empty():
				return nested
	return ""


func _find_join_index(value: Variant) -> int:
	if value is Dictionary:
		if value.has("->"):
			var local_index := _relative_index(str(value["->"]))
			if local_index >= 0:
				return local_index
		for key in value.keys():
			var nested := _find_join_index(value[key])
			if nested >= 0:
				return nested
	elif value is Array:
		for child in value:
			var nested := _find_join_index(child)
			if nested >= 0:
				return nested
	return -1


func _parse_divert_target(path: String) -> Dictionary:
	if path.is_empty() or path.begins_with("."):
		return {}
	var parts := path.split(".")
	var knot := str(parts[0])
	if not _program.has(knot) or not _program[knot] is Array:
		return {}
	var target_index := 0
	if parts.size() > 1:
		if not str(parts[1]).is_valid_int():
			return {}
		target_index = int(parts[1])
	return {"knot": knot, "index": target_index}


func _get_knot_sequence(knot_name: String) -> Array:
	var path_parts := knot_name.split(".")
	var base := str(path_parts[0])
	if not _program.has(base) or not _program[base] is Array:
		return []
	return _program[base]


func _relative_index(path: String) -> int:
	if not path.begins_with(".^"):
		return -1
	var final_part := path.get_slice(".", path.get_slice_count(".") - 1)
	return int(final_part) if final_part.is_valid_int() else -1


func _find_eval_end(sequence: Array, start_index: int) -> int:
	for index in range(start_index, sequence.size()):
		if sequence[index] is String and sequence[index] == "/ev":
			return index
	return -1


func _is_branch_entry(value: Variant) -> bool:
	return not _parse_branch_entry(value).is_empty()


func _is_named_child_dictionary(value: Dictionary) -> bool:
	for key in value.keys():
		if str(key).begins_with("c-") or key == "b":
			return true
	return false


func _has_open_tag() -> bool:
	return not _line_tags.is_empty() and _line_tags[-1] == "__tag_start__"


func _flush_line() -> void:
	if _line_buffer.is_empty() and _line_tags.is_empty():
		return
	var clean_tags := PackedStringArray()
	for tag in _line_tags:
		if tag != "__tag_start__":
			clean_tags.append(tag)
	_line_queue.append({"text": _line_buffer, "tags": clean_tags, "knot": _line_buffer_knot if not _line_buffer_knot.is_empty() else _current_knot})
	_line_buffer = ""
	_line_tags.clear()
	_line_buffer_knot = ""


func _last_value() -> Variant:
	return _evaluation_stack.back() if not _evaluation_stack.is_empty() else null


func _pop_value(context: String) -> Variant:
	if _evaluation_stack.is_empty():
		_fail("Stack Ink vuoto durante %s nel knot %s." % [context, _current_knot])
		return null
	return _evaluation_stack.pop_back()


func _format_value(value: Variant) -> String:
	if value is bool:
		return "true" if value else "false"
	if value is float and is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return str(value)


func _copy_choices() -> Array[Dictionary]:
	var copied: Array[Dictionary] = []
	for choice in _choices:
		copied.append(choice.duplicate(true))
	return copied


func _read_global_variables(declarations: Array) -> Dictionary:
	var values: Dictionary = {}
	for index in range(1, declarations.size()):
		var token: Variant = declarations[index]
		if token is Dictionary and token.has("VAR=") and index > 0:
			values[str(token["VAR="])] = _normalize_number(declarations[index - 1])
	return values


func _normalize_number(value: Variant) -> Variant:
	if value is bool:
		return value
	if value is float and is_equal_approx(value, round(value)):
		return int(round(value))
	return value


func _read_start_knot(header: Array) -> String:
	for item in header:
		if item is Dictionary and item.has("->"):
			var target := str(item["->"])
			if not target.begins_with("."):
				return target
	return ""


func _validate_program(program: Dictionary) -> String:
	var allowed_ops := ["ev", "/ev", "out", "str", "/str", "nop", "end", "done", "#", "/#", "!", "&&", "||", "+", "-", "*", "/", "%", "==", "!=", ">", ">=", "<", "<=", "\n"]
	for knot_name in program.keys():
		if not program[knot_name] is Array:
			continue
		var error := _validate_value(program[knot_name], allowed_ops)
		if not error.is_empty():
			return "Bytecode Ink non supportato in '%s': %s" % [str(knot_name), error]
	return ""


func _validate_value(value: Variant, allowed_ops: Array) -> String:
	if value is String:
		var token := str(value)
		if token.begins_with("^") or allowed_ops.has(token):
			return ""
		return "opcode '%s'" % token
	if value is Array:
		for child in value:
			var error := _validate_value(child, allowed_ops)
			if not error.is_empty():
				return error
	elif value is Dictionary:
		for key in value.keys():
			var key_text := str(key)
			if key_text in ["->", "VAR?", "VAR=", "*", "flg", "c", "b", "re", "#f", "#n"] or key_text.begins_with("c-"):
				if key_text in ["b"] or key_text.begins_with("c-"):
					var error := _validate_value(value[key], allowed_ops)
					if not error.is_empty():
						return error
				continue
			return "campo '%s'" % key_text
	return ""


func _error_result(message: String) -> Dictionary:
	_fail(message)
	return {"ended": true}


func _fail(message: String) -> bool:
	_stopped = true
	_running = false
	_line_queue.clear()
	_choices.clear()
	choices_available.emit(_copy_choices())
	runtime_error.emit(message)
	return false
