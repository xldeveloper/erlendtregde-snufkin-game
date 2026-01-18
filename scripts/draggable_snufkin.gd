extends Area2D

# Dragging state
var is_dragging = false
var drag_offset = Vector2.ZERO

# Current location we're hovering over
var current_location: Area2D = null

# Animation state (for future use)
var is_idle = true

# Reference to sprite
@onready var sprite = $Sprite2D

func _ready():
	# Make sure we can receive input
	z_index = 200  # Draw on top of everything
	
	# Connect input signals
	input_event.connect(_on_input_event)
	
	# Position will be set by MapController based on current_location
	print("[Snufkin] Initialized at position: ", position)

func _on_input_event(_viewport, event, _shape_idx):
	# Start dragging on right click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging = true
				is_idle = false
				drag_offset = position - get_global_mouse_position()
		# Left click to enter location
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not is_dragging:
				if current_location:
					enter_location()

func _input(event):
	# Stop dragging on release
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			if is_dragging:
				is_dragging = false
				is_idle = true
	
	# Move Snufkin while dragging
	if event is InputEventMouseMotion and is_dragging:
		position = get_global_mouse_position() + drag_offset

func _process(_delta):
	# Check which location we're hovering over
	check_location_hover()

func check_location_hover():
	# Get all areas at Snufkin's position
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = global_position
	params.collide_with_areas = true
	params.collide_with_bodies = false
	
	var result = space_state.intersect_point(params, 10)
	
	for r in result:
		var area = r.collider
		# Skip self
		if area == self:
			continue
		if area is Area2D and area.has_method("change_scene"):
			if current_location != area:
				# New location detected
				current_location = area
				print("[Snufkin] Hovering over: ", area.location_name)
			return
	
	# Not over any location
	if current_location != null:
		print("[Snufkin] Left location")
	current_location = null

func enter_location():
	if current_location:
		print("[Snufkin] Entering: ", current_location.location_name)
		
		# Save which location we're entering from for spawn positioning
		if current_location.location_name == "Tent":
			Global.from_scene = "map_tent"
		elif current_location.location_name == "Moomin House":
			Global.from_scene = "map_moomin"
		elif current_location.location_name == "Bridge":
			Global.from_scene = "map_bridge"
		
		current_location.change_scene()
