## Hand-placed avatar positions for Chore Explorer (world space under scene root).
## Reward Explorer uses the same layout mirrored on X: use flipped_for_reward().
extends RefCounted
class_name WorldExplorerPositions

const CHORE_AVATAR_POSITIONS: Array[Vector2] = [
	Vector2(1500, 8),
	Vector2(1800, 152),
	Vector2(1675, 152),
	Vector2(1490, 7),
	Vector2(1439, 152),
	Vector2(1315, 23),
	Vector2(1223, -24),
	Vector2(1103, -56),
	Vector2(1045, -56),
	Vector2(968, -8),
	Vector2(1400, 152),
	Vector2(1300, 152),
	Vector2(1250, 152),
	Vector2(1080, 152),
	Vector2(950, 152),
	Vector2(1320, 392),
	Vector2(1488, 312),
	Vector2(1100, 409),
	Vector2(1022, 392),
	Vector2(920, 328),
	Vector2(780, 24),
	Vector2(656, -40),
	Vector2(462, 24),
	Vector2(376, 24),
	Vector2(215, 24),
	Vector2(126, 24),
	Vector2(670, 152),
	Vector2(200, 152),
	Vector2(163, 312),
	Vector2(32, 312),
	Vector2(-140, 280),
	Vector2(-80, 344),
	Vector2(34, 120),
	Vector2(83, 152),
	Vector2(-160, 24),
	Vector2(-332, -8),
	Vector2(-430, -40),
	Vector2(-308, 232),
	Vector2(-380, 200),
	Vector2(-438, 200),
	Vector2(-500, 200),
	Vector2(-676, 232),
	Vector2(-266, 345),
	Vector2(-359, 361),
	Vector2(-534, 377),
	Vector2(-760, 104),
	Vector2(-837, 104),
	Vector2(-943, 104),
	Vector2(-1114, 56),
	Vector2(-1000, 248),
	Vector2(-1080, 248),
	Vector2(-1188, 248),
	Vector2(-1368, 328),
	Vector2(-1500, 441),
	Vector2(-1544, 377),
	Vector2(-1617, 264),
	Vector2(-1719, 312),
	Vector2(-1786, 248),
]


static func flipped_for_reward(world: Vector2) -> Vector2:
	return Vector2(-world.x, world.y)


static func position_for_chore_index(index: int) -> Vector2:
	var pts := CHORE_AVATAR_POSITIONS
	if pts.is_empty():
		return Vector2.ZERO
	return pts[index % pts.size()]


## Picks `count` positions from the hand-placed list in random order (no repeats while count <= list size).
static func random_positions_no_repeat(count: int) -> Array[Vector2]:
	var pts := CHORE_AVATAR_POSITIONS
	var out: Array[Vector2] = []
	if pts.is_empty() or count <= 0:
		return out
	var indices: Array = range(pts.size())
	indices.shuffle()
	for i in range(count):
		out.append(pts[indices[i % indices.size()]])
	return out
