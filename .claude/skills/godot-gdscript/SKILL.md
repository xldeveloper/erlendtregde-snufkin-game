---
name: godot-gdscript
description: Comprehensive GDScript and Godot 4.x development knowledge covering node architecture, scene structure, signals, physics, input handling, resources, and best practices. Use when working with Godot projects involving GDScript code, scene files (.tscn), game logic implementation, node-based architecture, or Godot-specific features like AnimatedSprite2D, CharacterBody2D, Area2D, Camera2D, physics, collision detection, timers, tweens, or resource management.
---

# Godot GDScript Development

Comprehensive guide for Godot 4.x game development using GDScript.

## Core Principles

### Node-Based Architecture

Everything in Godot is a **Node**. Scenes are trees of nodes. Understand the hierarchy:
- `Node` - Base class, provides basic tree structure
- `Node2D` - Adds 2D transform (position, rotation, scale)
- `Node3D` - Adds 3D transform
- Specialized nodes inherit from these

### Scene Structure

- **Scenes are reusable** - A scene can be instanced multiple times
- **Composition over inheritance** - Build complex objects from simple scenes
- **Each scene has a root node** - The top-level node defines the scene type

## Essential Syntax & Patterns

### Variable Declaration

```gdscript
# Inferred type
var health = 100

# Explicit type
var health: int = 100

# Export to Inspector (Godot 4.x syntax)
@export var speed: float = 300.0
@export_range(0, 100) var health: int = 100
@export_category("Combat")
@export var damage: int = 10

# Constants
const MAX_SPEED = 500.0
const GRAVITY = 980.0
```

### Property Initialization Sequence

**Understanding the order matters for exports and setters:**

```gdscript
@export var my_value: String = "initial":
    set(value):
        my_value = value + "!"

func _init():
    # Runs AFTER initial value, triggers setter
    my_value = "from_init"  # Result: "from_init!"

# When node is in a scene file with Inspector value set to "inspector":
# Final result: "inspector!" (Inspector overrides _init)
```

**Sequence:**
1. Initial value assignment (`= "initial"`) - setter NOT called
2. `_init()` assignments - setter IS called
3. Inspector/export values - setter IS called (if node in scene)

**Best Practice:** For exports, use `null` or invalid defaults, let Inspector set real values.

### Node References

```gdscript
# @onready - Runs after _ready(), node tree is guaranteed to exist
@onready var sprite = $AnimatedSprite2D
@onready var timer = $Timer
@onready var collision = $CollisionShape2D

# Manual reference
var sprite = null

func _ready():
    sprite = get_node("AnimatedSprite2D")
    # or
    sprite = $AnimatedSprite2D
```

### Lifecycle Methods

```gdscript
func _init():
    # Constructor - called when object is created
    # Runs BEFORE _ready(), before node is in tree
    # Use for initial property setup
    pass

func _ready():
    # Called once when node enters scene tree
    # All child nodes have also called _ready() (bottom-up)
    # Initialize variables, connect signals, setup state
    pass

func _enter_tree():
    # Called when node enters tree (before _ready)
    # Called again if removed and re-added
    # Use for setup that needs parent access
    pass

func _exit_tree():
    # Called when node exits tree
    # Use for cleanup
    pass

func _process(delta: float):
    # Called every frame (frame-dependent)
    # Use for non-physics updates, animations, timers, UI
    # Check inputs here if you need frame-perfect response
    pass

func _physics_process(delta: float):
    # Called at fixed intervals (default 60 FPS, frame-independent)
    # Use for physics, movement, collision detection
    # Prefer this over _process for movement
    pass

func _input(event: InputEvent):
    # Receives ALL input events
    # Use for specific key/mouse detection
    if event.is_action_pressed("jump"):
        jump()

func _unhandled_input(event: InputEvent):
    # Only receives events not handled by UI or other nodes
    pass

func _notification(what: int):
    # Universal callback for engine notifications
    # Handles NOTIFICATION_* constants
    match what:
        NOTIFICATION_PARENTED:
            print("Node got a parent")
        NOTIFICATION_UNPARENTED:
            print("Node lost parent")
```

### Process vs Physics Process vs Input

**Use `_process(delta)`:**
- Frame-dependent updates
- UI updates
- Non-physics animations
- Timers that don't need precision
- For recurring checks without every-frame need, use Timer instead

**Use `_physics_process(delta)`:**
- All physics and movement
- Consistent updates regardless of framerate
- Collision detection
- Kinematic operations

**Use `*_input(event)`:**
- Reacts only when input occurs (more efficient)
- For input checks, prefer this over polling in _process
- Check delta time with `get_process_delta_time()` if needed

### Input Handling

