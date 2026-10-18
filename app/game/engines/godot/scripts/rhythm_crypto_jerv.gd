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
const DEFAULT_PERFECT_WINDOW_MS := 50
const DEFAULT_GOOD_WINDOW_MS := 120
const MIN_JUDGMENT_WINDOW_MS := 5
const MAX_GOOD_WINDOW_MS := 120
const JUDGMENT_WINDOW_STEP_MS := 5
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
@onready var music: Node = get_parent().get_node("Music")

var player_column := 4
var player_row_from_bottom := 3
var bpm := DEFAULT_BPM
var bpm_enabled := true
var beat_duration := 60.0 / DEFAULT_BPM
var animation_beat_duration := DEFAULT_ANIMATION_BEAT_DURATION
var idle_frame_duration := DEFAULT_ANIMATION_BEAT_DURATION * IDLE_FRAME_BEATS
var attack_frame_duration := DEFAULT_ANIMATION_BEAT_DURATION / ATTACK_FRAME_COUNT
var turn_count := 0
var bpm_profile := "P4"
var perfect_window_ms := DEFAULT_PERFECT_WINDOW_MS
var good_window_ms := DEFAULT_GOOD_WINDOW_MS
var free_move_direction := Vector2i.ZERO
var free_move_timer := 0.0
var facing_row := FACING_ROW_DOWN
var facing_direction := Vector2i(0, -1)
var idle_frame := 0
var idle_frame_timer := 0.0
var active_attack := ""
var active_attack_frame := 0
var attack_timer := 0.0
var last_clock_beat_index := -1
var last_accepted_action_slot_index := -1
var movement_log_sequence := 0


func _ready() -> void:
	scale = Vector2.ONE
	region_enabled = true
	_set_idle_frame(0)
	grid.call("set_tempo", bpm, bpm_profile)
	_sync_judgment_windows()
	music.call("set_tempo", bpm)
	last_clock_beat_index = int(music.call("get_track_beat_index"))
	_update_position()
	_update_target_cell()


func _process(delta: float) -> void:
	if not active_attack.is_empty():
		_update_attack_animation(delta)
	else:
		_update_idle_animation(delta)

	if bpm_enabled:
		_sync_clock_to_music()
		grid.call("set_timing_phase", float(music.call("get_beat_phase")))
	else:
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
			_submit_rhythm_action(Vector2i.ZERO, attack)
		else:
			grid.call("set_judgment", "FREE")
			_perform_attack(attack)
	elif direction != Vector2i.ZERO:
		_set_facing_direction(direction)
		if bpm_enabled:
			_submit_rhythm_action(direction, "")
		else:
			free_move_direction = direction
			free_move_timer = FREE_MOVE_INITIAL_DELAY
			grid.call("set_judgment", "FREE")
			_perform_movement(direction, "key_free", "", -1, "FREE")
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
	bpm = clampf(value, MIN_BPM, MAX_BPM)
	beat_duration = 60.0 / bpm
	bpm_profile = profile_name
	_clamp_judgment_windows()
	_set_animation_beat_duration(beat_duration)
	music.call("set_tempo", bpm)
	grid.call("set_tempo", bpm, bpm_profile)
	grid.call("set_bpm_enabled", bpm_enabled)
	_sync_judgment_windows()


func get_rhythm_settings() -> Dictionary:
	return {
		"bpm": roundi(bpm),
		"profile": bpm_profile,
		"bpm_enabled": bpm_enabled,
		"perfect_window_ms": perfect_window_ms,
		"good_window_ms": good_window_ms,
		"good_window_max_ms": _maximum_good_window_ms(),
	}


func adjust_rhythm_setting(setting: String, direction: int) -> void:
	var step_direction := clampi(direction, -1, 1)
	if step_direction == 0:
		return
	match setting:
		"bpm":
			var next_bpm := clampf(bpm + BPM_STEP * step_direction, MIN_BPM, MAX_BPM)
			_set_bpm(next_bpm, _profile_name_for_bpm(next_bpm))
		"perfect":
			perfect_window_ms = clampi(
				perfect_window_ms + JUDGMENT_WINDOW_STEP_MS * step_direction,
				MIN_JUDGMENT_WINDOW_MS,
				good_window_ms - JUDGMENT_WINDOW_STEP_MS
			)
			_sync_judgment_windows()
		"good":
			good_window_ms = clampi(
				good_window_ms + JUDGMENT_WINDOW_STEP_MS * step_direction,
				perfect_window_ms + JUDGMENT_WINDOW_STEP_MS,
				_maximum_good_window_ms()
			)
			_sync_judgment_windows()


