class_name IsoRenderer
extends Node2D

var game: Variant = null
var time_sec: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	time_sec += delta
	queue_redraw()

func _draw() -> void:
	if game == null or game.tiles.is_empty():
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var cam_offset: Vector2 = game.camera_offset
	draw_set_transform(cam_offset, 0.0, Vector2.ONE)

	# Viewport frustum bounds in world-screen space (with generous padding for tall walls/trees)
	var min_sx: float = -cam_offset.x - 120.0
	var max_sx: float = -cam_offset.x + vp_size.x + 120.0
	var min_sy: float = -cam_offset.y - 140.0
	var max_sy: float = -cam_offset.y + vp_size.y + 140.0

	var draw_list: Array[Dictionary] = []
	var tiles: Array = game.tiles
	var map_w: int = tiles.size()
	var map_h: int = (tiles[0] as Array).size() if map_w > 0 else 0

	for x in range(map_w):
		var col_arr: Array = tiles[x]
		for y in range(map_h):
			# Quick isometric screen-space frustum check before building dictionary
			var approx_sx: float = float(x - y) * IsoMath.HALF_W
			if approx_sx < min_sx or approx_sx > max_sx:
				continue
			var approx_sy: float = float(x + y) * IsoMath.HALF_H
			if approx_sy < min_sy or approx_sy > max_sy + 90.0:
				continue

			var t: Dictionary = col_arr[y]
			var z_eff: float = float(t["z"])
			if int(t["type"]) == LevelData.TileType.CRUMBLING_STONE and bool(t["crumbled"]):
				z_eff = 0.0
			draw_list.append({
				"kind": "tile",
				"depth": float(x + y) * 100.0 + z_eff * 0.5,
				"x": x,
				"y": y,
				"tile": t
			})

	for prop in game.props:
		var p: Vector3 = prop["pos"]
		var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
		if sp.x < min_sx or sp.x > max_sx or sp.y < min_sy or sp.y > max_sy:
			continue
		draw_list.append({
			"kind": "prop",
			"depth": IsoMath.depth_key(p.x, p.y, p.z) + 12.0,
			"prop": prop
		})

	for drop in game.ground_items:
		var p: Vector3 = drop["pos"]
		var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
		if sp.x < min_sx or sp.x > max_sx or sp.y < min_sy or sp.y > max_sy:
			continue
		draw_list.append({
			"kind": "drop",
			"depth": IsoMath.depth_key(p.x, p.y, p.z) + 10.0,
			"drop": drop
		})

	for enemy in game.enemies:
		if int(enemy["hp"]) <= 0:
			continue
		var p: Vector3 = enemy["pos"]
		var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
		if sp.x < min_sx or sp.x > max_sx or sp.y < min_sy or sp.y > max_sy:
			continue
		draw_list.append({
			"kind": "enemy",
			"depth": IsoMath.depth_key(p.x, p.y, p.z) + 16.0,
			"enemy": enemy
		})

	var av_pos: Vector3 = game.avatar_pos
	draw_list.append({
		"kind": "avatar",
		"depth": IsoMath.depth_key(av_pos.x, av_pos.y, av_pos.z) + 16.5
	})

	for proj in game.projectiles:
		var p: Vector3 = proj["pos"]
		draw_list.append({
			"kind": "proj",
			"depth": IsoMath.depth_key(p.x, p.y, p.z) + 22.0,
			"proj": proj
		})

	for part in game.particles:
		var p: Vector3 = part["pos"]
		draw_list.append({
			"kind": "part",
			"depth": IsoMath.depth_key(p.x, p.y, p.z) + 24.0,
			"part": part
		})

	draw_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["depth"]) < float(b["depth"])
	)

	for item in draw_list:
		var k: String = String(item["kind"])
		match k:
			"tile":
				_draw_tile(int(item["x"]), int(item["y"]), item["tile"])
			"prop":
				_draw_prop(item["prop"])
			"drop":
				_draw_drop(item["drop"])
			"enemy":
				_draw_enemy(item["enemy"])
			"avatar":
				_draw_avatar()
			"proj":
				_draw_projectile(item["proj"])
			"part":
				_draw_particle(item["part"])

	_draw_pentagram_sigil()
	if not game.in_start_menu:
		_draw_target_reticle()
	_draw_lighting_and_barks(min_sx, max_sx, min_sy, max_sy)

