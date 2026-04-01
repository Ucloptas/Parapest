extends Node2D

## Chore avatar - animal-shaped marker that displays a chore when the player gets near.
## chore_index is set by the parent (chore_xplorer) when spawned.

signal player_entered(chore_index: int)
signal player_exited(chore_index: int)

var chore_index: int = 0

const SNAP_RAY_ABOVE := 260.0
const SNAP_RAY_BELOW := 720.0
const TILE_COLLISION_MASK := 1
## Search along X so we snap to a walkable top (rays that hit pit walls are skipped).
const HORIZONTAL_SEARCH_OFFSETS: Array[float] = [
	0.0, -8.0, 8.0, -16.0, 16.0, -24.0, 24.0, -32.0, 32.0, -40.0, 40.0,
	-48.0, 48.0, -56.0, 56.0, -64.0, 64.0, -80.0, 80.0, -96.0, 96.0,
	-112.0, 112.0, -128.0, 128.0, -160.0, 160.0, -192.0, 192.0
]

# Animal sprite regions from spritesheet (idle/focus frame for each type)
const ANIMAL_REGIONS: Array[Rect2] = [
	Rect2(0, 288, 16, 16),   # bear
	Rect2(64, 144, 16, 16),  # mouse
	Rect2(32, 384, 16, 16),  # wolf
	Rect2(32, 64, 16, 16),   # snake
	Rect2(32, 0, 16, 16),    # snake variant
	Rect2(96, 288, 16, 16),  # bear 2
]

@onready var proximity_area: Area2D = $ProximityArea
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if proximity_area:
		proximity_area.body_entered.connect(_on_body_entered)
		proximity_area.body_exited.connect(_on_body_exited)


func setup(index: int, animal_type: int = -1) -> void:
	chore_index = index
	if animal_type >= 0 and animal_type < ANIMAL_REGIONS.size():
		_set_animal_sprite(animal_type)
	else:
		_set_animal_sprite(index % ANIMAL_REGIONS.size())
	call_deferred("snap_feet_to_ground")


## Snap feet to a horizontal walkable surface (reject vertical wall hits).
func snap_feet_to_ground() -> void:
	if not is_inside_tree():
		return
	if _try_snap_to_walkable_floor():
		return
	var explorer := get_parent().get_parent()
	if explorer and explorer.has_method("snap_chore_avatar_to_walkable_surface"):
		explorer.snap_chore_avatar_to_walkable_surface(self)


func _try_snap_to_walkable_floor() -> bool:
	var space := get_world_2d().direct_space_state
	var exclude := _ray_exclude_rids()
	var base_x := global_position.x
	var base_y := global_position.y
	for ox in HORIZONTAL_SEARCH_OFFSETS:
		var x := base_x + ox
		var from := Vector2(x, base_y - SNAP_RAY_ABOVE)
		var to := Vector2(x, base_y + SNAP_RAY_BELOW)
		var q := PhysicsRayQueryParameters2D.create(from, to)
		q.collision_mask = TILE_COLLISION_MASK
		q.exclude = exclude
		var hit: Dictionary = space.intersect_ray(q)
		if hit.is_empty():
			continue
		var n: Vector2 = hit.get("normal", Vector2.ZERO)
		var pos: Vector2 = hit.get("position", Vector2.ZERO)
		if not _is_walkable_floor_normal(n):
			continue
		global_position = Vector2(x, pos.y)
		return true
	return false


func _is_walkable_floor_normal(n: Vector2) -> bool:
	# Godot 2D: Y+ is down; upward-facing platform top has normal pointing up → negative Y.
	return n.y <= -0.42 and abs(n.x) < 0.72


func _ray_exclude_rids() -> Array[RID]:
	var exclude: Array[RID] = []
	var player := get_tree().get_first_node_in_group("player")
	if player is CollisionObject2D:
		exclude.append(player.get_rid())
	return exclude


func _set_animal_sprite(type: int) -> void:
	if sprite and type < ANIMAL_REGIONS.size():
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://Assets/spritesheet.png") as Texture2D
		atlas.region = ANIMAL_REGIONS[type]
		sprite.texture = atlas


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(chore_index)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_exited.emit(chore_index)
