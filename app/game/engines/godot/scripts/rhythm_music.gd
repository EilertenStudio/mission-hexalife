extends Node

const MUSIC_SOURCE_BPM := 120.0
const BASE_BEAT_SECONDS := 60.0 / MUSIC_SOURCE_BPM
const DEFAULT_VOLUME_PERCENT := 40
const VOLUME_STEP_PERCENT := 10
const TRACK: AudioStreamWAV = preload("res://assets/audio/dungeon-pulse-original.wav")

var volume_percent := DEFAULT_VOLUME_PERCENT
var track: AudioStreamWAV
var player: AudioStreamPlayer
var grid: Node
var track_duration := 0.0
var beats_per_loop := 0


func _ready() -> void:
	grid = get_parent().get_node("Grid")
	track = TRACK.duplicate() as AudioStreamWAV
	track_duration = track.get_length()
	beats_per_loop = maxi(1, roundi(track_duration / BASE_BEAT_SECONDS))
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_begin = 0
	track.loop_end = roundi(track_duration * track.mix_rate)
	player = AudioStreamPlayer.new()
	player.name = "TrackPlayer"
	player.stream = track
	add_child(player)
	_set_volume(volume_percent)
	grid.call("set_audio_volume_percent", volume_percent)
	player.play()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.physical_keycode == KEY_PAGEUP:
		_set_volume(volume_percent + VOLUME_STEP_PERCENT)
		get_viewport().set_input_as_handled()
	elif key_event.physical_keycode == KEY_PAGEDOWN:
		_set_volume(volume_percent - VOLUME_STEP_PERCENT)
		get_viewport().set_input_as_handled()


func set_tempo(bpm: float) -> void:
	if player:
		player.pitch_scale = bpm / MUSIC_SOURCE_BPM


func get_beat_phase() -> float:
	var song_time := _audible_song_position()
	return fposmod(song_time, BASE_BEAT_SECONDS) / BASE_BEAT_SECONDS


func get_track_beat_index() -> int:
	var song_time := _audible_song_position()
	return int(floor(song_time / BASE_BEAT_SECONDS)) % beats_per_loop


func get_beats_per_loop() -> int:
	return beats_per_loop


func _audible_song_position() -> float:
	if player == null or not player.playing or track_duration <= 0.0:
		return 0.0
	var mix_offset := AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	var source_position := player.get_playback_position() + mix_offset * player.pitch_scale
	return fposmod(maxf(0.0, source_position), track_duration)


func _set_volume(value: int) -> void:
	volume_percent = clampi(value, 0, 100)
	if player:
		player.volume_db = linear_to_db(float(volume_percent) / 100.0) if volume_percent > 0 else -80.0
	if grid:
		grid.call("set_audio_volume_percent", volume_percent)
