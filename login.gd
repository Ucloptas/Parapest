extends Control

# UI References
@onready var username_input: LineEdit = %Username
@onready var password_input: LineEdit = %Password
@onready var family_id_input: LineEdit = %FamilyID
@onready var family_id_container: HBoxContainer = %FamilyIDContainer
@onready var lbl_error: Label = %Error
@onready var lbl_title: Label = %Title

@onready var btn_login: Button = %BtnLogin
@onready var btn_register: Button = %BtnRegister
@onready var btn_parent: Button = %BtnParent
@onready var btn_child: Button = %BtnChild
@onready var btn_switch_mode: Button = %BtnSwitchMode
@onready var btn_exit: Button = %BtnExit

# Scrolling background references
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
var _request_in_progress: bool = false

# Mode tracking
enum Mode { LOGIN, REGISTER }
enum Role { PARENT, CHILD }
var current_mode: Mode = Mode.LOGIN
var selected_role: Role = Role.PARENT

func _ready() -> void:
	http_client = get_node("/root/HTTPClient")
	
	# Setup scrolling background
	layer_width = get_viewport_rect().size.x
	if bg_layer1_b: bg_layer1_b.position.x = layer_width
	if bg_layer2_b: bg_layer2_b.position.x = layer_width
	if bg_layer3_b: bg_layer3_b.position.x = layer_width
	if bg_layer4_b: bg_layer4_b.position.x = layer_width
	
	# Connect buttons
	btn_login.pressed.connect(_on_login_pressed)
	btn_register.pressed.connect(_on_register_pressed)
	btn_parent.pressed.connect(_on_parent_selected)
	btn_child.pressed.connect(_on_child_selected)
	btn_switch_mode.pressed.connect(_on_switch_mode)
	btn_exit.pressed.connect(_on_exit_pressed)
	password_input.text_submitted.connect(_on_password_submit)
	family_id_input.text_submitted.connect(_on_family_id_submit)
	
	# Initial UI state
	_update_ui()
	username_input.grab_focus()

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

func _update_ui() -> void:
	if current_mode == Mode.LOGIN:
		lbl_title.text = "Sign in to continue"
		btn_login.visible = true
		btn_register.visible = false
		btn_switch_mode.text = "Don't have an account? Sign up"
		btn_parent.visible = false
		btn_child.visible = false
		family_id_container.visible = false
	else:
		lbl_title.text = "Create your account"
		btn_login.visible = false
		btn_register.visible = true
		btn_switch_mode.text = "Already have an account? Sign in"
		btn_parent.visible = true
		btn_child.visible = true
		family_id_container.visible = (selected_role == Role.CHILD)
	
	_update_role_buttons()
	_clear_message()

func _update_role_buttons() -> void:
	# Reset both buttons
	btn_parent.add_theme_stylebox_override("normal", _create_role_style(selected_role == Role.PARENT))
	btn_child.add_theme_stylebox_override("normal", _create_role_style(selected_role == Role.CHILD))
	
	if selected_role == Role.PARENT:
		btn_parent.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
	else:
		btn_parent.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	
	if selected_role == Role.CHILD:
		btn_child.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
	else:
		btn_child.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))

func _create_role_style(selected: bool) -> StyleBoxFlat:
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

func _on_parent_selected() -> void:
	selected_role = Role.PARENT
	_update_ui()

func _on_child_selected() -> void:
	selected_role = Role.CHILD
	_update_ui()

func _on_switch_mode() -> void:
	if current_mode == Mode.LOGIN:
		current_mode = Mode.REGISTER
	else:
		current_mode = Mode.LOGIN
	_update_ui()

func _on_login_pressed() -> void:
	if _request_in_progress:
		return
	
	var username := username_input.text.strip_edges()
	var pwd := password_input.text
	
	if username.is_empty() or pwd.is_empty():
		_show_error("Please enter your username and password")
		return
	
	_request_in_progress = true
	_set_buttons_disabled(true)
	_show_info("Signing in...")
	
	http_client.login(username, pwd, _on_login_response)

func _on_login_response(success: bool, data: Dictionary) -> void:
	_request_in_progress = false
	_set_buttons_disabled(false)
	
	if success:
		var user = data.get("user", {})
		var role = user.get("role", "")
		
		_show_success("Welcome back, " + user.get("username", ""))
		
		await get_tree().create_timer(0.7).timeout
		
		if role == "parent":
			get_tree().change_scene_to_file("res://parent_dashboard.tscn")
		else:
			get_tree().change_scene_to_file("res://chore_xplorer.tscn")
	else:
		var error_msg = data.get("error", "Unable to sign in")
		_show_error(error_msg)

func _on_register_pressed() -> void:
	if _request_in_progress:
		return
	
	var username := username_input.text.strip_edges()
	var pwd := password_input.text
	var family_id := family_id_input.text.strip_edges()
	
	if username.is_empty() or pwd.is_empty():
		_show_error("Please enter a username and password")
		return
	
	if username.length() < 3:
		_show_error("Username must be at least 3 characters")
		return
	
	if pwd.length() < 4:
		_show_error("Password must be at least 4 characters")
		return
	
	var role_str = "parent" if selected_role == Role.PARENT else "child"
	
	if selected_role == Role.CHILD and family_id.is_empty():
		_show_error("Please enter your Family ID to join")
		return
	
	_request_in_progress = true
	_set_buttons_disabled(true)
	_show_info("Creating your account...")
	
	http_client.register(username, pwd, role_str, family_id, _on_register_response)

func _on_register_response(success: bool, data: Dictionary) -> void:
	_request_in_progress = false
	_set_buttons_disabled(false)
	
	if success:
		var user = data.get("user", {})
		var role = user.get("role", "")
		var family_id = user.get("familyId", "")
		
		if role == "parent":
			_show_success("Account created. Family ID: " + family_id)
		else:
			_show_success("Account created successfully")
		
		await get_tree().create_timer(1.2).timeout
		
		if role == "parent":
			get_tree().change_scene_to_file("res://parent_dashboard.tscn")
		else:
			get_tree().change_scene_to_file("res://chore_xplorer.tscn")
	else:
		var error_msg = data.get("error", "Unable to create account")
		_show_error(error_msg)

func _on_password_submit(_text: String) -> void:
	if current_mode == Mode.LOGIN:
		_on_login_pressed()
	elif selected_role == Role.PARENT:
		_on_register_pressed()

func _on_family_id_submit(_text: String) -> void:
	_on_register_pressed()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _set_buttons_disabled(disabled: bool) -> void:
	btn_login.disabled = disabled
	btn_register.disabled = disabled
	btn_parent.disabled = disabled
	btn_child.disabled = disabled
	btn_switch_mode.disabled = disabled

func _clear_message() -> void:
	lbl_error.visible = false
	lbl_error.text = ""

func _show_error(msg: String) -> void:
	lbl_error.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4, 1))
	lbl_error.text = msg
	lbl_error.visible = true

func _show_success(msg: String) -> void:
	lbl_error.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1))
	lbl_error.text = msg
	lbl_error.visible = true

func _show_info(msg: String) -> void:
	lbl_error.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9, 1))
	lbl_error.text = msg
	lbl_error.visible = true
