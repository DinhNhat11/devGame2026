# mouse_controller.gd
# Represents a drowning mouse that the player needs to rescue.
# Each mouse has a countdown timer - when it reaches zero, the mouse drowns.
#
# Setup:
# 1. Create an Area3D node as the root (for detection by the boat)
# 2. Add MeshInstance3D child (sphere for now, can replace with mouse model)
# 3. Add CollisionShape3D child with SphereShape3D
# 4. Add this script to the root Area3D
# 5. Add the node to group "mouse"
# 6. Save as a scene (mouse.tscn) so GameManager can spawn it
#
# The mouse will:
# - Bob up and down in the water (gets frantic as time runs out)
# - Change color from green to yellow to red based on urgency
# - Emit signals when rescued or drowned
# - Delete itself when drowned (with animation)

extends Area3D

# === MOUSE TYPES ===
# Priority system: Fat mice give more cheese but drown faster
enum MouseType { LITTLE, SKINNY, FAT }

const MOUSE_DATA = {
	MouseType.LITTLE: { "time": 30.0, "cheese": 1, "scale": 0.6 },
	MouseType.SKINNY: { "time": 18.0, "cheese": 2, "scale": 0.8 },
	MouseType.FAT:    { "time": 8.0,  "cheese": 5, "scale": 1.2 },
}

# === SIGNALS ===
# GameManager and scoring system connect to these

signal rescued(mouse: Node)
signal drowned(mouse: Node)

# === CONFIGURATION ===

@export_group("Mouse Type")
@export var mouse_type: MouseType = MouseType.LITTLE
var cheese_reward: int = 1

@export_group("Drowning")
@export var max_drowning_time: float = 10.0  # Overridden by mouse_type in _ready()

@export_group("Visual Feedback")
@export var safe_color: Color = Color(0.2, 0.8, 0.2)      # Green
@export var warning_color: Color = Color(0.9, 0.9, 0.2)   # Yellow
@export var danger_color: Color = Color(0.9, 0.2, 0.2)    # Red

@export_group("Animation")
@export var bob_speed: float = 2.0       # How fast the bobbing animation
@export var bob_height: float = 0.3      # How high the bob
@export var panic_multiplier: float = 2.0  # Speed increase when panicking

# === STATE ===

var current_time: float = 0.0
var is_rescued: bool = false
var is_drowned: bool = false
var start_position: Vector3

# References
var mesh_instance: MeshInstance3D = null
var material: StandardMaterial3D = null

# === COMPUTED PROPERTIES ===

func get_time_remaining() -> float:
	return current_time

func get_drowning_percentage() -> float:
	# Returns 1.0 when full time, 0.0 when about to drown
	return current_time / max_drowning_time

func is_available_for_rescue() -> bool:
	return not is_rescued and not is_drowned

# === GODOT LIFECYCLE ===

func _ready():
	# Add to mouse group for detection
	add_to_group("mouse")

	# Apply mouse type data
	var data = MOUSE_DATA[mouse_type]
	max_drowning_time = data["time"]
	cheese_reward = data["cheese"]
	scale = Vector3.ONE * data["scale"]

	# Initialize timer
	current_time = max_drowning_time
	
	# Store starting position for bobbing animation
	start_position = global_position
	
	# Find and set up the mesh for color changes
	_setup_mesh()
	
	# Apply initial color
	_update_visuals()

func _process(delta: float):
	# Don't process if already rescued or drowned
	if is_rescued or is_drowned:
		return
	
	# Count down the drowning timer
	current_time -= delta
	
	# Update visual appearance based on time remaining
	_update_visuals()
	
	# Animate bobbing in the water
	_animate_bobbing()
	
	# Check if we've drowned
	if current_time <= 0:
		_drown()

# === VISUAL FEEDBACK ===

func _setup_mesh():
	"""Finds the MeshInstance3D child and creates a unique material for color changes."""
	
	# Find the MeshInstance3D child
	for child in get_children():
		if child is MeshInstance3D:
			mesh_instance = child
			break
	
	if mesh_instance == null:
		push_warning("MouseController: No MeshInstance3D child found!")
		return
	
	# Create a unique material instance so color changes don't affect other mice
	# This is important - without this, ALL mice would change color together!
	var existing_material = mesh_instance.get_surface_override_material(0)
	
	if existing_material:
		material = existing_material.duplicate()
	else:
		material = StandardMaterial3D.new()
	
	mesh_instance.set_surface_override_material(0, material)

