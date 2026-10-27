@tool
extends Node2D

const GARAGE_ROOM_SCENE: PackedScene = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/garage_room.tscn"
)
const GENERATED_ROOM_NAME := "GarageRoom"

@onready var _lighting_controls: CanvasLayer = $GarageRoom/LightingControls
@onready var _crt_filter: ColorRect = $CRTVertical/ScreenFilter
@onready var _crt_material: ShaderMaterial = $CRTVertical/ScreenFilter.material as ShaderMaterial

@export_tool_button("GENERATE")
var generate_node_tree_action: Callable = func(): generate_node_tree()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_lighting_controls.crt_enabled_changed.connect(_on_crt_enabled_changed)
	_lighting_controls.crt_strength_changed.connect(_on_crt_strength_changed)
	_lighting_controls.crt_spacing_changed.connect(_on_crt_spacing_changed)
	_lighting_controls.call(
		"set_crt_control_values",
		_crt_filter.visible,
		_crt_material.get_shader_parameter("strength"),
		_crt_material.get_shader_parameter("period_px")
	)


func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.ctrl_pressed
		and event.keycode == KEY_EQUAL
	):
		_lighting_controls.visible = not _lighting_controls.visible
		get_viewport().set_input_as_handled()


func generate_node_tree() -> void:
	var editor_interface: Object = Engine.get_singleton(&"EditorInterface")
	if editor_interface == null:
		return
	if editor_interface.get_edited_scene_root() != self:
		push_error("GENERATE can only be used on the Playground V1 scene root.")
		return

	var current_room := get_node_or_null(GENERATED_ROOM_NAME)
	if current_room != null:
		remove_child(current_room)
		current_room.free()

	var room_instance := GARAGE_ROOM_SCENE.instantiate()
	room_instance.name = GENERATED_ROOM_NAME
	add_child(room_instance)
	_set_owner_recursive(room_instance, self)
	editor_interface.mark_scene_as_unsaved()


func _set_owner_recursive(node: Node, scene_root: Node) -> void:
	node.owner = scene_root
	for child: Node in node.get_children():
		_set_owner_recursive(child, scene_root)


func _on_crt_enabled_changed(is_enabled: bool) -> void:
	_crt_filter.visible = is_enabled


func _on_crt_strength_changed(value: float) -> void:
	_crt_material.set_shader_parameter("strength", value)


func _on_crt_spacing_changed(value: float) -> void:
	_crt_material.set_shader_parameter("period_px", value)
