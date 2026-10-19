extends Node2D

const COLUMNS := 12
const ROWS := 9
const CELL_SIZE := Vector2(32.0, 32.0)
const GRAPHIC_GRID_SIZE := Vector2(16.0, 16.0)
const GRID_ORIGIN := Vector2.ZERO
const PLAYFIELD_SIZE := Vector2(384.0, 288.0)
const SIDEBAR_WIDTH := 112.0
const VIEWPORT_SIZE := Vector2(PLAYFIELD_SIZE.x + SIDEBAR_WIDTH, PLAYFIELD_SIZE.y)
const INITIAL_STATIC_EFFECTS := [
	{"effect": "black_hole", "cell": Vector2i(9, 2)},
	{"effect": "white_hole", "cell": Vector2i(1, 1)},
	{"effect": "gravity_star", "cell": Vector2i(4, 5)},
]
const OBJECT_ORBIT_INFLUENCE_RADIUS := 128.0
const OBJECT_ORBIT_PERIOD_SECONDS := 6.0
const OBJECT_CLEARANCE_FROM_WALLS := 8.0
const BLACK_HOLE_INWARD_ACCELERATION := 36.0
const BLACK_HOLE_MAX_INWARD_SPEED := 36.0
const BLACK_HOLE_ORBIT_PERIOD_SECONDS := 2.5
const BLACK_HOLE_CAPTURE_RADIUS := 5.0
const WHITE_HOLE_LAUNCH_SPEED := 160.0
const WHITE_HOLE_DECELERATION := 80.0
const WHITE_HOLE_WALL_RESTITUTION := 0.55
const WHITE_HOLE_STOP_SPEED := 5.0
const WHITE_HOLE_INVENTORY_EJECT_INTERVAL := 0.35
const OBJECT_TRACE_SAMPLE_INTERVAL := 0.045
const OBJECT_TRACE_LIFETIME_SECONDS := 1.5
const OBJECT_TRACE_MAX_POINTS := 40
const OBJECT_TRACE_JUMP_THRESHOLD := 12.0
const OBJECT_TRACE_MAX_EVENTS := 6
const BLACK_HOLE_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-black-hole.png")
const WHITE_HOLE_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-white-hole.png")
const GRAVITY_STAR_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-star.png")

const BACKGROUND := Color8(5, 7, 16)
const SIDEBAR_BACKGROUND := Color8(9, 12, 24)
const SIDEBAR_TEXT := Color8(205, 216, 237)
const SIDEBAR_MUTED := Color8(143, 159, 188)
const SIDEBAR_HEADING := Color8(117, 179, 214)
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

var objects: Array[Dictionary] = []
var inventory: Array[Dictionary] = []
var object_trace_sequence := 0
var object_traces: Dictionary = {}
var object_trace_events: Array[Dictionary] = []
var active_spell_implementation := "V1"
var spell_physics_enabled := true
var snap_during_physics := false
var snap_on_physics_end := true
var show_spell_influence_debug := true
var physics_rng := RandomNumberGenerator.new()
var static_effect_sequence := 0
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
	physics_rng.randomize()
	objects = [
		{"id": "ion_crystal", "position": _cell_screen_position(Vector2i(5, 3)) + CELL_SIZE * 0.5},
		{"id": "brass_gear", "position": _cell_screen_position(Vector2i(7, 4)) + CELL_SIZE * 0.5},
		{"id": "echo_orb", "position": _cell_screen_position(Vector2i(3, 5)) + CELL_SIZE * 0.5},
	]
	for index in range(objects.size()):
		var item: Dictionary = objects[index]
		_ensure_object_trace(item)
		objects[index] = item
	for initial_effect: Dictionary in INITIAL_STATIC_EFFECTS:
		_place_static_effect(str(initial_effect["effect"]), initial_effect["cell"])
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw := false
	if _update_active_static_fields():
		should_redraw = true
	if _update_orbiting_objects(delta):
		should_redraw = true
	if _update_spell_motion_objects(delta):
		should_redraw = true
	if _update_white_hole_inventory_ejection(delta):
		should_redraw = true
	if _update_object_traces(delta):
		should_redraw = true

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
	elif static_version:
		action_feedback = "BLACK HOLE STATIC: INNESCA"
	else:
		var object_index := _find_object_index_in_cell(cell)
		if object_index < 0:
			action_feedback = "BLACK HOLE: TILE VUOTO"
		else:
			var item: Dictionary = objects[object_index]
			objects.remove_at(object_index)
			item.erase("position")
			item.erase("motion")
			item.erase("orbit")
			item.erase("last_white_hole_id")
			inventory.append(item)
			action_feedback = "ASSORBITO: %s" % _item_name(item)
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
	elif _find_object_index_in_cell(cell) >= 0:
		action_feedback = "WHITE HOLE%s: TILE OCCUPATO" % (" STATIC" if static_version else "")
	else:
		var item: Dictionary = inventory.pop_back()
		item["position"] = _cell_screen_position(cell) + CELL_SIZE * 0.5
		item.erase("last_white_hole_id")
		objects.append(item)
		_update_active_static_fields()
		action_feedback = "%sESPULSO: %s" % ["STATIC " if static_version else "", _item_name(item)]
	queue_redraw()


