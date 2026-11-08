class_name GameController
extends Node2D

var tiles: Array = []
var props: Array = []
var enemies: Array = []
var ground_items: Array = []
var projectiles: Array = []
var particles: Array = []
var barks: Array = []
var bridge_tiles: Array = []
var crumbling_coords: Array[Vector2i] = []
var minimap_tex: ImageTexture = null
var pentagram_center: Vector3 = Vector3(8.5, 4.5, 1.92)

var renderer: IsoRenderer
var audio: AudioManager

# Procedural Level Progression (1 to 666)
var current_level: int = 1
var level_seed: int = 0
var level_title: String = "The Sunken Docks of Tenebrae"

# Avatar State & 3 Lives System
var avatar_pos: Vector3 = Vector3(4.5, 17.8, 1.0)
var avatar_vel: Vector3 = Vector3.ZERO
var last_safe_pos: Vector3 = Vector3(4.5, 17.8, 1.0)
var avatar_grounded: bool = true
var avatar_moving: bool = false
var avatar_dead: bool = false
var respawn_timer: float = 0.0
var avatar_facing: int = 2
var avatar_anim_t: float = 0.0
var step_sfx_timer: float = 0.0

var lives: int = 3
var max_lives: int = 3
var hp: int = 100
var max_hp: int = 100
var mana: int = 60
var max_mana: int = 60
var combat_mode: bool = false
var attack_cd: float = 0.0
var attack_anim_timer: float = 0.0
var cast_cd: float = 0.0
var screen_shake: float = 0.0

# Inventory & Progression
var inventory: Array[String] = []
var bridge_raised: bool = false
var bridge_anim_progress: float = 0.0
var obelisk_awakened: bool = false
var game_won: bool = false
var show_help: bool = true
var show_minimap: bool = true
var show_paperdoll: bool = false

# Start Screen & Credits Menu State
var in_start_menu: bool = true
var show_credits: bool = false
var game_has_started: bool = false
var menu_selected_idx: int = 0
var menu_anim_t: float = 0.0

# Camera & Mouse
var camera_offset: Vector2 = Vector2.ZERO
var mouse_world_pos: Vector3 = Vector3.ZERO
var mouse_world_valid: bool = false
var hovered_prop: Variant = null
var hovered_enemy: Variant = null
var right_click_held: bool = false
var last_rclick_time: float = 0.0

const ITEM_INFO := {
	"iron_key": {"name": "Rusty Iron Key", "color": Color(0.75, 0.78, 0.84), "desc": "Unlocks the Iron Portcullis"},
	"red_potion": {"name": "Red Healing Potion", "color": Color(0.92, 0.20, 0.20), "desc": "Click or press [1] to heal +50 HP & restore +1 Life (up to 3)"},
	"blue_potion": {"name": "Blue Mana Potion", "color": Color(0.24, 0.52, 0.96), "desc": "Click or press [2] to restore +40 Mana"},
	"flame_blade": {"name": "Flame Sting Blade", "color": Color(1.0, 0.55, 0.12), "desc": "Enchanted blade of Pyros (34 DMG)"},
	"ignis_scroll": {"name": "Ignis Spell Scroll", "color": Color(0.98, 0.78, 0.22), "desc": "Unlocks Firebolt [Q / F] (10 Mana)"},
	"ritual_candle": {"name": "Blood Ritual Candle", "color": Color(0.85, 0.14, 0.24), "desc": "Used at the Heart of the Pentagram"},
	"grimoire": {"name": "Necromancer's Grimoire", "color": Color(0.75, 0.25, 0.88), "desc": "Drains +8 HP on every attack"}
}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	SpriteFactory.export_sprites_to_assets()
	audio = AudioManager.new()
	add_child(audio)

	renderer = IsoRenderer.new()
	renderer.game = self
	renderer.z_index = -1
	add_child(renderer)

	_start_new_run()
	audio.play_track("title")

func _start_or_resume_game() -> void:
	in_start_menu = false
	show_credits = false
	right_click_held = false
	audio.play("portal", 0.05, -5.0)
	audio.set_combat_music(combat_mode or LevelData.is_boss_level(current_level))
	if not game_has_started:
		game_has_started = true
		_say_bark(avatar_pos, "Level 1 of 666: " + level_title + " (3/3 Lives)", Color(0.98, 0.90, 0.55), 4.0)

func _activate_menu_option(idx: int) -> void:
	match idx:
		0:
			_start_or_resume_game()
		1:
			show_credits = true
			audio.play("pickup", 0.05, -5.0)
		2:
			audio.play("lever", 0.05, -5.0)
			get_tree().quit()

func _get_menu_button_rect(idx: int, vp: Vector2) -> Rect2:
	var btn_w: float = 310.0
	var btn_h: float = 50.0
	var start_y: float = vp.y * 0.5 + 24.0
	return Rect2(vp.x * 0.5 - btn_w * 0.5, start_y + float(idx) * 64.0, btn_w, btn_h)

func _handle_start_menu_input(event: InputEvent) -> void:
	var vp: Vector2 = get_viewport_rect().size
	if show_credits:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				show_credits = false
				audio.play("step", 0.05, -4.0)
		elif event is InputEventKey and event.pressed and not event.echo:
			var k := event as InputEventKey
			if k.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_BACKSPACE]:
				show_credits = false
				audio.play("step", 0.05, -4.0)
		return

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		for i in range(3):
			if _get_menu_button_rect(i, vp).has_point(mm.position):
				if menu_selected_idx != i:
					menu_selected_idx = i
					audio.play("step", 0.05, -8.0)
				break
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			for i in range(3):
				if _get_menu_button_rect(i, vp).has_point(mb.position):
					menu_selected_idx = i
					_activate_menu_option(i)
					return
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.keycode:
			KEY_UP, KEY_W:
				menu_selected_idx = (menu_selected_idx + 2) % 3
				audio.play("step", 0.05, -6.0)
			KEY_DOWN, KEY_S:
				menu_selected_idx = (menu_selected_idx + 1) % 3
				audio.play("step", 0.05, -6.0)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_activate_menu_option(menu_selected_idx)
			KEY_C:
				show_credits = true
				audio.play("pickup", 0.05, -5.0)
			KEY_ESCAPE:
				if game_has_started:
					_start_or_resume_game()
			KEY_Q:
				get_tree().quit()

func _start_new_run() -> void:
	current_level = 1
	lives = max_lives
	hp = max_hp
	mana = max_mana
	inventory.clear()
	combat_mode = false
	game_won = false
	_load_level(1, false)

func _advance_to_next_level(target_lvl: int = -1) -> void:
	var next_lvl: int = (current_level + 1) if target_lvl < 0 else target_lvl
	current_level = clampi(next_lvl, 1, LevelData.MAX_LEVELS)
	game_won = false
	_load_level(current_level, true)
	if not in_start_menu:
		audio.set_combat_music(combat_mode or LevelData.is_boss_level(current_level))
	if LevelData.is_boss_level(current_level):
		_say_bark(avatar_pos, "BOSS SANCTUM (Level " + str(current_level) + "): Face the Arch-Executioner!", Color(1.0, 0.45, 0.30), 4.2)
	else:
		_say_bark(avatar_pos, "Descended to Level " + str(current_level) + " of " + str(LevelData.MAX_LEVELS) + ": " + level_title, Color(0.95, 0.85, 0.45), 3.6)

func _load_level(lvl_num: int = 1, keep_progress: bool = false) -> void:
	current_level = clampi(lvl_num, 1, LevelData.MAX_LEVELS)
	var data: Dictionary = LevelData.build_level(current_level, -1)
	tiles = data["tiles"]
	props = data["props"]
	enemies = data["enemies"]
	avatar_pos = data["spawn"]
	bridge_tiles = data.get("bridge_tiles", [])
	pentagram_center = data.get("pentagram_center", Vector3(8.5, 4.5, 1.92))
	level_title = String(data.get("level_title", "The Sunken Sanctum"))
	level_seed = int(data.get("seed", 0))

	last_safe_pos = avatar_pos
	avatar_vel = Vector3.ZERO
	avatar_grounded = true
	avatar_dead = false

	if not keep_progress:
		lives = max_lives
		hp = max_hp
		mana = max_mana
		inventory.clear()
	else:
		# Strip level-specific puzzle keys/candles while preserving weapons, spells, grimoire & potions
		var kept: Array[String] = []
		for item_id in inventory:
			if item_id != "iron_key" and item_id != "ritual_candle":
				kept.append(item_id)
		inventory = kept

	ground_items.clear()
	projectiles.clear()
	particles.clear()
	barks.clear()
	bridge_raised = false
	bridge_anim_progress = 0.0
	obelisk_awakened = false
	game_won = false

	crumbling_coords.clear()
	for x in range(LevelData.MAP_W):
		for y in range(LevelData.MAP_H):
			var t: Dictionary = tiles[x][y]
			if int(t["type"]) == LevelData.TileType.CRUMBLING_STONE:
				crumbling_coords.append(Vector2i(x, y))
	_rebuild_minimap_texture()

