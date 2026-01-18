# Dialogue System

Complete reference for the dialogue system in Snufkin game.

## Overview

The dialogue system uses JSON files for dialogue data, an Area2D-based NPC interaction system, and a Control-based UI with camera transitions.

## Components

### 1. Dialogue Data (`dialague/moominMama.json`)

JSON array with name/text pairs:

```json
[
    {"name": "Moomin mama", "text": "Hello there!"},
    {"name": "Moomin mama", "text": "I love this place."},
    {"name": "Snufkin", "text": "Indeed, it's peaceful here."}
]
```

**Structure**:
- Array of dialogue entries
- Each entry has `name` (speaker) and `text` (dialogue line)
- No branches or choices currently

### 2. NPC Script (`npc.gd`)

Detects player proximity and triggers dialogue.

```gdscript
extends Area2D

@export var dialogue_control_path: NodePath
@export var npc_name: String = "Moomin mama"

var dialogue_control
var player_in_range = false

func _ready():
    dialogue_control = get_node(dialogue_control_path)

func _on_chat_detection_area_body_entered(body):
    if body.is_in_group("Player"):
        player_in_range = true

func _on_chat_detection_area_body_exited(body):
    if body.is_in_group("Player"):
        player_in_range = false

func _input(event):
    if event.is_action_pressed("interact"):
        if player_in_range and dialogue_control:
            dialogue_control.start_dialogue(self)
```

**Key Properties**:
- `dialogue_control_path` - NodePath to Dialogue Control node
- `npc_name` - Display name for this NPC
- `player_in_range` - Tracks player proximity

**Scene Setup**:
```
NPC (Area2D) - npc.gd
├── CollisionShape2D
└── Sprite2D (NPC visual)
```

Connect signals in editor:
- `body_entered` → `_on_chat_detection_area_body_entered`
- `body_exited` → `_on_chat_detection_area_body_exited`

### 3. Dialogue Controller (`dialogue.gd`)

Manages dialogue UI, camera transitions, and player control.

**Scene Structure**:
```
Dialogue (Control)
├── DialogueCamera (Camera2D)
├── LeftCharacter (TextureRect) - NPC sprite
├── RightCharacter (TextureRect) - Player sprite
├── NinePatchRect (dialogue box)
│   ├── Name (Label)
│   └── Text (Label)
└── UIButton (back button)
```

**Key Exports**:
```gdscript
@export var dialogue_file: String = "res://dialogue/moominMama.json"
```

**Key Variables**:
```gdscript
var dialogue = []                    # Loaded dialogue array
var current_dialogue_id = -1         # Current line index
var active_npc = null                # NPC we're talking to
var npc_sprite_path = {}             # NPC name → sprite mapping
var player_camera = null             # Reference to player camera
var player_node = null               # Reference to player
var player_camera_original_position = Vector2.ZERO
```

**NPC Sprite Mapping**:
```gdscript
npc_sprite_path = {
    "Moomin mama": preload("res://dialague/Images/idleSmokeing.png"),
}
```

## Dialogue Flow

### Starting Dialogue

```gdscript
func start_dialogue(npc):
    if active_npc:
        return  # Prevent multiple dialogues
    
    active_npc = npc
    load_dialogue()
    
    if dialogue == null or dialogue.size() == 0:
        return
    
    current_dialogue_id = -1
    
    # Setup UI
    visible = true
    back_button.visible = true
    
    # Update character sprites
    if npc.npc_name in npc_sprite_path:
        left_character.texture = npc_sprite_path[npc.npc_name]
        left_character.visible = true
    right_character.visible = true
    
    # Camera transition
    if player_camera and player_camera is Camera2D:
        player_camera_original_position = player_camera.position
        
        var tween = get_tree().create_tween()
        tween.set_ease(Tween.EASE_IN_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(player_camera, "position", dialogue_camera.position, 0.5)
        await tween.finished
        
        dialogue_camera.make_current()
    
    # Disable player movement
    if player_node:
        player_node.set_physics_process(false)
        player_node.set_process_input(false)
        
        if "velocity" in player_node:
            player_node.velocity = Vector2.ZERO
            player_node.move_and_slide()
    
    z_index = 100
    next_script()
```

**Steps**:
1. Check for existing dialogue (prevent overlap)
2. Load dialogue JSON
3. Show UI elements
4. Set character sprites
5. Tween camera to dialogue position (0.5s)
6. Switch to dialogue camera
7. Disable player physics and input
8. Set high z_index (render on top)
9. Display first line

### Advancing Dialogue

```gdscript
func _input(event):
    if event.is_action_pressed("ui_accept") and visible:
        next_script()
    elif event.is_action_pressed("ui_cancel") and visible:
        end_dialogue()

func next_script():
    current_dialogue_id += 1
    if current_dialogue_id >= len(dialogue):
        end_dialogue()
        return
    
    if "name" in dialogue[current_dialogue_id] and "text" in dialogue[current_dialogue_id]:
        name_label.text = dialogue[current_dialogue_id]['name']
        text_label.text = dialogue[current_dialogue_id]['text']
    else:
        print("Error: Missing 'name' or 'text' in dialogue entry!")
```

