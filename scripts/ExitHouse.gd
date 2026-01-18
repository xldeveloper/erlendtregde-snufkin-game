extends Area2D

var entered = false  
var player_character_body = null  # Cache CharacterBody2D reference
@onready var label = $Label  

func _ready():
	label.visible = false
	# We're in the house, so set location
	Global.current_location = "moomin_house"
	
	# Wait for scene to fully load before restoring position
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame to ensure player is ready
	
	# Restore saved position ONLY if returning from map to house_interior
	var current_scene_path = get_tree().current_scene.scene_file_path
	if Global.saved_player_position != Vector2.ZERO and Global.saved_position_scene == current_scene_path:
		var _player = get_tree().get_first_node_in_group("Player")
		if _player:
			print("[HouseInterior] Restoring saved position: ", Global.saved_player_position)
			_player.global_position = Global.saved_player_position
			Global.saved_player_position = Vector2.ZERO
			Global.saved_position_scene = ""
	else:
		# Coming from a different scene, clear the saved position
		print("[HouseInterior] Not restoring position - different scene or no saved position")
		Global.saved_player_position = Vector2.ZERO
		Global.saved_position_scene = ""

func _on_body_entered(body):
	if body.is_in_group("Player"):  
		entered = true
		player_character_body = body
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		entered = false
		player_character_body = null
		label.visible = false

func _process(_delta):
	if not is_inside_tree():
		return
	if entered and Input.is_action_just_pressed("interact"):
		# Track that we're coming from house_interior
		print("[ExitHouse] Setting from_scene to house_interior")
		Global.from_scene = "house_interior"
		get_tree().change_scene_to_file("res://scenes/main.tscn")
