# boat_controller.gd
# Controls the player's boat movement on the water.
# Attach this to a RigidBody3D node that represents the boat.
#
# Setup checklist:
# 1. Create a RigidBody3D node, name it "Boat"
# 2. Add MeshInstance3D child (for the visual)
# 3. Add CollisionShape3D child (for physics collision)
# 4. Set RigidBody3D Gravity Scale to 0 (we're floating, not falling)
# 5. Set Linear Damp to ~2.0 (water resistance slows the boat)
# 6. Set Angular Damp to ~3.0 (prevents spinning forever)
# 7. Attach this script to the RigidBody3D
# 8. Add the boat to group "player"
#
# The script uses Godot's physics system to apply forces for realistic water movement.
# Movement feels floaty and momentum-based, like a real boat.

extends RigidBody3D

# === CONFIGURATION ===
# @export variables appear in the Inspector so you can tweak without editing code

@export_group("Movement")
@export var move_speed: float = 800.0  # Force applied for forward/backward
@export var turn_speed: float = 2.5    # Rotation speed (radians per second)
@export var max_speed: float = 15.0    # Maximum velocity (prevents infinite acceleration)

@export_group("Water Settings")
@export var water_level: float = 0.5   # Y position the boat tries to stay at
@export var buoyancy_strength: float = 5.0  # How strongly boat returns to water level

# === STATE ===

var can_move: bool = true  # Set to false when out of fuel

# === SIGNALS ===
# Other scripts (like FuelSystem) can connect to these

signal movement_started
signal movement_stopped

var was_moving: bool = false

# === GODOT LIFECYCLE ===

func _ready():
	# Ensure we're set up correctly for water physics
	_configure_physics()
	
	# Add to the player group so other scripts can find us
	add_to_group("player")
	
	print("Boat ready! Use WASD to move.")

func _physics_process(delta: float):
	# _physics_process runs at a fixed rate (default 60 times/second)
	# Always use this for physics-related code, not _process
	
	if can_move:
		_handle_movement_input(delta)
	
	# Keep the boat at water level and upright
	_maintain_water_level(delta)
	_stay_upright(delta)
	
	# Clamp maximum speed to prevent boat from going too fast
	_clamp_velocity()
	
	# Track movement state for signals
	_update_movement_state()

# === MOVEMENT ===

func _handle_movement_input(delta: float):
	# Get input from the input map we set up in Project Settings
	# get_axis returns a value from -1 to 1 based on two opposing actions
	var forward_input = Input.get_axis("move_backward", "move_forward")
	var turn_input = Input.get_axis("move_right", "move_left")
	
	# Forward/Backward movement
	# We apply force in the direction the boat is facing (-basis.z is forward in Godot)
	if abs(forward_input) > 0.1:  # Small deadzone to prevent drift
		# transform.basis.z is the boat's forward direction
		# We negate it because in Godot, -Z is typically "forward"
		var forward_direction = -transform.basis.z
		var thrust = forward_direction * forward_input * move_speed * delta
		apply_central_force(thrust)
	
	# Turning (rotation around Y axis)
	if abs(turn_input) > 0.1:
		# Apply torque to rotate the boat
		# Positive Y torque turns left, negative turns right
		var torque = Vector3(0, turn_input * turn_speed, 0)
		apply_torque(torque)

func _maintain_water_level(delta: float):
	# If the boat drifts above or below water level, push it back
	# This simulates buoyancy without complex water physics
	
	var height_difference = water_level - global_position.y
	
	if abs(height_difference) > 0.05:  # Only correct if noticeably off
		# Apply an upward or downward force proportional to the difference
		var correction_force = Vector3(0, height_difference * buoyancy_strength, 0)
		apply_central_force(correction_force)

func _stay_upright(delta: float):
	# Prevent the boat from tipping over by correcting X and Z rotation
	# We want the boat to stay level on the water
	
	var current_rotation = rotation_degrees
	
	# If tilted, apply corrective torque
	if abs(current_rotation.x) > 1.0:
		apply_torque(Vector3(-current_rotation.x * 0.1, 0, 0))
	
	if abs(current_rotation.z) > 1.0:
		apply_torque(Vector3(0, 0, -current_rotation.z * 0.1))

func _clamp_velocity():
	# Prevent the boat from accelerating infinitely
	var current_speed = linear_velocity.length()
	
	if current_speed > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _update_movement_state():
	# Track whether the boat is moving and emit signals for fuel consumption
	var is_moving = linear_velocity.length() > 0.5 or angular_velocity.length() > 0.1
	
	if is_moving and not was_moving:
		movement_started.emit()
	elif not is_moving and was_moving:
		movement_stopped.emit()
	
	was_moving = is_moving

func _configure_physics():
	# Configure RigidBody3D settings for boat-like behavior
	# These can also be set in the Inspector, but doing it here ensures consistency
	
	# Gravity should be 0 since we're floating (set in Inspector is better, but backup here)
	gravity_scale = 0.0
	
	# Add some damping so the boat slows down naturally
	# This simulates water resistance
	if linear_damp < 1.0:
		linear_damp = 2.0
	
	if angular_damp < 1.0:
		angular_damp = 3.0
	
	# Lock rotation on X and Z axes to prevent barrel rolls
	# Actually, we'll handle this with corrective forces instead for smoother behavior
	# axis_lock_angular_x = true
	# axis_lock_angular_z = true

# === PUBLIC METHODS ===
# Called by other scripts like FuelSystem

func set_can_move(value: bool):
	"""Enable or disable boat movement. Called when fuel runs out."""
	can_move = value
	
	if not can_move:
		# Stop all movement when disabled
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		print("Boat movement disabled!")
	else:
		print("Boat movement enabled!")

func is_moving() -> bool:
	"""Returns true if the boat is currently moving. Used by FuelSystem."""
	return linear_velocity.length() > 0.5 or angular_velocity.length() > 0.1

func get_speed() -> float:
	"""Returns the current speed of the boat."""
	return linear_velocity.length()
