# hud_controller.gd
# Manages all the HUD (Heads-Up Display) elements during gameplay.
# This script connects to signals from game systems and updates the UI accordingly.
#
# Setup:
# 1. Create a CanvasLayer node (HUD renders on top of 3D scene)
# 2. Add a Control node as child (container for UI elements)
# 3. Add child UI elements: Labels for score/timer/mice, ProgressBar for fuel
# 4. Attach this script to the Control node (or the CanvasLayer)
# 5. Assign the UI element references in the Inspector
#
# Recommended scene structure:
# CanvasLayer
# └── HUD (Control) ← This script goes here
#     ├── ScoreLabel (Label) - anchored top-right
#     ├── MiceRescuedLabel (Label) - below score
#     ├── TimerLabel (Label) - anchored top-center
#     ├── CapacityLabel (Label) - anchored bottom-left
#     └── FuelBar (ProgressBar) - anchored bottom-left or bottom-center
#
# To anchor UI elements:
# Select the node → In Inspector, find Layout → Anchor Preset → Choose position

extends Control

# === UI ELEMENT REFERENCES ===
# Assign these in the Inspector by dragging the UI nodes

@export_group("Display Elements")
@export var score_label: Label
@export var timer_label: Label
@export var mice_rescued_label: Label
@export var capacity_label: Label
@export var fuel_bar: ProgressBar

@export_group("Colors")
@export var fuel_normal_color: Color = Color(0.2, 0.8, 0.2)     # Green
@export var fuel_warning_color: Color = Color(0.9, 0.9, 0.2)    # Yellow
@export var fuel_critical_color: Color = Color(0.9, 0.2, 0.2)   # Red
@export var timer_warning_color: Color = Color(0.9, 0.2, 0.2)   # Red

# === STATE ===

var timer_normal_color: Color
var boat_rescue_system: Node = null
var fuel_system: Node = null

# === GODOT LIFECYCLE ===

func _ready():
	# Store the original timer color for resetting
	if timer_label:
		timer_normal_color = timer_label.modulate
	
	# Connect to GameManager signals
	_connect_to_game_manager()
	
	# Find and connect to player systems
	# We need to wait a frame for everything to be ready
	call_deferred("_find_player_systems")
	
	# Initialize displays with default values
	_initialize_displays()
	
	print("HUD Controller ready!")

func _process(_delta: float):
	# Flash the timer when time is low
	_update_timer_flash()

func _exit_tree():
	# Disconnect signals when this node is removed
	_disconnect_signals()

# === SETUP ===

func _connect_to_game_manager():
	"""Connects to signals from the global GameManager autoload."""
	
	if not GameManager:
		push_warning("HUDController: GameManager not found!")
		return
	
	# Connect to GameManager signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.mice_rescued_changed.connect(_on_mice_rescued_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)

func _find_player_systems():
	"""Finds the player's boat and connects to its signals."""
	
	# Find the player's boat
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		push_warning("HUDController: No player found!")
		return
	
	var player = players[0]
	
	# Find FuelSystem
	# It might be the player node itself or a child
	if player.has_signal("fuel_changed"):
		fuel_system = player
	else:
		for child in player.get_children():
			if child.has_signal("fuel_changed"):
				fuel_system = child
				break
	
	if fuel_system:
		fuel_system.fuel_changed.connect(_on_fuel_changed)
		# Get initial fuel value
		if fuel_system.has_method("get_fuel_percentage"):
			_on_fuel_changed(fuel_system.get_fuel_percentage())
	
	# Find BoatRescueSystem
	for child in player.get_children():
		if child.has_signal("capacity_changed"):
			boat_rescue_system = child
			boat_rescue_system.capacity_changed.connect(_on_capacity_changed)
			# Get initial capacity
			if boat_rescue_system.has_method("get_current_count"):
				var current = boat_rescue_system.get_current_count()
				var maximum = boat_rescue_system.max_capacity
				_on_capacity_changed(current, maximum)
			break

