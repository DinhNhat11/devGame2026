# scoreboard.gd
# Displays cheese count and session timer in the top-left corner.
#
# Setup:
# 1. Add a CanvasLayer to your main scene
# 2. Add a Control node as child, attach this script
# 3. The script auto-creates the UI labels — no manual setup needed
#
# Integration:
#   The scoreboard listens to GameManager signals automatically.
#   Make sure GameManager is registered as an Autoload (Globals).

extends Control

# === UI ELEMENTS (auto-created) ===
var cheese_label: Label
var timer_label: Label
var container: VBoxContainer

# === CONFIGURATION ===
@export var font_size: int = 24
@export var timer_warning_seconds: float = 30.0
@export var timer_critical_seconds: float = 10.0

# === COLORS ===
var color_normal: Color = Color.WHITE
var color_warning: Color = Color.YELLOW
var color_critical: Color = Color.RED

# === GODOT LIFECYCLE ===

func _ready():
	_build_ui()
	_connect_signals()
	_initialize_values()
	print("Scoreboard ready!")

func _process(_delta: float):
	_update_timer_flash()

# === UI CONSTRUCTION ===

func _build_ui():
	# Anchor to top-left
	anchor_left = 0
	anchor_top = 0
	anchor_right = 0
	anchor_bottom = 0
	offset_left = 20
	offset_top = 20

	# Container for vertical layout
	container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	add_child(container)

	# Cheese count
	cheese_label = Label.new()
	cheese_label.text = "Cheese: 0"
	cheese_label.add_theme_font_size_override("font_size", font_size)
	cheese_label.add_theme_color_override("font_color", color_normal)
	container.add_child(cheese_label)

	# Session timer
	timer_label = Label.new()
	timer_label.text = "Time: 5:00"
	timer_label.add_theme_font_size_override("font_size", font_size)
	timer_label.add_theme_color_override("font_color", color_normal)
	container.add_child(timer_label)

# === SIGNALS ===

func _connect_signals():
	if not GameManager:
		push_warning("Scoreboard: GameManager not found!")
		return

	GameManager.time_updated.connect(_on_time_updated)
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# cheese_collected is tracked via score_changed — we read cheese_collected directly
	GameManager.score_changed.connect(_on_score_changed)

func _initialize_values():
	if GameManager:
		cheese_label.text = "Cheese: " + str(GameManager.cheese_collected)
		_on_time_updated(GameManager.time_remaining)

# === UPDATE HANDLERS ===

func _on_score_changed(_new_score: int):
	if GameManager:
		cheese_label.text = "Cheese: " + str(GameManager.cheese_collected)

func _on_time_updated(time_remaining: float):
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "Time: %d:%02d" % [minutes, seconds]

	# Color based on remaining time
	if time_remaining <= timer_critical_seconds:
		timer_label.add_theme_color_override("font_color", color_critical)
	elif time_remaining <= timer_warning_seconds:
		timer_label.add_theme_color_override("font_color", color_warning)
	else:
		timer_label.add_theme_color_override("font_color", color_normal)

func _update_timer_flash():
	if not GameManager:
		return
	if GameManager.time_remaining <= timer_critical_seconds and GameManager.current_state == GameManager.GameState.PLAYING:
		var flash = abs(sin(Time.get_ticks_msec() * 0.005))
		timer_label.modulate = color_critical.lerp(Color.WHITE, flash * 0.5)
	else:
		timer_label.modulate = Color.WHITE

func _on_game_state_changed(new_state):
	match new_state:
		GameManager.GameState.MENU:
			visible = false
		GameManager.GameState.PLAYING:
			visible = true
			cheese_label.text = "Cheese: 0"
		GameManager.GameState.GAME_OVER:
			visible = true
