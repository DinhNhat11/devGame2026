# game_over_ui.gd
# Displays the game over screen with final stats and options to restart or quit.
# This panel is hidden during gameplay and appears when the game ends.
#
# Setup:
# 1. Create a new scene with CanvasLayer as root (or add to existing CanvasLayer)
# 2. Add a Control node sized to cover the full screen
# 3. Add a ColorRect or Panel as background (semi-transparent black)
# 4. Add Labels for: title, reason, score, mice rescued
# 5. Add Buttons for: restart, quit
# 6. Attach this script to the root Control
# 7. Assign UI references in Inspector
# 8. Set the root Control to start HIDDEN (visible = false)
#
# Scene structure:
# CanvasLayer
# └── GameOverUI (Control - Full Rect anchor) ← This script
#     ├── Background (ColorRect - full screen, black with ~0.8 alpha)
#     ├── CenterContainer (to center the content)
#     │   └── VBoxContainer (vertical layout)
#     │       ├── TitleLabel
#     │       ├── ReasonLabel
#     │       ├── ScoreLabel
#     │       ├── MiceLabel
#     │       ├── RestartButton
#     │       └── QuitButton
#
# The panel will be shown automatically when GameManager emits game_over signal.

extends Control

# === UI ELEMENT REFERENCES ===

@export_group("Labels")
@export var title_label: Label
@export var reason_label: Label
@export var final_score_label: Label
@export var mice_rescued_label: Label
@export var mice_drowned_label: Label

@export_group("Buttons")
@export var restart_button: Button
@export var quit_button: Button

@export_group("Animation")
@export var fade_in_duration: float = 0.5

# === GODOT LIFECYCLE ===

func _ready():
	# Make sure we start hidden
	visible = false
	
	# Set process mode to always so we work even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect to GameManager's game_over signal
	if GameManager:
		GameManager.game_over.connect(_on_game_over)
	else:
		push_warning("GameOverUI: GameManager not found!")
	
	# Connect button signals
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	print("GameOverUI ready (hidden until game over)")

# === DISPLAY METHODS ===

func _on_game_over(reason: String):
	"""Called when the game ends. Shows the game over screen."""
	
	print("Showing game over screen: ", reason)
	
	# Update the display text with final stats
	_update_display(reason)
	
	# Show the panel with a fade-in animation
	_show_with_animation()
	
	# Pause the game
	get_tree().paused = true

func _update_display(reason: String):
	"""Updates all the text elements with final game stats."""
	
	# Set the title based on reason
	if title_label:
		if reason == "Time's Up!":
			title_label.text = "TIME'S UP!"
			title_label.modulate = Color.YELLOW
		elif reason == "Out of Fuel!":
			title_label.text = "OUT OF FUEL!"
			title_label.modulate = Color.RED
		else:
			title_label.text = "GAME OVER"
			title_label.modulate = Color.WHITE
	
	# Set the reason
	if reason_label:
		reason_label.text = reason
	
	# Get stats from GameManager
	if GameManager:
		if final_score_label:
			final_score_label.text = "Final Score: " + str(GameManager.current_score)
		
		if mice_rescued_label:
			mice_rescued_label.text = "Mice Rescued: " + str(GameManager.mice_rescued)
		
		if mice_drowned_label:
			mice_drowned_label.text = "Mice Drowned: " + str(GameManager.mice_drowned)

func _show_with_animation():
	"""Fades in the game over screen."""
	
	# Start fully transparent
	modulate = Color(1, 1, 1, 0)
	visible = true
	
	# Animate to fully visible
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), fade_in_duration)
	
	# Once visible, give focus to restart button for keyboard navigation
	tween.tween_callback(func(): 
		if restart_button:
			restart_button.grab_focus()
	)

func hide_screen():
	"""Hides the game over screen."""
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): visible = false)

# === BUTTON HANDLERS ===

func _on_restart_pressed():
	"""Called when the Restart button is clicked."""
	
	print("Restart pressed")
	
	# Unpause the game
	get_tree().paused = false
	
	# Tell GameManager to restart
	if GameManager:
		GameManager.restart_game()
	else:
		# Fallback: just reload the scene directly
		get_tree().reload_current_scene()

func _on_quit_pressed():
	"""Called when the Quit button is clicked."""
	
	print("Quit pressed")
	
	# Unpause before quitting (good practice)
	get_tree().paused = false
	
	# Quit the game
	if GameManager:
		GameManager.quit_game()
	else:
		get_tree().quit()

# === UTILITY ===

func _input(event: InputEvent):
	"""Handle keyboard shortcuts when game over screen is visible."""
	
	if not visible:
		return
	
	# Press R to restart
	if event.is_action_pressed("ui_accept") and restart_button and restart_button.has_focus():
		_on_restart_pressed()
	
	# Press Escape to quit (optional)
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
