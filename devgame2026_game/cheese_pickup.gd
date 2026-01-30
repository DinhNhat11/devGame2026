# cheese_pickup.gd
# A collectible floating in the water that gives the player points when touched.
# This is one of the simplest scripts in your game - a good template for other pickups.
#
# Setup:
# 1. Create an Area3D node as the root (for collision detection)
# 2. Add MeshInstance3D child (cylinder or wedge shape, yellow material)
# 3. Add CollisionShape3D child with appropriate shape
# 4. Add this script to the root Area3D
# 5. Add the node to group "cheese"
# 6. Save as scene (cheese.tscn) for spawning

extends Area3D

# === CONFIGURATION ===

@export_group("Value")
@export var point_value: int = 5  # How many points this cheese is worth

@export_group("Animation")
@export var rotation_speed: float = 45.0  # Degrees per second
@export var bob_speed: float = 2.0        # Bob animation speed
@export var bob_height: float = 0.2       # How high it bobs

# === STATE ===

var start_position: Vector3
var is_collected: bool = false

# === GODOT LIFECYCLE ===

func _ready():
	# Add to cheese group for detection by the rescue system
	add_to_group("cheese")
	
	# Remember starting position for bobbing animation
	start_position = global_position

func _process(delta: float):
	# Don't animate if already collected
	if is_collected:
		return
	
	# Rotate continuously
	rotation_degrees.y += rotation_speed * delta
	
	# Bob up and down using a sine wave
	var time_factor = Time.get_ticks_msec() * 0.001
	var bob_offset = sin(time_factor * bob_speed) * bob_height
	global_position = Vector3(start_position.x, start_position.y + bob_offset, start_position.z)

# === COLLECTION ===

func collect() -> int:
	"""
	Called by the boat's rescue system when the player collects this cheese.
	Returns the point value so the caller can add it to the score.
	"""
	
	# Prevent double-collection
	if is_collected:
		return 0
	
	is_collected = true
	
	# Play collection effect
	_play_collect_effect()
	
	return point_value

func _play_collect_effect():
	"""Visual and audio feedback when collected."""
	
	# Quick scale-up then delete animation
	var tween = create_tween()
	
	# Pop effect - scale up quickly then disappear
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(self, "scale", Vector3(0, 0, 0), 0.1)
	
	# Delete after animation
	tween.tween_callback(queue_free)
	
	# You could also spawn particles here:
	# var particles = preload("res://effects/collect_particles.tscn").instantiate()
	# get_tree().current_scene.add_child(particles)
	# particles.global_position = global_position
