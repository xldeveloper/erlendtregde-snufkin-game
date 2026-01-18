# Scene Architecture Patterns

Best practices for organizing and composing Godot scenes.

## Core Principles

1. **Scenes are reusable** - Design them for instancing
2. **Composition over inheritance** - Build complex from simple
3. **Single responsibility** - Each scene does one thing well
4. **Loose coupling** - Use signals instead of direct references

## Common Scene Structures

### Player Scene

```
Player (CharacterBody2D)
├── Sprite (AnimatedSprite2D)
├── Collision (CollisionShape2D)
├── Camera (Camera2D)
├── Timers
│   ├── InvincibilityTimer
│   └── AttackCooldown
└── Hitboxes (Area2D nodes)
    ├── HurtBox (Area2D)
    └── AttackBox (Area2D)
```

### Enemy Scene

```
Enemy (CharacterBody2D)
├── Sprite (AnimatedSprite2D)
├── Collision (CollisionShape2D)
├── HealthBar (ProgressBar)
├── DetectionZone (Area2D)
├── AttackZone (Area2D)
└── AI (Node) - Script for behavior
```

### Level Scene

```
Level (Node2D)
├── World (game objects layer)
│   ├── Environment
│   │   ├── TileMap
│   │   ├── BackgroundLayers
│   │   └── Props (StaticBody2D objects)
│   ├── Entities
│   │   ├── Player
│   │   ├── Enemies
│   │   └── NPCs
│   └── Collectibles
└── GUI (UI layer, always on top)
    ├── HUD
    ├── Minimap
    └── PauseMenu
```

**Benefits of World/GUI separation:**
- GUI naturally renders above game objects
- Camera only affects World, not GUI
- Easy to toggle UI visibility independently
- Clear architectural boundary
│   ├── Enemies (spawn points or instances)
│   └── NPCs
├── Triggers
│   ├── LevelTransitions (Area2D)
│   ├── Checkpoints (Area2D)
│   └── EventTriggers (Area2D)
├── UI (CanvasLayer)
│   ├── HUD
│   └── PauseMenu
└── Systems
    ├── EnemySpawner
    ├── ParticleEffects
    └── AudioManager
```

### UI Scene (HUD)

```
HUD (CanvasLayer)
└── Container (Control)
    ├── HealthBar
    ├── ScoreLabel
    ├── AmmoCounter
    └── Minimap
```

## Reusable Component Patterns

### Health Component

Create a reusable health system:

```gdscript
# health_component.gd
extends Node
class_name HealthComponent

signal health_changed(new_health, max_health)
signal died

@export var max_health: float = 100.0
var current_health: float

func _ready():
    current_health = max_health

func take_damage(amount: float):
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        died.emit()

func heal(amount: float):
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
```

**Usage in Enemy:**
```gdscript
# enemy.gd
extends CharacterBody2D

@onready var health = $HealthComponent

func _ready():
    health.died.connect(_on_died)

func _on_died():
    queue_free()
```

### Hitbox/Hurtbox Pattern

Separate damage dealing from damage receiving:

**HurtBox (receives damage):**
```gdscript
# hurtbox.gd
extends Area2D

signal hurt(damage)

func _ready():
    area_entered.connect(_on_area_entered)

func _on_area_entered(hitbox: Area2D):
    if hitbox.is_in_group("hitbox"):
        hurt.emit(hitbox.damage)
```

**HitBox (deals damage):**
```gdscript
# hitbox.gd
extends Area2D

@export var damage: float = 10.0
@export var knockback_force: float = 200.0
```

**Usage:**
```
Player
├── HurtBox (Area2D) [Layer: Player, Mask: EnemyHitbox]
└── AttackBox (HitBox) [Layer: PlayerHitbox, Mask: Enemy]
```

## Scene Communication Patterns

### 1. Signals (Preferred)

**Child to Parent:**
```gdscript
# button.gd
signal button_clicked

func _on_pressed():
    button_clicked.emit()

# parent.gd
func _ready():
    $Button.button_clicked.connect(_on_button_clicked)

func _on_button_clicked():
    print("Button clicked!")
```

**Cross-Scene (via Autoload):**
```gdscript
# Global.gd (autoload)
signal player_died
signal score_changed(new_score)

# player.gd
func die():
    Global.player_died.emit()

# hud.gd
func _ready():
    Global.score_changed.connect(_on_score_changed)
```

### 2. Direct Reference (When Necessary)

**Parent to Child:**
```gdscript
@onready var player = $Player

func _ready():
    player.health_changed.connect(_on_player_health_changed)
```

**Find Node in Tree:**
```gdscript
# Find by group (preferred)
var player = get_tree().get_first_node_in_group("Player")

# Find by path (fragile)
var player = get_node("/root/Level/Player")
```

### 3. Autoload Singleton

Use for global state and cross-scene communication:

```gdscript
# Global.gd
extends Node

var current_level = 1
var player_health = 100
var score = 0

func reset_game():
    current_level = 1
    player_health = 100
    score = 0

# Access from any scene
Global.player_health -= 10
```

## Scene Instancing Patterns

### Dynamic Scene Loading

```gdscript
# Spawn enemy at runtime
const ENEMY = preload("res://scenes/enemy.tscn")

func spawn_enemy(position: Vector2):
    var enemy = ENEMY.instantiate()
    enemy.global_position = position
    add_child(enemy)
    return enemy
```

### Object Pooling

```gdscript
# bullet_pool.gd
extends Node

const BULLET = preload("res://scenes/bullet.tscn")
var pool = []
var pool_size = 20

func _ready():
    for i in pool_size:
        var bullet = BULLET.instantiate()
        bullet.visible = false
        add_child(bullet)
        pool.append(bullet)

