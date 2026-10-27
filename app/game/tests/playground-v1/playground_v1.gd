@tool
extends Node2D

const GARAGE_ROOM_SCENE: PackedScene = preload(
	"res://tests/playground-v1/assets/rooms/garage_room/garage_room.tscn"
)
const GENERATED_ROOM_NAME := "GarageRoom"

@export_tool_button("GENERATE")
var generate_node_tree_action: Callable = func(): generate_node_tree()


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
