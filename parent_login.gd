extends Control

@onready var email: LineEdit    = %Email
@onready var password: LineEdit = %Password
@onready var lbl_error: Label   = %Error
@onready var btn_login: Button  = %BtnLogin
@onready var btn_back: Button   = %BtnBack

var http_client: Node

func _ready() -> void:
	# Get the HTTPClient singleton
	http_client = get_node("/root/HTTPClient")
	
	email.grab_focus()  # start typing immediately
	btn_login.pressed.connect(_on_login_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	# If you connected Password.text_submitted in the Node tab, it will call _on_password_submit

func _on_login_pressed() -> void:
	var username := email.text.strip_edges()
	var pwd := password.text
	if username.is_empty() or pwd.is_empty():
		_show_error("Please enter username and password.")
		return
	
	# Disable button during login
	btn_login.disabled = true
	_show_error("Logging in...")
	
	# Call the backend API
	http_client.login(username, pwd, _on_login_response)

func _on_login_response(success: bool, data: Dictionary) -> void:
	btn_login.disabled = false
	
	if success:
		_show_error("")
		# Check if user is a parent
		var user = data.get("user", {})
		var role = user.get("role", "")
		
		if role == "parent":
			# Navigate to parent dashboard
			get_tree().change_scene_to_file("res://parent_dashboard.tscn")
		else:
			# Navigate to child dashboard (chore_xplorer)
			get_tree().change_scene_to_file("res://chore_xplorer.tscn")
	else:
		var error_msg = data.get("error", "Login failed")
		# If user doesn't exist, try to register as parent
		if error_msg == "Invalid credentials" or error_msg.contains("not found"):
			_show_error("Account not found. Creating new parent account...")
			var username = email.text.strip_edges()
			var pwd = password.text
			btn_login.disabled = true
			http_client.register(username, pwd, "parent", "", _on_register_response)
		else:
			_show_error(error_msg)

func _on_register_response(success: bool, data: Dictionary) -> void:
	btn_login.disabled = false
	
	if success:
		_show_error("Account created! Logging in...")
		# Navigate to parent dashboard
		get_tree().change_scene_to_file("res://parent_dashboard.tscn")
	else:
		var error_msg = data.get("error", "Registration failed")
		_show_error("Registration failed: " + error_msg)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_password_submit(_text: String) -> void:
	_on_login_pressed()

func _show_error(msg: String) -> void:
	lbl_error.text = msg
	lbl_error.visible = msg != ""
