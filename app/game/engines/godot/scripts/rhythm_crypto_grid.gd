extends Node2D

const COLUMNS := 12
const ROWS := 9
const CELL_SIZE := Vector2(32.0, 32.0)
const GRAPHIC_GRID_SIZE := Vector2(16.0, 16.0)
const GRID_ORIGIN := Vector2.ZERO
const BLACK_HOLE_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-black-hole.png")
const WHITE_HOLE_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-white-hole.png")

const BACKGROUND := Color8(5, 7, 16)
const FLOOR := Color8(13, 16, 29)
const FLOOR_ALTERNATE := Color8(17, 20, 35)
const GRID_LINE := Color8(43, 49, 69)
const MOVEMENT_TILE_LINE := Color8(61, 67, 88)
const OUTER_BORDER := Color8(99, 67, 99)
const WALL_MORTAR := Color8(8, 11, 19)
const WALL_BLOCK := Color8(31, 38, 52)
const WALL_BLOCK_ALT := Color8(37, 44, 58)
const WALL_EDGE_LIGHT := Color8(62, 72, 88)
const WALL_EDGE_SHADOW := Color8(17, 22, 33)
const EFFECT_FRAME_COUNT := 4
const CAST_START_COLUMN := 0
const STATIC_LOOP_START_COLUMN := 4
const STATIC_LOOP_FRAME_DURATION := 0.18
const BEAT_PULSE_FRACTION := 0.36
const AUDIO_DETECTION_FLASH_SECONDS := 0.3
const DEFAULT_ANIMATION_BPM := 120.0
const DEFAULT_GOOD_WINDOW_MS := 120
const DEFAULT_PERFECT_WINDOW_MS := 50
const TIMING_TARGET_RED := Color8(255, 72, 84)

const OBJECT_CATALOG := {
	"ion_crystal": {
		"name": "Cristallo ionico",
		"shape": "diamond",
		"color": Color8(91, 220, 255),
	},
	"brass_gear": {
		"name": "Ingranaggio d'ottone",
		"shape": "gear",
		"color": Color8(244, 177, 79),
	},
	"echo_orb": {
		"name": "Sfera d'eco",
		"shape": "orb",
		"color": Color8(194, 145, 255),
	},
}

var objects_by_cell: Dictionary = {}
var inventory: Array[Dictionary] = []
var target_cell := Vector2i(5, 3)
var action_feedback := "PRONTO"
var active_effect := ""
var effect_cell := Vector2i.ZERO
var effect_frame := 0
var effect_timer := 0.0
var static_effects: Dictionary = {}
var retiring_static_effects: Dictionary = {}
var pending_static_effect := ""
var pending_static_effect_cell := Vector2i.ZERO
var bpm := 120.0
var bpm_enabled := true
var bpm_profile := "P4"
var beat_duration := 0.5
var effect_frame_duration := 0.5 / EFFECT_FRAME_COUNT
var beat_pulse_duration := 0.5 * BEAT_PULSE_FRACTION
var turn_count := 0
var beat_pulse_remaining := 0.0
var timing_cycle_phase := 0.0
var audio_volume_percent := 40
var judgment_feedback := "READY"
var judgment_slot := ""
var judgment_feedback_timer := 0.0
var good_window_ms := DEFAULT_GOOD_WINDOW_MS
var perfect_window_ms := DEFAULT_PERFECT_WINDOW_MS
var audio_beat_candidate_phase := -1.0
var audio_beat_candidate_strength := 0.0
var audio_beat_candidate_flash_timer := 0.0
var audio_beat_candidate_count := 0


