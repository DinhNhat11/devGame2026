# camera_follow.gd
# A smooth third-person camera that follows the player's boat.
# Attach this script to a Camera3D node in your game scene.
#
# Setup:
# 1. Add a Camera3D to your game scene
# 2. Attach this script to it
# 3. In the Inspector, assign the target (your Boat node)
# 4. Adjust the offset and smoothing values to taste
#
# The camera will smoothly follow behind and above the target,
# always looking at where the boat is heading.

extends Camera3D

# === CONFIGURATION ===

@export_group("Target")
@export var target: Node3D  # Drag your Boat node here in the Inspector

@export_group("Position")
@export var distance_behind: float = 12.0  # How far behind the target
@export var height_above: float = 6.0      # How far above the target
@export var look_ahead: float = 5.0        # How far ahead of target to look

@export_group("Smoothing")
@export var follow_speed: float = 5.0      # How fast camera catches up (higher = snappier)
@export var rotation_speed: float = 8.0    # How fast camera rotates to face target

# === STATE ===

var current_velocity: Vector3 = Vector3.ZERO  # Used for smooth damping

# === GODOT LIFECYCLE ===

func _ready():
	# If no target assigned, try to find one
	if target == null:
		_find_target()
	
	if target:
		# Snap to initial position immediately
		snap_to_target()
		print("Camera following: ", target.name)
	else:
		push_warning("CameraFollow: No target assigned! Drag your Boat into the Target field.")

func _physics_process(delta: float):
	# Use _physics_process for smoother following of physics objects
	if target == null:
		return
	
	_follow_target(delta)
	_look_at_target(delta)

# === CAMERA MOVEMENT ===

func _follow_target(delta: float):
	"""Smoothly moves the camera to follow behind the target."""
	
	# Calculate the desired position:
	# Behind the target (opposite of where it's facing) and above
	
	# Get the target's forward direction
	# In Godot, -Z is typically forward, so -transform.basis.z points forward
	var target_forward = -target.transform.basis.z
	
	# Calculate offset: behind and above
	var behind_offset = -target_forward * distance_behind
	var height_offset = Vector3.UP * height_above
	
	var desired_position = target.global_position + behind_offset + height_offset
	
	# Smoothly interpolate to the desired position
	# lerp = linear interpolation: moves a fraction of the way each frame
	global_position = global_position.lerp(desired_position, follow_speed * delta)
	
	# Alternative: use move_toward for constant-speed following
	# global_position = global_position.move_toward(desired_position, follow_speed * delta)

func _look_at_target(delta: float):
	"""Smoothly rotates the camera to look at the target."""
	
	# Calculate a look-ahead point
	# This makes the camera lead the target slightly for better game feel
	var look_at_point = target.global_position
	
	# If target is moving, look slightly ahead of it
	if target is RigidBody3D:
		var velocity = target.linear_velocity
		if velocity.length() > 0.5:
			look_at_point += velocity.normalized() * look_ahead
	
	# Calculate the direction to look at
	var direction_to_target = look_at_point - global_position
	
	if direction_to_target.length() < 0.01:
		return  # Avoid issues when very close
	
	# Calculate the target rotation
	var target_rotation = Transform3D().looking_at(direction_to_target, Vector3.UP).basis.get_euler()
	
	# Smoothly interpolate rotation
	rotation.x = lerp_angle(rotation.x, target_rotation.x, rotation_speed * delta)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, rotation_speed * delta)
	# Usually we don't want roll (z rotation) on a follow camera
	rotation.z = lerp_angle(rotation.z, 0, rotation_speed * delta)

# === PUBLIC METHODS ===

func set_target(new_target: Node3D):
	"""Changes the camera's target at runtime."""
	target = new_target
	if target:
		snap_to_target()

func snap_to_target():
	"""Instantly moves the camera to its ideal position. Call after teleporting the target."""
	
	if target == null:
		return
	
	var target_forward = -target.transform.basis.z
	var behind_offset = -target_forward * distance_behind
	var height_offset = Vector3.UP * height_above
	
	global_position = target.global_position + behind_offset + height_offset
	look_at(target.global_position)

func _find_target():
	"""Attempts to automatically find a target in the player group."""
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		print("CameraFollow: Auto-found target in 'player' group")
