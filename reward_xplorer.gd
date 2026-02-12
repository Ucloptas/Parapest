extends Node2D

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_panel: Panel = $PauseMenu/PausePanel

var is_paused: bool = false
var http_client: Node
var rewards: Array = []
var current_reward_index: int = 0
var current_reward: Dictionary = {}
var user_points: int = 0

# UI references (created dynamically)
var reward_popup: CanvasLayer
var popup_container: VBoxContainer
var redeem_button: Button

func _ready():
	# Get HTTP client reference
	http_client = get_node("/root/HTTPClient")
	
	# Load selected character
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
	player_instance.position = Vector2(0, 0)
	
	# Hide pause menu initially
	pause_menu.visible = false
	
	# Setup HUD and reward popup
	_setup_hud()
	_setup_reward_popup()
	
	# Fetch rewards and user data
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
	panel_style.border_color = Color(0.55, 0.7, 0.9, 1)
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
	points_label.add_theme_color_override("font_color", Color(0.55, 0.7, 0.9))
	inner_hbox.add_child(points_label)
	
	# Rewards button
	var rewards_btn = Button.new()
	rewards_btn.name = "RewardsButton"
	rewards_btn.text = "View Rewards"
	rewards_btn.add_theme_font_size_override("font_size", 16)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.4, 0.55, 0.7, 1)
	btn_style.set_corner_radius_all(6)
	rewards_btn.add_theme_stylebox_override("normal", btn_style)
	rewards_btn.position = Vector2(200, 20)
	rewards_btn.custom_minimum_size = Vector2(130, 40)
	rewards_btn.pressed.connect(_on_rewards_button_pressed)
	hud.add_child(rewards_btn)
	
	# Back to Chores button
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "Chores"
	back_btn.add_theme_font_size_override("font_size", 16)
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.2, 0.5, 0.35, 1)
	back_style.set_corner_radius_all(6)
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.position = Vector2(350, 20)
	back_btn.custom_minimum_size = Vector2(80, 40)
	back_btn.pressed.connect(_on_back_to_chores_pressed)
	hud.add_child(back_btn)

func _setup_reward_popup():
	# Create reward popup overlay
	reward_popup = CanvasLayer.new()
	reward_popup.name = "RewardPopup"
	reward_popup.layer = 50
	reward_popup.visible = false
	add_child(reward_popup)
	
	# Background overlay
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	reward_popup.add_child(overlay)
	
	# Main panel
	var panel = PanelContainer.new()
	panel.name = "Panel"
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.12, 0.95)
	panel_style.border_color = Color(0.55, 0.7, 0.9, 1)
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
	reward_popup.add_child(panel)
	
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
	title.text = "REWARDS SHOP"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.55, 0.7, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_container.add_child(title)
	
	# Button container
	var btn_hbox = HBoxContainer.new()
	btn_hbox.name = "ButtonContainer"
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	popup_container.add_child(btn_hbox)
	
	# Redeem button
	redeem_button = Button.new()
	redeem_button.name = "RedeemButton"
	redeem_button.text = "Redeem"
	redeem_button.add_theme_font_size_override("font_size", 18)
	redeem_button.custom_minimum_size = Vector2(120, 45)
	var redeem_style = StyleBoxFlat.new()
	redeem_style.bg_color = Color(0.4, 0.55, 0.7, 1)
	redeem_style.set_corner_radius_all(6)
	redeem_button.add_theme_stylebox_override("normal", redeem_style)
	redeem_button.pressed.connect(_on_redeem_pressed)
	btn_hbox.add_child(redeem_button)
	
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
	close_btn.pressed.connect(_hide_reward_popup)
	btn_hbox.add_child(close_btn)

func _load_data():
	# Get current points from user data
	user_points = http_client.user_data.get("points", 0)
	_update_points_display()
	
	# Fetch rewards from backend
	http_client.get_rewards(func(success, data):
		if success and data is Array:
			rewards = data
			print("Loaded ", rewards.size(), " rewards from backend")
		else:
			rewards = []
			print("Failed to load rewards or no rewards available")
	)

func _update_points_display():
	var hud = get_node_or_null("HUD")
	if hud:
		var points_panel = hud.get_node_or_null("PointsPanel")
		if points_panel:
			var points_label = points_panel.get_node("HBoxContainer/MarginContainer/HBoxContainer/PointsLabel")
			if points_label:
				points_label.text = str(user_points)

func _on_rewards_button_pressed():
	if rewards.is_empty():
		_show_reward_message("No Rewards", "No rewards available yet.\nAsk your parent to add some!")
		return
	
	current_reward_index = 0
	_show_reward_popup(current_reward_index)

func _on_back_to_chores_pressed():
	get_tree().change_scene_to_file("res://chore_xplorer.tscn")

