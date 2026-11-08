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

const MAP_W: int = 22
const MAP_H: int = 22
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

static func get_level_title(level_num: int, rng: RandomNumberGenerator) -> String:
	if level_num == 6:
		return "The Grand Courtyard of Malchir (BOSS)"
	if level_num == MAX_LEVELS:
		return "The 666th Outdoor Citadel of Pagan (FINAL BOSS)"
	if is_boss_level(level_num):
		var lord: String = REALM_LORDS[(level_num / 6) % REALM_LORDS.size()]
		return "Boss Courtyard " + str(level_num) + " " + lord
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
	# Light-grey stone flagstone interior floor (exact match to user's screenshot!)
	_paint_transformed_rect(tiles, hx0, hy0, hx1, hy1, TileType.OBSIDIAN_FLOOR, floor_z, mirror_x, mirror_y, swap_xy)
	var wall_z: float = floor_z + 1.85
	# Cut-away grey stone masonry walls around the room corners & back edges, leaving cutaway opening & doorway
	_paint_transformed_rect(tiles, hx0, hy0, hx0, hy0, TileType.WALL_BLOCK, wall_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, hx1, hy0, hx1, hy0, TileType.WALL_BLOCK, wall_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, hx0, hy1, hx0, hy1, TileType.WALL_BLOCK, wall_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, hx1, hy1, hx1, hy1, TileType.WALL_BLOCK, wall_z, mirror_x, mirror_y, swap_xy)
	if door_side != "north" and (hx1 - hx0) >= 3:
		_paint_transformed_rect(tiles, hx0 + 1, hy0, hx1 - 1, hy0, TileType.WALL_BLOCK, wall_z - 0.15, mirror_x, mirror_y, swap_xy)
	if door_side != "west" and (hy1 - hy0) >= 3:
		_paint_transformed_rect(tiles, hx0, hy0 + 1, hx0, hy1 - 1, TileType.WALL_BLOCK, wall_z - 0.15, mirror_x, mirror_y, swap_xy)

