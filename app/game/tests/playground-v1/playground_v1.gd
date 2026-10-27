extends Node2D

@onready var _lighting_controls: CanvasLayer = $GarageRoom/LightingControls
@onready var _crt_filter: ColorRect = $CRTVertical/ScreenFilter
@onready var _crt_material: ShaderMaterial = $CRTVertical/ScreenFilter.material as ShaderMaterial

func _ready() -> void:
	_lighting_controls.visible = false
	_lighting_controls.crt_enabled_changed.connect(_on_crt_enabled_changed)
	_lighting_controls.crt_strength_changed.connect(_on_crt_strength_changed)
	_lighting_controls.crt_spacing_changed.connect(_on_crt_spacing_changed)
	_lighting_controls.call(
		"set_crt_control_values",
		_crt_filter.visible,
		_crt_material.get_shader_parameter("strength"),
		_crt_material.get_shader_parameter("period_px")
	)

func _on_crt_enabled_changed(is_enabled: bool) -> void:
	_crt_filter.visible = is_enabled


func _on_crt_strength_changed(value: float) -> void:
	_crt_material.set_shader_parameter("strength", value)


func _on_crt_spacing_changed(value: float) -> void:
	_crt_material.set_shader_parameter("period_px", value)
