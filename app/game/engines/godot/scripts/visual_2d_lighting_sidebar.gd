extends Control

const PANEL_X := 384.0
const PANEL_WIDTH := 112.0

const PANEL := Color8(5, 7, 15)
const TEXT := Color8(205, 216, 237)
const MUTED := Color8(135, 151, 178)
const HEADING := Color8(117, 179, 214)
const STAR_COLOR := Color8(255, 207, 128)

var displayed_cell := Vector2i(-1, -1)
var displayed_spell_state := ""
var displayed_mode := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var jerv := scene.get_node_or_null("Jerv")
	if jerv == null or not jerv.has_method("get_grid_cell"):
		return
	var next_cell: Vector2i = jerv.call("get_grid_cell")
	var spell_vfx := scene.get_node_or_null("SpellVFX")
	var next_spell_state := String(spell_vfx.call("get_status_text")) if spell_vfx != null else "READY"
	var next_mode := String(scene.call("get_lighting_mode_label")) if scene.has_method("get_lighting_mode_label") else "2D RAYTRACE"
	if next_cell != displayed_cell or next_spell_state != displayed_spell_state or next_mode != displayed_mode:
		displayed_cell = next_cell
		displayed_spell_state = next_spell_state
		displayed_mode = next_mode
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(PANEL_X, 0, PANEL_WIDTH, 288), PANEL, true)
	draw_line(Vector2(PANEL_X, 0), Vector2(PANEL_X, 288), Color8(48, 57, 76), 1.0)
	_draw_text("LIGHT PROBE", 14, TEXT, 8)
	draw_line(Vector2(392, 21), Vector2(488, 21), Color8(44, 53, 72), 1.0)

	_draw_text("LIGHT MODE", 34, HEADING, 6)
	_draw_text(displayed_mode, 46, STAR_COLOR if displayed_mode == "STAR RADIAL" else TEXT, 6)
	_draw_text("MOUSE: AIM", 57, MUTED, 6)
	_draw_text("TAB: NEXT", 68, MUTED, 6)
	draw_line(Vector2(392, 77), Vector2(488, 77), Color8(37, 46, 64), 1.0)

	_draw_text("MOVIMENTO", 94, HEADING, 6)
	_draw_text("JERV %02d,%02d" % [displayed_cell.x, displayed_cell.y], 106, TEXT, 6)
	_draw_text("I J K L", 117, MUTED, 6)
	draw_line(Vector2(392, 127), Vector2(488, 127), Color8(37, 46, 64), 1.0)

	_draw_text("SPELL VFX", 145, HEADING, 6)
	_draw_text("A/S/D  CAST", 157, TEXT, 5)
	_draw_text("SHIFT + KEY  LOOP", 167, TEXT, 5)
	_draw_text("D FULL = STAR", 177, STAR_COLOR, 5)
	_draw_text("ALT + KEY REMOVE", 187, MUTED, 5)
	draw_line(Vector2(392, 198), Vector2(488, 198), Color8(37, 46, 64), 1.0)
	_draw_text("CURRENT", 216, HEADING, 6)
	_draw_text(displayed_spell_state, 228, STAR_COLOR if displayed_spell_state != "READY" else MUTED, 6)
	_draw_text("AMBIENT: LOW", 250, MUTED, 5)
	_draw_text("1 BOUNCE", 261, MUTED, 5)
	_draw_text("WALL: SOLID", 278, TEXT, 5)


func _draw_text(value: String, baseline_y: float, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(392, baseline_y), value, HORIZONTAL_ALIGNMENT_LEFT, 96, font_size, color)
