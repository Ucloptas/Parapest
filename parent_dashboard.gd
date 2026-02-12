extends Control

# UI references
@onready var welcome_label: Label = %WelcomeLabel
@onready var family_id_label: Label = %FamilyIDLabel
@onready var page_title: Label = %PageTitle
@onready var btn_logout: Button = %BtnLogout

# Navigation buttons
@onready var btn_nav_chores: Button = %BtnNavChores
@onready var btn_nav_rewards: Button = %BtnNavRewards
@onready var btn_nav_approvals: Button = %BtnNavApprovals
@onready var btn_nav_family: Button = %BtnNavFamily
@onready var btn_nav_history: Button = %BtnNavHistory

# Add buttons
@onready var btn_add_chore: Button = %BtnAddChore
@onready var btn_add_reward: Button = %BtnAddReward

# Content lists
@onready var chores_list: VBoxContainer = %ChoresList
@onready var rewards_list: VBoxContainer = %RewardsList
@onready var family_list: VBoxContainer = %FamilyList
@onready var history_container: VBoxContainer = %HistoryContainer
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
var pending_completions: Array = []

# Approvals list (created dynamically if not in scene)
var approvals_list: VBoxContainer

var editing_chore_id: String = ""
var editing_reward_id: String = ""
var current_page: String = "chores"

# Colors
const COLOR_ACTIVE = Color(0.9, 0.92, 0.95, 1)
const COLOR_INACTIVE = Color(0.5, 0.55, 0.6, 1)
const COLOR_POINTS = Color(0.45, 0.75, 0.55, 1)
const COLOR_COST = Color(0.55, 0.7, 0.9, 1)

func _ready() -> void:
	http_client = get_node("/root/HTTPClient")
	
	# Setup UI
	var user_data = http_client.user_data
	welcome_label.text = user_data.get("username", "Parent")
	family_id_label.text = "ID: " + user_data.get("familyId", "N/A")
	
	# Connect navigation buttons
	btn_nav_chores.pressed.connect(func(): _switch_page("chores"))
	btn_nav_rewards.pressed.connect(func(): _switch_page("rewards"))
	if btn_nav_approvals:
		btn_nav_approvals.pressed.connect(func(): _switch_page("approvals"))
	btn_nav_family.pressed.connect(func(): _switch_page("family"))
	btn_nav_history.pressed.connect(func(): _switch_page("history"))
	
	# Create approvals list dynamically if it doesn't exist
	_setup_approvals_list()
	
	# Connect action buttons
	btn_logout.pressed.connect(_on_logout_pressed)
	btn_add_chore.pressed.connect(_on_add_chore_pressed)
	btn_add_reward.pressed.connect(_on_add_reward_pressed)
	btn_save_chore.pressed.connect(_on_save_chore_pressed)
	btn_cancel_chore.pressed.connect(func(): chore_dialog.hide())
	btn_save_reward.pressed.connect(_on_save_reward_pressed)
	btn_cancel_reward.pressed.connect(func(): reward_dialog.hide())
	
	# Connect window close buttons
	chore_dialog.close_requested.connect(func(): chore_dialog.hide())
	reward_dialog.close_requested.connect(func(): reward_dialog.hide())
	
	# Initial page
	_switch_page("chores")
	_load_all_data()

func _setup_approvals_list():
	# Create approvals list container
	approvals_list = VBoxContainer.new()
	approvals_list.name = "ApprovalsList"
	approvals_list.visible = false
	approvals_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	approvals_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	approvals_list.add_theme_constant_override("separation", 10)
	
	# Add it as sibling to other lists (inside the ContentScroll)
	if chores_list and chores_list.get_parent():
		var parent = chores_list.get_parent()
		parent.add_child(approvals_list)
		print("Approvals list created and added to: ", parent.name)

