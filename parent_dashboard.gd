extends Control

# UI references
@onready var welcome_label: Label = %WelcomeLabel
@onready var family_id_label: Label = %FamilyIDLabel
@onready var btn_logout: Button = %BtnLogout

@onready var tab_container: TabContainer = %TabContainer

# Chores tab
@onready var chores_list: VBoxContainer = %ChoresList
@onready var btn_add_chore: Button = %BtnAddChore

# Rewards tab
@onready var rewards_list: VBoxContainer = %RewardsList
@onready var btn_add_reward: Button = %BtnAddReward

# Family tab
@onready var family_list: VBoxContainer = %FamilyList

# History tab
@onready var completed_chores_list: VBoxContainer = %CompletedChoresList
@onready var redeemed_rewards_list: VBoxContainer = %RedeemedRewardsList

# Dialogs
@onready var chore_dialog: Window = %ChoreDialog
@onready var chore_title_input: LineEdit = %ChoreTitleInput
@onready var chore_desc_input: TextEdit = %ChoreDescInput
@onready var chore_points_input: SpinBox = %ChorePointsInput
@onready var btn_save_chore: Button = %BtnSaveChore
@onready var btn_cancel_chore: Button = %BtnCancelChore

@onready var reward_dialog: Window = %RewardDialog
@onready var reward_title_input: LineEdit = %RewardTitleInput
@onready var reward_desc_input: TextEdit = %RewardDescInput
@onready var reward_cost_input: SpinBox = %RewardCostInput
@onready var btn_save_reward: Button = %BtnSaveReward
@onready var btn_cancel_reward: Button = %BtnCancelReward

var http_client: Node
var chores: Array = []
var rewards: Array = []
var family_members: Array = []
var completed_chores: Array = []
var redeemed_rewards: Array = []

var editing_chore_id: String = ""
var editing_reward_id: String = ""

func _ready() -> void:
	http_client = get_node("/root/HTTPClient")
	
	# Setup UI
	var user_data = http_client.user_data
	welcome_label.text = "Welcome, " + user_data.get("username", "Parent") + "!"
	family_id_label.text = "Family ID: " + user_data.get("familyId", "N/A")
	
	# Connect buttons
	btn_logout.pressed.connect(_on_logout_pressed)
	btn_add_chore.pressed.connect(_on_add_chore_pressed)
	btn_add_reward.pressed.connect(_on_add_reward_pressed)
	btn_save_chore.pressed.connect(_on_save_chore_pressed)
	btn_cancel_chore.pressed.connect(func(): chore_dialog.hide())
	btn_save_reward.pressed.connect(_on_save_reward_pressed)
	btn_cancel_reward.pressed.connect(func(): reward_dialog.hide())
	
	# Connect window close buttons (X button)
	chore_dialog.close_requested.connect(func(): chore_dialog.hide())
	reward_dialog.close_requested.connect(func(): reward_dialog.hide())
	
	# Load data
	_load_all_data()

func _load_all_data() -> void:
	http_client.get_chores(func(success, data):
		print("get_chores callback - success: ", success, " data: ", data)
		if success:
			if data is Array:
				chores = data
				print("Loaded ", chores.size(), " chores")
			else:
				chores = []
				print("Data is not an Array, type: ", typeof(data))
			_refresh_chores_list()
		else:
			# If loading fails, still show empty list
			chores = []
			_refresh_chores_list()
			print("Failed to load chores: ", data.get("error", "Unknown error"))
	)
	
	http_client.get_rewards(func(success, data):
		print("get_rewards callback - success: ", success, " data: ", data)
		if success:
			if data is Array:
				rewards = data
				print("Loaded ", rewards.size(), " rewards")
			else:
				rewards = []
				print("Data is not an Array, type: ", typeof(data))
			_refresh_rewards_list()
		else:
			# If loading fails, still show empty list
			rewards = []
			_refresh_rewards_list()
			print("Failed to load rewards: ", data.get("error", "Unknown error"))
	)
	
	http_client.get_family(func(success, data):
		if success:
			if data is Array:
				family_members = data
			else:
				family_members = []
			_refresh_family_list()
		else:
			family_members = []
			_refresh_family_list()
			print("Failed to load family: ", data.get("error", "Unknown error"))
	)
	
	http_client.get_completed_chores(func(success, data):
		if success:
			if data is Array:
				completed_chores = data
			else:
				completed_chores = []
			_refresh_history()
		else:
			completed_chores = []
			_refresh_history()
			print("Failed to load completed chores: ", data.get("error", "Unknown error"))
	)
	
	http_client.get_redeemed_rewards(func(success, data):
		if success:
			if data is Array:
				redeemed_rewards = data
			else:
				redeemed_rewards = []
			_refresh_history()
		else:
			redeemed_rewards = []
			_refresh_history()
			print("Failed to load redeemed rewards: ", data.get("error", "Unknown error"))
	)

