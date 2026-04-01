extends Node2D

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_panel: Panel = $PauseMenu/PausePanel
@onready var info_popup_container = $infoPopup/Overlay/HBoxContainer/InfoVboxContainer
@onready var select_button = $infoPopup/Overlay/HBoxContainer/SelectConfirmButton
@onready var camera = $playerPlaceholder/Camera
var popup_height = 300
var is_paused: bool = false
var http_client: Node
var chores: Array = []
var current_chore_index: int = 0
var current_chore: Dictionary = {}
var user_points: int = 0
var chore_avatars_container: Node2D
var chore_avatar_scene: PackedScene
## When true (opened from an animal), arrow keys cannot change chores; UI shows one chore only.
var chore_popup_single_chore_only: bool = false
var _walkable_feet_cache: Array[Vector2] = []
var _walkable_feet_cache_built: bool = false
## Match chore_avatar.gd FEET_ART_CLEARANCE_PX (feet above tile collider top for sprite padding).
const CHORE_AVATAR_FEET_CLEARANCE_LOCAL := 12.0

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
	
	# Setup select button for completing chores
	if select_button:
		select_button.text = "Complete"
		# Connect the button press signal
		if not select_button.pressed.is_connected(_on_complete_chore_pressed):
			select_button.pressed.connect(_on_complete_chore_pressed)
	
	# Setup HUD
	_setup_hud()
	
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
	
	for child in chore_avatars_container.get_children():
		child.queue_free()
	
	if chores.is_empty():
		return
	
	_build_walkable_feet_cache()
	
	var n: int = chores.size()
	# Random unique hand-placed coordinates (one spawn point per chore)
	var positions: Array[Vector2] = WorldExplorerPositions.random_positions_no_repeat(n)
	# Random permutation: each chore from the DB appears on exactly one animal
	var chore_perm: Array = []
	for i in range(n):
		chore_perm.append(i)
	chore_perm.shuffle()
	
	for slot in range(n):
		var chore_idx: int = chore_perm[slot]
		var pos: Vector2 = positions[slot]
		var animal_type: int = randi() % 6
		
		var avatar: Node2D = chore_avatar_scene.instantiate()
		avatar.position = pos
		avatar.name = "ChoreAvatar_chore%d" % chore_idx
		avatar.set("chore_index", chore_idx)
		chore_avatars_container.add_child(avatar)
		if avatar.has_method("setup"):
			avatar.call_deferred("setup", chore_idx, animal_type)
		if avatar.has_signal("player_entered"):
			avatar.player_entered.connect(_on_chore_avatar_player_near)
		if avatar.has_signal("player_exited"):
			avatar.player_exited.connect(_on_chore_avatar_player_far)


## Tilemap surface tops (feet positions) for fallback when ray hits a wall / bad spot.
func _build_walkable_feet_cache() -> void:
	if _walkable_feet_cache_built:
		return
	_walkable_feet_cache.clear()
	var tilemaps: Array[TileMapLayer] = []
	for layer_name in ["TileMapLayerMid", "TileMapLayerBack", "TileMapLayerFront"]:
		var tm: TileMapLayer = get_node_or_null(layer_name) as TileMapLayer
		if tm:
			tilemaps.append(tm)
	if tilemaps.is_empty():
		_walkable_feet_cache_built = true
		return
	var tile_h := 16.0
	if tilemaps[0].tile_set:
		tile_h = float(tilemaps[0].tile_set.tile_size.y)
	var all_occupied: Dictionary = {}
	for tilemap in tilemaps:
		for cell in tilemap.get_used_cells():
			var key := "%d,%d" % [cell.x, cell.y]
			all_occupied[key] = true
	var ref_tm: TileMapLayer = tilemaps[0]
	for key in all_occupied:
		var parts = key.split(",")
		var cx := int(parts[0])
		var cy := int(parts[1])
		var above_key := "%d,%d" % [cx, cy - 1]
		if above_key not in all_occupied:
			var center_local: Vector2 = ref_tm.map_to_local(Vector2i(cx, cy))
			var local_feet := Vector2(center_local.x, center_local.y - tile_h * 0.5 - CHORE_AVATAR_FEET_CLEARANCE_LOCAL)
			_walkable_feet_cache.append(ref_tm.to_global(local_feet))
	_walkable_feet_cache_built = true


