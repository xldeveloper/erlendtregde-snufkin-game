# Fishing System

Complete reference for the fishing minigame mechanics.

## Overview

The fishing system is a separate scene (`fishing_scene.tscn`) with custom controls for casting, catching fish, and scoring.

## Scene Structure

```
FishingScene (Node2D)
├── FishingPlayer (Node2D) - fishing_player.gd
│   ├── Hook (Area2D) - hook.gd
│   └── Sprite/Visual elements
├── FishSpawner (Node2D) - fish_spawner.gd
├── UI (CanvasLayer)
│   ├── ScoreLabel
│   ├── StopFishingButton
│   └── FishingUI - fishing_ui.gd
└── Water/Background elements
```

## Core Components

### FishingPlayer (`fishing_player.gd`)

Main fishing controller that manages the rod and line.

```gdscript
extends Node2D

@onready var hook = $Hook
var saved_position = Vector2.ZERO
var last_hook_position = Vector2.ZERO

func _input(event):
    if event.is_action_pressed("cast_hook"):
        hook.cast_hook()

func _process(_delta):
    # Redraw line only when hook moves
    if hook and hook.position != last_hook_position:
        last_hook_position = hook.position
        queue_redraw()

func _draw():
    if hook:
        var start_pos = Vector2(0, 0)  # Rod position (relative)
        var end_pos = hook.position     # Hook position (relative)
        draw_line(start_pos, end_pos, Color(1, 1, 1), 2)
```

**Key Features**:
- Draws fishing line from rod to hook
- Only redraws when hook position changes (performance)
- Listens for "cast_hook" input (Space)
- Manages local position state

### Hook (`hook.gd`)

The fishing hook that moves and catches fish.

**Typical Pattern**:
```gdscript
extends Area2D

@export var cast_speed = 500.0
@export var reel_speed = 300.0
var is_cast = false
var is_reeling = false

func cast_hook():
    if not is_cast:
        is_cast = true
        # Start moving downward
        
func reel_in():
    is_reeling = true
    # Move back to start

func _physics_process(delta):
    if is_cast and not is_reeling:
        # Move hook down/out
        position.y += cast_speed * delta
    elif is_reeling:
        # Move hook back to rod
        position = position.move_toward(Vector2.ZERO, reel_speed * delta)

func _on_area_entered(area):
    if area.is_in_group("fish"):
        # Catch fish logic
        area.catch()
```

**Hook Signals**:
- Detects fish via Area2D overlap
- Can be grabbed/controlled with input

### Fish (`fish.gd`)

Individual fish that swim around and can be caught.

**Common Pattern**:
```gdscript
extends Area2D

@export var swim_speed = 100.0
@export var points = 10
var direction = Vector2.RIGHT
var is_caught = false

func _physics_process(delta):
    if not is_caught:
        position += direction * swim_speed * delta
        
        # Simple boundary wrap or direction change
        if position.x > boundary:
            direction = -direction
            $Sprite.flip_h = !$Sprite.flip_h

func catch():
    if not is_caught:
        is_caught = true
        # Add score
        Global.score += points
        # Play animation/effect
        queue_free()
```

### FishSpawner (`fish_spawner.gd`)

Spawns fish at intervals.

**Pattern**:
```gdscript
extends Node2D

@export var fish_scene: PackedScene
@export var spawn_interval = 2.0
@export var max_fish = 10

var spawn_timer = 0.0
var current_fish_count = 0

func _process(delta):
    spawn_timer += delta
    
    if spawn_timer >= spawn_interval and current_fish_count < max_fish:
        spawn_fish()
        spawn_timer = 0.0

func spawn_fish():
    var fish = fish_scene.instantiate()
    fish.global_position = get_spawn_position()
    add_child(fish)
    current_fish_count += 1
    
    fish.tree_exiting.connect(_on_fish_removed)

func _on_fish_removed():
    current_fish_count -= 1

func get_spawn_position() -> Vector2:
    # Random position logic
    return Vector2(randf_range(100, 900), randf_range(200, 500))
```

### FishingUI (`fishing_ui.gd`)

Manages UI elements (score, instructions, buttons).

**Pattern**:
```gdscript
extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var instruction_label = $InstructionLabel

func _ready():
    update_score(0)
    show_instruction("Press SPACE to cast")

func update_score(new_score):
    score_label.text = "Score: " + str(new_score)

func show_instruction(text):
    instruction_label.text = text
```

### StopFishingButton (`stop_fishing_button.gd`)

Exit button to return to main world.

```gdscript
extends Button

func _ready():
    pressed.connect(_on_pressed)

func _on_pressed():
    # Return to main world without saving position
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

## Input Actions

Fishing-specific actions (from project.godot):

```
cast_hook  - Space  (cast the hook)
catch_fish - Enter  (reel in / catch)
```

## Fishing Flow

### 1. Entering Fishing Scene

From `FishingInteraction.gd` in main world:

```gdscript
func _process(_delta):
    if entered and Input.is_action_just_pressed("interact"):
        if player_character_body:
            Global.save_position(player_character_body.global_position)
        
        get_tree().change_scene_to_file("res://scenes/fishing_scene.tscn")