func _rebuild_minimap_texture() -> void:
	if tiles.is_empty():
		return
	var img: Image = Image.create(LevelData.MAP_W, LevelData.MAP_H, false, Image.FORMAT_RGBA8)
	for x in range(LevelData.MAP_W):
		for y in range(LevelData.MAP_H):
			var t: Dictionary = tiles[x][y]
			var tt: int = int(t["type"])
			var mc := Color(0.08, 0.16, 0.32)
			if tt == LevelData.TileType.LAVA:
				mc = Color(0.78, 0.22, 0.05)
			elif tt == LevelData.TileType.GRASS_FLOOR:
				mc = Color(0.18, 0.42, 0.14)
			elif tt == LevelData.TileType.COBBLE_FLOOR or tt == LevelData.TileType.BRIDGE_RAISED:
				mc = Color(0.38, 0.30, 0.22)
			elif tt == LevelData.TileType.PENTAGRAM_FLOOR:
				mc = Color(0.72, 0.14, 0.18)
			elif tt == LevelData.TileType.WALL_BLOCK:
				mc = Color(0.78, 0.82, 0.88)
			elif tt != LevelData.TileType.WATER and tt != LevelData.TileType.BRIDGE_SUNKEN:
				mc = Color(0.54, 0.58, 0.66)
			img.set_pixel(x, y, mc)
	minimap_tex = ImageTexture.create_from_image(img)

func has_item(item_id: String) -> bool:
	return inventory.has(item_id)

func count_item(item_id: String) -> int:
	var c := 0
	for it in inventory:
		if it == item_id:
			c += 1
	return c

func remove_one_item(item_id: String) -> bool:
	var idx := inventory.find(item_id)
	if idx != -1:
		inventory.remove_at(idx)
		return true
	return false

func get_lit_ritual_pyres_count() -> int:
	var c := 0
	for prop in props:
		if prop["type"] == "brazier" and prop.get("ritual", false) and prop.get("lit", false):
			c += 1
	return c

func _get_active_final_boss() -> Dictionary:
	for enemy in enemies:
		var e: Dictionary = enemy
		if bool(e.get("final_boss", false)) and int(e["hp"]) > 0:
			return e
	return {}

func _unhandled_input(event: InputEvent) -> void:
	if in_start_menu:
		_handle_start_menu_input(event)
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				var now := Time.get_ticks_msec() / 1000.0
				if now - last_rclick_time < 0.28:
					# Classic Ultima VIII double-right-click to jump!
					_try_jump(true)
				last_rclick_time = now
				right_click_held = true
			else:
				right_click_held = false
		elif mb.button_index == MOUSE_BUTTON_MIDDLE and mb.pressed:
			_try_jump(true)
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if _handle_hud_click(mb.position):
				return
			if game_won:
				if current_level < LevelData.MAX_LEVELS:
					_advance_to_next_level(current_level + 1)
				else:
					_start_new_run()
				return
			_handle_world_left_click()

	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				in_start_menu = true
				show_credits = false
				right_click_held = false
				audio.play_track("title")
			KEY_SPACE:
				_try_jump(false)
			KEY_ENTER, KEY_KP_ENTER:
				if game_won:
					if current_level < LevelData.MAX_LEVELS:
						_advance_to_next_level(current_level + 1)
					else:
						_start_new_run()
			KEY_C, KEY_TAB:
				combat_mode = not combat_mode
				audio.play("sword", 0.1, -9.0)
				audio.set_combat_music(combat_mode or LevelData.is_boss_level(current_level))
				_say_bark(avatar_pos, "Combat Ready!" if combat_mode else "Weapon Sheathed.", Color(0.95, 0.75, 0.35), 1.8)
			KEY_Q, KEY_F:
				_try_cast_firebolt()
			KEY_E:
				_interact_nearest()
			KEY_1:
				_use_inventory_item("red_potion")
			KEY_2:
				_use_inventory_item("blue_potion")
			KEY_H:
				show_help = not show_help
			KEY_M:
				show_minimap = not show_minimap
			KEY_I, KEY_P:
				show_paperdoll = not show_paperdoll
			KEY_N, KEY_PAGEDOWN:
				if current_level < LevelData.MAX_LEVELS:
					audio.play("portal", 0.05, -4.0)
					_advance_to_next_level(current_level + 1)
			KEY_B:
				audio.play("portal", 0.05, -4.0)
				if current_level < 6:
					_advance_to_next_level(6)
				elif current_level < LevelData.MAX_LEVELS:
					_advance_to_next_level(LevelData.MAX_LEVELS)
			KEY_R:
				_start_new_run()
				_say_bark(avatar_pos, "New Procedural Run Started (Level 1 — 3/3 Lives)!", Color(0.9, 0.8, 0.5), 2.5)

func _process(delta: float) -> void:
	menu_anim_t += delta
	var vp_size := get_viewport_rect().size
	if in_start_menu:
		var orbit_x: float = float(LevelData.MAP_W) * 0.5 + cos(menu_anim_t * 0.25) * 8.0
		var orbit_y: float = float(LevelData.MAP_H) * 0.5 + sin(menu_anim_t * 0.25) * 8.0
		var orbit_screen: Vector2 = IsoMath.world_to_screen(orbit_x, orbit_y, 2.0)
		var menu_cam: Vector2 = vp_size * 0.5 - orbit_screen + Vector2(0.0, 20.0)
		camera_offset = camera_offset.lerp(menu_cam, minf(1.0, delta * 3.5))
		queue_redraw()
		return

	var av_screen := IsoMath.world_to_screen(avatar_pos.x, avatar_pos.y, avatar_pos.z)
	var target_cam := vp_size * 0.5 - av_screen + Vector2(0, 20)
	if screen_shake > 0.0:
		screen_shake = maxf(0.0, screen_shake - delta)
		target_cam += Vector2(randf_range(-5.0, 5.0), randf_range(-4.0, 4.0))
	camera_offset = camera_offset.lerp(target_cam, minf(1.0, delta * 9.0))

	_update_mouse_world()
	_update_timers_and_world(delta)
	if not game_won:
		_update_avatar(delta)
		_update_enemies(delta)
	_update_projectiles_and_particles(delta)
	queue_redraw()

func _update_mouse_world() -> void:
	var mpos := get_viewport().get_mouse_position() - camera_offset
	var w2 := IsoMath.screen_to_world_on_z(mpos, avatar_pos.z)
	var gz := get_floor_z_at(w2.x, w2.y)
	var w_exact := IsoMath.screen_to_world_on_z(mpos, gz)
	mouse_world_pos = Vector3(w_exact.x, w_exact.y, get_floor_z_at(w_exact.x, w_exact.y))
	mouse_world_valid = w_exact.x >= 0.0 and w_exact.x < LevelData.MAP_W and w_exact.y >= 0.0 and w_exact.y < LevelData.MAP_H

	hovered_prop = null
	var best_d := 26.0
	for prop in props:
		var p: Vector3 = prop["pos"]
		var sp := IsoMath.world_to_screen(p.x, p.y, p.z) + Vector2(0, -12)
		var d := sp.distance_to(mpos)
		if d < best_d:
			best_d = d
			hovered_prop = prop

	hovered_enemy = null
	var best_ed := 28.0
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		var p: Vector3 = enemy["pos"]
		var sp := IsoMath.world_to_screen(p.x, p.y, p.z) + Vector2(0, -18)
		var d := sp.distance_to(mpos)
		if d < best_ed:
			best_ed = d
			hovered_enemy = enemy

func _update_timers_and_world(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)
	attack_anim_timer = maxf(0.0, attack_anim_timer - delta)
	cast_cd = maxf(0.0, cast_cd - delta)

	# Passive slow mana regeneration
	if not avatar_dead and mana < max_mana:
		if Engine.get_process_frames() % 45 == 0:
			mana = mini(max_mana, mana + 1)

	# Animate rising Sunken Bridge when lever is pulled
	if bridge_raised and bridge_anim_progress < 1.0:
		bridge_anim_progress = minf(1.0, bridge_anim_progress + delta * 0.7)
		var bz := lerpf(0.0, 1.4, bridge_anim_progress)
		for cell in bridge_tiles:
			var coord: Vector2i = cell
			tiles[coord.x][coord.y]["type"] = LevelData.TileType.BRIDGE_RAISED
			tiles[coord.x][coord.y]["z"] = bz
		if bridge_anim_progress >= 1.0:
			_rebuild_minimap_texture()

	# Update Crumbling Stones
	for coord in crumbling_coords:
		var t: Dictionary = tiles[coord.x][coord.y]
		if not bool(t["crumbled"]) and float(t["crumble_timer"]) > 0.0:
			t["crumble_timer"] = float(t["crumble_timer"]) + delta
			if float(t["crumble_timer"]) >= 0.85:
				t["crumbled"] = true
				t["crumble_timer"] = 4.0 # Respawn countdown
				audio.play("land", 0.1, -4.0)
				_spawn_burst(Vector3(float(coord.x) + 0.5, float(coord.y) + 0.5, float(t["base_z"])), Color(0.55, 0.42, 0.35), 10)
		elif bool(t["crumbled"]):
			t["crumble_timer"] = float(t["crumble_timer"]) - delta
			if float(t["crumble_timer"]) <= 0.0:
				t["crumbled"] = false
				t["crumble_timer"] = 0.0

	# Update floating barks
	for i in range(barks.size() - 1, -1, -1):
		barks[i]["timer"] -= delta
		barks[i]["rise"] += delta * 12.0
		if barks[i]["timer"] <= 0.0:
			barks.remove_at(i)

func _trigger_avatar_death(cause_msg: String, col: Color) -> void:
	if avatar_dead:
		return
	avatar_dead = true
	lives = maxi(0, lives - 1)
	respawn_timer = 1.9
	screen_shake = 0.6
	if lives > 0:
		_say_bark(avatar_pos, cause_msg + " — Lost 1 Life! (" + str(lives) + "/" + str(max_lives) + " Lives Left)", col, 2.8)
	else:
		audio.play("portal", 0.05, -2.0)
		_say_bark(avatar_pos, "YOU DIED! 0/3 Lives — Generating a New Procedural Realm...", Color(1.0, 0.25, 0.25), 3.2)