func _ready() -> void:
	objects_by_cell = {
		Vector2i(5, 3): {"id": "ion_crystal"},
		Vector2i(7, 4): {"id": "brass_gear"},
		Vector2i(3, 5): {"id": "echo_orb"},
	}
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw := false
	if not active_effect.is_empty():
		effect_timer += delta
		var next_frame := int(effect_timer / effect_frame_duration)
		if next_frame >= EFFECT_FRAME_COUNT:
			active_effect = ""
			effect_frame = 0
			effect_timer = 0.0
			_finish_pending_static_effect()
		else:
			effect_frame = next_frame
		should_redraw = true

	if not static_effects.is_empty():
		var static_loop_duration := STATIC_LOOP_FRAME_DURATION * EFFECT_FRAME_COUNT
		for effect_variant in static_effects.keys():
			var static_state: Dictionary = static_effects[effect_variant]
			var static_timer := float(static_state["timer"]) + delta
			static_state["timer"] = static_timer
			static_state["frame"] = int(fmod(static_timer, static_loop_duration) / STATIC_LOOP_FRAME_DURATION)
			static_effects[effect_variant] = static_state
		should_redraw = true

	if not retiring_static_effects.is_empty():
		for effect_variant in retiring_static_effects.keys():
			var effect_name := str(effect_variant)
			var retiring_state: Dictionary = retiring_static_effects[effect_name]
			var retiring_timer := float(retiring_state["timer"]) + delta
			var reverse_frame := int(retiring_timer / effect_frame_duration)
			if reverse_frame >= EFFECT_FRAME_COUNT:
				retiring_static_effects.erase(effect_name)
			else:
				retiring_state["timer"] = retiring_timer
				retiring_state["frame"] = EFFECT_FRAME_COUNT - reverse_frame - 1
				retiring_static_effects[effect_name] = retiring_state
		should_redraw = true

	if beat_pulse_remaining > 0.0:
		beat_pulse_remaining = maxf(0.0, beat_pulse_remaining - delta)
		should_redraw = true

	if judgment_feedback_timer > 0.0:
		judgment_feedback_timer = maxf(0.0, judgment_feedback_timer - delta)
		if judgment_feedback_timer == 0.0:
			judgment_feedback = "READY"
			judgment_slot = ""
		should_redraw = true

	if audio_beat_candidate_flash_timer > 0.0:
		audio_beat_candidate_flash_timer = maxf(0.0, audio_beat_candidate_flash_timer - delta)
		should_redraw = true

	if should_redraw:
		queue_redraw()


func set_tempo(value_bpm: float, profile_name: String = "") -> void:
	bpm = value_bpm
	bpm_profile = profile_name
	_update_tempo_durations()
	queue_redraw()


func set_judgment_windows(perfect_ms: int, good_ms: int) -> void:
	good_window_ms = maxi(good_ms, 10)
	perfect_window_ms = clampi(perfect_ms, 5, good_window_ms - 5)
	queue_redraw()


func set_bpm_enabled(enabled: bool) -> void:
	bpm_enabled = enabled
	if not bpm_enabled:
		beat_pulse_remaining = 0.0
	_update_tempo_durations()
	queue_redraw()


func _update_tempo_durations() -> void:
	var effect_phase := effect_timer / beat_duration
	var pulse_phase := beat_pulse_remaining / beat_pulse_duration
	var retiring_phases: Dictionary = {}
	var animation_bpm := bpm if bpm_enabled else DEFAULT_ANIMATION_BPM
	for effect_variant in retiring_static_effects.keys():
		var old_retiring_name := str(effect_variant)
		var old_retiring_state: Dictionary = retiring_static_effects[old_retiring_name]
		retiring_phases[old_retiring_name] = float(old_retiring_state["timer"]) / beat_duration
	beat_duration = 60.0 / animation_bpm
	effect_frame_duration = beat_duration / EFFECT_FRAME_COUNT
	beat_pulse_duration = beat_duration * BEAT_PULSE_FRACTION
	effect_timer = effect_phase * beat_duration
	for effect_variant in retiring_phases.keys():
		var new_retiring_name := str(effect_variant)
		var new_retiring_state: Dictionary = retiring_static_effects[new_retiring_name]
		var retiring_phase := float(retiring_phases[new_retiring_name])
		new_retiring_state["timer"] = retiring_phase * beat_duration
		new_retiring_state["frame"] = EFFECT_FRAME_COUNT - int(new_retiring_state["timer"] / effect_frame_duration) - 1
		retiring_static_effects[new_retiring_name] = new_retiring_state
	if bpm_enabled:
		beat_pulse_remaining = pulse_phase * beat_pulse_duration
	if not active_effect.is_empty():
		effect_frame = mini(int(effect_timer / effect_frame_duration), EFFECT_FRAME_COUNT - 1)


