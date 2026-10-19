extends Sprite2D

const COLUMNS := 12
const ROWS := 9
const CELL_SIZE := 32.0
const GRID_ORIGIN := Vector2.ZERO
const FLAP_FRAME_COUNT := 2
const DEFAULT_BPM := 120.0

var grid_cell := Vector2i(9, 6)
var bpm := DEFAULT_BPM
var bpm_enabled := true
var frame_duration := 0.25
var frame_timer := 0.0
var flap_frame := 0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	region_enabled = true
	region_rect = Rect2(0.0, 0.0, CELL_SIZE, CELL_SIZE)
	random.randomize()
	_update_position()


func _process(delta: float) -> void:
	frame_timer += delta
	while frame_timer >= frame_duration:
		frame_timer -= frame_duration
		flap_frame = (flap_frame + 1) % FLAP_FRAME_COUNT
		_set_flap_frame()


func set_tempo(value_bpm: float, enabled: bool) -> void:
	var frame_phase := frame_timer / frame_duration
	bpm = value_bpm
	bpm_enabled = enabled
	var animation_bpm := bpm if bpm_enabled else DEFAULT_BPM
	frame_duration = 60.0 / animation_bpm / FLAP_FRAME_COUNT
	frame_timer = frame_phase * frame_duration
	_set_flap_frame()


func advance_beat(player_cell: Vector2i) -> void:
	if not bpm_enabled:
		return

	var destinations: Array[Vector2i] = []
	var cardinal_directions: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(1, 0),
	]
	for direction_value in cardinal_directions:
		var direction: Vector2i = direction_value
		var candidate := grid_cell + direction
		if _is_inside_grid(candidate) and candidate != player_cell:
			destinations.append(candidate)

	if destinations.is_empty():
		return

	grid_cell = destinations[random.randi_range(0, destinations.size() - 1)]
	_update_position()


func occupies_cell(cell: Vector2i) -> bool:
	return grid_cell == cell


func _is_inside_grid(cell: Vector2i) -> bool:
	return cell.x > 0 and cell.x < COLUMNS - 1 and cell.y > 0 and cell.y < ROWS - 1


func _update_position() -> void:
	position = Vector2(
		GRID_ORIGIN.x + (grid_cell.x + 0.5) * CELL_SIZE,
		GRID_ORIGIN.y + (ROWS - grid_cell.y - 0.5) * CELL_SIZE
	)


func _set_flap_frame() -> void:
	region_rect = Rect2(flap_frame * CELL_SIZE, 0.0, CELL_SIZE, CELL_SIZE)
