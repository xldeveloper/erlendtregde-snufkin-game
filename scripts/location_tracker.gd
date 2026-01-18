extends Node

# Track player's current location based on position in Main scene

var player
var has_initialized = false

func _ready():
	# Wait for player to finish spawning
	await get_tree().create_timer(0.2).timeout
	player = get_tree().get_first_node_in_group("Player")
	if player:
		update_player_location()
		has_initialized = true

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	if has_initialized and player:
		update_player_location()

func update_player_location():
	var player_x = player.global_position.x
	
	# Determine location based on player's X position in Main scene
	var new_location = ""
	if player_x >= -2000 and player_x < 0:  # Bridge area (negative X)
		new_location = "bridge"
	elif player_x >= 2000 and player_x < 3000:  # Moomin House area
		new_location = "moomin_house"
	elif player_x >= 0 and player_x < 1500:  # Tent area (positive X, not too far right)
		new_location = "tent"
	
	if new_location != "" and Global.current_location != new_location:
		Global.current_location = new_location
		print("[LocationTracker] Player moved to: ", new_location)
