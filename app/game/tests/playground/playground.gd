extends Node2D

@onready var _feedback: Label = %Feedback
@onready var _status: Label = %Status

func _ready() -> void:
	for target in $Targets.get_children():
		if target is SurfaceTapTarget:
			target.tapped.connect(_on_target_tapped)


func _on_target_tapped(target: SurfaceTapTarget) -> void:
	var surface_material := str(target.get("surface_material"))
	var target_name := str(target.get("target_name"))
	_status.text = "%s  /  %s" % [surface_material.to_upper(), target_name.to_upper()]
	_feedback.text = _material_response(surface_material)


func _material_response(surface_material: String) -> String:
	match surface_material:
		"Glass":
			return "Un tocco leggero, quasi cristallino."
		"Metal":
			return "Un colpo breve risuona nella lamiera."
		"Wood":
			return "Il legno restituisce un suono sordo."
		_:
			return "La parete risponde con un colpo asciutto."
