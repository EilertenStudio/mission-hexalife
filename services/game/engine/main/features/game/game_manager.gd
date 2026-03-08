@tool
extends Node

var settings := SettingsManager.new()
var data := DataManager.new()
var scene := SceneManager.new()
var menu := GameMenuManager.new()
var ui := UIManager.new()
var context := ContextManager.new()

func _init() -> void:
	Log.event(self, "Init")

func _enter_tree() -> void:
	Log.event(self, "Enter Tree")

func _ready() -> void:
	Log.event(self, "Ready")

func _load() -> void:
	Log.debug(self, "Load managers")
	GameManager.settings.load()
	GameManager.scene._load()
	GameManager.ui.load()
	GameManager.context._load()
