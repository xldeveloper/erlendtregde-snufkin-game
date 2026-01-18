---
name: snufkin-game
description: Project-specific architecture and patterns for the Snufkin game. Use when working on this specific Godot project involving player movement, scene transitions (house interior, fishing scene, main world, map navigation), NPC dialogue system, interaction zones, global state management, particle effects (falling leaves, wind gusts), fishing mechanics, main menu system, map-based travel system, or UI systems specific to this game.
---

# Snufkin Game Architecture

Project-specific patterns and systems for the Snufkin Moomin game.

## Project Overview

- **Engine**: Godot 4.5
- **Genre**: 2D adventure/exploration game
- **Resolution**: 1920x1080 (fullscreen, canvas_items stretch)
- **Main Scene**: `res://scenes/main_menu.tscn` (starts at main menu)

## Core Architecture

### Autoload Singleton: Global

Located at `res://scripts/global.gd`

**Purpose**: Manage persistent state across scene transitions

```gdscript
# Global.gd
extends Node

var from_scene = ""  # Tracks scene transition type
var current_location = "tent"  # Player's current map location
var previous_scene = ""  # Scene to return to after map
var saved_player_position = Vector2.ZERO  # Position before opening map
var saved_position_scene = ""  # Which scene position belongs to
```

**Usage**: Manages scene transitions, position restoration, and location tracking for map navigation system.

### Project Structure

```
scenes/
├── main_menu.tscn      # Main menu (starting scene)
├── map_scene.tscn      # Interactive world map
├── main.tscn           # Main overworld
├── house_interior.tscn # Moomin house interior
├── fishing_scene.tscn  # Fishing minigame
├── player.tscn         # Player character
├── npc.tscn            # NPC template
└── draggable_item.tscn # Draggable objects (house interior)

scripts/
├── global.gd                      # Autoload singleton
├── main_menu.gd                  # Main menu controller
├── character_body_2d.gd          # Player controller
├── map_controller.gd             # Map scene camera controller
├── map_opener.gd                 # Universal M key handler
├── map_location.gd               # Clickable map locations
├── draggable_snufkin.gd          # Draggable map character
├── location_tracker.gd           # Track player location in Main
├── HouseInteraction.gd           # Enter house trigger
├── ExitHouse.gd                  # Exit house trigger
├── FishingInteraction.gd         # Enter fishing trigger
├── npc.gd                        # NPC interaction
├── dialogue.gd                   # Dialogue system
├── HouseInteriorController.gd    # House scene setup
├── DraggableItem.gd              # Drag-and-drop items
└── [particle/weather systems]

dialague/
├── moominMama.json     # Dialogue data
└── Images/             # Dialogue character sprites
```

## Game Flow

### User Journey
1. **Main Menu** (`main_menu.tscn`) - Intro, instructions, "Begin Journey" button
2. **World Map** (`map_scene.tscn`) - Drag Snufkin, select location
3. **Gameplay Scenes** - Main overworld, house interior, fishing
4. **Map Navigation** - Press M anytime to open map, Esc to close

## Scene Transition Pattern

All scene transitions follow this pattern:

### 1. Interaction Area (Area2D)

```gdscript
extends Area2D

var entered = false
var player_character_body = null
@onready var label = $Label

func _ready():
    label.visible = false

func _on_body_entered(body):
    if body.is_in_group("Player"):
        entered = true
        player_character_body = body
        label.visible = true

func _on_body_exited(body):
    if body.is_in_group("Player"):
        entered = false
        player_character_body = null
        label.visible = false

func _process(_delta):
    if not is_inside_tree():
        return
    if entered and Input.is_action_just_pressed("interact"):
        # Set transition type and location
        Global.from_scene = "house_interior"  # or "fishing_scene"
        Global.current_location = "moomin_house"  # Update location
        
        get_tree().change_scene_to_file("res://scenes/TARGET_SCENE.tscn")
```

**Key Points**:
- Area2D detects player entry via `is_in_group("Player")`
- Shows label when player is in range
- Waits for "interact" action (E key)
- Saves position before transition
- Changes scene using `get_tree().change_scene_to_file()`

### 2. Position Restoration

Player script checks scene name and restores position:

```gdscript
func _ready():
    await get_tree().process_frame
    
    var current_scene = get_tree().current_scene.name
    if current_scene == "HouseInterior":
        pass  # Use default spawn position
    else:
        var saved_pos = Global.get_saved_position()
        if saved_pos != Vector2.ZERO:
            global_position = saved_pos
```

### 3. Exit Interactions

Exit areas DON'T save position (returns to previously saved position):

```gdscript
# ExitHouse.gd
func _process(_delta):
    if entered and Input.is_action_just_pressed("interact"):
        # Don't save position - use the one saved before entering
        get_tree().change_scene_to_file("res://scenes/main.tscn")
```

## Player System

### Player Controller (`character_body_2d.gd`)

**Key Features**:
- Side-scrolling platformer movement
- Jump mechanic with gravity
- Idle timer system (15 seconds → sitting animation + music)
- Random idle animations ("idle" vs "smoking")
- Animation state management

**Constants**:
```gdscript
const SPEED = 700.0
const GRAVITY = 800.0
const JUMP_FORCE = -300.0
const IDLE_TIME_LIMIT = 15.0
```

**Idle System**:
- Timer starts on `_ready()`
- Resets on movement/jump
- After 15 seconds, plays "sitting" animation
- Starts harmonica music during sitting
- Music stops when player moves

**Animation States**:
- `"idle"` - Standing still
- `"smoking"` - Alternative idle
- `"sitting"` - After idle timeout
- `"run_right"` - Running (flip_h for left)
- `"jump"` - In air

**Important**: Player is in group "Player" for detection

## Dialogue System

Located at `res://scripts/dialogue.gd` and `res://dialogue/`

### Dialogue Structure

**JSON Format** (`moominMama.json`):
```json
[
    {"name": "Moomin mama", "text": "Hello there!"},
    {"name": "Moomin mama", "text": "I love this place."}
]
```

### NPC Interaction (`npc.gd`)

```gdscript
extends Area2D

@export var dialogue_control_path: NodePath
@export var npc_name: String = "Moomin mama"

var dialogue_control
var player_in_range = false

func _ready():
    dialogue_control = get_node(dialogue_control_path)

func _input(event):
    if event.is_action_pressed("interact"):
        if player_in_range and dialogue_control:
            dialogue_control.start_dialogue(self)
```

### Dialogue Controller (`dialogue.gd`)

**Features**:
- Camera transition from player to dialogue camera
- Player movement disabled during dialogue
- Character sprites displayed (left = NPC, right = player)
- UI_ACCEPT to advance, UI_CANCEL to exit
- Smooth camera tweening

**Key Functions**:
```gdscript
func start_dialogue(npc):
    # Load dialogue, setup UI, disable player, transition camera
    
func next_script():
    # Advance to next dialogue line
    
func end_dialogue():
    # Restore player control, transition camera back
```

**Camera Behavior**:
- Tweens from player camera to dialogue camera (0.5s cubic ease)
- Tweens back on dialogue end
- Player physics/input disabled during dialogue

## Fishing System

See [Fishing System Reference](references/fishing_system.md) for complete details.

**Key Scripts**:
- `FishingInteraction.gd` - Enter fishing area
- `fishing_player.gd` - Fishing rod controller
- `hook.gd` - Hook movement
- `fish.gd` / `fish_spawner.gd` - Fish behavior

## Particle Systems

### Falling Leaves (`falling_leaves.gd`)

**Features**:
- GPU particles for performance
- Strong leftward wind effect
- Multiple leaf textures (animated)
- Camera following (stays relative to view)
- Ground collision detection

**Key Exports**:
- `particle_amount` - Number of leaves
- `wind_strength` - Horizontal force (default: -600)
- `gravity_strength` - Vertical force (default: 50)
- `follow_camera` - Stick to viewport

### Wind Gusts (`WindGustSpawner.gd`)

**Features**:
- Spawns wind effect across screen (right to left)
- Variable spawn intervals and Y positions
- Parallax depth variation (some in background layers)
- Distance-based scaling (parallax effect)
- Auto-cleanup off-screen

**Spawn Pattern**:
- Spawns just off right edge of camera
- Moves left via Path2D
- Random Y offset for variety
- 40% spawn in parallax layers, 60% in foreground

## Input Actions

Defined in `project.godot`:

```
ui_left    - A, Left Arrow
ui_right   - D, Right Arrow
ui_accept  - Space (jump/confirm)
interact   - E (interact with NPCs/objects)
fish       - F (fishing cast)
cast_hook  - Space (in fishing scene)
catch_fish - Enter (in fishing scene)
```

## Common Patterns

### Camera Management

**Main World**: Player has Camera2D child
**House Interior**: Separate Camera2D, player's camera disabled
**Dialogue**: Temporary camera switch with tween

```gdscript
# Disable player camera
var player_camera = get_tree().get_first_node_in_group("player_camera")
if player_camera:
    player_camera.enabled = false

# Enable scene camera
var scene_camera = $Camera2D
scene_camera.enabled = true
scene_camera.make_current()
```

### Groups

**Critical Groups**:
- `"Player"` - Player character (for detection)
- `"player_camera"` - Player's camera (for access)
- `"player"` - Player node (alternative reference)

### Timer Pattern

```gdscript
@onready var timer = $Timer

func _ready():
    timer.wait_time = 15.0
    timer.one_shot = true
    timer.timeout.connect(_on_timer_timeout)
    timer.start()

func reset_timer():
    timer.start()
```

## House Interior System

**Controller**: `HouseInteriorController.gd`

**Setup**:
1. Disable player camera
2. Enable house Camera2D
3. Player spawns at default position

**Draggable Items**: Use `DraggableItem.gd` for interactive objects

```gdscript
extends Node2D

@export var can_be_dragged: bool = true
var is_dragging: bool = false

func _on_input_event(_viewport, event, _shape_idx):
    if can_be_dragged and event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            is_dragging = event.pressed

func _process(_delta):
    if is_dragging:
        global_position = get_global_mouse_position()
```

## Best Practices for This Project

### Scene Transitions
1. Always check if player reference exists before saving position
2. Use priority-based spawn system in player _ready()
3. Exit scenes should set from_scene and current_location
4. Always check `is_inside_tree()` before processing input
5. Handle Node2D containers with CharacterBody2D children

### Player State
- Reset idle timer on any input
- Stop music when exiting idle state
- Use `await get_tree().process_frame` before position checks
- Spawn priority: saved position > from_scene > map selection > default

### Map Navigation
- Clear from_scene when pressing Esc to enable position restoration
- Position DraggableSnufkin after scene tree is ready
- Use exact location node positions from scene file
- Add timing delays (0.2s) to LocationTracker to avoid conflicts

### Dialogue
- Disable player physics AND input during dialogue
- Always restore both when ending dialogue
- Use tweens for smooth camera transitions
- Set high z_index for dialogue UI (e.g., 100)

### Particle Systems
- Set `local_coords = false` for camera-following particles
- Use `queue_redraw()` only when state changes
- Clean up particles off-screen

## Quick Reference: Common Tasks

### Adding Map Navigation to New Scene
1. Add MapOpener node: `[node name="MapOpener" type="Node" parent="."]`
2. Attach script: `script = ExtResource("map_opener_script")`
3. Player can now press M to open map from that scene

### Creating New Map Location
1. Add Area2D to map_scene.tscn at desired position
2. Attach map_location.gd script
3. Set exports: location_name, target_scene_path, focused_texture
4. Add CollisionShape2D for hover detection

### Handling Scene Transitions
```gdscript
# Before changing scene from interaction
Global.from_scene = "house_interior"  # or "fishing_scene"
Global.current_location = "moomin_house"  # Update location
get_tree().change_scene_to_file("res://scenes/target.tscn")
```

### Position Restoration Pattern
```gdscript
# Priority 1: Restore saved position (same scene via Esc)
if Global.saved_player_position != Vector2.ZERO and Global.saved_position_scene == current_scene_path:
    global_position = Global.saved_player_position
    # Clear globals
    Global.saved_player_position = Vector2.ZERO
    Global.saved_position_scene = ""
    Global.from_scene = ""
```

## Project-Specific Templates

See `assets/templates/` for:
- Interaction area template
- NPC template
- Draggable item template

## Further Reading

- [Main Menu System](references/main_menu_system.md)
- [Map Navigation System](references/map_navigation_system.md)
- [Dialogue System Details](references/dialogue_system.md)
- [Fishing System Details](references/fishing_system.md)
- [Scene Transition Workflow](references/scene_transitions.md)

