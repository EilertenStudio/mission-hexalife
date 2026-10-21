@tool
extends RefCounted


func generate(scene_root: Control, expected_scene_path: String) -> bool:
	if (
		EditorInterface.get_edited_scene_root() != scene_root
		or scene_root.scene_file_path != expected_scene_path
	):
		push_error("Open the test-gameplay-ink scene to generate its node tree")
		return false
	if not bool(scene_root.call("_materialize_node_tree")):
		return false
	EditorInterface.mark_scene_as_unsaved()
	return true
