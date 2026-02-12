extends Node2D

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_panel: Panel = $PauseMenu/PausePanel
@onready var info_popup_container = $infoPopup/Overlay/HBoxContainer/InfoVboxContainer
@onready var select_button = $infoPopup/Overlay/HBoxContainer/SelectConfirmButton

var popup_height = 300
var is_paused: bool = false
var http_client: Node
var chores: Array = []
var current_chore_index: int = 0
var current_chore: Dictionary = {}
var user_points: int = 0

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
	
	# Hide pause menu initially
	pause_menu.visible = false
	
	# Setup select button for completing chores
	if select_button:
		select_button.text = "Complete"
		# Connect the button press signal
		if not select_button.pressed.is_connected(_on_complete_chore_pressed):
			select_button.pressed.connect(_on_complete_chore_pressed)
	
	# Setup HUD
	_setup_hud()
	
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

func _load_data():
	# Fetch user data to get current points
	user_points = http_client.user_data.get("points", 0)
	_update_points_display()
	
	# Fetch chores from backend
	http_client.get_chores(func(success, data):
		if success and data is Array:
			chores = data
			print("Loaded ", chores.size(), " chores from backend")
		else:
			chores = []
			print("Failed to load chores or no chores available")
	)

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
	
	current_chore_index = 0
	_show_chore_popup(current_chore_index)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://character_selection.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if $infoPopup.visible:
			hide_info_popup()
		else:
			toggle_pause()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("ui_left") and $infoPopup.visible and chores.size() > 1:
		current_chore_index = (current_chore_index - 1 + chores.size()) % chores.size()
		_show_chore_popup(current_chore_index)
	elif event.is_action_pressed("ui_right") and $infoPopup.visible and chores.size() > 1:
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

func hide_info_popup():
	clear_popup_content()
	$infoPopup.hide()
	current_chore = {}

func _show_chore_popup(index: int):
	if index < 0 or index >= chores.size():
		return
	
	clear_popup_content()
	current_chore = chores[index]
	
	# Update title with nice formatting
	var title_node = info_popup_container.get_node_or_null("Title")
	if title_node:
		title_node.text = "CHORE " + str(index + 1) + " of " + str(chores.size())
		title_node.add_theme_font_size_override("font_size", 18)
		title_node.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 5)
	info_popup_container.add_child(spacer1)
	
	# Chore title - big and prominent
	var title_label = Label.new()
	title_label.text = current_chore.get("title", "Untitled")
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_popup_container.add_child(title_label)
	
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
		info_popup_container.add_child(desc_label)
	
	# Points reward - highlighted
	var points_container = HBoxContainer.new()
	points_container.alignment = BoxContainer.ALIGNMENT_CENTER
	info_popup_container.add_child(points_container)
	
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
	info_popup_container.add_child(spacer2)
	
	# Navigation hint
	if chores.size() > 1:
		var nav_label = Label.new()
		nav_label.text = "Use Arrow Keys to browse chores"
		nav_label.add_theme_font_size_override("font_size", 13)
		nav_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_popup_container.add_child(nav_label)
	
	# Update select button to be more child-friendly
	if select_button:
		select_button.text = "I Did It!"
		select_button.visible = true
		select_button.disabled = false
	
	$infoPopup.show()

func _show_message(title: String, message: String):
	clear_popup_content()
	current_chore = {}
	
	var title_node = info_popup_container.get_node_or_null("Title")
	if title_node:
		title_node.text = title
		# Color based on message type
		if "SENT" in title or "COMPLETED" in title:
			title_node.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			title_node.add_theme_font_size_override("font_size", 26)
		elif "OOPS" in title or "ERROR" in title:
			title_node.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
			title_node.add_theme_font_size_override("font_size", 24)
		else:
			title_node.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
			title_node.add_theme_font_size_override("font_size", 24)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	info_popup_container.add_child(spacer)
	
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.custom_minimum_size = Vector2(350, 0)
	info_popup_container.add_child(msg_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	info_popup_container.add_child(spacer2)
	
	# Add a close hint
	var hint_label = Label.new()
	hint_label.text = "Press ESC or E to close"
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_popup_container.add_child(hint_label)
	
	if select_button:
		select_button.visible = false
	
	$infoPopup.show()

func show_info_popup(data: Dictionary):
	for key in data.keys():
		var label = Label.new()
		label.text = key + ": " + str(data[key])
		info_popup_container.add_child(label)
	$infoPopup.show()

func clear_popup_content():
	for child in info_popup_container.get_children():
		if str(child.name) != "Title":
			child.queue_free()

func _on_dismiss_button_button_down() -> void:
	if $infoPopup.visible:
		hide_info_popup()

func _on_complete_chore_pressed():
	if current_chore.is_empty():
		return
	
	var chore_id = current_chore.get("id", "")
	if chore_id == "":
		return
	
	# Disable button while processing
	if select_button:
		select_button.text = "Sending..."
		select_button.disabled = true
	
	http_client.complete_chore(chore_id, func(success, data):
		if select_button:
			select_button.disabled = false
		
		if success:
			var is_pending = data.get("pending", false)
			var points = data.get("points", 0)
			
			if is_pending:
				# New workflow: waiting for parent approval
				_show_message("REQUEST SENT!", "Waiting for parent to approve.\n\nYou'll get +" + str(points) + " points when approved!")
			else:
				# Old workflow (if backend doesn't support pending)
				var points_earned = data.get("points", 0)
				user_points = data.get("totalPoints", user_points + points_earned)
				http_client.user_data["points"] = user_points
				_update_points_display()
				_show_message("COMPLETED!", "You earned " + str(points_earned) + " points!")
			
			print("Chore completion requested for ", current_chore.get("title", ""))
		else:
			var error = data.get("error", "Failed to send request")
			_show_message("OOPS!", error)
			if select_button:
				select_button.text = "Done!"
	)

func interact():
	if !$infoPopup.visible:
		if chores.is_empty():
			_show_message("No Chores", "No chores available.\nAsk your parent to add some!")
		else:
			current_chore_index = 0
			_show_chore_popup(current_chore_index)
	else:
		hide_info_popup()
