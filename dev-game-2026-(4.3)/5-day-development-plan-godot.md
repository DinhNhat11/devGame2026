# Mouse Rescue Game - 5-Day Development Plan (Godot Edition)

## Scope Definition (READ THIS FIRST)

### What We're Building (MVP)
A single-player mouse rescue game where you control a boat, save drowning mice, collect cheese for points, and manage your fuel. The game has a 5-minute timer and tracks your final score.

### What We're NOT Building (Yet)
- Online multiplayer (requires significant networking knowledge)
- First-person camera (adds complexity, third-person is enough)
- Multiple teams competing (single-player focus)
- Team defeat conditions (no teams = no team logic)

These can all be added AFTER your deadline once you understand Godot better.

---

## Why Godot Will Save You Time

Compared to Unity, Godot offers several advantages for a 5-day sprint:

**Faster iteration**: Godot opens in seconds, not minutes. Scene changes are instant. This matters when you're testing constantly.

**Simpler syntax**: GDScript is Python-like. No semicolons, no type ceremony, no boilerplate. You write less code to achieve the same result.

**Built-in Autoloads**: Creating a global GameManager is trivial — just add it to Project Settings. No singleton pattern boilerplate.

**Signals over events**: Godot's signal system is cleaner than C# delegates/events. Connection is visual or one line of code.

**Scene-based prefabs**: Saving any node tree as a scene is intuitive. Instantiating it is straightforward.

---

## Daily Schedule Overview

| Day | Focus | Hours | Outcome |
|-----|-------|-------|---------|
| 1 | Setup + Learning + Basic Boat | 8-10h | Moving boat on water |
| 2 | Mice + Drowning + Pickups | 8-10h | Core gameplay loop works |
| 3 | Fuel System + Boosters + Game Flow | 8-10h | Full single game session |
| 4 | UI + Polish + Boat Selection | 8-10h | Playable game with feedback |
| 5 | Testing + Fixes + Build | 6-8h | Shippable build |

---

## Project Structure

Create this folder structure in your Godot project:

```
MouseRescue/
├── scenes/
│   ├── game.tscn              (main game scene)
│   ├── boat.tscn              (player boat)
│   ├── mouse.tscn             (drowning mouse)
│   ├── cheese.tscn            (cheese pickup)
│   ├── fuel_booster.tscn      (fuel pickup)
│   └── ui/
│       ├── hud.tscn           (in-game UI)
│       └── game_over.tscn     (end screen)
├── scripts/
│   ├── boat_controller.gd
│   ├── fuel_system.gd
│   ├── boat_rescue_system.gd
│   ├── mouse_controller.gd
│   ├── cheese_pickup.gd
│   ├── fuel_booster.gd
│   ├── camera_follow.gd
│   ├── hud_controller.gd
│   └── game_over_ui.gd
├── autoloads/
│   └── game_manager.gd        (global singleton)
└── resources/
    └── (materials, etc.)
```

---

## GitHub Issues to Create

Copy each of these into your GitHub repository as issues.

---

### MILESTONE 1: Project Foundation (Day 1)

#### Issue #1: Project Setup
**Labels:** `setup`, `priority-critical`

**Description:**
- [ ] Download and open Godot 4.x
- [ ] Create new project named "MouseRescue"
- [ ] Create folder structure: scenes/, scripts/, autoloads/, resources/
- [ ] Set up version control (git init, .gitignore for Godot)
- [ ] Save the initial empty project
- [ ] First commit: "Initial project setup"

**Godot .gitignore:**
```
# Godot 4+ specific ignores
.godot/

# Godot-specific ignores
*.translation

# Imported textures and samples
.import/

# Build
export/
*.exe
*.dmg
```

**Acceptance Criteria:** Project opens in Godot with organized folders.

---

#### Issue #2: Configure Input Actions
**Labels:** `setup`, `priority-critical`

