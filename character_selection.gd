extends Control

# UI References
@onready var lbl_username: Label = %Username
@onready var lbl_points: Label = %Points
@onready var btn_blue: Button = %BtnBlue
@onready var btn_pink: Button = %BtnPink
@onready var btn_white: Button = %BtnWhite
@onready var btn_start: Button = %BtnStart
@onready var btn_logout: Button = %BtnLogout
@onready var character_preview: Node2D = %CharacterPreview

# Scrolling background references (same as login)
@onready var bg_layer1_a: TextureRect = $Background/Layer1A
@onready var bg_layer1_b: TextureRect = $Background/Layer1B
@onready var bg_layer2_a: TextureRect = $Background/Layer2A
@onready var bg_layer2_b: TextureRect = $Background/Layer2B
@onready var bg_layer3_a: TextureRect = $Background/Layer3A
@onready var bg_layer3_b: TextureRect = $Background/Layer3B
@onready var bg_layer4_a: TextureRect = $Background/Layer4A
@onready var bg_layer4_b: TextureRect = $Background/Layer4B

# Scroll speeds for parallax effect
var scroll_speed_layer1: float = 12.0
var scroll_speed_layer2: float = 25.0
var scroll_speed_layer3: float = 50.0
var scroll_speed_layer4: float = 85.0

var layer_width: float = 1920.0
var http_client: Node
var selected_character: String = ""  # "blue", "pink", or "white"
var preview_instance: Node = null
var entrance_tween: Tween = null

# Character scene paths
const CHARACTER_SCENES = {
	"blue": "res://characters/bluePlayer.tscn",
	"pink": "res://characters/pinkPlayer.tscn",
	"white": "res://characters/whitePlayer.tscn"
}

func _ready() -> void:
	http_client = get_node("/root/HTTPClient")
	
	# Setup scrolling background
	layer_width = get_viewport_rect().size.x
	if bg_layer1_b: bg_layer1_b.position.x = layer_width
	if bg_layer2_b: bg_layer2_b.position.x = layer_width
	if bg_layer3_b: bg_layer3_b.position.x = layer_width
	if bg_layer4_b: bg_layer4_b.position.x = layer_width
	
	# Connect buttons
	btn_blue.pressed.connect(_on_blue_selected)
	btn_pink.pressed.connect(_on_pink_selected)
	btn_white.pressed.connect(_on_white_selected)
	btn_start.pressed.connect(_on_start_pressed)
	if btn_logout:
		btn_logout.pressed.connect(_on_logout_pressed)
	
	# Load user data
	_update_user_info()
	
	# Select blue as default character
	selected_character = "blue"
	btn_start.disabled = false
	_update_character_buttons()
	# Defer the preview load to ensure the SubViewport is fully ready
	call_deferred("_show_character_preview", "blue")

func _process(delta: float) -> void:
	_scroll_layer_pair(bg_layer1_a, bg_layer1_b, scroll_speed_layer1, delta)
	_scroll_layer_pair(bg_layer2_a, bg_layer2_b, scroll_speed_layer2, delta)
	_scroll_layer_pair(bg_layer3_a, bg_layer3_b, scroll_speed_layer3, delta)
	_scroll_layer_pair(bg_layer4_a, bg_layer4_b, scroll_speed_layer4, delta)

func _scroll_layer_pair(layer_a: TextureRect, layer_b: TextureRect, speed: float, delta: float) -> void:
	if layer_a == null or layer_b == null:
		return
	layer_a.position.x -= speed * delta
	layer_b.position.x -= speed * delta
	if layer_a.position.x <= -layer_width:
		layer_a.position.x = layer_b.position.x + layer_width
	if layer_b.position.x <= -layer_width:
		layer_b.position.x = layer_a.position.x + layer_width

func _update_user_info() -> void:
	var user = http_client.user_data
	if user.is_empty():
		# If user data is empty, show defaults
		lbl_username.text = "Welcome, User!"
		lbl_points.text = "Points: 0"
	else:
		_update_user_display()

func _update_user_display() -> void:
	var user = http_client.user_data
	var username = user.get("username", "User")
	var points = user.get("points", 0)
	
	lbl_username.text = "Welcome, " + username + "!"
	lbl_points.text = "Points: " + str(points)

func _on_blue_selected() -> void:
	_select_character("blue")

func _on_pink_selected() -> void:
	_select_character("pink")

func _on_white_selected() -> void:
	_select_character("white")

func _select_character(character: String) -> void:
	selected_character = character
	btn_start.disabled = false
	_update_character_buttons()
	_show_character_preview(character)

