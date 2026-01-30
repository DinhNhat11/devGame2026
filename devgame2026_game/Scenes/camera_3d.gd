extends Camera3D
# Simple Follow Camera - Stays Behind Character
# Automatically follows and rotates to match character's orientation
#
# Setup:
# 1. Add Camera3D to your scene
# 2. Attach this script
# 3. Drag character into Target field in Inspector

@export var target: Node3D  # Your character
@export var distance: float = 8.0  # How far behind
@export var height: float = 3.0    # How high above
@export var follow_speed: float = 8.0  # How fast camera follows
@export var rotation_speed: float = 10.0  # How fast camera rotates

func _ready():
	make_current()
	
	# Auto-find target
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			print("Camera found target: ", target.name)

func _process(delta):
	if not target:
		return
	
	# Calculate desired position behind character
	var target_position = target.global_position
	target_position += target.global_transform.basis.z * distance  # Behind
	target_position.y += height  # Above
	
	# Smoothly move to position
	global_position = global_position.lerp(target_position, follow_speed * delta)
	
	# Smoothly rotate to match character's rotation
	var target_rotation = target.global_rotation
	global_rotation.y = lerp_angle(global_rotation.y, target_rotation.y, rotation_speed * delta)
	
	# Always look at character
	look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)
