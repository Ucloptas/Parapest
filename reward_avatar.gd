extends Node2D

## Reward avatar - animal-shaped marker that displays a reward when the player gets near and presses E.
## reward_index is set by the parent (reward_xplorer) when spawned.

signal player_entered(reward_index: int)
signal player_exited(reward_index: int)

var reward_index: int = 0
var player_nearby: bool = false

# Animal sprite regions from spritesheet (same as chore_avatar - proven to work)
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
var interact_hint: Label = null


func _ready() -> void:
	if proximity_area:
		proximity_area.body_entered.connect(_on_body_entered)
		proximity_area.body_exited.connect(_on_body_exited)
	
	# Create "Press E" hint label
	interact_hint = Label.new()
	interact_hint.text = "Press E"
	interact_hint.add_theme_font_size_override("font_size", 12)
	interact_hint.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	interact_hint.position = Vector2(-25, -50)
	interact_hint.visible = false
	add_child(interact_hint)


func setup(index: int, animal_type: int = -1) -> void:
	reward_index = index
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
		player_nearby = true
		if interact_hint:
			interact_hint.visible = true
		player_entered.emit(reward_index)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if interact_hint:
			interact_hint.visible = false
		player_exited.emit(reward_index)