func _nearest_walkable_feet_global(from_global: Vector2) -> Vector2:
	if _walkable_feet_cache.is_empty():
		return from_global
	var best: Vector2 = _walkable_feet_cache[0]
	var best_d2: float = from_global.distance_squared_to(best)
	for p in _walkable_feet_cache:
		var d2: float = from_global.distance_squared_to(p)
		if d2 < best_d2:
			best_d2 = d2
			best = p
	return best


func snap_chore_avatar_to_walkable_surface(avatar: Node2D) -> void:
	if avatar == null:
		return
	_build_walkable_feet_cache()
	if _walkable_feet_cache.is_empty():
		return
	avatar.global_position = _nearest_walkable_feet_global(avatar.global_position)


func _player_overlaps_any_chore_avatar() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or chore_avatars_container == null:
		return false
	for child in chore_avatars_container.get_children():
		var area: Area2D = child.get_node_or_null("ProximityArea") as Area2D
		if area and area.overlaps_body(player):
			return true
	return false


func _on_chore_avatar_player_far(chore_index: int) -> void:
	# Defer so entering another animal's area in the same frame still registers
	call_deferred("_try_hide_popup_after_leaving_chore_avatar", chore_index)


func _try_hide_popup_after_leaving_chore_avatar(chore_index: int) -> void:
	if not chore_popup_single_chore_only:
		return
	if not $infoPopup.visible:
		return
	if current_chore_index != chore_index:
		return
	if _player_overlaps_any_chore_avatar():
		return
	hide_info_popup()


func _on_chore_avatar_player_near(chore_index: int) -> void:
	if chore_index < 0 or chore_index >= chores.size():
		return
	chore_popup_single_chore_only = true
	current_chore_index = chore_index
	_show_chore_popup(current_chore_index)


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
	
	chore_popup_single_chore_only = false
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
	elif event.is_action_pressed("ui_left") and $infoPopup.visible and chores.size() > 1 and not chore_popup_single_chore_only:
		current_chore_index = (current_chore_index - 1 + chores.size()) % chores.size()
		_show_chore_popup(current_chore_index)
	elif event.is_action_pressed("ui_right") and $infoPopup.visible and chores.size() > 1 and not chore_popup_single_chore_only:
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
	chore_popup_single_chore_only = false

func _show_chore_popup(index: int):
	if index < 0 or index >= chores.size():
		return
	
	clear_popup_content()
	current_chore = chores[index]
	
	# Update title: from animals, show a single-chore header (no "2 of 3" or arrow browsing)
	var title_node = info_popup_container.get_node_or_null("Title")
	if title_node:
		if chore_popup_single_chore_only:
			title_node.text = "CHORE"
		else:
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
	
	# Navigation hint (only when browsing all chores from the menu, not from an animal)
	if chores.size() > 1 and not chore_popup_single_chore_only:
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
	chore_popup_single_chore_only = false
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
	hint_label.text = "Press ESC or Q to close"
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
		print("=== CHORE COMPLETE RESPONSE ===")
		print("Success: ", success)
		print("Data: ", data)
		
		if select_button:
			select_button.disabled = false
		
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
			if select_button:
				select_button.text = "I Did It!"
	)

func interact():
	if !$infoPopup.visible:
		if chores.is_empty():
			_show_message("No Chores", "No chores available.\nAsk your parent to add some!")
		else:
			chore_popup_single_chore_only = false
			current_chore_index = 0
			_show_chore_popup(current_chore_index)
	else:
		hide_info_popup()