func _refresh_chores_list() -> void:
	print("=== REFRESHING CHORES LIST ===")
	print("Chores array size: ", chores.size())
	print("Chores array: ", chores)
	
	# Clear existing items - remove and queue_free immediately
	var children_to_remove = []
	for child in chores_list.get_children():
		children_to_remove.append(child)
	
	for child in children_to_remove:
		chores_list.remove_child(child)
		child.queue_free()
	
	if chores.is_empty() or chores.size() == 0:
		print("No chores to display, showing empty message")
		var label = Label.new()
		label.text = "No chores yet. Click 'Add Chore' to create one!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		chores_list.add_child(label)
		print("Empty message label added")
		return
	
	print("Adding ", chores.size(), " chore cards to the list")
	# Add chore cards
	for i in range(chores.size()):
		var chore = chores[i]
		print("Processing chore ", i, ": ", chore)
		if chore is Dictionary:
			print("Creating card for chore: ", chore.get("title", "No title"))
			var card = _create_chore_card(chore)
			if card != null:
				chores_list.add_child(card)
				print("Card added to list. ChoresList children count: ", chores_list.get_child_count())
			else:
				print("ERROR: Card creation returned null!")
		else:
			print("ERROR: Chore is not a Dictionary! Type: ", typeof(chore), " Value: ", chore)
	
	print("=== DONE REFRESHING CHORES LIST ===")
	print("Total children in ChoresList: ", chores_list.get_child_count())
	
	# Force update
	chores_list.queue_sort()
	chores_list.get_parent().queue_sort()

func _create_chore_card(chore: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add a style box for visibility
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.3, 0.35, 1.0)
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style_box)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(margin)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = chore.get("title", "Untitled")
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_label)
	
	var desc = chore.get("description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		vbox.add_child(desc_label)
	
	var points_label = Label.new()
	points_label.text = "⭐ " + str(chore.get("points", 0)) + " points"
	points_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	vbox.add_child(points_label)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.pressed.connect(_on_edit_chore_pressed.bind(chore))
	hbox.add_child(edit_btn)
	
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete_chore_pressed.bind(chore))
	hbox.add_child(delete_btn)
	
	return panel

func _refresh_rewards_list() -> void:
	print("=== REFRESHING REWARDS LIST ===")
	print("Rewards array size: ", rewards.size())
	print("Rewards array: ", rewards)
	
	# Clear existing items - remove and queue_free immediately
	var children_to_remove = []
	for child in rewards_list.get_children():
		children_to_remove.append(child)
	
	for child in children_to_remove:
		rewards_list.remove_child(child)
		child.queue_free()
	
	if rewards.is_empty() or rewards.size() == 0:
		print("No rewards to display, showing empty message")
		var label = Label.new()
		label.text = "No rewards yet. Click 'Add Reward' to create one!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		rewards_list.add_child(label)
		print("Empty message label added")
		return
	
	print("Adding ", rewards.size(), " reward cards to the list")
	# Add reward cards
	for i in range(rewards.size()):
		var reward = rewards[i]
		print("Processing reward ", i, ": ", reward)
		if reward is Dictionary:
			print("Creating card for reward: ", reward.get("title", "No title"))
			var card = _create_reward_card(reward)
			if card != null:
				rewards_list.add_child(card)
				print("Card added to list. RewardsList children count: ", rewards_list.get_child_count())
			else:
				print("ERROR: Card creation returned null!")
		else:
			print("ERROR: Reward is not a Dictionary! Type: ", typeof(reward), " Value: ", reward)
	
	print("=== DONE REFRESHING REWARDS LIST ===")
	print("Total children in RewardsList: ", rewards_list.get_child_count())
	
	# Force update
	rewards_list.queue_sort()
	rewards_list.get_parent().queue_sort()

func _create_reward_card(reward: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add a style box for visibility
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.3, 0.35, 1.0)
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style_box)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(margin)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = reward.get("title", "Untitled")
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_label)
	
	var desc = reward.get("description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		vbox.add_child(desc_label)
	
	var cost_label = Label.new()
	cost_label.text = "💎 " + str(reward.get("cost", 0)) + " points"
	cost_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 1.0))
	vbox.add_child(cost_label)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.pressed.connect(_on_edit_reward_pressed.bind(reward))
	hbox.add_child(edit_btn)
	
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete_reward_pressed.bind(reward))
	hbox.add_child(delete_btn)
	
	return panel

