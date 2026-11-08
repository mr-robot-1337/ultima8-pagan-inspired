class_name LevelData
extends RefCounted

enum TileType {
	WATER = 0,
	LAVA = 1,
	OBSIDIAN_FLOOR = 2,
	COBBLE_FLOOR = 3,
	PILLAR_STONE = 4,
	CRUMBLING_STONE = 5,
	BRIDGE_SUNKEN = 6,
	BRIDGE_RAISED = 7,
	PENTAGRAM_FLOOR = 8,
	STAIRS = 9,
	WALL_BLOCK = 10,
	GRASS_FLOOR = 11
}

# 72 x 72 = 5,184 tiles (~10.7x the area of the original 22 x 22 = 484 tile map!)
const MAP_W: int = 72
const MAP_H: int = 72
const MAX_LEVELS: int = 666

const REALM_PREFIXES: Array[String] = [
	"The Cobblestone",
	"The Verdant",
	"The Outlying",
	"The Misty",
	"The Forsaken",
	"The Crimson",
	"The Zealan",
	"The Highland",
	"The Twilight",
	"The Ancient"
]

const REALM_PLACES: Array[String] = [
	"Streets",
	"Outskirts",
	"Crossroads",
	"Commons",
	"Highlands",
	"Village",
	"Courtyards",
	"Hamlet",
	"Wilds",
	"Borough"
]

const REALM_LORDS: Array[String] = [
	"of Tenebrae",
	"of Pagan",
	"of Lithos",
	"of Malchir",
	"of Pyros",
	"of Hydros",
	"of Stratos",
	"of Mordea",
	"of the Wilds",
	"of the Avatar"
]

# 23 Distinct Regular/Elite Enemy Types (+ 24th Titan Boss) — Every single enemy has a unique HP value, Sprite & Death SFX!
const ENEMY_CATALOG: Array[Dictionary] = [
	{"type": "kith", "name": "Swamp Kith", "hp": 28, "damage": 8, "speed": 2.35, "ranged": false},
	{"type": "changeling", "name": "Morphing Changeling", "hp": 34, "damage": 9, "speed": 2.40, "ranged": false},
	{"type": "seeker", "name": "Floating Seeker Eye", "hp": 38, "damage": 10, "speed": 2.20, "ranged": true},
	{"type": "torax", "name": "Torax Hive Drone", "hp": 44, "damage": 10, "speed": 2.45, "ranged": false},
	{"type": "ghoul", "name": "Catacomb Ghoul", "hp": 50, "damage": 11, "speed": 2.15, "ranged": false},
	{"type": "zombie", "name": "Risen Pagan Zombie", "hp": 56, "damage": 12, "speed": 1.85, "ranged": false},
	{"type": "ghost", "name": "Wailing Ghost of Tenebrae", "hp": 62, "damage": 12, "speed": 2.25, "ranged": false},
	{"type": "fire_imp", "name": "Pyros Fire Imp", "hp": 66, "damage": 13, "speed": 2.30, "ranged": true},
	{"type": "skeleton", "name": "Restless Skeleton", "hp": 72, "damage": 13, "speed": 2.10, "ranged": false},
	{"type": "outcast", "name": "Heretic Outcast", "hp": 78, "damage": 14, "speed": 2.30, "ranged": false},
	{"type": "zealan_monk", "name": "Fallen Zealan Fanatic", "hp": 84, "damage": 14, "speed": 2.10, "ranged": false},
	{"type": "necromancer", "name": "Scion of Lithos", "hp": 90, "damage": 15, "speed": 2.05, "ranged": true},
	{"type": "theurgist", "name": "Acolyte of Stratos", "hp": 96, "damage": 15, "speed": 2.15, "ranged": true},
	{"type": "tempest_guard", "name": "Mordea's Palace Guard", "hp": 104, "damage": 16, "speed": 2.15, "ranged": false},
	{"type": "sorcerer", "name": "Cabal Sorcerer of Pyros", "hp": 112, "damage": 16, "speed": 2.10, "ranged": true},
	{"type": "troll", "name": "Cave Troll of Carthax", "hp": 122, "damage": 18, "speed": 1.90, "ranged": false},
	{"type": "gargoyle", "name": "Winged Obsidian Gargoyle", "hp": 132, "damage": 17, "speed": 2.25, "ranged": false},
	{"type": "water_lurker", "name": "Spawn of the Lurker", "hp": 142, "damage": 18, "speed": 2.05, "ranged": false},
	{"type": "earth_golem", "name": "Golem of Lithos", "hp": 154, "damage": 20, "speed": 1.80, "ranged": false},
	{"type": "aerial_servant", "name": "Whirlwind Elemental", "hp": 165, "damage": 17, "speed": 2.40, "ranged": true},
	{"type": "hellhound", "name": "Brimstone Hellhound", "hp": 176, "damage": 19, "speed": 2.45, "ranged": false},
	{"type": "executioner", "name": "Tenebrae High Executioner", "hp": 190, "damage": 20, "speed": 2.20, "ranged": true},
	{"type": "daemon", "name": "Greater Daemon of Pyros", "hp": 215, "damage": 22, "speed": 2.30, "ranged": true}
]

static func get_level_title(level_num: int, rng: RandomNumberGenerator) -> String:
	if level_num == 6:
		return "The Grand Citadel of Malchir (BOSS)"
	if level_num == MAX_LEVELS:
		return "The 666th Outdoor Citadel of Pagan (FINAL BOSS)"
	if is_boss_level(level_num):
		var lord: String = REALM_LORDS[(level_num / 6) % REALM_LORDS.size()]
		return "Boss Citadel " + str(level_num) + " " + lord
	var p_idx: int = rng.randi_range(0, REALM_PREFIXES.size() - 1)
	var n_idx: int = rng.randi_range(0, REALM_PLACES.size() - 1)
	var l_idx: int = rng.randi_range(0, REALM_LORDS.size() - 1)
	return REALM_PREFIXES[p_idx] + " " + REALM_PLACES[n_idx] + " " + REALM_LORDS[l_idx]

static func is_boss_level(level_num: int) -> bool:
	return level_num == 6 or level_num == MAX_LEVELS or (level_num % 6 == 0)

