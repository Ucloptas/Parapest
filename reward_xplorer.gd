extends Node2D
func _ready():
	#load selected character
	var player_scene = preload("res://Characters/pinkPlayer.tscn")
	var player_instance = player_scene.instantiate()
	# Add to placeholder
	$playerPlaceholder.add_child(player_instance)
	# Optionally center it or position it on the map
	player_instance.position = Vector2(0, -600)
	