**Description:**
- [ ] Open Project → Project Settings → Input Map
- [ ] Add action: `move_forward` → W key
- [ ] Add action: `move_backward` → S key
- [ ] Add action: `move_left` → A key
- [ ] Add action: `move_right` → D key
- [ ] Add action: `interact` → E key and Space key
- [ ] Save project settings

**Acceptance Criteria:** Input actions are defined and usable in code.

---

#### Issue #3: Create Water Surface
**Labels:** `environment`, `day-1`

**Description:**
- [ ] Create a new 3D scene, save as `game.tscn`
- [ ] Add MeshInstance3D child, name it "Water"
- [ ] Set Mesh to PlaneMesh, size 100x100
- [ ] Create blue StandardMaterial3D for water
- [ ] Position at Y=0

**Optional enhancements:**
- [ ] Add subtle animation with a shader (can skip for MVP)

**Acceptance Criteria:** Large blue flat surface representing the ocean.

---

#### Issue #4: Basic Boat Scene and Controller
**Labels:** `player`, `core`, `priority-critical`

**Description:**

Create `boat.tscn`:
- [ ] Root node: RigidBody3D named "Boat"
- [ ] Child: MeshInstance3D with BoxMesh (temporary boat shape)
- [ ] Child: CollisionShape3D with BoxShape3D
- [ ] Set Boat's Gravity Scale to 0 (we're on water, not falling)
- [ ] Set Linear Damp to 2.0, Angular Damp to 3.0 (water resistance)
- [ ] Freeze rotation on X and Z axes (boat stays upright)
- [ ] Add to group: "player"

Create `boat_controller.gd`:
- [ ] WASD movement using forces
- [ ] Rotation (turning) with A/D
- [ ] Configurable speed via @export
- [ ] Ability to disable movement (for when fuel runs out)

**Acceptance Criteria:** Boat moves on water with boat-like physics.

---

#### Issue #5: Third-Person Camera
**Labels:** `camera`, `day-1`

**Description:**

Create `camera_follow.gd`:
- [ ] Attach to Camera3D in the game scene
- [ ] Follow the boat from behind and above
- [ ] Smooth following using lerp
- [ ] Configurable offset and smoothness
- [ ] Export variable to assign target

**Setup:**
- [ ] Add Camera3D to game.tscn
- [ ] Position behind/above where boat will be
- [ ] Attach camera_follow.gd
- [ ] Set target reference to boat

**Acceptance Criteria:** Camera smoothly follows boat around the play area.

---

#### Issue #6: Play Area Boundaries
**Labels:** `environment`, `day-1`

**Description:**
- [ ] Create 4 StaticBody3D walls around the play area (or one Area3D for detection)
- [ ] Position to form a ~80x80 boundary
- [ ] Add CollisionShape3D to each (BoxShape3D)
- [ ] Boat collides and cannot escape

**Alternative approach:**
- [ ] In boat_controller.gd, clamp position to bounds each frame

**Acceptance Criteria:** Boat cannot escape the play area.

---

### MILESTONE 2: Core Entities (Day 2)

#### Issue #7: Mouse Scene with Drowning Timer
**Labels:** `entities`, `core`, `priority-critical`

**Description:**

Create `mouse.tscn`:
- [ ] Root node: Area3D named "Mouse" (for detection)
- [ ] Child: MeshInstance3D with SphereMesh (temporary mouse shape)
- [ ] Child: CollisionShape3D with SphereShape3D
- [ ] Add to group: "mouse"

Create `mouse_controller.gd`:
- [ ] Configurable drowning timer (default 10 seconds)
- [ ] Visual feedback: color changes green → yellow → red
- [ ] Bobbing animation in water
- [ ] Gets more frantic as time runs out
- [ ] Emits signal when rescued
- [ ] Emits signal when drowned
- [ ] Deletes itself when drowned (with animation)

**Acceptance Criteria:** Mouse bobs in water, changes color, eventually drowns.

---