func use_gravity_star(cell: Vector2i) -> void:
	if _is_inside_grid(cell):
		_start_static_effect_creation("gravity_star", cell)
		action_feedback = "STELLA: POSIZIONATA"
	else:
		action_feedback = "STELLA: FUORI GRIGLIA"
	queue_redraw()


func play_gravity_star_short_cast(cell: Vector2i) -> void:
	if _is_inside_grid(cell):
		_start_effect("gravity_star", cell)
		action_feedback = "STELLA: CAST"
	else:
		action_feedback = "STELLA: FUORI GRIGLIA"
	queue_redraw()


func _start_effect(effect: String, cell: Vector2i) -> void:
	active_effect = effect
	effect_cell = cell
	effect_frame = 0
	effect_timer = 0.0
	queue_redraw()


func _place_static_effect(effect: String, cell: Vector2i) -> void:
	static_effect_sequence += 1
	var state := {
		"id": static_effect_sequence,
		"cell": cell,
		"frame": 0,
		"timer": 0.0,
	}
	if effect == "white_hole":
		state["inventory_eject_timer"] = 0.0
	static_effects[effect] = state
	_update_active_static_fields()
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
	_update_active_static_fields()


func _update_orbiting_objects(delta: float) -> bool:
	if not spell_physics_enabled or not static_effects.has("gravity_star"):
		return false
	var moved_objects := false
	for index in range(objects.size()):
		var item: Dictionary = objects[index]
		if not item.has("orbit"):
			continue
		var orbit: Dictionary = item["orbit"]
		var angle := float(orbit["angle"]) + float(orbit["angular_speed"]) * delta
		orbit["angle"] = angle
		var center: Vector2 = orbit["center"]
		var orbit_radius := float(orbit["radius"])
		var orbit_position := center + Vector2(cos(angle), sin(angle)) * orbit_radius
		var safe_min := Vector2(CELL_SIZE.x, CELL_SIZE.y) + Vector2.ONE * OBJECT_CLEARANCE_FROM_WALLS
		var safe_max := Vector2((COLUMNS - 1) * CELL_SIZE.x, (ROWS - 1) * CELL_SIZE.y) - Vector2.ONE * OBJECT_CLEARANCE_FROM_WALLS
		orbit_position.x = clampf(orbit_position.x, safe_min.x, safe_max.x)
		orbit_position.y = clampf(orbit_position.y, safe_min.y, safe_max.y)
		if snap_during_physics:
			orbit_position = _snap_position_to_tile_center(orbit_position)
		item["position"] = orbit_position
		item["orbit"] = orbit
		objects[index] = item
		moved_objects = true
	return moved_objects


func _update_active_static_fields() -> bool:
	if not spell_physics_enabled:
		return false
	var changed := false # Re-resolve overlapping fields during every update.
	for index in range(objects.size()):
		var item: Dictionary = objects[index]
		var before_item: Dictionary = item.duplicate(true)
		var updated_item: Dictionary = _apply_active_static_fields(item)
		objects[index] = updated_item
		if updated_item != before_item:
			changed = true
	return changed


