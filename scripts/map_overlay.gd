extends CanvasLayer

# Reference to the map scene instance
var map_instance = null
var is_map_open = false

func _ready():
	# Start hidden
	visible = false
	# Process input even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event is InputEventKey and event.pressed:
		# M to open map
		if event.keycode == KEY_M and not is_map_open:
			open_map()
		# Esc to close map
		elif event.keycode == KEY_ESCAPE and is_map_open:
			close_map()

func open_map():
	if not map_instance:
		# Load and instance the map scene
		var map_scene = load("res://scenes/map_scene.tscn")
		map_instance = map_scene.instantiate()
		add_child(map_instance)
	
	# Position Snufkin at current location
	position_snufkin()
	
	# Show map and pause game
	visible = true
	is_map_open = true
	get_tree().paused = true
	print("[MapOverlay] Map opened, current location: ", Global.current_location)

func close_map():
	# Hide map and unpause game
	visible = false
	is_map_open = false
	get_tree().paused = false
	print("[MapOverlay] Map closed")

func position_snufkin():
	if not map_instance:
		return
	
	# Find the DraggableSnufkin node
	var snufkin = map_instance.get_node_or_null("DraggableSnufkin")
	if not snufkin:
		return
	
	# Position based on current location
	match Global.current_location:
		"tent":
			snufkin.position = Vector2(108, 203)  # Tent location position
		"moomin_house":
			snufkin.position = Vector2(-239, 547)  # Moomin house location position
		"bridge":
			snufkin.position = Vector2(290, 134)  # Bridge location position
	
	print("[MapOverlay] Positioned Snufkin at: ", Global.current_location)