func advance_turn(next_turn_count: int) -> void:
	turn_count = next_turn_count
	beat_pulse_remaining = beat_pulse_duration
	queue_redraw()


func set_timing_phase(phase: float) -> void:
	timing_cycle_phase = clampf(phase, 0.0, 1.0)
	queue_redraw()


func set_judgment(label: String, slot_name: String = "") -> void:
	judgment_feedback = label
	judgment_slot = slot_name
	judgment_feedback_timer = 0.8
	queue_redraw()


func set_audio_volume_percent(value: int) -> void:
	audio_volume_percent = clampi(value, 0, 100)
	queue_redraw()


func set_audio_beat_candidate(phase: float, strength: float) -> void:
	audio_beat_candidate_phase = clampf(phase, 0.0, 1.0)
	audio_beat_candidate_strength = maxf(1.0, strength)
	audio_beat_candidate_flash_timer = AUDIO_DETECTION_FLASH_SECONDS
	audio_beat_candidate_count += 1
	queue_redraw()


func set_target_cell(cell: Vector2i) -> void:
	if target_cell == cell:
		return
	target_cell = cell
	queue_redraw()


func use_black_hole(cell: Vector2i, static_version: bool = false) -> void:
	if static_version:
		if _is_inside_grid(cell):
			_start_static_effect_creation("black_hole", cell)
	else:
		_start_effect("black_hole", cell)
	if not _is_inside_grid(cell):
		action_feedback = "BLACK HOLE: FUORI GRIGLIA"
	elif not objects_by_cell.has(cell):
		action_feedback = "BLACK HOLE%s: TILE VUOTO" % (" STATIC" if static_version else "")
	else:
		var item: Dictionary = objects_by_cell[cell]
		objects_by_cell.erase(cell)
		inventory.append(item)
		action_feedback = "%sASSORBITO: %s" % ["STATIC " if static_version else "", _item_name(item)]
	queue_redraw()


func use_white_hole(cell: Vector2i, static_version: bool = false) -> void:
	if static_version:
		if _is_inside_grid(cell):
			_start_static_effect_creation("white_hole", cell)
	else:
		_start_effect("white_hole", cell)
	if inventory.is_empty():
		action_feedback = "WHITE HOLE%s: INVENTARIO VUOTO" % (" STATIC" if static_version else "")
	elif not _is_inside_grid(cell):
		action_feedback = "WHITE HOLE: FUORI GRIGLIA"
	elif objects_by_cell.has(cell):
		action_feedback = "WHITE HOLE%s: TILE OCCUPATO" % (" STATIC" if static_version else "")
	else:
		var item: Dictionary = inventory.pop_back()
		objects_by_cell[cell] = item
		action_feedback = "%sESPULSO: %s" % ["STATIC " if static_version else "", _item_name(item)]
	queue_redraw()


func _start_effect(effect: String, cell: Vector2i) -> void:
	active_effect = effect
	effect_cell = cell
	effect_frame = 0
	effect_timer = 0.0
	queue_redraw()


func _place_static_effect(effect: String, cell: Vector2i) -> void:
	static_effects[effect] = {
		"cell": cell,
		"frame": 0,
		"timer": 0.0,
	}
	queue_redraw()


