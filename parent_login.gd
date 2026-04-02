extends Control

# UI References
@onready var username_input: LineEdit = %Username
@onready var password_input: LineEdit = %Password
@onready var family_id_input: LineEdit = %FamilyID
@onready var family_id_container: HBoxContainer = %FamilyIDContainer
@onready var lbl_error: Label = %Error
@onready var btn_login: Button = %BtnLogin
@onready var btn_register: Button = %BtnRegister
@onready var btn_toggle_mode: Button = %BtnToggleMode
@onready var role_parent: CheckBox = %RoleParent
@onready var role_child: CheckBox = %RoleChild
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle

# Scrolling background references
@onready var bg_layer1_a: TextureRect = $Background/Layer1A
@onready var bg_layer1_b: TextureRect = $Background/Layer1B
@onready var bg_layer2_a: TextureRect = $Background/Layer2A
@onready var bg_layer2_b: TextureRect = $Background/Layer2B
@onready var bg_layer3_a: TextureRect = $Background/Layer3A
@onready var bg_layer3_b: TextureRect = $Background/Layer3B
@onready var bg_layer4_a: TextureRect = $Background/Layer4A
@onready var bg_layer4_b: TextureRect = $Background/Layer4B

# Scroll speeds
var scroll_speed_layer1: float = 15.0
var scroll_speed_layer2: float = 30.0
var scroll_speed_layer3: float = 60.0
var scroll_speed_layer4: float = 100.0
var layer_width: float = 1920.0

var http_client: Node
var _request_in_progress: bool = false
var _is_login_mode: bool = true  # true = login, false = register

func _ready() -> void:
	http_client = get_node("/root/HTTPClient")
	
	# Setup scrolling background
	layer_width = get_viewport_rect().size.x
	if bg_layer1_b: bg_layer1_b.position.x = layer_width
	if bg_layer2_b: bg_layer2_b.position.x = layer_width
	if bg_layer3_b: bg_layer3_b.position.x = layer_width
	if bg_layer4_b: bg_layer4_b.position.x = layer_width
	
	# Connect signals
	btn_login.pressed.connect(_on_login_pressed)
	btn_register.pressed.connect(_on_register_pressed)
	btn_toggle_mode.pressed.connect(_on_toggle_mode_pressed)
	role_parent.toggled.connect(_on_role_changed)
	role_child.toggled.connect(_on_role_changed)
	password_input.text_submitted.connect(_on_password_submit)
	family_id_input.text_submitted.connect(_on_family_id_submit)
	
	# Initial setup
	username_input.grab_focus()
	_update_ui_for_mode()

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

func _on_toggle_mode_pressed() -> void:
	_is_login_mode = !_is_login_mode
	_update_ui_for_mode()
	_show_error("")

func _update_ui_for_mode() -> void:
	if _is_login_mode:
		title_label.text = "Welcome Back!"
		subtitle_label.text = "Login to your account"
		btn_login.visible = true
		btn_register.visible = false
		btn_toggle_mode.text = "Create New Account"
		role_parent.visible = false
		role_child.visible = false
		family_id_container.visible = false
	else:
		title_label.text = "Join the Family!"
		subtitle_label.text = "Create your account"
		btn_login.visible = false
		btn_register.visible = true
		btn_toggle_mode.text = "Already have an account? Login"
		role_parent.visible = true
		role_child.visible = true
		_update_family_id_visibility()

func _on_role_changed(_pressed: bool) -> void:
	_update_family_id_visibility()

func _update_family_id_visibility() -> void:
	# Show Family ID field only for child registration
	family_id_container.visible = !_is_login_mode and role_child.button_pressed

func _on_login_pressed() -> void:
	if _request_in_progress:
		return
	
	var username := username_input.text.strip_edges()
	var pwd := password_input.text
	
	if username.is_empty() or pwd.is_empty():
		_show_error("Please enter username and password.")
		return
	
	_request_in_progress = true
	_set_buttons_disabled(true)
	_show_info("Logging in...")
	
	http_client.login(username, pwd, _on_login_response)

func _on_login_response(success: bool, data: Dictionary) -> void:
	_request_in_progress = false
	_set_buttons_disabled(false)
	
	if success:
		var user = data.get("user", {})
		var role = user.get("role", "")
		var family_id = user.get("familyId", "")
		
		_show_success("Welcome back!")
		await get_tree().create_timer(0.5).timeout
		
		if role == "parent":
			get_tree().change_scene_to_file("res://parent_dashboard.tscn")
		else:
			# Child goes to the game
			get_tree().change_scene_to_file("res://chore_xplorer.tscn")
	else:
		var error_msg = data.get("error", "Login failed")
		_show_error(error_msg)

func _on_register_pressed() -> void:
	if _request_in_progress:
		return
	
	var username := username_input.text.strip_edges()
	var pwd := password_input.text
	var role := "parent" if role_parent.button_pressed else "child"
	var family_id := family_id_input.text.strip_edges()
	
	# Validation
	if username.is_empty():
		_show_error("Please enter a username.")
		return
	
	if username.length() < 3:
		_show_error("Username must be at least 3 characters.")
		return
	
	if pwd.is_empty():
		_show_error("Please enter a password.")
		return
	
	if pwd.length() < 4:
		_show_error("Password must be at least 4 characters.")
		return
	
	if role == "child" and family_id.is_empty():
		_show_error("Children must enter a Family ID to join.")
		return
	
	_request_in_progress = true
	_set_buttons_disabled(true)
	_show_info("Creating account...")
	
	http_client.register(username, pwd, role, family_id, _on_register_response)

func _on_register_response(success: bool, data: Dictionary) -> void:
	_request_in_progress = false
	_set_buttons_disabled(false)
	
	if success:
		var user = data.get("user", {})
		var role = user.get("role", "")
		var family_id = user.get("familyId", "")
		
		if role == "parent":
			_show_success("Account created! Your Family ID: " + family_id)
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file("res://parent_dashboard.tscn")
		else:
			_show_success("Welcome to the family!")
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_file("res://chore_xplorer.tscn")
	else:
		var error_msg = data.get("error", "Registration failed")
		_show_error(error_msg)

func _on_password_submit(_text: String) -> void:
	if _is_login_mode:
		_on_login_pressed()
	elif role_child.button_pressed:
		family_id_input.grab_focus()
	else:
		_on_register_pressed()

func _on_family_id_submit(_text: String) -> void:
	_on_register_pressed()

func _set_buttons_disabled(disabled: bool) -> void:
	btn_login.disabled = disabled
	btn_register.disabled = disabled
	btn_toggle_mode.disabled = disabled
	role_parent.disabled = disabled
	role_child.disabled = disabled

func _show_error(msg: String) -> void:
	lbl_error.add_theme_color_override("font_color", Color(0.80, 0.40, 0.35, 1))
	lbl_error.text = msg
	lbl_error.visible = msg != ""

func _show_success(msg: String) -> void:
	lbl_error.add_theme_color_override("font_color", Color(0.45, 0.75, 0.35, 1))
	lbl_error.text = msg
	lbl_error.visible = msg != ""

func _show_info(msg: String) -> void:
	lbl_error.add_theme_color_override("font_color", Color(0.75, 0.72, 0.60, 1))
	lbl_error.text = msg
	lbl_error.visible = msg != ""
