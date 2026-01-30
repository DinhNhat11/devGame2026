# main_world.gd
# Attached to the MainWorld root node.
# Starts the game when the scene loads.

extends RigidBody3D

func _ready():
	GameManager.start_game()
