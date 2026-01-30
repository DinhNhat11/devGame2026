# fuel_booster.gd
# A pickup that restores fuel to the player's boat.
# These spawn less frequently than other pickups and are critical for survival!
#
# Setup:
# 1. Create an Area3D node as the root
# 2. Add MeshInstance3D child (capsule or canister shape)
# 3. Create a glowing green material (set emission for glow effect)
# 4. Add CollisionShape3D child
# 5. Add this script to the root Area3D
# 6. Add the node to group "booster"
# 7. Save as scene (fuel_booster.tscn) for spawning

extends Area3D

# === CONFIGURATION ===

@export_group("Fuel")
@export var fuel_amount: float = 25.0  # How much fuel this restores

@export_group("Animation")
@export var rotation_speed: float = 90.0   # Degrees per second (faster than cheese)
@export var bob_speed: float = 3.0          # Faster bobbing to stand out
@export var bob_height: float = 0.3         # Higher bob
@export var pulse_amount: float = 0.1       # How much the scale pulses

@export_group("Visual")
@export var booster_color: Color = Color(0.2, 1.0, 0.5)  # Bright green

# === STATE ===

var start_position: Vector3
var is_collected: bool = false
var mesh_instance: MeshInstance3D = null
var material: StandardMaterial3D = null

# === GODOT LIFECYCLE ===

func _ready():
	# Add to booster group for detection
	add_to_group("booster")
	
	# Remember starting position for bobbing
	start_position = global_position
	
	# Set up the glowing material
	_setup_material()

func _process(delta: float):
	if is_collected:
		return
	
	# Rotate faster than cheese to make it stand out
	rotation_degrees.y += rotation_speed * delta
	
	# Bobbing animation
	var time_factor = Time.get_ticks_msec() * 0.001
	var bob_offset = sin(time_factor * bob_speed) * bob_height
	global_position = Vector3(start_position.x, start_position.y + bob_offset, start_position.z)
	
	# Pulsing scale effect to make it more noticeable
	var pulse = 1.0 + sin(time_factor * bob_speed * 2) * pulse_amount
	scale = Vector3(pulse, pulse, pulse)

func _setup_material():
	"""Creates a glowing material to make the booster stand out."""
	
	# Find the MeshInstance3D child
	for child in get_children():
		if child is MeshInstance3D:
			mesh_instance = child
			break
	
	if mesh_instance == null:
		return
	
	# Create or duplicate the material
	material = StandardMaterial3D.new()
	material.albedo_color = booster_color
	
	# Enable emission for a glow effect
	material.emission_enabled = true
	material.emission = booster_color
	material.emission_energy_multiplier = 1.5  # Glow intensity
	
	mesh_instance.set_surface_override_material(0, material)

# === COLLECTION ===

func collect() -> float:
	"""
	Called by the boat's rescue system when the player collects this booster.
	Returns the fuel amount to add.
	"""
	
	if is_collected:
		return 0.0
	
	is_collected = true
	
	# Play collection effect
	_play_collect_effect()
	
	return fuel_amount

func _play_collect_effect():
	"""Visual feedback when collected - more dramatic than cheese."""
	
	var tween = create_tween()
	
	# Bright flash effect
	if material:
		tween.tween_property(material, "emission_energy_multiplier", 5.0, 0.1)
	
	# Scale up then disappear
	tween.parallel().tween_property(self, "scale", Vector3(2, 2, 2), 0.15)
	tween.tween_property(self, "scale", Vector3(0, 0, 0), 0.1)
	
	# Delete after animation
	tween.tween_callback(queue_free)
