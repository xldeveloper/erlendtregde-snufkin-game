extends Button

func _ready():
	# Connect the button to the function
	self.pressed.connect(_on_stop_fishing_pressed)

func _on_stop_fishing_pressed():
	# Track that we're coming from fishing_scene
	print("[StopFishing] Setting from_scene to fishing_scene")
	Global.from_scene = "fishing_scene"
	# Change the scene back to main
	get_tree().change_scene_to_file("res://scenes/main.tscn")