func _update_white_hole_inventory_ejection(delta: float) -> bool:
	if not spell_physics_enabled or not static_effects.has("white_hole"):
		return false
	var white_hole_state: Dictionary = static_effects["white_hole"]
	if inventory.is_empty():
		white_hole_state["inventory_eject_timer"] = 0.0
		static_effects["white_hole"] = white_hole_state
		return false
	var eject_timer := float(white_hole_state.get("inventory_eject_timer", 0.0)) + delta
	if eject_timer < WHITE_HOLE_INVENTORY_EJECT_INTERVAL:
		white_hole_state["inventory_eject_timer"] = eject_timer
		static_effects["white_hole"] = white_hole_state
		return false
	white_hole_state["inventory_eject_timer"] = 0.0
	static_effects["white_hole"] = white_hole_state
	var item: Dictionary = inventory.pop_back()
	var center: Vector2 = _cell_screen_position(white_hole_state["cell"]) + CELL_SIZE * 0.5
	item.erase("position")
	item.erase("motion")
	item.erase("orbit")
	item.erase("last_white_hole_id")
	objects.append(_launch_from_white_hole(item, center, int(white_hole_state["id"])))
	_update_active_static_fields()
	action_feedback = "WHITE HOLE: ESPULSO %s" % _item_name(item)
	return true


func _ensure_object_trace(item: Dictionary) -> String:
	if not item.has("trace_id"):
		object_trace_sequence += 1
		item["trace_id"] = "OBJECT_%02d" % object_trace_sequence
	var trace_id := str(item["trace_id"])
	if not object_traces.has(trace_id):
		var initial_position: Vector2 = item.get("position", Vector2.ZERO)
		object_traces[trace_id] = {
			"label": _object_trace_label(item),
			"points": [],
			"last_position": initial_position,
			"last_state": _object_trace_state(item),
			"sample_timer": 0.0,
		}
	return trace_id


func _update_object_traces(delta: float) -> bool:
	var should_redraw := false
	for trace_variant in object_traces.keys():
		var trace_id := str(trace_variant)
		var trace: Dictionary = object_traces[trace_id]
		var points: Array = trace["points"]
		if not points.is_empty():
			should_redraw = true
		for point_index in range(points.size() - 1, -1, -1):
			var point: Dictionary = points[point_index]
			point["age"] = float(point.get("age", 0.0)) + delta
			if float(point["age"]) > OBJECT_TRACE_LIFETIME_SECONDS:
				points.remove_at(point_index)
			else:
				points[point_index] = point
				should_redraw = true
		trace["points"] = points
		object_traces[trace_id] = trace

	for index in range(objects.size()):
		var item: Dictionary = objects[index]
		var trace_id := _ensure_object_trace(item)
		objects[index] = item
		var trace: Dictionary = object_traces[trace_id]
		var previous_position: Vector2 = trace["last_position"]
		var current_position: Vector2 = item["position"]
		var previous_state := str(trace["last_state"])
		var current_state := _object_trace_state(item)
		var distance := previous_position.distance_to(current_position)
		var state_changed := previous_state != current_state
		var black_hole_maximum_speed := (
			BLACK_HOLE_MAX_INWARD_SPEED
			+ OBJECT_ORBIT_INFLUENCE_RADIUS * TAU / BLACK_HOLE_ORBIT_PERIOD_SECONDS
		)
		var maximum_expected_speed := maxf(
			maxf(WHITE_HOLE_LAUNCH_SPEED, black_hole_maximum_speed),
			OBJECT_ORBIT_INFLUENCE_RADIUS * TAU / OBJECT_ORBIT_PERIOD_SECONDS
		)
		var jump_threshold := maxf(OBJECT_TRACE_JUMP_THRESHOLD, maximum_expected_speed * delta * 1.5)
		if distance >= jump_threshold or state_changed:
			_record_object_trace_event(
				trace_id,
				str(trace["label"]),
				previous_state,
				current_state,
				previous_position,
				current_position,
				distance,
				jump_threshold
			)
			should_redraw = true

		var points: Array = trace["points"]
		var sample_timer := float(trace["sample_timer"]) + delta
		var is_moving := current_state != "FERMO"
		if is_moving or state_changed:
			if points.is_empty():
				points.append({"position": previous_position, "age": 0.0})
			var last_point: Dictionary = points.back()
			var last_point_position: Vector2 = last_point["position"]
			if state_changed or sample_timer >= OBJECT_TRACE_SAMPLE_INTERVAL:
				if last_point_position.distance_to(current_position) >= 0.25:
					points.append({"position": current_position, "age": 0.0})
				if points.size() > OBJECT_TRACE_MAX_POINTS:
					points.remove_at(0)
				sample_timer = 0.0
				should_redraw = true
		else:
			sample_timer = 0.0

		trace["points"] = points
		trace["last_position"] = current_position
		trace["last_state"] = current_state
		trace["sample_timer"] = sample_timer
		object_traces[trace_id] = trace
	return should_redraw


