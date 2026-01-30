# game_manager.gd
# This is an AUTOLOAD script - it runs globally and is accessible from any script.
# Set it up: Project → Project Settings → Autoload → Add this script as "GameManager"
#
# The GameManager orchestrates the entire game:
# - Tracks game state (menu, playing, game over)
# - Manages the countdown timer
# - Handles spawning of entities
# - Tracks score and statistics
# - Determines win/lose conditions
#
# Any script can access it via: GameManager.some_function() or GameManager.some_variable

extends Node

# === ENUMS ===
# Enums define a fixed set of possible values, making code more readable

enum GameState { MENU, PLAYING, GAME_OVER }

# === SIGNALS ===
# Signals allow other nodes to react to changes without tight coupling.
# The UI will connect to these to update displays.

signal game_state_changed(new_state: GameState)
signal score_changed(new_score: int)
signal time_updated(time_remaining: float)
signal mice_rescued_changed(count: int)
signal game_over(reason: String)

# === CONFIGURATION ===
# @export makes these editable in the Inspector (when this isn't an autoload)
# For autoloads, you'll set these in code or use the default values

@export var game_duration: float = 300.0  # 5 minutes in seconds
@export var mouse_spawn_interval: float = 3.0
@export var cheese_spawn_interval: float = 5.0
@export var booster_spawn_interval: float = 15.0
@export var points_per_mouse: int = 10
@export var points_per_cheese: int = 5

# Spawn area bounds (adjust based on your water size)
@export var spawn_area_min: Vector2 = Vector2(-40, -40)
@export var spawn_area_max: Vector2 = Vector2(40, 40)
@export var spawn_height: float = 0.5

# === SCENE REFERENCES ===
# Preload scenes so we can instantiate them. Update these paths to match your project.
# The 'preload' function loads the resource at compile time, making spawning faster.

var mouse_scene: PackedScene = null
var cheese_scene: PackedScene = null
var booster_scene: PackedScene = null

# === GAME STATE ===

var current_state: GameState = GameState.MENU
var time_remaining: float = 0.0
var current_score: int = 0
var mice_rescued: int = 0
var mice_drowned: int = 0
var cheese_collected: int = 0

# Timers for spawning (we'll create these in code)
var mouse_spawn_timer: Timer
var cheese_spawn_timer: Timer
var booster_spawn_timer: Timer

# Reference to the main game scene (set when game starts)
var game_scene: Node = null

# === COMPUTED PROPERTIES ===
# GDScript doesn't have C#-style properties, but we can use functions

func get_time_formatted() -> String:
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	return "%d:%02d" % [minutes, seconds]

# === GODOT LIFECYCLE ===

func _ready():
	# Since this is an autoload, _ready runs when the game starts.
	# We set up timers here but don't start them until start_game() is called.
	
	_create_spawn_timers()
	_load_scenes()
	
	print("GameManager initialized!")

func _process(delta: float):
	# Only process during gameplay
	if current_state != GameState.PLAYING:
		return
	
	# Update countdown timer
	time_remaining -= delta
	time_updated.emit(time_remaining)
	
	# Check for time running out
	if time_remaining <= 0:
		time_remaining = 0
		end_game("Time's Up!")

# === SETUP METHODS ===

func _create_spawn_timers():
	# Create timer nodes and add them as children of the GameManager
	# Timers must be in the scene tree to work
	
	mouse_spawn_timer = Timer.new()
	mouse_spawn_timer.wait_time = mouse_spawn_interval
	mouse_spawn_timer.timeout.connect(_on_mouse_spawn_timer)
	add_child(mouse_spawn_timer)
	
	cheese_spawn_timer = Timer.new()
	cheese_spawn_timer.wait_time = cheese_spawn_interval
	cheese_spawn_timer.timeout.connect(_on_cheese_spawn_timer)
	add_child(cheese_spawn_timer)
	
	booster_spawn_timer = Timer.new()
	booster_spawn_timer.wait_time = booster_spawn_interval
	booster_spawn_timer.timeout.connect(_on_booster_spawn_timer)
	add_child(booster_spawn_timer)

func _load_scenes():
	# Attempt to load the scenes. These paths must match your project structure.
	# If the files don't exist yet, that's okay - we'll check before spawning.
	
	if ResourceLoader.exists("res://scenes/mouse.tscn"):
		mouse_scene = load("res://scenes/mouse.tscn")
	else:
		push_warning("Mouse scene not found at res://scenes/mouse.tscn")
	
	if ResourceLoader.exists("res://scenes/cheese.tscn"):
		cheese_scene = load("res://scenes/cheese.tscn")
	else:
		push_warning("Cheese scene not found at res://scenes/cheese.tscn")
	
	if ResourceLoader.exists("res://scenes/fuel_booster.tscn"):
		booster_scene = load("res://scenes/fuel_booster.tscn")
	else:
		push_warning("Booster scene not found at res://scenes/fuel_booster.tscn")

# === GAME FLOW METHODS ===

