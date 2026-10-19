extends Node2D

const COLUMNS := 12
const ROWS := 9
const CELL_SIZE := 32
const FRAME_COUNT := 4
const LOOP_START_COLUMN := 4
const LOOP_FRAME_COUNT := 4
const FRAME_DURATION := 0.180
const STAR_LIGHT_ENERGY := 2.2
const STAR_LIGHT_PULSE_AMOUNT := 0.08
const STAR_LIGHT_PULSE_PERIOD := 0.72
const BLACK_HOLE_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-black-hole.png")
const WHITE_HOLE_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-white-hole.png")
const GRAVITY_STAR_SHEET: Texture2D = preload("res://assets/vfx/prop-weapon-cosmic_ring-star.png")

var active_spell := ""
var target_cell := Vector2i.ZERO
var elapsed := 0.0
var full_cast := false
var cast_sequence := 0
var cast_duration_seconds := FRAME_COUNT * FRAME_DURATION
var persistent_instances: Dictionary = {}
var retiring_instances: Array[Dictionary] = []
var gravity_star_light: PointLight2D
var radial_lights_enabled := true


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	var source_light: PointLight2D = get_parent().get_node("GravityStar/Light")
	gravity_star_light = PointLight2D.new()
	gravity_star_light.name = "SpellGravityStarLight"
	gravity_star_light.texture = source_light.texture
	gravity_star_light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	gravity_star_light.texture_scale = source_light.texture_scale
	gravity_star_light.color = source_light.color
	gravity_star_light.energy = STAR_LIGHT_ENERGY
	gravity_star_light.shadow_enabled = false
	gravity_star_light.enabled = false
	add_child(gravity_star_light)


func _process(delta: float) -> void:
	var should_redraw := false
	if not active_spell.is_empty():
		var old_frame := int(elapsed / FRAME_DURATION)
		elapsed += delta
		if elapsed >= cast_duration_seconds:
			if full_cast:
				persistent_instances[active_spell] = {
					"cell": target_cell,
					"frame": 0,
					"timer": 0.0,
				}
			active_spell = ""
			elapsed = 0.0
			full_cast = false
			should_redraw = true
		elif int(elapsed / FRAME_DURATION) != old_frame:
			should_redraw = true

	for index in range(retiring_instances.size() - 1, -1, -1):
		var retiring: Dictionary = retiring_instances[index]
		var old_frame := int(float(retiring["elapsed"]) / FRAME_DURATION)
		var retiring_elapsed := float(retiring["elapsed"]) + delta
		if retiring_elapsed >= cast_duration_seconds:
			retiring_instances.remove_at(index)
			should_redraw = true
			continue
		retiring["elapsed"] = retiring_elapsed
		retiring_instances[index] = retiring
		if int(retiring_elapsed / FRAME_DURATION) != old_frame:
			should_redraw = true

	for spell in persistent_instances.keys():
		var instance: Dictionary = persistent_instances[spell]
		var timer := float(instance["timer"]) + delta
		var next_frame := int(timer / FRAME_DURATION) % LOOP_FRAME_COUNT
		if next_frame != int(instance["frame"]):
			should_redraw = true
		instance["timer"] = timer
		instance["frame"] = next_frame
		persistent_instances[spell] = instance
	_sync_gravity_star_light()
	if should_redraw:
		queue_redraw()


func cast(spell: String, cell: Vector2i, is_full_cast: bool = false) -> void:
	if spell not in ["black_hole", "white_hole", "gravity_star"]:
		return
	if is_full_cast and persistent_instances.has(spell):
		_start_static_removal(spell)
	active_spell = spell
	target_cell = cell
	elapsed = 0.0
	full_cast = is_full_cast
	cast_sequence += 1
	queue_redraw()


func cancel(spell: String) -> void:
	var cancelled_cast := active_spell == spell
	if cancelled_cast:
		active_spell = ""
		elapsed = 0.0
		full_cast = false
	var removed_loop := persistent_instances.has(spell)
	if removed_loop:
		_start_static_removal(spell)
	if cancelled_cast or removed_loop:
		queue_redraw()