func _switch_page(page: String) -> void:
	current_page = page
	
	# Update navigation button colors
	btn_nav_chores.add_theme_color_override("font_color", COLOR_ACTIVE if page == "chores" else COLOR_INACTIVE)
	btn_nav_rewards.add_theme_color_override("font_color", COLOR_ACTIVE if page == "rewards" else COLOR_INACTIVE)
	if btn_nav_approvals:
		btn_nav_approvals.add_theme_color_override("font_color", COLOR_ACTIVE if page == "approvals" else COLOR_INACTIVE)
	btn_nav_family.add_theme_color_override("font_color", COLOR_ACTIVE if page == "family" else COLOR_INACTIVE)
	btn_nav_history.add_theme_color_override("font_color", COLOR_ACTIVE if page == "history" else COLOR_INACTIVE)
	
	# Update page title and visibility
	chores_list.visible = (page == "chores")
	rewards_list.visible = (page == "rewards")
	if approvals_list:
		approvals_list.visible = (page == "approvals")
	family_list.visible = (page == "family")
	history_container.visible = (page == "history")
	
	btn_add_chore.visible = (page == "chores")
	btn_add_reward.visible = (page == "rewards")
	
	match page:
		"chores":
			page_title.text = "Chores"
		"rewards":
			page_title.text = "Rewards"
		"approvals":
			page_title.text = "Pending Approvals"
			_reload_pending_completions()
		"family":
			page_title.text = "Family Members"
		"history":
			page_title.text = "Activity History"

func _load_all_data() -> void:
	http_client.get_chores(func(success, data):
		if success and data is Array:
			chores = data
		else:
			chores = []
		_refresh_chores_list()
	)
	
	http_client.get_rewards(func(success, data):
		if success and data is Array:
			rewards = data
		else:
			rewards = []
		_refresh_rewards_list()
	)
	
	http_client.get_pending_completions(func(success, data):
		if success and data is Array:
			pending_completions = data
		else:
			pending_completions = []
		_refresh_approvals_list()
		_update_approvals_badge()
	)
	
	http_client.get_family(func(success, data):
		if success and data is Array:
			family_members = data
		else:
			family_members = []
		_refresh_family_list()
	)
	
	http_client.get_completed_chores(func(success, data):
		if success and data is Array:
			completed_chores = data
		else:
			completed_chores = []
		_refresh_history()
	)
	
	http_client.get_redeemed_rewards(func(success, data):
		if success and data is Array:
			redeemed_rewards = data
		else:
			redeemed_rewards = []
		_refresh_history()
	)

func _reload_pending_completions() -> void:
	print("Reloading pending completions...")
	http_client.get_pending_completions(func(success, data):
		print("Reload pending - Success: ", success, " Data: ", data)
		if success and data is Array:
			pending_completions = data
			print("Reloaded ", pending_completions.size(), " pending completions")
		else:
			pending_completions = []
			print("No pending completions found")
		_refresh_approvals_list()
		_update_approvals_badge()
	)

func _update_approvals_badge() -> void:
	if btn_nav_approvals and pending_completions.size() > 0:
		btn_nav_approvals.text = "Approvals (" + str(pending_completions.size()) + ")"
	elif btn_nav_approvals:
		btn_nav_approvals.text = "Approvals"

func _refresh_approvals_list() -> void:
	if not approvals_list:
		return
	
	_clear_children(approvals_list)
	
	if pending_completions.is_empty():
		var label = _create_empty_label("No pending approvals. Children's chore completions will appear here.")
		approvals_list.add_child(label)
		return
	
	for pending in pending_completions:
		if pending is Dictionary:
			var card = _create_approval_card(pending)
			approvals_list.add_child(card)

