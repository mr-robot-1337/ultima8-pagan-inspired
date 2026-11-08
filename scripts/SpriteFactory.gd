class_name SpriteFactory
extends RefCounted

# Generates authentic 1994 Origin Systems VGA pixel-art ImageTexture sprites for Ultima VIII: Pagan
# Matching the Tenebrae stone masonry, dark brown cobblestone streets, light grey flagstone interiors,
# brass-banded chests, ring-handled doors, and the Armored Avatar (steel coif, crimson tabard, gold pauldrons & steel greaves).

static var cache: Dictionary = {}

static func get_tile_sprite(t_type: int, variant: int, frame: int) -> ImageTexture:
	var f_key: int = frame if (t_type == LevelData.TileType.WATER or t_type == LevelData.TileType.LAVA or t_type == LevelData.TileType.BRIDGE_SUNKEN) else 0
	var v_key: int = variant % 4
	var key: String = "tile_u8_v2_%d_%d_%d" % [t_type, v_key, f_key]
	if cache.has(key):
		return cache[key]
	var tex: ImageTexture = _build_tile_texture(t_type, v_key, f_key)
	cache[key] = tex
	return tex

static func get_avatar_sprite(facing: int, anim_phase: int, jumping: bool, attacking: bool, has_flame_blade: bool, dead: bool, in_combat: bool = false) -> ImageTexture:
	var key: String = "av_u8_%d_%d_%d_%d_%d_%d_%d" % [facing, anim_phase, int(jumping), int(attacking), int(has_flame_blade), int(dead), int(in_combat)]
	if cache.has(key):
		return cache[key]
	var tex: ImageTexture = _build_avatar_texture(facing, anim_phase, jumping, attacking, has_flame_blade, dead, in_combat)
	cache[key] = tex
	return tex

static func get_enemy_sprite(e_type: String, anim_phase: int, flash: bool) -> ImageTexture:
	var key: String = "en_u8_v2_%s_%d_%d" % [e_type, anim_phase, int(flash)]
	if cache.has(key):
		return cache[key]
	var tex: ImageTexture = _build_enemy_texture(e_type, anim_phase, flash)
	cache[key] = tex
	return tex

static func get_prop_sprite(p_type: String, state: int, frame: int) -> ImageTexture:
	var f_key: int = frame if (p_type == "brazier" or p_type == "obelisk" or p_type == "corpse") else 0
	var key: String = "pr_u8_%s_%d_%d" % [p_type, state, f_key]
	if cache.has(key):
		return cache[key]
	var tex: ImageTexture = _build_prop_texture(p_type, state, f_key)
	cache[key] = tex
	return tex

static func get_projectile_sprite(from_player: bool, frame: int) -> ImageTexture:
	var key: String = "proj_u8_%d_%d" % [int(from_player), frame % 3]
	if cache.has(key):
		return cache[key]
	var tex: ImageTexture = _build_projectile_texture(from_player, frame % 3)
	cache[key] = tex
	return tex

static func get_item_sprite(item_id: String) -> ImageTexture:
	var key: String = "it_u8_%s" % item_id
	if cache.has(key):
		return cache[key]
	var tex: ImageTexture = _build_item_texture(item_id)
	cache[key] = tex
	return tex

static func _set_px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)

static func _fill_rect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for x in range(x0, x0 + w):
		for y in range(y0, y0 + h):
			_set_px(img, x, y, col)