func _record_object_trace_event(
	trace_id: String,
	label: String,
	previous_state: String,
	current_state: String,
	previous_position: Vector2,
	current_position: Vector2,
	distance: float,
	jump_threshold: float
) -> void:
	var event_kind := "JUMP" if distance >= jump_threshold else "STATE"
	object_trace_events.push_front({
		"kind": event_kind,
		"trace_id": trace_id,
		"label": label,
		"previous_state": previous_state,
		"current_state": current_state,
		"previous_position": previous_position,
		"current_position": current_position,
		"distance": distance,
	})
	if object_trace_events.size() > OBJECT_TRACE_MAX_EVENTS:
		object_trace_events.resize(OBJECT_TRACE_MAX_EVENTS)
	print(
		"[OBJECT TRACE] %s %s %s>%s (%.1f,%.1f)->(%.1f,%.1f), delta %.1f px (threshold %.1f)"
		% [label, event_kind, previous_state, current_state, previous_position.x, previous_position.y, current_position.x, current_position.y, distance, jump_threshold]
	)


func _object_trace_state(item: Dictionary) -> String:
	if item.has("motion"):
		var motion: Dictionary = item["motion"]
		match str(motion.get("type", "")):
			"white_hole_launch":
				return "BIANCO"
			"black_hole_pull":
				return "NERO"
	if item.has("orbit"):
		return "STELLA"
	return "FERMO"


func _object_trace_label(item: Dictionary) -> String:
	match str(item.get("id", "")):
		"ion_crystal":
			return "ION"
		"brass_gear":
			return "GEAR"
		"echo_orb":
			return "ORB"
		_:
			return "OBJ"


func _position_to_cell(position: Vector2) -> Vector2i:
	var screen_column := floori(position.x / CELL_SIZE.x)
	var screen_row := floori(position.y / CELL_SIZE.y)
	return Vector2i(screen_column, ROWS - screen_row - 1)


func _apply_active_static_fields(item: Dictionary) -> Dictionary:
	if not item.has("position"):
		return item
	var object_position: Vector2 = item["position"]
	var existing_motion: Dictionary = item.get("motion", {})
	var existing_motion_type := str(existing_motion.get("type", ""))

	if static_effects.has("black_hole"):
		var black_hole_state: Dictionary = static_effects["black_hole"]
		var black_hole_center: Vector2 = _cell_screen_position(black_hole_state["cell"]) + CELL_SIZE * 0.5
		if object_position.distance_to(black_hole_center) <= OBJECT_ORBIT_INFLUENCE_RADIUS:
			var existing_center: Vector2 = existing_motion.get("center", black_hole_center)
			if existing_motion_type != "black_hole_pull" or existing_center != black_hole_center:
				item = _set_black_hole_motion(item, black_hole_center)
			return item

	if existing_motion_type == "black_hole_pull":
		item.erase("motion")

	if static_effects.has("gravity_star"):
		var star_state: Dictionary = static_effects["gravity_star"]
		var star_center: Vector2 = _cell_screen_position(star_state["cell"]) + CELL_SIZE * 0.5
		var star_offset := object_position - star_center
		var star_radius := star_offset.length()
		var star_influence_radius := OBJECT_ORBIT_INFLUENCE_RADIUS
		if star_radius > 0.01 and star_radius <= star_influence_radius:
			var existing_orbit: Dictionary = item.get("orbit", {})
			if int(existing_orbit.get("effect_id", -1)) == int(star_state["id"]):
				return item
			if item.has("orbit") and snap_on_physics_end:
				var snapped_position := _snap_position_to_tile_center(object_position)
				var snapped_offset := snapped_position - star_center
				if snapped_offset.length() <= star_influence_radius:
					object_position = snapped_position
					item["position"] = object_position
					star_offset = snapped_offset
					star_radius = star_offset.length()
			item.erase("motion")
			item["orbit"] = {
				"effect_id": int(star_state["id"]),
				"center": star_center,
				"radius": star_radius,
				"angle": star_offset.angle(),
				"angular_speed": TAU / OBJECT_ORBIT_PERIOD_SECONDS,
			}
			return item

	if item.has("orbit"):
		if snap_on_physics_end:
			object_position = _snap_position_to_tile_center(object_position)
			item["position"] = object_position
		item.erase("orbit")

	if static_effects.has("white_hole"):
		var white_hole_state: Dictionary = static_effects["white_hole"]
		var white_hole_id := int(white_hole_state["id"])
		var white_hole_center: Vector2 = _cell_screen_position(white_hole_state["cell"]) + CELL_SIZE * 0.5
		if int(item.get("last_white_hole_id", -1)) != white_hole_id and object_position.distance_to(white_hole_center) <= OBJECT_ORBIT_INFLUENCE_RADIUS:
			return _launch_from_white_hole(item, white_hole_center, white_hole_id)
	return item


