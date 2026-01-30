# boat_rescue_system.gd
# Handles all rescue and pickup interactions for the boat.
# This script detects collisions with mice, cheese, and fuel boosters,
# then processes each appropriately.
#
# Setup:
# 1. The Boat scene needs an Area3D child for detection
# 2. The Area3D needs a CollisionShape3D (slightly larger than the boat's physics shape)
# 3. Attach this script to the Area3D node
# 4. Connect the Area3D's "area_entered" signal to _on_area_entered (or use code)
#
# Scene structure:
# Boat (RigidBody3D)
# ├── MeshInstance3D
# ├── CollisionShape3D (for physics)
# ├── BoatController.gd
# ├── FuelSystem.gd
# └── RescueArea (Area3D)          ← This script goes here
#     └── CollisionShape3D (for detection, slightly larger)
#
# Alternative: You can also attach this to the Boat itself and use body_entered
# on the RigidBody3D, but using a separate Area3D gives more control.

extends Area3D

# === SIGNALS ===

signal mouse_rescued(mouse: Node)
signal capacity_changed(current: int, maximum: int)

# === CONFIGURATION ===

@export_group("Capacity")
@export var max_capacity: int = 4  # How many mice the boat can hold

@export_group("Mouse Positions")
# Local positions where rescued mice sit on the boat
# You can adjust these based on your boat's size
@export var mouse_slots: Array[Vector3] = [
	Vector3(-0.5, 0.5, 0.5),   # Front-left
	Vector3(0.5, 0.5, 0.5),    # Front-right
	Vector3(-0.5, 0.5, -0.5),  # Back-left
	Vector3(0.5, 0.5, -0.5),   # Back-right
	Vector3(0, 0.5, 0),        # Center (5th slot)
	Vector3(0, 0.7, 0.3),      # Stacked (6th slot)
]

# === STATE ===

var rescued_mice: Array[Node] = []  # Array of MouseController nodes
var fuel_system: Node = null        # Reference to FuelSystem

# === COMPUTED PROPERTIES ===

func get_current_count() -> int:
	return rescued_mice.size()

func has_capacity() -> bool:
	return rescued_mice.size() < max_capacity

func is_empty() -> bool:
	return rescued_mice.size() == 0

# === GODOT LIFECYCLE ===

func _ready():
	# Connect to our own area_entered signal
	# This fires when another Area3D overlaps with us
	area_entered.connect(_on_area_entered)
	
	# Also connect body_entered in case pickups are RigidBody3D instead of Area3D
	body_entered.connect(_on_body_entered)
	
	# Find the fuel system (should be on parent or sibling)
	_find_fuel_system()
	
	# Set up collision layers
	# Make sure this Area3D is set to detect pickups
	# In Project Settings > Layer Names > 3D Physics, you might name layers like:
	# Layer 1: player, Layer 2: pickups, Layer 3: environment
	
	# Notify UI of initial capacity
	capacity_changed.emit(get_current_count(), max_capacity)
	
	print("Rescue system ready! Capacity: ", max_capacity)

# === COLLISION DETECTION ===

func _on_area_entered(area: Area3D):
	"""Called when another Area3D overlaps with our rescue zone."""
	
	# Check what we collided with using groups
	# Groups are set on the root node of each pickup scene
	
	if area.is_in_group("mouse"):
		_try_rescue_mouse(area)
	elif area.is_in_group("cheese"):
		_collect_cheese(area)
	elif area.is_in_group("booster"):
		_collect_booster(area)

func _on_body_entered(body: Node3D):
	"""Called when a physics body enters. Backup detection method."""
	
	if body.is_in_group("mouse"):
		_try_rescue_mouse(body)
	elif body.is_in_group("cheese"):
		_collect_cheese(body)
	elif body.is_in_group("booster"):
		_collect_booster(body)

# === RESCUE AND COLLECTION ===

func _try_rescue_mouse(mouse_node: Node):
	"""Attempts to rescue a mouse. Fails if at capacity or mouse unavailable."""
	
	# Get the MouseController script
	var mouse = mouse_node
	if not mouse.has_method("rescue"):
		# Maybe the script is on the parent?
		if mouse.get_parent() and mouse.get_parent().has_method("rescue"):
			mouse = mouse.get_parent()
		else:
			push_warning("Detected mouse but couldn't find MouseController!")
			return
	
	# Check if mouse can be rescued
	if mouse.has_method("is_available_for_rescue"):
		if not mouse.is_available_for_rescue():
			return  # Already rescued or drowned
	
	# Check our capacity
	if not has_capacity():
		print("Boat is full! Cannot rescue more mice.")
		# TODO: Play "boat full" feedback sound
		return
	
	# Rescue the mouse!
	mouse.rescue()

	# Notify GameManager for scoring (adds cheese based on mouse type)
	if GameManager:
		GameManager.on_mouse_rescued(mouse)

	# Notify listeners
	mouse_rescued.emit(mouse)

	print("Mouse rescued! +", mouse.cheese_reward, " cheese")

	# Remove the mouse from the scene
	mouse.queue_free()