func _start_static_removal(spell: String) -> void:
	if not persistent_instances.has(spell):
		return
	var instance: Dictionary = persistent_instances[spell]
	persistent_instances.erase(spell)
	retiring_instances.append({
		"spell": spell,
		"cell": instance["cell"],
		"elapsed": 0.0,
	})


func get_status_text() -> String:
	if not active_spell.is_empty():
		return "%s %s" % [_spell_label(active_spell), "FULL" if full_cast else "CAST"]
	if not retiring_instances.is_empty():
		return "%s REMOVE" % _spell_label(str(retiring_instances[0]["spell"]))
	if persistent_instances.size() == 1:
		var only_spell := str(persistent_instances.keys()[0])
		return "STAR LIGHT" if only_spell == "gravity_star" else "%s LOOP" % _spell_label(only_spell)
	if persistent_instances.size() > 1:
		return "%d LOOPS" % persistent_instances.size()
	return "READY"


func set_radial_lights_enabled(enabled: bool) -> void:
	radial_lights_enabled = enabled
	_sync_gravity_star_light()


func get_debug_state() -> Dictionary:
	return {
		"active_spell": active_spell,
		"target_cell": target_cell,
		"frame": mini(int(elapsed / FRAME_DURATION), FRAME_COUNT - 1) if not active_spell.is_empty() else -1,
		"full_cast": full_cast,
		"duration_seconds": cast_duration_seconds,
		"cast_sequence": cast_sequence,
		"persistent_instances": persistent_instances.duplicate(true),
		"retiring_instances": retiring_instances.duplicate(true),
		"gameplay_effects": false,
	}


func _draw() -> void:
	for spell in persistent_instances.keys():
		var instance: Dictionary = persistent_instances[spell]
		var cell: Vector2i = instance["cell"]
		var frame := int(instance["frame"])
		_draw_spell_frame(str(spell), cell, LOOP_START_COLUMN + frame)
	if not active_spell.is_empty():
		var frame := mini(int(elapsed / FRAME_DURATION), FRAME_COUNT - 1)
		_draw_spell_frame(active_spell, target_cell, frame)
	for retiring in retiring_instances:
		var reverse_frame := mini(int(float(retiring["elapsed"]) / FRAME_DURATION), FRAME_COUNT - 1)
		reverse_frame = FRAME_COUNT - 1 - reverse_frame
		_draw_spell_frame(str(retiring["spell"]), retiring["cell"], reverse_frame)


func _draw_spell_frame(spell: String, cell: Vector2i, column: int) -> void:
	var source := Rect2(column * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
	var screen_y := (ROWS - cell.y - 1) * CELL_SIZE
	var destination := Rect2(cell.x * CELL_SIZE, screen_y, CELL_SIZE, CELL_SIZE)
	draw_texture_rect_region(_spell_sheet(spell), destination, source, Color.WHITE, false, true)


func _spell_sheet(spell: String) -> Texture2D:
	match spell:
		"black_hole":
			return BLACK_HOLE_SHEET
		"white_hole":
			return WHITE_HOLE_SHEET
		_:
			return GRAVITY_STAR_SHEET


func _spell_label(spell: String) -> String:
	match spell:
		"black_hole":
			return "BH"
		"white_hole":
			return "WH"
		_:
			return "STAR"


func _sync_gravity_star_light() -> void:
	if gravity_star_light == null:
		return
	if not radial_lights_enabled or not persistent_instances.has("gravity_star"):
		gravity_star_light.enabled = false
		return
	var instance: Dictionary = persistent_instances["gravity_star"]
	var cell: Vector2i = instance["cell"]
	gravity_star_light.position = Vector2(cell.x + 0.5, ROWS - cell.y - 0.5) * CELL_SIZE
	var pulse_phase := fmod(float(instance["timer"]), STAR_LIGHT_PULSE_PERIOD) / STAR_LIGHT_PULSE_PERIOD * TAU
	gravity_star_light.energy = STAR_LIGHT_ENERGY + sin(pulse_phase) * STAR_LIGHT_PULSE_AMOUNT
	gravity_star_light.enabled = true
