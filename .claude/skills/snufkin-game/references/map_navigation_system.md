# Map Navigation System

## Overview
The map navigation system allows players to travel between locations in Moominvalley using an interactive map with a draggable Snufkin character.

## Core Components

### Map Scene (`scenes/map_scene.tscn`)
- **MapBackground**: Sprite2D displaying the full valley map (fullmap.png)
- **Camera2D**: Zoomed view (0.7x) for better visibility
- **DraggableSnufkin**: Area2D node that can be dragged with right-click
- **Location Markers**: Three clickable areas (Tent, Moomin House, Bridge)

### Map Controller (`scripts/map_controller.gd`)
```gdscript
extends Camera2D

func _ready():
    make_current()
    zoom = Vector2(0.7, 0.7)
    await get_tree().process_frame
    position_snufkin()

func position_snufkin():
    var snufkin = get_tree().current_scene.get_node_or_null("DraggableSnufkin")
    if not snufkin:
        return
    
    # Position based on Global.current_location
    match Global.current_location:
        "tent":
            snufkin.position = Vector2(108, 203)
        "moomin_house":
            snufkin.position = Vector2(-239, 547)
        "bridge":
            snufkin.position = Vector2(290, 134)

func return_to_previous_scene():
    if Global.previous_scene != "":
        var scene_path = Global.previous_scene
        Global.previous_scene = ""
        Global.from_scene = ""
        get_tree().change_scene_to_file(scene_path)
```

### Draggable Snufkin (`scripts/draggable_snufkin.gd`)
- **Right-click drag**: Move Snufkin around the map
- **Left-click**: Enter location when hovering over a marker
- **Hover detection**: Shows location names and highlights markers

Key functions:
```gdscript
func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            if event.pressed:
                is_dragging = true
                drag_offset = position - get_global_mouse_position()
        elif event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed and not is_dragging:
                if current_location:
                    enter_location()

func enter_location():
    # Sets Global.from_scene to "map_tent", "map_moomin", or "map_bridge"
    Global.from_scene = location_scene_id
    get_tree().change_scene_to_file(target_scene)
```

### Map Locations (`scripts/map_location.gd`)
- **Hover effects**: Shows location name label and focused texture
- **Area2D detection**: Tracks when Snufkin is over the location
- **Visual feedback**: Labels render with z_index 400 (above everything)

Properties:
- `location_name`: Display name (e.g., "Tent")
- `target_scene_path`: Scene to load (e.g., "res://scenes/main.tscn")
- `focused_texture`: Image shown on hover

### Map Opener (`scripts/map_opener.gd`)
Universal script attached to all gameplay scenes to open the map.

```gdscript
func _input(event):
    if not is_inside_tree():
        return
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_M:
            open_map()

func open_map():
    var player = get_tree().get_first_node_in_group("Player")
    if player:
        # Handle Node2D container with CharacterBody2D child
        if player is Node2D and not player is CharacterBody2D:
            var character_body = player.get_node_or_null("CharacterBody2D")
            if character_body:
                player = character_body
        
        Global.saved_player_position = player.global_position
    
    Global.previous_scene = get_tree().current_scene.scene_file_path
    Global.saved_position_scene = Global.previous_scene
    get_tree().change_scene_to_file("res://scenes/map_scene.tscn")
```

### Location Tracker (`scripts/location_tracker.gd`)
Tracks player location in Main scene based on X position.

```gdscript
func update_player_location():
    var player_x = player.global_position.x
    
    var new_location = ""
    if player_x >= -2000 and player_x < 0:  # Bridge area
        new_location = "bridge"
    elif player_x >= 2000 and player_x < 3000:  # Moomin House area
        new_location = "moomin_house"
    elif player_x >= 0 and player_x < 1500:  # Tent area
        new_location = "tent"
    
    if new_location != "" and Global.current_location != new_location:
        Global.current_location = new_location
```

## Global State Variables

```gdscript
# scripts/global.gd
var from_scene = ""  # Tracks transition type
var current_location = "tent"  # Current map location
var previous_scene = ""  # Scene to return to after map closes
var saved_player_position = Vector2.ZERO  # Player position before map
var saved_position_scene = ""  # Which scene position belongs to
```

## Position Management

