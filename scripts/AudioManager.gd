class_name AudioManager
extends Node

const MIX_RATE: int = 22050
var sfx_streams: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer
var muted: bool = false
var current_track: String = ""
var music_tracks: Dictionary = {}

func _ready() -> void:
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		sfx_players.append(p)

	_generate_all_sfx()
	_setup_pagan_music()

func play_track(target: String) -> void:
	if current_track != target and music_tracks.has(target):
		current_track = target
		ambient_player.stream = music_tracks[target]
		if not muted:
			ambient_player.play()
	elif not muted and ambient_player != null and not ambient_player.playing and music_tracks.has(target):
		ambient_player.stream = music_tracks[target]
		ambient_player.play()

func set_combat_music(in_combat: bool) -> void:
	var target: String = "combat" if in_combat else "tenebrae"
	play_track(target)

func play(sfx_name: String, pitch_var: float = 0.08, vol_db: float = -6.0) -> void:
	if muted or not sfx_streams.has(sfx_name):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx_streams[sfx_name]
			p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
			p.volume_db = vol_db
			p.play()
			return
	var p0: AudioStreamPlayer = sfx_players[0]
	p0.stream = sfx_streams[sfx_name]
	p0.pitch_scale = 1.0
	p0.volume_db = vol_db
	p0.play()

func _load_music_asset(paths: Array[String]) -> AudioStream:
	for path in paths:
		var abs_path: String = ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			if path.ends_with(".ogg"):
				var ogg_direct: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(abs_path)
				if ogg_direct != null:
					ogg_direct.loop = true
					return ogg_direct
			elif path.ends_with(".mp3"):
				var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
				if bytes.size() > 0:
					var mp3_direct := AudioStreamMP3.new()
					mp3_direct.data = bytes
					mp3_direct.loop = true
					return mp3_direct
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is AudioStreamOggVorbis:
				var ogg := res as AudioStreamOggVorbis
				ogg.loop = true
				return ogg
			elif res is AudioStreamMP3:
				var mp3 := res as AudioStreamMP3
				mp3.loop = true
				return mp3
			elif res is AudioStreamWAV:
				var wav := res as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				return wav
	return null

func _setup_pagan_music() -> void:
	ambient_player = AudioStreamPlayer.new()
	ambient_player.volume_db = -6.0
	add_child(ambient_player)

	# 1. Load authentic Ultima VIII: Pagan - Main Theme (Start Screen) from res://assets/music/
	var title_stream: AudioStream = _load_music_asset([
		"res://assets/music/pagan_ost.ogg",
		"res://assets/music/pagan_ost.mp3",
		"res://assets/music/tenebrae.ogg",
		"res://assets/music/tenebrae.mp3"
	])

	# 2. Load authentic Ultima VIII: Pagan - Tenebrae theme from res://assets/music/
	var tenebrae_stream: AudioStream = _load_music_asset([
		"res://assets/music/tenebrae.ogg",
		"res://assets/music/tenebrae.mp3",
		"res://assets/music/docks.ogg",
		"res://assets/music/docks.mp3",
		"res://assets/music/pagan_ost.ogg",
		"res://assets/music/pagan_ost.mp3",
		"res://assets/music/tenebrae.wav"
	])
	if tenebrae_stream != null:
		music_tracks["tenebrae"] = tenebrae_stream
	else:
		music_tracks["tenebrae"] = _build_tenebrae_theme()

	if title_stream != null:
		music_tracks["title"] = title_stream
	else:
		music_tracks["title"] = music_tracks["tenebrae"]

	# 3. Load authentic Ultima VIII: Pagan - Combat theme from res://assets/music/
	var combat_stream: AudioStream = _load_music_asset([
		"res://assets/music/combat.ogg",
		"res://assets/music/combat.mp3",
		"res://assets/music/combat.wav"
	])
	if combat_stream != null:
		music_tracks["combat"] = combat_stream
	else:
		music_tracks["combat"] = _build_combat_theme()

	play_track("title")