func _start_static_effect_creation(effect: String, cell: Vector2i) -> void:
	_begin_static_effect_removal(effect)
	pending_static_effect = effect
	pending_static_effect_cell = cell
	_start_effect(effect, cell)


func _begin_static_effect_removal(effect: String) -> void:
	if not static_effects.has(effect):
		return
	var previous_state: Dictionary = static_effects[effect]
	static_effects.erase(effect)
	retiring_static_effects[effect] = {
		"cell": previous_state["cell"],
		"frame": EFFECT_FRAME_COUNT - 1,
		"timer": 0.0,
	}


func _finish_pending_static_effect() -> void:
	if pending_static_effect.is_empty():
		return
	_place_static_effect(pending_static_effect, pending_static_effect_cell)
	pending_static_effect = ""
	pending_static_effect_cell = Vector2i.ZERO


func has_active_effect() -> bool:
	return not active_effect.is_empty()


func cancel_active_effect() -> void:
	if active_effect.is_empty() and pending_static_effect.is_empty() and retiring_static_effects.is_empty():
		return
	_finish_pending_static_effect()
	active_effect = ""
	effect_frame = 0
	effect_timer = 0.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(384.0, 288.0)), BACKGROUND, true)

	for row in range(1, ROWS - 1):
		for column in range(1, COLUMNS - 1):
			_draw_floor_tile(Vector2i(column, row))

	for row in range(ROWS):
		for column in range(COLUMNS):
			var cell := Vector2i(column, ROWS - row - 1)
			if _is_wall_cell(cell):
				_draw_wall_tile(cell)

	if _is_inside_grid(target_cell):
		var target_rect := Rect2(_cell_screen_position(target_cell), CELL_SIZE)
		draw_rect(target_rect, Color(0.95, 0.72, 0.26, 0.08), true)
		draw_rect(target_rect, Color8(241, 190, 55, 220), false, 1.0)

	for cell_variant in objects_by_cell:
		var cell: Vector2i = cell_variant
		_draw_object(cell, objects_by_cell[cell])

	_draw_active_effect()
	_draw_hud()
	_draw_timing_bar()


func _draw_floor_tile(cell: Vector2i) -> void:
	var tile_origin := _cell_screen_position(cell)
	for graphic_row in range(2):
		for graphic_column in range(2):
			var graphic_position := tile_origin + Vector2(graphic_column, graphic_row) * GRAPHIC_GRID_SIZE
			var shade := cell.x + cell.y + graphic_column + graphic_row
			var floor_color := FLOOR_ALTERNATE if shade % 2 == 1 else FLOOR
			draw_rect(Rect2(graphic_position, GRAPHIC_GRID_SIZE), floor_color, true)
			draw_rect(Rect2(graphic_position, GRAPHIC_GRID_SIZE), GRID_LINE, false, 1.0)
	draw_rect(Rect2(tile_origin, CELL_SIZE), MOVEMENT_TILE_LINE, false, 1.0)


