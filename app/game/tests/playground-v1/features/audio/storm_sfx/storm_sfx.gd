extends Node

signal lightning_level_changed(value: float)

@export_range(0.5, 3.0, 0.1) var thunder_frequency := 1.0
@export_range(0.5, 3.0, 0.1) var wind_frequency := 1.0

const THUNDER_SAMPLES: Array[AudioStream] = [
	preload("res://tests/playground-v1/features/audio/storm_sfx/samples/thunder_clap_roboroo.mp3"),
	preload("res://tests/playground-v1/features/audio/storm_sfx/samples/thunder_clap_fission9.mp3"),
	preload("res://tests/playground-v1/features/audio/storm_sfx/samples/thunder_roll_emulius.mp3"),
]
const WIND_SAMPLES: Array[AudioStream] = [
	preload("res://tests/playground-v1/features/audio/storm_sfx/samples/wind_gust_wintuh.mp3"),
	preload("res://tests/playground-v1/features/audio/storm_sfx/samples/wind_gust_zip_creates.mp3"),
	preload("res://tests/playground-v1/features/audio/storm_sfx/samples/wind_gust_hyperbloodhell.mp3"),
]

const FIRST_THUNDER_DELAY := Vector2(14.0, 30.0)
const THUNDER_INTERVAL := Vector2(24.0, 52.0)
const FIRST_WIND_DELAY := Vector2(8.0, 20.0)
const WIND_INTERVAL := Vector2(26.0, 48.0)
const MIN_EVENT_FREQUENCY := 0.5
const MAX_EVENT_FREQUENCY := 3.0

@onready var _thunder_player: AudioStreamPlayer = $ThunderPlayer
@onready var _wind_player: AudioStreamPlayer = $WindPlayer
@onready var _thunder_timer: Timer = $ThunderTimer
@onready var _wind_timer: Timer = $WindTimer

var _random := RandomNumberGenerator.new()
var _last_thunder_index := -1
var _last_wind_index := -1
var _thunder_is_playing := false


func _ready() -> void:
	_random.randomize()
	_thunder_timer.timeout.connect(_on_thunder_timer_timeout)
	_wind_timer.timeout.connect(_on_wind_timer_timeout)
	_schedule_thunder(FIRST_THUNDER_DELAY)
	_schedule_wind(FIRST_WIND_DELAY)


func _on_thunder_timer_timeout() -> void:
	await _play_thunder_event()
	_schedule_thunder(THUNDER_INTERVAL)


func _play_thunder_event() -> void:
	if _thunder_is_playing:
		return
	_thunder_is_playing = true
	var sample_index := _get_next_sample_index(THUNDER_SAMPLES, _last_thunder_index)
	var volume_db := _random.randf_range(-11.0, -5.0)
	var pitch_scale := _random.randf_range(0.92, 1.06)
	await _play_lightning_sequence()
	_thunder_player.stream = THUNDER_SAMPLES[sample_index]
	_thunder_player.volume_db = volume_db
	_thunder_player.pitch_scale = pitch_scale
	_thunder_player.play()
	_last_thunder_index = sample_index
	_thunder_is_playing = false


func _on_wind_timer_timeout() -> void:
	_play_wind_event()
	_schedule_wind(WIND_INTERVAL)


func _play_wind_event() -> void:
	_last_wind_index = _play_random_sample(
		_wind_player,
		WIND_SAMPLES,
		_last_wind_index,
		Vector2(-20.0, -12.0),
		Vector2(0.9, 1.08)
	)


func trigger_thunder() -> void:
	if not is_node_ready() or _thunder_is_playing:
		return
	_thunder_timer.stop()
	await _play_thunder_event()
	_schedule_thunder(THUNDER_INTERVAL)


func trigger_wind() -> void:
	if not is_node_ready():
		return
	_wind_timer.stop()
	_play_wind_event()
	_schedule_wind(WIND_INTERVAL)


func set_thunder_frequency(value: float) -> void:
	thunder_frequency = clampf(value, MIN_EVENT_FREQUENCY, MAX_EVENT_FREQUENCY)
	if is_node_ready():
		_schedule_thunder(THUNDER_INTERVAL)


func set_wind_frequency(value: float) -> void:
	wind_frequency = clampf(value, MIN_EVENT_FREQUENCY, MAX_EVENT_FREQUENCY)
	if is_node_ready():
		_schedule_wind(WIND_INTERVAL)


func _schedule_thunder(delay_range: Vector2) -> void:
	_thunder_timer.start(_random.randf_range(delay_range.x, delay_range.y) / thunder_frequency)


func _schedule_wind(delay_range: Vector2) -> void:
	_wind_timer.start(_random.randf_range(delay_range.x, delay_range.y) / wind_frequency)


func _play_lightning_sequence() -> void:
	var flash_count := _random.randi_range(2, 4)
	for flash_index in range(flash_count):
		lightning_level_changed.emit(_random.randf_range(0.38, 0.72))
		await get_tree().create_timer(_random.randf_range(0.035, 0.09), false).timeout
		lightning_level_changed.emit(0.0)
		if flash_index < flash_count - 1:
			await get_tree().create_timer(_random.randf_range(0.07, 0.17), false).timeout
	await get_tree().create_timer(_random.randf_range(0.25, 0.7), false).timeout


func _play_random_sample(
	player: AudioStreamPlayer,
	samples: Array[AudioStream],
	previous_index: int,
	volume_range: Vector2,
	pitch_range: Vector2
) -> int:
	var sample_index := _get_next_sample_index(samples, previous_index)

	player.stream = samples[sample_index]
	player.volume_db = _random.randf_range(volume_range.x, volume_range.y)
	player.pitch_scale = _random.randf_range(pitch_range.x, pitch_range.y)
	player.play()
	return sample_index


func _get_next_sample_index(samples: Array[AudioStream], previous_index: int) -> int:
	var sample_index := _random.randi_range(0, samples.size() - 1)
	if samples.size() > 1 and sample_index == previous_index:
		sample_index = (sample_index + _random.randi_range(1, samples.size() - 1)) % samples.size()
	return sample_index
