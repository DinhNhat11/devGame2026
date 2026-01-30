# fuel_system.gd
# Manages the boat's fuel - consuming it while moving and triggering game over when empty.
# This creates the core tension: you need to keep moving to save mice, but moving uses fuel!
#
# Setup:
# 1. Attach this script to the same node as boat_controller.gd (the Boat RigidBody3D)
# 2. Or attach it to a child Node of the Boat
# 3. The script will find the BoatController automatically
#
# This script demonstrates Godot's signal system for decoupled communication.
# The UI connects to fuel_changed to update the gauge, and GameManager connects
# to fuel_depleted to trigger game over.

extends Node

# === SIGNALS ===
# These let other scripts react to fuel changes without tight coupling

signal fuel_changed(percentage: float)     # Emits 0.0 to 1.0
signal fuel_warning                         # Emitted when fuel gets low
signal fuel_critical                        # Emitted when fuel is critical
signal fuel_depleted                        # Emitted when fuel hits zero

# === CONFIGURATION ===

@export_group("Fuel Settings")
@export var max_fuel: float = 100.0         # Maximum fuel capacity
@export var consumption_rate: float = 3.0   # Fuel consumed per second while moving
@export var idle_consumption: float = 0.0   # Fuel consumed while stationary (0 = none)

@export_group("Warning Thresholds")
@export var warning_threshold: float = 0.30   # 30% - show warning
@export var critical_threshold: float = 0.15  # 15% - critical warning

# === STATE ===

var current_fuel: float = 0.0
var is_empty: bool = false
var warning_triggered: bool = false
var critical_triggered: bool = false

# Reference to the boat controller (to check if moving)
var boat_controller: Node = null

# === COMPUTED PROPERTIES ===

func get_fuel_percentage() -> float:
	return current_fuel / max_fuel

func is_warning() -> bool:
	return get_fuel_percentage() <= warning_threshold and not is_empty

func is_critical() -> bool:
	return get_fuel_percentage() <= critical_threshold and not is_empty

# === GODOT LIFECYCLE ===

func _ready():
	# Find the boat controller on the parent or siblings
	_find_boat_controller()
	
	# Initialize fuel to full
	current_fuel = max_fuel
	fuel_changed.emit(get_fuel_percentage())
	
	print("Fuel system ready: ", current_fuel, "/", max_fuel)

func _process(delta: float):
	# Don't process if already empty
	if is_empty:
		return
	
	# Consume fuel based on whether the boat is moving
	var consumption = 0.0
	
	if boat_controller and boat_controller.is_moving():
		consumption = consumption_rate * delta
	else:
		consumption = idle_consumption * delta
	
	if consumption > 0:
		consume_fuel(consumption)

# === FUEL MANAGEMENT ===

func consume_fuel(amount: float):
	"""Reduces fuel by the given amount. Triggers events at thresholds."""
	
	if is_empty:
		return
	
	# Store previous state for threshold detection
	var previous_percentage = get_fuel_percentage()
	
	# Reduce fuel
	current_fuel = max(0.0, current_fuel - amount)
	var new_percentage = get_fuel_percentage()
	
	# Notify listeners of the change
	fuel_changed.emit(new_percentage)
	
	# Check threshold crossings
	_check_thresholds(previous_percentage, new_percentage)
	
	# Check for empty
	if current_fuel <= 0 and not is_empty:
		_handle_fuel_depleted()

func add_fuel(amount: float):
	"""Adds fuel to the tank. Cannot exceed maximum."""
	
	if is_empty:
		print("Cannot add fuel - boat has already sunk!")
		return
	
	var previous_fuel = current_fuel
	current_fuel = min(max_fuel, current_fuel + amount)
	
	var actual_added = current_fuel - previous_fuel
	print("Added ", actual_added, " fuel. Now at ", current_fuel, "/", max_fuel)
	
	# Reset warning states if we're back above thresholds
	if get_fuel_percentage() > warning_threshold:
		warning_triggered = false
	if get_fuel_percentage() > critical_threshold:
		critical_triggered = false
	
	fuel_changed.emit(get_fuel_percentage())

func _check_thresholds(previous: float, current: float):
	"""Checks if we crossed any warning thresholds and emits signals."""
	
	# Warning threshold
	if current <= warning_threshold and previous > warning_threshold:
		if not warning_triggered:
			warning_triggered = true
			fuel_warning.emit()
			print("Fuel WARNING: Running low!")
	
	# Critical threshold
	if current <= critical_threshold and previous > critical_threshold:
		if not critical_triggered:
			critical_triggered = true
			fuel_critical.emit()
			print("Fuel CRITICAL: Find a booster now!")

func _handle_fuel_depleted():
	"""Called when fuel reaches zero. This is game over!"""
	
	is_empty = true
	current_fuel = 0
	
	print("FUEL DEPLETED! The boat is sinking!")
	
	# Disable boat movement
	if boat_controller and boat_controller.has_method("set_can_move"):
		boat_controller.set_can_move(false)
	
	# Notify listeners (GameManager will handle game over)
	fuel_depleted.emit()
	
	# Notify the global GameManager
	if GameManager:
		GameManager.on_player_fuel_depleted()
	
	# Start sinking animation
	_start_sinking()

func _start_sinking():
	"""Visual feedback - the boat sinks when fuel is depleted."""
	
	# Create a tween for smooth sinking animation
	var tween = create_tween()
	
	# Get the parent (the boat RigidBody3D)
	var boat = get_parent()
	if boat == null:
		boat = self
	
	# Sink down over 3 seconds
	var sink_target = boat.global_position + Vector3(0, -5, 0)
	tween.tween_property(boat, "global_position", sink_target, 3.0)
	
	# Also tilt the boat
	var tilt_target = boat.rotation_degrees + Vector3(30, 0, 15)
	tween.parallel().tween_property(boat, "rotation_degrees", tilt_target, 3.0)

# === SETUP ===

func _find_boat_controller():
	"""Finds the BoatController script on this node or its parent."""
	
	# First check if we're attached to the same node as BoatController
	if get_parent().has_method("is_moving"):
		boat_controller = get_parent()
		return
	
	# Check if it's a sibling script on the parent
	var parent = get_parent()
	for child in parent.get_children():
		if child.has_method("is_moving"):
			boat_controller = child
			return
	
	# Try to find by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for player in players:
			if player.has_method("is_moving"):
				boat_controller = player
				return
	
	push_warning("FuelSystem: Could not find BoatController!")

# === PUBLIC METHODS ===

func reset():
	"""Resets the fuel system to full. Used when restarting."""
	
	is_empty = false
	warning_triggered = false
	critical_triggered = false
	current_fuel = max_fuel
	
	# Re-enable boat movement if we have a reference
	if boat_controller and boat_controller.has_method("set_can_move"):
		boat_controller.set_can_move(true)
	
	fuel_changed.emit(get_fuel_percentage())

func set_max_fuel(new_max: float):
	"""Sets the maximum fuel capacity. Called when selecting different boat types."""
	
	max_fuel = new_max
	current_fuel = max_fuel
	fuel_changed.emit(get_fuel_percentage())

func set_consumption_rate(new_rate: float):
	"""Sets how fast fuel is consumed. Different boats may have different efficiency."""
	
	consumption_rate = new_rate