func _draw_wall_tile(cell: Vector2i) -> void:
	var tile_origin := _cell_screen_position(cell)
	draw_rect(Rect2(tile_origin, CELL_SIZE), WALL_MORTAR, true)
	var vertical_split := 15 if posmod(cell.x + cell.y, 2) == 0 else 17
	var horizontal_split := 15 if posmod(cell.y, 2) == 0 else 17
	var block_rects := [
		Rect2(tile_origin + Vector2(1, 1), Vector2(vertical_split - 1, horizontal_split - 1)),
		Rect2(tile_origin + Vector2(vertical_split + 1, 1), Vector2(30 - vertical_split, horizontal_split - 1)),
		Rect2(tile_origin + Vector2(1, horizontal_split + 1), Vector2(vertical_split - 1, 30 - horizontal_split)),
		Rect2(tile_origin + Vector2(vertical_split + 1, horizontal_split + 1), Vector2(30 - vertical_split, 30 - horizontal_split)),
	]
	for block_index in range(block_rects.size()):
		var block: Rect2 = block_rects[block_index]
		var shade := cell.x * 3 + cell.y * 5 + block_index
		var block_color := WALL_BLOCK_ALT if posmod(shade, 3) == 0 else WALL_BLOCK
		draw_rect(block, block_color, true)
		draw_line(block.position, Vector2(block.end.x - 1, block.position.y), WALL_EDGE_LIGHT, 1.0)
		draw_line(block.position, Vector2(block.position.x, block.end.y - 1), WALL_EDGE_LIGHT, 1.0)
		draw_line(Vector2(block.position.x + 1, block.end.y - 1), Vector2(block.end.x - 1, block.end.y - 1), WALL_EDGE_SHADOW, 1.0)
		draw_line(Vector2(block.end.x - 1, block.position.y + 1), Vector2(block.end.x - 1, block.end.y - 1), WALL_EDGE_SHADOW, 1.0)
	if posmod(cell.x * 7 + cell.y * 11, 9) == 0:
		var crack_start := tile_origin + Vector2(8 + posmod(cell.x * 3, 9), 7 + posmod(cell.y * 5, 11))
		draw_line(crack_start, crack_start + Vector2(3, 3), WALL_EDGE_SHADOW, 1.0)
		draw_line(crack_start + Vector2(3, 3), crack_start + Vector2(5, 2), WALL_EDGE_SHADOW, 1.0)


func _is_wall_cell(cell: Vector2i) -> bool:
	return cell.x == 0 or cell.x == COLUMNS - 1 or cell.y == 0 or cell.y == ROWS - 1


func _draw_object(cell: Vector2i, item: Dictionary) -> void:
	var catalog: Dictionary = OBJECT_CATALOG[item["id"]]
	var center := _cell_screen_position(cell) + CELL_SIZE * 0.5
	var item_color: Color = catalog["color"]
	match catalog["shape"]:
		"diamond":
			draw_colored_polygon(
				PackedVector2Array([center + Vector2(0, -8), center + Vector2(6, 0), center + Vector2(0, 8), center + Vector2(-6, 0)]),
				item_color
			)
			draw_line(center + Vector2(0, -6), center + Vector2(0, 6), Color(0.86, 0.98, 1.0), 1.0)
		"gear":
			draw_rect(Rect2(center + Vector2(-5, -5), Vector2(10, 10)), item_color, true)
			draw_rect(Rect2(center + Vector2(-2, -2), Vector2(4, 4)), FLOOR, true)
			draw_rect(Rect2(center + Vector2(-1, -8), Vector2(2, 3)), item_color, true)
			draw_rect(Rect2(center + Vector2(-1, 5), Vector2(2, 3)), item_color, true)
			draw_rect(Rect2(center + Vector2(-8, -1), Vector2(3, 2)), item_color, true)
			draw_rect(Rect2(center + Vector2(5, -1), Vector2(3, 2)), item_color, true)
		"orb":
			draw_circle(center, 6.0, item_color)
			draw_rect(Rect2(center + Vector2(-2, -3), Vector2(2, 2)), Color(0.96, 0.92, 1.0), true)


func _draw_active_effect() -> void:
	for effect_variant in ["black_hole", "white_hole"]:
		var static_name := str(effect_variant)
		if not static_effects.has(static_name):
			continue
		var static_state: Dictionary = static_effects[static_name]
		var cell: Vector2i = static_state["cell"]
		if _is_inside_grid(cell):
			_draw_effect_frame(static_name, cell, int(static_state["frame"]), true)
	if not active_effect.is_empty() and _is_inside_grid(effect_cell):
		_draw_effect_frame(active_effect, effect_cell, effect_frame, false)
	for effect_variant in retiring_static_effects.keys():
		var retiring_name := str(effect_variant)
		var retiring_state: Dictionary = retiring_static_effects[retiring_name]
		var cell: Vector2i = retiring_state["cell"]
		if _is_inside_grid(cell):
			_draw_effect_frame(retiring_name, cell, int(retiring_state["frame"]), false)