func _update_avatar(delta: float) -> void:
	if avatar_dead:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			if lives > 0:
				avatar_dead = false
				avatar_pos = last_safe_pos + Vector3(0, 0, 0.2)
				avatar_vel = Vector3.ZERO
				hp = max_hp
				_say_bark(avatar_pos, "Respawned (" + str(lives) + "/" + str(max_lives) + " Lives). Red Potions restore lost lives!", Color(0.95, 0.85, 0.45), 3.0)
			else:
				# All 3 lives lost -> Restart on a brand-new procedurally generated Level 1!
				_start_new_run()
				_say_bark(avatar_pos, "Reborn in a newly generated Pagan Sanctum! (Level 1 — 3/3 Lives)", Color(0.98, 0.82, 0.35), 3.6)
		return

	# Auto-pickup ground drops
	for i in range(ground_items.size() - 1, -1, -1):
		var drop: Dictionary = ground_items[i]
		if Vector2(avatar_pos.x, avatar_pos.y).distance_to(Vector2(drop["pos"].x, drop["pos"].y)) < 0.85:
			var item_id: String = drop["item"]
			inventory.append(item_id)
			audio.play("pickup")
			var item_name: String = ITEM_INFO.get(item_id, {}).get("name", item_id)
			_say_bark(avatar_pos, "Found " + item_name + "!", Color(0.45, 0.98, 0.55), 2.4)
			ground_items.remove_at(i)

	# Gather movement input (WASD + Ultima VIII Right-Click-Hold toward cursor)
	var screen_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		screen_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		screen_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		screen_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		screen_dir.x += 1.0

	var move_world_dir := Vector2.ZERO
	var speed_mult := 1.0

	if screen_dir.length_squared() > 0.01:
		screen_dir = screen_dir.normalized()
		move_world_dir = Vector2(
			screen_dir.x / IsoMath.HALF_W + screen_dir.y / IsoMath.HALF_H,
			screen_dir.y / IsoMath.HALF_H - screen_dir.x / IsoMath.HALF_W
		).normalized()
	elif right_click_held:
		var mpos := get_viewport().get_mouse_position() - camera_offset
		var av_sp := IsoMath.world_to_screen(avatar_pos.x, avatar_pos.y, avatar_pos.z)
		var diff := mpos - av_sp
		if diff.length() > 10.0:
			speed_mult = clampf(diff.length() / 75.0, 0.55, 1.15)
			var w_dir := Vector2(
				diff.x / IsoMath.HALF_W + diff.y / IsoMath.HALF_H,
				diff.y / IsoMath.HALF_H - diff.x / IsoMath.HALF_W
			)
			move_world_dir = w_dir.normalized()

	var move_speed := 3.6 * speed_mult
	if avatar_grounded:
		if move_world_dir.length_squared() > 0.01:
			avatar_moving = true
			avatar_facing = IsoMath.dir_to_octant(move_world_dir)
			avatar_anim_t += delta * speed_mult
			avatar_vel.x = move_world_dir.x * move_speed
			avatar_vel.y = move_world_dir.y * move_speed
			step_sfx_timer -= delta
			if step_sfx_timer <= 0.0:
				step_sfx_timer = 0.28 / speed_mult
				audio.play("step", 0.12, -12.0)
		else:
			avatar_moving = false
			avatar_vel.x = move_toward(avatar_vel.x, 0.0, 18.0 * delta)
			avatar_vel.y = move_toward(avatar_vel.y, 0.0, 18.0 * delta)
	else:
		# Air control while jumping across pillars
		avatar_moving = true
		avatar_anim_t += delta * 0.7
		if move_world_dir.length_squared() > 0.01:
			avatar_facing = IsoMath.dir_to_octant(move_world_dir)
			avatar_vel.x = lerpf(avatar_vel.x, move_world_dir.x * (move_speed * 1.12), delta * 4.0)
			avatar_vel.y = lerpf(avatar_vel.y, move_world_dir.y * (move_speed * 1.12), delta * 4.0)

	# Horizontal collision resolution (with Ultima VIII Ledge Mantling!)
	var next_x: float = avatar_pos.x + avatar_vel.x * delta
	var next_y: float = avatar_pos.y + avatar_vel.y * delta
	if _can_occupy(next_x, avatar_pos.y, avatar_pos.z):
		avatar_pos.x = next_x
	elif not avatar_grounded and _can_occupy(next_x, avatar_pos.y, avatar_pos.z + 0.55):
		avatar_pos.x = next_x
		avatar_pos.z = get_floor_z_at(avatar_pos.x, avatar_pos.y)
		avatar_vel.z = 0.0
		avatar_grounded = true
		audio.play("step", 0.08, -6.0)
	if _can_occupy(avatar_pos.x, next_y, avatar_pos.z):
		avatar_pos.y = next_y
	elif not avatar_grounded and _can_occupy(avatar_pos.x, next_y, avatar_pos.z + 0.55):
		avatar_pos.y = next_y
		avatar_pos.z = get_floor_z_at(avatar_pos.x, avatar_pos.y)
		avatar_vel.z = 0.0
		avatar_grounded = true
		audio.play("step", 0.08, -6.0)

	# Vertical Z physics (Gravity & Step-ups)
	var floor_z := get_floor_z_at(avatar_pos.x, avatar_pos.y)
	if avatar_grounded:
		if floor_z <= 0.05:
			avatar_grounded = false
		elif absf(floor_z - avatar_pos.z) <= 0.55:
			avatar_pos.z = lerpf(avatar_pos.z, floor_z, minf(1.0, delta * 18.0))
			_check_tile_underfoot()
		elif floor_z < avatar_pos.z - 0.55:
			avatar_grounded = false
	else:
		avatar_vel.z -= 11.5 * delta
		avatar_pos.z += avatar_vel.z * delta
		if avatar_pos.z <= floor_z and avatar_vel.z <= 0.0:
			avatar_pos.z = floor_z
			avatar_vel.z = 0.0
			avatar_grounded = true
			audio.play("land", 0.08, -7.0)
			_check_tile_underfoot()

	# Check if Avatar fell into Water or Lava
	if avatar_pos.z <= 0.10 and get_floor_z_at(avatar_pos.x, avatar_pos.y) <= 0.05:
		var t_type := _get_tile_type_at(avatar_pos.x, avatar_pos.y)
		if t_type == LevelData.TileType.LAVA:
			audio.play("firebolt", 0.1, -3.0)
			_spawn_burst(avatar_pos, Color(1.0, 0.45, 0.1), 18)
			_trigger_avatar_death("Burned in Pyros Lava", Color(1.0, 0.35, 0.15))
		else:
			audio.play("splash", 0.08, -3.0)
			_spawn_burst(avatar_pos, Color(0.25, 0.55, 0.95), 18)
			_trigger_avatar_death("Claimed by the Lurker's Depths", Color(0.45, 0.75, 1.0))

func _check_tile_underfoot() -> void:
	var tx := int(floor(avatar_pos.x))
	var ty := int(floor(avatar_pos.y))
	if tx < 0 or tx >= LevelData.MAP_W or ty < 0 or ty >= LevelData.MAP_H:
		return
	var t: Dictionary = tiles[tx][ty]
	if t["type"] == LevelData.TileType.CRUMBLING_STONE and not t["crumbled"]:
		if t["crumble_timer"] <= 0.0:
			t["crumble_timer"] = 0.01
			_say_bark(avatar_pos, "The stone gives way!", Color(0.95, 0.65, 0.35), 1.4)
	elif t["z"] >= 0.8 and t["type"] != LevelData.TileType.CRUMBLING_STONE:
		last_safe_pos = Vector3(tx + 0.5, ty + 0.5, t["z"])

func _try_jump(toward_cursor: bool) -> void:
	if avatar_dead or not avatar_grounded or game_won:
		return
	avatar_grounded = false
	avatar_vel.z = 5.4
	var jump_dir := Vector2(avatar_vel.x, avatar_vel.y)
	if toward_cursor or jump_dir.length_squared() < 0.1:
		var mpos := get_viewport().get_mouse_position() - camera_offset
		var av_sp := IsoMath.world_to_screen(avatar_pos.x, avatar_pos.y, avatar_pos.z)
		var diff := mpos - av_sp
		var w_dir := Vector2(
			diff.x / IsoMath.HALF_W + diff.y / IsoMath.HALF_H,
			diff.y / IsoMath.HALF_H - diff.x / IsoMath.HALF_W
		).normalized()
		avatar_facing = IsoMath.dir_to_octant(w_dir)
		avatar_vel.x = w_dir.x * 4.3
		avatar_vel.y = w_dir.y * 4.3
	else:
		var nd := jump_dir.normalized()
		avatar_vel.x = nd.x * 4.3
		avatar_vel.y = nd.y * 4.3
	audio.play("jump")

func _can_occupy(wx: float, wy: float, wz: float) -> bool:
	if wx < 0.4 or wx >= LevelData.MAP_W - 0.4 or wy < 0.4 or wy >= LevelData.MAP_H - 0.4:
		return false
	var fz := get_floor_z_at(wx, wy)
	if fz > wz + 0.60:
		return false
	for prop in props:
		if not prop.get("blocking", false):
			continue
		if prop["type"] == "gate" and prop.get("opened", false):
			continue
		var pp: Vector3 = prop["pos"]
		var rad: float = 0.55 if prop["type"] == "gate" else 0.42
		if Vector2(wx, wy).distance_to(Vector2(pp.x, pp.y)) < rad:
			return false
	return true

func get_floor_z_at(wx: float, wy: float) -> float:
	var tx := int(floor(wx))
	var ty := int(floor(wy))
	if tx < 0 or tx >= LevelData.MAP_W or ty < 0 or ty >= LevelData.MAP_H:
		return 0.0
	var t: Dictionary = tiles[tx][ty]
	if t["type"] == LevelData.TileType.CRUMBLING_STONE and t["crumbled"]:
		return 0.0
	return float(t["z"])

