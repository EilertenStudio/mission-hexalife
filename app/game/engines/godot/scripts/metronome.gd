extends Node

const SAMPLE_RATE := 44100
const CLICK_DURATION_SECONDS := 0.035
const CLICK_FREQUENCY_HZ := 1800.0
const CLICK_AMPLITUDE := 0.58
const DEFAULT_VOLUME_PERCENT := 40
const VOLUME_STEP_PERCENT := 10

var volume_percent := DEFAULT_VOLUME_PERCENT
var enabled := true
var tick_player: AudioStreamPlayer
var grid: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	grid = get_parent().get_node("Grid")
	tick_player = AudioStreamPlayer.new()
	tick_player.name = "TickPlayer"
	tick_player.stream = _create_click_stream()
	add_child(tick_player)
	_apply_volume()
	grid.call("set_audio_volume_percent", volume_percent)


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


func play_tick() -> void:
	if not enabled or volume_percent <= 0:
		return
	tick_player.play()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		tick_player.stop()


func _set_volume(value: int) -> void:
	volume_percent = clampi(value, 0, 100)
	_apply_volume()
	grid.call("set_audio_volume_percent", volume_percent)


func _apply_volume() -> void:
	tick_player.volume_db = linear_to_db(float(volume_percent) / 100.0) if volume_percent > 0 else -80.0


func _create_click_stream() -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * CLICK_DURATION_SECONDS)
	var sample_data := PackedByteArray()
	sample_data.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var progress := float(sample_index) / float(sample_count)
		var envelope := pow(1.0 - progress, 9.0)
		var sample := sin(TAU * CLICK_FREQUENCY_HZ * float(sample_index) / float(SAMPLE_RATE))
		sample *= envelope * CLICK_AMPLITUDE
		sample_data.encode_s16(sample_index * 2, int(sample * 32767.0))

	var click_stream := AudioStreamWAV.new()
	click_stream.format = AudioStreamWAV.FORMAT_16_BITS
	click_stream.mix_rate = SAMPLE_RATE
	click_stream.stereo = false
	click_stream.data = sample_data
	return click_stream
