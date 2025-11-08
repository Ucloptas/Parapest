extends Control

@onready var email: LineEdit    = %Email
@onready var password: LineEdit = %Password
@onready var lbl_error: Label   = %Error
@onready var btn_login: Button  = %BtnLogin
@onready var btn_back: Button   = %BtnBack

func _ready() -> void:
	email.grab_focus()  # start typing immediately
	btn_login.pressed.connect(_on_login_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	# If you connected Password.text_submitted in the Node tab, it will call _on_password_submit

func _on_login_pressed() -> void:
	var e := email.text.strip_edges()
	var p := password.text
	if e.is_empty() or p.is_empty():
		_show_error("Please enter email and password.")
		return

	# Placeholder authentication — replace with real logic later
	if e == "parent@example.com" and p == "1234":
		_show_error("")
		var dlg := AcceptDialog.new()
		dlg.title = "Login"
		dlg.dialog_text = "Logged in (placeholder)."
		add_child(dlg)
		dlg.popup_centered()
	else:
		_show_error("Invalid credentials (demo).")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_password_submit(_text: String) -> void:
	_on_login_pressed()

func _show_error(msg: String) -> void:
	lbl_error.text = msg
	lbl_error.visible = msg != ""