func get_bullet() -> Node2D:
    for bullet in pool:
        if not bullet.visible:
            bullet.visible = true
            return bullet
    # If pool exhausted, create new
    var bullet = BULLET.instantiate()
    add_child(bullet)
    pool.append(bullet)
    return bullet

func return_bullet(bullet: Node2D):
    bullet.visible = false
```

### Scene Switching

```gdscript
# scene_manager.gd (autoload)
extends Node

var current_scene = null

func change_scene(scene_path: String):
    # Defer to avoid issues
    call_deferred("_change_scene", scene_path)

func _change_scene(scene_path: String):
    # Remove current scene
    if current_scene:
        current_scene.queue_free()
    
    # Load and instance new scene
    var new_scene = load(scene_path).instantiate()
    get_tree().root.add_child(new_scene)
    get_tree().current_scene = new_scene
    current_scene = new_scene

# Usage
SceneManager.change_scene("res://scenes/level_2.tscn")
```

## Scene Inheritance

Use for variations of similar objects:

**Base Enemy:**
```
Enemy.tscn
└── Enemy (CharacterBody2D) - enemy_base.gd
    ├── Sprite (AnimatedSprite2D)
    └── Collision (CollisionShape2D)
```

**Specific Enemy (inherits Enemy.tscn):**
```
FastEnemy.tscn (inherits Enemy.tscn)
└── Override script to fast_enemy.gd
└── Change Sprite animations
└── Adjust speed values
```

**In code:**
```gdscript
# enemy_base.gd
extends CharacterBody2D
class_name Enemy

@export var speed = 100.0
@export var damage = 10.0

# fast_enemy.gd
extends Enemy  # Inherits from enemy_base.gd

func _ready():
    speed = 200.0  # Override
    damage = 5.0
```

## Performance Optimization Patterns

### Lazy Loading

```gdscript
var heavy_resource = null

func get_heavy_resource():
    if heavy_resource == null:
        heavy_resource = load("res://heavy_scene.tscn")
    return heavy_resource
```

### Visibility-Based Processing

```gdscript
extends Node2D

func _ready():
    visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
    set_physics_process(visible)
    set_process(visible)
```

### Distance-Based LOD (Level of Detail)

```gdscript
extends Enemy

@onready var player = get_tree().get_first_node_in_group("Player")
var update_rate = 1.0  # Update every frame by default

func _physics_process(delta):
    if player:
        var distance = global_position.distance_to(player.global_position)
        
        if distance > 1000:
            # Far away - disable
            set_physics_process(false)
        elif distance > 500:
            # Medium distance - update less frequently
            update_rate = 0.5
        else:
            # Close - full update
            update_rate = 1.0
```

## Common Scene Organization Mistakes

### ❌ Don't: Deeply nested node paths
```gdscript
var label = get_node("UI/Container/Panel/VBox/Label")
```

### ✅ Do: Use @onready and groups
```gdscript
@onready var label = $Label  # Direct child
var label = get_tree().get_first_node_in_group("score_label")
```

### ❌ Don't: God objects (one scene does everything)
```gdscript
# player.gd - 1000 lines of code
```

### ✅ Do: Composition with components
```gdscript
# player.gd - delegates to components
@onready var health = $HealthComponent
@onready var inventory = $InventoryComponent
@onready var movement = $MovementComponent
```

### ❌ Don't: Hardcode scene references
```gdscript
var enemy = load("res://scenes/enemies/goblin_v2_final.tscn")
```

### ✅ Do: Use exports and resources
```gdscript
@export var enemy_scene: PackedScene
var enemy = enemy_scene.instantiate()
```

## Advanced Patterns

### Player Persistence Across Scenes

**Problem:** Need player to persist when changing rooms/areas

**Solution 1: Root-Level Player**
```gdscript
# Main scene structure:
# Main
# ├── Player (persists)
# └── CurrentRoom (gets swapped)

# main.gd
func change_room(room_scene: PackedScene):
    if $CurrentRoom:
        $CurrentRoom.queue_free()
    var room = room_scene.instantiate()
    add_child(room)
    # Player stays at root, moves to room entrance
```

**Solution 2: Autoload Player Reference**
```gdscript
# Global.gd
var player: CharacterBody2D = null

# room.gd
func _ready():
    if Global.player == null:
        Global.player = PLAYER_SCENE.instantiate()
    add_child(Global.player)
    Global.player.position = $PlayerSpawn.position
```

### RemoteTransform for Relative Positioning

**Use case:** UI element follows world object

```gdscript
# Structure:
# Enemy
# └── HealthBarAnchor (Node2D)
#     └── RemoteTransform2D → points to GUI/HealthBars/EnemyHealth

# Setup
@onready var remote = $HealthBarAnchor/RemoteTransform2D

func _ready():
    var health_bar = get_tree().get_first_node_in_group("health_bars")
    remote.remote_path = health_bar.get_path()
    remote.update_position = true
    remote.update_rotation = false
    remote.update_scale = false
```

**Benefits:**
- UI element automatically follows world position
- No manual update code needed
- Works across different parent hierarchies

### Scenes vs Scripts Decision

**Use PackedScene when:**
- Game-specific content (player, enemy, level)
- Need visual editing in editor
- Performance matters (scenes instantiate faster)

**Use script classes when:**
- Reusable tool/utility (custom Resource, component)
- Library functionality
- No visual representation needed

```gdscript
# Tool/Library - Use script
class_name DamageCalculator extends RefCounted

static func calculate(base: int, armor: int) -> int:
    return max(1, base - armor)

# Game object - Use scene + script
# player.tscn with player.gd attached
```
