extends Node2D

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_panel: Panel = $PauseMenu/PausePanel
@onready var camera = $playerPlaceholder/Camera
var is_paused: bool = false
var http_client: Node
var chores: Array = []
var current_chore_index: int = 0
var current_chore: Dictionary = {}
var user_points: int = 0
var chore_avatars_container: Node2D
var chore_avatar_scene: PackedScene
var nearby_chore_index: int = -1  # Track which animal/chore the player is near
var is_browsing_all: bool = false  # True when using View Chores button, false when interacting with animal

# Dynamic popup UI (like reward scene)
var chore_popup: CanvasLayer
var popup_container: VBoxContainer
var complete_button: Button

# Fixed spawn positions for animals (hand-picked valid coordinates)
const SPAWN_POSITIONS: Array = [
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

func _ready():
	# Get HTTP client reference
	http_client = get_node("/root/HTTPClient")
	
	# Load selected character from HTTPClient
	var character_name = http_client.selected_character
	
	# Default to pink if no character selected
	if character_name.is_empty():
		character_name = "pink"
	
	# Map character name to scene path
	var character_scenes = {
		"blue": "res://characters/bluePlayer.tscn",
		"pink": "res://characters/pinkPlayer.tscn",
		"white": "res://characters/whitePlayer.tscn"
	}
	
	var scene_path = character_scenes.get(character_name, "res://characters/pinkPlayer.tscn")
	var player_scene = load(scene_path)
	var player_instance = player_scene.instantiate()
	
	# Add to placeholder
	$playerPlaceholder.add_child(player_instance)
	# Optionally center it or position it on the map
	player_instance.position = Vector2(0, 0)
	camera.reparent(player_instance)
	# Hide pause menu initially
	pause_menu.visible = false
	
	# Hide old infoPopup if it exists (we're using dynamic popup now)
	var old_popup = get_node_or_null("infoPopup")
	if old_popup:
		old_popup.visible = false
	
	# Setup HUD and chore popup
	_setup_hud()
	_setup_chore_popup()
	
	# Setup chore avatars container (animals placed in world for proximity-based chore display)
	chore_avatars_container = Node2D.new()
	chore_avatars_container.name = "ChoreAvatarsContainer"
	add_child(chore_avatars_container)
	# Ensure avatars render above tilemap, in front of player
	chore_avatars_container.z_index = 5
	
	chore_avatar_scene = load("res://chore_avatar.tscn") as PackedScene
	
	# Fetch chores and user data from backend
	_load_data()

func _setup_hud():
	# Create HUD layer for points display
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	add_child(hud)
	
	# Points display panel
	var points_panel = PanelContainer.new()
	points_panel.name = "PointsPanel"
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.12, 0.15, 0.9)
	panel_style.border_color = Color(0.3, 0.65, 0.45, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	points_panel.add_theme_stylebox_override("panel", panel_style)
	points_panel.position = Vector2(20, 20)
	hud.add_child(points_panel)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	points_panel.add_child(hbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	hbox.add_child(margin)
	
	var inner_hbox = HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 8)
	margin.add_child(inner_hbox)
	
	var star_label = Label.new()
	star_label.text = "Points:"
	star_label.add_theme_font_size_override("font_size", 20)
	star_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	inner_hbox.add_child(star_label)
	
	var points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "0"
	points_label.add_theme_font_size_override("font_size", 24)
	points_label.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
	inner_hbox.add_child(points_label)
	
	# Chores button
	var chores_btn = Button.new()
	chores_btn.name = "ChoresButton"
	chores_btn.text = "View Chores"
	chores_btn.add_theme_font_size_override("font_size", 16)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.5, 0.35, 1)
	btn_style.set_corner_radius_all(6)
	chores_btn.add_theme_stylebox_override("normal", btn_style)
	chores_btn.position = Vector2(200, 20)
	chores_btn.custom_minimum_size = Vector2(120, 40)
	chores_btn.pressed.connect(_on_chores_button_pressed)
	hud.add_child(chores_btn)
	
	# Back button
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "Back"
	back_btn.add_theme_font_size_override("font_size", 16)
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.4, 0.35, 0.5, 1)
	back_style.set_corner_radius_all(6)
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.position = Vector2(340, 20)
	back_btn.custom_minimum_size = Vector2(80, 40)
	back_btn.pressed.connect(_on_back_button_pressed)
	hud.add_child(back_btn)

