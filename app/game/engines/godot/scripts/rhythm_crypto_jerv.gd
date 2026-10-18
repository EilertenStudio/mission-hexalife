extends Sprite2D

const COLUMNS := 10
const ROWS := 7
const CELL_SIZE := 32.0
const GRID_ORIGIN := Vector2(32.0, 32.0)
const IDLE_FRAME_COUNT := 2
const IDLE_FRAME_BEATS := 2.0
const ATTACK_FRAME_COUNT := 4
const BLACK_HOLE_START_COLUMN := 2
const WHITE_HOLE_START_COLUMN := 6
const DEFAULT_BPM := 120.0
const MIN_BPM := 40.0
const MAX_BPM := 240.0
const BPM_STEP := 5.0
const FREE_MOVE_INITIAL_DELAY := 0.22
const FREE_MOVE_REPEAT_INTERVAL := 0.12
const DEFAULT_ANIMATION_BEAT_DURATION := 60.0 / DEFAULT_BPM
const BPM_PROFILE_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
const BPM_PROFILE_VALUES := [60.0, 80.0, 100.0, 120.0, 140.0, 160.0]

const FACING_ROW_DOWN := 0
const FACING_ROW_LEFT := 1
const FACING_ROW_UP := 2
const FACING_ROW_RIGHT := 3

@onready var grid: Node = get_parent().get_node("Grid")
@onready var metronome: Node = get_parent().get_node("Metronome")

var player_column := 4
var player_row_from_bottom := 3
var queued_direction := Vector2i.ZERO
var queued_attack := ""
var beat_timer := 0.0
var bpm := DEFAULT_BPM
var bpm_enabled := true
var beat_duration := 60.0 / DEFAULT_BPM
var animation_beat_duration := DEFAULT_ANIMATION_BEAT_DURATION
var idle_frame_duration := DEFAULT_ANIMATION_BEAT_DURATION * IDLE_FRAME_BEATS
var attack_frame_duration := DEFAULT_ANIMATION_BEAT_DURATION / ATTACK_FRAME_COUNT
var turn_count := 0
var bpm_profile := "P4"
var free_move_direction := Vector2i.ZERO
var free_move_timer := 0.0
var facing_row := FACING_ROW_DOWN
var facing_direction := Vector2i(0, -1)
var idle_frame := 0
var idle_frame_timer := 0.0
var active_attack := ""
var active_attack_frame := 0
var attack_timer := 0.0


func _ready() -> void:
	scale = Vector2.ONE
	region_enabled = true
	_set_idle_frame(0)
	grid.call("set_tempo", bpm, bpm_profile)
	_update_position()
	_update_target_cell()