func _update_visuals():
	"""Updates the mouse's color based on remaining time."""
	
	if material == null:
		return
	
	var time_percent = get_drowning_percentage()  # 1.0 = safe, 0.0 = danger
	var target_color: Color
	
	if time_percent > 0.66:
		# Plenty of time - green to yellow transition
		var t = (time_percent - 0.66) / 0.34
		target_color = warning_color.lerp(safe_color, t)
	
	elif time_percent > 0.33:
		# Getting urgent - yellow to red transition
		var t = (time_percent - 0.33) / 0.33
		target_color = danger_color.lerp(warning_color, t)
	
	else:
		# Critical - red, with flashing when very low
		target_color = danger_color
		
		# Flash when critical (less than 20% time)
		if time_percent < 0.2:
			var flash = abs(sin(Time.get_ticks_msec() * 0.01))
			target_color = danger_color.lerp(Color.WHITE, flash * 0.3)
	
	material.albedo_color = target_color

func _animate_bobbing():
	"""Animates the mouse bobbing in the water, faster when panicking."""
	
	# Calculate panic level - more panic = faster bobbing
	# Urgency is 0 when full time, 1 when about to drown
	var urgency = 1.0 - get_drowning_percentage()
	var current_bob_speed = bob_speed * (1.0 + urgency * panic_multiplier)
	
	# Calculate vertical offset using sine wave
	var time_factor = Time.get_ticks_msec() * 0.001  # Convert to seconds
	var vertical_offset = sin(time_factor * current_bob_speed) * bob_height
	
	# Apply bobbing to position
	var new_position = start_position
	new_position.y += vertical_offset
	global_position = new_position
	
	# Add wobble rotation when panicking
	if urgency > 0.5:
		var wobble = sin(time_factor * current_bob_speed * 2.0) * urgency * 10.0
		rotation_degrees = Vector3(wobble, 0, wobble * 0.5)

# === STATE CHANGES ===

func rescue():
	"""Called when the player successfully rescues this mouse."""
	
	# Prevent double-rescue
	if is_rescued or is_drowned:
		return
	
	is_rescued = true
	
	print("Mouse rescued with ", current_time, " seconds remaining!")
	
	# Emit signal for scoring
	rescued.emit(self)
	
	# Change to happy color
	if material:
		material.albedo_color = safe_color
	
	# Stop bobbing by resetting rotation
	rotation_degrees = Vector3.ZERO

func _drown():
	"""Called when the timer runs out and the mouse drowns."""
	
	# Prevent re-drowning
	if is_drowned:
		return
	
	is_drowned = true
	current_time = 0
	
	print("A mouse drowned! :(")
	
	# Emit signal
	drowned.emit(self)
	
	# Play drowning animation then delete
	_play_drown_animation()

func _play_drown_animation():
	"""Animates the mouse sinking and fading out."""
	
	# Create a tween for the animation
	var tween = create_tween()
	tween.set_parallel(true)  # Run all tweens simultaneously
	
	# Sink down
	var sink_target = global_position + Vector3(0, -3, 0)
	tween.tween_property(self, "global_position", sink_target, 2.0)
	
	# Fade out (if material supports transparency)
	if material:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 2.0)
	
	# Scale down
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 2.0)
	
	# Delete after animation completes
	tween.chain().tween_callback(queue_free)

# === UTILITY ===

func attach_to_boat(boat: Node3D, local_position: Vector3):
	"""Called when this mouse is picked up by a boat."""
	
	# The boat_rescue_system handles reparenting, this is for any additional setup
	
	# Stop bobbing animation by disabling process
	set_process(false)
	
	# Ensure we're at the correct local position
	position = local_position
	rotation = Vector3.ZERO
	
	# Set happy color
	if material:
		material.albedo_color = safe_color

func get_urgency() -> float:
	"""
	Returns how urgent this mouse is (0.0 = not urgent, 1.0 = very urgent).
	Used for priority sorting - higher urgency = should rescue first.
	"""
	return 1.0 - get_drowning_percentage()
