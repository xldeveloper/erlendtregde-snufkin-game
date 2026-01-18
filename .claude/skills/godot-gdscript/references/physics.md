# Physics & Collision

Advanced physics patterns and collision detection in Godot 4.x.

## Collision Layers & Masks

**Layers** = What layer is this object on?
**Masks** = What layers can this object detect?

Configure in Project Settings → Layer Names → 2D Physics

### Common Setup

```
Layer 1: Player
Layer 2: Enemies
Layer 3: Environment (walls, floors)
Layer 4: Triggers (Area2D zones)
Layer 5: Projectiles
```

### Examples

**Player:**
- Layer: 1 (Player)
- Mask: 2, 3, 4 (Detect enemies, environment, triggers)

**Enemy:**
- Layer: 2 (Enemies)
- Mask: 1, 3, 5 (Detect player, environment, projectiles)

**Bullet:**
- Layer: 5 (Projectiles)
- Mask: 2, 3 (Detect enemies, environment)

**Trigger Zone:**
- Layer: 4 (Triggers)
- Mask: 1 (Only detect player)

## CharacterBody2D Movement Patterns

### Platformer Movement

```gdscript
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

func _physics_process(delta):
    # Gravity
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    
    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY
    
    # Horizontal movement
    var direction = Input.get_axis("move_left", "move_right")
    if direction:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
    
    move_and_slide()
```

### Top-Down Movement (4-directional)

```gdscript
extends CharacterBody2D

const SPEED = 300.0

func _physics_process(delta):
    var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    if input_vector != Vector2.ZERO:
        velocity = input_vector.normalized() * SPEED
    else:
        velocity = velocity.move_toward(Vector2.ZERO, SPEED)
    
    move_and_slide()
```

### Top-Down Movement (8-directional with acceleration)

```gdscript
extends CharacterBody2D

const SPEED = 300.0
const ACCELERATION = 1500.0
const FRICTION = 1000.0

func _physics_process(delta):
    var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    if input_vector != Vector2.ZERO:
        input_vector = input_vector.normalized()
        velocity = velocity.move_toward(input_vector * SPEED, ACCELERATION * delta)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
    
    move_and_slide()
```

### Knockback

```gdscript
extends CharacterBody2D

var knockback_velocity = Vector2.ZERO
var knockback_friction = 500.0

func _physics_process(delta):
    # Apply knockback
    if knockback_velocity != Vector2.ZERO:
        knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
        velocity = knockback_velocity
    else:
        # Normal movement
        handle_movement()
    
    move_and_slide()

func apply_knockback(direction: Vector2, force: float):
    knockback_velocity = direction.normalized() * force
```

### Dash Ability

```gdscript
extends CharacterBody2D

const DASH_SPEED = 800.0
const DASH_DURATION = 0.2

var is_dashing = false
var dash_direction = Vector2.ZERO

func _physics_process(delta):
    if is_dashing:
        velocity = dash_direction * DASH_SPEED
    else:
        handle_normal_movement()
    
    move_and_slide()

func dash():
    if is_dashing:
        return
    
    var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if input_vector != Vector2.ZERO:
        is_dashing = true
        dash_direction = input_vector.normalized()
        
        await get_tree().create_timer(DASH_DURATION).timeout
        is_dashing = false
```

## Collision Detection Patterns

### Check Specific Collision

```gdscript
extends CharacterBody2D

func _physics_process(delta):
    velocity.y += GRAVITY * delta
    move_and_slide()
    
    # Check collisions after move_and_slide()
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()
        
        if collider.is_in_group("Enemy"):
            take_damage(10)
        elif collider.is_in_group("Collectible"):
            collider.collect()
```

### Raycast Detection

```gdscript
extends Node2D

@onready var raycast = $RayCast2D

func _ready():
    raycast.enabled = true
    raycast.target_position = Vector2(100, 0)  # Cast 100 pixels to the right

func _physics_process(delta):
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        var collision_point = raycast.get_collision_point()
        print("Hit: ", collider.name, " at ", collision_point)
```

### Area2D Overlap Detection

```gdscript
extends Area2D

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.is_in_group("Player"):
        print("Player entered!")
        # Do something

func check_overlaps():
    var overlapping_bodies = get_overlapping_bodies()
    for body in overlapping_bodies:
        if body.is_in_group("Enemy"):
            print("Enemy in range: ", body.name)
```

### ShapeCast2D (Multiple Collisions)

```gdscript
extends Node2D

@onready var shapecast = $ShapeCast2D

func _ready():
    shapecast.enabled = true
    shapecast.target_position = Vector2(0, 100)

func _physics_process(delta):
    if shapecast.is_colliding():
        var collision_count = shapecast.get_collision_count()
        for i in range(collision_count):
            var collider = shapecast.get_collider(i)
            print("Colliding with: ", collider.name)
```

## RigidBody2D Patterns

### Apply Force

```gdscript
extends RigidBody2D

func _physics_process(delta):
    if Input.is_action_pressed("move_right"):
        apply_central_force(Vector2(500, 0))

func explode():
    # Apply outward force
    var direction = (global_position - explosion_center).normalized()
    apply_impulse(direction * 1000.0)
```

### Projectile

```gdscript
extends RigidBody2D

var speed = 500.0
var direction = Vector2.RIGHT

func _ready():
    linear_velocity = direction * speed
    
    # Auto-destroy after 5 seconds
    await get_tree().create_timer(5.0).timeout
    queue_free()

func _on_body_entered(body):
    if body.is_in_group("Enemy"):
        body.take_damage(10)
    queue_free()
```

## One-Way Platforms

```gdscript
extends CharacterBody2D

func _physics_process(delta):
    velocity.y += GRAVITY * delta
    
    # Disable one-way collision when moving down
    if Input.is_action_pressed("move_down"):
        set_collision_mask_value(3, false)  # Disable layer 3
    else:
        set_collision_mask_value(3, true)
    
    move_and_slide()
```

## Advanced: Custom Physics Queries

### PhysicsRaycast

```gdscript
func raycast_query(from: Vector2, to: Vector2):
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(from, to)
    query.exclude = [self]  # Don't hit ourselves
    
    var result = space_state.intersect_ray(query)
    if result:
        print("Hit: ", result.collider.name)
        return result.collider
    return null
```

### PhysicsShapecast (Circle)

```gdscript
func check_circle_area(center: Vector2, radius: float):
    var space_state = get_world_2d().direct_space_state
    var shape = CircleShape2D.new()
    shape.radius = radius
    
    var query = PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0, center)
    query.exclude = [self]
    
    var results = space_state.intersect_shape(query)
    for result in results:
        print("Found: ", result.collider.name)
```

## Common Physics Issues

### Issue: Character Sticks to Walls When Jumping

**Solution:** Separate horizontal and vertical velocity

```gdscript
func _physics_process(delta):
    # Apply gravity first
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    
    # Then horizontal movement
    var direction = Input.get_axis("move_left", "move_right")
    velocity.x = direction * SPEED
    
    move_and_slide()
```

### Issue: Character Jitters on Moving Platform

**Solution:** Use platform_on_leave property

```gdscript
# On CharacterBody2D
platform_on_leave = PLATFORM_ON_LEAVE_ADD_VELOCITY
```

### Issue: Fast-Moving Objects Pass Through Collisions

**Solution:** Enable Continuous Collision Detection (CCD)

```gdscript
# For RigidBody2D
continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

# For CharacterBody2D, reduce delta or use multiple move_and_slide() calls
func _physics_process(delta):
    for i in 2:  # Move twice per frame
        velocity.y += (GRAVITY * delta) / 2.0
        move_and_slide()
```
