extends Node

const MUSIC_SOURCE_BPM := 140.0
const BASE_BEAT_SECONDS := 60.0 / MUSIC_SOURCE_BPM
const DEFAULT_VOLUME_PERCENT := 40
const VOLUME_STEP_PERCENT := 10
const TRACK_PATH := "res://tests/test-gameplay-rhythm-crypto/assets/audio/hard-dungeon-bpm140.ogg"
const ANALYSIS_BUS_NAME := "BeatAnalysis"
const BAND_RANGES_HZ := [Vector2(45.0, 180.0), Vector2(180.0, 900.0), Vector2(900.0, 3000.0)]
const BAND_WEIGHTS := Vector3(0.78, 0.22, 0.0)
const MIN_ONSET_INTERVAL_SECONDS := 0.30
const MIN_ONSET_FLUX := 0.004
const ONSET_THRESHOLD_MULTIPLIER := 3.5
const FLUX_BASELINE_TIME_SECONDS := 0.5

var volume_percent := DEFAULT_VOLUME_PERCENT
var track: AudioStreamOggVorbis
var player: AudioStreamPlayer
var grid: Node
var track_duration := 0.0
var beats_per_loop := 0
var analyzer_bus_index := -1
var analyzer_effect_index := -1
var analyzer_instance: AudioEffectSpectrumAnalyzerInstance
var previous_band_energy := Vector3.ZERO
var has_previous_spectrum := false
var adaptive_flux_baseline := 0.0
var onset_cooldown := 0.0
var detected_candidate_count := 0
var last_detected_flux := 0.0
var last_detection_threshold := 0.0


func _ready() -> void:
	grid = get_parent().get_node("Grid")
	track = AudioStreamOggVorbis.load_from_file(TRACK_PATH)
	if track == null:
		push_error("Unable to load Hard Dungeon audio from %s" % TRACK_PATH)
		return
	track.bpm = MUSIC_SOURCE_BPM
	track.beat_count = 288
	track.bar_beats = 4
	track.loop = true
	track_duration = track.get_length()
	beats_per_loop = maxi(1, roundi(track_duration / BASE_BEAT_SECONDS))
	_setup_spectrum_analyzer()
	player = AudioStreamPlayer.new()
	player.name = "TrackPlayer"
	player.stream = track
	if analyzer_bus_index >= 0:
		player.bus = ANALYSIS_BUS_NAME
	add_child(player)
	_set_volume(volume_percent)
	grid.call("set_audio_volume_percent", volume_percent)
	player.play()
	set_process(analyzer_bus_index >= 0)


func _process(delta: float) -> void:
	if onset_cooldown > 0.0:
		onset_cooldown = maxf(0.0, onset_cooldown - delta)
	if analyzer_instance == null:
		var effect_instance := AudioServer.get_bus_effect_instance(analyzer_bus_index, analyzer_effect_index)
		analyzer_instance = effect_instance as AudioEffectSpectrumAnalyzerInstance
		if analyzer_instance == null:
			return

	var band_energy := Vector3.ZERO
	for band_index in BAND_RANGES_HZ.size():
		var band_range: Vector2 = BAND_RANGES_HZ[band_index]
		var magnitude := analyzer_instance.get_magnitude_for_frequency_range(band_range.x, band_range.y)
		band_energy[band_index] = (magnitude.x + magnitude.y) * 0.5
	if not has_previous_spectrum:
		previous_band_energy = band_energy
		has_previous_spectrum = true
		return

	var flux := 0.0
	for band_index in BAND_RANGES_HZ.size():
		flux += maxf(0.0, band_energy[band_index] - previous_band_energy[band_index]) * BAND_WEIGHTS[band_index]
	previous_band_energy = band_energy
	var energy := band_energy.dot(BAND_WEIGHTS)
	var threshold := maxf(MIN_ONSET_FLUX, adaptive_flux_baseline * ONSET_THRESHOLD_MULTIPLIER)
	last_detected_flux = flux
	last_detection_threshold = threshold

	if onset_cooldown <= 0.0 and energy > MIN_ONSET_FLUX and flux > threshold:
		onset_cooldown = MIN_ONSET_INTERVAL_SECONDS
		detected_candidate_count += 1
		if grid and grid.has_method("set_audio_beat_candidate"):
			grid.call("set_audio_beat_candidate", get_beat_phase(), flux / threshold)

	var baseline_blend := 1.0 - exp(-delta / FLUX_BASELINE_TIME_SECONDS)
	adaptive_flux_baseline = lerpf(adaptive_flux_baseline, flux, baseline_blend)


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


func get_detection_debug() -> Dictionary:
	return {
		"enabled": analyzer_instance != null,
		"candidate_count": detected_candidate_count,
		"last_flux": last_detected_flux,
		"threshold": last_detection_threshold,
		"cooldown": onset_cooldown,
	}


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


func _setup_spectrum_analyzer() -> void:
	analyzer_bus_index = AudioServer.get_bus_index(ANALYSIS_BUS_NAME)
	if analyzer_bus_index < 0:
		AudioServer.add_bus()
		analyzer_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(analyzer_bus_index, ANALYSIS_BUS_NAME)
		AudioServer.set_bus_send(analyzer_bus_index, "Master")
		AudioServer.set_bus_volume_db(analyzer_bus_index, 0.0)

	for effect_index in AudioServer.get_bus_effect_count(analyzer_bus_index):
		if AudioServer.get_bus_effect(analyzer_bus_index, effect_index) is AudioEffectSpectrumAnalyzer:
			analyzer_effect_index = effect_index
			break
	if analyzer_effect_index < 0:
		var analyzer := AudioEffectSpectrumAnalyzer.new()
		analyzer.buffer_length = 0.1
		analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
		analyzer_effect_index = AudioServer.get_bus_effect_count(analyzer_bus_index)
		AudioServer.add_bus_effect(analyzer_bus_index, analyzer)