func _setup_chore_popup():
	# Create chore popup overlay (same style as reward popup)
	chore_popup = CanvasLayer.new()
	chore_popup.name = "ChorePopup"
	chore_popup.layer = 50
	chore_popup.visible = false
	add_child(chore_popup)
	
	# Background overlay
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	chore_popup.add_child(overlay)
	
	# Main panel
	var panel = PanelContainer.new()
	panel.name = "Panel"
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.12, 0.95)
	panel_style.border_color = Color(0.3, 0.65, 0.45, 1)  # Green tint for chores
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(500, 350)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -175
	panel.offset_bottom = 175
	chore_popup.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)
	
	popup_container = VBoxContainer.new()
	popup_container.name = "Container"
	popup_container.add_theme_constant_override("separation", 15)
	margin.add_child(popup_container)
	
	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "CHORE"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.65, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_container.add_child(title)
	
	# Button container
	var btn_hbox = HBoxContainer.new()
	btn_hbox.name = "ButtonContainer"
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	popup_container.add_child(btn_hbox)
	
	# Complete button
	complete_button = Button.new()
	complete_button.name = "CompleteButton"
	complete_button.text = "I Did It!"
	complete_button.add_theme_font_size_override("font_size", 18)
	complete_button.custom_minimum_size = Vector2(120, 45)
	var complete_style = StyleBoxFlat.new()
	complete_style.bg_color = Color(0.2, 0.5, 0.35, 1)
	complete_style.set_corner_radius_all(6)
	complete_button.add_theme_stylebox_override("normal", complete_style)
	complete_button.pressed.connect(_on_complete_chore_pressed)
	btn_hbox.add_child(complete_button)
	
	# Close button
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.custom_minimum_size = Vector2(100, 45)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.5, 0.3, 0.3, 1)
	close_style.set_corner_radius_all(6)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(_hide_chore_popup)
	btn_hbox.add_child(close_btn)

func _load_data():
	# Fetch user data to get current points
	user_points = http_client.user_data.get("points", 0)
	_update_points_display()
	
	# Fetch chores from backend
	http_client.get_chores(func(success, data):
		if success and data is Array:
			chores = data
			print("Loaded ", chores.size(), " chores from backend")
			_spawn_chore_avatars()
		else:
			chores = []
			print("Failed to load chores or no chores available")
			_spawn_chore_avatars()
	)

func _spawn_chore_avatars():
	if not chore_avatars_container or not chore_avatar_scene:
		return
	
	# Remove existing avatars
	for child in chore_avatars_container.get_children():
		child.queue_free()
	
	if chores.is_empty():
		return
	
	# Shuffle positions randomly so animals appear at different locations each time
	var shuffled_positions = SPAWN_POSITIONS.duplicate()
	shuffled_positions.shuffle()
	
	# Only spawn as many animals as we have unique positions (no duplicates)
	var spawn_count = min(chores.size(), shuffled_positions.size())
	
	for i in range(spawn_count):
		var pos: Vector2 = shuffled_positions[i]
		
		var avatar: Node2D = chore_avatar_scene.instantiate()
		avatar.position = pos
		avatar.name = "ChoreAvatar_%d" % i
		chore_avatars_container.add_child(avatar)
		
		if avatar.has_method("setup"):
			avatar.setup(i, i % 6)
		
		if avatar.has_signal("player_entered"):
			avatar.player_entered.connect(_on_chore_avatar_player_entered)
		if avatar.has_signal("player_exited"):
			avatar.player_exited.connect(_on_chore_avatar_player_exited)
	
	print("Spawned ", spawn_count, " chore animals at random positions")


func _on_chore_avatar_player_entered(chore_index: int) -> void:
	# Just track which animal is nearby, don't show popup automatically
	if chore_index >= 0 and chore_index < chores.size():
		nearby_chore_index = chore_index
		print("Near animal for chore: ", chores[chore_index].get("title", "Unknown"))


