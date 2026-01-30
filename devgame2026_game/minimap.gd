# minimap.gd
# Dot-based minimap in the top-right corner.
# Shows player (white), mice (green), cheese (yellow), fuel boosters (blue).
#
# Setup:
# 1. Instance Scenes/minimap.tscn into your main scene, OR
# 2. Add a CanvasLayer → Control and attach this script
#
# Requirements:
# - Player node must be in group "player"
# - Mice nodes must be in group "mouse"
# - Cheese nodes must be in group "cheese"
# - Fuel boosters must be in group "booster"
#
# The minimap auto-detects all objects by group — no manual wiring needed.

extends Control

# === CONFIGURATION ===
@export var map_size: float = 150.0        # Pixel size of the minimap
@export var map_range: float = 60.0        # World units visible on the minimap
@export var border_width: float = 2.0
@export var dot_radius_player: float = 5.0
@export var dot_radius_object: float = 3.0

# === COLORS ===
@export var bg_color: Color = Color(0.1, 0.1, 0.15, 0.8)
@export var border_color: Color = Color(0.5, 0.5, 0.6, 0.9)
@export var player_color: Color = Color.WHITE
@export var mouse_color: Color = Color(0.3, 0.9, 0.3)       # Green
@export var cheese_color: Color = Color(1.0, 0.85, 0.1)     # Yellow
@export var booster_color: Color = Color(0.3, 0.6, 1.0)     # Blue
@export var boundary_color: Color = Color(0.4, 0.4, 0.5, 0.5)

# === STATE ===
var player: Node3D = null

# === GODOT LIFECYCLE ===

func _ready():
	# Set size and anchor to top-right
	custom_minimum_size = Vector2(map_size, map_size)
	size = Vector2(map_size, map_size)
	anchor_left = 1.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = -map_size - 20
	offset_top = 20
	offset_right = -20
	offset_bottom = map_size + 20

	print("Minimap ready!")

func _process(_delta: float):
	# Find player if not set
	if not player or not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	# Redraw every frame
	queue_redraw()

func _draw():
	var center = Vector2(map_size / 2.0, map_size / 2.0)
	var half = map_size / 2.0

	# Background
	draw_rect(Rect2(0, 0, map_size, map_size), bg_color)

	# Border
	draw_rect(Rect2(0, 0, map_size, map_size), border_color, false, border_width)

	# Draw play area boundary
	if GameManager:
		_draw_boundary(center, half)

	if not player or not is_instance_valid(player):
		# No player — just draw empty map
		return

	# Draw objects
	_draw_group("mouse", mouse_color, center, half)
	_draw_group("cheese", cheese_color, center, half)
	_draw_group("booster", booster_color, center, half)

	# Draw player dot (always at center)
	draw_circle(center, dot_radius_player, player_color)

	# Draw player direction indicator
	_draw_player_direction(center)

# === DRAWING HELPERS ===

func _world_to_minimap(world_pos: Vector3, center: Vector2, half: float) -> Vector2:
	if not player:
		return center

	# Offset from player position
	var dx = world_pos.x - player.global_position.x
	var dz = world_pos.z - player.global_position.z

	# Scale to minimap
	var scale = half / map_range
	var map_x = center.x + dx * scale
	var map_y = center.y + dz * scale

	return Vector2(map_x, map_y)

func _is_in_bounds(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= map_size and pos.y >= 0 and pos.y <= map_size

func _draw_group(group_name: String, color: Color, center: Vector2, half: float):
	var nodes = get_tree().get_nodes_in_group(group_name)
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if not node is Node3D:
			continue

		var pos = _world_to_minimap(node.global_position, center, half)
		if _is_in_bounds(pos):
			draw_circle(pos, dot_radius_object, color)

func _draw_boundary(center: Vector2, half: float):
	if not player or not GameManager:
		return

	# Draw the spawn area boundary as a rectangle
	var min_pos = Vector3(GameManager.spawn_area_min.x, 0, GameManager.spawn_area_min.y)
	var max_pos = Vector3(GameManager.spawn_area_max.x, 0, GameManager.spawn_area_max.y)

	var tl = _world_to_minimap(min_pos, center, half)
	var br = _world_to_minimap(max_pos, center, half)

	# Clamp to minimap bounds
	tl.x = clamp(tl.x, 0, map_size)
	tl.y = clamp(tl.y, 0, map_size)
	br.x = clamp(br.x, 0, map_size)
	br.y = clamp(br.y, 0, map_size)

	var rect = Rect2(tl, br - tl)
	draw_rect(rect, boundary_color, false, 1.0)

func _draw_player_direction(center: Vector2):
	if not player:
		return

	# Get player's forward direction
	var forward = Vector2.ZERO
	if player is Node3D:
		var fwd_3d = -player.global_transform.basis.z
		forward = Vector2(fwd_3d.x, fwd_3d.z).normalized()

	if forward.length() < 0.1:
		return

	# Draw a small triangle/line showing facing direction
	var tip = center + forward * (dot_radius_player + 4)
	draw_line(center, tip, player_color, 2.0)
