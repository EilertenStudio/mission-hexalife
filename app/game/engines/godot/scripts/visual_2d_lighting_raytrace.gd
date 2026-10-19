extends Sprite2D

const LIGHTMAP_SIZE := Vector2i(192, 144)
const LIGHTMAP_SCALE := 0.5
const ROOM_MIN := Vector2(32.0, 32.0)
const ROOM_MAX := Vector2(352.0, 256.0)
const SOURCE_PIXEL := Vector2(176.0, 144.0)
const PRIMARY_RAY_COUNT := 19
const BOUNCE_RAY_COUNT := 42
const PRIMARY_SPREAD := 0.0104719755
const DIRECT_COLOR := Color(198.0 / 255.0, 239.0 / 255.0, 1.0)
const CORE_COLOR := Color(245.0 / 255.0, 252.0 / 255.0, 1.0)
const BOUNCE_COLOR := Color(198.0 / 255.0, 239.0 / 255.0, 1.0)

var beam_direction := Vector2.RIGHT
var pending_direction := Vector2.RIGHT
var rebuild_delay := 0.0
var light_image: Image


func _ready() -> void:
	centered = false
	position = Vector2.ZERO
	scale = Vector2.ONE / LIGHTMAP_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = additive
	_rebuild_lightmap()


func _process(delta: float) -> void:
	if rebuild_delay <= 0.0:
		return
	rebuild_delay -= delta
	if rebuild_delay <= 0.0 and pending_direction.dot(beam_direction) < 0.999999:
		beam_direction = pending_direction
		_rebuild_lightmap()


func set_beam_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.0001:
		return
	pending_direction = direction.normalized()
	if pending_direction.dot(beam_direction) > 0.999999:
		return
	if rebuild_delay <= 0.0:
		rebuild_delay = 0.035


func _rebuild_lightmap() -> void:
	light_image = Image.create(LIGHTMAP_SIZE.x, LIGHTMAP_SIZE.y, false, Image.FORMAT_RGBAF)
	var center_hit := _ray_hit(SOURCE_PIXEL, beam_direction)
	var direct_angle_step := (PRIMARY_SPREAD * 2.0) / float(PRIMARY_RAY_COUNT - 1)
	for ray_index in range(PRIMARY_RAY_COUNT):
		var centered_index := float(ray_index) - float(PRIMARY_RAY_COUNT - 1) * 0.5
		var angle := centered_index * direct_angle_step
		var direction := beam_direction.rotated(angle).normalized()
		var hit := _ray_hit(SOURCE_PIXEL, direction)
		var energy := 0.115
		_trace_segment(SOURCE_PIXEL, hit["point"], 1.15, energy, DIRECT_COLOR)
		if ray_index == int(PRIMARY_RAY_COUNT / 2):
			_trace_segment(SOURCE_PIXEL, hit["point"], 0.7, 0.44, CORE_COLOR)

	var impact: Vector2 = center_hit["point"]
	var inward_normal: Vector2 = center_hit["normal"]
	_stamp(impact, 7.5, 0.60, CORE_COLOR)
	_stamp(impact, 16.0, 0.09, DIRECT_COLOR)
	_trace_diffuse_bounce(impact, inward_normal)
	texture = ImageTexture.create_from_image(light_image)


func _trace_diffuse_bounce(origin: Vector2, inward_normal: Vector2) -> void:
	var normal_angle := inward_normal.angle()
	for ray_index in range(BOUNCE_RAY_COUNT):
		var position := (float(ray_index) + 0.5) / float(BOUNCE_RAY_COUNT)
		var angle_offset := lerpf(-PI * 0.49, PI * 0.49, position)
		var direction := Vector2.from_angle(normal_angle + angle_offset)
		var cosine_weight := maxf(0.0, cos(angle_offset))
		var hit := _ray_hit(origin + inward_normal * 1.5, direction)
		var length := origin.distance_to(hit["point"])
		var distance_falloff := 1.0 / (1.0 + length * 0.0018)
		var energy := 0.24 * cosine_weight * distance_falloff
		_trace_segment(origin, hit["point"], 6.0, energy, BOUNCE_COLOR)
		_stamp(hit["point"], 5.5, energy * 0.48, DIRECT_COLOR)


func _ray_hit(origin: Vector2, direction: Vector2) -> Dictionary:
	var distance := INF
	var normal := Vector2.ZERO
	if direction.x > 0.00001:
		distance = (ROOM_MAX.x - origin.x) / direction.x
		normal = Vector2.LEFT
	elif direction.x < -0.00001:
		distance = (ROOM_MIN.x - origin.x) / direction.x
		normal = Vector2.RIGHT
	if direction.y > 0.00001:
		var y_distance := (ROOM_MAX.y - origin.y) / direction.y
		if y_distance < distance:
			distance = y_distance
			normal = Vector2.UP
	elif direction.y < -0.00001:
		var y_distance_to_top := (ROOM_MIN.y - origin.y) / direction.y
		if y_distance_to_top < distance:
			distance = y_distance_to_top
			normal = Vector2.DOWN
	return {"point": origin + direction * distance, "normal": normal}


func _trace_segment(start: Vector2, end: Vector2, radius: float, energy: float, color: Color) -> void:
	var distance := start.distance_to(end)
	var spacing := maxf(1.0, radius * 0.42)
	var steps := maxi(1, int(ceil(distance / spacing)))
	for step in range(steps + 1):
		var amount := float(step) / float(steps)
		var axial_falloff := lerpf(1.0, 0.83, amount)
		_stamp(start.lerp(end, amount), radius, energy * axial_falloff, color)


func _stamp(screen_position: Vector2, radius: float, energy: float, color: Color) -> void:
	if energy <= 0.0001:
		return
	var center := screen_position * LIGHTMAP_SCALE
	var sigma := maxf(0.55, radius * LIGHTMAP_SCALE * 0.52)
	var radius_in_texels := maxi(1, int(ceil(sigma * 2.6)))
	var center_x := int(round(center.x))
	var center_y := int(round(center.y))
	var min_x := maxi(0, center_x - radius_in_texels)
	var max_x := mini(LIGHTMAP_SIZE.x - 1, center_x + radius_in_texels)
	var min_y := maxi(0, center_y - radius_in_texels)
	var max_y := mini(LIGHTMAP_SIZE.y - 1, center_y + radius_in_texels)
	var denominator := 2.0 * sigma * sigma
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var offset := Vector2(float(x), float(y)) - center
			var gaussian := exp(-offset.length_squared() / denominator)
			if gaussian < 0.012:
				continue
			var previous := light_image.get_pixel(x, y)
			light_image.set_pixel(x, y, Color(
				previous.r + color.r * energy * gaussian,
				previous.g + color.g * energy * gaussian,
				previous.b + color.b * energy * gaussian,
				1.0
			))