func _refresh_family_list() -> void:
	# Clear existing items
	for child in family_list.get_children():
		child.queue_free()
	
	if family_members.is_empty():
		var label = Label.new()
		label.text = "No family members yet."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		family_list.add_child(label)
		return
	
	# Add family member cards
	for member in family_members:
		var card = _create_family_member_card(member)
		family_list.add_child(card)

func _create_family_member_card(member: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var icon_label = Label.new()
	var role = member.get("role", "")
	icon_label.text = "👨‍👩‍👧‍👦" if role == "parent" else "👶"
	icon_label.add_theme_font_size_override("font_size", 24)
	hbox.add_child(icon_label)
	
	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = member.get("username", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	var role_label = Label.new()
	role_label.text = role.capitalize()
	vbox.add_child(role_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	var points_label = Label.new()
	points_label.text = "⭐ " + str(member.get("points", 0)) + " points"
	points_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(points_label)
	
	return panel

func _refresh_history() -> void:
	# Clear completed chores list
	for child in completed_chores_list.get_children():
		child.queue_free()
	
	if completed_chores.is_empty():
		var label = Label.new()
		label.text = "No completed chores yet."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		completed_chores_list.add_child(label)
	else:
		for item in completed_chores:
			var card = _create_history_item(
				item.get("username", "") + " completed " + item.get("choreTitle", ""),
				item.get("completedAt", ""),
				"+" + str(item.get("points", 0)) + " points"
			)
			completed_chores_list.add_child(card)
	
	# Clear redeemed rewards list
	for child in redeemed_rewards_list.get_children():
		child.queue_free()
	
	if redeemed_rewards.is_empty():
		var label = Label.new()
		label.text = "No redeemed rewards yet."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		redeemed_rewards_list.add_child(label)
	else:
		for item in redeemed_rewards:
			var card = _create_history_item(
				item.get("username", "") + " redeemed " + item.get("rewardTitle", ""),
				item.get("redeemedAt", ""),
				"-" + str(item.get("cost", 0)) + " points"
			)
			redeemed_rewards_list.add_child(card)

func _create_history_item(text: String, timestamp: String, points: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)
	
	var text_label = Label.new()
	text_label.text = text
	vbox.add_child(text_label)
	
	var time_label = Label.new()
	time_label.text = timestamp
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(time_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	var points_label = Label.new()
	points_label.text = points
	points_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(points_label)
	
	return panel

# Button handlers
func _on_logout_pressed() -> void:
	http_client.logout()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_add_chore_pressed() -> void:
	editing_chore_id = ""
	chore_title_input.text = ""
	chore_desc_input.text = ""
	chore_points_input.value = 10
	chore_dialog.title = "Add New Chore"
	btn_save_chore.disabled = false
	btn_save_chore.text = "Save Chore"
	chore_dialog.popup_centered()

func _on_edit_chore_pressed(chore: Dictionary) -> void:
	editing_chore_id = chore.get("id", "")
	chore_title_input.text = chore.get("title", "")
	chore_desc_input.text = chore.get("description", "")
	chore_points_input.value = chore.get("points", 10)
	chore_dialog.title = "Edit Chore"
	chore_dialog.popup_centered()

func _on_save_chore_pressed() -> void:
	var title = chore_title_input.text.strip_edges()
	var desc = chore_desc_input.text.strip_edges()
	var points = int(chore_points_input.value)
	
	if title.is_empty():
		_show_error_dialog("Error", "Chore title cannot be empty")
		return
	
	# Disable button during save
	btn_save_chore.disabled = true
	btn_save_chore.text = "Saving..."
	
	if editing_chore_id == "":
		# Create new chore
		http_client.create_chore(title, desc, points, func(success, data):
			btn_save_chore.disabled = false
			btn_save_chore.text = "Save Chore"
			
			print("create_chore callback - success: ", success, " data: ", data)
			if success:
				print("Chore created successfully, reloading data...")
				chore_dialog.hide()
				# Reload only chores to be faster
				http_client.get_chores(func(load_success, load_data):
					print("Reload after create - success: ", load_success, " data: ", load_data)
					if load_success:
						if load_data is Array:
							chores = load_data
							print("Reloaded ", chores.size(), " chores")
						else:
							chores = []
						_refresh_chores_list()
					else:
						print("Failed to reload chores: ", load_data.get("error", "Unknown error"))
				)
			else:
				var error_msg = data.get("error", "Failed to save chore")
				_show_error_dialog("Error", "Failed to save chore: " + error_msg)
		)
	else:
		# Update existing chore
		http_client.update_chore(editing_chore_id, title, desc, points, func(success, data):
			btn_save_chore.disabled = false
			btn_save_chore.text = "Save Chore"
			
			if success:
				chore_dialog.hide()
				_load_all_data()
			else:
				var error_msg = data.get("error", "Failed to update chore")
				_show_error_dialog("Error", "Failed to update chore: " + error_msg)
		)

func _on_delete_chore_pressed(chore: Dictionary) -> void:
	var chore_id = chore.get("id", "")
	if chore_id == "":
		return
	
	# Confirm deletion
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Are you sure you want to delete this chore?"
	confirm.confirmed.connect(func():
		http_client.delete_chore(chore_id, func(success, data):
			if success:
				_load_all_data()
			else:
				var error_msg = data.get("error", "Failed to delete chore")
				_show_error_dialog("Error", "Failed to delete chore: " + error_msg)
		)
		confirm.queue_free()
	)
	confirm.canceled.connect(func():
		confirm.queue_free()
	)
	add_child(confirm)
	confirm.popup_centered()

func _on_add_reward_pressed() -> void:
	editing_reward_id = ""
	reward_title_input.text = ""
	reward_desc_input.text = ""
	reward_cost_input.value = 50
	reward_dialog.title = "Add New Reward"
	btn_save_reward.disabled = false
	btn_save_reward.text = "Save Reward"
	reward_dialog.popup_centered()

func _on_edit_reward_pressed(reward: Dictionary) -> void:
	editing_reward_id = reward.get("id", "")
	reward_title_input.text = reward.get("title", "")
	reward_desc_input.text = reward.get("description", "")
	reward_cost_input.value = reward.get("cost", 50)
	reward_dialog.title = "Edit Reward"
	reward_dialog.popup_centered()

func _on_save_reward_pressed() -> void:
	var title = reward_title_input.text.strip_edges()
	var desc = reward_desc_input.text.strip_edges()
	var cost = int(reward_cost_input.value)
	
	if title.is_empty():
		_show_error_dialog("Error", "Reward title cannot be empty")
		return
	
	# Disable button during save
	btn_save_reward.disabled = true
	btn_save_reward.text = "Saving..."
	
	if editing_reward_id == "":
		# Create new reward
		http_client.create_reward(title, desc, cost, func(success, data):
			btn_save_reward.disabled = false
			btn_save_reward.text = "Save Reward"
			
			print("create_reward callback - success: ", success, " data: ", data)
			if success:
				print("Reward created successfully, reloading data...")
				reward_dialog.hide()
				# Reload only rewards to be faster
				http_client.get_rewards(func(load_success, load_data):
					print("Reload after create - success: ", load_success, " data: ", load_data)
					if load_success:
						if load_data is Array:
							rewards = load_data
							print("Reloaded ", rewards.size(), " rewards")
						else:
							rewards = []
						_refresh_rewards_list()
					else:
						print("Failed to reload rewards: ", load_data.get("error", "Unknown error"))
				)
			else:
				var error_msg = data.get("error", "Failed to save reward")
				_show_error_dialog("Error", "Failed to save reward: " + error_msg)
		)
	else:
		# Update existing reward
		http_client.update_reward(editing_reward_id, title, desc, cost, func(success, data):
			btn_save_reward.disabled = false
			btn_save_reward.text = "Save Reward"
			
			if success:
				reward_dialog.hide()
				_load_all_data()
			else:
				var error_msg = data.get("error", "Failed to update reward")
				_show_error_dialog("Error", "Failed to update reward: " + error_msg)
		)

func _on_delete_reward_pressed(reward: Dictionary) -> void:
	var reward_id = reward.get("id", "")
	if reward_id == "":
		return
	
	# Confirm deletion
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Are you sure you want to delete this reward?"
	confirm.confirmed.connect(func():
		http_client.delete_reward(reward_id, func(success, data):
			if success:
				_load_all_data()
			else:
				var error_msg = data.get("error", "Failed to delete reward")
				_show_error_dialog("Error", "Failed to delete reward: " + error_msg)
		)
		confirm.queue_free()
	)
	confirm.canceled.connect(func():
		confirm.queue_free()
	)
	add_child(confirm)
	confirm.popup_centered()

func _show_error_dialog(title: String, message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