func _collect_cheese(cheese_node: Node):
	"""Collects cheese and adds points to score."""
	
	# Get the CheesePickup script
	var cheese = cheese_node
	if not cheese.has_method("collect"):
		if cheese.get_parent() and cheese.get_parent().has_method("collect"):
			cheese = cheese.get_parent()
		else:
			push_warning("Detected cheese but couldn't find CheesePickup script!")
			return
	
	# Collect the cheese
	cheese.collect()

	# Notify GameManager (+1 cheese)
	if GameManager:
		GameManager.on_cheese_collected(1)

	# Remove the cheese from the scene
	cheese.queue_free()

	print("Collected cheese! +1 cheese")

func _collect_booster(booster_node: Node):
	"""Collects a fuel booster and adds fuel to the boat."""
	
	# Get the FuelBooster script
	var booster = booster_node
	if not booster.has_method("collect"):
		if booster.get_parent() and booster.get_parent().has_method("collect"):
			booster = booster.get_parent()
		else:
			push_warning("Detected booster but couldn't find FuelBooster script!")
			return
	
	if not fuel_system:
		push_warning("No fuel system found - cannot use booster!")
		return
	
	# Collect and get fuel amount
	var fuel_amount = booster.collect()
	
	# Add fuel to our system
	fuel_system.add_fuel(fuel_amount)
	
	print("Collected booster! Added ", fuel_amount, " fuel.")

# === HELPER METHODS ===

func _get_slot_position(index: int) -> Vector3:
	"""Gets the local position for a mouse slot."""
	
	if index < mouse_slots.size():
		return mouse_slots[index]
	else:
		# Fallback: stack on top if we somehow exceed slots
		return Vector3(0, 0.5 + (index * 0.3), 0)

func _attach_mouse_to_boat(mouse: Node, local_position: Vector3):
	"""Parents the mouse to the boat and positions it."""
	
	# Get the boat (parent of this Area3D)
	var boat = get_parent()
	
	# Remove mouse from its current parent
	var mouse_root = mouse
	# Find the root node of the mouse scene (might be the mouse itself or its parent)
	while mouse_root.get_parent() and not mouse_root.get_parent().is_in_group("game_root"):
		if mouse_root.get_parent() == get_tree().current_scene:
			break
		mouse_root = mouse_root.get_parent()
	
	# Reparent to boat
	mouse_root.get_parent().remove_child(mouse_root)
	boat.add_child(mouse_root)
	
	# Set local position on the boat
	mouse_root.position = local_position
	mouse_root.rotation = Vector3.ZERO
	
	# Tell the mouse it's attached (so it can stop bobbing, etc.)
	if mouse.has_method("attach_to_boat"):
		mouse.attach_to_boat(boat, local_position)

func _find_fuel_system():
	"""Finds the FuelSystem node."""
	
	# Check siblings on the parent
	var boat = get_parent()
	if boat:
		for child in boat.get_children():
			if child.has_signal("fuel_changed"):
				fuel_system = child
				return
		
		# Check if it's a script on the parent itself
		if boat.has_signal("fuel_changed"):
			fuel_system = boat
			return
	
	# Try to find in player group
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.has_signal("fuel_changed"):
			fuel_system = player
			return
		for child in player.get_children():
			if child.has_signal("fuel_changed"):
				fuel_system = child
				return
	
	push_warning("BoatRescueSystem: Could not find FuelSystem!")

# === PUBLIC METHODS ===

func set_capacity(new_capacity: int):
	"""Sets the boat's mouse capacity. Called when selecting different boats."""
	
	max_capacity = new_capacity
	capacity_changed.emit(get_current_count(), max_capacity)

func deposit_mice() -> int:
	"""
	Removes all mice from the boat and returns the count.
	Could be used for a 'safe zone' mechanic where you deposit mice for points.
	"""
	
	var count = rescued_mice.size()
	
	for mouse in rescued_mice:
		if is_instance_valid(mouse):
			mouse.queue_free()
	
	rescued_mice.clear()
	capacity_changed.emit(get_current_count(), max_capacity)
	
	return count

func get_rescued_mice() -> Array[Node]:
	"""Returns the array of rescued mice."""
	return rescued_mice
