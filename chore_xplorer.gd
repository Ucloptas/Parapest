extends Node2D
func _ready():
	#load selected character
	var player_scene = preload("res://characters/pinkPlayer.tscn")
	var player_instance = player_scene.instantiate()
	# Add to placeholder
	$playerPlaceholder.add_child(player_instance)
	# Optionally center it or position it on the map
	player_instance.position = Vector2(0, 0)


func _on_next_level_body_entered(body):
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://reward_xplorer.tscn")