func _process(delta: float) -> void:
	if not active_attack.is_empty():
		_update_attack_animation(delta)
	else:
		_update_idle_animation(delta)

	if bpm_enabled:
		beat_timer += delta
		while beat_timer >= beat_duration:
			beat_timer -= beat_duration
			_advance_turn()
		var cycle_phase := fposmod(float(turn_count) + beat_timer / beat_duration, 2.0) / 2.0
		grid.call("set_timing_phase", cycle_phase)
	else:
		if not queued_attack.is_empty() or queued_direction != Vector2i.ZERO:
			_resolve_queued_action()
		_update_free_mode_repeat(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_0 or key_event.physical_keycode == KEY_0:
		_toggle_bpm_enabled()
		get_viewport().set_input_as_handled()
		return
	if _handle_tempo_key(key_event.keycode):
		get_viewport().set_input_as_handled()
		return
	var direction := Vector2i.ZERO
	var attack := ""
	match key_event.physical_keycode:
		KEY_I:
			direction = Vector2i(0, 1)
		KEY_J:
			direction = Vector2i(-1, 0)
		KEY_K:
			direction = Vector2i(0, -1)
		KEY_L:
			direction = Vector2i(1, 0)
		KEY_A:
			attack = "black_hole"
		KEY_S:
			attack = "white_hole"

	if not attack.is_empty():
		if bpm_enabled:
			queued_attack = attack
		else:
			_perform_attack(attack)
	elif direction != Vector2i.ZERO:
		if bpm_enabled:
			queued_direction = direction
		else:
			free_move_direction = direction
			free_move_timer = FREE_MOVE_INITIAL_DELAY
			_perform_movement(direction)
	if not attack.is_empty() or direction != Vector2i.ZERO:
		get_viewport().set_input_as_handled()


func _handle_tempo_key(key: int) -> bool:
	if not bpm_enabled:
		return false
	var profile_index := BPM_PROFILE_KEYS.find(key)
	if profile_index >= 0:
		_set_bpm(BPM_PROFILE_VALUES[profile_index], "P%d" % (profile_index + 1))
		return true

	if key == KEY_BRACKETLEFT:
		var next_bpm := clampf(bpm + BPM_STEP, MIN_BPM, MAX_BPM)
		_set_bpm(next_bpm, _profile_name_for_bpm(next_bpm))
		return true
	if key == KEY_BRACKETRIGHT:
		var next_bpm := clampf(bpm - BPM_STEP, MIN_BPM, MAX_BPM)
		_set_bpm(next_bpm, _profile_name_for_bpm(next_bpm))
		return true
	return false


func _set_bpm(value: float, profile_name: String) -> void:
	var beat_phase := beat_timer / beat_duration
	bpm = clampf(value, MIN_BPM, MAX_BPM)
	beat_duration = 60.0 / bpm
	beat_timer = beat_phase * beat_duration
	bpm_profile = profile_name
	_set_animation_beat_duration(beat_duration)
	grid.call("set_tempo", bpm, bpm_profile)
	grid.call("set_bpm_enabled", bpm_enabled)


func _set_animation_beat_duration(value: float) -> void:
	var idle_frame_phase := idle_frame_timer / idle_frame_duration
	var attack_phase := attack_timer / animation_beat_duration
	animation_beat_duration = value
	idle_frame_duration = animation_beat_duration * IDLE_FRAME_BEATS
	attack_frame_duration = animation_beat_duration / ATTACK_FRAME_COUNT
	idle_frame_timer = idle_frame_phase * idle_frame_duration
	attack_timer = attack_phase * animation_beat_duration
	if not active_attack.is_empty():
		active_attack_frame = mini(int(attack_timer / attack_frame_duration), ATTACK_FRAME_COUNT - 1)
		_set_attack_frame()


func _toggle_bpm_enabled() -> void:
	bpm_enabled = not bpm_enabled
	beat_timer = 0.0
	free_move_direction = Vector2i.ZERO
	free_move_timer = 0.0
	var animation_duration := beat_duration if bpm_enabled else DEFAULT_ANIMATION_BEAT_DURATION
	_set_animation_beat_duration(animation_duration)
	metronome.call("set_enabled", bpm_enabled)
	grid.call("set_bpm_enabled", bpm_enabled)


func _profile_name_for_bpm(value: float) -> String:
	var profile_index := BPM_PROFILE_VALUES.find(value)
	return "P%d" % (profile_index + 1) if profile_index >= 0 else "CUSTOM"


func _advance_turn() -> void:
	turn_count += 1
	metronome.call("play_tick")
	grid.call("advance_turn", turn_count)
	_resolve_queued_action()


func _resolve_queued_action() -> void:
	var direction := queued_direction
	if queued_attack.is_empty() and direction == Vector2i.ZERO:
		direction = _read_direction()
	var has_action := not queued_attack.is_empty() or direction != Vector2i.ZERO
	if not has_action:
		return

	if not queued_attack.is_empty():
		var attack := queued_attack
		queued_attack = ""
		_perform_attack(attack)
		return

	queued_direction = Vector2i.ZERO
	_perform_movement(direction)


func _prepare_for_player_action() -> void:
	var has_active_vfx := bool(grid.call("has_active_effect"))
	if not active_attack.is_empty() or has_active_vfx:
		_cancel_active_animation()
		grid.call("cancel_active_effect")


func _perform_attack(attack: String) -> void:
	_prepare_for_player_action()
	_start_attack(attack)


func _perform_movement(direction: Vector2i) -> void:
	_prepare_for_player_action()
	_set_facing_direction(direction)
	_reset_idle_animation()
	_move_one_cell(direction)


func _update_free_mode_repeat(delta: float) -> void:
	var direction := _read_direction()
	if direction == Vector2i.ZERO:
		free_move_direction = Vector2i.ZERO
		free_move_timer = 0.0
		return
	if direction != free_move_direction:
		free_move_direction = direction
		free_move_timer = FREE_MOVE_INITIAL_DELAY
		return
	free_move_timer -= delta
	if free_move_timer <= 0.0:
		_perform_movement(direction)
		free_move_timer = FREE_MOVE_REPEAT_INTERVAL


func _cancel_active_animation() -> void:
	active_attack = ""
	active_attack_frame = 0
	attack_timer = 0.0
	idle_frame = 0
	idle_frame_timer = 0.0
	_set_idle_frame(idle_frame)


func _update_idle_animation(delta: float) -> void:
	idle_frame_timer += delta
	if idle_frame_timer >= idle_frame_duration:
		var frame_steps := int(idle_frame_timer / idle_frame_duration)
		idle_frame_timer = fmod(idle_frame_timer, idle_frame_duration)
		idle_frame = (idle_frame + frame_steps) % IDLE_FRAME_COUNT
		_set_idle_frame(idle_frame)


func _reset_idle_animation() -> void:
	var frame_changed := idle_frame != 0
	idle_frame = 0
	idle_frame_timer = 0.0
	if frame_changed:
		_set_idle_frame(idle_frame)


func _update_attack_animation(delta: float) -> void:
	attack_timer += delta
	if attack_timer >= animation_beat_duration:
		active_attack = ""
		active_attack_frame = 0
		attack_timer = 0.0
		idle_frame = 0
		idle_frame_timer = 0.0
		_set_idle_frame(idle_frame)
		return

	var next_frame := int(attack_timer / attack_frame_duration)
	if next_frame != active_attack_frame:
		active_attack_frame = next_frame
		_set_attack_frame()


func _start_attack(attack: String) -> void:
	var target_cell := _target_cell()
	if attack == "black_hole":
		grid.call("use_black_hole", target_cell)
	else:
		grid.call("use_white_hole", target_cell)

	idle_frame = 0
	idle_frame_timer = 0.0
	active_attack = attack
	active_attack_frame = 0
	attack_timer = 0.0
	_set_attack_frame()


func _set_attack_frame() -> void:
	var start_column := BLACK_HOLE_START_COLUMN if active_attack == "black_hole" else WHITE_HOLE_START_COLUMN
	_set_sheet_region(start_column + active_attack_frame, facing_row)


func _set_idle_frame(frame_index: int) -> void:
	_set_sheet_region(frame_index, facing_row)


func _set_sheet_region(column: int, row: int) -> void:
	region_rect = Rect2(
		Vector2(column * CELL_SIZE, row * CELL_SIZE),
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
	facing_direction = direction
	idle_frame = 0
	idle_frame_timer = 0.0
	_set_idle_frame(idle_frame)
	_update_target_cell()


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
		_update_target_cell()


func _target_cell() -> Vector2i:
	return Vector2i(player_column, player_row_from_bottom) + facing_direction


func _update_target_cell() -> void:
	grid.call("set_target_cell", _target_cell())


func _update_position() -> void:
	position = Vector2(
		GRID_ORIGIN.x + (player_column + 0.5) * CELL_SIZE,
		GRID_ORIGIN.y + (ROWS - player_row_from_bottom - 0.5) * CELL_SIZE
	)
