# Godot Quick-Start Guide for Mouse Rescue Game

## Why Godot Will Feel Natural

If you've used Python before, GDScript will feel immediately familiar. It uses indentation for code blocks, has clean syntax, and avoids the boilerplate that other languages require. You'll be writing game logic within minutes of opening Godot.

---

## Installing Godot (2 minutes)

1. Go to [godotengine.org/download](https://godotengine.org/download)
2. Download **Godot 4.x** (standard version, NOT the .NET version)
3. On Mac: Unzip the file, drag Godot to Applications (or just run it from anywhere)
4. Double-click to open — that's it, no installation wizard!

First launch takes about 5 seconds. Compare that to Unity's multi-minute startup.

---

## The Godot Mindset: Everything is a Node

In Godot, your entire game is built from **Nodes** arranged in **Scenes**.

**Node**: A single building block with a specific purpose. There are nodes for 3D objects, physics, audio, UI, timers, and more. Nodes can have children, forming a tree structure.

**Scene**: A saved tree of nodes that you can reuse. Your boat is a scene. Each mouse is a scene. Your entire game level is a scene. Scenes can contain other scenes (like your level scene containing multiple mouse scenes).

Think of it like HTML: nodes are elements, scenes are reusable components, and the tree structure determines relationships.

```
Game (Node3D)
├── Water (MeshInstance3D)
├── Boat (RigidBody3D)          ← This is also its own saved scene
│   ├── CollisionShape3D
│   ├── MeshInstance3D
│   └── BoatController.gd       ← Script attached to Boat
├── Camera3D
├── GameManager (Node)
│   └── GameManager.gd
└── UI (CanvasLayer)
    └── HUD (Control)
```

---

## The Godot Interface

When you open Godot and create a project, you'll see:

**Scene Panel (top-left)**: Shows the node tree for your current scene. You'll spend a lot of time here adding and organizing nodes.

**FileSystem Panel (bottom-left)**: Your project's files — scripts, scenes, textures, etc. Like a file explorer.

**Viewport (center)**: The 2D or 3D editor where you visually arrange things. Toggle between 2D, 3D, Script, and AssetLib views at the top.

**Inspector (right)**: When you select a node, this shows all its properties. This is where you tweak values, assign resources, and configure behavior.

**Node Panel (right, tab next to Inspector)**: Shows signals you can connect and groups you can add.

---

## Core Concepts You Need

### Creating Nodes

To add a node to your scene:
1. Select the parent node in the Scene panel (or root if it's the first)
2. Click the **+** button (or press Ctrl+A / Cmd+A)
3. Search for the node type you want
4. Click "Create"

Common 3D nodes you'll use:
- **Node3D**: Empty node for organization or as a script holder
- **MeshInstance3D**: Displays a 3D shape (cube, sphere, or imported model)
- **RigidBody3D**: Physics-enabled object that responds to forces
- **CharacterBody3D**: For player-controlled movement with more control than RigidBody3D
- **Area3D**: Detects when things enter/exit (perfect for pickups)
- **CollisionShape3D**: Defines the physical boundary (must be child of physics nodes)
- **Camera3D**: The player's viewpoint

### Attaching Scripts

1. Select a node in the Scene panel
2. Click the scroll/paper icon (or press Ctrl+Shift+S / Cmd+Shift+S)
3. Choose a location and name
4. Click "Create"

The script automatically includes the correct `extends` line based on what node you attached it to.

### The Transform (Position, Rotation, Scale)

Every Node3D has a transform:
- **Position**: Where it is in 3D space (`position` property, or `global_position` for world coordinates)
- **Rotation**: Which way it's facing (`rotation` in radians, or `rotation_degrees` for degrees)
- **Scale**: How big it is (`scale` property)

In code:
```gdscript
position = Vector3(0, 1, 0)           # Set local position
global_position = Vector3(10, 0, 10)  # Set world position
rotation_degrees.y = 45               # Rotate 45 degrees on Y axis
```

---

## Your First GDScript Explained

```gdscript
# Every script starts with 'extends' declaring what type of node it attaches to
extends RigidBody3D

# Variables marked with @export appear in the Inspector
# You can tweak these without editing code
@export var speed := 10.0
@export var turn_speed := 2.0

# Regular variables are private to this script
var can_move := true

# _ready() runs once when the node enters the scene tree
# Similar to Start() in Unity
func _ready():
    print("Boat is ready!")

# _process(delta) runs every frame
# delta is the time since last frame (use for smooth movement)
func _process(delta):
    if Input.is_action_just_pressed("ui_accept"):  # Space or Enter
        print("Action button pressed!")

# _physics_process(delta) runs at fixed intervals (60 times/sec by default)
# Use this for physics-related code
func _physics_process(delta):
    if not can_move:
        return
    
    # Get input and apply movement
    var forward = Input.get_axis("move_backward", "move_forward")
    var movement = -transform.basis.z * forward * speed
    apply_central_force(movement)
```

Key syntax notes:
- **No semicolons** at the end of lines
- **Indentation matters** (like Python)
- **`:=` for type inference**: `var speed := 10.0` means "speed is a float"
- **`func` for functions**, no return type needed unless you want it
- **`var` for variables**, `const` for constants

---

## Input Handling

Godot uses an **Input Map** where you name actions and assign keys to them.

**Setting up inputs:**
1. Go to **Project → Project Settings → Input Map**
2. Add a new action (e.g., "move_forward")
3. Click the **+** next to it and press the key you want (W)
4. Repeat for other actions

**Default actions you can use immediately:**
- `ui_up`, `ui_down`, `ui_left`, `ui_right` (arrow keys)
- `ui_accept` (Enter/Space)
- `ui_cancel` (Escape)

**In code:**
```gdscript
# Check if action is currently held
if Input.is_action_pressed("move_forward"):
    # W is being held

# Check if action was just pressed this frame
if Input.is_action_just_pressed("jump"):
    # Space was just pressed

# Get a value between -1 and 1 based on two actions
var horizontal = Input.get_axis("move_left", "move_right")  # -1 to 1
```

---

## Signals: Godot's Event System

Signals are how nodes communicate without being tightly coupled. When something happens (collision, timer finished, button pressed), a node emits a signal. Other nodes can connect to that signal and respond.

**Connecting signals in the editor:**
1. Select a node (e.g., an Area3D)
2. Go to the **Node** panel (tab next to Inspector)
3. Double-click a signal (e.g., `body_entered`)
4. Select which node should receive it
5. Click "Connect" — Godot creates the function for you

**Connecting signals in code:**
```gdscript
func _ready():
    # Connect the "body_entered" signal to our "_on_body_entered" function
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    print("Something entered: ", body.name)
```

**Creating custom signals:**
```gdscript
# Declare a signal at the top of your script
signal fuel_changed(new_amount)
signal mouse_rescued(mouse)

# Emit the signal when something happens
func add_fuel(amount):
    current_fuel += amount
    fuel_changed.emit(current_fuel)  # Anyone listening will be notified
```

---

## Physics and Collisions

### RigidBody3D (Physics-driven objects)

Use this when you want physics to control movement (gravity, forces, collisions push it around).

```gdscript
extends RigidBody3D

func _physics_process(delta):
    # Apply a force in the forward direction
    var force = -transform.basis.z * 100
    apply_central_force(force)
    
    # Apply torque (rotational force)
    apply_torque(Vector3(0, 10, 0))
```

Important RigidBody3D settings in Inspector:
- **Mass**: Heavier objects need more force
- **Linear Damp**: Resistance to movement (higher = slows down faster)
- **Angular Damp**: Resistance to rotation
- **Gravity Scale**: 0 = no gravity (good for top-down water game)

### Area3D (Detection zones)

Use this for triggers — detecting when something enters without physical collision.

```gdscript
extends Area3D

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.is_in_group("player"):
        print("Player entered the area!")
        queue_free()  # Delete this node
```

### Collision Layers and Masks

Found in the Inspector under "Collision":
- **Layer**: What this object IS (e.g., "I am a pickup")
- **Mask**: What this object DETECTS (e.g., "I detect players")

Set these numerically or name them in Project Settings → Layer Names.

---

## Groups: Tagging Nodes

Groups are like tags. Add a node to a group to identify what it is.

**Adding to a group (Inspector):**
1. Select the node
2. Go to Node panel → Groups tab
3. Type group name and click Add

**Adding to a group (code):**
```gdscript
func _ready():
    add_to_group("enemies")
    add_to_group("damageable")
```

**Checking groups:**
```gdscript
func _on_body_entered(body):
    if body.is_in_group("player"):
        collect()
```

**Finding all nodes in a group:**
```gdscript
var all_mice = get_tree().get_nodes_in_group("mice")
for mouse in all_mice:
    print(mouse.name)
```

---

## Scenes and Instantiation (Spawning)

### Creating a Reusable Scene (Prefab equivalent)

1. Create your node tree (e.g., a Mouse with all its children)
2. Right-click the root node → "Save Branch as Scene"
3. Save it (e.g., `res://scenes/mouse.tscn`)
4. Now you can spawn copies of it!

### Spawning Scenes in Code

```gdscript
# At the top of your script, preload the scene
const MouseScene = preload("res://scenes/mouse.tscn")

func spawn_mouse():
    # Create an instance
    var mouse = MouseScene.instantiate()
    
    # Set its position
    mouse.position = Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
    
    # Add it to the scene tree (makes it appear in the game)
    add_child(mouse)
    # Or add to a specific parent:
    # get_node("SpawnContainer").add_child(mouse)
```

### Deleting Nodes

```gdscript
queue_free()  # Safely deletes this node at the end of the frame
# or
some_node.queue_free()  # Delete a specific node
```

---

## Autoloads: Global Scripts (Singletons)

For scripts that need to exist throughout your game and be accessible from anywhere (like GameManager), use Autoloads.

**Setting up an Autoload:**
1. Create your script (e.g., `game_manager.gd`)
2. Go to **Project → Project Settings → Autoload**
3. Click the folder icon, select your script
4. Give it a name (e.g., "GameManager")
5. Click "Add"

**Accessing it from any script:**
```gdscript
# No need to get_node() or find anything — just use the name directly!
GameManager.add_score(10)
GameManager.game_over()
print(GameManager.current_score)
```

This is MUCH cleaner than Unity's singleton pattern.

---

## UI Basics

UI in Godot uses **Control** nodes under a **CanvasLayer**.

**Basic setup:**
```
CanvasLayer
└── Control (anchor: Full Rect)
    ├── Label (for text)
    ├── ProgressBar (for fuel gauge)
    └── Button (for restart)
```

**Common Control nodes:**
- **Label**: Displays text
- **Button**: Clickable button (connect its `pressed` signal)
- **ProgressBar**: Shows a value from 0-100 (perfect for fuel)
- **TextureRect**: Displays an image
- **VBoxContainer/HBoxContainer**: Automatically arranges children

**Updating UI from code:**
```gdscript
@onready var score_label = $CanvasLayer/HUD/ScoreLabel
@onready var fuel_bar = $CanvasLayer/HUD/FuelBar

func update_score(value):
    score_label.text = "Score: " + str(value)

func update_fuel(percentage):
    fuel_bar.value = percentage * 100  # ProgressBar uses 0-100
```

**@onready**: Gets the node reference when `_ready()` runs. Cleaner than calling `get_node()` in `_ready()`.

---

## Common Patterns

### Timer

```gdscript
# Create a timer in code
var spawn_timer = Timer.new()

func _ready():
    spawn_timer.wait_time = 3.0
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    add_child(spawn_timer)
    spawn_timer.start()

func _on_spawn_timer_timeout():
    spawn_mouse()
```

Or add a Timer node in the editor and connect its `timeout` signal.

### Changing Scenes

```gdscript
# Reload current scene (restart)
get_tree().reload_current_scene()

# Change to a different scene
get_tree().change_scene_to_file("res://scenes/game_over.tscn")
```

### Pausing

```gdscript
get_tree().paused = true   # Pause everything
get_tree().paused = false  # Unpause

# To make a node ignore pause (like pause menu UI):
# Set its Process Mode to "Always" in Inspector
```

---

## Debugging Tips

**Print statements:**
```gdscript
print("Current fuel: ", fuel)
print("Mouse position: ", mouse.global_position)
```

**Breakpoints:** Click the left margin in the script editor to add a breakpoint. The game will pause there and let you inspect variables.

**Remote tab:** While the game is running, the Scene panel shows a "Remote" tab. Click it to see the actual running scene tree and inspect live values.

---

## Your First Hour Checklist

1. [ ] Download Godot 4.x from godotengine.org
2. [ ] Open Godot, click "New Project", name it "MouseRescue", choose a folder, click "Create & Edit"
3. [ ] In the FileSystem panel, create folders: `scenes`, `scripts`
4. [ ] Create the water: Scene panel → "3D Scene" (creates a Node3D root) → rename to "Game"
5. [ ] Add child: Ctrl+A → search "MeshInstance3D" → Create
6. [ ] In Inspector, click Mesh → New PlaneMesh → set size to 100x100
7. [ ] Create a material: Surface Material Override → New StandardMaterial3D → Albedo Color → blue
8. [ ] Add the boat: Ctrl+A → RigidBody3D → rename to "Boat"
9. [ ] Add child to Boat: MeshInstance3D → Mesh → New BoxMesh
10. [ ] Add child to Boat: CollisionShape3D → Shape → New BoxShape3D
11. [ ] Select Boat, add script: Click scroll icon → save as `boat_controller.gd`
12. [ ] Copy the BoatController code from the scripts I provided
13. [ ] Add Camera3D to the scene, position it above and behind the boat
14. [ ] Press F5 (or Play button) to run — choose your current scene as main
15. [ ] Use WASD to move! (After setting up input actions)

**Setting up input actions:**
1. Project → Project Settings → Input Map
2. Add: `move_forward` (W), `move_backward` (S), `move_left` (A), `move_right` (D)
3. Add: `interact` (E or Space)

You now have a moving boat. Everything else builds on this foundation.
