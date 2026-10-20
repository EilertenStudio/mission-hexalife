extends Sprite2D

const COLUMNS := 12
const ROWS := 9
const CELL_SIZE := 32.0
const START_CELL := Vector2i(2, 4)
const IDLE_START_COLUMN := 0
const BLACK_HOLE_START_COLUMN := 2
const WHITE_HOLE_START_COLUMN := 6
const CAST_FRAME_COUNT := 4
const CAST_FRAME_DURATION := 0.18

const FACING_ROW_DOWN := 0
const FACING_ROW_LEFT := 1
const FACING_ROW_UP := 2
const FACING_ROW_RIGHT := 3

var grid_cell := START_CELL
var facing_row := FACING_ROW_DOWN
var active_spell_pose := ""
var active_spell_frame := 0
var spell_pose_timer := 0.0

@onready var spell_vfx: Node = get_parent().get_node("SpellVFX")


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	region_enabled = true
	grid_cell = START_CELL
	_update_pose_and_position()


func _process(delta: float) -> void:
	if active_spell_pose.is_empty():
		return
	spell_pose_timer += delta
	var next_frame := mini(int(spell_pose_timer / CAST_FRAME_DURATION), CAST_FRAME_COUNT - 1)
	if spell_pose_timer >= CAST_FRAME_DURATION * CAST_FRAME_COUNT:
		active_spell_pose = ""
		active_spell_frame = 0
		spell_pose_timer = 0.0
		_update_pose_and_position()
	elif next_frame != active_spell_frame:
		active_spell_frame = next_frame
		_update_pose_and_position()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var key := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	if key_event.alt_pressed and key in [KEY_A, KEY_S, KEY_D]:
		var spell_to_cancel := _spell_for_key(key)
		spell_vfx.call("cancel", spell_to_cancel)
		if active_spell_pose == spell_to_cancel:
			active_spell_pose = ""
			active_spell_frame = 0
			spell_pose_timer = 0.0
			_update_pose_and_position()
		get_viewport().set_input_as_handled()
		return
	if key in [KEY_A, KEY_S, KEY_D]:
		_cast_spell(_spell_for_key(key), key_event.shift_pressed)
		get_viewport().set_input_as_handled()
		return
	var direction := Vector2i.ZERO
	match key:
		KEY_I:
			direction = Vector2i(0, 1)
			facing_row = FACING_ROW_UP
		KEY_J:
			direction = Vector2i(-1, 0)
			facing_row = FACING_ROW_LEFT
		KEY_K:
			direction = Vector2i(0, -1)
			facing_row = FACING_ROW_DOWN
		KEY_L:
			direction = Vector2i(1, 0)
			facing_row = FACING_ROW_RIGHT
	if direction == Vector2i.ZERO:
		return
	var destination := grid_cell + direction
	if destination.x >= 1 and destination.x < COLUMNS - 1 and destination.y >= 1 and destination.y < ROWS - 1:
		grid_cell = destination
	_update_pose_and_position()
	get_viewport().set_input_as_handled()


func _spell_for_key(key: int) -> String:
	match key:
		KEY_A:
			return "black_hole"
		KEY_S:
			return "white_hole"
		_:
			return "gravity_star"


func _cast_spell(spell: String, full_cast: bool) -> void:
	var facing := Vector2i.ZERO
	match facing_row:
		FACING_ROW_UP:
			facing = Vector2i(0, 1)
		FACING_ROW_LEFT:
			facing = Vector2i(-1, 0)
		FACING_ROW_DOWN:
			facing = Vector2i(0, -1)
		FACING_ROW_RIGHT:
			facing = Vector2i(1, 0)
	var target_cell := grid_cell + facing
	spell_vfx.call("cast", spell, target_cell, full_cast)
	active_spell_pose = spell if spell in ["black_hole", "white_hole"] else ""
	active_spell_frame = 0
	spell_pose_timer = 0.0
	_update_pose_and_position()


func get_grid_cell() -> Vector2i:
	return grid_cell


func _update_pose_and_position() -> void:
	position = Vector2(grid_cell.x + 0.5, ROWS - grid_cell.y - 0.5) * CELL_SIZE
	var column := IDLE_START_COLUMN
	if active_spell_pose == "black_hole":
		column = BLACK_HOLE_START_COLUMN + active_spell_frame
	elif active_spell_pose == "white_hole":
		column = WHITE_HOLE_START_COLUMN + active_spell_frame
	region_rect = Rect2(Vector2(column * int(CELL_SIZE), facing_row * int(CELL_SIZE)), Vector2(CELL_SIZE, CELL_SIZE))