static func build_level(level_num: int = 1, custom_seed: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if custom_seed >= 0:
		rng.seed = custom_seed
	else:
		rng.randomize()

	var clamped_lvl: int = clampi(level_num, 1, MAX_LEVELS)
	if is_boss_level(clamped_lvl):
		return _build_boss_level(rng, clamped_lvl)
	return _build_procedural_level(rng, clamped_lvl)

static func _create_empty_tiles(rng: RandomNumberGenerator, default_type: int, default_z: float = 0.0) -> Array:
	var tiles: Array = []
	tiles.resize(MAP_W)
	var seed_off: int = rng.randi_range(0, 999)
	for x in range(MAP_W):
		var col: Array = []
		col.resize(MAP_H)
		for y in range(MAP_H):
			col[y] = {
				"type": default_type,
				"z": default_z,
				"base_z": default_z,
				"crumble_timer": 0.0,
				"crumbled": false,
				"variant": (x * 7 + y * 13 + seed_off) % 4
			}
		tiles[x] = col
	return tiles

static func _paint_transformed_rect(
	tiles: Array,
	x0: int,
	y0: int,
	x1: int,
	y1: int,
	t_type: int,
	z_val: float,
	mirror_x: bool,
	mirror_y: bool,
	swap_xy: bool
) -> void:
	var min_x: int = maxi(0, mini(x0, x1))
	var max_x: int = mini(MAP_W - 1, maxi(x0, x1))
	var min_y: int = maxi(0, mini(y0, y1))
	var max_y: int = mini(MAP_H - 1, maxi(y0, y1))
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var tx: int = (MAP_W - 1 - x) if mirror_x else x
			var ty: int = (MAP_H - 1 - y) if mirror_y else y
			var fx: int = ty if swap_xy else tx
			var fy: int = tx if swap_xy else ty
			if fx >= 0 and fx < MAP_W and fy >= 0 and fy < MAP_H:
				tiles[fx][fy]["type"] = t_type
				tiles[fx][fy]["z"] = z_val
				tiles[fx][fy]["base_z"] = z_val

static func _tx_vec3(v: Vector3, mirror_x: bool, mirror_y: bool, swap_xy: bool) -> Vector3:
	var x: float = (float(MAP_W) - v.x) if mirror_x else v.x
	var y: float = (float(MAP_H) - v.y) if mirror_y else v.y
	if swap_xy:
		return Vector3(y, x, v.z)
	return Vector3(x, y, v.z)

static func _tx_cell(c: Vector2i, mirror_x: bool, mirror_y: bool, swap_xy: bool) -> Vector2i:
	var x: int = (MAP_W - 1 - c.x) if mirror_x else c.x
	var y: int = (MAP_H - 1 - c.y) if mirror_y else c.y
	if swap_xy:
		return Vector2i(y, x)
	return Vector2i(x, y)

static func _build_cutaway_house(
	tiles: Array,
	hx0: int,
	hy0: int,
	hx1: int,
	hy1: int,
	floor_z: float,
	door_side: String,
	mirror_x: bool,
	mirror_y: bool,
	swap_xy: bool
) -> void:
	# Light-grey stone flagstone interior floor (matching the Tenebrae screenshot!)
	_paint_transformed_rect(tiles, hx0, hy0, hx1, hy1, TileType.OBSIDIAN_FLOOR, floor_z, mirror_x, mirror_y, swap_xy)
	var wall_z: float = floor_z + 1.85
	var mid_x: int = (hx0 + hx1) / 2
	var mid_y: int = (hy0 + hy1) / 2

	# Perimeter cut-away grey stone masonry walls with doorway openings
	_paint_transformed_rect(tiles, hx0, hy0, hx1, hy0, TileType.WALL_BLOCK, wall_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, hx0, hy1, hx1, hy1, TileType.WALL_BLOCK, wall_z - 0.25, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, hx0, hy0, hx0, hy1, TileType.WALL_BLOCK, wall_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, hx1, hy0, hx1, hy1, TileType.WALL_BLOCK, wall_z - 0.25, mirror_x, mirror_y, swap_xy)

	# Carve wide doorway gap on the requested side so the Avatar can walk inside freely
	match door_side:
		"east":
			_paint_transformed_rect(tiles, hx1, mid_y - 1, hx1, mid_y + 1, TileType.OBSIDIAN_FLOOR, floor_z, mirror_x, mirror_y, swap_xy)
		"west":
			_paint_transformed_rect(tiles, hx0, mid_y - 1, hx0, mid_y + 1, TileType.OBSIDIAN_FLOOR, floor_z, mirror_x, mirror_y, swap_xy)
		"south":
			_paint_transformed_rect(tiles, mid_x - 1, hy1, mid_x + 1, hy1, TileType.OBSIDIAN_FLOOR, floor_z, mirror_x, mirror_y, swap_xy)
		"north":
			_paint_transformed_rect(tiles, mid_x - 1, hy0, mid_x + 1, hy0, TileType.OBSIDIAN_FLOOR, floor_z, mirror_x, mirror_y, swap_xy)

static func _build_procedural_level(rng: RandomNumberGenerator, level_num: int) -> Dictionary:
	var title: String = get_level_title(level_num, rng)

	# Full 8-way dihedral symmetry + 5 outdoor archetypes + randomized coordinates across a massive 72x72 (10x larger) world!
	var mirror_x: bool = (rng.randi() % 2 == 1)
	var mirror_y: bool = (rng.randi() % 2 == 1)
	var swap_xy: bool = (rng.randi() % 2 == 1)
	var archetype: int = rng.randi_range(0, 4)

	var base_elev: float = 1.0 + float(rng.randi_range(0, 3)) * 0.08
	var hazard_liquid: int = TileType.LAVA if (archetype == 4 or (level_num > 3 and rng.randf() < 0.28)) else TileType.WATER

	# 0. Start with a sprawling 72x72 outdoor Pagan landscape: lush emerald GRASS_FLOOR bordered by coastal river/sea!
	var tiles: Array = _create_empty_tiles(rng, hazard_liquid, 0.0)
	_paint_transformed_rect(tiles, 2, 2, MAP_W - 3, MAP_H - 3, TileType.GRASS_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)

	# Randomize layout shifts for the 5 Districts
	var s_shift_x: int = rng.randi_range(-4, 5)
	var m_shift_x: int = rng.randi_range(-4, 5)
	var n_shift_x: int = rng.randi_range(-4, 5)
	var canal_y: int = rng.randi_range(23, 27)
	var east_creek_x: int = rng.randi_range(42, 46)
	var gate_y: int = rng.randi_range(47, 50)

	# 1. Carve Major Outdoor Rivers, Canals, Lakes & Coastal Bays across the 72x72 Grasslands
	# Main East-West Canal separating the Central Town Commons from the Northern Sanctum Borough
	_paint_transformed_rect(tiles, 0, canal_y, MAP_W - 1, canal_y + 4, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
	# East River Gorge separating the Town Commons from the Eastern Watchtower Estate & Islands
	_paint_transformed_rect(tiles, east_creek_x, canal_y + 4, east_creek_x + 4, MAP_H - 1, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)

	# Archetype-specific outdoor lakes, ponds, and volcanic fissures
	if archetype == 0 or archetype == 1:
		# Scenic Western Woodland Lake
		_paint_transformed_rect(tiles, 4, 34, 9, 41, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
		_paint_transformed_rect(tiles, 5, 56, 10, 62, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
	elif archetype == 2:
		# Twin Market Ponds
		_paint_transformed_rect(tiles, 30, 35, 36, 40, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
	elif archetype == 3:
		# Northern Coastal Bays
		_paint_transformed_rect(tiles, 3, 3, 10, 11, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
		_paint_transformed_rect(tiles, 58, 3, 67, 12, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
	elif archetype == 4:
		# Lava / Water Fissure Pockets
		_paint_transformed_rect(tiles, 32, 54, 38, 60, TileType.LAVA, 0.0, mirror_x, mirror_y, swap_xy)

	# =========================================================================
	# DISTRICT 1: SOUTHERN OUTSKIRTS HAMLET & COBBLESTONE HIGHWAY (y = gate_y..68)
	# =========================================================================
	var road_x: int = clampi(20 + s_shift_x, 14, 28)
	# Wide 4-tile dark-brown Cobblestone Main Street (like the Tenebrae screenshot!)
	_paint_transformed_rect(tiles, road_x - 1, gate_y, road_x + 3, 66, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)
	# East-West Outskirts Cobblestone Cross-Street
	_paint_transformed_rect(tiles, road_x - 8, 58, road_x + 12, 60, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Cottage #1 (West of the main street)
	var h1_x0: int = road_x - 8
	var h1_x1: int = road_x - 2
	_build_cutaway_house(tiles, h1_x0, 51, h1_x1, 57, base_elev + 0.06, "east", mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Inn / Tavern #2 (East of the main street)
	var h2_x0: int = road_x + 4
	var h2_x1: int = road_x + 11
	_build_cutaway_house(tiles, h2_x0, 51, h2_x1, 57, base_elev + 0.06, "west", mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Guardhouse #3 (South-East of the cross-street)
	_build_cutaway_house(tiles, road_x + 4, 61, road_x + 10, 66, base_elev + 0.06, "north", mirror_x, mirror_y, swap_xy)

	# Fortified Town Gatehouse Masonry Wall spanning from West border to the East River Gorge at y = gate_y
	_paint_transformed_rect(tiles, 2, gate_y, east_creek_x - 1, gate_y, TileType.WALL_BLOCK, base_elev + 1.9, mirror_x, mirror_y, swap_xy)
	# Open the Gatehouse Doorway across the Cobblestone Street
	_paint_transformed_rect(tiles, road_x, gate_y, road_x + 1, gate_y, TileType.OBSIDIAN_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)

	# =========================================================================
	# DISTRICT 2: CENTRAL TOWN COMMONS & MARKET CROSSROADS (y = canal_y+5 .. gate_y-1)
	# =========================================================================
	var mid_x: int = clampi(20 + m_shift_x, 14, 28)
	# Connect Gatehouse road to Central Market Plaza
	_paint_transformed_rect(tiles, mini(road_x, mid_x) - 1, canal_y + 5, maxi(road_x, mid_x) + 3, gate_y - 1, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)
	# Central Cobblestone Market Square & East Avenue toward the River Gorge
	var ave_y: int = clampi(canal_y + 11, 34, 41)
	_paint_transformed_rect(tiles, 10, ave_y - 1, east_creek_x - 1, ave_y + 2, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Apothecary / Shop #4 (North-West of the Market Crossroads)
	var h4_x0: int = clampi(mid_x - 9, 8, 16)
	_build_cutaway_house(tiles, h4_x0, ave_y - 8, h4_x0 + 6, ave_y - 2, base_elev + 0.08, "south", mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Blacksmith / Barracks #5 (North-East of the Market Crossroads)
	var h5_x0: int = clampi(mid_x + 5, 25, east_creek_x - 9)
	_build_cutaway_house(tiles, h5_x0, ave_y - 8, h5_x0 + 6, ave_y - 2, base_elev + 0.08, "south", mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Guildhall #6 (South of the East Avenue)
	_build_cutaway_house(tiles, h5_x0, ave_y + 3, h5_x0 + 7, ave_y + 9, base_elev + 0.08, "north", mirror_x, mirror_y, swap_xy)

	# =========================================================================
	# DISTRICT 3: EAST RIVER GORGE, STEPPING STONES & WATCHTOWER KEEP (x = east_creek_x .. 69)
	# =========================================================================
	# Stepping Stones #1 across the East River Gorge along the East Avenue
	var step1_type: int = TileType.CRUMBLING_STONE if (level_num >= 2 and rng.randf() < 0.35) else TileType.PILLAR_STONE
	_paint_transformed_rect(tiles, east_creek_x, ave_y, east_creek_x + 1, ave_y + 1, step1_type, base_elev + 0.15, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, east_creek_x + 2, ave_y, east_creek_x + 4, ave_y + 2, TileType.PILLAR_STONE, base_elev + 0.25, mirror_x, mirror_y, swap_xy)

	# Stepping Stones #2 (Southern Ford to the Bonus Treasure Island & Watchtower South Lawn)
	var ford_y: int = ave_y + 10
	_paint_transformed_rect(tiles, east_creek_x - 3, ford_y, east_creek_x - 1, ford_y + 2, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, east_creek_x, ford_y, east_creek_x + 4, ford_y + 2, TileType.PILLAR_STONE, base_elev + 0.2, mirror_x, mirror_y, swap_xy)

	# Eastern Watchtower Highlands & Cut-Away Keep Complex
	var tw_x0: int = east_creek_x + 5
	var tw_x1: int = MAP_W - 4
	var tw_y0: int = canal_y + 5
	var tw_y1: int = MAP_H - 5
	var tw_z: float = base_elev + 0.35
	_paint_transformed_rect(tiles, tw_x0, tw_y0, tw_x1, tw_y1, TileType.GRASS_FLOOR, tw_z, mirror_x, mirror_y, swap_xy)
	# Cobblestone Watchtower Courtyard & Road
	_paint_transformed_rect(tiles, tw_x0, ave_y - 2, tw_x0 + 14, ford_y + 3, TileType.COBBLE_FLOOR, tw_z, mirror_x, mirror_y, swap_xy)

	# Cut-Away Watchtower Keep #7 (houses the Canal Bridge Lever & War Chest)
	var keep_x0: int = tw_x0 + 4
	var keep_x1: int = mini(tw_x1 - 2, keep_x0 + 9)
	var keep_y0: int = ave_y - 4
	var keep_y1: int = ave_y + 4
	_build_cutaway_house(tiles, keep_x0, keep_y0, keep_x1, keep_y1, tw_z + 0.08, "west", mirror_x, mirror_y, swap_xy)

	# Cut-Away Southern Watchtower Cottage #8 (Bonus Loot House)
	_build_cutaway_house(tiles, keep_x0, ford_y, keep_x1 - 1, ford_y + 6, tw_z + 0.08, "west", mirror_x, mirror_y, swap_xy)

	# Upper Stepping Stones across the Main Canal from the Eastern Highlands to the North Sanctum Borough
	_paint_transformed_rect(tiles, tw_x0 + 2, canal_y, tw_x0 + 5, canal_y + 4, TileType.PILLAR_STONE, tw_z - 0.05, mirror_x, mirror_y, swap_xy)

	# =========================================================================
	# DISTRICT 4: THE SUNKEN CANAL BRIDGE (y = canal_y .. canal_y + 4)
	# =========================================================================
	var br_x0: int = mid_x
	var br_x1: int = mid_x + 2
	var bridge_tiles: Array = []
	for bx in range(br_x0, br_x1 + 1):
		for by in range(canal_y, canal_y + 5):
			var tc: Vector2i = _tx_cell(Vector2i(bx, by), mirror_x, mirror_y, swap_xy)
			tiles[tc.x][tc.y]["type"] = TileType.BRIDGE_SUNKEN
			tiles[tc.x][tc.y]["z"] = 0.0
			tiles[tc.x][tc.y]["base_z"] = 0.0
			bridge_tiles.append(tc)

	# =========================================================================
	# DISTRICT 5: NORTHERN PRIORY BOROUGH & GRAND PENTAGRAM COURTYARD (y = 3 .. canal_y - 1)
	# =========================================================================
	var sanctum_z: float = base_elev + 0.35
	_paint_transformed_rect(tiles, 3, 3, MAP_W - 4, canal_y - 1, TileType.GRASS_FLOOR, sanctum_z, mirror_x, mirror_y, swap_xy)

	var s_x0: int = clampi(12 + n_shift_x, 8, 18)
	var s_x1: int = clampi(48 + n_shift_x, 42, 56)
	# Grand Cobblestone Sanctum Avenue & Plaza
	_paint_transformed_rect(tiles, s_x0, 6, s_x1, canal_y - 1, TileType.COBBLE_FLOOR, sanctum_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, br_x0, canal_y - 1, br_x1, canal_y - 1, TileType.STAIRS, sanctum_z - 0.15, mirror_x, mirror_y, swap_xy)

	# Cut-Away Western Priory #9 (houses the Zealan Sarcophagus & Grimoire)
	_build_cutaway_house(tiles, s_x0 + 1, 8, s_x0 + 8, 15, sanctum_z + 0.08, "east", mirror_x, mirror_y, swap_xy)

	# Cut-Away Eastern Reliquary #10 (houses extra Potions & Feast Table)
	_build_cutaway_house(tiles, s_x1 - 8, 8, s_x1 - 1, 15, sanctum_z + 0.08, "west", mirror_x, mirror_y, swap_xy)

	# Grand Open-Air Pentagram Ritual Courtyard in the Center of the Northern Borough
	var p_cx_int: int = (s_x0 + s_x1) / 2
	var p_x0: int = p_cx_int - 2
	var p_x1: int = p_cx_int + 2
	var pent_z: float = sanctum_z + 0.12
	_paint_transformed_rect(tiles, p_x0 - 2, 7, p_x1 + 2, 16, TileType.OBSIDIAN_FLOOR, sanctum_z + 0.06, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, p_x0, 9, p_x1, 13, TileType.PENTAGRAM_FLOOR, pent_z, mirror_x, mirror_y, swap_xy)

	# Grand Stone Dais for the Blackrock Obelisk Gateway
	var dais_z: float = sanctum_z + 0.35
	_paint_transformed_rect(tiles, p_x0 - 1, 3, p_x1 + 1, 6, TileType.OBSIDIAN_FLOOR, dais_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, p_x0 - 1, 3, p_x0 - 1, 3, TileType.WALL_BLOCK, dais_z + 1.9, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, p_x1 + 1, 3, p_x1 + 1, 3, TileType.WALL_BLOCK, dais_z + 1.9, mirror_x, mirror_y, swap_xy)

	var pent_center_raw := Vector3(float(p_cx_int) + 0.5, 11.5, pent_z + 0.02)
	var pentagram_center: Vector3 = _tx_vec3(pent_center_raw, mirror_x, mirror_y, swap_xy)

	# =========================================================================
	# INTERACTIVE PROPS, CHESTS, TAVERN TABLES, BARRELS & OUTDOOR FOLIAGE
	# =========================================================================
	var dock_loot: Array[String] = ["red_potion", "blue_potion"]
	if rng.randf() < 0.75:
		dock_loot.append("red_potion")

	var tower_loot: Array[String] = ["red_potion", "blue_potion"]
	if level_num == 1 or rng.randf() < 0.65:
		tower_loot.append("flame_blade")
	if level_num == 1 or rng.randf() < 0.80:
		tower_loot.append("ignis_scroll")

	var sarc_loot: Array[String] = ["ritual_candle", "red_potion", "blue_potion"]
	if level_num >= 2 or rng.randf() < 0.65:
		sarc_loot.append("grimoire")

	var keep_cx: float = float(keep_x0 + keep_x1) * 0.5 + 0.5
	var keep_cy: float = float(keep_y0 + keep_y1) * 0.5 + 0.5
	var raw_props: Array = [
		# District 1 Props (Outskirts Hamlet)
		{
			"id": "corpse_guard",
			"type": "corpse",
			"name": "Slain Tenebrae Guard",
			"pos": Vector3(float(road_x) + 1.5, float(gate_y) + 5.5, base_elev),
			"looted": false,
			"blocking": false,
			"desc": "A slain guard on the cobblestone street. His hand clutches a Brass-Bound Gatehouse Key."
		},
		{
			"id": "chest_dock",
			"type": "chest",
			"name": "Cottage Gold-Banded Chest",
			"pos": Vector3(float(h1_x0) + 2.5, 53.5, base_elev + 0.06),
			"opened": false,
			"loot": dock_loot,
			"blocking": true,
			"desc": "An ornate gold-banded chest inside the western stone cottage."
		},
		{
			"id": "table_cottage_1",
			"type": "table",
			"name": "Cottage Feast Table",
			"pos": Vector3(float(h1_x0) + 2.5, 55.5, base_elev + 0.06),
			"used": false,
			"blocking": true,
			"desc": "A wooden table set with a wheel of Tenebrae cheese and green wine bottle."
		},
		{
			"id": "table_tavern_2",
			"type": "table",
			"name": "Tavern Banquet Table",
			"pos": Vector3(float(h2_x0) + 3.5, 53.5, base_elev + 0.06),
			"used": false,
			"blocking": true,
			"desc": "A tavern table laden with cheese, wine, and a pewter mug."
		},
		{
			"id": "chest_tavern_2",
			"type": "chest",
			"name": "Innkeeper's Coffer",
			"pos": Vector3(float(h2_x0) + 4.5, 55.5, base_elev + 0.06),
			"opened": false,
			"loot": ["red_potion", "blue_potion"],
			"blocking": true,
			"desc": "A brass-bound chest inside the eastern roadside tavern."
		},
		{
			"id": "lore_stone_dock",
			"type": "plaque",
			"name": "Town Waystone",
			"pos": Vector3(float(road_x) + 2.6, float(gate_y) + 9.5, base_elev),
			"blocking": true,
			"learned": false,
			"desc": "'Realm " + str(level_num) + " of " + str(MAX_LEVELS) + " (" + title + "): Unlock the Gatehouse Door, pull the Watchtower Keep Lever & awaken the Obelisk!'"
		},
		{
			"id": "gate_portcullis",
			"type": "gate",
			"name": "Heavy Ring-Handled Gatehouse Door",
			"pos": Vector3(float(road_x) + 0.8, float(gate_y) + 0.5, base_elev),
			"opened": false,
			"blocking": true,
			"desc": "A heavy Tenebrae timber-and-iron doorway barring the main cobblestone street."
		},
		{
			"id": "brazier_dock_1",
			"type": "brazier",
			"name": "Outskirts Street Hearth",
			"pos": Vector3(float(road_x) - 0.5, float(gate_y) + 3.5, base_elev),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "brazier_dock_2",
			"type": "brazier",
			"name": "Crossroads Hearth",
			"pos": Vector3(float(road_x) + 3.2, 58.5, base_elev),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		# District 2 Props (Central Market Commons)
		{
			"id": "brazier_courtyard",
			"type": "brazier",
			"name": "Market Square Hearth",
			"pos": Vector3(float(mid_x) + 1.5, float(ave_y) + 0.5, base_elev),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "chest_market_shop",
			"type": "chest",
			"name": "Apothecary Supply Chest",
			"pos": Vector3(float(h4_x0) + 3.0, float(ave_y) - 5.5, base_elev + 0.08),
			"opened": false,
			"loot": ["red_potion", "red_potion", "blue_potion"],
			"blocking": true,
			"desc": "An apothecary chest stocked with healing & mana draughts."
		},
		{
			"id": "table_commons",
			"type": "table",
			"name": "Blacksmith Feast Table",
			"pos": Vector3(float(h5_x0) + 3.0, float(ave_y) - 5.5, base_elev + 0.08),
			"used": false,
			"blocking": true,
			"desc": "A sturdy oak table inside the market house."
		},
		{
			"id": "skulls_courtyard",
			"type": "skulls",
			"name": "Market Oak Cask",
			"pos": Vector3(float(h5_x0) + 2.5, float(ave_y) + 6.0, base_elev + 0.08),
			"blocking": false,
			"desc": "A weathered oak barrel inside the guildhall."
		},
		# District 3 Props (Eastern Watchtower Keep)
		{
			"id": "lever_bridge",
			"type": "lever",
			"name": "Grand Canal Bridge Lever",
			"pos": Vector3(keep_cx - 1.5, keep_cy, tw_z + 0.08),
			"activated": false,
			"blocking": false,
			"desc": "An iron mechanism inside the Watchtower Keep that raises the Sunken Canal Bridge."
		},
		{
			"id": "chest_watchtower",
			"type": "chest",
			"name": "Gold-Banded War Chest",
			"pos": Vector3(keep_cx + 1.8, keep_cy - 1.5, tw_z + 0.08),
			"opened": false,
			"loot": tower_loot,
			"blocking": true,
			"desc": "A heavy gold-strapped chest holding enchanted armaments of Pyros."
		},
		{
			"id": "brazier_watchtower",
			"type": "brazier",
			"name": "Watchtower Keep Hearth",
			"pos": Vector3(keep_cx + 1.8, keep_cy + 1.5, tw_z + 0.08),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "chest_east_cottage",
			"type": "chest",
			"name": "Highland Guard Chest",
			"pos": Vector3(keep_cx, float(ford_y) + 3.0, tw_z + 0.08),
			"opened": false,
			"loot": ["red_potion", "blue_potion", "ignis_scroll"],
			"blocking": true,
			"desc": "A supply chest in the southern watchtower cottage."
		},
		# District 5 Props (Northern Priory & Grand Pentagram Courtyard)
		{
			"id": "sarcophagus_sanctum",
			"type": "sarcophagus",
			"name": "Ancient Zealan Reliquary",
			"pos": Vector3(float(s_x0) + 4.5, 11.5, sanctum_z + 0.08),
			"opened": false,
			"loot": sarc_loot,
			"blocking": true,
			"desc": "A chiseled grey-stone tomb inside the western priory."
		},
		{
			"id": "chest_east_priory",
			"type": "chest",
			"name": "Priory Vault Chest",
			"pos": Vector3(float(s_x1) - 4.5, 11.5, sanctum_z + 0.08),
			"opened": false,
			"loot": ["red_potion", "red_potion", "ritual_candle"],
			"blocking": true,
			"desc": "A sacred chest inside the eastern priory containing a spare Blood Ritual Candle & potions."
		},
		{
			"id": "table_east_priory",
			"type": "table",
			"name": "Priory Refectory Table",
			"pos": Vector3(float(s_x1) - 4.5, 13.5, sanctum_z + 0.08),
			"used": false,
			"blocking": true,
			"desc": "A refectory table set with cheese and wine."
		},
		{
			"id": "ritual_pyre_1",
			"type": "brazier",
			"name": "First Courtyard Pyre",
			"pos": Vector3(float(p_x0) - 0.8, 11.5, pent_z),
			"lit": false,
			"ritual": true,
			"blocking": true,
			"desc": "An unlit ritual hearth bordering the outdoor Pentagram."
		},
		{
			"id": "ritual_pyre_2",
			"type": "brazier",
			"name": "Second Courtyard Pyre",
			"pos": Vector3(float(p_x1) + 1.8, 11.5, pent_z),
			"lit": false,
			"ritual": true,
			"blocking": true,
			"desc": "An unlit ritual hearth bordering the outdoor Pentagram."
		},
		{
			"id": "ritual_pyre_3",
			"type": "brazier",
			"name": "Third Courtyard Pyre",
			"pos": Vector3(float(p_cx_int) + 0.5, 8.2, pent_z),
			"lit": false,
			"ritual": true,
			"blocking": true,
			"desc": "An unlit ritual hearth before the Obelisk Dais."
		},
		{
			"id": "pentagram_altar",
			"type": "pentagram_focus",
			"name": "Heart of the Pentagram",
			"pos": Vector3(float(p_cx_int) + 0.5, 11.5, pent_z),
			"activated": false,
			"blocking": false,
			"desc": "The crimson nexus of the outdoor Pentagram."
		},
		{
			"id": "blackrock_obelisk",
			"type": "obelisk",
			"name": "Blackrock Obelisk (Gateway to Level " + str(level_num + 1) + ")",
			"pos": Vector3(float(p_cx_int) + 0.5, 4.5, dais_z),
			"activated": false,
			"blocking": true,
			"desc": "An ancient Pagan monolith that warps to the next procedural outdoor realm."
		}
	]

	# Scatter 55+ Procedural Outdoor Woodland Trees & Roadside Bushes across the 72x72 Grasslands
	for f_idx in range(58):
		var fx: float = float(rng.randi_range(4, MAP_W - 5)) + 0.5
		var fy: float = float(rng.randi_range(4, MAP_H - 5)) + 0.5
		# Keep foliage on outdoor grass tiles away from the immediate spawn/pentagram
		var tx_check: Vector2i = _tx_cell(Vector2i(int(fx), int(fy)), mirror_x, mirror_y, swap_xy)
		if tiles[tx_check.x][tx_check.y]["type"] == TileType.GRASS_FLOOR:
			var fz: float = float(tiles[tx_check.x][tx_check.y]["z"])
			var is_tree: bool = ((f_idx + rng.randi()) % 3 == 0)
			raw_props.append({
				"id": "foliage_" + str(f_idx),
				"type": "tree" if is_tree else "bush",
				"name": "Pagan Woodland Tree" if is_tree else "Lush Roadside Bush",
				"pos": Vector3(fx, fy, fz),
				"blocking": false,
				"desc": "Dense emerald foliage thriving across the Pagan countryside."
			})

	var props: Array = []
	for rp in raw_props:
		var p_copy: Dictionary = rp.duplicate(true)
		p_copy["pos"] = _tx_vec3(rp["pos"], mirror_x, mirror_y, swap_xy)
		props.append(p_copy)

	# =========================================================================
	# PROCEDURAL ENEMY PATROLS — ALL 23 DISTINCT ENEMY TYPES ACROSS THE 5 DISTRICTS!
	# Every enemy has a unique sprite, unique death SFX, and strictly different Hit Points!
	# =========================================================================
	var eff_tier: int = mini(level_num, 25)
	var hp_scale: int = (eff_tier - 1) * 5
	var dmg_scale: int = (eff_tier - 1) * 1
	var spd_scale: float = minf(0.40, float(eff_tier) * 0.018)

	# 23 strategic spawn anchors across the 5 districts of the 72x72 outdoor world
	var spawn_anchors: Array[Vector3] = [
		# District 1: Outskirts Hamlet & Streets (5 enemies)
		Vector3(float(road_x) + 1.5, 53.5, base_elev),
		Vector3(float(road_x) + 7.5, 59.0, base_elev),
		Vector3(float(road_x) - 5.5, 59.0, base_elev),
		Vector3(float(h1_x0) + 3.0, 54.0, base_elev + 0.06),
		Vector3(float(road_x) + 6.5, 63.0, base_elev + 0.06),
		# District 2: Central Town Commons, Market & Guildhalls (6 enemies)
		Vector3(float(mid_x) + 1.5, float(ave_y) + 3.5, base_elev),
		Vector3(float(east_creek_x) - 4.5, float(ave_y) + 0.5, base_elev),
		Vector3(float(mid_x) + 1.5, float(canal_y) + 7.5, base_elev),
		Vector3(float(h4_x0) + 3.0, float(ave_y) - 4.5, base_elev + 0.08),
		Vector3(float(h5_x0) + 3.0, float(ave_y) - 4.5, base_elev + 0.08),
		Vector3(float(h5_x0) + 3.5, float(ave_y) + 6.0, base_elev + 0.08),
		# District 3: Eastern River Gorge & Watchtower Highlands (5 enemies)
		Vector3(keep_cx - 2.0, keep_cy + 1.0, tw_z + 0.08),
		Vector3(float(tw_x0) + 3.5, float(ford_y) + 1.5, tw_z),
		Vector3(float(tw_x0) + 2.5, float(ave_y) + 1.0, tw_z),
		Vector3(keep_cx + 1.0, float(ford_y) + 3.5, tw_z + 0.08),
		Vector3(float(tw_x0) + 8.0, float(ave_y) + 6.0, tw_z),
		# District 5: Northern Priory Borough & Grand Pentagram Courtyard (7 enemies)
		Vector3(float(s_x0) + 6.5, 11.5, sanctum_z + 0.08),
		Vector3(float(s_x1) - 6.5, 11.5, sanctum_z + 0.08),
		Vector3(float(s_x0) + 10.5, float(canal_y) - 4.0, sanctum_z),
		Vector3(float(s_x1) - 10.5, float(canal_y) - 4.0, sanctum_z),
		Vector3(float(p_x0) - 3.5, 11.5, sanctum_z),
		Vector3(float(p_x1) + 3.5, 11.5, sanctum_z),
		Vector3(float(p_cx_int) + 0.5, 11.5, pent_z) # 23rd anchor: Pentagram Warden (drops Blood Ritual Candle)
	]

	var raw_enemies: Array = []
	for idx in range(ENEMY_CATALOG.size()):
		var spec: Dictionary = ENEMY_CATALOG[idx]
		var e_type: String = String(spec["type"])
		var e_name: String = String(spec["name"])
		var e_hp: int = int(spec["hp"]) + hp_scale + idx # Guaranteed strictly distinct HP per enemy!
		var e_dmg: int = int(spec["damage"]) + dmg_scale
		var e_spd: float = float(spec["speed"]) + spd_scale
		var is_ranged: bool = bool(spec["ranged"])
		var is_warden: bool = (idx >= ENEMY_CATALOG.size() - 2)
		raw_enemies.append({
			"id": "enemy_" + str(idx) + "_" + e_type,
			"type": e_type,
			"name": e_name,
			"pos": spawn_anchors[idx],
			"hp": e_hp,
			"max_hp": e_hp,
			"damage": e_dmg,
			"speed": e_spd,
			"attack_cd": 0.0,
			"cast_cd": 2.6 + float(idx % 4) * 0.3,
			"hit_flash": 0.0,
			"state": "guard" if is_ranged else "patrol",
			"facing": (idx * 3) % 8,
			"anim_t": float(idx) * 0.37,
			"boss": is_warden or is_ranged
		})

	var enemies: Array = []
	for re in raw_enemies:
		var e_copy: Dictionary = re.duplicate(true)
		var tp: Vector3 = _tx_vec3(re["pos"], mirror_x, mirror_y, swap_xy)
		e_copy["pos"] = tp
		e_copy["home"] = tp
		enemies.append(e_copy)

	var spawn_raw := Vector3(float(road_x) + 1.0, 63.5, base_elev)
	var spawn_pos: Vector3 = _tx_vec3(spawn_raw, mirror_x, mirror_y, swap_xy)

	return {
		"tiles": tiles,
		"props": props,
		"enemies": enemies,
		"spawn": spawn_pos,
		"bridge_tiles": bridge_tiles,
		"pentagram_center": pentagram_center,
		"level_num": level_num,
		"level_title": title,
		"seed": int(rng.seed)
	}

static func _build_boss_level(rng: RandomNumberGenerator, level_num: int) -> Dictionary:
	# MASSIVE 72x72 OUTDOOR BOSS CITADEL & ROYAL BOROUGHS (Level 6, every 6th level, and Level 666)
	var title: String = get_level_title(level_num, rng)
	var mirror_x: bool = (rng.randi() % 2 == 1)
	var mirror_y: bool = (rng.randi() % 2 == 1)
	var swap_xy: bool = (rng.randi() % 2 == 1)

	var tiles: Array = _create_empty_tiles(rng, TileType.WATER if (level_num == 6) else TileType.LAVA, 0.0)
	_paint_transformed_rect(tiles, 2, 2, MAP_W - 3, MAP_H - 3, TileType.GRASS_FLOOR, 1.2, mirror_x, mirror_y, swap_xy)

	var cx: int = 36 + rng.randi_range(-3, 3)

	# 1. Outer Royal Avenue & Cut-Away Guardhouses (y = 46..66)
	_paint_transformed_rect(tiles, cx - 5, 44, cx + 5, 66, TileType.COBBLE_FLOOR, 1.4, mirror_x, mirror_y, swap_xy)
	_build_cutaway_house(tiles, cx - 12, 52, cx - 5, 59, 1.45, "east", mirror_x, mirror_y, swap_xy)
	_build_cutaway_house(tiles, cx + 5, 52, cx + 12, 59, 1.45, "west", mirror_x, mirror_y, swap_xy)

	# 2. Citadel Moat Canal & Grand Stone Causeway (y = 39..43)
	_paint_transformed_rect(tiles, 2, 39, MAP_W - 3, 43, TileType.LAVA if level_num >= 12 else TileType.WATER, 0.0, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 2, 38, cx + 2, 44, TileType.COBBLE_FLOOR, 1.6, mirror_x, mirror_y, swap_xy)

	# 3. Grand Outdoor Boss Citadel Courtyard (y = 14..37)
	var arena_z: float = 1.8
	_paint_transformed_rect(tiles, cx - 14, 14, cx + 14, 37, TileType.COBBLE_FLOOR, arena_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 10, 17, cx + 10, 34, TileType.OBSIDIAN_FLOOR, arena_z + 0.05, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 2, 37, cx + 2, 37, TileType.STAIRS, 1.7, mirror_x, mirror_y, swap_xy)

	# Cut-Away Flanking Citadel Bastions
	_build_cutaway_house(tiles, cx - 14, 21, cx - 9, 29, arena_z + 0.1, "east", mirror_x, mirror_y, swap_xy)
	_build_cutaway_house(tiles, cx + 9, 21, cx + 14, 29, arena_z + 0.1, "west", mirror_x, mirror_y, swap_xy)

	# 4. Grand Crimson Pentagram in the Heart of the Citadel Courtyard
	var pent_z: float = 1.9
	_paint_transformed_rect(tiles, cx - 2, 23, cx + 2, 27, TileType.PENTAGRAM_FLOOR, pent_z, mirror_x, mirror_y, swap_xy)

	# 5. Throne Dais & Final Blackrock Obelisk (y = 6..13)
	var dais_z: float = 2.2
	_paint_transformed_rect(tiles, cx - 4, 6, cx + 4, 12, TileType.OBSIDIAN_FLOOR, dais_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 2, 13, cx + 2, 13, TileType.STAIRS, 2.0, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 4, 6, cx - 4, 6, TileType.WALL_BLOCK, 4.1, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx + 4, 6, cx + 4, 6, TileType.WALL_BLOCK, 4.1, mirror_x, mirror_y, swap_xy)

	var pent_cx: float = float(cx) + 0.5
	var pentagram_center: Vector3 = _tx_vec3(Vector3(pent_cx, 25.5, pent_z + 0.02), mirror_x, mirror_y, swap_xy)

	var boss_name: String = "Malchir, Arch-Executioner of Pagan"
	if level_num == MAX_LEVELS:
		boss_name = "Pyros, Overlord of the 666th Realm"
	elif level_num > 6:
		boss_name = "Arch-Executioner of Realm " + str(level_num)

	var raw_props: Array = [
		{
			"id": "chest_boss_supply",
			"type": "chest",
			"name": "Gold-Banded War Chest",
			"pos": Vector3(float(cx) - 8.5, 55.5, 1.45),
			"opened": false,
			"loot": ["flame_blade", "ignis_scroll", "grimoire", "red_potion", "red_potion", "blue_potion"],
			"blocking": true,
			"desc": "Relics of Pyros and healing draughts for the Boss confrontation."
		},
		{
			"id": "chest_boss_east",
			"type": "chest",
			"name": "Royal Armory Chest",
			"pos": Vector3(float(cx) + 8.5, 55.5, 1.45),
			"opened": false,
			"loot": ["red_potion", "red_potion", "blue_potion"],
			"blocking": true,
			"desc": "Extra healing potions stored in the eastern guardhouse."
		},
		{
			"id": "table_boss_entry",
			"type": "table",
			"name": "Guardhouse Feast Table",
			"pos": Vector3(float(cx) - 8.5, 57.5, 1.45),
			"used": false,
			"blocking": true,
			"desc": "A table set with Tenebrae cheese and wine before the citadel battle."
		},
		{
			"id": "lore_stone_boss",
			"type": "plaque",
			"name": "Tablet of the Crimson Trial",
			"pos": Vector3(float(cx) + 3.2, 60.5, 1.4),
			"blocking": true,
			"learned": false,
			"desc": "'REALM " + str(level_num) + ": Follow the Royal Cobblestone Avenue & vanquish " + boss_name + " to awaken the Blackrock Obelisk!'"
		},
		{
			"id": "brazier_entry_l",
			"type": "brazier",
			"name": "Royal Avenue Hearth",
			"pos": Vector3(float(cx) - 3.5, 46.5, 1.4),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "brazier_entry_r",
			"type": "brazier",
			"name": "Royal Avenue Hearth",
			"pos": Vector3(float(cx) + 3.5, 46.5, 1.4),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "ritual_pyre_1",
			"type": "brazier",
			"name": "First Throne Pyre",
			"pos": Vector3(pent_cx - 4.0, 25.5, arena_z + 0.05),
			"lit": true,
			"ritual": true,
			"blocking": true,
			"desc": "A blood-fire pyre fueling the Crimson Courtyard."
		},
		{
			"id": "ritual_pyre_2",
			"type": "brazier",
			"name": "Second Throne Pyre",
			"pos": Vector3(pent_cx + 4.0, 25.5, arena_z + 0.05),
			"lit": true,
			"ritual": true,
			"blocking": true,
			"desc": "A blood-fire pyre fueling the Crimson Courtyard."
		},
		{
			"id": "ritual_pyre_3",
			"type": "brazier",
			"name": "Third Throne Pyre",
			"pos": Vector3(pent_cx, 20.5, arena_z + 0.05),
			"lit": true,
			"ritual": true,
			"blocking": true,
			"desc": "A blood-fire pyre before the Blackrock Obelisk."
		},
		{
			"id": "pentagram_altar",
			"type": "pentagram_focus",
			"name": "Heart of the Crimson Courtyard",
			"pos": Vector3(pent_cx, 25.5, pent_z),
			"activated": false,
			"blocking": false,
			"desc": "Bound to the life-force of " + boss_name + "."
		},
		{
			"id": "blackrock_obelisk",
			"type": "obelisk",
			"name": "Grand Blackrock Obelisk",
			"pos": Vector3(pent_cx, 8.5, dais_z),
			"activated": false,
			"blocking": true,
			"desc": "Vanquish " + boss_name + " to awaken the Obelisk!"
		}
	]

	for f_idx in range(45):
		var fx: float = float(rng.randi_range(4, MAP_W - 5)) + 0.5
		var fy: float = float(rng.randi_range(4, MAP_H - 5)) + 0.5
		var tx_check: Vector2i = _tx_cell(Vector2i(int(fx), int(fy)), mirror_x, mirror_y, swap_xy)
		if tiles[tx_check.x][tx_check.y]["type"] == TileType.GRASS_FLOOR:
			var is_tree: bool = ((f_idx + rng.randi()) % 3 == 0)
			raw_props.append({
				"id": "boss_foliage_" + str(f_idx),
				"type": "tree" if is_tree else "bush",
				"name": "Pagan Woodland Tree" if is_tree else "Lush Courtyard Bush",
				"pos": Vector3(fx, fy, 1.2),
				"blocking": false,
				"desc": "Emerald foliage surrounding the Citadel."
			})

	var props: Array = []
	for rp in raw_props:
		var p_copy: Dictionary = rp.duplicate(true)
		p_copy["pos"] = _tx_vec3(rp["pos"], mirror_x, mirror_y, swap_xy)
		props.append(p_copy)

	var boss_tier_bonus: int = mini(level_num / 6, 30) * 15
	var boss_hp: int = 230 + boss_tier_bonus
	if level_num == MAX_LEVELS:
		boss_hp = 666

	var raw_enemies: Array = [
		{
			"id": "boss_malchir",
			"type": "titan_boss",
			"name": boss_name,
			"pos": Vector3(pent_cx, 25.0, pent_z),
			"hp": boss_hp,
			"max_hp": boss_hp,
			"damage": 22 + mini(12, level_num / 12),
			"speed": 2.45,
			"attack_cd": 0.0,
			"cast_cd": 1.8,
			"hit_flash": 0.0,
			"state": "guard",
			"facing": 2,
			"anim_t": 0.0,
			"boss": true,
			"final_boss": true
		},
		{
			"id": "boss_guard_l",
			"type": "daemon",
			"name": "Greater Daemon of Pyros",
			"pos": Vector3(pent_cx - 4.5, 30.5, arena_z + 0.05),
			"hp": 195,
			"max_hp": 195,
			"damage": 18,
			"speed": 2.25,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 0.4
		},
		{
			"id": "boss_guard_r",
			"type": "gargoyle",
			"name": "Winged Obsidian Gargoyle",
			"pos": Vector3(pent_cx + 4.5, 30.5, arena_z + 0.05),
			"hp": 148,
			"max_hp": 148,
			"damage": 16,
			"speed": 2.25,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 1.1
		},
		{
			"id": "boss_avenue_guard_1",
			"type": "tempest_guard",
			"name": "Mordea's Palace Guard",
			"pos": Vector3(pent_cx - 1.5, 49.5, 1.4),
			"hp": 108,
			"max_hp": 108,
			"damage": 14,
			"speed": 2.15,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 0.2
		},
		{
			"id": "boss_avenue_guard_2",
			"type": "hellhound",
			"name": "Brimstone Hellhound",
			"pos": Vector3(pent_cx + 1.5, 49.5, 1.4),
			"hp": 162,
			"max_hp": 162,
			"damage": 15,
			"speed": 2.35,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 0.8
		}
	]

	var enemies: Array = []
	for re in raw_enemies:
		var e_copy: Dictionary = re.duplicate(true)
		var tp: Vector3 = _tx_vec3(re["pos"], mirror_x, mirror_y, swap_xy)
		e_copy["pos"] = tp
		e_copy["home"] = tp
		enemies.append(e_copy)

	var spawn_pos: Vector3 = _tx_vec3(Vector3(pent_cx, 63.5, 1.4), mirror_x, mirror_y, swap_xy)
	return {
		"tiles": tiles,
		"props": props,
		"enemies": enemies,
		"spawn": spawn_pos,
		"bridge_tiles": [],
		"pentagram_center": pentagram_center,
		"level_num": level_num,
		"level_title": title,
		"seed": int(rng.seed)
	}