**Controls**:
- `ui_accept` (Space) - Next line
- `ui_cancel` (ESC) - Exit dialogue

### Ending Dialogue

```gdscript
func end_dialogue():
    if not visible:
        return
    
    # Hide UI elements
    visible = false
    back_button.visible = false
    left_character.visible = false
    right_character.visible = false
    
    # Reset dialogue state
    active_npc = null
    current_dialogue_id = -1
    
    # Restore player camera
    player_camera = get_tree().get_first_node_in_group("player_camera")
    if player_camera and player_camera is Camera2D:
        player_camera.make_current()
        
        # Smooth camera transition back
        var tween = get_tree().create_tween()
        tween.set_ease(Tween.EASE_IN_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(player_camera, "position", player_camera_original_position, 0.5)
        await tween.finished
    
    # Re-enable player movement
    if player_node:
        player_node.set_physics_process(true)
        player_node.set_process_input(true)
    
    get_tree().paused = false
```

**Steps**:
1. Hide all UI elements
2. Reset state variables
3. Switch back to player camera
4. Tween camera back (0.5s)
5. Re-enable player physics and input
6. Unpause game

## Camera System

### Camera Positions

**Player Camera**:
- Attached to player as child
- Follows player movement
- In group "player_camera"

**Dialogue Camera**:
- Fixed position in dialogue scene
- Positioned to frame both characters
- Made current during dialogue

### Camera Transition

```gdscript
# Save original position
player_camera_original_position = player_camera.position

# Tween to dialogue position
var tween = get_tree().create_tween()
tween.set_ease(Tween.EASE_IN_OUT)
tween.set_trans(Tween.TRANS_CUBIC)
tween.tween_property(player_camera, "position", dialogue_camera.position, 0.5)
await tween.finished

# Switch active camera
dialogue_camera.make_current()
```

**Why tween player_camera.position?**
- Smooth visual transition
- Player camera remains technically active during tween
- Then dialogue camera takes over

## Adding New NPCs

### 1. Create NPC Scene

Instance `npc.tscn` or create new:

```
NewNPC (Area2D) - npc.gd
├── CollisionShape2D
└── Sprite2D
```

### 2. Configure NPC

In Inspector:
- Set `npc_name` to NPC identifier
- Set `dialogue_control_path` to dialogue Control node
- Connect `body_entered` and `body_exited` signals

### 3. Create Dialogue JSON

Create `res://dialogue/new_npc.json`:

```json
[
    {"name": "New NPC", "text": "Hello traveler!"},
    {"name": "New NPC", "text": "Welcome to my shop."},
    {"name": "Snufkin", "text": "Thanks!"}
]
```

### 4. Add NPC Sprite

In `dialogue.gd`, add to `npc_sprite_path`:

```gdscript
npc_sprite_path = {
    "Moomin mama": preload("res://dialague/Images/idleSmokeing.png"),
    "New NPC": preload("res://dialague/Images/new_npc.png"),
}
```

### 5. Update Dialogue File Path

For multiple NPCs, use different dialogue files:

**Option A**: Per-NPC dialogue files
- Modify `dialogue.gd` to accept dynamic file path
- Pass file path from NPC

**Option B**: Single file with branches
- Use NPC name to filter dialogue
- Current implementation uses single file per dialogue controller

## Extending the System

### Adding Dialogue Choices

Modify JSON structure:

```json
[
    {
        "name": "NPC",
        "text": "What would you like?",
        "choices": [
            {"text": "Ask about quest", "next": 1},
            {"text": "Say goodbye", "next": -1}
        ]
    },
    {
        "name": "NPC",
        "text": "Here's the quest..."
    }
]
```

Update `dialogue.gd`:
- Detect `choices` field
- Show buttons instead of advancing
- Jump to `next` index on choice

### Adding Character Portraits

Currently uses static textures. For animated portraits:

```gdscript
# Use AnimatedSprite2D instead of TextureRect
@onready var left_character = $LeftCharacter  # AnimatedSprite2D

# In start_dialogue()
left_character.play("talking")
```

### Adding Text Effects

Use RichTextLabel instead of Label:

```gdscript
@onready var text_label = $NinePatchRect/RichTextLabel

# In next_script()
text_label.bbcode_enabled = true
text_label.text = "[wave]Hello![/wave]"
```

### Adding Sound Effects

```gdscript
@onready var dialogue_sound = $DialogueSound

func next_script():
    current_dialogue_id += 1
    # ... existing code ...
    
    # Play sound
    dialogue_sound.play()
```

## Common Issues

### Dialogue Doesn't Start

**Check**:
- NPC `dialogue_control_path` is set correctly
- Dialogue Control node exists in scene
- Player is in group "Player"
- JSON file path is correct

### Player Can Move During Dialogue

**Ensure**:
- `player_node.set_physics_process(false)` is called
- `player_node.set_process_input(false)` is called
- Both are re-enabled in `end_dialogue()`

### Camera Doesn't Transition

**Check**:
- Player camera is in group "player_camera"
- Dialogue camera exists and positioned correctly
- Tween completes before switching cameras

### JSON Parse Error

**Validate**:
- JSON syntax is correct (use JSON validator)
- All entries have both "name" and "text"
- No trailing commas
- Proper escape characters for quotes in text
