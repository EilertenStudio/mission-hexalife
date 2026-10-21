extends Control

const DESIGN_SIZE := Vector2(1990.0, 1066.0)

@onready var _composition: Control = $Composition


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_composition)
	_fit_composition()


func _fit_composition() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var fit_scale := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	_composition.scale = Vector2.ONE * fit_scale
	_composition.position = (viewport_size - DESIGN_SIZE * fit_scale) * 0.5