func _get_tile_type_at(wx: float, wy: float) -> int:
	var tx := int(floor(wx))
	var ty := int(floor(wy))
	if tx < 0 or tx >= LevelData.MAP_W or ty < 0 or ty >= LevelData.MAP_H:
		return LevelData.TileType.WATER
	var t: Dictionary = tiles[tx][ty]
	if t["type"] == LevelData.TileType.CRUMBLING_STONE and t["crumbled"]:
		return LevelData.TileType.WATER
	return int(t["type"])

func _handle_world_left_click() -> void:
	if avatar_dead:
		return
	if hovered_enemy != null:
		var dist := Vector2(avatar_pos.x, avatar_pos.y).distance_to(Vector2(hovered_enemy["pos"].x, hovered_enemy["pos"].y))
		if dist <= 1.95:
			_perform_melee_attack(hovered_enemy)
			return
		elif has_item("ignis_scroll") and mana >= 10:
			_try_cast_firebolt()
			return

	if hovered_prop != null:
		_interact_with_prop(hovered_prop)
		return

	if combat_mode:
		_perform_melee_attack(null)

func _interact_nearest() -> void:
	var best_p: Dictionary = {}
	var best_d: float = 2.2
	for prop in props:
		var pr: Dictionary = prop
		var d: float = Vector2(avatar_pos.x, avatar_pos.y).distance_to(Vector2(pr["pos"].x, pr["pos"].y))
		if d < best_d:
			best_d = d
			best_p = pr
	if not best_p.is_empty():
		_interact_with_prop(best_p)

func _interact_with_prop(prop: Dictionary) -> void:
	var dist := Vector2(avatar_pos.x, avatar_pos.y).distance_to(Vector2(prop["pos"].x, prop["pos"].y))
	if dist > 2.35:
		var desc: String = prop.get("desc", prop.get("name", "Something ancient."))
		_say_bark(prop["pos"], desc, Color(0.82, 0.80, 0.88), 2.8)
		return

	var p_type: String = prop["type"]
	match p_type:
		"corpse":
			if not prop["looted"]:
				prop["looted"] = true
				inventory.append("iron_key")
				audio.play("pickup")
				_say_bark(prop["pos"], "Found a Rusty Iron Key on the slain guard!", Color(0.98, 0.88, 0.35), 3.0)
			else:
				_say_bark(prop["pos"], prop["desc"], Color(0.78, 0.76, 0.82), 2.2)

		"chest", "sarcophagus":
			if not prop["opened"]:
				prop["opened"] = true
				audio.play("pickup")
				var loot_list: Array = prop.get("loot", [])
				var names: Array[String] = []
				for item_id in loot_list:
					inventory.append(item_id)
					names.append(ITEM_INFO.get(item_id, {}).get("name", item_id))
				_say_bark(prop["pos"], "Opened: " + ", ".join(names) + "!", Color(0.45, 0.98, 0.55), 3.5)
				if loot_list.has("flame_blade"):
					combat_mode = true
			else:
				_say_bark(prop["pos"], "It is empty.", Color(0.75, 0.75, 0.78), 1.8)

		"plaque", "skulls", "tree", "bush":
			_say_bark(prop["pos"], String(prop.get("desc", "Ancient Pagan scenery.")), Color(0.95, 0.82, 0.48), 3.2)

		"table":
			if not bool(prop.get("used", false)):
				prop["used"] = true
				hp = mini(max_hp, hp + 20)
				audio.play("potion")
				_say_bark(prop["pos"], "Ate Tenebrae cheese & wine (+20 HP)!", Color(0.55, 0.96, 0.58), 2.8)
			else:
				_say_bark(prop["pos"], String(prop.get("desc", "A wooden table.")), Color(0.82, 0.78, 0.72), 2.2)

		"gate":
			if prop["opened"]:
				_say_bark(prop["pos"], "The portcullis is raised.", Color(0.8, 0.8, 0.85), 1.8)
			elif has_item("iron_key"):
				prop["opened"] = true
				prop["blocking"] = false
				audio.play("lever")
				_say_bark(prop["pos"], "Unlocked the Iron Portcullis!", Color(0.55, 0.95, 0.55), 2.6)
			else:
				audio.play("hit", 0.05, -10.0)
				_say_bark(prop["pos"], "Locked. I need the guard's Iron Key.", Color(0.95, 0.45, 0.40), 2.5)

		"lever":
			if not prop["activated"]:
				prop["activated"] = true
				bridge_raised = true
				screen_shake = 0.8
				audio.play("lever")
				_say_bark(prop["pos"], "The Sunken Bridge rises from the abyss!", Color(0.98, 0.85, 0.35), 3.6)
			else:
				_say_bark(prop["pos"], "The bridge mechanism is locked in place.", Color(0.8, 0.8, 0.85), 2.0)

		"brazier":
			if prop.get("ritual", false) and not prop.get("lit", false):
				prop["lit"] = true
				audio.play("firebolt", 0.08, -5.0)
				_spawn_burst(prop["pos"] + Vector3(0, 0, 0.5), Color(1.0, 0.5, 0.1), 16)
				var lit_c := get_lit_ritual_pyres_count()
				_say_bark(prop["pos"], "Ritual Pyre ignited! (" + str(lit_c) + "/3)", Color(1.0, 0.65, 0.22), 2.6)
				_check_sanctum_ritual()
			else:
				_say_bark(prop["pos"], "The brazier burns with dark Pagan flame.", Color(0.95, 0.65, 0.32), 2.0)

		"pentagram_focus":
			if prop["activated"]:
				_say_bark(prop["pos"], "The Heart of the Pentagram pulses with blood magic.", Color(0.95, 0.35, 0.35), 2.4)
			elif has_item("ritual_candle"):
				remove_one_item("ritual_candle")
				prop["activated"] = true
				audio.play("portal", 0.05, -5.0)
				_spawn_burst(prop["pos"], Color(0.95, 0.18, 0.22), 22)
				_say_bark(prop["pos"], "Placed the Blood Ritual Candle upon the Pentagram!", Color(1.0, 0.40, 0.35), 3.0)
				_check_sanctum_ritual()
			else:
				_say_bark(prop["pos"], "The Pentagram requires a Blood Ritual Candle and 3 lit Pyres.", Color(0.95, 0.45, 0.45), 3.0)

		"obelisk":
			if prop["activated"]:
				audio.play("portal")
				_spawn_burst(prop["pos"] + Vector3(0, 0, 1.0), Color(0.85, 0.35, 1.0), 35)
				if current_level == 6 or current_level == LevelData.MAX_LEVELS:
					game_won = true
					_say_bark(avatar_pos, "Vas Rel Por! You have conquered the Boss of Sanctum " + str(current_level) + "!", Color(0.95, 0.75, 1.0), 5.0)
				else:
					_advance_to_next_level(current_level + 1)
			else:
				if LevelData.is_boss_level(current_level):
					_say_bark(prop["pos"], "Dormant! Slay the Boss of Sanctum " + str(current_level) + " to awaken the Obelisk!", Color(0.95, 0.45, 0.45), 3.0)
				else:
					_say_bark(prop["pos"], "Dormant. Light the 3 Pyres & place the Blood Candle on the Pentagram!", Color(0.85, 0.55, 0.95), 3.0)

func _check_sanctum_ritual() -> void:
	if obelisk_awakened:
		return
	var lit_c := get_lit_ritual_pyres_count()
	var focus_active := false
	for prop in props:
		if prop["id"] == "pentagram_altar" and prop.get("activated", false):
			focus_active = true
	if lit_c >= 3 and focus_active:
		_awaken_obelisk()

func _awaken_obelisk() -> void:
	if obelisk_awakened:
		return
	obelisk_awakened = true
	screen_shake = 1.0
	audio.play("portal")
	for prop in props:
		if prop["id"] == "blackrock_obelisk":
			prop["activated"] = true
			var opos: Vector3 = prop["pos"]
			_spawn_burst(opos + Vector3(0, 0, 1.0), Color(0.85, 0.25, 1.0), 32)
			_say_bark(opos + Vector3(0, 0, 0.6), "Kal Vas Grav! The Blackrock Obelisk awakens!", Color(0.95, 0.55, 1.0), 4.0)

func _perform_melee_attack(target_enemy) -> void:
	if attack_cd > 0.0:
		return
	attack_cd = 0.36
	attack_anim_timer = 0.25
	audio.play("sword")

	var mpos := get_viewport().get_mouse_position() - camera_offset
	var av_sp := IsoMath.world_to_screen(avatar_pos.x, avatar_pos.y, avatar_pos.z)
	var diff := mpos - av_sp
	var w_dir := Vector2(
		diff.x / IsoMath.HALF_W + diff.y / IsoMath.HALF_H,
		diff.y / IsoMath.HALF_H - diff.x / IsoMath.HALF_W
	).normalized()
	avatar_facing = IsoMath.dir_to_octant(w_dir)

	var dmg := 34 if has_item("flame_blade") else 18
	var hit_any := false
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		var d := Vector2(avatar_pos.x, avatar_pos.y).distance_to(Vector2(enemy["pos"].x, enemy["pos"].y))
		if d <= 2.0 or enemy == target_enemy:
			if d <= 2.15:
				_damage_enemy(enemy, dmg)
				hit_any = true
	if has_item("flame_blade"):
		_spawn_burst(avatar_pos + Vector3(w_dir.x * 0.8, w_dir.y * 0.8, 0.5), Color(1.0, 0.55, 0.12), 8)
	elif hit_any:
		_spawn_burst(avatar_pos + Vector3(w_dir.x * 0.8, w_dir.y * 0.8, 0.5), Color(0.9, 0.9, 0.95), 5)