#### Issue #8: Mouse Rescue Mechanic
**Labels:** `gameplay`, `core`, `priority-critical`

**Description:**

Create `boat_rescue_system.gd`:
- [ ] Attach to boat
- [ ] Use Area3D child on boat for detection
- [ ] When overlapping a mouse: rescue it
- [ ] Track rescued mice count
- [ ] Configurable capacity (max mice boat can hold)
- [ ] Mice visually attach to boat when rescued
- [ ] Emit signal when mouse rescued (for scoring)

**Acceptance Criteria:** Boat collects mice by touching them, mice ride on boat.

---

#### Issue #9: Cheese Pickup
**Labels:** `entities`, `day-2`

**Description:**

Create `cheese.tscn`:
- [ ] Root node: Area3D named "Cheese"
- [ ] Child: MeshInstance3D (yellow cylinder or wedge shape)
- [ ] Child: CollisionShape3D
- [ ] Add to group: "cheese"

Create `cheese_pickup.gd`:
- [ ] Float and rotate animation
- [ ] Configurable point value (default 5)
- [ ] Emit collected signal
- [ ] Delete self when collected

**Acceptance Criteria:** Cheese floats, spins, disappears when boat touches it.

---

#### Issue #10: Entity Spawning
**Labels:** `core`, `priority-critical`

**Description:**

In `game_manager.gd` (Autoload):
- [ ] Preload mouse, cheese, and booster scenes
- [ ] Timer-based spawning for each entity type
- [ ] Random positions within play area
- [ ] Configurable spawn intervals
- [ ] Track all spawned entities (for cleanup)

**Spawn intervals:**
- Mice: every 3 seconds
- Cheese: every 5 seconds
- Boosters: every 15 seconds

**Acceptance Criteria:** Entities automatically spawn during gameplay.

---

### MILESTONE 3: Fuel System & Game Flow (Day 3)

#### Issue #11: Fuel System
**Labels:** `player`, `core`, `priority-critical`

**Description:**

Create `fuel_system.gd`:
- [ ] Track current fuel (0-100)
- [ ] Consume fuel when boat is moving
- [ ] Configurable max fuel and consumption rate
- [ ] Emit signal when fuel changes (for UI)
- [ ] Emit signal when fuel reaches warning level
- [ ] Emit signal when fuel depleted
- [ ] When empty: disable boat movement, trigger game over

**Acceptance Criteria:** Moving consumes fuel, empty fuel = game over.

---

#### Issue #12: Fuel Booster Pickup
**Labels:** `entities`, `day-3`

**Description:**

Create `fuel_booster.tscn`:
- [ ] Root: Area3D
- [ ] Green glowing appearance (emission material)
- [ ] Bobbing and rotating animation
- [ ] Add to group: "booster"

Create `fuel_booster.gd`:
- [ ] Configurable fuel amount (default 25)
- [ ] Connect to boat_rescue_system or handle in own script
- [ ] Delete when collected

**Acceptance Criteria:** Collecting boosters refills fuel.

---

#### Issue #13: Game Manager Autoload
**Labels:** `core`, `priority-critical`

**Description:**

Create `game_manager.gd` as an Autoload:
- [ ] Project → Project Settings → Autoload → Add game_manager.gd as "GameManager"
- [ ] Track game state: MENU, PLAYING, GAME_OVER
- [ ] 5-minute countdown timer
- [ ] Track score (cheese + mice points)
- [ ] Track mice rescued count
- [ ] Handle spawning (or delegate to spawner)
- [ ] Emit signals: score_changed, time_updated, game_over
- [ ] start_game(), end_game(), restart_game() functions

**Acceptance Criteria:** Global game state accessible from any script.

---

#### Issue #14: Win/Lose Conditions
**Labels:** `core`, `day-3`

**Description:**