func toggle_bpm_enabled() -> void:
	_toggle_bpm_enabled()


func _maximum_good_window_ms() -> int:
	var half_spacing_midpoint_ms := 15000.0 / bpm
	var strict_step_count := int(ceil(half_spacing_midpoint_ms / float(JUDGMENT_WINDOW_STEP_MS))) - 1
	var non_overlapping_max := strict_step_count * JUDGMENT_WINDOW_STEP_MS
	return mini(MAX_GOOD_WINDOW_MS, non_overlapping_max)


func _clamp_judgment_windows() -> void:
	good_window_ms = mini(good_window_ms, _maximum_good_window_ms())
	perfect_window_ms = mini(perfect_window_ms, good_window_ms - JUDGMENT_WINDOW_STEP_MS)
	perfect_window_ms = maxi(perfect_window_ms, MIN_JUDGMENT_WINDOW_MS)


func _sync_judgment_windows() -> void:
	if grid:
		grid.call("set_judgment_windows", perfect_window_ms, good_window_ms)


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
	last_clock_beat_index = int(music.call("get_track_beat_index"))
	last_accepted_action_slot_index = -1
	free_move_direction = Vector2i.ZERO
	free_move_timer = 0.0
	var animation_duration := beat_duration if bpm_enabled else DEFAULT_ANIMATION_BEAT_DURATION
	_set_animation_beat_duration(animation_duration)
	grid.call("set_bpm_enabled", bpm_enabled)


func _profile_name_for_bpm(value: float) -> String:
	var profile_index := BPM_PROFILE_VALUES.find(value)
	return "P%d" % (profile_index + 1) if profile_index >= 0 else "CUSTOM"


func _advance_turn() -> void:
	turn_count += 1
	grid.call("advance_turn", turn_count)
	var beat_action_slot_index := turn_count * 2
	if last_accepted_action_slot_index == beat_action_slot_index:
		return
	var held_direction := _read_direction()
	if held_direction != Vector2i.ZERO:
		_set_facing_direction(held_direction)
		if _can_move(held_direction):
			last_accepted_action_slot_index = beat_action_slot_index
			grid.call("set_judgment", "PERFECT", "BEAT")
			_perform_movement(held_direction, "held_beat", "BEAT", beat_action_slot_index, "PERFECT")
		else:
			grid.call("set_judgment", "BLOCKED")
			_log_blocked_movement("held_beat", held_direction, "BEAT", beat_action_slot_index)


func _sync_clock_to_music(allow_held_movement: bool = true) -> void:
	var track_beat_index := int(music.call("get_track_beat_index"))
	var beats_per_loop := int(music.call("get_beats_per_loop"))
	while last_clock_beat_index != track_beat_index:
		last_clock_beat_index = (last_clock_beat_index + 1) % beats_per_loop
		if allow_held_movement:
			_advance_turn()
		else:
			turn_count += 1
			grid.call("advance_turn", turn_count)


func _submit_rhythm_action(direction: Vector2i, attack: String) -> void:
	_sync_clock_to_music(false)
	var phase := float(music.call("get_beat_phase"))
	var nearest_subdivision := roundi(phase * 2.0)
	var phase_error := absf(phase - float(nearest_subdivision) * 0.5)
	var timing_error := phase_error * beat_duration
	var slot_name := "HALF" if nearest_subdivision % 2 == 1 else "BEAT"
	var action_slot_index := turn_count * 2 + nearest_subdivision
	var action_name := attack.to_upper()
	if direction != Vector2i.ZERO:
		action_name = "MOVE %s" % str(direction)
	if timing_error > float(good_window_ms) / 1000.0:
		grid.call("set_judgment", "MISS", slot_name)
		if direction != Vector2i.ZERO:
			_log_rhythm_movement_attempt(action_name, slot_name, action_slot_index, phase, timing_error, "MISS")
		return

	if last_accepted_action_slot_index == action_slot_index:
		grid.call("set_judgment", "LOCKED", slot_name)
		if direction != Vector2i.ZERO:
			_log_rhythm_movement_attempt(action_name, slot_name, action_slot_index, phase, timing_error, "LOCKED")
		return
	if direction != Vector2i.ZERO and not _can_move(direction):
		grid.call("set_judgment", "BLOCKED", slot_name)
		_log_rhythm_movement_attempt(action_name, slot_name, action_slot_index, phase, timing_error, "BLOCKED")
		return

	last_accepted_action_slot_index = action_slot_index
	var judgment := "PERFECT" if timing_error <= float(perfect_window_ms) / 1000.0 else "GOOD"
	grid.call("set_judgment", judgment, slot_name)
	if not attack.is_empty():
		_perform_attack(attack)
	else:
		_log_rhythm_movement_attempt(action_name, slot_name, action_slot_index, phase, timing_error, judgment)
		_perform_movement(direction, "key", slot_name, action_slot_index, judgment)