func _try_cast_firebolt() -> void:
	if avatar_dead or game_won or cast_cd > 0.0:
		return
	if not has_item("ignis_scroll"):
		_say_bark(avatar_pos, "I need an Ignis Scroll to cast Firebolt.", Color(0.95, 0.55, 0.45), 2.0)
		return
	if mana < 10:
		_say_bark(avatar_pos, "Not enough Mana!", Color(0.45, 0.65, 1.0), 1.8)
		return

	mana -= 10
	cast_cd = 0.52
	audio.play("firebolt")
	_say_bark(avatar_pos, "Kal Vas Flam!", Color(1.0, 0.65, 0.20), 1.4)

	var mpos := get_viewport().get_mouse_position() - camera_offset
	var av_sp := IsoMath.world_to_screen(avatar_pos.x, avatar_pos.y, avatar_pos.z + 0.5)
	var diff := mpos - av_sp
	var w_dir := Vector2(
		diff.x / IsoMath.HALF_W + diff.y / IsoMath.HALF_H,
		diff.y / IsoMath.HALF_H - diff.x / IsoMath.HALF_W
	).normalized()
	avatar_facing = IsoMath.dir_to_octant(w_dir)

	projectiles.append({
		"pos": avatar_pos + Vector3(w_dir.x * 0.5, w_dir.y * 0.5, 0.55),
		"vel": Vector3(w_dir.x * 7.6, w_dir.y * 7.6, 0.0),
		"from_player": true,
		"damage": 40,
		"life": 1.8,
		"color": Color(1.0, 0.42, 0.08)
	})

func _damage_enemy(enemy: Dictionary, dmg: int) -> void:
	enemy["hp"] -= dmg
	enemy["hit_flash"] = 0.18
	audio.play("hit")
	if has_item("grimoire") and hp < max_hp:
		hp = mini(max_hp, hp + 8)
	_spawn_burst(enemy["pos"] + Vector3(0, 0, 0.5), Color(0.95, 0.25, 0.15), 10)
	if enemy["hp"] <= 0:
		var ep: Vector3 = enemy["pos"]
		var e_type: String = String(enemy["type"])
		audio.play_enemy_death(e_type)
		_say_bark(ep, String(enemy["name"]) + " vanquished!", Color(0.98, 0.82, 0.35), 2.5)
		_spawn_burst(ep + Vector3(0, 0, 0.4), Color(0.95, 0.45, 0.15), 24)
		if bool(enemy.get("final_boss", false)):
			# Final / Tier Boss defeated! Awaken the Obelisk directly and drop rich rewards!
			ground_items.append({"item": "red_potion", "pos": ep + Vector3(-0.3, 0.2, 0.0)})
			ground_items.append({"item": "ritual_candle", "pos": ep + Vector3(0.3, -0.2, 0.0)})
			for prop in props:
				if prop["id"] == "pentagram_altar":
					prop["activated"] = true
				elif prop["type"] == "brazier" and prop.get("ritual", false):
					prop["lit"] = true
			_awaken_obelisk()
			_say_bark(ep, "THE BOSS IS SLAIN! Enter the awakened Blackrock Obelisk!", Color(1.0, 0.88, 0.32), 4.5)
		elif bool(enemy.get("boss", false)):
			ground_items.append({
				"item": "ritual_candle",
				"pos": ep
			})
			_say_bark(ep, "The Executioner Wraith dropped a Blood Ritual Candle!", Color(1.0, 0.45, 0.45), 3.5)
		else:
			ground_items.append({
				"item": "red_potion",
				"pos": ep
			})

func _use_inventory_item(item_id: String) -> void:
	if avatar_dead:
		return
	if item_id == "red_potion":
		if hp >= max_hp and lives >= max_lives:
			_say_bark(avatar_pos, "Already at full HP and 3/3 Lives.", Color(0.85, 0.85, 0.85), 1.8)
			return
		if remove_one_item("red_potion"):
			var prev_lives: int = lives
			hp = mini(max_hp, hp + 50)
			lives = mini(max_lives, lives + 1)
			audio.play("potion")
			_spawn_burst(avatar_pos + Vector3(0, 0, 0.5), Color(0.95, 0.2, 0.2), 14)
			if lives > prev_lives:
				_say_bark(avatar_pos, "Red Potion: +50 HP & +1 LIFE RESTORED (" + str(lives) + "/" + str(max_lives) + " Lives)!", Color(0.98, 0.45, 0.45), 2.8)
			else:
				_say_bark(avatar_pos, "Quaffed Red Healing Potion (+50 HP, Lives: " + str(lives) + "/" + str(max_lives) + ").", Color(0.98, 0.45, 0.45), 2.2)
	elif item_id == "blue_potion":
		if mana >= max_mana:
			_say_bark(avatar_pos, "Mana is already full.", Color(0.85, 0.85, 0.85), 1.6)
			return
		if remove_one_item("blue_potion"):
			mana = mini(max_mana, mana + 40)
			audio.play("potion")
			_spawn_burst(avatar_pos + Vector3(0, 0, 0.5), Color(0.25, 0.55, 1.0), 12)
			_say_bark(avatar_pos, "Quaffed Blue Mana Potion (+40 Mana).", Color(0.45, 0.75, 1.0), 2.0)

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		enemy["anim_t"] += delta
		enemy["hit_flash"] = maxf(0.0, enemy["hit_flash"] - delta)
		enemy["attack_cd"] = maxf(0.0, enemy["attack_cd"] - delta)

		var ep: Vector3 = enemy["pos"]
		var dist_2d := Vector2(ep.x, ep.y).distance_to(Vector2(avatar_pos.x, avatar_pos.y))
		var z_diff := absf(ep.z - avatar_pos.z)
		var detect_range: float = 8.5 if bool(enemy.get("final_boss", false)) else 5.5

		if not avatar_dead and dist_2d < detect_range and z_diff < 1.3:
			var dir: Vector2 = (Vector2(avatar_pos.x, avatar_pos.y) - Vector2(ep.x, ep.y)).normalized()
			if dist_2d > 1.15:
				var spd: float = float(enemy["speed"])
				var nx: float = ep.x + dir.x * spd * delta
				var ny: float = ep.y + dir.y * spd * delta
				if get_floor_z_at(nx, ny) >= 0.8 and _can_occupy(nx, ny, ep.z):
					ep.x = nx
					ep.y = ny
					ep.z = get_floor_z_at(nx, ny)
					enemy["pos"] = ep
			elif enemy["attack_cd"] <= 0.0:
				enemy["attack_cd"] = 1.20
				hp = maxi(0, hp - int(enemy["damage"]))
				audio.play("hit", 0.1, -4.0)
				_spawn_burst(avatar_pos + Vector3(0, 0, 0.5), Color(0.9, 0.1, 0.1), 8)
				if hp <= 0:
					_trigger_avatar_death("Struck down by " + String(enemy["name"]), Color(1.0, 0.3, 0.3))

			# Boss ranged sorcery barrage
			if enemy.get("boss", false):
				enemy["cast_cd"] = float(enemy.get("cast_cd", 2.5)) - delta
				if float(enemy["cast_cd"]) <= 0.0 and dist_2d > 1.6:
					var is_final: bool = bool(enemy.get("final_boss", false))
					enemy["cast_cd"] = 2.2 if is_final else 2.8
					audio.play("firebolt", 0.15, -6.0)
					_say_bark(ep, "Kal Vas Corp!" if is_final else "Corp Por!", Color(0.98, 0.35, 0.45), 1.5)
					var angles: Array[float] = [-0.24, 0.0, 0.24] if is_final else [0.0]
					for ang in angles:
						var s_dir: Vector2 = dir.rotated(ang)
						projectiles.append({
							"pos": ep + Vector3(s_dir.x * 0.45, s_dir.y * 0.45, 0.55),
							"vel": Vector3(s_dir.x * 5.4, s_dir.y * 5.4, 0.0),
							"from_player": false,
							"damage": 18 if is_final else 15,
							"life": 1.9,
							"color": Color(0.95, 0.22, 0.18) if is_final else Color(0.85, 0.15, 0.65)
						})

func _update_projectiles_and_particles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var proj: Dictionary = projectiles[i]
		proj["life"] -= delta
		proj["pos"] += proj["vel"] * delta
		var p: Vector3 = proj["pos"]

		particles.append({
			"pos": p,
			"vel": Vector3(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4), randf_range(0.2, 0.8)),
			"life": 0.22,
			"max_life": 0.22,
			"size": 4.0,
			"color": proj["color"]
		})

		var hit := false
		if proj["from_player"]:
			for enemy in enemies:
				if enemy["hp"] <= 0:
					continue
				if Vector2(p.x, p.y).distance_to(Vector2(enemy["pos"].x, enemy["pos"].y)) < 0.80:
					_damage_enemy(enemy, int(proj["damage"]))
					hit = true
					break
			if not hit:
				for prop in props:
					if prop["type"] == "brazier" and prop.get("ritual", false) and not prop.get("lit", false):
						if Vector2(p.x, p.y).distance_to(Vector2(prop["pos"].x, prop["pos"].y)) < 0.85:
							prop["lit"] = true
							audio.play("firebolt", 0.05, -4.0)
							_spawn_burst(prop["pos"] + Vector3(0, 0, 0.5), Color(1.0, 0.55, 0.1), 16)
							var lit_c := get_lit_ritual_pyres_count()
							_say_bark(prop["pos"], "Ritual Pyre ignited! (" + str(lit_c) + "/3)", Color(1.0, 0.65, 0.22), 2.5)
							_check_sanctum_ritual()
							hit = true
							break
		else:
			if not avatar_dead and Vector2(p.x, p.y).distance_to(Vector2(avatar_pos.x, avatar_pos.y)) < 0.65:
				hp = maxi(0, hp - int(proj["damage"]))
				audio.play("hit")
				_spawn_burst(avatar_pos + Vector3(0, 0, 0.5), Color(0.9, 0.2, 0.7), 10)
				if hp <= 0:
					_trigger_avatar_death("Felled by Dark Sorcery", Color(1.0, 0.3, 0.4))
				hit = true

		if hit or proj["life"] <= 0.0:
			projectiles.remove_at(i)

	for i in range(particles.size() - 1, -1, -1):
		var part: Dictionary = particles[i]
		part["life"] -= delta
		part["pos"] += part["vel"] * delta
		if part["life"] <= 0.0:
			particles.remove_at(i)