func _set_black_hole_motion(item: Dictionary, center: Vector2) -> Dictionary:
	# Start the inward spiral at the current point on a direct field handoff.
	item.erase("orbit")
	var offset: Vector2 = item["position"] - center
	item["motion"] = {
		"type": "black_hole_pull",
		"center": center,
		"radius": offset.length(),
		"angle": offset.angle(),
		"inward_speed": 0.0,
	}
	return item


func _launch_from_white_hole(item: Dictionary, center: Vector2, effect_id: int) -> Dictionary:
	if item.has("orbit") and snap_on_physics_end:
		item["position"] = _snap_position_to_tile_center(item["position"])
	var launch_angle := physics_rng.randf_range(0.0, TAU)
	item.erase("orbit")
	item["position"] = center
	item["last_white_hole_id"] = effect_id
	item["motion"] = {
		"type": "white_hole_launch",
		"center": center,
		"velocity": Vector2(cos(launch_angle), sin(launch_angle)) * WHITE_HOLE_LAUNCH_SPEED,
	}
	return item


func _update_spell_motion_objects(delta: float) -> bool:
	if not spell_physics_enabled:
		return false
	var changed := false
	for index in range(objects.size() - 1, -1, -1):
		var item: Dictionary = objects[index]
		if not item.has("motion"):
			continue
		var motion: Dictionary = item["motion"]
		var motion_type := str(motion.get("type", ""))
		match motion_type:
			"black_hole_pull":
				if not static_effects.has("black_hole"):
					item.erase("motion")
					objects[index] = item
					continue
				var black_hole_center: Vector2 = motion["center"]
				var radius := float(motion.get("radius", item["position"].distance_to(black_hole_center)))
				var angle := float(motion.get("angle", (item["position"] - black_hole_center).angle()))
				var inward_speed := minf(
					float(motion.get("inward_speed", 0.0)) + BLACK_HOLE_INWARD_ACCELERATION * delta,
					BLACK_HOLE_MAX_INWARD_SPEED
				)
				var next_radius := maxf(0.0, radius - inward_speed * delta)
				if next_radius <= BLACK_HOLE_CAPTURE_RADIUS:
					item.erase("position")
					item.erase("motion")
					item.erase("orbit")
					item.erase("last_white_hole_id")
					inventory.append(item)
					objects.remove_at(index)
					action_feedback = "BUCO NERO: ASSORBITO %s" % _item_name(item)
					changed = true
					continue
				angle += TAU / BLACK_HOLE_ORBIT_PERIOD_SECONDS * delta
				var next_position := black_hole_center + Vector2(cos(angle), sin(angle)) * next_radius
				if snap_during_physics:
					next_position = _snap_position_to_tile_center(next_position)
				item["position"] = next_position
				motion["radius"] = next_radius
				motion["angle"] = angle
				motion["inward_speed"] = inward_speed
				item["motion"] = motion
				objects[index] = item
				changed = true
			"white_hole_launch":
				var white_hole_velocity: Vector2 = motion["velocity"]
				# Preserve the launch impulse until the object clears the originating field.
				var white_hole_center: Vector2 = motion["center"]
				if item["position"].distance_to(white_hole_center) > OBJECT_ORBIT_INFLUENCE_RADIUS:
					white_hole_velocity = white_hole_velocity.move_toward(Vector2.ZERO, WHITE_HOLE_DECELERATION * delta)
				var white_hole_position: Vector2 = item["position"] + white_hole_velocity * delta
				var safe_min := Vector2(CELL_SIZE.x, CELL_SIZE.y) + Vector2.ONE * OBJECT_CLEARANCE_FROM_WALLS
				var safe_max := Vector2((COLUMNS - 1) * CELL_SIZE.x, (ROWS - 1) * CELL_SIZE.y) - Vector2.ONE * OBJECT_CLEARANCE_FROM_WALLS
				if white_hole_position.x < safe_min.x or white_hole_position.x > safe_max.x:
					white_hole_position.x = clampf(white_hole_position.x, safe_min.x, safe_max.x)
					white_hole_velocity.x = -white_hole_velocity.x * WHITE_HOLE_WALL_RESTITUTION
				if white_hole_position.y < safe_min.y or white_hole_position.y > safe_max.y:
					white_hole_position.y = clampf(white_hole_position.y, safe_min.y, safe_max.y)
					white_hole_velocity.y = -white_hole_velocity.y * WHITE_HOLE_WALL_RESTITUTION
				if snap_during_physics:
					white_hole_position = _snap_position_to_tile_center(white_hole_position)
				item["position"] = white_hole_position
				if white_hole_velocity.length() <= WHITE_HOLE_STOP_SPEED:
					if snap_on_physics_end:
						item["position"] = _snap_position_to_tile_center(item["position"])
					item.erase("motion")
				else:
					motion["velocity"] = white_hole_velocity
					item["motion"] = motion
				objects[index] = item
				changed = true
			_:
				item.erase("motion")
				objects[index] = item
	return changed


