extends Node2D

## Chore avatar - animal-shaped marker that displays a chore when the player gets near.
## chore_index is set by the parent (chore_xplorer) when spawned.

signal player_entered(chore_index: int)

var chore_index: int = 0

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


func setup(index: int, animal_type: int = -1) -> void:
	chore_index = index
	if animal_type >= 0 and animal_type < ANIMAL_REGIONS.size():
		_set_animal_sprite(animal_type)
	else:
		_set_animal_sprite(index % ANIMAL_REGIONS.size())


func _set_animal_sprite(type: int) -> void:
	if sprite and type < ANIMAL_REGIONS.size():
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://Assets/spritesheet.png") as Texture2D
		atlas.region = ANIMAL_REGIONS[type]
		sprite.texture = atlas


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(chore_index)