func _spawn_burst(pos: Vector3, col: Color, count: int) -> void:
	for i in range(count):
		particles.append({
			"pos": pos,
			"vel": Vector3(randf_range(-2.2, 2.2), randf_range(-2.2, 2.2), randf_range(0.8, 3.2)),
			"life": randf_range(0.25, 0.55),
			"max_life": 0.55,
			"size": randf_range(3.0, 6.0),
			"color": col
		})

func _say_bark(pos: Vector3, text: String, col: Color, duration: float = 2.5) -> void:
	barks.append({
		"pos": pos,
		"text": text,
		"color": col,
		"timer": duration,
		"rise": 0.0
	})

func _handle_hud_click(screen_pos: Vector2) -> bool:
	var vp := get_viewport_rect().size
	var inv_rect := Rect2(18, vp.y - 122, 450, 104)
	if inv_rect.has_point(screen_pos):
		var unique_items: Array[String] = ["iron_key", "red_potion", "blue_potion", "flame_blade", "ignis_scroll", "ritual_candle", "grimoire"]
		var slot_x := 28.0
		for item_id in unique_items:
			if count_item(item_id) > 0:
				var s_rect := Rect2(slot_x, vp.y - 78, 48, 48)
				if s_rect.has_point(screen_pos):
					if item_id == "red_potion" or item_id == "blue_potion":
						_use_inventory_item(item_id)
					else:
						var desc: String = ITEM_INFO[item_id]["desc"]
						_say_bark(avatar_pos, ITEM_INFO[item_id]["name"] + ": " + desc, Color(0.95, 0.85, 0.45), 2.4)
					return true
				slot_x += 56.0
		return true

	var menu_btn := Rect2(vp.x - 362, vp.y - 68, 104, 48)
	if menu_btn.has_point(screen_pos):
		in_start_menu = true
		show_credits = false
		right_click_held = false
		audio.play("step", 0.05, -5.0)
		audio.play_track("title")
		return true

	var combat_btn := Rect2(vp.x - 250, vp.y - 68, 112, 48)
	if combat_btn.has_point(screen_pos):
		combat_mode = not combat_mode
		audio.play("sword", 0.1, -8.0)
		audio.set_combat_music(combat_mode or LevelData.is_boss_level(current_level))
		return true

	var spell_btn := Rect2(vp.x - 130, vp.y - 68, 112, 48)
	if spell_btn.has_point(screen_pos):
		_try_cast_firebolt()
		return true

	return false

func _draw_heart_icon(center: Vector2, filled: bool) -> void:
	var c_fill := Color(0.94, 0.16, 0.20) if filled else Color(0.22, 0.12, 0.16)
	var c_rim := Color(1.0, 0.72, 0.32) if filled else Color(0.48, 0.34, 0.36)
	draw_circle(center + Vector2(-3.2, -2.0), 4.2, c_fill)
	draw_circle(center + Vector2(3.2, -2.0), 4.2, c_fill)
	var tri := PackedVector2Array([
		center + Vector2(-7.2, -0.5),
		center + Vector2(7.2, -0.5),
		center + Vector2(0.0, 7.5)
	])
	draw_colored_polygon(tri, c_fill)
	draw_arc(center, 7.6, 0.0, TAU, 18, c_rim, 1.1)