func _create_approval_card(pending: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Highlight style for pending approvals
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.1, 1)
	style.border_color = Color(0.4, 0.6, 0.3, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)
	
	var child_label = Label.new()
	child_label.text = pending.get("username", "Child") + " completed:"
	child_label.add_theme_font_size_override("font_size", 14)
	child_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	info_vbox.add_child(child_label)
	
	var title_label = Label.new()
	title_label.text = pending.get("choreTitle", "Untitled")
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	info_vbox.add_child(title_label)
	
	var points_label = Label.new()
	points_label.text = "+" + str(pending.get("points", 0)) + " pts"
	points_label.add_theme_font_size_override("font_size", 15)
	points_label.add_theme_color_override("font_color", COLOR_POINTS)
	info_vbox.add_child(points_label)
	
	var btn_container = HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 10)
	hbox.add_child(btn_container)
	
	var approve_btn = Button.new()
	approve_btn.text = "Approve"
	approve_btn.custom_minimum_size = Vector2(90, 38)
	approve_btn.add_theme_font_size_override("font_size", 14)
	var approve_style = StyleBoxFlat.new()
	approve_style.bg_color = Color(0.25, 0.5, 0.3, 1)
	approve_style.set_corner_radius_all(6)
	approve_btn.add_theme_stylebox_override("normal", approve_style)
	approve_btn.pressed.connect(_on_approve_pressed.bind(pending))
	btn_container.add_child(approve_btn)
	
	var reject_btn = Button.new()
	reject_btn.text = "Reject"
	reject_btn.custom_minimum_size = Vector2(80, 38)
	reject_btn.add_theme_font_size_override("font_size", 14)
	reject_btn.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))
	reject_btn.pressed.connect(_on_reject_pressed.bind(pending))
	btn_container.add_child(reject_btn)
	
	return panel

func _on_approve_pressed(pending: Dictionary) -> void:
	var pending_id = str(pending.get("id", ""))
	if pending_id == "":
		print("Error: No pending ID found")
		return
	
	print("Approving completion: ", pending_id)
	
	http_client.approve_completion(pending_id, func(success, data):
		print("Approve result - Success: ", success, " Data: ", data)
		if success:
			# Show feedback
			_show_approval_feedback("Approved! " + pending.get("username", "Child") + " earned " + str(pending.get("points", 0)) + " points.")
			_reload_pending_completions()
			_load_all_data()  # Refresh all data including family points
		else:
			var error = data.get("error", "Unknown error") if data is Dictionary else "Unknown error"
			print("Failed to approve: ", error)
			_show_approval_feedback("Error: " + str(error))
	)

func _on_reject_pressed(pending: Dictionary) -> void:
	var pending_id = str(pending.get("id", ""))
	if pending_id == "":
		print("Error: No pending ID found")
		return
	
	print("Rejecting completion: ", pending_id)
	
	http_client.reject_completion(pending_id, func(success, data):
		print("Reject result - Success: ", success, " Data: ", data)
		if success:
			_show_approval_feedback("Rejected.")
			_reload_pending_completions()
		else:
			var error = data.get("error", "Unknown error") if data is Dictionary else "Unknown error"
			print("Failed to reject: ", error)
			_show_approval_feedback("Error: " + str(error))
	)

func _show_approval_feedback(message: String) -> void:
	# Create a temporary feedback label at the top of the page
	var feedback = Label.new()
	feedback.text = message
	feedback.add_theme_font_size_override("font_size", 16)
	if "Error" in message:
		feedback.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
	else:
		feedback.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if approvals_list:
		approvals_list.add_child(feedback)
		approvals_list.move_child(feedback, 0)
		
		# Remove after 3 seconds
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func():
			if is_instance_valid(feedback):
				feedback.queue_free()
		)

func _refresh_chores_list() -> void:
	_clear_children(chores_list)
	
	if chores.is_empty():
		var label = _create_empty_label("No chores yet. Click ADD CHORE to create one.")
		chores_list.add_child(label)
		return
	
	for chore in chores:
		if chore is Dictionary:
			var card = _create_chore_card(chore)
			chores_list.add_child(card)

func _create_chore_card(chore: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 90)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _create_card_style())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)
	
	var title_label = Label.new()
	title_label.text = chore.get("title", "Untitled")
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	info_vbox.add_child(title_label)
	
	var desc = chore.get("description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_vbox.add_child(desc_label)
	
	var points_label = Label.new()
	points_label.text = str(chore.get("points", 0)) + " pts"
	points_label.add_theme_font_size_override("font_size", 14)
	points_label.add_theme_color_override("font_color", COLOR_POINTS)
	info_vbox.add_child(points_label)
	
	var btn_container = HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 8)
	hbox.add_child(btn_container)
	
	var edit_btn = _create_action_button("Edit")
	edit_btn.pressed.connect(_on_edit_chore_pressed.bind(chore))
	btn_container.add_child(edit_btn)
	
	var delete_btn = _create_action_button("Delete", true)
	delete_btn.pressed.connect(_on_delete_chore_pressed.bind(chore))
	btn_container.add_child(delete_btn)
	
	return panel

