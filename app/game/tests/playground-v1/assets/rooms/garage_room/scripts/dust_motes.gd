extends Node2D

# Keep this on the room's main canvas so CanvasModulate and PointLight2D shade it.
@export_range(12, 48, 1) var mote_count := 28
@export_range(0.1, 1.0, 0.05) var opacity := 0.65

const ROOM_MARGIN := 64.0
const PIXEL_SCALE := 4.0
const LOW_SHADE := Color(0.251, 0.251, 0.251)
const MID_SHADE := Color(0.376, 0.376, 0.376)

var _rng := RandomNumberGenerator.new()
var _bounds := Rect2()
var _elapsed := 0.0
var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _sizes: Array[Vector2] = []
var _phases: Array[float] = []
var _shades: Array[Color] = []


func _ready() -> void:
	_rng.randomize()
	var viewport_size := get_viewport_rect().size
	_bounds = Rect2(
		Vector2.ONE * ROOM_MARGIN,
		viewport_size - Vector2.ONE * ROOM_MARGIN * 2.0
	)

	for _index in range(mote_count):
		_positions.append(
			Vector2(
				_rng.randf_range(_bounds.position.x, _bounds.end.x),
				_rng.randf_range(_bounds.position.y, _bounds.end.y)
			)
		)
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(2.0, 6.0)
		_velocities.append(Vector2(cos(angle), sin(angle)) * speed)
		var size := PIXEL_SCALE if _rng.randf() < 0.82 else PIXEL_SCALE * 2.0
		_sizes.append(Vector2.ONE * size)
		_phases.append(_rng.randf_range(0.0, TAU))
		_shades.append(LOW_SHADE if _rng.randf() < 0.78 else MID_SHADE)


func _process(delta: float) -> void:
	_elapsed += delta
	for index in range(_positions.size()):
		var position := _positions[index]
		var phase := _phases[index]
		var sway := Vector2(
			sin(_elapsed * 0.47 + phase) * 1.8,
			cos(_elapsed * 0.31 + phase * 1.37) * 1.2
		)
		position += (_velocities[index] + sway) * delta
		position.x = wrapf(position.x, _bounds.position.x, _bounds.end.x)
		position.y = wrapf(position.y, _bounds.position.y, _bounds.end.y)
		_positions[index] = position
	queue_redraw()


func _draw() -> void:
	for index in range(_positions.size()):
		var mote_color := _shades[index]
		var shimmer := 0.82 + 0.18 * sin(_elapsed * 0.9 + _phases[index])
		mote_color.a = opacity * shimmer
		var pixel_position := (_positions[index] / PIXEL_SCALE).floor() * PIXEL_SCALE
		draw_rect(
			Rect2(pixel_position, _sizes[index]),
			mote_color,
			true
		)
