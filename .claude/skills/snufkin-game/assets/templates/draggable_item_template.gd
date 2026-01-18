# Draggable Item Template
# Use for objects that can be picked up and dragged with mouse

extends Node2D

# Configuration
@export var can_be_dragged: bool = true
@export var snap_to_grid: bool = false
@export var grid_size: int = 32

# State
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready():
	# Connect input events from Area2D child
	if has_node("Area2D"):
		$Area2D.input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if not can_be_dragged:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
			else:
				# Stop dragging
				is_dragging = false
				if snap_to_grid:
					snap_position_to_grid()

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func snap_position_to_grid():
	global_position.x = round(global_position.x / grid_size) * grid_size
	global_position.y = round(global_position.y / grid_size) * grid_size

# Optional: Add bounds checking
func is_within_bounds(pos: Vector2) -> bool:
	# Implement boundary checking if needed
	return true

# SETUP INSTRUCTIONS:
# 1. Add this script to a Node2D
# 2. Add Area2D child with CollisionShape2D
# 3. Add Sprite2D or other visual
# 4. In Inspector, configure:
#    - can_be_dragged: Enable/disable dragging
#    - snap_to_grid: Snap to grid when released
#    - grid_size: Size of grid cells
# 5. Area2D must have input_pickable = true
#
# Scene Structure:
# DraggableItem (Node2D) - this script
# ├── Area2D (input_pickable = true)
# │   └── CollisionShape2D
# └── Sprite2D (or visual node)
#
# USAGE EXAMPLES:
# - Furniture in house interior
# - Items in inventory
# - Puzzle pieces
# - Decorative objects