func _prepare_for_player_action() -> void:
	var has_active_vfx := bool(grid.call("has_active_effect"))
	if not active_attack.is_empty() or has_active_vfx:
		_cancel_active_animation()
		grid.call("cancel_active_effect")


func _perform_attack(attack: String) -> void:
	_prepare_for_player_action()
	_start_attack(attack)


func _perform_movement(
	direction: Vector2i,
	source: String = "key_free",
	slot_name: String = "",
	action_slot_index: int = -1,
	judgment: String = "FREE"
) -> void:
	var from_cell := Vector2i(player_column, player_row_from_bottom)
	_prepare_for_player_action()
	_set_facing_direction(direction)
	_reset_idle_animation()
	var moved := _move_one_cell(direction)
	var to_cell := Vector2i(player_column, player_row_from_bottom)
	movement_log_sequence += 1
	var phase_text := "OFF"
	if bpm_enabled:
		phase_text = "%.3f" % float(music.call("get_beat_phase"))
	print(
		"[MOVE #%04d] source=%s turn=%d slot=%s slot_index=%d phase=%s judgment=%s dir=%s cell=%s->%s result=%s" % [
			movement_log_sequence,
			source,
			turn_count,
			slot_name if not slot_name.is_empty() else "-",
			action_slot_index,
			phase_text,
			judgment,
			str(direction),
			str(from_cell),
			str(to_cell),
			"MOVED" if moved else "BLOCKED",
		]
	)


func _log_rhythm_movement_attempt(
	action_name: String,
	slot_name: String,
	action_slot_index: int,
	phase: float,
	timing_error: float,
	result: String
) -> void:
	print(
		"[MOVE INPUT] action=%s turn=%d slot=%s slot_index=%d phase=%.3f error_ms=%.1f result=%s cell=%s" % [
			action_name,
			turn_count,
			slot_name,
			action_slot_index,
			phase,
			timing_error * 1000.0,
			result,
			str(Vector2i(player_column, player_row_from_bottom)),
		]
	)


func _log_blocked_movement(source: String, direction: Vector2i, slot_name: String, action_slot_index: int) -> void:
	print(
		"[MOVE INPUT] action=MOVE %s source=%s turn=%d slot=%s slot_index=%d phase=%.3f result=BLOCKED cell=%s" % [
			str(direction),
			source,
			turn_count,
			slot_name,
			action_slot_index,
			float(music.call("get_beat_phase")),
			str(Vector2i(player_column, player_row_from_bottom)),
		]
	)


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
		_perform_movement(direction, "held_free_repeat", "", -1, "FREE")
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
	var should_change_frame := idle_frame != 0
	idle_frame = 0
	idle_frame_timer = 0.0
	if should_change_frame:
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


func _move_one_cell(direction: Vector2i) -> bool:
	var next_column := player_column + direction.x
	var next_row := player_row_from_bottom + direction.y
	if next_column >= 0 and next_column < COLUMNS and next_row >= 0 and next_row < ROWS:
		player_column = next_column
		player_row_from_bottom = next_row
		_update_position()
		_update_target_cell()
		return true
	return false


func _can_move(direction: Vector2i) -> bool:
	var next_column := player_column + direction.x
	var next_row := player_row_from_bottom + direction.y
	return next_column >= 0 and next_column < COLUMNS and next_row >= 0 and next_row < ROWS


func _target_cell() -> Vector2i:
	return Vector2i(player_column, player_row_from_bottom) + facing_direction


func _update_target_cell() -> void:
	grid.call("set_target_cell", _target_cell())


func _update_position() -> void:
	position = Vector2(
		GRID_ORIGIN.x + (player_column + 0.5) * CELL_SIZE,
		GRID_ORIGIN.y + (ROWS - player_row_from_bottom - 0.5) * CELL_SIZE
	)