```

### 2. Fishing Gameplay Loop

1. Player presses **Space** to cast hook
2. Hook moves downward/outward
3. Fish swim in area
4. Hook overlaps fish → fish caught
5. Score increases
6. Continue fishing or exit

### 3. Exiting Fishing Scene

Player clicks "Stop Fishing" button → returns to main world at saved position.

## Scoring System

**Current Implementation**:
- Each fish has `points` value
- Score tracked globally or in fishing scene
- Displayed in UI

**Typical Pattern**:
```gdscript
# Global.gd (add to autoload)
var fishing_score = 0

func reset_fishing_score():
    fishing_score = 0

# fish.gd
func catch():
    Global.fishing_score += points
    # Update UI
    get_node("/root/FishingScene/UI").update_score(Global.fishing_score)
```

## Fish Types

**Extendable Pattern**: Different fish with varying difficulty

```gdscript
# fast_fish.gd (extends Fish)
extends Area2D  # base fish script

func _ready():
    swim_speed = 200.0  # Faster
    points = 20         # More points
```

## Hook Movement Patterns

### Pattern 1: Simple Vertical Cast

```gdscript
func _physics_process(delta):
    if is_cast:
        position.y += cast_speed * delta
        
        if position.y > max_depth:
            reel_in()
```

### Pattern 2: Player-Controlled Hook

```gdscript
func _physics_process(delta):
    if is_cast:
        var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
        position += input * cast_speed * delta
```

### Pattern 3: Physics-Based Hook

```gdscript
extends RigidBody2D

func cast_hook():
    apply_impulse(Vector2(0, 500))  # Downward force

func reel_in():
    apply_impulse(Vector2(0, -500))  # Upward force
```

## Visual Effects

### Fishing Line

Drawn in `FishingPlayer._draw()`:

```gdscript
func _draw():
    if hook:
        draw_line(Vector2.ZERO, hook.position, Color.WHITE, 2)
```

**Enhancements**:
- Curved line (using draw_polyline)
- Line tension based on fish weight
- Line color changes when fish hooked

### Water Ripples

Add particles when hook enters water:

```gdscript
# hook.gd
@onready var splash_particles = $GPUParticles2D

func _physics_process(delta):
    if just_entered_water:
        splash_particles.emitting = true
```

### Fish Animation

```gdscript
# fish.gd
@onready var sprite = $AnimatedSprite2D

func _ready():
    sprite.play("swim")

func catch():
    sprite.play("caught")
    await sprite.animation_finished
    queue_free()
```

## Advanced Features

### Fishing Zone

Restrict where fish can be caught:

```gdscript
# FishingZone.gd
extends Area2D

var hook_in_zone = false

func _on_area_entered(area):
    if area.is_in_group("hook"):
        hook_in_zone = true

func _on_area_exited(area):
    if area.is_in_group("hook"):
        hook_in_zone = false

# hook.gd
func check_catch():
    var fishing_zone = get_tree().get_first_node_in_group("fishing_zone")
    if fishing_zone and fishing_zone.hook_in_zone:
        # Can catch fish
        pass
```

### Fish AI Behaviors

```gdscript
# smart_fish.gd
extends Area2D

@export var flee_distance = 100.0
var hook = null

func _ready():
    hook = get_tree().get_first_node_in_group("hook")

func _physics_process(delta):
    if hook:
        var distance = global_position.distance_to(hook.global_position)
        
        if distance < flee_distance:
            # Flee from hook
            var flee_direction = (global_position - hook.global_position).normalized()
            position += flee_direction * swim_speed * delta
        else:
            # Normal swimming
            position += direction * swim_speed * delta
```

### Combo System

Catch multiple fish quickly for bonus points:

```gdscript
# fishing_ui.gd
var combo = 0
var combo_timer = 0.0
const COMBO_WINDOW = 3.0

func _process(delta):
    if combo > 0:
        combo_timer -= delta
        if combo_timer <= 0:
            reset_combo()

func fish_caught(points):
    combo += 1
    combo_timer = COMBO_WINDOW
    
    var bonus = points * combo
    Global.fishing_score += bonus
    
    update_combo_display()

func reset_combo():
    combo = 0
    update_combo_display()
```

## Common Issues

### Hook Not Catching Fish

**Check**:
- Hook is in group "hook"
- Fish is in group "fish"
- Collision layers/masks set correctly
- `_on_area_entered` signal connected

### Line Not Drawing

**Check**:
- `queue_redraw()` called when hook moves
- `_draw()` function implemented
- Hook reference is valid

### Fish Spawn Continuously

**Check**:
- `max_fish` limit enforced
- Fish removed from count when freed
- `tree_exiting` signal connected

### Can't Exit Fishing Scene

**Check**:
- Stop button visible and enabled
- Button script changes scene correctly
- Scene path is correct

## Best Practices

1. **Use groups** for hook/fish detection
2. **Optimize drawing** - only redraw when hook moves
3. **Track fish count** to limit spawning
4. **Cache references** (hook, spawner) in `_ready()`
5. **Use signals** for fish caught events
6. **Pool fish objects** if spawning many
7. **Add visual feedback** (splash, ripples, animations)
8. **Test collision layers** carefully

## Future Enhancements

- Different fish species with behaviors
- Power-ups (faster reel, larger hook area)
- Fishing rod upgrades
- Daily challenges
- Leaderboards
- Weather effects affecting difficulty
- Rare/legendary fish