func _find_object_index_in_cell(cell: Vector2i) -> int:
	for index in range(objects.size()):
		var position: Vector2 = objects[index]["position"]
		var screen_column := floori(position.x / CELL_SIZE.x)
		var screen_row := floori(position.y / CELL_SIZE.y)
		var object_cell := Vector2i(screen_column, ROWS - screen_row - 1)
		if object_cell == cell:
			return index
	return -1


func _snap_position_to_tile_center(position: Vector2) -> Vector2:
	var screen_column := clampi(floori(position.x / CELL_SIZE.x), 1, COLUMNS - 2)
	var screen_row := clampi(floori(position.y / CELL_SIZE.y), 1, ROWS - 2)
	return Vector2(screen_column + 0.5, screen_row + 0.5) * CELL_SIZE


func get_spell_v1_settings() -> Dictionary:
	return {
		"implementation": active_spell_implementation,
		"physics_enabled": spell_physics_enabled,
		"snap_during_physics": snap_during_physics,
		"snap_on_physics_end": snap_on_physics_end,
		"influence_visualization": show_spell_influence_debug,
	}


func select_spell_implementation(version: String) -> void:
	if version != "V1":
		return
	active_spell_implementation = version
	queue_redraw()


func toggle_spell_physics() -> void:
	spell_physics_enabled = not spell_physics_enabled
	if not spell_physics_enabled:
		for index in range(objects.size()):
			var item: Dictionary = objects[index]
			item.erase("motion")
			item.erase("orbit")
			objects[index] = item
	else:
		_update_active_static_fields()
	queue_redraw()


func toggle_spell_snap_during_physics() -> void:
	snap_during_physics = not snap_during_physics
	queue_redraw()


func toggle_spell_snap_on_physics_end() -> void:
	snap_on_physics_end = not snap_on_physics_end
	queue_redraw()


func toggle_spell_influence_visualization() -> void:
	show_spell_influence_debug = not show_spell_influence_debug
	queue_redraw()


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