func _draw_effect_frame(effect: String, cell: Vector2i, frame: int, static_version: bool) -> void:
	var sprite_sheet := BLACK_HOLE_SHEET if effect == "black_hole" else WHITE_HOLE_SHEET
	var start_column := STATIC_LOOP_START_COLUMN if static_version else CAST_START_COLUMN
	var source_rect := Rect2(Vector2((start_column + frame) * 32, 0), Vector2(32, 32))
	draw_texture_rect_region(sprite_sheet, Rect2(_cell_screen_position(cell), CELL_SIZE), source_rect)


func _draw_hud() -> void:
	draw_rect(Rect2(Vector2(8, 5), Vector2(368, 27)), Color8(8, 11, 24, 242), true)
	draw_rect(Rect2(Vector2(8, 5), Vector2(368, 27)), OUTER_BORDER, false, 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(14, 17), "IJKL MOVE A/S CAST SHIFT+A/S LOOP  1-6 BPM [ ] 0 BPM PGUP/DN VOL", HORIZONTAL_ALIGNMENT_LEFT, 350, 8, Color8(217, 223, 239))
	var top_item := "VUOTO" if inventory.is_empty() else _item_name(inventory.back())
	var tempo_status := "%d BPM %s" % [roundi(bpm), bpm_profile] if bpm_enabled else "FREE (BPM OFF, NEXT %d)" % roundi(bpm)
	var status_text := "%s  T%04d  STACK %d %s  VOL %d%%" % [tempo_status, turn_count, inventory.size(), top_item, audio_volume_percent]
	draw_string(font, Vector2(14, 29), status_text, HORIZONTAL_ALIGNMENT_LEFT, 342, 7, Color8(177, 191, 217))
	var detection_color := Color8(105, 236, 255) if audio_beat_candidate_flash_timer > 0.0 else Color8(100, 133, 153)
	draw_string(font, Vector2(307, 29), "AUTO %03d" % audio_beat_candidate_count, HORIZONTAL_ALIGNMENT_LEFT, 67, 7, detection_color)
	if bpm_enabled:
		var pulse_strength := beat_pulse_remaining / beat_pulse_duration
		var pulse_radius := 1.5 + pulse_strength * 2.0
		var pulse_color := Color(0.45, 0.92, 1.0, 0.35 + pulse_strength * 0.65)
		draw_circle(Vector2(365, 14), pulse_radius, pulse_color)