func _show_reward_popup(index: int):
	if index < 0 or index >= rewards.size():
		return
	
	_clear_popup_content()
	current_reward = rewards[index]
	
	# Update title with nice formatting
	var title = popup_container.get_node_or_null("Title")
	if title:
		title.text = "REWARD " + str(index + 1) + " of " + str(rewards.size())
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 5)
	popup_container.add_child(spacer1)
	popup_container.move_child(spacer1, 1)
	
	# Reward name - big and prominent
	var name_label = Label.new()
	name_label.text = current_reward.get("title", "Untitled")
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_container.add_child(name_label)
	popup_container.move_child(name_label, 2)
	
	# Description
	var desc = current_reward.get("description", "")
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
	
	# Cost display with affordability indication
	var cost = current_reward.get("cost", 0)
	var can_afford = user_points >= cost
	
	var cost_container = HBoxContainer.new()
	cost_container.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_container.add_child(cost_container)
	popup_container.move_child(cost_container, popup_container.get_child_count() - 1)
	
	var cost_prefix = Label.new()
	cost_prefix.text = "Cost: "
	cost_prefix.add_theme_font_size_override("font_size", 20)
	cost_prefix.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
	cost_container.add_child(cost_prefix)
	
	var cost_label = Label.new()
	cost_label.text = str(cost) + " points"
	cost_label.add_theme_font_size_override("font_size", 22)
	if can_afford:
		cost_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	else:
		cost_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
	cost_container.add_child(cost_label)
	
	# Your points display
	var your_points_label = Label.new()
	your_points_label.text = "(You have: " + str(user_points) + " points)"
	your_points_label.add_theme_font_size_override("font_size", 15)
	your_points_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	your_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_container.add_child(your_points_label)
	popup_container.move_child(your_points_label, popup_container.get_child_count() - 1)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	popup_container.add_child(spacer2)
	popup_container.move_child(spacer2, popup_container.get_child_count() - 1)
	
	# Update redeem button state - always enabled so user can see message
	if redeem_button:
		redeem_button.disabled = false
		if can_afford:
			redeem_button.text = "Get This!"
			# Green style for affordable
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.2, 0.45, 0.3, 1)
			btn_style.set_corner_radius_all(6)
			redeem_button.add_theme_stylebox_override("normal", btn_style)
		else:
			redeem_button.text = "Get This!"
			# Red style for not affordable
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.35, 0.2, 0.2, 1)
			btn_style.set_corner_radius_all(6)
			redeem_button.add_theme_stylebox_override("normal", btn_style)
	
	# Navigation hint
	if rewards.size() > 1:
		var nav_label = Label.new()
		nav_label.text = "Use Arrow Keys to browse rewards"
		nav_label.add_theme_font_size_override("font_size", 13)
		nav_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		popup_container.add_child(nav_label)
		popup_container.move_child(nav_label, popup_container.get_child_count() - 1)
	
	reward_popup.visible = true

func _show_reward_message(title_text: String, message: String):
	_clear_popup_content()
	current_reward = {}
	
	var title = popup_container.get_node_or_null("Title")
	if title:
		title.text = title_text
		# Color based on message type
		if "REDEEMED" in title_text or "SUCCESS" in title_text:
			title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			title.add_theme_font_size_override("font_size", 26)
		elif "ERROR" in title_text or "FAILED" in title_text:
			title.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
			title.add_theme_font_size_override("font_size", 24)
		else:
			title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
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
	
	if redeem_button:
		redeem_button.visible = false
	
	reward_popup.visible = true

func _hide_reward_popup():
	reward_popup.visible = false
	current_reward = {}
	if redeem_button:
		redeem_button.visible = true

func _clear_popup_content():
	# Keep Title and ButtonContainer, remove everything else
	var to_remove = []
	for child in popup_container.get_children():
		if child.name != "Title" and child.name != "ButtonContainer":
			to_remove.append(child)
	
	for child in to_remove:
		popup_container.remove_child(child)
		child.queue_free()

func _on_redeem_pressed():
	if current_reward.is_empty():
		return
	
	var reward_id = current_reward.get("id", "")
	if reward_id == "":
		return
	
	var cost = current_reward.get("cost", 0)
	if user_points < cost:
		var needed = cost - user_points
		_show_reward_message("NOT ENOUGH POINTS!", "This reward costs " + str(cost) + " points.\n\nYou have " + str(user_points) + " points.\n\nYou need " + str(needed) + " more points!\n\nComplete more chores to earn points.")
		return
	
	# Disable button while processing
	if redeem_button:
		redeem_button.text = "..."
		redeem_button.disabled = true
	
	http_client.redeem_reward(reward_id, func(success, data):
		if redeem_button:
			redeem_button.disabled = false
		
		if success:
			user_points = data.get("remainingPoints", user_points - cost)
			
			# Update HTTPClient user data
			http_client.user_data["points"] = user_points
			
			_update_points_display()
			
			# Show success message
			_show_reward_message("REDEEMED!", "You got: " + current_reward.get("title", "Reward") + "\n\nRemaining points: " + str(user_points))
			
			print("Reward redeemed! Remaining points: ", user_points)
		else:
			var error = data.get("error", "Failed to redeem reward")
			_show_reward_message("ERROR", error)
			if redeem_button:
				redeem_button.text = "Redeem"
	)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if reward_popup.visible:
			_hide_reward_popup()
		else:
			toggle_pause()
	elif event.is_action_pressed("interact"):
		if not reward_popup.visible:
			_on_rewards_button_pressed()
		else:
			_hide_reward_popup()
	elif event.is_action_pressed("ui_left") and reward_popup.visible and rewards.size() > 1:
		current_reward_index = (current_reward_index - 1 + rewards.size()) % rewards.size()
		_show_reward_popup(current_reward_index)
	elif event.is_action_pressed("ui_right") and reward_popup.visible and rewards.size() > 1:
		current_reward_index = (current_reward_index + 1) % rewards.size()
		_show_reward_popup(current_reward_index)

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