func _on_chore_avatar_player_exited(chore_index: int) -> void:
	# Clear nearby tracking when player leaves
	if nearby_chore_index == chore_index:
		nearby_chore_index = -1
		print("Left animal area")


func _update_points_display():
	var hud = get_node_or_null("HUD")
	if hud:
		var points_panel = hud.get_node_or_null("PointsPanel")
		if points_panel:
			var points_label = points_panel.get_node("HBoxContainer/MarginContainer/HBoxContainer/PointsLabel")
			if points_label:
				points_label.text = str(user_points)

func _on_chores_button_pressed():
	if chores.is_empty():
		_show_message("No chores available!", "Ask your parent to add some chores.")
		return
	
	is_browsing_all = true
	current_chore_index = 0
	_show_chore_popup(current_chore_index)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://character_selection.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if chore_popup.visible:
			_hide_chore_popup()
		else:
			toggle_pause()
	elif event.is_action_pressed("interact"):
		interact()
	# Arrow key navigation only when browsing all chores (via View Chores button)
	elif event.is_action_pressed("ui_left") and chore_popup.visible and is_browsing_all and chores.size() > 1:
		current_chore_index = (current_chore_index - 1 + chores.size()) % chores.size()
		_show_chore_popup(current_chore_index)
	elif event.is_action_pressed("ui_right") and chore_popup.visible and is_browsing_all and chores.size() > 1:
		current_chore_index = (current_chore_index + 1) % chores.size()
		_show_chore_popup(current_chore_index)

func toggle_pause():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused

func _on_resume_pressed():
	toggle_pause()

func _on_main_menu_pressed():
	get_tree().paused = false
	http_client.logout()
	get_tree().change_scene_to_file("res://login.tscn")

func _on_next_level_body_entered(body):
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://reward_xplorer.tscn")

func _hide_chore_popup():
	chore_popup.visible = false
	current_chore = {}
	is_browsing_all = false
	if complete_button:
		complete_button.visible = true