static func _build_procedural_level(rng: RandomNumberGenerator, level_num: int) -> Dictionary:
	var title: String = get_level_title(level_num, rng)

	# Full 8-way dihedral symmetry + 5 outdoor archetypes + randomized coordinates
	# Ensures every level (and every new run on death) has a genuinely different layout & direction!
	var mirror_x: bool = (rng.randi() % 2 == 1)
	var mirror_y: bool = (rng.randi() % 2 == 1)
	var swap_xy: bool = (rng.randi() % 2 == 1)
	var archetype: int = rng.randi_range(0, 4)

	var base_elev: float = 1.0 + float(rng.randi_range(0, 3)) * 0.08
	var hazard_liquid: int = TileType.LAVA if (archetype == 4 or (level_num > 3 and rng.randf() < 0.28)) else TileType.WATER

	# Start with an outdoor Pagan landscape: lush emerald GRASS_FLOOR surrounded by a 1-tile coastal/river border!
	var tiles: Array = _create_empty_tiles(rng, hazard_liquid, 0.0)
	_paint_transformed_rect(tiles, 1, 1, MAP_W - 2, MAP_H - 2, TileType.GRASS_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)

	# Randomize layout offsets for roads, houses, river canal, watchtower & sanctum
	var s_shift_x: int = rng.randi_range(-1, 2)
	var m_shift_x: int = rng.randi_range(-1, 2)
	var n_shift_x: int = rng.randi_range(-1, 2)
	var canal_y: int = rng.randi_range(7, 9)
	var east_creek_x: int = rng.randi_range(12, 14)

	# 1. Carve Outdoor River / Canal & East Creek across the Grasslands (creates natural outdoor islands & moats)
	_paint_transformed_rect(tiles, 0, canal_y, MAP_W - 1, canal_y + 2, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, east_creek_x, canal_y + 2, east_creek_x + 2, MAP_H - 1, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)

	# Depending on archetype, carve additional scenic outdoor ponds, lava vents, or coastal bays
	if archetype == 1:
		# Woodland Pond in the West
		_paint_transformed_rect(tiles, 1, 12, 2, 15, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
	elif archetype == 2:
		# Crossroads Central Fountain / Moat Pocket
		_paint_transformed_rect(tiles, 9, 13, 10, 14, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
	elif archetype == 3:
		# Coastal Archipelago Inlets
		_paint_transformed_rect(tiles, 1, 1, 2, 5, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)
		_paint_transformed_rect(tiles, 18, 1, 20, 4, hazard_liquid, 0.0, mirror_x, mirror_y, swap_xy)

	# 2. Zone 1: Outdoor Cobblestone Town Street & Cut-Away Guardhouse (South-West Quadrant)
	var road_x: int = clampi(5 + s_shift_x, 4, 8)
	# Main dark-brown cobblestone street (like the screenshot!)
	_paint_transformed_rect(tiles, road_x - 1, 11, road_x + 2, 19, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Cottage #1 (West/East of the street, with light-grey flagstone floor & walls)
	var h1_x0: int = clampi(road_x - 3, 1, 4)
	var h1_x1: int = h1_x0 + 2
	_build_cutaway_house(tiles, h1_x0, 16, h1_x1, 19, base_elev + 0.06, "east", mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Guardhouse Gateway across the Cobblestone Street at y = 14
	var gate_y: int = 14
	_paint_transformed_rect(tiles, 1, gate_y, east_creek_x - 1, gate_y, TileType.WALL_BLOCK, base_elev + 1.9, mirror_x, mirror_y, swap_xy)
	# Open the cobblestone street doorway at (road_x, gate_y)
	_paint_transformed_rect(tiles, road_x, gate_y, road_x, gate_y, TileType.OBSIDIAN_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)

	# 3. Zone 2: Town Commons / Mid-Street North of the Gatehouse (y = canal_y+3 .. 13)
	var mid_x: int = clampi(5 + m_shift_x, 3, 8)
	_paint_transformed_rect(tiles, mini(road_x, mid_x), canal_y + 3, maxi(road_x + 2, mid_x + 3), 13, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)
	# Cut-Away Stone Tavern / Shop #2 on the Town Commons
	var h2_x0: int = clampi(mid_x - 2, 1, 4)
	_build_cutaway_house(tiles, h2_x0, canal_y + 3, h2_x0 + 2, canal_y + 5, base_elev + 0.08, "east", mirror_x, mirror_y, swap_xy)

	# 4. Stepping Stones across the East Creek & Outdoor Watchtower Villa (East Side)
	var step_y1: int = clampi(canal_y + 4, 11, 13)
	_paint_transformed_rect(tiles, east_creek_x - 2, step_y1, east_creek_x - 1, step_y1 + 1, TileType.COBBLE_FLOOR, base_elev, mirror_x, mirror_y, swap_xy)
	var step1_type: int = TileType.CRUMBLING_STONE if (level_num >= 2 and rng.randf() < 0.35) else TileType.PILLAR_STONE
	_paint_transformed_rect(tiles, east_creek_x, step_y1, east_creek_x + 1, step_y1 + 1, step1_type, base_elev + 0.2, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, east_creek_x + 2, step_y1 + 1, east_creek_x + 2, step_y1 + 2, TileType.PILLAR_STONE, base_elev + 0.35, mirror_x, mirror_y, swap_xy)
	# Extra wide stepping stones further south so the player has two ways across the creek!
	_paint_transformed_rect(tiles, east_creek_x, step_y1 + 3, east_creek_x + 2, step_y1 + 4, TileType.PILLAR_STONE, base_elev + 0.25, mirror_x, mirror_y, swap_xy)

	# East Outdoor Lawn & Cut-Away Watchtower House (contains the Bridge Lever & Flame Chest)
	var tw_x0: int = east_creek_x + 3
	var tw_x1: int = MAP_W - 2
	var tw_y0: int = canal_y + 3
	var tw_y1: int = MAP_H - 3
	var tw_z: float = base_elev + 0.4
	_paint_transformed_rect(tiles, tw_x0, tw_y0, tw_x1, tw_y1, TileType.GRASS_FLOOR, tw_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, tw_x0, tw_y0 + 1, tw_x1 - 1, tw_y0 + 4, TileType.COBBLE_FLOOR, tw_z, mirror_x, mirror_y, swap_xy)
	_build_cutaway_house(tiles, tw_x0 + 1, tw_y0 + 1, tw_x1, tw_y0 + 4, tw_z + 0.08, "west", mirror_x, mirror_y, swap_xy)

	# Upper Stepping Stones across the Canal from the East Watchtower to the North Sanctum Outskirts
	_paint_transformed_rect(tiles, tw_x0, canal_y, tw_x0 + 1, canal_y + 2, TileType.PILLAR_STONE, tw_z - 0.1, mirror_x, mirror_y, swap_xy)

	# 5. Sunken Bridge across the Main Canal (connects Town Commons to the North Sanctum Plaza)
	var br_x0: int = clampi(mid_x + 1, 4, 8)
	var br_x1: int = br_x0 + 1
	var bridge_tiles: Array = []
	for bx in range(br_x0, br_x1 + 1):
		for by in range(canal_y, canal_y + 3):
			var tc: Vector2i = _tx_cell(Vector2i(bx, by), mirror_x, mirror_y, swap_xy)
			tiles[tc.x][tc.y]["type"] = TileType.BRIDGE_SUNKEN
			tiles[tc.x][tc.y]["z"] = 0.0
			tiles[tc.x][tc.y]["base_z"] = 0.0
			bridge_tiles.append(tc)

	# 6. Zone 3: Outdoor North Sanctum Plaza, Cobblestone Avenue & Cut-Away Priory (y = 1 .. canal_y - 1)
	var sanctum_z: float = base_elev + 0.35
	_paint_transformed_rect(tiles, 1, 1, MAP_W - 2, canal_y - 1, TileType.GRASS_FLOOR, sanctum_z, mirror_x, mirror_y, swap_xy)
	var s_x0: int = clampi(3 + n_shift_x, 2, 5)
	var s_x1: int = clampi(13 + n_shift_x, 11, 16)
	# Cobblestone courtyard avenue
	_paint_transformed_rect(tiles, s_x0, 2, s_x1, canal_y - 1, TileType.COBBLE_FLOOR, sanctum_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, br_x0, canal_y - 1, br_x1, canal_y - 1, TileType.STAIRS, sanctum_z - 0.15, mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Priory Room in the Sanctum (holds the Zealan Sarcophagus)
	_build_cutaway_house(tiles, s_x0, 2, s_x0 + 3, 5, sanctum_z + 0.08, "east", mirror_x, mirror_y, swap_xy)

	# Open-Air Pentagram Ritual Courtyard (3x3)
	var p_x0: int = s_x0 + 5
	var p_x1: int = p_x0 + 2
	var pent_z: float = sanctum_z + 0.12
	_paint_transformed_rect(tiles, p_x0 - 1, 2, p_x1 + 1, 6, TileType.OBSIDIAN_FLOOR, sanctum_z + 0.06, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, p_x0, 3, p_x1, 5, TileType.PENTAGRAM_FLOOR, pent_z, mirror_x, mirror_y, swap_xy)

	# Stone Dais for the Blackrock Obelisk Gateway
	var dais_z: float = sanctum_z + 0.35
	_paint_transformed_rect(tiles, p_x0, 1, p_x1, 2, TileType.OBSIDIAN_FLOOR, dais_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, p_x0, 1, p_x0, 1, TileType.WALL_BLOCK, dais_z + 1.9, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, p_x1, 1, p_x1, 1, TileType.WALL_BLOCK, dais_z + 1.9, mirror_x, mirror_y, swap_xy)

	var pent_center_raw := Vector3(float(p_x0) + 1.5, 4.5, pent_z + 0.02)
	var pentagram_center: Vector3 = _tx_vec3(pent_center_raw, mirror_x, mirror_y, swap_xy)

	# 7. Interactive Props, Tavern Furniture, Outdoor Trees & Roadside Bushes
	var dock_loot: Array[String] = ["red_potion", "blue_potion"]
	if rng.randf() < 0.75:
		dock_loot.append("red_potion")

	var tower_loot: Array[String] = ["red_potion", "blue_potion"]
	if level_num == 1 or rng.randf() < 0.55:
		tower_loot.append("flame_blade")
	if level_num == 1 or rng.randf() < 0.75:
		tower_loot.append("ignis_scroll")

	var sarc_loot: Array[String] = ["ritual_candle", "red_potion", "blue_potion"]
	if level_num >= 2 or rng.randf() < 0.65:
		sarc_loot.append("grimoire")

	var tw_cx: float = float(tw_x0 + tw_x1) * 0.5 + 0.5
	var raw_props: Array = [
		{
			"id": "corpse_guard",
			"type": "corpse",
			"name": "Slain Tenebrae Guard",
			"pos": Vector3(float(road_x) + 1.2, 16.2, base_elev),
			"looted": false,
			"blocking": false,
			"desc": "A slain guard on the cobblestone street. His hand clutches a Brass-Bound Key."
		},
		{
			"id": "chest_dock",
			"type": "chest",
			"name": "Gold-Banded House Chest",
			"pos": Vector3(float(h1_x0) + 1.2, 17.2, base_elev + 0.06),
			"opened": false,
			"loot": dock_loot,
			"blocking": true,
			"desc": "An ornate gold-banded chest inside the stone cottage."
		},
		{
			"id": "table_cottage_1",
			"type": "table",
			"name": "Cottage Feast Table",
			"pos": Vector3(float(h1_x0) + 1.5, 18.4, base_elev + 0.06),
			"used": false,
			"blocking": true,
			"desc": "A wooden table set with a wheel of Tenebrae cheese and green wine bottle."
		},
		{
			"id": "lore_stone_dock",
			"type": "plaque",
			"name": "Town Waystone",
			"pos": Vector3(float(road_x) + 2.2, 17.5, base_elev),
			"blocking": true,
			"learned": false,
			"desc": "'Realm " + str(level_num) + " of " + str(MAX_LEVELS) + " (" + title + "): Unlock the Gatehouse Door, pull the Watchtower Lever & awaken the Obelisk!'"
		},
		{
			"id": "gate_portcullis",
			"type": "gate",
			"name": "Heavy Ring-Handled Door",
			"pos": Vector3(float(road_x) + 0.5, float(gate_y) + 0.5, base_elev),
			"opened": false,
			"blocking": true,
			"desc": "A heavy Tenebrae timber-and-iron doorway with a brass ring handle."
		},
		{
			"id": "brazier_dock_1",
			"type": "brazier",
			"name": "Street Hearth Lantern",
			"pos": Vector3(float(road_x) - 0.4, 15.5, base_elev),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "brazier_courtyard",
			"type": "brazier",
			"name": "Town Commons Hearth",
			"pos": Vector3(float(mid_x) + 0.5, float(canal_y) + 3.6, base_elev),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "table_commons",
			"type": "table",
			"name": "Tavern Table",
			"pos": Vector3(float(h2_x0) + 1.4, float(canal_y) + 4.2, base_elev + 0.08),
			"used": false,
			"blocking": true,
			"desc": "A tavern table laden with cheese, wine, and a pewter mug."
		},
		{
			"id": "skulls_courtyard",
			"type": "skulls",
			"name": "Wooden Tavern Barrel",
			"pos": Vector3(float(h2_x0) + 1.4, float(canal_y) + 5.2, base_elev + 0.08),
			"blocking": false,
			"desc": "A weathered oak cask beside the cottage wall."
		},
		{
			"id": "lever_bridge",
			"type": "lever",
			"name": "Canal Bridge Lever",
			"pos": Vector3(tw_cx - 0.4, float(tw_y0) + 2.5, tw_z + 0.08),
			"activated": false,
			"blocking": false,
			"desc": "An iron lever inside the eastern house that raises the Canal Bridge."
		},
		{
			"id": "chest_watchtower",
			"type": "chest",
			"name": "Gold-Banded War Chest",
			"pos": Vector3(tw_cx + 0.8, float(tw_y0) + 1.8, tw_z + 0.08),
			"opened": false,
			"loot": tower_loot,
			"blocking": true,
			"desc": "A heavy gold-strapped chest holding enchanted armaments."
		},
		{
			"id": "brazier_watchtower",
			"type": "brazier",
			"name": "Watchtower Hearth",
			"pos": Vector3(tw_cx + 0.8, float(tw_y0) + 3.4, tw_z + 0.08),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "sarcophagus_sanctum",
			"type": "sarcophagus",
			"name": "Ancient Stone Vault",
			"pos": Vector3(float(s_x0) + 1.6, 3.6, sanctum_z + 0.08),
			"opened": false,
			"loot": sarc_loot,
			"blocking": true,
			"desc": "A chiseled grey-stone reliquary inside the northern priory."
		},
		{
			"id": "ritual_pyre_1",
			"type": "brazier",
			"name": "First Courtyard Pyre",
			"pos": Vector3(float(p_x0) - 0.4, 4.5, pent_z),
			"lit": false,
			"ritual": true,
			"blocking": true,
			"desc": "An unlit ritual hearth bordering the outdoor Pentagram."
		},
		{
			"id": "ritual_pyre_2",
			"type": "brazier",
			"name": "Second Courtyard Pyre",
			"pos": Vector3(float(p_x1) + 1.4, 4.5, pent_z),
			"lit": false,
			"ritual": true,
			"blocking": true,
			"desc": "An unlit ritual hearth bordering the outdoor Pentagram."
		},
		{
			"id": "ritual_pyre_3",
			"type": "brazier",
			"name": "Third Courtyard Pyre",
			"pos": Vector3(float(p_x0) + 1.5, 2.7, pent_z),
			"lit": false,
			"ritual": true,
			"blocking": true,
			"desc": "An unlit ritual hearth before the Obelisk Dais."
		},
		{
			"id": "pentagram_altar",
			"type": "pentagram_focus",
			"name": "Heart of the Pentagram",
			"pos": Vector3(float(p_x0) + 1.5, 4.5, pent_z),
			"activated": false,
			"blocking": false,
			"desc": "The crimson nexus of the outdoor Pentagram."
		},
		{
			"id": "blackrock_obelisk",
			"type": "obelisk",
			"name": "Blackrock Obelisk (Gateway to Level " + str(level_num + 1) + ")",
			"pos": Vector3(float(p_x0) + 1.5, 1.6, dais_z),
			"activated": false,
			"blocking": true,
			"desc": "An ancient Pagan monolith that warps to the next procedural outdoor realm."
		}
	]

	# Add Procedural Outdoor Trees & Roadside Green Bushes (matching the lush greenery in the screenshot!)
	var foliage_spots: Array[Vector3] = [
		Vector3(float(road_x) + 3.2, 18.2, base_elev),
		Vector3(float(road_x) + 3.4, 15.8, base_elev),
		Vector3(2.2, 14.8, base_elev),
		Vector3(float(mid_x) + 4.2, float(canal_y) + 3.5, base_elev),
		Vector3(float(tw_x0) + 0.8, float(tw_y1) - 0.6, tw_z),
		Vector3(float(s_x1) + 1.8, 3.2, sanctum_z),
		Vector3(float(s_x1) + 2.4, 5.2, sanctum_z),
		Vector3(2.2, 2.5, sanctum_z)
	]
	for f_idx in range(foliage_spots.size()):
		var fp: Vector3 = foliage_spots[f_idx]
		var is_tree: bool = ((f_idx + rng.randi()) % 3 == 0)
		raw_props.append({
			"id": "foliage_" + str(f_idx),
			"type": "tree" if is_tree else "bush",
			"name": "Pagan Woodland Tree" if is_tree else "Lush Roadside Bush",
			"pos": fp,
			"blocking": false,
			"desc": "Dense emerald foliage thriving beside the cobblestone street."
		})

	var props: Array = []
	for rp in raw_props:
		var p_copy: Dictionary = rp.duplicate(true)
		p_copy["pos"] = _tx_vec3(rp["pos"], mirror_x, mirror_y, swap_xy)
		props.append(p_copy)

	# 8. Procedural Enemies (scaled smoothly up to 666)
	var eff_tier: int = mini(level_num, 25)
	var hp_scale: int = (eff_tier - 1) * 6
	var dmg_scale: int = (eff_tier - 1) * 1
	var spd_scale: float = minf(0.45, float(eff_tier) * 0.02)

	var raw_enemies: Array = [
		{
			"id": "skel_courtyard",
			"type": "skeleton",
			"name": "Outskirts Bone Patrol",
			"pos": Vector3(float(mid_x) + 1.8, float(canal_y) + 4.2, base_elev),
			"hp": 42 + hp_scale,
			"max_hp": 42 + hp_scale,
			"damage": 11 + dmg_scale,
			"speed": 2.05 + spd_scale,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 0.0
		},
		{
			"id": "skel_watchtower",
			"type": "skeleton",
			"name": "Watchtower Guard",
			"pos": Vector3(tw_cx - 0.5, float(tw_y0) + 2.2, tw_z + 0.08),
			"hp": 52 + hp_scale,
			"max_hp": 52 + hp_scale,
			"damage": 13 + dmg_scale,
			"speed": 2.15 + spd_scale,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 4,
			"anim_t": 1.3
		},
		{
			"id": "sanctum_warden",
			"type": "executioner",
			"name": "Tenebrae High Executioner",
			"pos": Vector3(float(p_x0) + 1.5, 4.5, pent_z),
			"hp": 85 + hp_scale * 2,
			"max_hp": 85 + hp_scale * 2,
			"damage": 15 + dmg_scale,
			"speed": 2.25 + spd_scale,
			"attack_cd": 0.0,
			"cast_cd": 2.6,
			"hit_flash": 0.0,
			"state": "guard",
			"facing": 2,
			"anim_t": 0.0,
			"boss": true
		}
	]

	if level_num >= 2 or rng.randf() < 0.6:
		raw_enemies.append({
			"id": "skel_sanctum_guard",
			"type": "skeleton",
			"name": "Priory Sentinel",
			"pos": Vector3(float(s_x0) + 2.5, 4.6, sanctum_z),
			"hp": 48 + hp_scale,
			"max_hp": 48 + hp_scale,
			"damage": 12 + dmg_scale,
			"speed": 2.15 + spd_scale,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 0.7
		})
	if level_num >= 4 or rng.randf() < 0.35:
		raw_enemies.append({
			"id": "wraith_sanctum_cabal",
			"type": "executioner",
			"name": "Cabal Enforcer",
			"pos": Vector3(float(s_x1) - 1.2, 4.2, sanctum_z),
			"hp": 75 + hp_scale,
			"max_hp": 75 + hp_scale,
			"damage": 15 + dmg_scale,
			"speed": 2.2 + spd_scale,
			"attack_cd": 0.0,
			"cast_cd": 3.0,
			"hit_flash": 0.0,
			"state": "guard",
			"facing": 3,
			"anim_t": 1.9,
			"boss": false
		})

	var enemies: Array = []
	for re in raw_enemies:
		var e_copy: Dictionary = re.duplicate(true)
		var tp: Vector3 = _tx_vec3(re["pos"], mirror_x, mirror_y, swap_xy)
		e_copy["pos"] = tp
		e_copy["home"] = tp
		enemies.append(e_copy)

	var spawn_raw := Vector3(float(road_x) + 0.6, 18.2, base_elev)
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
	# OUTDOOR BOSS COURTYARD (Level 6, every 6th level, and Level 666)
	var title: String = get_level_title(level_num, rng)
	var mirror_x: bool = (rng.randi() % 2 == 1)
	var mirror_y: bool = (rng.randi() % 2 == 1)
	var swap_xy: bool = (rng.randi() % 2 == 1)

	var tiles: Array = _create_empty_tiles(rng, TileType.WATER if (level_num == 6) else TileType.LAVA, 0.0)
	# Lush Outdoor Grasslands surrounding the Grand Boss Courtyard
	_paint_transformed_rect(tiles, 1, 1, MAP_W - 2, MAP_H - 2, TileType.GRASS_FLOOR, 1.2, mirror_x, mirror_y, swap_xy)

	var arena_shift_x: int = rng.randi_range(-1, 1)
	var cx: int = 10 + arena_shift_x

	# 1. Cobblestone Grand Avenue & Cut-Away Gatehouse Bastion (Spawn Area)
	_paint_transformed_rect(tiles, cx - 3, 15, cx + 3, 20, TileType.COBBLE_FLOOR, 1.4, mirror_x, mirror_y, swap_xy)
	_build_cutaway_house(tiles, cx - 3, 17, cx - 1, 19, 1.45, "east", mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx + 3, 16, cx + 3, 16, TileType.WALL_BLOCK, 3.2, mirror_x, mirror_y, swap_xy)

	# 2. Moat Canal & Cobblestone Causeway into the Grand Outdoor Boss Courtyard
	_paint_transformed_rect(tiles, 1, 13, MAP_W - 2, 14, TileType.LAVA if level_num >= 12 else TileType.WATER, 0.0, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 1, 13, cx + 1, 15, TileType.COBBLE_FLOOR, 1.55, mirror_x, mirror_y, swap_xy)

	# 3. Grand Outdoor Boss Courtyard (Light-Grey Flagstone Plaza bordered by Cobblestones & Cut-Away Masonry)
	var arena_z: float = 1.75
	_paint_transformed_rect(tiles, cx - 6, 4, cx + 6, 12, TileType.COBBLE_FLOOR, arena_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 4, 5, cx + 4, 11, TileType.OBSIDIAN_FLOOR, arena_z + 0.05, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 1, 12, cx + 1, 12, TileType.STAIRS, 1.65, mirror_x, mirror_y, swap_xy)

	# Cut-Away Stone Corner Towers with Glowing Yellow Wall Lanterns
	_paint_transformed_rect(tiles, cx - 6, 4, cx - 6, 4, TileType.WALL_BLOCK, 3.8, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx + 6, 4, cx + 6, 4, TileType.WALL_BLOCK, 3.8, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 6, 12, cx - 6, 12, TileType.WALL_BLOCK, 3.6, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx + 6, 12, cx + 6, 12, TileType.WALL_BLOCK, 3.6, mirror_x, mirror_y, swap_xy)

	# 4. Grand Crimson Pentagram in the Heart of the Outdoor Courtyard
	var pent_z: float = 1.85
	_paint_transformed_rect(tiles, cx - 1, 6, cx + 1, 8, TileType.PENTAGRAM_FLOOR, pent_z, mirror_x, mirror_y, swap_xy)

	# 5. Throne Dais & Final Blackrock Obelisk
	var dais_z: float = 2.15
	_paint_transformed_rect(tiles, cx - 2, 1, cx + 2, 3, TileType.OBSIDIAN_FLOOR, dais_z, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 1, 3, cx + 1, 3, TileType.STAIRS, 1.98, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx - 2, 1, cx - 2, 1, TileType.WALL_BLOCK, 4.1, mirror_x, mirror_y, swap_xy)
	_paint_transformed_rect(tiles, cx + 2, 1, cx + 2, 1, TileType.WALL_BLOCK, 4.1, mirror_x, mirror_y, swap_xy)

	var pent_cx: float = float(cx) + 0.5
	var pentagram_center: Vector3 = _tx_vec3(Vector3(pent_cx, 7.5, pent_z + 0.02), mirror_x, mirror_y, swap_xy)

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
			"pos": Vector3(float(cx) - 2.0, 18.2, 1.45),
			"opened": false,
			"loot": ["flame_blade", "ignis_scroll", "grimoire", "red_potion", "red_potion", "blue_potion"],
			"blocking": true,
			"desc": "Relics of Pyros and healing draughts for the Boss confrontation."
		},
		{
			"id": "table_boss_entry",
			"type": "table",
			"name": "Guardhouse Feast Table",
			"pos": Vector3(float(cx) - 2.0, 17.2, 1.45),
			"used": false,
			"blocking": true,
			"desc": "A table set with Tenebrae cheese and wine before the courtyard battle."
		},
		{
			"id": "lore_stone_boss",
			"type": "plaque",
			"name": "Tablet of the Crimson Trial",
			"pos": Vector3(float(cx) + 2.2, 18.2, 1.4),
			"blocking": true,
			"learned": false,
			"desc": "'REALM " + str(level_num) + ": Vanquish " + boss_name + " to awaken the Blackrock Obelisk!'"
		},
		{
			"id": "brazier_entry_l",
			"type": "brazier",
			"name": "Courtyard Hearth",
			"pos": Vector3(float(cx) - 1.5, 15.8, 1.4),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "brazier_entry_r",
			"type": "brazier",
			"name": "Courtyard Hearth",
			"pos": Vector3(float(cx) + 2.5, 15.8, 1.4),
			"lit": true,
			"ritual": false,
			"blocking": true
		},
		{
			"id": "ritual_pyre_1",
			"type": "brazier",
			"name": "First Throne Pyre",
			"pos": Vector3(pent_cx - 2.2, 7.5, arena_z + 0.05),
			"lit": true,
			"ritual": true,
			"blocking": true,
			"desc": "A blood-fire pyre fueling the Crimson Courtyard."
		},
		{
			"id": "ritual_pyre_2",
			"type": "brazier",
			"name": "Second Throne Pyre",
			"pos": Vector3(pent_cx + 2.2, 7.5, arena_z + 0.05),
			"lit": true,
			"ritual": true,
			"blocking": true,
			"desc": "A blood-fire pyre fueling the Crimson Courtyard."
		},
		{
			"id": "ritual_pyre_3",
			"type": "brazier",
			"name": "Third Throne Pyre",
			"pos": Vector3(pent_cx, 5.2, arena_z + 0.05),
			"lit": true,
			"ritual": true,
			"blocking": true,
			"desc": "A blood-fire pyre before the Blackrock Obelisk."
		},
		{
			"id": "pentagram_altar",
			"type": "pentagram_focus",
			"name": "Heart of the Crimson Courtyard",
			"pos": Vector3(pent_cx, 7.5, pent_z),
			"activated": false,
			"blocking": false,
			"desc": "Bound to the life-force of " + boss_name + "."
		},
		{
			"id": "blackrock_obelisk",
			"type": "obelisk",
			"name": "Grand Blackrock Obelisk",
			"pos": Vector3(pent_cx, 1.8, dais_z),
			"activated": false,
			"blocking": true,
			"desc": "Vanquish " + boss_name + " to awaken the Obelisk!"
		},
		{
			"id": "boss_tree_1",
			"type": "tree",
			"name": "Ancient Pagan Tree",
			"pos": Vector3(2.5, 6.5, 1.2),
			"blocking": false,
			"desc": "A gnarled tree overlooking the courtyard."
		},
		{
			"id": "boss_tree_2",
			"type": "tree",
			"name": "Ancient Pagan Tree",
			"pos": Vector3(18.5, 6.5, 1.2),
			"blocking": false,
			"desc": "A gnarled tree overlooking the courtyard."
		},
		{
			"id": "boss_bush_1",
			"type": "bush",
			"name": "Lush Courtyard Bush",
			"pos": Vector3(float(cx) - 5.2, 8.5, arena_z),
			"blocking": false,
			"desc": "Green shrubbery along the stone courtyard wall."
		},
		{
			"id": "boss_bush_2",
			"type": "bush",
			"name": "Lush Courtyard Bush",
			"pos": Vector3(float(cx) + 5.2, 8.5, arena_z),
			"blocking": false,
			"desc": "Green shrubbery along the stone courtyard wall."
		}
	]

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
			"pos": Vector3(pent_cx, 7.2, pent_z),
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
			"type": "skeleton",
			"name": "Tenebrae Honor Guard",
			"pos": Vector3(pent_cx - 2.8, 9.5, arena_z + 0.05),
			"hp": 65,
			"max_hp": 65,
			"damage": 14,
			"speed": 2.25,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 0.4
		},
		{
			"id": "boss_guard_r",
			"type": "skeleton",
			"name": "Tenebrae Honor Guard",
			"pos": Vector3(pent_cx + 2.8, 9.5, arena_z + 0.05),
			"hp": 65,
			"max_hp": 65,
			"damage": 14,
			"speed": 2.25,
			"attack_cd": 0.0,
			"hit_flash": 0.0,
			"state": "patrol",
			"facing": 2,
			"anim_t": 1.1
		}
	]

	var enemies: Array = []
	for re in raw_enemies:
		var e_copy: Dictionary = re.duplicate(true)
		var tp: Vector3 = _tx_vec3(re["pos"], mirror_x, mirror_y, swap_xy)
		e_copy["pos"] = tp
		e_copy["home"] = tp
		enemies.append(e_copy)

	var spawn_pos: Vector3 = _tx_vec3(Vector3(pent_cx, 18.8, 1.4), mirror_x, mirror_y, swap_xy)
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