func _draw_tile(x: int, y: int, t: Dictionary) -> void:
	var t_type: int = int(t["type"])
	var z: float = float(t["z"])
	var variant: int = int(t["variant"])
	if t_type == LevelData.TileType.CRUMBLING_STONE and bool(t["crumbled"]):
		t_type = LevelData.TileType.WATER
		z = 0.0

	var shake := Vector2.ZERO
	if t_type == LevelData.TileType.CRUMBLING_STONE and float(t["crumble_timer"]) > 0.0:
		shake = Vector2(sin(time_sec * 55.0) * 2.5, cos(time_sec * 48.0) * 1.5)

	var anim_frame: int = int(time_sec * 3.5 + float(x + y)) % 3
	var tex: ImageTexture = SpriteFactory.get_tile_sprite(t_type, variant, anim_frame)

	if z > 1.8 and t_type != LevelData.TileType.WATER and t_type != LevelData.TileType.LAVA:
		var low_sp: Vector2 = IsoMath.world_to_screen(float(x), float(y), z - 1.8) + shake
		draw_texture(tex, low_sp - Vector2(32.0, 0.0))

	var top_sp: Vector2 = IsoMath.world_to_screen(float(x), float(y), z) + shake
	draw_texture(tex, top_sp - Vector2(32.0, 0.0))

func _draw_pentagram_sigil() -> void:
	var pc: Vector3 = game.pentagram_center
	var center_w := Vector2(pc.x, pc.y)
	var z: float = pc.z
	var lit_count: int = game.get_lit_ritual_pyres_count()
	var glow_factor: float = 0.35 + float(lit_count) * 0.22 + (0.15 * sin(time_sec * 4.0) if lit_count >= 3 else 0.0)
	var blood_col := Color(0.75, 0.12, 0.10, clampf(glow_factor, 0.3, 0.95))
	var inner_glow := Color(1.0, 0.45, 0.12, clampf(glow_factor - 0.2, 0.0, 0.85))

	var radius: float = 1.65
	var ring_pts := PackedVector2Array()
	var segments: int = 32
	for i in range(segments + 1):
		var ang: float = float(i) * TAU / float(segments)
		var wx: float = center_w.x + cos(ang) * radius
		var wy: float = center_w.y + sin(ang) * radius
		ring_pts.append(IsoMath.world_to_screen(wx, wy, z))
	draw_polyline(ring_pts, blood_col, 2.5)

	var star_pts: Array[Vector2] = []
	for i in range(5):
		var ang: float = -PI * 0.5 + float(i) * TAU / 5.0
		var wx: float = center_w.x + cos(ang) * (radius * 0.95)
		var wy: float = center_w.y + sin(ang) * (radius * 0.95)
		star_pts.append(IsoMath.world_to_screen(wx, wy, z))

	var order: Array[int] = [0, 2, 4, 1, 3, 0]
	for i in range(5):
		var p_a: Vector2 = star_pts[order[i]]
		var p_b: Vector2 = star_pts[order[i + 1]]
		draw_line(p_a, p_b, blood_col, 2.5)
		if lit_count > 0:
			draw_line(p_a, p_b, inner_glow, 1.2)

func _draw_prop(prop: Dictionary) -> void:
	var p: Vector3 = prop["pos"]
	var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
	var p_type: String = String(prop["type"])
	var state: int = 0

	match p_type:
		"brazier":
			var is_lit: int = 1 if bool(prop.get("lit", false)) else 0
			var is_rit: int = 2 if bool(prop.get("ritual", false)) else 0
			state = is_lit + is_rit
		"chest", "sarcophagus", "gate":
			state = 1 if bool(prop.get("opened", false)) else 0
		"corpse":
			state = 1 if bool(prop.get("looted", false)) else 0
		"lever", "pentagram_focus", "obelisk":
			state = 1 if bool(prop.get("activated", false)) else 0

	var frame: int = int(time_sec * 8.0 + p.x * 3.0) % 3
	var tex: ImageTexture = SpriteFactory.get_prop_sprite(p_type, state, frame)
	draw_texture_rect(tex, Rect2(sp.x - 28.0, sp.y - 62.0, 56.0, 72.0), false)

