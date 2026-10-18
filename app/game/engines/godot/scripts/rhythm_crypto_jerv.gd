extends Sprite2D

const COLUMNS := 10
const ROWS := 7
const CELL_SIZE := 32.0
const GRID_ORIGIN := Vector2(32.0, 32.0)
const IDLE_FRAME_COUNT := 2
const IDLE_FRAME_DURATION := 1.0
const FACING_ROW_DOWN := 0
const FACING_ROW_LEFT := 1
const FACING_ROW_UP := 2
const FACING_ROW_RIGHT := 3

const INITIAL_REPEAT_DELAY := 0.22
const REPEAT_INTERVAL := 0.12

var player_column := 4
var player_row_from_bottom := 3
var held_direction := Vector2i.ZERO
var repeat_timer := 0.0
var facing_row := FACING_ROW_DOWN
var idle_frame := 0
var idle_frame_timer := 0.0


func _ready() -> void:
	scale = Vector2.ONE
	region_enabled = true
	_set_idle_frame(0)
	_update_position()


func _process(delta: float) -> void:
	var direction := _read_direction()
	if direction == Vector2i.ZERO:
		held_direction = Vector2i.ZERO
		repeat_timer = 0.0
		_update_idle_animation(delta)
		return

	_set_facing_direction(direction)
	_reset_idle_animation()
	if direction != held_direction:
		held_direction = direction
		repeat_timer = INITIAL_REPEAT_DELAY
		_move_one_cell(direction)
	else:
		repeat_timer -= delta
		if repeat_timer <= 0.0:
			_move_one_cell(direction)
			repeat_timer = REPEAT_INTERVAL


func _update_idle_animation(delta: float) -> void:
	idle_frame_timer += delta
	if idle_frame_timer >= IDLE_FRAME_DURATION:
		idle_frame_timer = fmod(idle_frame_timer, IDLE_FRAME_DURATION)
		idle_frame = (idle_frame + 1) % IDLE_FRAME_COUNT
		_set_idle_frame(idle_frame)


func _reset_idle_animation() -> void:
	idle_frame_timer = 0.0
	if idle_frame != 0:
		idle_frame = 0
		_set_idle_frame(idle_frame)


func _set_idle_frame(frame: int) -> void:
	region_rect = Rect2(
		Vector2(frame * CELL_SIZE, facing_row * CELL_SIZE),
		Vector2(CELL_SIZE, CELL_SIZE)
	)


func _set_facing_direction(direction: Vector2i) -> void:
	var next_facing_row := FACING_ROW_DOWN
	if direction.x < 0:
		next_facing_row = FACING_ROW_LEFT
	elif direction.x > 0:
		next_facing_row = FACING_ROW_RIGHT
	elif direction.y > 0:
		next_facing_row = FACING_ROW_UP

	if next_facing_row == facing_row:
		return

	facing_row = next_facing_row
	idle_frame = 0
	idle_frame_timer = 0.0
	_set_idle_frame(idle_frame)


func _read_direction() -> Vector2i:
	if Input.is_physical_key_pressed(KEY_I):
		return Vector2i(0, 1)
	if Input.is_physical_key_pressed(KEY_J):
		return Vector2i(-1, 0)
	if Input.is_physical_key_pressed(KEY_K):
		return Vector2i(0, -1)
	if Input.is_physical_key_pressed(KEY_L):
		return Vector2i(1, 0)
	return Vector2i.ZERO


func _move_one_cell(direction: Vector2i) -> void:
	var next_column := player_column + direction.x
	var next_row := player_row_from_bottom + direction.y
	if next_column >= 0 and next_column < COLUMNS and next_row >= 0 and next_row < ROWS:
		player_column = next_column
		player_row_from_bottom = next_row
		_update_position()


func _update_position() -> void:
	position = Vector2(
		GRID_ORIGIN.x + (player_column + 0.5) * CELL_SIZE,
		GRID_ORIGIN.y + (ROWS - player_row_from_bottom - 0.5) * CELL_SIZE
	)
