extends Node2D

const COLUMNS := 10
const ROWS := 7
const CELL_SIZE := Vector2(32.0, 32.0)
const GRAPHIC_GRID_SIZE := Vector2(16.0, 16.0)
const GRID_ORIGIN := Vector2(32.0, 32.0)
const SPRITE_SHEET: Texture2D = preload("res://assets/characters/jerv/jerv-tgrc-topdown-sheet.png")

const BACKGROUND := Color8(5, 7, 16)
const FLOOR := Color8(13, 16, 29)
const FLOOR_ALTERNATE := Color8(17, 20, 35)
const GRID_LINE := Color8(43, 49, 69)
const MOVEMENT_TILE_LINE := Color8(61, 67, 88)
const OUTER_BORDER := Color8(99, 67, 99)
const EFFECT_FRAME_COUNT := 4
const BEAT_PULSE_FRACTION := 0.36
const AUDIO_DETECTION_FLASH_SECONDS := 0.3
const DEFAULT_ANIMATION_BPM := 120.0
const DEFAULT_GOOD_WINDOW_MS := 120
const DEFAULT_PERFECT_WINDOW_MS := 50

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
var target_cell := Vector2i(4, 2)
var action_feedback := "PRONTO"
var active_effect := ""
var effect_cell := Vector2i.ZERO
var effect_frame := 0
var effect_timer := 0.0
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
		Vector2i(4, 2): {"id": "ion_crystal"},
		Vector2i(6, 3): {"id": "brass_gear"},
		Vector2i(2, 4): {"id": "echo_orb"},
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
		else:
			effect_frame = next_frame
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
	var animation_bpm := bpm if bpm_enabled else DEFAULT_ANIMATION_BPM
	beat_duration = 60.0 / animation_bpm
	effect_frame_duration = beat_duration / EFFECT_FRAME_COUNT
	beat_pulse_duration = beat_duration * BEAT_PULSE_FRACTION
	effect_timer = effect_phase * beat_duration
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


func use_black_hole(cell: Vector2i) -> void:
	_start_effect("black_hole", cell)
	if not _is_inside_grid(cell):
		action_feedback = "BLACK HOLE: FUORI GRIGLIA"
	elif not objects_by_cell.has(cell):
		action_feedback = "BLACK HOLE: TILE VUOTO"
	else:
		var item: Dictionary = objects_by_cell[cell]
		objects_by_cell.erase(cell)
		inventory.append(item)
		action_feedback = "ASSORBITO: %s" % _item_name(item)
	queue_redraw()


func use_white_hole(cell: Vector2i) -> void:
	_start_effect("white_hole", cell)
	if inventory.is_empty():
		action_feedback = "WHITE HOLE: INVENTARIO VUOTO"
	elif not _is_inside_grid(cell):
		action_feedback = "WHITE HOLE: FUORI GRIGLIA"
	elif objects_by_cell.has(cell):
		action_feedback = "WHITE HOLE: TILE OCCUPATO"
	else:
		var item: Dictionary = inventory.pop_back()
		objects_by_cell[cell] = item
		action_feedback = "ESPULSO: %s" % _item_name(item)
	queue_redraw()


func _start_effect(effect: String, cell: Vector2i) -> void:
	active_effect = effect
	effect_cell = cell
	effect_frame = 0
	effect_timer = 0.0
	queue_redraw()


func has_active_effect() -> bool:
	return not active_effect.is_empty()


func cancel_active_effect() -> void:
	if active_effect.is_empty():
		return
	active_effect = ""
	effect_frame = 0
	effect_timer = 0.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(384.0, 288.0)), BACKGROUND, true)

	var graphic_columns := COLUMNS * int(CELL_SIZE.x / GRAPHIC_GRID_SIZE.x)
	var graphic_rows := ROWS * int(CELL_SIZE.y / GRAPHIC_GRID_SIZE.y)
	for row in range(graphic_rows):
		for column in range(graphic_columns):
			var cell_position := GRID_ORIGIN + Vector2(column, row) * GRAPHIC_GRID_SIZE
			var cell_rect := Rect2(cell_position, GRAPHIC_GRID_SIZE)
			var floor_color := FLOOR_ALTERNATE if (column + row) % 2 == 1 else FLOOR
			draw_rect(cell_rect, floor_color, true)
			draw_rect(cell_rect, GRID_LINE, false, 1.0)

	var grid_size := Vector2(COLUMNS, ROWS) * CELL_SIZE
	for column in range(COLUMNS + 1):
		var x := GRID_ORIGIN.x + column * CELL_SIZE.x
		draw_line(Vector2(x, GRID_ORIGIN.y), Vector2(x, GRID_ORIGIN.y + grid_size.y), MOVEMENT_TILE_LINE, 1.0)
	for row in range(ROWS + 1):
		var y := GRID_ORIGIN.y + row * CELL_SIZE.y
		draw_line(Vector2(GRID_ORIGIN.x, y), Vector2(GRID_ORIGIN.x + grid_size.x, y), MOVEMENT_TILE_LINE, 1.0)
	draw_rect(Rect2(GRID_ORIGIN - Vector2(2.0, 2.0), grid_size + Vector2(4.0, 4.0)), OUTER_BORDER, false, 2.0)

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
	if active_effect.is_empty() or not _is_inside_grid(effect_cell):
		return

	var effect_row := 4 if active_effect == "black_hole" else 5
	var start_column := 2 if active_effect == "black_hole" else 6
	var source_rect := Rect2(
		Vector2((start_column + effect_frame) * 32, effect_row * 32),
		Vector2(32, 32)
	)
	draw_texture_rect_region(
		SPRITE_SHEET,
		Rect2(_cell_screen_position(effect_cell), CELL_SIZE),
		source_rect
	)


func _draw_hud() -> void:
	draw_rect(Rect2(Vector2(8, 5), Vector2(368, 27)), Color8(8, 11, 24, 242), true)
	draw_rect(Rect2(Vector2(8, 5), Vector2(368, 27)), OUTER_BORDER, false, 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(14, 17), "IJKL MOVE  A/S HOLES  1-6 BPM  [ +5 ] -5  0 BPM ON/OFF  PGUP/DN VOL", HORIZONTAL_ALIGNMENT_LEFT, 350, 8, Color8(217, 223, 239))
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
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS


func _cell_screen_position(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell.x, ROWS - cell.y - 1) * CELL_SIZE


func _item_name(item: Dictionary) -> String:
	return str(OBJECT_CATALOG[item["id"]]["name"])