func _show_chore_popup(index: int):
	if index < 0 or index >= chores.size():
		return
	
	_clear_popup_content()
	current_chore = chores[index]
	
	# Update title based on browsing mode
	var title = popup_container.get_node_or_null("Title")
	if title:
		if is_browsing_all:
			title.text = "CHORE " + str(index + 1) + " of " + str(chores.size())
		else:
			title.text = "THIS ANIMAL'S CHORE"
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color(0.3, 0.65, 0.45))
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 5)
	popup_container.add_child(spacer1)
	popup_container.move_child(spacer1, 1)
	
	# Chore title - big and prominent
	var title_label = Label.new()
	title_label.text = current_chore.get("title", "Untitled")
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_container.add_child(title_label)
	popup_container.move_child(title_label, 2)
	
	# Description
	var desc = current_chore.get("description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(400, 0)
		popup_container.add_child(desc_label)
		popup_container.move_child(desc_label, 3)
	
	# Points reward - highlighted
	var points_container = HBoxContainer.new()
	points_container.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_container.add_child(points_container)
	popup_container.move_child(points_container, popup_container.get_child_count() - 1)
	
	var star_label = Label.new()
	star_label.text = "Reward: "
	star_label.add_theme_font_size_override("font_size", 20)
	star_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
	points_container.add_child(star_label)
	
	var points_label = Label.new()
	points_label.text = "+" + str(current_chore.get("points", 0)) + " points"
	points_label.add_theme_font_size_override("font_size", 22)
	points_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	points_container.add_child(points_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	popup_container.add_child(spacer2)
	popup_container.move_child(spacer2, popup_container.get_child_count() - 1)
	
	# Update complete button
	if complete_button:
		complete_button.text = "I Did It!"
		complete_button.visible = true
		complete_button.disabled = false
	
	# Navigation hint depends on mode
	if chores.size() > 1:
		var nav_label = Label.new()
		if is_browsing_all:
			nav_label.text = "Use Arrow Keys to browse chores"
		else:
			nav_label.text = "Find " + str(chores.size() - 1) + " other animals for more chores!"
		nav_label.add_theme_font_size_override("font_size", 13)
		nav_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		popup_container.add_child(nav_label)
		popup_container.move_child(nav_label, popup_container.get_child_count() - 1)
	
	chore_popup.visible = true

func _show_message(title_text: String, message: String):
	_clear_popup_content()
	current_chore = {}
	
	var title = popup_container.get_node_or_null("Title")
	if title:
		title.text = title_text
		# Color based on message type
		if "SENT" in title_text or "COMPLETED" in title_text:
			title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			title.add_theme_font_size_override("font_size", 26)
		elif "OOPS" in title_text or "ERROR" in title_text:
			title.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
			title.add_theme_font_size_override("font_size", 24)
		else:
			title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
			title.add_theme_font_size_override("font_size", 24)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	popup_container.add_child(spacer)
	popup_container.move_child(spacer, 1)
	
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.custom_minimum_size = Vector2(350, 0)
	popup_container.add_child(msg_label)
	popup_container.move_child(msg_label, 2)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	popup_container.add_child(spacer2)
	popup_container.move_child(spacer2, 3)
	
	# Add a close hint
	var hint_label = Label.new()
	hint_label.text = "Press ESC or E to close"
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_container.add_child(hint_label)
	popup_container.move_child(hint_label, 4)
	
	if complete_button:
		complete_button.visible = false
	
	chore_popup.visible = true

func _clear_popup_content():
	# Keep Title and ButtonContainer, remove everything else
	var to_remove = []
	for child in popup_container.get_children():
		if child.name != "Title" and child.name != "ButtonContainer":
			to_remove.append(child)
	
	for child in to_remove:
		popup_container.remove_child(child)
		child.queue_free()

func _on_complete_chore_pressed():
	if current_chore.is_empty():
		return
	
	var chore_id = current_chore.get("id", "")
	if chore_id == "":
		return
	
	# Disable button while processing
	if complete_button:
		complete_button.text = "Sending..."
		complete_button.disabled = true
	
	http_client.complete_chore(chore_id, func(success, data):
		print("=== CHORE COMPLETE RESPONSE ===")
		print("Success: ", success)
		print("Data: ", data)
		
		if complete_button:
			complete_button.disabled = false
		
		if success:
			var is_pending = data.get("pending", false)
			var points = data.get("points", 0)
			
			print("Is Pending: ", is_pending)
			print("Points in response: ", points)
			
			if is_pending:
				# New workflow: waiting for parent approval - DO NOT update points!
				print("PENDING MODE - Points NOT added to child")
				_show_message("REQUEST SENT!", "Waiting for parent to approve.\n\nYou'll get +" + str(points) + " points when approved!")
			else:
				# Old workflow (if backend doesn't support pending) - this should NOT happen
				print("WARNING: Old workflow triggered - backend may be outdated!")
				var points_earned = data.get("points", 0)
				user_points = data.get("totalPoints", user_points + points_earned)
				http_client.user_data["points"] = user_points
				_update_points_display()
				_show_message("COMPLETED!", "You earned " + str(points_earned) + " points!")
			
			print("Chore completion requested for ", current_chore.get("title", ""))
		else:
			var error_msg = "Failed to send request"
			if data is Dictionary:
				error_msg = data.get("error", error_msg)
			print("ERROR: ", error_msg)
			_show_message("OOPS!", str(error_msg))
			if complete_button:
				complete_button.text = "I Did It!"
	)

func interact():
	if not chore_popup.visible:
		# Check if player is near an animal
		if nearby_chore_index >= 0 and nearby_chore_index < chores.size():
			# Show the specific chore for this animal (not browsing all)
			is_browsing_all = false
			current_chore_index = nearby_chore_index
			_show_chore_popup(current_chore_index)
		elif chores.is_empty():
			_show_message("No Chores", "No chores available.\nAsk your parent to add some!")
		else:
			_show_message("Find an Animal", "Walk up to an animal and press E to see its chore!")
	else:
		_hide_chore_popup()
