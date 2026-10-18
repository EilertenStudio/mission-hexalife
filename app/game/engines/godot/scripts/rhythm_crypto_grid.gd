extends Node2D

const COLUMNS := 10
const ROWS := 7
const CELL_SIZE := Vector2(32.0, 32.0)
const GRAPHIC_GRID_SIZE := Vector2(16.0, 16.0)
const GRID_ORIGIN := Vector2(32.0, 32.0)

const BACKGROUND := Color8(5, 7, 16)
const FLOOR := Color8(13, 16, 29)
const FLOOR_ALTERNATE := Color8(17, 20, 35)
const GRID_LINE := Color8(43, 49, 69)
const MOVEMENT_TILE_LINE := Color8(61, 67, 88)
const OUTER_BORDER := Color8(99, 67, 99)


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
