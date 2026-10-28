extends Node

enum SourceMode { SAMPLE, PROCEDURAL }

@export_enum("Sample", "Procedural") var source_mode: int = SourceMode.SAMPLE:
	set(value):
		if source_mode == value:
			return
		source_mode = value
		if is_node_ready():
			_configure_audio_source()

@export var sample_stream: AudioStream
@export_range(-30.0, 0.0, 1.0) var volume_db := -12.0
@export_range(0.1, 1.5, 0.05) var rain_intensity := 0.85
@export_range(700.0, 3000.0, 50.0) var muffled_cutoff_hz := 1700.0

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.35
const DISTANT_RUMBLE_HZ := 380.0
const DROPLET_RATE := 0.00045
const DROPLET_DECAY := 0.9988

@onready var _player: AudioStreamPlayer = $AudioStreamPlayer

var _rng := RandomNumberGenerator.new()
var _playback: AudioStreamGeneratorPlayback
var _muffle_coefficient := 0.0
var _rumble_coefficient := 0.0
var _filtered_left := 0.0
var _filtered_right := 0.0
var _rumble_left := 0.0
var _rumble_right := 0.0
var _droplet_left := 0.0
var _droplet_right := 0.0


func _ready() -> void:
	_rng.randomize()
	_muffle_coefficient = _low_pass_coefficient(muffled_cutoff_hz)
	_rumble_coefficient = _low_pass_coefficient(DISTANT_RUMBLE_HZ)
	_configure_audio_source()


func _configure_audio_source() -> void:
	_player.stop()
	_playback = null
	_player.volume_db = volume_db

	if source_mode == SourceMode.SAMPLE and sample_stream != null:
		var looped_sample := sample_stream.duplicate() as AudioStream
		if looped_sample is AudioStreamWAV:
			var wav_sample := looped_sample as AudioStreamWAV
			wav_sample.loop_begin = 0
			wav_sample.loop_end = roundi(wav_sample.get_length() * wav_sample.mix_rate)
			wav_sample.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_player.stream = looped_sample
		_player.play()
		return

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = BUFFER_LENGTH
	_player.stream = stream
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_buffer()


func _process(_delta: float) -> void:
	_fill_buffer()


func set_sample_enabled(is_enabled: bool) -> void:
	source_mode = SourceMode.SAMPLE if is_enabled else SourceMode.PROCEDURAL


func set_volume_linear(value: float) -> void:
	var linear_volume := clampf(value, 0.0, 1.0)
	volume_db = linear_to_db(linear_volume) if linear_volume > 0.0 else -80.0
	if is_instance_valid(_player):
		_player.volume_db = volume_db


func _low_pass_coefficient(cutoff_hz: float) -> float:
	return 1.0 - exp(-TAU * cutoff_hz / MIX_RATE)


func _fill_buffer() -> void:
	if _playback == null:
		return

	var frame_count := _playback.get_frames_available()
	if frame_count <= 0:
		return

	var samples := PackedVector2Array()
	samples.resize(frame_count)
	for frame in range(frame_count):
		samples[frame] = _next_rain_sample()
	_playback.push_buffer(samples)


func _next_rain_sample() -> Vector2:
	var noise_left := _rng.randf_range(-1.0, 1.0)
	var noise_right := noise_left * 0.72 + _rng.randf_range(-1.0, 1.0) * 0.28
	_filtered_left += (noise_left - _filtered_left) * _muffle_coefficient
	_filtered_right += (noise_right - _filtered_right) * _muffle_coefficient
	_rumble_left += (_filtered_left - _rumble_left) * _rumble_coefficient
	_rumble_right += (_filtered_right - _rumble_right) * _rumble_coefficient

	if _rng.randf() < DROPLET_RATE * rain_intensity:
		_droplet_left = _rng.randf_range(0.08, 0.32)
		_droplet_right = _rng.randf_range(0.08, 0.32)

	var patter_left := _rng.randf_range(-1.0, 1.0) * _droplet_left
	var patter_right := _rng.randf_range(-1.0, 1.0) * _droplet_right
	_droplet_left *= DROPLET_DECAY
	_droplet_right *= DROPLET_DECAY

	var left := (_filtered_left * 0.3 + _rumble_left * 0.18 + patter_left * 0.12)
	var right := (_filtered_right * 0.3 + _rumble_right * 0.18 + patter_right * 0.12)
	return Vector2(left, right) * rain_intensity
