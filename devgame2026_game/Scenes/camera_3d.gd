extends Camera3D
# SIMPLE Camera - Just Attach to Camera3D
# The easiest camera setup - just follows the player
#
# Setup:
# 1. Add Camera3D to your scene
# 2. Attach THIS script to the Camera3D
# 3. Drag your character into "Target" in Inspector
# 4. Done!

@export var target: Node3D  # Drag your character here
@export var offset: Vector3 = Vector3(0, 5, 10)  # Camera position relative to character
@export var follow_speed: float = 5.0

func _ready():
	# Make this the active camera
	make_current()
	
	# Auto-find target if not set
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]

func _process(delta):
	if not target:
		return
	
	# Follow target smoothly
	var target_pos = target.global_position + offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Always look at target
	look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)