func interrupt_static_effect(effect: String, pending_cast_was_cancelled: bool = false) -> bool:
	var interrupted := pending_cast_was_cancelled
	if pending_static_effect == effect:
		pending_static_effect = ""
		pending_static_effect_cell = Vector2i.ZERO
		interrupted = true
	if active_effect == effect:
		active_effect = ""
		effect_frame = 0
		effect_timer = 0.0
		interrupted = true
	if static_effects.has(effect):
		_begin_static_effect_removal(effect)
		interrupted = true
	_update_active_static_fields()
	var effect_label := effect.to_upper().replace("_", " ")
	if interrupted:
		action_feedback = "%s: INTERROTTA" % effect_label
	else:
		action_feedback = "%s: NON ATTIVA" % effect_label
	queue_redraw()
	return interrupted


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), BACKGROUND, true)

	for row in range(1, ROWS - 1):
		for column in range(1, COLUMNS - 1):
			_draw_floor_tile(Vector2i(column, row))

	for row in range(ROWS):
		for column in range(COLUMNS):
			var cell := Vector2i(column, ROWS - row - 1)
			if _is_wall_cell(cell):
				_draw_wall_tile(cell)

	if _is_on_map(target_cell):
		var target_rect := Rect2(_cell_screen_position(target_cell), CELL_SIZE)
		if _is_inside_grid(target_cell):
			draw_rect(target_rect, Color(0.95, 0.72, 0.26, 0.08), true)
			draw_rect(target_rect, Color8(241, 190, 55, 220), false, 1.0)
		var target_label := "%02d,%02d" % [target_cell.x, target_cell.y]
		var label_rect := Rect2(target_rect.position + Vector2(1, 1), Vector2(25, 9))
		draw_rect(label_rect, Color8(5, 7, 16, 225), true)
		draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(2, 7), target_label, HORIZONTAL_ALIGNMENT_LEFT, 23, 6, Color8(255, 224, 135))

	if show_spell_influence_debug:
		_draw_spell_influence_debug()

	for item in objects:
		_draw_object(item)

	_draw_active_effect()
	_draw_hud()
	_draw_timing_bar()


func _draw_spell_influence_debug() -> void:
	for effect_variant in ["black_hole", "white_hole", "gravity_star"]:
		var effect_name := str(effect_variant)
		if not static_effects.has(effect_name):
			continue
		var state: Dictionary = static_effects[effect_name]
		var cell: Vector2i = state["cell"]
		var center := _cell_screen_position(cell) + CELL_SIZE * 0.5
		var color: Color
		var label: String
		match effect_name:
			"black_hole":
				color = Color8(191, 113, 255, 230)
				label = "BH"
			"white_hole":
				color = Color8(104, 224, 255, 230)
				label = "WH"
			_:
				color = Color8(255, 211, 105, 230)
				label = "STAR"
		var influence_radius := OBJECT_ORBIT_INFLUENCE_RADIUS
		draw_circle(center, influence_radius, Color(color.r, color.g, color.b, 0.055), true)
		draw_arc(center, influence_radius, 0.0, TAU, 64, color, 1.0, false)
		draw_line(center + Vector2(-3.0, 0.0), center + Vector2(3.0, 0.0), color, 1.0)
		draw_line(center + Vector2(0.0, -3.0), center + Vector2(0.0, 3.0), color, 1.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(5.0, -5.0), "%s · %d px" % [label, roundi(influence_radius)], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, color)


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


func _draw_object(item: Dictionary) -> void:
	_draw_object_trace(item)
	var catalog: Dictionary = OBJECT_CATALOG[item["id"]]
	var center: Vector2 = item["position"]
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


func _draw_object_trace(item: Dictionary) -> void:
	var trace_id := str(item.get("trace_id", ""))
	if trace_id.is_empty() or not object_traces.has(trace_id):
		return
	var trace: Dictionary = object_traces[trace_id]
	var points: Array = trace["points"]
	if points.size() < 2:
		return
	var catalog: Dictionary = OBJECT_CATALOG[item["id"]]
	var base_color: Color = catalog["color"]
	for point_index in range(1, points.size()):
		var previous_point: Dictionary = points[point_index - 1]
		var current_point: Dictionary = points[point_index]
		var current_position: Vector2 = current_point["position"]
		var fade := 1.0 - clampf(float(current_point["age"]) / OBJECT_TRACE_LIFETIME_SECONDS, 0.0, 1.0)
		var trail_color := Color(base_color.r, base_color.g, base_color.b, 0.08 + fade * 0.42)
		draw_line(previous_point["position"], current_position, trail_color, 1.0, false)
		draw_circle(current_position, 1.0, trail_color)


func _draw_active_effect() -> void:
	for effect_variant in ["black_hole", "white_hole", "gravity_star"]:
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
	var sprite_sheet: Texture2D
	match effect:
		"black_hole":
			sprite_sheet = BLACK_HOLE_SHEET
		"white_hole":
			sprite_sheet = WHITE_HOLE_SHEET
		_:
			sprite_sheet = GRAVITY_STAR_SHEET
	var start_column := STATIC_LOOP_START_COLUMN if static_version else CAST_START_COLUMN
	var source_rect := Rect2(Vector2((start_column + frame) * 32, 0), Vector2(32, 32))
	draw_texture_rect_region(sprite_sheet, Rect2(_cell_screen_position(cell), CELL_SIZE), source_rect)


