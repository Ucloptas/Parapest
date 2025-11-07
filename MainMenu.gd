extends Control

# Create the dialog once when the scene loads
var dialog: AcceptDialog

func _ready() -> void:
	dialog = AcceptDialog.new()
	dialog.title = "Parent Login"
	dialog.dialog_text = "Parent portal coming soon."
	add_child(dialog)

func _on_parent_login_button_down() -> void:
	dialog.popup_centered()

func _on_chore_xplorer_button_down() -> void:
	get_tree().change_scene_to_file("res://chore_xplorer.tscn")  # adjust path if needed

func _on_exit_button_down() -> void:
	get_tree().quit()
