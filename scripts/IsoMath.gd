class_name IsoMath
extends RefCounted

# Classic 2:1 Isometric projection constants (Ultima VIII style)
const TILE_W: float = 64.0
const TILE_H: float = 32.0
const HALF_W: float = TILE_W * 0.5
const HALF_H: float = TILE_H * 0.5
const Z_SCALE: float = 18.0 # Pixels of vertical screen lift per 1.0 unit of Z elevation

static func world_to_screen(wx: float, wy: float, wz: float = 0.0) -> Vector2:
	var sx: float = (wx - wy) * HALF_W
	var sy: float = (wx + wy) * HALF_H - wz * Z_SCALE
	return Vector2(sx, sy)

static func screen_to_world_on_z(screen_pos: Vector2, wz: float = 0.0) -> Vector2:
	var adj_y: float = screen_pos.y + wz * Z_SCALE
	var wx: float = (screen_pos.x / HALF_W + adj_y / HALF_H) * 0.5
	var wy: float = (adj_y / HALF_H - screen_pos.x / HALF_W) * 0.5
	return Vector2(wx, wy)

static func depth_key(wx: float, wy: float, wz: float = 0.0) -> float:
	# Isometric painters algorithm order: (wx + wy) primary, wz secondary
	return (wx + wy) * 100.0 + wz * 2.5

static func dir_to_octant(dir: Vector2) -> int:
	# Converts world-space direction vector into 8 screen-space octants
	if dir.length_squared() < 0.0001:
		return 2 # Default facing South-East (towards camera)
	var screen_dir := Vector2((dir.x - dir.y) * HALF_W, (dir.x + dir.y) * HALF_H).normalized()
	var angle := atan2(screen_dir.y, screen_dir.x)
	var octant := int(round(angle / (PI / 4.0))) % 8
	if octant < 0:
		octant += 8
	return octant