static func _draw_line_px(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var cx: int = x0
	var cy: int = y0
	while true:
		_set_px(img, cx, cy, col)
		if cx == x1 and cy == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy

static func _add_outline(img: Image, outline_col: Color = Color(0.04, 0.03, 0.04, 1.0)) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var copy: Image = img.duplicate()
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if copy.get_pixel(x, y).a < 0.1:
				if copy.get_pixel(x - 1, y).a > 0.5 or copy.get_pixel(x + 1, y).a > 0.5 or copy.get_pixel(x, y - 1).a > 0.5 or copy.get_pixel(x, y + 1).a > 0.5:
					img.set_pixel(x, y, outline_col)

static func _build_tile_texture(t_type: int, variant: int, frame: int) -> ImageTexture:
	var img: Image = Image.create(64, 72, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Default: Dark earthy-brown Pagan cobblestone street (exact match to screenshot)
	var top_c1 := Color(0.27, 0.23, 0.18)
	var top_c2 := Color(0.22, 0.18, 0.14)
	var mortar_c := Color(0.09, 0.07, 0.06)
	var left_c1 := Color(0.48, 0.51, 0.57)
	var left_c2 := Color(0.40, 0.43, 0.49)
	var right_c1 := Color(0.34, 0.37, 0.43)
	var right_c2 := Color(0.27, 0.29, 0.35)
	var bevel_c := Color(0.36, 0.31, 0.25)
	var cliff_h: int = 36

	match t_type:
		LevelData.TileType.WATER, LevelData.TileType.BRIDGE_SUNKEN:
			cliff_h = 0
			var w_shift: float = float(frame) * 0.02
			top_c1 = Color(0.06, 0.11 + w_shift, 0.20 + w_shift)
			top_c2 = Color(0.04, 0.07, 0.14)
			if t_type == LevelData.TileType.BRIDGE_SUNKEN:
				top_c1 = top_c1.lerp(Color(0.35, 0.38, 0.44), 0.45)
			bevel_c = Color(0.16, 0.26, 0.38)
		LevelData.TileType.LAVA:
			cliff_h = 0
			var l_shift: float = float(frame) * 0.06
			top_c1 = Color(0.82 + l_shift, 0.26 + l_shift, 0.04)
			top_c2 = Color(0.48, 0.10, 0.02)
			bevel_c = Color(0.98, 0.65, 0.14)
		LevelData.TileType.COBBLE_FLOOR:
			# Screenshot dark brown/charcoal rectangular cobblestones with deep mortar
			top_c1 = Color(0.26, 0.22, 0.17)
			top_c2 = Color(0.20, 0.17, 0.13)
			mortar_c = Color(0.08, 0.06, 0.05)
			left_c1 = Color(0.36, 0.32, 0.27)
			left_c2 = Color(0.28, 0.24, 0.20)
			right_c1 = Color(0.24, 0.20, 0.17)
			right_c2 = Color(0.18, 0.15, 0.12)
			bevel_c = Color(0.34, 0.29, 0.23)
		LevelData.TileType.OBSIDIAN_FLOOR:
			# Screenshot light cool-grey stone flagstone interior floor slabs!
			top_c1 = Color(0.56, 0.59, 0.65)
			top_c2 = Color(0.50, 0.53, 0.59)
			mortar_c = Color(0.31, 0.33, 0.38)
			left_c1 = Color(0.50, 0.53, 0.59)
			left_c2 = Color(0.42, 0.45, 0.51)
			right_c1 = Color(0.36, 0.39, 0.45)
			right_c2 = Color(0.29, 0.31, 0.37)
			bevel_c = Color(0.68, 0.71, 0.77)
		LevelData.TileType.PILLAR_STONE, LevelData.TileType.STAIRS:
			top_c1 = Color(0.52, 0.55, 0.61)
			top_c2 = Color(0.45, 0.48, 0.54)
			mortar_c = Color(0.26, 0.28, 0.33)
			bevel_c = Color(0.66, 0.69, 0.75)
		LevelData.TileType.CRUMBLING_STONE:
			top_c1 = Color(0.46, 0.38, 0.32)
			top_c2 = Color(0.36, 0.29, 0.24)
			mortar_c = Color(0.16, 0.12, 0.10)
			left_c1 = Color(0.38, 0.31, 0.26)
			left_c2 = Color(0.28, 0.22, 0.18)
			bevel_c = Color(0.58, 0.48, 0.40)
		LevelData.TileType.BRIDGE_RAISED:
			top_c1 = Color(0.44, 0.36, 0.28)
			top_c2 = Color(0.36, 0.28, 0.21)
			mortar_c = Color(0.16, 0.12, 0.09)
			bevel_c = Color(0.56, 0.46, 0.36)
		LevelData.TileType.PENTAGRAM_FLOOR:
			top_c1 = Color(0.42, 0.38, 0.44)
			top_c2 = Color(0.35, 0.31, 0.37)
			mortar_c = Color(0.48, 0.12, 0.14)
			bevel_c = Color(0.64, 0.22, 0.24)
		LevelData.TileType.WALL_BLOCK:
			# Screenshot cut-away grey stone masonry wall with white corner pilaster trim
			top_c1 = Color(0.60, 0.63, 0.69)
			top_c2 = Color(0.52, 0.55, 0.61)
			mortar_c = Color(0.28, 0.30, 0.35)
			left_c1 = Color(0.56, 0.59, 0.66)
			left_c2 = Color(0.46, 0.49, 0.56)
			right_c1 = Color(0.42, 0.45, 0.52)
			right_c2 = Color(0.33, 0.36, 0.42)
			bevel_c = Color(0.75, 0.78, 0.84)
		LevelData.TileType.GRASS_FLOOR:
			# Outdoor Ultima VIII lush woodland grass & turf with earthen cliff sides
			top_c1 = Color(0.18, 0.36, 0.12)
			top_c2 = Color(0.14, 0.29, 0.09)
			mortar_c = Color(0.10, 0.22, 0.06)
			left_c1 = Color(0.32, 0.24, 0.16)
			left_c2 = Color(0.25, 0.18, 0.12)
			right_c1 = Color(0.22, 0.16, 0.11)
			right_c2 = Color(0.17, 0.12, 0.08)
			bevel_c = Color(0.26, 0.48, 0.17)

	# 1. Draw Isometric Cliff / Stone Masonry Wall Sides
	if cliff_h > 0:
		for x in range(0, 64):
			var edge_y: int = 31 - absi(31 - x) / 2
			var is_left: bool = (x < 32)
			# White stone corner pilaster on WALL_BLOCK (just like the screenshot's doorway/corner pillars!)
			var is_pilaster: bool = (t_type == LevelData.TileType.WALL_BLOCK) and (absi(x - 31) <= 3 or x <= 4 or x >= 59)
			for dy in range(0, cliff_h):
				var py: int = edge_y + dy
				if py >= 72:
					break
				var dither: bool = ((x + py) % 2 == 0)
				var col: Color = (left_c1 if dither else left_c2) if is_left else (right_c1 if dither else right_c2)
				if is_pilaster:
					col = col.lightened(0.22)
				# Ashlar stone block mortar joints
				var row_idx: int = dy / 7
				var brick_x: int = (x + (row_idx % 2) * 6) % 12
				if dy % 7 == 0 or brick_x == 0:
					col = col.darkened(0.38)
				elif dy % 7 == 1:
					col = col.lightened(0.10)
				_set_px(img, x, py, col)

		# Add mounted glowing yellow Wrought-Iron Wall Lantern or Gargoyle Relief on WALL_BLOCK variants (like screenshot!)
		if t_type == LevelData.TileType.WALL_BLOCK:
			if variant % 2 == 0:
				# Wrought-iron bracket + glowing yellow-white glass lantern on the wall face
				_fill_rect(img, 42, 34, 2, 8, Color(0.12, 0.14, 0.18))
				_fill_rect(img, 42, 36, 5, 2, Color(0.12, 0.14, 0.18))
				_fill_rect(img, 45, 29, 7, 8, Color(0.10, 0.12, 0.16))
				_fill_rect(img, 46, 30, 5, 6, Color(1.0, 0.94, 0.32))
				_fill_rect(img, 47, 31, 3, 4, Color(1.0, 1.0, 0.78))
				_fill_rect(img, 44, 28, 9, 2, Color(0.14, 0.16, 0.22))
			else:
				# Carved grey stone Gargoyle / Lion head relief & barred window grate
				_fill_rect(img, 14, 30, 9, 10, Color(0.10, 0.12, 0.16))
				for bx in range(15, 23, 2):
					_fill_rect(img, bx, 30, 1, 10, Color(0.45, 0.48, 0.54))
				_fill_rect(img, 14, 34, 9, 1, Color(0.45, 0.48, 0.54))

	# 2. Draw Top Isometric Diamond Surface (64x32)
	for y in range(0, 32):
		var half_span: int = y * 2 if y < 16 else (31 - y) * 2
		var x_start: int = 31 - half_span
		var x_end: int = 32 + half_span
		for x in range(x_start, x_end + 1):
			var dither: bool = ((x + y) % 2 == 0)
			var col: Color = top_c1 if dither else top_c2

			if x <= x_start + 1 or x >= x_end - 1:
				col = bevel_c if y < 16 else bevel_c.darkened(0.28)
			elif t_type == LevelData.TileType.WATER:
				if ((x + frame * 5 + y * 3) % 19 == 0) and (y % 4 == 0):
					col = Color(0.28, 0.45, 0.64)
			elif t_type == LevelData.TileType.LAVA:
				if ((x * 3 + y * 5 + frame * 4) % 17 < 2):
					col = Color(1.0, 0.85, 0.22)
			elif t_type == LevelData.TileType.COBBLE_FLOOR:
				# Isometric dark-brown cobblestone grid with deep mortar lines
				var u: int = x + y * 2
				var v: int = y * 2 - x + 64
				var course: int = v / 8
				var joint_u: int = (u + (course % 2) * 5) % 10
				if v % 8 == 0 or joint_u == 0:
					col = mortar_c
				elif v % 8 == 1 or joint_u == 1:
					col = col.lightened(0.14)
				elif ((course + (u / 10) + variant) % 3 == 0):
					col = col.darkened(0.12)
				# Lush green Pagan bush/foliage tuft along edge of variant==3 cobble tiles
				if variant == 3 and x > 40 and y > 6 and y < 22:
					if ((x * 3 + y * 5) % 7 != 0):
						col = Color(0.26, 0.48, 0.16) if dither else Color(0.16, 0.34, 0.10)
						if (x + y) % 5 == 0:
							col = Color(0.40, 0.64, 0.24)
			elif t_type == LevelData.TileType.OBSIDIAN_FLOOR or t_type == LevelData.TileType.PILLAR_STONE:
				# Light grey chiseled stone flagstones (exact match to indoor floors in screenshot)
				var u: int = x + y * 2
				var v: int = y * 2 - x + 64
				var slab_row: int = v / 14
				var slab_u: int = (u + (slab_row % 2) * 8) % 16
				if v % 14 == 0 or slab_u == 0:
					col = mortar_c
				elif v % 14 == 1 or slab_u == 1:
					col = bevel_c
				elif (x + y * 3 + variant * 7) % 29 == 0:
					col = col.darkened(0.12)
			elif t_type == LevelData.TileType.STAIRS:
				# Chiseled stone steps
				if y % 5 == 0:
					col = mortar_c
				elif y % 5 == 1:
					col = bevel_c
			elif t_type == LevelData.TileType.GRASS_FLOOR:
				# Lush Ultima VIII grass blades, moss tufts & earth speckles
				var h_val: int = (x * 13 + y * 29 + variant * 17) % 23
				if h_val < 4:
					col = Color(0.28, 0.52, 0.18)
				elif h_val < 7:
					col = Color(0.36, 0.62, 0.22)
				elif h_val == 8:
					col = Color(0.11, 0.23, 0.07)
				elif h_val == 19 and variant == 2:
					col = Color(0.88, 0.78, 0.24) # Wildflower speck
			else:
				if (x + y * 2 + variant * 5) % 19 == 0 or (x - y * 2 == variant * 4 - 6):
					col = mortar_c
			_set_px(img, x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_avatar_texture(facing: int, anim_phase: int, jumping: bool, attacking: bool, has_flame_blade: bool, dead: bool, in_combat: bool) -> ImageTexture:
	# Exact match to the Armored Ultima VIII: Pagan Avatar in the user's screenshot:
	# - Steel/grey chainmail coif & nasal helm with shadowed visor/face
	# - Bright scarlet-crimson tunic/tabard with golden-yellow/brass shoulder pauldrons & chest trim
	# - Gold waist belt with brass buckle & dark leather backpack behind shoulders
	# - Crimson/gold gauntlets & ochre/tan knee-breeches
	# - Tall silver-grey steel greaves / boots with dark articulated knee bands & steel sabatons
	var img: Image = Image.create(48, 56, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Palette sampled directly from the uploaded screenshot's Avatar sprite
	var c_crimson_dark := Color(0.48, 0.06, 0.05)
	var c_crimson_mid := Color(0.76, 0.12, 0.09)
	var c_crimson_hi := Color(0.92, 0.22, 0.15)

	var c_gold_dark := Color(0.58, 0.38, 0.08)
	var c_gold_mid := Color(0.84, 0.62, 0.15)
	var c_gold_hi := Color(0.98, 0.82, 0.28)

	var c_steel_dark := Color(0.30, 0.32, 0.36)
	var c_steel_mid := Color(0.52, 0.55, 0.60)
	var c_steel_hi := Color(0.74, 0.77, 0.83)

	var c_breeches := Color(0.72, 0.52, 0.24)
	var c_pack_dark := Color(0.18, 0.12, 0.07)
	var c_pack_mid := Color(0.28, 0.19, 0.11)
	var c_face_sh := Color(0.55, 0.38, 0.28)
	var c_face_mid := Color(0.76, 0.56, 0.42)

	if dead:
		# Fallen Armored Avatar on stone
		_fill_rect(img, 6, 41, 12, 6, c_steel_mid)
		_fill_rect(img, 17, 40, 15, 7, c_crimson_mid)
		_fill_rect(img, 20, 39, 5, 3, c_gold_hi)
		_fill_rect(img, 31, 40, 8, 6, c_steel_mid)
		_add_outline(img)
		return ImageTexture.create_from_image(img)

	var stride_l: int = 0
	var stride_r: int = 0
	var bob_y: int = 1 if in_combat else 0
	if jumping:
		stride_l = -4
		stride_r = 4
		bob_y = -4
	else:
		match anim_phase:
			1:
				stride_l = -3
				stride_r = 3
				bob_y = -1
			2:
				stride_l = 0
				stride_r = 0
			3:
				stride_l = 3
				stride_r = -3
				bob_y = -1

	var is_back: bool = (facing == 5 or facing == 6 or facing == 7)
	var flip_x: bool = (facing == 3 or facing == 4 or facing == 5)
	var cx: int = 24
	var by: int = 8 + bob_y

	# 0. Dark Leather Backpack peeking behind shoulders (visible in screenshot)
	_fill_rect(img, cx + 3, by + 6, 6, 11, c_pack_dark)
	_fill_rect(img, cx + 4, by + 7, 4, 9, c_pack_mid)

	# 1. Legs: Ochre Knee-Breeches + Tall Silver-Grey Steel Greaves & Sabatons
	var lx: int = cx - 4 + stride_l
	var rx: int = cx + 1 + stride_r
	var ly_f: int = by + 39 - absi(stride_l) / 2
	var ry_f: int = by + 39 - absi(stride_r) / 2

	# Upper thighs / knee breeches (ochre-gold leather beneath crimson tunic skirt)
	_fill_rect(img, lx, by + 24, 4, 5, c_breeches)
	_fill_rect(img, rx, by + 24, 4, 5, c_breeches)

	# Left Tall Steel Greave & Boot
	_fill_rect(img, lx - 1, ly_f - 11, 5, 11, c_steel_dark)
	_fill_rect(img, lx, ly_f - 10, 4, 10, c_steel_mid)
	_fill_rect(img, lx + 1, ly_f - 9, 2, 8, c_steel_hi)
	_fill_rect(img, lx - 1, ly_f - 11, 5, 2, c_pack_dark) # Dark knee-band joint
	_fill_rect(img, lx - 2, ly_f - 1, 6, 3, c_steel_mid)  # Steel sabaton foot
	_fill_rect(img, lx - 2, ly_f, 5, 2, c_steel_hi)

	# Right Tall Steel Greave & Boot
	_fill_rect(img, rx - 1, ry_f - 11, 5, 11, c_steel_dark)
	_fill_rect(img, rx, ry_f - 10, 4, 10, c_steel_mid)
	_fill_rect(img, rx + 1, ry_f - 9, 2, 8, c_steel_hi)
	_fill_rect(img, rx - 1, ry_f - 11, 5, 2, c_pack_dark)
	_fill_rect(img, rx - 1, ry_f - 1, 6, 3, c_steel_mid)
	_fill_rect(img, rx, ry_f, 5, 2, c_steel_hi)

	# 2. Torso: Scarlet-Crimson Tabard / Tunic & Skirt (with Gold Trim & Belt)
	# Crimson Tunic Skirt (over upper thighs)
	_fill_rect(img, cx - 6, by + 19, 12, 7, c_crimson_dark)
	_fill_rect(img, cx - 5, by + 19, 10, 6, c_crimson_mid)
	_fill_rect(img, cx - 4, by + 20, 4, 4, c_crimson_hi)
	_fill_rect(img, cx - 6, by + 25, 12, 1, c_gold_mid) # Gold hem trim

	# Crimson Chest Cuirass / Tabard
	_fill_rect(img, cx - 6, by + 8, 12, 11, c_crimson_dark)
	_fill_rect(img, cx - 5, by + 8, 10, 10, c_crimson_mid)
	_fill_rect(img, cx - 4, by + 9, 4, 7, c_crimson_hi)
	_fill_rect(img, cx + 1, by + 9, 3, 6, c_crimson_hi)

	# Golden-Yellow Chest Crest / Collar Trim & Waist Belt (exact match to screenshot)
	if not is_back:
		_fill_rect(img, cx - 2, by + 8, 4, 2, c_gold_mid)
		_fill_rect(img, cx - 1, by + 9, 2, 6, c_gold_hi)
	else:
		_fill_rect(img, cx - 4, by + 9, 8, 8, c_pack_mid)

	# Heavy Gold / Brown Waist Belt & Brass Buckle
	_fill_rect(img, cx - 6, by + 17, 12, 3, c_gold_dark)
	_fill_rect(img, cx - 5, by + 17, 10, 2, c_gold_mid)
	_fill_rect(img, cx - 2, by + 17, 4, 3, c_gold_hi)

	# 3. Golden-Yellow Shoulder Pauldrons & Armored Arms with Crimson Gauntlets
	var arm_sw: int = -stride_l
	var ly_arm: int = by + 10 + arm_sw / 2
	var ry_arm: int = by + 10 - arm_sw / 2
	if attacking:
		ry_arm = by + 7
	elif in_combat:
		ry_arm = by + 9

	# Left Golden Pauldron (Shoulder Guard)
	_fill_rect(img, cx - 9, by + 7, 4, 5, c_gold_dark)
	_fill_rect(img, cx - 8, by + 7, 3, 4, c_gold_mid)
	_fill_rect(img, cx - 8, by + 8, 2, 2, c_gold_hi)
	# Left Arm & Crimson-Brown Gauntlet
	_fill_rect(img, cx - 9, ly_arm + 2, 3, 5, c_gold_mid)
	_fill_rect(img, cx - 9, ly_arm + 6, 3, 4, c_crimson_dark)
	_fill_rect(img, cx - 8, ly_arm + 6, 2, 3, c_crimson_mid)

	# Right Golden Pauldron (Shoulder Guard)
	_fill_rect(img, cx + 5, by + 7, 4, 5, c_gold_dark)
	_fill_rect(img, cx + 5, by + 7, 3, 4, c_gold_mid)
	_fill_rect(img, cx + 6, by + 8, 2, 2, c_gold_hi)
	# Right Arm & Crimson-Brown Gauntlet
	_fill_rect(img, cx + 6, ry_arm + 2, 3, 5, c_gold_mid)
	_fill_rect(img, cx + 6, ry_arm + 6, 3, 4, c_crimson_dark)
	_fill_rect(img, cx + 6, ry_arm + 6, 2, 3, c_crimson_mid)

	# 4. Head: Steel Chainmail Coif & Nasal Helm (exact match to screenshot!)
	# Chainmail neck gorget / coif collar
	_fill_rect(img, cx - 4, by + 5, 8, 4, c_steel_dark)
	_fill_rect(img, cx - 3, by + 5, 6, 3, c_steel_mid)
	# Steel Helm Dome
	_fill_rect(img, cx - 4, by - 1, 8, 7, c_steel_dark)
	_fill_rect(img, cx - 3, by - 1, 6, 6, c_steel_mid)
	_fill_rect(img, cx - 2, by, 4, 3, c_steel_hi)

	if not is_back:
		# Face opening / Visor shadow with steel nasal bar
		_fill_rect(img, cx - 3, by + 2, 6, 3, c_face_sh)
		_fill_rect(img, cx - 2, by + 3, 4, 2, c_face_mid)
		_set_px(img, cx - 2, by + 2, Color(0.08, 0.08, 0.12))
		_set_px(img, cx + 1, by + 2, Color(0.08, 0.08, 0.12))
		# Steel nasal guard down center of face
		_fill_rect(img, cx - 1, by + 1, 2, 3, c_steel_hi)

	# 5. Drawn Broadsword / Flame Sting Blade (when in Combat Mode or attacking)
	if in_combat or attacking or has_flame_blade:
		var hx: int = cx + 8
		var hy: int = ry_arm + 8
		var b_c1: Color = Color(1.0, 0.45, 0.08) if has_flame_blade else c_steel_mid
		var b_c2: Color = Color(1.0, 0.92, 0.35) if has_flame_blade else c_steel_hi
		_fill_rect(img, hx - 2, hy - 1, 5, 2, c_gold_hi)
		if attacking:
			_draw_line_px(img, hx, hy, hx + 12, hy - 13, b_c1)
			_draw_line_px(img, hx, hy - 1, hx + 12, hy - 14, b_c2)
		else:
			_draw_line_px(img, hx, hy, hx + 8, hy - 15, b_c1)
			_draw_line_px(img, hx + 1, hy, hx + 9, hy - 15, b_c2)

	if flip_x:
		img.flip_x()

	_add_outline(img)
	return ImageTexture.create_from_image(img)

static func _build_enemy_texture(e_type: String, anim_phase: int, flash: bool) -> ImageTexture:
	var img: Image = Image.create(48, 56, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var stride: int = -3 if anim_phase == 1 else (3 if anim_phase == 3 else 0)
	var cx: int = 24

	match e_type:
		"kith":
			# 1. Swamp Kith: Multi-legged emerald-chitin insectoid predator with mandibles
			var c_shell := Color(1, 1, 1) if flash else Color(0.18, 0.48, 0.22)
			var c_shell_hi := Color(1, 1, 1) if flash else Color(0.35, 0.68, 0.28)
			var c_leg := Color(0.12, 0.26, 0.10)
			_fill_rect(img, cx - 10, 30, 20, 11, c_shell)
			_fill_rect(img, cx - 7, 28, 14, 7, c_shell_hi)
			for i in range(-2, 3):
				_draw_line_px(img, cx + i * 4, 38, cx + i * 6 + stride, 48, c_leg)
			_fill_rect(img, cx - 5, 34, 3, 2, Color(1.0, 0.90, 0.15))
			_fill_rect(img, cx + 3, 34, 3, 2, Color(1.0, 0.90, 0.15))
			_draw_line_px(img, cx - 4, 40, cx - 7, 45, Color(0.85, 0.82, 0.68))
			_draw_line_px(img, cx + 4, 40, cx + 7, 45, Color(0.85, 0.82, 0.68))

		"changeling":
			# 2. Morphing Changeling: Green-purple shapeshifter with elongated claws
			var c_body := Color(1, 1, 1) if flash else Color(0.28, 0.56, 0.34)
			var c_shift := Color(1, 1, 1) if flash else Color(0.52, 0.22, 0.58)
			_fill_rect(img, cx - 5, 16, 11, 16, c_body)
			_fill_rect(img, cx - 3, 18, 7, 10, c_shift)
			_fill_rect(img, cx - 4, 9, 9, 8, c_body)
			_set_px(img, cx - 2, 12, Color(1.0, 0.95, 0.20))
			_set_px(img, cx + 2, 12, Color(1.0, 0.95, 0.20))
			_draw_line_px(img, cx - 3, 32, cx - 5 + stride, 46, c_body)
			_draw_line_px(img, cx + 3, 32, cx + 5 - stride, 46, c_shift)
			_draw_line_px(img, cx - 5, 18, cx - 13, 28 + stride, c_shift)
			_draw_line_px(img, cx + 5, 18, cx + 13, 28 - stride, c_body)

		"seeker":
			# 3. Floating Seeker Eye: Disembodied eyeball with hypnotic iris & trailing nerves
			var c_sclera := Color(1, 1, 1) if flash else Color(0.92, 0.88, 0.82)
			var c_iris := Color(0.22, 0.68, 0.92)
			var c_vein := Color(0.78, 0.14, 0.18)
			var bob: int = stride / 2
			_fill_rect(img, cx - 8, 16 + bob, 17, 15, c_sclera)
			_fill_rect(img, cx - 6, 14 + bob, 13, 19, c_sclera)
			_fill_rect(img, cx - 4, 19 + bob, 9, 9, c_iris)
			_fill_rect(img, cx - 2, 21 + bob, 5, 5, Color(0.05, 0.05, 0.08))
			_set_px(img, cx - 1, 21 + bob, Color.WHITE)
			for i in range(-2, 3):
				_draw_line_px(img, cx + i * 2, 32 + bob, cx + i * 3 + stride, 45, c_vein)

		"torax":
			# 4. Torax Hive Drone: Winged wasp-like insectoid with yellow-black stripes
			var c_yel := Color(1, 1, 1) if flash else Color(0.92, 0.74, 0.14)
			var c_blk := Color(0.12, 0.10, 0.14)
			var c_wing := Color(0.75, 0.88, 0.96, 0.85)
			_fill_rect(img, cx - 13, 12 - stride, 10, 7, c_wing)
			_fill_rect(img, cx + 4, 12 + stride, 10, 7, c_wing)
			_fill_rect(img, cx - 4, 16, 9, 18, c_yel)
			for y_s in range(18, 33, 4):
				_fill_rect(img, cx - 4, y_s, 9, 2, c_blk)
			_fill_rect(img, cx - 3, 10, 7, 6, c_blk)
			_set_px(img, cx - 2, 12, Color(1.0, 0.2, 0.1))
			_set_px(img, cx + 2, 12, Color(1.0, 0.2, 0.1))
			_draw_line_px(img, cx, 34, cx, 42, Color(0.95, 0.95, 0.95))

		"ghoul":
			# 5. Catacomb Ghoul: Hunched decaying corpse-eater with bloodied claws
			var c_flesh := Color(1, 1, 1) if flash else Color(0.46, 0.58, 0.42)
			var c_sh := Color(1, 1, 1) if flash else Color(0.28, 0.36, 0.25)
			var c_blood := Color(0.82, 0.12, 0.12)
			_fill_rect(img, cx - 6, 18, 12, 14, c_flesh)
			_fill_rect(img, cx - 4, 20, 8, 10, c_sh)
			_fill_rect(img, cx - 5, 11, 8, 8, c_flesh)
			_set_px(img, cx - 3, 14, c_blood)
			_set_px(img, cx + 1, 14, c_blood)
			_fill_rect(img, cx - 3, 17, 5, 2, c_blood)
			_fill_rect(img, cx - 5 + stride, 32, 4, 14, c_sh)
			_fill_rect(img, cx + 2 - stride, 32, 4, 14, c_sh)
			_fill_rect(img, cx - 11, 24 + stride, 5, 4, c_blood)
			_fill_rect(img, cx + 7, 24 - stride, 5, 4, c_blood)

		"zombie":
			# 6. Risen Pagan Zombie: Shambling undead peasant in tattered olive/brown rags
			var c_zskin := Color(1, 1, 1) if flash else Color(0.52, 0.62, 0.48)
			var c_rags := Color(1, 1, 1) if flash else Color(0.36, 0.28, 0.18)
			var c_pants := Color(0.24, 0.28, 0.20)
			_fill_rect(img, cx - 4, 9, 8, 8, c_zskin)
			_set_px(img, cx - 2, 12, Color(0.9, 0.2, 0.1))
			_set_px(img, cx + 1, 12, Color(0.9, 0.2, 0.1))
			_fill_rect(img, cx - 6, 17, 12, 15, c_rags)
			_fill_rect(img, cx - 11, 18, 6, 4, c_zskin) # Outstretched zombie arms
			_fill_rect(img, cx + 5, 18, 6, 4, c_zskin)
			_fill_rect(img, cx - 5 + stride, 32, 4, 15, c_pants)
			_fill_rect(img, cx + 1 - stride, 32, 4, 15, c_pants)

		"ghost":
			# 7. Wailing Ghost of Tenebrae: Translucent cyan-white spectral apparition
			var c_sp1 := Color(1, 1, 1) if flash else Color(0.62, 0.92, 0.98, 0.85)
			var c_sp2 := Color(1, 1, 1) if flash else Color(0.32, 0.68, 0.88, 0.70)
			for y in range(10, 46):
				var wave: int = int(sin(float(y) * 0.4 + float(anim_phase)) * 2.0)
				var hw: int = 4 + int(float(y - 10) * 0.22)
				_fill_rect(img, cx - hw + wave, y, hw * 2, 1, c_sp1 if y < 28 else c_sp2)
			_fill_rect(img, cx - 3, 14, 2, 3, Color(0.05, 0.12, 0.22))
			_fill_rect(img, cx + 1, 14, 2, 3, Color(0.05, 0.12, 0.22))
			_fill_rect(img, cx - 2, 19, 4, 4, Color(0.05, 0.12, 0.22))

		"fire_imp":
			# 8. Pyros Fire Imp: Winged crimson-orange devilkin wreathed in embers
			var c_imp := Color(1, 1, 1) if flash else Color(0.92, 0.26, 0.08)
			var c_wing := Color(0.58, 0.12, 0.06)
			var c_fire := Color(1.0, 0.86, 0.22)
			_fill_rect(img, cx - 12, 15 + stride, 8, 10, c_wing)
			_fill_rect(img, cx + 5, 15 - stride, 8, 10, c_wing)
			_fill_rect(img, cx - 4, 18, 9, 14, c_imp)
			_fill_rect(img, cx - 4, 11, 9, 7, c_imp)
			_draw_line_px(img, cx - 4, 11, cx - 7, 7, c_fire)
			_draw_line_px(img, cx + 4, 11, cx + 7, 7, c_fire)
			_fill_rect(img, cx - 2, 13, 2, 2, c_fire)
			_fill_rect(img, cx + 1, 13, 2, 2, c_fire)
			_draw_line_px(img, cx - 3, 32, cx - 5 + stride, 44, c_imp)
			_draw_line_px(img, cx + 3, 32, cx + 5 - stride, 44, c_imp)

		"skeleton":
			# 9. Restless Skeleton: Undead warrior with buckler & scimitar
			var c_bone := Color(1, 1, 1) if flash else Color(0.86, 0.82, 0.73)
			var c_bone_sh := Color(1, 1, 1) if flash else Color(0.58, 0.54, 0.46)
			var c_eye := Color(1.0, 0.18, 0.12)
			_fill_rect(img, cx - 3, 12, 7, 6, c_bone)
			_fill_rect(img, cx - 2, 18, 5, 2, c_bone_sh)
			_set_px(img, cx - 2, 15, c_eye)
			_set_px(img, cx + 2, 15, c_eye)
			_fill_rect(img, cx, 20, 2, 12, c_bone_sh)
			for r in range(4):
				_fill_rect(img, cx - 4, 21 + r * 2, 9, 1, c_bone)
			_fill_rect(img, cx - 3, 31, 7, 2, c_bone_sh)
			_draw_line_px(img, cx - 2, 33, cx - 4 + stride, 46, c_bone)
			_draw_line_px(img, cx + 2, 33, cx + 4 - stride, 46, c_bone)
			_fill_rect(img, cx - 9, 22, 5, 10, Color(0.38, 0.25, 0.15))
			_fill_rect(img, cx - 8, 23, 3, 8, Color(0.68, 0.52, 0.22))
			_draw_line_px(img, cx + 5, 26, cx + 15, 14 + stride, Color(0.78, 0.80, 0.86))

		"outcast":
			# 10. Heretic Outcast: Hooded rogue in forest-brown cloak with twin daggers
			var c_cloak := Color(1, 1, 1) if flash else Color(0.34, 0.24, 0.14)
			var c_tunic := Color(1, 1, 1) if flash else Color(0.22, 0.38, 0.18)
			var c_steel := Color(0.82, 0.86, 0.92)
			_fill_rect(img, cx - 4, 8, 9, 8, c_cloak)
			_fill_rect(img, cx - 2, 11, 5, 4, Color(0.76, 0.56, 0.42))
			_fill_rect(img, cx - 6, 16, 13, 16, c_tunic)
			_fill_rect(img, cx - 7, 16, 3, 18, c_cloak)
			_fill_rect(img, cx + 5, 16, 3, 18, c_cloak)
			_fill_rect(img, cx - 4 + stride, 32, 4, 15, c_cloak)
			_fill_rect(img, cx + 1 - stride, 32, 4, 15, c_cloak)
			_draw_line_px(img, cx - 8, 26, cx - 14, 19 + stride, c_steel)
			_draw_line_px(img, cx + 8, 26, cx + 14, 19 - stride, c_steel)

		"zealan_monk":
			# 11. Fallen Zealan Fanatic: Saffron-gold & violet robed cultist with ritual staff
			var c_robe := Color(1, 1, 1) if flash else Color(0.46, 0.18, 0.54)
			var c_saffron := Color(0.92, 0.72, 0.18)
			for y in range(15, 47):
				var hw: int = 4 + int(float(y - 15) * 0.24)
				_fill_rect(img, cx - hw, y, hw * 2 + 1, 1, c_robe)
			_fill_rect(img, cx - 2, 16, 5, 28, c_saffron)
			_fill_rect(img, cx - 4, 8, 9, 8, c_saffron)
			_set_px(img, cx - 2, 12, Color(0.2, 0.9, 1.0))
			_set_px(img, cx + 2, 12, Color(0.2, 0.9, 1.0))
			_draw_line_px(img, cx + 7, 46, cx + 9, 8, Color(0.55, 0.36, 0.18))
			_fill_rect(img, cx + 7, 6, 5, 5, Color(0.35, 0.92, 0.98))

		"necromancer":
			# 12. Scion of Lithos: Earthen-brown Necromancer in skull mask with bone staff
			var c_robe := Color(1, 1, 1) if flash else Color(0.26, 0.20, 0.14)
			var c_bone := Color(0.88, 0.84, 0.74)
			var c_emerald := Color(0.22, 0.92, 0.38)
			for y in range(15, 48):
				var hw: int = 5 + int(float(y - 15) * 0.25)
				_fill_rect(img, cx - hw, y, hw * 2 + 1, 1, c_robe)
			_fill_rect(img, cx - 4, 8, 9, 8, c_bone)
			_set_px(img, cx - 2, 11, c_emerald)
			_set_px(img, cx + 2, 11, c_emerald)
			_draw_line_px(img, cx - 8, 46, cx - 10, 9, c_bone)
			_fill_rect(img, cx - 12, 6, 5, 5, c_emerald)

		"theurgist":
			# 13. Acolyte of Stratos: Azure & silver robed Wind Theurgist with lightning orb
			var c_azure := Color(1, 1, 1) if flash else Color(0.18, 0.46, 0.82)
			var c_silver := Color(0.86, 0.90, 0.96)
			for y in range(15, 47):
				var hw: int = 4 + int(float(y - 15) * 0.25)
				_fill_rect(img, cx - hw, y, hw * 2 + 1, 1, c_azure)
			_fill_rect(img, cx - 2, 16, 5, 29, c_silver)
			_fill_rect(img, cx - 4, 8, 9, 8, c_silver)
			_set_px(img, cx - 2, 12, Color(0.2, 0.8, 1.0))
			_set_px(img, cx + 2, 12, Color(0.2, 0.8, 1.0))
			_fill_rect(img, cx + 8, 18 + stride, 6, 6, Color(0.45, 0.95, 1.0))

		"tempest_guard":
			# 14. Mordea's Palace Guard: Teal-and-steel armored Tenebrae halberdier
			var c_teal := Color(1, 1, 1) if flash else Color(0.14, 0.44, 0.48)
			var c_steel := Color(1, 1, 1) if flash else Color(0.64, 0.68, 0.76)
			var c_gold := Color(0.90, 0.72, 0.22)
			_fill_rect(img, cx - 4, 7, 9, 8, c_steel)
			_fill_rect(img, cx - 2, 5, 5, 3, c_teal) # Plume
			_fill_rect(img, cx - 6, 15, 13, 16, c_teal)
			_fill_rect(img, cx - 8, 15, 3, 5, c_gold)
			_fill_rect(img, cx + 6, 15, 3, 5, c_gold)
			_fill_rect(img, cx - 4 + stride, 31, 4, 16, c_steel)
			_fill_rect(img, cx + 1 - stride, 31, 4, 16, c_steel)
			_draw_line_px(img, cx + 8, 46, cx + 10, 5, Color(0.45, 0.30, 0.16))
			_fill_rect(img, cx + 8, 6, 6, 9, c_steel)

		"sorcerer":
			# 15. Cabal Sorcerer of Pyros: Crimson-and-black hooded mage with flaming rod
			var c_blk := Color(1, 1, 1) if flash else Color(0.14, 0.08, 0.12)
			var c_red := Color(0.92, 0.16, 0.14)
			var c_fire := Color(1.0, 0.78, 0.18)
			for y in range(14, 48):
				var hw: int = 5 + int(float(y - 14) * 0.26)
				_fill_rect(img, cx - hw, y, hw * 2 + 1, 1, c_blk)
				_set_px(img, cx - hw, y, c_red)
				_set_px(img, cx + hw, y, c_red)
			_fill_rect(img, cx - 4, 7, 9, 8, c_red)
			_set_px(img, cx - 2, 11, c_fire)
			_set_px(img, cx + 2, 11, c_fire)
			_draw_line_px(img, cx + 7, 42, cx + 13, 10, c_red)
			_fill_rect(img, cx + 10, 6, 7, 7, c_fire)

		"troll":
			# 16. Cave Troll of Carthax: Hulking mossy-green brute with massive stone club
			var c_troll := Color(1, 1, 1) if flash else Color(0.28, 0.44, 0.22)
			var c_troll_hi := Color(1, 1, 1) if flash else Color(0.40, 0.58, 0.30)
			var c_club := Color(0.42, 0.30, 0.18)
			_fill_rect(img, cx - 9, 14, 19, 19, c_troll)
			_fill_rect(img, cx - 7, 16, 15, 14, c_troll_hi)
			_fill_rect(img, cx - 5, 7, 11, 8, c_troll_hi)
			_fill_rect(img, cx - 3, 10, 2, 2, Color(1.0, 0.3, 0.1))
			_fill_rect(img, cx + 2, 10, 2, 2, Color(1.0, 0.3, 0.1))
			_fill_rect(img, cx - 7 + stride, 33, 6, 15, c_troll)
			_fill_rect(img, cx + 2 - stride, 33, 6, 15, c_troll)
			_fill_rect(img, cx + 10, 10 + stride, 7, 22, c_club)

		"gargoyle":
			# 17. Winged Obsidian Gargoyle: Horned stone fiend with bat wings & talons
			var c_stone := Color(1, 1, 1) if flash else Color(0.38, 0.41, 0.48)
			var c_wing := Color(1, 1, 1) if flash else Color(0.24, 0.26, 0.32)
			_fill_rect(img, cx - 16, 11 + stride, 10, 16, c_wing)
			_fill_rect(img, cx + 7, 11 - stride, 10, 16, c_wing)
			_fill_rect(img, cx - 6, 15, 13, 16, c_stone)
			_fill_rect(img, cx - 4, 8, 9, 7, c_stone)
			_draw_line_px(img, cx - 4, 8, cx - 8, 3, Color(0.75, 0.78, 0.84))
			_draw_line_px(img, cx + 4, 8, cx + 8, 3, Color(0.75, 0.78, 0.84))
			_set_px(img, cx - 2, 11, Color(1.0, 0.45, 0.1))
			_set_px(img, cx + 2, 11, Color(1.0, 0.45, 0.1))
			_fill_rect(img, cx - 5 + stride, 31, 4, 15, c_stone)
			_fill_rect(img, cx + 2 - stride, 31, 4, 15, c_stone)

		"water_lurker":
			# 18. Spawn of the Lurker: Tentacled deep-sea horror of Hydros
			var c_sea := Color(1, 1, 1) if flash else Color(0.12, 0.48, 0.56)
			var c_fin := Color(1, 1, 1) if flash else Color(0.28, 0.82, 0.76)
			_fill_rect(img, cx - 8, 14, 17, 18, c_sea)
			_fill_rect(img, cx - 5, 10, 11, 6, c_fin)
			_fill_rect(img, cx - 4, 17, 3, 3, Color(1.0, 0.92, 0.24))
			_fill_rect(img, cx + 2, 17, 3, 3, Color(1.0, 0.92, 0.24))
			for i in range(-3, 4):
				_draw_line_px(img, cx + i * 2, 32, cx + i * 3 + stride, 47, c_fin if i % 2 == 0 else c_sea)

		"earth_golem":
			# 19. Golem of Lithos: Massive granite boulder construct with glowing emerald core
			var c_rock := Color(1, 1, 1) if flash else Color(0.46, 0.38, 0.28)
			var c_rock_d := Color(1, 1, 1) if flash else Color(0.32, 0.26, 0.18)
			var c_gem := Color(0.20, 0.96, 0.42)
			_fill_rect(img, cx - 10, 12, 21, 20, c_rock_d)
			_fill_rect(img, cx - 8, 14, 17, 16, c_rock)
			_fill_rect(img, cx - 6, 6, 13, 8, c_rock)
			_fill_rect(img, cx - 3, 20, 7, 6, c_gem) # Emerald heart
			_fill_rect(img, cx - 3, 9, 2, 2, c_gem)
			_fill_rect(img, cx + 2, 9, 2, 2, c_gem)
			_fill_rect(img, cx - 8 + stride, 32, 7, 16, c_rock_d)
			_fill_rect(img, cx + 2 - stride, 32, 7, 16, c_rock_d)

		"aerial_servant":
			# 20. Whirlwind Elemental: Swirling cyclone spirit of Stratos
			var c_wind1 := Color(1, 1, 1) if flash else Color(0.55, 0.88, 1.0)
			var c_wind2 := Color(1, 1, 1) if flash else Color(0.85, 0.96, 1.0)
			for y in range(8, 48):
				var span: int = 12 - int(float(y - 8) * 0.24)
				var shift: int = int(sin(float(y) * 0.5 + float(anim_phase) * 1.5) * 3.0)
				_fill_rect(img, cx - span + shift, y, span * 2, 1, c_wind2 if y % 3 == 0 else c_wind1)
			_fill_rect(img, cx - 4, 14, 3, 2, Color(1.0, 1.0, 0.4))
			_fill_rect(img, cx + 2, 14, 3, 2, Color(1.0, 1.0, 0.4))

		"hellhound":
			# 21. Brimstone Hellhound: Quadruped magma mastiff with fiery mane
			var c_coat := Color(1, 1, 1) if flash else Color(0.32, 0.08, 0.06)
			var c_mane := Color(1.0, 0.52, 0.10)
			_fill_rect(img, cx - 12, 26, 24, 11, c_coat)
			_fill_rect(img, cx - 14, 20, 10, 9, c_coat)
			_fill_rect(img, cx - 9, 19, 8, 7, c_mane)
			_set_px(img, cx - 12, 22, Color(1.0, 0.95, 0.25))
			_fill_rect(img, cx - 11 + stride, 37, 4, 11, c_coat)
			_fill_rect(img, cx - 5 - stride, 37, 4, 11, c_coat)
			_fill_rect(img, cx + 4 + stride, 37, 4, 11, c_coat)
			_fill_rect(img, cx + 9 - stride, 37, 4, 11, c_coat)
			_draw_line_px(img, cx + 11, 27, cx + 17, 21 + stride, c_mane)

		"daemon":
			# 22. Greater Daemon of Pyros: Towering horned crimson winged fiend
			var c_red := Color(1, 1, 1) if flash else Color(0.78, 0.12, 0.10)
			var c_dark := Color(0.24, 0.04, 0.06)
			var c_flame := Color(1.0, 0.82, 0.20)
			_fill_rect(img, cx - 17, 8 + stride, 11, 20, c_dark)
			_fill_rect(img, cx + 7, 8 - stride, 11, 20, c_dark)
			_fill_rect(img, cx - 7, 14, 15, 18, c_red)
			_fill_rect(img, cx - 5, 6, 11, 8, c_red)
			_draw_line_px(img, cx - 5, 6, cx - 10, 1, c_flame)
			_draw_line_px(img, cx + 5, 6, cx + 10, 1, c_flame)
			_fill_rect(img, cx - 3, 9, 2, 2, c_flame)
			_fill_rect(img, cx + 2, 9, 2, 2, c_flame)
			_fill_rect(img, cx - 6 + stride, 32, 5, 16, c_red)
			_fill_rect(img, cx + 2 - stride, 32, 5, 16, c_red)
			_draw_line_px(img, cx + 8, 30, cx + 18, 6 - stride, c_flame)

		"titan_boss":
			# 24. Malchir / Pyros Arch-Executioner Titan Boss Sprite
			var c_armor := Color(1, 0.8, 0.7) if flash else Color(0.18, 0.16, 0.22)
			var c_crimson := Color(1, 0.5, 0.4) if flash else Color(0.86, 0.12, 0.12)
			var c_gold := Color(0.98, 0.80, 0.24)
			var c_flame := Color(1.0, 0.48, 0.08)
			for y in range(11, 50):
				var hw: int = 6 + int(float(y - 11) * 0.32)
				_fill_rect(img, cx - hw, y, hw * 2 + 1, 1, c_armor)
				_set_px(img, cx - hw, y, c_crimson)
				_set_px(img, cx + hw, y, c_crimson)
				if y % 4 == 0:
					_set_px(img, cx - hw + 1, y, c_gold)
					_set_px(img, cx + hw - 1, y, c_gold)
			_fill_rect(img, cx - 12, 13, 6, 5, c_gold)
			_fill_rect(img, cx + 7, 13, 6, 5, c_gold)
			_fill_rect(img, cx - 13, 10, 2, 4, c_crimson)
			_fill_rect(img, cx + 12, 10, 2, 4, c_crimson)
			_fill_rect(img, cx - 4, 16, 9, 26, c_crimson)
			_fill_rect(img, cx - 2, 18, 5, 3, c_gold)
			_fill_rect(img, cx - 1, 16, 3, 12, c_gold)
			_fill_rect(img, cx - 5, 5, 11, 9, Color(0.32, 0.35, 0.42))
			_draw_line_px(img, cx - 5, 7, cx - 9, 2, c_gold)
			_draw_line_px(img, cx + 5, 7, cx + 9, 2, c_gold)
			_fill_rect(img, cx - 3, 9, 2, 2, Color(1.0, 0.88, 0.24))
			_fill_rect(img, cx + 2, 9, 2, 2, Color(1.0, 0.88, 0.24))
			_draw_line_px(img, cx + 8, 36, cx + 18, 5 + stride, c_gold)
			_fill_rect(img, cx + 14, 5 + stride, 7, 14, c_flame)
			_fill_rect(img, cx + 16, 6 + stride, 3, 11, Color(1.0, 0.94, 0.42))

		_:
			# 23. Tenebrae High Executioner (Default / "executioner")
			var c_robe := Color(1, 0.7, 0.7) if flash else Color(0.24, 0.25, 0.30)
			var c_trim := Color(0.82, 0.14, 0.14)
			var c_gold := Color(0.88, 0.68, 0.22)
			var c_hood := Color(0.38, 0.40, 0.46)
			for y in range(14, 48):
				var hw: int = 4 + int(float(y - 14) * 0.26)
				_fill_rect(img, cx - hw, y, hw * 2 + 1, 1, c_robe)
				_set_px(img, cx - hw, y, c_trim)
				_set_px(img, cx + hw, y, c_trim)
			_fill_rect(img, cx - 3, 17, 7, 22, c_trim)
			_fill_rect(img, cx - 3, 25, 7, 2, c_gold)
			_fill_rect(img, cx - 4, 7, 9, 8, c_hood)
			_set_px(img, cx - 2, 11, Color(1.0, 0.25, 0.12))
			_set_px(img, cx + 2, 11, Color(1.0, 0.25, 0.12))
			_draw_line_px(img, cx + 5, 32, cx + 16, 8 + stride, Color(0.48, 0.34, 0.20))
			_fill_rect(img, cx + 12, 9 + stride, 7, 9, Color(0.75, 0.78, 0.84))
			_fill_rect(img, cx + 17, 8 + stride, 2, 11, Color(0.90, 0.18, 0.18))

	_add_outline(img)
	return ImageTexture.create_from_image(img)

static func _build_prop_texture(p_type: String, state: int, frame: int) -> ImageTexture:
	var img: Image = Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: int = 24
	var by: int = 56

	match p_type:
		"brazier":
			# Matches both the glowing yellow wrought-iron lanterns & red-brick hearth fire in the screenshot!
			_fill_rect(img, cx - 8, by - 7, 17, 7, Color(0.46, 0.49, 0.56))
			_fill_rect(img, cx - 10, by - 16, 21, 9, Color(0.48, 0.22, 0.16)) # Red-brown brick hearth/basin
			_fill_rect(img, cx - 9, by - 15, 19, 2, Color(0.84, 0.64, 0.20) if state >= 2 else Color(0.62, 0.65, 0.72))
			if state == 1 or state == 3:
				var shift: int = (frame % 3) - 1
				_fill_rect(img, cx - 7, by - 23, 15, 8, Color(0.92, 0.28, 0.06))
				_fill_rect(img, cx - 5 + shift, by - 31, 11, 9, Color(1.0, 0.62, 0.12))
				_fill_rect(img, cx - 3 + shift, by - 37, 7, 14, Color(1.0, 0.94, 0.36))

		"chest":
			# Exact match to the domed dark-grey/brown treasure chest with heavy curved GOLD bands in top-left of screenshot!
			var c_body_d := Color(0.24, 0.21, 0.19)
			var c_body_m := Color(0.35, 0.31, 0.28)
			var c_gold_d := Color(0.58, 0.40, 0.10)
			var c_gold_m := Color(0.82, 0.62, 0.18)
			var c_gold_h := Color(0.98, 0.82, 0.32)
			# Chest lower box
			_fill_rect(img, cx - 13, by - 13, 26, 13, c_body_d)
			_fill_rect(img, cx - 12, by - 12, 24, 11, c_body_m)
			# Domed chest lid
			if state == 1:
				_fill_rect(img, cx - 13, by - 23, 26, 9, Color(0.16, 0.12, 0.10))
				_fill_rect(img, cx - 9, by - 14, 18, 4, c_gold_h)
			else:
				_fill_rect(img, cx - 12, by - 18, 24, 6, c_body_m)
				_fill_rect(img, cx - 10, by - 20, 20, 3, Color(0.44, 0.39, 0.35))
			# Heavy gold/brass straps & corner rivets (like screenshot)
			_fill_rect(img, cx - 13, by - 18, 3, 18, c_gold_m)
			_fill_rect(img, cx + 10, by - 18, 3, 18, c_gold_m)
			_fill_rect(img, cx - 12, by - 18, 1, 17, c_gold_h)
			_fill_rect(img, cx + 11, by - 18, 1, 17, c_gold_h)
			_fill_rect(img, cx - 13, by - 13, 26, 2, c_gold_d)
			_fill_rect(img, cx - 13, by - 2, 26, 2, c_gold_m)
			# Central gold lockplate
			_fill_rect(img, cx - 3, by - 14, 6, 7, c_gold_m)
			_fill_rect(img, cx - 2, by - 13, 4, 5, c_gold_h)
			_set_px(img, cx, by - 11, Color(0.1, 0.08, 0.06))

		"corpse":
			_fill_rect(img, cx - 14, by - 5, 28, 5, Color(0.46, 0.06, 0.06))
			_fill_rect(img, cx - 10, by - 9, 16, 6, Color(0.48, 0.51, 0.58))
			_fill_rect(img, cx - 15, by - 10, 8, 6, Color(0.74, 0.14, 0.12))
			_fill_rect(img, cx + 6, by - 8, 5, 5, Color(0.84, 0.64, 0.22))
			if state == 0 and (frame % 2 == 0):
				_fill_rect(img, cx - 4, by - 3, 4, 3, Color(1.0, 0.90, 0.35))

		"plaque":
			_fill_rect(img, cx - 9, by - 34, 19, 34, Color(0.46, 0.49, 0.56))
			_fill_rect(img, cx - 8, by - 33, 17, 32, Color(0.58, 0.61, 0.68))
			_fill_rect(img, cx - 7, by - 37, 15, 5, Color(0.68, 0.71, 0.78))
			for r in range(4):
				_fill_rect(img, cx - 5, by - 28 + r * 5, 11, 2, Color(0.28, 0.30, 0.36))

		"gate":
			# Exact match to the heavy Tenebrae Doors in the screenshot:
			# White cut-stone side pilasters, dark charcoal/brown timber-iron door, and large round GOLD RING HANDLE!
			var lift: int = 34 if state == 1 else 0
			# White/light-grey stone door pilasters on left and right
			_fill_rect(img, cx - 16, 10, 5, 46, Color(0.72, 0.75, 0.82))
			_fill_rect(img, cx - 15, 10, 3, 45, Color(0.84, 0.87, 0.92))
			_fill_rect(img, cx + 11, 10, 5, 46, Color(0.64, 0.67, 0.74))
			_fill_rect(img, cx + 12, 10, 3, 45, Color(0.76, 0.79, 0.86))
			# Heavy dark door slab (lifts up when opened)
			var door_h: int = maxi(4, 44 - lift)
			_fill_rect(img, cx - 11, 12, 22, door_h, Color(0.22, 0.20, 0.18))
			_fill_rect(img, cx - 10, 13, 20, door_h - 2, Color(0.29, 0.27, 0.24))
			# Vertical plank seams
			for px in range(cx - 6, cx + 10, 5):
				_fill_rect(img, px, 13, 1, door_h - 2, Color(0.15, 0.13, 0.11))
			# Large brass/gold ring handle on the right side of the door (just like the screenshot!)
			if state == 0:
				var rx: int = cx + 5
				var ry: int = 34
				_fill_rect(img, rx - 3, ry - 3, 7, 7, Color(0.82, 0.60, 0.18))
				_fill_rect(img, rx - 2, ry - 2, 5, 5, Color(0.96, 0.78, 0.28))
				_fill_rect(img, rx - 1, ry - 1, 3, 3, Color(0.29, 0.27, 0.24))

		"skulls":
			# Wooden Tavern Barrel + Skulls cache (matching the brown wooden barrel in the screenshot!)
			_fill_rect(img, cx - 8, by - 16, 16, 15, Color(0.36, 0.22, 0.11))
			_fill_rect(img, cx - 7, by - 15, 14, 13, Color(0.48, 0.30, 0.16))
			_fill_rect(img, cx - 8, by - 13, 16, 2, Color(0.22, 0.24, 0.28))
			_fill_rect(img, cx - 8, by - 6, 16, 2, Color(0.22, 0.24, 0.28))
			_fill_rect(img, cx + 5, by - 6, 6, 6, Color(0.84, 0.80, 0.70))

		"lever":
			_fill_rect(img, cx - 7, by - 6, 15, 6, Color(0.50, 0.53, 0.60))
			var lx: int = cx + 9 if state == 1 else cx - 9
			_draw_line_px(img, cx, by - 5, lx, by - 22, Color(0.75, 0.78, 0.84))
			_fill_rect(img, lx - 2, by - 24, 5, 5, Color(0.92, 0.72, 0.22))

		"sarcophagus":
			_fill_rect(img, cx - 15, by - 16, 30, 16, Color(0.48, 0.51, 0.58))
			_fill_rect(img, cx - 14, by - 15, 28, 14, Color(0.58, 0.61, 0.68))
			_fill_rect(img, cx - 13, by - 19, 26, 4, Color(0.68, 0.71, 0.78))
			if state == 0:
				_fill_rect(img, cx - 8, by - 13, 16, 4, Color(0.86, 0.66, 0.22))

		"pentagram_focus":
			if state == 1:
				_fill_rect(img, cx - 10, by - 12, 4, 10, Color(0.82, 0.14, 0.14))
				_fill_rect(img, cx + 6, by - 12, 4, 10, Color(0.82, 0.14, 0.14))
				_fill_rect(img, cx - 2, by - 16, 4, 10, Color(0.82, 0.14, 0.14))
				_fill_rect(img, cx - 10, by - 15, 4, 3, Color(1.0, 0.86, 0.28))
				_fill_rect(img, cx + 6, by - 15, 4, 3, Color(1.0, 0.86, 0.28))
				_fill_rect(img, cx - 2, by - 19, 4, 3, Color(1.0, 0.86, 0.28))
			else:
				_fill_rect(img, cx - 4, by - 3, 9, 3, Color(0.55, 0.10, 0.12))

		"obelisk":
			for y in range(6, by):
				var hw: int = 4 + int(float(y - 6) * 0.16)
				_fill_rect(img, cx - hw, y, hw * 2 + 1, 1, Color(0.18, 0.20, 0.26))
				var rim: Color = Color(0.95, 0.78, 0.28) if state == 1 else Color(0.52, 0.55, 0.62)
				_set_px(img, cx - hw, y, rim)
				_set_px(img, cx + hw, y, rim)
			if state == 1:
				var pulse_r: int = 5 + (frame % 3)
				_fill_rect(img, cx - pulse_r, 24 - pulse_r, pulse_r * 2, pulse_r * 2, Color(0.75, 0.22, 0.92))
				_fill_rect(img, cx - 3, 21, 6, 6, Color(1.0, 0.90, 0.45))

		"bush":
			# Lush Pagan roadside bush / shrubbery (exact match to screenshot greenery!)
			var c_leaf_d := Color(0.10, 0.24, 0.07)
			var c_leaf_m := Color(0.18, 0.39, 0.12)
			var c_leaf_h := Color(0.30, 0.56, 0.19)
			var c_leaf_b := Color(0.42, 0.68, 0.26)
			_fill_rect(img, cx - 14, by - 14, 28, 12, c_leaf_d)
			_fill_rect(img, cx - 12, by - 19, 24, 14, c_leaf_m)
			_fill_rect(img, cx - 9, by - 22, 18, 10, c_leaf_h)
			for bx in range(cx - 11, cx + 11, 3):
				for by_p in range(by - 20, by - 6, 3):
					if ((bx + by_p) % 2 == 0):
						_fill_rect(img, bx, by_p, 2, 2, c_leaf_b if by_p < by - 13 else c_leaf_h)

		"tree":
			# Tall Pagan Woodland Tree with gnarled trunk & layered canopy
			_fill_rect(img, cx - 4, by - 22, 8, 22, Color(0.26, 0.16, 0.09))
			_fill_rect(img, cx - 2, by - 22, 4, 21, Color(0.36, 0.23, 0.13))
			_fill_rect(img, cx - 6, by - 4, 12, 4, Color(0.22, 0.14, 0.08))
			var c_td := Color(0.09, 0.22, 0.06)
			var c_tm := Color(0.17, 0.37, 0.11)
			var c_th := Color(0.28, 0.54, 0.18)
			var c_tb := Color(0.40, 0.66, 0.25)
			_fill_rect(img, cx - 17, by - 36, 34, 18, c_td)
			_fill_rect(img, cx - 15, by - 44, 30, 22, c_tm)
			_fill_rect(img, cx - 11, by - 50, 22, 16, c_th)
			_fill_rect(img, cx - 7, by - 53, 14, 8, c_tb)
			for tx in range(cx - 13, cx + 12, 4):
				for ty in range(by - 48, by - 22, 4):
					_fill_rect(img, tx, ty, 2, 2, c_tb if ty < by - 36 else c_th)

		"table":
			# Wooden tavern table with cheese wheel, green wine bottle & pewter jug (from screenshot!)
			var c_wood_d := Color(0.32, 0.16, 0.08)
			var c_wood_m := Color(0.48, 0.25, 0.12)
			var c_wood_h := Color(0.62, 0.34, 0.17)
			# Table legs
			_fill_rect(img, cx - 11, by - 12, 3, 12, c_wood_d)
			_fill_rect(img, cx + 8, by - 12, 3, 12, c_wood_d)
			_fill_rect(img, cx - 6, by - 10, 3, 8, c_wood_d)
			_fill_rect(img, cx + 3, by - 10, 3, 8, c_wood_d)
			# Tabletop
			_fill_rect(img, cx - 13, by - 17, 26, 6, c_wood_m)
			_fill_rect(img, cx - 12, by - 16, 24, 4, c_wood_h)
			# Golden cheese wheel (left)
			_fill_rect(img, cx - 9, by - 21, 7, 5, Color(0.95, 0.78, 0.20))
			_fill_rect(img, cx - 8, by - 22, 5, 2, Color(1.0, 0.88, 0.36))
			# Green glass bottle (right)
			_fill_rect(img, cx + 3, by - 24, 5, 8, Color(0.14, 0.48, 0.18))
			_fill_rect(img, cx + 4, by - 27, 3, 3, Color(0.18, 0.58, 0.22))
			_set_px(img, cx + 4, by - 22, Color(0.65, 0.92, 0.65))
			# Pewter jug (center)
			_fill_rect(img, cx - 1, by - 22, 4, 6, Color(0.58, 0.62, 0.68))

	_add_outline(img)
	return ImageTexture.create_from_image(img)

static func _build_projectile_texture(from_player: bool, frame: int) -> ImageTexture:
	var img: Image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c_out: Color = Color(0.98, 0.36, 0.06) if from_player else Color(0.82, 0.14, 0.68)
	var c_in: Color = Color(1.0, 0.92, 0.36) if from_player else Color(0.98, 0.65, 1.0)
	var r_s: int = 5 + (frame % 2)
	_fill_rect(img, 10 - r_s, 10 - r_s, r_s * 2, r_s * 2, c_out)
	_fill_rect(img, 7, 7, 6, 6, c_in)
	_add_outline(img)
	return ImageTexture.create_from_image(img)

static func _build_item_texture(item_id: String) -> ImageTexture:
	var img: Image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match item_id:
		"iron_key":
			_fill_rect(img, 5, 8, 6, 6, Color(0.86, 0.68, 0.24))
			_fill_rect(img, 7, 10, 2, 2, Color(0, 0, 0, 0))
			_fill_rect(img, 11, 10, 9, 2, Color(0.86, 0.68, 0.24))
			_fill_rect(img, 16, 12, 2, 3, Color(0.86, 0.68, 0.24))
			_fill_rect(img, 19, 12, 2, 4, Color(0.86, 0.68, 0.24))
		"red_potion":
			_fill_rect(img, 10, 4, 4, 4, Color(0.65, 0.50, 0.32))
			_fill_rect(img, 7, 8, 10, 11, Color(0.88, 0.16, 0.16))
			_fill_rect(img, 9, 10, 3, 6, Color(1.0, 0.55, 0.55))
		"blue_potion":
			_fill_rect(img, 10, 4, 4, 4, Color(0.65, 0.50, 0.32))
			_fill_rect(img, 7, 8, 10, 11, Color(0.18, 0.48, 0.92))
			_fill_rect(img, 9, 10, 3, 6, Color(0.55, 0.82, 1.0))
		"flame_blade":
			_draw_line_px(img, 5, 19, 19, 5, Color(1.0, 0.50, 0.10))
			_draw_line_px(img, 6, 19, 20, 5, Color(1.0, 0.88, 0.30))
			_fill_rect(img, 5, 16, 5, 2, Color(0.85, 0.68, 0.22))
		"ignis_scroll":
			_fill_rect(img, 6, 5, 12, 14, Color(0.88, 0.78, 0.56))
			_fill_rect(img, 8, 8, 8, 2, Color(0.92, 0.25, 0.12))
			_fill_rect(img, 8, 12, 6, 2, Color(0.92, 0.25, 0.12))
		"ritual_candle":
			_fill_rect(img, 9, 9, 6, 11, Color(0.82, 0.14, 0.18))
			_fill_rect(img, 10, 4, 4, 5, Color(1.0, 0.82, 0.24))
		"grimoire":
			_fill_rect(img, 5, 4, 14, 16, Color(0.28, 0.08, 0.22))
			_fill_rect(img, 6, 5, 12, 14, Color(0.45, 0.12, 0.34))
			_fill_rect(img, 9, 8, 6, 6, Color(0.92, 0.22, 0.26))
	_add_outline(img)
	return ImageTexture.create_from_image(img)

static func export_sprites_to_assets() -> void:
	var dir_path: String = ProjectSettings.globalize_path("res://assets/sprites")
	DirAccess.make_dir_recursive_absolute(dir_path)
	get_avatar_sprite(2, 0, false, false, false, false, false).get_image().save_png(dir_path + "/avatar.png")
	get_avatar_sprite(2, 1, false, true, true, false, true).get_image().save_png(dir_path + "/avatar_combat.png")
	get_enemy_sprite("skeleton", 1, false).get_image().save_png(dir_path + "/skeleton.png")
	get_enemy_sprite("executioner", 1, false).get_image().save_png(dir_path + "/executioner.png")
	get_prop_sprite("brazier", 3, 0).get_image().save_png(dir_path + "/brazier.png")
	get_prop_sprite("obelisk", 1, 0).get_image().save_png(dir_path + "/obelisk.png")
	get_tile_sprite(LevelData.TileType.OBSIDIAN_FLOOR, 0, 0).get_image().save_png(dir_path + "/tile_obsidian.png")