func _draw_hud() -> void:
	draw_rect(Rect2(PLAYFIELD_SIZE.x, 0.0, SIDEBAR_WIDTH, VIEWPORT_SIZE.y), SIDEBAR_BACKGROUND, true)
	draw_line(Vector2(PLAYFIELD_SIZE.x, 0.0), Vector2(PLAYFIELD_SIZE.x, VIEWPORT_SIZE.y), Color8(63, 76, 103), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(392, 14), "RITMO CRYPTO", HORIZONTAL_ALIGNMENT_LEFT, 94, 8, Color8(229, 236, 251))
	draw_line(Vector2(392, 21), Vector2(488, 21), Color8(54, 66, 91), 1.0)

	_draw_sidebar_text("RITMO", 32, SIDEBAR_HEADING, 6)
	var tempo_status := "%d BPM P%s" % [roundi(bpm), bpm_profile.trim_prefix("P")] if bpm_enabled else "BPM OFF  %d" % roundi(bpm)
	_draw_sidebar_text(tempo_status, 43, Color8(226, 232, 249), 6)
	var judgment_text := "T%04d %s" % [turn_count, judgment_feedback]
	if not judgment_slot.is_empty():
		judgment_text += " " + judgment_slot
	_draw_sidebar_text(judgment_text, 53, _judgment_color(), 5)
	var detection_color := Color8(105, 236, 255) if audio_beat_candidate_flash_timer > 0.0 else SIDEBAR_MUTED
	_draw_sidebar_text("VOL %d%%  AUTO %03d" % [audio_volume_percent, audio_beat_candidate_count], 63, detection_color, 5)
	draw_line(Vector2(392, 71), Vector2(488, 71), Color8(42, 53, 76), 1.0)

	_draw_sidebar_text("MOVIMENTO", 89, SIDEBAR_HEADING, 6)
	var player_cell := _player_cell()
	_draw_sidebar_text("JERV %02d,%02d" % [player_cell.x, player_cell.y], 100, SIDEBAR_TEXT, 6)
	_draw_sidebar_text("TARGET %02d,%02d" % [target_cell.x, target_cell.y], 110, Color8(255, 224, 135), 6)
	draw_line(Vector2(392, 117), Vector2(488, 117), Color8(42, 53, 76), 1.0)

	_draw_sidebar_text("INVENTARIO", 136, SIDEBAR_HEADING, 6)
	_draw_sidebar_text("STACK %02d" % inventory.size(), 147, SIDEBAR_TEXT, 6)
	var top_item := "VUOTO" if inventory.is_empty() else _sidebar_item_name(inventory.back())
	_draw_sidebar_text("TOP " + top_item.substr(0, 14), 158, SIDEBAR_MUTED, 5)
	if bpm_enabled:
		var pulse_strength := beat_pulse_remaining / beat_pulse_duration
		var pulse_radius := 1.5 + pulse_strength * 2.0
		var pulse_color := Color(0.45, 0.92, 1.0, 0.35 + pulse_strength * 0.65)
		draw_circle(Vector2(488, 13), pulse_radius, pulse_color)


func _draw_sidebar_text(text: String, baseline_y: float, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(392, baseline_y), text, HORIZONTAL_ALIGNMENT_LEFT, 96, font_size, color)


func _sidebar_item_name(item: Dictionary) -> String:
	match str(item.get("id", "")):
		"ion_crystal":
			return "CRISTALLO"
		"brass_gear":
			return "INGRANAGGIO"
		"echo_orb":
			return "SFERA D'ECO"
		_:
			return "UNKNOWN"


func _player_cell() -> Vector2i:
	var player_node := get_parent().get_node_or_null("Jerv") as Node2D
	if player_node == null:
		return Vector2i.ZERO
	var player_position: Vector2 = player_node.position
	return _position_to_cell(player_position)


func _draw_timing_bar() -> void:
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


func _is_on_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS


func _cell_screen_position(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell.x, ROWS - cell.y - 1) * CELL_SIZE


func _item_name(item: Dictionary) -> String:
	return str(OBJECT_CATALOG[item["id"]]["name"])
