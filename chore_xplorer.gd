extends Node2D

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_panel: Panel = $PauseMenu/PausePanel
@onready var info_popup_container = $infoPopup/Overlay/HBoxContainer/InfoVboxContainer
var popup_height = 300
var is_paused: bool = false

func _ready():
	# Load selected character from HTTPClient
	var http_client = get_node("/root/HTTPClient")
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
	
	# Hide pause menu initially
	pause_menu.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_pause()
	elif event.is_action_pressed("interact"):
		interact()

func toggle_pause():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused
	pass

func _on_resume_pressed():
	toggle_pause()

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://login.tscn")

func _on_next_level_body_entered(body):
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://reward_xplorer.tscn")

func hide_info_popup():
	clear_popup_content()
	$infoPopup.hide()

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
func interact():
	if !$infoPopup.visible:
		var time = Time.get_datetime_dict_from_system()
		var time_string = "%02d:%02d:%02d" % [time["hour"], time["minute"], time["second"]]
		var test_data = {
			"time" : time_string,
			"current world" : "Chore Lobby"
		}
		show_info_popup(test_data)
	elif $infoPopup.visible:
		hide_info_popup()