```gdscript
# Check action state (defined in Project Settings > Input Map)
if Input.is_action_pressed("move_right"):  # Held down
    velocity.x += SPEED

if Input.is_action_just_pressed("jump"):  # Pressed this frame
    jump()

if Input.is_action_just_released("shoot"):  # Released this frame
    stop_shooting()

# Get axis input (-1 to 1)
var direction = Input.get_axis("move_left", "move_right")
velocity.x = direction * SPEED

# Get vector input
var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
```

## Common Node Types & Usage

### CharacterBody2D (for player/NPCs)

```gdscript
extends CharacterBody2D

const SPEED = 300.0
const GRAVITY = 980.0
const JUMP_FORCE = -400.0

func _physics_process(delta):
    # Apply gravity
    velocity.y += GRAVITY * delta
    
    # Horizontal movement
    var direction = Input.get_axis("ui_left", "ui_right")
    velocity.x = direction * SPEED
    
    # Jump
    if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
        velocity.y = JUMP_FORCE
    
    # MUST call this to apply movement and handle collisions
    move_and_slide()
```

### Area2D (for triggers/detection)

```gdscript
extends Area2D

signal player_entered
signal player_exited

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
    if body.is_in_group("Player"):
        player_entered.emit()
        print("Player entered area")

func _on_body_exited(body: Node2D):
    if body.is_in_group("Player"):
        player_exited.emit()
```

### AnimatedSprite2D

```gdscript
@onready var sprite = $AnimatedSprite2D

func _ready():
    sprite.play("idle")

func update_animation(direction: float):
    if direction != 0:
        sprite.play("run")
        sprite.flip_h = direction < 0  # Flip when moving left
    else:
        sprite.play("idle")
```

### Timer

```gdscript
@onready var timer = $Timer

func _ready():
    timer.wait_time = 2.0
    timer.one_shot = true  # Only fires once
    timer.timeout.connect(_on_timer_timeout)
    timer.start()

func _on_timer_timeout():
    print("Timer finished!")
```

### Camera2D

```gdscript
@onready var camera = $Camera2D

func _ready():
    camera.enabled = true
    camera.make_current()  # Set as active camera
    
    # Smooth following
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
```

## Signals

### Defining & Emitting Signals

```gdscript
# Define custom signal
signal health_changed(new_health)
signal player_died

# Emit signal
health_changed.emit(50)
player_died.emit()
```

### Connecting Signals

```gdscript
# Godot 4.x syntax - connect in code
func _ready():
    $Button.pressed.connect(_on_button_pressed)
    $Timer.timeout.connect(_on_timer_timeout)

func _on_button_pressed():
    print("Button clicked!")
```

## Groups & Node Queries

```gdscript
# Add node to group (in editor or code)
add_to_group("enemies")
add_to_group("Player")

# Check if in group
if body.is_in_group("Player"):
    take_damage()

# Get all nodes in group
var enemies = get_tree().get_nodes_in_group("enemies")
for enemy in enemies:
    enemy.take_damage(10)

# Get first node in group
var player = get_tree().get_first_node_in_group("Player")
```

## Scene Management

### Changing Scenes

```gdscript
# Change scene by path
get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Change scene by PackedScene
var next_scene = preload("res://scenes/level_2.tscn")
get_tree().change_scene_to_packed(next_scene)

# Manual scene change with transition
var new_scene = load("res://scenes/level_2.tscn")
get_tree().root.add_child(new_scene.instantiate())
queue_free()  # Remove current scene
```

### Instancing Scenes

```gdscript
# Preload (at compile time)
const BULLET = preload("res://scenes/bullet.tscn")

func shoot():
    var bullet = BULLET.instantiate()
    bullet.position = $Muzzle.global_position
    get_tree().root.add_child(bullet)

# Load (at runtime)
var enemy_scene = load("res://scenes/enemy.tscn")
var enemy = enemy_scene.instantiate()
add_child(enemy)
```

## Resources & Preloading

### Preload vs Load

```gdscript
# PRELOAD - Compile-time loading (FASTER)
# - Loads when script loads
# - Editor can autocomplete paths
# - Use for constants and frequently used resources
const BulletScene = preload("res://scenes/bullet.tscn")
const PlayerTexture = preload("res://sprites/player.png")

# LOAD - Runtime loading (FLEXIBLE)
# - Loads when line executes
# - Can use dynamic paths
# - Use for conditional/optional resources
var scene_path = "res://scenes/level_" + str(level_num) + ".tscn"
var level = load(scene_path)

# For exports, avoid preloading - let Inspector override
@export var custom_scene: PackedScene  # Don't preload here
```

### When to Use Each

**Use `preload()`:**
- Script/scene dependencies that won't change
- Frequently spawned objects (bullets, particles)
- Required resources that must exist

**Use `load()`:**
- Dynamic path construction
- Optional/conditional resources
- Resources that may be unloaded later
- Large resources that shouldn't stay in memory

## Tweens (Animations)

