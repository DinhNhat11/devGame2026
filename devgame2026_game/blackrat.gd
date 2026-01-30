extends CharacterBody3D
# Character Movement Controller for 3D Model
# This script provides smooth, responsive character movement with support for
# walking, running, jumping, and camera-relative controls.
#
# Setup:
# 1. Change your Node3D to a CharacterBody3D
# 2. Add a CollisionShape3D child with an appropriate shape (CapsuleShape3D recommended)
# 3. Attach this script to the CharacterBody3D
# 4. Add a Camera3D to the scene (can be child or separate)
#
# Scene structure:
# Character (CharacterBody3D)          ← This script goes here
# ├── MeshInstance3D (your 3D model)
# ├── CollisionShape3D (CapsuleShape3D or similar)
# └── Camera3D (optional, or reference external camera)

# === SIGNALS ===

signal jumped()
signal landed()
signal started_running()
signal stopped_running()

# === MOVEMENT CONFIGURATION ===

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var acceleration: float = 10.0
@export var deceleration: float = 15.0
@export var air_control: float = 0.3  # How much control you have while jumping (0-1)

@export_group("Jumping")
@export var jump_velocity: float = 6.0
@export var gravity_multiplier: float = 1.5  # Makes character fall faster (feels more responsive)
@export var jump_buffer_time: float = 0.1  # Time window to buffer jump input
@export var coyote_time: float = 0.1  # Time after leaving ground where you can still jump

@export_group("Rotation")
@export var rotation_speed: float = 12.0  # How fast character rotates to face movement direction
@export var use_camera_relative_movement: bool = true  # Move relative to camera direction

@export_group("References")
@export var camera: Camera3D  # Drag your camera here in the inspector
@export var model_root: Node3D  # The visual model (if you want to rotate it separately)

# === STATE ===

var current_speed: float = walk_speed
var is_running: bool = false
var was_on_floor: bool = false
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0

# Get the gravity from the project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# === GODOT LIFECYCLE ===

func _ready():
	# If camera not set, try to find it
	if not camera:
		camera = get_viewport().get_camera_3d()
		if camera:
			print("Character: Auto-detected camera")
	
	# If model_root not set, try to find MeshInstance3D child
	if not model_root:
		for child in get_children():
			if child is MeshInstance3D:
				model_root = child
				print("Character: Auto-detected model root")
				break
	
	print("Character controller ready!")

func _physics_process(delta: float):
	# Update timers
	_update_timers(delta)
	
	# Handle jumping and gravity
	_handle_vertical_movement(delta)
	
	# Get input direction
	var input_dir = _get_input_direction()
	
	# Handle horizontal movement
	_handle_horizontal_movement(input_dir, delta)
	
	# Apply movement
	move_and_slide()
	
	# Check landing
	_check_landing()

# === VERTICAL MOVEMENT (JUMPING & GRAVITY) ===

func _handle_vertical_movement(delta: float):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * gravity_multiplier * delta
	
	# Handle jump input
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Execute jump if conditions are met
	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0:
			_jump()

func _jump():
	velocity.y = jump_velocity
	jump_buffer_timer = 0
	coyote_timer = 0
	jumped.emit()
	print("Jump!")

# === HORIZONTAL MOVEMENT ===

func _get_input_direction() -> Vector2:
	"""Gets input direction from WASD/Arrow keys."""
	
	# Default Godot input actions (you can customize these in Project Settings)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Alternative: Use custom actions if you've set them up
	# var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	return input_dir

func _handle_horizontal_movement(input_dir: Vector2, delta: float):
	# Update run state
	_update_run_state()
	
	# Convert 2D input to 3D direction
	var direction = _calculate_movement_direction(input_dir)
	
	# Calculate target velocity
	var target_velocity = Vector3.ZERO
	if direction != Vector3.ZERO:
		target_velocity = direction * current_speed
	
	# Apply acceleration/deceleration
	var control = air_control if not is_on_floor() else 1.0
	var accel = acceleration if direction != Vector3.ZERO else deceleration
	
	velocity.x = lerp(velocity.x, target_velocity.x, accel * control * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, accel * control * delta)
	
	# Rotate character to face movement direction
	if direction != Vector3.ZERO and model_root:
		_rotate_to_direction(direction, delta)

func _calculate_movement_direction(input_dir: Vector2) -> Vector3:
	"""Converts 2D input to 3D movement direction, optionally camera-relative."""
	
	if input_dir.length() == 0:
		return Vector3.ZERO
	
	var direction = Vector3.ZERO
	
	if use_camera_relative_movement and camera:
		# Get camera's forward and right directions (projected onto XZ plane)
		var cam_forward = -camera.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		
		var cam_right = camera.global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		
		# Combine input with camera directions
		direction = (cam_forward * -input_dir.y + cam_right * input_dir.x).normalized()
	else:
		# World-space movement (forward = -Z, right = +X)
		direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	return direction

func _rotate_to_direction(direction: Vector3, delta: float):
	"""Smoothly rotates the character model to face the movement direction."""
	
	var target_rotation = atan2(direction.x, direction.z)
	var current_rotation = model_root.rotation.y
	
	# Smooth rotation using lerp
	var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
	model_root.rotation.y = new_rotation

# === RUN STATE ===

func _update_run_state():
	"""Checks if player is holding run button and updates speed."""
	
	# Check for run input (Shift key by default)
	var wants_to_run = Input.is_action_pressed("ui_shift") or Input.is_action_pressed("sprint")
	
	if wants_to_run and not is_running:
		is_running = true
		current_speed = run_speed
		started_running.emit()
	elif not wants_to_run and is_running:
		is_running = false
		current_speed = walk_speed
		stopped_running.emit()

# === TIMERS ===

func _update_timers(delta: float):
	"""Updates jump buffer and coyote time."""
	
	# Jump buffer countdown
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Coyote time: brief window after leaving ground where you can still jump
	if is_on_floor():
		coyote_timer = coyote_time
	elif coyote_timer > 0:
		coyote_timer -= delta

func _check_landing():
	"""Detects when character lands on ground."""
	
	if not was_on_floor and is_on_floor():
		landed.emit()
		print("Landed!")
	
	was_on_floor = is_on_floor()

# === PUBLIC METHODS ===

func set_movement_enabled(enabled: bool):
	"""Enable/disable movement (useful for cutscenes, menus, etc.)."""
	set_physics_process(enabled)

func teleport(new_position: Vector3):
	"""Instantly move character to a new position."""
	global_position = new_position
	velocity = Vector3.ZERO

func add_impulse(impulse: Vector3):
	"""Adds a one-time force to the character (knockback, explosions, etc.)."""
	velocity += impulse

# === INPUT SETUP INSTRUCTIONS ===

# To use this script, make sure you have these input actions set up:
# Go to Project > Project Settings > Input Map and add:
#
# ui_accept (usually Space) - Jump
# ui_left (A / Left Arrow) - Move left
# ui_right (D / Right Arrow) - Move right  
# ui_up (W / Up Arrow) - Move forward
# ui_down (S / Down Arrow) - Move backward
# ui_shift (Shift) - Sprint/Run
#
# OR create custom actions:
# - jump
# - move_left, move_right, move_forward, move_back
# - sprint