func _draw_timing_bar() -> void:
	var judgment_text := judgment_feedback
	if not judgment_slot.is_empty():
		judgment_text = "%s %s" % [judgment_feedback, judgment_slot]
	draw_string(ThemeDB.fallback_font, Vector2(14, 264), "%s  %s" % [judgment_text, action_feedback], HORIZONTAL_ALIGNMENT_LEFT, 356, 7, _judgment_color())
	if not bpm_enabled:
		return
	var bar_rect := Rect2(Vector2(126, 274), Vector2(132, 8))
	draw_rect(bar_rect, Color8(8, 12, 22), true)
	draw_rect(bar_rect, Color8(112, 127, 151), false, 1.0)
	var good_radius := minf(0.5, (float(good_window_ms) / 1000.0) / beat_duration)
	var perfect_radius := minf(good_radius, (float(perfect_window_ms) / 1000.0) / beat_duration)
	var good_width := good_radius * 2.0 * bar_rect.size.x
	var perfect_width := perfect_radius * 2.0 * bar_rect.size.x
	var half_beat_good_width := good_radius * bar_rect.size.x
	var half_beat_perfect_width := perfect_radius * bar_rect.size.x
	var center_x := bar_rect.position.x + bar_rect.size.x * 0.5
	var zone_y := bar_rect.position.y + 1.0
	var zone_height := bar_rect.size.y - 2.0
	var good_color := Color8(38, 111, 66)
	var perfect_color := Color8(83, 188, 103)
	draw_rect(Rect2(Vector2(center_x - good_width * 0.5, zone_y), Vector2(good_width, zone_height)), good_color, true)
	draw_rect(Rect2(Vector2(bar_rect.position.x + 1.0, zone_y), Vector2(half_beat_good_width, zone_height)), good_color, true)
	draw_rect(Rect2(Vector2(bar_rect.end.x - half_beat_good_width - 1.0, zone_y), Vector2(half_beat_good_width, zone_height)), good_color, true)
	draw_rect(Rect2(Vector2(center_x - perfect_width * 0.5, zone_y), Vector2(perfect_width, zone_height)), perfect_color, true)
	draw_rect(Rect2(Vector2(bar_rect.position.x + 1.0, zone_y), Vector2(half_beat_perfect_width, zone_height)), perfect_color, true)
	draw_rect(Rect2(Vector2(bar_rect.end.x - half_beat_perfect_width - 1.0, zone_y), Vector2(half_beat_perfect_width, zone_height)), perfect_color, true)

	var marker_position := 0.5 + timing_cycle_phase if timing_cycle_phase < 0.5 else timing_cycle_phase - 0.5
	var marker_x := bar_rect.position.x + marker_position * bar_rect.size.x
	draw_rect(Rect2(Vector2(marker_x - 1.0, bar_rect.position.y - 2.0), Vector2(2.0, 12.0)), Color8(244, 247, 255), true)
	var half_beat_left_x := bar_rect.position.x + 1.0
	var half_beat_right_x := bar_rect.end.x - 1.0
	draw_rect(Rect2(Vector2(half_beat_left_x - 1.0, zone_y), Vector2(2.0, zone_height)), TIMING_TARGET_RED, true)
	draw_rect(Rect2(Vector2(center_x - 1.5, zone_y), Vector2(3.0, zone_height)), TIMING_TARGET_RED, true)
	draw_rect(Rect2(Vector2(half_beat_right_x - 1.0, zone_y), Vector2(2.0, zone_height)), TIMING_TARGET_RED, true)
	if audio_beat_candidate_count > 0 and audio_beat_candidate_phase >= 0.0:
		var detected_position := 0.5 + audio_beat_candidate_phase if audio_beat_candidate_phase < 0.5 else audio_beat_candidate_phase - 0.5
		var detected_x := bar_rect.position.x + detected_position * bar_rect.size.x
		var flash := audio_beat_candidate_flash_timer / AUDIO_DETECTION_FLASH_SECONDS
		var opacity := clampf(0.55 + flash * 0.3 + minf(audio_beat_candidate_strength - 1.0, 2.0) * 0.075, 0.55, 1.0)
		var detection_color := Color(0.25, 0.95, 1.0, opacity)
		draw_colored_polygon(PackedVector2Array([
			Vector2(detected_x, bar_rect.position.y - 3.0),
			Vector2(detected_x + 3.0, bar_rect.position.y - 6.0),
			Vector2(detected_x - 3.0, bar_rect.position.y - 6.0),
		]), detection_color)


func _judgment_color() -> Color:
	match judgment_feedback:
		"PERFECT":
			return Color8(150, 255, 178)
		"GOOD":
			return Color8(226, 244, 156)
		"MISS":
			return Color8(255, 112, 112)
		"BLOCKED", "LOCKED":
			return Color8(255, 190, 105)
		"FREE":
			return Color8(141, 211, 255)
		_:
			return Color8(177, 191, 217)


func _is_inside_grid(cell: Vector2i) -> bool:
	return cell.x > 0 and cell.x < COLUMNS - 1 and cell.y > 0 and cell.y < ROWS - 1


func _cell_screen_position(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell.x, ROWS - cell.y - 1) * CELL_SIZE


func _item_name(item: Dictionary) -> String:
	return str(OBJECT_CATALOG[item["id"]]["name"])
