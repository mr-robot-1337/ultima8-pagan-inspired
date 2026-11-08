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
	for i in range(12):
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

func play_enemy_death(e_type: String) -> void:
	var key: String = "death_" + e_type
	if sfx_streams.has(key):
		play(key, 0.04, -3.5)
	else:
		play("death_skeleton", 0.06, -4.0)

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

	var title_stream: AudioStream = _load_music_asset([
		"res://assets/music/pagan_ost.ogg",
		"res://assets/music/pagan_ost.mp3",
		"res://assets/music/tenebrae.ogg",
		"res://assets/music/tenebrae.mp3"
	])

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

	# =========================================================================
	# 24 DISTINCT ENEMY DEATH SOUND EFFECTS (One Unique Death SFX per Enemy!)
	# =========================================================================
	# 1. Swamp Kith: Chitinous insectoid chitter-hiss & crunch
	sfx_streams["death_kith"] = _make_sfx(0.36, func(t: float, d: float) -> float:
		var env: float = exp(-t * 9.0)
		var chitter: float = sin(t * TAU * (880.0 - t * 1400.0) + sin(t * TAU * 45.0) * 4.0)
		return (chitter * 0.55 + randf_range(-0.8, 0.8) * 0.45) * env * 0.8
	)
	# 2. Morphing Changeling: Warping phase-shift dissolve
	sfx_streams["death_changeling"] = _make_sfx(0.45, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var f: float = lerpf(520.0, 95.0, t / d) + sin(t * TAU * 18.0) * 85.0
		return sin(t * TAU * f) * env * 0.75
	)
	# 3. Floating Seeker Eye: High-pitched optic warble & pop
	sfx_streams["death_seeker"] = _make_sfx(0.34, func(t: float, d: float) -> float:
		var env: float = exp(-t * 10.0)
		var pop: float = sin(t * TAU * (1120.0 - t * 2600.0))
		var vib: float = sin(t * TAU * 32.0)
		return pop * (0.6 + 0.4 * vib) * env * 0.8
	)
	# 4. Torax Hive Drone: Buzzing wing-flutter descending into a sharp crack
	sfx_streams["death_torax"] = _make_sfx(0.38, func(t: float, d: float) -> float:
		var env: float = exp(-t * 8.5)
		var buzz: float = signf(sin(t * TAU * lerpf(310.0, 110.0, t / d))) * 0.5
		return (buzz + sin(t * TAU * 620.0) * 0.3) * env * 0.75
	)
	# 5. Catacomb Ghoul: Guttural rasping snarl & collapse
	sfx_streams["death_ghoul"] = _make_sfx(0.46, func(t: float, d: float) -> float:
		var env: float = exp(-t * 6.5)
		var f: float = lerpf(165.0, 62.0, t / d)
		var rasp: float = sin(t * TAU * f + sin(t * TAU * 28.0) * 3.5)
		return (rasp * 0.65 + randf_range(-0.6, 0.6) * 0.35) * env * 0.85
	)
	# 6. Risen Pagan Zombie: Low hollow groan & heavy thump
	sfx_streams["death_zombie"] = _make_sfx(0.52, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI) * exp(-t * 3.0)
		var f: float = lerpf(118.0, 54.0, t / d)
		return (sin(t * TAU * f) * 0.6 + sin(t * TAU * f * 1.5) * 0.3 + randf_range(-0.25, 0.25)) * env * 0.85
	)
	# 7. Wailing Ghost of Tenebrae: Ethereal shimmering spectral wail
	sfx_streams["death_ghost"] = _make_sfx(0.62, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var f: float = lerpf(680.0, 290.0, t / d) + sin(t * TAU * 9.5) * 42.0
		return (sin(t * TAU * f) * 0.55 + sin(t * TAU * (f * 1.5)) * 0.35) * env * 0.7
	)
	# 8. Pyros Fire Imp: Cackling shriek & sizzling flame pop
	sfx_streams["death_fire_imp"] = _make_sfx(0.40, func(t: float, d: float) -> float:
		var env: float = exp(-t * 7.5)
		var shriek: float = sin(t * TAU * lerpf(940.0, 240.0, t / d) + sin(t * TAU * 38.0) * 2.5)
		return (shriek * 0.5 + randf_range(-0.8, 0.8) * 0.5) * env * 0.8
	)
	# 9. Restless Skeleton: Clattering cascade of dry bones hitting stone
	sfx_streams["death_skeleton"] = _make_sfx(0.44, func(t: float, _d: float) -> float:
		var step_t: float = fmod(t, 0.08)
		var pulse: float = exp(-step_t * 42.0) * exp(-t * 3.5)
		var bone_f: float = 420.0 + float(int(t / 0.08) * 115 % 340)
		return (sin(t * TAU * bone_f) * 0.6 + randf_range(-0.8, 0.8) * 0.4) * pulse * 0.9
	)
	# 10. Heretic Outcast: Humanoid rogue cry & metallic dagger clatter
	sfx_streams["death_outcast"] = _make_sfx(0.42, func(t: float, d: float) -> float:
		var env: float = exp(-t * 6.8)
		var cry: float = sin(t * TAU * lerpf(260.0, 125.0, t / d)) * 0.65
		var ring: float = sin(t * TAU * 1240.0) * exp(-maxf(0.0, t - 0.15) * 35.0) * 0.35
		return (cry + ring) * env * 0.85
	)
	# 11. Fallen Zealan Fanatic: Deep resonant chanting chord cut short
	sfx_streams["death_zealan_monk"] = _make_sfx(0.50, func(t: float, d: float) -> float:
		var env: float = exp(-t * 5.5)
		var f: float = lerpf(220.0, 110.0, t / d)
		return (sin(t * TAU * f) * 0.5 + sin(t * TAU * f * 1.2) * 0.35 + sin(t * TAU * f * 2.0) * 0.2) * env * 0.8
	)
	# 12. Scion of Lithos (Necromancer): Dark rumbling seismic whisper
	sfx_streams["death_necromancer"] = _make_sfx(0.56, func(t: float, d: float) -> float:
		var env: float = exp(-t * 5.0)
		var f: float = lerpf(150.0, 48.0, t / d)
		return (sin(t * TAU * f) * 0.65 + randf_range(-0.7, 0.7) * 0.35) * env * 0.85
	)
	# 13. Acolyte of Stratos (Theurgist): Airy harmonic wind-chime whoosh
	sfx_streams["death_theurgist"] = _make_sfx(0.52, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var chime: float = sin(t * TAU * 784.0) * 0.4 + sin(t * TAU * 1046.5) * 0.3
		var wind: float = randf_range(-0.5, 0.5) * 0.35
		return (chime * exp(-t * 5.0) + wind) * env * 0.8
	)
	# 14. Mordea's Palace Guard: Heavy steel plate armor crash & groan
	sfx_streams["death_tempest_guard"] = _make_sfx(0.48, func(t: float, d: float) -> float:
		var env: float = exp(-t * 6.0)
		var clang: float = (sin(t * TAU * 340.0) + sin(t * TAU * 515.0) * 0.7) * exp(-t * 14.0)
		var groan: float = sin(t * TAU * lerpf(185.0, 82.0, t / d)) * 0.5
		return (clang * 0.5 + groan + randf_range(-0.4, 0.4) * 0.25) * env * 0.85
	)
	# 15. Cabal Sorcerer of Pyros: Arcane feedback crackle & flame implosion
	sfx_streams["death_sorcerer"] = _make_sfx(0.54, func(t: float, d: float) -> float:
		var env: float = exp(-t * 5.5)
		var sweep: float = sin(t * TAU * lerpf(640.0, 75.0, t / d) + sin(t * TAU * 50.0) * 3.0)
		return (sweep * 0.55 + randf_range(-0.85, 0.85) * 0.45) * env * 0.85
	)
	# 16. Cave Troll of Carthax: Deep booming beast roar & earth-shaking thud
	sfx_streams["death_troll"] = _make_sfx(0.58, func(t: float, d: float) -> float:
		var env: float = exp(-t * 4.8)
		var roar_f: float = lerpf(108.0, 42.0, t / d)
		var roar: float = sin(t * TAU * roar_f + sin(t * TAU * 22.0) * 2.8) * 0.75
		return (roar + randf_range(-0.5, 0.5) * 0.3) * env * 0.9
	)
	# 17. Winged Obsidian Gargoyle: Cracking stone shatter & wing thump
	sfx_streams["death_gargoyle"] = _make_sfx(0.52, func(t: float, d: float) -> float:
		var env: float = exp(-t * 6.2)
		var crack: float = sin(t * TAU * lerpf(280.0, 60.0, t / d)) * 0.55
		var debris: float = randf_range(-0.95, 0.95) * exp(-fmod(t, 0.12) * 25.0) * 0.55
		return (crack + debris) * env * 0.88
	)
	# 18. Spawn of the Lurker: Gurgling deep-water bubble roar & splash
	sfx_streams["death_water_lurker"] = _make_sfx(0.60, func(t: float, d: float) -> float:
		var env: float = exp(-t * 4.5)
		var gurgle: float = sin(t * TAU * (lerpf(210.0, 68.0, t / d) + sin(t * TAU * 36.0) * 55.0))
		return (gurgle * 0.65 + randf_range(-0.6, 0.6) * 0.35) * env * 0.85
	)
	# 19. Golem of Lithos: Avalanching boulder rumble & crystal shatter
	sfx_streams["death_earth_golem"] = _make_sfx(0.66, func(t: float, d: float) -> float:
		var env: float = exp(-t * 4.2)
		var rumble: float = sin(t * TAU * lerpf(92.0, 34.0, t / d)) * 0.7
		var crystal: float = sin(t * TAU * 920.0) * exp(-t * 16.0) * 0.35
		return (rumble + crystal + randf_range(-0.6, 0.6) * 0.35) * env * 0.92
	)
	# 20. Whirlwind Elemental (Aerial Servant): Howling tornado decompression whistle
	sfx_streams["death_aerial_servant"] = _make_sfx(0.62, func(t: float, d: float) -> float:
		var env: float = sin((t / d) * PI)
		var whistle: float = sin(t * TAU * lerpf(820.0, 180.0, t / d)) * 0.45
		return (whistle + randf_range(-0.9, 0.9) * 0.55) * env * 0.8
	)
	# 21. Brimstone Hellhound: Ferocious canine snarl & magma hiss
	sfx_streams["death_hellhound"] = _make_sfx(0.48, func(t: float, d: float) -> float:
		var env: float = exp(-t * 6.0)
		var bark_f: float = lerpf(245.0, 75.0, t / d)
		var snarl: float = sin(t * TAU * bark_f + sin(t * TAU * 42.0) * 3.2) * 0.65
		return (snarl + randf_range(-0.7, 0.7) * 0.4) * env * 0.88
	)
	# 22. Tenebrae High Executioner: Echoing metallic bell-toll & dark wraith shriek
	sfx_streams["death_executioner"] = _make_sfx(0.68, func(t: float, d: float) -> float:
		var env: float = exp(-t * 4.2)
		var bell: float = (sin(t * TAU * 293.66) + sin(t * TAU * 440.0) * 0.6) * exp(-t * 6.0) * 0.5
		var wraith: float = sin(t * TAU * lerpf(540.0, 130.0, t / d)) * 0.5
		return (bell + wraith) * env * 0.9
	)
	# 23. Greater Daemon of Pyros: Abyssal demonic roar with sub-bass thunder
	sfx_streams["death_daemon"] = _make_sfx(0.75, func(t: float, d: float) -> float:
		var env: float = exp(-t * 3.8)
		var f: float = lerpf(135.0, 38.0, t / d)
		var roar: float = (sin(t * TAU * f) + sin(t * TAU * f * 0.5) * 0.8 + sin(t * TAU * f * 1.5) * 0.5) * 0.45
		return (roar + randf_range(-0.7, 0.7) * 0.35) * env * 0.95
	)
	# 24. Malchir / Pyros Arch-Executioner (Titan Boss): Apocalyptic multi-stage boss explosion!
	sfx_streams["death_titan_boss"] = _make_sfx(1.10, func(t: float, d: float) -> float:
		var env: float = clampf(1.0 - (t / d), 0.0, 1.0)
		var f: float = lerpf(180.0, 32.0, t / d)
		var boom: float = sin(t * TAU * f) * 0.6 + sin(t * TAU * (f * 2.0)) * 0.3
		var choir: float = (sin(t * TAU * 293.66) + sin(t * TAU * 369.99) + sin(t * TAU * 440.0)) * 0.18
		return (boom + choir + randf_range(-0.6, 0.6) * 0.35) * env * 0.95
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
