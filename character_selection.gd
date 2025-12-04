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
	
	# Initially disable start button
	btn_start.disabled = true
	_update_character_buttons()

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
	# Remove old preview safely
	if preview_instance and is_instance_valid(preview_instance):
		preview_instance.queue_free()
		preview_instance = null
		# Wait for the node to be freed
		await get_tree().process_frame
	
	# Load and show new character
	var scene_path = CHARACTER_SCENES.get(character, "")
	if scene_path.is_empty():
		print("Character selection: Invalid character path for: ", character)
		return
	
	var character_scene = load(scene_path)
	if character_scene == null:
		print("Character selection: Failed to load scene: ", scene_path)
		return
	
	preview_instance = character_scene.instantiate()
	if preview_instance == null:
		print("Character selection: Failed to instantiate character")
		return
	
	# Add to preview container
	if character_preview == null:
		print("Character selection: character_preview is null!")
		return
		
	character_preview.add_child(preview_instance)
	# Position relative to CharacterPreview node (which is already at viewport center)
	# Character is scaled 1.5x, sprite is offset by -16 on Y axis
	# Since CharacterPreview is at (252, 116), position character at origin relative to it
	preview_instance.position = Vector2(0, 0)
	preview_instance.visible = true
	preview_instance.modulate = Color.WHITE
	
	# Make sure sprite is visible and properly configured
	if preview_instance.has_node("AnimationSprites"):
		var sprite = preview_instance.get_node("AnimationSprites")
		if sprite:
			sprite.visible = true
			sprite.modulate = Color.WHITE
			# Ensure sprite frames are loaded
			if sprite.sprite_frames:
				print("Character selection: Sprite frames loaded, available animations: ", sprite.sprite_frames.get_animation_names())
			print("Character selection: Sprite is visible, animation: ", sprite.animation, ", position: ", sprite.position)
	
	# Wait a frame for the node to be fully added to the scene tree
	await get_tree().process_frame
	
	# Ensure camera is current and properly configured
	var subviewport = character_preview.get_parent()
	if subviewport and subviewport.has_node("Camera2D"):
		var camera = subviewport.get_node("Camera2D")
		# Make camera current (this is the correct way in Godot 4)
		camera.make_current()
		# Zoom in a bit to make character more visible
		if camera.zoom == Vector2(1, 1):
			camera.zoom = Vector2(2, 2)
		print("Character selection: Camera set to current at position ", camera.position, " zoom: ", camera.zoom)
	
	# Disable physics processing to prevent movement/crashes
	if is_instance_valid(preview_instance):
		preview_instance.set_physics_process(false)
		preview_instance.set_physics_process_internal(false)
		
		# Disable player movement in preview
		if "can_move" in preview_instance:
			preview_instance.can_move = false
		
		# Make sure the character is visible first
		preview_instance.visible = true
		preview_instance.modulate = Color.WHITE
		
		# Disable the character's built-in camera if it exists (it conflicts with SubViewport camera)
		# In SubViewport, only one camera can be current, so the character's camera won't interfere
		if preview_instance.has_node("Camera"):
			var char_camera = preview_instance.get_node("Camera")
			# Just disable it - don't try to set current property
			char_camera.enabled = false
			print("Character selection: Disabled character's built-in camera")
		
		# Ensure idle animation plays on AnimatedSprite2D
		if preview_instance.has_node("AnimationSprites"):
			var sprite = preview_instance.get_node("AnimationSprites")
			if sprite:
				sprite.visible = true
				sprite.modulate = Color.WHITE
				# Force animation to idle
				sprite.animation = "idle_animation"
				sprite.play()
				# Wait a frame and check again
				await get_tree().process_frame
				if sprite.animation != "idle_animation":
					sprite.animation = "idle_animation"
					sprite.play()
				print("Character selection: Sprite animation: ", sprite.animation, ", playing: ", sprite.is_playing(), ", visible: ", sprite.visible)
		else:
			print("Character selection: AnimationSprites node not found!")
		
		# Also try AnimationPlayer if it exists
		if preview_instance.has_node("Animations"):
			var anim_player = preview_instance.get_node("Animations")
			if anim_player:
				if anim_player.has_animation("idle_animation"):
					anim_player.play("idle_animation")
					print("Character selection: Playing animation on AnimationPlayer")
				elif anim_player.has_animation("RESET"):
					anim_player.play("RESET")
		
		# Debug: Print character tree structure
		print("Character selection: Character tree:")
		_print_node_tree(preview_instance, 0)
		
		print("Character selection: Successfully loaded ", character, " character at position ", preview_instance.position, " (global: ", preview_instance.global_position, ")")

func _print_node_tree(node: Node, indent: int = 0) -> void:
	var indent_str = "  ".repeat(indent)
	print(indent_str, node.name, " (", node.get_class(), ") visible=", node.visible if "visible" in node else "N/A")
	for child in node.get_children():
		_print_node_tree(child, indent + 1)

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