In game_manager.gd:
- [ ] Game ends when timer hits zero (Time's Up)
- [ ] Game ends when fuel depletes (Out of Fuel)
- [ ] Final score calculated
- [ ] Transition to game over state
- [ ] Emit game_over signal with reason

**Acceptance Criteria:** Game properly ends under both conditions.

---

### MILESTONE 4: User Interface (Day 4)

#### Issue #15: HUD - Fuel Gauge
**Labels:** `ui`, `priority-high`

**Description:**
- [ ] Create CanvasLayer → Control → ProgressBar
- [ ] Position in corner of screen
- [ ] Connect to FuelSystem's fuel_changed signal
- [ ] Color coding: green → yellow → red based on level
- [ ] Create hud_controller.gd to manage updates

**Acceptance Criteria:** Player sees fuel level at all times.

---

#### Issue #16: HUD - Score and Stats Display
**Labels:** `ui`, `priority-high`

**Description:**
- [ ] Add Label for score: "Score: 000"
- [ ] Add Label for mice rescued: "Mice Saved: 00"
- [ ] Add Label for boat capacity: "On Board: 0/4"
- [ ] Connect to GameManager signals
- [ ] Position in top corners

**Acceptance Criteria:** Player sees score and rescue stats.

---

#### Issue #17: HUD - Timer Display
**Labels:** `ui`, `priority-high`

**Description:**
- [ ] Add Label for timer
- [ ] Format as "4:59" (MM:SS)
- [ ] Connect to GameManager time_updated signal
- [ ] Flash red in final 30 seconds
- [ ] Position top-center

**Acceptance Criteria:** Player knows how much time remains.

---

#### Issue #18: Game Over Screen
**Labels:** `ui`, `priority-high`

**Description:**

Create `game_over.tscn`:
- [ ] CanvasLayer with full-screen Control
- [ ] Semi-transparent dark background
- [ ] "GAME OVER" title label
- [ ] Reason label (Time's Up / Out of Fuel)
- [ ] Final score label
- [ ] Mice rescued label
- [ ] Restart button
- [ ] Quit button

Create `game_over_ui.gd`:
- [ ] Show when game_over signal received
- [ ] Pause the game (get_tree().paused = true)
- [ ] Connect button signals
- [ ] Restart reloads scene
- [ ] Quit exits game

**Acceptance Criteria:** Clear end screen with stats and replay option.

---

#### Issue #19: Boat Selection Screen (Simple)
**Labels:** `ui`, `day-4`

**Description:**

For MVP, simplify to:
- [ ] Three buttons at game start: Small / Medium / Large boat
- [ ] Each button sets boat stats and starts game
- [ ] Or: Use @export variables and skip selection UI

**Boat stats:**
- Small: Speed 15, Capacity 2, Fuel 60
- Medium: Speed 10, Capacity 4, Fuel 100
- Large: Speed 6, Capacity 6, Fuel 150

**Acceptance Criteria:** Player can choose boat type (or use default).

---

### MILESTONE 5: Polish & Ship (Day 5)

#### Issue #20: Visual Priority Indicators
**Labels:** `gameplay`, `priority-medium`

**Description:**
- [ ] Mice change color based on urgency (already in mouse_controller)
- [ ] Optional: Add floating exclamation mark over critical mice
- [ ] Optional: UI list showing nearby mice sorted by urgency

**Acceptance Criteria:** Player can identify urgent mice visually.

---

#### Issue #21: Sound Effects
**Labels:** `polish`, `day-5`

**Description:**
- [ ] Add AudioStreamPlayer nodes for:
  - Boat engine (looping)
  - Pickup sound
  - Rescue sound
  - Low fuel warning
  - Game over sound
- [ ] Find free sounds at freesound.org or kenney.nl
- [ ] Trigger sounds at appropriate moments

**Acceptance Criteria:** Game has audio feedback.

---

#### Issue #22: Visual Effects
**Labels:** `polish`, `day-5`

**Description:**
- [ ] Add GPUParticles3D for:
  - Water splash behind boat
  - Sparkle on pickups
  - Bubbles when mouse drowns
- [ ] Godot has built-in particle presets to start from

**Acceptance Criteria:** Game has visual feedback.

---

#### Issue #23: Final Testing
**Labels:** `testing`, `priority-critical`

**Description:**
- [ ] Game starts correctly
- [ ] Boat movement feels good
- [ ] Mice spawn and drown properly
- [ ] Rescuing mice works
- [ ] Collecting cheese works
- [ ] Fuel depletes and boosters work
- [ ] Timer counts down
- [ ] Game ends at 0:00
- [ ] Game ends when fuel empty
- [ ] Game over screen shows correct stats
- [ ] Restart works
- [ ] No errors in debugger
- [ ] Acceptable performance

**Acceptance Criteria:** All features work without errors.

---

#### Issue #24: Export Build
**Labels:** `release`, `priority-critical`

**Description:**
- [ ] Project → Export
- [ ] Add export preset (macOS, Windows, or Web)
- [ ] For Web: Enable in export settings
- [ ] Click "Export Project"
- [ ] Test the exported build
- [ ] Create README with controls

**Acceptance Criteria:** Standalone game that runs outside Godot.

---

## Day-by-Day Issue Assignment

### Day 1 (Setup + Boat)
- Issue #1: Project Setup
- Issue #2: Configure Input Actions
- Issue #3: Create Water Surface
- Issue #4: Basic Boat Scene and Controller
- Issue #5: Third-Person Camera
- Issue #6: Play Area Boundaries

### Day 2 (Mice + Pickups)
- Issue #7: Mouse Scene with Drowning Timer
- Issue #8: Mouse Rescue Mechanic
- Issue #9: Cheese Pickup
- Issue #10: Entity Spawning

### Day 3 (Fuel + Game Flow)
- Issue #11: Fuel System
- Issue #12: Fuel Booster Pickup
- Issue #13: Game Manager Autoload
- Issue #14: Win/Lose Conditions

### Day 4 (UI)
- Issue #15: HUD - Fuel Gauge
- Issue #16: HUD - Score Display
- Issue #17: HUD - Timer Display
- Issue #18: Game Over Screen
- Issue #19: Boat Selection Screen

### Day 5 (Polish + Ship)
- Issue #20: Visual Priority Indicators
- Issue #21: Sound Effects (if time)
- Issue #22: Visual Effects (if time)
- Issue #23: Final Testing
- Issue #24: Export Build

---

## Risk Mitigation

**If running behind schedule:**

- Day 2 behind → Skip cheese initially, focus on mice only
- Day 3 behind → Simplify fuel to just a timer (not consumption-based)
- Day 4 behind → Minimal UI (just Labels, no fancy styling)
- Day 4 behind → Skip boat selection (hardcode medium boat)
- Day 5 behind → Skip all polish (sound, particles)

**The absolute minimum shippable game needs:**
1. Moving boat
2. Spawning mice that drown
3. Ability to rescue mice
4. Score counter
5. Game timer with game over

Everything else is enhancement.

---

## Godot-Specific Tips

**Save scenes often**: Ctrl+S / Cmd+S saves the current scene. Godot auto-saves scripts but not scenes.

**Use @onready**: Instead of getting nodes in _ready(), declare them with @onready at the top:
```gdscript
@onready var mesh = $MeshInstance3D
```

**Print debugging**: `print("value: ", variable)` outputs to the bottom Output panel.

**Check errors**: Errors appear in the Output panel with line numbers. Click to jump to the problem.

**Remote tab**: While running, the Scene panel has a "Remote" tab showing the live scene tree. Super useful for debugging.

**Reload scene to restart**: `get_tree().reload_current_scene()` is the easiest way to restart.

---

## Resources

- [Godot Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [Godot Asset Library](https://godotengine.org/asset-library/asset) (free assets)
- [Kenney Assets](https://kenney.nl/assets) (free 3D models and sounds)
- [Freesound](https://freesound.org/) (free sound effects)