func _refresh_rewards_list() -> void:
	_clear_children(rewards_list)
	
	if rewards.is_empty():
		var label = _create_empty_label("No rewards yet. Click ADD REWARD to create one.")
		rewards_list.add_child(label)
		return
	
	for reward in rewards:
		if reward is Dictionary:
			var card = _create_reward_card(reward)
			rewards_list.add_child(card)

func _create_reward_card(reward: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 90)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _create_card_style())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)
	
	var title_label = Label.new()
	title_label.text = reward.get("title", "Untitled")
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	info_vbox.add_child(title_label)
	
	var desc = reward.get("description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_vbox.add_child(desc_label)
	
	var cost_label = Label.new()
	cost_label.text = str(reward.get("cost", 0)) + " pts"
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", COLOR_COST)
	info_vbox.add_child(cost_label)
	
	var btn_container = HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 8)
	hbox.add_child(btn_container)
	
	var edit_btn = _create_action_button("Edit")
	edit_btn.pressed.connect(_on_edit_reward_pressed.bind(reward))
	btn_container.add_child(edit_btn)
	
	var delete_btn = _create_action_button("Delete", true)
	delete_btn.pressed.connect(_on_delete_reward_pressed.bind(reward))
	btn_container.add_child(delete_btn)
	
	return panel

func _refresh_family_list() -> void:
	_clear_children(family_list)
	
	if family_members.is_empty():
		var label = _create_empty_label("No family members yet.")
		family_list.add_child(label)
		return
	
	for member in family_members:
		var card = _create_family_member_card(member)
		family_list.add_child(card)

func _create_family_member_card(member: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _create_card_style())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var role = member.get("role", "")
	var role_indicator = Label.new()
	role_indicator.text = "P" if role == "parent" else "C"
	role_indicator.add_theme_font_size_override("font_size", 14)
	role_indicator.add_theme_color_override("font_color", Color(0.08, 0.09, 0.11))
	role_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_indicator.custom_minimum_size = Vector2(32, 32)
	
	var indicator_panel = PanelContainer.new()
	var indicator_style = StyleBoxFlat.new()
	indicator_style.bg_color = COLOR_POINTS if role == "parent" else COLOR_COST
	indicator_style.set_corner_radius_all(16)
	indicator_panel.add_theme_stylebox_override("panel", indicator_style)
	indicator_panel.add_child(role_indicator)
	hbox.add_child(indicator_panel)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(12, 0)
	hbox.add_child(spacer1)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = member.get("username", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	info_vbox.add_child(name_label)
	
	var role_label = Label.new()
	role_label.text = role.capitalize()
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	info_vbox.add_child(role_label)
	
	var points_label = Label.new()
	points_label.text = str(member.get("points", 0)) + " pts"
	points_label.add_theme_font_size_override("font_size", 16)
	points_label.add_theme_color_override("font_color", COLOR_POINTS)
	hbox.add_child(points_label)
	
	return panel

func _refresh_history() -> void:
	_clear_children(completed_chores_list)
	_clear_children(redeemed_rewards_list)
	
	if completed_chores.is_empty():
		var label = _create_empty_label("No completed chores yet.")
		completed_chores_list.add_child(label)
	else:
		for item in completed_chores:
			var card = _create_history_item(
				item.get("username", "") + " completed " + item.get("choreTitle", ""),
				item.get("completedAt", ""),
				"+" + str(item.get("points", 0)) + " pts",
				true
			)
			completed_chores_list.add_child(card)
	
	if redeemed_rewards.is_empty():
		var label = _create_empty_label("No redeemed rewards yet.")
		redeemed_rewards_list.add_child(label)
	else:
		for item in redeemed_rewards:
			var card = _create_history_item(
				item.get("username", "") + " redeemed " + item.get("rewardTitle", ""),
				item.get("redeemedAt", ""),
				"-" + str(item.get("cost", 0)) + " pts",
				false
			)
			redeemed_rewards_list.add_child(card)

func _create_history_item(text: String, timestamp: String, points: String, is_positive: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _create_card_style())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var text_label = Label.new()
	text_label.text = text
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	vbox.add_child(text_label)
	
	var time_label = Label.new()
	time_label.text = timestamp
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
	vbox.add_child(time_label)
	
	var points_label = Label.new()
	points_label.text = points
	points_label.add_theme_font_size_override("font_size", 15)
	points_label.add_theme_color_override("font_color", COLOR_POINTS if is_positive else Color(0.9, 0.5, 0.5))
	hbox.add_child(points_label)
	
	return panel

# Helper functions
func _create_card_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.11, 0.14, 1)
	style.border_color = Color(0.15, 0.17, 0.22, 1)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

