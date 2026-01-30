extends Node3D
# Third Person Camera Controller
# Follows the player character from behind with smooth movement
#
# Setup:
# 1. Add a Node3D to your scene, rename to "CameraRig"
# 2. Add a Camera3D as child of CameraRig
# 3. Attach this script to the CameraRig (not the Camera3D)
# 4. In Inspector, drag your character into the "Target" field
#
# Scene structure:
# Character (CharacterBody3D)
# CameraRig (Node3D)              ← This script goes here
# └── Camera3D

# === CONFIGURATION ===

@export_group("Target")
@export var target: Node3D  # Drag your character here

@export_group("Camera Position")
@export var camera_distance: float = 8.0  # How far behind character
@export var camera_height: float = 4.0    # How high above character
@export var camera_offset: Vector3 = Vector3.ZERO  # Additional offset

@export_group("Camera Behavior")
@export var follow_speed: float = 5.0     # How fast camera catches up
@export var rotation_speed: float = 3.0   # How fast camera rotates

@export_group("Mouse Look")
@export var mouse_sensitivity: float = 0.3
@export var enable_mouse_look: bool = true
@export var invert_y_axis: bool = false

@export_group("Camera Limits")
@export var min_pitch: float = -60.0  # How far down you can look
@export var max_pitch: float = 60.0   # How far up you can look

# === STATE ===

var camera_rotation: Vector2 = Vector2.ZERO  # X = yaw, Y = pitch
var camera_node: Camera3D

# === GODOT LIFECYCLE ===

func _ready():
	# Find the Camera3D child
	camera_node = get_node_or_null("Camera3D")
	
	if not camera_node:
		# Try to find any Camera3D child
		for child in get_children():
			if child is Camera3D:
				camera_node = child
				break
	
	if not camera_node:
		push_error("CameraController: No Camera3D found as child!")
		return
	
	# Position camera initially
	camera_node.position = Vector3(0, 0, camera_distance)
	
	# Capture mouse if using mouse look
	if enable_mouse_look:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Find target if not set
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			print("Camera: Auto-detected target: ", target.name)
	
	if not target:
		push_warning("Camera: No target set! Drag character into 'Target' field in Inspector")
	
	print("Camera controller ready!")

func _input(event):
	# Handle mouse look
	if enable_mouse_look and event is InputEventMouseMotion:
		_handle_mouse_look(event.relative)
	
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	if not target or not camera_node:
		return
	
	# Handle keyboard camera rotation (arrow keys or Q/E)
	_handle_keyboard_rotation(delta)
	
	# Follow target
	_follow_target(delta)
	
	# Apply rotation to camera rig
	_apply_rotation()

# === CAMERA MOVEMENT ===

func _follow_target(delta: float):
	"""Smoothly follows the target character."""
	
	# Calculate desired position (target position)
	var desired_position = target.global_position
	
	# Smoothly move to target
	global_position = global_position.lerp(desired_position, follow_speed * delta)

func _apply_rotation():
	"""Applies yaw and pitch rotation to camera."""
	
	# Clamp pitch to limits
	camera_rotation.y = clamp(camera_rotation.y, min_pitch, max_pitch)
	
	# Apply rotation
	rotation_degrees.y = camera_rotation.x  # Yaw (left/right)
	rotation_degrees.x = camera_rotation.y  # Pitch (up/down)

# === INPUT HANDLING ===

func _handle_mouse_look(mouse_delta: Vector2):
	"""Handles mouse look rotation."""
	
	# Horizontal rotation (yaw)
	camera_rotation.x -= mouse_delta.x * mouse_sensitivity
	
	# Vertical rotation (pitch)
	var y_delta = mouse_delta.y * mouse_sensitivity
	if invert_y_axis:
		y_delta = -y_delta
	camera_rotation.y -= y_delta

func _handle_keyboard_rotation(delta: float):
	"""Handles keyboard camera rotation (arrow keys or Q/E)."""
	
	var rotate_input = Vector2.ZERO
	
	# Horizontal rotation
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("rotate_left"):
		rotate_input.x += 1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("rotate_right"):
		rotate_input.x -= 1
	
	# Vertical rotation
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("rotate_up"):
		rotate_input.y += 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("rotate_down"):
		rotate_input.y -= 1
	
	# Apply rotation
	camera_rotation.x += rotate_input.x * rotation_speed * 50 * delta
	camera_rotation.y += rotate_input.y * rotation_speed * 50 * delta

# === PUBLIC METHODS ===

func set_target(new_target: Node3D):
	"""Change the camera's follow target."""
	target = new_target

func reset_camera():
	"""Reset camera to default behind-character position."""
	camera_rotation = Vector2.ZERO

func set_distance(distance: float):
	"""Change camera distance from character."""
	camera_distance = distance
	if camera_node:
		camera_node.position.z = distance

func shake(intensity: float = 0.5, duration: float = 0.3):
	"""Simple camera shake effect."""
	var original_pos = camera_node.position
	var shake_timer = 0.0
	
	while shake_timer < duration:
		shake_timer += get_process_delta_time()
		var offset = Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			0
		)
		camera_node.position = original_pos + offset
		await get_tree().process_frame
	
	camera_node.position = original_pos
