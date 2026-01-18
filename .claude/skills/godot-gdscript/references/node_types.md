# Node Types Reference

Comprehensive reference for commonly used Godot node types.

## Table of Contents

- [2D Physics Nodes](#2d-physics-nodes)
- [2D Visual Nodes](#2d-visual-nodes)
- [Control Nodes (UI)](#control-nodes-ui)
- [Audio Nodes](#audio-nodes)
- [Utility Nodes](#utility-nodes)

## 2D Physics Nodes

### CharacterBody2D

Player and NPC movement with collision detection. Best for characters with complex movement.

**Key Properties:**
- `velocity: Vector2` - Current movement velocity
- `motion_mode` - MOTION_MODE_GROUNDED or MOTION_MODE_FLOATING
- `floor_stop_on_slope` - Prevent sliding down slopes
- `floor_max_angle` - Maximum walkable slope angle

**Key Methods:**
- `move_and_slide()` - Apply velocity and handle collisions
- `is_on_floor()` - Check if touching ground
- `is_on_wall()` - Check if touching wall
- `is_on_ceiling()` - Check if touching ceiling
- `get_floor_normal()` - Get normal of floor surface
- `get_slide_collision(index)` - Get collision information

**Example:**
```gdscript
extends CharacterBody2D

const SPEED = 300.0
const GRAVITY = 980.0

func _physics_process(delta):
    velocity.y += GRAVITY * delta
    var direction = Input.get_axis("ui_left", "ui_right")
    velocity.x = direction * SPEED
    move_and_slide()
```

### RigidBody2D

Physics-based objects with realistic movement (falling, bouncing, forces).

**Key Properties:**
- `mass` - Object weight
- `gravity_scale` - Multiplier for global gravity
- `linear_velocity` - Current velocity
- `angular_velocity` - Current rotation speed
- `lock_rotation` - Prevent rotation

**Key Methods:**
- `apply_force(force, offset)` - Apply force at position
- `apply_central_force(force)` - Apply force at center
- `apply_impulse(impulse, offset)` - Instant velocity change

### Area2D

Trigger zones, detection areas, hitboxes. No collision response, only detection.

**Key Signals:**
- `body_entered(body)` - When physics body enters
- `body_exited(body)` - When physics body exits
- `area_entered(area)` - When another Area2D enters
- `area_exited(area)` - When another Area2D exits

**Key Properties:**
- `monitoring` - Detect other bodies/areas
- `monitorable` - Can be detected by other areas
- `priority` - For overlapping areas

**Common Pattern:**
```gdscript
extends Area2D

var player_inside = false

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.is_in_group("Player"):
        player_inside = true

func _on_body_exited(body):
    if body.is_in_group("Player"):
        player_inside = false
```

### StaticBody2D

Immovable collision objects (walls, floors, platforms).

**Key Properties:**
- `constant_linear_velocity` - Moving platforms
- `constant_angular_velocity` - Rotating platforms

### CollisionShape2D / CollisionPolygon2D

Define collision boundaries. Must be child of physics body.

**Key Properties:**
- `shape` - RectangleShape2D, CircleShape2D, CapsuleShape2D, etc.
- `disabled` - Enable/disable collision

## 2D Visual Nodes

### Sprite2D

Display single image.

**Key Properties:**
- `texture` - Image resource
- `flip_h` / `flip_v` - Flip horizontal/vertical
- `offset` - Texture offset
- `modulate` - Color tint

### AnimatedSprite2D

Play sprite animations (frame-based).

**Key Methods:**
- `play(name)` - Play animation
- `stop()` - Stop animation
- `set_frame(frame)` - Jump to frame

**Key Signals:**
- `animation_finished` - When animation completes
- `frame_changed` - When frame changes

**Key Properties:**
- `sprite_frames` - SpriteFrames resource with animations
- `animation` - Current animation name
- `frame` - Current frame index
- `speed_scale` - Animation speed multiplier

**Example:**
```gdscript
@onready var sprite = $AnimatedSprite2D

func _ready():
    sprite.play("idle")
    sprite.animation_finished.connect(_on_animation_finished)

func attack():
    sprite.play("attack")
    await sprite.animation_finished
    sprite.play("idle")
```

### Line2D

Draw connected line segments.

**Key Properties:**
- `points` - Array of Vector2 positions
- `width` - Line thickness
- `default_color` - Line color

**Example:**
```gdscript
@onready var line = $Line2D

func _ready():
    line.points = [Vector2(0, 0), Vector2(100, 50), Vector2(200, 0)]
    line.width = 5.0
    line.default_color = Color.RED
```

### GPUParticles2D

Hardware-accelerated particle effects (fire, smoke, rain).

**Key Properties:**
- `amount` - Number of particles
- `lifetime` - How long each particle lives
- `process_material` - ParticleProcessMaterial for behavior
- `emitting` - Start/stop emission

**Requires ParticleProcessMaterial** for behavior (gravity, velocity, color over lifetime).

### CanvasLayer

UI layer that stays on screen (HUD, menus). Doesn't move with camera.

**Key Properties:**
- `layer` - Draw order (higher = on top)
- `follow_viewport_enabled` - Follow camera
- `offset` - Layer offset

## Control Nodes (UI)

### Control

Base class for all UI nodes.

**Key Properties:**
- `anchor_*` - Anchoring (left, right, top, bottom)
- `position` - Position relative to anchor
- `size` - Node size
- `visible` - Show/hide
- `modulate` - Color/transparency

### Label

Display text.

**Key Properties:**
- `text` - Display string
- `horizontal_alignment` - LEFT, CENTER, RIGHT
- `vertical_alignment` - TOP, CENTER, BOTTOM
- `autowrap_mode` - Text wrapping

### Button

Clickable button.

**Key Signals:**
- `pressed` - When clicked
- `button_down` - When pressed
- `button_up` - When released

**Key Properties:**
- `text` - Button label
- `disabled` - Enable/disable

### TextureButton

Button with image.

**Key Properties:**
- `texture_normal` - Default appearance
- `texture_pressed` - When clicked
- `texture_hover` - On mouse over
- `texture_disabled` - When disabled

### NinePatchRect

Scalable UI panel without distortion.

**Key Properties:**
- `texture` - Panel texture
- `region_rect` - Which part of texture to use
- `patch_margin_*` - Non-stretched borders

## Audio Nodes

### AudioStreamPlayer / AudioStreamPlayer2D

Play sounds. 2D version has positional audio.

**Key Properties:**
- `stream` - Audio file (MP3, WAV, OGG)
- `volume_db` - Volume (-80 to 24)
- `pitch_scale` - Playback speed
- `autoplay` - Start on scene load
- `bus` - Audio bus for mixing

**Key Methods:**
- `play(from_position)` - Start playback
- `stop()` - Stop playback
- `seek(position)` - Jump to time

**Key Signals:**
- `finished` - When playback completes

**Example:**
```gdscript
@onready var audio = $AudioStreamPlayer

func _ready():
    audio.stream = preload("res://sounds/music.mp3")
    audio.volume_db = -10.0
    audio.play()

func play_sound_effect():
    var sfx = AudioStreamPlayer.new()
    sfx.stream = preload("res://sounds/jump.wav")
    add_child(sfx)
    sfx.play()
    await sfx.finished
    sfx.queue_free()
```

## Utility Nodes

### Timer

Execute code after delay.

**Key Properties:**
- `wait_time` - Duration in seconds
- `one_shot` - Fire once vs. repeat
- `autostart` - Start on scene load

**Key Methods:**
- `start(time)` - Begin countdown
- `stop()` - Cancel timer
- `is_stopped()` - Check if running

**Key Signals:**
- `timeout` - When timer completes

**Example:**
```gdscript
@onready var timer = $Timer

func _ready():
    timer.wait_time = 3.0
    timer.one_shot = true
    timer.timeout.connect(_on_timeout)
    timer.start()

func _on_timeout():
    print("3 seconds elapsed")
```

### Camera2D

Camera viewport control.

**Key Properties:**
- `zoom` - Camera zoom level
- `position_smoothing_enabled` - Smooth following
- `position_smoothing_speed` - Follow speed
- `limit_*` - Camera boundaries (left, right, top, bottom)
- `enabled` - Enable/disable camera

**Key Methods:**
- `make_current()` - Set as active camera
- `get_screen_center_position()` - Get camera center in world space

**Example:**
```gdscript
@onready var camera = $Camera2D

func _ready():
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    camera.zoom = Vector2(1.5, 1.5)
    camera.make_current()
```

### Node2D

Base 2D node with transform.

**Key Properties:**
- `position` - Local position
- `global_position` - World position
- `rotation` - Rotation in radians
- `scale` - Scale multiplier
- `z_index` - Draw order (higher = on top)

**Key Methods:**
- `look_at(point)` - Rotate towards point
- `move_local_x(delta)` - Move in local direction
- `get_angle_to(point)` - Angle to point

### CanvasItem

Base class for anything drawn on screen (sprites, shapes, etc.).

**Key Methods:**
- `queue_redraw()` - Request visual update (calls `_draw()`)
- `show()` / `hide()` - Visibility
- `set_modulate(color)` - Tint/transparency

**Custom Drawing:**
```gdscript
func _draw():
    # Called when queue_redraw() is triggered
    draw_line(Vector2(0, 0), Vector2(100, 100), Color.RED, 2.0)
    draw_circle(Vector2(50, 50), 20, Color.BLUE)
    draw_rect(Rect2(0, 0, 100, 50), Color.GREEN)
```

### Path2D / PathFollow2D

Move objects along curved paths.

**Path2D** - Defines the path (use curve editor)
**PathFollow2D** - Follows the path

**PathFollow2D Properties:**
- `progress` - Distance along path (0 to path length)
- `progress_ratio` - Percentage along path (0.0 to 1.0)
- `loop` - Wrap around at end
- `rotates` - Rotate to follow path direction

**Example:**
```gdscript
extends PathFollow2D

@export var speed = 100.0

func _process(delta):
    progress += speed * delta
```
