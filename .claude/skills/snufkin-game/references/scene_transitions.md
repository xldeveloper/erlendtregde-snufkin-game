# Scene Transitions

Complete guide for scene transitions in Snufkin game.

## Architecture

The game uses a simple but effective scene transition system:
1. Save player position before transition
2. Load target scene
3. Restore player position (if applicable)

## Global State Management

**Autoload**: `Global.gd` (res://scripts/global.gd)

```gdscript
extends Node

var saved_position = Vector2.ZERO

func save_position(new_position):
    saved_position = new_position

func get_saved_position():
    return saved_position
```

**Purpose**:
- Persist player position across scene changes
- Accessible from any script via `Global`
- Resets to `Vector2.ZERO` when unused

## Scene Graph

```
main.tscn (overworld)
├──[Enter House]──→ house_interior.tscn ──[Exit]──┐
└──[Fish Zone]────→ fishing_scene.tscn ──[Exit]──┤
                                                  ↓
                                             main.tscn (restored position)
```

## Transition Types

### Type 1: Enter New Area (Save Position)

Used when entering house or fishing zone from main world.

**Pattern**: Area2D with interaction trigger

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
    if entered and Input.is_action_just_pressed("interact"):
        if player_character_body:
            Global.save_position(player_character_body.global_position)
        
        get_tree().change_scene_to_file("res://scenes/TARGET_SCENE.tscn")
```

**Key Points**:
- Shows prompt label when player in range
- Waits for "interact" action (E key)
- Saves position BEFORE scene change
- Uses `player_character_body` (the CharacterBody2D)
- Changes scene with `get_tree().change_scene_to_file()`

**Examples**:
- `HouseInteraction.gd` → `house_interior.tscn`
- `FishingInteraction.gd` → `fishing_scene.tscn`

### Type 2: Return to Main World (Restore Position)

Used when exiting house or fishing zone.

**Pattern**: Area2D without saving position

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
    if entered and Input.is_action_just_pressed("interact"):
        # DON'T save position - use previously saved one
        get_tree().change_scene_to_file("res://scenes/main.tscn")
```

**Key Points**:
- Does NOT call `Global.save_position()`
- Returns to saved position from before entering
- Shows exit prompt label

**Examples**:
- `ExitHouse.gd` → `main.tscn`
- `stop_fishing_button.gd` → `main.tscn` (UI button version)

## Player Position Restoration

In `character_body_2d.gd` (_ready function):

```gdscript
func _ready():
    await get_tree().process_frame  # Wait for scene to fully load
    
    # Check current scene
    var current_scene = get_tree().current_scene.name
    if current_scene == "HouseInterior":
        pass  # Use default spawn position
    else:
        var saved_pos = Global.get_saved_position()
        if saved_pos != Vector2.ZERO:
            global_position = saved_pos
```

**Logic**:
1. Wait one frame to ensure scene tree is ready
2. Check scene name
3. **House Interior**: Use default position (don't restore)
4. **Other scenes**: Restore from `Global` if position exists

**Why wait one frame?**
- Ensures all nodes are instantiated
- Prevents timing issues with position setting
- Use `await get_tree().process_frame` (Godot 4.x)

## Scene-Specific Handling

### House Interior

**Controller**: `HouseInteriorController.gd`

```gdscript
extends Node2D

func _ready():
    var player = $Player
    
    # Disable player's camera
    var player_camera = get_tree().get_first_node_in_group("player_camera")
    if player_camera:
        player_camera.enabled = false
    
    # Enable house camera
    var house_camera = $Camera2D
    if house_camera:
        house_camera.enabled = true
        house_camera.make_current()
```

**Special Behavior**:
- Player spawns at predefined position (not restored)
- Player's camera disabled
- House scene camera takes over
- Allows interior-specific camera framing

### Fishing Scene

**Controller**: `fishing_player.gd`

```gdscript
extends Node2D

var saved_position = Vector2.ZERO

func save_position(new_position):
    saved_position = new_position

func get_saved_position():
    return saved_position
```

**Special Behavior**:
- Separate local position management
- Different control scheme (fishing mechanics)
- Different camera setup

### Main World

**Default behavior**: Always restore from `Global.saved_position`

**Player spawning**:
- If returning from house/fishing: Restores to saved position
- If fresh scene load: Uses default position (Vector2.ZERO check)

## Implementation Checklist

### Creating New Entrance

1. **Create Area2D node** in source scene
   - Add CollisionShape2D
   - Add Label child (for prompt)

2. **Attach interaction script**:
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
    if entered and Input.is_action_just_pressed("interact"):
        if player_character_body:
            Global.save_position(player_character_body.global_position)
        get_tree().change_scene_to_file("res://scenes/target.tscn")
```

3. **Connect signals** in editor:
   - `body_entered` → `_on_body_entered`
   - `body_exited` → `_on_body_exited`

4. **Set label text**: "Press E to Enter"

5. **Configure collision layer**:
   - Layer: Environment/Triggers
   - Mask: Player

### Creating New Exit

1. **Create Area2D node** in target scene

2. **Attach exit script**:
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
    if entered and Input.is_action_just_pressed("interact"):
        # DON'T save position
        get_tree().change_scene_to_file("res://scenes/main.tscn")
```

3. **Set label text**: "Press E to Exit"

4. **Position near entry point** (door, edge of map, etc.)

## Common Patterns

### UI Button Exit

For exiting via button instead of Area2D:

```gdscript
extends Button

func _ready():
    pressed.connect(_on_pressed)

func _on_pressed():
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

**Example**: `stop_fishing_button.gd`

### Multiple Exits to Same Scene

All exits go to same scene (main.tscn), position restored automatically.

No need to track which entrance was used - player returns to where they entered.

### Entrance with Custom Position

Override position restoration for specific spawn points:

```gdscript
# In target scene's controller
func _ready():
    var player = $Player
    player.global_position = Vector2(500, 300)  # Custom spawn
```

## Debugging

### Position Not Saving

**Check**:
- `Global.save_position()` called before `change_scene_to_file()`
- Player reference is valid (`player_character_body != null`)
- Using `global_position`, not `position`

### Position Not Restoring

**Check**:
- `await get_tree().process_frame` in player's `_ready()`
- Scene name check is correct
- `Vector2.ZERO` check works as expected
- Using `global_position` for restoration

### Wrong Spawn Position

**Check**:
- Scene name in if-statement matches actual scene name
- No other script overriding position
- Position saved is correct (print debug value)

### Player Appears at Origin

**Cause**: Position restored as `Vector2.ZERO`

**Fix**:
- Ensure position was saved before transition
- Check `Global.saved_position` isn't being reset
- Verify scene name check logic

## Best Practices

1. **Always save before transition** (except exits)
2. **Wait one frame before checking position**
3. **Use groups for player detection** (`"Player"`)
4. **Cache player reference** in Area2D scripts
5. **Show/hide prompt labels** for user feedback
6. **Use global_position** for world-space coordinates
7. **Don't save on exits** - return to previous position
8. **Handle null checks** before accessing player

## Advanced: Transition with Fade

Not currently implemented, but pattern for smooth transitions:

```gdscript
extends Area2D

@onready var fade = $CanvasLayer/ColorRect

func _process(_delta):
    if entered and Input.is_action_just_pressed("interact"):
        if player_character_body:
            Global.save_position(player_character_body.global_position)
        
        # Fade out
        var tween = create_tween()
        tween.tween_property(fade, "modulate:a", 1.0, 0.5)
        await tween.finished
        
        # Change scene
        get_tree().change_scene_to_file("res://scenes/target.tscn")
```

For fade-in, add to target scene's `_ready()`.
