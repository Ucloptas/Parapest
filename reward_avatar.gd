extends Node2D

## Reward avatar - animal-shaped marker that displays a reward when the player gets near and presses E.
## reward_index is set by the parent (reward_xplorer) when spawned.

signal player_entered(reward_index: int)
signal player_exited(reward_index: int)

var reward_index: int = 0
var player_nearby: bool = false

# Idle animation frame pairs per animal type (from spritesheet)
const ANIMAL_IDLE_FRAMES: Array = [
	[Rect2(48, 288, 16, 16), Rect2(32, 288, 16, 16)],   # bear
	[Rect2(96, 144, 16, 16), Rect2(112, 144, 16, 16)],  # mouse
	[Rect2(32, 384, 16, 16), Rect2(48, 384, 16, 16)],   # wolf
	[Rect2(32, 48, 16, 16), Rect2(48, 48, 16, 16)],     # snake
	[Rect2(32, 0, 16, 16), Rect2(48, 0, 16, 16)],       # snake variant
	[Rect2(96, 288, 16, 16), Rect2(112, 288, 16, 16)],  # bear 2
]

# Focus frame (single frame shown when player is nearby)
const ANIMAL_FOCUS_FRAMES: Array[Rect2] = [
	Rect2(32, 304, 16, 16),  # bear
	Rect2(80, 160, 16, 16),  # mouse
	Rect2(32, 400, 16, 16),  # wolf
	Rect2(32, 64, 16, 16),   # snake
	Rect2(16, 16, 16, 16),   # snake variant
	Rect2(96, 304, 16, 16),  # bear 2
]

@onready var proximity_area: Area2D = $ProximityArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var interact_hint: Label = null


func _ready() -> void:
	if proximity_area:
		proximity_area.body_entered.connect(_on_body_entered)
		proximity_area.body_exited.connect(_on_body_exited)
	
	# Create "Press E" hint label
	interact_hint = Label.new()
	interact_hint.text = "Press E"
	interact_hint.add_theme_font_size_override("font_size", 12)
	interact_hint.add_theme_color_override("font_color", Color(0.90, 0.85, 0.70))
	interact_hint.position = Vector2(-25, -50)
	interact_hint.visible = false
	add_child(interact_hint)


func setup(index: int, animal_type: int = -1) -> void:
	reward_index = index
	if animal_type >= 0 and animal_type < ANIMAL_IDLE_FRAMES.size():
		_set_animal_sprite(animal_type)
	else:
		_set_animal_sprite(index % ANIMAL_IDLE_FRAMES.size())


func _set_animal_sprite(type: int) -> void:
	if not sprite or type >= ANIMAL_IDLE_FRAMES.size():
		return
	
	var atlas_tex = load("res://Assets/spritesheet.png") as Texture2D
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	
	# Idle animation (2 frames, looping)
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 2.0)
	for region in ANIMAL_IDLE_FRAMES[type]:
		var atlas = AtlasTexture.new()
		atlas.atlas = atlas_tex
		atlas.region = region
		frames.add_frame("idle", atlas)
	
	# Focus animation (single frame, shown when player is nearby)
	frames.add_animation("focus")
	frames.set_animation_loop("focus", true)
	frames.set_animation_speed("focus", 1.0)
	var focus_atlas = AtlasTexture.new()
	focus_atlas.atlas = atlas_tex
	focus_atlas.region = ANIMAL_FOCUS_FRAMES[type]
	frames.add_frame("focus", focus_atlas)
	
	sprite.sprite_frames = frames
	sprite.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if interact_hint:
			interact_hint.visible = true
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("focus"):
			sprite.play("focus")
		player_entered.emit(reward_index)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if interact_hint:
			interact_hint.visible = false
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		player_exited.emit(reward_index)