func start_game():
	"""Call this to begin gameplay. Resets all stats and starts timers."""
	
	print("Starting game!")
	
	# Reset all stats
	current_state = GameState.PLAYING
	time_remaining = game_duration
	current_score = 0
	mice_rescued = 0
	mice_drowned = 0
	cheese_collected = 0
	
	# Get reference to the current scene for spawning entities
	game_scene = get_tree().current_scene
	
	# Notify listeners
	game_state_changed.emit(current_state)
	score_changed.emit(current_score)
	mice_rescued_changed.emit(mice_rescued)
	time_updated.emit(time_remaining)
	
	# Start spawn timers
	mouse_spawn_timer.start()
	cheese_spawn_timer.start()
	booster_spawn_timer.start()
	
	# Spawn a few entities immediately so the game doesn't feel empty
	_spawn_mouse()
	_spawn_mouse()
	_spawn_cheese()

func end_game(reason: String):
	"""Called when the game should end, either from time or fuel depletion."""
	
	# Prevent double-ending
	if current_state == GameState.GAME_OVER:
		return
	
	print("Game Over: ", reason)
	print("Final Score: ", current_score)
	print("Mice Rescued: ", mice_rescued)
	print("Mice Drowned: ", mice_drowned)
	
	current_state = GameState.GAME_OVER
	
	# Stop all spawn timers
	mouse_spawn_timer.stop()
	cheese_spawn_timer.stop()
	booster_spawn_timer.stop()
	
	# Notify listeners (UI will show game over screen)
	game_state_changed.emit(current_state)
	game_over.emit(reason)

func restart_game():
	"""Restarts by reloading the current scene."""
	
	print("Restarting game...")
	
	# Make sure game is unpaused
	get_tree().paused = false
	
	# Reload the scene - this resets everything
	get_tree().reload_current_scene()
	
	# Note: After reload, you may need to call start_game() again
	# depending on how your main scene is set up.
	# One approach: have your main scene call GameManager.start_game() in its _ready()

func quit_game():
	"""Exits the application."""
	
	print("Quitting game...")
	get_tree().quit()

# === SCORING METHODS ===

func add_score(points: int):
	"""Adds points to the current score."""
	
	current_score += points
	score_changed.emit(current_score)

func on_mouse_rescued(mouse: Node):
	"""Called when a mouse is successfully rescued by the player."""
	
	mice_rescued += 1
	add_score(points_per_mouse)
	mice_rescued_changed.emit(mice_rescued)
	
	print("Mouse rescued! Total: ", mice_rescued)

func on_mouse_drowned(mouse: Node):
	"""Called when a mouse drowns (timer ran out)."""
	
	mice_drowned += 1
	print("Mouse drowned! Total drowned: ", mice_drowned)

func on_cheese_collected(points: int):
	"""Called when the player collects cheese."""
	
	cheese_collected += 1
	add_score(points)
	print("Cheese collected! Total: ", cheese_collected)

func on_player_fuel_depleted():
	"""Called by the fuel system when the player runs out of fuel."""
	
	end_game("Out of Fuel!")

# === SPAWNING METHODS ===

func _on_mouse_spawn_timer():
	_spawn_mouse()

func _on_cheese_spawn_timer():
	_spawn_cheese()

func _on_booster_spawn_timer():
	_spawn_booster()

func _spawn_mouse():
	"""Spawns a mouse at a random position in the play area."""
	
	if current_state != GameState.PLAYING:
		return
	
	if mouse_scene == null:
		push_warning("Cannot spawn mouse - scene not loaded")
		return
	
	if game_scene == null:
		push_warning("Cannot spawn mouse - no game scene reference")
		return
	
	var spawn_pos = _get_random_spawn_position()
	var mouse = mouse_scene.instantiate()
	mouse.position = spawn_pos
	
	# Connect to mouse signals so we know when it's rescued or drowns
	if mouse.has_signal("rescued"):
		mouse.rescued.connect(on_mouse_rescued)
	if mouse.has_signal("drowned"):
		mouse.drowned.connect(on_mouse_drowned)
	
	# Add to the game scene
	game_scene.add_child(mouse)

func _spawn_cheese():
	"""Spawns cheese at a random position."""
	
	if current_state != GameState.PLAYING:
		return
	
	if cheese_scene == null:
		return
	
	if game_scene == null:
		return
	
	var spawn_pos = _get_random_spawn_position()
	var cheese = cheese_scene.instantiate()
	cheese.position = spawn_pos
	
	game_scene.add_child(cheese)

func _spawn_booster():
	"""Spawns a fuel booster at a random position."""
	
	if current_state != GameState.PLAYING:
		return
	
	if booster_scene == null:
		return
	
	if game_scene == null:
		return
	
	var spawn_pos = _get_random_spawn_position()
	var booster = booster_scene.instantiate()
	booster.position = spawn_pos
	
	game_scene.add_child(booster)

func _get_random_spawn_position() -> Vector3:
	"""Returns a random position within the spawn area bounds."""
	
	var x = randf_range(spawn_area_min.x, spawn_area_max.x)
	var z = randf_range(spawn_area_min.y, spawn_area_max.y)
	
	return Vector3(x, spawn_height, z)