func _update_character_buttons() -> void:
	# Reset all buttons
	btn_blue.add_theme_stylebox_override("normal", _create_char_style(selected_character == "blue"))
	btn_pink.add_theme_stylebox_override("normal", _create_char_style(selected_character == "pink"))
	btn_white.add_theme_stylebox_override("normal", _create_char_style(selected_character == "white"))
	
	# Update colors
	var selected_color = Color(0.45, 0.85, 0.55)
	var unselected_color = Color(0.6, 0.65, 0.7)
	
	btn_blue.add_theme_color_override("font_color", selected_color if selected_character == "blue" else unselected_color)
	btn_pink.add_theme_color_override("font_color", selected_color if selected_character == "pink" else unselected_color)
	btn_white.add_theme_color_override("font_color", selected_color if selected_character == "white" else unselected_color)

func _create_char_style(selected: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(0.15, 0.25, 0.2, 1)
		style.border_color = Color(0.35, 0.65, 0.45, 1)
	else:
		style.bg_color = Color(0.12, 0.14, 0.18, 1)
		style.border_color = Color(0.25, 0.28, 0.35, 1)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

func _show_character_preview(character: String) -> void:
	# Kill any running entrance animation
	if entrance_tween and entrance_tween.is_valid():
		entrance_tween.kill()
	
	var old_instance = preview_instance
	preview_instance = null
	
	# Load new character scene
	var scene_path = CHARACTER_SCENES.get(character, "")
	if scene_path.is_empty():
		return
	
	var character_scene = load(scene_path)
	if character_scene == null:
		return
	
	var new_instance = character_scene.instantiate()
	if new_instance == null:
		return
	
	if character_preview == null:
		return
	
	# Add to scene and configure
	character_preview.add_child(new_instance)
	_setup_preview_character(new_instance)
	
	# Ensure SubViewport camera is active
	var subviewport = character_preview.get_parent()
	if subviewport and subviewport.has_node("Camera2D"):
		var camera = subviewport.get_node("Camera2D")
		camera.make_current()
	
	# Start off-screen to the right
	new_instance.position = Vector2(150, 0)
	preview_instance = new_instance
	
	# Get sprite for animation control
	var new_sprite = new_instance.get_node_or_null("AnimationSprites")
	
	# Start running animation, facing left (running toward center)
	if new_sprite:
		new_sprite.flip_h = true
		new_sprite.animation = "run_animation"
		new_sprite.play()
	
	# Build the entrance tween sequence
	entrance_tween = create_tween()
	
	# --- Phase 1: Run in from the right & knock old character off ---
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(new_instance, "position:x", 0.0, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	if old_instance and is_instance_valid(old_instance):
		# Old character gets knocked to the left with an arc and spin
		var old_sprite = old_instance.get_node_or_null("AnimationSprites")
		if old_sprite:
			old_sprite.animation = "fall_animation"
			old_sprite.play()
		entrance_tween.tween_property(old_instance, "position:x", -180.0, 0.45) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		entrance_tween.tween_property(old_instance, "position:y", -30.0, 0.2) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		entrance_tween.tween_property(old_instance, "rotation", -0.7, 0.45) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	entrance_tween.set_parallel(false)
	
	# --- Phase 2: Attack / punch animation ---
	entrance_tween.tween_callback(func():
		if is_instance_valid(new_instance) and new_sprite:
			new_sprite.flip_h = false  # face right for the punch
			new_sprite.animation = "attack_animation"
			new_sprite.play()
	)
	entrance_tween.tween_interval(0.5)
	
	# --- Phase 3: Settle into idle ---
	entrance_tween.tween_callback(func():
		if is_instance_valid(new_instance) and new_sprite:
			new_sprite.animation = "idle_animation"
			new_sprite.play()
		# Clean up old character
		if old_instance and is_instance_valid(old_instance):
			old_instance.queue_free()
	)

func _setup_preview_character(instance: Node) -> void:
	instance.visible = true
	instance.modulate = Color.WHITE
	
	# Disable physics processing to prevent movement/crashes
	instance.set_physics_process(false)
	instance.set_physics_process_internal(false)
	
	# Disable player movement
	if "can_move" in instance:
		instance.can_move = false
	
	# Disable character's built-in camera (conflicts with SubViewport camera)
	if instance.has_node("Camera"):
		var cam = instance.get_node("Camera")
		cam.enabled = false
	
	# Stop the AnimationPlayer so we can control the sprite directly
	if instance.has_node("Animations"):
		var anim_player = instance.get_node("Animations")
		anim_player.stop()
	
	# Ensure sprite is visible
	if instance.has_node("AnimationSprites"):
		var sprite = instance.get_node("AnimationSprites")
		sprite.visible = true
		sprite.modulate = Color.WHITE

func _on_start_pressed() -> void:
	if selected_character.is_empty():
		return
	
	# Store selected character in a global or pass via scene tree
	# Using a simple approach: store in HTTPClient as a temporary variable
	http_client.selected_character = selected_character
	
	# Navigate to chore_xplorer
	get_tree().change_scene_to_file("res://chore_xplorer.tscn")

func _on_logout_pressed() -> void:
	# Clear user data and selected character
	http_client.logout()
	http_client.selected_character = ""
	
	# Navigate back to login
	get_tree().change_scene_to_file("res://login.tscn")