func _create_empty_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
	label.add_theme_font_size_override("font_size", 14)
	return label

func _create_action_button(text: String, is_danger: bool = false) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(70, 32)
	btn.add_theme_font_size_override("font_size", 13)
	if is_danger:
		btn.add_theme_color_override("font_color", Color(0.85, 0.5, 0.5))
	return btn

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

# Button handlers
func _on_logout_pressed() -> void:
	http_client.logout()
	get_tree().change_scene_to_file("res://login.tscn")

func _on_add_chore_pressed() -> void:
	editing_chore_id = ""
	chore_title_input.text = ""
	chore_desc_input.text = ""
	chore_points_input.value = 10
	chore_dialog.title = "Add Chore"
	btn_save_chore.disabled = false
	btn_save_chore.text = "Save"
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
		return
	
	btn_save_chore.disabled = true
	btn_save_chore.text = "Saving..."
	
	if editing_chore_id == "":
		http_client.create_chore(title, desc, points, func(success, data):
			btn_save_chore.disabled = false
			btn_save_chore.text = "Save"
			if success:
				chore_dialog.hide()
				_reload_chores()
		)
	else:
		http_client.update_chore(editing_chore_id, title, desc, points, func(success, data):
			btn_save_chore.disabled = false
			btn_save_chore.text = "Save"
			if success:
				chore_dialog.hide()
				_reload_chores()
		)

func _on_delete_chore_pressed(chore: Dictionary) -> void:
	var chore_id = chore.get("id", "")
	if chore_id == "":
		return
	
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Delete this chore?"
	confirm.confirmed.connect(func():
		http_client.delete_chore(chore_id, func(success, data):
			if success:
				_reload_chores()
		)
		confirm.queue_free()
	)
	confirm.canceled.connect(func(): confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()

func _on_add_reward_pressed() -> void:
	editing_reward_id = ""
	reward_title_input.text = ""
	reward_desc_input.text = ""
	reward_cost_input.value = 50
	reward_dialog.title = "Add Reward"
	btn_save_reward.disabled = false
	btn_save_reward.text = "Save"
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
		return
	
	btn_save_reward.disabled = true
	btn_save_reward.text = "Saving..."
	
	if editing_reward_id == "":
		http_client.create_reward(title, desc, cost, func(success, data):
			btn_save_reward.disabled = false
			btn_save_reward.text = "Save"
			if success:
				reward_dialog.hide()
				_reload_rewards()
		)
	else:
		http_client.update_reward(editing_reward_id, title, desc, cost, func(success, data):
			btn_save_reward.disabled = false
			btn_save_reward.text = "Save"
			if success:
				reward_dialog.hide()
				_reload_rewards()
		)

func _on_delete_reward_pressed(reward: Dictionary) -> void:
	var reward_id = reward.get("id", "")
	if reward_id == "":
		return
	
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Delete this reward?"
	confirm.confirmed.connect(func():
		http_client.delete_reward(reward_id, func(success, data):
			if success:
				_reload_rewards()
		)
		confirm.queue_free()
	)
	confirm.canceled.connect(func(): confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()

func _reload_chores() -> void:
	http_client.get_chores(func(success, data):
		if success and data is Array:
			chores = data
		else:
			chores = []
		_refresh_chores_list()
	)

func _reload_rewards() -> void:
	http_client.get_rewards(func(success, data):
		if success and data is Array:
			rewards = data
		else:
			rewards = []
		_refresh_rewards_list()
	)
