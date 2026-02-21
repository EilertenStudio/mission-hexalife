extends Node

func load_resources():
	Log.info(self, "Loading resources")
	SettingsManager.load()