func _draw_drop(drop: Dictionary) -> void:
	var p: Vector3 = drop["pos"]
	var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
	var bob: float = sin(time_sec * 4.5 + p.x) * 2.5
	draw_circle(sp + Vector2(0, 2), 6.0, Color(0, 0, 0, 0.45))
	var item_id: String = String(drop["item"])
	var tex: ImageTexture = SpriteFactory.get_item_sprite(item_id)
	draw_texture_rect(tex, Rect2(sp.x - 14.0, sp.y - 26.0 + bob, 28.0, 28.0), false)

func _draw_avatar() -> void:
	var p: Vector3 = game.avatar_pos
	var ground_z: float = game.get_floor_z_at(p.x, p.y)
	var shadow_sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, ground_z)
	var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)

	var height_above: float = maxf(0.0, p.z - ground_z)
	var shadow_r: float = clampf(11.0 - height_above * 2.0, 4.0, 11.0)
	draw_circle(shadow_sp + Vector2(0, 2), shadow_r, Color(0.0, 0.0, 0.0, 0.55))

	var anim_phase: int = 0
	if bool(game.avatar_moving):
		anim_phase = (int(float(game.avatar_anim_t) * 8.0) % 3) + 1

	var jumping: bool = not bool(game.avatar_grounded)
	var attacking: bool = float(game.attack_anim_timer) > 0.0
	var has_flame: bool = bool(game.has_item("flame_blade"))
	var dead: bool = bool(game.avatar_dead)
	var facing: int = int(game.avatar_facing)
	var in_combat: bool = bool(game.combat_mode)

	var tex: ImageTexture = SpriteFactory.get_avatar_sprite(facing, anim_phase, jumping, attacking, has_flame, dead, in_combat)
	draw_texture_rect(tex, Rect2(sp.x - 30.0, sp.y - 58.0, 60.0, 70.0), false)

func _draw_enemy(enemy: Dictionary) -> void:
	var p: Vector3 = enemy["pos"]
	var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
	var flash: bool = float(enemy["hit_flash"]) > 0.0
	var anim_phase: int = (int(float(enemy["anim_t"]) * 6.0) % 3) + 1
	var e_type: String = String(enemy["type"])
	var is_final_boss: bool = bool(enemy.get("final_boss", false))

	if is_final_boss:
		var pulse_r: float = 18.0 + sin(time_sec * 6.0) * 3.0
		draw_circle(sp + Vector2(0, 2), pulse_r, Color(0.95, 0.20, 0.10, 0.32))
		draw_circle(sp + Vector2(0, 2), 13.0, Color(0, 0, 0, 0.6))
		var tex_b: ImageTexture = SpriteFactory.get_enemy_sprite(e_type, anim_phase, flash)
		draw_texture_rect(tex_b, Rect2(sp.x - 37.0, sp.y - 72.0, 74.0, 86.0), false)
	else:
		draw_circle(sp + Vector2(0, 2), 10.0, Color(0, 0, 0, 0.5))
		var tex: ImageTexture = SpriteFactory.get_enemy_sprite(e_type, anim_phase, flash)
		draw_texture_rect(tex, Rect2(sp.x - 30.0, sp.y - 58.0, 60.0, 70.0), false)

	var cur_hp: int = int(enemy["hp"])
	var max_hp_v: int = int(enemy["max_hp"])
	var ratio: float = clampf(float(cur_hp) / float(max_hp_v), 0.0, 1.0)
	var bar_w: float = 44.0 if is_final_boss else 30.0
	var by: float = (sp.y - 72.0) if is_final_boss else (sp.y - 56.0)
	draw_rect(Rect2(sp.x - bar_w * 0.5, by, bar_w, 5.0 if is_final_boss else 4.0), Color(0.1, 0.05, 0.05, 0.85))
	draw_rect(Rect2(sp.x - bar_w * 0.5, by, bar_w * ratio, 5.0 if is_final_boss else 4.0), Color(0.96, 0.26, 0.12, 0.95))
	var font: Font = ThemeDB.fallback_font
	var hp_txt: String = str(cur_hp) + "/" + str(max_hp_v)
	var htw: float = font.get_string_size(hp_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 10).x
	draw_string_outline(font, Vector2(sp.x - htw * 0.5, by - 3.0), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, Color.BLACK)
	draw_string(font, Vector2(sp.x - htw * 0.5, by - 3.0), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.92, 0.55))