func _initialize_displays():
	"""Sets all displays to initial values."""
	
	_on_score_changed(0)
	_on_mice_rescued_changed(0)
	_on_fuel_changed(1.0)  # Start with full fuel
	
	if GameManager:
		_on_time_updated(GameManager.time_remaining)
		_on_capacity_changed(0, 4)  # Default capacity

func _disconnect_signals():
	"""Disconnects all signal connections."""
	
	if GameManager:
		if GameManager.score_changed.is_connected(_on_score_changed):
			GameManager.score_changed.disconnect(_on_score_changed)
		if GameManager.time_updated.is_connected(_on_time_updated):
			GameManager.time_updated.disconnect(_on_time_updated)
		if GameManager.mice_rescued_changed.is_connected(_on_mice_rescued_changed):
			GameManager.mice_rescued_changed.disconnect(_on_mice_rescued_changed)
		if GameManager.game_state_changed.is_connected(_on_game_state_changed):
			GameManager.game_state_changed.disconnect(_on_game_state_changed)
	
	if fuel_system and fuel_system.fuel_changed.is_connected(_on_fuel_changed):
		fuel_system.fuel_changed.disconnect(_on_fuel_changed)
	
	if boat_rescue_system and boat_rescue_system.capacity_changed.is_connected(_on_capacity_changed):
		boat_rescue_system.capacity_changed.disconnect(_on_capacity_changed)

# === UI UPDATE METHODS ===

func _on_score_changed(new_score: int):
	"""Updates the score display."""
	if score_label:
		score_label.text = "Score: " + str(new_score)

func _on_time_updated(time_remaining: float):
	"""Updates the timer display."""
	if timer_label == null:
		return
	
	# Format as MM:SS
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
	
	# Change color when time is low (last 30 seconds)
	if time_remaining <= 30:
		timer_label.modulate = timer_warning_color
	else:
		timer_label.modulate = timer_normal_color

func _update_timer_flash():
	"""Makes the timer flash when time is very low."""
	if timer_label == null:
		return
	
	if GameManager and GameManager.time_remaining <= 10:
		# Flash every half second
		var flash = abs(sin(Time.get_ticks_msec() * 0.005))
		timer_label.modulate = timer_warning_color.lerp(Color.WHITE, flash * 0.5)

func _on_fuel_changed(percentage: float):
	"""Updates the fuel gauge."""
	if fuel_bar == null:
		return
	
	# ProgressBar uses 0-100 by default
	fuel_bar.value = percentage * 100
	
	# Get or create a StyleBoxFlat for the fill
	# Change the fill color based on fuel level
	var fill_style = fuel_bar.get_theme_stylebox("fill")
	
	if fill_style is StyleBoxFlat:
		if percentage <= 0.15:
			fill_style.bg_color = fuel_critical_color
		elif percentage <= 0.30:
			fill_style.bg_color = fuel_warning_color
		else:
			fill_style.bg_color = fuel_normal_color

func _on_capacity_changed(current: int, maximum: int):
	"""Updates the boat capacity display."""
	if capacity_label:
		capacity_label.text = "On Board: %d/%d" % [current, maximum]
		
		# Highlight when full
		if current >= maximum:
			capacity_label.modulate = fuel_warning_color
		else:
			capacity_label.modulate = Color.WHITE

func _on_mice_rescued_changed(count: int):
	"""Updates the total mice rescued display."""
	if mice_rescued_label:
		mice_rescued_label.text = "Mice Saved: " + str(count)

func _on_game_state_changed(new_state):
	"""Responds to game state changes."""
	# You could hide/show the HUD based on state
	match new_state:
		GameManager.GameState.MENU:
			visible = false
		GameManager.GameState.PLAYING:
			visible = true
		GameManager.GameState.GAME_OVER:
			# Keep HUD visible during game over, or hide it
			pass
