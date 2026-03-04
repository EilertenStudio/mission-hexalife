@tool
extends Node

func _enter_tree() -> void:
	Log.event(self, "Init")

func _ready() -> void:
	Log.event(self, "Ready")

var settings := SettingsManager.new()
var state := StateManager.new()
var scene := SceneManager.new()
var menu :=  GameMenuManager.new()