func _draw_projectile(proj: Dictionary) -> void:
	var p: Vector3 = proj["pos"]
	var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
	var from_p: bool = bool(proj.get("from_player", true))
	var frame: int = int(time_sec * 12.0) % 3
	var tex: ImageTexture = SpriteFactory.get_projectile_sprite(from_p, frame)
	draw_texture_rect(tex, Rect2(sp.x - 12.0, sp.y - 12.0, 24.0, 24.0), false)

func _draw_particle(part: Dictionary) -> void:
	var p: Vector3 = part["pos"]
	var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z)
	var alpha: float = clampf(float(part["life"]) / float(part["max_life"]), 0.0, 1.0)
	var col: Color = part["color"]
	col.a = alpha
	var sz: float = float(part["size"]) * alpha
	draw_rect(Rect2(sp.x - sz * 0.5, sp.y - sz * 0.5, sz, sz), col)

func _draw_target_reticle() -> void:
	if game.hovered_prop != null:
		var hp: Vector3 = game.hovered_prop["pos"]
		var hsp: Vector2 = IsoMath.world_to_screen(hp.x, hp.y, hp.z)
		var pulse: float = 0.65 + 0.35 * sin(time_sec * 6.0)
		draw_arc(hsp + Vector2(0, -14), 16.0, 0, TAU, 24, Color(0.95, 0.78, 0.25, pulse), 1.8)
	elif game.mouse_world_valid:
		var mw: Vector3 = game.mouse_world_pos
		var msp: Vector2 = IsoMath.world_to_screen(mw.x, mw.y, mw.z)
		draw_arc(msp + Vector2(0, 16), 6.0, 0, TAU, 16, Color(0.85, 0.75, 0.45, 0.35), 1.2)

func _draw_lighting_and_barks(min_sx: float, max_sx: float, min_sy: float, max_sy: float) -> void:
	for prop in game.props:
		var p_type: String = String(prop["type"])
		if p_type == "brazier" and bool(prop.get("lit", false)):
			var p: Vector3 = prop["pos"]
			var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z) + Vector2(0, -18)
			if sp.x < min_sx - 80.0 or sp.x > max_sx + 80.0 or sp.y < min_sy - 80.0 or sp.y > max_sy + 80.0:
				continue
			var r: float = 68.0 + sin(time_sec * 9.0 + p.x) * 6.0
			var glow_c: Color = Color(1.0, 0.45, 0.12, 0.07) if not bool(prop.get("ritual", false)) else Color(1.0, 0.22, 0.18, 0.10)
			draw_circle(sp, r, glow_c)
			draw_circle(sp, r * 0.5, Color(1.0, 0.65, 0.22, 0.08))
		elif p_type == "obelisk" and bool(prop.get("activated", false)):
			var p: Vector3 = prop["pos"]
			var sp: Vector2 = IsoMath.world_to_screen(p.x, p.y, p.z) + Vector2(0, -30)
			draw_circle(sp, 90.0 + sin(time_sec * 5.0) * 10.0, Color(0.75, 0.20, 0.95, 0.12))

	var font: Font = ThemeDB.fallback_font
	for bark in game.barks:
		var bp: Vector3 = bark["pos"]
		var bsp: Vector2 = IsoMath.world_to_screen(bp.x, bp.y, bp.z) + Vector2(0, -56.0 - float(bark["rise"]))
		var alpha: float = clampf(float(bark["timer"]) / 1.2, 0.0, 1.0)
		var col: Color = bark["color"]
		col.a = alpha
		var outline := Color(0, 0, 0, alpha)
		var text: String = String(bark["text"])
		var fsize: int = 15
		var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize).x
		var draw_pos := Vector2(bsp.x - tw * 0.5, bsp.y)
		draw_string_outline(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 4, outline)
		draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