func _build_tenebrae_theme() -> AudioStreamWAV:
	var duration: float = 32.0
	var samples: int = int(float(MIX_RATE) * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	var bass_freqs: Array[float] = [
		73.42, 58.27, 98.00, 55.00,
		73.42, 77.78, 65.41, 55.00
	]

	var arp_bars: Array = [
		[146.83, 220.00, 293.66, 349.23, 440.00, 349.23, 293.66, 220.00],
		[116.54, 174.61, 233.08, 293.66, 349.23, 293.66, 233.08, 174.61],
		[196.00, 293.66, 392.00, 466.16, 587.33, 466.16, 392.00, 293.66],
		[164.81, 220.00, 277.18, 329.63, 440.00, 349.23, 329.63, 277.18],
		[146.83, 220.00, 293.66, 349.23, 587.33, 440.00, 349.23, 293.66],
		[155.56, 233.08, 311.13, 392.00, 466.16, 392.00, 311.13, 233.08],
		[130.81, 196.00, 261.63, 311.13, 392.00, 311.13, 261.63, 196.00],
		[164.81, 220.00, 277.18, 349.23, 329.63, 277.18, 220.00, 164.81]
	]

	var lead_notes: Array[float] = [
		293.66, 349.23, 440.00, 392.00,
		349.23, 293.66, 233.08, 293.66,
		392.00, 466.16, 440.00, 392.00,
		329.63, 349.23, 277.18, 220.00,
		587.33, 523.25, 466.16, 440.00,
		311.13, 392.00, 349.23, 311.13,
		261.63, 311.13, 293.66, 261.63,
		277.18, 329.63, 293.66, 293.66
	]

	for i in range(samples):
		var t: float = float(i) / float(MIX_RATE)
		var bar_idx: int = int(t / 4.0) % 8
		var bar_t: float = fmod(t, 4.0)
		var step_idx: int = int(bar_t / 0.5) % 8
		var step_t: float = fmod(t, 0.5)
		var q_idx: int = int(t / 1.0) % 32
		var q_t: float = fmod(t, 1.0)

		var bf: float = bass_freqs[bar_idx]
		var pad_env: float = clampf(bar_t / 0.15, 0.0, 1.0) * clampf((4.0 - bar_t) / 0.15, 0.0, 1.0)
		var bass_sig: float = (
			sin(bar_t * TAU * bf) * 0.36 +
			sin(bar_t * TAU * (bf * 2.0) + 0.25 * sin(bar_t * TAU * 3.5)) * 0.18 +
			sin(bar_t * TAU * (bf * 3.0)) * 0.08
		) * pad_env

		var arp_bar: Array = arp_bars[bar_idx]
		var af: float = float(arp_bar[step_idx])
		var pluck_env: float = exp(-step_t * 6.8)
		var fm_mod: float = sin(step_t * TAU * af * 3.0) * exp(-step_t * 16.0) * 1.1
		var arp_sig: float = sin(step_t * TAU * af + fm_mod) * pluck_env * 0.28

		var lf: float = lead_notes[q_idx]
		var vib_phase: float = sin(q_t * TAU * 5.2) * 0.35 * clampf(q_t, 0.0, 1.0)
		var lead_env: float = clampf(q_t / 0.06, 0.0, 1.0) * exp(-q_t * 1.35)
		var lead_sig: float = (
			sin(q_t * TAU * lf + vib_phase) * 0.55 +
			sin(q_t * TAU * (lf * 2.0) + vib_phase * 2.0) * 0.30 +
			sin(q_t * TAU * (lf * 3.0)) * 0.15
		) * lead_env * 0.26

		var drum_env: float = exp(-bar_t * 9.5)
		var drum_phase: float = TAU * (46.0 * bar_t + 4.5 * (1.0 - exp(-bar_t * 12.0)))
		var drum_sig: float = sin(drum_phase) * drum_env * 0.24

		var mix: float = clampf((bass_sig + arp_sig + lead_sig + drum_sig) * 0.75, -1.0, 1.0)
		data.encode_s16(i * 2, int(mix * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	wav.data = data
	return wav

func _build_combat_theme() -> AudioStreamWAV:
	var duration: float = 8.0
	var samples: int = int(float(MIX_RATE) * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	var ostinato: Array[float] = [146.83, 146.83, 155.56, 146.83, 174.61, 155.56, 146.83, 130.81]
	for i in range(samples):
		var t: float = float(i) / float(MIX_RATE)
		var step: int = int(t / 0.25) % 8
		var st_t: float = fmod(t, 0.25)
		var f: float = ostinato[step]
		var env: float = clampf(st_t / 0.015, 0.0, 1.0) * exp(-st_t * 9.5)
		var brass: float = (sin(st_t * TAU * f) + sin(st_t * TAU * f * 2.0) * 0.6 + sin(st_t * TAU * f * 0.5) * 0.8) * env * 0.35
		var drum_t: float = fmod(t, 0.5)
		var drum_phase: float = TAU * (50.0 * drum_t + 3.8 * (1.0 - exp(-drum_t * 18.0)))
		var drum: float = sin(drum_phase) * exp(-drum_t * 14.0) * 0.35
		var mix: float = clampf((brass + drum) * 0.75, -1.0, 1.0)
		data.encode_s16(i * 2, int(mix * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples
	wav.data = data
	return wav

func _generate_all_sfx() -> void:
	sfx_streams["step"] = _make_sfx(0.06, func(t: float, _d: float) -> float:
		var env: float = exp(-t * 50.0)
		return (randf_range(-1.0, 1.0) * 0.5 + sin(t * TAU * 105.0) * 0.5) * env * 0.45
	)
	sfx_streams["jump"] = _make_sfx(0.22, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var freq: float = lerpf(140.0, 320.0, t / d)
		return (sin(t * TAU * freq) * 0.5 + randf_range(-0.3, 0.3)) * env * 0.5
	)
	sfx_streams["land"] = _make_sfx(0.14, func(t: float, d: float) -> float:
		var env: float = exp(-t * 28.0)
		var freq: float = lerpf(130.0, 48.0, t / d)
		return (sin(t * TAU * freq) * 0.7 + randf_range(-0.6, 0.6)) * env * 0.7
	)
	sfx_streams["sword"] = _make_sfx(0.20, func(t: float, d: float) -> float:
		var env: float = exp(-t * 16.0)
		var freq: float = lerpf(620.0, 180.0, t / d)
		return (randf_range(-0.8, 0.8) + sin(t * TAU * freq) * 0.5) * env * 0.6
	)
	sfx_streams["hit"] = _make_sfx(0.18, func(t: float, d: float) -> float:
		var env: float = exp(-t * 20.0)
		var freq: float = lerpf(240.0, 70.0, t / d)
		return (sin(t * TAU * freq) * 0.75 + randf_range(-0.7, 0.7)) * env * 0.8
	)
	sfx_streams["firebolt"] = _make_sfx(0.42, func(t: float, d: float) -> float:
		var env: float = exp(-t * 6.5)
		var freq: float = lerpf(420.0, 110.0, t / d) + sin(t * 90.0) * 35.0
		return (sin(t * TAU * freq) * 0.55 + randf_range(-0.85, 0.85) * 0.55) * env * 0.75
	)
	sfx_streams["lever"] = _make_sfx(0.55, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var clank: float = sin(t * TAU * 85.0) + sin(t * TAU * 128.0) * 0.6
		var rumble: float = randf_range(-0.6, 0.6)
		return (clank * 0.5 + rumble * 0.5) * env * 0.7
	)
	sfx_streams["pickup"] = _make_sfx(0.26, func(t: float, d: float) -> float:
		var env: float = exp(-t * 10.0)
		var freq: float = 440.0 if t < d * 0.45 else 660.0
		return sin(t * TAU * freq) * env * 0.55
	)
	sfx_streams["potion"] = _make_sfx(0.38, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var freq: float = lerpf(280.0, 760.0, t / d) + sin(t * 70.0) * 40.0
		return sin(t * TAU * freq) * env * 0.55
	)
	sfx_streams["splash"] = _make_sfx(0.55, func(t: float, _d: float) -> float:
		var env: float = exp(-t * 5.5)
		var bubble: float = sin(t * TAU * (180.0 + sin(t * 55.0) * 80.0)) * 0.4
		return (randf_range(-0.9, 0.9) * 0.7 + bubble) * env * 0.8
	)
	sfx_streams["portal"] = _make_sfx(0.85, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var freq: float = lerpf(160.0, 520.0, t / d)
		return (sin(t * TAU * freq) + sin(t * TAU * freq * 1.5) * 0.5) * env * 0.55
	)

func _make_sfx(duration: float, gen: Callable) -> AudioStreamWAV:
	var samples: int = int(float(MIX_RATE) * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(MIX_RATE)
		var v: float = clampf(float(gen.call(t, duration)), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
