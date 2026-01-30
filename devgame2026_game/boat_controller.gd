extends CharacterBody3D
# Character Controller - Mouse Rotates Character Directly
# Mouse left/right = Character turns left/right
# Camera will follow behind automatically
#
# Setup:
# 1. Attach to CharacterBody3D
# 2. Add CollisionShape3D child
# 3. Done! Mouse controls character rotation

# === MOVEMENT CONFIGURATION ===

@export_group("Movement")
@export var walk_speed: float = 50.0
@export var run_speed: float = 80.0
@export var acceleration: float = 30.0

@export_group("Jumping")
@export var jump_velocity: float = 6.0

@export_group("Mouse Rotation")
@export var mouse_sensitivity: float = 0.3
@export var enable_mouse_rotation: bool = true

# === STATE ===

var current_speed: float = walk_speed
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# === GODOT LIFECYCLE ===

func _ready():
	add_to_group("player")
	
	# Capture mouse
	if enable_mouse_rotation:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	print("Character ready! Mouse to turn, WASD to move")

func _input(event):
	# Mouse rotates character left/right
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion and enable_mouse_rotation:
			# Rotate character with mouse horizontal movement
			rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Sprint
	current_speed = run_speed if Input.is_action_pressed("ui_shift") else walk_speed
	
	# Get input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Move relative to character's facing direction
	var direction = Vector3.ZERO
	if input_dir.length() > 0:
		# Forward/back relative to where character is facing
		direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		direction.y = 0
		direction = direction.normalized()
	
	# Apply movement
	var target_velocity = direction * current_speed
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
	
	move_and_slide()
