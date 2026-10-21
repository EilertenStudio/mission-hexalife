extends Node

signal line_emitted(text: String, tags: PackedStringArray, knot_name: String)
signal choices_available(choices: Array[Dictionary])
signal variables_changed(variables: Dictionary)
signal cue_requested(kind: String, id: String)
signal story_ended
signal runtime_error(message: String)

const InkStoryRuntime = preload("res://addons/ink_scene_director/ink_story_runtime.gd")
const CUE_KINDS := ["scene", "actor", "camera", "audio"]

@export_file("*.json") var story_json_path := ""

var _runtime: RefCounted = InkStoryRuntime.new()
var _cue_handlers: Dictionary = {
	"scene": {},
	"actor": {},
	"camera": {},
	"audio": {},
}


func _ready() -> void:
	_runtime.line_emitted.connect(_on_runtime_line)
	_runtime.choices_available.connect(func(choices: Array[Dictionary]) -> void: choices_available.emit(choices))
	_runtime.variables_changed.connect(func(variables: Dictionary) -> void: variables_changed.emit(variables))
	_runtime.story_ended.connect(func() -> void: story_ended.emit())
	_runtime.runtime_error.connect(func(message: String) -> void: runtime_error.emit(message))


func register_scene_cue(id: String, handler: Callable) -> bool:
	return _register_cue("scene", id, handler)


func register_actor_cue(id: String, handler: Callable) -> bool:
	return _register_cue("actor", id, handler)


func register_camera_cue(id: String, handler: Callable) -> bool:
	return _register_cue("camera", id, handler)


func register_audio_cue(id: String, handler: Callable) -> bool:
	return _register_cue("audio", id, handler)


func load_story(path: String = "") -> bool:
	var selected_path := path if not path.is_empty() else story_json_path
	return _runtime.load_json_file(selected_path)


func load_story_text(source: String) -> bool:
	return _runtime.load_json_text(source)


func start_story(knot_name: String = "") -> bool:
	return _runtime.start(knot_name)


func continue_story() -> void:
	_runtime.continue_story()


func choose(index: int) -> bool:
	return _runtime.choose(index)


## Select an Ink choice by the destination knot, if it is currently available.
func choose_target(target_knot: String) -> bool:
	return _runtime.choose_target(target_knot)


func jump_to_knot(knot_name: String) -> bool:
	return _runtime.jump_to_knot(knot_name)


func stop_story() -> void:
	_runtime.stop()


func get_variable(name: String, fallback: Variant = null) -> Variant:
	return _runtime.get_variable(name, fallback)


func get_variables() -> Dictionary:
	return _runtime.get_variables()


func get_choices() -> Array[Dictionary]:
	return _runtime.get_choices()


func get_current_knot() -> String:
	return _runtime.get_current_knot()


func has_pending_content() -> bool:
	return _runtime.has_pending_content()


func is_waiting_for_choice() -> bool:
	return _runtime.is_waiting_for_choice()


func _register_cue(kind: String, id: String, handler: Callable) -> bool:
	if not CUE_KINDS.has(kind) or id.is_empty() or id.contains(":"):
		runtime_error.emit("Registrazione cue non valida: %s:%s." % [kind, id])
		return false
	if not handler.is_valid():
		runtime_error.emit("Handler non valido per il cue %s:%s." % [kind, id])
		return false
	_cue_handlers[kind][id] = handler
	return true


func _on_runtime_line(text: String, tags: PackedStringArray, knot_name: String) -> void:
	for tag in tags:
		var separator := tag.find(":")
		if separator < 1:
			continue
		var kind := tag.substr(0, separator)
		var id := tag.substr(separator + 1)
		if kind == "ui":
			continue
		if kind == "char":
			kind = "actor"
		if not CUE_KINDS.has(kind):
			_runtime.stop()
			runtime_error.emit("Tipo di tag/cue non supportato: %s." % kind)
			return
		if not _cue_handlers[kind].has(id):
			_runtime.stop()
			runtime_error.emit("Cue non registrato: %s:%s." % [kind, id])
			return
		var handler: Callable = _cue_handlers[kind][id]
		handler.call(id)
		cue_requested.emit(kind, id)
	line_emitted.emit(text, tags, knot_name)
