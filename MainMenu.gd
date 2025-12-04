extends Control

# Scrolling background references (two copies for seamless loop)
@onready var bg_layer1_a: TextureRect = $Background/Layer1A
@onready var bg_layer1_b: TextureRect = $Background/Layer1B
@onready var bg_layer2_a: TextureRect = $Background/Layer2A
@onready var bg_layer2_b: TextureRect = $Background/Layer2B
@onready var bg_layer3_a: TextureRect = $Background/Layer3A
@onready var bg_layer3_b: TextureRect = $Background/Layer3B
@onready var bg_layer4_a: TextureRect = $Background/Layer4A
@onready var bg_layer4_b: TextureRect = $Background/Layer4B

# Scroll speeds for parallax effect (back layers slower, front layers faster)
var scroll_speed_layer1: float = 15.0   # Furthest back (sky) - slowest
var scroll_speed_layer2: float = 30.0   # Mountains
var scroll_speed_layer3: float = 60.0   # Trees back
var scroll_speed_layer4: float = 100.0  # Trees front - fastest

# Layer width (screen width)
var layer_width: float = 1920.0

func _ready() -> void:
	# Get actual screen size
	layer_width = get_viewport_rect().size.x
	
	# Position the B copies right after the A copies
	if bg_layer1_b: bg_layer1_b.position.x = layer_width
	if bg_layer2_b: bg_layer2_b.position.x = layer_width
	if bg_layer3_b: bg_layer3_b.position.x = layer_width
	if bg_layer4_b: bg_layer4_b.position.x = layer_width

func _process(delta: float) -> void:
	# Scroll all layer pairs to the left with parallax effect
	_scroll_layer_pair(bg_layer1_a, bg_layer1_b, scroll_speed_layer1, delta)
	_scroll_layer_pair(bg_layer2_a, bg_layer2_b, scroll_speed_layer2, delta)
	_scroll_layer_pair(bg_layer3_a, bg_layer3_b, scroll_speed_layer3, delta)
	_scroll_layer_pair(bg_layer4_a, bg_layer4_b, scroll_speed_layer4, delta)

func _scroll_layer_pair(layer_a: TextureRect, layer_b: TextureRect, speed: float, delta: float) -> void:
	if layer_a == null or layer_b == null:
		return
	
	# Move both layers to the left
	layer_a.position.x -= speed * delta
	layer_b.position.x -= speed * delta
	
	# When layer A goes completely off-screen left, move it to the right of layer B
	if layer_a.position.x <= -layer_width:
		layer_a.position.x = layer_b.position.x + layer_width
	
	# When layer B goes completely off-screen left, move it to the right of layer A
	if layer_b.position.x <= -layer_width:
		layer_b.position.x = layer_a.position.x + layer_width

func _on_parent_login_button_down() -> void:
	get_tree().change_scene_to_file("res://parent_login.tscn")

func _on_chore_xplorer_button_down() -> void:
	get_tree().change_scene_to_file("res://chore_xplorer.tscn")

func _on_exit_button_down() -> void:
	get_tree().quit()