```gdscript
# Create tween
var tween = create_tween()

# Animate property
tween.tween_property($Sprite, "position", Vector2(100, 100), 1.0)
tween.tween_property($Sprite, "modulate:a", 0.0, 0.5)  # Fade out

# Chaining
tween.tween_property($Sprite, "scale", Vector2(2, 2), 0.5)
tween.tween_property($Sprite, "scale", Vector2(1, 1), 0.5)

# Easing
tween.set_ease(Tween.EASE_IN_OUT)
tween.set_trans(Tween.TRANS_CUBIC)

# Wait for completion
await tween.finished
print("Tween completed!")
```

## Async Operations (await)

```gdscript
# Wait for signal
await $Timer.timeout
print("Timer finished")

# Wait one frame
await get_tree().process_frame

# Wait for animation
$AnimatedSprite.play("attack")
await $AnimatedSprite.animation_finished
print("Attack animation done")

# Useful in sequence
func do_sequence():
    print("Starting")
    await get_tree().create_timer(1.0).timeout
    print("After 1 second")
    await get_tree().create_timer(2.0).timeout
    print("After 3 seconds total")
```

## Autoload (Singletons)

Configure in Project Settings → Autoload. **Use sparingly - prefer scene-based architecture.**

```gdscript
# Global.gd (autoload singleton)
extends Node

var player_health = 100
var current_level = 1

func save_game():
    # Save logic
    pass

# Access from any script
Global.player_health -= 10
Global.save_game()
```

### When to Use Autoloads

**Good uses:**
- Truly global systems (save/load, settings, audio manager)
- Systems managing their own data without interfering with scenes
- Shared utilities that don't need scene context

**Avoid autoloads for:**
- Scene-specific functionality (use scene nodes instead)
- Things that could be passed via signals or references
- Manager classes that tightly couple your code

**Alternative:** Use `static` functions/variables in script classes:

```gdscript
# utils.gd
extends Node
class_name Utils

static var shared_data = {}

static func calculate_damage(base: int, modifier: float) -> int:
    return int(base * modifier)

# Use anywhere without autoload
Utils.calculate_damage(10, 1.5)
```

## Best Practices

### Code Organization

- **One script per node** - Each scene's root node gets its own script
- **Use @onready for node references** - Ensures nodes exist when accessed
- **Group related functionality** - Use separate scenes for reusable components
- **Prefer composition** - Combine simple scenes into complex ones
- **snake_case for files/folders** - Avoids case-sensitivity issues on export
- **PascalCase for node names** - Matches built-in node convention

### Performance

- **Avoid `get_node()` in loops** - Cache references in `@onready` or `_ready()`
- **Use `_physics_process()` for physics** - Don't do physics in `_process()`
- **Queue free properly** - Use `queue_free()` instead of manual removal
- **Limit `queue_redraw()`** - Only redraw when state changes
- **Set properties before adding to tree** - Property setters can be slow; batch changes before `add_child()`
- **PackedScene faster than script instantiation** - Prefer scenes over `MyScript.new()` for game objects

### Data Structure Choice

**Array:** Fast iteration, slow insert/remove (except at end)
**Dictionary:** Fast insert/remove/get by key, slow find by value  
**Object/Resource:** Provides structure but slower than both due to property lookup chain

**Rule:** Use simplest structure that meets needs. Array for lists, Dictionary for lookups, Object for complex data with behavior.

### Common Patterns

- **State machines for complex behavior** - Track current state, handle transitions
- **Use signals for loose coupling** - Don't directly reference other nodes when possible
- **Validate in `_ready()`** - Check that required nodes exist
- **Use `is_instance_valid()`** - Before accessing nodes that might be freed
- **Duck-typed access** - Check `has_method()` before calling on unknown types

### Godot 4.x Changes

- `@export` instead of `export`
- `@onready` instead of `onready`
- `.connect()` requires explicit method reference: `signal.connect(method)`
- `move_and_slide()` takes no parameters (velocity is property)
- Signals emit with `.emit()` instead of `emit_signal()`

## Common Gotchas

1. **Forgetting `move_and_slide()`** - CharacterBody2D won't move without it
2. **Not checking `is_on_floor()`** - Before allowing jumps
3. **Using wrong process function** - Physics in `_physics_process()`, not `_process()`
4. **Accessing nodes before `_ready()`** - Use `@onready` or access in/after `_ready()`
5. **Forgetting `delta`** - Multiply movement/timers by delta for frame-rate independence
6. **Not setting collision layers** - Objects won't collide without proper layer setup

## Further Reading

For deep dives into specific topics:
- [Node Types Reference](references/node_types.md) - Detailed node type documentation
- [Physics & Collision](references/physics.md) - Advanced physics patterns
- [Scene Architecture](references/scene_patterns.md) - Scene composition strategies
- [Best Practices](references/best_practices.md) - Official Godot best practices (dependency injection, autoload guidelines, data structures, performance patterns)
