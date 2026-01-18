extends Camera2D

func _ready():
	# Make camera current
	make_current()
	
	# Adjust zoom to show entire map (lower number = more zoomed out)
	zoom = Vector2(0.7, 0.7)  # Adjust this value to fit your map size	
	# Wait for scene tree to be fully ready, then position Snufkin
	await get_tree().process_frame
	position_snufkin()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			return_to_previous_scene()

func position_snufkin():
	# Find the DraggableSnufkin node
	var snufkin = get_tree().current_scene.get_node_or_null("DraggableSnufkin")
	if not snufkin:
		return
	
	# Position based on current location - using ACTUAL location node positions
	match Global.current_location:
		"tent":
			snufkin.position = Vector2(108, 203)  # TentLocation position
		"moomin_house":
			snufkin.position = Vector2(-239, 547)  # MoominHouseLocation position
		"bridge":
			snufkin.position = Vector2(290, 134)  # BridgeLocation position
	
	print("[MapController] Positioned Snufkin at: ", Global.current_location, " - Position: ", snufkin.position)

func return_to_previous_scene():
	if Global.previous_scene != "":
		print("[MapController] Returning to: ", Global.previous_scene)
		var scene_path = Global.previous_scene
		Global.previous_scene = ""  # Clear it
		Global.from_scene = ""  # Clear from_scene so position restoration works
		get_tree().change_scene_to_file(scene_path)
