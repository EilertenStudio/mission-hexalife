extends Node2D

const COLUMNS := 12
const ROWS := 9
const CELL_SIZE := Vector2(32.0, 32.0)
const GRAPHIC_CELL_SIZE := Vector2(16.0, 16.0)
const GRID_SIZE := Vector2(384.0, 288.0)

const BACKGROUND := Color8(0, 0, 2)
const FLOOR := Color8(32, 34, 44)
const FLOOR_ALT := Color8(38, 40, 51)
const GRID_LINE := Color8(60, 65, 82)
const WALL_MORTAR := Color8(10, 12, 20)
const WALL_BLOCK := Color8(39, 43, 57)
const WALL_BLOCK_ALT := Color8(46, 50, 65)
const WALL_EDGE_LIGHT := Color8(74, 80, 96)
const WALL_EDGE_SHADOW := Color8(17, 20, 30)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(496.0, 288.0)), BACKGROUND, true)
	for cell_y in range(1, ROWS - 1):
		for cell_x in range(1, COLUMNS - 1):
			_draw_floor_tile(Vector2i(cell_x, cell_y))
	for cell_y in range(ROWS):
		for cell_x in range(COLUMNS):
			var cell := Vector2i(cell_x, ROWS - cell_y - 1)
			if _is_wall_cell(cell):
				_draw_wall_tile(cell)


func _draw_floor_tile(cell: Vector2i) -> void:
	var tile_origin := _cell_screen_position(cell)
	for graphic_y in range(2):
		for graphic_x in range(2):
			var graphic_origin := tile_origin + Vector2(graphic_x, graphic_y) * GRAPHIC_CELL_SIZE
			var graphic_cell_x := cell.x * int(CELL_SIZE.x / GRAPHIC_CELL_SIZE.x) + graphic_x
			var graphic_cell_y := cell.y * int(CELL_SIZE.y / GRAPHIC_CELL_SIZE.y) + graphic_y
			var is_alternate := posmod(graphic_cell_x + graphic_cell_y, 2) == 1
			draw_rect(Rect2(graphic_origin, GRAPHIC_CELL_SIZE), FLOOR_ALT if is_alternate else FLOOR, true)
			draw_rect(Rect2(graphic_origin, GRAPHIC_CELL_SIZE), GRID_LINE, false, 1.0)


func _draw_wall_tile(cell: Vector2i) -> void:
	var origin := _cell_screen_position(cell)
	draw_rect(Rect2(origin, CELL_SIZE), WALL_MORTAR, true)
	var split_x := 15 if posmod(cell.x + cell.y, 2) == 0 else 17
	var split_y := 15 if posmod(cell.y, 2) == 0 else 17
	var blocks := [
		Rect2(origin + Vector2(1, 1), Vector2(split_x - 1, split_y - 1)),
		Rect2(origin + Vector2(split_x + 1, 1), Vector2(30 - split_x, split_y - 1)),
		Rect2(origin + Vector2(1, split_y + 1), Vector2(split_x - 1, 30 - split_y)),
		Rect2(origin + Vector2(split_x + 1, split_y + 1), Vector2(30 - split_x, 30 - split_y)),
	]
	for index in range(blocks.size()):
		var block: Rect2 = blocks[index]
		var alternate := posmod(cell.x * 3 + cell.y * 5 + index, 3) == 0
		draw_rect(block, WALL_BLOCK_ALT if alternate else WALL_BLOCK, true)
		draw_line(block.position, Vector2(block.end.x - 1, block.position.y), WALL_EDGE_LIGHT, 1.0)
		draw_line(block.position, Vector2(block.position.x, block.end.y - 1), WALL_EDGE_LIGHT, 1.0)
		draw_line(Vector2(block.position.x + 1, block.end.y - 1), Vector2(block.end.x - 1, block.end.y - 1), WALL_EDGE_SHADOW, 1.0)
		draw_line(Vector2(block.end.x - 1, block.position.y + 1), Vector2(block.end.x - 1, block.end.y - 1), WALL_EDGE_SHADOW, 1.0)


func _is_wall_cell(cell: Vector2i) -> bool:
	return cell.x == 0 or cell.x == COLUMNS - 1 or cell.y == 0 or cell.y == ROWS - 1


func _cell_screen_position(cell: Vector2i) -> Vector2:
	return Vector2(cell.x, ROWS - cell.y - 1) * CELL_SIZE
