extends Node3D
# Mouse-Look Camera with Character Rotation
# The camera rotates with mouse movement AND the character turns to face where you're looking
#
# Setup:
# 1. Add Node3D to scene, name it "CameraRig"
# 2. Add Camera3D as child of CameraRig
# 3. Attach this script to CameraRig
# 4. Drag your character into Target field in Inspector
#
# Structure:
# Character (CharacterBody3D)
# CameraRig (Node3D)          ← This script
# └── Camera3D

# === CONFIGURATION ===

@export_group("Target")
@export var target: Node3D  # Your character

@export_group("Camera Settings")
@export var camera_distance: float = 50.0
@export var camera_height: float = 30.0
@export var follow_speed: float = 10.0

@export_group("Mouse Look")
@export var mouse_sensitivity: float = 0.3
@export var invert_y: bool = false

@export_group("Camera Limits")
@export var min_pitch: float = -60.0  # How far down
@export var max_pitch: float = 60.0   # How far up

@export_group("Character Rotation")
@export var rotate_character: bool = true  # Turn character with mouse
@export var character_rotation_speed: float = 10.0

# === STATE ===

var yaw: float = 0.0    # Left/right rotation
var pitch: float = 0.0  # Up/down rotation
var camera_node: Camera3D

# === GODOT LIFECYCLE ===

func _ready():
	# Find camera
	camera_node = get_node_or_null("Camera3D")
	if not camera_node:
		for child in get_children():
			if child is Camera3D:
				camera_node = child
				break
	
	if not camera_node:
		push_error("No Camera3D found!")
		return
	
	# Position camera
	camera_node.position = Vector3(0, camera_height, camera_distance)
	
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Auto-find target
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			print("Camera: Found target - ", target.name)
	
	if not target:
		push_warning("No target set! Drag character into Inspector.")
	
	print("Mouse-look camera ready! Press ESC to release mouse.")

func _input(event):
	# Mouse look
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_handle_mouse_look(event.relative)
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	if not target:
		return
	
	# Follow target position
	global_position = global_position.lerp(target.global_position, follow_speed * delta)
	
	# Apply camera rotation
	rotation_degrees.x = pitch
	rotation_degrees.y = yaw
	
	# Rotate character to match camera yaw
	if rotate_character and target:
		_rotate_character(delta)

# === MOUSE LOOK ===

func _handle_mouse_look(mouse_delta: Vector2):
	# Horizontal (yaw)
	yaw -= mouse_delta.x * mouse_sensitivity
	
	# Vertical (pitch)
	var pitch_delta = mouse_delta.y * mouse_sensitivity
	if invert_y:
		pitch_delta = -pitch_delta
	pitch -= pitch_delta
	
	# Clamp pitch
	pitch = clamp(pitch, min_pitch, max_pitch)

# === CHARACTER ROTATION ===

func _rotate_character(delta: float):
	"""Makes character turn to face the camera's direction."""
	
	# Get the camera's forward direction on the XZ plane
	var camera_forward = -global_transform.basis.z
	camera_forward.y = 0
	camera_forward = camera_forward.normalized()
	
	if camera_forward.length() < 0.1:
		return
	
	# Calculate target rotation
	var target_rotation = atan2(camera_forward.x, camera_forward.z)
	
	# Smoothly rotate character
	var current_rotation = target.rotation.y
	var new_rotation = lerp_angle(current_rotation, target_rotation, character_rotation_speed * delta)
	target.rotation.y = new_rotation

# === PUBLIC METHODS ===

func set_distance(distance: float):
	"""Change camera distance."""
	camera_distance = distance
	if camera_node:
		camera_node.position.z = distance

func reset_rotation():
	"""Reset camera to default position."""
	yaw = 0
	pitch = 0
