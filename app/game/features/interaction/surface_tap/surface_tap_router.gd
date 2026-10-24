extends Node
class_name SurfaceTapRouter

@export var targets_path: NodePath = ^"../Targets"

var _hovered_target: SurfaceTapTarget


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(event.position)
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			var target := _topmost_target_at(click.position)
			if target:
				target.activate()
				get_viewport().set_input_as_handled()


func _update_hover(screen_position: Vector2) -> void:
	var next_target := _topmost_target_at(screen_position)
	if next_target == _hovered_target:
		return
	if _hovered_target:
		_hovered_target.set_hovered(false)
	_hovered_target = next_target
	if _hovered_target:
		_hovered_target.set_hovered(true)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _topmost_target_at(screen_position: Vector2) -> SurfaceTapTarget:
	var target_container := get_node_or_null(targets_path)
	if target_container == null:
		return null

	var candidates: Array[SurfaceTapTarget] = []
	for child in target_container.get_children():
		if child is SurfaceTapTarget:
			candidates.append(child)
	candidates.sort_custom(_is_drawn_above)

	for target in candidates:
		if target.contains_opaque_pixel_at_screen_position(screen_position):
			return target
	return null


func _is_drawn_above(first: SurfaceTapTarget, second: SurfaceTapTarget) -> bool:
	if first.z_index == second.z_index:
		return first.get_index() > second.get_index()
	return first.z_index > second.z_index
