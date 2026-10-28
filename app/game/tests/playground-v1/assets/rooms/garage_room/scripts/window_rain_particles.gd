extends Node2D
## Pixel rain visible outside the transparent panes of the V006 garage windows.

@export_range(4, 48, 1) var particle_count := 18
@export_range(0.5, 8.0, 0.1) var minimum_speed := 2.0
@export_range(0.5, 12.0, 0.1) var maximum_speed := 5.0

# Transparent pane interiors in garage_room-v006-background.png. Coordinates are
# in source-image pixels, so the particles follow the room's pixel scale.
const PANE_AREAS: Array[Rect2i] = [
	Rect2i(110, 45, 20, 3),
	Rect2i(133, 45, 7, 3),
	Rect2i(110, 51, 20, 3),
	Rect2i(133, 51, 7, 3),
	Rect2i(180, 45, 7, 3),
	Rect2i(190, 45, 20, 3),
	Rect2i(180, 51, 7, 3),
	Rect2i(190, 51, 20, 3),
]
const RAIN_SHADES: Array[Color] = [Color("#606060"), Color("#606060"), Color("#808080")]

@onready var _background: Sprite2D = get_node("../Background")

var _random := RandomNumberGenerator.new()
var _drops: Array[Dictionary] = []


func _ready() -> void:
	_random.randomize()
	for _index in range(particle_count):
		_drops.append(_make_drop())


func _process(delta: float) -> void:
	for drop in _drops:
		var pane: Rect2i = PANE_AREAS[drop.pane_index]
		drop.position += Vector2(drop.drift, drop.speed) * delta
		if floor(drop.position.y) + drop.length > pane.end.y:
			_reset_drop(drop)
	queue_redraw()


func _draw() -> void:
	var source_size := Vector2(_background.texture.get_size())
	var pixel_scale := _background.global_scale
	for drop in _drops:
		var source_position: Vector2 = drop.position
		var source_pixel := Vector2(floor(source_position.x), floor(source_position.y))
		for segment in range(drop.length):
			var source_point := source_pixel + Vector2(0.0, segment)
			var background_local := source_point - source_size * 0.5
			var scene_position := to_local(_background.to_global(background_local))
			draw_rect(
				Rect2(scene_position, pixel_scale),
				drop.color,
				true
			)


func _make_drop() -> Dictionary:
	var pane_index := _choose_pane()
	var pane: Rect2i = PANE_AREAS[pane_index]
	var length := _random.randi_range(1, 2)
	return {
		"pane_index": pane_index,
		"position": Vector2(
			_random.randi_range(pane.position.x, pane.end.x - 1),
			_random.randf_range(pane.position.y, pane.end.y - length)
		),
		"speed": _random.randf_range(minimum_speed, maximum_speed),
		"drift": _random.randf_range(-0.25, 0.25),
		"length": length,
		"color": RAIN_SHADES[_random.randi_range(0, RAIN_SHADES.size() - 1)],
	}


func _reset_drop(drop: Dictionary) -> void:
	var replacement := _make_drop()
	for key in replacement:
		drop[key] = replacement[key]


func _choose_pane() -> int:
	var total_area := 0
	for pane in PANE_AREAS:
		total_area += pane.size.x * pane.size.y
	var selected_area := _random.randi_range(0, total_area - 1)
	for index in range(PANE_AREAS.size()):
		var pane: Rect2i = PANE_AREAS[index]
		selected_area -= pane.size.x * pane.size.y
		if selected_area < 0:
			return index
	return PANE_AREAS.size() - 1
