extends Control

func _on_parent_login_button_down() -> void:
	get_tree().change_scene_to_file("res://parent_login.tscn")

func _on_chore_xplorer_button_down() -> void:
	get_tree().change_scene_to_file("res://chore_xplorer.tscn")

func _on_exit_button_down() -> void:
	get_tree().quit()
