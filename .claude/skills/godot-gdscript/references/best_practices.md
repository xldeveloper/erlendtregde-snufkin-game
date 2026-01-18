# Godot Best Practices Reference

Advanced patterns and architectural guidelines from official Godot 4.5 documentation.

## Table of Contents

- [Scene Organization](#scene-organization)
- [Dependency Injection](#dependency-injection)
- [Autoload Guidelines](#autoload-guidelines)
- [Data Structure Performance](#data-structure-performance)
- [Logic Patterns](#logic-patterns)
- [Object Access Patterns](#object-access-patterns)

## Scene Organization

### Loose Coupling Principle

**Children should have no hard dependencies on their environment.**

```gdscript
# BAD - Child depends on specific parent structure
extends Node2D

func _ready():
    get_parent().get_node("../UI/HealthBar").value = 100  # Fragile!

# GOOD - Child exposes signal, parent connects it
extends Node2D
signal health_changed(new_health)

func take_damage(amount):
    health -= amount
    health_changed.emit(health)

# Parent connects signal to whatever needs it
func _ready():
    $Player.health_changed.connect($UI/HealthBar.set_value)
```

### Main/World/GUI Pattern

Recommended scene structure for levels:

```
Main (root)
├── World (game objects)
│   ├── Player
│   ├── Enemies
│   └── Environment
└── GUI (UI layer)
    ├── HealthBar
    ├── Inventory
    └── Minimap
```

**Benefits:**
- Clear separation of game logic and UI
- GUI stays on top naturally (later children draw above earlier)
- Easy to toggle GUI visibility
- Camera affects World only, not GUI

```gdscript
# main.gd
extends Node

@onready var world = $World
@onready var gui = $GUI

func toggle_ui():
    gui.visible = !gui.visible
```

## Dependency Injection

Five methods to give nodes access to dependencies:

### 1. Signals (Most Loosely Coupled)

```gdscript
# child.gd - No parent knowledge needed
extends Node
signal request_spawn(enemy_type)

func spawn_enemy():
    request_spawn.emit("goblin")

# parent.gd
func _ready():
    $Child.request_spawn.connect(_on_child_request_spawn)

func _on_child_request_spawn(enemy_type):
    # Parent decides how to handle it
    var enemy = ENEMIES[enemy_type].instantiate()
    $Enemies.add_child(enemy)
```

### 2. Call Methods (Direct but Simple)

```gdscript
# parent.gd
extends Node

func spawn_enemy(type: String):
    # Implementation
    pass

# child.gd
func _ready():
    get_parent().call("spawn_enemy", "goblin")
    # or if you know parent type:
    # get_parent().spawn_enemy("goblin")
```

### 3. Callable Properties (Flexible Injection)

```gdscript
# child.gd
extends Node
var spawn_func: Callable = func(enemy): pass  # Default no-op

func spawn_enemy():
    spawn_func.call("goblin")

# parent.gd
func _ready():
    $Child.spawn_func = spawn_enemy_impl

func spawn_enemy_impl(type: String):
    # Implementation
    pass
```

### 4. Node References (Type-Safe)

```gdscript
# child.gd
extends Node
@export var enemy_manager: Node  # Set in Inspector

func spawn_enemy():
    if enemy_manager and enemy_manager.has_method("spawn"):
        enemy_manager.spawn("goblin")

# Set in Inspector: drag EnemyManager to this export
```

### 5. NodePath (Scene Tree Query)

```gdscript
# child.gd
extends Node
@export var manager_path: NodePath

@onready var manager = get_node(manager_path)

func spawn_enemy():
    manager.spawn("goblin")

# In Inspector: set path like "../../../EnemyManager"
```

### Which to Use?

| Method | Coupling | Type Safety | Flexibility |
|--------|----------|-------------|-------------|
| Signals | Lowest | Low | Highest |
| Callable | Low | Medium | High |
| Call methods | Medium | Low | Medium |
| Node export | High | Medium | Low |
| NodePath | High | Low | Low |

**General rule:** Use signals unless you need tight integration or type safety.

## Autoload Guidelines

### When NOT to Use Autoloads

**Problem: The "Sound Manager" Anti-Pattern**

```gdscript
# BAD - Global sound manager creates issues
# autoload/sound.gd
extends Node

var audio_players = []

func play(sound_path: String):
    # Find available player, play sound
    for player in audio_players:
        if not player.playing:
            player.stream = load(sound_path)
            player.play()
            return
```

**Issues:**
1. **Global state** - All audio controlled by one object
2. **Global access** - Any code anywhere can play sounds (hard to debug)
3. **Global resource allocation** - Pool size is guess (too few = bugs, too many = waste)

**Solution: Scene-Local Audio**

```gdscript
# Each scene has AudioStreamPlayer nodes as needed
@onready var coin_sound = $CoinSound
@onready var jump_sound = $JumpSound

func collect_coin():
    coin_sound.play()
```

**Benefits:**
- Each scene manages own audio state
- Easy to find bug source (only this script)
- Allocates exactly what's needed

### When TO Use Autoloads

**Good use cases:**
- Truly global systems (save/load, settings, input mapping)
- Systems with wide scope but narrow interface
- Data that persists across all scenes

**Example: Quest System**

```gdscript
# autoload/quest_manager.gd
extends Node

signal quest_completed(quest_id)
signal quest_started(quest_id)

var active_quests = {}

func start_quest(quest_id: String):
    active_quests[quest_id] = QuestData.new()
    quest_started.emit(quest_id)

func complete_quest(quest_id: String):
    active_quests.erase(quest_id)
    quest_completed.emit(quest_id)
```

**Why this works:**
- Manages own data (active quests)
- Doesn't interfere with scene structure
- Provides narrow, well-defined interface
- Makes sense to persist across scenes

### Autoload Alternatives

#### Static Variables (Godot 4.1+)

```gdscript
# game_stats.gd
extends Node
class_name GameStats

static var high_score: int = 0
static var total_playtime: float = 0.0

static func save_stats():
    # Save implementation
    pass

# Use anywhere without autoload
GameStats.high_score = 1000
GameStats.save_stats()
```

#### Static Functions

```gdscript
# math_utils.gd
extends Node
class_name MathUtils

static func lerp_angle(from: float, to: float, weight: float) -> float:
    var diff = fmod(to - from, TAU)
    return from + fmod(2.0 * diff, TAU) - diff

# Use anywhere
var angle = MathUtils.lerp_angle(0, PI, 0.5)
```

## Data Structure Performance

### Array Performance

**Characteristics:**
- Contiguous memory (fast iteration: O(1) per item)
- Position-based access: O(1)
- Insert/remove: O(n) except at end (O(1))
- Find value: O(n)

**Best for:**
- Lists of items processed in order
- FIFO/LIFO queues (if you only add/remove from one end)
- Small collections (< 1000 items)

```gdscript
# Fast
for item in array:
    process(item)

var last = array[-1]  # Fast
array.append(item)    # Fast
array.pop_back()      # Fast

# Slow
array.insert(0, item)  # Must shift all items
array.erase(item)      # Must find then shift
if item in array:      # Must search all items
```

### Dictionary Performance

**Characteristics:**
- HashMap internally (constant-time access: O(1))
- Key-based access: O(1)
- Insert/remove/lookup by key: O(1)
- Find by value: O(n)
- Memory overhead for hash table

**Best for:**
- Key-value lookups
- Large collections needing fast access
- Caching/memoization

```gdscript
# Fast
var value = dict["key"]     # O(1)
dict["key"] = value         # O(1)
dict.erase("key")           # O(1)
if "key" in dict:           # O(1)

# Slow
for key in dict:
    if dict[key] == search_value:  # O(n)
```

### Object/Resource Performance

**Characteristics:**
- Property access goes through lookup chain
- Checks script → ClassDB → parent classes
- Much slower than Array/Dictionary for data
- Provides structure, validation, signals

**When to use:**
- Need encapsulation and methods
- Want Inspector integration (Resources)
- Signals/reactive behavior needed
- Complex data with validation

```gdscript
# Custom data structure
class_name InventoryItem extends Resource

@export var item_name: String
@export var icon: Texture2D
@export var stack_size: int = 1

var current_stack: int = 1

func can_stack_with(other: InventoryItem) -> bool:
    return item_name == other.item_name and current_stack < stack_size
```

### Performance Summary

| Operation | Array | Dictionary | Object |
|-----------|-------|------------|--------|
| Get by index/key | O(1) | O(1) | O(log n) |
| Get by value | O(n) | O(n) | O(n) |
| Insert | O(n) | O(1) | N/A |
| Remove | O(n) | O(1) | N/A |
| Iterate | Fast | Fast | Slow |
| Memory | Low | Medium | High |

## Logic Patterns

### Adding Nodes: Set Properties First

```gdscript
# SLOW - Property setters run while node is in tree
func spawn_enemy():
    var enemy = ENEMY_SCENE.instantiate()
    add_child(enemy)  # Added to tree
    enemy.health = 100  # Triggers setter, may update UI/etc
    enemy.position = spawn_point  # May update physics
    enemy.color = Color.RED  # May update rendering

# FAST - Set properties before adding to tree
func spawn_enemy():
    var enemy = ENEMY_SCENE.instantiate()
    enemy.health = 100  # Pure assignment
    enemy.position = spawn_point  # Pure assignment
    enemy.color = Color.RED  # Pure assignment
    add_child(enemy)  # Only one tree update
```

**Exception:** Some properties require node to be in tree (e.g., `global_position`).

### Large Levels: Static vs Dynamic

**Static (all at once):**
- Pro: Simple, no loading code
- Con: High memory use, long initial load

**Dynamic (stream in/out):**
- Pro: Lower memory, shorter load times
- Con: Complex, more bugs, technical debt

**Decision matrix:**
- Small/medium game → Static
- Large game + time/resources → Library/plugin for streaming
- Large game + coding skills → Custom dynamic system

## Object Access Patterns

### Duck Typing in Godot

Godot is duck-typed - checks if object can do operation, not type.

```gdscript
# These all work, increasing safety/verbosity tradeoff:

# 1. Direct access (fastest, will crash if property missing)
enemy.health -= 10

# 2. Check method existence first
if enemy.has_method("take_damage"):
    enemy.take_damage(10)

# 3. Type check (safe, but couples code)
if enemy is Enemy:
    enemy.take_damage(10)
    enemy.show_health_bar()  # Multiple calls, check once

# 4. Group-based interface (flexible)
if enemy.is_in_group("damageable"):
    enemy.take_damage(10)  # Assumes all "damageable" have this method

# 5. Use assertions for debugging
assert(enemy.has_method("take_damage"), "Enemy missing take_damage method")
enemy.take_damage(10)
```

### Acquiring Node References (Speed Ranking)

```gdscript
# FASTEST - Cached export reference
@export var target: Node
func attack():
    target.take_damage(10)

# FAST - @onready cached NodePath
@onready var target = $"../Enemy"
func attack():
    target.take_damage(10)

# MEDIUM - Dynamic lookup with cached path (GDScript only)
func attack():
    $"../Enemy".take_damage(10)

# SLOW - String-based lookup every time
func attack():
    get_node("../Enemy").take_damage(10)

# VERY SLOW - String construction + lookup
func attack():
    get_node("../" + enemy_name).take_damage(10)
```

### Resource Loading Patterns

```gdscript
# Pattern 1: Constant import (preload at compile time)
const BULLET = preload("res://scenes/bullet.tscn")

func shoot():
    var bullet = BULLET.instantiate()
    add_child(bullet)

# Pattern 2: Conditional preload (property with default)
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

# Pattern 3: Runtime load (dynamic path)
func load_level(level_num: int):
    var path = "res://levels/level_%d.tscn" % level_num
    var scene = load(path)
    return scene.instantiate()

# Pattern 4: Validate export (tool script)
@tool
@export var required_scene: PackedScene:
    set(value):
        required_scene = value

func _get_configuration_warnings() -> PackedStringArray:
    if not required_scene:
        return ["Must set required_scene property"]
    return []
```

## Node Alternatives

### When to Use Object/RefCounted/Resource Instead of Node

**Object:**
- Custom data structures
- Lightweight containers
- Manual memory management acceptable
- Example: TreeItem (used by Tree UI)

**RefCounted:**
- Same as Object but with automatic memory management
- Most common choice for custom data classes
- Example: FileAccess

**Resource:**
- Need save/load to disk
- Want Inspector editing
- Example: Custom weapon stats, dialogue data

```gdscript
# Custom tree structure using Object (lighter than Node)
class_name TreeNode extends Object

var parent: TreeNode = null
var children: Array[TreeNode] = []
var data = null

func _notification(what):
    if what == NOTIFICATION_PREDELETE:
        # Clean up children when deleted
        for child in children:
            child.free()

func add_child(child: TreeNode):
    children.append(child)
    child.parent = self

# Use it
var root = TreeNode.new()
var child1 = TreeNode.new()
root.add_child(child1)
```

### Node Performance Cost

Nodes have overhead:
- Scene tree management
- Signal system
- Editor integration
- Memory per node ~= 200-300 bytes

**Rule:** If you have 10,000+ of something, consider Object/RefCounted instead of Node.

**Example: Particle System**

```gdscript
# BAD - 10,000 Node2D particles = slow
for i in 10000:
    var particle = Node2D.new()
    add_child(particle)

# GOOD - Use GPUParticles2D or custom Object-based system
@onready var particles = $GPUParticles2D
particles.emitting = true
```

## AnimatedTexture vs AnimatedSprite2D vs AnimationPlayer

### AnimatedTexture (Resource)

**When:** Simple texture animation, no control needed
**Use case:** Background animated tiles in TileMap

```gdscript
var anim_texture = AnimatedTexture.new()
anim_texture.frames = 4
anim_texture.set_frame_texture(0, load("res://frame0.png"))
# ... set other frames
$Sprite2D.texture = anim_texture
```

### AnimatedSprite2D (Node)

**When:** Frame-based character/object animation
**Use case:** Player sprite, enemy sprites

```gdscript
@onready var sprite = $AnimatedSprite2D

func _ready():
    sprite.play("idle")

func update_animation(velocity):
    if velocity.x != 0:
        sprite.play("run")
    else:
        sprite.play("idle")
```

### AnimationPlayer (Node)

**When:** Need to animate multiple properties, trigger events, complex sequences
**Use case:** Cutscenes, character with bones, property animations

```gdscript
@onready var anim = $AnimationPlayer

func _ready():
    anim.play("idle")

# AnimationPlayer can:
# - Animate transform, color, custom properties
# - Call methods at keyframes
# - Play sounds at specific times
# - Blend between animations
```

### AnimationTree (Node)

**When:** Need blending, state machines, complex animation logic
**Use case:** 3D character with locomotion blending, advanced 2D character

```gdscript
@onready var tree = $AnimationTree

func _ready():
    tree.active = true
    
func update_movement(velocity):
    tree.set("parameters/movement/blend_position", velocity.normalized())
```

**Hierarchy:** AnimatedTexture < AnimatedSprite2D < AnimationPlayer < AnimationTree

## Project Organization

### File Structure

```
/project.godot
/scripts/
    player.gd
    enemy.gd
/scenes/
    player.tscn
    enemy.tscn
/assets/
    textures/
    sounds/
    fonts/
/autoload/
    global.gd
    save_manager.gd
/addons/          # Third-party plugins
    cool_plugin/
```

### Style Guide

- **snake_case** - Files, folders, variables, functions
- **PascalCase** - Node names, class names
- **SCREAMING_SNAKE_CASE** - Constants

```gdscript
# Good
const MAX_SPEED = 500
var player_health = 100

func calculate_damage():
    pass

class_name PlayerController
```

### Ignoring Folders

Create `.gdignore` in folder to exclude from import:

```
/docs/.gdignore     # Docs folder won't be imported
/raw_assets/.gdignore  # Keep source files out of project
```

**Use for:**
- Documentation
- Source files (PSD, Blender, etc.)
- Build scripts
- Large reference files

## Key Takeaways

1. **Loose coupling:** Use signals > callables > direct references
2. **Autoloads sparingly:** Prefer scene-local or static functions
3. **Set properties before add_child():** Performance optimization
4. **Choose data structures wisely:** Array for lists, Dictionary for lookups, Object for behavior
5. **Use right process method:** Physics in `_physics_process`, UI in `_process`, input in `*_input`
6. **Cache node references:** @onready or @export, not get_node() in loops
7. **Object alternatives:** Consider Object/RefCounted/Resource for data-heavy systems
8. **Project structure:** Group by feature, use snake_case for files
