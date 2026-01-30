extends Node3D
# Automatic Lighting Setup
# This script creates a complete lighting environment when the scene starts
#
# Usage:
# 1. Add a Node3D to your scene, name it "Lighting"
# 2. Attach this script
# 3. Run scene - lighting appears automatically!

# === CONFIGURATION ===

@export_group("Sun")
@export var sun_enabled: bool = true
@export var sun_color: Color = Color(1.0, 0.95, 0.8)  # Warm white
@export var sun_energy: float = 1.0
@export var sun_angle: Vector3 = Vector3(-45, 45, 0)  # Angle of sun
@export var enable_shadows: bool = true

@export_group("Sky")
@export var sky_enabled: bool = true
@export var sky_top_color: Color = Color(0.4, 0.6, 1.0)  # Light blue
@export var sky_horizon_color: Color = Color(0.7, 0.8, 1.0)  # Lighter blue

@export_group("Ambient Light")
@export var ambient_energy: float = 0.3  # How much ambient/fill light

@export_group("Fog")
@export var fog_enabled: bool = false
@export var fog_density: float = 0.01
@export var fog_color: Color = Color(0.5, 0.6, 0.7)

# === GODOT LIFECYCLE ===

func _ready():
	print("Setting up lighting...")
	
	if sun_enabled:
		_create_sun()
	
	if sky_enabled:
		_create_environment()
	
	print("Lighting setup complete!")

# === SUN ===

func _create_sun():
	"""Creates a directional light (sun)."""
	
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	add_child(sun)
	
	# Set rotation
	sun.rotation_degrees = sun_angle
	
	# Set color and brightness
	sun.light_color = sun_color
	sun.light_energy = sun_energy
	
	# Enable shadows for realism
	sun.shadow_enabled = enable_shadows
	
	if enable_shadows:
		# Improve shadow quality
		sun.shadow_blur = 1.0
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance = 100.0
	
	print("Sun created at angle: ", sun_angle)

# === ENVIRONMENT (SKY + AMBIENT) ===

func _create_environment():
	"""Creates sky and environment settings."""
	
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	add_child(world_env)
	
	# Create environment
	var environment = Environment.new()
	world_env.environment = environment
	
	# Setup sky
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	
	# Sky colors
	sky_material.sky_top_color = sky_top_color
	sky_material.sky_horizon_color = sky_horizon_color
	sky_material.ground_bottom_color = Color(0.2, 0.3, 0.2)  # Dark green
	sky_material.ground_horizon_color = Color(0.4, 0.5, 0.3)  # Light green
	
	# Sun settings
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.5
	
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	
	# Ambient light (fills in shadows)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = ambient_energy
	
	# Fog (optional atmospheric effect)
	if fog_enabled:
		environment.fog_enabled = true
		environment.fog_light_color = fog_color
		environment.fog_density = fog_density
		environment.fog_aerial_perspective = 0.5
	
	# Tone mapping (makes colors look better)
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	
	print("Environment created with sky")

# === PUBLIC METHODS ===

func set_time_of_day(time: float):
	"""
	Changes lighting based on time (0.0 = midnight, 0.5 = noon, 1.0 = midnight)
	Great for day/night cycles!
	"""
	
	var sun_node = get_node_or_null("Sun")
	if not sun_node:
		return
	
	# Calculate sun angle based on time
	# 0.0 (midnight) = 90° below horizon
	# 0.5 (noon) = 0° (straight up)
	# 1.0 (midnight) = 90° below horizon
	
	var angle = (time - 0.5) * 180.0  # -90 to +90
	sun_node.rotation_degrees.x = angle
	
	# Adjust brightness (dimmer at sunrise/sunset)
	var brightness = 1.0 - abs(time - 0.5) * 2.0
	brightness = clamp(brightness * 2.0, 0.1, 1.0)
	sun_node.light_energy = brightness
	
	# Change color (orange at sunrise/sunset)
	if time < 0.25 or time > 0.75:
		# Sunrise/sunset - orange
		sun_node.light_color = Color(1.0, 0.6, 0.3)
	else:
		# Daytime - white
		sun_node.light_color = sun_color

func toggle_shadows():
	"""Turn shadows on/off for performance."""
	
	var sun_node = get_node_or_null("Sun")
	if sun_node:
		sun_node.shadow_enabled = !sun_node.shadow_enabled
		print("Shadows: ", "ON" if sun_node.shadow_enabled else "OFF")

func set_fog(enabled: bool):
	"""Enable/disable fog."""
	
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = enabled
		print("Fog: ", "ON" if enabled else "OFF")
