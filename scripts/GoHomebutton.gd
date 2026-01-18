extends Button

func _ready():
	self.pressed.connect(_on_stop_fishing_pressed)
	
	# We're at the bridge, so set location
	Global.current_location = "bridge"
	
	# Clear saved position since fishing scene doesn't use CharacterBody2D player
	Global.saved_player_position = Vector2.ZERO
	Global.saved_position_scene = ""

func _on_stop_fishing_pressed():
	# Track that we're coming from fishing_scene
	print("[GoHomeButton] Setting from_scene to fishing_scene")
	Global.from_scene = "fishing_scene"
	get_tree().change_scene_to_file("res://scenes/main.tscn")