func _draw() -> void:
	var vp := get_viewport_rect().size
	var font := ThemeDB.fallback_font

	if in_start_menu:
		_draw_start_menu(vp, font)
		return

	# 1. Top Title, Procedural Level Counter & Quest Objective Banner
	var top_rect := Rect2(vp.x * 0.5 - 295, 12, 590, 58)
	draw_rect(top_rect, Color(0.07, 0.05, 0.10, 0.90))
	var is_boss_lvl: bool = LevelData.is_boss_level(current_level)
	var top_border_col := Color(0.95, 0.28, 0.20, 0.95) if is_boss_lvl else Color(0.55, 0.38, 0.22, 0.9)
	draw_rect(top_rect, top_border_col, false, 2.0)

	var header_txt: String = "LEVEL " + str(current_level) + " / " + str(LevelData.MAX_LEVELS) + "  —  " + level_title.to_upper()
	draw_string(font, Vector2(top_rect.position.x + 16, 33), header_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.98, 0.76, 0.32) if not is_boss_lvl else Color(1.0, 0.42, 0.32))

	var quest_str := _get_current_quest_text()
	draw_string(font, Vector2(top_rect.position.x + 16, 55), "Objective: " + quest_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.84, 0.80, 0.88))

	# 1b. Boss Health Bar (on Level 6, Level 666, or any Boss Sanctum while Final Boss lives)
	var active_boss: Dictionary = _get_active_final_boss()
	if not active_boss.is_empty():
		var b_rect := Rect2(vp.x * 0.5 - 240, 76, 480, 32)
		draw_rect(b_rect, Color(0.10, 0.03, 0.05, 0.92))
		draw_rect(b_rect, Color(0.92, 0.24, 0.18), false, 2.0)
		var b_ratio: float = clampf(float(active_boss["hp"]) / float(active_boss["max_hp"]), 0.0, 1.0)
		draw_rect(Rect2(b_rect.position.x + 4, b_rect.position.y + 4, (b_rect.size.x - 8.0) * b_ratio, b_rect.size.y - 8.0), Color(0.86, 0.14, 0.14))
		var b_txt: String = "☠ " + String(active_boss["name"]).to_upper() + "  (" + str(active_boss["hp"]) + " / " + str(active_boss["max_hp"]) + " HP)"
		var btw: float = font.get_string_size(b_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
		draw_string_outline(font, Vector2(vp.x * 0.5 - btw * 0.5, b_rect.position.y + 21), b_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color.BLACK)
		draw_string(font, Vector2(vp.x * 0.5 - btw * 0.5, b_rect.position.y + 21), b_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.90, 0.48))

	# 2. Avatar Status, 3 Lives & Satchel Gump (Bottom-Left)
	var gump_rect := Rect2(18, vp.y - 122, 464, 104)
	draw_rect(gump_rect, Color(0.08, 0.06, 0.11, 0.90))
	draw_rect(gump_rect, Color(0.52, 0.36, 0.22, 0.92), false, 2.0)

	# HP Bar
	draw_string(font, Vector2(28, vp.y - 98), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.35, 0.35))
	draw_rect(Rect2(52, vp.y - 110, 112, 14), Color(0.18, 0.05, 0.05))
	draw_rect(Rect2(52, vp.y - 110, 112.0 * float(hp) / float(max_hp), 14), Color(0.85, 0.16, 0.16))
	draw_string(font, Vector2(82, vp.y - 98), str(hp) + "/" + str(max_hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# Mana Bar
	draw_string(font, Vector2(174, vp.y - 98), "MP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.70, 1.0))
	draw_rect(Rect2(200, vp.y - 110, 104, 14), Color(0.05, 0.08, 0.20))
	draw_rect(Rect2(200, vp.y - 110, 104.0 * float(mana) / float(max_mana), 14), Color(0.20, 0.48, 0.92))
	draw_string(font, Vector2(232, vp.y - 98), str(mana) + "/" + str(max_mana), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# 3 Lives Indicator (Restored by Red Healing Potions!)
	draw_string(font, Vector2(316, vp.y - 98), "LIVES:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.98, 0.80, 0.36))
	for l_i in range(max_lives):
		_draw_heart_icon(Vector2(374.0 + float(l_i) * 22.0, vp.y - 103.0), l_i < lives)
	draw_string(font, Vector2(440, vp.y - 98), str(lives) + "/" + str(max_lives), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.88, 0.45))

	# Inventory Slots
	var unique_items: Array[String] = ["iron_key", "red_potion", "blue_potion", "flame_blade", "ignis_scroll", "ritual_candle", "grimoire"]
	var slot_x: float = 28.0
	var any_item: bool = false
	for item_id in unique_items:
		var cnt: int = count_item(item_id)
		if cnt > 0:
			any_item = true
			var s_rect := Rect2(slot_x, vp.y - 78, 48, 48)
			draw_rect(s_rect, Color(0.14, 0.11, 0.18))
			var item_col: Color = ITEM_INFO[item_id]["color"]
			draw_rect(s_rect, item_col, false, 1.8)
			var item_tex: ImageTexture = SpriteFactory.get_item_sprite(item_id)
			draw_texture_rect(item_tex, Rect2(slot_x + 6.0, vp.y - 72.0, 36.0, 36.0), false)
			if cnt > 1:
				draw_string(font, Vector2(slot_x + 32, vp.y - 35), "x" + str(cnt), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			slot_x += 56.0
	if not any_item:
		draw_string(font, Vector2(28, vp.y - 50), "Satchel Empty — Left-click corpses & chests to loot", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.58, 0.55, 0.64))

	# 3. Menu, Combat & Sorcery Buttons (Bottom-Right)
	var menu_btn := Rect2(vp.x - 362, vp.y - 68, 104, 48)
	draw_rect(menu_btn, Color(0.10, 0.08, 0.14, 0.90))
	draw_rect(menu_btn, Color(0.55, 0.40, 0.25), false, 2.0)
	draw_string(font, menu_btn.position + Vector2(12, 22), "MENU [ESC]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.96, 0.80, 0.42))
	draw_string(font, menu_btn.position + Vector2(12, 40), "Title / Quit", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.72, 0.82))

	var combat_btn := Rect2(vp.x - 250, vp.y - 68, 112, 48)
	draw_rect(combat_btn, Color(0.32, 0.10, 0.10, 0.92) if combat_mode else Color(0.10, 0.08, 0.14, 0.90))
	draw_rect(combat_btn, Color(0.95, 0.45, 0.25) if combat_mode else Color(0.48, 0.36, 0.25), false, 2.0)
	draw_string(font, combat_btn.position + Vector2(12, 22), "COMBAT [C]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.98, 0.85, 0.55))
	draw_string(font, combat_btn.position + Vector2(12, 40), "ACTIVE" if combat_mode else "SHEATHED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.45, 0.35) if combat_mode else Color(0.65, 0.65, 0.72))

	var spell_btn := Rect2(vp.x - 130, vp.y - 68, 112, 48)
	var has_ignis := has_item("ignis_scroll")
	draw_rect(spell_btn, Color(0.24, 0.12, 0.06, 0.92) if has_ignis else Color(0.08, 0.07, 0.11, 0.85))
	draw_rect(spell_btn, Color(1.0, 0.60, 0.18) if has_ignis else Color(0.32, 0.28, 0.36), false, 2.0)
	draw_string(font, spell_btn.position + Vector2(12, 22), "IGNIS [Q]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.75, 0.30) if has_ignis else Color(0.5, 0.5, 0.55))
	draw_string(font, spell_btn.position + Vector2(12, 40), "Firebolt (10M)" if has_ignis else "Locked", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.60, 0.25) if has_ignis else Color(0.45, 0.45, 0.50))

	# 4. Hover Target Label (Bottom-Center)
	var hover_str: String = ""
	if hovered_enemy != null:
		hover_str = String(hovered_enemy["name"]) + " (" + str(hovered_enemy["hp"]) + "/" + str(hovered_enemy["max_hp"]) + " HP) — Left-Click to Attack"
	elif hovered_prop != null:
		hover_str = String(hovered_prop.get("name", "Object")) + " — Left-Click to Use / Examine"
	if hover_str != "":
		var tw := font.get_string_size(hover_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
		draw_string_outline(font, Vector2((vp.x - tw) * 0.5, vp.y - 24), hover_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
		draw_string(font, Vector2((vp.x - tw) * 0.5, vp.y - 24), hover_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.98, 0.88, 0.48))

	# 5. Controls Guide Box (Top-Right, toggle with H)
	if show_help:
		var h_rect := Rect2(vp.x - 296, 12, 282, 226)
		draw_rect(h_rect, Color(0.06, 0.05, 0.09, 0.86))
		draw_rect(h_rect, Color(0.46, 0.34, 0.22, 0.85), false, 1.5)
		var lines: Array[String] = [
			"PAGAN CONTROLS [H to Hide]:",
			"• Hold Right-Click or WASD: Move",
			"• Space / Double R-Click: Jump",
			"• Left-Click: Interact / Attack",
			"• [C] or [Tab]: Toggle Combat",
			"• [Q] or [F]: Cast Ignis Firebolt",
			"• [1] Red Potion (+HP & +1 Life!)",
			"• [2] Mana  [I] Avatar  [M] Map",
			"• [N] Next Lvl  [B] Warp Boss (6/666)",
			"• [R] New Run   [Esc] Title Menu"
		]
		for i in range(lines.size()):
			var col := Color(0.95, 0.76, 0.32) if i == 0 else Color(0.82, 0.79, 0.86)
			draw_string(font, h_rect.position + Vector2(12, 22 + i * 20), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

	# 5b. Sanctum Minimap Gump (Top-Left, toggle with M)
	if show_minimap and minimap_tex != null:
		var mm_rect := Rect2(18, 12, 168, 188)
		draw_rect(mm_rect, Color(0.06, 0.05, 0.09, 0.88))
		draw_rect(mm_rect, Color(0.48, 0.35, 0.22, 0.88), false, 1.5)
		draw_string(font, Vector2(26, 28), "LVL " + str(current_level) + " MAP (72x72) [M]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.74, 0.32))
		var map_px: float = 144.0
		var cell_s: float = map_px / float(LevelData.MAP_W)
		var ox: float = 30.0
		var oy: float = 36.0
		draw_texture_rect(minimap_tex, Rect2(ox, oy, map_px, map_px), false)
		for prop in props:
			var pid: String = String(prop.get("id", ""))
			var pp: Vector3 = prop["pos"]
			if pid == "lever_bridge":
				draw_circle(Vector2(ox + pp.x * cell_s, oy + pp.y * cell_s), 2.8, Color(0.35, 0.92, 1.0))
			elif pid == "blackrock_obelisk":
				draw_circle(Vector2(ox + pp.x * cell_s, oy + pp.y * cell_s), 3.2, Color(0.88, 0.35, 1.0))
			elif pid == "gate_portcullis" and not bool(prop.get("opened", false)):
				draw_circle(Vector2(ox + pp.x * cell_s, oy + pp.y * cell_s), 2.8, Color(0.96, 0.68, 0.24))
		for enemy in enemies:
			if int(enemy["hp"]) > 0:
				var ep: Vector3 = enemy["pos"]
				var ec := Color(1.0, 0.55, 0.1) if bool(enemy.get("final_boss", false)) else Color(1.0, 0.2, 0.2)
				draw_circle(Vector2(ox + ep.x * cell_s, oy + ep.y * cell_s), 3.2 if bool(enemy.get("final_boss", false)) else 2.2, ec)
		draw_circle(Vector2(ox + avatar_pos.x * cell_s, oy + avatar_pos.y * cell_s), 3.4, Color(1.0, 0.92, 0.25))

	# 5c. Ultima VIII Avatar Paperdoll Gump (Center-Left, toggle with I or P)
	if show_paperdoll:
		var pd_rect := Rect2(180, vp.y * 0.5 - 130, 268, 250)
		draw_rect(pd_rect, Color(0.07, 0.05, 0.11, 0.94))
		draw_rect(pd_rect, Color(0.72, 0.52, 0.24, 0.95), false, 2.0)
		draw_string(font, pd_rect.position + Vector2(16, 26), "THE AVATAR OF PAGAN [I]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.96, 0.78, 0.34))
		var pd_tex: ImageTexture = SpriteFactory.get_avatar_sprite(2, 0, false, false, has_item("flame_blade"), false, true)
		draw_texture_rect(pd_tex, Rect2(pd_rect.position.x + 12, pd_rect.position.y + 42, 112, 130), false)
		var stats: Array[String] = [
			"Level: " + str(current_level) + " / " + str(LevelData.MAX_LEVELS),
			"Lives: " + str(lives) + " / " + str(max_lives) + " (Potions +1)",
			"Helm: Steel Chain Coif",
			"Armor: Crimson & Gold Tabard",
			"Boots: Polished Steel Greaves",
			"Weapon: " + ("Flame Sting" if has_item("flame_blade") else "Steel Blade")
		]
		for s_i in range(stats.size()):
			draw_string(font, pd_rect.position + Vector2(122, 62 + s_i * 24), stats[s_i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.86, 0.82, 0.90))

	# 6. Victory Modal Banner (Triggered upon defeating the Level 6 Boss or completing Level 666!)
	if game_won:
		var win_rect := Rect2(vp.x * 0.5 - 270, vp.y * 0.5 - 105, 540, 210)
		draw_rect(win_rect, Color(0.06, 0.04, 0.10, 0.96))
		draw_rect(win_rect, Color(0.88, 0.62, 0.24), false, 3.0)
		var win_title: String = "ULTIMATE VICTORY — SANCTUM 666 CONQUERED!" if current_level >= LevelData.MAX_LEVELS else "VICTORY — LEVEL " + str(current_level) + " BOSS VANQUISHED!"
		draw_string(font, win_rect.position + Vector2(42, 44), win_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.98, 0.82, 0.32))
		draw_string(font, win_rect.position + Vector2(36, 82), "You have braved the procedurally generated realms of Pagan,", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.88, 0.84, 0.92))
		draw_string(font, win_rect.position + Vector2(36, 106), "overcome the Arch-Executioner, and awakened the Blackrock Obelisk!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.88, 0.84, 0.92))
		draw_string(font, win_rect.position + Vector2(36, 132), "Remaining Lives: " + str(lives) + " / " + str(max_lives) + "   •   Sanctum Seed: #" + str(absi(level_seed) % 100000), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.68, 0.42))
		if current_level < LevelData.MAX_LEVELS:
			draw_string(font, win_rect.position + Vector2(46, 168), "[ Left-Click / Enter: Continue to Level " + str(current_level + 1) + " of 666 ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.96, 0.62))
			draw_string(font, win_rect.position + Vector2(126, 192), "[ Press R: Restart New Procedural Run ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.72, 0.35))
		else:
			draw_string(font, win_rect.position + Vector2(105, 176), "[ Left-Click or Press R to Start a New Run ]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.72, 0.35))

func _draw_start_menu(vp: Vector2, font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.03, 0.02, 0.05, 0.76))

	var panel_w: float = 680.0
	var panel_h: float = 520.0
	var panel_rect := Rect2(vp.x * 0.5 - panel_w * 0.5, vp.y * 0.5 - panel_h * 0.5, panel_w, panel_h)
	draw_rect(panel_rect, Color(0.06, 0.04, 0.09, 0.94))
	draw_rect(panel_rect, Color(0.68, 0.22, 0.16, 0.95), false, 3.0)
	draw_rect(panel_rect.grow(-6.0), Color(0.82, 0.62, 0.26, 0.85), false, 1.5)

	var pent_center := Vector2(vp.x * 0.5, panel_rect.position.y + 88.0)
	var pulse: float = 0.78 + 0.22 * sin(menu_anim_t * 3.2)
	var ring_r: float = 48.0
	draw_circle(pent_center, ring_r + 8.0, Color(0.75, 0.10, 0.08, 0.18 * pulse))
	draw_arc(pent_center, ring_r, 0.0, TAU, 48, Color(0.92, 0.18, 0.12, 0.95 * pulse), 2.8)
	draw_arc(pent_center, ring_r - 5.0, 0.0, TAU, 48, Color(0.98, 0.72, 0.24, 0.65 * pulse), 1.2)

	var star_pts := PackedVector2Array()
	for i in range(5):
		var ang: float = -PI * 0.5 + float(i) * TAU / 5.0
		star_pts.append(pent_center + Vector2(cos(ang), sin(ang)) * (ring_r - 3.0))
	var star_order: Array[int] = [0, 2, 4, 1, 3, 0]
	for i in range(5):
		var a: Vector2 = star_pts[star_order[i]]
		var b: Vector2 = star_pts[star_order[i + 1]]
		draw_line(a, b, Color(0.98, 0.24, 0.14, 0.95 * pulse), 2.4)

	var flame_frame: int = int(menu_anim_t * 8.0) % 3
	var brazier_tex: ImageTexture = SpriteFactory.get_prop_sprite("brazier", 1, flame_frame)
	draw_texture_rect(brazier_tex, Rect2(panel_rect.position.x + 36.0, panel_rect.position.y + 168.0, 96.0, 144.0), false)
	draw_texture_rect(brazier_tex, Rect2(panel_rect.end.x - 132.0, panel_rect.position.y + 168.0, 96.0, 144.0), false)

	var av_tex: ImageTexture = SpriteFactory.get_avatar_sprite(2, int(menu_anim_t * 3.0) % 4, false, false, true, false, true)
	draw_texture_rect(av_tex, Rect2(panel_rect.position.x + 92.0, panel_rect.position.y + 164.0, 112.0, 130.0), false)

	var wraith_tex: ImageTexture = SpriteFactory.get_enemy_sprite("titan_boss", int(menu_anim_t * 3.0) % 4, false)
	draw_texture_rect(wraith_tex, Rect2(panel_rect.end.x - 204.0, panel_rect.position.y + 164.0, 112.0, 130.0), false)

	var title_str: String = "ULTIMA VIII : PAGAN"
	var t_size: Vector2 = font.get_string_size(title_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 32)
	var title_pos := Vector2(vp.x * 0.5 - t_size.x * 0.5, panel_rect.position.y + 182.0)
	draw_string_outline(font, title_pos, title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 6, Color(0.05, 0.02, 0.02))
	draw_string(font, title_pos, title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(0.96, 0.78, 0.30))

	var sub_str: String = "THE 666 PROCEDURAL SANCTUMS OF TENEBRAE"
	var s_size: Vector2 = font.get_string_size(sub_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(font, Vector2(vp.x * 0.5 - s_size.x * 0.5, panel_rect.position.y + 212.0), sub_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.90, 0.34, 0.26))

	var lore_str: String = "\"3 Lives • Procedural Realms • Boss Battles at Level 6 & 666 • Permadeath Reseed\""
	var l_size: Vector2 = font.get_string_size(lore_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	draw_string(font, Vector2(vp.x * 0.5 - l_size.x * 0.5, panel_rect.position.y + 240.0), lore_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.76, 0.72, 0.82))

	if show_credits:
		_draw_credits_modal(vp, font)
		return

	var labels: Array[String] = [
		("RESUME (LVL " + str(current_level) + " • " + str(lives) + " LIVES)") if game_has_started else "START GAME",
		"CREDITS",
		"QUIT GAME"
	]
	for i in range(3):
		var btn_rect: Rect2 = _get_menu_button_rect(i, vp)
		var sel: bool = (menu_selected_idx == i)
		var bg_col := Color(0.36, 0.10, 0.10, 0.96) if sel else Color(0.11, 0.08, 0.15, 0.92)
		var border_col := Color(0.98, 0.76, 0.30) if sel else Color(0.48, 0.34, 0.24)
		draw_rect(btn_rect, bg_col)
		draw_rect(btn_rect, border_col, false, 2.5 if sel else 1.5)

		var label_txt: String = ("✦  " + labels[i] + "  ✦") if sel else labels[i]
		var lw: float = font.get_string_size(label_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 18).x
		var text_col := Color(1.0, 0.88, 0.42) if sel else Color(0.84, 0.80, 0.88)
		draw_string(font, Vector2(btn_rect.position.x + (btn_rect.size.x - lw) * 0.5, btn_rect.position.y + 32.0), label_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, text_col)

	var music_str: String = "♪ Soundtrack: Ultima VIII: Pagan — Main Theme (Composed by Nenad Vugrinec, 1994)"
	var mw: float = font.get_string_size(music_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12).x
	draw_string(font, Vector2(vp.x * 0.5 - mw * 0.5, panel_rect.end.y - 34.0), music_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.86, 0.68, 0.34))

	var hint_str: String = "[Left-Click or W/S + Enter/Space to Select]"
	var hw: float = font.get_string_size(hint_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12).x
	draw_string(font, Vector2(vp.x * 0.5 - hw * 0.5, panel_rect.end.y - 14.0), hint_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.58, 0.68))

func _draw_credits_modal(vp: Vector2, font: Font) -> void:
	var c_w: float = 620.0
	var c_h: float = 420.0
	var c_rect := Rect2(vp.x * 0.5 - c_w * 0.5, vp.y * 0.5 - c_h * 0.5 + 24.0, c_w, c_h)
	draw_rect(c_rect, Color(0.05, 0.03, 0.08, 0.98))
	draw_rect(c_rect, Color(0.92, 0.68, 0.26, 0.96), false, 2.5)
	draw_rect(c_rect.grow(-5.0), Color(0.65, 0.18, 0.16, 0.85), false, 1.5)

	var header: String = "CODEX OF PAGAN  —  CREDITS"
	var hw: float = font.get_string_size(header, HORIZONTAL_ALIGNMENT_CENTER, -1, 20).x
	draw_string(font, Vector2(vp.x * 0.5 - hw * 0.5, c_rect.position.y + 36.0), header, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.98, 0.80, 0.32))

	var credit_lines: Array[String] = [
		"ORIGINAL ULTIMA VIII: PAGAN (1994) — ORIGIN SYSTEMS",
		"• Executive Producer & Creator:  Richard Garriott (Lord British)",
		"• Original Musical Score:  Nenad Vugrinec (Main Theme, Tenebrae, Docks, Combat)",
		"• Lead Art & Direction:  Billy Cain & Origin Systems Austin Studio",
		"",
		"THE 666 PROCEDURAL SANCTUMS  —  GODOT 4.7 EDITION",
		"• Isometric 2:1 Z-Elevation Engine & Depth Sorter:  IsoMath & IsoRenderer",
		"• 1994 VGA Pixel-Art Avatar, Monsters & Boss Sprites:  SpriteFactory",
		"• 3-Lives System, Potion Life Restore & Boss Combat:  GameController",
		"• 666-Level Procedural Dungeon & Boss Arena Generator:  LevelData",
		"• Authentic Pagan Soundtrack & SFX Integration:  AudioManager"
	]

	for i in range(credit_lines.size()):
		var line: String = credit_lines[i]
		if line == "":
			continue
		var is_section: bool = not line.begins_with("•")
		var col := Color(0.94, 0.42, 0.30) if is_section else Color(0.86, 0.83, 0.92)
		var fsize: int = 14 if is_section else 13
		draw_string(font, Vector2(c_rect.position.x + 32.0, c_rect.position.y + 74.0 + float(i) * 26.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)

	var back_rect := Rect2(vp.x * 0.5 - 160.0, c_rect.end.y - 54.0, 320.0, 38.0)
	draw_rect(back_rect, Color(0.32, 0.10, 0.10, 0.95))
	draw_rect(back_rect, Color(0.96, 0.74, 0.28), false, 2.0)
	var back_str: String = "✦  BACK TO TITLE MENU [ESC / CLICK]  ✦"
	var bw: float = font.get_string_size(back_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
	draw_string(font, Vector2(vp.x * 0.5 - bw * 0.5, back_rect.position.y + 24.0), back_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.88, 0.42))

func _get_current_quest_text() -> String:
	if LevelData.is_boss_level(current_level):
		var active_boss: Dictionary = _get_active_final_boss()
		if not active_boss.is_empty():
			return "Vanquish " + String(active_boss["name"]) + " in the Courtyard to awaken the Obelisk!"
		return "Enter the awakened Grand Blackrock Obelisk on the stone dais!"
	for prop in props:
		if prop["id"] == "gate_portcullis" and not prop.get("opened", false):
			if not has_item("iron_key"):
				return "Search the slain guard on the cobblestone street for the Gatehouse Key."
			return "Use the Key on the heavy Ring-Handled Gatehouse Door."
	if not bridge_raised:
		return "Cross the creek stepping stones to the Watchtower House & pull the Canal Bridge Lever."
	if not obelisk_awakened:
		var lit_c := get_lit_ritual_pyres_count()
		return "Courtyard Ritual: Light 3 Pyres (" + str(lit_c) + "/3) & place a Blood Candle on the Pentagram."
	return "Enter the awakened Blackrock Obelisk to warp to Level " + str(current_level + 1) + "!"