### Spawn Priority System (`scripts/character_body_2d.gd`)
1. **Priority 1**: Restore saved position if returning to same scene
2. **Priority 2**: from_scene "house_interior" or "fishing_scene"
3. **Priority 3**: from_scene "map_tent", "map_moomin", or "map_bridge"
4. **Priority 4**: Default spawn with location detection

```gdscript
func _ready():
    await get_tree().process_frame
    
    var current_scene_path = get_tree().current_scene.scene_file_path
    
    if Global.saved_player_position != Vector2.ZERO and Global.saved_position_scene == current_scene_path:
        global_position = Global.saved_player_position
        Global.saved_player_position = Vector2.ZERO
        Global.saved_position_scene = ""
        Global.from_scene = ""
    elif Global.from_scene == "house_interior":
        global_position = Vector2(2588, 921)
        Global.current_location = "moomin_house"
        # Clear globals...
    # ... other priorities
```

## Key User Flows

### Opening Map from Gameplay
1. Player presses M in any scene (Main, house_interior, fishing_scene)
2. MapOpener saves player position and current scene path
3. Scene changes to map_scene.tscn
4. MapController positions DraggableSnufkin at current_location
5. Player can drag Snufkin or press Esc to return

### Traveling to New Location
1. Player drags Snufkin over a location marker
2. Location name appears (hover label)
3. Player left-clicks on Snufkin
4. from_scene is set to "map_tent", "map_moomin", or "map_bridge"
5. Scene changes to target (Main, house_interior, or fishing_scene)
6. Player spawns at fixed location spawn point

### Returning from Map (Esc)
1. Player presses Esc in map_scene
2. MapController calls return_to_previous_scene()
3. Clears from_scene to enable position restoration
4. Returns to previous_scene
5. Player spawns at exact saved_player_position

## Integration Points

### Adding MapOpener to New Scenes
```gdscript
# Add as Node child in scene tree
[node name="MapOpener" type="Node" parent="."]
script = ExtResource("map_opener_script")
```

### Adding LocationTracker to Main Scene
```gdscript
# Only needed in main.tscn
[node name="LocationTracker" type="Node" parent="."]
script = ExtResource("location_tracker_script")
```

### Setting Location on Scene Transitions
```gdscript
# In scene transition scripts (e.g., ExitHouse.gd)
Global.current_location = "moomin_house"
Global.from_scene = "house_interior"
get_tree().change_scene_to_file("res://scenes/main.tscn")
```

## Map Coordinates Reference

### Location Node Positions (map_scene.tscn)
- **TentLocation**: Vector2(108, 203)
- **MoominHouseLocation**: Vector2(-239, 547)
- **BridgeLocation**: Vector2(290, 134)

### Spawn Positions (main.tscn)
- **Tent spawn**: Vector2(108, 1100)
- **Moomin House spawn**: Vector2(2588, 921)
- **Bridge spawn**: Vector2(-1470, 1114)

### Detection Ranges (Main scene X coordinates)
- **Tent**: X between 0 and 1500
- **Moomin House**: X between 2000 and 3000
- **Bridge**: X between -2000 and 0

## Best Practices

1. **Always use exact positions**: Match DraggableSnufkin position to actual location node positions
2. **Clear globals properly**: Always clear from_scene and saved_position_scene after use
3. **Handle Node2D containers**: Check if Player is a container with CharacterBody2D child
4. **Add timing delays**: Use `await get_tree().process_frame` for proper initialization
5. **Safety checks**: Always check `is_inside_tree()` before processing input

## Common Issues

### DraggableSnufkin Not Positioning Correctly
- **Cause**: Position reset in _ready() before MapController positions it
- **Solution**: Remove any position initialization in draggable_snufkin.gd _ready()

### Position Not Restoring on Esc
- **Cause**: from_scene not cleared when returning from map
- **Solution**: Set `Global.from_scene = ""` in return_to_previous_scene()

### Player Spawning at Wrong Location
- **Cause**: LocationTracker runs too early or spawn positions incorrect
- **Solution**: Add 0.2s delay to LocationTracker, verify spawn coordinates

### Map Not Showing Player Position
- **Cause**: Player node is Node2D container, not CharacterBody2D
- **Solution**: Check for container and get CharacterBody2D child in MapOpener
